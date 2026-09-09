# Roadmap — CodeBlock

What to do next, and **what has been agreed**. The decisions below are recorded
nowhere else. Findings are in `AUDIT.md`, manual checks in `PLAYTEST.md`,
unscheduled intentions in `TODO.md`.

Ids: phases `Phase 0`–`Phase 10`, features `F1`–`F17`, findings `B`/`S`/`C`/`A`.
**Nothing is ever renumbered.**

Three releases: **`Phase 8` is v1.0.0**, **`Phase 9` is v1.x.y**, **`Phase 10`
is v2.0.0 and holds `F6` alone**.

## Now

**`F17` shipped at `be3155f`, and `Phase 8` has no unshipped feature left.**
Seven player-facing names left the API, two arrived, and the `table` namespace
left player code with `table.randomizer`. Gates green there: luacheck silent,
the three `--check` generators up to date, **725 in-engine assertions with 0
failed and 0 xpass**, 254 standalone. **It is played too:** `F17-1` to `F17-4`
and `F12-6` all pass at `6440ca0`, record-only over `3fa9d0c`, engine 5.17.0,
2026-09-09. What is left before the tag is *Finalising v1.0.0* below.

**Answer the fixture question.** What `tests/game/mods/vector3` should pin is
the one open question left before the tag, now that a player may have any of
three versions.

**`S8` and `S9` are both closed.** `snapshot_vector3` in `lib/sandbox.lua`
rebuilds each `vector` constant with the constructor, so a run cannot reach the
module's own; `vector3` v2.0.2 separates the metatable from the methods table
and the submodule is bumped to `fc8a5b8`. **`S8` now has its in-world reading**
— `F-6` passes at `6440ca0` on the pinned v2.0.2 — and `S9`'s is `R5`, unrun.
`S9` is still live for a player on
v1.5 or v2.0.1, which the mod now names in `debug.txt` at load and which the
support matrix in the `run-tests` skill tracks.

**`A17` and `A18` are closed.** `A18` landed at `c089f78`, both `meta.active`
loops now assignments. `A17` finishes at `6a4fa91`: `lib/utils.lua` is deleted,
four names rehomed and three made private. `fd219ef` pins the new home in
`integration_spec`. Gates green there — 671 in-engine assertions, 0 failed, 0
xpass. **`C24` is the one open finding**, and it is `Phase 9`'s.

**`F16` and `B55` shipped at `7c1442d`, with `2608dc3`'s 28 spec cases over the
two parsers.** `/codeblock level` reports a codelevel, and any engine-legal
player name is addressable by every subcommand. Gates green at `2608dc3`:
luacheck silent, the three `--check` generators up to date, 703 in-engine
assertions with 0 failed, 0 xpass and the one known `B4` xfail, 253 standalone.
**Both are played:** `F16-1` to `F16-8` all pass at `fb75bc8`, engine 5.17.0,
2026-09-08, and `F16-8` is `B55`'s only possible in-world evidence.

**Six commits are unpushed over `origin/master` at `fb75bc8`.** `fb75bc8`'s CI
run — luacheck, the six standalone specs, the three generator checks —
concluded success. **`F17` and `C18`'s `flat_sky` removal have therefore not
been through CI.** Take the count from
`git rev-list --count origin/master..HEAD`, never from counting hashes.

**Every `Phase 8` feature has shipped and every feature check is played.**
`PLAYTEST.md`'s remaining action is the `R` group alone: `R5` unrun, `R1` and
`R2` stale, `R3` and `R4` owed. `E2` and `E3` pass at `fffdded`, which is
`A18`'s in-world evidence.

**`R4` is runnable as written for the first time.** Its four numbered cases ask
for a codelevel to be read back, which `7c1442d` added, so its `dd98aab` fail is
superseded. `A17`'s call-time read is still owed one in-world reading, which the
check's log half gives on its own.

## Finalising v1.0.0

Steps 6–10 are the `release-codeblock` skill's procedure and are not restated.

