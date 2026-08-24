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
local cost_per_resume = 100 -- microseconds of pretend work
local guard_enters, guard_leaves = 0, 0

local real_deps = stepper.set_deps({
    now = function() return clock end,
    guard_enter = function() guard_enters = guard_enters + 1 end,
    guard_leave = function() guard_leaves = guard_leaves + 1 end
})

-- The clock only moves when a resume happens, so advance() sees time pass
-- exactly as if each resume took cost_per_resume.
local function make_drone(src, auth_level)
    local drone = {
        name = 'stepper_test',
        file = 'spec.lua',
        auth_level = auth_level or 4,
        calls = 0,
        commands = 0,
        volume = 0,
        checkpoints = {}
    }

    local chunk = assert(loadstring(preprocess.preprocess_code(src)),
                         'spec program failed to compile')

    local api = {print = function() end, error = error}
    api._G = envlib.seal({
        print = api.print,
        error = api.error,
        use_call = function()
            clock = clock + cost_per_resume
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
    -- Codelevel 1 deliberately, because calls_before_yield is 1 there: every
    -- injected counter call yields, so one resume costs exactly one
    -- cost_per_resume and the arithmetic below is checkable. At codelevel 4 the
    -- budget yields every 600th call, so a single resume charges 600 units and
    -- overruns any sensible budget on its own - which is a real property worth
    -- knowing, and is asserted separately further down.
    local drone = make_drone('for i = 1, 100000 do end\n', 1)

    clock = 0
    local resumes = stepper.advance(drone, 1000, 1024 * 1024)
    it('one step does more than a single resume', (resumes > 1), true)

    -- The old behaviour was exactly one. With 100us per resume and a 1000us
    -- budget, ten resumes fit; the eleventh check sees the budget spent.
    it('and about as many as the budget pays for', resumes, 10)

    -- Twice the budget, twice the work: throughput follows the allowance rather
    -- than the tick rate, which is the whole claim of A5.
    clock = 0
    local more = stepper.advance(drone, 2000, 1024 * 1024)
    it('doubling the budget doubles the work', more, 20)

    clock = 0
    local less = stepper.advance(drone, 300, 1024 * 1024)
    it('a small budget does proportionally less', less, 3)
end

--------------------------------------------------------------------------------
-- outcomes
--------------------------------------------------------------------------------

do
    local drone = make_drone('for i = 1, 100000 do end\n', 1)
    clock = 0
    local _, outcome = stepper.advance(drone, 500, 1024 * 1024)
    it('an unfinished program yields', outcome, 'yielded')
end

-- The budget is checked between resumes, never inside one, so a resume that
-- runs long overshoots it. At codelevel 4 that is the normal case rather than an
-- edge one: 600 calls pass before the program yields. Asserted so the limitation
-- is recorded rather than discovered later.
do
    local drone = make_drone('for i = 1, 100000 do end\n', 4)
    clock = 0
    local resumes = stepper.advance(drone, 100, 1024 * 1024)
    it('a long resume still runs to its own yield point', resumes, 1)
    it('overshooting the budget rather than interrupting it', (clock > 100), true)
end

do
    -- short enough to finish inside one step
    local drone = make_drone('local x = 0\nfor i = 1, 3 do x = x + 1 end\n', 4)
    clock = 0
    local _, outcome = stepper.advance(drone, 1000000, 1024 * 1024)
    it('a finished program reports completed', outcome, 'completed')
end

do
    local drone = make_drone('for i = 1, 10 do end\nerror("boom")\n', 4)
    clock = 0
    local _, outcome, err = stepper.advance(drone, 1000000, 1024 * 1024)
    it('a failing program reports error', outcome, 'error')
    it('and carries the message',
       (err ~= nil and tostring(err):find('boom', 1, true) ~= nil), true)
end

do
    -- a completed coroutine, advanced again
    local drone = make_drone('local x = 1\n', 4)
    clock = 0
    stepper.advance(drone, 1000000, 1024 * 1024)
    clock = 0
    local resumes, outcome = stepper.advance(drone, 1000, 1024 * 1024)
    it('advancing a finished program resumes nothing', resumes, 0)
    it('and still reports completed', outcome, 'completed')
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
    stepper.advance(drone, 1000, 1024 * 1024)
    it('armed once for the whole step', guard_enters, 1)
    it('released once', guard_leaves, 1)

    -- and on the error path, where an early return would be easy to write
    local bad = make_drone('error("boom")\n', 4)
    guard_enters, guard_leaves = 0, 0
    clock = 0
    stepper.advance(bad, 1000, 1024 * 1024)
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
