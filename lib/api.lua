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
            'chosen in the editor\'s Settings panel, or stone until a choice ' ..
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
        title = 'Block tables',
        intro = 'Anything taking a `block` argument wants a value from one of ' ..
            'these. The names each table holds are listed under Block types ' ..
            'below.',
        entries = {
            {
                name = 'blocks',
                kind = 'value',
                doc = 'Building blocks, indexed by name.'
            },
            {name = 'plants', kind = 'value', doc = 'Plants, indexed by name.'},
            {
                name = 'wools',
                kind = 'value',
                doc = 'The full wool palette, indexed by name.'
            }, {
                name = 'iwools',
                kind = 'value',
                doc = 'The colourful wools as an array, in rainbow order, ' ..
                    'without white, black or greys.'
            }
        }
    }, {
        title = 'Choosing blocks',
        entries = {
            {
                name = 'random.block',
                params = {},
                doc = 'A random building block.'
            }, {name = 'random.plant', params = {}, doc = 'A random plant.'},
            {name = 'random.wool', params = {}, doc = 'A random wool colour.'},
            {
                name = 'color',
                params = {'v', 'min', 'max'},
                doc = 'Map a number onto the iwools palette.',
                note = 'Values at or below `min` give the first colour and ' ..
                    'those at or above `max` the last; anything outside the ' ..
                    'range is clamped rather than wrapped. `min` and `max` ' ..
                    'default to 1 and 11. Useful for colouring a shape by ' ..
                    'height or distance.'
            }, {
                name = 'get_block',
                params = {},
                doc = 'The block at the drone position, or false if it is ' ..
                    'not one the drone can place.'
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
                doc = 'A random number: no arguments for 0..1, one for 1..m, ' ..
                    'two for m..n.'
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
                params = {'message'},
                doc = 'Print a message in the chat.'
            }, {
                name = 'error',
                params = {'message'},
                doc = 'Stop the program and print a message.'
            }, {name = 'ipairs', params = {'table'}, doc = 'Standard ipairs.'},
            {name = 'pairs', params = {'table'}, doc = 'Standard pairs.'}, {
                name = 'table.randomizer',
                params = {'t'},
                doc = 'Return a function that picks a random value from t.'
            }
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
-- random.block - gets a __call metamethod.
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
            -- both a callable and a namespace: random() and random.block()
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

--------------------------------------------------------------------------------
-- rendering: Markdown reference
--------------------------------------------------------------------------------

--- The "Lua api" section of doc/api.md.
-- `block_tables` is an optional map of table name to a list of the names it
-- holds, so the reference can list the real block names from the config rather
-- than a copy that drifts.
function api.to_markdown(block_tables)

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

    if block_tables then
        w('# Block types')
        w()
        w('The names each block table holds. Generated from `lib/config.lua`.')
        w()
        local order = {'blocks', 'plants', 'wools', 'iwools'}
        for _, tname in ipairs(order) do
            local list = block_tables[tname]
            if list then
                w('## `' .. tname .. '`')
                w()
                w('```lua')
                w(table.concat(list, ', '))
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

function api.compose_markdown(current, block_tables)
    current = current or ''
    local head = current:match('^(.-)\n' .. api.GENERATED_FROM)
    if not head then
        if current ~= '' then
            return nil, ('no "%s" heading found, refusing to guess where the ' ..
                       'generated section begins'):format(api.GENERATED_FROM)
        end
        head = ''
    end
    return head .. '\n' .. api.to_markdown(block_tables) .. '\n'
end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

if rawget(_G, 'codeblock') then codeblock.api = api end

return api
