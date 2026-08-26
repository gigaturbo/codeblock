--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------
local S = codeblock.S
local get_player_by_name = minetest.get_player_by_name
local get_pointed_thing_position = minetest.get_pointed_thing_position
local chat_send_player = minetest.chat_send_player

local drone_on_run = codeblock.Drone.on_run
local drone_on_place = codeblock.Drone.on_place
local drone_on_remove = codeblock.Drone.on_remove

local show_file_editor = codeblock.formspecs.file_editor.show
local show_file_chooser = codeblock.formspecs.file_chooser.show

local check_auth_level = codeblock.utils.check_auth_level
local parse_target = codeblock.utils.parse_target

local get_user_data = codeblock.filesystem.get_user_data
local write_file = codeblock.filesystem.write_file
local exists = codeblock.filesystem.exists
local remove_user_data = codeblock.filesystem.remove_user_data
local make_user_dir = codeblock.filesystem.make_user_dir

local examples = codeblock.examples.examples

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

--- Write the bundled example programs into a player's directory.
--
-- Existing files are left alone. This used to overwrite unconditionally, so a
-- player who had opened an example and edited it in place lost that work the
-- next time anyone ran /codegenerate. To get a pristine copy back, delete the
-- file in the editor and run the command again.
--
-- Returns err, written, skipped.
local function generate_examples(name)

    local err = make_user_dir(name)
    if err then
        return err, 0, 0
    end

    local written, skipped = 0, 0
    for ex_name, content in pairs(examples) do
        local filename = ex_name .. '.lua'
        -- filesystem.exists returns nil when the file IS present
        if exists(name, filename, true) == nil then
            skipped = skipped + 1
        else
            local werr = write_file(name, filename, content)
            if werr then
                return werr, written, skipped
            end
            written = written + 1
        end
    end

    return nil, written, skipped
end

--------------------------------------------------------------------------------
-- tools
--------------------------------------------------------------------------------

minetest.register_tool("codeblock:poser", {
    description = S("Drone placer"),
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
        -- The drone decides whether a file still has to be picked; the form
        -- layer is asked for it from here, so lib/drone.lua need not know it
        -- exists. (A11)
        if drone_on_place(name, pos) then show_file_chooser(name) end
        return itemstack
    end,
    on_secondary_use = function() end
})

minetest.register_tool("codeblock:setter", {
    description = S("Drone setter"),
    inventory_image = "drone_setter.png",
    range = 0,
    stack_max = 1,
    on_drop = function(itemstack) return itemstack end,
    on_use = function(itemstack, user)
        local name = user:get_player_name()
        drone_on_remove(name)
        return itemstack
    end,
    on_place = function(itemstack, placer)
        local name = placer:get_player_name()
        show_file_editor(name)
        return itemstack
    end,
    on_secondary_use = function(itemstack, user)
        local name = user:get_player_name()
        show_file_editor(name)
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

    local name = player:get_player_name()

    -- init user data
    get_user_data(name)

    -- example
    generate_examples(name)

    -- privs
    local privs = minetest.get_player_privs(player:get_player_name())
    privs.fly = true
    privs.fast = true
    privs.noclip = true
    minetest.set_player_privs(player:get_player_name(), privs)

    -- meta
    local meta = player:get_meta()
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
    -- TODO: TEMP fix
    player:override_day_night_ratio(1)
    player:set_stars({visible = false})
    player:set_sun({visible = false})
    player:set_moon({visible = false})
    player:set_clouds({density = 0})

end)

minetest.register_on_leaveplayer(function(player, timed_out)
    local name = player:get_player_name()
    drone_on_remove(name)
    remove_user_data(name)
end)

--------------------------------------------------------------------------------
-- Commands and privileges
--------------------------------------------------------------------------------

-- give_to_singleplayer was false, which made /codelevel unusable in exactly the
-- setting this game is mostly played in - while the command's own body carried
-- a dead is_singleplayer() branch trying to work around it. In singleplayer the
-- player is the administrator, so the privilege belongs to them.
minetest.register_privilege("codeblock", {
    description = "Player can set another player's codelevel and generate " ..
        "their example programs",
    give_to_singleplayer = true
})

minetest.register_chatcommand("codelevel", {
    params = "[<playername>] <1-4>",
    description = "Set a player's codelevel",
    -- Stays privileged, including for your own level. codelevel is the knob
    -- that bounds how much a program may do - calls, volume, commands - so a
    -- player who could raise their own would be lifting their own limits. The
    -- bug was never the privilege, it was that the privilege was unobtainable
    -- in singleplayer.
    privs = {codeblock = true},
    func = function(name, params)

        local pname, level = parse_target(name, params, '%d+')

        if not pname then
            return false, S(
                       'Usage: codelevel <playername> <level> OR codelevel <level>')
        end

        local valid, al = check_auth_level(tonumber(level))
        if not valid then return false, S('Invalid codelevel') end

        local player = get_player_by_name(pname)
        if not player then return false, S('Player not found') end

        player:get_meta():set_int('codeblock:auth_level', al)
        return true, S('@1 codelevel set to @2', pname, al)

    end
})

minetest.register_chatcommand("codegenerate", {
    params = "[<playername>]",
    description = "Write any missing example programs into a player's files",
    -- Same rule: your own files are yours; someone else's need the privilege.
    -- This command used to have no privs at all AND ignore the name it parsed,
    -- so it could only ever overwrite the caller's own files.
    func = function(name, params)

        local pname = string.match(params, '^%s*([%a][%w_%-]*)%s*$') or
                          (params:match('^%s*$') and name)

        if not pname then return false, S('Usage: codegenerate [playername]') end

        if pname ~= name and not minetest.check_player_privs(name, {
            codeblock = true
        }) then
            return false, S('You need the codeblock privilege to generate ' ..
                                'examples for another player')
        end

        if not get_player_by_name(pname) then
            return false, S('Player not found')
        end

        local err, written, skipped = generate_examples(pname)
        if err then
            return false, S('An error occured when generating example')
        end
        return true, S('@1: @2 examples written, @3 already present', pname,
                       written, skipped)

    end
})

--------------------------------------------------------------------------------
-- formspecs
--------------------------------------------------------------------------------
