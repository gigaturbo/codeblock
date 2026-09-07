codeblock.sandbox = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S
local chat_send_player = core.chat_send_player
local max = math.max
local min = math.min
local floor = math.floor

local move = codeblock.commands.drone_move
local forward = codeblock.commands.drone_forward
local back = codeblock.commands.drone_back
local right = codeblock.commands.drone_right
local left = codeblock.commands.drone_left
local up = codeblock.commands.drone_up
local down = codeblock.commands.drone_down
local turn_left = codeblock.commands.drone_turn_left
local turn_right = codeblock.commands.drone_turn_right
local turn = codeblock.commands.drone_turn
local place_block = codeblock.commands.drone_place_block
local place_relative = codeblock.commands.drone_place_relative
local set_default_block = codeblock.commands.drone_set_default_block
local place_cube = codeblock.commands.drone_place_cube
local place_ccube = codeblock.commands.drone_place_ccube
local place_sphere = codeblock.commands.drone_place_sphere
local place_csphere = codeblock.commands.drone_place_csphere
local place_dome = codeblock.commands.drone_place_dome
local place_cdome = codeblock.commands.drone_place_cdome
local place_cylinder = codeblock.commands.drone_place_cylinder
local place_ccylinder = codeblock.commands.drone_place_ccylinder
local save_checkpoint = codeblock.commands.drone_save_checkpoint
local goto_checkpoint = codeblock.commands.drone_goto_checkpoint
local send_message = codeblock.commands.drone_send_message
local use_call = codeblock.commands.drone_use_call
local drone_get_block = codeblock.commands.drone_get_block

-- The one name taken from lib/cost.lua rather than lib/commands.lua: a sleep has
-- no geometry, so commands.lua would have nothing to add and re-exporting it
-- there - as it does for use_call - would be two names for one function. (F3)
local sleep = codeblock.cost.sleep

-- The categories as a list, because a game may register one of its own and the
-- environment names them all the same way. The mod's own three are also read by
-- name, for random.color, random.glass and random.lamp, which are ours: a
-- registered category is reached with table.randomizer instead. (F11)
local categories = codeblock.config.allowed_blocks.categories
local by_name = codeblock.config.allowed_blocks.by_name
local colors = by_name.colors.spelled
local glass = by_name.glass.spelled
local lamps = by_name.lamps.spelled
-- The palette views: ordered arrays of short colour names. A category is
-- indexed by the same short name, so glass[h] turns any of them into a glass
-- gradient without a fourth set of names existing. (F14)
local hues = codeblock.config.allowed_blocks.hues
local light_hues = codeblock.config.allowed_blocks.light_hues
local dark_hues = codeblock.config.allowed_blocks.dark_hues
local neutrals = codeblock.config.allowed_blocks.neutrals
local table_randomizer = codeblock.utils.table_randomizer

local snapshot = codeblock.env.snapshot
local snapshot_module = codeblock.env.snapshot_module
local seal = codeblock.env.seal
local new_env = codeblock.env.new_env
local build_api = codeblock.api.build

--------------------------------------------------------------------------------
-- private
--------------------------------------------------------------------------------

-- round(value, decimals), value first - round0(x) is short for round(x, 0).
local function round(num, dec)
    local mult = 10 ^ (dec or 0)
    return floor(num * mult + 0.5) / mult
end

local function round0(num) return floor(num + 0.5) end

--- One entry of `list` for a number `v` in [m, M]. The whole of the ramp
-- mapping: every ramp in the environment goes through here, so ramp.of and the
-- per-category ramps cannot drift apart.
--
-- Out of range clamps to the end entries rather than wrapping, so a value at or
-- below `m` gives the first entry and one at or above `M` the last. The default
-- range is the list's own length, so ramp(i) over 1..#list walks it once. A
-- non-number `v`, and a range of zero width, both give the first entry - there
-- is no other answer to give and raising would stop a program over an
-- arithmetic accident. A `list` that is not a table, or is empty, answers nil
-- for the same reason: ramp.of takes a list a program may have built itself.
local function ramp_pick(list, v, m, M)
    if type(list) ~= 'table' then return nil end
    local n = #list
    if n == 0 then return nil end
    m = (type(m) == 'number') and m or 1
    M = (type(M) == 'number') and M or n
    m, M = min(m, M), max(m, M)
    if type(v) ~= 'number' then return list[1] end
    if M == m then return list[1] end
    local i = round0((v - m) / (M - m) * (n - 1)) + 1
    if i < 1 then i = 1 end
    if i > n then i = n end
    return list[i]
