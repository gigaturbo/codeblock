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

**`tests/game` exists because the engine needs a game to boot, and because
`mod.conf` names `vector3`, which is a submodule under `tests/game/mods/`.** It
used to hold empty `default` and `wool` stubs as well, to satisfy dependencies
this mod no longer has: `F11` dropped both and `mod.conf` now reads
`depends = vector3` alone. What is left in their place is
**`tests/game/mods/cbfixture`**, which registers nothing but the three mapgen
aliases the engine validates at startup. **The mod registers its own 105 nodes**,
so a spec wanting a real node has one; if one is ever needed that the mod does
not provide, register that one node in `cbfixture` and no more.

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

**CI boots no engine, so those three specs and every engine-guarded case inside
the other six are unproven by CI** (`C24`). The `test` job installs plain Lua 5.1
and runs the six standalone; nothing starts Luanti. A case guarded on an engine
global — `preprocess_spec`'s enumeration of `lib/examples/`, which needs
`core.get_dir_list` — therefore runs in a local `run_tests.ps1` and not in a pull
request, which sees the standalone line and goes green.

**A spec case that cannot run in an environment must say so in a line beginning
`passed`, `failed`, `FAIL`, `want`, `got`, `skipped` or `xfail`.**
`run_tests.ps1`'s report filter keeps only those, so a note worded any other way
is dropped from the report — which is the silence the note exists to break. The
convention here is to start it with `skipped:`.

The rest, all run by this repository's CI:

```bash
luacheck . --formatter plain --codes
lua scripts/gen_docs.lua --check         # doc/api.md, and .luacheckrc's sandbox std,
                                         # both match lib/api.lua
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

**One thing the suite cannot see even in principle, found while covering `F14`:
a chat line the mod sends a player.** `lib/sandbox.lua` binds
`chat_send_player` as a **load-time local**, so replacing `core.chat_send_player`
around a run does not intercept it, and there is no logged-in player to receive
it either. A spec can therefore assert that a run did not raise, which passes
against a version that reports as well as one that does not — a vacuous
assertion. *Nothing is reported* is a `PLAYTEST.md` check (`F14-2`), never a
spec.

**`B54` widened that to `print`, and there are two locals, not one.** Do not
"correct" either into the other: `lib/sandbox.lua:8` binds `chat_send_player`
and uses it at line 126 for the **unknown-block warning** `F14-2` is about, while
`lib/commands.lua:26` binds the one `drone_send_message` — and therefore
`print` — goes through. So **what `print` puts in the chat is unobservable from
a spec as well**, and that was driven to a result rather than assumed: a probe
capturing `core.chat_send_player` around a real `print("a", "b")` read
`want: > a b, got: nil`. The consequence is the trap: **a spec asserting that
`print` merely does not raise would have been green throughout `B54`**, the
one-argument version having raised nothing while dropping everything after the
first value. What the twelve committed cases pin instead is **the charge** —
one `print` call is one command however many arguments it carries, the join
happening in the sandbox so `drone_send_message` keeps taking one value — and
they guard the implementation rather than witnessing the defect. The chat line
itself is `PLAYTEST.md` `W7`.

Two `print` constraints follow, both invisible to every gate. **Read the varargs
with `select('#', ...)` and `select(i, ...)`, never `{...}` and `#`** — Lua 5.1
cannot see a nil in the middle or at the end of a vararg list, and `get_block()`
answers `nil` over ungenerated map, so a player prints a nil routinely and
`{...}` would truncate the line there. **Join with a space, not real Lua's
tab** — Luanti's chat console has no tab stops, so a tab renders as an ordinary
glyph rather than as alignment, and the engine's chat wrapping breaks on spaces,
so a tab-joined line refuses to wrap on a narrow console. `lua_api.md` documents
neither, which is why the second is reasoned from the client's text path and is
**unverified** until `W7` runs.

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
   no `__pairs` or `__len` and a proxy would break `pairs(colors)` for player
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
`lib/sandbox.lua`, `stds.codeblock_sandbox` in `.luacheckrc` and the explicit
name list in `tests/api_spec.lua`, and regenerating `doc/api.md`. Such a change breaks saved
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

### Restatements of the source: three generated, three checked, one not

**Seven things here restate the source** — read by a human, by a linter, by
ContentDB or by a player rather than by the code, and so **drifting silently:
nothing fails when they are wrong**. Four are below, `.cdb.json` is the fifth,
and the new-file template and the example-name list, both found on 2026-09-07,
are the sixth and seventh; the last three are after the four.
`doc/api.md` drifted and got `gen_docs.lua --check`. `locale/template.txt`
drifted twelve messages one way and seventeen the other and got
`gen_locale.lua --check` (C17). **`settingtypes.txt` was the third and got
`gen_settingtypes.lua --check`** on 2026-09-02: it only *draws* the settings
menu, the engine reads no defaults from it, and every value in it was a hand-kept
copy of a literal in `lib/config.lua`. The pattern the three of them are: a note
about remembering does not hold, a `--check` in CI does.

