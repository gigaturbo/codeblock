# BACKLOG

CodeBlock is a Luanti mod that adds programming to the game. **v1.0.0 is
released** and on ContentDB, published by the tag itself. v1.1.0 is drone throughput,
`F-S-1` to `F-S-4`. v1.x is opened on what comes back from players
and carries `F15`; v2.0.0 holds `F6` alone.

**Every id here predates the `B-X-N` scheme and keeps its old form for ever**,
because commit messages cite them: `B` bugs, `S` sandbox and security, `C`
compliance and packaging, `A` architecture and performance, `F` features, and
the in-world checks under their own group letters. **A gap in a sequence is an
id that went to the `codecube` game's record** when the two projects shared one:
`B19`, `B20`, `B24`, `C2`-`C5`, `C15`, `A7`, `A8`, `A13`, `A14`. `C9` was never
used. The categories below are for new items only.

The reasoning behind any item is in the `codeblock-kb` skill, not here. The
in-world check recipes are in its `references/playtests.md`.

## Categories

| Letter | Covers |
|---|---|
| `S` | The sandbox, the run pipeline and what player code can reach |
| `D` | The drone, its entity and the tools |
| `E` | The editor and its forms |
| `K` | Blocks, the palette and the ramps |
| `G` | Generated files, the gates and CI |
| `P` | Packaging, licensing and what ships |

## Bugs

Nothing open.

## Features

### F6 · Blockly web-based editor

`todo` `large` `target: v2.0.0`

Build programs by dragging blocks in a browser instead of typing Lua. A major
version because it is the change most likely to break how a program is stored
and edited. **Do not start building it because it has a target.**

**Four obstacles, none answered.** This mod has no HTTP allowance and cannot
give itself one, `core.request_http_api` returning a table only for a mod named
in `secure.http_mods` or `secure.trusted_mods`, and a feature that silently does
nothing on a correctly configured server is worse than one that is absent. Mod
security blocks the write side, and `lib/filesystem.lua` has no spec coverage.
The assets have to live somewhere: either a page hosted elsewhere, which is a
third-party runtime dependency for an offline game plus an AGPL-3.0-only
licensing and privacy question, or an in-tree server this mod does not have.

**Do:** one written answer to *where do the assets live and who allows the HTTP
call*, before any code.

### F15 · `colorhex`, a palette node

`todo` `large` `target: v1.x` `filed 2026-09-07`

`place(colorhex("#F7A8E7"))`. Feasible, but **not as an arbitrary colour**:
Luanti has no runtime node registration, so a hex nobody anticipated cannot
become a node. What it offers is `paramtype2 = "color"` plus a 256-pixel palette
texture, one node carrying 256 colours indexed by `param2`, so `colorhex` snaps
to the nearest of 256 and its name and documentation must say *nearest*. Plain
`color` is the right paramtype2: all eight bits go to colour, these nodes
needing no rotation. It is additive, so no saved program and no existing world
breaks.

**Do:** answer which 256 colours, and how the value reaches `place()`, whose
one-string contract is load-bearing. Then the cost: `allowed_blocks.all` stops
being name to itemstring, so every write path changes shape; `lib/shapes.lua`
needs a second full-size `set_param2_data` array per slab in the one path that
has to stay fast; `get_block` and `is_block` must read `param2`, since
`by_node[itemstring]` cannot tell 256 colours apart; and the block picker cannot
enumerate 256 x 3.

### F-S-3 · budget a share of the step, weighted by codelevel

`todo` `medium` `filed 2026-09-24` `target: v1.1.0`

A drone gets a fixed slice of each step, up to 8 ms, so the same codelevel works
about half the time in singleplayer, a tenth on a dedicated server and a twelfth
with the game window unfocused. The pool is split equally and then capped, so a
low codelevel's capped remainder and a paced drone's unspent slice go to nobody.