end

--- One ramp bound to `list`, an ordered array of the flat block keys place()
-- takes. Called once per category per run, so a game's category gets a ramp on
-- the same footing as the mod's own.
local function ramp_over(list)
    return function(v, m, M) return ramp_pick(list, v, m, M) end
end

--- The `vector` table one run gets: a copy of the vector3 module whose
-- table-valued entries - its fourteen exported constants - are copies too.
--
-- snapshot_module is one level deep, so without this every run and every player
-- shares the module's own `zero`, `one`, `x` ... and `dir = vector.one;
-- dir.x = -dir.x` writes into a constant the whole server reads (S8). vector3
-- 2.0 froze them, which turns that write into a raise instead, but mod.conf
-- reads `depends = vector3` and Luanti has no version constraint, so a player
-- may be on 1.5, where it lands. Fourteen constructions per program start.
--
-- Rebuilt with the constructor, never by copying the keys and reattaching
-- getmetatable(v): a frozen constant is an empty table reading through its
-- metatable, so pairs() over it yields nothing and the reattached metatable
-- aliases the original - a copy that reads correctly and is not one.
--
-- Only what is actually a vector, by vector3's own duck test, so a release
-- exporting a table of some other shape does not make this raise at the start
-- of every program.
local function snapshot_vector3()
    local c = snapshot_module(vector3)
    for k, v in pairs(vector3) do
        if type(v) == 'table' and type(v.x) == 'number' and type(v.y) ==
            'number' and type(v.z) == 'number' then c[k] = vector3(v) end
    end
    return c
end

local function getScriptEnv(drone)

    assert(drone, S("Error, drone does not exist"))

    -- Said once and at the read, where the name the player typed is still
    -- known: by the time a nil block reaches a command all that is left is the
    -- fallback. The flag is an upvalue of this environment, which is built
    -- fresh for every run, so drones running side by side each get their own.
    local warned = false
    local function unknown_block(key)
        if warned then return end
        warned = true
        chat_send_player(drone.name, S(
            "Warning: no block named '@1', the default block is used instead",
            tostring(key)))
    end

    -- Every name a program may use, paired with what it does. The names come
    -- from lib/api.lua, and build_api below refuses to start if this table and
    -- that description disagree.
    local impls = {
        -- movement
        ['move'] = function(x, y, z) move(drone, x, y, z) end,
        ['forward'] = function(n) forward(drone, n) end,
        ['back'] = function(n) back(drone, n) end,
        ['left'] = function(n) left(drone, n) end,
        ['right'] = function(n) right(drone, n) end,
        ['up'] = function(n) up(drone, n) end,
        ['down'] = function(n) down(drone, n) end,
        ['turn_left'] = function() turn_left(drone) end,
        ['turn_right'] = function() turn_right(drone) end,
        ['turn'] = function(quarters) turn(drone, quarters) end,

        ['sleep'] = function(seconds) sleep(drone, seconds) end,
        -- placement
        ['place'] = function(block) place_block(drone, block) end,
        ['place_relative'] = function(x, y, z, block, chkpt)
            place_relative(drone, x, y, z, block, chkpt)
        end,
        ['default_block'] = function(block)
            set_default_block(drone, block)
        end,
        -- checkpoints
        ['save'] = function(chkpt) save_checkpoint(drone, chkpt) end,
        ['go'] = function(chkpt, x, y, z)
            goto_checkpoint(drone, chkpt, x, y, z)
        end,
        -- shapes
        ['cube'] = function(w, h, l, block, hollow)
            place_cube(drone, w, h, l, block, hollow)
        end,
        ['sphere'] = function(r, block, hollow)
            place_sphere(drone, r, block, hollow)
        end,
        ['dome'] = function(r, block, hollow)
            place_dome(drone, r, block, hollow)
        end,
        ['cylinder'] = function(l, r, block, hollow)
            place_cylinder(drone, 'V', l, r, block, hollow)
        end,
        ['vertical.cylinder'] = function(l, r, block, hollow)
            place_cylinder(drone, 'V', l, r, block, hollow)
        end,
        ['horizontal.cylinder'] = function(l, r, block, hollow)
            place_cylinder(drone, 'H', l, r, block, hollow)
        end,
        ['centered.cube'] = function(w, h, l, block, hollow)
            place_ccube(drone, w, h, l, block, hollow)
        end,
        ['centered.sphere'] = function(r, block, hollow)
            place_csphere(drone, r, block, hollow)
        end,
        ['centered.dome'] = function(r, block, hollow)
            place_cdome(drone, r, block, hollow)
        end,
        ['centered.cylinder'] = function(l, r, block, hollow)
            place_ccylinder(drone, 'V', l, r, block, hollow)
        end,
        ['centered.vertical.cylinder'] = function(l, r, block, hollow)
            place_ccylinder(drone, 'V', l, r, block, hollow)
        end,
        ['centered.horizontal.cylinder'] = function(l, r, block, hollow)
            place_ccylinder(drone, 'H', l, r, block, hollow)
        end,
        -- The block categories are added below, after this table: they are not
        -- known until every mod has loaded. The four palette views are arrays,
        -- where reading past the end is a legitimate thing to do, so none of
        -- them gets a misspelling report. air is engine-provided and belongs to
        -- no category, so it is a plain name.
        ['hues'] = snapshot(hues),
        ['light_hues'] = snapshot(light_hues),
        ['dark_hues'] = snapshot(dark_hues),
        ['neutrals'] = snapshot(neutrals),
        ['air'] = 'air',
        -- choosing blocks
        ['random.color'] = table_randomizer(colors),
        ['random.glass'] = table_randomizer(glass),
        ['random.lamp'] = table_randomizer(lamps),
        -- The one ramp not built from a category: hues is already an array of
        -- colors keys, one per family, so it is the only one that reads as a
        -- gradient. The per-category ramps are added below with the categories.
        ['ramp.hues'] = ramp_over(hues),
        -- The generic ramp, over any array: the palette views above, or a list
        -- the program built. It is ramp_pick itself, so its mapping is the
        -- other ramps' by construction rather than by resemblance. What it
        -- returns is whatever the list holds - it does not check that an entry
        -- is a block name, because a program may ramp anything.
        ['ramp.of'] = ramp_pick,
        ['get_block'] = function(x, y, z)
            return drone_get_block(drone, x, y, z)
        end,
        -- The read happens whatever `block` is, so one call costs one command
        -- however it answers. A name that is not a block answers false rather
        -- than resolving through place()'s default: substituting grey is right
        -- for a write and a trap for a question, and a misspelling has already
        -- been reported once by unknown_block, at the read where its spelling
        -- was still known.
        ['is_block'] = function(block, x, y, z)
            local found = drone_get_block(drone, x, y, z)
            return type(block) == 'string' and found == block
        end,
        -- vectors. The copy keeps the module's metatable, so vector(x, y, z)
        -- still resolves through its __call, and its constants are this run's
        -- own - see snapshot_vector3 above.
        ['vector'] = snapshot_vector3(),
        -- math
        ['random'] = math.random,
        ['round'] = round,
        ['round0'] = round0,
        ['floor'] = math.floor,
        ['ceil'] = math.ceil,
        ['abs'] = math.abs,
        ['max'] = math.max,
        ['min'] = math.min,
        ['sqrt'] = math.sqrt,
        ['pow'] = math.pow,
        ['exp'] = math.exp,
        ['log'] = math.log,
        ['deg'] = math.deg,
        ['rad'] = math.rad,
        ['sin'] = math.sin,
        ['cos'] = math.cos,
        ['tan'] = math.tan,
        ['asin'] = math.asin,
        ['acos'] = math.acos,
        ['atan'] = math.atan,
        ['atan2'] = math.atan2,
        ['sinh'] = math.sinh,
        ['cosh'] = math.cosh,
        ['tanh'] = math.tanh,
        ['pi'] = math.pi,
        ['e'] = math.exp(1),
        -- misc
        -- Variadic like real Lua's print, and one call still costs one command
        -- however many arguments it takes: the join happens here, so
        -- drone_send_message keeps taking one value and charging once. The list
        -- is read with select rather than `{...}` and `#`, which cannot see a
        -- nil in the middle or at the end of it - and a nil is ordinary here,
        -- get_block() answering nil for map that was never generated. Joined
        -- with a space, not real Lua's tab: the chat console has no tab stops
        -- and wraps on spaces.
        ['print'] = function(...)
            local parts = {}
            for i = 1, select('#', ...) do
                parts[i] = tostring((select(i, ...)))
            end
            return send_message(drone, table.concat(parts, ' '))
        end,
        ['error'] = error,
        ['ipairs'] = ipairs,
        ['pairs'] = pairs,
        ['table.randomizer'] = table_randomizer
    }

    -- Every block category, the mod's own three and any the game registered.
    -- Snapshots, so a program cannot alter one for every other player, and
    -- name-indexed, so a name that is not in one is a misspelling worth
    -- reporting. Built here rather than listed above because the list is only
    -- complete once every mod has loaded, and lib/blocks.lua has by then
    -- described each one in lib/api.lua - which is what stops build_api below
    -- refusing an implementation nothing describes. (F11)
    for _, category in ipairs(categories) do
        impls[category.name] = snapshot(category.spelled, unknown_block)
        -- One ramp per category, over the keys in the order the category was
        -- declared in. Not a snapshot: a closure over the list is already
        -- private to this run, and the list itself is never handed out.
        impls['ramp.' .. category.name] = ramp_over(category.keys)
    end

    local api = build_api(impls)

    -- The instrumenter emits `_G.use_call()`, so this is the budget counter the
    -- program is paying into. Sealed: a program that could assign to
    -- _G.use_call would switch its own limits off.
    api._G = seal({
        print = api.print,
        error = api.error,
        use_call = function() use_call(drone) end
    }, '_G')

    -- Reads fall through to `api`; assigning an API name raises; anything else
    -- becomes an ordinary player global.
    return new_env(api)

