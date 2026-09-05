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
local hues = codeblock.config.allowed_blocks.hues
local nhues = #hues
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

-- Map a number in [m, M] onto the hue palette, clamping out-of-range values to
-- the end colours. The default range is the palette's own length, so color(i)
-- over 1..#hues walks the whole rainbow.
local color
do
    local tmp1 = nhues - 1
    color = function(v, m, M)
        local m = (type(m) == 'number') and m or 1
        local M = (type(M) == 'number') and M or nhues
        m, M = min(m, M), max(m, M)
        if type(v) ~= 'number' then return hues[1] end
        if M == m then return hues[1] end
        local i = round0((v - m) / (M - m) * tmp1) + 1
        if i < 1 then i = 1 end
        if i > nhues then i = nhues end
        return hues[i]
    end
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
        -- known until every mod has loaded. hues is the wheel order as an
        -- array, where reading past the end is a legitimate thing to do, so it
        -- gets no misspelling report. air is engine-provided and belongs to no
        -- category, so it is a plain name.
        ['hues'] = snapshot(hues),
        ['air'] = 'air',
        -- choosing blocks
        ['random.color'] = table_randomizer(colors),
        ['random.glass'] = table_randomizer(glass),
        ['random.lamp'] = table_randomizer(lamps),
        ['color'] = color,
        ['get_block'] = function() return drone_get_block(drone) end,
        -- vectors. snapshot_module keeps the metatable so vector(x, y, z) still
        -- resolves through its __call.
        ['vector'] = snapshot_module(vector3),
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
        ['print'] = function(str) return send_message(drone, str) end,
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
