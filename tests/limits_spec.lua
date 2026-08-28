--- Tests for lib/limits.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua mods/codeblock/tests/limits_spec.lua
--
-- Or in-engine by starting the game with codeblock_run_tests = true.
--
-- The module is arithmetic, and what arithmetic like this gets wrong is the
-- boundary and the unit: a ceiling that is off by one, a megabyte counted as a
-- kilobyte, a decay that reaches zero at the wrong moment. So every case here
-- states the expected figure as a number rather than deriving it the way the
-- module does.

local limits
do
    if rawget(_G, 'codeblock') and codeblock.limits then
        limits = codeblock.limits
    else
        local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
        local candidates = {
            here and (here .. '/../lib/limits.lua') or nil,
            'mods/codeblock/lib/limits.lua', '../lib/limits.lua',
            'lib/limits.lua'
        }
        for _, p in ipairs(candidates) do
            local f = io.open(p, 'r')
            if f then
                f:close()
                limits = dofile(p)
                break
            end
        end
    end
end

assert(limits, 'could not locate lib/limits.lua')

--------------------------------------------------------------------------------
-- harness
--------------------------------------------------------------------------------

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

--- Same, to within a microsecond: the decay is floating point.
local function about(name, got, want)
    local close = type(got) == 'number' and math.abs(got - want) < 1
    it(name, close and want or got, want)
end

-- Shaped like codeblock.config, with values chosen to be recognisable after
-- conversion rather than realistic.
local config = {
    max_nodes_written = {100, 200, 300, 400},
    max_runtime_s = {1, 2, 3, 4},
    map_memory_mb = {1, 2, 4, 8},
    heap_mb = {1, 2, 4, 8},
    max_string_mb = {1, 2, 4, 8},
    pace_ms = {300, 50, 0, 0},
    step_budget_us = {1000, 2000, 4000, 8000},
    map_window_s = 10
}

local function new(level, now) return limits.new(config, level or 1, now or 0) end

--------------------------------------------------------------------------------
-- new: the caps arrive in the units the checks use
--------------------------------------------------------------------------------

do
    local b = new(2, 1234)

    it('the level is kept', b.level, 2)
    it('nodes stay nodes', b.caps.nodes, 200)
    it('runtime becomes microseconds', b.caps.runtime, 2e6)
    it('map memory becomes mapblocks', b.caps.map, 128)
    it('heap becomes kB', b.caps.heap_kb, 2048)
    it('the string ceiling becomes bytes', b.caps.string_bytes, 2 * 1024 * 1024)
    it('pace becomes microseconds', b.caps.pace, 50000)
    it('the step budget is passed through', b.caps.step, 2000)

    it('nothing is spent yet', b.used.nodes, 0)
    it('nothing is held yet', b.used.map, 0)
    it('the window becomes microseconds', b.window, 10e6)
    it('the footprint clock starts now', b.map_at, 1234)

    -- The engine's own setting is the source; 29s is only the fallback.
    local d = limits.new({
        max_nodes_written = {1}, max_runtime_s = {1}, map_memory_mb = {1},
        heap_mb = {1}, max_string_mb = {1}, pace_ms = {0},
        step_budget_us = {1}
    }, 1, 0)
    it('an unstated window falls back to the unload default', d.window, 29e6)

    -- A level 4 program is not level 1 with a bigger number: pace goes to zero,
    -- which is what makes the top levels fast rather than merely roomier.
    it('the novice is paced', new(1).caps.pace, 300000)
    it('the poweruser is not', new(4).caps.pace, 0)
end

--------------------------------------------------------------------------------
-- charge: spent resources stop the run
--------------------------------------------------------------------------------

do
    local b = new(1)

    it('a charge that fits is allowed', limits.charge(b, 'nodes', 60), true)
    it('and is counted', b.used.nodes, 60)

    it('landing exactly on the ceiling is allowed',
       limits.charge(b, 'nodes', 40), true)
    it('the ceiling is spent, not exceeded', b.used.nodes, 100)

    it('one unit past it is not', limits.charge(b, 'nodes', 1), false)
    it('the overspend is still recorded', b.used.nodes, 101)

    -- Two counters, one table: a run out of nodes has its runtime intact.
    it('runtime is charged separately', limits.charge(b, 'runtime', 999999),
       true)
    it('and has its own ceiling', limits.charge(b, 'runtime', 2), false)
end

--------------------------------------------------------------------------------
-- hold: the map footprint drains instead of killing the run
--------------------------------------------------------------------------------

