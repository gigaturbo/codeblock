---
name: run-tests
description: Run the mod's full test suite in-engine, by booting Luanti headless against the fixture game in tests/game, and reading the results. Runs all nine specs including the three that need the mod loaded. Handles assembling the fixture, launching, and reading the one verdict line the run prints. The fixture game enables the suite itself and shuts the server down when it has reported, so nothing touches the player's own config.
when_to_use: After changing anything in this repository, before committing, when asked to run or verify the tests, or when checking whether the mod still loads cleanly on the installed engine.
argument-hint: "[--keep-world]"
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

# Running the tests

The specs run inside Luanti, not under a standalone interpreter, because three of
them need the mod loaded — `integration_spec` drives the real command budget,
`forms_spec` needs the registered callbacks, `stepper_spec` needs the real
config. A headless server boots, the specs print, and the server shuts itself
down.

Six of the nine also run standalone under Lua 5.1 in CI. That is not redundant:
it is the only thing that catches behaviour differing between plain 5.1 and the
LuaJIT the engine runs. A bug in the `string.rep` separator was found exactly this
way.

**CI runs all nine in-engine too**, in upstream's server container. The local run
and the CI run are the same suite on the same engine version; see *What CI does
and does not prove*.

## The fixture game

The engine needs a game to boot, and it will not load a mod whose `depends` are
unmet. `mod.conf` names `vector3` and nothing else, so `tests/game` is a game
whose whole purpose is to satisfy that: `game.conf` on singlenode, `vector3` as a
submodule, and **`tests/game/mods/cbfixture`**, which registers nothing but the
three mapgen aliases the engine validates at startup.

**`tests/game/minetest.conf` is what enables the suite**, and it is the reason
nothing has to touch the player's own config. A `minetest.conf` at a game's root
supplies defaults when that game is run (`lua_api.md`, *Game directory
structure*) and `core.settings` reads that layer. It sets two things:

| Setting | Effect |
|---|---|
| `codeblock_run_tests = true` | the suite runs on every boot of this game, and of nothing else |
| `codeblock_run_tests_exit = true` | the server shuts itself down once the suite has reported |

**To boot the fixture and stay in it**, override `codeblock_run_tests_exit =
false` in a user config; a user config beats a game default. **The file ships to
nobody** — `tests export-ignore` keeps it out of the release archive.

**It used to hold empty `default` and `wool` stubs as well.** `F11` dropped both
dependencies — the mod registers its own 105 nodes now — and the two stubs went
with them, `cbfixture` taking over the mapgen aliases. If a spec needs a node the
mod does not provide, register that one node in `cbfixture` and no more.

The game cannot live in the repository, because it has to contain the repository
as one of its mods. `scripts/run_tests.ps1` assembles it in
`%APPDATA%\Minetest\games\cbtest`: `tests/game` copied for `game.conf`,
`minetest.conf` and `cbfixture`, plus a junction for the mod itself.

If a submodule was never initialised, the boot fails on `vector3`:

```bash
git submodule update --init --recursive
```

## Three versions of `vector3`, and only one of them tested

`mod.conf` reads `depends = vector3` and **Luanti has no version constraints**,
so a player may have any release installed. The submodule is at **v2.0.2
(`fc8a5b8`)**, having been **v1.5 (`1662164`)** and then **v2.0.1
(`5077617`)**. **A submodule bump changes the test fixture only; it changes
nothing a player has.** So a green suite proves codeblock works against v2.0.2
and says nothing about the other two.

| | v1.5 | v2.0.1 | v2.0.2 |
|---|---|---|---|
| `vector.one.x = -1` | accepted, changes `one` server-wide | raises `read only` | raises `read only` |
| `vector.fromPolar('a', 1)` | returns nothing | raises `format error` | raises `format error` |
| `vector.srandom('a', 1)` | returns `(0,0,0)` silently | raises `format error` | raises `format error` |
| `pairs(vector.one)` | 3 keys | 0 keys | 0 keys |
| `vector(1,2,3).__index` | table | table | nil (`S9` fixed) |

**The raises are an improvement for a player.** `srandom` answering `(0,0,0)` for
a bad argument is silently wrong geometry, which is worse than nil.

**`pairs` is the trap, on both 2.0.x — in mod code.** `frozen()`
(`vector3.lua:370`) builds an *empty* table with `__index` onto a private
backing vector, so `next`, `rawget`, `pairs`, `table.copy` and `core.serialize`
all read a constant as empty — silently, and not as a raise. **It is no longer
true inside a player's program**: `snapshot_vector3` rebuilds each constant with
the constructor (`S8`), so the run's copy is an ordinary vector and iterates.
The row above describes what mod code holds.

