# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in the `codeblock` repository.

## What this is

CodeBlock is a Luanti (formerly Minetest) **mod** that adds programming to the
game: a Lua sandbox, a drone that builds what the program says, an in-game
editor, and the player-facing API those three share. It is the main project —
essentially all the logic lives here. It has its own ContentDB package, its own
CI, its own tests, its own documentation and its own release path, and it
depends on `vector3`, another package by the same author.

The `codecube` game embeds this mod as a submodule and makes it pleasant to
play. It is a *consumer* of releases, not a co-branch: see the root
`CLAUDE.md` two directories up for the relationship, the submodule policy, the
shared response style, the shared editing, coding and helper rules, and the
`.gitattributes` hazard that applies to both packages. Nothing in this file
repeats them.

One thing is not separable, and it is worth knowing before you plan a test run:
the in-engine specs boot the **game**. `run-tests` launches
`luanti.exe --server --gameid codecube`, so the mod cannot exercise its
in-engine specs without `codecube` installed. That is why the tooling and the
`.claude/` directory live in the game's tree rather than here.

## The mod's record

Four documents, all in this directory. This is the main project, so this is the
main record; the game keeps its own four, of the same shape, and neither restates
the other.

- `ROADMAP.md` — the one to read first, in either repository. What is left to
  do, fix or change in this mod, in order.
- `TODO.md` — intentions that are not findings. One line per item, a finding id
  where there is one.
- `CHANGELOG.md` — what shipped, for someone using the mod in any game.
- `.audit/audit.html` — **this mod's own audit, and the main one of the two.**
  Every finding with its id, severity, state and, once fixed, how, plus the
  reasoning `ROADMAP.md` leaves out. Its phases (`Phase 0`–`Phase 8`) are the
  numbers commit messages quote and are never renumbered.

Finding ids are allocated once across both audits, so a number never means two
things and is never renumbered; a gap in the sequence here is a finding whose
work is the game's. The game orders its own work as `G1`–`G5` and never says
"Phase N".

`.audit/` must not be committed. **This repository has no `.gitignore` yet**, so
the audit currently shows up as untracked — adding one containing `.audit/` is on
`TODO.md`. `.gitattributes` already keeps it out of the release archive via
`.*  export-ignore`.

The `project-manager` agent owns all four; edit one by hand only for something
that agent cannot know.

## Commands

The full test suite runs **inside Luanti**. Use the `run-tests` skill — it owns
the procedure. The one thing to know without reading it: enabling the suite
writes `codeblock_run_tests = true` into the player's real config, and it must
be removed afterwards or every ordinary launch runs the tests.

Six specs also run standalone under a Lua 5.1 interpreter, which is how CI runs
them and the only way to catch behaviour differing between plain 5.1 and the
LuaJIT the game uses:

```bash
lua tests/api_spec.lua    # also preprocess_spec, env_spec, shapes_spec, strguard_spec, limits_spec
```

`forms_spec`, `stepper_spec` and `integration_spec` are in-engine only — they
need `codeblock.forms`, the real command budget and `codeblock.commands`. Faking
those would mean testing the fake. Running a single spec in-engine means editing
the `dofile` list in `init.lua`.

The rest, all run by **this repository's** CI and none of them by the game's:

```bash
luacheck . --formatter plain --codes
lua scripts/gen_docs.lua --check    # doc/api.md matches the code
bash scripts/gen_cdb_json.sh        # regenerate after a README edit
```

`LUACHECK_STRICT=1` reports what the baseline exemptions hide. `gen_cdb_json.sh`
is the one script here nothing verifies — the game's copy is checked by
`check_game.sh`, this one by nobody.

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
player programs, which are data the game cannot migrate — that is a major version
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

Every setting here is the mod's, not the game's. The game contributes its own
settings — mapgen, daylight, build restrictions — and the two do not mix.

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

These bite in any Luanti Lua, so they hold for the game's own mods too.

- `minetest` is a permanent alias for `core` and is **not** deprecated.
- Lua 5.1 / LuaJIT: `loadstring`, `setfenv`, `math.pow`, `math.atan2` all exist;
  `0` is truthy; you cannot yield across `pcall`.
- Mod security blocks writes into a mod's own directory, so
  `codeblock_gen_docs=true` writes `api.md` into the world directory to be copied
  over by hand.
