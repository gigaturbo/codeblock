codeblock.sandbox = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S
local max = math.max
local min = math.min
local abs = math.abs
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

local cubes = codeblock.config.allowed_blocks.cubes
local plants = codeblock.config.allowed_blocks.plants
local wools = codeblock.config.allowed_blocks.wools
local iwools = codeblock.config.allowed_blocks.iwools
local niwools = #iwools
local table_randomizer = codeblock.utils.table_randomizer

--------------------------------------------------------------------------------
-- private
--------------------------------------------------------------------------------

local function round(dec, num)
    local mult = 10 ^ (dec or 0)
    return floor(num * mult + 0.5) / mult
end

local function round0(num) return floor(num + 0.5) end

local color
do
    local tmp1 = niwools - 1
    color = function(v, m, M)
        local m = (type(m) == 'number') and m or 1
        local M = (type(M) == 'number') and M or 11
        m, M = min(m, M), max(m, M)
        local i = round0(((v - m) / (M - m) * tmp1) % niwools) + 1
        return iwools[i]
    end
end

local function getScriptEnv(drone)

    assert(drone, S("Error, drone does not exist"))

    local env = {
        -- movements
        move = function(x, y, z) move(drone, x, y, z) end,
        forward = function(n) forward(drone, n) end,
        back = function(n) back(drone, n) end,
        left = function(n) left(drone, n) end,
        right = function(n) right(drone, n) end,
        up = function(n) up(drone, n) end,
        down = function(n) down(drone, n) end,
        turn_left = function() turn_left(drone) end,
        turn_right = function() turn_right(drone) end,
        turn = function(quarters) turn(drone, quarters) end,
        place = function(block) place_block(drone, block) end,
        place_relative = function(x, y, z, block, chkpt)
            place_relative(drone, x, y, z, block, chkpt)
        end,
        save = function(chkpt) save_checkpoint(drone, chkpt) end,
        go = function(chkpt, x, y, z)
            goto_checkpoint(drone, chkpt, x, y, z)
        end,
        -- worldedit commands
        cube = function(w, h, l, block, hollow)
            place_cube(drone, w, h, l, block, hollow)
        end,
        sphere = function(r, block, hollow)
            place_sphere(drone, r, block, hollow)
        end,
        dome = function(r, block, hollow)
            place_dome(drone, r, block, hollow)
        end,
        cylinder = function(l, r, block, hollow)
            place_cylinder(drone, 'V', l, r, block, hollow)
        end,
        vertical = {
            cylinder = function(l, r, block, hollow)
                place_cylinder(drone, 'V', l, r, block, hollow)
            end
        },
        horizontal = {
            cylinder = function(l, r, block, hollow)
                place_cylinder(drone, 'H', l, r, block, hollow)
            end
        },
        centered = {
            cube = function(w, h, l, block, hollow)
                place_ccube(drone, w, h, l, block, hollow)
            end,
            sphere = function(r, block, hollow)
                place_csphere(drone, r, block, hollow)
            end,
            dome = function(r, block, hollow)
                place_cdome(drone, r, block, hollow)
            end,
            cylinder = function(l, r, block, hollow)
                place_ccylinder(drone, 'V', l, r, block, hollow)
            end,
            vertical = {
                cylinder = function(l, r, block, hollow)
                    place_ccylinder(drone, 'V', l, r, block, hollow)
                end
            },
            horizontal = {
                cylinder = function(l, r, block, hollow)
                    place_ccylinder(drone, 'H', l, r, block, hollow)
                end
            }
        },
        -- blocks: wools
        wools = wools,
        iwools = iwools,
        -- blocks: default
        blocks = cubes,
        plants = plants,
        -- vector3 commands
        vector = vector3,
        -- utilities
        get_block = function() return drone_get_block(drone) end,
        print = function(str) return send_message(drone, str) end,
        color = color,
        ipairs = ipairs,
        pairs = pairs,
        random = setmetatable({}, {
            __index = {
                block = table_randomizer(cubes),
                plant = table_randomizer(plants),
                wool = table_randomizer(wools)
            },
            __call = function(self, ...) return math.random(...) end
        }),
        table = {randomizer = table_randomizer},
        floor = math.floor,
        ceil = math.ceil,
        round = round,
        round0 = round0,
        deg = math.deg,
        rad = math.rad,
        exp = math.exp,
        log = math.log,
        max = math.max,
        min = math.min,
        pow = math.pow,
        sqrt = math.sqrt,
        abs = math.abs,
        sin = math.sin,
        sinh = math.sinh,
        asin = math.asin,
        cos = math.cos,
        cosh = math.cosh,
        acos = math.acos,
        tan = math.tan,
        tanh = math.tanh,
        atan = math.atan,
        atan2 = math.atan2,
        pi = math.pi,
        e = math.exp(1),
        error = error
    }

    env._G = {
        print = env.print,
        error = env.error,
        use_call = function() use_call(drone) end
    }
    return env

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

    local name = drone.name
    local filename = drone.file

    -- loading file
    local untrusted_code = codeblock.filesystem.read_file(name, filename, true)

    if not untrusted_code then
        return false, S("Compilation error in @1: ", filename) ..
                   S('@1 not found.', filename)
    end

    if untrusted_code:byte(1) == 27 then
        return false, S("Compilation error in @1: ", filename) ..
                   S("binary bytecode prohibited")
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