**The mod names an old `vector3` in `debug.txt` at load.** One `warning` from
`init.lua` when `vector3(1, 1, 1).__index ~= nil`, giving the guessed version
and *Install vector3 2.0.2 or newer*. Silent on the pinned v2.0.2, so a suite
run shows nothing. Its check is `PLAYTEST.md` `R5`.

**`v.__index` is nil only from v2.0.2.** It carries `__index` and every
metamethod on a separate `meta` table, which is `S9`'s fix. On v1.5 and v2.0.1
a player program can still reach the class table through any vector.

**`.luacheckrc:75` excludes `tests/game/mods/vector3/**`**, so luacheck's silence
says nothing about the bumped library. That is correct — it is another package
with its own gates — but it is not coverage.

## What CI does and does not prove

**CI boots the engine, since `C24`.** Four jobs: `luacheck`, `preprocessor spec`
(plain Lua 5.1, the six standalone), **`the nine specs in Luanti`**, and `docs
are generated from the code`.

**The engine job runs the whole suite in `ghcr.io/luanti-org/luanti:5.17.0`** —
upstream's own server-only build of the version this mod is developed against,
so there is no build step and no third party's binary. It is a **LuaJIT** build,
so it is also the only CI job running the mod on the interpreter the engine
actually uses. `forms_spec`, `stepper_spec`, `integration_spec` and every
engine-guarded case are covered by it, including `preprocess_spec`'s enumeration
of `lib/examples/`, which needs `core.get_dir_list`.

**Four facts that job depends on, read from the engine source at tag 5.17.0.**
Each would otherwise cost a CI cycle to discover.

| Fact | Where | Consequence |
|---|---|---|
| `--server` exists only in a client build | `src/main.cpp:427`, inside `#if CHECK_CLIENT_BUILD()` | do **not** pass it to the container; the local script still needs it |
| `LUANTI_GAME_PATH` appends to the game search path | `src/content/subgames.cpp:141` | `--gameid` finds the fixture without depending on `path_user` |
| the image runs as uid 30000, home `/var/lib/minetest` | the 5.17.0 Dockerfile | `chmod -R a+rX` on the assembled game, and a world under that home |
| `git archive` obeys `tests export-ignore` | `.gitattributes` | assemble the game with `rsync`, not `git archive`, or the specs are dropped |

`actions/checkout` needs `submodules: recursive` there, or the boot fails on
`vector3` and nothing reports.

**What CI still does not prove.** Nothing in a running world: the suite runs at
mod load, before a map, a player or a user directory exists, and that is
`PLAYTEST.md`'s business. And a green suite proves the mod against the pinned
`vector3` only — see the version table above.

## Procedure

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

**A full run takes about 2 seconds.** The game conf asks for the shutdown, so the
script waits on the process instead of sleeping a fixed span.

`-KeepWorld` leaves the world directory for inspection; otherwise it is a
throwaway under `%TEMP%`. `-Exe <path>` overrides the engine location, which
defaults to `%LOCALAPPDATA%\luanti\5.17.0\bin\luanti.exe`.
**`-TimeoutSeconds <n>`** is a ceiling, not a duration, and defaults to 120.
Reaching it means the suite never reported, and the report says so.

One thing the script does that is worth knowing before editing it: it removes the
junction with `rmdir` and never with `Remove-Item -Recurse`, which follows a
junction and would delete the repository behind it.

Running a single spec in-engine means editing the `specs` list at the bottom of
`init.lua`. That block probes for `tests/api_spec.lua` first and only warns if it
is missing, because `tests export-ignore` keeps the specs out of the ContentDB
archive and an unguarded `dofile` took the mod down on a release install (audit
C16). Running the six standalone specs needs no engine at all:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && for s in api preprocess env shapes strguard limits; do lua5.1 tests/${s}_spec.lua; done'
```

## Reading the result

**Read the verdict line.** `init.lua` prints one line carrying every pass
criterion, so a reader and the CI job apply the same one instead of each
restating it:

```
  suite: 9/9 specs   725 passed   0 failed   1 xfail   0 xpass   0 skipped
```

**`9/9` and `0 skipped` are two independent counts, and both matter.** A spec
that skipped is counted under `skipped` and not under `9/9`, so a spec which
stopped asserting shows up twice over. **They were one count for part of a day
and that was a hole**: the three in-engine specs answer their can't-run branch
with `return {skipped = true}`, a table, so a skipped spec counted as one that
ran. Breaking the guard `forms_spec` exists to hold reported
`9/9 specs   659 passed   0 failed   0 xpass` — 66 assertions gone, green
everywhere. **Do not collapse them back into one.** The line carries the word
`passed`, so the script's report filter keeps it.

The per-spec summaries are still printed and still worth reading when the verdict
is red, because they say which spec. A healthy run prints one per spec and `none`
under errors. As of 2026-09-03, at the commit that decoupled the drone record
from its entity (B50, B52):

```
  api_spec              30 passed   0 failed
  preprocess_spec       54 passed   0 failed   1 xfail (known defects)   0 xpass
  env_spec              34 passed   0 failed
  shapes_spec           31 passed   0 failed
  strguard_spec         29 passed   0 failed
  limits_spec           73 passed   0 failed
  forms_spec            66 passed   0 failed
  stepper_spec          45 passed   0 failed
  integration_spec     112 passed   0 failed
