# Roadmap — CodeBlock

What to do next, and **what has been agreed**. The decisions below are recorded
nowhere else. Findings are in `AUDIT.md`, manual checks in `PLAYTEST.md`,
unscheduled intentions in `TODO.md`.

Ids: phases `Phase 0`–`Phase 10`, features `F1`–`F15`, findings `B`/`S`/`C`/`A`.
**Nothing is ever renumbered.**

Three releases: **`Phase 8` is v1.0.0**, **`Phase 9` is v1.x.y**, **`Phase 10`
is v2.0.0 and holds `F6` alone**.

## Now

**Answer the `S8` copy question, answer the fixture question, then push.**
`S8` is medium and latent on `vector3` v2.0.x, reachable on v1.5. Whether to
adopt the per-constant `vector3(c)` copy is an open decision, set out under
*Finalising v1.0.0*. The fixture question is what `tests/game/mods/vector3`
should pin now that a player may have three versions.

**`S9` is closed.** `vector3` v2.0.2 separates the metatable from the methods
table, and the submodule is bumped to `fc8a5b8`. It is still live for a player
on v1.5 or v2.0.1, which is what the support matrix in the `run-tests` skill is
for.

**Twenty-two commits are unpushed.** `origin/master` is `65b4c46`; CI has seen
no part of `F11`, `F12`, `F13`, `F14`, `B53`, `C23`, `B54` or either `vector3`
bump. Take the count from `git rev-list --count origin/master..HEAD`, never from
counting hashes.

**Every feature in `Phase 8` has shipped and been played.** `PLAYTEST.md`
carries no fail and two unrun checks, `F-6` and `F-7`.

## Finalising v1.0.0

Steps 7–11 are the `release-codeblock` skill's procedure and are not restated.

1. **Decide whether to adopt the per-constant copy for `S8`** — replace
   `snapshot_module`'s shallow leaf with `vector3(c)`, fourteen constructions
   per program start. Probe-verified on v1.5 and v2.0.2. **Open, not settled.**
   (`S8`)
   - **For:** it is the only thing that closes `S8` for a player on **v1.5**,
     where the finding is reachable rather than latent and the freeze does
     nothing. It also restores `dir = vector.one; dir.x = -1`, the idiom v2.0's
     freeze broke and the author's own `game.lua` used. The cost is fourteen
     constructions beside a disk read.
   - **Against:** `vector.one` would then be writable inside codeblock and
     frozen everywhere else, so a player reading `vector3`'s own documentation
     gets a different answer from the one codeblock gives.
2. **Decide what the test fixture pins** — newest, oldest supported, or a
   documented floor. Luanti has no dependency version mechanism, and there are
   now three releases in the wild. (`S8`)
3. **Push.** The one item that can fail rather than merely take time.
4. **Fix `README.md`.** Line 10's *"works in any game that provides the blocks
   it places"* is false and backwards since `d075742`; add a short **For game
   authors** section for `codeblock.register_blocks`; the ContentDB URLs are on
   the pre-rename `content.minetest.net`; line 23 reads *"ant its dependencies"*
   and there is now one. (`C19`, `F10`, `F11`)
5. **Upload the new screenshots to the ContentDB page** — it loads them from raw
   GitHub URLs on `master`, so the new names go up and the dropped 2021 file
   comes off. (`C19`)
6. **Run playtests `F-6` and `F-7`**, both unrun. (`S8`, `C23`)
7. **Re-run `R2`** on the archive built from the release tag, not `HEAD`. Stale
   since `7c5bceb`, before `F4`, `F11`'s textures and `.gitattributes`. Install
   it in a game that is not `codecube`. (`C16`, `C10`)
8. **`release-check`**, and do not start the tag until it says ready.
9. **Strike what the release closed** from `ROADMAP.md` and `TODO.md`, confirm
   the `vector3` submodule commit is pushed, commit, push, tag `v1.0.0`.
10. **Upload to ContentDB**, long description from the regenerated `.cdb.json`.
11. **Configure the release webhook** — trigger **Branch or tag creation**.

Done and not repeated here: `CHANGELOG.md` is the heading alone, `CONTENTDB.md`
was corrected at `c2e541f`, `settingtypes.txt`'s generator landed, `B47` shipped
mitigated, and `B48`, `B49`, `B50`, `B51`, `B52`, `B53`, `B54`, `C21`, `C22`,
`C23` and `F10`–`F14` are all committed with their playtests run.

**After the tag.** `Phase 9` opens on what comes back from players. `codecube`
adopts the release on its own schedule and must set `codeblock_flat_sky = true`
in its own `minetest.conf` (`C18`). `Phase 10` needs `F6`'s four obstacles
answered in writing before any code.

## Milestones

| Phase | Goal | State | Closed |
|---|---|---|---|
| 0 | Make change safe | done | 2/2 |
| 1 | Ship the compliance fixes | done | 4/4 |
| 2 | Rewrite the sandbox preprocessor | done | 11/11 |
| 3 | Replace ActiveFormspecs | done | 3/3 |
| 4 | Performance | done | 4/4 |
| 5 | Limits that track real load | done | 4/4 |
| 6 | Limits for what the server spends | done | 3/3 |
| 7 | Clear the way for features | done | 26/26 |
| 8 | Features for v1.0.0 | in progress | 12/12 features; `S8`, `C24`, `A17`, `A18` open |
| 9 | v1.x.y — after the release | not started | 0/1 |
| 10 | v2.0.0 — the Blockly editor | not started | 0/1 |

Findings by phase: 0 (`C8`, `A12`); 1 (`C1`, `B5`, `B8`, `B9`); 2 (`B1`–`B4`,
`B6`, `B23`, `S1`–`S4`, `A10`); 3 (`A1`, `A2`, `B22`); 4 (`A5`, `B12`, `A4`,
`A15`); 5 (`S5`, `S6`, `C7`, `C13`, at `43e95a8`); 6 (`B25`, `B26`, `C14`, at
`2647228`); 7 (`A3`, `A6`, `A9`, `A11`, `A16`, `C6`, `C10`–`C12`, `B7`, `B10`,
`B11`, `B13`–`B18`, `B21`, `B27`–`B32`, `C16`, `742a1ca`–`191b533`); 9 (`C24`);
10 (`F6`).

**Done through Phase 7 means findings closed and gates green, not played.**
Phase 8's playtests have since found fifteen defects in code those phases called
done — `B36`–`B44`, `C17`, `C18`, `S7`, `B50`–`B52` — and all fifteen are fixed
and played.

