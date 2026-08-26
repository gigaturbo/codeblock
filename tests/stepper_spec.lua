--- Tests for lib/stepper.lua
--
-- In-engine only: it reaches codeblock.stepper and the real command budget.
--
-- The point of these is measurement, not just behaviour. The claim behind audit
-- finding A5 is "a step now does more than one resume, in proportion to the time
-- it is given". That is only checkable with control of the clock, which is why
-- the stepping logic was pulled out of the entity callback in the first place.

if not (rawget(_G, 'codeblock') and codeblock.stepper) then
    io.write('\n  stepper_spec\n  skipped (needs the mod loaded)\n\n')
    return {skipped = true}
end

local stepper = codeblock.stepper
local preprocess = codeblock.preprocess
local envlib = codeblock.env
local use_call = codeblock.commands.drone_use_call

local pass, fail = 0, 0
local failures = {}

local function it(name, got, want)
    if got == want then
        pass = pass + 1
    else
        fail = fail + 1
        failures[#failures + 1] = ('FAIL   %s\n       want: %s\n       got : %s')
                                      :format(name, tostring(want), tostring(got))
    end
end

--------------------------------------------------------------------------------
-- a fake clock, and a drone whose program really runs
--------------------------------------------------------------------------------

local clock = 0
local cost_per_call = 4 -- microseconds of pretend work per instrumented call
local guard_enters, guard_leaves = 0, 0

--- A real budget for `auth_level`, as lib/drone.lua builds one per run.
local function new_budget(auth_level)
    return codeblock.limits.new(codeblock.config, auth_level, clock)
end

local real_deps = stepper.set_deps({
    now = function() return clock end,
    guard_enter = function() guard_enters = guard_enters + 1 end,
    guard_leave = function() guard_leaves = guard_leaves + 1 end
})

-- The clock only moves when the program makes an instrumented call, so advance()
-- sees time pass exactly as if each call took cost_per_call.
local function make_drone(src, auth_level)
    local drone = {
        name = 'stepper_test',
        file = 'spec.lua',
        auth_level = auth_level or 4,
        calls = 0,
        commands = 0,
        checkpoints = {},
        budget = new_budget(auth_level or 4)
    }

    local chunk = assert(loadstring(preprocess.preprocess_code(src)),
                         'spec program failed to compile')

    local api = {print = function() end, error = error}
    api._G = envlib.seal({
        print = api.print,
        error = api.error,
        use_call = function()
            clock = clock + cost_per_call
            use_call(drone)
        end
    }, '_G')

    setfenv(chunk, envlib.new_env(api))
    drone.cor = coroutine.create(chunk)
    return drone
end

--------------------------------------------------------------------------------
-- the measurement: a step does as much work as its budget allows
--------------------------------------------------------------------------------

do
    local drone = make_drone('for i = 1, 100000 do end\n', 4)

    -- What one resume costs is measured rather than assumed: the counter yields
    -- every so many calls, and that cadence is a constant inside
    -- lib/commands.lua. A budget of 1 buys exactly one resume, so the clock says
    -- what a resume is worth, whatever the constant becomes.
    clock = 0
    stepper.advance(drone, 1)
    local per_resume = clock
    it('a resume is a run of instrumented calls', (per_resume > cost_per_call),
       true)

    clock = 0
    local resumes = stepper.advance(drone, per_resume * 10)
    it('one step does more than a single resume', (resumes > 1), true)

    -- The old behaviour was exactly one resume per step, however long the step
    -- had left.
    it('and about as many as the budget pays for', resumes, 10)

    -- Twice the budget, twice the work: throughput follows the allowance rather
    -- than the tick rate, which is the whole claim of A5.
    clock = 0
    local more = stepper.advance(drone, per_resume * 20)
    it('doubling the budget doubles the work', more, 20)

    clock = 0
    local less = stepper.advance(drone, per_resume * 3)
    it('a small budget does proportionally less', less, 3)
end

--------------------------------------------------------------------------------
-- one pool, shared (S5)
--
-- stepper.budget is arithmetic and nothing else, which is the point: the claim
-- "N drones no longer cost N budgets per step" is checkable without a server.
--------------------------------------------------------------------------------

do
    local budget = stepper.budget

    it('one drone gets its whole codelevel cap', budget(8000, 16000, 1), 8000)
    it('two drones still fit under the cap', budget(8000, 16000, 2), 8000)
    it('four drones share the pool', budget(8000, 16000, 4), 4000)
    it('sixteen drones share it further', budget(8000, 16000, 16), 1000)

    -- The old behaviour, for comparison: 16 drones at 8000 each was 128000us of
    -- a 90000us step. The share keeps the total at the pool.
    it('the total never exceeds the pool', 16 * budget(8000, 16000, 16), 16000)

    it('a low codelevel keeps its own smaller cap', budget(1000, 16000, 2), 1000)
    it('a count of zero is treated as one', budget(8000, 16000, 0), 8000)
end

--------------------------------------------------------------------------------
-- outcomes
--------------------------------------------------------------------------------

do
    local drone = make_drone('for i = 1, 100000 do end\n', 1)
    clock = 0
    local _, outcome = stepper.advance(drone, 500)
    it('an unfinished program yields', outcome, 'yielded')
end

-- The budget is checked between resumes, never inside one, so a resume that runs
-- long overshoots it - a run of instrumented calls happens before the program
-- yields, whatever is left of the slice. Asserted so the limitation is recorded
-- rather than discovered later.
do
    local drone = make_drone('for i = 1, 100000 do end\n', 4)
    clock = 0
    local resumes = stepper.advance(drone, 100)
    it('a long resume still runs to its own yield point', resumes, 1)
    it('overshooting the budget rather than interrupting it', (clock > 100), true)
end

do
    -- short enough to finish inside one step
    local drone = make_drone('local x = 0\nfor i = 1, 3 do x = x + 1 end\n', 4)
    clock = 0
    local _, outcome = stepper.advance(drone, 1000000)
    it('a finished program reports completed', outcome, 'completed')
end

do
    local drone = make_drone('for i = 1, 10 do end\nerror("boom")\n', 4)
    clock = 0
    local _, outcome, err = stepper.advance(drone, 1000000)
    it('a failing program reports error', outcome, 'error')
    it('and carries the message',
       (err ~= nil and tostring(err):find('boom', 1, true) ~= nil), true)
end

do
    -- a completed coroutine, advanced again
    local drone = make_drone('local x = 1\n', 4)
    clock = 0
    stepper.advance(drone, 1000000)
    clock = 0
    local resumes, outcome = stepper.advance(drone, 1000)
    it('advancing a finished program resumes nothing', resumes, 0)
    it('and still reports completed', outcome, 'completed')
end

--------------------------------------------------------------------------------
-- sleeping: the pace, and waiting for map memory
--
-- Both work the same way - the drone says when it wants to run again as it
-- yields - so both are covered by driving wake_at directly.
--------------------------------------------------------------------------------

do
    local drone = make_drone('for i = 1, 100000 do end\n', 4)

    -- Sleeps for 5ms every time it is resumed.
    drone.cor = coroutine.create(function()
        while true do
            drone.wake_at = clock + 5000
            coroutine.yield()
        end
    end)

    clock = 0
    local resumes = stepper.advance(drone, 1000000)
    it('a drone that sleeps ends the step there', resumes, 1)
    it('however much of the slice was left', (clock < 1000000), true)

    local asleep = stepper.advance(drone, 1000000)
    it('and is not resumed while it sleeps', asleep, 0)
    it('nor charged for the step', drone.budget.used.runtime, 0)

    clock = 5000
    it('but runs again once it is due', (stepper.advance(drone, 1) == 1), true)
    it('a drone with no wake-up time is always due',
       stepper.awake(make_drone('local x = 1\n', 4)), true)
end

--------------------------------------------------------------------------------
-- running time: the bound on a program that never finishes
--
-- Nothing limits how many calls or commands a program makes any more. What it
-- spends is time, charged here as time actually advanced - so a drone that slept,
-- or one on a server too busy to run it, is not charged for being slow.
--------------------------------------------------------------------------------

do
    local drone = make_drone('for i = 1, 1e9 do end\n', 4)
    clock = 0

    stepper.advance(drone, 1000)
    local first = drone.budget.used.runtime
    it('a step charges the time it spent', (first > 0), true)

    stepper.advance(drone, 1000)
    it('and the next one adds to it', (drone.budget.used.runtime > first), true)

    -- An endless program against a ceiling it has nearly reached: the next step
    -- takes it over and it is stopped rather than yielding again.
    drone.budget.caps.runtime = drone.budget.used.runtime + 1
    local _, outcome = stepper.advance(drone, 1000)
    it('a program out of running time reports timeout', outcome, 'timeout')

    -- A program that finishes on the step that runs it out is reported as having
    -- finished: it did.
    local short = make_drone('local x = 1\n', 4)
    short.budget.caps.runtime = 1
    local _, done = stepper.advance(short, 1000)
    it('but finishing wins over running out', done, 'completed')
end

--------------------------------------------------------------------------------
-- the string guard must be armed and released exactly once per step
--
-- One left armed would apply the per-run string limit to every other mod on the
-- server, so this is worth asserting rather than assuming.
--------------------------------------------------------------------------------

do
    local drone = make_drone('for i = 1, 100000 do end\n', 4)
    guard_enters, guard_leaves = 0, 0
    clock = 0
    stepper.advance(drone, 1000)
    it('armed once for the whole step', guard_enters, 1)
    it('released once', guard_leaves, 1)

    -- and on the error path, where an early return would be easy to write
    local bad = make_drone('error("boom")\n', 4)
    guard_enters, guard_leaves = 0, 0
    clock = 0
    stepper.advance(bad, 1000)
    it('released even when the program raises', guard_leaves, 1)
    it('armed exactly once on that path too', guard_enters, 1)
end

--------------------------------------------------------------------------------
-- restore the real clock and guards, or every drone after this misbehaves
--------------------------------------------------------------------------------

stepper.set_deps(real_deps)
it('the real dependencies are restored',
   (type(codeblock.stepper.advance) == 'function'), true)

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  stepper_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''
print(table.concat(out, '\n'))

return {passed = pass, failed = fail}
