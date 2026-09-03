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

Five documents in this directory, plus this file, the `.claude/` definitions and
the gitignored HTML renderings:

- `ROADMAP.md` — the one to read first. What to do next, in order; the phases
  (`Phase 0`–`Phase 10`) and the `F` feature series; and **the log of what was
  agreed** — a feature's shape as settled, a part argued out, a rewording, a
  default chosen. Nothing else records those. Three of those phases are three
  releases: `Phase 8` is v1.0.0, `Phase 9` is v1.x.y, and `Phase 10` is v2.0.0
  and holds nothing but the Blockly editor.
- `TODO.md` — the author's inbox and wanted-features list. One line each. A
  `FIX:` or `BUG:` line there is a hand-off: it gets a finding id in `AUDIT.md`
  and stays in `TODO.md` until the author deletes it.
- `AUDIT.md` — every finding with its id, severity, state and, once fixed, how,
  plus the reasoning a future change would otherwise re-break. Findings only; no
  roadmap and no features.
- `CHANGELOG.md` — what shipped, for someone using this mod in any game.
- `PLAYTEST.md` — the manual checks no spec can reach, each with what to do
  in-world, what a pass looks like, its finding id, and a result line carrying
  the commit, engine version and date, so a stale pass reads as stale. It is a
  record document, not a spec.
- `.reports/*.html` — browsable renderings of `ROADMAP.md`, `AUDIT.md` and
  `PLAYTEST.md`, gitignored.
  **Presentation only:** every fact in them is in the tracked Markdown, so a
  deleted `.reports/` costs nothing.

`AUDIT.md` and `PLAYTEST.md` each carry their own `export-ignore` line in
`.gitattributes`, so neither ships to a player.

Finding ids — `B` bugs, `S` sandbox and security, `C` compliance and packaging,
`A` architecture — are **never renumbered**, because commit messages cite them. A
gap in a sequence is a finding that was routed to the game's own audit back when
the two projects shared one record. `F` is a fifth series, features, allocated
when `Phase 8` became the feature phase; `F` ids are this project's own, are
quoted in commit messages the same way, and are never renumbered either.

The `project-manager` agent owns all six, `CONTENTDB.md` and the `.claude/`
definitions beside them; edit one by hand only for something that agent cannot
know — recording the outcome of a playtest run is exactly such a thing.

**These documents are the project's memory for an agent, and there is no other
store.** What the author asked for, decided or corrected is written into the one
whose subject it is — a decision in `ROADMAP.md`, a request in `TODO.md`, a
working convention here — because a note kept anywhere machine-local is invisible
to a checkout on another machine and to the next session. If it is not in the
repository, it will be re-litigated.

**Three agents divide the work, by what each can be trusted with.**
`project-manager` keeps the record and calls the other two; **`code-expert`** owns
`lib/`, `init.lua`, `scripts/`, `settingtypes.txt`, `locale/` and the generators
over them, and reads the `code-standards` skill before writing; **`test-agent`**
owns `tests/*_spec.lua`, the suite, the gates and the evidence side of
`AUDIT.md`, through the `run-tests` skill. Two more are read-only and verify
rather than change: `release-check` and the global `code-improver`. The split is
the point — an agent that both makes a change and reports on it can be trusted
for neither.

## How a feature gets built here

Six steps, which `F1` established and every `F` item follows. **The procedure is
the `build-feature` skill** (`.claude/skills/build-feature/SKILL.md`) — read it
before starting, resuming or reviewing an `F` item. Two of its steps need the
author in person, so it is a skill and not a subagent.

Two rules from it are repeated here because both were nearly lost:

- **A feature is done when it is committed with its gates green** — not when it
  works locally. Its in-world checks being run is a separate thing again, and
  `PLAYTEST.md` is where that is tracked.
- **Nothing in a running world is provable by the specs.** They run at mod load,
  before a map, a player or a user directory exists. Anything touching a
  formspec, player meta, the filesystem or the world needs a playtest entry.

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
`specs` list in `init.lua`, which is guarded by a probe for `tests/api_spec.lua`
— `tests` is `export-ignore`d, so a release build has no specs to load and says
so rather than failing to load (C16).

