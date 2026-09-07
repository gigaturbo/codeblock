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
-- get_block reads, and moves nothing
--
-- Only the outside-the-world branch is reachable from here, and that is not a
-- shortcoming of the spec. get_block loads the mapblock it reads, and the suite
-- runs at mod load: core.get_node then answers a node with no content id at
-- all, and builtin's own get_name_from_content_id raises on it. So a read
-- landing inside the world cannot be asked for here at any position, which is
-- worth knowing before anyone tries again - it is not that the answer is wrong,
-- it is that there is no map yet to be asked.
--
-- What the branch does reach is every part of the contract that is not the read
-- itself: the answer where there is no answer, the offsets being applied at
-- all, the command being charged, and the drone standing still. The three-way
-- answer over real map, and the offsets turning with the drone, are PLAYTEST
-- matters.
--------------------------------------------------------------------------------

do
    local get_block = codeblock.commands.drone_get_block
    local edge = tonumber(core.settings:get('mapgen_limit')) or 31000

    -- Facing +z, at the origin, and asked about somewhere past the world's
    -- edge. Deliberately far rather than at the boundary: what the boundary
    -- itself does is check_inside_world's, which lib/commands.lua shares
    -- between this and the write path.
    local drone = stub_drone(4)
    drone.x, drone.y, drone.z, drone.dir = 0, 0, 0, 0
    drone.angle = function() return 0 end

    local held = drone.budget.used.map
    local charged = drone.commands
    local ok, answer = pcall(get_block, drone, 0, 0, edge + 10)

    -- Not a raise. A question about somewhere that cannot exist is answered,
    -- not treated as an instruction the program got wrong - the write path
    -- raises at the same edge and this deliberately does not.
    it('a read outside the world does not raise', ok, true)
    -- nil and not false: false means a node no program can place, which is a
    -- different answer and one a program branches on differently.
    it('and answers nil rather than false', answer, nil)

    -- The same case proves the offsets are used at all: ignored, the read would
    -- have landed on the drone itself, which is inside the world.
    it('so the offset was applied, not dropped', ok and answer == nil, true)

    it('the drone did not move', ('%s,%s,%s'):format(drone.x, drone.y, drone.z),
       '0,0,0')
    it('and did not turn', drone.dir, 0)

    it('the read is charged as a command', drone.commands, charged + 1)
    -- Outside the world there is nothing to load, so nothing is held; the
    -- mapblock memo staying empty is the same fact read from the other side.
    it('and takes no map footprint', drone.budget.used.map, held)
    it('and loads no mapblock', drone.bx, nil)

    -- Each offset is optional, and a program that hands one something that is
    -- not a number gets zero rather than an arithmetic error out of a command
    -- that was only asked a question. Read from outside the world so the case
    -- needs no map: an offset that reached the addition unconverted would raise
    -- there just as surely.
    local adrift = stub_drone(4)
    adrift.x, adrift.y, adrift.z, adrift.dir = edge + 5, 0, 0, 0
    adrift.angle = function() return 0 end

    local ok2, answer2 = pcall(get_block, adrift, 'east', nil, {})
    it('a non-number offset does not raise', ok2, true)
    it('and reads as zero, so the answer is the drone position', answer2, nil)
end

--------------------------------------------------------------------------------
-- running a real player program, through the real environment
--
-- The two sections below - is_block, and the ramps - cover implementations that
-- live in a closure inside a local function in lib/sandbox.lua. The only door to
-- that function is get_safe_coroutine, which reads the program out of the
-- player's directory, so reaching either of them means writing one file. It goes
-- into the throwaway world the suite boots, under the stub drone's own name, and
-- is removed again at the end of the last section that uses it.
--
-- That write is not the thing the run-tests rule about a user directory
-- forbids. The rule is there to stop a spec passing vacuously over a world that
-- does not exist yet; these programs run the real forbidden-name check, the real
-- instrumenter, the real environment and the real command budget, and every
-- assertion built on them has been driven to fail. The two alternatives were
-- exporting the private environment factory to the spec - pinning the spec to an
-- implementation detail - and copying the code under test into the spec, which
-- would assert nothing about what ships. Do not delete the write.
--------------------------------------------------------------------------------

local sandbox_edge = tonumber(core.settings:get('mapgen_limit')) or 31000
local program_file = 'sandbox_spec_program.lua'

