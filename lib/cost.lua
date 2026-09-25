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
-- control back are the same question, and the mapblock memo in load_block is
-- only correct because release() is the single yield in this file. (A3)
--
-- Errors raised here use level 4: this function, its command, the sandbox
-- closure, and then the player's own line, which is the one worth naming.

codeblock.cost = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

local set_node = core.set_node
local load_area = core.load_area
local emerge_area = core.emerge_area
local get_us_time = core.get_us_time
local EMERGE_CANCELLED = core.EMERGE_CANCELLED
local EMERGE_ERRORED = core.EMERGE_ERRORED

local wait_for_mapgen = codeblock.config.wait_for_mapgen

local S = codeblock.S
local charge = codeblock.limits.charge
local hold = codeblock.limits.hold
local flush = codeblock.shapes.flush

-- Calls between checks. The instrumented counter runs on every loop iteration
-- and every function call, so this is how finely a program that issues no drone
-- command at all can be interrupted. A few hundred iterations of player code is
-- a handful of microseconds; reading the clock on each one would cost more than
-- the work being measured.
local CALLS_PER_CHECK = 256

-- How a drone waiting for mapgen sleeps, in microseconds. POLL is shorter than
-- any server step and longer than one resume, so the drone looks again once a
-- step. BUSY is the pause before asking again for a chunk another emerge thread
-- was generating, at most RETRIES times: a chunk whose border crosses
-- mapgen_limit answers busy for ever, and is never generated, so it is safe to
-- write after. GIVE_UP bounds a wait whose answer never comes.
local POLL_US = 1000
local BUSY_US = 250000
local RETRIES = 20
local GIVE_UP_US = 120e6

-- Mapchunks known to be generated, keyed by chunk_key. A chunk is generated
-- once, so an entry stays true for the server's life, unless core.delete_area
-- removes its blocks. Filled from emerge_area callbacks only.
local generated = {}

-- The mapchunk size, in mapblocks per axis, and the mapblocks mapgen can reach.
-- Read on the first wait: the mapgen is set up after every mod has loaded.
local chunk, reach_lo, reach_hi

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
-- Checked at every command and before every box of a bulk shape, which is what
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

--- The mapchunk holding mapblock (x, y, z), in chunks per axis.
-- The engine's alignment: a chunk starts half a chunk below the origin, so at
-- the default 5 mapblocks they span nodes -32 to 47.
local function chunk_of(x, y, z)
    local c = chunk
    return floor((x + floor(c.x / 2)) / c.x), floor((y + floor(c.y / 2)) / c.y),
           floor((z + floor(c.z / 2)) / c.z)
end

--- One number for chunk (x, y, z), exact for any chunk inside mapgen_limit.
local function chunk_key(x, y, z)
    return ((x + 4096) * 8192 + y + 4096) * 8192 + z + 4096
end

--- Wait until no mapchunk being generated can overwrite mapblocks b1 to b2.
--
-- The emerge thread generates a mapchunk from a copy of it and a one-mapblock
-- border, then writes the copy back over anything written there meanwhile, with
-- no error (B-S-3). So a write is safe once every chunk within one mapblock of
-- it is generated. They are asked for with emerge_area, and the drone sleeps
-- until every mapblock has answered. Nothing is asked when all are known.
--
-- The request loads the border as well, so its footprint is charged here: the
-- caller has charged b1 to b2 already. Clipped to what mapgen can reach, since
-- a mapblock outside the world never answers. May yield, through release().
local function wait_for_map(drone, b1, b2)

    if not wait_for_mapgen then return end
    if not chunk then
        -- While mods load no mapgen runs, so nothing can be overwritten, and no
        -- step comes to deliver an answer. The in-engine specs run then.
        if core.get_current_modname() then return end
        chunk = core.get_mapgen_chunksize and core.get_mapgen_chunksize()
        if not chunk then
            local n = tonumber(core.get_mapgen_setting('chunksize')) or 5
            chunk = {x = n, y = n, z = n}
        end
        local e = tonumber(core.get_mapgen_setting('mapgen_limit')) or 31007
        local lo, hi = {x = -e, y = -e, z = -e}, {x = e, y = e, z = e}
        if core.get_mapgen_edges then lo, hi = core.get_mapgen_edges() end
        -- Only mapblocks wholly inside.
        reach_lo = {x = ceil(lo.x / 16), y = ceil(lo.y / 16), z = ceil(lo.z / 16)}
        reach_hi = {x = floor((hi.x + 1) / 16) - 1, y = floor((hi.y + 1) / 16) - 1,
                    z = floor((hi.z + 1) / 16) - 1}
    end

    local lo = {x = max(b1.x - 1, reach_lo.x), y = max(b1.y - 1, reach_lo.y),
                z = max(b1.z - 1, reach_lo.z)}
    local hi = {x = min(b2.x + 1, reach_hi.x), y = min(b2.y + 1, reach_hi.y),
                z = min(b2.z + 1, reach_hi.z)}
    if lo.x > hi.x or lo.y > hi.y or lo.z > hi.z then return end

    local ax, ay, az = chunk_of(lo.x, lo.y, lo.z)
    local bx, by, bz = chunk_of(hi.x, hi.y, hi.z)
    local nx, ny = bx - ax + 1, by - ay + 1
    local known = true
    for i = 0, nx * ny * (bz - az + 1) - 1 do
        local x, y, z = i % nx, floor(i / nx) % ny, floor(i / (nx * ny))
        if not generated[chunk_key(ax + x, ay + y, az + z)] then
            known = false
            break
        end
    end
    if known then return end

    use_map(drone, max(0, (hi.x - lo.x + 1) * (hi.y - lo.y + 1) * (hi.z - lo.z + 1) -
                           (b2.x - b1.x + 1) * (b2.y - b1.y + 1) * (b2.z - b1.z + 1)))

    -- The callback touches no drone, so one outliving a stopped run is harmless.
    local pos1 = {x = lo.x * 16, y = lo.y * 16, z = lo.z * 16}
    local pos2 = {x = hi.x * 16 + 15, y = hi.y * 16 + 15, z = hi.z * 16 + 15}
    local started = get_us_time()
    for _ = 0, RETRIES do
        local ask = {pending = true, busy = false}
        emerge_area(pos1, pos2, function(bp, action, remaining)
            if action == EMERGE_CANCELLED then
                ask.busy = true
            elseif action ~= EMERGE_ERRORED then
                generated[chunk_key(chunk_of(bp.x, bp.y, bp.z))] = true
            end
            if remaining == 0 then ask.pending = false end
        end)
        while ask.pending do
            if get_us_time() - started > GIVE_UP_US then
                core.log('warning', '[codeblock] no answer from mapgen at ' ..
                             core.pos_to_string(pos1) .. '; writing anyway')
                return
            end
            drone.wake_at = get_us_time() + POLL_US
            release(drone)
        end
        if not ask.busy then return end
        drone.wake_at = get_us_time() + BUSY_US
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
-- footprint that pass will pin, wait for the map around it to be generated,
-- and start it on a fresh slice if this one is already spent. A box is under
-- 10ms, so a large shape becomes many steps of work rather than one long stall.
local function slabs(drone)
    return function(n, lo, hi)
        use_map(drone, n)
        wait_for_map(drone,
                     {x = floor(lo.x / 16), y = floor(lo.y / 16), z = floor(lo.z / 16)},
                     {x = floor(hi.x / 16), y = floor(hi.y / 16), z = floor(hi.z / 16)})
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
        -- Kept as a peak because this is the only place it is measured, and it
        -- can fall as well as rise: a display reading it live would show a
        -- collection as the program using less. (F4)
        local used = drone.budget.used
        if grown > used.heap_kb then used.heap_kb = grown end
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

