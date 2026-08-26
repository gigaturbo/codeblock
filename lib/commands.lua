codeblock.commands = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local floor = math.floor
local abs = math.abs
local pi = math.pi
local upper = string.upper

local chat_send_player = minetest.chat_send_player
local set_node = minetest.set_node
local get_node = minetest.get_node
local load_area = minetest.load_area
local get_us_time = minetest.get_us_time

local build = codeblock.shapes.build

local S = codeblock.S
local table_reverse = codeblock.utils.table_reverse

local cubes_names = codeblock.config.allowed_blocks.cubes
local blocks = codeblock.config.allowed_blocks.all
local charge = codeblock.limits.charge
local hold = codeblock.limits.hold

-- Calls between checks. The instrumented counter runs on every loop iteration
-- and every function call, so this is how finely a program that issues no drone
-- command at all can be interrupted. A few hundred iterations of player code is
-- a handful of microseconds; reading the clock on each one would cost more than
-- the work being measured.
local CALLS_PER_CHECK = 256

-- The engine's own edge of the world, from mapgen_limit. Past it a write
-- silently does nothing, which is the lost write load_area was added to stop, so
-- the drone is kept inside it.
--
-- What replaced max_distance. Distance from spawn was never the resource - the
-- map footprint is, and that is charged where it is taken - and as a rule it
-- confused players, who could see a build they were not allowed to fly to.
local world_edge = tonumber(minetest.settings:get('mapgen_limit')) or 31000

local tmp1 = 2 * pi
local tmp2 = pi / 2
local tmp3 = 4 / 3 * pi
local tmp4 = 2 / 3 * pi
local rev_blocks = table_reverse(blocks)

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

local function round0(x) return floor(x + .5) end

--- Hand control back to the stepper.
--
-- Also the only place the mapblock memo below is dropped. The engine may unload
-- a block while the drone is not running (server_unload_unused_data_timeout,
-- 29s), so a memo that outlived a yield could skip a load that had become
-- necessary again, and the write would be lost with no error at all. (A4)
local function release(drone)
    drone.bx, drone.by, drone.bz = nil, nil, nil
    coroutine.yield()
end

--- Release control if this drone's slice of the server step is gone.
--
-- Checked at every command and before every slab of a bulk shape, which is what
-- makes the step budget bound work rather than resumes. lib/stepper.lua sets the
-- deadline; it is nil outside a step.
local function yield_if_spent(drone)
    if drone.deadline and get_us_time() >= drone.deadline then release(drone) end
end

--- Charge `n` nodes written to the run.
local function use_nodes(drone, n)
    if not charge(drone.budget, 'nodes', n) then
        error(S('Maximum number of nodes written (@1)', drone.budget.caps.nodes),
              4)
    end
end

--- Take `n` mapblocks of map footprint, waiting for room when there is none.
--
-- The one ceiling a program is not stopped for reaching: the engine frees idle
-- mapblocks by itself, so the honest answer to a program holding too much of the
-- map is to slow it down until it drains. See map_memory_mb in lib/config.lua
-- and limits.hold. A single request larger than the whole ceiling can never be
-- granted, and is the one case that raises.
local function use_map(drone, n)

    while true do
        local wait = hold(drone.budget, n, get_us_time())
        if wait == 0 then return end
        if not wait then
            error(S('Maximum map footprint exceeded (@1 MB)',
                    drone.budget.caps.map / 64), 4)
        end
        drone.wake_at = get_us_time() + wait
        release(drone)
    end

end

--- What lib/shapes.lua calls before each of its VoxelManip passes: take the
-- footprint that pass will pin, and start it on a fresh slice if this one is
-- already spent. A slab is around 10ms, so a large shape becomes many steps of
-- work rather than one long stall.
local function slabs(drone)
    return function(n)
        use_map(drone, n)
        yield_if_spent(drone)
    end
end

