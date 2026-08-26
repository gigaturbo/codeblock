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

Luanti will not load a mod whose `depends` are unmet, and `mod.conf` names
`default`, `wool` and `vector3`. So `tests/game` is a game whose whole purpose is
to satisfy that: `game.conf` on singlenode, empty `default` and `wool` stubs, and
`vector3` as a submodule. The mod calls no function from `default` or `wool` and
borrows no asset from them — the only use is the node names in the palette tables
of `lib/config.lua` — so the stubs register nothing but the three mapgen aliases
the engine validates at startup.

The game cannot live in the repository, because it has to contain the repository
as one of its mods. `scripts/run_tests.ps1` assembles it in
`%APPDATA%\Minetest\games\cbtest`: `tests/game` copied for `game.conf` and the
stubs, plus a junction for the mod itself.

If a submodule was never initialised, the boot fails on `vector3`:

```bash
git submodule update --init --recursive
```

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

Running a single spec in-engine means editing the `dofile` list at the bottom of
`init.lua`. Running the six standalone ones needs no engine at all:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && for s in api preprocess env shapes strguard limits; do lua5.1 tests/${s}_spec.lua; done'
```

## Reading the result

A healthy run prints one summary per spec, and `none` under errors:

```
  api_spec              30 passed   0 failed
  preprocess_spec       54 passed   0 failed   1 xfail (known defects)   0 xpass
  env_spec              21 passed   0 failed
  shapes_spec           27 passed   0 failed
  strguard_spec         29 passed   0 failed
  limits_spec           36 passed   0 failed
  forms_spec            35 passed   0 failed
  stepper_spec          35 passed   0 failed
  integration_spec      59 passed   0 failed
```

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
- **skipped** — a spec that needs the mod and did not find it. With the fixture in
  place this should never appear: it means the mod failed to load, so investigate
  rather than accept it.

If nothing prints at all, the mod did not load. Look in the error output for
`ModError` and read the traceback — a syntax error in any `lib/*.lua` stops the
whole mod.

## Before concluding it passes

- No `ModError` in the error stream, and the errors section says `none`.
- All nine specs reported, none skipped.
- `0 failed` and `0 xpass` everywhere.
- The setting is gone from `minetest.conf` — check, do not assume:
  `grep -n codeblock_run_tests "$APPDATA/Minetest/minetest.conf"`.

## Related

`scripts/gen_docs.lua --check` verifies the API reference is current, and
`luacheck` lints. Both run in CI and neither is run by this skill:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && luacheck . --formatter plain --codes && lua5.1 scripts/gen_docs.lua --check'
```