**Do:** one setting, `codeblock_server_share`, defaulting to 80% in singleplayer
and 33% otherwise, taken of `dtime` clamped to about 0.2 s, replacing the two µs
settings through the `retired` table. Share it in one pass over the awake drones
sorted by level cap, each getting its weight's part of what is left and paying
what it actually spent, with a floor per share so an overshoot cannot starve the
last drone. `stepper.budget` stays arithmetic, and its spec pins that the
planned total never exceeds the share of the step.

## Tests

### T-S-2 · small shapes, `place` and `get_block` sharing a mapblock

`todo` `playtest`

`F-S-1` writes a shape's box back late: when a shape leaves it, a node is read
or placed in it, or the step ends. No spec reaches a real map, so what a
program sees and what is left after it fails are unchecked. Never run.

### T-S-1 · a shape is lit correctly, inside and out

`todo` `playtest`

`F-S-1` writes several shapes back in one relight, after the step's last
command rather than after each shape. Last pass at `9c369c7`, engine 5.17.0,
2026-09-24.

### P2 · slab progression under the step budget

`todo` `playtest`

The overshoot under test is now one box of at most 16 mapblocks, whatever the
shape (`F-S-4`). Last pass 2026-08-27.

### P3 · the footprint throttle actually throttling

`todo` `playtest`

`F-S-4` replaced the longest-axis slicing `B42` relied on with boxes on all
three axes; `cube(2, 2, 30000)` should now pass in boxes of 1 x 1 x 16. Last
pass 2026-08-28.

## Closed

**A check listed here is done against a commit, not for good.** Its recipe is
permanent and lives in `codeblock-kb`'s `references/playtests.md`, which also
says which group a change owes. Move the line back into `Tests` as a `todo`
entry the moment the code under it moves, and keep the commit and date below so
whoever re-runs it knows what they are re-reading against.

### Bugs and findings

- `B-S-3` closed `medium` 2026-09-28 · a write into a mapchunk the engine was generating was overwritten when generation finished, leaving mapblock-sized holes in a completed build; a write now waits for the map one mapblock around it to be generated, bounded per run by `max_map_generated` and to one drone request server-wide, and `codeblock_wait_for_mapgen` turns it off; headless 6 of 6 exact against 2 of 3 wrong, and the in-world `sphere(100)` beside fresh ground passed
- `B-S-2` wontfix `low` 2026-09-24 · a shape carved into never-generated map keeps its air, but mapgen later lays the biome's top and filler nodes on the carve's floor; the author's call, the game's generator is the place to stop that, and generating before every write would make a far carve wait on mapgen
- `B-S-1` closed `medium` 2026-09-24 · every shape left the light of the voxels it did not claim stale, the buffer being prefilled with `ignore`, which the engine's relight skips: a hollow shape stayed sky-lit inside, and every air node on a mapblock border around a shape sat one light level low, drawn as dark lines every 16 nodes
- `B34` wontfix `low` · a file cannot be removed without opening it first; the author's call, not really needed, open it then remove it. Its permanent second effect is that `B14`'s cold-cache removal path can never be reached from the editor

