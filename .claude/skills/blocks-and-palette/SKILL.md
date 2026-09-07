---
name: blocks-and-palette
description: The CodeBlock mod's own 105 nodes and 35 colours — how lib/nodes.lua tints three shared tiles, how lib/config.lua derives the palette and its four views from two literals, how a game registers its own category through codeblock.register_blocks, how the ramps map a number onto a list, and what get_block answers.
when_to_use: Before editing lib/nodes.lua, lib/blocks.lua, the palette or category parts of lib/config.lua, or the block, ramp and get_block implementations in lib/sandbox.lua and lib/commands.lua. Also when adding a colour, a category, a view or a top-level API name, and when a game-registered node is not resolving.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# The mod's blocks

**105 nodes, 35 colours** — each colour a solid, a glass and a lamp, built in
`lib/nodes.lua` from **three** shared tiles. `mod.conf` is `depends = vector3`
and nothing else.

**Tint with `^[multiply:#rrggbb`, never `^[colorize:<hex>:255`.** At ratio 255
colorize replaces every pixel, which throws the glass and lamp tiles away and
opaques the glass.

**The solid tile is flat pure white**, so `^[multiply` reproduces the palette hex
exactly. The glass tile keeps its frame and highlight;
`textures/codeblock_lamp.png` is a faint grid, ground 252 with lines at 234 every
8 px, so a wall of lamps reads as blocks rather than one slab. The cost is that a
wall of one solid colour has **no node-edge definition at all** (`F12-2`).

**None of the 105 nodes has a `sounds` field, deliberately** — every
`node_sound_*_defaults()` belongs to a game.

# The palette and its views

**`lib/config.lua` holds two literals — `neutrals` and `families` — and derives
`palette` and the four palette views from them** (`F12`, `F14`). Five neutrals
light to dark, then ten hue families in colour-wheel order, each
`light_x` / `x` / `dark_x`.

**The views are ordered arrays of short colour names**: `hues` the plain shade of
each family, `light_hues` and `dark_hues` the other two tiers in the same wheel
order, `neutrals` the five greys light to dark. **Do not flatten this back into
one list** — a flat list with an index range for the neutrals cannot express *the
plain shade of each family*. `fallback` is `grey`.

**A view is one axis of the palette and a category is the other** (`F14`). Every
category is indexed by the same short name, so `glass[h]` and `lamps[h]` turn any
view into a glass or a lamp gradient and **four arrays give twelve gradients** —
which is why there is no `dark_glass` array and must not be one. For `colors` the
short name **is** the flat key, so `place(dark_hues[i])` needs nothing around it.

**The views reach the sandbox through `snapshot`** like every other table, and
none of them reports an unknown name: reading past the end of an array is a
legitimate thing for a program to do.

**Derive every view in `config.add_category` and nowhere else.** A list built at
load time in a reader is a snapshot taken before any game has registered
anything. Three such snapshots existed and all three were invisible to the suite;
`rev_blocks` in `lib/commands.lua` was a live defect, `get_block()` answering
`false` for every game-registered node. The views are mutated and never replaced,
so a local reference still sees a late arrival.

# A game's own blocks

**A category is a namespace and the flat key space behind it is not.** `place()`
takes one string, so `colors.red`, `glass.red` and `lamps.red` resolve to the
unique keys `red`, `red_glass` and `red_lamp`. A game's category is namespaced —
`wool.red` — so a game can never shadow one of the mod's own.

**Read a category through `allowed_blocks.by_name[name].spelled`, never by
indexing the structure table.** A game chooses its own category name, so a name
indexing `allowed_blocks` directly could be `all` or `fallback` and overwrite the
map every write path resolves through.

**`codeblock.register_blocks` is queued at the call and validated at
`register_on_mods_loaded`** (`lib/blocks.lua`). That ordering is the constraint:
`core.registered_nodes` is complete only then, so checking at the call would
refuse a node belonging to a mod that loads later.

**A refusal is `core.log('error', ...)` naming the calling mod — never a raise**,
because a game's typo must not abort the server. A call arriving after the seal
is refused rather than warned about.

**Its taken-set is seeded from `api.names()`, so every top-level API name is a
category name a game cannot have.** That is correct, but it means **adding a
top-level name takes a name out of every game's namespace**, which is not visible
in `lib/blocks.lua`. `F14` took three at once: `light_hues`, `dark_hues` and
`neutrals`. Weigh that when adding a name, and say so in `CHANGELOG.md`, where a
game author reads it.

**Nothing under `tests/game/mods/` may call `codeblock.register_blocks`.** That
directory is all-enabled, so such a mod would change `api.names()` and the
palette underneath every spec run. The mod exercising the game-author path lives
outside this repository and unversioned at `../codeblock-test-mod`;
`PLAYTEST.md` `F11-10` describes what it registers in enough detail to rebuild
it.

# The ramps

**One ramp per category, `ramp.hues`, and `ramp.of` over any array** (`F12`,
`F14`).

**`ramp_pick(list, v, m, M)` in `lib/sandbox.lua` is the whole of the mapping.**
`ramp_over(list)` binds it to one list, and **`ramp.of` is `ramp_pick` itself**,
so the generic ramp and the per-category ones cannot drift apart. Do not
reimplement either against the other.

**A per-category ramp is built once per category per run** from `add_category`'s
`keys` view, so a game's category gets one on the same terms as the mod's own. It
is appended to `lib/api.lua`'s *Choosing blocks* group by `lib/blocks.lua`, which
is why that group carries an `id`.

**Out of range clamps, never wraps.** A non-number `v` or a zero-width range
gives the first entry; a non-table or empty list answers `nil`. An arithmetic
accident must not stop a program.

**`color(v, min, max)` is gone with no alias.**

**Only `ramp.hues` and `ramp.of` over a palette view are gradients.**
`ramp.colors`, `ramp.glass` and `ramp.lamps` walk light/plain/dark inside each
family and strobe. That is a consequence of one ramp per category, not a defect.

# `get_block`

**`get_block(n_right, n_up, n_forward)` reads without moving the drone**, the
offsets rotated by its facing like `place_relative`.

**It calls `codeblock.cost.load_block`** — shared with `place_block`, memo still
per-resume — because `get_node` on a block that is not in server memory answers
`ignore`, which is indistinguishable from map that does not exist.

**Three answers**: a block name, `false` for a node no program can place, `nil`
for map that was never generated or a position outside the world. **`nil` is
permanent**: `load_area` does not run mapgen.

**The edge is one predicate, `inside_world`**, shared with `check_inside_world`
so the query's edge and the raise's cannot drift. The asymmetry is deliberate — a
write raises out of the world while a read answers `nil` — because raising on the
query a player uses to look before they leap is the wrong shape. **Do not turn it
into a raise.**

## Related

- **`program-pipeline`** — the per-resume memo `load_block` depends on, and what a
  write costs.
- **`generated-files`** — adding a name to `lib/api.lua` and what it drags with it.
