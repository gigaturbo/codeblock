#!/usr/bin/env lua
--- Regenerate settingtypes.txt from lib/config.lua.
--
--     lua scripts/gen_settingtypes.lua          write settingtypes.txt
--     lua scripts/gen_settingtypes.lua --check  exit 1 if it is out of date
--
-- The third file here that restates the source for a reader rather than for the
-- code, and the last of the three to get a check. settingtypes.txt only *draws*
-- the settings menu - the engine reads no default out of it - so every value in
-- it was a copy of a literal in lib/config.lua kept in step by hand, and nothing
-- failed when the two disagreed. (C7, C17)
--
-- Where each part comes from, because only one of them is derived:
--
--   * the DEFAULTS from lib/config.lua, dofile'd under a bare interpreter where
--     there is no `core` global, so what is emitted is the built-in default and
--     never an administrator's own override;
--   * the ORDER, the sections, the labels, the menu bounds and the prose from
--     SETTINGS below, which is written for an administrator reading the menu.
--     config.lua's comments are for whoever edits the code and say other things.
--
-- So this guarantees the numbers agree and nothing at all about the words: a
-- generator guarantees the output matches its input, and no more (C19). What it
-- does beyond that is fail on a setting config.lua reads and SETTINGS does not
-- draw, and on one drawn that nothing reads - which is the half no hand-kept
-- file could do. Adding a limit now breaks this check instead of going undrawn.

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
if not exists(root .. '/lib/config.lua') then
    root = '..'
    if not exists(root .. '/lib/config.lua') then
        io.stderr:write('cannot find lib/config.lua; run from the mod root\n')
        os.exit(2)
    end
end

-- config.lua assigns into a `codeblock` global and references nothing else, so a
-- stub is enough to read the defaults out of it without the mod loaded.
codeblock = codeblock or {}
dofile(root .. '/lib/config.lua')
local cfg = codeblock.config

--------------------------------------------------------------------------------
-- what the menu shows, in the order it shows it
--
-- `kind` says how the default is written into the file:
--
--   per_level  four comma-separated numbers from the config table
--   int        the config value, then the menu's own min and max
--   bool       the config value
--   string     no default at all - see default_auth_level, the one setting whose
--              built-in default is two values and cannot be written as one
--
-- `text` is one entry per paragraph. Each is reflowed to WIDTH; the break
-- between them is kept, because that is where the prose puts one.
--------------------------------------------------------------------------------

