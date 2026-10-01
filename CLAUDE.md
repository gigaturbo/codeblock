# CLAUDE.md

## What this is

CodeBlock is a Luanti (formerly Minetest) **mod** that adds programming to the
game: a Lua sandbox, a drone that builds what the program says, an in-game
editor, and the player-facing API those three share. Essentially all the logic
lives here. Its own ContentDB package, its own CI, its own tests, its own
documentation and its own release path, branch `master`. AGPL-3.0-only.

It depends on `vector3`, another ContentDB package by the same author, vendored
as a submodule under `tests/game/mods/` so the specs have a game to boot in.

A game called `codecube` embeds this mod and presents it to players. It is a
**downstream consumer of releases**: it pins one, adopts a new one on its own
schedule, and keeps a wholly separate record. Nothing here depends on it. **Do
not read it, report on it, or change it from here.**

## Layout

- [init.lua](init.lua) dofiles `lib/` in a load order that matters, and runs the
  suite when the setting asks for it.
- [lib/](lib/) the whole mod, one file per topic. The run pipeline is
  `preprocess`, `env`, `sandbox`, `stepper`, `limits`, `strguard`; the drone is
  `drone`, `drone_entity`, `commands`, `cost`, `shapes`; the interface is
  `forms`, `formspecs`, `hud`; the content is `nodes`, `blocks`, `palette`,
  `config`, `api`. `register.lua` owns every engine registration and the
  globalstep.
- [lib/examples/](lib/examples/) the shipped example programs, player code.
- [scripts/](scripts/) the generators and the local test runner. Not shipped.
- [tests/](tests/) ten specs, and `tests/game/` the fixture game they boot in.
  Not shipped.
- [doc/api.md](doc/api.md) the player's API reference. Generated below its
  `# Lua api` heading, hand-written above it. Shipped.
- [CONTENTDB.md](CONTENTDB.md) the source of the ContentDB long description.
  `.cdb.json` is generated from it. Neither ships.
- [CHANGELOG.md](CHANGELOG.md) what shipped, for someone using this mod in any
  game. Shipped.
- [BACKLOG.md](BACKLOG.md) all open work, with what has closed compressed below
  it. Not shipped.

## Architecture

**A player's program is instrumented, sandboxed and resumed under a budget.**
`lib/preprocess.lua` inserts a counter call into the source, `lib/env.lua` and
`lib/sandbox.lua` build the environment the program runs in, and
`lib/stepper.lua` resumes its coroutine from one globalstep until the step's
time budget is spent. `lib/limits.lua` holds the budget.

**The drone record and its entity are separate.** `lib/drone.lua` owns the
lifecycle; `lib/drone_entity.lua` is a view that can disappear and come back.

**`lib/api.lua` is pure data and the single description of the API.** The
sandbox environment, the in-game help panel and `doc/api.md` all derive from it.

**The security boundary is the environment table plus the read-only API
surface**, never the forbidden-name list.

Everything else is in the `codeblock-kb` skill: the constraints each area
carries, the decisions already argued out, the in-world check recipes, and the
release gate. **Read the reference for the file you are about to touch.**

## Commands

No arguments are needed from outside the repository root. `lua5.1` and
`luacheck` live in WSL, not on Windows.

**Test.** The suite runs inside Luanti, against the fixture game in
`tests/game`. All ten specs run this way, and so does CI.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

**Test, standalone.** Seven of the ten also run under plain Lua 5.1, which is
the only thing that catches 5.1 differing from the engine's LuaJIT.

```powershell
wsl bash -lc 'lua5.1 tests/api_spec.lua; lua5.1 tests/preprocess_spec.lua; lua5.1 tests/env_spec.lua; lua5.1 tests/shapes_spec.lua; lua5.1 tests/strguard_spec.lua; lua5.1 tests/limits_spec.lua; lua5.1 tests/palette_spec.lua'
```

Each spec is named because **a shell variable does not survive this machine's
WSL layer**. `for s in ...; do lua5.1 tests/${s}_spec.lua; done` reaches bash with
`${s}` already gone, whatever the quoting, and runs `tests/_spec.lua` six times:
six *cannot open* lines and nothing that reads as a gate failing.

**Lint and the three generators**, all of them run by CI too.

```powershell
wsl bash -lc 'luacheck . --formatter plain --codes'
wsl bash -lc 'lua5.1 scripts/gen_docs.lua --check'
wsl bash -lc 'lua5.1 scripts/gen_locale.lua --check'
wsl bash -lc 'lua5.1 scripts/gen_settingtypes.lua --check'
```

`LUACHECK_STRICT=1` reports what the baseline exemptions hide. Drop `--check` to
write. `bash scripts/gen_cdb_json.sh` regenerates `.cdb.json` after a
`CONTENTDB.md` edit and prints nothing either way.

**Read the output, not the exit code.** `$?` does not survive this machine's WSL
layer, so a gate is green when it *says* so: luacheck silent, each generator
*up to date*, and one verdict line reading `10/10 specs`, `0 failed`, `0 xpass`,
`0 skipped`.

**Report.** Rebuilds `.reports/backlog.html` from the JSON.

```powershell
py -3 $HOME/.claude/skills/project-architecture/tools/gen_report.py --json .reports/backlog.json --out .reports/backlog.html --backlog BACKLOG.md
```

## Packaging

`mod.conf` declares `min_minetest_version = 5.4`, no ceiling, and
`depends = vector3`. ContentDB builds a release with `git archive`, so anything
without an `export-ignore` rule in [.gitattributes](.gitattributes) reaches
players, and nothing in CI checks it. Verify the archive rather than read the
rules:

```powershell
git archive --format=tar -o $env:TEMP\archive-check.tar HEAD
tar -tf $env:TEMP\archive-check.tar | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique
```

`screenshot.png` must survive, Luanti showing it in the main menu's Mods tab,
and so must `doc/api.md`, the shipped README telling the player to read it. The
whole release procedure and its ten-gate check are in the `codeblock-kb` skill.
