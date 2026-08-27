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

codeblock.config.auth_levels = {1, 2, 3, 4}

-- The codelevel a player gets on first join. Level 4 is right for singleplayer,
-- where the player is the administrator and a lower level would only be an
-- annoyance; on a server it would hand an unvetted joiner every ceiling below
-- at its widest. So the default depends on which one this is, and either can be
-- overridden by the setting. (S6)
--
-- Checked against auth_levels rather than trusted: every limit below is indexed
-- by this, so a level that does not exist would not be a wide limit but a nil
-- one, and the first command a program ran would fail on arithmetic.
local singleplayer = engine and engine.is_singleplayer()
local wanted = singleplayer and 4 or 2
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
codeblock.config.pace_ms = {250, 15, 0, 0}

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
codeblock.config.max_runtime_s = {300, 300, 600, 1800}

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
codeblock.config.map_memory_mb = {8, 16, 64, 128}

-- How many nodes one program may write.
--
-- The ceiling on a single shape as much as on the run, now that neither a
-- dimension nor a distance is bounded: 2e5 nodes is a 58-node cube or a
-- radius-36 sphere, 1e8 a 464-node cube. Bulk shapes are written in slices, so
-- a large one is slow rather than a freeze, which is what made bounding their
-- dimensions unnecessary.
codeblock.config.max_nodes_written = {2e5, 1e6, 1e7, 1e8}

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
codeblock.config.max_string_mb = {1, 4, 16, 64}

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
-- Allowed blocks with their names
--------------------------------------------------------------------------------

