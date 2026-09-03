# Codelevel

Drone capacities depends on the user's _codelevel_ which can be set with the `/codeblock level` [command](https://github.com/gigaturbo/codeblock#chat-commands) (see below). High codelevels should be given carefully to users as program could overload the server and crash it. A new player starts at codelevel `3` in singleplayer, where the player is the administrator but has no use for the widest ceilings there are, and at `2` on a server — set `codeblock_default_auth_level` to override either.

| codelevel         | 1 (novice) | 2 (intermediate) | 3 (advanced) | 4 (poweruser) | description                                                    |
|-------------------|------------|------------------|--------------|---------------|----------------------------------------------------------------|
| pace_ms           |        250 |                5 |            0 |             0 | wait after each drone command, in milliseconds (0 = no wait)   |
| step_budget_us    |       1000 |             2000 |         4000 |          8000 | time (µs) one drone may spend running per server step          |
| max_runtime_s     |         30 |               60 |          120 |           300 | total running time (s) one program gets                        |
| max_nodes_written |        1e5 |              5e5 |          1e6 |           5e7 | nodes one program may write, and so the size of a single shape |
| map_memory_mb     |          8 |               32 |           64 |           128 | map footprint (MB) one program may hold at once                |
| heap_mb           |         16 |               64 |          128 |           512 | Lua heap growth (MB) one program run may cause                 |
| max_string_mb     |          1 |                8 |           16 |            64 | size (MB) of the largest string a single call may produce      |

Every limit above can be changed from the settings menu, under Mods → codeblock,
or by setting it in `minetest.conf` — the names and formats are in
`settingtypes.txt`. Each takes four numbers, one per codelevel. They are read
when the mod loads, so a change needs a restart, and the defaults in
`lib/config.lua` apply to anything left unset.

Each limit stands for a resource the server actually spends: time, nodes written,
map memory, Lua memory. Raising a codelevel buys more of each — and less waiting.

`pace_ms` is the only one that is not a ceiling. The drone waits that long after
every command, which is what makes the lower codelevels slow enough to watch a
loop happen: a beginner sees the drone step and place, one block at a time. It
costs the server nothing — a waiting drone is not running, and does not take a
share of the step budget either. From codelevel 3 up it is zero and the drone
runs as fast as the server has room for.

`max_runtime_s` is the bound on a program that never finishes. It counts time the
drone was actually advanced, not wall-clock time, so waiting for its pace and
sharing a busy server do not eat into it. A program that runs out is stopped with
a message. Nothing limits how many calls or commands a program makes any more:
those were proxies for this.

`sleep()` is the one thing that spends this budget without running: a wait is
charged for its full length when it is asked for. A sleeping drone costs no CPU,
so nothing else could bound it, and a program that waits for ever is the same
runaway as one that loops for ever.

`max_nodes_written` is the build budget, and doubles as the largest shape a
codelevel can place — 1e5 nodes is a 46-node cube or a radius-28 sphere, 5e7 a
368-node cube. Neither a shape's dimensions nor the drone's distance from home is
limited: a big shape is written in slabs of a few thousand nodes with a pause
between them, so it is slow rather than a frozen server, and flying away costs
map memory, which is charged below.

`map_memory_mb` bounds the one resource none of the others can see. Writing a
node needs the mapblock containing it to be in memory, so `place()` loads it
first — without that the write silently does nothing and the build has holes.
Loading pins a 16×16×16 block, 16 KiB, in the server's memory, and may read it
from disk to do so. `heap_mb` cannot see that, because it measures the Lua heap
and a mapblock is not on it; `max_nodes_written` cannot either, because a program
that places one node per mapblock scores the minimum on nodes and the maximum
here.

It is also the one limit a program is not stopped for reaching. The engine
unloads a mapblock nothing has touched for `server_unload_unused_data_timeout`
(29 s by default), so the footprint drains by itself: a program over its ceiling
is made to wait for room instead of being killed. What that bounds in practice is
the rate — 128 MB over 29 s is about 280 mapblocks a second, against the 1700 a
second the engine can serve — so a build spread thinly over the world slows down
rather than failing.