local SETTINGS = {

    {'Codelevel', {
        {
            name = 'default_auth_level',
            label = 'Default codelevel',
            kind = 'string',
            text = {
                'Codelevel a player is given on first join. 1 to 4.',
                'Leave empty for the built-in default, which is 3 in ' ..
                'singleplayer - where the player is the administrator, but has ' ..
                'no use for the widest ceilings there are - and 2 on a server, ' ..
                'where an unvetted joiner would otherwise arrive holding a ' ..
                'large share of every limit below.'
            }
        }
    }},

    {'Files', {
        {
            name = 'max_file_kb',
            label = 'Maximum program file size',
            kind = 'int',
            min = 1,
            max = 640,
            text = {
                'Largest program file, in kilobytes, that will be read from or ' ..
                'written to a player\'s directory. Not a limit on a running ' ..
                'program: it bounds the read itself, which is paid for three ' ..
                'times over - the file, the copy kept in memory, and the ' ..
                'formspec the editor sends to the client. A program a person ' ..
                'edits is kilobytes. Nothing saved from the editor can exceed ' ..
                '640 kB in any case, that being the engine\'s own ceiling on a ' ..
                'formspec submission.'
            }
        }
    }},

    {'Pacing', {
        {
            name = 'pace_ms',
            label = 'Pace between commands',
            kind = 'per_level',
            text = {
                'Milliseconds the drone waits after each command. Zero is no ' ..
                'wait. This is what makes the novice codelevels slow enough to ' ..
                'watch; it costs the server nothing, as a waiting drone is not ' ..
                'running.'
            }
        },
        {
            name = 'step_budget_us',
            label = 'Step budget per drone',
            kind = 'per_level',
            text = {
                'Microseconds one drone may spend advancing its program per ' ..
                'server step. A cap, not an allowance: a drone gets the smaller ' ..
                'of this and its share of the server budget below.'
            }
        },
        {
            name = 'server_step_budget_us',
            label = 'Step budget for all drones',
            kind = 'int',
            min = 1000,
            max = 90000,
            text = {
                'Microseconds per server step for all running drones together, ' ..
                'divided equally among them. Without it, each new drone costs ' ..
                'the server another full budget. A dedicated server steps ' ..
                'roughly every 90000 microseconds.'
            }
        }
    }},

    {'Work limits', {
        {
            name = 'max_runtime_s',
            label = 'Maximum running time',
            kind = 'per_level',
            text = {
                'Seconds of running time one program gets. Counted as time the ' ..
                'drone was actually advanced, not wall clock, so pacing and a ' ..
                'busy server do not eat into it. This is what stops a program ' ..
                'that never finishes.'
            }
        },
        {
            name = 'max_nodes_written',
            label = 'Maximum nodes written',
            kind = 'per_level',
            text = {
                'Nodes one program may write. Also the ceiling on a single ' ..
                'shape, since neither a shape\'s dimensions nor the drone\'s ' ..
                'distance are limited.'
            }
        }
    }},

    {'Memory limits', {
        {
            name = 'map_memory_mb',
            label = 'Maximum map footprint',
            kind = 'per_level',
            text = {
                'Megabytes of map one program may hold. Touching a node pins ' ..
                'its 16 KiB mapblock in the server\'s memory, and this is the ' ..
                'only limit that can see that: the heap limit below measures ' ..
                'Lua memory, and a mapblock is not on the Lua heap. The engine ' ..
                'unloads an idle mapblock by itself, so a program over this ' ..
                'ceiling is slowed down rather than stopped.'
            }
        },
        {
            name = 'heap_mb',
            label = 'Maximum heap growth',
            kind = 'per_level',
            text = {
                'Lua heap growth, in megabytes, one program run may cause. ' ..
                'Checked when the drone yields, so it catches a program that ' ..
                'accumulates rather than one that allocates everything in a ' ..
                'single call.'
            }
        },
        {
            name = 'max_string_mb',
            label = 'Maximum string size',
            kind = 'per_level',
            text = {
                'Largest string, in megabytes, a single call may produce. ' ..
                'Covers the single allocation the heap limit cannot see.'
            }
        }
    }},

    {'Appearance', {
        {
            name = 'flat_sky',
            label = 'Flat sky',
            kind = 'bool',
            text = {
                'Hold daylight at noon and hide the sun, moon, stars and ' ..
                'clouds, for every player who joins. Nothing this mod does ' ..
                'needs it - a drone builds the same at midnight - so it is off, ' ..
                'and a game that wants a flat, sunless sky asks for it here. ' ..
                'Per-player and re-applied on join, so turning it off takes ' ..
                'effect on the next one.'
            }
        },
        {
            name = 'drone_hud',
            label = 'Drone HUD',
            kind = 'bool',
            text = {
                'Whether a player who has set no preference of their own sees ' ..
                'the drone HUD while their program runs: the file, whether it ' ..
                'is running or paused, and what the run has spent of each of ' ..
                'the three limits that can stop it. On, because it is the only ' ..
                'place a running program\'s budget can be seen, and it leaves ' ..
                'the screen the moment the program ends. A player\'s own ' ..
                'choice, made in the editor, overrides this.'
            }
        }
    }}
}

local HEADER = {
    'Settings for the codeblock mod, shown under Mods in the advanced settings.',
    'GENERATED by scripts/gen_settingtypes.lua. Do not edit this file: edit a ' ..
    'default in lib/config.lua or the wording in that script, and run it again.',
    'Everything here bounds what one player program may do, except the two ' ..
    'under Appearance. They are read once, when the mod loads, so a change ' ..
    'needs a server restart.',
    'The per-codelevel limits take four numbers separated by commas, one for ' ..
    'each codelevel from 1 (novice) to 4 (poweruser). A value that is empty, ' ..
    'or that is not four numbers, is ignored with a warning in the log and the ' ..
    'built-in default is used instead. doc/api.md describes what each one does.',
    'The engine does not read this file for defaults - it only parses it to ' ..
    'draw the settings menu, and a mod setting the menu has never written ' ..
    'reads back as unset. So the values below are copies of the real defaults ' ..
    'in lib/config.lua, which is why they are generated rather than kept in ' ..
    'step by hand.'
}

--------------------------------------------------------------------------------
-- every setting config.lua reads has to be drawn, and nothing else
--
-- Two shapes to look for, and neither is a list of names that could go stale:
--
--   * a scalar, read through number('name', ...) or flag('name', ...);
--   * a per-codelevel limit, which is a table of four numbers assigned to
--     codeblock.config and overridden in one loop afterwards, so there is no
--     literal name to match. It is matched by shape, the same way gen_docs.lua
--     matches the same tables for the codelevel documentation - which is why
--     those tables must stay plain literals. auth_levels is the list of levels
--     itself, not a limit.
--
-- A retired name from the `replaced` table is matched by neither, and must not
-- be: it warns and does nothing, so drawing it would offer a dead setting.
--------------------------------------------------------------------------------