do
    local b = new(1) -- cap 64 blocks, window 10s

    it('a footprint that fits needs no wait', limits.hold(b, 40, 0), 0)
    it('and is held', b.used.map, 40)

    it('a second one accumulates', limits.hold(b, 24, 0), 0)
    it('up to the ceiling', b.used.map, 64)

    -- Full, and no time has passed: the answer is how long to wait, not an
    -- error, because the engine is about to free these blocks anyway.
    local wait = limits.hold(b, 8, 0)
    about('a full footprint asks for a wait', wait, 10e6 * 8 / 64)
    it('and holds nothing extra meanwhile', b.used.map, 64)

    -- The round trip that matters: wait exactly what was asked, then the same
    -- request fits.
    it('waiting the stated time makes room', limits.hold(b, 8, wait), 0)

    -- Decay is linear over the window, so half a window halves the footprint.
    local c = new(1)
    limits.hold(c, 64, 0)
    limits.hold(c, 0, 5e6)
    about('half a window drains half the footprint', c.used.map, 32)

    -- A whole window with no load at all means nothing is resident.
    local d = new(1)
    limits.hold(d, 64, 0)
    it('a full window frees the whole footprint', limits.hold(d, 64, 10e6), 0)
    it('and the count starts again from that charge', d.used.map, 64)

    -- Never a wait longer than the window: past it there is nothing held.
    local e = new(1)
    limits.hold(e, 64, 0)
    it('a wait is never longer than the window',
       limits.hold(e, 64, 0) <= e.window, true)

    -- One request bigger than the whole ceiling can never be granted. Bulk
    -- writes avoid it by arriving in slices; this is the guard against a caller
    -- that does not, and it must not answer "wait" and be retried for ever.
    it('a request over the ceiling is refused outright',
       limits.hold(new(1), 65, 0), nil)
    it('a request exactly at the ceiling is not', limits.hold(new(1), 64, 0), 0)
end

--------------------------------------------------------------------------------
-- binding: which limit the run is actually closest to
--------------------------------------------------------------------------------

-- The display's whole point is to name one resource out of four, so what this
-- has to get right is the comparison across units: 60 nodes of 100 must beat
-- half a second of one second, even though 60 is the larger number.
do
    local b = new(1)

    local what, at = limits.binding(b)
    it('an untouched budget is binding on the first resource', what, 'nodes')
    it('and is not full at all', at, 0)

    b.used.nodes = 60
    b.used.runtime = 0.5e6
    what, at = limits.binding(b)
    it('the fuller fraction wins, not the larger number', what, 'nodes')
    it('and the fraction is in the resource\'s own units', at, 0.6)

    b.used.runtime = 0.9e6
    what, at = limits.binding(b)
    it('a fuller resource in another unit takes over', what, 'runtime')
    about('reported as a fraction of its own ceiling', at * 1000, 900)

    -- Mapblocks and kB, the two the display converts back for the player. Both
    -- have to be comparable here or the wrong row is highlighted.
    b.used.map = 60
    what = limits.binding(b)
    it('the map footprint competes on the same scale', what, 'map')

    b.used.heap_kb = 1000
    what, at = limits.binding(b)
    it('the heap peak competes too', what, 'heap_kb')
    about('at its own fraction', at * 1000, 976)

    -- A run is stopped by the charge that went over, so the honest figure is
    -- briefly above the ceiling. Clamping it here would hide an overshoot.
    b.used.heap_kb = 2048
    local _, over = limits.binding(b)
    it('an overshoot is reported as it is, not clamped', over, 2)
end

do
    -- A ceiling of zero admits no use at all: there is no fraction to compute,
    -- so nothing spent is empty and anything spent is full.
    local b = new(1)
    b.caps.nodes = 0
    it('a zero ceiling with nothing spent is not binding',
       select(2, limits.binding(b)), 0)
    b.used.nodes = 1
    it('a zero ceiling with anything spent is fully binding',
       select(2, limits.binding(b)), 1)
    it('and names that resource', limits.binding(b), 'nodes')
end

--------------------------------------------------------------------------------
-- report: back into the units a player reads
--------------------------------------------------------------------------------

-- limits.new converts the config's seconds and megabytes into microseconds and
-- mapblocks; this converts them back. The two have to be exact inverses, or the
-- panel shows a player a ceiling their settings file does not contain.
do
    local b = new(2)
    b.used.nodes = 50
    b.used.runtime = 1e6
    b.used.map = 64
    b.used.heap_kb = 512

    local r = limits.report(b)

    it('every fillable resource is reported', #r, 4)
    it('in a fixed order, so the rows never move', r[1].what .. r[2].what ..
           r[3].what .. r[4].what, 'nodesruntimemapheap_kb')

    it('nodes are counted, not converted', r[1].used, 50)
    it('and their ceiling is the config figure', r[1].cap, 200)
    it('nodes carry no unit', r[1].unit, '')

    it('runtime comes back as seconds', r[2].used, 1)
    it('against the ceiling in seconds', r[2].cap, 2)
    it('labelled as seconds', r[2].unit, 's')

    it('the footprint comes back as megabytes', r[3].used, 1)
    it('against the ceiling in megabytes', r[3].cap, 2)
    it('labelled as megabytes', r[3].unit, 'MB')

    it('the heap comes back as megabytes', r[4].used, 0.5)
    it('against the ceiling in megabytes', r[4].cap, 2)
    it('labelled as megabytes', r[4].unit, 'MB')
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  limits_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''

local text = table.concat(out, '\n')
if rawget(_G, 'core') then
    print(text)
else
    io.write(text)
    os.exit(fail == 0 and 0 or 1)
end

return {passed = pass, failed = fail}