**Phase 8 open findings: `C24` and `S8`.** `S8` is latent on `vector3` v2.0.x
and reachable on v1.5, and its remaining question is the author's; `C24` is
queued for `Phase 9`. `S9` closed with the v2.0.2 bump. `A17` and `A18` are low
and pre-existing; `A17` wants the author's decision, not a cleanup. `B10`'s refusal is out of the phase rather
than done — its check was removed as untestable and reaching it needs a way to
observe the server releasing a mapblock.

**Phase 9 holds one item:** give CI a job that boots the engine, so the three
in-engine-only specs and every engine-guarded case are run by something other
than a local `run_tests.ps1` (`C24`). Closing it means a CI job that starts
Luanti, or `lfs` for one directory enumeration — not a dependency worth adding.
Otherwise deliberately empty: a phase for what comes back from players is worth
more empty than filled in advance.

## The features

A shipped entry is one line. What was load-bearing in it is under *Other
decisions*. `F6` and `F15` describe work not done and keep their shape.

| Id | Size | State | What it is |
|---|---|---|---|
| `F1` | small | shipped `500dd85` | A per-player default block, picked in the editor's Settings panel; `default_block(block)` overrides it for one run. |
| `F2` | small | shipped `dee0bc7` | *Create a copy* writes what is on screen to a derived name and opens it; the file list sorts `foo_2` before `foo_10`. |
| `F3` | medium | shipped `90cfb70` | `sleep(seconds)` parks the drone and hands the step back. Defaults to one second, takes fractions. |
| `F4` | large | shipped `729c255` | A live HUD read-out while a program runs, and a formspec panel with the per-limit breakdown and the buttons. |
| `F5` | large | dropped 2026-08-29 | Change a codelevel mid-run. Cut unbuilt by the author — *"not very interesting in the end."* |
| `F6` | large | planned, `Phase 10` | Blockly web-based editor. See below. |
| `F7` | small | shipped `afbe504` | A tab whose buffer differs from what was last written gets a trailing `*`. |
| `F8` | medium | shipped `d619fba`, revised `60dc8dd` | Made the drone panel readable: three hard-limit rows, coloured percentages, one destructive button. |
| `F9` | small | shipped `8869d8c`, revised `cd13414` | The state and the run's clock time in the same words on both surfaces. |
| `F10` | medium | shipped `b23a8bc` | The mod stops imposing itself: no tool handout, no privilege grant, `/codeblock tools`, `level`, `generate`. |
| `F11` | large | shipped `d075742` + `6126abe` | The mod registers its own nodes and drops `default` and `wool`; a game adds a category of its own. |
| `F12` | large | shipped `01f9641` (examples `b752ea3`) | 35 colours, 105 nodes, one `ramp` per category, `get_block` relative coordinates. |
| `F13` | small | shipped `4450ce1` | `is_block(block, n_right, n_up, n_forward)`, the predicate form of `get_block`. Closed `C22` in the same commit. |
| `F14` | small | shipped `e3e2178` | `light_hues`, `dark_hues`, `neutrals` and `ramp.of(list, v, min, max)`. |
| `F15` | large | shaped, not scheduled | `colorhex("#F7A8E7")`. See below. |

### F6 · Phase 10 / v2.0.0 · planned — Blockly web-based editor

Build programs by dragging blocks in a browser instead of typing Lua. A major
version because it is the change most likely to break how a program is stored
and edited. The author's framing is the point: *"Blockly will be 2.0.0 so I have
time to plan and think."* **Do not start building it because the phase exists.**

**Four obstacles, none answered.**

- **This mod has no HTTP allowance and cannot give itself one.**
  `core.request_http_api` returns a table only for a mod named in the server's
  `secure.http_mods` or `secure.trusted_mods`. **A feature that silently does
  nothing on a correctly configured server is worse than one that is absent.**
- **Mod security blocks the write side.** Generated Lua lands in the player's
  file area through `lib/filesystem.lua`, which has no spec coverage.
- **The assets have to come from somewhere.** Either a page hosted elsewhere — a
  third-party runtime dependency for an offline game, and an AGPL-3.0-only
  licensing and privacy question — or an in-tree server this mod does not have.
- **What would settle feasibility:** one written answer to *where do the assets
  live and who allows the HTTP call*, before any code.

### F15 · large · shaped 2026-09-07, not scheduled — `colorhex`, a palette node

**Feasible, but not as an arbitrary colour.** There is no runtime node
registration in Luanti, so a hex nobody anticipated cannot become a node. The
engine offers `paramtype2 = "color"` plus a 256-pixel `palette` texture — one
node carrying 256 colours indexed by `param2` (5.17.0 `lua_api.md` line 1182).
So `colorhex` **snaps to the nearest of 256**, and its name and documentation
must say *nearest*.

**Plain `color` is the right paramtype2.** `colorwallmounted` gives 32 colours,
`colorfacedir` 8, `color4dir` 64; these nodes need no rotation, so all eight
bits go to colour.

**It fits this mod.** The solid tile is already flat pure white, which is
exactly what a palette tints. It is additive — three nodes and one PNG, the 105
stay — so no saved program and no existing world breaks.

**What it costs.** `allowed_blocks.all` stops being name → itemstring, so every
write path changes shape. `lib/shapes.lua` is the bulk of it: a second full-size
`set_param2_data` array per slab, in the one path that has to stay fast.
`get_block` and `is_block` reverse-look-up through `by_node[itemstring]`, which
cannot tell 256 colours apart, so both must read `param2`. The block picker
cannot enumerate 256 × 3. `lib/cost.lua:236` is trivial by comparison.

**Two questions open on purpose.** Which 256 colours — a colour cube, a
greyscale allocation, or hand-tuned. And how the value reaches `place()`, whose
one-string contract is load-bearing; one candidate is `colorhex` returning the
normalised hex string itself, every write path recognising a hex-shaped key
before consulting `all`, which would make `place('#F7A8E7')` work directly.

## Other decisions worth not re-litigating

### Dependencies and the sandbox

- **`S8`'s reachable half was closed by freezing `vector3`'s constants,
  upstream.** Writing to an exported constant raises `read only` from v2.0. `S8`
  itself stays open: `env.snapshot` is still shallow, and the freeze does
  nothing on v1.5.
