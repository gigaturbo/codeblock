codeblock.DroneEntity = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S
local chat_send_player = minetest.chat_send_player

local drone_get = codeblock.Drone.get
local drone_rmv = codeblock.Drone.remove

local strguard_enter = codeblock.strguard.enter
local strguard_leave = codeblock.strguard.leave
local max_string_bytes = codeblock.config.max_string_bytes

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

            if drone ~= nil then
                if drone.cor ~= nil then
                    local status = coroutine.status(drone.cor)
                    if status == 'suspended' then
                        -- Arm the string guards for exactly the span in which
                        -- player code runs. Luanti runs mods on one thread, so
                        -- no other mod executes inside this window - and leave()
                        -- runs unconditionally afterwards, because a guard left
                        -- armed would apply the limit to the whole server.
                        strguard_enter(max_string_bytes[drone.auth_level])
                        local success, ret = coroutine.resume(drone.cor)
                        strguard_leave()
                        if not success then
                            chat_send_player(drone.name, S(
                                                 'Runtime error in @1:',
                                                 drone.file) .. '\n' .. ret)
                        end
                    elseif status == 'dead' then
                        chat_send_player(drone.name, S(
                                             "Program '@1' completed: @2",
                                             drone.file, tostring(drone)))
                        drone_rmv(drone.name)
                    end
                end

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