The rest, all run by this repository's CI:

```bash
luacheck . --formatter plain --codes
lua scripts/gen_docs.lua --check         # doc/api.md matches the code
lua scripts/gen_locale.lua --check       # locale/template.txt matches the code
lua scripts/gen_settingtypes.lua --check # settingtypes.txt matches lib/config.lua
bash scripts/gen_cdb_json.sh             # regenerate after a CONTENTDB.md edit
```

`LUACHECK_STRICT=1` reports what the baseline exemptions hide. `gen_cdb_json.sh`
is the one script here that nothing verifies. Both `--check` scripts run under a
bare Lua 5.1 with no engine global; `gen_locale.lua` also lists `lib/` through
`ls`, so it wants a POSIX shell rather than a hand-kept list of its own inputs —
that being the same defect one level up. `gen_locale.lua --check` fails on
`locale/template.txt` only: it
also reports which `.tr` files are incomplete, but an untranslated message
legitimately falls back to English, while a template that lies about what needs
translating does not (C17).

**Read the output, not the exit code.** `$?` does not survive this machine's WSL
layer, so a gate is green when it *says* so — `doc/api.md is up to date`,
`locale/template.txt is up to date`, luacheck silent.

Reading a result: `failed` must be 0, and so must `xpass`. An `xfail` that now
passes either means a defect was fixed and the test should be promoted, or the
code path stopped running and the assertion passes vacuously. The second has
happened here.

**What no spec reaches, and where it is written down.** The suite runs at mod
load, before a map, a player or a user directory exists, so the editor, the
filesystem, drone placement and every write into the world have no coverage and
cannot have. Those checks are a tracked checklist in **`PLAYTEST.md`**,
each with a result line, the commit it was checked at and the date. Do a run
before calling anything verified in a running world, and record the outcome
there.

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

**`doc/api.md` is only generated from the `# Lua api` heading onward, and the
part above it is hand-written and checked by nothing.** `gen_docs.lua` says so in
its own comments; what sits above the marker is `# Codelevel` and
`# Chat commands`, neither of which the generator writes and neither of which
`--check` reads. So the gate can report *doc/api.md is up to date* over a chat
command that no longer exists, which is exactly what it did while `F10` renamed
`/codelevel` and `/codegenerate` (2026-09-03). **Edit that region by hand when a
command or a codelevel limit changes, and do not read a green `--check` as
covering it.** It is the same family as `C17`, `C19` and `C20` — a mirror of the
source that drifts in silence — except that here the blind spot is by design:
the region describes chat commands and privileges, which `lib/api.lua` knows
nothing about.

### Three mirrors of the source, all three now generated

Three files here restate the source, are read by a human or by ContentDB rather
than by the code, and so **drift silently — nothing fails when they are wrong**.
`doc/api.md` drifted and got `gen_docs.lua --check`. `locale/template.txt`
drifted twelve messages one way and seventeen the other and got
`gen_locale.lua --check` (C17). **`settingtypes.txt` was the third and got
`gen_settingtypes.lua --check`** on 2026-09-02: it only *draws* the settings
menu, the engine reads no defaults from it, and every value in it was a hand-kept
copy of a literal in `lib/config.lua`. The pattern the three of them are: a note
about remembering does not hold, a `--check` in CI does.

**What that generator can and cannot promise.** It derives the **numbers** from
`lib/config.lua` and **owns the words** — `config.lua`'s comments are for whoever
edits the code, the menu's descriptions are for an administrator, and one file
cannot serve both. So it guarantees the defaults agree and nothing about the
prose. What it adds beyond that is a **completeness check in both directions**: a
setting `config.lua` reads that the menu does not offer, or a menu entry nothing
reads, fails the check by name.

**A check that cannot fail is indistinguishable from a check that passes.** Two
here were written, committed, believed and matched nothing: `gen_docs.lua`'s
documented-limit guard first listed three name prefixes that missed every limit
being added, and its replacement matched by shape with `%w+` — and **Lua's `%w`
excludes the underscore that every limit name contains**, so it matched nothing
at all from the day it was written (C20). Both generators are now `[%w_]+`, and
both have been run against a deliberately undrawn limit and seen to exit 1.
**Make a new check fail once before trusting it.**