end

--------------------------------------------------------------------------------
-- source preprocessing (see lib/preprocess.lua and tests/preprocess_spec.lua)
--------------------------------------------------------------------------------

local preprocess_code = codeblock.preprocess.preprocess_code
local find_forbidden = codeblock.preprocess.find_forbidden

local function check_code(code)
    local bad = find_forbidden(code)
    if bad then return S('@1 is not allowed!', bad) end
end


--------------------------------------------------------------------------------
-- public
--------------------------------------------------------------------------------

function codeblock.sandbox.get_safe_coroutine(drone, filename)

    assert(drone)
    assert(filename)

    -- `filename` used to be immediately overwritten with drone.file, silently
    -- discarding the argument. The only caller passes drone.file anyway, so the
    -- behaviour is unchanged - the parameter is simply honoured now.
    local name = drone.name

    -- loading file
    local untrusted_code, ferr = codeblock.filesystem.read_file(name, filename,
                                                               true)

    -- read_file's own message is a whole sentence naming the real reason - too
    -- large, unreadable, bytecode - so it stands in for the generic one rather
    -- than being prefixed by it. Without this, a file refused for its size ran
    -- as "not found". (B40)
    if not untrusted_code then
        return false, ferr or (S("Compilation error in @1: ", filename) ..
                   S('@1 not found.', filename))
    end

    if untrusted_code:byte(1) == 27 then
        -- The same key lib/filesystem.lua uses for the same refusal. It was
        -- lower-cased here, which is a second key for one message and left this
        -- one untranslated. (C17)
        return false, S("Compilation error in @1: ", filename) ..
                   S('Binary bytecode prohibited')
    end

    -- checking forbiden things

    local err = check_code(untrusted_code);

    if err then
        return false, S("Compilation error in @1: ", filename) .. '\n' .. err
    end

    -- preprocessing code

    local safe_code = preprocess_code(untrusted_code);

    -- compiling into bytecode

    local bytecode, message = loadstring(safe_code)
    if not bytecode then
        return false,
               S("Compilation error in @1: ", filename) .. '\n' .. message
    end

    -- return it

    setfenv(bytecode, getScriptEnv(drone))
    return true, coroutine.create(bytecode)

end
