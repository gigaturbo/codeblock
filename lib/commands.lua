--- Everything a player's program can make the drone do.
--
-- One function per name in lib/api.lua, all of the same shape: coerce what the
-- program passed, work out where the drone ends up, write, then end_command.
-- What any of it costs and when it yields is lib/cost.lua's; the geometry of a
-- bulk shape is lib/shapes.lua's. This file is the arithmetic in between - how a
-- drone-relative instruction becomes world coordinates.
--
-- Errors raised here use level 3: this function, the sandbox closure, and then
-- the player's own line.

codeblock.commands = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local floor = math.floor
local abs = math.abs
local pi = math.pi
local upper = string.upper

local chat_send_player = core.chat_send_player
local get_node = core.get_node

local build = codeblock.shapes.build

local use_nodes = codeblock.cost.use_nodes
local slabs = codeblock.cost.slabs
local use_call = codeblock.cost.use_call
local end_command = codeblock.cost.end_command
local place_block = codeblock.cost.place_block

local S = codeblock.S
local table_reverse = codeblock.utils.table_reverse

local cubes_names = codeblock.config.allowed_blocks.cubes
local blocks = codeblock.config.allowed_blocks.all

-- The engine's own edge of the world, from mapgen_limit. Past it a write
-- silently does nothing, which is the lost write load_area was added to stop, so
-- the drone is kept inside it.
--
-- What replaced max_distance. Distance from spawn was never the resource - the
-- map footprint is, and that is charged where it is taken - and as a rule it
-- confused players, who could see a build they were not allowed to fly to.
local world_edge = tonumber(core.settings:get('mapgen_limit')) or 31000

local tmp1 = 2 * pi
local tmp2 = pi / 2
local tmp3 = 4 / 3 * pi
local tmp4 = 2 / 3 * pi
local rev_blocks = table_reverse(blocks)

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

local function round0(x) return floor(x + .5) end

--- Turn a drone-relative offset into a world one, by quarter-turn.
--
-- The drone's own axes are x to its right, y up, z ahead. Every command that
-- moves relative to where the drone is facing goes through here, which is what
-- the seven near-identical movement functions were spelling out one axis at a
-- time. (A3)
local rotate = {
    [0] = function(x, y, z) return x, y, z end,
    [1] = function(x, y, z) return -z, y, x end,
    [2] = function(x, y, z) return -x, y, -z end,
    [3] = function(x, y, z) return z, y, -x end
}

--- Keep the drone inside the world; see world_edge above.
local function check_inside_world(x, y, z)
    if abs(x) > world_edge or abs(y) > world_edge or abs(z) > world_edge then
        error(S('The drone cannot leave the world (@1 nodes)', world_edge), 4)
    end
end

--- The opening every placement command shares: the drone has to exist, the
-- block has to be one a program may place, and hollow is a boolean whatever the
-- program passed. Returns the node name and that flag. (A3)
--
-- Level 4 rather than the 3 the commands themselves use, because raising from
-- in here puts one more frame between the message and the player's line.
local function placement(drone, block, hollow)
    assert(drone, S("Error, drone does not exist"))
    local real_block = blocks[block or cubes_names.stone]
    if not real_block then error(S('Cannot place this block'), 4) end
    return real_block, (hollow and true or false)
end

--- The named checkpoint, or an error naming it.
local function checkpoint(drone, chkpt)
    local chkpt = (type(chkpt) == 'string') and chkpt or 'spawn'
    local cp = drone.checkpoints[chkpt]
    if not cp then error(S('Checkpoint @1 does not exists', chkpt)) end
    return cp
end

-------------------------------------------------------------------------------
-- movements
-------------------------------------------------------------------------------

--- Move the drone by an offset in its own axes: x to its right, y up, z ahead.
--
-- All seven movement commands are this function with different arguments, which
-- is what they used to spell out one axis and one quarter-turn at a time. (A3)
-- Each of them calls it directly rather than through move(), so the player's
-- line stays at the same stack level from every one of them - Lua counts the
-- extra frame even when the call is a tail call.
local function move_by(drone, x, y, z)

    assert(drone, S("Error, drone does not exist"))

    local dx, dy, dz = rotate[drone:angle()](x, y, z)
    drone.x, drone.y, drone.z = drone.x + dx, drone.y + dy, drone.z + dz

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