**`.cdb.json` is a fourth file of the same family and failed differently, which is
why a `--check` would not have saved it.** It is generated by
`scripts/gen_cdb_json.sh`, so it never drifted — for the project's whole life it
was faithfully generated from the wrong source, `README.md`. ContentDB's rules say
a long description must not repeat the title or the short description, must not
link to the repository or to its own ContentDB page, must not carry licence text
or API documentation, and **must not contain images, which are not visible inside
Luanti at all**. A good README is all of those things, and that one broke six
rules at once (`C19`, resolved 2026-08-28). The source is now **`CONTENTDB.md`**,
written for someone on the package page: edit that and run the generator, never
`.cdb.json`. What is still hand-kept is its recent-changes list against
`CHANGELOG.md`, and nothing checks the two agree. The lesson generalises past this
file: **a generator guarantees the output matches its input, and nothing more.**

Three rules for a string a player sees, the first two learned from C17:

- **Never build a translation key with `..`.** The literal argument to `S()` *is*
  the key, so a concatenated one cannot be extracted, cannot be translated, and
  nothing reports it. One line in `lib/register.lua` was in that state for the
  whole project's life.
- **Never edit a key in the source alone.** A trailing space, a plural or a
  capital orphans the existing translation with no error anywhere, and it still
  looks translated in the `.tr` file. Three messages were in that state. Only a
  diff of the two key lists sees it, which is what the new check is.
- **A new `S()` key ships English-by-default and nothing fails.**
  `gen_locale.lua --check` fails on `locale/template.txt` only; an incomplete
  `.tr` it merely *reports*, which is correct, because an untranslated message
  legitimately falls back to English. The consequence is that **a feature adding
  player-facing strings is not finished until the `.tr` files are written, and
  the only thing that will tell you is playing it in another language.** `F10` is
  the first feature here to demonstrate it: its eight new keys were deliberately
  left untranslated, the gate stayed green, and the playtest on 2026-09-03 read
  the first-join line and the `/codeblock tools` replies in English on a French
  client. Read the check's *untranslated* list, not just its exit line.

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
`default_auth_level`, `server_step_budget_us`, `max_file_kb` and `flat_sky`.
`max_file_kb` is the ceiling on a file read out of a player's directory, which is
not a codelevel limit because it bounds the read itself rather than a running
program (B40); `flat_sky` is the one setting here that bounds nothing at all, and
why it exists is below (C18).
`settingtypes.txt` only *draws*
that menu — the engine does not read it for defaults, so its values are copies of
the literals here, and they are **generated** by `scripts/gen_settingtypes.lua`
rather than kept in step by hand. Do not edit that file: change a default here or
the wording in the script, and run it. `map_window_s` is not a
codeblock setting at all: it is read from the engine's
`server_unload_unused_data_timeout`, because the map footprint decays over
exactly that window. Two constraints in `config.lua` exist for reasons that are
not local to it, so check before changing either. The tables stay **plain
literals** with the overrides applied in one loop afterwards, because **two**
generators grep this source for a name assigned a table whose first element is a
number — `gen_docs.lua` for the documented row and `gen_settingtypes.lua` for the
menu entry — and a computed value turns both checks off without failing. And
every settings read is guarded with `rawget(_G, 'core')`, because both scripts
dofile `config.lua` under a bare interpreter with no engine global, which is also
what makes the defaults they read the built-in ones rather than this machine's.

`config.lua` keeps the units a player and an administrator read — seconds,
megabytes, milliseconds. `limits.new` converts them once, and nothing else does
the arithmetic. A retired setting name still in someone's `minetest.conf` warns
at load and names its replacement, from the `replaced` table.

Every setting here is this mod's. A game that embeds it contributes its own —
mapgen, daylight, build restrictions — and the two do not mix.

