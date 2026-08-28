--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------
local S = codeblock.S
local get_player_by_name = core.get_player_by_name
local get_pointed_thing_position = core.get_pointed_thing_position
local chat_send_player = core.chat_send_player

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

--- Make sure the player is carrying the two drone tools.
--
-- Adds whichever tool is missing and clears nothing. It used to empty main,
-- craft, craftpreview and craftresult first - invisible in the game this mod is
-- written for, where a player has nothing else, and destructive in any other:
-- adding the mod to a world that already had players makes both tools missing
-- at once, so the next join wiped the inventory. B16 stopped that happening on
-- *every* login, which left the first join after an install still doing it.
-- (B39)
--
-- No room is reported rather than passed over: a player with no drone tools and
-- no explanation has no way into the mod at all.
local function set_tools(player)
    local inv = player:get_inventory()
    local name = player:get_player_name()

    for _, itemname in ipairs({'codeblock:poser', 'codeblock:setter'}) do

        -- The craft grid counts as carrying it. Both tools are undroppable but
        -- nothing stops a player parking one there, and only looking in `main`
        -- would hand them a second copy on every join - which the wipe used to
        -- cover up.
        local stack = ItemStack(itemname)
        local carried = inv:contains_item('main', stack) or
                            inv:contains_item('craft', stack)

        if not carried and not inv:add_item('main', stack):is_empty() then
            chat_send_player(name, S(
                'No room for the drone tools, free a slot and rejoin'))
            return
        end

    end
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

core.register_tool("codeblock:poser", {
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
    -- The engine calls this instead of on_place when there is no node to point
    -- at, which is how aiming past loaded ground or into the sky arrives: the
    -- client cannot point at a node it does not have. An empty function meant
    -- the one gesture a player makes to find the tool's reach was the one that
    -- answered nothing at all - the B10 refusal below could only be seen by
    -- pointing at a node the *server* had not loaded. Routed through the same
    -- call with no position, so there is one refusal and not two. (B38)
    on_secondary_use = function(itemstack, user)
        if user then drone_on_place(user:get_player_name(), nil) end
        return itemstack
    end
})

core.register_tool("codeblock:setter", {
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

core.register_entity("codeblock:drone", codeblock.DroneEntity)

--------------------------------------------------------------------------------
-- players
--------------------------------------------------------------------------------

core.register_on_newplayer(function(player)

    local name = player:get_player_name()

    -- init user data
    get_user_data(name)

    -- example
    generate_examples(name)

    -- privs
    local privs = core.get_player_privs(player:get_player_name())
    privs.fly = true
    privs.fast = true
    privs.noclip = true
    core.set_player_privs(player:get_player_name(), privs)

    -- meta
    local meta = player:get_meta()
    meta:set_string('codeblock:last_file', "")
    meta:set_int('codeblock:auth_level', codeblock.config.default_auth_level)
    meta:set_string('codeblock:editor_state_tabs', "")
    meta:set_string('codeblock:editor_state_active', "")
    -- The three editor preferences are deliberately not written here. They are
    -- read in lib/formspecs.lua with get_string, where an absent key means "the
    -- player has never chosen" and two of them then start ticked - the whole
    -- reason they are not read with get_int, which cannot tell that from a
    -- stored 0 (B5). Writing a 0 at birth made every player look like one who
    -- had unticked both, so the default could never be seen. (B36)

end)

core.register_on_joinplayer(function(player)

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

    -- Presentation, and off unless a game asks for it: see config.flat_sky.
    -- Per-player and re-applied on every join, so nothing has to be undone
    -- when the setting is turned off. (C18)
    if codeblock.config.flat_sky then
        player:override_day_night_ratio(1)
        player:set_stars({visible = false})
        player:set_sun({visible = false})
        player:set_moon({visible = false})
        player:set_clouds({density = 0})
    end

end)

core.register_on_leaveplayer(function(player, timed_out)
    -- Runs after lib/forms.lua's own leave callback, which closes a form still
    -- open and lets its handler write what it holds. That handler reads the
    -- player's file list, which this one drops, and leave callbacks run in load
    -- order - forms.lua is loaded first, so keep it that way. (B33)
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
core.register_privilege("codeblock", {
    description = "Player can set another player's codelevel and generate " ..
        "their example programs",
    give_to_singleplayer = true
})

core.register_chatcommand("codelevel", {
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

core.register_chatcommand("codegenerate", {
    params = "[<playername>]",
    description = "Write any missing example programs into a player's files",
    -- Same rule: your own files are yours; someone else's need the privilege.
    -- This command used to have no privs at all AND ignore the name it parsed,
    -- so it could only ever overwrite the caller's own files.
    func = function(name, params)

        local pname = string.match(params, '^%s*([%a][%w_%-]*)%s*$') or
                          (params:match('^%s*$') and name)

        if not pname then return false, S('Usage: codegenerate [playername]') end

        if pname ~= name and not core.check_player_privs(name, {
            codeblock = true
        }) then
            -- One literal, deliberately: the argument to S is the translation
            -- key, so a key assembled with .. is invisible to anything that
            -- reads the source for strings to translate - and this one was
            -- never in locale/template.txt as a result. Shortened to fit. (C17)
            return false,
                   S('You need the codeblock privilege for another player')
        end

        if not get_player_by_name(pname) then
            return false, S('Player not found')
        end

        local err, written, skipped = generate_examples(pname)
        if err then
            -- Plural, which is the key locale/ has always carried: the singular
            -- here silently unhooked its own translation. (C17)
            return false, S('An error occured when generating examples')
        end
        return true, S('@1: @2 examples written, @3 already present', pname,
                       written, skipped)

    end
})
