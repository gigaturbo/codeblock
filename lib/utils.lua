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

codeblock.utils.html_commands = [[
    <b><style font=normal size=16>Moving the drone</style></b>
    <b><style color=#888888 font=mono size=12>up</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>down</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>forward</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>back</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>left</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>right</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>move</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n_right</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_up</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_forward</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Rotating the drone</style></b>
    <b><style color=#888888 font=mono size=12>turn_right</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>turn_left</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>turn</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n_quarters_anti_clockwise</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Checkpoints</style></b>
    <b><style color=#888888 font=mono size=12>save</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>name</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>go</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>name</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_right</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_up</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_forward</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Random blocks</style></b>
    <b><style color=#888888 font=mono size=12>random.block</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>random.plant</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>random.wool</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Block at drone position</style></b>
    <b><style color=#888888 font=mono size=12>get_block</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Placing one block</style></b>
    <b><style color=#888888 font=mono size=12>place</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>block</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>place_relative</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>n_right</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_up</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n_forward</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> checkpoint</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Shapes</style></b>
    <b><style color=#888888 font=mono size=12>cube</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>width</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> height</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> length</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>sphere</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>dome</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>cylinder</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>height</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vertical.cylinder</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>height</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>horizontal.cylinder</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>length</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Centered shapes</style></b>
    <b><style color=#888888 font=mono size=12>centered.cube</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>width</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> height</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> length</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>centered.sphere</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>centered.dome</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>centered.cylinder</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>height</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>centered.vertical.cylinder</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>height</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>centered.horizontal.cylinder</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>length</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> radius</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> block</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> hollow</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Math</style></b>
    <b><style color=#888888 font=mono size=12>random</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>\[m \[</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> n\]\]</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>round</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> num</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>round0</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>ceil</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>floor</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>deg</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>rad</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>exp</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>log</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>max</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> ...</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>min</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> ...</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>abs</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>pow</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> y</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>sqrt</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>sin</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>asin</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>sinh</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>cos</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>acos</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>cosh</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>tan</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>atan</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>atan2</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> y</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>tanh</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>pi</style></b>
    <b><style color=#888888 font=mono size=12>e</style></b>
    <b><style font=normal size=16>Misc</style></b>
    <b><style color=#888888 font=mono size=12>print</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>message</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>error</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>message</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>ipairs</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>table</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>pairs</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>table</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>table.randomizer</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>t</style><style font=mono size=12>)</style></b>
    <b><style font=normal size=16>Vectors</style></b>
    <b><style color=#888888 font=mono size=12>See https://github.com/ISs25u/vector3 for details</style></b>
    Operations + - * /
    <b><style color=#888888 font=mono size=12>vector</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> y</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> z</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vector.fromSpherical</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>r</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> theta</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> phi</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vector.fromCylindrical</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>r</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> phi</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> y</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vector.fromPolar</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>r</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> phi</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vector.srandom</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>a</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> b</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vector.crandom</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>a</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> b</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> c</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> d</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>vector.prandom</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>a</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> b</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:clone</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:length</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:norm</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:scale</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:limit</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:floor</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:round</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:set</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>x</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> y</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> z</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:offset</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>ox</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> oy</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> oz</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:apply</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>f</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:dist</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>v2</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:dot</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>v2</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:cross</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>v2</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:rotate_around</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>v</style><style font=mono size=12>,</style><style color=#e9c46a font=mono size=12> angle</style><style font=mono size=12>)</style></b>
    <b><style color=#888888 font=mono size=12>v1:unpack</style><style font=mono size=12>(</style><style color=#e9c46a font=mono size=12></style><style font=mono size=12>)</style></b>
]]