**One setting is the exception, and it exists only because that rule was broken
once.** `register_on_joinplayer` in `lib/register.lua` used to call
`override_day_night_ratio(1)` and hide the sun, moon, stars and clouds for every
player, unguarded, under a comment reading `TODO: TEMP fix` — `codecube`'s
presentation living in the mod, and imposed on every other game that installed
it. It is now behind `config.flat_sky`, **off by default** (C18), so a game that
wants that sky asks for it in its own `minetest.conf`. Read through `flag`, the
boolean sibling of `number` and `per_level`. Do not add anything else of that
kind: the next piece of `codecube` presentation belongs in `codecube`.

### Writing to the world

`lib/shapes.lua` owns the four bulk shapes (cube, sphere, dome, cylinder) through
`shapes.build(spec)`, in mapblock-aligned slabs of `SLICE_BLOCKS` — one VoxelManip
pass each, with `spec.charge` called before every pass and free to yield. A pass
cannot be interrupted, so the slab size *is* the longest stall the mod can cause;
that is what lets a shape be any size at all. Every filler clips itself to the
area it is handed rather than to a range passed in, which keeps the clip equal to
the extent the data array covers.

Single-node `place()` lives in `lib/cost.lua` as `place_block`, and must call
`core.load_area` first: `set_node` into a mapblock that is not in memory silently
does nothing, which used to leave holes in builds far from spawn. Bulk shapes
need no such call — `read_from_map` emerges the region itself.

`lib/cost.lua` holds what a command spends and when it gives the server its step
back — `use_nodes`, `slabs`, `use_call`, `end_command`, `place_block` — and
`lib/commands.lua` holds the geometry that calls them.

`place_block` makes that call only when the drone crosses into a new mapblock,
comparing `floor(x/16)` on three axes against the last write, and takes footprint
for each crossing. Two things about that memo are load-bearing. `load_area` does
not trigger mapgen, so what a load costs is a resident MapBlock plus a disk read —
and `heap_mb` cannot see it (`collectgarbage('count')` is the Lua heap; a MapBlock
is C++ side), which is why `map_memory_mb` exists. And the memo is **per-resume,
not per-run**: `release` clears `drone.bx/by/bz` before every yield, and it is the
only `coroutine.yield` in `lib/cost.lua` for exactly that reason. Widening its
lifetime brings back the silent lost write the `load_area` call was added to fix.

Bulk shapes are charged too, per slab, through the `slabs(drone)` callback.
Without it, `cube(1,1,1)` in a loop bypasses the ceiling exactly.

Untested by the specs: they run at mod load, before a map exists, so nothing
exercises `place()` itself. What was checked by hand in a running world (S5):
the memo, the per-crossing charge and the per-resume reset all behave, a mapblock
costs 16.3 kB resident, and the engine serves about 1700 loads a second.

### Formspecs

`lib/forms.lua` is a per-player form session on `core.show_formspec`: state that
survives a redraw, field routing, one form per player.
`lib/formspecs.lua` builds the editor itself. Handlers are
`handler(meta, player, fields)`, where `meta` is the same table across redraws.

**The editor formspec is in legacy coordinates**, not
`formspec_version` coordinate mode, and three things follow from that which are
invisible until something is drawn in the wrong place (roadmap F1, F2). A `scroll_container` maps its contents into a
different space from the elements around it and clips them to its own rectangle,
so rows drawn in one land somewhere else; and an `item_image_button` inside one
gets a hit area that does not match where it is drawn. The three help panels get
away with a container only because `item_image` takes no clicks. That is why the
block picker is a `textlist` — a legacy element that scrolls itself, as the file
list in the same form already does. And **a button's `W` is not a width**: the
engine gives a `button` `W*spacing - (spacing - imgsize)` and a `textlist` plain
`W*spacing`, with `spacing = imgsize * 5/4`, so a button is short by a fixed
**0.2 units** whatever `W` is — the offset does not scale. That is why *Create a
copy* is `3.2` wide against the 3-wide file list and `+` is `0.95` (roadmap F2). A
legacy button's `H` is not a height either: the height is fixed and `H` only
shifts it down. `lua_api.md` records the spacing, the padding and the fixed
height but **not** the width offset, so the reference cannot settle a
misalignment here — `src/gui/guiFormSpecMenu.cpp` can. Anything new in this form
has to know all of this, and converting it to the new coordinate system is a
change to the whole editor.