- `B1` closed `critical` · comment stripping deleted the code between two block comments
- `B2` closed `critical` · `--[[ ]]` unhandled; only `--]]` matched, leaving a comment body as bare code
- `B3` closed `critical` · a string containing `--` was truncated mid-literal
- `B4` closed `high` · `"function"` matched as a substring, injecting a statement into unrelated expressions
- `B5` closed `high` `500dd85` · two editor checkboxes did nothing, because `0` is truthy in Lua; it destroyed work rather than being ignored
- `B6` closed `medium` · `color()` wrapped instead of clamping and answered nil past its maximum, so `place(nil)` silently built stone
- `B7` closed `medium` `37c416e` · a file-read error printed a file handle instead of the filename
- `B8` closed `high` · `/codegenerate` had no privilege check and overwrote the caller's files
- `B9` closed `medium` · `/codelevel` was unreachable in singleplayer, which it special-cased
- `B10` closed `medium` `742a1ca` · `add_entity`'s result was used without a nil check
- `B11` closed `medium` `742a1ca` · `on_deactivate` dereferenced `_data` without the guard `on_step` had
- `B12` closed `medium` · a runtime error was reported twice and left the coroutine attached
- `B13` closed `low` `37c416e` · `save_editor_state` could pass nil to `set_string`
- `B14` closed `medium` `37c416e` · `write_file` and `remove_file` indexed the per-player cache without populating it, so the first save after a rejoin crashed
- `B15` closed `low` `37c416e` · example loading had no error handling and leaked handles
- `B16` closed `medium` `37c416e` · every join wiped the player's inventory
- `B17` closed `low` `37c416e` · a number was passed to `set_string`
- `B18` closed `low` `834f69f` · a dead branch left cylinder coordinates nil
- `B21` closed `low` `834f69f` · 61 trailing-whitespace sites across 16 files
- `B22` closed `medium` `5832bf2` · `gen_cdb_json.sh` produced different output on Windows and Linux
- `B23` closed `medium` · `round()` took its arguments in the opposite order to its own documentation, plausibly and silently
- `B25` closed `high` · `use_call` yielded without dropping the mapblock memo, so a lost write could return
- `B26` closed `low` · a program's reported duration was the server's CPU time, so on Linux it counted everything else the server did
- `B27` closed `critical` `7d9ca47` · the rotation table is keyed by exact integers and was indexed with a float, so one `turn(n)` could make the next move crash — a regression from `A3`
- `B28` closed `medium` `7d9ca47` · `check_inside_world`'s error level was one short on the movement path, losing the player's line — a regression from `A3`
- `B29` closed `high` `191b533` · placing a second drone destroyed it immediately, because `on_lost` fired after the replacement was installed
- `B30` closed `low` `7d9ca47`, `1b991ae` · `on_lost` reported the end of a program that was never running — a regression from `A11`
- `B31` closed `high` `7d9ca47` · `run_tests.ps1` wrote a UTF-8 BOM into the user's real `minetest.conf`, killing its first setting
- `B32` closed `medium` `7d9ca47` · the same script appended its enable line with no separator, so on some configs the suite silently never ran, permanently
- `B33` closed `medium` `500dd85` · the editor saved its open-tab state on one exit path and lost it on three, including *Load and close*
- `B35` closed `high` `500dd85` · every editor button but *Save* discarded everything typed since the last save: 3 of 11 branches captured `fields.content`
- `B36` closed `medium` `1f7cd97` · the new-player initialiser wrote `0` into the editor preference keys, making the ticked default unreachable
- `B37` closed `high` `1f7cd97` · three help-panel scroll branches shadowed four others, so ESC never saved the tabs and Enter never created a file
- `B38` closed `medium` `b5d2e40` · aiming the poser at nothing was silently ignored, because the engine calls `on_secondary_use`, and `B10`'s refusal became unreachable
- `B39` closed `high` `b5d2e40` · the first join after installing the mod wiped the player's inventory — the case `B16`'s narrowing left behind
- `B40` closed `high` `62cf464` · a player's file was read whole with no bound: a 168 MB file took Luanti to ~14 GB resident and froze the game twice
- `B41` closed `low` `6fea453` · cancelling the file chooser left a drone that could not run
- `B42` closed `medium` `febf16f` · a shape wider than the footprint ceiling raised instead of throttling, and the drone's facing decided which
- `B43` closed `low` `6fea453` · the emerged box was one node larger than the shape on every axis, doubling the cost of a thin shape
- `B44` closed `low` `6fea453` · removing a file left a drone still naming it, taken away one gesture later
- `B45` closed `medium` `d619fba` · the HUD almost always named *map memory* as the binding limit, because a held resource sits at its ceiling by design
- `B46` closed `medium` `d619fba` · the runtime budget was labelled *Running time*, which reads as wall clock and is not
- `B47` closed `medium` `d8d44cd` · a button on the drone panel needed a second click: the panel's own 0.5 s refresh rebuilds every element, and a button's `Pressed` dies with the object
- `B48` closed `medium` `4179877` · the editor marked every unsaved tab modified on losing focus: a CRLF file never compared equal to the client's LF textarea
- `B49` closed `medium` `d8c32f7` · a misspelled block name built the default block and said nothing, `place(colors.typo)` being indistinguishable from `place()`
- `B50` closed `high` `1b991ae` · the drone disappeared mid-run at codelevel 1, taking its program with it: `static_save = false` deletes the object when its mapblock leaves server memory
- `B51` closed `medium` `8de3cea` · a run cut short was announced as *completed*, with a fraction of the node count it asked for
- `B52` closed `medium` `1b991ae` · a drone standing still far from any player died at about 29 s, `load_area` never resetting the block's usage timer
- `B53` closed `high` `de3bcbb` · the new-file template said `place(blocks.obsidian)`, a category `F11` had deleted, so **every file a player created failed on its first statement** for three days, with five gates green
- `B54` closed `medium` `24842d3` · `print` took exactly one parameter, so it dropped every argument after the first with no error, while the concatenated form raised
- `B55` closed `medium` `7c1442d` · both argument parsers in `lib/register.lua` required a leading `[%a]`, so a player named `007`, `4player` or `_bob` — all legal to the engine — could not be named to `tools`, `generate` or `level`, and the answer was the usage string
- `B56` closed `low` `8da8cab` · the three in-engine specs wrote their can't-run note with `io.write`, whose buffer the engine discards at exit, so a skipped spec said nothing in any captured output — and `C24`'s wording rule could not help, the filter never receiving the line
- `B57` closed `low` `v1.x` · the warning for a retired setting told administrators to use `codeblock_nothing`, every value in the table being read as a setting name and `max_distance` having no replacement
- `S1` closed `high` · player programs got live references to shared module and config tables, and the damage was global until restart
- `S2` closed `high` · one builtin call could exhaust server memory, invisibly to the call counter
- `S3` closed `medium` · the blacklist refused any file containing `repeat`, `until`, `_G` or `_c_` as substrings, so `repeat_count` was refused
- `S4` closed `medium` · the vendored WorldEdit fork still carried its arbitrary-code-execution module
- `S5` closed `medium` · `place()` could pin an unbounded number of mapblocks in server memory, and no limit could see them
- `S6` closed `medium` `af018d0` · every player got the widest limits by default
- `S7` closed `low` `6fea453` · a failed file open told the player the server's absolute path, in English whatever the game's language
- `S8` closed `medium` `124d032` · `env.snapshot` copies one level, so `vector`'s fourteen load-time constants were the module's own: `dir = vector.one; dir.x = -dir.x` wrote into a constant every player read, until restart
- `S9` closed `high` `submodule bumped to `fc8a5b8` · `vector3.__index = vector3` made the class table an ordinary field of every instance, so `v.__index.unpack = f` replaced a method for every mod using the `vector3` global
- `C1` closed `high` · a `max_minetest_version` ceiling hid the package from every modern user, and the floor was a false claim
- `C6` closed `low` · `minetest.*` throughout, style rather than breakage
- `C7` closed `medium` `d8d44cd` · no `settingtypes.txt`: every limit was source-only
- `C8` closed `low` · linting and CI had been set up, then removed
- `C10` closed `low` · a malformed `.gitattributes` line, and a release archive nothing had decided the contents of
- `C11` closed `low` · the changelog shipped two known limitations the same section contradicted
- `C12` closed `low` · `.luacheckrc` configured two mods that no longer exist, under a comment asserting a correspondence that did not hold
- `C13` closed `low` · `max_distance` was stored squared while its documentation gave it in nodes, which `C7` turned into a defect
- `C14` closed `medium` · `gen_docs.lua`'s documented-limit check matched by name prefix, so three limits were invisible to it
- `C16` closed `medium` `7d9ca47` · `codeblock_run_tests` aborted mod load on a ContentDB install, `tests` being export-ignored
- `C17` closed `medium` `b5d2e40` · `locale/template.txt` had drifted 12 messages one way and 17 the other, one key was built with `..`, and three translations were orphaned by a one-character edit
- `C18` closed `medium` `6fea453`, removed `3fa9d0c` · five sky overrides were forced on every joining player, unguarded, under a `TODO: TEMP fix` comment
- `C19` closed `medium` `7c5bceb`, `9e04990` · the ContentDB long description was `README.md` verbatim, breaking six of ContentDB's *do not include* rules, five of its nine images load-bearing in the instructions
- `C20` closed `medium` `d8d44cd` · `gen_docs.lua`'s limit check matched nothing and had matched nothing since it was written: Lua's `%w` excludes the underscore every limit name contains
- `C21` closed `medium` `b23a8bc` · `register_on_newplayer` granted `fly`, `fast` and `noclip` to every new player, in any game that installed the mod
- `C22` closed `low` `4450ce1` · `.luacheckrc`'s sandbox std had drifted: `sleep` and `default_block` were missing, so a correct example would have been reported as a typo
- `C23` closed `medium` `de3bcbb`, `63c3c33` · the shipped examples were checked against a hand-kept list of names, not against the directory, and the count agreed only by a dead entry
- `C24` closed `medium` `8da8cab` · CI booted no engine, so `forms_spec`, `stepper_spec`, `integration_spec` and every engine-guarded case never ran in CI
- `C25` closed `medium` `0ae4d3e` · `run_tests.ps1`'s error filter matched no `core.log('error', ...)` the mod emits, so the report printed `errors: none` on every run whose log carried one — and it had carried one for as long as `integration_spec`'s late-`register_blocks` case has existed
- `C26` closed `medium` `b371c76` · `scripts/gen_cdb_json.sh` could not run on the author's machine: `core.autocrlf` is `true` and `.gitattributes` had no text rule, so the script was checked out CRLF, its `printf \` continuation escaped the CR instead of the newline, and bash exited 126 with `File name too long` — writing no `.cdb.json` and leaving a zero-byte lookalike beside the real one
- `A1` closed `high` · the entire UI rested on an unmaintained mod that installed ten names into the engine namespace and replaced `register_node` globally
- `A2` closed `medium` · the player-facing API was defined in three places and had already drifted
- `A3` closed `medium` `834f69f` · `lib/commands.lua` was 971 lines of mechanical repetition
- `A4` closed `medium` `f413758` · `place()` wrote one node at a time and failed silently off-map
- `A5` closed `high` · the drone advanced one coroutine resume per server step, pinning throughput near 400 commands/s regardless of headroom
- `A6` closed `low` `742a1ca` · the entity prototype relied on a two-level metatable chain that resolved by coincidence
- `A9` closed `medium` `37c416e` · the filesystem layer duplicated its read path and exported six near-identical getters
- `A10` closed `low` · `get_safe_coroutine` overwrote its own parameter
- `A11` closed `medium` `742a1ca` · `drone.lua` and `drone_entity.lua` did not divide by responsibility, and drone state had no owner
- `A12` closed `low` · no tests, on the component that most needs them
- `A15` closed `medium` · only 448 of the vendored WorldEdit fork's 2,299 lines were reachable, and the whole dependency was four functions
- `A16` closed `medium` `a023ceb` · `api_spec` was standalone-capable but not run by CI, so the change most likely to break every saved player program was the one CI could not see
- `A17` closed `low` `c089f78`, `6a4fa91`, `fd219ef` · `codeblock.utils` was a published global holding ten unrelated entries, three of them with no caller anywhere in the tree
- `A18` closed `low` `c089f78` · `meta.active = #meta.tabs` was written as a `0` followed by a guarded `ipairs` loop assigning the index every iteration, at two sites

