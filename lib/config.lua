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
if codeblock.config.auth_levels[asked] then
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
-- Thirty-three colours the mod registers itself: six neutrals, then
-- twenty-seven chromatic ones in colour-wheel order, each family light / plain
-- / dark so the plain name a player reaches for first always exists.
--
-- The order is load-bearing. `hues` below is the chromatic tail as an array and
-- color(v, min, max) maps a number onto it, so a gradient across it has to read
-- as a rainbow. NEUTRALS is where that tail starts.
--
-- The hexes are read by lib/nodes.lua and by nothing else: one shared tile is
-- multiplied by each of them rather than 33 images being drawn.
--------------------------------------------------------------------------------

local NEUTRALS = 6

local palette = {
    {'white', '#f2f0eb'}, {'ash', '#c9c6bf'}, {'grey', '#8f8d88'},
    {'slate', '#5c6066'}, {'ink', '#33363b'}, {'black', '#1a1a1c'},

    {'salmon', '#e8836f'}, {'red', '#c0392b'}, {'maroon', '#7a2230'},
    {'apricot', '#f0a860'}, {'orange', '#e07b23'}, {'rust', '#a8501c'},
    {'sand', '#d8c091'}, {'brown', '#9a6b3f'}, {'chocolate', '#5b3a24'},
    {'butter', '#f2dd84'}, {'yellow', '#e0b422'}, {'ochre', '#a8801c'},
    {'lime', '#a8cc48'}, {'green', '#4a9d3f'}, {'forest', '#2c5e34'},
    {'aqua', '#7fd4c8'}, {'teal', '#2f8f86'}, {'cyan', '#2bb3c4'},
    {'sky', '#7fb8e0'}, {'blue', '#2f6fc4'}, {'navy', '#1e3a6e'},
    {'lavender', '#b4a6dd'}, {'violet', '#7a4fbf'}, {'indigo', '#43307a'},
    {'magenta', '#c44bb0'}, {'rose', '#d9628a'}, {'pink', '#f0a8c0'}
}

codeblock.config.palette = palette

--------------------------------------------------------------------------------
-- What a program may name, and what each name places
--
-- `all` is the flat short-name -> itemstring union every write path resolves a
-- block through, so the short names have to stay unique across the categories:
-- place() takes one string and knows nothing about which table it came from.
-- The category tables spell a name for the player and hold that unique key -
-- colors.red is 'red', glass.red is 'red_glass', lamps.red is 'red_lamp'.
--
-- `air` is engine-provided, belongs to no category, and is a name of its own.
--
-- `categories` is the ordered list the help panels, the block picker and
-- doc/api.md all render from, in palette order rather than alphabetically.
--------------------------------------------------------------------------------

local blocks = {all = {air = 'air'}, hues = {}, categories = {}}

for _, variant in ipairs({
    {'colors', ''}, {'glass', '_glass'}, {'lamps', '_lamp'}
}) do
    local spelled, names = {}, {}
    for i, entry in ipairs(palette) do
        local key = entry[1] .. variant[2]
        spelled[entry[1]] = key
        names[i] = entry[1]
        blocks.all[key] = 'codeblock:' .. key
    end
    blocks[variant[1]] = spelled
    blocks.categories[#blocks.categories + 1] = {
        name = variant[1],
        names = names
    }
end

for i = NEUTRALS + 1, #palette do
    blocks.hues[#blocks.hues + 1] = palette[i][1]
end

codeblock.config.allowed_blocks = blocks
