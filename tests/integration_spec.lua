--- End-to-end test of the program pipeline, in-engine only.
--
-- The other specs test lib/preprocess.lua and lib/env.lua in isolation, which
-- says nothing about whether they are wired together correctly. This one runs a
-- player program through the real path - forbidden-name check, real
-- instrumentation, real environment construction, real budget counter from
-- lib/commands.lua - inside a real coroutine, and checks it behaves.
--
-- It needs codeblock.commands, so it is skipped under a bare interpreter rather
-- than duplicating the mod's setup.

if not (rawget(_G, 'codeblock') and codeblock.commands) then
    io.write('\n  integration_spec\n  skipped (needs the mod loaded)\n\n')
    return {skipped = true}
end

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
-- a stub drone, carrying only what the budget counter touches
--------------------------------------------------------------------------------

local function stub_drone(auth_level)
    local al = auth_level or 4
    return {
        name = 'test_player',
        file = 'spec.lua',
        auth_level = al,
        calls = 0,
        commands = 0,
        checkpoints = {},
        -- The real budget for that codelevel, as lib/drone.lua builds it: the
        -- counters and every ceiling the commands check live in here now.
        budget = codeblock.limits.new(codeblock.config, al,
                                      minetest.get_us_time())
    }
end

--- Run `src` through the real pipeline. Returns ok, drone, yields, err.
local function run(src, auth_level)

    local drone = stub_drone(auth_level)

    local bad = preprocess.find_forbidden(src)
    if bad then return false, drone, 0, 'forbidden: ' .. bad end

    local chunk, msg = loadstring(preprocess.preprocess_code(src))
    if not chunk then return false, drone, 0, 'compile: ' .. tostring(msg) end

    -- Built the same way lib/sandbox.lua builds it.
    local api = {
        print = function() end,
        error = error,
        ipairs = ipairs,
        pairs = pairs,
        floor = math.floor,
        -- stand-ins for the drone commands, so the read-only checks below have
        -- a real API name to attack
        place = function() end,
        up = function() end,
        blocks = envlib.snapshot({stone = 'stone', air = 'air'})
    }
    api._G = envlib.seal({
        print = api.print,
        error = api.error,
        use_call = function() use_call(drone) end
    }, '_G')

    setfenv(chunk, envlib.new_env(api))

    local co = coroutine.create(chunk)
    local yields = 0
    while true do
        local ok, err = coroutine.resume(co)
        if not ok then return false, drone, yields, tostring(err) end
        if coroutine.status(co) == 'dead' then break end
        yields = yields + 1
        if yields > 10000 then return false, drone, yields, 'runaway' end
    end
    return true, drone, yields, nil
end

--------------------------------------------------------------------------------
-- the pipeline works end to end
--------------------------------------------------------------------------------

do
    local ok, drone = run('local x = 0\nfor i = 1, 5 do x = x + 1 end\n')
    it('a bounded loop completes', ok, true)
    it('the real counter charged once per iteration', drone.calls, 5)
end

do
    local ok, drone = run('local x = 1 + 2\n')
    it('a loop-free program completes', ok, true)
    it('a loop-free program is charged nothing', drone.calls, 0)
end

do
    -- The counter yields periodically so the drone gives time back to the
    -- engine. Every few hundred calls at every codelevel, so 1500 iterations
    -- must have yielded at least twice.
    local ok, _, yields = run('for i = 1, 1500 do end\n', 4)
    it('a long loop completes', ok, true)
    it('a long loop yields back to the engine', (yields >= 2), true)
end

do
    -- repeat/until was refused outright before Phase 2.
    local ok, drone = run('local i = 0\nrepeat i = i + 1 until i >= 4\n')
    it('repeat/until runs', ok, true)
    it('repeat/until is charged per iteration', (drone.calls >= 4), true)
end

do
    local ok, drone = run(
                          'function add(a, b) return a + b end\nlocal s = add(1, 2)\n')
    it('a function definition and call runs', ok, true)
    it('the function body is charged', (drone.calls >= 1), true)
end

--------------------------------------------------------------------------------
-- comments and strings survive the real pipeline (B1-B3)
--------------------------------------------------------------------------------

do
    local ok = run('--[[ a --]]\nlocal x = 1\n--[[ b --]]\nlocal y = 2\n')
    it('B1 two block comments no longer delete the code between them', ok, true)
