--- What a drone command costs the run, and when it gives the server its step
-- back.
--
-- Every ceiling itself lives in lib/limits.lua; this is the layer between it and
-- the commands in lib/commands.lua. Spent resources - nodes written, calls made
-- - are charged and stop the run when they are gone. The one held resource, map
-- footprint, makes the drone wait instead, because the engine frees idle
-- mapblocks by itself.
--
-- Yielding is here for the same reason: what a command costs and when it hands
-- control back are the same question, and the mapblock memo in place_block is
-- only correct because release() is the single yield in this file. (A3)
--
-- Errors raised here use level 4: this function, its command, the sandbox
-- closure, and then the player's own line, which is the one worth naming.

codeblock.cost = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local floor = math.floor

local set_node = minetest.set_node
local load_area = minetest.load_area
local get_us_time = minetest.get_us_time

local S = codeblock.S
local charge = codeblock.limits.charge
local hold = codeblock.limits.hold

-- Calls between checks. The instrumented counter runs on every loop iteration
-- and every function call, so this is how finely a program that issues no drone
-- command at all can be interrupted. A few hundred iterations of player code is
-- a handful of microseconds; reading the clock on each one would cost more than
-- the work being measured.
local CALLS_PER_CHECK = 256

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- charging
-------------------------------------------------------------------------------

--- Charge `n` nodes written to the run.
local function use_nodes(drone, n)
    if not charge(drone.budget, 'nodes', n) then
        error(S('Maximum number of nodes written (@1)', drone.budget.caps.nodes),
              4)
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

-------------------------------------------------------------------------------
-- writing
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

codeblock.cost.use_nodes = use_nodes
codeblock.cost.slabs = slabs
codeblock.cost.use_call = use_call
codeblock.cost.end_command = end_command
codeblock.cost.place_block = place_block