```

474 assertions. Treat the numbers as the shape of a healthy run, not as a
checksum: they rise whenever a spec gains a case, and they were 357 before `F1`.
The block above is the shape at `6126abe`; at `01f9641` the run reports 544
across the nine with `integration_spec` at 182, and at `4450ce1` **610 across
the nine**, `integration_spec` alone at **248**, with 0 failed, 0 xpass and 1
known xfail. At `e3e2178` it is 646, at `de3bcbb` 651, and at `63c3c33`
**653 across the nine** — `integration_spec` **288**, `preprocess_spec` **57** —
still 0 failed, 0 xpass, 1 known xfail, none skipped. At `dc73e1e` with the
`vector3` submodule at v2.0.2 it is **665 across the nine** — 30, 57, 34, 31,
29, 73, 66, 45, 300 — 0 failed, 0 xpass, 1 known `B4` xfail, errors `none`, and
the standalone six total **253** (`preprocess_spec` 56, one case engine-guarded).
**The v2.0.2 bump moved no count in either direction.**

**The current shape is 725 across the nine** — `api_spec` **31**,
`integration_spec` **359**, `preprocess_spec` 56 in a standalone run — with 0
failed, 0 xpass and the one known `B4` xfail. The standalone six total **254**:
31, 56, 34, 31, 29, 73, with the one legitimate `skipped:` line. **These are the
shape of a healthy run, not a checksum**; every number here rose when a spec
gained a case, and the verdict line is what to compare against.

**The script's report filter drops the spec-name lines**, keeping only the lines
matching `passed|failed|FAIL|want|got|skipped|xfail`, so
`run_tests.ps1` prints the nine summaries in the order of the `specs` list in
`init.lua` — `api`, `preprocess`, `env`, `shapes`, `strguard`, `limits`, `forms`,
`stepper`, `integration` — and not the names. Count the lines: nine, or a spec
did not report.

What each column means:

- **failed** — a real failure. Nothing else matters until it is zero.
- **xfail** — a known defect, asserted as still broken. The count dropping is
  good news; it means something was fixed. The count *rising* means a defect was
  introduced and someone recorded it rather than fixing it.
- **xpass** — an `xfail` that now passes. **This fails the run deliberately.** It
  usually means a defect was fixed and the test should be promoted — but it can
  also mean the test is passing vacuously because the thing it exercises stopped
  running at all. That second case has happened here: instrumentation was
  silently disabled and the `xfail` cases passed trivially. Always check which.
- **skipped** — a spec that needs the mod and did not find it. **It is a field on
  the verdict line as well as a per-spec note**, and the field is the reliable
  half (`B56`). In the in-engine run, with the fixture in place, this should
  never appear: it means the mod failed to load or a module stopped being
  exported, so investigate rather than accept it. **In a standalone run it
  can be legitimate**, and one case is: `preprocess_spec` prints
  `skipped: the shipped examples match the list, both ways - not checked here:
  needs core.get_dir_list, in-engine only`, because the directory enumeration
  that closes `C23` exists only in-engine. That is also why the spec reads **56
  standalone against 57 in-engine** — the guarded case counts once instead of
  twice, and it is not a discrepancy.

**A can't-run note needs both halves: the right wording *and* `print`.** Neither
alone works, and getting only the first was `B56`.

- **Wording.** The report filter keeps only lines matching
  `passed|failed|FAIL|want|got|skipped|xfail`, so start the note with
  `skipped:` — anything else vanishes from the report, which is the exact
  silence the note exists to break.
- **`print`, never `io.write`.** Luanti flushes `print` per line; the C stdio
  buffer behind `io.write` is **discarded when the server exits**, so an
  `io.write` note reaches no captured output at all however well it is worded.
  The three in-engine specs each carry a comment saying why it is `print`.

**Detection does not depend on the note.** The verdict line's `skipped` field is
what catches a spec that could not run. The note only says which and why. With
two guards broken at once the report reads:

```
  73 passed   0 failed
  skipped: needs the mod loaded
  skipped: needs the mod loaded
  359 passed   0 failed
  suite: 7/9 specs   614 passed   0 failed   1 xfail   0 xpass   2 skipped