**`F17`'s in-world checks are done and the numbers do not move.** `F17-1` to
`F17-4` and `F12-6` all pass at `6440ca0`; `F12-5` kept its pass on the half
`F17` did not touch. What step 7's `release-check` still reads as outstanding is
the `R` group.

**`CONTENTDB.md`'s description was corrected at ship, not deferred.** It was
naming `ramp.colors`, `ramp.glass`, `ramp.lamps` and a ramp per registered
category, none of which exist — a page that sells a function a player cannot
call is worse than one that is merely incomplete. **What is left to the `C19`
pass is the recent-changes list against `CHANGELOG.md`**, which is hand-kept and
which nothing checks. **The page and the changelog address different readers**:
the page says what a player writes now, `CHANGELOG.md` says what stops working.

1. **Decide what the test fixture pins** — newest, oldest supported, or a
   documented floor. Luanti has no dependency version mechanism, and there are
   now three releases in the wild. (`S8`)
2. **Fix `README.md`.** Line 10's *"works in any game that provides the blocks
   it places"* is false and backwards since `d075742`; add a short **For game
   authors** section for `codeblock.register_blocks`; the ContentDB URLs are on
   the pre-rename `content.minetest.net`; line 23 reads *"ant its dependencies"*
   and there is now one. (`C19`, `F10`, `F11`)
3. **Upload the new screenshots to the ContentDB page** — it loads them from raw
   GitHub URLs on `master`, so the new names go up and the dropped 2021 file
   comes off. (`C19`)
4. **Run `R5`**, the one unrun check left. It needs the `vector3` submodule
   swapped to v1.5 and to v2.0.1 by hand, a world started on each, and the pin
   put back before the suite runs. It is `S9`'s only in-world reading. (`S9`)
5. **Run `R4` in a fresh world.** Its log half —
   `codeblock_default_auth_level = 9` and the warning in `debug.txt` — needs no
   command and is the one in-world reading `A17`'s call-time read is owed.
   (`A17`, `S6`)
6. **Re-run `R2`** on the archive built from the release tag, not `HEAD`. Stale
   since `7c5bceb`, before `F4`, `F11`'s textures and `.gitattributes`. Install
   it in a game that is not `codecube`. (`C16`, `C10`)
7. **`release-check`**, and do not start the tag until it says ready.
8. **Strike what the release closed** from `ROADMAP.md` and `TODO.md`, confirm
   the `vector3` submodule commit is pushed, commit, push, tag `v1.0.0`.
9. **Upload to ContentDB**, long description from the regenerated `.cdb.json`.
10. **Configure the release webhook** — trigger **Branch or tag creation**.

Done and not repeated here: `CHANGELOG.md` is the heading alone, `CONTENTDB.md`
was corrected at `c2e541f`, `settingtypes.txt`'s generator landed, `B47` shipped
mitigated, and `B48`, `B49`, `B50`, `B51`, `B52`, `B53`, `B54`, `C21`, `C22`,
`C23`, `F10`–`F14` and `F16` are all committed with their playtests run.

**After the tag.** `Phase 9` opens on what comes back from players. `codecube`
adopts the release on its own schedule. `Phase 10` needs `F6`'s four obstacles
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
| 8 | Features for v1.0.0 | in progress | 14/14 features shipped; `C24` open |
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

**Phase 8's one open finding is `C24`**, queued for `Phase 9`. `S8` closed with
the per-constant copy, `S9` with the v2.0.2 bump, `A17` with the deletion of
`lib/utils.lua`, `A18` with the two assignments and `B55` with the widened
parsers. `B10`'s refusal is out of the phase rather than
done — its check was removed as untestable and reaching it needs a way to
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
| `F12` | large | shipped `01f9641` (examples `b752ea3`) | 35 colours, 105 nodes, the `ramp` namespace, `get_block` relative coordinates. Its per-category ramps were removed at `F17`. |
| `F13` | small | shipped `4450ce1` | `is_block(block, n_right, n_up, n_forward)`, the predicate form of `get_block`. Closed `C22` in the same commit. |
| `F14` | small | shipped `e3e2178` | `light_hues`, `dark_hues`, `neutrals` and `ramp.of(list, v, min, max)`. |
| `F15` | large | shaped, not scheduled | `colorhex("#F7A8E7")`. See below. |
| `F16` | small | shipped `7c1442d` | `/codeblock level` reports a codelevel; the read is free for your own. Fixed `B55` in the same commit and made `R4` runnable. Checks `F16-1` to `F16-8` all pass at `fb75bc8`. |
| `F17` | small | shipped `be3155f` | Seven names left the API and two arrived: `random.of(list)` and `random.hues()`. `ramp.of` also takes a block category. The `table` namespace left player code with `table.randomizer`. Played at `6440ca0`. |

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

