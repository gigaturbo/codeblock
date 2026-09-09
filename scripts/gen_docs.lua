#!/usr/bin/env lua
--- Regenerate the reference sections of doc/api.md from the code.
--
--     lua scripts/gen_docs.lua          write doc/api.md
--     lua scripts/gen_docs.lua --check  exit 1 if it is out of date
--
-- Audit finding A2: the player-facing API was described in three places with
-- nothing connecting them, and they had drifted. lib/api.lua is now the source
-- for all three - it builds the sandbox environment, renders the in-game help,
-- and produces the sections this script writes.
--
-- What is generated and what is not: everything from the "# Lua api" heading
-- onward. The Codelevel table and the Chat commands section above it are
-- hand-written prose about behaviour rather than a list of names, so they are
-- preserved untouched. Edit those in place; edit lib/api.lua for anything below.
--
-- Runs under a bare interpreter, which is why lib/api.lua holds no closures and
-- lib/config.lua needs nothing but a stub global.

--------------------------------------------------------------------------------
-- locate the mod root, so this works from either the root or scripts/
--------------------------------------------------------------------------------

local function exists(path)
    local f = io.open(path, 'r')
    if f then
        f:close()
        return true
    end
    return false
end

local root = '.'
if not exists(root .. '/lib/api.lua') then
    root = '..'
    if not exists(root .. '/lib/api.lua') then
        io.stderr:write('cannot find lib/api.lua; run from the mod root\n')
        os.exit(2)
    end
end

--------------------------------------------------------------------------------
-- load the description and the block tables
--------------------------------------------------------------------------------

-- config.lua assigns into a `codeblock` global and references nothing else, so a
-- stub is enough to read the block tables out of it without the mod loaded.
codeblock = codeblock or {}
dofile(root .. '/lib/config.lua')
local api = dofile(root .. '/lib/api.lua')

-- Handed to the renderer whole rather than picked apart here: config.lua holds
-- the categories in palette order, api.to_markdown lists them in it, and this
-- and the in-engine generator in init.lua therefore cannot disagree.
local allowed = codeblock.config.allowed_blocks

--------------------------------------------------------------------------------
-- compose
--------------------------------------------------------------------------------

local doc_path = root .. '/doc/api.md'
local current = ''
do
    local f = io.open(doc_path, 'r')
    if f then
        current = f:read('*a')
        f:close()
    end
end

local wanted, why = api.compose_markdown(current, allowed)
if not wanted then
    io.stderr:write('doc/api.md: ' .. tostring(why) .. '\n')
    os.exit(2)
end

--------------------------------------------------------------------------------
-- the hand-written part still has to cover every per-codelevel limit
--
-- This generator only owns the section from "# Lua api" onward. The codelevel
-- table above it is hand-written prose, so nothing here regenerates it - and
-- when scripts/check_docs.sh was replaced by this script, the check that every
-- limit in config.lua has a row in that table went with it. step_budget_us was
-- added and undocumented before anyone noticed. Checked here instead, since this
-- is the tool that survived.
--------------------------------------------------------------------------------