- **Do not re-propose deep-copying a constant with
  `setmetatable(copy, getmetatable(v))`.** Against a frozen constant it produces
  an empty table aliased to the original, so it changes nothing while looking
  fixed. `AUDIT.md`'s `S8` entry carries the three probe readings.
- **`S9` was fixed upstream, not here.** `vector3` v2.0.2 puts `__index` and
  every metamethod on a separate `meta` table, so `v.__index` reads nil. The
  submodule is at `fc8a5b8`.
- **Write-protecting `vector3`'s metatable from inside this mod was refused.**
  Sealing `getmetatable(vector3.one)` at load is `C18`'s mistake on another
  author's package, and every other mod using the global would be subject to it.
- **Leave-and-document was rejected for both `S8` and `S9`.** `S8` crosses to
  other players and `S9` to other mods, so neither is a limitation a player
  could work around.
- **What the test fixture pins is open**, not settled by either bump. It is a
  question under *Finalising v1.0.0*, not a decision.
- **An example copies with the constructor, not `clone()`.**
  `lib/examples/game.lua` reads `dir = vector(1, 1, 1)`. The constructor is what
  `lib/api.lua` documents, it matches the file's own `vector(1, 0, 1)`, and
  *reach for a named constant and remember to copy it* would teach the habit
  that caused the defect.
- **`lib/examples/game.lua` is tracked and ships** (`63c3c33`). Two properties
  are intended, not oversights: it is the only shipped example that never
  terminates, ending in `while 1 == 1 do`, and its `sleep(0.03)` is in the
  moving branch only, so a bounce runs at full speed.

### The palette and a game's blocks

- **`default` and `wool` are dropped outright, not made optional.** Optional
  dependencies would make the palette vary by game, so a program would stop
  meaning the same thing everywhere and `doc/api.md` would describe a palette
  that may not exist. **For a mod whose artefact is a shared program,
  portability beats range.** Dropping `wool` only defers the question rather
  than settling it.
- **The palette is hand-picked and ordered by hue.** Not a computed hue × shade
  grid — hand-picked names read better in a program. The order is load-bearing:
  a ramp maps a number onto it, so a gradient must read as a rainbow.
- **Every family's mid-tone carries the plain word** — `red`, `yellow`, not
  `crimson`, `gold`. The obvious name for a colour must exist and must be the
  middle of its family, light / plain / dark. `F12` made it mechanical:
  `light_x` / `x` / `dark_x`.
- **The neutrals stay five.** Ten greys were asked for and declined after the
  `F15` feasibility: a 256-colour palette node gives a smooth greyscale and
  every other colour with it. Both rejected schemes: `grey_1`…`grey_10` with the
  five existing names as aliases onto the same flat keys, which costs
  `add_category` an alias concept; and ten hand-picked English names, which have
  **no guessable order**. Either way ten *even* steps moves the existing hexes,
  so `colors.grey` would change shade in worlds already built.
- **One node definition per colour, not a `param2` palette.** Neither write path
  carries `param2` today — `shapes.lua` writes `data[i] = id`, `cost.lua` writes
  `set_node{name = block}` — so a definition per colour costs nothing.
- **`^[multiply:#rrggbb`, never `^[colorize:<hex>:255`.** At ratio 255 colorize
  replaces every pixel and throws the tile away; multiply scales RGB per pixel
  and leaves alpha alone, which is what keeps the glass transparent. Switching
  back would opaque the glass and flatten the lamps in one edit.
- **The solid tile is flat pure white**, so `^[multiply` reproduces each palette
  hex exactly. **Do not put a grain back on the solids** — it would cost the
  exact hex. `F12-2` judged the flat wall acceptable in a world; the question is
  closed.
- **The five neutral hexes are the project's, not the author's** — `#ffffff
  #c0c0c0 #808080 #404040 #101010`, an even grey ramp chosen because the author
  named the neutrals without values. `F12-1` passed and said nothing against
  them.
- **A palette view is one axis and a block category is the other.** Every
  category is indexed by the same short name, so `glass[h]` and `lamps[h]` turn
  any ordered array into a gradient in any material. **Four arrays give twelve
  gradients with no extra names**, which is why there is no `dark_glass` array.
  Three rejected readings: twelve arrays of blocks (eleven names for what
  indexing does); nested `colors.dark.red` tables (nine names, no ramps,
  `snapshot` and `unknown_block` both learning to nest, and **asymmetric with a
  game-registered category, which has no shade tiers**); a named ramp per tier
  (six names instead of four, and no way to ramp a list the player built).
- **`lib/config.lua` holds two literals, `neutrals` and `families`**, and
  derives `palette` and the four views from them. `F11`'s flat list with an
  index range could not express *the plain shade of each family*. Do not flatten
  it back. `fallback` is still `grey`.
- **Derive every view in `config.add_category` and nowhere else.** A list built
  at load time in a reader is a snapshot taken before any game registered
  anything; three such snapshots existed and `rev_blocks` in `lib/commands.lua`
  was a live defect. The views are mutated and never replaced, so a held
  reference sees a late arrival.
- **The short-name space is flat and unique behind the category tables.**
  `colors.red`, `glass.red` and `lamps.red` resolve to `red`, `red_glass` and
  `red_lamp`, because `place()` takes one string.
- **A registered category gets namespaced flat keys — `wool.red`.** That is what
  makes it impossible for a game to shadow a built-in. A dotted key travels into
  player meta as a `default_block`.
- **Read a category through `allowed_blocks.by_name[name].spelled`, never by
  indexing the structure table.** A game chooses its own category name, so a
  name indexing `allowed_blocks` directly could be `all` or `fallback` and
  overwrite the map every write path resolves through. `by_name` is the one
  table a game-chosen string may index.
- **`air` is a plain top-level name holding `'air'`.** Not `colors.air` and not
  a category of one: it is engine-provided, and a category is a namespace of
  nodes this mod or a game registered.
- **The palette is the mod's own and is not a translation of `wool`'s.** Do not
  size a palette to match another mod's.
- **`register_blocks` is queued at the call and validated at
  `register_on_mods_loaded`.** `core.registered_nodes` is complete only then, so
  checking at the call would refuse a node belonging to a mod that loads later.
  **Do not move the check into `register_blocks`.**
- **A refusal is `core.log('error', …)` naming the calling mod, never a raise**
  — a game's typo must not abort the server. A call after the seal is refused,
  not warned about: it cannot be validated.
