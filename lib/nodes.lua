--------------------------------------------------------------------------------
-- The blocks the mod brings with it
--
-- Three nodes per colour in codeblock.config.palette - solid, glass and lamp -
-- registered as codeblock:<short>, codeblock:<short>_glass and
-- codeblock:<short>_lamp. That is the whole of what a program can place, and it
-- is why this mod now depends on nothing but vector3: `default` and `wool` are
-- Minetest Game's and ship with almost no other game, so borrowing a node, a
-- texture or a sound from either put the mod out of reach of most of
-- ContentDB. (F11)
--
-- One definition per colour rather than one node with a param2 colour palette:
-- neither write path carries param2 - lib/shapes.lua writes data[i] = id and
-- lib/cost.lua's place_block writes set_node{name = block} - so a definition
-- per colour costs nothing here and a palette would change both.
--
-- One tile per variant - block, glass, lamp - rather than 105 images, tinted
-- with [multiply, which scales the tile's RGB per pixel. Not
-- [colorize:<hex>:255, which replaces every pixel with the flat colour and
-- would throw the glass frame and the lamp grid away. The block tile is pure
-- white, so a solid block is exactly its palette hex; the other two are
-- near-white, so what they draw rides on that hex rather than replacing it.
-- scripts/gen_textures.py draws all three.
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
        suffix = '',
        make = function(name, tint)
            return {
                description = S('@1 block', name),
                tiles = {'codeblock_block.png^[multiply:' .. tint},
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

for _, entry in ipairs(codeblock.config.palette) do
    for _, variant in ipairs(variants) do
        core.register_node('codeblock:' .. entry[1] .. variant.suffix,
                           variant.make(entry[1], entry[2]))
    end
end
