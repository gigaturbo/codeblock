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
local explode_textlist_event = core.explode_textlist_event
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
        local active = 0
        local soe = false
        local loe = false
        local sos = false
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
                        if filename == saved_active then active = #tabs end
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
            default_block = dblock,
            picking = false,
            soe = soe,
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
        local fs = "size[20,10.5]"

        -- styles
        fs = fs .. 'style[remove;bgcolor=red]'
        fs = fs .. 'style[content;font=mono;font_size=-2;textcolor=#115555]'
        fs = fs .. 'style[create;bgcolor=green]'
        fs = fs .. 'style[help_cubes;bgcolor=blue]'
        fs = fs .. 'style[help_plants;bgcolor=blue]'
        fs = fs .. 'style[help_wools;bgcolor=blue]'
        fs = fs .. 'style[help_cmds;bgcolor=blue]'
        fs = fs .. 'style[help_settings;bgcolor=blue]'

        -- tabs
        if #meta.tabs > 0 then
            fs = fs .. 'tabheader[0,0;tabs;'
            for i, filename in ipairs(meta.tabs) do
                if i ~= 1 then fs = fs .. ',' end
                fs = fs .. formspec_escape(filename)
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

        -- checkboxes
        -- fs = fs .. 'checkbox[0,10;soe;Save on exit;' ..
        --          (meta.soe and 'true' or 'false') .. ']'
        fs = fs .. 'checkbox[0,10;loe;' .. S('Load program on exit') .. ';' ..
                 (meta.loe and 'true' or 'false') .. ']'
        fs = fs .. 'checkbox[5,10;sos;' .. S('Save on tab switch') .. ';' ..
                 (meta.sos and 'true' or 'false') .. ']'

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
            if err then chat_send_player(name, err) end
        end

        local function remove_active()
            if meta.active == 0 then return end
            if #meta.tabs == 0 then return end
            local err = remove_file(name, meta.tabs[meta.active])
            if err then
                chat_send_player(name, err)
            else
                table.remove(meta.tabs, meta.active)
                table.remove(meta.contents, meta.active)
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
        if fields.content and meta.active ~= 0 then
            meta.contents[meta.active] = fields.content
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
        elseif fields.c_scroll then
            meta.scroll_c = core.explode_scrollbar_event(fields.c_scroll)
                                .value
        elseif fields.p_scroll then
            meta.scroll_p = core.explode_scrollbar_event(fields.p_scroll)
                                .value
        elseif fields.w_scroll then
            meta.scroll_w = core.explode_scrollbar_event(fields.w_scroll)
                                .value
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
        elseif fields.newfile then -- last because sent everytime
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

        local function cancel()
            close_form(name)
        end

        -- Nothing selected leaves selectedIndex at 0, which names no file.
        local function choose(i)
            local file = get_user_data(name).list[i]
            if file then set_file(name, file.name) end
            close_form(name)
        end

        if fields.choose then
            choose(meta.selectedIndex)
        elseif fields.cancel then
            cancel()
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

        end

    end

}

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

codeblock.formspecs.file_chooser = file_chooser
codeblock.formspecs.file_editor = file_editor
