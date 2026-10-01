--- The single description of the player-facing API.
--
-- This file is the source. The sandbox environment, the in-game help panel
-- (api.to_hypertext) and doc/api.md (api.to_markdown) are all derived from it,
-- so they cannot drift apart. Pure data - no closures, no dependency on the mod
-- being loaded - so scripts/gen_docs.lua can read it under a bare interpreter.
--
-- Entry fields:
--   name     the name a program uses, dotted for nested tables
--   params   parameter names, in order, for the signature line
--   doc      one line for the reference; keep it to what a player needs
--   kind     'fn' (default) or 'value' for a table or constant
--   note     optional extra paragraph, for the Markdown only

local api = {}

--------------------------------------------------------------------------------
-- the API
--------------------------------------------------------------------------------

api.groups = {
    {
        title = 'Moving the drone',
        intro = 'The coordinate system is relative to the drone, which faces ' ..
            'the direction the player was facing when it was placed. `n` is a ' ..
            'whole number of blocks, defaults to 1, and may be negative - ' ..
            '`up(-1)` is `down(1)`.',
        entries = {
            {name = 'up', params = {'n'}, doc = 'Move n blocks up.'},
            {name = 'down', params = {'n'}, doc = 'Move n blocks down.'},
            {name = 'forward', params = {'n'}, doc = 'Move n blocks forward.'},
            {name = 'back', params = {'n'}, doc = 'Move n blocks backward.'},
            {name = 'left', params = {'n'}, doc = 'Move n blocks left.'},
            {name = 'right', params = {'n'}, doc = 'Move n blocks right.'},
            {
                name = 'move',
                params = {'n_right', 'n_up', 'n_forward'},
                doc = 'Move on all three axes at once. Each defaults to zero.'
            }
        }
    }, {
        title = 'Rotating the drone',
        entries = {
            {name = 'turn_right', params = {}, doc = 'Turn a quarter turn right.'},
            {name = 'turn_left', params = {}, doc = 'Turn a quarter turn left.'},
            {
                name = 'turn',
                params = {'n_quarters_anti_clockwise'},
                doc = 'Turn n quarter turns anti-clockwise.'
            }
        }
    }, {
        title = 'Waiting',
        intro = 'A wait costs the program running time, the same budget a ' ..
            'long program spends, so a program cannot wait for ever: asking ' ..
            'for more than is left stops it there. Nothing else on the ' ..
            'server waits - other drones keep building and take the time ' ..
            'this one is not using.',
        entries = {
            {
                name = 'sleep',
                params = {'seconds'},
                doc = 'Pause the drone for this many seconds.',
                note = 'Defaults to one second, and fractions are allowed. ' ..
                    'The server looks at its drones about eleven times a ' ..
                    'second, so anything shorter than that lasts one look.'
            }
        }
    }, {
        title = 'Checkpoints',
        intro = 'A checkpoint remembers a position so it can be returned to. ' ..
            'Names are strings. The checkpoint `spawn` always exists and is ' ..
            'where the drone was placed.',
        entries = {
            {
                name = 'save',
                params = {'name'},
                doc = 'Save the current position under this name.'
            }, {
                name = 'go',
                params = {'name', 'n_right', 'n_up', 'n_forward'},
                doc = 'Return to a checkpoint, with an optional offset.',
                note = 'Every argument is optional: `go()` is ' ..
                    '`go(\'spawn\', 0, 0, 0)`.'
            }
        }
    }, {
        title = 'Placing one block',
        intro = 'Leave `block` out and the default block is used: the one ' ..
            'chosen in the editor\'s Settings panel, or grey until a choice ' ..
            'is made.',
        entries = {
            {
                name = 'place',
                params = {'block'},
                doc = 'Place one block at the drone position.'
            }, {
                name = 'place_relative',
                params = {'n_right', 'n_up', 'n_forward', 'block', 'checkpoint'},
                doc = 'Place one block at an offset from a checkpoint.',
                note = '`checkpoint` defaults to `spawn`.'
            }, {
                name = 'default_block',
                params = {'block'},
                doc = 'Change the default block for the rest of the program.',
                note = 'Affects every later call that leaves `block` out, ' ..
                    'shapes included. It lasts until the program ends and ' ..
                    'does not change the choice saved in the editor.'
            }
        }
    }, {
        title = 'Shapes',
        intro = 'The drone position is the back-bottom-left of the shape, ' ..
            'which extends right, up and forward. `width` runs right, ' ..
            '`height` up, `length` forward, and `radius` in the remaining ' ..
            'directions. `hollow` defaults to false and `block` to the ' ..
            'default block.',
        entries = {
            {
                name = 'cube',
                params = {'width', 'height', 'length', 'block', 'hollow'},
                doc = 'A rectangular box.'
            },
            {
                name = 'sphere',
                params = {'radius', 'block', 'hollow'},
                doc = 'A sphere.'
            },
            {
                name = 'dome',
                params = {'radius', 'block', 'hollow'},
                doc = 'The upper half of a sphere.'
            }, {
                name = 'cylinder',
                params = {'height', 'radius', 'block', 'hollow'},
                doc = 'A vertical cylinder; short for vertical.cylinder.'
            }, {
                name = 'vertical.cylinder',
                params = {'height', 'radius', 'block', 'hollow'},
                doc = 'A cylinder standing on its end.'
            }, {
                name = 'horizontal.cylinder',
                params = {'length', 'radius', 'block', 'hollow'},
                doc = 'A cylinder lying along the forward axis.'
            }
        }
    }, {
        title = 'Centered shapes',
        intro = 'The same shapes, positioned so the drone is at their centre ' ..
            'rather than a corner. For a dome the drone is at the centre of ' ..
            'its flat base. `width` runs left-right, `height` up-down and ' ..
            '`length` forward-backward.',
        entries = {
            {
                name = 'centered.cube',
                params = {'width', 'height', 'length', 'block', 'hollow'},
                doc = 'A box centred on the drone.'
            }, {
                name = 'centered.sphere',
                params = {'radius', 'block', 'hollow'},
                doc = 'A sphere centred on the drone.'
            }, {
                name = 'centered.dome',
                params = {'radius', 'block', 'hollow'},
                doc = 'A dome centred on the drone.'
            }, {
                name = 'centered.cylinder',
                params = {'height', 'radius', 'block', 'hollow'},
                doc = 'Short for centered.vertical.cylinder.'
            }, {
                name = 'centered.vertical.cylinder',
                params = {'height', 'radius', 'block', 'hollow'},
                doc = 'A standing cylinder centred on the drone.'
            }, {
                name = 'centered.horizontal.cylinder',
                params = {'length', 'radius', 'block', 'hollow'},
                doc = 'A lying cylinder centred on the drone.'
            }
        }
    }, {
        title = 'Material blocks',
        -- Named, because lib/blocks.lua appends an entry here for every
        -- category a game registers and matching on the title would break on a
        -- rewording. It is the only group that grows at run time. (F11)
        id = 'blocks',
        intro = 'Bricks, glass and lamps, each in 35 named colours: 5 ' ..
            'neutrals, and 10 hues in a light, a plain and a dark shade. ' ..
            '`bricks.red`, `glass.light_blue` and `lamps.dark_green` are ' ..
            'blocks to place. The names are listed under Block types ' ..
            'below. A name that does not exist stops the program, naming ' ..
            'it. For any other colour, use a solid colour.',
        entries = {
            {
                name = 'bricks',
                kind = 'value',
                doc = 'Brick blocks, indexed by colour name.'
            }, {
                name = 'glass',
                kind = 'value',
                doc = 'See-through blocks, indexed by colour name.'
            }, {
                name = 'lamps',
                kind = 'value',
                doc = 'Glowing blocks, indexed by colour name. The light is ' ..
                    'the same whatever the colour.'
            }, {
                name = 'air',
                kind = 'value',
                doc = 'Empty space. Place it to carve rather than to build.'
            }
        }
    }, {
        title = 'Color names',
        intro = 'The 35 names in four arrays: 10 `hues`, 10 `light_hues`, ' ..
            '10 `dark_hues` and 5 `neutrals`. They hold names, not ' ..
            'blocks. A name indexes any material: `bricks[hues[i]]` is a ' ..
            'brick and `lamps[dark_hues[i]]` a lamp. A name placed by ' ..
            'itself places a solid colour block, `place(hues[i])` (see ' ..
            'Solid colors below).',
        entries = {
            {
                name = 'hues',
                kind = 'value',
                doc = 'The plain shade of each hue, in colour-wheel order.'
            }, {
                name = 'light_hues',
                kind = 'value',
                doc = 'The light shade of each hue, same order.'
            }, {
                name = 'dark_hues',
                kind = 'value',
                doc = 'The dark shade of each hue, same order.'
            }, {
                name = 'neutrals',
                kind = 'value',
                doc = 'The neutrals, white to black.'
            }
        }
    }, {
        title = 'Solid colors',
        intro = 'Solid blocks in 3930 colours. The functions below reach ' ..
            'any of them, from a hex string, from red, green and blue, ' ..
            'or from OKLCh, OKHSL or OKHSV numbers, each rounding the ' ..
            'colour asked for to the nearest of the 3930: ' ..
            '`place(colors.hex(\'#f7a8e7\'))` places `color_#f9a7ef`, the ' ..
            'name `get_block` reads back. The colours are steps of ' ..
            'lightness, chroma and hue, so a gradient in one never steps ' ..
            'back in another.\n\n' ..
            '35 of them are named, `colors.red`, `colors.dark_blue` and ' ..
            'the rest: each is the one of the 3930 closest to the ' ..
            'material colour of the same name. A bare name such as ' ..
            '`\'red\'` is the same block.',
        entries = {
            {
                name = 'colors.hex',
                params = {'hex'},
                doc = 'The palette colour of a hex string, `#rgb` or `#rrggbb`.'
            }, {
                name = 'colors.rgb',
                params = {'r', 'g', 'b'},
                doc = 'The palette colour of red, green and blue, each 0 to 255.',
                note = 'A value outside 0 to 255 is clamped. A value that ' ..
                    'is not a number stops the program.'
            }, {
                name = 'colors.oklch',
                params = {'L', 'c', 'h'},
                doc = 'The palette colour of a lightness, a chroma and a hue.',
                note = 'The numbers of CSS `oklch()`: `L` from 0 (black) to ' ..
                    '1 (white), `c` from 0 (grey) to about 0.37, and `h` an ' ..
                    'angle in degrees. Turn `h` for a rainbow of one ' ..
                    'lightness. A screen shows far more chroma in some hues ' ..
                    'than others, so a large `c` gives vivid blues and dull ' ..
                    'greens. For a rainbow as strong in every hue, use `L` ' ..
                    '0.75 and `c` 0.128 or less.'
            }, {
                name = 'colors.okhsl',
                params = {'h', 's', 'l'},
                doc = 'The palette colour of a hue, a saturation and a ' ..
                    'lightness.',
                note = '`h` in degrees, `s` and `l` from 0 to 1. `l` is the ' ..
                    'same lightness in every hue, so turning `h` gives a ' ..
                    'rainbow of one brightness. `s` 1 is the most chroma a ' ..
                    'screen shows at that hue and lightness.'
            }, {
                name = 'colors.okhsv',
                params = {'h', 's', 'v'},
                doc = 'The palette colour of a hue, a saturation and a value.',
                note = '`h` in degrees, `s` and `v` from 0 to 1. ' ..
                    '`colors.okhsv(h, 1, 1)` is the most vivid colour of a ' ..
                    'hue, `s` 0 a grey and `v` 0 black. Turning `h` gives ' ..
                    'the most vivid rainbow, light in yellow and dark in blue.'
            }, {
                name = 'colors.list',
                kind = 'value',
                doc = 'All 3930 colours as an array, greys first.',
                note = 'For `random.of(colors.list)`. It is not a gradient: ' ..
                    'ramp with `colors.oklch`, `colors.okhsl` or ' ..
                    '`colors.okhsv` instead.'
            }
        }
    }, {
        title = 'Block utilities',
        intro = 'Picking a block out of many, and reading the map. ' ..
            '`random` picks one at random. `ramp` maps a number onto a ' ..
            'list, so a shape can be coloured by height, distance or any ' ..
            'other number: `min` and below give the first item, `max` and ' ..
            'above the last. `min` and `max` default to 1 and the length ' ..
            'of the list.',
        entries = {
            {
                name = 'random.of',
                params = {'list'},
                doc = 'One value of a list or a block table, at random.',
                note = 'Takes any list: `hues`, a block table such as ' ..
                    '`bricks`, `colors.list`, or a list you built. ' ..
                    '`random.of(hues)` gives ten clean colours, where a ' ..
                    'pick across a whole block table mixes light, plain and ' ..
                    'dark shades and looks muddled.'
            }, {
                name = 'random.hues',
                params = {},
                doc = 'A random hue, short for random.of(hues).',
                note = 'A colour name, so `place(random.hues())` is a solid ' ..
                    'colour and `lamps[random.hues()]` the matching lamp.'
            }, {
                name = 'ramp.hues',
                params = {'v', 'min', 'max'},
                doc = 'A smooth rainbow, short for ramp.of(hues, v, min, max).'
            }, {
                name = 'ramp.of',
                params = {'list', 'v', 'min', 'max'},
                doc = 'Map a number onto a list or a block table.',
                note = 'Answers whatever the list holds, so ' ..
                    '`glass[ramp.of(dark_hues, i, 1, n)]` runs through the ' ..
                    'dark shades in glass. The four colour-name arrays read ' ..
                    'as gradients. A block table has no order of its own: ' ..
                    '`bricks`, `glass` and `lamps` are walked in palette ' ..
                    'order, light, plain and dark through each hue, which ' ..
                    'strobes, and a table the game added alphabetically. A ' ..
                    'value that is neither a list nor a block table gives ' ..
                    'nothing rather than stopping the program.'
            }, {
                name = 'get_block',
                params = {'n_right', 'n_up', 'n_forward'},
                doc = 'The block at an offset from the drone, without ' ..
                    'moving it.',
                note = 'Each offset defaults to zero, so `get_block()` reads ' ..
                    'where the drone is and `get_block(0, 0, 1)` one step ' ..
                    'ahead. The offsets turn with the drone, as in ' ..
                    '`place_relative`. It answers the name of a block the ' ..
                    'drone could place, `false` for a node it could not, ' ..
                    'and `nil` for map never generated or outside the world.'
            }, {
                name = 'is_block',
                params = {'block', 'n_right', 'n_up', 'n_forward'},
                doc = 'Whether the block at an offset from the drone is the ' ..
                    'one named.',
                note = 'The offsets are those of `get_block`. True only ' ..
                    'when the block there is exactly the one named: ' ..
                    '`is_block(air)` asks whether the space is empty, ' ..
                    '`is_block(bricks.red)` whether it is a red brick. ' ..
                    'Anything else is false, whatever the reason, so use ' ..
                    '`get_block` to tell the cases apart.'
            }
        }
    }, {
        title = 'Vectors',
        intro = 'A small vector library. See ' ..
            'https://github.com/ISs25u/vector3 for the full list of methods, ' ..
            'reading `vector` for `vector3`.',
        entries = {
            {
                name = 'vector',
                params = {'x', 'y', 'z'},
                doc = 'Make a vector. Also carries the library\'s ' ..
                    'constructors, such as vector.fromPolar.',
                note = 'Vectors support `+ - * /`, and methods including ' ..
                    '`:length()`, `:norm()`, `:dot(v)`, `:cross(v)`, ' ..
                    '`:rotate_around(axis, angle)`, `:round()` and ' ..
                    '`:unpack()`.'
            }
        }
    }, {
        title = 'Math',
        entries = {
            {
                name = 'random',
                params = {'m', 'n'},
                doc = 'A random number. With no arguments, a fraction from 0 ' ..
                    'up to but not including 1. With one, a whole number ' ..
                    'from 1 to m. With two, a whole number from m to n.'
            }, {
                name = 'round',
                params = {'x', 'decimals'},
                doc = 'Round x to this many decimal places (default 0).'
            }, {
                name = 'round0',
                params = {'x'},
                doc = 'Round x to a whole number; short for round(x, 0).'
            }, {name = 'floor', params = {'x'}, doc = 'Round down.'},
            {name = 'ceil', params = {'x'}, doc = 'Round up.'},
            {name = 'abs', params = {'x'}, doc = 'Absolute value.'},
            {name = 'max', params = {'x', '...'}, doc = 'Largest argument.'},
            {name = 'min', params = {'x', '...'}, doc = 'Smallest argument.'},
            {name = 'sqrt', params = {'x'}, doc = 'Square root.'},
            {name = 'pow', params = {'x', 'y'}, doc = 'x to the power of y.'},
            {name = 'exp', params = {'x'}, doc = 'e to the power of x.'},
            {name = 'log', params = {'x'}, doc = 'Natural logarithm.'},
            {name = 'deg', params = {'x'}, doc = 'Radians to degrees.'},
            {name = 'rad', params = {'x'}, doc = 'Degrees to radians.'},
            {name = 'sin', params = {'x'}, doc = 'Sine.'},
            {name = 'cos', params = {'x'}, doc = 'Cosine.'},
            {name = 'tan', params = {'x'}, doc = 'Tangent.'},
            {name = 'asin', params = {'x'}, doc = 'Arc sine.'},
            {name = 'acos', params = {'x'}, doc = 'Arc cosine.'},
            {name = 'atan', params = {'x'}, doc = 'Arc tangent.'},
            {
                name = 'atan2',
                params = {'x', 'y'},
                doc = 'Arc tangent of x/y, using the signs to pick the quadrant.'
            }, {name = 'sinh', params = {'x'}, doc = 'Hyperbolic sine.'},
            {name = 'cosh', params = {'x'}, doc = 'Hyperbolic cosine.'},
            {name = 'tanh', params = {'x'}, doc = 'Hyperbolic tangent.'},
            {name = 'pi', kind = 'value', doc = '3.14159...'},
            {name = 'e', kind = 'value', doc = '2.71828...'}
        }
    }, {
        title = 'Misc',
        entries = {
            {
                name = 'print',
                params = {'message', '...'},
                doc = 'Print every argument in the chat, joined by a space.'
            }, {
                name = 'error',
                params = {'message'},
                doc = 'Stop the program and print a message.'
            }, {name = 'ipairs', params = {'table'}, doc = 'Standard ipairs.'},
            {name = 'pairs', params = {'table'}, doc = 'Standard pairs.'}
        }
    }
}