--- A distance in one axis defaults to 1; the three of move() default to 0.
local function steps(n) return (type(n) == 'number') and round0(n) or 1 end

local function drone_move(drone, x, y, z)
    move_by(drone, (type(x) == 'number') and round0(x) or 0,
            (type(y) == 'number') and round0(y) or 0,
            (type(z) == 'number') and round0(z) or 0)
end

local function drone_forward(drone, n) move_by(drone, 0, 0, steps(n)) end

local function drone_back(drone, n) move_by(drone, 0, 0, -steps(n)) end

local function drone_right(drone, n) move_by(drone, steps(n), 0, 0) end

local function drone_left(drone, n) move_by(drone, -steps(n), 0, 0) end

local function drone_up(drone, n) move_by(drone, 0, steps(n), 0) end

local function drone_down(drone, n) move_by(drone, 0, -steps(n), 0) end

--- Turn by whole quarter-turns, anticlockwise seen from above.
local function turn_by(drone, quarters)

    assert(drone, S("Error, drone does not exist"))

    drone.dir = (drone.dir + quarters * tmp2) % tmp1

    drone:update_entity()
    end_command(drone)

end

local function drone_turn(drone, quarters)
    turn_by(drone, (type(quarters) == 'number') and round0(quarters) or 0)
end

local function drone_turn_left(drone) turn_by(drone, 1) end

local function drone_turn_right(drone) turn_by(drone, -1) end

-------------------------------------------------------------------------------
-- blocks
-------------------------------------------------------------------------------

local function drone_place_block(drone, block)

    local real_block = placement(drone, block)

    use_nodes(drone, 1)

    place_block(drone, drone.x, drone.y, drone.z, real_block)
    end_command(drone)

end

local function drone_place_relative(drone, x, y, z, block, chkpt)

    local real_block = placement(drone, block)

    local x = (type(x) == 'number') and round0(x) or 0
    local y = (type(y) == 'number') and round0(y) or 0
    local z = (type(z) == 'number') and round0(z) or 0

    local cp = checkpoint(drone, chkpt)

    use_nodes(drone, 1)

    local dx, dy, dz = rotate[drone:angle()](x, y, z)
    drone.x, drone.y, drone.z = cp.x + dx, cp.y + dy, cp.z + dz
    drone.dir = cp.dir

    check_inside_world(drone.x, drone.y, drone.z)

    drone:update_entity()
    place_block(drone, drone.x, drone.y, drone.z, real_block)
    end_command(drone)

end

-------------------------------------------------------------------------------
-- shapes
--
-- Each of these works out where the shape's own origin lands given where the
-- drone is and which way it faces, then hands lib/shapes.lua a spec. The `c`
-- variants centre the shape on the drone instead of growing it away from it.
-------------------------------------------------------------------------------