end

do
    local ok = run('--[[\nprose\n]]\nlocal x = 1\n')
    it('B2 a standard block comment runs', ok, true)
end

do
    local ok = run('local s = "a -- b"\n')
    it('B3 a string containing a double dash runs', ok, true)
end

do
    local ok = run('local nfunctions = 3\nlocal x = math_missing\n')
    it('B4 an identifier containing "function" runs', ok, true)
end

--------------------------------------------------------------------------------
-- the environment holds under attack
--------------------------------------------------------------------------------

do
    local ok, _, _, err = run('place = function() end\n')
    it('reassigning an API name is refused', ok, false)
    it('and says why', (err and err:find('cannot be reassigned', 1, true) ~= nil),
       true)
end

do
    local ok, _, _, err = run('_G.use_call = function() end\n')
    -- _G is still on the forbidden list; either rejection is a pass, but the
    -- seal is what makes it safe to relax that later.
    it('disabling the budget counter is refused', ok, false)
    it('the refusal is reported', (err ~= nil), true)
end

do
    -- S1: a program must not be able to corrupt shared config for everyone.
    local ok = run('blocks.stone = "tampered"\n')
    it('mutating the block table is allowed within the run', ok, true)
    it('but the real config is untouched',
       codeblock.config.allowed_blocks.cubes.stone, 'stone')
end

do
    local ok = run('my_helper = function() return 1 end\nlocal v = my_helper()\n')
    it('a player global still works', ok, true)
end

--------------------------------------------------------------------------------
-- the shapes are this mod's own, and WorldEdit is gone
--
-- The four shapes moved into lib/shapes.lua (A15), which is what let the
-- vendored fork be deleted. tests/shapes_spec.lua checks the geometry; this
-- checks that the mod is wired to its own implementation and no longer reaches
-- for a global that is no longer there.
--------------------------------------------------------------------------------

do
    it('shapes.build is available', type(codeblock.shapes and
                                             codeblock.shapes.build), 'function')
    it('nothing provides a worldedit global', rawget(_G, 'worldedit'), nil)
end

--------------------------------------------------------------------------------
-- the drone seam (A11)
--
-- Nothing here can place a drone: the specs run at mod load, before a map
-- exists, so add_entity and everything downstream of it is unreachable. What is
-- reachable is the shape of the seam, and that is worth pinning, because every
-- name across it is looked up by string at load time and a rename would go
-- unnoticed until a player clicked something.
--
-- The entity holds the owner's *name*, never the record: a cached table is what
-- B11 was, and what made teardown depend on two files agreeing.
--------------------------------------------------------------------------------

