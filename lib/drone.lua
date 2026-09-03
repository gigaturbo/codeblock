--- A player's drone: the record, its lifecycle, and what a run's outcome means.
--
-- One drone per player, in Drone.instances, keyed by player name. This file
-- owns that table and everything in it. Nothing else may hold a drone across a
-- server step: lib/drone_entity.lua holds the owner's *name* and a serial, and
-- looks the record up, so a drone taken away mid-step cannot come back through
-- a stale reference. The serial is what tells a drone from the one that
-- replaced it, since removal only takes effect at the end of the step. (A11,
-- B29)
--
-- The entity is the record's, not the other way round. Drone.new spawns it,
-- Drone.on_step spawns it again once it has been unloaded, update_entity pushes
-- position, facing and nametag into it, and Drone.remove takes it away. The
-- entity itself decides nothing, and a record without one is a run nobody can
-- see rather than a run that has stopped.
--
-- The run is driven by lib/register.lua's globalstep and not by the entity: an
-- entity with static_save = false is deleted the moment its mapblock leaves
-- server memory, and the program must not go with it. (B50, B52)
--
-- Everything a program's end is announced with is in Drone.finish, and every
-- path that ends a run goes through it.
--
-- Knows nothing about forms. on_place says whether the player still has to pick
-- a file; showing the chooser is the caller's job, which is what lets
-- lib/formspecs.lua depend on this file rather than both ways.

codeblock.Drone = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S
local pi = math.pi
local floor = math.floor

local chat_send_player = core.chat_send_player
local get_player_by_name = core.get_player_by_name

local check_auth_level = codeblock.utils.check_auth_level

local get_user_data = codeblock.filesystem.get_user_data
local exists = codeblock.filesystem.exists

local get_safe_coroutine = codeblock.sandbox.get_safe_coroutine

local advance = codeblock.stepper.advance
local step_budget = codeblock.stepper.budget
local awake = codeblock.stepper.awake

local max_runtime_s = codeblock.config.max_runtime_s
local server_step_budget_us = codeblock.config.server_step_budget_us

local blocks = codeblock.config.allowed_blocks.all
-- What a bare place() uses until a player chooses otherwise. Described in
-- lib/api.lua, so the two have to agree.
local fallback_block = codeblock.config.allowed_blocks.cubes.stone

local tmp1 = 2 / pi
local tmp3 = pi / 2
local tmp4 = pi / 4

local function dirtocardinal(dir) return floor((dir + tmp4) * tmp1) * tmp3 end

-- Counts drones spawned this session, so each one can be told from the one it
-- replaced. Compared as a value rather than by comparing ObjectRefs, which the
-- engine nowhere promises are the same userdata twice. (B29)
local serial = 0

-- How long a drone waits before trying for another object, in seconds, and the
-- countdown Drone.on_step keeps against it. Server-wide rather than per drone:
-- the wait is only there to keep the attempt off the tick, and one drone getting
-- its view back a fraction sooner than another is nothing a player can see.
local respawn_period_s = 1
local respawn_wait = 0

--- The block this player has chosen for a bare place(), or stone.
--
-- Validated on read rather than trusted from the write: a player who joined
-- before the setting existed has no key at all, and player meta outlives a
-- change to the palette, so a stored name can stop resolving. Either way the
-- failure it would otherwise cause is 'Cannot place this block' raised on a
-- line where the player passed no block. (F1)
local function preferred_block(name)
    local player = get_player_by_name(name)
    if not player then return fallback_block end
    local stored = player:get_meta():get_string('codeblock:default_block')
    return blocks[stored] and stored or fallback_block
end

--------------------------------------------------------------------------------
-- private
--------------------------------------------------------------------------------

local Drone = {instances = {}}

local instance_mt = {

    __index = {

        update_entity = function(self)
            if self.obj ~= nil then
                self.obj:set_pos({x = self.x, y = self.y, z = self.z})
                self.obj:set_rotation({x = 0, y = self.dir, z = 0})
                self.obj:set_properties({
                    nametag = '[' .. self.name .. '] ' .. (self.file or '?.lua')
                });
            end
        end,

        -- Which quarter-turn the drone faces, 0 to 3, as an integer fit to
        -- index a table with. Rounded rather than scaled, because dir is a
        -- float and the arithmetic that produces it does not land on an exact
        -- multiple of pi/2: turn(1000) left it a hair under 2*pi, so the wrap
        -- did not happen and the old expression gave 4. (B27)
        angle = function(self) return floor(self.dir / tmp3 + .5) % 4 end

    },

    -- What the player gets when a program finishes: what it built and how long
    -- it took. Not the runtime it was charged - against a ceiling of minutes
    -- that reads as 0.01s, which says nothing to anyone. It belongs in the
    -- budget display, as a share of the budget.
    --
    -- The duration is Drone.elapsed_us, the same figure the drone panel's
    -- heading shows, so the last number the player saw live and the final one
    -- cannot disagree.
    __tostring = function(self)
        local used = self.budget and self.budget.used or {}
        return S('commands:@1 nodes:@2 duration:@3s', self.commands,
                 used.nodes or 0,
                 ('%.2f'):format(Drone.elapsed_us(self) / 1e6))
    end
}