--- Runs `src` as a real player program, through the real environment.
-- Returns the drone, so the program's answer can be read off the record, and
-- whatever went wrong on the way, so a failure to run reads as one.
--
-- The drone stands outside the world on x, which is what makes every map read
-- answer nil with no map loaded. is_block needs that; the ramps read no map and
-- do not care either way.
local function sandboxed(src, at)

    local half_pi = math.pi / 2
    local drone = stub_drone(4)
    drone.x, drone.y, drone.z, drone.dir = sandbox_edge + 5, 0, 0, 0
    if at then drone.x, drone.y, drone.z = at.x, at.y, at.z end
    drone.update_entity = function() end
    drone.angle = function(self)
        return math.floor(self.dir / half_pi + .5) % 4
    end

    codeblock.filesystem.make_user_dir(drone.name)
    local werr = codeblock.filesystem.write_file(drone.name, program_file, src)
    if werr then return drone, tostring(werr) end

    local ok, co = codeblock.sandbox.get_safe_coroutine(drone, program_file)
    if not ok then return drone, tostring(co) end

    for _ = 1, 10000 do
        local alive, err = coroutine.resume(co)
        if not alive then return drone, tostring(err) end
        if coroutine.status(co) == 'dead' then return drone, nil end
    end
    return drone, 'runaway'
end

--------------------------------------------------------------------------------
-- is_block answers, and is charged, through the real environment
--
-- is_block is two lines of glue over the read above.
--
-- Every read below lands outside the world, for the reason the get_block section
-- gives: there is no map at mod load. So what is pinned here is the guard and
-- the accounting; the answer over real map is a PLAYTEST matter, with
-- get_block's.
--
-- Each program reports through turn_left, which touches nothing but the drone
-- record. Comparing against `false` rather than testing for truth is
-- deliberate: without the type guard is_block() answers true out here, and a
-- merely broken one answers nil - `== false` tells those apart and a bare `if`
-- would not.
--------------------------------------------------------------------------------

do
    local edge = sandbox_edge

    local named, err = sandboxed(
                           'if is_block(colors.grey) == false then turn_left() end\n')
    it('a program calling is_block runs at all', err, nil)
    it('a block that is not the one there answers false', named:angle(), 1)

    -- The guard. colors.typo is nil, and outside the world the read answers nil
    -- too, so without `type(block) == 'string'` this is nil == nil and the
    -- answer is true - a program asking about a misspelling would be told yes.
    local guarded = sandboxed('if is_block() == false then turn_left() end\n')
    it('no block named at all answers false, not true', guarded:angle(), 1)

    local numbered = sandboxed('if is_block(42) == false then turn_left() end\n')
    it('and a number answers false as well', numbered:angle(), 1)

    -- One call, one command, whatever the answer: the read runs before the
    -- guard, so what a question costs does not depend on what was asked.
    local control = sandboxed('local x = 1\n')
    it('a program with no command in it is charged none', control.commands, 0)

    local counted = sandboxed('is_block(colors.grey)\n')
    it('one is_block costs one command', counted.commands, 1)

    local rejected = sandboxed('is_block(42)\n')
    it('and costs the same when it was not handed a block at all',
       rejected.commands, 1)

    it('the read moves nothing',
       ('%s,%s,%s'):format(counted.x, counted.y, counted.z),
       ('%s,0,0'):format(edge + 5))
    it('and turns nothing', counted.dir, 0)
end

--------------------------------------------------------------------------------
-- print, through the real environment
--
-- print became variadic because F12-4's is_block returns a boolean and the
-- one-argument version dropped it: print("is: ", is_block(colors.red)) sent
-- "is: " and nothing more.
--
-- **What print sends is not observable from a spec, and no case below claims to
-- check it.** lib/commands.lua binds chat_send_player as a load-time local, so
-- replacing core.chat_send_player around a run intercepts nothing, and
-- lib/sandbox.lua binds drone_send_message the same way, so the other end is
-- shut too; the line goes to a player name nobody is logged in under. That was
-- driven to failure rather than assumed - a case capturing
-- core.chat_send_player around print('a', 'b') reads nil, not '> a b'. Whether
-- the joined line reads correctly in chat is a PLAYTEST matter, with
-- get_block's answers.
--
-- So what is pinned here is the one part of print a spec can see, and the part
-- a refactor could break in silence: **the charge**. One call is one command
-- however many arguments it carries, because the join happens in the sandbox
-- and drone_send_message is reached once. An implementation looping
-- send_message per argument passes every other case in this spec and fails
-- these.
--
-- Said plainly, because a case that cannot fail is indistinguishable from one
-- that passes (C20): **these would have been green before the fix as well.**
-- The old print took one parameter and ignored the rest without raising, so it
-- charged once too. They guard the new implementation; they do not witness the
-- defect.
--------------------------------------------------------------------------------

