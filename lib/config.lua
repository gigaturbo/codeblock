codeblock.config = {}

--------------------------------------------------------------------------------
-- General config
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Reading the settings
--
-- Every limit here can be overridden from settingtypes.txt, so an administrator
-- changes them in the settings menu or minetest.conf rather than patching this
-- file and losing the change on update.
--
-- Both reads are guarded, because this file is also dofile'd by
-- scripts/gen_docs.lua under a bare interpreter where there is no `core`
-- global at all. The values below stay plain literals for a second reason:
-- gen_docs.lua reads this source to check that every `max_*` table has a row in
-- doc/api.md's codelevel table, and a computed value would switch that check
-- off without saying so.
--------------------------------------------------------------------------------

local engine = rawget(_G, 'core')
local settings = engine and engine.settings

local function warn(name, why)
    if engine then
        engine.log('warning', ('[codeblock] setting codeblock_%s %s'):format(
            name, why))
    end
end

--- One number from `codeblock_<name>`, or `default` when unset or unreadable.
local function number(name, default)
    local raw = settings and settings:get('codeblock_' .. name)
    if raw == nil or raw == '' then return default end
    local n = tonumber(raw)
    if not n then
        warn(name, 'is not a number; using the default')
        return default
    end
    return n
end

--- A boolean from `codeblock_<name>`, or `default` when unset or unreadable.
local function flag(name, default)
    if not settings then return default end
    return settings:get_bool('codeblock_' .. name, default)
end