```

If nothing prints at all, the mod did not load. Look in the error output for
`ModError` and read the traceback — a syntax error in any `lib/*.lua` stops the
whole mod.

## Before concluding it passes

- **The verdict line reads `9/9 specs`, `0 failed`, `0 xpass` and `0 skipped`.**
  That is the whole criterion. An absent verdict line means the mod did not
  load; `9/9` with a non-zero `skipped` is impossible and means the counts were
  collapsed.
- No `ModError` in the error stream, and the errors section says `none`.
- No spec skipped in the in-engine run.

**There is nothing to clean up afterwards.** The suite is enabled by
`tests/game/minetest.conf`, so the player's real `%APPDATA%\Minetest\minetest.conf`
is never written and never has to be checked. The old routine — write the
setting, strip it in a `finally`, then grep to be sure — is gone with `C24`, and
so is the class of defect it produced twice (`B31`'s UTF-8 BOM, `B32`'s glued
append). **Do not reinstate a config write** to enable the suite.

## What a good spec looks like here

A spec earns its place by failing when the behaviour breaks and at no other time.
Concretely, in this suite:

- **Assert the behaviour, not the implementation.** A spec pinned to a helper's
  name breaks on a rename that changed nothing a player can see, and then gets
  edited to match — which is how a suite stops testing anything.
- **One reason to fail per case.** A case asserting four things reports the first
  and hides the rest.
- **Nothing that needs a map, a player or a user directory.** The suite runs at
  mod load, before any of those exist. A test that appears to cover a formspec, a
  file read or a node write is passing vacuously — the honest move is a
  `PLAYTEST.md` entry, which `project-manager` writes.
  **The rule is about vacuity, not about the filesystem**, and the distinction
  was nearly lost on 2026-09-06. The sandbox implementations live in a closure
  inside the local `getScriptEnv`, whose only door is `get_safe_coroutine`, which
  reads a program out of the player's directory — so `integration_spec`'s `F17`
  section reaches `ramp.of` over a game's category, `random.of` and `random.hues`
  by **writing a file into the throwaway world** and running it. That is
  legitimate: every assertion in it was driven to failure, against three
  mutations of `lib/sandbox.lua` and `lib/blocks.lua`. **It shows both halves of
  why the world is the only door**: the section must also *register* a category
  before the run can see one. **Exporting `getScriptEnv` to avoid the write was offered
  and refused**, because pinning a spec to a private closure factory is pinning
  to the implementation. So: a spec may use the world it is booted in when that
  is the only real door to the behaviour and the spec has been made to fail —
  and the reason is commented in the spec, so do not delete the write on the
  strength of the sentence above it.
- **A chat line the mod sends a player is unobservable from a spec.**
  `lib/sandbox.lua` and `lib/commands.lua` each bind their sender as a load-time
  local, so replacing `core.chat_send_player` around a run intercepts nothing,
  and there is no logged-in player to receive it. A spec asserting that `print`
  merely does not raise would have been green throughout `B54`. Pin the charge —
  one `print` call is one command — and put the line itself in `PLAYTEST.md`
  (`W7`, `F14-2`).
- **Keep a spec standalone if it can be.** Six of the nine run under bare Lua 5.1
  in CI, and that is the only thing that catches plain 5.1 differing from the
  engine's LuaJIT. A new spec that pulls in `core` loses that for no gain unless
  it genuinely needs the engine.
- **An `xfail` is a recorded defect, not a parked test.** It gets a finding id in
  `AUDIT.md`, and a comment naming it. An `xfail` with no id is a defect nobody
  is tracking.
- **Test the boundary case that the finding was about.** Most findings here are
  off-by-one at a limit, an absent field, or a value that means two things — not
  a wrong formula.

## Related

The three `--check` gates below plus `luacheck` and this suite are the five every
change passes.

`scripts/gen_docs.lua --check` verifies the API reference is current,
`scripts/gen_locale.lua --check` verifies `locale/template.txt` lists exactly the
messages the code sends, `scripts/gen_settingtypes.lua --check` verifies
`settingtypes.txt` matches `lib/config.lua` — built 2026-09-02, and it found
`C20` on its first run — and `luacheck` lints. All four run in CI, the three
`--check`s in the `docs are generated from the code` job, and none is run by this
skill:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && luacheck . --formatter plain --codes && lua5.1 scripts/gen_docs.lua --check && lua5.1 scripts/gen_locale.lua --check && lua5.1 scripts/gen_settingtypes.lua --check'
```

Read what they print rather than the exit code: `$?` does not survive the WSL
layer here, so green means luacheck silent and all three checks saying *up to
date*.