- **codeblock validates a game's category and then trusts it.** Valid Lua
  identifier, no collision, registered node, load time. **Policing what the node
  does** was rejected — every guess is a false refusal waiting to happen — and
  **no checks at all** was rejected too, since a typo surfaces later as a broken
  help panel with nothing naming the game that caused it.
- **`mod ?` in a late-call refusal is cosmetic and gets no id.**
  `core.get_current_modname()` answers only while loading, so a call from a
  `core.after` names no mod, and it is not fixable from inside
  `register_blocks`. `F11-10` case 3's recipe says so, so a correct refusal is
  not read as a fail.
- **Adding a top-level API name takes a name out of every game's namespace**,
  because `blocks.install` seeds its taken-set from `api.names()`. `F14` took
  three at once. Weigh it, and say so in `CHANGELOG.md`.
- **None of the 105 nodes has a `sounds` field.** Every
  `node_sound_*_defaults()` belongs to a game, and calling one would put the mod
  back in the position `F11` took it out of.

### The player-facing API

- **`color(v, min, max)` was removed with no alias.** v1.0.0 is untagged and the
  same release already renames every block name a program writes; a name kept
  for compatibility with a version never released is a name kept for ever.
- **Every block category gets a ramp, and only `ramp.hues` is a gradient.**
  `ramp.colors`, `ramp.glass` and `ramp.lamps` walk light, plain and dark inside
  each family and therefore **strobe**. That follows from the author's own
  answer and is said in the help text. **Do not re-order `colors` by lightness
  to fix it** — the picker and the creative inventory read by family.
- **One ramp mapping, not two.** `ramp_pick(list, v, m, M)` is the whole of it;
  `ramp_over(list)` binds it to one list and **`ramp.of` is `ramp_pick`
  itself**, so the generic and per-category ramps cannot drift. Clamps, never
  wraps; a non-number `v` or a zero-width range gives the first entry.
- **`ramp.of` does not validate its list.** A player may ramp a list of their
  own; a non-table or an empty list answers `nil` rather than raising. **An
  arithmetic accident should not stop a program.**
- **`get_block` answers `nil` outside the world; `place` raises there.** Both
  use the one `inside_world` predicate so the edges cannot drift. The asymmetry
  is the point — raising on the query a player uses to look before they leap is
  the wrong shape. **Do not make it symmetrical.**
- **`get_block` loads the map it reads**, through `codeblock.cost.load_block`
  shared with `place_block`, and is charged as footprint. Without the load,
  `get_node` answers `ignore` for anything not in server memory, which is
  indistinguishable from map that does not exist. The memo stays **per-resume**
  and `release()` stays the only `coroutine.yield` in `lib/cost.lua`.
- **`get_block`'s `nil` is permanent.** `core.load_area` does not run mapgen, so
  waiting will not turn a `nil` into a name.
- **`is_block` calls `drone_get_block` and does not read the map itself**, so
  the load, the footprint charge and the one-command cost cannot drift from
  `get_block`'s. `type(block) == 'string'` is load-bearing and pinned by a spec:
  outside the world the read is `nil` and `colors.typo` is `nil` too, so a plain
  `found == block` would report `true` for a misspelt name at a position with no
  answer. A nil block does **not** resolve through the default-block fallback.
- **`unknown_block`'s message says *"the default block is used instead"* even
  under `is_block`, where none is.** Rewording the key would orphan the French
  translation and it is correct for `place()`. Left deliberately.
- **Warn about an unknown block name at the read, not at the call site.** By the
  time a nil reaches `placement` the typed key is gone. At the read it names
  `notablock`, covers every block-taking command including ones added later, and
  fires when the value is stored and placed much later. **The scope is a table
  read only** — `place('notablock')` already raises.
- **A warning, not an error, and once per run.** Erroring would break saved
  programs; one line per run keeps a typo in a loop out of chat. Accepted side
  effect: `if blocks[name] then` as a membership probe costs one chat line per
  run.
- **An `__index` on the copy is not the read-only proxy `S1` rejects.** Proxies
  are refused because Lua 5.1 has no `__pairs` or table `__len`, so they break
  `pairs(colors)` and `#hues`. An `__index` on a real copy fires only for an
  absent key. `hues` is excluded: reading past the end of an array is
  legitimate.
- **`print` is variadic, space-joined and nil-safe.** Read the varargs with
  `select('#', ...)` and `select(i, ...)`, **never** `{...}` with `#` — Lua 5.1
  cannot see a nil in the middle or at the end, and `get_block()` answers `nil`
  over ungenerated map. Join with a **space**, not real Lua's tab: Luanti's chat
  console has no tab stops and the engine wraps on spaces. `print()` alone sends
  a bare `> ` and still costs one command. **`error` was not widened** — real
  Lua's is not variadic either.
- **`sleep`'s wait is charged before it starts**, so `sleep(1e9)` puts the run
  past `max_runtime_s` and reports the same timeout a non-terminating program
  gets. That is `max_runtime_s`'s one exception — it bounds time not spent on
  CPU — and both places it is documented say so. **A per-codelevel cap on
  `sleep` was argued out**: the up-front charge bounds it without another limit,
  mirror row and documented row. **Routing it through `end_command` was argued
  out too**: that writes `wake_at` from `pace_ms` and the last writer wins, and
  **a sleep is not a command** — it pays no pace and is not counted as one.
- **`sleep` must keep yielding through `release()`**, the only `coroutine.yield`
  in `lib/cost.lua`, which clears the mapblock memo first. Yielding any other
  way reintroduces `B25`'s silent lost write.
- **Adding a player-facing name is breaking even when nothing is renamed.**
  `env.new_env` raises on assignment to any API name, so a saved program using
  `sleep` as its own global now fails on that line.
- **A run cut short says *stopped***, matching the panel button's own label. The
  rejected two: *cancelled* names no gesture in the interface, and *stopped
  before finishing* is a sentence where the other outcomes are one word. The
  shared verb with the timeout line was weighed and accepted.
  `register_on_leaveplayer` is the other caller, so a player disconnecting
  mid-run is told *stopped*; nobody sees that line. **Those two are the whole of
  `Drone.on_remove`'s callers — the setter has not been one since `F8`.**
- **The drone record is decoupled from its entity.** The entity is a *view*:
  every drone is advanced from the one globalstep `lib/register.lua` already
  registers, `on_deactivate` sets `drone.obj = nil` rather than ending the run,
  and the object is re-spawned with the **same serial** once the drone's
  mapblock is loaded again — at most once a second, gated on `get_node_or_nil`
  rather than on `add_entity` failing, which would log an engine warning per
  attempt. **There is no `on_step` on the entity and adding one would undo all
  of it.**
