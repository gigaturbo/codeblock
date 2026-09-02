---
name: build-feature
description: How a feature gets built in the CodeBlock mod — the six-step order F1 established, from shaping it in prose, through the choices only the author can make and the parts argued out, to the gates, the author's playtest in a real world, and recording what it found. Use when starting a new feature, picking up an F item (F4, F5, F6) mid-way, or deciding whether a feature is done.
when_to_use: Starting or resuming any feature or F item in this repository, before writing feature code, when asked "what's next on F4" or whether a feature is finished, and when a feature's playtest has just produced results.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion
---

# Building a feature in CodeBlock

`F1` established this order and `F1`, `F2` and `F3` each paid for one of its
steps. Follow it in order; the steps are cheap early and expensive late.

The `F` series (`F1`–`F6`) and the agreed shape of each feature live in
**`ROADMAP.md`**. Findings are in `AUDIT.md`, in-world checks in `PLAYTEST.md`.
Ids are never renumbered.

## 1. Shape it in prose before any code exists

Dependencies, consequences, risks, feasibility, and what the player experiences.
Write it into the feature's entry in `ROADMAP.md`. `F1` changed shape twice at
this stage and cost nothing either time.

Read the `F` entry first: `F4`, `F5` and `F6` already carry their constraints and
their risks, including which of them a spec can reach.

## 2. Put the author's choices to them, with a recommendation

Use **`AskUserQuestion`**: a small set of options with a recommendation, **never a
survey**. Four such choices settled `F1`'s whole scope in one exchange — where
the UI lives, how the player picks, who may set it, whether `air` counts.

A choice is the author's when it is about what the player gets, what the mod
imposes on a game, or what is privileged. It is yours when it is about how the
code is arranged.

## 3. Argue out what should not be built

`F1`'s proposed `persist` flag was cut before implementation, on four grounds.
`F3` lost a per-codelevel cap and a route through `end_command` the same way. **A
feature losing a part on argument is a normal outcome, not a failure**, and it is
cheapest here.

**Record the grounds** in the feature's `ROADMAP.md` entry and under *other
decisions worth not re-litigating*. An omission with no recorded reason gets
proposed again.

## 4. Write it, then the gates, every time

**`code-expert`** writes it — it reads the `code-standards` skill first, and it is
the one that knows what the change drags with it. **`test-agent`** runs the gates
and adds the coverage. Delegating both is the normal path; the gates are the same
either way.

```bash
luacheck . --formatter plain --codes
lua scripts/gen_docs.lua --check      # doc/api.md matches lib/api.lua
lua scripts/gen_locale.lua --check    # locale/template.txt matches the code
lua scripts/gen_settingtypes.lua --check   # settingtypes.txt matches lib/config.lua
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1   # the nine specs
```

**Read the output, not the exit code.** `$?` does not survive this machine's WSL
layer, so a gate is green when it *says* so: luacheck silent, `doc/api.md`,
`locale/template.txt` and `settingtypes.txt` each *up to date*, and `failed` and
`xpass` both 0 in the spec run. The `run-tests` skill owns the suite's procedure.

If the feature adds or changes a player-facing name, the edit spans `lib/api.lua`,
the `impls` table in `lib/sandbox.lua`, regenerated `doc/api.md` and
`tests/api_spec.lua`'s explicit name list. Adding a limit means a plain literal in
`lib/config.lua`, the hand-kept `settingtypes.txt` mirror, and a row in
`doc/api.md`'s codelevel table.

## 5. The author plays it in a real world — you cannot do this for them

Hand it over and stop. This is not a formality: `F1`'s picker was wrong twice in
ways no spec could catch, and `F2`'s naming produced `spirals_c__copy.lua` in the
author's world.

**Reach for the engine's documentation and source on the first surprise, not the
second.** Three findings here were the engine doing something the code did not
expect: `B37` (a scrollbar is in the field table on every submit), `B38`
(`on_secondary_use`, not `on_place`, when nothing is pointed at) and `B5`'s
`get_int` trap. `B38`'s callback *is* documented in `lua_api.md` and the cost was
not reading it; where `lua_api.md` is silent or misleading, as it is for `B37` and
for legacy button widths, `src/gui/guiFormSpecMenu.cpp` settles it.

## 6. Record what the playtest found, before the code moves on

Call **`project-manager`**, and tell it:

- the outcome of each check, with the **commit**, the **engine version** and the
  **date** — that is what `PLAYTEST.md`'s result lines need, and a result with no
  commit is not evidence;
- the **gate results**, read from their output;
- anything the author decided or reworded in the exchange, so it reaches
  `ROADMAP.md`'s decisions log;
- any defect found, so it gets a finding id.

**What gets an id is a defect in committed code.** `F1`'s playtest produced
`B33`, `B34` and `B35` — all in pre-existing editor code its playtest happened to
expose — and all three were recorded, then fixed or decided, before `F2` started.
`F2`'s naming was wrong in the same way and got **no id**, because `F2` was still
uncommitted: that is the feature being wrong before it ships, and the record for
it is the `F` entry. A wrong *check* is a defect in the record, not the code, and
is fixed in `PLAYTEST.md` (playtest `D3` and `F-3` both were).

Expect a feature's playtest to file bugs in the code it touches, and budget for
fixing them before the next feature.

## The two rules that were nearly lost

- **A feature is done when it is committed with its gates green** — not when it
  works locally. Its in-world checks being unrun is outstanding *checking*, not
  unfinished work, and `PLAYTEST.md` is where that is tracked.
- **Nothing in a running world is provable by the specs.** They run at mod load,
  before a map, a player or a user directory exists. Anything touching a
  formspec, player meta, the filesystem, an inventory, a tool callback, a locale
  file or the world needs a `PLAYTEST.md` entry — and if there is no entry, the
  behaviour is unverified however green the suite is.

## Two lessons this phase paid for

- **Run a playtest group that has never been run before writing the next
  feature.** Eight sessions on the editor found four findings; the one session
  that finally left the editor found three, one of them the worst defect this
  project has recorded against committed code (`B39`).
- **Play the mod outside its own game before a release.** `B38`, `B39` and `C18`
  are all invisible in `codecube`, where a player carries nothing but the two
  drone tools and a sunless sky is the game's design.