--- Place one node.
--
-- load_area first: set_node into a mapblock that is not in memory silently does
-- nothing, so a program that flew out and built left holes with no error at all.
--
-- Once per mapblock the drone crosses into rather than once per node. Comparing
-- floor(x/16) against the last block written is an exact test, not a guess, and
-- it turns a per-node cost into a per-block one. The memo is dropped at every
-- yield - see release() - because the engine may unload a block while the drone
-- is not running, so a memo that outlived a yield could skip a load that had
-- become necessary again and lose the write.
local function place_block(drone, x, y, z, block)

    local pos = {x = x, y = y, z = z}
    local bx, by, bz = floor(x / 16), floor(y / 16), floor(z / 16)

    if bx ~= drone.bx or by ~= drone.by or bz ~= drone.bz then
        use_map(drone, 1)
        drone.bx, drone.by, drone.bz = bx, by, bz
        load_area(pos)
    end

    set_node(pos, {name = block})

end

--- Charge one instrumented call: every loop iteration and every function call in
-- the player's program passes through here.
--
-- Nothing bounds the count any more - a program that loops for ever is stopped
-- by max_runtime_s, which is the resource it actually spends. What is left is
-- the cadence: releasing control every CALLS_PER_CHECK calls is what makes a
-- program containing no drone command interruptible at all, and that same point
-- is where heap growth is sampled. See heap_mb in config.lua for what the sample
-- does and does not catch - it stops a program that accumulates, not one that
-- allocates everything in a single call.
local function use_call(drone)

    local calls = drone.calls + 1
    drone.calls = calls
    if calls % CALLS_PER_CHECK ~= 0 then return end

    if drone.mem0 then
        local grown = collectgarbage('count') - drone.mem0
        if grown > drone.budget.caps.heap_kb then
            error(S('Memory limit exceeded (@1 MB)',
                    drone.budget.caps.heap_kb / 1024), 4)
        end
    end

    release(drone)

end

--- Finish a drone command: count it, then release control.
--
-- After the pace, at a codelevel that has one. That pace is what makes the
-- novice levels slow enough to watch, and it is what replaced the per-codelevel
-- yield cadence entirely: a paced drone yields on every command by construction,
-- and an unpaced one yields when its slice of the step runs out.
local function end_command(drone)

    drone.commands = drone.commands + 1

    local pace = drone.budget.caps.pace
    if pace > 0 then
        drone.wake_at = get_us_time() + pace
        release(drone)
    else
        yield_if_spent(drone)
    end

end

--- Keep the drone inside the world; see world_edge above.
local function check_inside_world(x, y, z)
    if abs(x) > world_edge or abs(y) > world_edge or abs(z) > world_edge then
        error(S('The drone cannot leave the world (@1 nodes)', world_edge), 4)
    end
end

-------------------------------------------------------------------------------
-- movements
-------------------------------------------------------------------------------