**`.luacheckrc`'s `stds.codeblock_sandbox` is the fourth, and it is *checked*
rather than generated** — the interesting difference, because the file is a
linter configuration a human also edits, and generating it would take it away
from whoever has to change it. It lints `lib/examples/**`, so a name missing
from it inverts the thing it exists for: an example calling a **correct** API
name is reported `(W113) accessing undefined variable`, which reads as a typo
and invites someone to edit working player code. `sleep` and `default_block`
were missing from it for a year (`C22`, fixed 2026-09-06 at `4450ce1`), and
nothing tracked used either, so the gate was silent on a clean checkout.
`gen_docs.lua --check` now compares that list with `api.names()` **in both
directions**, by `loadfile`+`setfenv` on the config rather than by pattern-
matching it — reading a nested `ramp = {fields = {...}}` correctly, and avoiding
`C20`'s failure mode by construction. It runs in write mode too, so the
generator refuses to write `doc/api.md` while the two disagree. Two rules follow:

- **The std holds API names and nothing else.** That is what makes the
  comparison a plain equality instead of an equality with an exemption list.
  Anything else — the bare `_` the examples pass for *use the default for this
  argument* — goes in `files["lib/examples/**"].read_globals`, which luacheck
  adds to the std.
- **A bare string entry is an escape hatch and a silent one.** luacheck accepts
  *every* field of a bare-string name, which is what `table` and `vector` need,
  so replacing `ramp = {fields = {...}}` with a plain `"ramp"` passes the check
  and switches off typo-catching for `ramp.*` with nothing going red. The check
  asserts what luacheck actually enforces rather than something stricter, and the
  script's comment states the leniency. Spell out the fields of a name whose
  fields are all described — `random = {fields = {"color", "glass", "lamp"}}`.

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

**`.cdb.json` is a fifth file of the same family and failed differently, which is
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

**Two more of the family were found on 2026-09-07, and one of them a player
runs.** The first is the **new-file template** — the program `create_file` in
`lib/formspecs.lua` writes into a file created with `+` or Enter. It is player
code inside a Lua string literal, so nothing lints it, compiles it or generates
it, and it said `place(blocks.obsidian)` for three days after `F11` deleted the
`blocks` category: **every file a player created failed on its first statement,
with all five gates green** (`B53`). It is now in the *checked* column with
`.luacheckrc`'s std: `tests/integration_spec.lua` **reads the string out of
`lib/formspecs.lua`** — anchored on the `write_file(name, filename,` call — and
runs it through `get_safe_coroutine`, with the pre-`F11` text kept as a control
that must fail. Two rules follow. **A copy of the template in the spec would be
one more mirror**, which is why the spec reads the source. And **the template
names no individual colour**: `for i = 1, #hues do place(hues[i]) up(1) end`,
because `place`, `up` and `hues` change only in a major version while a colour
name is the part of the API that moves.

The second is **the list of example names in `tests/preprocess_spec.lua`**, and
it is the one still **unchecked in the direction that matters** (`C23`, open).
That spec is the only thing that compiles the shipped examples, and it checks
them against a hand-written list rather than against `lib/examples/`. A listed
name with no file now fails by name; **a file with no listed name is still
compiled by nothing.** The real set is `codeblock.examples.examples`, built at
load from `core.get_dir_list`, and the fix is blocked only by an untracked
example in that directory making the check red locally and green in CI.

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
  client. **The eight were written later that day and read correctly in a world
  on 2026-09-04**, so what `F10` leaves behind is the lesson and not a gap. Read
  the check's *untranslated* list, not just its exit line.

### The mod's own blocks, and a game's

`F11` gave the mod registered nodes of its own and `F12` replaced the palette:
**105 nodes, 35 colours**, each a solid, a glass and a lamp, built in
`lib/nodes.lua` from **three** shared tiles tinted with **`^[multiply:#rrggbb`**.
Not `^[colorize:<hex>:255`, which at ratio 255 replaces every pixel and would
throw the glass and lamp tiles away and opaque the glass. `mod.conf` is
`depends = vector3`.

**`lib/config.lua` holds two literals — `neutrals` and `families` — and derives
`palette` and the four palette views from them** (`F12`, `F14`). Five neutrals
light to dark, then ten hue families in colour-wheel order, each
`light_x` / `x` / `dark_x`. The views are ordered arrays of **short colour
names**: `hues` the plain shade of each family, `light_hues` and `dark_hues` the
other two tiers in the same wheel order, `neutrals` the five greys light to
dark. Do not flatten this back into one list: F11's flat list with an index
range for the neutrals could not express *the plain shade of each family*.
`fallback` is still `grey`.

