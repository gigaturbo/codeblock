--- The drone's engine-side object: something to see, and something to step.
--
-- It owns nothing and decides nothing. The record lives in lib/drone.lua and is
-- reached by the owner's name - that and a serial are the only things kept
-- here - so there is no cached table to go stale: a name that names no drone
-- simply looks up nil. (A11, B11)
--
-- Both arrive as staticdata from add_entity rather than being written in from
-- outside. initial_properties.static_save is false, so they never reach disk;
-- the values exist only for the life of the object.
--
-- Methods sit directly on the prototype: register_entity makes the definition
-- table the per-entity luaentity's metatable with __index pointing at itself,
-- so a metatable of this file's own would resolve only by the coincidence of
-- two designs agreeing. (A6)

local drone_on_step = codeblock.Drone.on_step
local drone_on_lost = codeblock.Drone.on_lost

codeblock.DroneEntity = {

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

    owner = nil,
    serial = nil,

    -- staticdata is `<serial> <name>`; a player name cannot contain a space, so
    -- the first one separates them. The serial says which drone this object
    -- belongs to, which matters once a name has outlived one. (B29)
    on_activate = function(self, staticdata, dtime_s)
        self.serial, self.owner = staticdata:match('^(%d+) (.*)$')
    end,

    on_step = function(self, dtime, moveresult)
        drone_on_step(self.owner, self.serial)
    end,

    -- Fires on removal and on the mapblock unloading alike. Both mean the same
    -- thing to a running program, and the removal flag is not needed to tell
    -- them apart: Drone.remove clears the record before it removes the object,
    -- so teardown from that side finds nothing here to report.
    --
    -- The serial goes with the name because removal is deferred to the end of
    -- the step, so by the time this fires the name may already belong to a
    -- newer drone. (B29)
    on_deactivate = function(self, removal)
        drone_on_lost(self.owner, self.serial)
    end,

    on_rightclick = function(self, clicker) end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities,
                        dir, damage) return {} end,

    on_blast = function(self, damage) end

}
