# CLAUDE.md

Guidance for Claude Code in the `codeblock` repository. The response, editing,
coding and helper conventions are in `~/.claude/CLAUDE.md` and are not repeated
here. Neither is the architecture: five skills own it, listed below.

## What this is

CodeBlock is a Luanti (formerly Minetest) **mod** that adds programming to the
game: a Lua sandbox, a drone that builds what the program says, an in-game
editor, and the player-facing API those three share. Essentially all the logic
lives here. Its own ContentDB package, its own CI, its own tests, its own
documentation and its own release path, branch `master`.

It depends on `vector3`, another ContentDB package by the same author, vendored
as a submodule under `tests/game/mods/` so the specs have a game to boot in.

A game called `codecube` embeds this mod and presents it to players. It is a
**downstream consumer of releases, maintained by the same author** — it pins a
release, adopts a new one on its own schedule, and keeps a wholly separate
record. It is developed in its own checkout and nothing here depends on it. **Do
not read it, report on it, or change it from here.**

## The record

Six documents in this directory, plus the `.claude/` definitions and the
gitignored HTML renderings. Each document's own header says what it is; this is
only what each owns.

| File | Owns |
|---|---|
| `ROADMAP.md` | What to do next, the phases `Phase 0`–`Phase 10`, the `F` feature series, and the log of what was agreed. Read it first. |
| `TODO.md` | The author's inbox, one line each. A `FIX:` or `BUG:` line is a hand-off: it gets a finding id in `AUDIT.md` and stays until the author deletes it. |
| `AUDIT.md` | Every finding, its state, and the reasoning a future change would re-break. Findings only. |
| `CHANGELOG.md` | What shipped, for someone using this mod in any game. |
| `PLAYTEST.md` | The manual checks no spec can reach, each with a result line carrying the commit, engine version and date. |
| `CONTENTDB.md` | The ContentDB long description. `.cdb.json` is generated from it. |
| `.reports/*.html` | Renderings of the roadmap, the audit and the playtest checklist. Gitignored, presentation only. |

`Phase 8` is v1.0.0, `Phase 9` is v1.x.y, and `Phase 10` is v2.0.0 and holds
nothing but the Blockly editor.

**Finding ids are never renumbered**, because commit messages cite them: `B`
bugs, `S` sandbox and security, `C` compliance and packaging, `A` architecture,
`F` features. A gap in a sequence is a finding routed to the game's own audit
back when the two projects shared one record.

**`AUDIT.md` and `PLAYTEST.md` each carry their own `export-ignore` line** in
`.gitattributes`, so neither ships to a player.

**The `project-manager` agent owns all of them**, plus the `.claude/`
definitions beside them. Edit one by hand only for something that agent cannot
know — recording the outcome of a playtest run is exactly such a thing.

**One exception, and it is deliberate.** `code-expert` writes its own definition
and the six skills it reads, so that an engine behaviour or a trap that cost it a
debugging round is written down where the next change will meet it. That is the
mechanism by which a mistake is made once. Nothing else in `.claude/` is its.

**These documents are the project's memory for an agent, and there is no other
store.** What the author asked for, decided or corrected goes into the one whose
subject it is — a decision in `ROADMAP.md`, a request in `TODO.md`, a working
convention here. A note kept anywhere machine-local is invisible to a checkout on
another machine and to the next session. If it is not in the repository, it will
be re-litigated.

## The agents and the skills

**The split is the point** — an agent that both makes a change and reports on it
can be trusted for neither.

| Agent | Owns |
|---|---|
| `project-manager` | The record documents and the `.claude/` definitions. Calls the other two. Never touches source or specs. |
| `code-expert` | `lib/`, `init.lua`, `scripts/`, `settingtypes.txt`, `locale/` and the generators over them. |
| `test-agent` | `tests/*_spec.lua`, the suite, the gates and the evidence side of `AUDIT.md`. |
| `release-check` | Read-only. Decides whether a release is ready. |
| `code-improver` | Read-only, global. Reviews rather than changes. |