local allowed_blocks = {
    cubes = {
        air = 'air',
        stone = 'default:stone',
        cobble = 'default:cobble',
        stonebrick = 'default:stonebrick',
        stone_block = 'default:stone_block',
        mossycobble = 'default:mossycobble',
        desert_stone = 'default:desert_stone',
        desert_cobble = 'default:desert_cobble',
        desert_stonebrick = 'default:desert_stonebrick',
        desert_stone_block = 'default:desert_stone_block',
        sandstone = 'default:sandstone',
        sandstonebrick = 'default:sandstonebrick',
        sandstone_block = 'default:sandstone_block',
        desert_sandstone = 'default:desert_sandstone',
        desert_sandstone_brick = 'default:desert_sandstone_brick',
        desert_sandstone_block = 'default:desert_sandstone_block',
        silver_sandstone = 'default:silver_sandstone',
        silver_sandstone_brick = 'default:silver_sandstone_brick',
        silver_sandstone_block = 'default:silver_sandstone_block',
        obsidian = 'default:obsidian',
        obsidianbrick = 'default:obsidianbrick',
        obsidian_block = 'default:obsidian_block',
        dirt = 'default:dirt',
        dirt_with_grass = 'default:dirt_with_grass',
        dirt_with_dry_grass = 'default:dirt_with_dry_grass',
        dirt_with_snow = 'default:dirt_with_snow',
        dirt_with_rainforest_litter = 'default:dirt_with_rainforest_litter',
        dirt_with_coniferous_litter = 'default:dirt_with_coniferous_litter',
        dry_dirt = 'default:dry_dirt',
        dry_dirt_with_dry_grass = 'default:dry_dirt_with_dry_grass',
        permafrost = 'default:permafrost',
        permafrost_with_stones = 'default:permafrost_with_stones',
        permafrost_with_moss = 'default:permafrost_with_moss',
        clay = 'default:clay',
        snowblock = 'default:snowblock',
        ice = 'default:ice',
        tree = 'default:tree',
        wood = 'default:wood',
        leaves = 'default:leaves',
        jungletree = 'default:jungletree',
        junglewood = 'default:junglewood',
        jungleleaves = 'default:jungleleaves',
        pine_tree = 'default:pine_tree',
        pine_wood = 'default:pine_wood',
        pine_needles = 'default:pine_needles',
        acacia_tree = 'default:acacia_tree',
        acacia_wood = 'default:acacia_wood',
        acacia_leaves = 'default:acacia_leaves',
        aspen_tree = 'default:aspen_tree',
        aspen_wood = 'default:aspen_wood',
        aspen_leaves = 'default:aspen_leaves',
        stone_with_coal = 'default:stone_with_coal',
        coalblock = 'default:coalblock',
        stone_with_iron = 'default:stone_with_iron',
        steelblock = 'default:steelblock',
        stone_with_copper = 'default:stone_with_copper',
        copperblock = 'default:copperblock',
        stone_with_tin = 'default:stone_with_tin',
        tinblock = 'default:tinblock',
        bronzeblock = 'default:bronzeblock',
        stone_with_gold = 'default:stone_with_gold',
        goldblock = 'default:goldblock',
        stone_with_mese = 'default:stone_with_mese',
        mese = 'default:mese',
        stone_with_diamond = 'default:stone_with_diamond',
        diamondblock = 'default:diamondblock',
        cactus = 'default:cactus',
        bush_leaves = 'default:bush_leaves',
        acacia_bush_leaves = 'default:acacia_bush_leaves',
        pine_bush_needles = 'default:pine_bush_needles',
        bookshelf = 'default:bookshelf',
        glass = 'default:glass',
        obsidian_glass = 'default:obsidian_glass',
        brick = 'default:brick',
        meselamp = 'default:meselamp'
    },
    plants = {
        sapling = 'default:sapling',
        apple = 'default:apple',
        junglesapling = 'default:junglesapling',
        emergent_jungle_sapling = 'default:emergent_jungle_sapling',
        pine_sapling = 'default:pine_sapling',
        acacia_sapling = 'default:acacia_sapling',
        aspen_sapling = 'default:aspen_sapling',
        large_cactus_seedling = 'default:large_cactus_seedling',
        dry_shrub = 'default:dry_shrub',
        junglegrass = 'default:junglegrass',
        grass_1 = 'default:grass_1',
        grass_2 = 'default:grass_2',
        grass_3 = 'default:grass_3',
        grass_4 = 'default:grass_4',
        grass_5 = 'default:grass_5',
        dry_grass_1 = 'default:dry_grass_1',
        dry_grass_2 = 'default:dry_grass_2',
        dry_grass_3 = 'default:dry_grass_3',
        dry_grass_4 = 'default:dry_grass_4',
        dry_grass_5 = 'default:dry_grass_5',
        fern_1 = 'default:fern_1',
        fern_2 = 'default:fern_2',
        fern_3 = 'default:fern_3',
        marram_grass_1 = 'default:marram_grass_1',
        marram_grass_2 = 'default:marram_grass_2',
        marram_grass_3 = 'default:marram_grass_3',
        bush_stem = 'default:bush_stem',
        bush_sapling = 'default:bush_sapling',
        acacia_bush_stem = 'default:acacia_bush_stem',
        acacia_bush_sapling = 'default:acacia_bush_sapling',
        pine_bush_stem = 'default:pine_bush_stem',
        pine_bush_sapling = 'default:pine_bush_sapling'
    },
    wools = {
        white = 'wool:white',
        grey = 'wool:grey',
        dark_grey = 'wool:dark_grey',
        black = 'wool:black',
        violet = 'wool:violet',
        blue = 'wool:blue',
        cyan = 'wool:cyan',
        dark_green = 'wool:dark_green',
        green = 'wool:green',
        yellow = 'wool:yellow',
        brown = 'wool:brown',
        orange = 'wool:orange',
        red = 'wool:red',
        magenta = 'wool:magenta',
        pink = 'wool:pink'
    }
}

codeblock.config.allowed_blocks = {
    all = {},
    iwools = {
        'red', 'brown', 'orange', 'yellow', 'green',
        'dark_green', 'cyan', 'blue', 'violet',
        'magenta', 'pink'
    }
}

for category, blocks in pairs(allowed_blocks) do
    codeblock.config.allowed_blocks[category] = {}
    for k, v in pairs(blocks) do
        codeblock.config.allowed_blocks[category][k] = k
        codeblock.config.allowed_blocks.all[k] = v
    end

end
