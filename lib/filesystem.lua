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
local max_kb = codeblock.config.max_file_kb
local max_bytes = max_kb * 1024

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

local user_data = {}

local function get_file_path(name, filename)
    return path_join(data_path, name, filename)
end

local function remove_user_data(name) user_data[name] = nil end

--- The one refusal both the read and the write share, so the size a player is
-- told is the same size either way, from one translatable message.
local function too_large(filename)
    return S('File @1 is too large: over @2 kB', filename, max_kb)
end

--- A sort key that orders digit runs by value, so foo_2 precedes foo_10 rather
-- than following it. Each run is prefixed with its own length, which orders
-- shorter numbers first without having to guess a padding width. Case is left
-- alone, so the rest of the ordering is the byte order it has always been.
local function sort_key(filename)
    return (filename:gsub('%d+', function(digits)
        return ('%03d'):format(#digits) .. digits
    end))
end

--- The player's files. Built on first use, rebuilt when `forceRefresh` is set.
local function get_user_data(name, forceRefresh)

    if user_data[name] ~= nil and not forceRefresh then return user_data[name] end

    local files = get_dir_list(path_join(data_path, name), false) or {}
    table.sort(files, function(a, b) return sort_key(a) < sort_key(b) end)

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

    -- io.open's own message is "<absolute path>: <reason>", so it goes to the
    -- log and never to the player: it discloses the server's filesystem layout,
    -- and being the C runtime's errno string it is not a translation key either,
    -- so it could never come out in the player's language. The player gets the
    -- filename, like every other refusal here. (S7)
    local handle, err = io.open(file.path, 'rb')
    if not handle then
        core.log('warning', ('[codeblock] cannot read %s: %s'):format(filename,
                                                                     err or '?'))
        return nil, unreadable
    end

    -- One byte over the ceiling is all it takes to know the file is too large,
    -- and it is the only way to find out that does not pay for the whole file
    -- first. An unbounded read here was charged three times over - the string,
    -- the copy cached below, and the formspec the editor sends to the client -
    -- and a 168 MB file took the server to 14 GB. (B40)
    --
    -- read(n) answers nil at end of file, which for a handle that opened is an
    -- empty file: a program created and not yet written is exactly that.
    local content = handle:read(max_bytes + 1) or ''
    handle:close()

    if #content > max_bytes then return nil, too_large(filename) end

    -- Lua's signature byte for a precompiled chunk. Bytecode is not checked the
    -- way source is, so it is refused before anything can load it.
    if content:byte(1) == 27 then
        return nil, S("Compilation error in @1: ", filename) ..
                   S('Binary bytecode prohibited')
    end

    -- Line endings normalised to LF, after the size check so a CRLF file cannot
    -- shrink its way under the ceiling. The client's textarea returns LF
    -- whatever it was given, so a CRLF buffer never equals the field coming
    -- back and the editor marked every pristine example modified the moment it
    -- lost focus. The bundled examples are all CRLF, which is why only files
    -- the player had already saved escaped the mark. (B48)
    content = content:gsub('\r\n', '\n')

    file.content = content
    return content

end

local function write_file(name, filename, content)

    local content = content or ''
    local failed = S('Cannot write file') .. ' ' .. filename

    -- Refused at the same size the read refuses, or the editor would write a
    -- file it then declines to open. What arrives from a client is already
    -- bounded by the engine, but only from 5.7 on and only at 640 kB. (B40)
    if #content > max_bytes then return too_large(filename) end

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