`heap_mb` stops a program that *accumulates* memory — appending to a table in a
loop, building an ever-longer string. It is checked when the drone yields, so it
cannot see inside a single call. The figures are generous because the underlying
measurement covers the whole server's Lua heap, so it is a delta from program
start and other mods' allocations appear in it.

`max_string_mb` covers what that cannot: one call that allocates everything at
once. `("x"):rep(1e9)` is a single call and would allocate a gigabyte before any
yield happened. Only two string methods can turn a small input into a large
output — `rep` and `gsub` — and both refuse a result over this size before
computing it. (`format` cannot: Lua accepts at most two digits of field width, so
`%100d` is already rejected by the language.)

Neither limit can stop a pathological Lua pattern from burning CPU inside a
single `find` or `match` call. That is a known gap.

`step_budget_us` is how long a drone may spend running its program during one
server step. It advances repeatedly until the budget is spent, so throughput
follows the headroom the server has spare rather than the tick rate.

It is a cap rather than an allowance. What a drone actually gets is the smaller of
it and an equal share of `codeblock_server_step_budget_us`, 16000 µs by default,
divided among the drones currently running. So the server's cost does not grow
with the number of players: a second drone halves the share rather than doubling
the bill.

One limit worth knowing: the budget is checked between drone commands and between
the slabs of a shape, never inside one, so a single slab — a few thousand nodes,
around 10 ms — overshoots it.

# Chat commands

Everything the mod offers a player outside the game world is a subcommand of
`/codeblock`. Running it with no subcommand prints the three usages.

In every one, `<playername>` defaults to the caller. Acting on **another** player
requires the `codeblock` privilege (`/grant <user> codeblock`); in singleplayer it
is granted automatically, since the player is the administrator.

## `/codeblock tools [<playername>]`

Puts the **Drone placer** and the **Drone setter** in a player's main inventory.

The mod does not hand these out. A player takes them from the creative inventory
or asks for them here, and this command is the only route in a game with no
creative inventory.

Whichever of the two tools the player is not already carrying is added, and
nothing is ever cleared. A tool parked in the craft grid counts as carried, so
running this twice does not produce duplicates. With no free slot it refuses and
says so rather than making room.

Both tools can be dropped and thrown away; this command is how you get them back.

## `/codeblock level [<playername>] <1-4>`

Sets a player's codelevel.

Requires the `codeblock` privilege **including for your own codelevel** — codelevel
is what bounds how much work a program may do, so being able to raise your own
would defeat the limits.

## `/codeblock generate [<playername>]`

Writes any of the bundled example programs that are **missing** from a player's
files.

Files that already exist are left untouched, and the reply reports how many were
written and how many were already present. To get a pristine copy of an example
you have edited, delete it in the editor and run the command again.

# Lua api

This section is generated from `lib/api.lua` by `scripts/gen_docs.lua`.
Edit that file rather than this one.

## Moving the drone

The coordinate system is relative to the drone, which faces the direction the player was facing when it was placed. `n` is a whole number of blocks, defaults to 1, and may be negative - `up(-1)` is `down(1)`.

```lua
up(n)                          -- Move n blocks up.
down(n)                        -- Move n blocks down.
forward(n)                     -- Move n blocks forward.
back(n)                        -- Move n blocks backward.
left(n)                        -- Move n blocks left.
right(n)                       -- Move n blocks right.
move(n_right, n_up, n_forward) -- Move on all three axes at once. Each defaults to zero.
```

## Rotating the drone

```lua
turn_right()                    -- Turn a quarter turn right.
turn_left()                     -- Turn a quarter turn left.
turn(n_quarters_anti_clockwise) -- Turn n quarter turns anti-clockwise.
```

## Waiting

