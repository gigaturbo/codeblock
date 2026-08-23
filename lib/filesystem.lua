codeblock.filesystem = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local S = codeblock.S

local get_dir_list = minetest.get_dir_list
local safe_file_write = minetest.safe_file_write
local mkdir = minetest.mkdir
local path_join = codeblock.utils.path_join
local data_path = path_join(minetest.get_worldpath(), codeblock.config.lua_dir)

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

local user_data = {}

local function get_file_path(name, filename)
    return path_join(data_path, name, filename)
end

local function get_user_files(name)
    local path = path_join(data_path, name)
    local files = get_dir_list(path, false)
    table.sort(files)
    return files
end

local function remove_user_data(name) user_data[name] = nil end

local function get_user_data(name, forceRefresh)
    local ud
    if user_data[name] == nil or forceRefresh then
        local itf = get_user_files(name) or {}
        local fti = {}
        local ftp = {}
        local ftc = {}
        for i, f in ipairs(itf) do
            ftp[f] = get_file_path(name, f)
            fti[f] = i
            ftc[f] = nil
        end
        ud = {itf = itf, ftp = ftp, fti = fti, ftc = ftc}
        user_data[name] = ud
    else
        ud = user_data[name]
    end
    return ud
end

local function get_ftp(name, f, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    return ud.ftp[f]
end

local function get_itp(name, i, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    return ud.ftp[ud.itf[i]]
end

local function get_fti(name, f, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    return ud.fti[f]
end

local function get_itf(name, i, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    return ud.itf[i]
end

local function get_ftc(name, f, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    return ud.ftc[f]
end

local function get_itc(name, i, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    return ud.ftc[ud.itf[i]]
end

local function read_file(name, filename, forceRefresh)
    local ud = get_user_data(name, forceRefresh)
    if forceRefresh then
        -- we don't care if ftc is nil or not, we force read the file if it
        -- *exists* in the user_data ftp
        -- as we forceRefresh ftp/fti/idf should be up to date
        -- but... we never know. Maybe we can read the file content
        -- but the directory structure failed
        if ud.ftp[filename] then
            local path = get_file_path(name, filename)
            local file, err = io.open(path, 'rb')
            if err then return nil, err end
            local content = file:read('*a')
            file:close()
            if content then
                if content:byte(1) == 27 then
                    return nil, S("Compilation error in @1: ", file) ..
                               S('Binary bytecode prohibited')
                end
                user_data[name].ftc[filename] = content
                return content
            else
                user_data[name].ftc[filename] = nil
            end
        end
        return nil, S('Cannot read file') .. ' ' .. filename
    else
        -- we care if ftc is nil or not, if it is nil it means
        -- the file exists in user_data but the content has not
        -- been loaded yet. If content exists then ftp must exist
        local content = ud.ftc[filename]
        if content then
            return content
        else
            -- here, content is nil but it should be because
            -- the file has not been read yet, hence ftp/fti/idf
            -- must exists
            if ud.ftp[filename] then
                local path = get_file_path(name, filename)
                local file, err = io.open(path, 'rb')
                if err then return nil, err end
                local content = file:read('*a')
                file:close()
                if content then
                    if content:byte(1) == 27 then
                        return nil, S("Compilation error in @1: ", file) ..
                                   S('Binary bytecode prohibited')
                    end
                    user_data[name].ftc[filename] = content
                    return content
                else
                    user_data[name].ftc[filename] = nil
                end
            end
            return nil, S('Cannot read file') .. ' ' .. filename
        end
    end
end

local function write_file(name, filename, content)
    local content = content or ''
    local path = get_file_path(name, filename)
    local success = safe_file_write(path, content)
    if success then
        if user_data[name].ftp[filename] then
            user_data[name].ftc[filename] = content
            return nil
        else
            get_user_data(name, true) -- the new file should exist now
            if user_data[name].ftp[filename] then
                user_data[name].ftc[filename] = content
                return nil
            end
        end
    end
    return S('Cannot write file') .. ' ' .. filename
end

local function exists(name, filename, forceRefresh)
    local exists = get_user_data(name, forceRefresh).ftp[filename] ~= nil
    if exists then
        return nil
    else
        return S('File @1 does not exists', filename)
    end
end

local function remove_file(name, filename)
    if user_data[name].ftp[filename] then
        local _, err = os.remove(get_file_path(name, filename))
        if err then
            return S('Failed to remove @1', filename)
        else
            get_user_data(name, true)
            return nil
        end
    end
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
codeblock.filesystem.get_ftp = get_ftp
codeblock.filesystem.get_itp = get_itp
codeblock.filesystem.get_fti = get_fti
codeblock.filesystem.get_itf = get_itf
codeblock.filesystem.get_ftc = get_ftc
codeblock.filesystem.get_itc = get_itc
codeblock.filesystem.make_user_dir = make_user_dir
codeblock.filesystem.data_path = data_path
