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
local split = codeblock.utils.split

local get_user_data = codeblock.filesystem.get_user_data
local read_file = codeblock.filesystem.read_file
local exists = codeblock.filesystem.exists

local get_safe_coroutine = codeblock.sandbox.get_safe_coroutine

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
                    nametag = '[' .. self.obj:get_luaentity().owner .. '] ' ..
                        (self.file or '?.lua')
                });
            end
        end,

        angle = function(self) return tmp1 * (self.dir % tmp2) end

    },

    __tostring = function(self)
        return S('commands:@1 volume:@2m³ calls:@3 duration:@4s',
                 self.commands, self.volume, self.calls,
                 (os.clock() - (self.tstart or os.clock())))
    end
}

local drone_mt = {

    __index = {

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

            local drone = {
                name = name,
                x = px,
                y = py,
                z = pz,
                spawn = {px, py, pz},
                dir = dir,
                auth_level = auth_level,
                checkpoints = {},
                volume = 0,
                calls = 0,
                commands = 0,
                tstart = nil,
                file = nil,
                cor = nil,
                obj = nil
            }

            drone.checkpoints['spawn'] = {x = px, y = py, z = pz, dir = dir}

            setmetatable(drone, instance_mt)

            drone.obj = minetest.add_entity(pos, "codeblock:drone", nil)
            drone.obj:get_luaentity().owner = name
            drone.obj:get_luaentity()._data = drone

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
                rawset(Drone.instances, k, nil) -- avoid obj:remove() to call remove() again
                if d.obj ~= nil then d.obj:remove() end
                d.obj = nil
                d.cor = nil
                return nil
            end
            return nil
        end,

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
                return {}
            end

            local dir = dirtocardinal(player:get_look_horizontal())

            local last_file = player:get_meta()
                                  :get_string('codeblock:last_file')
            local auth_level = player:get_meta():get_int('codeblock:auth_level')

            Drone.new(name, pos, dir, auth_level)

            if (not last_file) or last_file == "" or
                (not get_user_data(name).ftp[last_file]) then

                Drone.show_set_file_form(name)
            else
                Drone.set_file(name, last_file)
            end

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

            drone.tstart = os.clock()
            -- Baseline for the heap-growth guard in commands.use_call.
            -- collectgarbage('count') is server-wide, so only the delta from
            -- here is meaningful, and even that is approximate.
            drone.mem0 = collectgarbage('count')
            drone.cor = res

        end,

        on_remove = function(name)

            local drone = Drone.get(name)

            if drone ~= nil then
                if drone.cor ~= nil then
                    chat_send_player(drone.name, S("Program '@1' completed: @2",
                                                   drone.file, tostring(drone)))
                    Drone.remove(name)
                else
                    Drone.remove(name)
                end
            end

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

        end,

        show_set_file_form = function(name)

            local meta = {name = name, selectedIndex = 0}
            local fs = codeblock.formspecs.file_chooser
            minetest.create_form(meta, name, fs.get_form(meta), fs.on_close)

        end,

        show_file_editor_form = function(name)

            local ud = get_user_data(name, true)

            -- load saved state
            local tabs = {}
            local contents = {}
            local active = 0
            local soe = false
            local loe = false
            local sos = false
            local player = get_player_by_name(name)
            if player then
                local meta = player:get_meta()
                -- Converted to booleans here, at the persistence boundary.
                -- These used to be carried around as the 0/1 that get_int
                -- returns and then tested with `if meta.sos then`, which is
                -- always true in Lua - 0 is truthy - so both checkboxes were
                -- permanently on whatever the player ticked.
                soe = meta:get_int('codeblock:save_on_exit') == 1
                loe = meta:get_int('codeblock:load_on_exit') == 1
                sos = meta:get_int('codeblock:save_on_switch') == 1
                local saved_active = meta:get_string(
                                         'codeblock:editor_state_active')
                local saved_tabs =
                    meta:get_string('codeblock:editor_state_tabs')
                if saved_tabs ~= "" then
                    local pot_tabs = split(saved_tabs, ',')
                    for i, filename in ipairs(pot_tabs) do
                        if ud.ftp[filename] then
                            local content, err = read_file(name, filename, true)
                            if not err then
                                table.insert(tabs, filename)
                                table.insert(contents, content)
                                if saved_active ~= "" and filename ==
                                    saved_active then
                                    active = #tabs
                                end
                            else
                                chat_send_player(name, err)
                            end
                        end
                    end
                end
            end

            local meta = {
                name = name,
                tabs = tabs,
                contents = contents,
                active = active,
                help = 'cubes',
                scroll_c = 0,
                scroll_p = 0,
                scroll_w = 0,
                scroll_a = 0,
                soe = soe,
                loe = loe,
                sos = sos,
                newfile = ''
            }
            local fe = codeblock.formspecs.file_editor
            minetest.create_form(meta, name, fe.get_form(meta), fe.on_close)
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
