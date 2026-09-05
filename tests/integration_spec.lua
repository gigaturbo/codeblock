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
        -- The real record carries one from the moment it is made, because
        -- placement() falls back to nothing further. (F1)
        default_block = 'grey',
        -- The real budget for that codelevel, as lib/drone.lua builds it: the
        -- counters and every ceiling the commands check live in here now.
        budget = codeblock.limits.new(codeblock.config, al,
                                      core.get_us_time())
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
        colors = envlib.snapshot({grey = 'grey', white = 'white'})
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
    local ok = run('colors.grey = "tampered"\n')
    it('mutating the block table is allowed within the run', ok, true)
    it('but the real config is untouched',
       codeblock.config.allowed_blocks.by_name.colors.spelled.grey, 'grey')
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
-- The entity holds the owner's *name* and a serial, never the record: a cached
-- table is what B11 was, and what made teardown depend on two files agreeing.
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

    -- The unsaved marker (F7). What is checked here is the one thing that can
    -- go wrong silently: the asterisk being decoration and nothing else. It
    -- must appear in the drawn label and must never reach meta.tabs, which is
    -- the name write_file, read_file and remove_file are handed - a name with a
    -- star in it creates a file called foo.lua*. Whether a player can see the
    -- mark is a playtest (E16); that the string carries it is testable here.
    local ed_meta = {
        name = 'codeblock_spec_player',
        tabs = {'one.lua', 'two.lua'},
        contents = {'a', 'b'},
        dirty = {false, true},
        active = 1,
        help = 'cubes',
        scroll_c = 0,
        scroll_p = 0,
        scroll_w = 0,
        default_block = 'grey',
        picking = false,
        soe = false,
        loe = false,
        sos = false,
        newfile = ''
    }
    local labels = codeblock.formspecs.file_editor.get_form(ed_meta):match(
                       'tabheader%[0,0;tabs;([^;]*);')
    it('a clean tab is drawn under its own name', labels, 'one.lua,two.lua*')
    it('and the marker never reaches the name a file is written under',
       table.concat(ed_meta.tabs, ','), 'one.lua,two.lua')

    -- Directly on the prototype, not behind a metatable of this mod's own:
    -- register_entity makes the definition the luaentity's metatable with
    -- __index pointing at itself. (A6)
    it('the entity is told when it goes away',
       type(rawget(entity, 'on_deactivate')), 'function')
    it('and is told its owner on activation',
       type(rawget(entity, 'on_activate')), 'function')
    it('the entity caches no drone', rawget(entity, '_data'), nil)

    -- The object is a view and drives nothing. An entity with
    -- static_save = false is deleted the moment its mapblock leaves server
    -- memory, so a program advanced from here would end with the view of it.
    -- (B50, B52)
    it('and the entity does not advance the program',
       rawget(entity, 'on_step'), nil)

    -- ObjectRef:remove() takes effect at the end of the step, so the entity of
    -- a drone that has been replaced fires on_deactivate once the new drone is
    -- already installed under the same name. It is told which drone it belongs
    -- to and must leave any other alone - without the guard, replacing a drone
    -- would blank the new one's object and leave it invisible. (B29)
    --
    -- A serial rather than the ObjectRef, because nothing in the engine's
    -- documentation says the same object yields the same userdata twice.
    --
    -- obj carries a placeholder rather than being left unset, for two reasons:
    -- it is what tells 'left alone' from 'cleared' below, and Drone.on_step
    -- hands any record with no object to get_node_or_nil with its own x/y/z,
    -- which this fake does not have.
    local spec_player = '!spec_player'
    local spec_obj = {}
    Drone.instances[spec_player] =
        {name = spec_player, serial = '2', obj = spec_obj}

    Drone.on_lost(spec_player, '1')
    it('a replaced drone does not blank the object of the one that replaced it',
       Drone.instances[spec_player].obj, spec_obj)

    -- Losing the object is losing the view and nothing else: the run carries on
    -- unseen and on_step gives the drone another one once its block is back.
    -- Nothing is announced and nothing is torn down, including for a drone with
    -- no coroutine. (B30, B52)
    Drone.on_lost(spec_player, '2')
    it('and its own object going leaves the record standing',
       Drone.instances[spec_player] ~= nil, true)
    it('with nothing to be seen by until it is spawned again',
       Drone.instances[spec_player].obj, nil)

    -- One pass over every record per server step, taking only dtime: the drone
    -- is no longer stepped per entity, so nothing about the signature or the
    -- pass can be inferred from the entity any more. pcall because a change to
    -- either would otherwise take the rest of the file with it.
    --
    -- The object is restored first: with none, the pass would look the fake's
    -- position up in a map that does not exist yet at mod load.
    Drone.instances[spec_player].obj = spec_obj
    it('the whole set of drones is advanced in one pass, from dtime alone',
       pcall(Drone.on_step, 0), true)

    -- Nothing to advance, so nothing to end. A drone waiting for a program must
    -- survive a step it takes no part in.
    it('and a drone that is not running is left where it is',
       Drone.instances[spec_player] ~= nil, true)

    Drone.instances[spec_player] = nil
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
       moves(5, 4, core.get_us_time() + 1e9), 0)

    -- A paced drone says when it wants to run again, and the stepper leaves it
    -- alone until then. 300ms at codelevel 1.
    local _, paced = moves(1, 1)
    it('and sets a wake-up time', (paced.wake_at ~= nil and paced.wake_at >
        core.get_us_time()), true)
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
-- sleep (F3)
--
-- A wait costs no CPU, so what bounds it is the charge: without one, a program
-- could hold a drone, an entity and a slot in the shared pool for ever, which
-- is the hole max_runtime_s exists to close. So the assertion that matters is
-- that the wait is charged, up front, and that going over the ceiling leaves
-- the counter past it - that is what makes lib/stepper.lua report a timeout.
--------------------------------------------------------------------------------

