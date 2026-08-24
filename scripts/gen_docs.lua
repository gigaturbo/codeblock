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

local allowed = codeblock.config.allowed_blocks

--- The names a block table holds, sorted.
-- Sorted rather than in declaration order so this needs no parsing of
-- config.lua's source and gives the same answer as the in-engine generator in
-- init.lua. iwools keeps its own order, which is meaningful - it is a rainbow.
local function sorted_keys(t)
    local names = {}
    for k in pairs(t or {}) do names[#names + 1] = k end
    table.sort(names)
    return names
end

local block_tables = {
    blocks = sorted_keys(allowed and allowed.cubes),
    plants = sorted_keys(allowed and allowed.plants),
    wools = sorted_keys(allowed and allowed.wools),
    iwools = allowed and allowed.iwools or nil
}

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

local wanted, why = api.compose_markdown(current, block_tables)
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
    for name in cfg:gmatch('codeblock%.config%.(max_%w+)%s*=%s*{') do
        if not current:find('\n| ' .. name .. ' ', 1, true) then
            missing[#missing + 1] = name
        end
    end
    for name in cfg:gmatch('codeblock%.config%.(%w+_before_yield)%s*=%s*{') do
        if not current:find('\n| ' .. name .. ' ', 1, true) then
            missing[#missing + 1] = name
        end
    end
    for name in cfg:gmatch('codeblock%.config%.(step_budget_us)%s*=%s*{') do
        if not current:find('\n| ' .. name .. ' ', 1, true) then
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