- **Two alternatives to that lost, and one earlier rejection was itself wrong.**
  Option A closed neither of `B52`'s cases; option B closed them only by
  forceloading, which spends the game's shared `max_forceloaded_blocks` and runs
  ABMs wherever a drone goes — a `C18`-class imposition on the surrounding game.
  The globalstep driver had been refused once as inverting `A11`'s direction of
  dependency, and **that reading was mistaken**: `register.lua` already owns
  orchestration, so driving the drones from it *follows* `A11`. **Do not
  re-raise it.**
- **Two costs were accepted with that decision, not overlooked.** A far-away
  runaway loses its accidental stop, so `max_nodes_written`, `max_runtime_s` and
  `map_memory_mb` carry the whole load — the last unintended backstop going
  away. And **`/clearobjects` no longer ends a program**: it blanks the view,
  which comes back. Neither is a defect.
- **The default block is read once per run** into `drone.default_block`, so a
  mid-run change cannot split one build between two blocks. The read **validates
  through the palette and falls back**, which is what stops a default arriving
  from a form becoming a way to place any node name. Meta is written **on
  click**, not on form close, which kept the preference immune to `B33`.
- **Block choice is not privileged, unlike everything beside it.** Codelevel is
  privileged because it bounds resource use; stone and red wool cost the server
  the same. `air` is selectable, so a bare `place()` can erase.
- **A `persist` flag on `default_block()` was argued out.** It would be the only
  API call whose effect outlives its run; a shared program would silently
  rewrite the reader's saved preference with no undo; in a loop it is a meta
  write per iteration inside a budgeted run; and no spec could reach it.
  Persistence from a program would get its own command.

### The editor, the panel and the HUD

- **The block picker is a `textlist`, not item rows in a `scroll_container`.**
  The editor formspec is in **legacy coordinates**, where a `scroll_container`
  maps its contents into a different space and clips them, and an
  `item_image_button` inside one gets a hit area that does not match where it is
  drawn. The help panels get away with a container only because `item_image`
  takes no clicks.
- **A legacy button's `W` is not a width.** `src/gui/guiFormSpecMenu.cpp` at
  5.17.0: a `button` gets `W*spacing - (spacing - imgsize)`, a `textlist` gets
  `W*spacing`, with `spacing = imgsize * 5/4`. A button is short by a fixed
  **0.2 units whatever `W` is**. Hence *Create a copy* at `3.2` against a 3-wide
  file list and `+` at `0.95`. `H` is not a height either. `lua_api.md` records
  none of it.
- **One panel, not a second form.** `lib/forms.lua` holds one form per player,
  so a settings form would displace the editor. Every future setting adds a row.
- **The panel tick must check the session is still the panel's** — opening the
  editor over an open panel silently replaces it. Pinned by `forms_spec`.
- **The panel is unconditional and the setter's left click means *drone info*.**
  No two-meanings-by-state: click, get the panel, and if nothing is running it
  says so. **An effect that depends on state the player cannot see is one they
  have to guess at**, and the guess destroyed builds. `on_punch` was rejected —
  a stray punch ending a long build is the objection that moved Stop into the
  panel.
- **One destructive button.** *Cancel* and *Remove drone* were the same
  `Drone.on_remove` call under two labels. **A second button that offers a
  distinction the code does not make is worse than no button.**
- **Stop goes through `Drone.finish`**, the single place an outcome is
  announced, or the player gets two messages or none (`B12`, `B30`). Anything
  reading a drone by name from a callback reads the record fresh and respects
  the **serial guard** (`B29`).
- **Hard limits only, three rows.** The map footprint is a throttle that sits at
  its ceiling by design (`B45`); listing it beside three ceilings that end a run
  invites the misreading. The *Will stop on: …* line is gone — the binding limit
  is the one coloured **amber**, **red** at 80%.
- **Every limit row gets a describing line, as an area label.** The single-line
  version was cut off at the panel edge in French; the engine wraps an area
  label and gives it no scrollbar. This is the panel earning its space over the
  HUD.
- **Long numbers get `K`/`M`/`G`**, threshold 10 000, so a small count still
  reads as a plain integer. Formatting is presentation: `limits.report` and
  `limits.binding` stay pure functions of `caps` and `used` so `limits_spec`
  keeps pinning them.
- **The panel heading is bold with the state coloured** — `running` green,
  `paused` yellow, idle bold and **not** coloured. **One colour meaning two
  things on one form is worse than no colour**, and a third colour for idle
  would quietly change what the colour is for. Built by **concatenation**, not
  from the `S('@1 : @2')` key, because only part of the line is coloured; a
  label's `font` is per element and `halign` works only in the area-label form.
- **The heading carries the run's clock time, bold and immediately after the
  state** — `<program> : <state> (<duration>)`. Asked for as *not bold* and
  reversed within the hour once on screen. **Nothing in Lua can measure rendered
  text**, so *adjacent and differently styled* is the combination that cannot be
  built: as two labels, the x where the state ends varies with the player's font
  and `gui_scaling`. **Do not reintroduce the second label to unbold it.**
- **The clock stops while a run is paused** — *how long has this build taken*,
  not *how long since I started it*. `max_runtime_s` already ignored a pause.
  Reversed from `F9`'s original decision the same day, on seeing it in a world.
- **`Drone.elapsed_us(drone)` is the single answer** both the panel heading and
  the finish message read, so the live figure and the final one cannot disagree.
  `tstart` is shifted forward on resume rather than a `paused_us` accumulated —
  one field to keep correct instead of two. **`Drone.toggle_pause` is the only
  thing that may write `drone.paused`**, `on_run` clearing both being the only
  other writer.
- **A wall-clock duration must not be charged, displayed as, or derived from
  `used.runtime`.** Two numbers about time on one form is what `B46` closed, so
  it is a `get_us_time` delta and the row keeps its line saying it is not clock
  time.
- **The duration is on the panel only, not the HUD.** The corner block is four
  words and a number a line; its first line already carries a filename and a
  state.
- **The HUD is a five-line block** hanging from the top-right, with its own
  short names — `Blocks`, *CPU time*, `Memory`. That duplication is deliberate:
  the panel's row is a heading over a sentence. `CPU` alone read as a load
  percentage, which is `B46`'s misreading one word along. **The two-line version
  naming only the binding limit is gone** — naming one meant the other two were
  invisible while the answer was nearly always the same. A HUD `text` has a
  `style` bitfield (1 bold, 2 italic, 4 monospace) and per-element colour
  through `number`, so one element per line gives per-line colour without
  `core.colorize`.