--- Four numbers from `codeblock_<name>`, one per codelevel: "1,2,3,4".
--
-- Negative values are rejected rather than trusted; zero is allowed, because
-- pace_ms uses it to mean "do not pace at all". Nothing here is a divisor any
-- more, which is what made a zero dangerous before.
local function per_level(name, default)
    local raw = settings and settings:get('codeblock_' .. name)
    if raw == nil or raw == '' then return default end
    local t = {}
    for n in raw:gmatch('[^,%s]+') do t[#t + 1] = tonumber(n) end
    if #t ~= 4 then
        warn(name, 'needs four numbers separated by commas; using the defaults')
        return default
    end
    for i = 1, 4 do
        if t[i] < 0 then
            warn(name, 'has a negative value; using the defaults')
            return default
        end
    end
    return t
end

----------------------- 1:limited 2:standard 3:privileged 4:trusted
codeblock.config.lua_dir = 'codeblock_files'

-- The largest file, in kilobytes, that will be read out of a player's directory.
--
-- Not a limit on a running program - it bounds the read itself, which nothing
-- else does. A file is read whole, cached on its record, then escaped into the
-- editor's formspec and sent to the client on every redraw, so one oversized
-- file in the directory is paid for three times over: a 168 MB one took the
-- server to 14 GB and froze it (B40). A program a person edits is kilobytes, and
-- a saved one cannot exceed 640 kB anyway - that is the engine's own ceiling on
-- a formspec submission, from 5.7 onwards.
codeblock.config.max_file_kb = number('max_file_kb', 128)

-- Flatten the sky for every player who joins: daylight held at noon, and no
-- sun, moon, stars or clouds.
--
-- Off, and it is the only presentation setting here. Nothing this mod does needs
-- it - a drone builds the same at midnight - and daylight is a game's to
-- contribute, not a mod's. It exists only because these five overrides were
-- applied unguarded on every join, so any game that installed the mod silently
-- lost its sky; a game that wants that look now asks for it in its own
-- minetest.conf. (C18)
codeblock.config.flat_sky = flag('flat_sky', false)

-- Whether a player who has expressed no preference sees the drone HUD: the file,
-- the state, and which limit the running program is closest to.
--
-- On, unlike flat_sky, and the difference is the point. This is not presentation
-- the mod imposes on a game - it is on screen only while that player's own
-- program runs, and it is the only place the budget a run is held to is visible
-- at all. A player who disagrees unticks it in the editor, and that choice wins
-- over this default. (F4, C18)
codeblock.config.drone_hud = flag('drone_hud', true)

codeblock.config.auth_levels = {1, 2, 3, 4}

--- Validate a codelevel, from player meta or from a setting.
-- Returns ok, level - the default level when it is not one of auth_levels, so
-- the second return can be used unchecked. The default is read at call time
-- rather than captured, because the setting that sets it is validated by this
-- same function, just below.
function codeblock.config.check_auth_level(auth_level)
    if type(auth_level) == 'number' and
        codeblock.config.auth_levels[auth_level] ~= nil then
        return true, auth_level
    end
    return false, codeblock.config.default_auth_level
end

-- The codelevel a player gets on first join. Level 3 is right for singleplayer:
-- the player is the administrator, so a paced level would only be an annoyance,
-- but level 4 is the widest set of ceilings there is and nothing should sit
-- there without being asked for - the difference is a headroom nobody needs by
-- default, not a capability. On a server the default is 2, which builds fast
-- enough to be useful and cannot hand an unvetted joiner the whole server step.
-- Either is overridden by the setting. (S6)
--
-- Checked against auth_levels rather than trusted: every limit below is indexed
-- by this, so a level that does not exist would not be a wide limit but a nil
-- one, and the first command a program ran would fail on arithmetic.
local singleplayer = engine and engine.is_singleplayer()
local wanted = singleplayer and 3 or 2
local asked = number('default_auth_level', wanted)
if codeblock.config.check_auth_level(asked) then
    wanted = asked
else
    warn('default_auth_level', 'is not a codelevel from 1 to 4; ignored')
end
codeblock.config.default_auth_level = wanted
-- How long the drone waits after each command, in milliseconds; zero is no
-- wait, and the drone then runs as fast as its share of the server step allows.
--
-- The one setting here that is not about resources. The lower codelevels exist
-- to be watched: a program that places a block and moves on inside a
-- millisecond teaches nothing to someone finding out what a loop does, so level
-- 1 is deliberately slow and level 2 merely brisk. A paced drone costs the
-- server almost nothing, which is why the novice levels are cheap to host as
-- well as easy to follow.
codeblock.config.pace_ms = {250, 5, 0, 0}

-- How long one program may run in total, in seconds - the bound on a program
-- that never finishes. Counted as time the drone was actually advanced, not
-- wall clock, so pacing and a busy server do not eat into it.
--
-- One exception, and it is deliberate: sleep() charges the wait it asks for.
-- A sleeping drone spends no CPU, so nothing else here could bound it, and an
-- unbounded wait is the same runaway program in a different disguise. (F3)
--
-- This replaced max_calls, which bounded the same thing in units nobody could
-- reason about: a call was neither a second nor a node, and its ceiling had to
-- be guessed.
codeblock.config.max_runtime_s = {30, 60, 120, 300}

-- The map footprint one program may hold, in megabytes.
--
-- The limit that tracks a resource rather than a proxy for one. `place()` has to
-- call core.load_area before writing, or the node silently never lands (A4), and
-- a bulk shape emerges the region it writes; either way the server holds a
-- 16 KiB MapBlock per 16x16x16 nodes touched - measured at 16.3 kB over a
-- 400-block sweep - and no other limit here can see it. heap_mb is the Lua heap
-- and a MapBlock is not on it, while max_nodes_written counts nodes written,
-- which a program placing one node per mapblock scores the minimum on. (S5)
--
-- A rate, not a total: the engine unloads a block nothing has touched for
-- server_unload_unused_data_timeout, so the footprint drains by itself and a
-- program over this ceiling is made to wait rather than stopped. The ceiling
-- divided by that window is the load rate it settles at - 128 MB over 29s is
-- some 280 mapblocks a second, against the 1700 a second the engine can
-- actually serve. See lib/limits.lua.
codeblock.config.map_memory_mb = {8, 32, 64, 128}

-- How many nodes one program may write.
--
-- The ceiling on a single shape as much as on the run, now that neither a
-- dimension nor a distance is bounded: 1e5 nodes is a 46-node cube or a
-- radius-28 sphere, 5e7 a 368-node cube. Bulk shapes are written in slices, so
-- a large one is slow rather than a freeze, which is what made bounding their
-- dimensions unnecessary.
codeblock.config.max_nodes_written = {1e5, 5e5, 1e6, 5e7}

-- How long, in microseconds, one drone may spend advancing its program during
-- a single server step. See lib/stepper.lua.
--
-- A dedicated server steps every ~90ms by default, so 8ms is under a tenth of
-- a step at the top codelevel. It is a cap per drone, not an allowance: what a
-- drone actually gets is the smaller of this and its share of
-- server_step_budget_us below.
codeblock.config.step_budget_us = {1000, 2000, 4000, 8000}

-- The whole mod's slice of one server step, in microseconds, divided equally
-- among the drones currently running. Without it, N drones cost N budgets per
-- step and the server's cost grows with the number of players. (S5)
codeblock.config.server_step_budget_us = number('server_step_budget_us', 16000)

-- How much Lua heap growth, in megabytes, one program run may be responsible
-- for before it is stopped. Checked where the drone yields, so it catches a
-- program that accumulates - appending to a table in a loop, building an
-- ever-longer string. A single enormous allocation returns before any check can
-- run; that case is covered by max_string_mb below instead.
--
-- Generous on purpose: collectgarbage('count') reports the whole server's heap,
-- so the figure is a delta from program start and other mods show up in it.
codeblock.config.heap_mb = {16, 64, 128, 512}

-- Largest string a single call may produce, in megabytes. The companion to
-- heap_mb, covering the one call that allocates everything at once. See
-- lib/strguard.lua: only rep and gsub can amplify, and they are bounded rather
-- than removed, because Lua 5.1 shares one string metatable across every
-- string and it cannot be hidden from the sandbox.
codeblock.config.max_string_mb = {1, 8, 16, 64}

-- The engine's own unload timer, in seconds: how long a mapblock nothing has
-- touched stays resident. Read from the engine rather than restated, because
-- map_memory_mb decays over exactly this window and a disagreement would make
-- the budget describe a footprint the server does not have.
codeblock.config.map_window_s =
    tonumber(settings and settings:get('server_unload_unused_data_timeout')) or
    29

-- Apply the per-codelevel overrides in one place, rather than wrapping each
-- literal above and losing gen_docs.lua's check on them. Every four-number table
-- in the config is a codelevel limit and takes one setting; auth_levels is the
-- list of levels themselves, not a limit, so it keeps its values. The block
-- tables are not assigned yet, which is why this runs here and not at the end.
for name, default in pairs(codeblock.config) do
    if name ~= 'auth_levels' and type(default) == 'table' and #default == 4 then
        codeblock.config[name] = per_level(name, default)
    end
end

-- Settings that no longer exist, and what took over from each. An
-- administrator's minetest.conf outlives a rewrite, and a limit that is silently
-- ignored is worse than one that is rejected: it reads as being in force.
local replaced = {
    max_calls = 'max_runtime_s',
    max_commands = 'max_runtime_s',
    max_volume = 'max_nodes_written',
    max_dimension = 'max_nodes_written',
    max_distance = 'nothing; distance is no longer limited',
    max_mapblocks = 'map_memory_mb',
    max_memory_kb = 'heap_mb',
    max_string_bytes = 'max_string_mb',
    commands_before_yield = 'pace_ms',
    calls_before_yield = 'pace_ms'
}
for old, new in pairs(replaced) do
    local raw = settings and settings:get('codeblock_' .. old)
    if raw ~= nil and raw ~= '' then
        warn(old, 'no longer exists; use codeblock_' .. new)
    end
end


--------------------------------------------------------------------------------
-- The block palette
--
-- Thirty-five colours the mod registers itself: five neutrals light to dark,
-- then ten hue families in colour-wheel order, each one light / plain / dark so
-- the plain name a player reaches for first always exists.
--
-- The two literals below are the source, and `palette` and the four palette
-- views are derived from them. `palette` is the flat {name, hex} list
-- lib/nodes.lua reads - the hexes go nowhere else, one shared tile per variant
-- being multiplied by each of them rather than 105 images being drawn.
--
-- The four views - `hues`, `light_hues`, `dark_hues` and `neutrals` - are
-- ordered arrays of short colour names, and they are one axis of the palette:
-- which colours, in what order. The category is the other axis: which material.
-- Because every category is indexed by the same short name, glass[h] and
-- lamps[h] turn any of these arrays into a glass or a lamp gradient, so the
-- four views cost three names each rather than one per material. The three hue
-- views are in colour-wheel order, so ramp.hues and ramp.of over them read as
-- gradients; `neutrals` is light to dark. (F14)
--------------------------------------------------------------------------------

-- The neutral ramp, light to dark. These five hexes are a choice rather than a
-- requirement - an even ramp - and retuning them touches nothing else.
local neutrals = {
    {'white', '#ffffff'}, {'light_grey', '#c0c0c0'}, {'grey', '#808080'},
    {'dark_grey', '#404040'}, {'black', '#101010'}
}

-- {family, light, plain, dark}, in colour-wheel order.
local families = {
    {'pink', '#ec8faa', '#ff6f98', '#a64662'},
    {'red', '#e98d82', '#f74931', '#a13526'},
    {'orange', '#edb581', '#ff9c40', '#a5672e'},
    {'yellow', '#f3e583', '#ffe32b', '#a49422'},
    {'olive', '#d4e679', '#bcd92a', '#7d8f23'},
    {'lime', '#bae379', '#90cf2a', '#628923'},
    {'green', '#8ee3b4', '#57b886', '#3b7e5b'},
    {'cyan', '#a8e2e9', '#49c1d1', '#33818b'},
    {'blue', '#879de9', '#4563cc', '#314488'},
    {'violet', '#a985de', '#7f56b8', '#563b7e'}
}

local palette, hues, light_hues, dark_hues, neutral_names = {}, {}, {}, {}, {}
for i, neutral in ipairs(neutrals) do
    palette[#palette + 1] = neutral
    neutral_names[i] = neutral[1]
end
for i, family in ipairs(families) do
    local plain = family[1]
    hues[i] = plain
    light_hues[i] = 'light_' .. plain
    dark_hues[i] = 'dark_' .. plain
    palette[#palette + 1] = {light_hues[i], family[2]}
    palette[#palette + 1] = {plain, family[3]}
    palette[#palette + 1] = {dark_hues[i], family[4]}
end

codeblock.config.palette = palette

--------------------------------------------------------------------------------
-- What a program may name, and what each name places
--
-- `all` is the flat key -> itemstring union every write path resolves a block
-- through: place() takes one string and knows nothing about which table it came
-- from, so the keys have to be unique across every category. A category spells
-- a name for the player and holds that unique key - colors.red is 'red',
-- glass.red is 'red_glass', lamps.red is 'red_lamp'.
--
-- `by_node` is the same map read backwards, for get_block().
--
-- `air` is engine-provided, belongs to no category, and is a name of its own.
--
-- `categories` is the ordered list the help panels, the block picker and
-- doc/api.md all render from, in palette order rather than alphabetically;
-- `by_name` is the same records keyed by name, and `pickable` the flat ordered
-- list the editor's block picker draws.
--
-- A game adds a category of its own through codeblock.register_blocks - see
-- lib/blocks.lua - so none of these lists is complete until every mod has
-- loaded. They are mutated and never replaced, which is what lets a reader hold
-- a local reference to one and still see a late arrival. (F11)
--------------------------------------------------------------------------------

local blocks = {
    all = {air = 'air'},
    by_node = {air = 'air'},
    -- The four palette views, short colour names rather than flat keys. For
    -- `colors` the two are equal, which falls out of F11's key layout - a
    -- category holds its short name unchanged and only glass and lamps suffix
    -- it - so place(ramp.of(dark_hues, i, 1, n)) places a solid block with no
    -- wrapping, while glass[ramp.of(dark_hues, i, 1, n)] places its glass.
    hues = hues,
    light_hues = light_hues,
    dark_hues = dark_hues,
    neutrals = neutral_names,
    categories = {},
    by_name = {},
    pickable = {{key = 'air', label = 'air'}},
    -- What a bare place() uses until a player picks something else: the flat
    -- key of the grey solid block. lib/api.lua says so in prose, so the two
    -- have to agree.
    fallback = 'grey'
}

--- Add one block category, and every view of it, in one place.
--
-- `name` is the table a program reads. `entries` is an array of
-- {short, key, itemstring} in the order the name lists are drawn in: `short` is
-- what a player spells after the dot, `key` is the unique flat name place()
-- takes, and `itemstring` is what lands in the world.
--
-- The record carries `names`, the shorts in that order, `spelled`, short -> key,
-- and `keys`, the same keys as an array - the order ramp.of resolves a category
-- table to, a map having none of its own. Whatever order `entries` arrived in:
-- palette order for the mod's own three, and alphabetical for a category a game
-- registered, which lib/blocks.lua sorts because a Lua map has no order to
-- preserve.
--
-- Deriving the views here rather than in each reader is what keeps a late
-- registration visible: a list built once at load time by lib/commands.lua or
-- lib/formspecs.lua would be a snapshot taken before any game had registered.
function codeblock.config.add_category(name, entries)
    local spelled, names, keys = {}, {}, {}
    for i, entry in ipairs(entries) do
        local short, key, item = entry[1], entry[2], entry[3]
        names[i] = short
        keys[i] = key
        spelled[short] = key
        blocks.all[key] = item
        -- First registrant wins, so a game listing one of the mod's own nodes
        -- in its category cannot change what get_block() answers for it.
        if blocks.by_node[item] == nil then blocks.by_node[item] = key end
        blocks.pickable[#blocks.pickable + 1] = {
            key = key,
            label = name .. '.' .. short
        }
    end
    local category = {
        name = name,
        names = names,
        keys = keys,
        spelled = spelled
    }
    blocks.categories[#blocks.categories + 1] = category
    blocks.by_name[name] = category
    return category
end

for _, variant in ipairs({
    {'colors', ''}, {'glass', '_glass'}, {'lamps', '_lamp'}
}) do
    local entries = {}
    for i, entry in ipairs(palette) do
        local key = entry[1] .. variant[2]
        entries[i] = {entry[1], key, 'codeblock:' .. key}
    end
    codeblock.config.add_category(variant[1], entries)
end

codeblock.config.allowed_blocks = blocks