local function drone_move(drone, x, y, z)

    assert(drone, S("Error, drone does not exist"))

    local x = (type(x) == 'number') and round0(x) or 0
    local y = (type(y) == 'number') and round0(y) or 0
    local z = (type(z) == 'number') and round0(z) or 0

    local angle = drone:angle()

    if angle == 0 then
        drone.x = drone.x + x
        drone.y = drone.y + y
        drone.z = drone.z + z
    elseif angle == 1 then
        drone.x = drone.x - z
        drone.y = drone.y + y
        drone.z = drone.z + x
    elseif angle == 2 then
        drone.x = drone.x - x
        drone.y = drone.y + y
        drone.z = drone.z - z
    elseif angle == 3 then
        drone.x = drone.x + z
        drone.y = drone.y + y
        drone.z = drone.z - x
    end

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_forward(drone, n)

    assert(drone, S("Error, drone does not exist"))

    local n = (type(n) == 'number') and round0(n) or 1

    local angle = drone:angle()

    if angle == 0 then
        drone.z = drone.z + n
    elseif angle == 1 then
        drone.x = drone.x - n
    elseif angle == 2 then
        drone.z = drone.z - n
    elseif angle == 3 then
        drone.x = drone.x + n
    end

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_back(drone, n)

    assert(drone, S("Error, drone does not exist"))

    local n = (type(n) == 'number') and round0(n) or 1

    local angle = drone:angle()

    if angle == 0 then
        drone.z = drone.z - n
    elseif angle == 1 then
        drone.x = drone.x + n
    elseif angle == 2 then
        drone.z = drone.z + n
    elseif angle == 3 then
        drone.x = drone.x - n
    end

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_right(drone, n)

    assert(drone, S("Error, drone does not exist"))

    local n = (type(n) == 'number') and round0(n) or 1

    local angle = drone:angle()

    if angle == 0 then
        drone.x = drone.x + n
    elseif angle == 1 then
        drone.z = drone.z + n
    elseif angle == 2 then
        drone.x = drone.x - n
    elseif angle == 3 then
        drone.z = drone.z - n
    end

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_left(drone, n)

    assert(drone, S("Error, drone does not exist"))

    local n = (type(n) == 'number') and round0(n) or 1

    local angle = drone:angle()

    if angle == 0 then
        drone.x = drone.x - n
    elseif angle == 1 then
        drone.z = drone.z - n
    elseif angle == 2 then
        drone.x = drone.x + n
    elseif angle == 3 then
        drone.z = drone.z + n
    end

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_up(drone, n)

    assert(drone, S("Error, drone does not exist"))

    local n = (type(n) == 'number') and round0(n) or 1

    drone.y = drone.y + n

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_down(drone, n)

    assert(drone, S("Error, drone does not exist"))

    local n = (type(n) == 'number') and round0(n) or 1

    drone.y = drone.y - n

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

local function drone_turn_left(drone)

    assert(drone, S("Error, drone does not exist"))

    drone.dir = (drone.dir + tmp2) % tmp1

    drone:update_entity()
    end_command(drone)

end

local function drone_turn_right(drone)

    assert(drone, S("Error, drone does not exist"))

    drone.dir = (drone.dir - tmp2) % tmp1

    drone:update_entity()
    end_command(drone)

end

local function drone_turn(drone, quarters)

    assert(drone, S("Error, drone does not exist"))

    local quarters = (type(quarters) == 'number') and round0(quarters) or 0

    drone.dir = (drone.dir + quarters * tmp2) % tmp1

    drone:update_entity()
    end_command(drone)

end

-------------------------------------------------------------------------------
-- blocks
-------------------------------------------------------------------------------

local function drone_place_block(drone, block)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    use_nodes(drone, 1)

    place_block(drone, drone.x, drone.y, drone.z, real_block)
    end_command(drone)

end

local function drone_place_relative(drone, x, y, z, block, chkpt)

    assert(drone, S("Error, drone does not exist"))

    local x = (type(x) == 'number') and round0(x) or 0
    local y = (type(y) == 'number') and round0(y) or 0
    local z = (type(z) == 'number') and round0(z) or 0

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local chkpt = (type(chkpt) == 'string') and chkpt or 'spawn'
    if not drone.checkpoints[chkpt] then
        error(S('Checkpoint @1 does not exists', chkpt))
    end
    local cp = drone.checkpoints[chkpt]

    use_nodes(drone, 1)

    local angle = drone:angle()
    if angle == 0 then
        drone.x = cp.x + x
        drone.y = cp.y + y
        drone.z = cp.z + z
        drone.dir = cp.dir
    elseif angle == 1 then
        drone.x = cp.x - z
        drone.y = cp.y + y
        drone.z = cp.z + x
        drone.dir = cp.dir
    elseif angle == 2 then
        drone.x = cp.x - x
        drone.y = cp.y + y
        drone.z = cp.z - z
        drone.dir = cp.dir
    elseif angle == 3 then
        drone.x = cp.x + z
        drone.y = cp.y + y
        drone.z = cp.z - x
        drone.dir = cp.dir
    end

    check_inside_world(drone.x, drone.y, drone.z)

    drone:update_entity()
    place_block(drone, drone.x, drone.y, drone.z, real_block)
    end_command(drone)

