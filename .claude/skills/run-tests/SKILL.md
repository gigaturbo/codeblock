---
name: run-tests
description: Run the mod's full test suite in-engine, by booting Luanti headless against the fixture game in tests/game with codeblock_run_tests enabled, and reading the results. Runs all nine specs including the three that need the mod loaded. Handles assembling the fixture, launching, parsing the output and — critically — removing the setting afterwards.
when_to_use: After changing anything in this repository, before committing, when asked to run or verify the tests, or when checking whether the mod still loads cleanly on the installed engine.
argument-hint: "[--keep-world]"
allowed-tools: Bash, PowerShell, Read, Glob, Grep
---

# Running the tests

The specs run inside Luanti, not under a standalone interpreter, because three of
them need the mod loaded — `integration_spec` drives the real command budget,
`forms_spec` needs the registered callbacks, `stepper_spec` needs the real
config. A headless server boots, the specs print, and the server is killed.

Six of the nine also run standalone under Lua 5.1 in CI. That is not redundant:
it is the only thing that catches behaviour differing between plain 5.1 and the
LuaJIT the engine runs. A bug in the `string.rep` separator was found exactly this
way.

## The fixture game

The engine needs a game to boot, and it will not load a mod whose `depends` are
unmet. `mod.conf` names `vector3` and nothing else, so `tests/game` is a game
whose whole purpose is to satisfy that: `game.conf` on singlenode, `vector3` as a
submodule, and **`tests/game/mods/cbfixture`**, which registers nothing but the
three mapgen aliases the engine validates at startup.

**It used to hold empty `default` and `wool` stubs as well.** `F11` dropped both
dependencies — the mod registers its own 105 nodes now — and the two stubs went
with them, `cbfixture` taking over the mapgen aliases. If a spec needs a node the
mod does not provide, register that one node in `cbfixture` and no more.

The game cannot live in the repository, because it has to contain the repository
as one of its mods. `scripts/run_tests.ps1` assembles it in
`%APPDATA%\Minetest\games\cbtest`: `tests/game` copied for `game.conf` and
`cbfixture`, plus a junction for the mod itself.

If a submodule was never initialised, the boot fails on `vector3`:

```bash
git submodule update --init --recursive
```

## Two versions of `vector3`, and only one of them tested

`mod.conf` reads `depends = vector3` and **Luanti has no version constraints**,
so a player may have either release installed. The submodule was bumped from
**v1.5 (`1662164`)** to **v2.0.1 (`5077617`)**, and **that bump changes the test
fixture only; it changes nothing a player has.** So a green suite proves
codeblock works against v2.0.1 and says nothing about v1.5.

| | v1.5 | v2.0.1 |
|---|---|---|
| `vector.one.x = -1` | accepted, changes `one` server-wide | raises `read only` |
| `vector.fromPolar('a', 1)` | returns nothing | raises `format error` |
| `vector.srandom('a', 1)` | returns `(0,0,0)` silently | raises `format error` |
| `pairs(vector.one)` | 3 keys | 0 keys |
| `vector(1,2,3).__index` | table | table (`S9`, unfixed on both) |

**The raises are an improvement for a player.** `srandom` answering `(0,0,0)` for
a bad argument is silently wrong geometry, which is worse than nil.

**`pairs` is the trap.** 2.0's `frozen()` (`vector3.lua:370`) builds an *empty*
table with `__index` onto a private backing vector, so `next`, `rawget`, `pairs`,
`table.copy` and `core.serialize` all read a constant as empty — silently, and
not as a raise.

**`.luacheckrc:75` excludes `tests/game/mods/vector3/**`**, so luacheck's silence
says nothing about the bumped library. That is correct — it is another package
with its own gates — but it is not coverage.

## What CI does not prove

**CI boots no engine** (`C24`). The `test` job installs plain Lua 5.1 and runs
the six standalone specs; nothing starts Luanti. So `forms_spec`, `stepper_spec`
and `integration_spec` never run in a pull request, and neither does any
engine-guarded case inside the other six — `preprocess_spec`'s enumeration of
`lib/examples/` needs `core.get_dir_list` and runs only in a local
`run_tests.ps1`. A pull request sees the standalone line and goes green.

