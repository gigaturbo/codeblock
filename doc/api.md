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
`get_block()` and `is_block()` load it too, and pay the same, because an unloaded
block reads as nothing at all.
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

Leave `block` out and the default block is used: the one chosen in the editor's Settings panel, or grey until a choice is made.

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
colors     -- Solid coloured blocks, indexed by name. A name that does not exist reads as nil and builds your default block instead; the first time a run does that, it says so in the chat.
glass      -- One see-through block per colour, indexed by name.
lamps      -- One glowing block per colour, indexed by name. The light itself is the same whatever the colour.
hues       -- The plain shade of each hue family as an array, in colour-wheel order.
light_hues -- The light shade of each hue family, same order.
dark_hues  -- The dark shade of each hue family, same order.
neutrals   -- The neutrals as an array, white to black.
air        -- Empty space. Place it to carve rather than to build.
```

**`hues`** &mdash; `hues`, `light_hues`, `dark_hues` and `neutrals` are the four ways of walking the palette: which colours, in what order. They hold colour names rather than blocks, and every table above is indexed by the same names, so `glass[hues[1]]` is glass and `lamps[dark_hues[1]]` is a lamp. A name out of one of them is a solid block already, so `place(hues[1])` needs nothing around it. Use them with `ramp.of`.

## Choosing blocks

A `ramp` maps a number onto one table of blocks, so a shape can be coloured by height, distance or anything else that is a number. Values at or below `min` give the first block and those at or above `max` the last; anything outside the range is clamped rather than wrapped. `min` and `max` default to 1 and the number of blocks in the table.

```lua
random.color()                            -- A random solid colour.
random.glass()                            -- A random glass block.
random.lamp()                             -- A random lamp.
ramp.hues(v, min, max)                    -- Map a number onto the hues: a smooth rainbow.
ramp.colors(v, min, max)                  -- Map a number onto the solid colours, in palette order.
ramp.glass(v, min, max)                   -- Map a number onto the glass blocks, in palette order.
ramp.lamps(v, min, max)                   -- Map a number onto the lamps, in palette order.
ramp.of(list, v, min, max)                -- Map a number onto any array: one of the palette orders, or a list you built.
get_block(n_right, n_up, n_forward)       -- The block at an offset from the drone, without moving it.
is_block(block, n_right, n_up, n_forward) -- Whether the block at an offset from the drone is the one named.
```

**`ramp.hues`** &mdash; The one ramp over a whole table that reads as a gradient, because `hues` is one name per family in colour-wheel order. `ramp.colors`, `ramp.glass` and `ramp.lamps` walk light, plain and dark inside each family in turn, so a gradient across one of them strobes; `ramp.of` over a palette order does not.

**`ramp.of`** &mdash; The same mapping as the ramps above, with the list given rather than fixed. `ramp.of(hues, i, 1, n)` walks the colour wheel; the material is whatever you index with the answer, so `glass[ramp.of(dark_hues, i, 1, n)]` is the dark shades in glass. It returns whatever the list holds, so a list of your own works too, and a value that is not a list at all reads as nothing rather than stopping the program.

**`get_block`** &mdash; Each offset defaults to zero, so `get_block()` reads where the drone is and `get_block(0, 0, 1)` reads one step ahead of it. The offsets turn with the drone, the same way `place_relative` does. Three answers: the name of a block the drone could place, `false` for a node it could not, and `nil` where there is no answer at all - map that has never been generated, or a position outside the world.

**`is_block`** &mdash; The offsets are `get_block`'s: each defaults to zero, they turn with the drone, and nothing is moved. True only when the block there is exactly the one named, so `is_block(air)` asks whether the space is empty. Everything else is false - a node no program can place, map that has never been generated, a position outside the world, and a name that does not exist. Use `get_block` to tell those apart.

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

The names each block table holds, in palette order, then the four
palette orders themselves. Generated from `lib/config.lua`.

## `colors`

```lua
white, light_grey, grey, dark_grey, black, light_pink, pink, dark_pink, light_red, red, dark_red, light_orange, orange, dark_orange, light_yellow, yellow, dark_yellow, light_olive, olive, dark_olive, light_lime, lime, dark_lime, light_green, green, dark_green, light_cyan, cyan, dark_cyan, light_blue, blue, dark_blue, light_violet, violet, dark_violet
```

## `glass`

```lua
white, light_grey, grey, dark_grey, black, light_pink, pink, dark_pink, light_red, red, dark_red, light_orange, orange, dark_orange, light_yellow, yellow, dark_yellow, light_olive, olive, dark_olive, light_lime, lime, dark_lime, light_green, green, dark_green, light_cyan, cyan, dark_cyan, light_blue, blue, dark_blue, light_violet, violet, dark_violet
```

## `lamps`

```lua
white, light_grey, grey, dark_grey, black, light_pink, pink, dark_pink, light_red, red, dark_red, light_orange, orange, dark_orange, light_yellow, yellow, dark_yellow, light_olive, olive, dark_olive, light_lime, lime, dark_lime, light_green, green, dark_green, light_cyan, cyan, dark_cyan, light_blue, blue, dark_blue, light_violet, violet, dark_violet
```

## `hues`

```lua
pink, red, orange, yellow, olive, lime, green, cyan, blue, violet
```

## `light_hues`

```lua
light_pink, light_red, light_orange, light_yellow, light_olive, light_lime, light_green, light_cyan, light_blue, light_violet
```

## `dark_hues`

```lua
dark_pink, dark_red, dark_orange, dark_yellow, dark_olive, dark_lime, dark_green, dark_cyan, dark_blue, dark_violet
```

## `neutrals`

```lua
white, light_grey, grey, dark_grey, black
```