local function drone_place_cube(drone, w, h, l, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local w = (type(w) == 'number') and round0(abs(w)) or 10
    local h = (type(h) == 'number') and round0(abs(h)) or 10
    local l = (type(l) == 'number') and round0(abs(l)) or 10
    local x
    local y = drone.y
    local z

    use_nodes(drone, w * h * l)

    local angle = drone:angle()
    if angle == 0 then
        x = drone.x + floor(w * 0.5)
        z = drone.z + floor(l * 0.5)
    elseif angle == 1 then
        w, l = l, w
        x = drone.x - floor((w - 1) * 0.5)
        z = drone.z - floor((l - 1) * 0.5) + l - 1
    elseif angle == 2 then
        x = drone.x - floor((w - 1) * 0.5)
        z = drone.z - floor((l - 1) * 0.5)
    elseif angle == 3 then
        w, l = l, w
        x = drone.x + floor(w * 0.5)
        z = drone.z + floor(l * 0.5) - l + 1
    end

    build {
        charge = slabs(drone),
        kind = 'cube',
        pos = {x = x, y = y, z = z},
        w = w,
        h = h,
        l = l,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_ccube(drone, w, h, l, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local w = (type(w) == 'number') and round0(abs(w)) or 10
    local h = (type(h) == 'number') and round0(abs(h)) or 10
    local l = (type(l) == 'number') and round0(abs(l)) or 10

    use_nodes(drone, w * h * l)

    -- Facing along x rather than z swaps width for length; the centre does not
    -- move, so there is nothing else to work out.
    if drone:angle() % 2 == 1 then w, l = l, w end

    build {
        charge = slabs(drone),
        kind = 'cube',
        pos = {x = drone.x, y = drone.y - floor(0.5 * (h - 1)), z = drone.z},
        w = w,
        h = h,
        l = l,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_sphere(drone, r, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local r = (type(r) == 'number') and round0(abs(r)) or 5
    local x
    local y = drone.y + r
    local z

    use_nodes(drone, round0(tmp3 * (r + 0.514) ^ 3))

    local angle = drone:angle()
    if angle == 0 then
        x = drone.x + r
        z = drone.z + r
    elseif angle == 1 then
        x = drone.x - r
        z = drone.z + r
    elseif angle == 2 then
        x = drone.x - r
        z = drone.z - r
    elseif angle == 3 then
        x = drone.x + r
        z = drone.z - r
    end

    build {
        charge = slabs(drone),
        kind = 'sphere',
        pos = {x = x, y = y, z = z},
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_csphere(drone, r, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local r = (type(r) == 'number') and round0(abs(r)) or 5

    use_nodes(drone, round0(tmp3 * (r + 0.514) ^ 3))

    build {
        charge = slabs(drone),
        kind = 'sphere',
        pos = {
            x = round0(drone.x),
            y = round0(drone.y),
            z = round0(drone.z)
        },
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_dome(drone, r, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local r = (type(r) == 'number') and round0(abs(r)) or 5
    local x
    local y = drone.y
    local z

    use_nodes(drone, round0(tmp4 * (r + 0.514) ^ 3))

    local angle = drone:angle()
    if angle == 0 then
        x = drone.x + r
        z = drone.z + r
    elseif angle == 1 then
        x = drone.x - r
        z = drone.z + r
    elseif angle == 2 then
        x = drone.x - r
        z = drone.z - r
    elseif angle == 3 then
        x = drone.x + r
        z = drone.z - r
    end

    build {
        charge = slabs(drone),
        kind = 'dome',
        pos = {x = x, y = y, z = z},
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_cdome(drone, r, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local r = (type(r) == 'number') and round0(abs(r)) or 5

    use_nodes(drone, round0(tmp4 * (r + 0.514) ^ 3))

    build {
        charge = slabs(drone),
        kind = 'dome',
        pos = {x = drone.x, y = drone.y, z = drone.z},
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

--- Vertical unless the program asked for horizontal.
--
-- Anything else used to fall through to an arm that named an axis and left the
-- coordinates nil, which reached lib/shapes.lua as a nil bound. Only two
-- orientations exist now, so there is no third arm to get wrong. (B18)
local function orientation(o)
    return (type(o) == 'string' and upper(o) == 'H') and 'H' or 'V'
end

local function drone_place_cylinder(drone, o, l, r, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local o = orientation(o)
    local l = (type(l) == 'number') and round0(abs(l)) or 10
    local r = (type(r) == 'number') and round0(abs(r)) or 5

    use_nodes(drone, round0((pi * l * (r + 0.514) ^ 2)))

    local angle = drone:angle()
    -- Laid down, the cylinder runs along whichever world axis the drone faces.
    local axis = (o == 'V') and 'y' or ((angle % 2 == 0) and 'z' or 'x')

    local iX = (axis == 'x' and 1 or 0)
    local iY = (axis == 'y' and 1 or 0)
    local iZ = (axis == 'z' and 1 or 0)
    local x
    local y
    local z

    if angle == 0 then
        x = drone.x + r
        y = drone.y + r * (1 - iY)
        z = drone.z + r * iY
    elseif angle == 1 then
        x = drone.x - r * iY - (l - 1) * iX
        y = drone.y + r * (1 - iY)
        z = drone.z + r
    elseif angle == 2 then
        x = drone.x - r
        y = drone.y + r * (1 - iY)
        z = drone.z - r * iY - (l - 1) * iZ
    elseif angle == 3 then
        x = drone.x + r * iY
        y = drone.y + r * (1 - iY)
        z = drone.z - r
    end

    build {
        charge = slabs(drone),
        kind = 'cylinder',
        pos = {x = x, y = y, z = z},
        axis = axis,
        l = l,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_ccylinder(drone, o, l, r, block, hollow)

    local real_block, hollow = placement(drone, block, hollow)

    local o = orientation(o)
    local l = (type(l) == 'number') and round0(abs(l)) or 10
    local r = (type(r) == 'number') and round0(abs(r)) or 5

    use_nodes(drone, round0((pi * l * (r + 0.514) ^ 2)))

    local angle = drone:angle()
    local axis = (o == 'V') and 'y' or ((angle % 2 == 0) and 'z' or 'x')

    -- Centred, so the shape starts half its length back along whichever axis it
    -- runs on and stays where the drone is on the other two.
    local x, y, z = drone.x, drone.y, drone.z
    if axis == 'y' then
        y = drone.y - floor(0.5 * (l - 1))
    elseif axis == 'z' then
        z = drone.z - floor(l / 2)
    else
        x = drone.x - floor(l / 2)
    end

    build {
        charge = slabs(drone),
        kind = 'cylinder',
        pos = {x = x, y = y, z = z},
        axis = axis,
        l = l,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

-------------------------------------------------------------------------------
-- checkpoints
-------------------------------------------------------------------------------

local function drone_save_checkpoint(drone, chkpt)

    assert(drone, S("Error, drone does not exist"))

    if type(chkpt) ~= 'string' then error(S('Checkpoint name is incorrect')) end

    drone.checkpoints[chkpt] = {
        x = drone.x,
        y = drone.y,
        z = drone.z,
        dir = drone.dir
    }

    end_command(drone)

end

local function drone_goto_checkpoint(drone, chkpt, x, y, z)

    assert(drone, S("Error, drone does not exist"))

    local x = (type(x) == 'number') and round0(x) or 0
    local y = (type(y) == 'number') and round0(y) or 0
    local z = (type(z) == 'number') and round0(z) or 0

    local cp = checkpoint(drone, chkpt)

    local dx, dy, dz = rotate[drone:angle()](x, y, z)
    drone.x, drone.y, drone.z = cp.x + dx, cp.y + dy, cp.z + dz

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

-------------------------------------------------------------------------------
-- utilities
-------------------------------------------------------------------------------

--- The block the drone is standing in: its player-facing name, false for a node
-- no program can place, and nil where the map is not loaded.
local function drone_get_block(drone)

    assert(drone, S("Error, drone does not exist"))

    local block_name = get_node({x = drone.x, y = drone.y, z = drone.z}).name

    end_command(drone)

    if block_name == 'ignore' then return nil end
    return rev_blocks[block_name] or false

end

-------------------------------------------------------------------------------
-- message
-------------------------------------------------------------------------------

local function drone_send_message(drone, string)

    assert(drone, S("Error, drone does not exist"))

    chat_send_player(drone.name, '> ' .. tostring(string))
    end_command(drone)
end

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

-- movements
codeblock.commands.drone_move = drone_move
codeblock.commands.drone_forward = drone_forward
codeblock.commands.drone_back = drone_back
codeblock.commands.drone_right = drone_right
codeblock.commands.drone_left = drone_left
codeblock.commands.drone_up = drone_up
codeblock.commands.drone_down = drone_down
codeblock.commands.drone_turn_left = drone_turn_left
codeblock.commands.drone_turn_right = drone_turn_right
codeblock.commands.drone_turn = drone_turn
codeblock.commands.drone_place_block = drone_place_block
codeblock.commands.drone_place_relative = drone_place_relative
codeblock.commands.drone_save_checkpoint = drone_save_checkpoint
codeblock.commands.drone_goto_checkpoint = drone_goto_checkpoint

codeblock.commands.drone_place_cube = drone_place_cube
codeblock.commands.drone_place_ccube = drone_place_ccube
codeblock.commands.drone_place_sphere = drone_place_sphere
codeblock.commands.drone_place_csphere = drone_place_csphere
codeblock.commands.drone_place_dome = drone_place_dome
codeblock.commands.drone_place_cdome = drone_place_cdome
codeblock.commands.drone_place_cylinder = drone_place_cylinder
codeblock.commands.drone_place_ccylinder = drone_place_ccylinder

codeblock.commands.drone_send_message = drone_send_message
codeblock.commands.drone_use_call = use_call
codeblock.commands.drone_get_block = drone_get_block