do
    local sleep = codeblock.cost.sleep

    --- Sleep once inside a coroutine, as a run would. Returns the drone.
    local function slept(seconds, auth_level)
        local drone = stub_drone(auth_level)
        local co = coroutine.create(function() sleep(drone, seconds) end)
        coroutine.resume(co)
        return drone, coroutine.status(co)
    end

    local drone, status = slept(2)
    it('a sleep yields rather than blocking the step', status, 'suspended')
    it('and charges the run for the whole wait', (drone.budget.used.runtime >=
        2e6), true)
    it('and asks to be run again later',
       (drone.wake_at ~= nil and drone.wake_at > core.get_us_time()), true)
    it('which the stepper honours', codeblock.stepper.awake(drone), false)

    -- Not a command: drone.commands feeds the completion line, and a wait
    -- placed nothing.
    it('a sleep is not counted as a command', drone.commands, 0)

    -- Coerced with a default rather than raising, as steps() does for a
    -- distance.
    it('no argument means one second', (slept().budget.used.runtime >= 1e6),
       true)
    it('so does a nonsense one', (slept('soon').budget.used.runtime >= 1e6),
       true)
    it('and so does a negative one', (slept(-5).budget.used.runtime >= 1e6),
       true)

    -- The whole point: an unbounded wait is refused by the runtime ceiling,
    -- not by a clamp. Charged up front, so the counter is already past the cap
    -- before the drone goes to sleep at all.
    local huge = slept(1e9, 4)
    it('a wait longer than the run may live goes over the ceiling',
       (huge.budget.used.runtime > huge.budget.caps.runtime), true)
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
            return math.floor(self.dir / half_pi + .5) % 4
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

    -- Turning has to leave dir somewhere the rotation table can be indexed by,
    -- however many quarters were asked for. Adding radians and wrapping did
    -- not: turn(1000) left dir a hair under 2*pi, the wrap did not happen and
    -- the index came out 4, which is no row at all. (B27)
    local function facing_after(quarters)
        local drone = at(0)
        cmd.drone_turn(drone, quarters)
        return drone:angle()
    end

    it('one turn faces a quarter round', facing_after(1), 1)
    it('four come back to the start', facing_after(4), 0)
    it('an awkward count still lands on a quarter', facing_after(11), 3)
    it('and a thousand of them', facing_after(1000), 0)
    it('and a count far past what a float can step through',
       facing_after(12345678901), 1)
    it('turning the other way wraps round', facing_after(-1), 3)
    it('and keeps wrapping', facing_after(-7), 1)

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
-- the default block (F1)
--
-- default_block() touches nothing but the drone record, which is the only
-- reason it is reachable here: place() and the shapes write to the map, and
-- these specs run at mod load, before there is one. So what is pinned is the
-- field every placement resolves through, not a node in the world. The panel
-- that sets the player's saved preference, and whether that survives a relog,
-- are in PLAYTEST.md.
--------------------------------------------------------------------------------