| Skill | Read when |
|---|---|
| `code-standards` | Before writing or changing any Lua here. The craft, and what a change drags with it. |
| `program-pipeline` | Editing `preprocess`, `env`, `sandbox`, `stepper`, `limits`, `strguard`, `config`, `cost`, `shapes` or `commands`, or changing a limit. |
| `drone-and-tools` | Editing `drone.lua`, `drone_entity.lua`, the globalstep, or anything touching a tool or a player's inventory. |
| `editor-formspecs` | Editing `forms.lua`, `formspecs.lua` or any `(meta, player, fields)` handler. |
| `blocks-and-palette` | Editing `nodes.lua`, `blocks.lua`, the palette, the ramps or `get_block`. |
| `generated-files` | Editing `api.lua`, a generator, `.luacheckrc` or `CONTENTDB.md`; adding an `S()` key or a file to the tree. |
| `run-tests` | Running or reading the suite and the gates, and writing a spec. |
| `build-feature` | Starting, resuming or finishing an `F` item. |
| `release-codeblock` | Cutting a release, or changing anything that ships in one. |

`luanti-reference` is a global skill and holds the engine-general facts —
`lua_api.md`, Lua 5.1, ContentDB's rules, and the behaviours that have already
cost findings. Use it before stating that a `core.*` function exists or behaves a
particular way.

## How a feature gets built here

Six steps, which `F1` established and every `F` item follows. **The procedure is
the `build-feature` skill** (`.claude/skills/build-feature/SKILL.md`) — read it
before starting, resuming or reviewing an `F` item.

Two of its steps need the author in person, which is why it is a skill and not a
subagent: the choices only they can make, and the playtest in a real world.

## Commands

The full suite runs **inside Luanti**, against the fixture game in `tests/game`.
All nine specs run this way:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

**CI runs all nine this way too**, in upstream's `luanti:5.17.0` server
container. Six of them also run standalone under Lua 5.1 in a separate CI job:

```bash
wsl bash -lc 'cd /mnt/c/Users/lacba/PRogrammation/codeblock && for s in api preprocess env shapes strguard limits; do lua5.1 tests/${s}_spec.lua; done'
```

The rest, all run by this repository's CI:

```bash
luacheck . --formatter plain --codes
lua scripts/gen_docs.lua --check         # doc/api.md, and .luacheckrc's sandbox std,
                                         # both match lib/api.lua
lua scripts/gen_locale.lua --check       # locale/template.txt matches the code
lua scripts/gen_settingtypes.lua --check # settingtypes.txt matches lib/config.lua
bash scripts/gen_cdb_json.sh             # regenerate after a CONTENTDB.md edit
```

`LUACHECK_STRICT=1` reports what the baseline exemptions hide.

**Read the output, not the exit code.** `$?` does not survive this machine's WSL
layer, so a gate is green when it *says* so — `doc/api.md is up to date`,
`locale/template.txt is up to date`, luacheck silent, and the spec run's one
verdict line reading `9/9 specs`, `0 failed`, `0 xpass`, `0 skipped`.

**The `run-tests` skill owns everything else about the suite**: the fixture
game and the `tests/game/minetest.conf` that enables the suite, the three
`vector3` versions and what a green run does not prove, which specs are
in-engine only, what CI's four jobs do and do not prove, and how to read the
verdict line.

## Environment notes

- `minetest` is a permanent alias for `core` and is **not** deprecated.
- Lua 5.1 / LuaJIT: `loadstring`, `setfenv`, `math.pow`, `math.atan2` all exist;
  `0` is truthy; you cannot yield across `pcall`.
- Mod security blocks writes into a mod's own directory, so
  `codeblock_gen_docs=true` writes `api.md` into the world directory to be copied
  over by hand.