**Re-showing a form destroys and rebuilds every element in it, and a button's
press does not survive that.** `show_formspec` onto an open form of the same name
regenerates it — but only when the new string differs byte for byte, which the
client checks in `drawMenu`. `regenerateGui` then carries table state and focus
across *by field name* and removes every child, so a `button` that recorded
`Pressed = true` on mouse-down is gone by mouse-up and its click is dropped with
no error anywhere. A `table`/`textlist` acts on mouse-**down** and is the one
element immune to it. So a form that refreshes itself under the player loses
roughly one click in five per 0.5 s beat (audit B47), and *no text field, so no
focus to lose* does not make a live form safe — input focus and a press in flight
are different questions. `lua_api.md` documents none of this; `guiFormSpecMenu.cpp`,
`guiButton.cpp` and `guiTable.cpp` do.

**`get_int` cannot tell an unset key from a stored `0`** — both come back 0. Read
a boolean preference out of player meta with `get_string`, where an absent key is
`""`, so a default of *on* is expressible and a deliberate untick still reads as
off. This is load-bearing for two defaults (audit B5).

**Which fields arrive is not what `lua_api.md` implies.** A **scrollbar is in the
field table on every submit**, not only when it moved: `parseScrollBar` sets
`send = true` at parse time and `acceptInput` then emits `VAL:n` unconditionally
(`CHG:n` only when it was the element that moved). A **checkbox is absent unless
it was the box clicked** — `lua_api.md` documents its value as `"true"`/`"false"`
with no caveat, while saying explicitly that a button is nil when not pressed, so
the document reads as though a checkbox always arrives. Getting either backwards
produces a dead branch (audit B37).

The rule that falls out of it: **in a single `elseif` chain, every always-sent
field must come last, or be read before the chain entirely.** `fields.content`
(B35), the three panel scrollbars and `newfile` (B37) are all in that class — and
`newfile` is keyed on `fields.key_enter_field == 'newfile'`, which the engine sets
on `EGET_EDITBOX_ENTER` and nothing else sets, rather than on the field being
non-empty.

In the editor, **every redraw re-renders the text area from
`meta.contents[meta.active]`**, so `fields.content` is captured once by a guarded
read *before* the branch chain in `on_close`, not inside the branches that happen
to need it (audit B35). Do not move that capture into a branch: eight of eleven
branches used to redraw without it and threw away everything typed since the last
save. The guard also carries the quit event, which sends no field but `quit`.

**A form closes by one path however it was reached** (audit B33). Leaving and
server shutdown both go through the local `close_session`, which drops the
session and then hands the handler the engine's own `{quit = 'true'}`, so a
handler holding unsaved state has one place to write it. `forms.forget` is
unchanged and is what the specs use for cleanup; only the engine callbacks close
a session this way. A close from the mod's side (`forms.close`) deliberately
sends nothing.

That makes **load order load-bearing**: leave callbacks run in load order,
`forms.lua` is dofiled before `register.lua`, and it must stay that way — the
editor's quit path reads the player's file list, which `register.lua`'s own leave
callback drops via `remove_user_data`. Reordering the `dofile` list in `init.lua`
silently breaks *Load program on exit* on disconnect. The constraint is commented
on `register_on_leaveplayer` in `lib/register.lua`.

Also per B33: player meta written from `register_on_shutdown` **is** still saved.
It follows from the engine's shutdown order, and it was an assumption until
`PLAYTEST.md` check E9 was run at `dee0bc7` on engine 5.17.0 — now observed,
not inferred.

Both of those callbacks build the `{quit = 'true'}` they pass in, so neither
carries a scrollbar field. That is why they kept working while closing the same
editor with ESC did not (B37): the two paths with playtest checks were the two
that worked.

### `drone.lua` vs `drone_entity.lua`