--- Put the drone to sleep for `seconds`, and charge the run for the wait.
--
-- Sleeping is the one thing a program can ask for that costs no CPU at all, so
-- left uncharged it would be the way to hold a drone, an entity and a slot in
-- the shared pool for ever - which is the hole max_runtime_s exists to close.
-- So the wait is charged against runtime, up front. Going over does not raise
-- here: lib/stepper.lua charges the step on its way out and reports 'timeout'
-- once the ceiling is passed, so sleep(1e9) stops the run there and then with
-- the message a program that never finishes already gets, instead of parking
-- the drone for a year.
--
-- Deliberately not through end_command. That writes wake_at from pace_ms, and
-- wake_at is one field where the last writer wins; a sleep is not a command, so
-- it neither pays the pace nor is overwritten by it. The pace of the next real
-- command still applies afterwards. (F3)
--
-- A wait shorter than a server step lasts one step: the stepper only looks at
-- its drones when the engine gives it a step. Rounding it here would only hide
-- that.
local function sleep(drone, seconds)

    local s = (type(seconds) == 'number' and seconds > 0) and seconds or 1
    local us = s * 1e6

    charge(drone.budget, 'runtime', us)
    drone.wake_at = get_us_time() + us
    release(drone)

end

-------------------------------------------------------------------------------
-- reading and writing the map
-------------------------------------------------------------------------------

--- Bring the mapblock holding `pos` into memory, and take its footprint.
--
-- Both directions need it. set_node into a mapblock that is not in memory
-- silently does nothing, so a program that flew out and built left holes with no
-- error at all; get_node on the same block answers 'ignore', which is
-- indistinguishable from map that was never generated.
--
-- Once per mapblock the drone crosses into rather than once per node. Comparing
-- floor(x/16) against the last block touched is an exact test, not a guess, and
-- it turns a per-node cost into a per-block one. A read and a write share the
-- memo because they ask the same question of it: whichever of the two loaded the
-- block last, the block is resident.
--
-- The memo is dropped at every yield - see release() - because the engine may
-- unload a block while the drone is not running, so a memo that outlived a yield
-- could skip a load that had become necessary again and lose the write. Nothing
-- unloads a block within one resume, which is what makes the memo safe at all.
-- (S5, A4)
local function load_block(drone, pos)

    local bx = floor(pos.x / 16)
    local by = floor(pos.y / 16)
    local bz = floor(pos.z / 16)
    if bx == drone.bx and by == drone.by and bz == drone.bz then return end

    -- Footprint and mapgen before the memo, because either may make the drone
    -- wait and so may yield: recording the block first would leave the memo
    -- claiming a block that was never loaded.
    use_map(drone, 1)
    local b = {x = bx, y = by, z = bz}
    wait_for_map(drone, b, b)
    drone.bx, drone.by, drone.bz = bx, by, bz
    load_area(pos)

end

--- Place one node.
--
-- Written straight to the map, not into the open shape box, which would skip
-- the replaced node's on_destruct and reset nothing of its param2. So the box
-- is written back first when it holds the node, or it would overwrite it.
-- (F-S-1)
local function place_block(drone, x, y, z, block)

    local pos = {x = x, y = y, z = z}

    load_block(drone, pos)
    flush(pos)
    set_node(pos, {name = block})

end

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

codeblock.cost.use_nodes = use_nodes
codeblock.cost.slabs = slabs
codeblock.cost.use_call = use_call
codeblock.cost.end_command = end_command
codeblock.cost.sleep = sleep
codeblock.cost.load_block = load_block
codeblock.cost.place_block = place_block
