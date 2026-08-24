codeblock.DroneEntity = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S
local chat_send_player = minetest.chat_send_player

local drone_get = codeblock.Drone.get
local drone_rmv = codeblock.Drone.remove

local advance = codeblock.stepper.advance
local max_string_bytes = codeblock.config.max_string_bytes
local step_budget_us = codeblock.config.step_budget_us

--------------------------------------------------------------------------------
-- private
--------------------------------------------------------------------------------

local DroneEntity = {
    initial_properties = {
        visual = "cube",
        visual_size = {x = 1.1, y = 1.1},
        textures = {
            "drone_top.png", "drone_side.png", "drone_side.png",
            "drone_side.png", "drone_side.png", "drone_side.png"
        },
        collisionbox = {-0.55, -0.55, -0.55, 0.55, 0.55, 0.55},
        physical = false,
        static_save = false
    },
    nametag = nil,
    owner = nil,
    _data = nil
}

local entity_mt = {

    __index = {

        on_step = function(self, dtime, moveresult)

            local drone = self._data -- ok as long as entity is removed
            if drone == nil or drone.cor == nil then return end

            local al = drone.auth_level

            -- Advance for up to this codelevel's slice of the step rather than
            -- exactly one resume; see lib/stepper.lua for why. The string
            -- guards are armed for the span in which player code runs and
            -- released inside advance().
            local _, outcome, err = advance(drone, step_budget_us[al],
                                            max_string_bytes[al])

            if outcome == 'error' then
                chat_send_player(drone.name,
                                 S('Runtime error in @1:', drone.file) .. '\n' ..
                                     tostring(err))
                -- Remove the drone here. Previously the error was reported and
                -- drone.cor left in place, so the next step found a dead
                -- coroutine and announced the program had "completed" as well -
                -- the player got both messages for one failure.
                drone_rmv(drone.name)

            elseif outcome == 'completed' then
                chat_send_player(drone.name,
                                 S("Program '@1' completed: @2", drone.file,
                                   tostring(drone)))
                drone_rmv(drone.name)

            elseif outcome == 'blocked' then
                -- Should not be reachable: a coroutine is suspended or dead
                -- while a drone holds it. Reported rather than spun on.
                minetest.log('warning', '[codeblock] drone ' ..
                                 tostring(drone.name) ..
                                 ' coroutine is neither suspended nor dead')
                drone_rmv(drone.name)
            end

        end,

        on_rightclick = function(self, clicker) end,

        on_punch = function(self, puncher, time_from_last_punch,
                            tool_capabilities, dir, damage) return {} end,

        on_blast = function(self, damage) end,

        on_deactivate = function(self, ...)
            -- check drone existence, not the cached value
            local drone = drone_get(self._data.name)
            if drone ~= nil then
                chat_send_player(drone.name, S(
                                     'The drone has disappeared, program stopped'))
                chat_send_player(drone.name, S("Program '@1' completed: @2",
                                               drone.file, tostring(drone)))
                drone_rmv(drone.name)
            end

        end

    }

}

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

codeblock.DroneEntity = setmetatable(DroneEntity, entity_mt)

