--- Advancing a running program, one server step at a time.
--
-- A step resumes the drone's coroutine repeatedly until a time budget is spent,
-- rather than exactly once. Throughput then follows the headroom the server has
-- spare instead of the tick rate.
--
-- The budget is checked between resumes, and again at each drone command and
-- each slab of a bulk shape through the deadline this module publishes. What
-- still overshoots it is one slab, which is bounded by lib/shapes.lua rather
-- than by anything here.
--
-- The budget itself is a share rather than an allowance - see stepper.budget.
--
-- Two things make a drone stop early. It can go to sleep: a paced codelevel and
-- a program waiting for map memory both set drone.wake_at, and until then the
-- drone is not resumed and takes no share of the pool. And the time it does
-- spend is charged against its runtime budget, which is what stops a program
-- that never finishes - reported as the 'timeout' outcome.
--
-- Kept out of the step driver so a test can drive it with an injected clock.

codeblock.stepper = {}

local stepper = codeblock.stepper
local charge = codeblock.limits.charge

--------------------------------------------------------------------------------
-- dependencies
--
-- Module-level rather than passed per call: on_step runs for every drone on
-- every server step. Tests swap them out, as in lib/forms.lua.
--------------------------------------------------------------------------------

local deps = {
    now = function() return core.get_us_time() end,
    guard_enter = function(bytes) codeblock.strguard.enter(bytes) end,
    guard_leave = function() codeblock.strguard.leave() end
}

--- Replace the clock and guards. Returns the previous set so a test can restore.
function stepper.set_deps(t)
    local previous = deps
    deps = t
    return previous
end

--------------------------------------------------------------------------------
-- how much of a step one drone gets
--------------------------------------------------------------------------------

--- The smaller of a drone's codelevel cap and an equal share of the pool.
--
-- Without the pool, every drone gets its own allowance and the server's cost
-- grows with the number of players: N drones cost N budgets per step. With it,
-- the total is bounded and adding a player slows everyone equally instead of
-- charging the server more. Arithmetic only, so it can be tested. (S5)
function stepper.budget(cap, pool, running)
    local share = pool / (running > 1 and running or 1)
    return share < cap and share or cap
end

--------------------------------------------------------------------------------
-- sleeping
--------------------------------------------------------------------------------

--- Is this drone due to run at all?
--
-- A paced or throttled drone sleeps until drone.wake_at, and a sleeping drone
-- must not take a share of the step pool either - otherwise a classroom of paced
-- novices would shrink the slice of the one drone actually working.
--
-- drone.paused is the player holding the program, and is deliberately not
-- expressed as a far-off wake_at: advance() clears wake_at the moment a drone is
-- awake again, so a pause that borrowed it would throw away the wake time of a
-- program that was in the middle of its own sleep(). Two reasons to be stopped,
-- two fields. (F4)
function stepper.awake(drone)
    if drone.paused then return false end
    return drone.wake_at == nil or deps.now() >= drone.wake_at
end

--------------------------------------------------------------------------------
-- advancing
--------------------------------------------------------------------------------

--- Run `drone`'s coroutine until its budget is spent or it stops.
--
-- Returns resumes, outcome, err where outcome is one of:
--   'yielded'    still running, budget spent - resume again next step
--   'completed'  the program finished
--   'error'      it raised; `err` is the message
--   'timeout'    it used all the running time its codelevel allows
--   'blocked'    neither suspended nor dead, which should not happen and is
--                reported rather than looped on
--
-- The string ceiling comes from the drone's own budget. The guards wrap the
-- whole loop rather than each resume: Luanti runs mods on one thread, so nothing
-- else can execute inside it.
function stepper.advance(drone, budget_us)

    local now = deps.now

    -- Asleep: nothing to do this step, and no time charged for finding out.
    if not stepper.awake(drone) then return 0, 'yielded' end
    drone.wake_at = nil

    local started = now()
    local resumes, outcome, err = 0, nil, nil

    -- Published so check_drone_yield in lib/commands.lua can cut a resume short
    -- when the slice is gone, instead of running to its command count. Cleared
    -- below, because outside this loop there is no deadline to be past. (S5)
    --
    -- It is in this module's clock, and commands.lua reads the engine's. The
    -- same clock in production; a test that injects one here *and* runs real
    -- drone commands would have to inject both.
    drone.deadline = started + budget_us

    deps.guard_enter(drone.budget.caps.string_bytes)

    while true do
        local status = coroutine.status(drone.cor)

        if status == 'dead' then
            outcome = 'completed'
            break
        elseif status ~= 'suspended' then
            outcome = 'blocked'
            break
        end

        local ok, ret = coroutine.resume(drone.cor)
        resumes = resumes + 1

        if not ok then
            outcome, err = 'error', ret
            break
        end

        -- Check for completion here as well as at the top, so a program that
        -- finishes mid-step is reported in the same step rather than the next.
        if coroutine.status(drone.cor) == 'dead' then
            outcome = 'completed'
            break
        end

        -- It went to sleep as it yielded - for its pace, or waiting for map
        -- memory - so this step is over for it however much slice is left.
        if not stepper.awake(drone) then break end

        -- Budget spent: leave the loop without setting an outcome, so the
        -- default below applies. Expressing 'yielded' once at the return rather
        -- than as an initialiser keeps it from being a dead assignment, and
        -- means a break added here later still gets a safe answer instead of nil.
        if now() - started >= budget_us then break end
    end

    -- Single exit point for the guard: one left armed would apply the string
    -- limit to every other mod on the server.
    deps.guard_leave()
    drone.deadline = nil

    -- Only the time actually spent advancing, which is the point of charging it
    -- here: a drone that waited, or one on a busy server, is not charged for
    -- being slow. A run out of time reports it, unless it has already finished
    -- or failed for a better reason.
    local within = charge(drone.budget, 'runtime', now() - started)

    return resumes, outcome or (within and 'yielded' or 'timeout'), err
end

return stepper
