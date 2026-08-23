codeblock.utils = {}

local auth_levels = codeblock.config.auth_levels
local default_auth_level = codeblock.config.default_auth_level

--------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------

function codeblock.utils.check_auth_level(auth_level)
    if type(auth_level) == 'number' and auth_levels[auth_level] ~= nil then
        return true, auth_level
    else
        return false, default_auth_level
    end
end

function codeblock.utils.split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

--- Parse "[<playername>] <rest>" from a chat command's arguments.
--
-- The player name is optional and defaults to `caller`. There is deliberately
-- no singleplayer special case: the engine passes the caller's own name either
-- way, and the previous hard-coded 'singleplayer' was wrong for a renamed
-- player.
--
-- `rest_pattern` is a Lua pattern for the remaining argument, e.g. '%d+'.
-- Returns target_name, rest - or nil, nil when the arguments do not match.
function codeblock.utils.parse_target(caller, params, rest_pattern)
    -- "<name> <rest>"
    local pname, rest = string.match(params, '^%s*([%a][%w_%-]*)%s+(' ..
                                         rest_pattern .. ')%s*$')
    if pname then return pname, rest end
    -- "<rest>" alone, addressed to the caller
    rest = string.match(params, '^%s*(' .. rest_pattern .. ')%s*$')
    if rest then return caller, rest end
    return nil, nil
end

function codeblock.utils.table_reverse(tbl)
    local rev = {}
    for k, v in pairs(tbl) do rev[v] = k end
    return rev
end

function codeblock.utils.table_convert_ik(tbl)
    local itable = {}
    for k, _ in pairs(tbl) do table.insert(itable, k) end
    table.sort(itable)
    return itable
end

function codeblock.utils.table_convert_iv(tbl)
    local itable = {}
    for k, v in pairs(tbl) do table.insert(itable, v) end
    table.sort(itable)
    return itable
end

function codeblock.utils.table_randomizer(tbl)
    local keys = {}
    local random = math.random
    for k in pairs(tbl) do table.insert(keys, k) end
    return function() return tbl[keys[random(#keys)]] end
end

function codeblock.utils.scroll_max(tbl) return #tbl * 2.32 - 20.56 end

-- The editor's API panel. Generated from lib/api.lua, which is also what
-- builds the sandbox environment and doc/api.md - so the help a player reads
-- in game cannot describe a different API from the one they are calling.
-- This replaced 98 lines of hand-written hypertext that had to be updated by
-- hand and had stopped matching.
codeblock.utils.html_commands = codeblock.api.to_hypertext()