### Features

- `F-S-1` done `large` 2026-09-24 · a shape leaves its last box open, and the shapes after it that fit inside write into it, so many small shapes pay one read, write and relight per mapblock per step; `mosely.lua` at `pow(3, 4)` went from 106 s to 19 s headless with an identical map and light, its peak footprint halved; `place()` stays a `set_node`, which runs the replaced node's callbacks
- `F-S-4` done `medium` 2026-09-24 · a shape is written in boxes of at most 16 mapblocks cut on all three axes, not slabs along one, so no pass stalls longer than one box whatever the shape; a box the shape does not reach is loaded and charged but not passed, bottom up so the shadow above it can reach it
- `F-S-2` dropped `medium` 2026-09-24 · relighting once per shape with `core.fix_light` after `write_to_map(false)` was up to 1.9x slower than relighting each pass in open air and level underground, measured headless on 5.17.0; lighting is 60 to 97% of a pass in open air, and fewer relights is `F-S-1`'s to win
- `F-D-1` done `small` 2026-09-24 · the drone's object is moved once per step rather than once per command, and only if it moved; the nametag is pushed only when the file changes
- `F17` done `small` `be3155f` · seven names left the API and two arrived, `random.of(list)` and `random.hues()`; `ramp.of` also takes a block category, and the `table` namespace left player code with `table.randomizer`
- `F16` done `small` `7c1442d` · `/codeblock level` reports a codelevel, the read free for your own
- `F14` done `small` `e3e2178` · `light_hues`, `dark_hues`, `neutrals` and `ramp.of(list, v, min, max)`
- `F13` done `small` `4450ce1` · `is_block(block, n_right, n_up, n_forward)`, the predicate form of `get_block`
- `F12` done `large` `01f9641` · 35 colours, 105 nodes, the `ramp` namespace and `get_block` relative coordinates; its per-category ramps were removed at `F17`
- `F11` done `large` `d075742` · the mod registers its own nodes and drops `default` and `wool`; a game adds a category of its own
- `F10` done `medium` `b23a8bc` · the mod stops imposing itself: no tool handout, no privilege grant, `/codeblock tools`, `level` and `generate`
- `F9` done `small` `8869d8c` · the state and the run clock time in the same words on both surfaces
- `F8` done `medium` `d619fba` · the drone panel made readable: three hard-limit rows, coloured percentages, one destructive button
- `F7` done `small` `afbe504` · a tab whose buffer differs from what was last written gets a trailing `*`
- `F5` dropped `large` 2026-08-29 · change a codelevel mid-run, cut unbuilt by the author as not very interesting in the end; the privilege gating and carrying `used` across a rebuild are what made it large
- `F4` done `large` `729c255` · a live HUD read-out while a program runs, and a formspec panel with the per-limit breakdown and the buttons
- `F3` done `medium` `90cfb70` · `sleep(seconds)` parks the drone and hands the step back
- `F2` done `small` `dee0bc7` · Create a copy writes what is on screen to a derived name and opens it
- `F1` done `small` `500dd85` · a per-player default block picked in the editor Settings panel, with `default_block(block)` overriding it for one run