- **A HUD cannot carry buttons.** 5.17.0 has nine element types and none is a
  button; **no HUD click callback exists anywhere in the API**. That is what
  splits `F4` into two surfaces. `register_on_player_receive_fields` is
  formspec-only and `get_player_control` is key state, not a click target.
- **The HUD shows only while that player's own drone is running.** A permanent
  status area is decoration, and decoration imposed on every game is `C18`'s
  shape.
- **Pause is not `wake_at`.** Reusing it would clobber a pending `sleep()`:
  resuming would wake the drone early. `drone.paused` is checked in
  `stepper.awake` and a paused drone takes no share of the step pool.
- **`lib/drone.lua` does not know forms exist and must not learn that a HUD
  exists.** Drive both from the other side, reading `drone.budget` (`A11`).
- **Four things were argued out of `F4`.** A **Start button** duplicates the
  poser's left click and doubles the entries into `get_safe_coroutine`. An
  **admin view of another player's drone** adds a privilege surface nobody asked
  for. A **`statbar`** needs a texture pair and draws in half-image steps, where
  a coloured `text` says the same thing to the pixel. A **live-refreshing panel
  reproducing the HUD** — two surfaces, one job each.
- **The three preference checkboxes live on the *Settings* panel**, not the
  editor form's bottom edge.
- **Slowing the display beat rather than making the panel static.** `PERIOD` 0.5
  → 1 s, one constant in `lib/hud.lua` driving both surfaces. It halves a
  dropped-click window it does not close. Three closures were rejected: *stop
  the self-refresh* takes away the liveness `F8` was built for; *quantise the
  string* cannot beat the elapsed clock, which changes every beat; *act on
  mouse-down* means a `textlist` where Stop is a button, and a destructive
  action on mouse-down is worse than a dropped click. **The fallback is the
  static panel, not a shorter beat**, and the bar for taking it is misses in
  ordinary use.
- **The unsaved-tab marker is a flag, not a diff against a kept pristine copy**
  — one boolean per tab against doubling the editor's memory for a cosmetic
  mark. `meta.dirty` is kept **dense**, because `table.remove` on a table with
  nil holes has no defined behaviour in Lua 5.1.
- **The marker is render-only.** `meta.tabs[i]` holds the filename the
  filesystem is handed; a `*` appended there would create `foo.lua*`. Decorate
  the label as the `tabheader` is built and nowhere else.
- **The flag is set from `fields.content ~= meta.contents[active]`, compared
  before the buffer is overwritten** — not from the field *arriving*, which
  would mark every tab on the first button press. So the mark means *differs
  from what was last written*. `save_active` clears it only on a write that
  happened.
- **That comparison is line-ending-sensitive** (`B48`): `read_file` opens `'rb'`
  and the textarea returns LF, so every CRLF file was permanently marked.
  `read_file` now normalises to LF. Anything else comparing a disk buffer
  against a formspec field has the same problem.
- **Resetting the text area to the file's content on a tab switch was
  rejected.** It makes the dirty state visible by throwing the player's typing
  away, which is exactly `B35`. **Do not gate the capture again.**
- **The copy naming derivation.** `foo.lua` → `foo_1.lua` → `foo_2.lua`, first
  free *N* up to 99, **numeric because the author asked for it** — language
  agnostic, so the name does not depend on the server's locale. **Strip a
  trailing `_%d+` before appending**, anchored to the end, never widened to
  match mid-name: taking the whole stem nested the suffix and lost a character
  to the 15-character limit each round. Trimming the suffix instead hands back
  the original name for any stem already at the limit.
- **A copy contains what is on screen, not what is on disk**, its name is
  derived and not typed, and the button is bottom-left rather than in the
  Save/Remove/Close row, which already runs to `x=14.08` against a help row
  starting at 14. The drone's file chooser does not get the button. **Saving the
  original first was argued out** — a copy is a copy — and so was a
  `filesystem.copy_file` helper: a copy is a derived name plus `write_file`,
  already the module's one write path.
- **The natural sort key lives in `lib/filesystem.lua`** and prefixes each digit
  run with its own length, so `foo_2` precedes `foo_10` **without guessing a
  padding width**. It is injective, so no tie-break is needed. The file chooser
  reads the same `ud.list` — one sort, two consumers.
- **The help row is one layout in every game — a `Blocks` button and an
  always-drawn category selector.** Chosen over a dropdown shown only when a
  game has registered something. **Two layouts for one thing means the rare one
  is where a defect sits**: `B38` and `B39` were both exactly that, correct in
  `codecube` and broken everywhere else. Built-in categories keep their
  translated labels; a game's shows raw, because the raw name is what a program
  types.
- **The selector's guard branches on the arriving value *matching* a label it
  drew, never on it *differing*, and sits below the `quit` branch.** A legacy
  dropdown is an always-sent field (`B37`), so *if it differs, switch* would
  fire on ESC and swallow the close. The formspec-version-4 `index event`
  parameter would retire the question (`lua_api.md` 5.17.0 line 3579) and is
  **not reachable here** — the editor is legacy coordinates.
- **Converting the editor form to the new coordinate system** — a change to the
  whole editor, unverifiable from a headless server, and not part of any feature
  that has needed it. (`A1`, `F1`)

### Limits and settings

- **Codelevel is privileged and players never set their own.** An intermediate
  version once removed the privs so they could — a privilege escalation,
  reverted before it shipped (`B9`). If a codelevel control is ever exposed in
  the panel it must be privilege-gated **per press, not per form**.
- **Rebuilding a budget from a new codelevel mid-run must carry `used` across.**
  A rebuild that resets it turns re-levelling into a way to spend
  `max_nodes_written` or `max_runtime_s` twice — a limit bypass through a
  legitimate command. That is why `F5` is large.
- **The per-codelevel numbers, 2026-08-30.** `max_nodes_written` `1e5 / 5e5 /
  1e6 / 1e7`, down an order of magnitude: a ceiling that cannot be reached
  teaches nothing about what a program costs. Level 2 gained in three places at
  once — `pace_ms` 15 → 5, `map_memory_mb` 16 → 32, `max_string_mb` 4 → 8 —
  because it is the level a server hands out and it was paced enough to feel
  slow without room to finish anything. The singleplayer default went **4 → 3**:
  level 4 is every ceiling at its widest at once.
