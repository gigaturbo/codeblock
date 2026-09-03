--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------
local S = codeblock.S
local get_player_by_name = core.get_player_by_name
local get_pointed_thing_position = core.get_pointed_thing_position
local chat_send_player = core.chat_send_player

local drone_on_run = codeblock.Drone.on_run
local drone_on_step = codeblock.Drone.on_step
local drone_on_place = codeblock.Drone.on_place
local drone_on_remove = codeblock.Drone.on_remove

local show_file_editor = codeblock.formspecs.file_editor.show
local show_file_chooser = codeblock.formspecs.file_chooser.show
local show_drone_panel = codeblock.formspecs.drone_panel.show
local drone_panel_tick = codeblock.formspecs.drone_panel.tick

local hud_tick = codeblock.hud.tick

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

--- Add whichever of the two drone tools a player is not already carrying.
--
-- Clears nothing, ever. Emptying the inventory first is destructive in any
-- world that had players before the mod was installed, where both tools are
-- missing at once and everything else is theirs. (B39)
--
-- The craft grid counts as carrying: nothing stops a player parking a tool
-- there, and looking only in `main` hands them a duplicate on every call.
--
-- Returns how many were added, and whether one did not fit.
local function give_tools(player)

    local inv = player:get_inventory()
    local added, full = 0, false

    for _, itemname in ipairs({'codeblock:poser', 'codeblock:setter'}) do

        local stack = ItemStack(itemname)
        local carried = inv:contains_item('main', stack) or
                            inv:contains_item('craft', stack)

        if not carried then
            if inv:room_for_item('main', stack) then
                inv:add_item('main', stack)
                added = added + 1
            else
                full = true
            end
        end

    end

    return added, full
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
    -- One gesture, one meaning: show me this drone.
    --
    -- It has meant three things in turn. It removed the drone; then `F4` split
    -- it, removing an idle one and opening the panel on a running one; and that
    -- split lasted exactly one playtest (`H4`), because a gesture whose effect
    -- depends on state the player cannot see is a gesture they have to guess at
    -- - and the guess destroys a build. Now it always opens the panel, which
    -- answers for all three states including *you have no drone*, and removal is
    -- a button in there. (F4, F8)
    on_use = function(itemstack, user)
        show_drone_panel(user:get_player_name())
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
-- the server step
--------------------------------------------------------------------------------

-- One globalstep for the running programs and for both surfaces that show what
-- they are spending, rather than one each. The two displays show the same
-- numbers, so a player watching both must not see them disagree: hud.tick owns
-- the cadence and says when it actually redrew - it is the same display period
-- for both - and the panel follows. The programs are advanced first, so what is
-- drawn is the state at the end of this step and not the last one.
--
-- Drone.on_step is here and not in the drone entity because an entity is deleted
-- with its mapblock, and a program must not be. (B50, B52)
--
-- None of the three is registered in its own module because none should have to
-- know the others exist; the orchestration is the caller's, which is here.
-- (F4, A11)
core.register_globalstep(function(dtime)
    drone_on_step(dtime)
    if hud_tick(dtime) then drone_panel_tick() end
end)

--------------------------------------------------------------------------------
-- players
--------------------------------------------------------------------------------

core.register_on_newplayer(function(player)

    local name = player:get_player_name()

    -- init user data
    get_user_data(name)

    -- example
    generate_examples(name)

    -- The two routes to the tools, said once. Nothing hands them out any more,
    -- so a player who is never told has no way in. (F10)
    chat_send_player(name, S(
        'Get the drone tools with /codeblock tools, or from the creative inventory'))

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

-- give_to_singleplayer, because in singleplayer the player is the
-- administrator: with it false the privileged subcommands were unusable in
-- exactly the setting this mod is mostly played in.
core.register_privilege("codeblock", {
    description = "Player can set a codelevel, and give the drone tools or " ..
        "generate the example programs for another player",
    give_to_singleplayer = true
})

--- Parse "[<playername>]" alone: the caller when omitted, nil when malformed.
-- The sibling of utils.parse_target, which needs a second argument to parse.
local function target_only(caller, params)
    if params:match('^%s*$') then return caller end
    return params:match('^%s*([%a][%w_%-]*)%s*$')
end

-- One entry per subcommand, each taking the caller's name and the arguments
-- after the subcommand word, and answering as a chatcommand func does.
--
-- Two privilege rules, and they differ on purpose. `tools` and `generate` act
-- on things that are the player's own, so they are free for yourself and need
-- the privilege for somebody else. `level` needs it either way: codelevel is
-- the knob that bounds what a program may spend, so a player able to raise
-- their own would be lifting their own ceilings.
local subcommands = {}

subcommands.tools = function(caller, params)

    local pname = target_only(caller, params)
    if not pname then
        return false, S('Usage: /codeblock tools [<playername>]')
    end

    if pname ~= caller and not core.check_player_privs(caller, {
        codeblock = true
    }) then
        -- One literal, deliberately: the argument to S is the translation key,
        -- so a key assembled with .. is invisible to anything that reads the
        -- source for strings to translate. (C17)
        return false, S('You need the codeblock privilege for another player')
    end

    local player = get_player_by_name(pname)
    if not player then return false, S('Player not found') end

    local added, full = give_tools(player)
    if full then
        return false, S('No room for the drone tools of @1, free a slot', pname)
    end
    if added == 0 then
        return true, S('@1 already carries both drone tools', pname)
    end
    return true, S('Drone tools given to @1', pname)

end

subcommands.level = function(caller, params)

    if not core.check_player_privs(caller, {codeblock = true}) then
        return false, S('You need the codeblock privilege to set a codelevel')
    end

    local pname, level = parse_target(caller, params, '%d+')
    if not pname then
        return false, S('Usage: /codeblock level [<playername>] <1-4>')
    end

    local valid, al = check_auth_level(tonumber(level))
    if not valid then return false, S('Invalid codelevel') end

    local player = get_player_by_name(pname)
    if not player then return false, S('Player not found') end

    player:get_meta():set_int('codeblock:auth_level', al)
    return true, S('@1 codelevel set to @2', pname, al)

end

subcommands.generate = function(caller, params)

    local pname = target_only(caller, params)
    if not pname then
        return false, S('Usage: /codeblock generate [<playername>]')
    end

    if pname ~= caller and not core.check_player_privs(caller, {
        codeblock = true
    }) then
        return false, S('You need the codeblock privilege for another player')
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
    return true, S('@1: @2 examples written, @3 already present', pname, written,
                   skipped)

end

core.register_chatcommand("codeblock", {
    params = "tools [<playername>] | level [<playername>] <1-4> | " ..
        "generate [<playername>]",
    description = "Give the drone tools, set a codelevel, or write the " ..
        "example programs",
    -- No command-level privs: two of the three subcommands are free for
    -- yourself, so each one asks for what it needs.
    func = function(name, params)

        local sub, rest = params:match('^%s*(%a+)%s*(.-)%s*$')
        local handler = sub and subcommands[sub]

        if not handler then
            return false, S('Usage: /codeblock tools [<playername>]') .. '\n' ..
                       S('Usage: /codeblock level [<playername>] <1-4>') ..
                       '\n' .. S('Usage: /codeblock generate [<playername>]')
        end

        return handler(name, rest)

    end
})