### In-world checks

- `E1` done `playtest` 2026-08-27 · open, save and close a program
- `E2` done `playtest` 2026-09-08 · create and remove a file
- `E3` done `playtest` 2026-09-08 · tabs
- `E4` done `playtest` 2026-08-27 · tab state survives ESC
- `E5` done `playtest` 2026-08-27 · tab state after **Load and close**
- `E6` done `playtest` 2026-08-27 · the two checkboxes
- `E7` done `playtest` 2026-08-27 · the help panels
- `E8` done `playtest` 2026-08-27 · tab state survives a disconnect
- `E9` done `playtest` 2026-08-27 · tab state survives a server shutdown
- `E10` done `playtest` 2026-08-27 · the checkboxes for a player who has never set them
- `E11` done `playtest` 2026-08-27 · typing survives every button that is not Save
- `E12` done `playtest` 2026-08-27 · **Save on tab switch** off really does not write to disk
- `E13` done `playtest` 2026-08-27 · **Create a copy**
- `E14` done `playtest` 2026-08-27 · closing the editor with **ESC** saves the open tabs
- `E15` done `playtest` 2026-08-27 · **Enter** in the New file field creates the file
- `E16` done `playtest` 2026-09-03 · the unsaved marker on a tab
- `E17` done `playtest` 2026-09-07 · a brand new file runs as it is
- `D1` done `playtest` 2026-08-27 · place a drone and run a program
- `D2` done `playtest` 2026-08-28 · place a drone at nothing
- `D3` done `playtest` 2026-08-27 · replace a drone under the same name
- `D4` done `playtest` 2026-08-27 · join with a full inventory
- `D5` done `playtest` 2026-08-28 · cancelling the file chooser
- `D6` done `playtest` 2026-08-28 · removing the file a drone is holding
- `D7` done `playtest` 2026-09-04 · a run cut short says *stopped*
- `H1` done `playtest` 2026-09-02 · the HUD appears, updates and goes
- `H2` done `playtest` 2026-09-02 · the binding limit is the one it names, and it changes
- `H3` done `playtest` 2026-09-02 · the toggle, whose choice wins, and where it lives
- `H4` done `playtest` 2026-09-02 · the setter's left click always opens the panel
- `H5` done `playtest` 2026-09-02 · the panel's numbers, and its own refresh
- `H6` done `playtest` 2026-09-02 · pause and Resume
- `H7` done `playtest` 2026-09-02 · stop
- `H8` done `playtest` `unreachable` · the panel over the editor, and a run that ends under it; the remaining cases cannot be performed on this form and no future run improves it
- `H9` done `playtest` 2026-08-29 · leaving and rejoining with a program running
- `H10` done `playtest` 2026-09-02 · a panel button responds to one click
- `F-1` done `playtest` 2026-08-27 · `/codeblock generate` on your own files
- `F-2` done `playtest` 2026-08-27 · `/codeblock generate <player>`
- `F-3` done `playtest` 2026-08-28 · a file that cannot be read
- `F-4` done `playtest` 2026-08-28 · a file too large to open
- `F-5` done `playtest` 2026-09-02 · every bundled example finishes at codelevel 2
- `F-6` done `playtest` 2026-09-09 · a run's `vector.one` is its own copy
- `F-7` done `playtest` 2026-09-08 · every shipped example still runs, after a dependency bump
- `W1` done `playtest` 2026-09-03 · `place()` far from spawn
- `W2` done `playtest` 2026-09-04 · a node written into never-generated ground
- `W3` done `playtest` 2026-09-24 · a large bulk shape; pass at `9c369c7`, engine 5.17.0, `cube(200, 200, 200)` in ~0.68 s against 0.4 s in slabs at `e0c2d23`: about 196 short passes cost more in all than 13 long ones
- `W4` done `playtest` 2026-09-03 · an unknown block name warns, once
- `W5` done `playtest` 2026-09-04 · a drone that stands still far away keeps running
- `W6` done `playtest` 2026-09-24 · the drone's entity goes away and comes back; pass at `4b61623`, engine 5.17.0, after `F-D-1` changed the re-spawn
- `W7` done `playtest` 2026-09-07 · `print` sends every argument, in one line
- `T-D-1` done `playtest` 2026-09-24 · the drone is drawn once per step; pass at `4b61623`, engine 5.17.0, all four cases
- `P1` done `playtest` 2026-08-27 · `pace_ms` at the low codelevels
- `P4` done `playtest` 2026-08-27 · several drones at once
- `R1` done `playtest` 2026-09-24 · the archive contains no `tests/`; pass against the `v1.0.0` tag, `f75766b`: top level is `doc`, `lib`, `locale`, `textures` and the files, with `screenshot.png`
- `R2` done `playtest` 2026-09-24 · a real install with the test flag set; pass against the `v1.0.0` tag, `f75766b`, engine 5.17.0, headless: the mod loads, logs that the build ships no `tests/`, no error. `vector3` was the working copy, not the ContentDB package
- `R3` done `playtest` 2026-09-09 · the sky belongs to the game
- `R4` done `playtest` 2026-09-09 · a brand new world hands out the right codelevel
- `R5` done `playtest` 2026-09-09 · an old `vector3` is named in the log at mod load
- `CI1` done `playtest` 2026-09-10 · the suite's verdict reaches the annotation list and the run summary
- `F1-1` done `playtest` 2026-08-27 · the Settings panel
- `F1-2` done `playtest` 2026-08-27 · the preference survives a relog
- `F3-1` done `playtest` 2026-08-27 · `sleep(seconds)` in a running world
- `F9-1` done `playtest` 2026-09-02 · the words on the panel and the HUD
- `F10-1` done `playtest` 2026-09-04 · a fresh player is given nothing
- `F10-2` done `playtest` 2026-09-04 · `/codeblock tools`
- `F10-3` done `playtest` 2026-09-03 · the two renamed subcommands
- `F10-4` done `playtest` 2026-09-03 · a dropped tool can be recovered
- `F11-1` done `playtest` 2026-09-07 · the category selector, in French
- `F11-2` done `playtest` 2026-09-07 · the help row's geometry
- `F11-3` done `playtest` 2026-09-07 · the mod installs into a game that ships neither `default` nor `wool`
- `F11-4` dropped · retired 2026-09-08; the case it covered stopped existing
- `F11-5` done `playtest` 2026-09-07 · coloured glass and coloured lamps
- `F11-6` done `playtest` 2026-09-07 · the blocks are silent, deliberately
- `F11-7` done `playtest` 2026-09-07 · digging, in a game that is not `codecube`
- `F11-8` done `playtest` 2026-09-07 · the creative inventory
- `F11-9` done `playtest` 2026-09-07 · `is_ground_content = false` survives mapgen
- `F11-10` done `playtest` 2026-09-07 · a real game mod calls `register_blocks`
- `F11-11` done `playtest` 2026-09-07 · a registered category reaches `place()`, `get_block()` and player meta
- `F12-1` done `playtest` 2026-09-07 · 105 nodes register, and the picker shows them in palette order
- `F12-2` done `playtest` 2026-09-07 · a lamp wall shows the grid; a solid wall shows nothing
- `F12-3` done `playtest` 2026-09-07 · `get_block` and `is_block` answer over real map
- `F12-4` done `playtest` 2026-09-07 · the read offsets turn with the drone and move nothing
- `F12-5` done `playtest` 2026-09-07 · `ramp.hues` reads as a gradient, and clamps
- `F12-6` done `playtest` 2026-09-09 · a game-registered category is rampable through `ramp.of`
- `F14-1` done `playtest` 2026-09-07 · the API help panel lists the new views and `ramp.of`
- `F14-2` done `playtest` 2026-09-07 · reading past the end of a palette view is silent
- `F14-3` done `playtest` 2026-09-07 · a gradient built through a view actually lands
- `F16-1` done `playtest` 2026-09-08 · reading your own codelevel with the privilege not granted
- `F16-2` done `playtest` 2026-09-08 · reading another player's codelevel
- `F16-3` done `playtest` 2026-09-08 · an offline name and a name that never existed
- `F16-4` done `playtest` 2026-09-08 · a player carrying no `codeblock:auth_level` key
- `F16-5` done `playtest` 2026-09-08 · the four forms of setting still behave
- `F16-6` done `playtest` 2026-09-08 · the usage strings name the optional level
- `F16-7` done `playtest` 2026-09-08 · the three lines on a French client
- `F16-8` done `playtest` 2026-09-08 · an engine-legal odd name, on all three subcommands
- `F17-1` done `playtest` 2026-09-09 · `random.of` draws from a category and from a list
- `F17-2` done `playtest` 2026-09-09 · `random.hues()` answers a colour name, not a block
- `F17-3` done `playtest` 2026-09-09 · `ramp.of` over a category walks that category's own order
- `F17-4` done `playtest` 2026-09-09 · the help panel after the deletions