**A view is one axis of the palette and a category is the other** (`F14`). Every
category is indexed by the same short name, so `glass[h]` and `lamps[h]` turn
any view into a glass or a lamp gradient and **four arrays give twelve
gradients** — which is why there is no `dark_glass` array and must not be one.
For `colors` the short name **is** the flat key, so `place(dark_hues[i])` needs
nothing around it. The views are published to the sandbox through `snapshot`
like every other table, and none of them gets an unknown-name report: reading
past the end of an array is a legitimate thing for a program to do.

**The solid tile is flat pure white**, so `^[multiply` reproduces the palette hex
exactly and a solid block is a flat fill. The glass tile keeps its frame and
highlight; `textures/codeblock_lamp.png` is a faint grid, ground 252 with lines
at 234 every 8 px, so a wall of lamps reads as blocks rather than one slab. The
cost of the flat solid is that a wall of one colour has **no node-edge
definition at all** — that is `F12-2`'s to judge in a world, and the decision may
come back.

**A category is a namespace and the flat key space behind it is not.** `place()`
takes one string, so `colors.red`, `glass.red` and `lamps.red` resolve to the
unique keys `red`, `red_glass` and `red_lamp`. A game's category is namespaced —
`wool.red` — so a game can never shadow one of the mod's own.

**Read a category through `allowed_blocks.by_name[name].spelled`, never by
indexing the structure table.** A game chooses its own category name, so a name
that indexed `allowed_blocks` directly could be `all` or `fallback` and overwrite
the map every write path resolves through.

**`codeblock.register_blocks` is queued at the call and validated at
`register_on_mods_loaded`** (`lib/blocks.lua`). That ordering is the constraint:
`core.registered_nodes` is complete only then, so checking at the call would
refuse a node belonging to a mod that loads later. A refusal is
`core.log('error', ...)` naming the calling mod — **never a raise**, because a
game's typo must not abort the server — and a call arriving after the seal is
refused rather than warned about.

**Its taken-set is seeded from `api.names()`, so every top-level API name is a
category name a game cannot have.** That is correct — a category shadowing one
would break the environment — but it means **adding a top-level name takes a
name out of every game's namespace**, which is not visible anywhere in
`lib/blocks.lua`. `F14` took three at once: `light_hues`, `dark_hues` and
`neutrals`. Weigh that when adding a name, and say so in `CHANGELOG.md`, where
a game author will read it.

**Derive every view of the palette in `config.add_category` and nowhere else.** A
list built at load time in a reader is a snapshot taken before any game has
registered anything. Three such snapshots existed and all three were invisible to
the suite; `rev_blocks` in `lib/commands.lua` was a live defect, `get_block()`
answering `false` for every game-registered node. The views are mutated and never
replaced, so a local reference still sees a late arrival.

**None of the 105 nodes has a `sounds` field, deliberately** — every
`node_sound_*_defaults()` belongs to a game.

**One ramp per category, `ramp.hues`, and `ramp.of` over any array** (`F12`,
`F14`). `ramp_pick(list, v, m, M)` in `lib/sandbox.lua` is the whole of the
mapping: `ramp_over(list)` binds it to one list, and **`ramp.of` is
`ramp_pick` itself**, so the generic ramp and the per-category ones cannot drift
apart — do not reimplement either against the other. A per-category ramp is
built once per category per run from `add_category`'s `keys` view, so a game's
category gets one on the same terms as the mod's own — appended to
`lib/api.lua`'s *Choosing blocks* group by `lib/blocks.lua`, which is why that
group carries an `id`. `color(v, min, max)` is **gone with no alias**. Out of
range clamps, never wraps; a non-number `v` or a zero-width range gives the
first entry, and a non-table or empty list answers `nil` — an arithmetic
accident must not stop a program. Only `ramp.hues` and `ramp.of` over a palette
view are gradients; `ramp.colors`, `ramp.glass` and `ramp.lamps` walk
light/plain/dark inside each family and strobe, which is a consequence of one
ramp per category and is not a defect.

**`get_block(n_right, n_up, n_forward)` reads without moving the drone**, the
offsets rotated by its facing like `place_relative`. It calls
`codeblock.cost.load_block` — shared with `place_block`, memo still per-resume —
because `get_node` on a block that is not in server memory answers `ignore`,
which is indistinguishable from map that does not exist. Three answers: a block
name, `false` for a node no program can place, `nil` for map that was never
generated or a position outside the world. **`nil` is permanent**: `load_area`
does not run mapgen. The edge is one predicate, `inside_world`, shared with
`check_inside_world` so the query's edge and the raise's cannot drift — and the
asymmetry is deliberate, a write raising out of the world while a read answers
`nil`, because raising on the query a player uses to look before they leap is
the wrong shape. Do not turn it into a raise.

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
gets a hit area that does not match where it is drawn. The help panels get
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
