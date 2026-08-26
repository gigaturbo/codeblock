codeblock.formspecs = {}

--------------------------------------------------------------------------------
-- local
--------------------------------------------------------------------------------

local S = codeblock.S

local tcik = codeblock.utils.table_convert_ik
local scroll_max = codeblock.utils.scroll_max
local split = codeblock.utils.split

local formspec_escape = minetest.formspec_escape
local chat_send_player = minetest.chat_send_player
local close_form = codeblock.forms.close
local update_form = codeblock.forms.update
local show_form = codeblock.forms.show
local explode_textlist_event = minetest.explode_textlist_event
local get_player_by_name = minetest.get_player_by_name

local blocks = codeblock.config.allowed_blocks.all
local cubes = codeblock.config.allowed_blocks.cubes
local plants = codeblock.config.allowed_blocks.plants
local wools = codeblock.config.allowed_blocks.wools
local cubes_ik = tcik(cubes)
local plants_ik = tcik(plants)
local wools_ik = tcik(wools)

local get_user_data = codeblock.filesystem.get_user_data
local read_file = codeblock.filesystem.read_file
local write_file = codeblock.filesystem.write_file
local remove_file = codeblock.filesystem.remove_file
local get_itf = codeblock.filesystem.get_itf
local get_fti = codeblock.filesystem.get_fti

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
            local saved_active =
                meta:get_string('codeblock:editor_state_active')
            local saved_tabs = meta:get_string('codeblock:editor_state_tabs')
            for _, filename in ipairs(split(saved_tabs, ',')) do
                if ud.ftp[filename] then
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

        -- tabs
        if #meta.tabs > 0 then
            fs = fs .. 'tabheader[0,0;tabs;'
            for i, filename in ipairs(meta.tabs) do
                if i ~= 1 then fs = fs .. ',' end
                fs = fs .. formspec_escape(filename)
            end
            fs = fs .. ';' .. (meta.active or 0) .. ';false;false]'
        end

        -- files
        fs = fs .. 'textlist[0, 0; 3, 8.75;files;'
        for i, filename in ipairs(ud.itf) do
            if i ~= 1 then fs = fs .. ',' end
            fs = fs .. formspec_escape(filename)
        end
        fs = fs .. ';' .. (ud.fti[meta.tabs[meta.active]] or 0) .. ']'

        -- new file
        fs = fs .. 'field_close_on_enter[newfile;false]'
        fs = fs .. 'field[0.27, 9.5;2.5, 1;newfile;' .. S('New file:') .. ';' ..
                 formspec_escape(meta.newfile) .. ']'
        fs = fs .. 'button[2.25, 9.20;1, 1;create;+]'

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
        fs = fs .. 'button[14,0;1.5, 0.75;help_cubes;' .. S('Blocks') .. ']'
        fs = fs .. 'button[15.5,0;1.5, 0.75;help_plants;' .. S('Plants') .. ']'
        fs = fs .. 'button[17,0;1.5, 0.75;help_wools;' .. S('Wools') .. ']'
        fs = fs .. 'button[18.5,0;1.5, 0.75;help_cmds;' .. S('API') .. ']'

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

        local function update_active_content(content)
            meta.contents[meta.active] = content
        end

        local function select_tab(i) meta.active = i end

        local function open(i)
            local filename = get_itf(name, i)
            local content, err = read_file(name, filename)
            if not err then
                table.insert(meta.tabs, filename)
                table.insert(meta.contents, content)
                meta.active = #meta.tabs
            else
                chat_send_player(name, err)
            end
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
                if not get_user_data(name).ftp[filename] then
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
                pmeta:set_string('codeblock:editor_state_active',
                                 meta.tabs[meta.active])
                -- booleans in memory, ints on disk
                pmeta:set_int('codeblock:save_on_exit', meta.soe and 1 or 0)
                pmeta:set_int('codeblock:load_on_exit', meta.loe and 1 or 0)
                pmeta:set_int('codeblock:save_on_switch', meta.sos and 1 or 0)
            end
        end

        -- FIELDS INPUTS
        if fields.close then
            close_active()
            update()
        elseif fields.tabs then
            if meta.sos then
                update_active_content(fields.content) -- old active
                save_active()
            end
            select_tab(tonumber(fields.tabs))
            update()
        elseif fields.load then
            update_active_content(fields.content)
            save_active()
            load_active()
            exit()
        elseif fields.save then
            update_active_content(fields.content)
            save_active()
            update()
        elseif fields.create then
            local filename = create_file(fields.newfile)
            if filename then
                open(get_fti(name, filename))
                update()
            end
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
            local t = e.type
            local i = e.index
            local sfilename = get_itf(name, i)
            if t == 'DCL' then
                for i, filename in ipairs(meta.tabs) do
                    if filename == sfilename then
                        update_active_content(fields.content)
                        select_tab(i)
                        update()
                        return
                    end
                end
                open(i)
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
        elseif fields.c_scroll then
            meta.scroll_c = minetest.explode_scrollbar_event(fields.c_scroll)
                                .value
        elseif fields.p_scroll then
            meta.scroll_p = minetest.explode_scrollbar_event(fields.p_scroll)
                                .value
        elseif fields.w_scroll then
            meta.scroll_w = minetest.explode_scrollbar_event(fields.w_scroll)
                                .value
        elseif fields.quit == 'true' then -- fields.content cannot be accessed here
            if meta.loe then load_active() end
            save_editor_state()
        elseif fields.newfile then -- last because sent everytime
            local filename = create_file(fields.newfile)
            if filename then
                open(get_fti(name, filename))
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
        for i, filename in ipairs(get_user_data(meta.name).itf) do
            table.insert(files_txt, formspec_escape(filename))
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

        local function choose(i)
            set_file(name, get_itf(name, i))
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