- **The per-constant copy was adopted, and `S8` is closed.** Each `vector`
  constant is rebuilt with the constructor before a run gets it, because it is
  the only fix that works on **v1.5**, where the finding is reachable rather
  than latent. The accepted cost is that `vector.one` is writable inside
  codeblock and frozen everywhere else, so a player reading `vector3`'s own
  documentation gets a different answer from the one codeblock gives.
- **The copy lives at the call site, in `lib/sandbox.lua`.**
  `env.snapshot_module` stays shallow and dependency-free; deepening it would
  copy tables of strings on every other call site for nothing.
- **Only what passes vector3's duck test is rebuilt** — a table with numeric
  `x`, `y`, `z` — so a future `vector3` release exporting a table of another
  shape does not raise at the start of every program.
- **`S8`'s reachable half had already been narrowed upstream** by freezing
  `vector3`'s constants: writing to one raises `read only` from v2.0. That was
  not enough on its own, the freeze doing nothing on v1.5.
- **Do not re-propose deep-copying a constant with
  `setmetatable(copy, getmetatable(v))`.** Against a frozen constant it produces
  an empty table aliased to the original, so it changes nothing while looking
  fixed. `AUDIT.md`'s `S8` entry carries the three probe readings.
- **`S9` was fixed upstream, not here.** `vector3` v2.0.2 puts `__index` and
  every metamethod on a separate `meta` table, so `v.__index` reads nil. The
  submodule is at `fc8a5b8`.
- **What this mod does about a player still on v1.5 or v2.0.1 is say so.**
  `init.lua` logs one warning at load naming the guessed version and the fix.
  Detection is read-only, `vector3(1, 1, 1).__index ~= nil`: probing by writing
  to a constant succeeds on v1.5 and changes it server-wide, which would cause
  `S8` in order to test for `S9`. Silent on a library without the hole, and
  untranslated, `debug.txt` being for whoever runs the server.
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
- **No block category has a ramp of its own, and none is to be re-added**
  (`F17`, `be3155f`). `ramp.colors`, `ramp.glass`, `ramp.lamps` and
  `ramp.<category>` walked light, plain and dark inside each family and
  therefore **strobed**. **A name whose own help text says it looks wrong is a
  name to delete, not to warn about.** Two things outlive them. **`colors` must
  still not be re-ordered by lightness** — the picker and the creative inventory
  read by family. And **`ramp.of` over a category a game registered is a lookup,
  not a gradient**, which was the deleted entry's caveat and now lives in
  `ramp.of`'s own text, since `ramp.of` is the only ordered reach a registered
  category has.
- **A category costs a game one name, not two** (`F17`). `ramp.of` takes the
  category table itself, so a registered category is rampable and randomisable
  through the one name it already has. The order is the category's own: palette
  order for `colors`, `glass` and `lamps`, **alphabetical for a category a game
  registered**, because `lib/blocks.lua` sorts the entries before `add_category`
  sees them and a Lua map has no order to preserve. *Not a fixed ramp per
  category as well* — a coherent rule, but the author chose the version where one
  name covers everything.
- **`random.of(list)` is the one random picker.** It takes a name-indexed
  category and an array alike, because `pairs` walks both and a random pick has
  no order to respect. It is named for the rhyme with `ramp.of`: the two take the
  same first argument and mean the same thing over it, so learning one teaches
  the other. *Not `random.from`* — the author's first sketch, set aside on that
  ground.