do
    local one, one_err = sandboxed('print("a")\n')
    it('a one-argument print runs', one_err, nil)
    it('and costs one command', one.commands, 1)

    local three, three_err = sandboxed('print("is: ", true, 42)\n')
    it('a three-argument print runs', three_err, nil)
    it('and still costs one command', three.commands, 1)

    -- The case select('#', ...) exists for, rather than `{...}` and `#`: a nil
    -- among the arguments is ordinary here, get_block answering nil for map
    -- that was never generated. It must neither stop the call nor change what
    -- it costs.
    local mid, mid_err = sandboxed('print("a", nil, "b")\n')
    it('a nil in the middle does not stop the call', mid_err, nil)
    it('and costs one command', mid.commands, 1)

    local tail, tail_err = sandboxed('print("a", nil)\n')
    it('a trailing nil does not stop the call', tail_err, nil)
    it('and it costs one command', tail.commands, 1)

    -- Zero arguments is a bare `> `, deliberately, and still a command.
    local none, none_err = sandboxed('print()\n')
    it('print with no argument at all runs', none_err, nil)
    it('and costs one command too', none.commands, 1)

    -- Ten calls of two arguments. A per-argument charge is caught by the cases
    -- above; a print that charged nothing at all is caught by this one.
    local many, many_err = sandboxed('for i = 1, 10 do print("n", i) end\n')
    it('ten two-argument prints run', many_err, nil)
    it('and cost ten commands', many.commands, 10)

    codeblock.filesystem.remove_file('test_player', program_file)
    codeblock.filesystem.remove_user_data('test_player')
end

--------------------------------------------------------------------------------
-- the ramps, through the real environment (F12)
--
-- ramp_over is one closure in lib/sandbox.lua, built once per ramp per run, and
-- it is what colours a shape by height or distance. Six things it promises: at
-- or below `min` the first entry, at or above `max` the last, clamping rather
-- than wrapping outside the range, `min` and `max` defaulting to 1 and the
-- list's length, the first entry for a `v` that is not a number, and the first
-- entry for a range of zero width.
--
-- All four built-in ramps are covered, not one. ramp.hues walks ten plain
-- shades and the other three walk a whole 35-entry category, so the last entry
-- differs between them: a ramp wired to the wrong list would still satisfy a
-- spec pinned to one of them.
--
-- Each program reports by setting the drone's default block, which is the one
-- command that writes a value onto the record a spec can read. It also refuses
-- anything that is not a real block, so a ramp answering nil off the end of its
-- list fails here as an error rather than as a wrong name.
--------------------------------------------------------------------------------

