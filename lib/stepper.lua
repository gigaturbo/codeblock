--- Advancing a running program, one server step at a time.
--
-- A step resumes the drone's coroutine repeatedly until a time budget is spent,
-- rather than exactly once. Throughput then follows the headroom the server has
-- spare instead of the tick rate, and `calls_before_yield` goes back to meaning
-- how finely the work is chopped.
--
-- The budget is checked between resumes, so one long resume overshoots it: a
-- large worldedit shape is a single call and cannot be interrupted. It bounds
-- how much work is started, not the length of any one piece. Each drone gets
-- its own budget.
--
-- Kept out of lib/drone_entity.lua so a test can drive it with an injected
-- clock.

codeblock.stepper = {}

local stepper = codeblock.stepper

--------------------------------------------------------------------------------
-- dependencies
--
-- Module-level rather than passed per call: on_step runs for every drone on
-- every server step. Tests swap them out, as in lib/forms.lua.
--------------------------------------------------------------------------------

local deps = {
    now = function() return minetest.get_us_time() end,
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
-- advancing
--------------------------------------------------------------------------------

--- Run `drone`'s coroutine until its budget is spent or it stops.
--
-- Returns resumes, outcome, err where outcome is one of:
--   'yielded'    still running, budget spent - resume again next step
--   'completed'  the program finished
--   'error'      it raised; `err` is the message
--   'blocked'    neither suspended nor dead, which should not happen and is
--                reported rather than looped on
--
-- `guard_bytes` is the per-run string ceiling handed to strguard. The guards
-- wrap the whole loop rather than each resume: Luanti runs mods on one thread,
-- so nothing else can execute inside it.
function stepper.advance(drone, budget_us, guard_bytes)

    local now = deps.now
    local started = now()
    local resumes, outcome, err = 0, nil, nil

    deps.guard_enter(guard_bytes)

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

        -- Budget spent: leave the loop without setting an outcome, so the
        -- default below applies. Expressing 'yielded' once at the return rather
        -- than as an initialiser keeps it from being a dead assignment, and
        -- means a break added here later still gets a safe answer instead of nil.
        if now() - started >= budget_us then break end
    end

    -- Single exit point for the guard: one left armed would apply the string
    -- limit to every other mod on the server.
    deps.guard_leave()

    return resumes, outcome or 'yielded', err
end

return stepper