do
    local source = assert(io.open(root .. '/lib/config.lua')):read('*a')
    local reads = {}
    for name in source:gmatch("number%('([%w_]+)'") do reads[name] = true end
    for name in source:gmatch("flag%('([%w_]+)'") do reads[name] = true end
    -- `[%w_]` and not `%w`: Lua's %w is alphanumeric and excludes the
    -- underscore, and every limit here has one in its name, so `%w+` matches
    -- none of them at all. That is C20 - the same pattern in gen_docs.lua had
    -- been matching nothing since it was written.
    for name in source:gmatch('codeblock%.config%.([%w_]+)%s*=%s*{%s*%d') do
        if name ~= 'auth_levels' then reads[name] = true end
    end

    local drawn = {}
    for _, section in ipairs(SETTINGS) do
        for _, setting in ipairs(section[2]) do
            drawn[setting.name] = true
        end
    end

    local problems = {}
    for name in pairs(reads) do
        if not drawn[name] then
            problems[#problems + 1] = ('lib/config.lua reads codeblock_%s and ' ..
                                          'SETTINGS does not draw it'):format(
                                          name)
        end
    end
    for name in pairs(drawn) do
        if not reads[name] then
            problems[#problems + 1] = ('SETTINGS draws codeblock_%s and ' ..
                                          'lib/config.lua does not read it')
                                          :format(name)
        elseif cfg[name] == nil then
            problems[#problems + 1] = ('SETTINGS draws codeblock_%s and ' ..
                                          'codeblock.config has no value for it')
                                          :format(name)
        end
    end

    if #problems > 0 then
        table.sort(problems)
        for _, p in ipairs(problems) do
            io.stderr:write('settingtypes.txt: ' .. p .. '\n')
        end
        io.stderr:write('Add it to SETTINGS in scripts/gen_settingtypes.lua.\n')
        os.exit(1)
    end
end

--------------------------------------------------------------------------------
-- compose
--------------------------------------------------------------------------------

local WIDTH = 80
local PREFIX = '#    '

--- One `#`-prefixed comment block, reflowed to WIDTH columns including the
-- prefix. One paragraph per entry, and the break between them is kept.
local function comment(paragraphs)
    local out = {}
    for _, para in ipairs(paragraphs) do
        local line
        for word in para:gmatch('%S+') do
            if not line then
                line = word
            elseif #PREFIX + #line + 1 + #word <= WIDTH then
                line = line .. ' ' .. word
            else
                out[#out + 1] = PREFIX .. line
                line = word
            end
        end
        if line then out[#out + 1] = PREFIX .. line end
    end
    return out
end

--- A config number as the settings menu should show it: full digits for a whole
-- number, since 1e5 is programmer notation and this file is read by an
-- administrator.
local function num(n)
    if n == math.floor(n) then return ('%d'):format(n) end
    return tostring(n)
end

--- The type and default half of a setting's line.
local function typed(setting)
    local v = cfg[setting.name]
    if setting.kind == 'per_level' then
        local parts = {}
        for i = 1, 4 do parts[i] = num(v[i]) end
        return 'string ' .. table.concat(parts, ',')
    elseif setting.kind == 'int' then
        return ('int %s %s %s'):format(num(v), num(setting.min),
                                       num(setting.max))
    elseif setting.kind == 'bool' then
        return 'bool ' .. tostring(v)
    end
    return 'string'
end

local lines = {}

for i, para in ipairs(HEADER) do
    if i > 1 then lines[#lines + 1] = '#' end
    for _, line in ipairs(comment({para})) do lines[#lines + 1] = line end
end

for _, section in ipairs(SETTINGS) do
    lines[#lines + 1] = ''
    lines[#lines + 1] = '[' .. section[1] .. ']'
    for _, setting in ipairs(section[2]) do
        lines[#lines + 1] = ''
        for _, line in ipairs(comment(setting.text)) do
            lines[#lines + 1] = line
        end
        lines[#lines + 1] = ('codeblock_%s (%s) %s'):format(setting.name,
                                                            setting.label,
                                                            typed(setting))
    end
end

local wanted = table.concat(lines, '\n') .. '\n'

--------------------------------------------------------------------------------
-- write or check
--------------------------------------------------------------------------------

local path = root .. '/settingtypes.txt'
local current = ''
do
    local f = io.open(path, 'r')
    if f then
        current = f:read('*a')
        f:close()
    end
end

local check_only = false
for _, a in ipairs(arg or {}) do
    if a == '--check' then check_only = true end
end

-- Compare with line endings normalised: a Windows checkout has CRLF in the file
-- and this script emits LF, which is not a difference worth failing over.
local function normalise(s) return (s:gsub('\r\n', '\n')) end

if normalise(current) == normalise(wanted) then
    print('settingtypes.txt is up to date')
    os.exit(0)
end

if check_only then
    io.stderr:write(
        'settingtypes.txt is out of date; run: lua scripts/gen_settingtypes.lua\n')
    os.exit(1)
end

local out = assert(io.open(path, 'wb'))
out:write(wanted)
out:close()
print('wrote settingtypes.txt')