end

-------------------------------------------------------------------------------
-- shapes
-------------------------------------------------------------------------------

local function drone_place_cube(drone, w, h, l, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
    local w = (type(w) == 'number') and round0(abs(w)) or 10
    local h = (type(h) == 'number') and round0(abs(h)) or 10
    local l = (type(l) == 'number') and round0(abs(l)) or 10
    local x
    local y = drone.y
    local z

    use_nodes(drone, w * h * l)

    local angle = drone:angle()
    if angle == 0 then
        w, l = w, l
        x = drone.x + floor(w * 0.5)
        z = drone.z + floor(l * 0.5)
    elseif angle == 1 then
        w, l = l, w
        x = drone.x - floor((w - 1) * 0.5)
        z = drone.z - floor((l - 1) * 0.5) + l - 1
    elseif angle == 2 then
        w, l = w, l
        x = drone.x - floor((w - 1) * 0.5)
        z = drone.z - floor((l - 1) * 0.5)
    elseif angle == 3 then
        w, l = l, w
        x = drone.x + floor(w * 0.5)
        z = drone.z + floor(l * 0.5) - l + 1
    end

    local pos = {x = x, y = y, z = z}

    build {
        charge = slabs(drone),
        kind = 'cube',
        pos = pos,
        w = w,
        h = h,
        l = l,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_ccube(drone, w, h, l, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
    local w = (type(w) == 'number') and round0(abs(w)) or 10
    local h = (type(h) == 'number') and round0(abs(h)) or 10
    local l = (type(l) == 'number') and round0(abs(l)) or 10

    use_nodes(drone, w * h * l)

    local angle = drone:angle()
    if angle == 0 then
        w, l = w, l
    elseif angle == 1 then
        w, l = l, w
    elseif angle == 2 then
        w, l = w, l
    elseif angle == 3 then
        w, l = l, w
    end

    local pos = {x = drone.x, y = drone.y - floor(0.5 * (h - 1)), z = drone.z}

    build {
        charge = slabs(drone),
        kind = 'cube',
        pos = pos,
        w = w,
        h = h,
        l = l,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_sphere(drone, r, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
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

    local pos = {x = x, y = y, z = z}

    build {
        charge = slabs(drone),
        kind = 'sphere',
        pos = pos,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_csphere(drone, r, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
    local r = (type(r) == 'number') and round0(abs(r)) or 5
    local pos = {x = round0(drone.x), y = round0(drone.y), z = round0(drone.z)}

    use_nodes(drone, round0(tmp3 * (r + 0.514) ^ 3))

    build {
        charge = slabs(drone),
        kind = 'sphere',
        pos = pos,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_dome(drone, r, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
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

    local pos = {x = x, y = y, z = z}

    build {
        charge = slabs(drone),
        kind = 'dome',
        pos = pos,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_cdome(drone, r, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
    local r = (type(r) == 'number') and round0(abs(r)) or 5
    local pos = {x = drone.x, y = drone.y, z = drone.z}

    use_nodes(drone, round0(tmp4 * (r + 0.514) ^ 3))

    build {
        charge = slabs(drone),
        kind = 'dome',
        pos = pos,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_cylinder(drone, o, l, r, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
    local o = (type(o) == 'string') and upper(o) or 'V'
    local l = (type(l) == 'number') and round0(abs(l)) or 10
    local r = (type(r) == 'number') and round0(abs(r)) or 5

    use_nodes(drone, round0((pi * l * (r + 0.514) ^ 2)))

    local axis
    local angle = drone:angle()
    if (o == 'V') then
        axis = 'y'
    elseif (o == 'H') then
        if angle == 0 then
            axis = 'z'
        elseif angle == 1 then
            axis = 'x'
        elseif angle == 2 then
            axis = 'z'
        elseif angle == 3 then
            axis = 'x'
        end
    else
        axis = 'y'
    end

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

    local pos = {x = x, y = y, z = z}

    build {
        charge = slabs(drone),
        kind = 'cylinder',
        pos = pos,
        axis = axis,
        l = l,
        r = r,
        node = real_block,
        hollow = hollow
    }
    end_command(drone)

end

local function drone_place_ccylinder(drone, o, l, r, block, hollow)

    assert(drone, S("Error, drone does not exist"))

    block = block or cubes_names.stone
    local real_block = blocks[block]
    if not real_block then error(S('Cannot place this block'), 3) end

    local hollow = (hollow == nil) and false or (hollow and true or false)
    local o = (type(o) == 'string') and upper(o) or 'V'
    local l = (type(l) == 'number') and round0(abs(l)) or 10
    local r = (type(r) == 'number') and round0(abs(r)) or 5

    use_nodes(drone, round0((pi * l * (r + 0.514) ^ 2)))

    local axis
    local x, y, z
    local angle = drone:angle()
    if (o == 'V') then
        axis = 'y'
        x = drone.x
        y = drone.y - floor(0.5 * (l - 1))
        z = drone.z
    elseif (o == 'H') then
        y = drone.y
        if angle == 0 then
            axis = 'z'
            x = drone.x
            z = drone.z - floor(l / 2)
        elseif angle == 1 then
            axis = 'x'
            x = drone.x - floor(l / 2)
            z = drone.z
        elseif angle == 2 then
            axis = 'z'
            x = drone.x
            z = drone.z - floor(l / 2)
        elseif angle == 3 then
            axis = 'x'
            x = drone.x - floor(l / 2)
            z = drone.z
        end
    else
        axis = 'y'
    end

    local pos = {x = x, y = y, z = z}

    build {
        charge = slabs(drone),
        kind = 'cylinder',
        pos = pos,
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

    local chkpt = (type(chkpt) == 'string') and chkpt or 'spawn'
    if not drone.checkpoints[chkpt] then
        error(S('Checkpoint @1 does not exists', chkpt))
    end
    local cp = drone.checkpoints[chkpt]

    local angle = drone:angle()

    if angle == 0 then
        drone.x = cp.x + x
        drone.y = cp.y + y
        drone.z = cp.z + z
    elseif angle == 1 then
        drone.x = cp.x - z
        drone.y = cp.y + y
        drone.z = cp.z + x
    elseif angle == 2 then
        drone.x = cp.x - x
        drone.y = cp.y + y
        drone.z = cp.z - z
    elseif angle == 3 then
        drone.x = cp.x + z
        drone.y = cp.y + y
        drone.z = cp.z - x
    end

    check_inside_world(drone.x, drone.y, drone.z)
    drone:update_entity()
    end_command(drone)

end

-------------------------------------------------------------------------------
-- utilities
-------------------------------------------------------------------------------

local function drone_get_block(drone)

    assert(drone, S("Error, drone does not exist"))

    local block_name = get_node({x = drone.x, y = drone.y, z = drone.z}).name

    if block_name == 'ignore' then
        end_command(drone)
        return nil
    else
        end_command(drone)
        local rblock = rev_blocks[block_name]
        if rblock then
            return rblock
        else
            return false
        end
    end

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
-- shapes
codeblock.commands.drone_place_cube = drone_place_cube
codeblock.commands.drone_place_ccube = drone_place_ccube
codeblock.commands.drone_place_sphere = drone_place_sphere
codeblock.commands.drone_place_csphere = drone_place_csphere
codeblock.commands.drone_place_dome = drone_place_dome
codeblock.commands.drone_place_cdome = drone_place_cdome
codeblock.commands.drone_place_cylinder = drone_place_cylinder
codeblock.commands.drone_place_ccylinder = drone_place_ccylinder
-- utilities
codeblock.commands.drone_send_message = drone_send_message
codeblock.commands.drone_use_call = use_call
codeblock.commands.drone_get_block = drone_get_block
