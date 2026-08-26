# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in the `codeblock` repository. The response, editing, coding and helper
conventions are in `~/.claude/CLAUDE.md` and are not repeated here.

## What this is

CodeBlock is a Luanti (formerly Minetest) **mod** that adds programming to the
game: a Lua sandbox, a drone that builds what the program says, an in-game
editor, and the player-facing API those three share. Essentially all the logic
lives here. Its own ContentDB package, its own CI, its own tests, its own
documentation and its own release path, branch `master`.

It depends on `vector3`, another ContentDB package by the same author, vendored
here as a submodule under `tests/game/mods/` so the specs have a game to boot in.

A game called `codecube` embeds this mod and presents it to players. It is a
**downstream consumer of releases, maintained by the same author** — it pins a
release, adopts a new one on its own schedule, and keeps a wholly separate
record. It is developed in its own checkout and nothing here depends on it. Do
not read it, report on it, or change it from here.

## The record

Four documents, all in this directory, plus the `.claude/` definitions:

- `ROADMAP.md` — the one to read first. What is left to do, fix or change, in
  order.
- `TODO.md` — intentions that are not findings. One line per item, a finding id
  where there is one.
- `CHANGELOG.md` — what shipped, for someone using this mod in any game.
- `.audit/audit.html` — every finding with its id, severity, state and, once
  fixed, how, plus the reasoning `ROADMAP.md` leaves out. Its phases
  (`Phase 0`–`Phase 8`) are the numbers commit messages quote and are never
  renumbered. Gitignored, so it never travels with a commit.

Finding ids — `B` bugs, `S` sandbox and security, `C` compliance and packaging,
`A` architecture — are **never renumbered**, because commit messages cite them. A
gap in a sequence is a finding that was routed to the game's own audit back when
the two projects shared one record.

The `project-manager` agent owns all four and the `.claude/` definitions beside
them; edit one by hand only for something that agent cannot know.

## Commands

The full suite runs **inside Luanti**, against the fixture game in `tests/game`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

All nine specs run this way. The `run-tests` skill owns the procedure and the
detail; the one thing to know without reading it is that enabling the suite
writes `codeblock_run_tests = true` into the player's real config, and it must be
removed afterwards or every ordinary launch runs the tests. The script strips it
in a `finally` block.

**`tests/game` exists because Luanti will not load a mod whose `depends` are
unmet.** `mod.conf` names `default`, `wool` and `vector3`, but this mod calls no
function from `default` or `wool` and borrows no asset from them — the only use is
the node names in the palette tables of `lib/config.lua`. So the stubs there
register nothing but the three mapgen aliases the engine validates at startup. If
a spec ever needs a real node, register that one node and no more.