A wait costs the program running time, the same budget a long program spends, so a program cannot wait for ever: asking for more than is left stops it there. Nothing else on the server waits - other drones keep building and take the time this one is not using.

```lua
sleep(seconds) -- Pause the drone for this many seconds.
```

**`sleep`** &mdash; Defaults to one second, and fractions are allowed. The server looks at its drones about eleven times a second, so anything shorter than that lasts one look.

## Checkpoints

A checkpoint remembers a position so it can be returned to. Names are strings. The checkpoint `spawn` always exists and is where the drone was placed.

```lua
save(name)                         -- Save the current position under this name.
go(name, n_right, n_up, n_forward) -- Return to a checkpoint, with an optional offset.
```

**`go`** &mdash; Every argument is optional: `go()` is `go('spawn', 0, 0, 0)`.

## Placing one block

Leave `block` out and the default block is used: the one chosen in the editor's Settings panel, or stone until a choice is made.

```lua
place(block)                                                -- Place one block at the drone position.
place_relative(n_right, n_up, n_forward, block, checkpoint) -- Place one block at an offset from a checkpoint.
default_block(block)                                        -- Change the default block for the rest of the program.
```

**`place_relative`** &mdash; `checkpoint` defaults to `spawn`.

**`default_block`** &mdash; Affects every later call that leaves `block` out, shapes included. It lasts until the program ends and does not change the choice saved in the editor.

## Shapes

The drone position is the back-bottom-left of the shape, which extends right, up and forward. `width` runs right, `height` up, `length` forward, and `radius` in the remaining directions. `hollow` defaults to false and `block` to the default block.

```lua
cube(width, height, length, block, hollow)         -- A rectangular box.
sphere(radius, block, hollow)                      -- A sphere.
dome(radius, block, hollow)                        -- The upper half of a sphere.
cylinder(height, radius, block, hollow)            -- A vertical cylinder; short for vertical.cylinder.
vertical.cylinder(height, radius, block, hollow)   -- A cylinder standing on its end.
horizontal.cylinder(length, radius, block, hollow) -- A cylinder lying along the forward axis.
```

## Centered shapes

The same shapes, positioned so the drone is at their centre rather than a corner. For a dome the drone is at the centre of its flat base. `width` runs left-right, `height` up-down and `length` forward-backward.

```lua
centered.cube(width, height, length, block, hollow)         -- A box centred on the drone.
centered.sphere(radius, block, hollow)                      -- A sphere centred on the drone.
centered.dome(radius, block, hollow)                        -- A dome centred on the drone.
centered.cylinder(height, radius, block, hollow)            -- Short for centered.vertical.cylinder.
centered.vertical.cylinder(height, radius, block, hollow)   -- A standing cylinder centred on the drone.
centered.horizontal.cylinder(length, radius, block, hollow) -- A lying cylinder centred on the drone.
```

## Block tables

Anything taking a `block` argument wants a value from one of these. The names each table holds are listed under Block types below.

```lua
blocks -- Building blocks, indexed by name.
plants -- Plants, indexed by name.
wools  -- The full wool palette, indexed by name.
iwools -- The colourful wools as an array, in rainbow order, without white, black or greys.
```

## Choosing blocks

```lua
random.block()     -- A random building block.
random.plant()     -- A random plant.
random.wool()      -- A random wool colour.
color(v, min, max) -- Map a number onto the iwools palette.
get_block()        -- The block at the drone position, or false if it is not one the drone can place.
```

**`color`** &mdash; Values at or below `min` give the first colour and those at or above `max` the last; anything outside the range is clamped rather than wrapped. `min` and `max` default to 1 and 11. Useful for colouring a shape by height or distance.

## Vectors

A small vector library. See https://github.com/ISs25u/vector3 for the full list of methods, reading `vector` for `vector3`.

```lua
vector(x, y, z) -- Make a vector. Also carries the library's constructors, such as vector.fromPolar.
```