--------------------------------------------------------------------------------
-- walking
--------------------------------------------------------------------------------

--- Every entry, flattened, in declaration order.
function api.entries()
    local out = {}
    for _, group in ipairs(api.groups) do
        for _, e in ipairs(group.entries) do
            out[#out + 1] = e
        end
    end
    return out
end

--- Every declared name, flattened.
function api.names()
    local out = {}
    for _, e in ipairs(api.entries()) do out[#out + 1] = e.name end
    return out
end

--- The signature as a player writes it: "cube(width, height, length)".
function api.signature(e)
    if e.kind == 'value' then return e.name end
    return e.name .. '(' .. table.concat(e.params or {}, ', ') .. ')'
end

--------------------------------------------------------------------------------
-- building the environment
--------------------------------------------------------------------------------

--- Turn a flat map of name -> implementation into the nested table a program
-- sees, checking it against the description above.
--
-- Names are dotted, so 'centered.vertical.cylinder' becomes a nested table. A
-- name that is both a leaf and a parent - `random` is callable and also carries
-- random.of - gets a __call metamethod.
--
-- Raises if the two sets differ in either direction, so a missing or an
-- undocumented implementation stops the mod loading rather than shipping a
-- reference that lies.
function api.build(impls)

    local missing, undocumented = {}, {}
    local declared = {}

    for _, e in ipairs(api.entries()) do
        declared[e.name] = true
        if impls[e.name] == nil then missing[#missing + 1] = e.name end
    end
    for name in pairs(impls) do
        if not declared[name] then undocumented[#undocumented + 1] = name end
    end

    if #missing > 0 or #undocumented > 0 then
        table.sort(missing)
        table.sort(undocumented)
        local parts = {}
        if #missing > 0 then
            parts[#parts + 1] = 'described in lib/api.lua but not implemented: ' ..
                                    table.concat(missing, ', ')
        end
        if #undocumented > 0 then
            parts[#parts + 1] =
                'implemented but not described in lib/api.lua: ' ..
                    table.concat(undocumented, ', ')
        end
        error('codeblock API mismatch - ' .. table.concat(parts, '; '), 2)
    end

    -- Build the nested shape. Leaves are assigned last so a name that is both a
    -- leaf and a parent keeps its children.
    local root = {}
    local leaves = {}

    local function split(name)
        local parts = {}
        for part in name:gmatch('[^%.]+') do parts[#parts + 1] = part end
        return parts
    end

    for _, e in ipairs(api.entries()) do
        local parts = split(e.name)
        if #parts == 1 then
            leaves[#leaves + 1] = {parts[1], impls[e.name], root}
        else
            local node = root
            for i = 1, #parts - 1 do
                local key = parts[i]
                if node[key] == nil then node[key] = {} end
                node = node[key]
            end
            leaves[#leaves + 1] = {parts[#parts], impls[e.name], node}
        end
    end

    for _, leaf in ipairs(leaves) do
        local key, value, node = leaf[1], leaf[2], leaf[3]
        local existing = node[key]
        if type(existing) == 'table' and type(value) == 'function' then
            -- both a callable and a namespace: random() and random.of()
            node[key] = setmetatable(existing, {
                __call = function(_, ...) return value(...) end
            })
        else
            node[key] = value
        end
    end

    return root
end

--------------------------------------------------------------------------------
-- rendering: in-game help
--------------------------------------------------------------------------------

local function esc_hypertext(s)
    return (s:gsub('\\', '\\\\'):gsub('<', '\\<'):gsub('>', '\\>'))
end

--- The hypertext shown in the editor's API panel.
-- Replaces a hand-written string that had to be updated by hand and had
-- therefore stopped matching the environment.
function api.to_hypertext()
    local out = {}
    for _, group in ipairs(api.groups) do
        out[#out + 1] = ('<b><style font=normal size=16>%s</style></b>'):format(
                            esc_hypertext(group.title))
        for _, e in ipairs(group.entries) do
            local name, args
            if e.kind == 'value' then
                name, args = e.name, nil
            else
                name = e.name
                args = table.concat(e.params or {}, ', ')
            end
            local line = ('<style color=#888888 font=mono size=12>%s</style>')
                             :format(esc_hypertext(name))
            if args then
                line = line ..
                           ('<style font=mono size=12>(</style><style color=#e9c46a font=mono size=12>%s</style><style font=mono size=12>)</style>')
                               :format(esc_hypertext(args))
            end
            out[#out + 1] = '<b>' .. line .. '</b>'
        end
    end
    return table.concat(out, '\n')
end

-- The panel the editor draws, rendered once. lib/blocks.lua renders it again
-- when a game's own block category has been added to the description.
api.html_commands = api.to_hypertext()

--------------------------------------------------------------------------------
-- rendering: Markdown reference
--------------------------------------------------------------------------------

--- The "Lua api" section of doc/api.md.
-- `allowed` is codeblock.config.allowed_blocks, or nil to leave the block
-- listing out. Reading it rather than a copy is what stops the reference
-- drifting from the palette; the categories are listed in the order the config
-- holds them, which is the palette's own, so a category a game adds appears
-- here with no change to this file.
function api.to_markdown(allowed)

    local out = {}
    local function w(s) out[#out + 1] = s or '' end

    w('# Lua api')
    w()
    w('This section is generated from `lib/api.lua` by `scripts/gen_docs.lua`.')
    w('Edit that file rather than this one.')
    w()

    for _, group in ipairs(api.groups) do
        w('## ' .. group.title)
        w()
        if group.intro then
            w(group.intro)
            w()
        end
        -- One block per group, description as an inline comment. This is the
        -- shape doc/api.md already used, and it avoids printing every signature
        -- twice - once as a listing and again as a described bullet.
        w('```lua')
        local width = 0
        for _, e in ipairs(group.entries) do
            local n = #api.signature(e)
            if n > width then width = n end
        end
        for _, e in ipairs(group.entries) do
            local sig = api.signature(e)
            if e.doc and e.doc ~= '' then
                w(sig .. string.rep(' ', width - #sig) .. ' -- ' .. e.doc)
            else
                w(sig)
            end
        end
        w('```')
        w()
        for _, e in ipairs(group.entries) do
            if e.note then
                w(('**`%s`** &mdash; %s'):format(e.name, e.note))
                w()
            end
        end
    end

    if allowed then
        w('# Block types')
        w()
        w('The names each block table holds, in palette order, then the four')
        w('colour-name arrays. The same thirty-five names are the named solid')
        w('colours, `colors.red` and the rest. Generated from')
        w('`lib/config.lua`.')
        w()
        local listed = {}
        for _, category in ipairs(allowed.categories or {}) do
            listed[#listed + 1] = category
        end
        -- The palette views are name lists as much as a category is, and the
        -- point of them is their order, which nothing else here shows. One that
        -- the caller did not supply is skipped by the `names` guard below.
        for _, view in ipairs({'hues', 'light_hues', 'dark_hues', 'neutrals'}) do
            listed[#listed + 1] = {name = view, names = allowed[view]}
        end
        for _, category in ipairs(listed) do
            if category.names then
                w('## `' .. category.name .. '`')
                w()
                w('```lua')
                w(table.concat(category.names, ', '))
                w('```')
                w()
            end
        end
    end

    return table.concat(out, '\n')
end

--- Splice a freshly rendered reference into an existing doc/api.md.
--
-- Everything before the "# Lua api" heading is hand-written prose and is kept
-- exactly; everything from that heading onward is replaced. Returns nil and a
-- reason if the marker is missing, rather than guessing.
api.GENERATED_FROM = '# Lua api'

function api.compose_markdown(current, allowed)
    current = current or ''
    local head = current:match('^(.-)\n' .. api.GENERATED_FROM)
    if not head then
        if current ~= '' then
            return nil, ('no "%s" heading found, refusing to guess where the ' ..
                       'generated section begins'):format(api.GENERATED_FROM)
        end
        head = ''
    end
    return head .. '\n' .. api.to_markdown(allowed) .. '\n'
end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

if rawget(_G, 'codeblock') then codeblock.api = api end

return api
