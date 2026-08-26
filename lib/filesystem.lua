--- A player's Lua files: where they are, what order they are in, and what is in
-- them.
--
-- Everything known about a file lives in one record - its name, its path, its
-- position in the sorted listing, and its content once it has been read - held
-- in a list and a name index onto the same tables. There is nothing to keep in
-- step, which is what four parallel tables keyed by two naming schemes used to
-- cost. (A9)
--
--   ud.list     {name = , path = , index = , content = }, sorted by name
--   ud.byname   [name] -> the same record
--
-- The cache is per player and dropped on disconnect. A refresh rebuilds the
-- records, so content read before it is read again.

codeblock.filesystem = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local S = codeblock.S

local get_dir_list = core.get_dir_list
local safe_file_write = core.safe_file_write
local mkdir = core.mkdir
local path_join = codeblock.utils.path_join
local data_path = path_join(core.get_worldpath(), codeblock.config.lua_dir)

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

local user_data = {}

local function get_file_path(name, filename)
    return path_join(data_path, name, filename)
end

local function remove_user_data(name) user_data[name] = nil end

--- The player's files. Built on first use, rebuilt when `forceRefresh` is set.
local function get_user_data(name, forceRefresh)

    if user_data[name] ~= nil and not forceRefresh then return user_data[name] end

    local files = get_dir_list(path_join(data_path, name), false) or {}
    table.sort(files)

    local ud = {list = {}, byname = {}}
    for i, filename in ipairs(files) do
        local file = {
            name = filename,
            path = get_file_path(name, filename),
            index = i
        }
        ud.list[i] = file
        ud.byname[filename] = file
    end

    user_data[name] = ud
    return ud

end

--- A file's content, or nil and a message.
--
-- Cached on the record, so re-reading the same file costs nothing;
-- `forceRefresh` rebuilds the listing first, which drops every cached content
-- with it and so always reaches the disk.
local function read_file(name, filename, forceRefresh)

    local unreadable = S('Cannot read file') .. ' ' .. filename

    local file = get_user_data(name, forceRefresh).byname[filename]
    if not file then return nil, unreadable end
    if file.content then return file.content end

    local handle, err = io.open(file.path, 'rb')
    if not handle then return nil, err or unreadable end

    local content = handle:read('*a')
    handle:close()

    if not content then return nil, unreadable end

    -- Lua's signature byte for a precompiled chunk. Bytecode is not checked the
    -- way source is, so it is refused before anything can load it.
    if content:byte(1) == 27 then
        return nil, S("Compilation error in @1: ", filename) ..
                   S('Binary bytecode prohibited')
    end

    file.content = content
    return content

end

local function write_file(name, filename, content)

    local content = content or ''
    local failed = S('Cannot write file') .. ' ' .. filename

    if not safe_file_write(get_file_path(name, filename), content) then
        return failed
    end

    -- A name the player did not have changes the listing, so it is rebuilt
    -- rather than patched. Both lookups go through get_user_data, which creates
    -- the entry when there is none - reaching into the cache directly was an
    -- index of nil for anyone who had disconnected since. (B14)
    local file = get_user_data(name).byname[filename] or
                     get_user_data(name, true).byname[filename]

    if not file then return failed end

    file.content = content
    return nil

end

--- nil when the file is there, a message when it is not. Note the polarity.
local function exists(name, filename, forceRefresh)
    if get_user_data(name, forceRefresh).byname[filename] then return nil end
    return S('File @1 does not exists', filename)
end

local function remove_file(name, filename)

    if not get_user_data(name).byname[filename] then return end

    local _, err = os.remove(get_file_path(name, filename))
    if err then return S('Failed to remove @1', filename) end

    get_user_data(name, true)
    return nil

end

local function make_user_dir(name)
    local path = path_join(data_path, name)
    local success = mkdir(path)
    if not success then return S('Cannot create directory @1', path) end
end

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

codeblock.filesystem.get_user_data = get_user_data
codeblock.filesystem.remove_user_data = remove_user_data
codeblock.filesystem.read_file = read_file
codeblock.filesystem.write_file = write_file
codeblock.filesystem.remove_file = remove_file
codeblock.filesystem.exists = exists
codeblock.filesystem.make_user_dir = make_user_dir
codeblock.filesystem.data_path = data_path