do
    local set_default = codeblock.commands.drone_set_default_block

    local drone = stub_drone(4)

    set_default(drone, 'red')
    it('default_block sets what a bare place() will use', drone.default_block,
       'red')

    -- A glass and a lamp too, not just a solid colour: the categories share one
    -- flat namespace, so a name from any of them is legal here exactly as it is
    -- in place(block).
    set_default(drone, 'red_glass')
    it('default_block takes a glass', drone.default_block, 'red_glass')
    set_default(drone, 'red_lamp')
    it('default_block takes a lamp', drone.default_block, 'red_lamp')

    -- air is allowed on purpose: it is already a legal argument to place(), so
    -- excluding it only from the default would be an inconsistency with
    -- nothing behind it. A bare place() can therefore erase.
    set_default(drone, 'air')
    it('default_block takes air', drone.default_block, 'air')

    local ok, err = pcall(set_default, drone, 'not_a_block')
    it('default_block rejects a name no program may place', ok, false)
    it('and says so rather than failing silently',
       type(err) == 'string' and err:find('block') ~= nil, true)
    it('a rejected name leaves the default alone', drone.default_block, 'air')

    -- Charged like every other command, so a loop of them cannot run free.
    local before = stub_drone(4)
    local commands = before.commands
    set_default(before, 'grey')
    it('default_block is charged as a command', before.commands, commands + 1)
end

--------------------------------------------------------------------------------
-- the block palette, and the nodes it registers (F11)
--
-- The mod registers its own blocks now, so whether `place(name)` lands on a
-- real node is this mod's problem and no longer the host game's. Nothing else
-- in the suite reaches a registered node - but lib/nodes.lua has run by the
-- time a spec does, so core.registered_nodes is the one piece of a world that
-- exists here. What a block looks like, drops, or sounds like is a PLAYTEST
-- matter; that every name a program may write resolves to a definition is not.
--
-- The two counts below are the shape F11 settled on: 33 colours, of which the
-- first six are neutral. Changing the palette deliberately means changing them
-- here and re-running gen_docs, which is the point of pinning them.
--------------------------------------------------------------------------------