- **`max_runtime_s` is `30 / 60 / 120 / 300`, retuned 2026-09-02, and level 4's
  node ceiling went `1e7` → `5e7`.** What made 2000 s wrong was the unit: a
  program that built for 387 s of clock time spent about 18 s of server time,
  ~4.6%, so 2000 s charged was eleven hours of building. The two moved in
  opposite directions on purpose — with `pace_ms` at 0, *how much may I build*
  is the only ceiling a poweruser meets, and 1e7 is a 215-node cube against
  5e7's 368.
- **The bundled examples all fit codelevel 2**, the largest `planet.lua` at ~71%
  of that level's node budget. Before nudging any limit: `planet.lua` and
  `death_star.lua` do not fit codelevel 1 and never did, and `cube(200,200,200)`
  needs codelevel 4.
- **The codelevel tables stay plain literals with overrides applied
  afterwards.** Two generators grep the source for a name assigned a table whose
  first element is a number, so a computed value switches both checks off
  without failing. (`C7`, `C14`)
- **The settings are all this mod's and do not move to the game.** It is its own
  ContentDB package. `C18`'s `flat_sky` is the one exception and its own entry
  says so; **do not read it as a precedent.**
- **A setting to keep the `fly`/`fast`/`noclip` grant was declined.** Nothing
  here needs creative flight to be reachable, and a game that wants it sets it
  in its own config. **A setting no code path here depends on is a setting
  maintained for nobody.**
- **`/codeblock tools`, not `/codetools`.** A subcommand namespace over a fourth
  top-level `/code*` name, with the two existing commands folded in rather than
  the family left split.
- **Aliases keeping `/codelevel` and `/codegenerate` working were cut.** v1.0.0
  is unreleased and already carries a thirteen-item breaking list, so the rename
  is free now and never again; and two names for one command is a second surface
  to document, translate and keep in step. **This is the omission most likely to
  be proposed again.**
- **Privileges are uniform.** `tools` and `generate` are free for yourself and
  need the `codeblock` priv for someone else; `level` is privileged either way,
  because a player able to raise their own codelevel is lifting their own
  ceilings.
- **`/codeblock tools` must add what is missing, never clear.** Both carrying
  reads stay — `main` **or** `craft` — because a tool parked in the craft grid
  would otherwise be duplicated on every run, silently. It is run on demand and
  repeatedly, which makes that easier to reach than the once-per-join version
  was.
- **A full inventory is a refusal, not a partial hand-out.** A player can
  produce it deliberately, so it has to say what happened rather than
  half-succeed.
- **The first-join line names the command and the creative inventory, and
  stops.** No hint about the editor, the examples or the drone.

### Documents, generators and checks

- **Make a new check fail once before trusting it.** Two here were written,
  committed, believed and matched nothing: three name prefixes that missed every
  limit, then a shape match whose `%w+` missed the same names because Lua's `%w`
  excludes the underscore every limit name has (`C20`). **A check that cannot
  fail is indistinguishable from a check that passes.**
- **A check that would be red locally and green in CI is backwards.** Settle the
  local anomaly rather than weaken the check — `C23`'s second direction was
  deferred for hours on exactly that, and the answer was to track the file.
- **A generator guarantees the output matches its input, and nothing more.**
  `.cdb.json` never drifted; it was faithfully generated from the wrong source
  for the project's whole life (`C19`).
- **`settingtypes.txt`'s generator owns the prose and derives the numbers.** Two
  audiences, two documents: `config.lua`'s comments are for whoever edits the
  code, the menu's descriptions for an administrator. What it adds beyond the
  numbers agreeing is a **completeness check in both directions** — a setting
  nothing offers, or a menu entry nothing reads.
- **`doc/api.md` has a hand-written region no check covers.** `gen_docs.lua`
  owns the file only from `# Lua api` down; `# Codelevel` and `# Chat commands`
  sit above it. The gate reported *up to date* while the file documented
  `/codelevel` and `/codegenerate` after `F10` renamed them. **The blindness is
  by design** — that region describes chat commands and privileges, which
  `lib/api.lua` knows nothing about. Edit it by hand; never read a green
  `--check` as covering it.
- **`.luacheckrc`'s sandbox std stays hand-written and is checked, not
  generated** — it is a linter configuration a human also edits. `gen_docs.lua
  --check` compares it with `api.names()` both ways. **The std holds API names
  and nothing else**, which is what makes the comparison a plain equality; the
  bare `_` the examples pass lives in `files["lib/examples/**"].read_globals`.
- **Never write `.cdb.json` by hand.** ContentDB reads `long_description` from
  that JSON only and a JSON string cannot hold a newline, so the shipped field
  is one enormous escaped line: the artefact, not the source. Edit
  `CONTENTDB.md` and run `bash scripts/gen_cdb_json.sh`. (`C19`)
- **Exporting `getScriptEnv` to give the sandbox implementations coverage was
  refused.** Pinning a spec to a private closure factory pins the
  implementation, and the factory would be public for the sake of a test. The
  spec **writes a program into the throwaway world** and runs it through
  `get_safe_coroutine` instead; it was driven to failure eight ways, so the
  `run-tests` rule against a spec touching a user directory does not apply.
- **A per-feature playtest check is named `F<feature>-<n>`**, numbered in
  document order and never renumbered; a feature with one check still takes
  `-1`. The *Filesystem and example generation* group stays `F-1`–`F-5`, where
  `F-` is filesystem and not a feature — confusable and left alone, since
  renaming it would break references for a cosmetic gain.
- **A playtest result line names both commits when the checkout was on a
  record-only one** — `2feadb1`, record-only over `24842d3`. The reader has to
  be able to tell which *code* was played, and a hash that touched no source
  cannot tell them.
- **The `register_blocks` test mod lives outside this repository, at
  `../codeblock-test-mod`, and is not versioned.** `tests/game/mods/` is
  all-enabled, so a mod registering a category there would change `api.names()`
  and the palette underneath every spec run. **Do not move it in.** What it
  registers is written into `F11-10` in enough detail to rebuild it.
- **No rendering has a next-step panel.** `.reports/playtest.html` opens on
  *What is outstanding*, `audit.html` on *The categories*, `roadmap.html` on
  *Finalising v1.0.0*. The document's own first section already answers the
  question, so a panel above it is a second, shorter answer, and two answers
  drift.