They divide by direction of dependency (audit A11). `lib/drone_entity.lua` is 69
lines: it holds the owner's **name** and a **serial**, arriving together as
`core.add_entity` staticdata in the form `<serial> <name>`, and routes one engine
event onto the record — `on_deactivate`. It owns nothing and caches nothing, so a
name that names no drone simply reads nil. `lib/drone.lua` owns the record, the
lifecycle, and `Drone.finish` — the single place a run's outcome is announced. It
does not know forms exist: `Drone.on_place` returns whether the player still
needs to pick a file, and `lib/register.lua` shows the chooser.

**The entity is a view, and nothing else. The run is driven by the globalstep in
`lib/register.lua`** — one registration, which calls `Drone.on_step(dtime)` and
then the HUD and panel tick. `Drone.on_step` loops over `Drone.instances`, counts
the running drones **once** so each gets its share of `server_step_budget_us`,
advances each one, and hands an object back to any drone that has lost one. There
is **no `on_step` on the entity**, and adding one would undo all of this
(audit B50, B52).

The reason is an engine rule: an object with `static_save = false` is deleted the
moment its mapblock leaves server memory — not when it goes out of active-block
range — and nothing in the mod keeps the drone's *own* block loaded, so any drone
past about 192 nodes from a player, or standing still for
`server_unload_unused_data_timeout`, loses its object. **So a record without an
object is a run nobody can see, not a run that stopped.** `Drone.on_lost` clears
`drone.obj` and does nothing else: it announces nothing, tears nothing down, and
does not test `drone.cor` — a parked drone with no coroutine waits for its view
too. `Drone.on_step` re-spawns the object with the **same serial** once
`get_node_or_nil` says the block is back, at most once a second. Two consequences
are deliberate: `/clearobjects` no longer ends a running program, and a runaway
drone far from any player loses its accidental stop, so `max_nodes_written`,
`max_runtime_s` and `map_memory_mb` carry that load alone.

Teardown is shaped around re-entrancy: `Drone.remove` clears the record *before*
`obj:remove()`, because that fires `on_deactivate`, which looks the drone up.
**That ordering is not what makes it safe.** `ObjectRef:remove()` takes effect at
the end of the step, so `on_deactivate` can fire after a replacement drone has
been installed under the same name. What protects the replacement is the serial:
`on_lost` ignores any record whose serial is not the one it was called for.
Without it, a dying object would blank the new drone's `obj` and leave it
invisible until the next re-spawn. Re-spawning under the same name makes that
case more common, not less, so do not remove either guard on the strength of the
other (audit B29).

### The two tools, and the player's inventory

`lib/register.lua` registers `codeblock:poser` and `codeblock:setter` and hands
them out on join. Two things there are load-bearing and both were bugs first.

**`on_place` fires only when the client has a node under the crosshair.** Aim
into the sky, or past what the client has loaded, and the engine calls
`on_secondary_use` instead — which is documented in `lua_api.md` and was an empty
function here, so the one gesture a player makes to find a tool's reach answered
nothing, and B10's *"move closer"* refusal was reachable only by pointing at a
node the *server* had unloaded. Both now route into one `Drone.on_place` call,
with `pos` nil for the no-node case, and that check sits **above** the busy check:
with no node it is the aim that failed, not the drone (audit B38).

**Never clear a player's inventory. Add what is missing.** `set_tools` used to
empty `main`, `craft`, `craftpreview` and `craftresult` first; narrowing that to
"only when a tool is missing" (B16) left it firing in exactly one case — the first
join after the mod is installed, which is the only case where the player has
anything to lose (audit B39). Both carrying reads must stay: `main` **or**
`craft`, because a tool parked in the craft grid would otherwise be duplicated on
every join, silently.

Both defects were **invisible in `codecube`**, where a player carries nothing but
the two tools and has no reason to aim at the sky. The mod ships standalone to any
game and that is the only place either existed. *Play it outside its own game.*

## Environment notes

- `minetest` is a permanent alias for `core` and is **not** deprecated.
- Lua 5.1 / LuaJIT: `loadstring`, `setfenv`, `math.pow`, `math.atan2` all exist;
  `0` is truthy; you cannot yield across `pcall`.
- Mod security blocks writes into a mod's own directory, so
  `codeblock_gen_docs=true` writes `api.md` into the world directory to be copied
  over by hand.
