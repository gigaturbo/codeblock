--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------
local S = codeblock.S
local get_player_by_name = minetest.get_player_by_name
local get_pointed_thing_position = minetest.get_pointed_thing_position
local chat_send_player = minetest.chat_send_player

local drone_on_run = codeblock.DroneEntity.on_run
local drone_on_place = codeblock.DroneEntity.on_place
local drone_on_remove = codeblock.DroneEntity.on_remove
local drone_show_set_file_form = codeblock.DroneEntity.show_set_file_form
local drone_show_file_editor_form = codeblock.DroneEntity.show_file_editor_form

local check_auth_level = codeblock.utils.check_auth_level

local get_user_data = codeblock.filesystem.get_user_data
local write_file = codeblock.filesystem.write_file
local remove_user_data = codeblock.filesystem.remove_user_data
local make_user_dir = codeblock.filesystem.make_user_dir

--------------------------------------------------------------------------------
-- private
--------------------------------------------------------------------------------

local function set_tools(player)
    local inv = player:get_inventory()

    local invs = {'main', 'craft', 'craftpreview', 'craftresult'}
    for _, inv_name in ipairs(invs) do
        for i = 1, inv:get_size(inv_name) do
            inv:set_stack(inv_name, i, ItemStack())
        end
    end

    inv:add_item('main', ItemStack('codeblock:poser'))
    inv:add_item('main', ItemStack('codeblock:setter'))
end

local function generate_examples(player)

    local name = type(player) == 'string' and player or player:get_player_name()

    local err = make_user_dir(name)
    if not err then
        for ex_name, content in pairs(codeblock.examples) do
            local filename = ex_name .. '.lua'
            write_file(name, filename, content)
        end
        return nil
    else
        chat_send_player(name, err)
        return err
    end
end

local function generate_simple_example(player)

    local name = type(player) == 'string' and player or player:get_player_name()

    local err = make_user_dir(name)
    if not err then
        local filename = 'example.lua'
        local content = codeblock.examples.example
        write_file(name, filename, content)
        return nil
    else
        chat_send_player(name, err)
        return err
    end
end

--------------------------------------------------------------------------------
-- tools
--------------------------------------------------------------------------------

minetest.register_tool("codeblock:poser", {
    description = S("Drone Poser"),
    inventory_image = "drone_poser.png",
    range = 128,
    stack_max = 1,
    liquids_pointable = true,
    on_drop = function(itemstack, dropper, pos) return itemstack end,
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        drone_on_run(name)
        return itemstack
    end,
    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        local pos = get_pointed_thing_position(pointed_thing)
        drone_on_place(name, pos)
        return itemstack
    end,
    on_secondary_use = function(itemstack, user, pointed_thing) return end
})

minetest.register_tool("codeblock:setter", {
    description = S("Drone Setter"),
    inventory_image = "drone_setter.png",
    range = 0,
    stack_max = 1,
    on_drop = function(itemstack, dropper, pos) return itemstack end,
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        drone_on_remove(name)
        return itemstack
    end,
    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        drone_show_file_editor_form(name)
        return itemstack
    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        drone_show_file_editor_form(name)
        return itemstack
    end
})

--------------------------------------------------------------------------------
-- entities
--------------------------------------------------------------------------------

minetest.register_entity("codeblock:drone", codeblock.DroneEntity)

--------------------------------------------------------------------------------
-- players
--------------------------------------------------------------------------------

minetest.register_on_newplayer(function(player)

    -- example
    local name = player:get_player_name()
    generate_simple_example(name)

    -- privs
    local privs = minetest.get_player_privs(player:get_player_name())
    privs.fly = true
    privs.fast = true
    privs.noclip = true
    minetest.set_player_privs(player:get_player_name(), privs)

    -- meta
    local meta = player:get_meta()
    meta:set_int('codeblock:last_index', 0)
    meta:set_string('codeblock:last_file', "")
    meta:set_int('codeblock:auth_level', codeblock.config.default_auth_level)
    meta:set_string('codeblock:editor_state_tabs', "")
    meta:set_string('codeblock:editor_state_active', 0)
    meta:set_int('codeblock:save_on_exit', 0)
    meta:set_int('codeblock:load_on_exit', 0)
    meta:set_int('codeblock:save_on_switch', 0)

end)

minetest.register_on_joinplayer(function(player)

    -- create lua dir and initialize user_data
    local name = player:get_player_name()
    local err = make_user_dir(name)
    if err then
        chat_send_player(name, err)
        return err
    end
    get_user_data(name)

    -- tools
    set_tools(player)

    -- overrides
    -- TODO: TEMP fix ?
    player:override_day_night_ratio(1)
    player:set_stars({visible = false})
    player:set_sun({visible = false})
    player:set_moon({visible = false})
    player:set_clouds({density = 0})

    -- local meta = player:get_meta()
    -- meta:set_int('codeblock:last_index', 0)
    -- meta:set_string('codeblock:last_file', "")
    -- meta:set_int('codeblock:auth_level', codeblock.config.default_auth_level)
    -- meta:set_string('codeblock:editor_state_tabs', "")
    -- meta:set_string('codeblock:editor_state_active', 0)

    -- meta
    -- TODO : carefully restore this?
    -- local meta = player:get_meta()
    -- meta:set_string('codeblock:editor_state_tabs', "")
    -- meta:set_int('codeblock:editor_state_active', 0)

end)

minetest.register_on_leaveplayer(function(player, timed_out)
    local name = player:get_player_name()
    drone_on_remove(name)
    remove_user_data(name)
end)

--------------------------------------------------------------------------------
-- Commands and privileges
--------------------------------------------------------------------------------

minetest.register_privilege("codeblock", {
    description = "Player can use the codeblock admin commands",
    give_to_singleplayer = false
})

minetest.register_chatcommand("authlevel", {
    privs = {codeblock = true},
    func = function(name, params)

        local pname, pal = string.match(params, '^([%a%d_-]+) (%d)$')

        local valid_al, al = check_auth_level(tonumber(pal))

        local player = get_player_by_name(pname or '')

        if valid_al then
            if player then
                player:get_meta():set_int('codeblock:auth_level', al)
                return true, S('@1 auth_level set to @2', pname, al)
            else
                return false, S('Player not found')
            end
        else
            return false, S('Invalid authlevel')
        end

    end
})

minetest.register_chatcommand("codeblock_examples", {
    func = function(name, params)

        local pname = string.match(params, '^([%a%d_-]+)$')

        local player = get_player_by_name(pname or name or '')

        if player then
            local err = generate_examples(player)
            if err then
                return false, S('error')
            else
                return true, S('examples generated')
            end
        else
            return false, S('Player not found')
        end

    end
})

-- minetest.register_chatcommand("luae", {
--     privs = {codeblock = true},
--     func = function(name, params)

--     end
-- })

--------------------------------------------------------------------------------
-- formspecs
--------------------------------------------------------------------------------