do
    local Drone = codeblock.Drone
    local entity = codeblock.DroneEntity

    local missing = {}
    for _, name in ipairs({
        'new', 'get', 'set', 'remove', 'on_place', 'on_run', 'on_remove',
        'on_step', 'on_lost', 'finish', 'set_file'
    }) do
        if type(Drone[name]) ~= 'function' then missing[#missing + 1] = name end
    end
    it('the drone record owns state, lifecycle and completion',
       table.concat(missing, ','), '')

    -- Bound as locals in lib/register.lua, so a wrong name is nil there and
    -- raises only when the tool is used.
    it('the editor is opened through the form layer',
       type(codeblock.formspecs.file_editor.show), 'function')
    it('so is the file chooser',
       type(codeblock.formspecs.file_chooser.show), 'function')
    it('and the drone no longer builds forms',
       Drone.show_file_editor_form or Drone.show_set_file_form, nil)

    -- Directly on the prototype, not behind a metatable of this mod's own:
    -- register_entity makes the definition the luaentity's metatable with
    -- __index pointing at itself. (A6)
    it('the entity defines its callbacks on the prototype',
       type(rawget(entity, 'on_step')), 'function')
    it('and is told its owner on activation',
       type(rawget(entity, 'on_activate')), 'function')
    it('the entity caches no drone', rawget(entity, '_data'), nil)
end

--------------------------------------------------------------------------------
-- the limits survive the settings layer (C7)
--
-- lib/config.lua now reads settingtypes.txt over its defaults, applying the
-- per-codelevel overrides in one loop rather than at each literal. A parser or
-- loop that mangled a table would do it at mod load, silently, so the shape of
-- every limit is asserted here with the real settings in effect.
--------------------------------------------------------------------------------

do
    local cfg = codeblock.config
    local names = {
        'pace_ms', 'step_budget_us', 'max_runtime_s', 'max_nodes_written',
        'map_memory_mb', 'heap_mb', 'max_string_mb'
    }
    local wrong = {}
    for _, name in ipairs(names) do
        local t = cfg[name]
        if type(t) ~= 'table' or #t ~= 4 then
            wrong[#wrong + 1] = name
        else
            for i = 1, 4 do
                if type(t[i]) ~= 'number' then wrong[#wrong + 1] = name end
            end
        end
    end
    it('every codelevel limit is four numbers', table.concat(wrong, ','), '')

    it('auth_levels was left alone by the override loop',
       table.concat(cfg.auth_levels, ','), '1,2,3,4')
    it('the default codelevel is a level that exists',
       (cfg.auth_levels[cfg.default_auth_level] ~= nil), true)
    it('the server step budget is a number', type(cfg.server_step_budget_us),
       'number')
    -- Read from the engine's own server_unload_unused_data_timeout, because the
    -- map footprint budget decays over exactly that window.
    it('the unload window is a number', type(cfg.map_window_s), 'number')

    -- The old names are gone rather than merely unused: a setting nothing reads
    -- looks like a limit in force. config.lua warns about each at load.
    local ghosts = {}
    for _, name in ipairs({
        'max_calls', 'max_volume', 'max_commands', 'max_distance',
        'max_dimension', 'max_mapblocks', 'max_memory_kb', 'max_string_bytes',
        'commands_before_yield', 'calls_before_yield'
    }) do if cfg[name] ~= nil then ghosts[#ghosts + 1] = name end end
    it('the limits the rewrite replaced are gone', table.concat(ghosts, ','), '')
end

--------------------------------------------------------------------------------
-- pacing, and the step deadline that cuts a resume short
--
-- What ends a command used to be a per-codelevel yield cadence; it is now the
-- pace, for the codelevels that have one, and otherwise the step deadline. Both
-- are asserted rather than assumed, because between them they are the whole
-- reason a runaway program cannot hold the server.
--
-- turn_left is used because it touches nothing but the drone record: place and
-- the shapes write to the map, and these specs run at mod load, before there is
-- a map.
--------------------------------------------------------------------------------

do
    local turn_left = codeblock.commands.drone_turn_left

    --- Runs `n` commands at `auth_level` with `deadline` set, and reports the
    -- yields and the drone.
    local function moves(n, auth_level, deadline)
        local drone = stub_drone(auth_level)
        drone.dir = 0
        drone.deadline = deadline
        drone.update_entity = function() end

        local co = coroutine.create(function()
            for _ = 1, n do turn_left(drone) end
        end)

        local yields = 0
        while coroutine.status(co) ~= 'dead' do
            local ok, err = coroutine.resume(co)
            if not ok then return nil, tostring(err) end
            if coroutine.status(co) ~= 'dead' then yields = yields + 1 end
        end
        return yields, drone
    end

    -- A paced codelevel yields on every command by construction: that is what
    -- makes the drone watchable, and it is why no yield count is needed.
    it('a paced codelevel yields on every command', moves(6, 1), 6)
    it('so does the second one', moves(6, 2), 6)

    -- An unpaced codelevel runs on until its slice of the step is gone.
    it('an unpaced codelevel does not yield on its own', moves(6, 3), 0)
    it('nor at the top codelevel', moves(6, 4), 0)

    -- A deadline already past: every command yields, which is what makes the
    -- step budget bound work rather than resumes.
    it('a spent deadline yields at codelevel 4', moves(5, 4, 1), 5)
    it('a deadline in the future changes nothing',
       moves(5, 4, minetest.get_us_time() + 1e9), 0)

    -- A paced drone says when it wants to run again, and the stepper leaves it
    -- alone until then. 300ms at codelevel 1.
    local _, paced = moves(1, 1)
    it('and sets a wake-up time', (paced.wake_at ~= nil and paced.wake_at >
        minetest.get_us_time()), true)
    it('which the stepper honours', codeblock.stepper.awake(paced), false)
    it('an unpaced drone sleeps not at all', select(2, moves(1, 4)).wake_at, nil)

    -- The mapblock memo cannot outlive a yield: the engine may unload the block
    -- while the drone is not running, and a stale memo would skip the load that
    -- had become necessary again and lose the write with no error. (A4)
    local drone = stub_drone(1)
    drone.dir, drone.update_entity = 0, function() end
    drone.bx, drone.by, drone.bz = 1, 2, 3
    coroutine.resume(coroutine.create(function() turn_left(drone) end))
    it('yielding drops the mapblock memo',
       (drone.bx == nil and drone.by == nil and drone.bz == nil), true)
end

--------------------------------------------------------------------------------
-- movement, in all four facings (A3)
--
-- The seven movement commands were seven copies of the same quarter-turn table,
-- one axis each; they are now one rotation applied to a drone-relative offset.
-- That is arithmetic with no map behind it, so unlike place() it is reachable
-- from here - and it is worth reaching, because nothing else would notice a
-- rotation row transcribed the wrong way round.
--
-- Codelevel 4 has no pace and no deadline is set, so no command yields and
-- these can be called outside a coroutine.
--------------------------------------------------------------------------------

do
    local cmd = codeblock.commands
    local half_pi = math.pi / 2

    --- A drone at the origin, facing `quarter` quarter-turns round.
    local function at(quarter)
        local drone = stub_drone(4)
        drone.x, drone.y, drone.z = 0, 0, 0
        drone.dir = quarter * half_pi
        drone.update_entity = function() end
        -- Mirrors the angle() method on the real record in lib/drone.lua.
        drone.angle = function(self)
            return (2 / math.pi) * (self.dir % (2 * math.pi))
        end
        return drone
    end

    --- Runs one command in each facing and reports the four end positions.
    local function each_facing(run)
        local out = {}
        for quarter = 0, 3 do
            local drone = at(quarter)
            run(drone)
            out[#out + 1] = ('%d,%d,%d'):format(drone.x, drone.y, drone.z)
        end
        return table.concat(out, ' ')
    end

    it('forward goes the way the drone faces',
       each_facing(function(d) cmd.drone_forward(d, 1) end),
       '0,0,1 -1,0,0 0,0,-1 1,0,0')
    it('back is its opposite', each_facing(function(d) cmd.drone_back(d, 1) end),
       '0,0,-1 1,0,0 0,0,1 -1,0,0')
    it('right is a quarter-turn from forward',
       each_facing(function(d) cmd.drone_right(d, 1) end),
       '1,0,0 0,0,1 -1,0,0 0,0,-1')
    it('left is its opposite', each_facing(function(d) cmd.drone_left(d, 1) end),
       '-1,0,0 0,0,-1 1,0,0 0,0,1')
    it('up ignores the facing', each_facing(function(d) cmd.drone_up(d, 2) end),
       '0,2,0 0,2,0 0,2,0 0,2,0')
    it('and so does down', each_facing(function(d) cmd.drone_down(d, 2) end),
       '0,-2,0 0,-2,0 0,-2,0 0,-2,0')

    -- move() takes all three at once, and rotates them together.
    it('move rotates the whole offset',
       each_facing(function(d) cmd.drone_move(d, 1, 2, 3) end),
       '1,2,3 -3,2,1 -1,2,-3 3,2,-1')

    -- Distances default to 1 for the one-axis moves and to 0 for move().
    it('a one-axis move defaults to one node',
       each_facing(function(d) cmd.drone_forward(d) end),
       '0,0,1 -1,0,0 0,0,-1 1,0,0')
    it('move defaults to standing still',
       each_facing(function(d) cmd.drone_move(d) end), '0,0,0 0,0,0 0,0,0 0,0,0')

    -- A negative distance is the opposite direction, not an error.
    it('back with a negative distance goes forward',
       each_facing(function(d) cmd.drone_back(d, -1) end),
       '0,0,1 -1,0,0 0,0,-1 1,0,0')

    -- Turning is counted in quarters; turn_left and turn_right are ±1.
    local turned = at(0)
    cmd.drone_turn_left(turned)
    it('turn_left is a quarter-turn', turned:angle(), 1)
    cmd.drone_turn_right(turned)
    cmd.drone_turn_right(turned)
    it('turn_right goes the other way', turned:angle(), 3)
    cmd.drone_turn(turned, 2)
    it('turn takes whole quarters and wraps', turned:angle(), 1)

    -- Every command counts, however it was spelled.
    it('the one-axis moves are counted like any other command', turned.commands,
       4)
end

--------------------------------------------------------------------------------
-- the budget itself
--
-- lib/limits.lua is tested on its own arithmetic in tests/limits_spec.lua. What
-- is checked here is that the real commands charge the real budget: a ceiling
-- nothing charges against is not a limit.
--------------------------------------------------------------------------------

do
    local turn_left = codeblock.commands.drone_turn_left
    local drone = stub_drone(4)
    drone.dir, drone.update_entity = 0, function() end

    it('a fresh run has spent nothing', drone.budget.used.nodes, 0)

    coroutine.resume(coroutine.create(function()
        for _ = 1, 3 do turn_left(drone) end
    end))
    it('commands are counted', drone.commands, 3)

    -- The caps arrive converted: seconds and megabytes in the config, but
    -- microseconds, kB and mapblocks where they are checked.
    local caps = drone.budget.caps
    it('the runtime cap is in microseconds', caps.runtime,
       codeblock.config.max_runtime_s[4] * 1e6)
    it('the map cap is in mapblocks', caps.map,
       codeblock.config.map_memory_mb[4] * 64)
    it('the heap cap is in kB', caps.heap_kb, codeblock.config.heap_mb[4] * 1024)
    it('the string cap is in bytes', caps.string_bytes,
       codeblock.config.max_string_mb[4] * 1024 * 1024)
end

--------------------------------------------------------------------------------
-- the string guards apply to real player code (S2)
--
-- strguard_spec checks the guards in isolation. This checks that a program
-- written by a player, running through the pipeline, actually hits them - and
-- that the guard is released afterwards, because one left armed would impose the
-- limit on every other mod on the server.
--------------------------------------------------------------------------------

do
    local strguard = codeblock.strguard

    strguard.enter(4096)
    local ok, _, _, err = run('local s = ("x"):rep(1e9)\n')
    strguard.leave()

    it('a program cannot allocate a gigabyte in one call', ok, false)
    it('and is told why',
       (err ~= nil and err:find('byte limit', 1, true) ~= nil), true)

    strguard.enter(4096)
    local ok2 = run('local s = ("x"):rep(100)\n')
    strguard.leave()
    it('a reasonable string still works', ok2, true)

    it('the guard is released after the run', strguard.is_active(), false)
    it('and normal string work is unaffected once released',
       #(('x'):rep(50000)), 50000)
end

--------------------------------------------------------------------------------
-- chat command argument parsing (B8, B9)
--
-- Both commands mishandled their optional player name: /codegenerate parsed one
-- and then ignored it, always acting on the caller, and /codelevel carried a
-- dead singleplayer branch. Parsing is where they went wrong, so it is tested.
--------------------------------------------------------------------------------

do
    local parse = codeblock.utils.parse_target

    local function both(caller, params, pat)
        local a, b = parse(caller, params, pat)
        return tostring(a) .. '|' .. tostring(b)
    end

    it('level only, addressed to the caller', both('bob', '3', '%d+'), 'bob|3')
    it('name and level', both('bob', 'alice 2', '%d+'), 'alice|2')
    it('tolerates surrounding space', both('bob', '  alice   2  ', '%d+'),
       'alice|2')
    it('rejects empty arguments', both('bob', '', '%d+'), 'nil|nil')
    it('rejects a name with no level', both('bob', 'alice', '%d+'), 'nil|nil')
    it('rejects a non-numeric level', both('bob', 'alice x', '%d+'), 'nil|nil')
    it('rejects trailing junk', both('bob', 'alice 2 3', '%d+'), 'nil|nil')
    it('accepts names with underscore and dash',
       both('bob', 'a_player-1 4', '%d+'), 'a_player-1|4')
    -- A digit-led token is a level, not a name: this is the case the old
    -- `([%w_-]*)%s*([%d]*)` pattern got wrong, since %w matches digits.
    it('does not read a bare number as a player name', both('bob', '4', '%d+'),
       'bob|4')
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  integration_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''
print(table.concat(out, '\n'))

return {passed = pass, failed = fail}