- **A full-size cover ships in the release archive.** `screenshot.png` is the
  mosaic verbatim, 1.83 MB, putting the archive at 2.21 MB. **A stale cover
  misrepresents the mod to every player deciding whether to install it; 0.7 MB
  does not.** Resize rather than revert if the size ever matters.
- **The release webhook's trigger is *Branch or tag creation*, not push**,
  because this project tags; push would publish every commit on `master`.
- **A reverse "no unexpected API name" check in `api_spec`** would duplicate
  `api.build` and make every API addition a spec edit. (`A16`, `F1`)
- **The last `.editorconfig` difference stays.** `align_call_args = true` fixes
  wrapped arguments but pushes a table constructor out to the paren column.
- **Chasing the remaining `minetest` names** — what is left must stay: the
  config filename, the forbidden-identifier list naming both aliases, the
  `vector3` submodule. Same for `loadstring`, `setfenv`, `math.pow`,
  `math.atan2`. (`C6`)

### Not built

- **`F5`.** Do not re-propose it as a small addition to the drone panel: the
  privilege gating and the counter-carrying above are what make it large.
- **A button in a HUD** — impossible, not merely unwise. See the HUD entry
  above.
- **Batching `place()` into `core.bulk_set_node`** — not for 1.0.0. 1.3x against
  five flush sites whose omission is a silently wrong build; the arithmetic
  wants redoing since Phase 6 changed the yield cadence. (`A4`)
- **Removing a file without opening it first** — won't fix, *"not really
  needed"*. `B14`'s cold path stays unreachable as a result. (`B34`)
- **The `soe` checkbox** — deliberately dead. A warning on unsaved changes is
  wanted instead, and is in `TODO.md`.
- **The new-file template naming an individual colour.** `colors.orange` was
  proposed as a one-word fix for `B53` and rejected: naming a current colour
  rebuilds the dependency that had just broken, and the template is prose no
  check can read. What ships is `for i = 1, #hues do place(hues[i]) up(1) end` —
  structural names that change only in a major version, fitting itself to
  whatever the palette holds. **Do not shorten it back.**

## What ships broken

- `heap_mb` cannot stop one huge allocation, and a pathological Lua pattern can
  burn CPU inside a single `find` or `match`. (`S2`)
- The step budget is never checked inside one VoxelManip pass, so a single slab
  — ~65k nodes, under 10 ms — overshoots it. (`A5`)
- A shape large in **two** dimensions asks for more mapblocks than the footprint
  ceiling in one pass, and the run dies instead of waiting. Only one axis can be
  sliced away. (`B42`)
- The map footprint decays linearly over the unload window rather than tracking
  each block, so it estimates what is resident. (`S5`)
- Nothing charges for writing a shape to the map database or pushing it to
  clients; both happen after a run reports `completed`. (`S5`)
- Nothing on screen says why a drone is slow — the map row was dropped from both
  surfaces deliberately, which leaves `H6`'s pause confusion able to return.
  (`B45`)
- `place()` writes one node per call; the four bulk shapes do not. (`A4`)
- A copy of a name already at the 15-character limit shifts base at the tenth
  copy. Fixing it would let copies past the length rule. (`F2`)
- The unsaved-tab mark is a flag, not a diff, so typing a character and undoing
  it leaves the tab marked until the next save. (`F7`)
- `if blocks[name] then` as a membership probe costs one chat line per run.
  (`B49`)
- A player created before `1f7cd97` keeps the stored "off" for both editor
  checkboxes; the ticked default reaches new players only. (`B36`)
- `save_on_exit` is read, written and acted on nowhere.
- A file over `max_file_kb` — 128 kB by default — cannot be opened or saved at
  all, and the ceiling cannot be raised from in-game. (`B40`)
- Cancelling the file chooser removes the drone it placed; removing a file takes
  the drone holding it. Both deliberate, and the two had to agree. (`B41`,
  `B44`)
- **`codecube` must set `codeblock_flat_sky = true`** in its own `minetest.conf`
  when it adopts a release, or its world gets an ordinary day/night cycle. This
  repository does not track whether it was added. (`C18`)
- A panel button misses a few presses in twenty at a deliberate rapid pace,
  measured by `H10` and accepted. A dropped click is silent. (`B47`)
- `scripts/gen_cdb_json.sh` is verified by nothing and escapes neither `"` nor a
  backslash. (`B22`)
- `.gitattributes` decides what reaches a player and no CI checks it. (`C10`)
- `README.md:14`'s trailing whitespace is deliberate — a Markdown hard break
  `gen_cdb_json.sh` folds into the ContentDB description. (`B21`)
- The 105 nodes are silent to walk on, dig and place. Deliberate; `F11-6` exists
  to have it seen once and recorded as intended. (`F11`)
- A wall of one solid colour has no node-edge definition. The choice was between
  an exact hex and a wall that reads as blocks, and the hex won; `F12-2` judged
  it acceptable. (`F12`)
- `is_block` cannot say *why* it answered false — a node no program can place,
  ungenerated map, outside the world, a name that does not exist and a different
  block are one answer. `get_block` tells them apart. (`F13`)
- A game's block category shows its raw, untranslated name in the help selector.
  (`F11`)

## Four rules this phase paid for

- **Run a playtest group that has never been run before writing the next
  feature.** Eight sessions on the editor found four findings; the first session
  that left the editor found three, including `B39`. `F4` repeated it: four
  green gates, and ten minutes in a world found two more.
- **Play the mod outside its own game before a release.** `B38`, `B39` and `C18`
  are all invisible in `codecube`, where a player carries nothing but the two
  drone tools and a sunless sky is the game's design.
- **A check is a starting point, not a script.** Do the obvious next thing to
  whatever it leaves on screen. `B41` was reported while a session was checking
  something else, and `B44` came out of re-running `B41`'s check and then
  removing the file the drone was holding.
- **Read what the game said, not just whether it did the right thing.** `F-3`
  case 2 passed on behaviour and printed the server's absolute filesystem path
  in English. That is `S7`, and a pass/fail line would have buried it.

---

Last reviewed **2026-09-07**, describing the `vector3` submodule bump to
**`fc8a5b8`** (v2.0.2). `origin/master` is **`65b4c46`**, **22 commits
behind**. `PLAYTEST.md`: 84 entries, `F11-4`
retired, two unrun (`F-6`, `F-7`), no fail. `AUDIT.md`: 92 findings, four open —
`S8` and `C24` medium, `A17` and `A18` low.