- **`random.hues()` exists only for the symmetry with `ramp.hues`.** It saves
  five characters over `random.of(hues)` and had no users when it was added.
  Recorded so it is not re-proposed as a saving. It answers a **colour name**
  rather than a block, which is what makes `lamps[random.hues()]` read.
- **`random.of(hues)` is the pick to recommend, not `random.of(colors)`.** A
  pick across a whole category draws light, plain and dark shades of unrelated
  families in a row and looks muddled. That is the author's stated motivation:
  *"Random function on glass or colors can be awkward because of different
  shades."*
- **`table.randomizer` was dropped as a second name for one idea, and the
  `table` namespace went with it** (`F17`), `randomizer` having been its only
  member. It sat in *Misc* rather than *Choosing blocks* and carried a
  documented trap: the keys are taken once, so a key added afterwards is never
  picked. A reusable picker is `function() return random.of(t) end`.
- **`table` stays out of `unavailable` in `lib/preprocess.lua`, and adding it is
  not to be re-proposed.** No finding id and no code change. Two grounds. **The
  mechanism would misfire on a common name:** `find_forbidden` exempts a name
  only when it follows `.` or `:`, so it cannot see a local, and `local table =
  {}` or `for i, table in ipairs(t)` would be refused outright — `table` is a far
  more plausible variable name for a beginner than `os`, `newproxy` or
  `coroutine`. The list's own header says it is not a security boundary but a way
  to turn an obscure failure into a useful message, and **refusing a legal
  program is too high a price for a better message**. **And the failure is not
  obscure:** the list exists for `os.time()`, which dies on some later line
  telling a beginner nothing, where `table.randomizer(t)` raises *attempt to
  index global 'table' (a nil value)* on the line that wrote it. That is the
  standard the list was built to reach, and this reaches it without the list.
- **None of `F17`'s seven deletions got an alias or a deprecation period**, on
  the same ground as `color(v, min, max)` and the `/codelevel` names: v1.0.0 is
  untagged, and a name kept for compatibility with a version never released is a
  name kept for ever.
- **A category is not to be made both a map and an array**, which would let
  `#glass` work and save `ramp.of` its lookup. It doubles every `pairs` walk, and
  `snapshot`'s misspelling reporter would fire on `glass[1]`.
- **One ramp mapping, not two, and `F17` makes it stronger.**
  `ramp_pick(list, v, m, M)` is the whole of it and **`ramp.of` is `ramp_pick`
  itself**. The category-to-`keys` lookup `ramp.of` resolves through is **module
  level, not per-run**, precisely so that stays true. `ramp_over(list)` bound
  `ramp_pick` to one list for the fixed ramps and goes with them. Clamps, never
  wraps; a
  non-number `v` or a zero-width range gives the first entry.
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
  ContentDB package. There is **no exception**: `C18`'s `flat_sky` was one and is
  gone with the five sky overrides it gated.
- **A setting to keep the `fly`/`fast`/`noclip` grant was declined**, and
  `flat_sky` was later removed on the same ground. Nothing here needs creative
  flight or a rewritten sky, and a game that wants either sets it in its own
  config. **A setting no code path here depends on is a setting maintained for
  nobody.** A presentation choice belongs to the game, not to this mod.
- **`/codeblock tools`, not `/codetools`.** A subcommand namespace over a fourth
  top-level `/code*` name, with the two existing commands folded in rather than
  the family left split.
- **Aliases keeping `/codelevel` and `/codegenerate` working were cut.** v1.0.0
  is unreleased and already carries a thirteen-item breaking list, so the rename
  is free now and never again; and two names for one command is a second surface
  to document, translate and keep in step. **This is the omission most likely to
  be proposed again.**
- **Privileges are uniform, and the split is set against read.** `tools`,
  `generate` and `level`'s read form are free for yourself and need the
  `codeblock` priv for someone else. **Every set form of `level` is privileged,
  including your own**, because a player able to raise their own codelevel is
  lifting their own ceilings. (`F16`)