**`vector`** &mdash; Vectors support `+ - * /`, and methods including `:length()`, `:norm()`, `:dot(v)`, `:cross(v)`, `:rotate_around(axis, angle)`, `:round()` and `:unpack()`.

## Math

```lua
random(m, n)       -- A random number: no arguments for 0..1, one for 1..m, two for m..n.
round(x, decimals) -- Round x to this many decimal places (default 0).
round0(x)          -- Round x to a whole number; short for round(x, 0).
floor(x)           -- Round down.
ceil(x)            -- Round up.
abs(x)             -- Absolute value.
max(x, ...)        -- Largest argument.
min(x, ...)        -- Smallest argument.
sqrt(x)            -- Square root.
pow(x, y)          -- x to the power of y.
exp(x)             -- e to the power of x.
log(x)             -- Natural logarithm.
deg(x)             -- Radians to degrees.
rad(x)             -- Degrees to radians.
sin(x)             -- Sine.
cos(x)             -- Cosine.
tan(x)             -- Tangent.
asin(x)            -- Arc sine.
acos(x)            -- Arc cosine.
atan(x)            -- Arc tangent.
atan2(x, y)        -- Arc tangent of x/y, using the signs to pick the quadrant.
sinh(x)            -- Hyperbolic sine.
cosh(x)            -- Hyperbolic cosine.
tanh(x)            -- Hyperbolic tangent.
pi                 -- 3.14159...
e                  -- 2.71828...
```

## Misc

```lua
print(message)      -- Print a message in the chat.
error(message)      -- Stop the program and print a message.
ipairs(table)       -- Standard ipairs.
pairs(table)        -- Standard pairs.
table.randomizer(t) -- Return a function that picks a random value from t.
```

# Block types

The names each block table holds. Generated from `lib/config.lua`.

## `blocks`

```lua
acacia_bush_leaves, acacia_leaves, acacia_tree, acacia_wood, air, aspen_leaves, aspen_tree, aspen_wood, bookshelf, brick, bronzeblock, bush_leaves, cactus, clay, coalblock, cobble, copperblock, desert_cobble, desert_sandstone, desert_sandstone_block, desert_sandstone_brick, desert_stone, desert_stone_block, desert_stonebrick, diamondblock, dirt, dirt_with_coniferous_litter, dirt_with_dry_grass, dirt_with_grass, dirt_with_rainforest_litter, dirt_with_snow, dry_dirt, dry_dirt_with_dry_grass, glass, goldblock, ice, jungleleaves, jungletree, junglewood, leaves, mese, meselamp, mossycobble, obsidian, obsidian_block, obsidian_glass, obsidianbrick, permafrost, permafrost_with_moss, permafrost_with_stones, pine_bush_needles, pine_needles, pine_tree, pine_wood, sandstone, sandstone_block, sandstonebrick, silver_sandstone, silver_sandstone_block, silver_sandstone_brick, snowblock, steelblock, stone, stone_block, stone_with_coal, stone_with_copper, stone_with_diamond, stone_with_gold, stone_with_iron, stone_with_mese, stone_with_tin, stonebrick, tinblock, tree, wood
```

## `plants`

```lua
acacia_bush_sapling, acacia_bush_stem, acacia_sapling, apple, aspen_sapling, bush_sapling, bush_stem, dry_grass_1, dry_grass_2, dry_grass_3, dry_grass_4, dry_grass_5, dry_shrub, emergent_jungle_sapling, fern_1, fern_2, fern_3, grass_1, grass_2, grass_3, grass_4, grass_5, junglegrass, junglesapling, large_cactus_seedling, marram_grass_1, marram_grass_2, marram_grass_3, pine_bush_sapling, pine_bush_stem, pine_sapling, sapling
```

## `wools`

```lua
black, blue, brown, cyan, dark_green, dark_grey, green, grey, magenta, orange, pink, red, violet, white, yellow
```

## `iwools`

```lua
red, brown, orange, yellow, green, dark_green, cyan, blue, violet, magenta, pink
```