do
    local palette = codeblock.config.palette
    local blocks = codeblock.config.allowed_blocks

    it('the palette has 33 colours', #palette, 33)

    local badhex = {}
    for _, e in ipairs(palette) do
        if not (type(e[2]) == 'string' and e[2]:match('^#%x%x%x%x%x%x$')) then
            badhex[#badhex + 1] = tostring(e[1])
        end
    end
    it('every colour carries a six-digit hex', table.concat(badhex, ', '), '')

    -- color(v, min, max) maps a number onto hues, so its order has to be the
    -- palette's own and not sorted, or a gradient stops reading as a rainbow.
    it('hues drops the six neutrals', #palette - #blocks.hues, 6)
    local tail = {}
    for i = #palette - #blocks.hues + 1, #palette do
        tail[#tail + 1] = palette[i][1]
    end
    it('hues is the palette tail, in palette order',
       table.concat(blocks.hues, ','), table.concat(tail, ','))

    -- place() takes one string and knows nothing about which category it came
    -- from, so a collision between two categories would silently shadow one.
    local flat = 0
    for _ in pairs(blocks.all) do flat = flat + 1 end
    it('the flat namespace holds three per colour plus air', flat,
       #palette * 3 + 1)

    it('there are three categories', #blocks.categories, 3)

    local shortfall = {}
    for _, cat in ipairs(blocks.categories) do
        if #cat.names ~= #palette then shortfall[#shortfall + 1] = cat.name end
    end
    it('every category spells every colour', table.concat(shortfall, ', '), '')

    local unresolved = {}
    for _, cat in ipairs(blocks.categories) do
        for _, name in ipairs(cat.names) do
            local key = cat.spelled[name]
            if not (key and blocks.all[key]) then
                unresolved[#unresolved + 1] = cat.name .. '.' .. tostring(name)
            end
        end
    end
    it('every spelled name resolves through the flat namespace',
       table.concat(unresolved, ', '), '')

    -- The whole of F11 in one line: a name a program may write that the engine
    -- does not know is a write that silently does nothing, far from anyone
    -- watching. air is in here too, and is engine-provided.
    local missing = {}
    for _, item in pairs(blocks.all) do
        if not core.registered_nodes[item] then
            missing[#missing + 1] = item
        end
    end
    it('every block a program may place is a registered node',
       table.concat(missing, ', '), '')

    -- One per variant. A copy-paste in lib/nodes.lua's variant table would
    -- register a solid block under a glass name, and nothing else would say so.
    it('a glass block is see-through',
       core.registered_nodes['codeblock:red_glass'].drawtype, 'glasslike')
    it('a lamp emits light',
       (core.registered_nodes['codeblock:red_lamp'].light_source or 0) > 0, true)
    it('a solid block emits none',
       (core.registered_nodes['codeblock:red'].light_source or 0), 0)
end

--------------------------------------------------------------------------------
-- a game registering a block category of its own (F11)
--
-- codeblock.blocks.install is driven directly rather than through
-- codeblock.register_blocks, because the queue that function feeds is emptied
-- at register_on_mods_loaded and this spec runs at mod load, before that. Given
-- a batch it returns what it installed and one line per rule broken, which is
-- what makes a refusal assertable at all: the mod logs those lines and drops
-- them, so nothing else here could see one.
--
-- The refusals are the valuable half. Each is a rule the decision named, and a
-- game hitting one has to be told which by name - that is the whole reason for
-- validating rather than trusting outright.
--------------------------------------------------------------------------------

do
    local blocks = codeblock.config.allowed_blocks

    --- Install one request from a fictional mod. Returns the refusal text, or
    -- '' when it was accepted, so a case asserts on what a game would read.
    local function refusal(category, entries)
        local installed, refusals = codeblock.blocks.install({
            {mod = 'agame', category = category, entries = entries}
        })
        if installed > 0 then return '' end
        return table.concat(refusals, ' | ')
    end

    local function refused_for(category, entries, what)
        local why = refusal(category, entries)
        return (why:find(what, 1, true) ~= nil) and why ~= ''
    end

    it('a category name that is not an identifier is refused',
       refused_for('2wool', {red = 'codeblock:red'}, 'Lua identifier'), true)

    it('a category name that is a Lua keyword is refused',
       refused_for('end', {red = 'codeblock:red'}, 'Lua identifier'), true)

    it('a category colliding with one of ours is refused',
       refused_for('colors', {red = 'codeblock:red'}, 'already taken'), true)

    -- Not a category, but a name the environment already holds: a table called
    -- `color` would shadow the function that maps a number onto the hues.
    it('a category colliding with any API name is refused',
       refused_for('color', {red = 'codeblock:red'}, 'already taken'), true)

    it('a block naming an unregistered node is refused',
       refused_for('agame', {red = 'nosuch:node'}, 'no mod has registered'),
       true)

    it('a block name that is not an identifier is refused',
       refused_for('agame', {['a b'] = 'codeblock:red'}, 'table key'), true)

    it('a category with nothing placeable in it is refused',
       refused_for('agame', {}, 'nothing that can be placed'), true)

    it('a refusal names the mod that caused it',
       refusal('2wool', {red = 'codeblock:red'}):sub(1, 11), 'mod agame: ')

    -- The happy path, installed for real: everything below reads the palette
    -- the mod is actually running on, which is the only way to prove the seam
    -- carries a game's category rather than merely accepting one.
    local before = #blocks.categories
    local installed = codeblock.blocks.install({
        {
            mod = 'agame',
            category = 'agame',
            entries = {
                mud = 'codeblock:brown',
                -- Refused on its own, and must not cost the category the rest:
                -- one typo is not worth a game's whole palette.
                broken = 'nosuch:node'
            }
        }
    })

    it('a valid category installs', installed, 1)
    it('one bad entry does not cost the category the good ones',
       #blocks.categories - before, 1)

    -- Defaulted so the two cases below report rather than abort the spec when
    -- the one above has already failed: one reason to fail per case.
    local category = blocks.by_name.agame or {names = {}, spelled = {}}
    it('the category is reachable by name', blocks.by_name.agame ~= nil, true)
    it('it holds only the entries that passed', #category.names, 1)
    it('the flat key carries the category, so it cannot shadow ours',
       category.spelled.mud, 'agame.mud')
    it('the flat key resolves to the node the game named',
       blocks.all['agame.mud'], 'codeblock:brown')
    -- First registrant wins, so get_block() still answers colors.brown for the
    -- node the mod registered itself.
    it('a node the mod already owns keeps its own name',
       blocks.by_node['codeblock:brown'], 'brown')

    local picked = false
    for _, entry in ipairs(blocks.pickable) do
        if entry.key == 'agame.mud' then picked = true end
    end
    it('the block picker offers it', picked, true)

    local described = false
    for _, name in ipairs(codeblock.api.names()) do
        if name == 'agame' then described = true end
    end
    it('lib/api.lua describes it, so the sandbox may implement it', described,
       true)

    it('the in-game help lists it',
       codeblock.api.to_hypertext():find('agame', 1, true) ~= nil, true)

    it('the reference renders it as a category',
       codeblock.api.to_markdown(blocks):find('## `agame`', 1, true) ~= nil,
       true)

    it('registering the same name twice is refused',
       refused_for('agame', {mud = 'codeblock:brown'}, 'already taken'), true)

    ----------------------------------------------------------------------------
    -- the editor's category selector
    --
    -- get_form is a pure function of the meta table, so the drawn string is
    -- assertable here even though nothing about clicking it is. What these
    -- cases hold in place is the decision: one layout, a Blocks button and a
    -- selector, the same row whether a game registered a category or not - a
    -- row that only appears once some game registers something is a row nobody
    -- plays. Whether the two line up on screen is a playtest.
    ----------------------------------------------------------------------------

    local function help_row(help, chosen, picking)
        return codeblock.formspecs.file_editor.get_form({
            name = 'codeblock_spec_player',
            tabs = {},
            contents = {},
            dirty = {},
            active = 0,
            help = help,
            category = chosen,
            scroll = {},
            default_block = 'grey',
            picking = picking or false,
            soe = false,
            loe = false,
            sos = false,
            newfile = ''
        })
    end

    local selector = 'dropdown%[[^%]]-;help_pick;([^;]*);(%d+)%]'
    -- Over the API panel, where meta.help names no category at all.
    local items, index = help_row('commands', 'colors'):match(selector)

    it('the selector is drawn over a panel that is not a block panel',
       items ~= nil, true)
    it('it shows the category that is selected, not the panel that is open',
       index, '1')
    -- The discriminating pair. The case above cannot tell meta.category from
    -- meta.help on its own: 'commands' names no category, so drawing from
    -- meta.help would leave the index at its default of 1 and the assertion
    -- would still pass. These two disagree with each other, so only reading
    -- meta.category satisfies both.
    it('the selector follows the choice when a block panel names another',
       select(2, help_row('agame', 'colors'):match(selector)), '1')
    it('and follows it over a panel that names no category at all',
       select(2, help_row('commands', 'agame'):match(selector)),
       tostring(#blocks.categories))
    it("it labels the mod's own categories in the player's language",
       (items or ''):find(codeblock.S('Colors'), 1, true) ~= nil, true)
    it("and a game's by the raw name a program types",
       (items or ''):find('agame', 1, true) ~= nil, true)
    local _, separators = (items or ''):gsub(',', '')
    it('it offers every category', separators + 1, #blocks.categories)

    -- The count is the point: three help buttons whatever the palette holds.
    -- A row with one button per category is what this replaced, and it is the
    -- shape that grows off the edge of the form once a game registers one.
    local _, buttons = help_row('commands', 'colors'):gsub('button%[[^%]]-;help_',
                                                           '')
    it('the row keeps a fixed number of buttons as the palette grows', buttons,
       3)

    -- The panel itself, and not only the selector above it. The help panel
    -- looks a category up by name, and a table of them copied at load time
    -- makes that lookup simply false: a game's category then selects a panel
    -- that draws nothing and raises nothing. (F11)
    it("a game's block panel lists its blocks",
       help_row('agame', 'agame'):find('agame.mud]', 1, true) ~= nil, true)

    -- Drawn, and not merely held by the config. lib/formspecs.lua reads the
    -- palette for the block picker too, and a list copied there at load time
    -- would offer the mod's own blocks and nothing a game added - which the
    -- case above cannot see, because it reads the config's own table. (F11)
    it('the block picker draws it',
       help_row('settings', 'colors', true):find('agame.mud', 1, true) ~= nil,
       true)

    local _, selected = help_row('agame', 'agame'):match(selector)
    it("the selector follows a game's category too", selected,
       tostring(#blocks.categories))

    -- The one rule that cannot be reached through the public function from
    -- here: the suite runs at mod load, where the queue is still open. The flag
    -- is on the module so this case exists at all.
    codeblock.blocks.sealed = true
    it('a call after every mod has loaded is refused',
       codeblock.register_blocks('late', {mud = 'codeblock:brown'}), false)
    codeblock.blocks.sealed = false

    ----------------------------------------------------------------------------
    -- what the editor does with the value the selector sends back
    --
    -- A dropdown is in the field table on every submit, like a scrollbar and
    -- unlike a button, so the handler has to decide from the value alone
    -- whether the player moved it. Two properties carry that, and they fail in
    -- opposite directions:
    --
    --   * a value is a choice only when it *matches* a category's label. A
    --     guard reading "differs from what it was drawn with" would call every
    --     submit a choice the moment a client ever answered with displayed
    --     rather than stored text.
    --   * the branch is last in the chain, below quit. So even a value that
    --     does match loses to whatever else the player did, and what goes
    --     wrong is the panel rather than the save. (B37)
    --
    -- on_close is driven directly with a fake player and no live form session.
    -- update() therefore reaches forms.update, which finds no session and
    -- sends nothing, and save_editor_state looks the name up and gets nil, so
    -- no player meta is written. get_form still runs, which lists the player's
    -- directory - a read of a path that does not exist. Nothing here writes.
    ----------------------------------------------------------------------------

    local function submit(fields)
        local meta = {
            name = 'codeblock_spec_player',
            tabs = {},
            contents = {},
            dirty = {},
            active = 0,
            help = 'commands',
            category = 'colors',
            scroll = {},
            default_block = 'grey',
            picking = false,
            soe = false,
            loe = false,
            sos = false,
            newfile = ''
        }
        codeblock.formspecs.file_editor.on_close(meta, {
            get_player_name = function() return 'codeblock_spec_player' end
        }, fields)
        return meta
    end

    -- The wire value for a category the mod owns. S() returns a translation
    -- escape, so this is what the engine round-trips and not the word a French
    -- client shows - which is what the next three cases send instead.
    local glass_label = codeblock.S('Glass')

    it('a matched value opens that category', submit({help_pick = glass_label})
           .help, 'glass')
    it('and is remembered as the choice',
       submit({help_pick = glass_label}).category, 'glass')

    -- The three below pin the fail-safe direction rather than catching a
    -- regression that has happened: the guard has required a match since it was
    -- written, so they pass against the previous chain too. They fail against a
    -- guard simplified to "differs from the label it was drawn with".
    it('a value matching no label opens no panel',
       submit({help_pick = 'Couleurs'}).help, 'commands')
    it('and leaves the remembered choice alone',
       submit({help_pick = 'Couleurs'}).category, 'colors')
    it('and does not consume the event it arrived with',
       submit({help_pick = 'Couleurs', help_settings = 'x'}).help, 'settings')

    -- The other half of the same guard, and the one an always-sent field makes
    -- necessary: the selector reports the item it was drawn with on every
    -- submit, so that value is a resend and not a choice. Without this the
    -- block panel would open under any submit no branch above claimed.
    it('the value the selector was drawn with reads as a resend',
       submit({help_pick = codeblock.S('Colors')}).help, 'commands')

    -- Ordering. Both cases send a value that does match, so neither can pass
    -- by the guard failing to fire - the first two cases above are what proves
    -- it fires. Against the chain that had this branch above quit, both fail.
    it('a matched value loses to the event it arrived with',
       submit({help_pick = glass_label, quit = 'true'}).help, 'commands')
    -- The same, with a winner whose effect is visible: it is not only that the
    -- selector lost, it is that the other event ran.
    it('and the event it lost to is the one that runs',
       submit({help_pick = glass_label, help_settings = 'x'}).help, 'settings')
    -- The choice is still recorded on that submit, so pressing Blocks later
    -- opens the category the player picked. Losing the event does not mean
    -- forgetting it.
    it('a choice that lost its submit is still remembered',
       submit({help_pick = glass_label, quit = 'true'}).category, 'glass')

    ----------------------------------------------------------------------------
    -- no two categories share a label
    --
    -- Last in this block on purpose: it installs a category, so it changes the
    -- palette every case above counts.
    --
    -- Why this is worth a case. The selector sends the item's *text* back, and
    -- the handler decides whether the player moved it by comparing that text
    -- against the label the selector was drawn with, so two categories under
    -- one label are two the handler cannot tell apart and one of them becomes
    -- unreachable. `glass` is taken and `Glass` is not, and the English for
    -- S('Glass') is the word itself - which reads like a collision waiting to
    -- happen and is not one, because S() returns a translation escape
    -- (\27(T@codeblock)Glass\27(E)) and a raw category name never contains one.
    -- The engine round-trips it exactly: parseDropDown stores
    -- unescape_string(item) and acceptInput sends that, not the displayed text
    -- (guiFormSpecMenu.cpp 1447 and 4319).
    --
    -- So this holds the escape in place. Labelling the mod's own three with
    -- plain words would create the collision the moment a game picked one of
    -- them, and nothing else here would notice.
    ----------------------------------------------------------------------------

    it('a category differing from one of ours only in case is accepted',
       codeblock.blocks.install({
        {mod = 'agame', category = 'Glass', entries = {pane = 'codeblock:brown'}}
    }), 1)

    local seen, duplicate = {}, nil
    for item in (help_row('commands', 'colors'):match(selector) or ''):gmatch(
                    '[^,]+') do
        if seen[item] then duplicate = item end
        seen[item] = true
    end
    it('no two categories are drawn under the same label', duplicate, nil)
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