local drone_mt = {

    __index = {

        --- Spawn a drone for `name`. Returns the drone, or nil and a message.
        new = function(name, pos, dir, auth_level)

            assert(type(name) == 'string' and #name > 0, 'Wrong parameters')
            assert(type(pos) == 'table' and
                       (type(pos.x) == 'number' and type(pos.y) == 'number' and
                           type(pos.z) == 'number'), 'Wrong parameters')
            local suc, auth_level = check_auth_level(auth_level)
            if not suc then
                get_player_by_name(name):get_meta():set_int(
                    'codeblock:auth_level', codeblock.config.default_auth_level)
            end

            local px, py, pz = floor(pos.x), floor(pos.y), floor(pos.z)
            local dir = (type(dir) == 'number' and dir % tmp3 == 0) and dir or 0

            -- The owner's name and this drone's serial travel as staticdata,
            -- which is how the engine hands an entity its initial state -
            -- nothing reaches into the luaentity from here. static_save is
            -- false, so it is never written to disk. (A11)
            --
            -- Serial first and name last, split on the first space: a player
            -- name cannot contain one, so the two never run together.
            --
            -- add_entity returns nil when the target area is not loaded, and
            -- the placer tool reaches 128 nodes, so a player can comfortably
            -- point past loaded ground. Placing there is refused rather than
            -- answered with a drone the player cannot see. Only re-spawning is
            -- permissive; a drone is never created without its object. (B10)
            serial = serial + 1
            local tag = serial .. ' ' .. name
            local obj = core.add_entity(pos, 'codeblock:drone', tag)
            if obj == nil then
                return nil, S('Cannot place the drone there, move closer')
            end

            local drone = {
                name = name,
                x = px,
                y = py,
                z = pz,
                spawn = {px, py, pz},
                dir = dir,
                serial = tostring(serial),
                auth_level = auth_level,
                checkpoints = {},
                calls = 0,
                commands = 0,
                -- Always a name the drone can place, from here on: placement()
                -- falls back to nothing further. Re-read at the start of every
                -- run, so changing the preference takes effect on the next one
                -- rather than splitting a build in two. (F1)
                default_block = preferred_block(name),
                -- The run's resource budget, built at start rather than here:
                -- it needs a clock reading and the codelevel the run will
                -- actually use. See lib/limits.lua.
                budget = nil,
                tstart = nil,
                file = nil,
                cor = nil,
                -- The player holding the program from the drone panel. Separate
                -- from wake_at, which is the program's own sleep; see
                -- stepper.awake for why the two cannot share a field. (F4)
                --
                -- paused_at is when the hold started, and only Drone.toggle_pause
                -- may write either: it is what keeps a pause out of the elapsed
                -- clock. (F9)
                paused = false,
                paused_at = nil,
                obj = obj
            }

            drone.checkpoints['spawn'] = {x = px, y = py, z = pz, dir = dir}

            setmetatable(drone, instance_mt)

            drone:update_entity()

            Drone.set(name, drone)

            return drone

        end,

        get = function(k) return rawget(Drone.instances, k) end,

        set = function(k, v)
            Drone.remove(k)
            return rawset(Drone.instances, k, v)
        end,

        remove = function(k)
            local d = rawget(Drone.instances, k)
            if d ~= nil then
                -- Cleared before obj:remove(), because that fires the entity's
                -- on_deactivate, which looks the drone up by name. Finding
                -- nothing is what stops teardown re-entering itself.
                rawset(Drone.instances, k, nil)
                if d.obj ~= nil then d.obj:remove() end
                d.obj = nil
                d.cor = nil
            end
            return nil
        end,

        --- Place a drone for `name` at `pos`, facing the way the player is.
        --
        -- Returns true when the drone has no file yet and the caller should
        -- offer the file chooser.
        on_place = function(name, pos)

            local player = get_player_by_name(name)

            if not player then return end

            -- Answered before the drone is looked at all: with no position the
            -- gesture failed, and whether a drone happens to be running is not
            -- what the player got wrong. The poser routes its no-node case here
            -- rather than repeating the message, so this branch is the only one
            -- that runs for it. (B38)
            if not pos then
                chat_send_player(name, S("Please target a node"))
                return
            end

            local drone = Drone.get(name)

            if drone ~= nil and drone.cor ~= nil then
                chat_send_player(name, S('Drone is busy, please wait!'))
                return
            end

            local meta = player:get_meta()
            local dir = dirtocardinal(player:get_look_horizontal())

            local placed, err = Drone.new(name, pos, dir,
                                          meta:get_int('codeblock:auth_level'))

            if not placed then
                chat_send_player(name, err)
                return
            end

            local last_file = meta:get_string('codeblock:last_file')

            if last_file == "" or not get_user_data(name).byname[last_file] then
                return true
            end

            Drone.set_file(name, last_file)

        end,

        on_run = function(name)

            local drone = Drone.get(name)

            if drone == nil then
                chat_send_player(name, S("Error, drone does not exist"))
                return
            else
                if drone.cor ~= nil then
                    chat_send_player(name, S('Drone is busy, please wait!'))
                    return
                end
            end

            local file = drone.file

            if not file then
                chat_send_player(name, S("Not a valid file"))
                return
            end

            local suc, res = get_safe_coroutine(drone, file)

            if not suc then
                Drone.remove(name)
                chat_send_player(name, res)
                return
            end

            -- get_us_time, not os.clock: os.clock is the server process's CPU
            -- time on POSIX, so on a real server it counts everything the
            -- server does and is not the wall clock the player is watching.
            drone.tstart = core.get_us_time()
            -- Baseline for the heap-growth guard in commands.use_call.
            -- collectgarbage('count') is server-wide, so only the delta from
            -- here is meaningful, and even that is approximate.
            drone.mem0 = collectgarbage('count')
            -- Every ceiling the run will be held to, in one table, counters
            -- included. Fresh per run, so nothing carries over from the last.
            drone.budget = codeblock.limits.new(codeblock.config,
                                                drone.auth_level,
                                                core.get_us_time())
            drone.calls, drone.commands = 0, 0
            drone.default_block = preferred_block(name)
            drone.wake_at = nil
            drone.paused, drone.paused_at = false, nil
            drone.cor = res

        end,

        --- The setter tool: take the drone away, reporting a run it cut short.
        on_remove = function(name)

            local drone = Drone.get(name)

            if drone == nil then return end

            if drone.cor == nil then
                Drone.remove(name)
                return
            end

            Drone.finish(drone, 'completed')

        end,

        --- Advance every drone for its slice of this server step, and give an
        -- object back to any that has lost one.
        --
        -- Registered as a globalstep in lib/register.lua. Driving it from the
        -- entity instead ended a run whenever the object went, and an object
        -- with static_save = false goes as soon as its mapblock leaves server
        -- memory - which is every drone past about 192 nodes from a player, and
        -- every drone standing still for server_unload_unused_data_timeout.
        -- (B50, B52)
        --
        -- One pass, because the share each drone gets needs the number of them
        -- running: counted per entity, that was a scan of every drone for every
        -- drone. It is counted rather than kept as a running total because a
        -- drone can stop for reasons that never pass through here.
        --
        -- Clearing a key during pairs is defined in Lua 5.1 and adding one is
        -- not; Drone.finish only ever removes.
        on_step = function(dtime)

            -- Sleeping drones are left out: they will spend nothing this step,
            -- so they must not take a share either.
            local running = 0
            for _, d in pairs(Drone.instances) do
                if d.cor ~= nil and awake(d) then running = running + 1 end
            end

            respawn_wait = respawn_wait - dtime
            local respawn = respawn_wait <= 0
            if respawn then respawn_wait = respawn_period_s end

            for _, drone in pairs(Drone.instances) do

                -- Same serial and owner as the drone was placed with, so the
                -- object that comes back belongs to the same run. (B29)
                --
                -- Gated on the block being in memory rather than on add_entity
                -- failing, which logs an engine warning per call and would fill
                -- debug.txt from here. Not tried every step: a mapblock comes
                -- and goes on the engine's own cadence of seconds, so a faster
                -- check would see nothing more.
                if respawn and drone.obj == nil then
                    local pos = {x = drone.x, y = drone.y, z = drone.z}
                    if core.get_node_or_nil(pos) ~= nil then
                        drone.obj = core.add_entity(pos, 'codeblock:drone',
                                                    drone.serial .. ' ' ..
                                                        drone.name)
                        drone:update_entity()
                    end
                end

                -- Advance for up to this drone's slice of the step rather than
                -- exactly one resume; see lib/stepper.lua for why, and for why
                -- the slice shrinks as more drones run. The string guards are
                -- armed for the span in which player code runs and released
                -- inside advance().
                if drone.cor ~= nil then
                    local budget = step_budget(drone.budget.caps.step,
                                               server_step_budget_us, running)
                    local _, outcome, err = advance(drone, budget)
                    if outcome ~= 'yielded' then
                        Drone.finish(drone, outcome, err)
                    end
                end

            end

        end,

        --- The object went away: unloaded with its mapblock, or removed by
        -- anything other than Drone.remove, which clears the record first.
        --
        -- The view of the drone, and nothing else. The run carries on unseen
        -- and on_step hands the drone another object once its block is back in
        -- memory, so nothing is announced and nothing is torn down - including
        -- for a drone with no coroutine, which now waits for its view rather
        -- than being taken away. B30's rule holds either way: a program that
        -- never started is never reported as having ended.
        --
        -- `serial` says which drone lost its object. ObjectRef:remove() takes
        -- effect at the end of the step, so an object taken away can fire this
        -- after a replacement drone has been installed under the same name -
        -- and without the check, replacing a drone would blank the new one's
        -- object and leave it invisible until the next re-spawn. (B29)
        on_lost = function(name, serial)

            local drone = Drone.get(name)

            if drone == nil or drone.serial ~= serial then return end

            drone.obj = nil

        end,

        --- Say how a run ended, then take the drone away.
        --
        -- The one place any of that is said. `outcome` is stepper.advance's,
        -- minus 'yielded', which is not an ending.
        finish = function(drone, outcome, err)

            local name = drone.name

            if outcome == 'error' then
                chat_send_player(name, S('Runtime error in @1:', drone.file) ..
                                     '\n' .. tostring(err))

            elseif outcome == 'timeout' then
                -- Out of running time: the bound on a program that never
                -- finishes. Named as time, because that is what it spent.
                chat_send_player(name, S(
                    "Program '@1' stopped: it used all @2 s of running time",
                    drone.file, max_runtime_s[drone.auth_level]))

            elseif outcome == 'blocked' then
                -- Should not be reachable: a coroutine is suspended or dead
                -- while a drone holds it. Reported rather than spun on.
                core.log('warning',
                             '[codeblock] drone ' .. tostring(name) ..
                                 ' coroutine is neither suspended nor dead')

            else
                chat_send_player(name, S("Program '@1' completed: @2",
                                         drone.file, tostring(drone)))
            end

            Drone.remove(name)

        end,

        --- How long this run has been building, in microseconds.
        --
        -- Wall clock, and deliberately not `budget.used.runtime`, which is the
        -- CPU time the run was charged and reads as a fraction of a second:
        -- keeping the two apart is the whole of B46.
        --
        -- **A pause does not count.** `paused_at` freezes the figure while the
        -- player holds the program, and toggle_pause shifts `tstart` forward on
        -- the way out, so there is no accumulator to keep in step. Both the
        -- drone panel's heading and the finish message's `duration:` read this,
        -- which is what makes the live number and the final one the same
        -- number. (F9)
        elapsed_us = function(drone)
            local now = core.get_us_time()
            return (drone.paused_at or now) - (drone.tstart or now)
        end,

        --- Hold the run, or let it go again.
        --
        -- **The only thing that may write `drone.paused`**, because the elapsed
        -- clock above depends on `paused_at` being stamped with it: the two
        -- fields are one fact in two halves. `on_run` clears both for a fresh
        -- run and is the only other writer. Callers guard on the drone having a
        -- coroutine, so `tstart` is set by the time this is reached. (F9)
        toggle_pause = function(drone)
            if drone.paused then
                drone.tstart = drone.tstart +
                                   (core.get_us_time() - drone.paused_at)
                drone.paused_at = nil
            else
                drone.paused_at = core.get_us_time()
            end
            drone.paused = not drone.paused
        end,

        set_file = function(name, filename)

            assert(filename)

            local player = get_player_by_name(name)

            local err = exists(name, filename)

            if err then
                chat_send_player(name, err)
                return err
            end

            -- set the drone file if drone exist
            local drone = Drone.get(name)
            if drone then
                drone.file = filename
                drone:update_entity()
            end

            -- set last_file for next drone placing
            if player then
                player:get_meta():set_string('codeblock:last_file', filename)
            end

            return nil

        end

    },

    __tostring = function()
        local s = ''
        for k, v in pairs(Drone.instances) do
            s = s .. k .. ': ' .. tostring(v) .. '\n'
        end
        return s
    end

}

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

codeblock.Drone = setmetatable(Drone, drone_mt)