## The one thing that must not be skipped

Enabling the suite means writing `codeblock_run_tests = true` into the **real
user config** at `%APPDATA%\Minetest\minetest.conf`. Luanti's `--config` flag
does not work for this — it is silently ignored, verified by setting `port` in a
file passed that way and watching the server bind the default anyway.

So the setting goes into the config the player actually uses, and **must be
removed afterwards**, or every ordinary launch runs the test suite and prints to
their console. `run_tests.ps1` strips it in a `finally` block, so it is removed on
the failure path too — but check, do not assume.

## Procedure

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

`-KeepWorld` leaves the world directory for inspection; otherwise it is a
throwaway under `%TEMP%`. `-Exe <path>` overrides the engine location, which
defaults to `%LOCALAPPDATA%\luanti\5.17.0\bin\luanti.exe`. `-Seconds <n>` extends
the wait if a slower machine has not finished booting in 25.

Two things the script does that are worth knowing before editing it. It removes
the junction with `rmdir` and never with `Remove-Item -Recurse`, which follows a
junction and would delete the repository behind it. And it strips the setting in a
`finally`, so an exception between boot and kill still cleans up.

Running a single spec in-engine means editing the `specs` list at the bottom of
`init.lua`. That block probes for `tests/api_spec.lua` first and only warns if it
is missing, because `tests export-ignore` keeps the specs out of the ContentDB
archive and an unguarded `dofile` took the mod down on a release install (audit
C16). Running the six standalone specs needs no engine at all:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && for s in api preprocess env shapes strguard limits; do lua5.1 tests/${s}_spec.lua; done'
```

## Reading the result

A healthy run prints one summary per spec, and `none` under errors. As of
2026-09-03, at the commit that decoupled the drone record from its entity
(B50, B52):

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
still 0 failed, 0 xpass, 1 known xfail, none skipped.

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
- **skipped** — a spec that needs the mod and did not find it. In the in-engine
  run, with the fixture in place, this should never appear: it means the mod
  failed to load, so investigate rather than accept it. **In a standalone run it
  can be legitimate**, and one case is: `preprocess_spec` prints
  `skipped: the shipped examples match the list, both ways - not checked here:
  needs core.get_dir_list, in-engine only`, because the directory enumeration
  that closes `C23` exists only in-engine. That is also why the spec reads **56
  standalone against 57 in-engine** — the guarded case counts once instead of
  twice, and it is not a discrepancy.

**Write a spec's can't-run note to survive the filter.** It keeps only lines
matching `passed|failed|FAIL|want|got|skipped|xfail`, so a note worded any other
way vanishes from the report — the exact silence a can't-run note exists to
break. Start it with `skipped:`.

If nothing prints at all, the mod did not load. Look in the error output for
`ModError` and read the traceback — a syntax error in any `lib/*.lua` stops the
whole mod.

## Before concluding it passes

- No `ModError` in the error stream, and the errors section says `none`.
- All nine specs reported, none skipped.
- `0 failed` and `0 xpass` everywhere.
- The setting is gone from `minetest.conf` — check, do not assume:
  `grep -n codeblock_run_tests "$APPDATA/Minetest/minetest.conf"`.
The script used to damage that file in two ways the grep could not see: it wrote
a UTF-8 BOM, killing the config's first setting, and it appended the enable line
with no separator on a file lacking a trailing newline. Both are fixed (audit
B31, B32) — the writes go through `[IO.File]` with an explicit no-BOM encoding,
and reading with `ReadAllText` strips a mark already there, so a damaged config
is repaired by the next run. Worth knowing if an old config still looks wrong:
`head -c 3 "$APPDATA/Minetest/minetest.conf" | od -An -tx1` should not be
`ef bb bf`.

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
  reads a program out of the player's directory — so `ramp_over`'s 57 assertions
  reach it by **writing a file into the throwaway world** and running it. That is
  legitimate: it was driven to failure eight ways, against eight mutations of
  `lib/sandbox.lua`. **Exporting `getScriptEnv` to avoid the write was offered
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
