codeblock.config = {}

--------------------------------------------------------------------------------
-- General config
--------------------------------------------------------------------------------

----------------------- 1:limited 2:standard 3:privileged 4:trusted
codeblock.config.lua_dir = 'codeblock_files'
codeblock.config.default_auth_level = 4
codeblock.config.auth_levels = {1, 2, 3, 4}
codeblock.config.max_calls = {1e6, 1e7, 1e8, 1e9}
codeblock.config.max_volume = {1e5, 1e6, 1e7, 1e8}
codeblock.config.max_commands = {1e4, 1e5, 1e6, 1e7}
codeblock.config.max_distance = {150 ^ 2, 300 ^ 2, 700 ^ 2, 1500 ^ 2}
codeblock.config.max_dimension = {15, 30, 70, 150}
codeblock.config.commands_before_yield = {1, 10, 20, 40}
codeblock.config.calls_before_yield = {1, 100, 250, 600}

-- How long, in microseconds, one drone may spend advancing its program during
-- a single server step. See lib/stepper.lua.
--
-- A dedicated server steps every ~90ms by default, so 8ms is under a tenth of
-- a step at the top codelevel. Checked between resumes, so one long call can
-- overshoot, and each drone has its own allowance.
codeblock.config.step_budget_us = {1000, 2000, 4000, 8000}

-- How much Lua heap growth, in kB, one program run may be responsible for
-- before it is stopped. Checked at yield points, so it catches a program that
-- accumulates - appending to a table in a loop, building an ever-longer string.
-- A single enormous allocation returns before any check can run; that case is
-- covered by max_string_bytes below instead.
--
-- Generous on purpose: collectgarbage('count') reports the whole server's heap,
-- so the figure is a delta from program start and other mods show up in it.
codeblock.config.max_memory_kb = {64 * 1024, 128 * 1024, 256 * 1024, 512 * 1024}

-- Largest string a single call may produce, in bytes. The companion to
-- max_memory_kb, covering the one call that allocates everything at once. See
-- lib/strguard.lua: only rep and gsub can amplify, and they are bounded rather
-- than removed, because Lua 5.1 shares one string metatable across every
-- string and it cannot be hidden from the sandbox.
codeblock.config.max_string_bytes = {1024 * 1024, 4 * 1024 * 1024,
                                     16 * 1024 * 1024, 64 * 1024 * 1024}

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
