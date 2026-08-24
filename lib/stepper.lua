--- Advancing a running program, one server step at a time.
--
-- Audit finding A5. The drone used to resume its coroutine exactly once per
-- server step. The program then ran until its next yield, which the budget in
-- commands.lua places every `calls_before_yield` calls - 600 at codelevel 4 -
-- and then stopped until the next step, whatever the server was doing. Two
-- consequences:
--
--   Throughput was pinned to the tick rate. A step finishing in 200us waited out
--   the rest of its ~90ms tick exactly like one that took 40ms, so a large build
--   crawled on an idle server.
--
--   `calls_before_yield` had to double as a throughput dial, which is not what it
--   is for. Raising it to speed the drone up made each resume longer and the
--   server less responsive; lowering it did the reverse. There was no setting
--   that meant "go faster but stay responsive".
--
-- Now a step resumes repeatedly until a time budget is spent. Throughput follows
-- available headroom, and `calls_before_yield` becomes what it should be: how
-- finely the work is chopped, and therefore how precisely the budget can be
-- honoured.
--
-- The budget is checked *between* resumes, so a single resume that runs long
-- overshoots it - one large worldedit shape is one call and cannot be
-- interrupted. The budget bounds how much work is *started*, not the length of
-- any one piece.
--
-- Each drone gets its own budget, so N drones cost N budgets per step. Fine for
-- the singleplayer case this game is built around; a busy server would want a
-- shared allowance.
--
-- Kept separate from lib/drone_entity.lua so it can be driven by a test with an
-- injected clock. Measuring "does this actually resume more than once" needs
-- control of time, which an entity callback does not give you.

codeblock.stepper = {}

local stepper = codeblock.stepper

--------------------------------------------------------------------------------
-- dependencies
--
-- Module-level rather than passed per call: on_step runs for every drone on
-- every server step, and allocating a table or a closure there would be waste.
-- Tests swap them out, the same way lib/forms.lua does.
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
--   'blocked'    the coroutine is neither suspended nor dead, which should not
--                happen and is reported rather than looped on
--
-- `guard_bytes` is the per-run string ceiling handed to strguard for the span in
-- which player code executes. The guards wrap the whole loop rather than each
-- resume: Luanti runs mods on one thread, so nothing else can execute inside it,
-- and one enter/leave pair per step is cheaper than one per resume.
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