do
    local cfg = io.open(root .. '/lib/config.lua'):read('*a')
    local missing = {}
    -- Matched by shape rather than by name: every per-codelevel limit is a
    -- table whose first element is a number. Three name prefixes were listed
    -- here instead, and a limit called pace_ms or heap_mb matched none of them,
    -- which turned the check off for exactly the limits being added.
    -- auth_levels is the list of levels itself, not a limit.
    --
    -- `[%w_]` and not `%w`, because Lua's %w is alphanumeric and excludes the
    -- underscore: every limit name has one, so the shape match found none of
    -- them either and this check was dead from the day it replaced the
    -- prefixes. (C20)
    for name in cfg:gmatch('codeblock%.config%.([%w_]+)%s*=%s*{%s*%d') do
        if name ~= 'auth_levels' and
            not current:find('\n| ' .. name .. ' ', 1, true) then
            missing[#missing + 1] = name
        end
    end
    if #missing > 0 then
        table.sort(missing)
        io.stderr:write(('doc/api.md: the codelevel table has no row for: %s\n')
                            :format(table.concat(missing, ', ')))
        io.stderr:write('That table is hand-written; add the rows yourself.\n')
        os.exit(1)
    end
end

--------------------------------------------------------------------------------
-- .luacheckrc's sandbox std has to name exactly the API, and nothing else
--
-- luacheck lints lib/examples/** against stds.codeblock_sandbox, so that list is
-- a fourth hand-kept mirror of lib/api.lua alongside doc/api.md,
-- locale/template.txt and settingtypes.txt - and like all three it drifts in
-- silence, an omitted name showing up only as a false "undefined variable" in
-- whichever example happens to use it. `sleep` and `default_block` were missing
-- for a year that way (C22). Checked here because this is the gate that already
-- loads lib/api.lua under a bare interpreter.
--
-- The config is Lua, so it is loaded with its own environment and read, rather
-- than pattern-matched: a nested entry such as ramp = {fields = {...}} then
-- costs nothing. A bare string entry lets luacheck accept every field of that
-- name, so `vector` covers vector.fromPolar; that leniency is luacheck's own
-- and is mirrored here rather than worked around.
--------------------------------------------------------------------------------

do
    local chunk, err = loadfile(root .. '/.luacheckrc')
    if not chunk then
        io.stderr:write('.luacheckrc: ' .. tostring(err) .. '\n')
        os.exit(2)
    end
    -- os.getenv is the only thing the config reads; everything it assigns lands
    -- in this table instead of in _G. `stds` and `files` are indexed rather
    -- than assigned, because luacheck itself supplies them empty.
    local cfg = {os = os, stds = {}, files = {}}
    setfenv(chunk, cfg)
    chunk()

    local std = cfg.stds and cfg.stds.codeblock_sandbox
    if not (std and std.read_globals) then
        io.stderr:write(
            '.luacheckrc: stds.codeblock_sandbox.read_globals is missing\n')
        os.exit(2)
    end

    -- name -> true when the entry restricts its fields, false when it is a bare
    -- string and so accepts any.
    local listed = {}
    local function flatten(fields, prefix)
        for k, v in pairs(fields) do
            local name, sub
            if type(k) == 'number' then
                name = prefix .. v
            else
                name = prefix .. k
                if type(v) == 'table' then sub = v.fields end
            end
            listed[name] = sub ~= nil
            if sub then flatten(sub, name .. '.') end
        end
    end
    flatten(std.read_globals, '')

    local described, prefixes = {}, {}
    for _, n in ipairs(api.names()) do
        described[n] = true
        local at = n:find('.', 1, true)
        while at do
            prefixes[n:sub(1, at - 1)] = true
            at = n:find('.', at + 1, true)
        end
    end

    -- Neither side may be empty, or the comparison below would pass by matching
    -- nothing at all. (C20)
    if not next(listed) or not next(described) then
        io.stderr:write('.luacheckrc: nothing to compare - the sandbox std or ' ..
                            'the API description read empty\n')
        os.exit(2)
    end

    local unlisted, undescribed = {}, {}
    for _, n in ipairs(api.names()) do
        local ok = listed[n] ~= nil
        local at = n:find('.', 1, true)
        while not ok and at do
            -- a bare parent accepts every field, so it covers this name
            ok = listed[n:sub(1, at - 1)] == false
            at = n:find('.', at + 1, true)
        end
        if not ok then unlisted[#unlisted + 1] = n end
    end
    for name in pairs(listed) do
        if not (described[name] or prefixes[name]) then
            undescribed[#undescribed + 1] = name
        end
    end

    if #unlisted > 0 or #undescribed > 0 then
        table.sort(unlisted)
        table.sort(undescribed)
        if #unlisted > 0 then
            io.stderr:write(('.luacheckrc: stds.codeblock_sandbox does not ' ..
                                'list: %s\n'):format(table.concat(unlisted, ', ')))
        end
        if #undescribed > 0 then
            io.stderr:write(
                ('.luacheckrc: stds.codeblock_sandbox lists what lib/api.lua ' ..
                    'does not describe: %s\n'):format(
                    table.concat(undescribed, ', ')))
        end
        io.stderr:write('That list lints lib/examples/**; edit it by hand.\n')
        os.exit(1)
    end
end

--------------------------------------------------------------------------------
-- write or check
--------------------------------------------------------------------------------

local check_only = false
for _, a in ipairs(arg or {}) do
    if a == '--check' then check_only = true end
end

-- Compare with line endings normalised: a Windows checkout has CRLF in the file
-- and this script emits LF, which is not a difference worth failing over.
local function normalise(s) return (s:gsub('\r\n', '\n')) end

if normalise(current) == normalise(wanted) then
    print('doc/api.md is up to date')
    os.exit(0)
end

if check_only then
    io.stderr:write('doc/api.md is out of date; run: lua scripts/gen_docs.lua\n')
    os.exit(1)
end

local out = assert(io.open(doc_path, 'wb'))
out:write(wanted)
out:close()
print('wrote doc/api.md')
