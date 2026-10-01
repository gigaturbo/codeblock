--------------------------------------------------------------------------------
-- The blocks the mod brings with it
--
-- codeblock:color_0 to codeblock:color_f, sixteen nodes carrying the palette's
-- colours, 256 each, through textures/codeblock_palette_<n>.png, and three
-- nodes per named colour in
-- codeblock.config.named - codeblock:<short>_brick, codeblock:<short>_glass and
-- codeblock:<short>_lamp. That is the whole of what a program can place, and it
-- is why this mod now depends on nothing but vector3: `default` and `wool` are
-- Minetest Game's and ship with almost no other game, so borrowing a node, a
-- texture or a sound from either put the mod out of reach of most of
-- ContentDB. (F11, F15, F-K-1)
--
-- One tile per variant - brick, glass, lamp - rather than 105 images, tinted
-- with [multiply, which scales the tile's RGB per pixel. Not
-- [colorize:<hex>:255, which replaces every pixel with the flat colour and
-- would throw the brick bond, the glass frame and the lamp grid away. The tiles
-- are near-white, so what they draw rides on the hex rather than replacing it.
-- The palette nodes' tile is pure white, so the engine's palette colour, which
-- multiplies it the same way, is exactly its hex. scripts/gen_textures.py draws
-- the tiles and scripts/gen_palette.py the palettes.
--
-- No `sounds` field anywhere below: the engine ships no sound assets of its
-- own and every node_sound_*_defaults() helper belongs to a game. Silence is
-- the price of depending on none of them.
--
-- is_ground_content = false on all three: these are player-built, and mapgen
-- must not treat them as stone it may carve a cave out of.
--------------------------------------------------------------------------------

local S = codeblock.S

-- Luanti light carries no hue: a lamp tinted red looks red and casts the same
-- light every other lamp does. paramtype = 'light' below is not decoration -
-- lua_api.md makes it a requirement for a light source to spread its light at
-- all.
local LAMP_LIGHT = core.LIGHT_MAX

--- The three variants. `suffix` is what the short name takes to become the node
-- name, and `make(name, tint)` is that colour's definition.
local variants = {
    {
        suffix = '_brick',
        make = function(name, tint)
            return {
                description = S('@1 brick', name),
                tiles = {'codeblock_brick.png^[multiply:' .. tint},
                groups = {
                    cracky = 3,
                    oddly_breakable_by_hand = 2,
                    codeblock = 1
                },
                is_ground_content = false
            }
        end
    }, {
        suffix = '_glass',
        make = function(name, tint)
            return {
                description = S('@1 glass', name),
                drawtype = 'glasslike',
                tiles = {'codeblock_glass.png^[multiply:' .. tint},
                paramtype = 'light',
                sunlight_propagates = true,
                use_texture_alpha = 'blend',
                groups = {
                    cracky = 3,
                    oddly_breakable_by_hand = 3,
                    codeblock = 1
                },
                is_ground_content = false
            }
        end
    }, {
        suffix = '_lamp',
        make = function(name, tint)
            return {
                description = S('@1 lamp', name),
                tiles = {'codeblock_lamp.png^[multiply:' .. tint},
                paramtype = 'light',
                light_source = LAMP_LIGHT,
                groups = {
                    cracky = 3,
                    oddly_breakable_by_hand = 2,
                    codeblock = 1
                },
                is_ground_content = false
            }
        end
    }
}

for _, entry in ipairs(codeblock.config.named) do
    for _, variant in ipairs(variants) do
        core.register_node('codeblock:' .. entry[1] .. variant.suffix,
                           variant.make(entry[1], entry[2]))
    end
end

-- paramtype2 = 'color' gives all eight bits of param2 to the colour, these
-- nodes needing no rotation. A player digging one keeps its colour in the item
-- and places it back the same: the engine carries palette_index both ways.
-- Only codeblock:color_0 is in the creative inventory, its index 0 being
-- white; see lib/config.lua for the layout.
for n = 0, 15 do
    local digit = ('%x'):format(n)
    core.register_node('codeblock:color_' .. digit, {
        description = S('Color block'),
        tiles = {'codeblock_block.png'},
        paramtype2 = 'color',
        palette = 'codeblock_palette_' .. digit .. '.png',
        groups = {
            cracky = 3,
            oddly_breakable_by_hand = 2,
            codeblock = 1,
            not_in_creative_inventory = n > 0 and 1 or nil
        },
        is_ground_content = false
    })
end

-- The v1 solid blocks, which a bare name used to place: kept so a world built
-- before v2 and an item a player still holds stay valid, out of the creative
-- inventory, and converted to the nearest palette colour as their mapblock
-- loads. They looked exactly like a palette block of their own hex, so the
-- change a player sees is the snap to the nearest palette colour. (F-K-1)
local solids, convert = {}, {}
local all = codeblock.config.allowed_blocks.all
local param2 = codeblock.config.allowed_blocks.param2
for _, entry in ipairs(codeblock.config.named) do
    local name = 'codeblock:' .. entry[1]
    core.register_node(name, {
        description = S('@1 block', entry[1]),
        tiles = {'codeblock_block.png^[multiply:' .. entry[2]},
        groups = {
            cracky = 3,
            oddly_breakable_by_hand = 2,
            codeblock = 1,
            not_in_creative_inventory = 1
        },
        is_ground_content = false
    })
    solids[#solids + 1] = name
    convert[name] = {name = all[entry[1]], param2 = param2[entry[1]]}
end

-- At every load, not once: on a map generated by 5.11.0 or older many mapblocks
-- carry no timestamp, and a run-once LBM never reaches them (lua_api.md, LBM
-- definition). A block holding none of these nodes costs the engine a lookup,
-- and one a player placed from a v1 item is converted the next time too.
-- swap_node, not set_node: a colour change must not run a node's callbacks.
core.register_lbm({
    label = 'codeblock v1 solid blocks to palette colours',
    name = 'codeblock:solid_to_palette',
    nodenames = solids,
    run_at_every_load = true,
    action = function(pos, node) core.swap_node(pos, convert[node.name]) end
})
