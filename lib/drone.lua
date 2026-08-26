--- A player's drone: the record, its lifecycle, and what a run's outcome means.
--
-- One drone per player, in Drone.instances, keyed by player name. This file
-- owns that table and everything in it. Nothing else may hold a drone across a
-- server step: lib/drone_entity.lua holds the owner's *name* and looks the
-- record up, so a drone taken away mid-step cannot come back through a stale
-- reference. (A11)
--
-- The entity is the record's, not the other way round. Drone.new spawns it,
-- update_entity pushes position, facing and nametag into it, and Drone.remove
-- takes it away. The entity itself decides nothing.
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

local chat_send_player = minetest.chat_send_player
local get_player_by_name = minetest.get_player_by_name

local check_auth_level = codeblock.utils.check_auth_level

local get_user_data = codeblock.filesystem.get_user_data
local exists = codeblock.filesystem.exists

local get_safe_coroutine = codeblock.sandbox.get_safe_coroutine

local advance = codeblock.stepper.advance
local step_budget = codeblock.stepper.budget
local awake = codeblock.stepper.awake

local max_runtime_s = codeblock.config.max_runtime_s
local server_step_budget_us = codeblock.config.server_step_budget_us

local tmp1 = 2 / pi
local tmp2 = 2 * pi
local tmp3 = pi / 2
local tmp4 = pi / 4

local function dirtocardinal(dir) return floor((dir + tmp4) * tmp1) * tmp3 end

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

        angle = function(self) return tmp1 * (self.dir % tmp2) end

    },

    -- What the player gets when a program finishes: what it built and how long
    -- it took. Not the runtime it was charged - against a ceiling of minutes
    -- that reads as 0.01s, which says nothing to anyone. It belongs in the
    -- budget display, as a share of the budget.
    __tostring = function(self)
        local used = self.budget and self.budget.used or {}
        local started = self.tstart or minetest.get_us_time()
        return S('commands:@1 nodes:@2 duration:@3s', self.commands,
                 used.nodes or 0, ('%.2f'):format(
                     (minetest.get_us_time() - started) / 1e6))
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
                minetest.get_player_by_name(name):get_meta():set_int(
                    'codeblock:auth_level', codeblock.config.default_auth_level)
            end

            local px, py, pz = floor(pos.x), floor(pos.y), floor(pos.z)
            local dir = (type(dir) == 'number' and dir % tmp3 == 0) and dir or 0

            -- The owner's name travels as staticdata, which is how the engine
            -- hands an entity its initial state - nothing reaches into the
            -- luaentity from here. static_save is false, so it is never written
            -- to disk. (A11)
            --
            -- add_entity returns nil when the target area is not loaded, and
            -- the placer tool reaches 128 nodes, so a player can comfortably
            -- point past loaded ground. Without an entity nothing would ever
            -- step the program, so no record is created either. (B10)
            local obj = minetest.add_entity(pos, 'codeblock:drone', name)
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
                auth_level = auth_level,
                checkpoints = {},
                calls = 0,
                commands = 0,
                -- The run's resource budget, built at start rather than here:
                -- it needs a clock reading and the codelevel the run will
                -- actually use. See lib/limits.lua.
                budget = nil,
                tstart = nil,
                file = nil,
                cor = nil,
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

            local drone = Drone.get(name)

            if drone ~= nil and drone.cor ~= nil then
                chat_send_player(name, S('Drone is busy, please wait!'))
                return
            end

            if not pos then
                chat_send_player(name, S("Please target a node"))
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

            if last_file == "" or not get_user_data(name).ftp[last_file] then
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
            drone.tstart = minetest.get_us_time()
            -- Baseline for the heap-growth guard in commands.use_call.
            -- collectgarbage('count') is server-wide, so only the delta from
            -- here is meaningful, and even that is approximate.
            drone.mem0 = collectgarbage('count')
            -- Every ceiling the run will be held to, in one table, counters
            -- included. Fresh per run, so nothing carries over from the last.
            drone.budget = codeblock.limits.new(codeblock.config,
                                                drone.auth_level,
                                                minetest.get_us_time())
            drone.calls, drone.commands = 0, 0
            drone.wake_at = nil
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

        --- Advance one drone for its slice of this server step.
        --
        -- Driven by the entity, which is why it is per-drone rather than one
        -- globalstep: an entity that has been unloaded stops being stepped, and
        -- so does the program it carries.
        on_step = function(name)

            local drone = Drone.get(name)

            if drone == nil or drone.cor == nil then return end

            -- Counted here rather than kept as a running total, because a drone
            -- can stop for reasons that never pass through this function. Few
            -- players, once per drone per step. Sleeping drones are left out:
            -- they are not going to spend anything this step, so they must not
            -- take a share either.
            local running = 0
            for _, d in pairs(Drone.instances) do
                if d.cor ~= nil and awake(d) then running = running + 1 end
            end

            -- Advance for up to this drone's slice of the step rather than
            -- exactly one resume; see lib/stepper.lua for why, and for why the
            -- slice shrinks as more drones run. The string guards are armed for
            -- the span in which player code runs and released inside advance().
            local budget = step_budget(drone.budget.caps.step,
                                       server_step_budget_us, running)
            local _, outcome, err = advance(drone, budget)

            if outcome ~= 'yielded' then Drone.finish(drone, outcome, err) end

        end,

        --- The entity went away under a running program: unloaded, or removed
        -- by anything other than Drone.remove, which clears the record first.
        on_lost = function(name)

            local drone = Drone.get(name)

            if drone == nil then return end

            chat_send_player(name,
                             S('The drone has disappeared, program stopped'))
            Drone.finish(drone, 'completed')

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
                minetest.log('warning',
                             '[codeblock] drone ' .. tostring(name) ..
                                 ' coroutine is neither suspended nor dead')

            else
                chat_send_player(name, S("Program '@1' completed: @2",
                                         drone.file, tostring(drone)))
            end

            Drone.remove(name)

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
