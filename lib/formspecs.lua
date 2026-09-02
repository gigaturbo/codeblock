codeblock.formspecs = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S

local tcik = codeblock.utils.table_convert_ik
local scroll_max = codeblock.utils.scroll_max
local split = codeblock.utils.split

local formspec_escape = core.formspec_escape
local chat_send_player = core.chat_send_player
local close_form = codeblock.forms.close
local update_form = codeblock.forms.update
local show_form = codeblock.forms.show
local get_form_meta = codeblock.forms.get_meta
local explode_textlist_event = core.explode_textlist_event
local explode_scrollbar_event = core.explode_scrollbar_event
local get_player_by_name = core.get_player_by_name

local blocks = codeblock.config.allowed_blocks.all
local cubes = codeblock.config.allowed_blocks.cubes
local plants = codeblock.config.allowed_blocks.plants
local wools = codeblock.config.allowed_blocks.wools
local cubes_ik = tcik(cubes)
local plants_ik = tcik(plants)
local wools_ik = tcik(wools)

-- Every name the default-block picker offers, with the API path to show beside
-- it. One list rather than a tab per table: the three share one namespace, so
-- default_block and place() take a name from any of them. (F1)
local pickable = {}
for _, group in ipairs({
    {cubes_ik, 'blocks'}, {plants_ik, 'plants'}, {wools_ik, 'wools'}
}) do
    for _, key in ipairs(group[1]) do
        pickable[#pickable + 1] = {key = key, label = group[2] .. '.' .. key}
    end
end

local get_user_data = codeblock.filesystem.get_user_data
local read_file = codeblock.filesystem.read_file
local write_file = codeblock.filesystem.write_file
local remove_file = codeblock.filesystem.remove_file

local set_file = codeblock.Drone.set_file
local get_drone = codeblock.Drone.get
local remove_drone = codeblock.Drone.remove
local stop_drone = codeblock.Drone.on_remove

local hud_wanted = codeblock.hud.wanted
local hud_set_wanted = codeblock.hud.set_wanted
-- One naming of the four limits for both surfaces, plus the number formatting;
-- lib/hud.lua owns how a limit is described to a player.
local limit_label = codeblock.hud.limit_label
local limit_description = codeblock.hud.limit_description
local short_number = codeblock.hud.short_number
local pct_colour = codeblock.hud.pct_colour
local limits_report = codeblock.limits.report
local limits_binding = codeblock.limits.binding

--------------------------------------------------------------------------------
-- private
--------------------------------------------------------------------------------

-- file_editor

local file_editor = {

    --- Open the editor for `name`, restoring the tabs it was left with.
    --
    -- A tab whose file has since gone is dropped silently; one that fails to
    -- read is reported and skipped, so a single bad file cannot cost the player
    -- the rest of the session.
    show = function(name)

        local ud = get_user_data(name, true)

        -- load saved state
        local tabs = {}
        local contents = {}
        -- One flag per tab, kept dense so table.remove shifts it with the two
        -- arrays beside it. Nothing restored here is dirty: every buffer was
        -- just read from the file it names. (F7)
        local dirty = {}
        local active = 0
        local soe = false
        local loe = false
        local sos = false
        local dhud = false
        local dblock = cubes.stone
        local player = get_player_by_name(name)
        if player then
            local meta = player:get_meta()
            -- Converted to booleans here, at the persistence boundary,
            -- because 0 is truthy in Lua and `if meta.sos then` on the
            -- 0/1 these are stored as is always true.
            --
            -- Read as strings rather than through get_int, which cannot
            -- tell a box the player unticked from one they have never
            -- seen: both come back 0. An absent key is "", so these two
            -- can start ticked for a new player and still honour an
            -- untick. set_int writes the digit as a string, so a stored
            -- 0 reads back as '0' and stays off.
            local s_loe = meta:get_string('codeblock:load_on_exit')
            local s_sos = meta:get_string('codeblock:save_on_switch')
            soe = meta:get_string('codeblock:save_on_exit') == '1'
            loe = s_loe == '' or s_loe == '1'
            sos = s_sos == '' or s_sos == '1'
            -- Same string read for the same reason, but the fallback is the
            -- server's setting rather than a literal, so hud.wanted owns it -
            -- there must be one answer to "does this player see it" and the
            -- tick in this box is the same question the HUD asks itself. (F4)
            dhud = hud_wanted(player)
            -- Validated on read, the same check lib/drone.lua makes at the
            -- start of a run: this key outlives a change to the palette, and a
            -- player who joined before the setting existed has none. (F1)
            local stored = meta:get_string('codeblock:default_block')
            if blocks[stored] then dblock = stored end
            local saved_active =
                meta:get_string('codeblock:editor_state_active')
            local saved_tabs = meta:get_string('codeblock:editor_state_tabs')
            for _, filename in ipairs(split(saved_tabs, ',')) do
                if ud.byname[filename] then
                    local content, err = read_file(name, filename, true)
                    if err then
                        chat_send_player(name, err)
                    else
                        table.insert(tabs, filename)
                        table.insert(contents, content)
                        table.insert(dirty, false)
                        if filename == saved_active then active = #tabs end
                    end
                end
            end
        end

        local meta = {
            name = name,
            tabs = tabs,
            contents = contents,
            dirty = dirty,
            active = active,
            help = 'cubes',
            scroll_c = 0,
            scroll_p = 0,
            scroll_w = 0,
            default_block = dblock,
            picking = false,
            soe = soe,
            dhud = dhud,
            loe = loe,
            sos = sos,
            newfile = ''
        }
        show_form(name, 'codeblock:file_editor', meta,
                  codeblock.formspecs.file_editor.get_form(meta),
                  codeblock.formspecs.file_editor.on_close)

    end,

    get_form = function(meta)

        local ud = get_user_data(meta.name)
        -- 10 rather than 10.5: the half unit was the row the three preference
        -- checkboxes sat on at y=10, and with them on the Settings panel it was
        -- background below every element. Nothing is positioned by this - a
        -- legacy form does not clip to it - so it only trims the empty band.
        local fs = "size[20,10]"

        -- styles
        fs = fs .. 'style[remove;bgcolor=red]'
        fs = fs .. 'style[content;font=mono;font_size=-2;textcolor=#115555]'
        fs = fs .. 'style[create;bgcolor=green]'
        fs = fs .. 'style[help_cubes;bgcolor=blue]'
        fs = fs .. 'style[help_plants;bgcolor=blue]'
        fs = fs .. 'style[help_wools;bgcolor=blue]'
        fs = fs .. 'style[help_cmds;bgcolor=blue]'
        fs = fs .. 'style[help_settings;bgcolor=blue]'

        -- tabs. The asterisk marks a buffer that differs from the file, and is
        -- decoration only: meta.tabs holds the name write_file, read_file and
        -- remove_file are handed, and fields.tabs comes back as an index, so
        -- nothing reads this label. Never append it to the name itself - that
        -- creates a file called foo.lua*. (F7)
        if #meta.tabs > 0 then
            fs = fs .. 'tabheader[0,0;tabs;'
            for i, filename in ipairs(meta.tabs) do
                if i ~= 1 then fs = fs .. ',' end
                fs = fs .. formspec_escape(filename)
                if meta.dirty[i] then fs = fs .. '*' end
            end
            fs = fs .. ';' .. (meta.active or 0) .. ';false;false]'
        end

        -- files. Shortened from 8.75 to leave the row below it for Copy file;
        -- the gap stays empty with no file open rather than the list changing
        -- height as tabs come and go. (F2)
        fs = fs .. 'textlist[0, 0; 3, 8.1;files;'
        for i, file in ipairs(ud.list) do
            if i ~= 1 then fs = fs .. ',' end
            fs = fs .. formspec_escape(file.name)
        end
        local shown = ud.byname[meta.tabs[meta.active]]
        fs = fs .. ';' .. (shown and shown.index or 0) .. ']'

        -- Copy file. Down here rather than with Save/Remove/Close: that row
        -- runs to x=14.08 and the help row starts at 14, so a fifth button
        -- means re-laying-out four that work. Drawn only with a file open, for
        -- the same reason those four are - it acts on the open file. (F2)
        -- 3.2 wide, not 3, to end flush with the 3-wide list above it. In
        -- legacy coordinates a button is not as wide as its W says: the engine
        -- computes W*spacing - (spacing - imgsize) for a button and plain
        -- W*spacing for a textlist, and spacing is imgsize*5/4, so every button
        -- is short by a fixed 0.2 units whatever W is. The H is decoration
        -- too - a legacy button's height is fixed and W's partner only shifts
        -- it down. (F2)
        if meta.active ~= 0 then
            fs = fs .. 'button[0, 8.3;3.2, 0.7;copy;' .. S('Create a copy') ..
                     ']'
        end

        -- new file
        fs = fs .. 'field_close_on_enter[newfile;false]'
        fs = fs .. 'field[0.27, 9.5;2.5, 1;newfile;' .. S('New file:') .. ';' ..
                 formspec_escape(meta.newfile) .. ']'
        -- 0.95 for the same reason 'copy' above is 3.2: at W=1 this button ran
        -- 0.05 units past the list's right edge instead of ending on it. (F2)
        fs = fs .. 'button[2.25, 9.20;0.95, 1;create;+]'

        -- file buttons
        if meta.active ~= 0 then
            fs = fs .. 'button[3.25 ,0 ;2 ,0.75;save;' .. S('Save') .. ']'
            fs = fs .. 'button[5.25 ,0 ;3 ,0.75;load;' .. S('Load and close') ..
                     ']'
            fs = fs .. 'button[8.25 ,0 ;3, 0.75;remove;' .. S('Remove file') ..
                     ']'
            fs = fs .. 'button[11.25,0;2.83, 0.75;close;' .. S('Close file') ..
                     ']'
        end

        -- help panel switches. Outside the block above on purpose: the panel is
        -- drawn with no file open, so without these it opens on the block list
        -- with no way to reach the others.
        -- Five across the same 14-to-20 span the four used, so Settings fits
        -- without the row running off the form. It is the wider one: the word
        -- does not fit 1.1. (F1)
        fs = fs .. 'button[14,0;1.1, 0.75;help_cubes;' .. S('Blocks') .. ']'
        fs = fs .. 'button[15.1,0;1.1, 0.75;help_plants;' .. S('Plants') .. ']'
        fs = fs .. 'button[16.2,0;1.1, 0.75;help_wools;' .. S('Wools') .. ']'
        fs = fs .. 'button[17.3,0;1.1, 0.75;help_cmds;' .. S('API') .. ']'
        fs = fs .. 'button[18.4,0;1.6, 0.75;help_settings;' .. S('Settings') ..
                 ']'

        -- The three preference checkboxes used to be here, loose along the bottom
        -- edge. They are on the Settings panel now, with the default-block
        -- picker, which is what that panel is for. (F8, playtest H3)

        -- textarea
        local text = meta.contents[meta.active]
        if meta.active ~= 0 and text then
            local etext = formspec_escape(text)
            fs = fs .. 'textarea[3.5,0.75;10.85,11;content;;' .. etext .. ']'
        elseif meta.active == 0 then
            fs =
                fs .. 'label[5.5,4.5;' .. S('Double click a file to open it') ..
                    ']'
        else
            fs = fs .. 'label[4.5,3;' .. S('Cannot read file') .. ']'
        end

        -- help
        if meta.help == 'cubes' then

            fs = fs .. 'scrollbaroptions[min=0;max=' .. scroll_max(cubes_ik) ..
                     ';smallstep=1;largestep=5]'
            fs = fs .. 'scrollbar[19.5, 1;0.3, 9.25;vertical;c_scroll;' ..
                     meta.scroll_c .. ']'
            fs = fs ..
                     'scroll_container[17.75, 1.25;7.25, 10.75;c_scroll;vertical;' ..
                     0.5 .. ']'
            local yi, yl
            for i, v in pairs(cubes_ik) do
                yi = tostring(i - 1 - 0.25)
                yl = tostring(i - 1)
                fs =
                    fs .. 'item_image[' .. '0,' .. yi .. ';1,1;' .. blocks[v] ..
                        ']'
                fs = fs .. 'label[1,' .. yl .. ';blocks.' .. v .. ']'
            end
            fs = fs .. 'scroll_container_end[]'

        elseif meta.help == 'plants' then

            fs = fs .. 'scrollbaroptions[min=0;max=' .. scroll_max(plants_ik) ..
                     ';smallstep=1;largestep=5]'
            fs = fs .. 'scrollbar[19.5, 1;0.3, 9.25;vertical;p_scroll;' ..
                     meta.scroll_p .. ']'
            fs = fs ..
                     'scroll_container[17.75, 1.25;7.25, 10.75;p_scroll;vertical;' ..
                     0.5 .. ']'
            local yi, yl
            for i, v in pairs(plants_ik) do
                yi = tostring(i - 1 - 0.25)
                yl = tostring(i - 1)
                fs =
                    fs .. 'item_image[' .. '0,' .. yi .. ';1,1;' .. blocks[v] ..
                        ']'
                fs = fs .. 'label[1,' .. yl .. ';plants.' .. v .. ']'
            end
            fs = fs .. 'scroll_container_end[]'

        elseif meta.help == 'wools' then

            fs = fs .. 'scrollbaroptions[min=0;max=' .. scroll_max(wools_ik) ..
                     ';smallstep=1;largestep=5]'
            fs = fs .. 'scrollbar[19.5, 1;0.3, 9.25;vertical;w_scroll;' ..
                     meta.scroll_w .. ']'
            fs = fs ..
                     'scroll_container[17.75, 1.25;7.25, 10.75;w_scroll;vertical;' ..
                     0.5 .. ']'
            local yi, yl
            for i, v in pairs(wools_ik) do
                yi = tostring(i - 1 - 0.25)
                yl = tostring(i - 1)
                fs = fs .. 'item_image[' .. '0,' .. yi .. ';1,1;' ..
                         blocks[wools[v]] .. ']'
                fs = fs .. 'label[1,' .. yl .. ';wools.' .. v .. ']'
            end
            fs = fs .. 'scroll_container_end[]'

        elseif meta.help == 'commands' then

            fs = fs .. 'hypertext[14.5,1;5.75,10.75;commands_html;' ..
                     codeblock.utils.html_commands .. ']'

        elseif meta.help == 'settings' then

            -- The block a bare place() uses, and what a program's
            -- default_block() starts each run from. The list is only drawn
            -- while the player is choosing; the rest of the time the setting is
            -- one line. Selecting a row saves it at once rather than on close,
            -- so the choice does not depend on the path that saves the editor's
            -- own state. (F1)
            -- The line is the button: clicking it opens the list, clicking it
            -- again closes it. One control rather than a label and a switch
            -- beside it.
            fs = fs .. 'item_image[14.5,1.15;0.8,0.8;' ..
                     blocks[meta.default_block] .. ']'
            fs = fs .. 'button[15.3,1.15;4.4,0.8;pick_open;' ..
                     S('Default block: @1', meta.default_block) .. ']'

            -- A textlist, not the item rows the help panels draw. This form is
            -- in legacy coordinates, where a scroll_container maps its contents
            -- into a different space from the elements around it and clips them
            -- to its own rectangle - which put the rows over the text area, and
            -- left an item_image_button inside it with a hit area that never
            -- matched where it was drawn. The three help panels get away with a
            -- container because item_image takes no clicks. textlist is a
            -- legacy element, scrolls by itself, and is what the file list in
            -- this same form already uses. The price is that the rows are names
            -- only, with the texture of the chosen one shown above. (F1)
            if meta.picking then
                local index = 0
                fs = fs .. 'textlist[14.5,2.2;5.2,7.5;pick;'
                for i, v in ipairs(pickable) do
                    if i ~= 1 then fs = fs .. ',' end
                    fs = fs .. formspec_escape(v.label)
                    if v.key == meta.default_block then index = i end
                end
                fs = fs .. ';' .. index .. ']'
            end

            -- The three preferences, together on the panel that is for
            -- preferences. They used to sit loose along the bottom edge of the
            -- form, beside nothing and below the text area, which is where the
            -- first two ended up when there was nowhere else and where the third
            -- followed them. Hidden while the block list is open, because that
            -- textlist is drawn over this space. (F8, playtest H3)
            -- No heading: this whole panel is the settings panel, so a
            -- "Preferences" label above three checkboxes on it named the panel
            -- twice. The rows moved up into the space it held.
            if not meta.picking then
                fs = fs .. 'checkbox[14.5,2.5;loe;' ..
                         S('Load program on exit') .. ';' ..
                         (meta.loe and 'true' or 'false') .. ']'
                fs = fs .. 'checkbox[14.5,3.1;sos;' ..
                         S('Save on tab switch') .. ';' ..
                         (meta.sos and 'true' or 'false') .. ']'
                fs = fs .. 'checkbox[14.5,3.7;dhud;' ..
                         S('Show the drone HUD') .. ';' ..
                         (meta.dhud and 'true' or 'false') .. ']'
            end

        end

        return fs
    end,

    on_close = function(meta, player, fields)

        local name = player:get_player_name()

        local function update()
            update_form(name, codeblock.formspecs.file_editor.get_form(meta))
        end

        local function exit()
            close_form(name)
        end

        local function load_active()
            if meta.active ~= 0 then
                set_file(name, meta.tabs[meta.active])
            end
        end

        local function save_active()
            local err = write_file(name, meta.tabs[meta.active],
                                   meta.contents[meta.active])
            if err then
                chat_send_player(name, err)
                return
            end
            -- Clean only on a write that happened: a refused save leaves the
            -- buffer differing from the file, which is what the mark says. (F7)
            meta.dirty[meta.active] = false
        end

        local function remove_active()
            if meta.active == 0 then return end
            if #meta.tabs == 0 then return end
            local filename = meta.tabs[meta.active]
            local err = remove_file(name, filename)
            if err then
                chat_send_player(name, err)
            else
                -- The drone holding this file would otherwise stand in the world
                -- naming one that no longer exists, and only go away on the next
                -- run, where reading it fails. Taking it with the file is the
                -- same answer B41 gave for a chooser cancelled with none picked;
                -- the two have to agree. remove_file knows nothing about drones
                -- and should not - this is the caller's to do. (B44)
                local drone = get_drone(name)
                if drone and drone.file == filename then remove_drone(name) end
                table.remove(meta.tabs, meta.active)
                table.remove(meta.contents, meta.active)
                table.remove(meta.dirty, meta.active)
                meta.active = 0
                if #meta.tabs > 0 then
                    for i, filename in ipairs(meta.tabs) do
                        meta.active = i
                    end
                end
            end
        end

        local function select_tab(i) meta.active = i end

        -- Takes the file record rather than a list position, so the two callers
        -- that have a name and the one that has an index each look it up their
        -- own way and a miss is nil here instead of an index of nil there.
        local function open(file)
            if not file then return end
            local content, err = read_file(name, file.name)
            if err then
                chat_send_player(name, err)
                return
            end
            table.insert(meta.tabs, file.name)
            table.insert(meta.contents, content)
            table.insert(meta.dirty, false)
            meta.active = #meta.tabs
        end

        local function create_file(filename)
            if (not filename) or filename == '' then return nil end
            local parts = codeblock.utils.split(filename, '.')
            if #parts > 0 then
                filename = parts[1]
                filename = string.gsub(filename, '[^%w_-]', '')
                filename = string.sub(filename, 1, 15)
                if #filename == 0 then return end
                filename = filename .. '.lua'
                if not get_user_data(name).byname[filename] then
                    write_file(name, filename,
                               '-- ' .. filename .. '\n\n' ..
                                   "for i = 1, 10 do\n" ..
                                   "  place(blocks.obsidian)\n" .. "  up(1)\n" ..
                                   "end\n")

                    meta.newfile = ''
                    return filename
                end
            end
            return nil
        end

        -- Copy the open file under a derived name and open the copy, so the
        -- player can try a variation without touching the version that works.
        -- It deliberately does not save the original first: what is copied is
        -- what is on screen, and the original is left exactly as it is on disk.
        -- The write goes through write_file, the module's one write path, with
        -- a name derived below rather than typed - not through create_file,
        -- which exists to sanitise a name a player typed. (F2)
        local function copy_active()

            if meta.active == 0 then return end
            local source = meta.tabs[meta.active]
            local content = meta.contents[meta.active]

            -- foo.lua -> foo_1.lua -> foo_2.lua: a number, not a word, so the
            -- name a player ends up with does not depend on the server's
            -- language. Both strips are anchored to the end of the name, never
            -- inserted before the extension (B15).
            --
            -- Stripping a trailing _<digits> is what makes copying a copy
            -- stable. Without it the previous suffix became part of the next
            -- stem, and since the stem is also what gets trimmed to
            -- create_file's 15-character limit, each round both nested and lost
            -- a character: _copy, _cop_copy, _co_copy2. Trimming the suffix
            -- instead is not an option - it hands back the original name for
            -- any stem already at the limit.
            local base = source:gsub('%.lua$', ''):gsub('_%d+$', '')
            local byname = get_user_data(name).byname
            local filename
            for i = 1, 99 do
                local suffix = '_' .. i
                local candidate = base:sub(1, 15 - #suffix) .. suffix .. '.lua'
                if not byname[candidate] then
                    filename = candidate
                    break
                end
            end

            if not content or not filename then
                chat_send_player(name, S('Cannot copy @1', source))
                return
            end

            local err = write_file(name, filename, content)
            if err then
                chat_send_player(name, err)
                return
            end

            open(get_user_data(name).byname[filename])

        end

        local function close_active()
            if meta.active == 0 then return end
            if #meta.tabs == 0 then return end
            table.remove(meta.tabs, meta.active)
            table.remove(meta.contents, meta.active)
            table.remove(meta.dirty, meta.active)
            meta.active = 0
            if #meta.tabs > 0 then
                for i, filename in ipairs(meta.tabs) do
                    meta.active = i
                end
            end
        end

        local function save_editor_state()
            local stabs = table.concat(meta.tabs, ',')
            -- Deliberately re-looked-up rather than reusing the `player`
            -- argument: the formspecs mod captures a player object when the form
            -- opens and hands the same one back later, so it can be stale.
            local cur_player = get_player_by_name(name)
            if cur_player then
                local pmeta = cur_player:get_meta()
                pmeta:set_string('codeblock:editor_state_tabs', stabs)
                -- meta.active is 0 with no tab open, which is the normal state
                -- after closing the last file, and set_string will not take the
                -- nil that indexes to. "" is what the reader compares against
                -- anyway. (B13)
                pmeta:set_string('codeblock:editor_state_active',
                                 meta.tabs[meta.active] or "")
                -- booleans in memory, ints on disk
                pmeta:set_int('codeblock:save_on_exit', meta.soe and 1 or 0)
                pmeta:set_int('codeblock:load_on_exit', meta.loe and 1 or 0)
                pmeta:set_int('codeblock:save_on_switch', meta.sos and 1 or 0)
            end
        end

        -- The textarea's value arrives with every submit, and every redraw below
        -- re-renders it from meta.contents. So it is taken once here rather than
        -- in the branches that happened to remember: without it, any button that
        -- was not Save - a help panel, a checkbox, a tab, the block picker -
        -- threw away everything typed since the last one. Still the *old* active
        -- tab at this point, which is what the tab and file branches want.
        -- Absent from the quit event, which carries no field but `quit`. (B35)
        --
        -- The tab is marked dirty from the comparison rather than from the
        -- field arriving: the textarea reports itself on every submit, so
        -- setting the flag unconditionally here would mark every tab on the
        -- first button press and the mark would mean nothing. Comparing against
        -- the buffer costs no memory - it is the copy already held - and is not
        -- the pristine-copy design F7 rejected, so it says *differs from what
        -- was last written* and not *differs from disk*: typing a character and
        -- undoing it leaves the tab marked until the next save. That is the
        -- harmless direction. (F7)
        if fields.content and meta.active ~= 0 then
            if fields.content ~= meta.contents[meta.active] then
                meta.dirty[meta.active] = true
            end
            meta.contents[meta.active] = fields.content
        end

        -- The open help panel's scroll position, read here for the same reason,
        -- and not a branch below. A scrollbar reports itself on *every* submit,
        -- not only when it moved: the engine sets send = true when it parses one
        -- and then emits 'VAL:n' unconditionally, so this is state like
        -- fields.content and not an event. As a branch it sat above quit, the
        -- block picker and the new-file field and swallowed all three whenever
        -- Blocks, Plants or Wools was showing - which is the panel the editor
        -- opens on. Closing with ESC then never saved the open tabs. (B37)
        --
        -- lua_api.md does not say this. It documents the two ways to read a
        -- scrollbar and the 'CHG'/'VAL' prefixes, but not that a scrollbar is
        -- always in the field table; guiFormSpecMenu.cpp's parseScrollBar and
        -- acceptInput are where it is visible.
        if fields.c_scroll then
            meta.scroll_c = explode_scrollbar_event(fields.c_scroll).value
        end
        if fields.p_scroll then
            meta.scroll_p = explode_scrollbar_event(fields.p_scroll).value
        end
        if fields.w_scroll then
            meta.scroll_w = explode_scrollbar_event(fields.w_scroll).value
        end

        -- FIELDS INPUTS
        if fields.close then
            close_active()
            update()
        elseif fields.tabs then
            -- Only the write to disk is the option's business; keeping the edit
            -- in memory is not, and gating both on it lost the edit outright.
            if meta.sos then save_active() end
            select_tab(tonumber(fields.tabs))
            update()
        elseif fields.load then
            save_active()
            load_active()
            -- Load and close is an exit like ESC, so the editor state has to
            -- be written on this path too. close_form sends no field table
            -- back, so the quit branch below never runs for it, and the
            -- active tab a player left on was lost. (B33)
            save_editor_state()
            exit()
        elseif fields.save then
            save_active()
            update()
        elseif fields.create then
            local filename = create_file(fields.newfile)
            if filename then
                open(get_user_data(name).byname[filename])
                update()
            end
        elseif fields.copy then
            copy_active()
            update()
        elseif fields.remove then
            remove_active()
            update()
        elseif fields.soe then
            meta.soe = (fields.soe == 'true')
            update()
        elseif fields.loe then
            meta.loe = (fields.loe == 'true')
            update()
        elseif fields.sos then
            meta.sos = (fields.sos == 'true')
            update()
        elseif fields.dhud then
            meta.dhud = (fields.dhud == 'true')
            -- Written now rather than with the other two at close, because this
            -- is the only preference here with an effect outside the form: the
            -- HUD reads player meta on its own tick, so deferring the write
            -- would leave it on screen until the editor was shut. (F4)
            hud_set_wanted(player, meta.dhud)
            update()
        elseif fields.files then
            local e = explode_textlist_event(fields.files)
            local selected = get_user_data(name).list[e.index]
            if e.type == 'DCL' and selected then
                for i, filename in ipairs(meta.tabs) do
                    if filename == selected.name then
                        select_tab(i)
                        update()
                        return
                    end
                end
                open(selected)
                update()
            end
        elseif fields.help_cubes then
            meta.help = 'cubes'
            update()
        elseif fields.help_plants then
            meta.help = 'plants'
            update()
        elseif fields.help_wools then
            meta.help = 'wools'
            update()
        elseif fields.help_cmds then
            meta.help = 'commands'
            update()
        elseif fields.help_settings then
            meta.help = 'settings'
            update()
        elseif fields.pick_open then
            meta.picking = not meta.picking
            update()
        elseif fields.pick then
            -- Validated before it is stored, not merely before it is drawn: an
            -- index arrives from the client, and what it selects ends up in
            -- player meta. Every event on this list is consumed here either
            -- way, so a forged one cannot fall through to the branches below.
            local choice = pickable[explode_textlist_event(fields.pick).index]
            if choice and blocks[choice.key] then
                meta.default_block = choice.key
                meta.picking = false
                -- Written now, not with the rest of the editor's state on
                -- close: that path only runs when the player quits the form,
                -- and a preference must not depend on how they left. (F1, B33)
                --
                -- Looked up fresh for the same reason save_editor_state does:
                -- the player object handed back with a form event can be stale.
                local cur_player = get_player_by_name(name)
                if cur_player then
                    cur_player:get_meta():set_string('codeblock:default_block',
                                                     choice.key)
                end
            end
            update()
        elseif fields.quit == 'true' then -- fields.content cannot be accessed here
            if meta.loe then load_active() end
            save_editor_state()
        -- Enter in the New file field, which is what field_close_on_enter above
        -- keeps the form open for. Keyed on key_enter_field rather than on
        -- fields.newfile being non-empty: a field reports itself on every
        -- submit, so the old test fired on any event no branch above claimed -
        -- and it could not fire at all while a panel scrollbar was shadowing
        -- it. key_enter_field names the field Enter was pressed in, and nothing
        -- else sets it. (B37)
        elseif fields.key_enter_field == 'newfile' then
            local filename = create_file(fields.newfile)
            if filename then
                open(get_user_data(name).byname[filename])
                update()
            end
        end

    end

}

-- file_chooser

local file_chooser = {

    --- Ask `name` which of their files the drone should run.
    show = function(name)
        local meta = {name = name, selectedIndex = 0}
        show_form(name, 'codeblock:file_chooser', meta,
                  codeblock.formspecs.file_chooser.get_form(meta),
                  codeblock.formspecs.file_chooser.on_close)
    end,

    get_form = function(meta)
        local files_txt = {}
        for _, file in ipairs(get_user_data(meta.name).list) do
            table.insert(files_txt, formspec_escape(file.name))
        end
        files_txt = table.concat(files_txt, ',')
        return 'formspec_version[4]' .. 'size[6,6]' .. 'label[0.5,0.5;' ..
                   S('Choose a file:') .. ']' .. 'textlist[0.5,1;5,3;file;' ..
                   files_txt .. ']' .. 'button[0.5,4.5;2,1;choose;' ..
                   S('Choose') .. ']' .. 'button[3.5,4.5;2,1;cancel;' ..
                   S('Cancel') .. ']'
    end,

    on_close = function(meta, player, fields)
        local name = player:get_player_name()

        -- Close the chooser, taking the drone with it when the player leaves
        -- without a file. Drone.on_place creates the drone before showing this
        -- form, and one with no file stands in the world answering "Not a valid
        -- file" on every use, so declining has to undo the placement. (B41)
        local function close()
            local drone = get_drone(name)
            if drone and not drone.file then remove_drone(name) end
            close_form(name)
        end

        -- Nothing selected leaves selectedIndex at 0, which names no file.
        local function choose(i)
            local file = get_user_data(name).list[i]
            if file then set_file(name, file.name) end
            close()
        end

        if fields.choose then
            choose(meta.selectedIndex)
        elseif fields.cancel then
            close()
        elseif fields.file then
            local e = explode_textlist_event(fields.file)
            local t = e.type
            local i = e.index
            if t == 'CHG' then
                meta.selectedIndex = i
                update_form(name,
                            codeblock.formspecs.file_chooser.get_form(meta))
            elseif t == 'DCL' then
                choose(i)
            elseif t == 'INV' then
                return
            end

        elseif fields.quit then
            -- Escape, the window's X, or Enter with nothing focused. Sent only
            -- on an active close, so it cannot mask a button above it.
            close()
        end

    end

}

-- drone_panel
--
-- Everything about one drone in one place: what it is doing, what a running
-- program is spending against each ceiling, and every action a player can take
-- on it. The at-a-glance version is lib/hud.lua; this is the whole table.
--
-- **Reached by left-clicking the drone with the setter, whatever it is doing.**
-- That gesture has meant three things in turn: it removed the drone, then it
-- removed an idle one and opened this panel on a running one, and now it always
-- opens this panel. The two-meanings version was `F4`'s and lasted one playtest
-- (`H4`): a gesture whose effect depends on invisible state is a gesture a player
-- has to guess at.
--
-- **Two buttons, Pause and Stop, and a close x in the corner.** Stop is
-- `Drone.on_remove`, which ends a run if there is one and takes the drone away
-- either way. It was briefly two buttons - Cancel and Remove drone - calling that
-- same function with different labels and colours, which offered a distinction
-- a player would hunt for and never find. One action, one button. (F8)
--
-- **Only the hard limits are listed.** The map footprint stops nothing - it makes
-- the drone wait and frees itself - so showing it beside three ceilings that do
-- end a run invited the exact misreading `B45` was filed for. It is still in
-- `limits.report`; this surface chooses not to draw it.
--
-- Refreshed on the same tick as the HUD. A redraw costs no input focus here
-- because there is no text field in the form - that is what makes a live
-- formspec affordable for this one and not for the editor.

-- name -> the panel's own meta table, for every player with one open. The panel
-- refreshes itself rather than being redrawn by whatever changed, so it has to
-- know who is watching, and forms.lua deliberately does not publish its session
-- list.
--
-- The meta table rather than `true`, so the tick can tell that the form still
-- open for this player is *this* one: forms.lua allows a single form per player,
-- so opening the editor silently replaces the session, and a tick that only knew
-- a name would push the panel's formspec into the editor's form.
local watching = {}

-- One side of a `used / cap` pair, in the row's own unit.
--
-- Counts go through short_number, so 100000000 reads as 100.0M; a quantity with
-- a unit is a small number already and gets one decimal. (F8)
local function fmt(n, unit)
    if unit == '' then return short_number(n) end
    return ('%.1f %s'):format(n, unit)
end

-- Where the rows and the buttons sit, so the form's height and the loop that
-- fills it cannot disagree. A row is a bold name with its numbers, then two
-- wrapped lines of description under it, which is what sets ROW_H.
local PANEL_W = 10
local ROW_Y = 1.9
local ROW_H = 1.35
local DESC_DY = 0.3
local HARD_ROWS = 3
local BUTTON_Y = ROW_Y + HARD_ROWS * ROW_H + 0.35

-- The drone's state in the panel header. Deliberately not the amber and red of
-- pct_colour below: those two say how close a limit is to stopping the run, and
-- reusing either for "paused" would make one colour mean two things on one form.
local RUNNING_COLOUR = '#5FD35F'
local PAUSED_COLOUR = '#FFE84D'

-- The percentage, coloured by how much trouble the row is in.
--
-- The rule and the two colours live in lib/hud.lua, which applies them to the
-- same numbers on the corner display: a player looking at both must not be told
-- two different things about one figure. That function answers in the integer a
-- HUD element takes, so it is formatted here for core.colorize.
-- How long the run has been going, in clock time, for the panel's heading.
--
-- Clock time and deliberately not the charged runtime the rows show: after B46
-- renamed that row to say it is not a stopwatch, nothing on either surface could
-- answer *how long has this been building*. This is the same figure the finish
-- message reports as `duration:`, so the live number and the final one agree.
--
-- It keeps counting through a pause: it answers "how long since I started this",
-- which the state word beside it already qualifies. (F9)
local function elapsed(tstart)
    local s = math.floor((core.get_us_time() - tstart) / 1e6)
    if s < 60 then return S('@1s', s) end
    if s < 3600 then
        return S('@1m @2s', math.floor(s / 60), s % 60)
    end
    return S('@1h @2m', math.floor(s / 3600), math.floor(s % 3600 / 60))
end

local function pct_label(fraction, is_binding)
    local text = math.floor(fraction * 100 + 0.5) .. '%'
    local colour = pct_colour(fraction, is_binding)
    if not colour then return text end
    return core.colorize(('#%06X'):format(colour), text)
end

local drone_panel = {

    show = function(name)
        local meta = {name = name}
        watching[name] = meta
        show_form(name, 'codeblock:drone_panel', meta,
                  codeblock.formspecs.drone_panel.get_form(meta),
                  codeblock.formspecs.drone_panel.on_close)
    end,

    get_form = function(meta)

        -- Read fresh on every redraw, never held in meta: this form outlives
        -- the run it describes, and a drone can be replaced by another under
        -- the same name between two ticks of it. (B29)
        local drone = get_drone(meta.name)
        local running = drone and drone.cor and drone.budget

        -- Three states, and the panel opens in all of them: no drone, an idle
        -- one, and a running one. Saying "there is no drone" is a real answer to
        -- the gesture, which is why it no longer has to mean something else when
        -- nothing is running. (F8)
        local fs = 'formspec_version[4]' .. 'size[' .. PANEL_W .. ',' ..
                       (running and (BUTTON_Y + 1.3) or 2.9) .. ']'

        -- An x in the top-right corner, where a window's close control lives,
        -- rather than a fourth button competing with the ones that do something.
        -- ESC still works and arrives as the same quit event.
        fs = fs .. 'button_exit[' .. (PANEL_W - 1.1) .. ',0.35;0.7,0.7;close;x]'

        if not drone then
            return fs .. 'label[0.6,0.9;' .. S('You have no drone') .. ']'
        end

        if not running then
            -- Built like the running heading below rather than as a sentence,
            -- so one panel does not describe two states in two shapes. No
            -- colour: green and yellow there say *a run is happening*, and idle
            -- is the absence of one - a third colour would make the colour mean
            -- "here is a state" instead, which is F8's rule broken. (F9)
            fs = fs .. 'style_type[label;font=bold]'
            fs = fs .. 'label[0.6,0.8;' ..
                     formspec_escape(drone.file or '?.lua') .. ' : ' ..
                     S('idle') .. ']'
            fs = fs .. 'style_type[label;font=normal]'
            -- The same Stop as below: on an idle drone there is no run to end,
            -- so it simply takes the drone away.
            fs = fs .. 'style[stop;bgcolor=red]'
            fs = fs .. 'button[0.6,1.7;2.1,0.8;stop;' .. S('Stop') .. ']'
            return fs
        end

        -- The header: file name in bold, state in green or yellow.
        --
        -- Concatenated rather than built from the S('@1 : @2') key the HUD uses,
        -- because only half of it is coloured and core.colorize has to wrap the
        -- state alone. lua_api.md allows exactly this - "string concatenation
        -- will still work as expected (note that you should only use this for
        -- things like formspecs) ... and operations such as core.colorize which
        -- are also concatenation" - and what is concatenated here is a filename,
        -- a separator and a status word, not a sentence broken into parts.
        --
        -- style_type makes the whole label bold, the font being per element: the
        -- state is bold as well as coloured, which is what the corner display
        -- does with the same line.
        -- The elapsed clock time closes the line, in parentheses and bold with
        -- the rest of it - one label, so it needs no position of its own and
        -- cannot drift from the words it follows. core.colorize resets to #fff
        -- after the state word, so only that word is coloured. (F9)
        fs = fs .. 'style_type[label;font=bold]'
        fs = fs .. 'label[0.6,0.8;' ..
                 formspec_escape(drone.file or '?.lua') .. ' : ' ..
                 core.colorize(drone.paused and PAUSED_COLOUR or RUNNING_COLOUR,
                               drone.paused and S('paused') or S('running')) ..
                 ' (' ..
                 formspec_escape(elapsed(drone.tstart or core.get_us_time())) ..
                 ')]'
        fs = fs .. 'style_type[label;font=normal]'

        -- Which limit will be reached first, used to colour its percentage
        -- rather than to print a sentence. Only the spent resources compete: the
        -- map footprint is a throttle that sits at its ceiling by design and
        -- used to win every time. (B45)
        local binding = limits_binding(drone.budget)

        local y = ROW_Y
        for _, row in ipairs(limits_report(drone.budget)) do
            -- Hard limits only. The held one stops nothing - it makes the drone
            -- wait - so listing it beside three ceilings that do end a run
            -- invited exactly the reading B45 was filed for.
            if not row.held then
                -- Bold for the name only, so the eye lands on the four names
                -- before it reads any number. style_type applies to the elements
                -- that follow it, so each row switches on and back off.
                fs = fs .. 'style_type[label;font=bold]'
                fs = fs .. 'label[0.6,' .. y .. ';' .. limit_label(row.what) ..
                         ']'
                fs = fs .. 'style_type[label;font=normal]'
                fs = fs .. 'label[4.4,' .. y .. ';' .. fmt(row.used, row.unit) ..
                         ' / ' .. fmt(row.cap, row.unit) .. ']'
                fs = fs .. 'label[8.2,' .. y .. ';' ..
                         pct_label(row.at, row.what == binding) .. ']'
                -- An area label, which the engine wraps to the box and never
                -- gives a scrollbar - so a long translation takes a second line
                -- instead of being cut off at the panel edge, and no extra field
                -- arrives on submit. Left edge shared with the name above it.
                fs = fs .. 'label[0.6,' .. (y + DESC_DY) .. ';' ..
                         (PANEL_W - 1.2) .. ',0.7;' ..
                         limit_description(row.what) .. ']'
                y = y + ROW_H
            end
        end

        fs = fs .. 'button[0.6,' .. BUTTON_Y .. ';2.1,0.8;pause;' ..
                 (drone.paused and S('Resume') or S('Pause')) .. ']'
        -- One destructive button, not two. Cancel and Remove drone were the same
        -- call - Drone.on_remove - wearing different labels and colours, which is
        -- a distinction a player would look for and never find.
        fs = fs .. 'style[stop;bgcolor=red]'
        fs = fs .. 'button[2.85,' .. BUTTON_Y .. ';2.1,0.8;stop;' .. S('Stop') ..
                 ']'

        return fs
    end,

    --- Redraw every open panel. Called from the same globalstep as hud.tick, so
    -- the two surfaces never disagree about what the run is spending.
    --
    -- A panel whose session has been replaced - the player opened the editor
    -- over it - is dropped rather than redrawn, because forms.update writes to
    -- whichever form the player actually has open. Copied before the walk, since
    -- the loop writes to the table. (B33)
    tick = function()
        local names = {}
        for name in pairs(watching) do names[#names + 1] = name end
        for _, name in ipairs(names) do
            local meta = watching[name]
            if get_form_meta(name) ~= meta then
                watching[name] = nil
            else
                update_form(name,
                            codeblock.formspecs.drone_panel.get_form(meta))
            end
        end
    end,

    on_close = function(meta, player, fields)

        local name = player:get_player_name()

        -- Every path out of this form drops the watch, including the engine's
        -- quit event, which is also what leaving and shutdown arrive as. (B33)
        local function close()
            watching[name] = nil
            close_form(name)
        end

        -- Both buttons read the drone fresh, and both do nothing if the run
        -- ended between the redraw the player clicked on and this event.
        if fields.pause then
            local drone = get_drone(name)
            if drone and drone.cor then
                drone.paused = not drone.paused
                update_form(name, codeblock.formspecs.drone_panel.get_form(meta))
            end
        elseif fields.stop then
            -- Through Drone.on_remove, which announces a run it cut short and
            -- takes the drone silently when there was nothing running. Those are
            -- the two meanings Stop needs, and it is the one place a run's
            -- outcome is announced, so the player gets exactly one message.
            -- (B12, B30)
            --
            -- This was two buttons, Cancel and Remove drone, and they called
            -- this same function: the same action with two labels and two
            -- colours, offering a difference that did not exist. (F8)
            stop_drone(name)
            close()
        elseif fields.quit then
            -- button_exit sends quit too, so Close needs no branch of its own.
            watching[name] = nil
        end

    end

}

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

codeblock.formspecs.file_chooser = file_chooser
codeblock.formspecs.file_editor = file_editor
codeblock.formspecs.drone_panel = drone_panel