Six specs also run standalone under a Lua 5.1 interpreter, which is how CI runs
them and the only way to catch behaviour differing between plain 5.1 and the
LuaJIT the engine uses:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && for s in api preprocess env shapes strguard limits; do lua5.1 tests/${s}_spec.lua; done'
```

`forms_spec`, `stepper_spec` and `integration_spec` are in-engine only — they need
`codeblock.forms`, the real command budget and `codeblock.commands`. Faking those
would mean testing the fake. Running a single spec in-engine means editing the
`dofile` list in `init.lua`.

The rest, all run by this repository's CI:

```bash
luacheck . --formatter plain --codes
lua scripts/gen_docs.lua --check    # doc/api.md matches the code
bash scripts/gen_cdb_json.sh        # regenerate after a README edit
```

`LUACHECK_STRICT=1` reports what the baseline exemptions hide. `gen_cdb_json.sh`
is the one script here that nothing verifies.

Reading a result: `failed` must be 0, and so must `xpass`. An `xfail` that now
passes either means a defect was fixed and the test should be promoted, or the
code path stopped running and the assertion passes vacuously. The second has
happened here.

## Architecture

### Running a player's program

The pipeline spans several files and is the thing worth understanding first.

1. **`lib/preprocess.lua`** instruments the source over a token stream, inserting
   `_G.use_call()` after every `do`, every `repeat`, every function parameter
   list, and before every `goto`. That is what makes loops and calls pay into a
   budget, so a runaway program stops instead of freezing the server. Free of any
   Luanti dependency so it can be tested standalone. It also reports forbidden
   identifiers — a message-quality feature, *not* the security boundary.
2. **`lib/env.lua`** builds the environment. `snapshot` gives each run its own
   copy of the API's tables — copies, not read-only proxies, because Lua 5.1 has
   no `__pairs` or `__len` and a proxy would break `pairs(blocks)` for player
   code. `new_env` makes API names unassignable, which is what stops a program
   reaching the injected counter.
3. **`lib/sandbox.lua`** pairs every name with an implementation, calls
   `api.build`, `setfenv`s the chunk, returns a coroutine.
4. **`lib/stepper.lua`** resumes that coroutine repeatedly each server step until
   a time budget is spent, so throughput follows spare headroom rather than the
   tick rate. That budget is the smaller of the codelevel cap and an equal share
   of one server-wide pool, so N drones do not cost N budgets. It is published as
   `drone.deadline` and checked at every drone command and every slab of a shape
   as well as between resumes, so what overshoots it is one slab. The step also
   charges the time it spent against `max_runtime_s` — the bound on a program
   that never finishes — and skips a drone that is asleep (`drone.wake_at`).
5. **`lib/limits.lua`** holds the run's budget: every ceiling converted once into
   the unit it is checked in, with its counter beside it. `charge` for what is
   spent (nodes, runtime) and stops the run; `hold` for the map footprint, which
   decays over the engine's unload window and makes the drone *wait* rather than
   fail. Dependency-free, so it is tested standalone.
6. **`lib/strguard.lua`** bounds `rep` and `gsub` on the shared string metatable
   for the span in which player code runs. Leaving `string` out of the
   environment is not enough: every Lua 5.1 string shares one metatable, so
   `("x"):rep(1e9)` is reachable from any literal.

The security boundary is the environment table plus the read-only API surface,
not the forbidden-name list.

### The API has one source

`lib/api.lua` is pure data and the single description of everything a program can
call. Three things derive from it: the sandbox environment, the in-game help
panel (`api.to_hypertext`), and `doc/api.md` (`api.to_markdown`). `api.build`
raises if description and implementations disagree **in either direction**, so
the mod refuses to load rather than ship a reference that lies, and
`gen_docs.lua --check` fails CI if the committed Markdown has drifted.

Changing a player-facing name means editing `lib/api.lua`, the `impls` table in
`lib/sandbox.lua`, and regenerating `doc/api.md`. Such a change breaks saved
player programs, which are data no game can migrate — that is a major version
bump.

### Per-codelevel limits

Seven limits in `lib/config.lua` are four-element arrays indexed by the player's
codelevel (1–4): `pace_ms`, `step_budget_us`, `max_runtime_s`,
`max_nodes_written`, `map_memory_mb`, `heap_mb`, `max_string_mb`. Each stands for
a resource the server spends; counts of calls, commands, volume, distance and
dimension were proxies and are gone. Codelevel bounds resource use, so it is
privileged — never let players set their own. Adding a limit means adding a row
to the codelevel table in `doc/api.md`; `gen_docs.lua` enforces that, because a
limit once shipped undocumented.

Every one of those tables can be overridden from the settings menu or
`minetest.conf`, as four comma-separated numbers, plus the scalars
`default_auth_level` and `server_step_budget_us`. `settingtypes.txt` only *draws*
that menu — the engine does not read it for defaults, so it is a hand-kept mirror
of the literals here and its own header says so. `map_window_s` is not a
codeblock setting at all: it is read from the engine's
`server_unload_unused_data_timeout`, because the map footprint decays over
exactly that window. Two constraints in `config.lua` exist for reasons that are
not local to it, so check before changing either. The tables stay **plain
literals** with the overrides applied in one loop afterwards, because
`gen_docs.lua` greps this source for a name assigned a table whose first element
is a number — a computed value turns that documentation check off without
failing. And every settings read is guarded with `rawget(_G, 'minetest')`,
because `gen_docs.lua` dofiles `config.lua` under a bare interpreter with no
engine global.

`config.lua` keeps the units a player and an administrator read — seconds,
megabytes, milliseconds. `limits.new` converts them once, and nothing else does
the arithmetic. A retired setting name still in someone's `minetest.conf` warns
at load and names its replacement, from the `replaced` table.

Every setting here is this mod's. A game that embeds it contributes its own —
mapgen, daylight, build restrictions — and the two do not mix.

### Writing to the world

`lib/shapes.lua` owns the four bulk shapes (cube, sphere, dome, cylinder) through
`shapes.build(spec)`, in mapblock-aligned slabs of `SLICE_BLOCKS` — one VoxelManip
pass each, with `spec.charge` called before every pass and free to yield. A pass
cannot be interrupted, so the slab size *is* the longest stall the mod can cause;
that is what lets a shape be any size at all. Every filler clips itself to the
area it is handed rather than to a range passed in, which keeps the clip equal to
the extent the data array covers.

Single-node `place()` lives in `lib/commands.lua` and must call `core.load_area`
first: `set_node` into a mapblock that is not in memory silently does nothing,
which used to leave holes in builds far from spawn. Bulk shapes need no such
call — `read_from_map` emerges the region itself.

`place_block` makes that call only when the drone crosses into a new mapblock,
comparing `floor(x/16)` on three axes against the last write, and takes footprint
for each crossing. Two things about that memo are load-bearing. `load_area` does
not trigger mapgen, so what a load costs is a resident MapBlock plus a disk read —
and `heap_mb` cannot see it (`collectgarbage('count')` is the Lua heap; a MapBlock
is C++ side), which is why `map_memory_mb` exists. And the memo is **per-resume,
not per-run**: `release` clears `drone.bx/by/bz` before every yield, and it is the
only yield in the file for exactly that reason. Widening its lifetime brings back
the silent lost write the `load_area` call was added to fix.

Bulk shapes are charged too, per slab, through the `slabs(drone)` callback.
Without it, `cube(1,1,1)` in a loop bypasses the ceiling exactly.

Untested by the specs: they run at mod load, before a map exists, so nothing
exercises `place()` itself. What was checked by hand in a running world (S5):
the memo, the per-crossing charge and the per-resume reset all behave, a mapblock
costs 16.3 kB resident, and the engine serves about 1700 loads a second.

### Formspecs

`lib/forms.lua` is a per-player form session on `core.show_formspec`: state that
survives a redraw, field routing, cleanup on leave, one form per player.
`lib/formspecs.lua` builds the editor itself. Handlers are
`handler(meta, player, fields)`, where `meta` is the same table across redraws.

### `drone.lua` vs `drone_entity.lua`

These do not divide by responsibility, and the drone record has no single owner
(audit A11, tracked in `TODO.md`). Expect to re-derive the invariant when
touching either.

## Environment notes

- `minetest` is a permanent alias for `core` and is **not** deprecated.
- Lua 5.1 / LuaJIT: `loadstring`, `setfenv`, `math.pow`, `math.atan2` all exist;
  `0` is truthy; you cannot yield across `pcall`.
- Mod security blocks writes into a mod's own directory, so
  `codeblock_gen_docs=true` writes `api.md` into the world directory to be copied
  over by hand.