- **A target name is any engine-legal name, and ambiguity is resolved by
  value.** `parse_target` used to require a leading letter, which kept `level 4`
  and `level alice` apart and made every player named `007` or `_bob`
  unaddressable (`B55`). A single argument matching `^[1-4]$` is a codelevel and
  anything else is a name. **Players named `1` to `4` stay unreadable**, and
  **the dispatcher's set-before-read order is now load-bearing** because the two
  parsers overlap. Fixing only the refusal message, and widening only the
  two-argument form, were both rejected — the first leaves such a server
  unadministrable, the second leaves an asymmetry to explain. (`F16`, `B55`)
- **The engine's player-name charset is in the engine source alone.**
  `PLAYERNAME_ALLOWED_CHARS` in `src/player.h`; neither `lua_api.md` nor the
  settings example says it. That absence is why the narrow pattern stood.
  (`B55`)
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
- **The three dead `codeblock.utils` exports were deleted rather than kept.**
  `table_reverse`, `table_convert_ik` and `table_convert_iv` had no caller
  anywhere in the tree. `codeblock.utils` is a global this mod publishes, so
  removing one is breaking for a game or mod reading it — and **v1.0.0 is the
  release where breaking a published global is free**, which will not come round
  again. Kept-in-case was refused: four lines each, and copying one into the mod
  that wants it is cheaper than a name this project has to keep for ever.
  (`A17`)
- **`codeblock.utils` is dissolved, not declared and not narrowed.** Every other
  lib file publishes one `codeblock.<name>` table for one topic, so `utils` was
  not specially undeclared — it was the only one that was not a topic.
  Declaring it public would have singled it out as the one supported table, and
  it was the worst candidate: `scroll_max` was a scrollbar's geometry constant
  and `html_commands` a mutable rendered string, neither of which anything
  downstream should hold. **The only surface `CONTENTDB.md` promises a game is
  `codeblock.register_blocks`.** Breaking a published global is free at v1.0.0
  and a major bump afterwards, which is why it was settled before the tag.
  (`A17`)
- **The four survivors are rehomed to the module that owns each.**
  `codeblock.path_join` is set by `lib/pathjoin.lua` itself, instead of a
  vendored file reaching into another module's table.
  `codeblock.config.check_auth_level` is in `lib/config.lua` and
  `codeblock.api.html_commands` in `lib/api.lua`. `codeblock.parse_target` is a
  file-local in `lib/register.lua` plus one export line, **published only
  because a spec needs it**: `tests/integration_spec.lua` covers it — `B8` and
  the dead singleplayer branch both lived in that parsing — and the suite runs
  at mod load, before a player exists, so it cannot be driven through the chat
  commands. `split`, `table_randomizer` and `scroll_max` became private; the
  constant was inlined at its single call site. (`A17`)
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
- **The ceilings in `F16`'s message.** Useful — nothing shows a player their
  limits either — but the message would restate `lib/config.lua` and drift from
  it. `doc/api.md`'s codelevel table already carries them.
- **An editor or HUD surface for the codelevel.** Chat answers the question. A
  formspec line costs a change in `lib/formspecs.lua` or `lib/hud.lua` and an
  in-world check of its own, for a value that changes about once per player.
  (`F16`)
- **A listing of every player's codelevel.** Nobody asked for it and the output
  is unbounded. (`F16`)
- **A setting for `F16`.** There is nothing in it to configure.

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

Last reviewed **2026-09-09**, describing **`0e9b81d`**, over `6440ca0`. `origin/master` is **`fb75bc8`**, **six
commits behind `HEAD`**. `PLAYTEST.md`: 97 entries, `F11-4` retired, one unrun
(`R5`), two stale (`R1`, `R2`), one unreachable (`H8`), two owed (`R3`, whose
guard is gone, and `R4`, carrying a superseded fail). `AUDIT.md`: 93 findings,
one open — `C24`, medium. The `flat_sky` removal is `3fa9d0c`.