do
    local blocks = codeblock.config.allowed_blocks

    --- The block a one-line program's ramp call resolved to, or the error that
    -- stopped it, so a run that did not happen reads as a failure.
    local function answer(expr)
        local drone, err = sandboxed('default_block(' .. expr .. ')\n')
        if err then return 'error: ' .. err end
        return drone.default_block
    end

    -- The readback channel itself: nothing else writes default_block, so a
    -- program that did not run would report 'grey', and no case below expects
    -- it.
    local quiet = sandboxed('local x = 1\n')
    it('a program setting no default block leaves the record alone',
       quiet.default_block, 'grey')

    -- The two list lengths every case below uses as an input. Pinned so that a
    -- change to the palette fails here, naming itself, rather than quietly
    -- turning the max cases into mid-list ones.
    it('hues is one name per family', #blocks.hues, 10)
    it('a colour category is the whole palette', #blocks.by_name.colors.keys, 35)

    -- {name, length, first entry, last entry, a value mid-list and its answer}.
    -- The first and last are literals rather than reads of the same tables the
    -- implementation indexes, so a ramp built over the wrong list is caught by
    -- what it answers and not merely by its length.
    local ramps = {
        {'hues', 10, 'pink', 'violet', 5, 'olive'},
        {'colors', 35, 'white', 'dark_violet', 18, 'light_olive'},
        {'glass', 35, 'white_glass', 'dark_violet_glass', 18, 'light_olive_glass'},
        {'lamps', 35, 'white_lamp', 'dark_violet_lamp', 18, 'light_olive_lamp'}
    }

    for _, r in ipairs(ramps) do
        local name, n, first, last, mid, mid_answer = r[1], r[2], r[3], r[4],
                                                      r[5], r[6]
        local call = 'ramp.' .. name

        it(call .. '(1) is the first entry', answer(call .. '(1)'), first)
        -- max defaulting to anything but the list length moves this one.
        it(call .. '(#list) is the last entry', answer(call .. '(' .. n .. ')'),
           last)
        it(call .. ' maps the middle of the range onto the middle of the list',
           answer(('%s(%d)'):format(call, mid)), mid_answer)

        -- Below the range. An unclamped index reads list[0] and the program
        -- dies on a nil block; a wrapped one lands at the far end.
        it(call .. ' below min clamps to the first entry',
           answer(call .. '(0)'), first)
        it(call .. ' far below min still clamps', answer(call .. '(-1000)'),
           first)
        -- Above the range. Wrapping would answer an early entry here, and an
        -- unclamped index runs off the end of the list.
        it(call .. ' above max clamps to the last entry',
           answer(('%s(%d)'):format(call, n + 5)), last)
        it(call .. ' far above max still clamps', answer(call .. '(1000)'), last)

        -- An explicit range, which is the whole point of min and max: the same
        -- two ends, reached from numbers that have nothing to do with the
        -- list's length.
        it(call .. ' honours an explicit min',
           answer(call .. '(-50, -50, 50)'), first)
        it(call .. ' honours an explicit max', answer(call .. '(50, -50, 50)'),
           last)
        it(call .. ' clamps inside an explicit range too',
           answer(call .. '(500, -50, 50)'), last)

        it(call .. ' answers the first entry for a range of zero width',
           answer(call .. '(3, 3, 3)'), first)
        it(call .. ' answers the first entry for a value that is not a number',
           answer(call .. '("middle")'), first)
        it(call .. ' answers the first entry for no value at all',
           answer(call .. '()'), first)
    end

    ----------------------------------------------------------------------------
    -- What ramp.hues exists for
    --
    -- It is the one ramp that reads as a gradient, because every answer is the
    -- plain shade of a family: never a light_ or dark_ one, and never a
    -- neutral. A ramp wired to a colour category instead would still clamp and
    -- still answer real blocks, and every case above for the other three would
    -- still pass.
    --
    -- The sweep runs inside the program, over `hues` itself, which the
    -- environment publishes: membership in that list is exactly the property,
    -- and the two cases above pin its ends to literals.
    ----------------------------------------------------------------------------

    local swept, sweep_err = sandboxed([[
local bad = 0
for i = -3, 14 do
    local answer = ramp.hues(i)
    local plain = false
    for _, name in ipairs(hues) do
        if name == answer then plain = true end
    end
    if not plain then bad = bad + 1 end
end
if bad == 0 then default_block(colors.white) else default_block(colors.black) end
]])
    it('the hues sweep runs', sweep_err, nil)
    it('every ramp.hues answer is the plain shade of a family',
       swept.default_block, 'white')

    codeblock.filesystem.remove_file('test_player', program_file)
    codeblock.filesystem.remove_user_data('test_player')
end

--------------------------------------------------------------------------------
-- the palette views, and ramp.of over them (F14)
--
-- hues, light_hues, dark_hues and neutrals are one axis of the palette - which
-- colours, in what order - and a category is the other, which material. The two
-- meet because every category is indexed by the same *short* colour name, so
-- glass[h] and lamps[h] turn any of these arrays into a glass or a lamp
-- gradient without a fourth set of names existing; and for colors the short
-- name and the flat key coincide, so a name straight out of one of them is a
-- solid block already. That relationship is the whole of the design and nothing
-- else in the suite reaches it: a view built out of flat keys would read as a
-- plausible array of names, would still ramp, and would only fail where it is
-- indexed into a category.
--
-- ramp.of is ramp_pick itself - the arithmetic the four F12 ramps were already
-- going through, extracted into a module local. The sweep below compares it
-- against ramp.hues across the range and past both ends, which is what says the
-- extraction changed nothing: the two now share one implementation, so they
-- could only disagree if the extraction had left something behind.
--
-- Same readback channel as the section above: default_block, the one command
-- that writes a value onto the record and refuses anything that is not a real
-- block, plus a white/black flag for the answers that are not block names.
--------------------------------------------------------------------------------

do
    local blocks = codeblock.config.allowed_blocks

    --- The block a one-line program's expression resolved to, or the error that
    -- stopped it, so a run that did not happen reads as a failure.
    local function answer(expr)
        local drone, err = sandboxed('default_block(' .. expr .. ')\n')
        if err then return 'error: ' .. err end
        return drone.default_block
    end

    --- Whether a condition held inside a real program. Anything whose answer is
    -- not a block name is read back this way. An error comes back as its own
    -- text rather than as false, so a case that could not be asked at all reads
    -- as a failure and not as a negative answer.
    local function holds(cond)
        local drone, err = sandboxed(
                               ('if %s then default_block(colors.white) else default_block(colors.black) end\n')
                                   :format(cond))
        if err then return 'error: ' .. err end
        return drone.default_block == 'white'
    end

    --- Whether `view` holds exactly `want`, in order, read from inside a
    -- program. The wanted names are written into the source as a literal rather
    -- than read back out of the config, so a view derived from the wrong column
    -- of the palette is caught by what it holds and not merely by its length.
    local function spells(view, want)
        local quoted = {}
        for i, name in ipairs(want) do quoted[i] = ("'%s'"):format(name) end
        local drone, err = sandboxed(([[
local want = {%s}
local bad = 0
for i = 1, %d do if %s[i] ~= want[i] then bad = bad + 1 end end
if bad == 0 then default_block(colors.white) else default_block(colors.black) end
]]):format(table.concat(quoted, ', '), #want, view))
        if err then return 'error: ' .. err end
        return drone.default_block == 'white'
    end

    -- The lengths, separately from the contents, so a view that lost an entry
    -- says so by name instead of failing the order case for a second reason.
    it('light_hues is one name per family', holds('#light_hues == 10'), true)
    it('dark_hues is one name per family', holds('#dark_hues == 10'), true)
    it('neutrals is the five greys', holds('#neutrals == 5'), true)

    it('light_hues runs light_pink to light_violet, in colour-wheel order',
       spells('light_hues', {
        'light_pink', 'light_red', 'light_orange', 'light_yellow',
        'light_olive', 'light_lime', 'light_green', 'light_cyan', 'light_blue',
        'light_violet'
    }), true)
    it('dark_hues runs dark_pink to dark_violet, in the same order',
       spells('dark_hues', {
        'dark_pink', 'dark_red', 'dark_orange', 'dark_yellow', 'dark_olive',
        'dark_lime', 'dark_green', 'dark_cyan', 'dark_blue', 'dark_violet'
    }), true)
    it('neutrals runs white to black', spells('neutrals', {
        'white', 'light_grey', 'grey', 'dark_grey', 'black'
    }), true)

    ----------------------------------------------------------------------------
    -- short colour names, not flat block keys
    --
    -- The three cases below are the design premise. A view of flat keys would
    -- satisfy every case above and every ramp case below, and would fail only
    -- here, where the name is used the way the feature exists to be used.
    ----------------------------------------------------------------------------

    it('a view holds the short colour name', holds("light_hues[1] == 'light_pink'"),
       true)
    it('so a category turns one into that material in glass',
       answer('glass[light_hues[1]]'), 'light_pink_glass')
    it('and into a lamp', answer('lamps[light_hues[1]]'), 'light_pink_lamp')
    -- The other half: for colors the short name *is* the flat key, so a name
    -- out of a view needs nothing around it to be placed as a solid.
    it('and is a solid block already, with nothing around it',
       answer('dark_hues[1]'), 'dark_pink')

    ----------------------------------------------------------------------------
    -- ramp.of is the same mapping as the ramps it was extracted from
    ----------------------------------------------------------------------------

    -- Half-integers as well as whole ones, because rounding is where the two
    -- would part company first, and past both ends, because clamping is the
    -- other half of the arithmetic. The explicit range is swept too: min and
    -- max are arguments ramp.of carries one position further along than the
    -- ramps do, which is exactly the kind of thing an extraction gets wrong.
    local agreed, agree_err = sandboxed([[
local bad = 0
for k = -6, 28 do
    local v = k / 2
    if ramp.of(hues, v) ~= ramp.hues(v) then bad = bad + 1 end
    if ramp.of(hues, v, -5, 20) ~= ramp.hues(v, -5, 20) then bad = bad + 1 end
end
if ramp.of(hues, 'x') ~= ramp.hues('x') then bad = bad + 1 end
if ramp.of(hues, 3, 3, 3) ~= ramp.hues(3, 3, 3) then bad = bad + 1 end
if bad == 0 then default_block(colors.white) else default_block(colors.black) end
]])
    it('the ramp.of sweep runs', agree_err, nil)
    it('ramp.of over hues answers exactly what ramp.hues answers',
       agreed.default_block, 'white')

    ----------------------------------------------------------------------------
    -- the composition, end to end
    ----------------------------------------------------------------------------

    -- orange is the third family, and over 1..10 the mapping is the identity,
    -- so 3 is the value that has to come back orange. A ramp wired to the wrong
    -- view answers a light or a plain shade here and a ramp off by one answers
    -- red or yellow.
    it('a ramp over dark_hues placed as a solid', answer('ramp.of(dark_hues, 3, 1, 10)'),
       'dark_orange')
    it('the same ramp read through glass',
       answer('glass[ramp.of(dark_hues, 3, 1, 10)]'), 'dark_orange_glass')
    it('and through lamps', answer('lamps[ramp.of(dark_hues, 3, 1, 10)]'),
       'dark_orange_lamp')

    ----------------------------------------------------------------------------
    -- ramp.of's edges
    --
    -- None of them raises. ramp.of takes a list a program may have built
    -- itself, so every way of handing it something it cannot use has an answer
    -- rather than an error: stopping a program over an arithmetic accident is
    -- the wrong shape for a function a player calls inside a loop.
    ----------------------------------------------------------------------------

    it('a list that is not a table answers nothing',
       holds('ramp.of(42, 1, 1, 10) == nil'), true)
    it('no list at all answers nothing', holds('ramp.of() == nil'), true)
    it('an empty list answers nothing', holds('ramp.of({}, 1, 1, 10) == nil'),
       true)
    it('a value that is not a number answers the first entry',
       answer('ramp.of(hues, "middle", 1, 10)'), 'pink')
    it('a range of zero width answers the first entry',
       answer('ramp.of(hues, 5, 3, 3)'), 'pink')
    it('below the range it clamps rather than wrapping',
       answer('ramp.of(hues, -1000, 1, 10)'), 'pink')
    it('above the range it clamps rather than wrapping',
       answer('ramp.of(hues, 1000, 1, 10)'), 'violet')
    it('min omitted defaults to 1', answer('ramp.of(hues, 1)'), 'pink')
    it('max omitted defaults to the length of the list',
       answer('ramp.of(hues, 10)'), 'violet')
    -- The default range follows the list it was handed, and is not a fixed ten
    -- borrowed from the hues: neutrals is five long, so 5 is its last entry and
    -- 10 would be off the end of it.
    it('and to the length of whichever list it was handed',
       answer('ramp.of(neutrals, 5)'), 'black')
    it('which is the same list its first entry comes from',
       answer('ramp.of(neutrals, 1)'), 'white')

    ----------------------------------------------------------------------------
    -- a list the program built itself
    --
    -- The reason ramp.of exists rather than a fourth and fifth named ramp.
    ----------------------------------------------------------------------------

    it("a two-entry list of the program's own answers its first entry",
       answer('ramp.of({colors.white, colors.red}, 1, 1, 2)'), 'white')
    it('and its last', answer('ramp.of({colors.white, colors.red}, 2, 1, 2)'),
       'red')
    -- It returns whatever the list holds and does not check that an entry is a
    -- block name, so a program may ramp anything it has in order.
    it('a list of things that are not blocks ramps the same way',
       holds("ramp.of({'a', 'b'}, 2, 1, 2) == 'b'"), true)

    ----------------------------------------------------------------------------
    -- the views are snapshots (S1)
    --
    -- One copy per run, like every other palette table the environment
    -- publishes. The first program has to be seen to write, or the second one
    -- reading a clean array would prove nothing: an assignment that raised
    -- would leave exactly the same trace.
    ----------------------------------------------------------------------------

    it('a program may write into a palette view within its own run', holds(
           "(function() dark_hues[1] = 'tampered' return dark_hues[1] == 'tampered' end)()"),
       true)
    it('but the next run reads the array unaltered', answer('dark_hues[1]'),
       'dark_pink')
    it('and the config behind it is untouched', blocks.dark_hues[1], 'dark_pink')

    -- The array may be written into; the name it is published under may not, or
    -- a program could swap the whole view out from under the ramps.
    local _, replaced = sandboxed('dark_hues = {}\n')
    it('and the name itself cannot be reassigned',
       (replaced or ''):find('cannot be reassigned', 1, true) ~= nil, true)

    ----------------------------------------------------------------------------
    -- reading past the end
    --
    -- Legitimate, and deliberately carries no misspelling report: the views are
    -- arrays, and walking one until it answers nil is a reasonable thing for a
    -- program to do, unlike misspelling colors.gray.
    --
    -- **What is not asserted here is the absence of the report**, and it cannot
    -- be from a spec. lib/sandbox.lua binds chat_send_player as a load-time
    -- local, so replacing core.chat_send_player around a run intercepts
    -- nothing, and the message goes to a player name no one is logged in
    -- under. What a case here would assert is that nothing raised, which is
    -- true of the reporting version too - so it would pass either way. Whether
    -- a stray warning reaches a player belongs in PLAYTEST.md.
    ----------------------------------------------------------------------------

    it('an index past the end of a view reads nil',
       holds('dark_hues[99] == nil'), true)
    it('and the program carries on', answer('colors.white'), 'white')

    codeblock.filesystem.remove_file('test_player', program_file)
    codeblock.filesystem.remove_user_data('test_player')
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
-- The palette's shape is pinned below: 35 colours, five neutrals light to dark
-- and then ten hue families of three. Changing it deliberately means changing
-- these and re-running gen_docs, which is the point of pinning them.
--
-- `hues` is the part with a contract behind it rather than a count. It is one
-- name per family - the plain middle shade - in family order, and ramp.hues()
-- maps a number straight onto it, so a value sweeping the range has to read as
-- a rainbow. A `hues` that lost a family, gained a light_ or dark_ shade, or
-- came out sorted would still be a plausible-looking array of colour names and
-- would still index; only the relationship to the palette says it is wrong.
-- So it is derived from the palette here and compared, not listed.
--------------------------------------------------------------------------------

do
    local palette = codeblock.config.palette
    local blocks = codeblock.config.allowed_blocks

    -- 5 neutrals + 10 families x 3 shades.
    local NEUTRALS, FAMILIES = 5, 10

    it('the palette has 35 colours', #palette, NEUTRALS + FAMILIES * 3)

    local badhex = {}
    for _, e in ipairs(palette) do
        if not (type(e[2]) == 'string' and e[2]:match('^#%x%x%x%x%x%x$')) then
            badhex[#badhex + 1] = tostring(e[1])
        end
    end
    it('every colour carries a six-digit hex', table.concat(badhex, ', '), '')

    it('hues holds one name per family', #blocks.hues, FAMILIES)

    -- The middle of each family, read out of the palette itself. This is the
    -- assertion ramp.hues() rests on: same entries, same order, no neutral and
    -- no light_ or dark_ shade among them.
    -- Indexed through a guard, so a palette that has lost an entry reports one
    -- failure here rather than aborting the spec on a nil index and taking
    -- every case below it with it.
    local function shade(i)
        local e = palette[i]
        return (e and e[1]) or ('<no palette entry ' .. i .. '>')
    end

    local plains = {}
    for i = 1, FAMILIES do plains[i] = shade(NEUTRALS + (i - 1) * 3 + 2) end
    it('hues is the plain shade of each family, in family order',
       table.concat(blocks.hues, ','), table.concat(plains, ','))

    -- And the layout that reading gets its meaning from: every hue is the
    -- middle of a light / plain / dark run, so the two names either side of a
    -- hue are that hue's own shades and not another family's.
    local malformed = {}
    for i = 1, FAMILIES do
        local at = NEUTRALS + (i - 1) * 3
        local plain = shade(at + 2)
        if shade(at + 1) ~= 'light_' .. plain or shade(at + 3) ~= 'dark_' ..
            plain then
            malformed[#malformed + 1] = plain
        end
    end
    it('every family runs light, plain, dark under one name',
       table.concat(malformed, ', '), '')

    -- The neutrals are the head, so the arithmetic above lands where it means
    -- to; naming them also pins the fallback block being one of them.
    local head = {}
    for i = 1, NEUTRALS do head[i] = shade(i) end
    it('the neutrals come first, light to dark', table.concat(head, ','),
       'white,light_grey,grey,dark_grey,black')

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

    -- `keys` is the array form of the same thing, and it is what ramp.colors,
    -- ramp.glass and ramp.lamps index: a ramp is a position in this list, so a
    -- keys that disagreed with names in order or in length would colour a
    -- gradient with the wrong blocks and nothing would raise. Compared against
    -- names through spelled rather than listed, so it holds for a category a
    -- game registers on exactly the same terms.
    local mismatched = {}
    for _, cat in ipairs(blocks.categories) do
        local built = {}
        for i, name in ipairs(cat.names) do built[i] = cat.spelled[name] end
        if #(cat.keys or {}) ~= #built or
            table.concat(cat.keys or {}, ',') ~= table.concat(built, ',') then
            mismatched[#mismatched + 1] = cat.name
        end
    end
    it('every category lists its keys in the order it spells its names',
       table.concat(mismatched, ', '), '')

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
    -- `ramp` would shadow every ramp.* the sandbox builds.
    --
    -- The name has to be one the environment really holds. This case named
    -- `color` until `color()` was replaced by the ramps; `ramp` is the honest
    -- replacement and is the better one, because nothing is called plain `ramp`
    -- - it is reserved by ramp.hues and its siblings alone, so this is also the
    -- case proving a dotted name reserves its first segment.
    --
    -- The one thing it must not become is a case that cannot fail. It is not
    -- one today: pointed at a free name, install_one accepts the category and
    -- refused_for answers false rather than passing on a refusal for some other
    -- rule. Keep it that way - the assertion is on the *reason*, not on the
    -- refusal.
    it('a category colliding with any API name is refused',
       refused_for('ramp', {red = 'codeblock:red'}, 'already taken'), true)

    -- A palette view is an API name and not a category, so it is spoken for by
    -- api.names() alone - the by_name seeding below it in blocks.install never
    -- sees one. A game registering `dark_hues` would shadow the array every
    -- ramp.of example in doc/api.md reads. (F14)
    it('a category colliding with a palette view is refused',
       refused_for('dark_hues', {red = 'codeblock:red'}, 'already taken'), true)

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
                mud = 'codeblock:olive',
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
    -- The derived view a late registration is most likely to lose. F11 found
    -- three palette snapshots taken at load time, one of them a live defect,
    -- and all three were invisible here; `keys` is the same shape of thing, and
    -- add_category building it is the only reason a game's ramp indexes
    -- anything at all.
    it("the category carries its keys, so it can have a ramp",
       table.concat(category.keys or {}, ','), 'agame.mud')
    it('the flat key carries the category, so it cannot shadow ours',
       category.spelled.mud, 'agame.mud')
    it('the flat key resolves to the node the game named',
       blocks.all['agame.mud'], 'codeblock:olive')
    -- First registrant wins, so get_block() still answers colors.olive for the
    -- node the mod registered itself.
    it('a node the mod already owns keeps its own name',
       blocks.by_node['codeblock:olive'], 'olive')

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

    -- A category is two names now, the table and its ramp, and api.build
    -- refuses a run where the description and the implementations disagree in
    -- either direction. So a missing description here is not a thinner help
    -- panel - it is every program failing to start once a game has registered
    -- anything.
    local ramped = false
    for _, name in ipairs(codeblock.api.names()) do
        if name == 'ramp.agame' then ramped = true end
    end
    it('and describes its ramp as well', ramped, true)

    it('the in-game help lists it',
       codeblock.api.to_hypertext():find('agame', 1, true) ~= nil, true)

    it('the reference renders it as a category',
       codeblock.api.to_markdown(blocks):find('## `agame`', 1, true) ~= nil,
       true)

    it('registering the same name twice is refused',
       refused_for('agame', {mud = 'codeblock:olive'}, 'already taken'), true)

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
       codeblock.register_blocks('late', {mud = 'codeblock:olive'}), false)
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
        {mod = 'agame', category = 'Glass', entries = {pane = 'codeblock:olive'}}
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
-- the program a new file starts with, run as a real player program
--
-- `+` and Enter in the editor write a starter program into the file they
-- create. It is player code inside a Lua string in lib/formspecs.lua, so
-- nothing lints it, compiles it or generates it from lib/api.lua. It still read
-- `place(blocks.obsidian)` for three days after F11 renamed the categories, so
-- every file a player made raised on its first statement, and all five gates
-- stayed green over it.
--
-- The template is read out of lib/formspecs.lua rather than copied here. It is
-- built inside a local closure and there is no runtime door to it, and a copy
-- in the spec would be one more unchecked mirror of the source - which is the
-- family of defect this one belongs to. The expression handed to write_file is
-- extracted by matching parentheses from the call, then evaluated, so what runs
-- below is the string that ships; a change to the shape of that call fails the
-- first case here by name rather than quietly switching the check off.
--
-- It runs at the origin and not outside the world like every other program in
-- this file, because it is the only one that moves and places, and `up` refuses
-- to leave the world. The nodes land in the throwaway world the suite boots.
-- Same allowance as the ramp sections above and for the same reason - there is
-- no other door - and the run is the whole point: the old template compiled
-- perfectly well, and only failed when the name was read.
--------------------------------------------------------------------------------

do
    --- The program lib/formspecs.lua writes into a newly created file, or nil
    -- if that call is no longer shaped the way this reads it.
    local function template_source()

        local f = io.open(codeblock.modpath .. '/lib/formspecs.lua', 'r')
        if not f then return nil end
        local text = f:read('*a')
        f:close()

        local anchor = 'write_file(name, filename,'
        local at = text:find(anchor, 1, true)
        if not at then return nil end

        -- Scan to the parenthesis closing that call, stepping over quoted text
        -- so a bracket inside the program itself cannot end it early. The
        -- escape character is spelled string.char(92): a backslash literal in
        -- the middle of this reads as a typo.
        local i = at + #anchor - 1
        local depth, quote, j = 1, nil, i
        while depth > 0 do
            j = j + 1
            local c = text:sub(j, j)
            if c == '' then return nil end
            if quote then
                if c == string.char(92) then
                    j = j + 1
                elseif c == quote then
                    quote = nil
                end
            elseif c == "'" or c == '"' then
                quote = c
            elseif c == '(' then
                depth = depth + 1
            elseif c == ')' then
                depth = depth - 1
            end
        end

        -- name and filename are the two locals in scope at the call site.
        local chunk = loadstring('local name, filename = ... return ' ..
                                     text:sub(i + 1, j - 1))
        if not chunk then return nil end

        local ok, template = pcall(chunk, 'test_player', 'newfile.lua')
        if not ok or type(template) ~= 'string' then return nil end
        return template
    end

    local template = template_source()
    it('the new-file template was found in lib/formspecs.lua', type(template),
       'string')

    local origin = {x = 0, y = 0, z = 0}
    local drone, err = sandboxed(template or '', origin)

    it('it runs to completion in the real sandbox environment', err, nil)
    -- Not merely that it ran. A template of nothing but comments resolves every
    -- name it has and would pass the case above, and so would no template at
    -- all: what is asserted is that it reached commands that charge.
    it('and it is a program that does something', (drone.commands > 0), true)

    -- This check can fail, and here is it failing. The line below is the
    -- template as it stood before F11, and what it does is index a global that
    -- is not in the environment - which is exactly what the run above would
    -- have reported for those three days.
    local _, dead = sandboxed('place(blocks.obsidian)\nup(1)\n', origin)
    it('a template naming a category that no longer exists does not run',
       (dead ~= nil), true)

    codeblock.filesystem.remove_file('test_player', program_file)
    codeblock.filesystem.remove_user_data('test_player')
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
