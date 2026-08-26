# Roadmap — CodeBlock

Where the mod stands and what to do next. CodeBlock is the main project; the
`codecube` game is a consumer of its releases and keeps its own record.

The reasoning behind every item lives in **this mod's own audit**,
`.audit/audit.html` beside this file — gitignored, generated locally, and the
main audit of the two. The ids below are stable and are never renumbered, so a
finding can be looked up there.

Two numbering conventions, so a commit message always resolves:

- **Phases** are this project's, `Phase 0` to `Phase 8`, and are quoted in
  commit messages. They are never renumbered.
- **Ids** are shared with the game's audit — a `B`, `S`, `C` or `A` number is
  allocated once across both, so it never means two things. Twelve ids are the
  game's and live in its audit: `C2`–`C5`, `A14`, `B20`, `A13`, `B19`, `B24`,
  `A7`, `A8`, plus `C15`.

Target is **v1.0.0**, major because several changes break saved player programs.

## Now

**Fix B27, then decide B29, then repair B31.** Phase 7's code shipped in four
commits and left five regressions behind; B27 is a player-reachable crash in the
movement path, so nothing should be pushed or released ahead of it. B29 needs one
minute in a running world to settle a disagreement between two reviews, not more
analysis. B31 has already corrupted the author's real `minetest.conf` and needs a
hand repair outside this repository as well as a fix inside it.

The four Phase 7 commits are **unpushed**, so no CI has seen them.

## Milestones

### 0. Make change safe — done (2/2)

Run on the current engine, put the sandbox under test, restore linting.

### 1. Ship the compliance fixes — done (4/4 here, 8/8 across both)

No version ceiling, licensing settled, the user-visible command and editor bugs
fixed. This repository's share is C1, B5, B8, B9. C1's residue is still here —
`mods/vector3/mod.conf` carries a 5.5 ceiling.

### 2. Rewrite the sandbox preprocessor — done (11/11)

Stop corrupting valid programs; make the environment something a program cannot
reach out of.

### 3. Replace ActiveFormspecs — done (3/3 here, 5/5 across both)

Last unmaintained dependency gone; documentation generated from the code. This
repository's share is A1, A2, B22.

### 4. Performance — done (4/4)

The drone builds at the speed the hardware allows; bulk shapes are one
VoxelManip pass each.

### 5. Limits that track real load — done (4/4)

`43e95a8`, CI green. Three of its items were superseded within the week by
Phase 6 — read the audit, not the old wording.

### 6. Limits that stand for what the server spends — done (3/3)

`2647228`, CI green. Eleven per-codelevel limits counted proxies; seven now
count what the server actually spends. (S5, C13, A5, B25, B26, C14.)

### 7. Clear the way for features — code done, regressions open (18/26 here)

Remove the duplication and dead weight that make every new feature cost more
than it should. Landed in `742a1ca`, `37c416e`, `834f69f`, `a00f87e` — none
pushed. Five of the game's findings are its milestones G3 and G4, untouched from
here.

Closed: the drone record has one owner and `Drone.finish` is the one place an
outcome is announced (A11, B10, B11, A6); `lib/filesystem.lua` keeps one record
per file (A9); compilation errors name the file (B7); five editor and join fixes
(B13, B14, B15, B16, B17); `lib/commands.lua` split 971 → 608 lines with a new
`lib/cost.lua` (A3); cylinder orientation normalised (B18); trailing whitespace
cleared but for one deliberate site (B21).

Open — fix in this order:

- Round or normalise the rotation key: `rotate[drone:angle()]` is keyed by
  integers and indexed by a float, so a `turn()` can crash the next move. (B27)
- Place a drone twice in a running world and record what happens; two reviews
  disagree about whether `on_lost` destroys the replacement. (B29)
- Stop `run_tests.ps1` writing a BOM into the user's config, and repair the
  config already damaged by it. (B31)
- Guard the spec `dofile`s in `init.lua`: `tests` is `export-ignore`d, so
  `codeblock_run_tests` aborts mod load on a ContentDB install. (C16)
- Give `check_inside_world` the right `error` level on the `move_by` path, or
  hoist it to the callers. (B28)
- Add a separator when `run_tests.ps1` appends the enable line. (B32)
- Check `drone.cor` in `on_lost` before announcing a program that ended. (B30)
- Keep folding `minetest.*` → `core.*` into other edits. (C6, partial by design)

Still wanted before this phase closes: a hands-on playtest of the editor and of
drone placement. Neither has any spec coverage and neither can have.

### 8. Show the budget — not started (0/1)

The last thing before v1.0.0, and a feature rather than a fix: a player should
see what a program is spending while it runs.

- Show each count beside its limit, live rather than only on completion, and the
  *binding* constraint as a percentage. Its one dependency, A11, is now met.
  Peak heap is still not kept, and the charged-CPU figure dropped from the
  completion line belongs here as a share. (`TODO.md`)

## What ships broken

- `heap_mb` cannot stop one huge allocation, and a pathological Lua pattern can
  still burn CPU inside a single `find` or `match`. (S2's residue)
- The step budget is never checked *inside* one VoxelManip pass, so a single
  slab — around 65k nodes, under 10 ms — still overshoots it.
- The map footprint decays linearly over the unload window rather than tracking
  each block, so it estimates what is resident rather than measuring it.
- `place()` writes one node per call; the four bulk shapes do not. (A4)
- Pacing, slab progression and the footprint throttle have no in-world
  verification: the specs run before a map exists. Untested, not known broken.
- The filesystem, the editor and drone placement have no spec coverage at all,
  for the same reason. Six findings closed in Phase 7 rest on reading only.
- Unknown whether mapgen can overwrite a node written into a never-generated
  area when a player later visits and it generates.
- `scripts/gen_cdb_json.sh` is verified by nothing.
- `.gitattributes` decides what reaches a player and **no CI checks it**. A file
  added here ships unless a rule excludes it, and nothing local fails. (C10)
- `README.md:14` keeps its trailing whitespace on purpose: it is a Markdown hard
  break that `gen_cdb_json.sh` folds into the ContentDB description. (B21)

## Deliberately not doing

- **Batching `place()` into `core.bulk_set_node`.** 1.3x by the engine's own
  figure, against five flush sites whose omission is a silently wrong build.
  Contingent on the yield cadence, which Phase 6 changed, so the arithmetic
  under A4 in the audit wants redoing before the decision is quoted again.
- **Migrating off `minetest.*` as a project.** `minetest` is a permanent alias
  for `core`, with no deprecation warning and no removal date. Phase 7 converted
  the 21 sites in the files it rewrote anyway; the rest drifts. (C6)
- **Chasing the last `.editorconfig` difference.** `align_call_args = true`
  fixes the wrapped-argument alignment but pushes a table constructor passed to
  a call out to the paren column, which is worse.
- **Computing the codelevel limits instead of overriding literals.**
  `gen_docs.lua` reads `lib/config.lua` for a name assigned a table of numbers,
  so a computed value would silently disable the check that every limit is
  documented. (C7, C14)
- **Moving the settings to the game.** Every one of them is this mod's, and this
  mod is its own ContentDB package. (C7)
- **Blockly web editor.** Wanted, out of scope for 1.0.0.

---

2026-08-27 · codeblock `a00f87e` (master), four commits ahead of `origin/master`
at `2647228`. Local gates green at `a00f87e`: luacheck, `gen_docs.lua --check`,
six standalone specs, nine in-engine specs (347 assertions, 0 failed, 0 xpass).
No CI run exists for the Phase 7 commits. Uncommitted in the working tree:
formatter reflow in `lib/formspecs.lua`, `lib/preprocess.lua` and
`lib/register.lua`, plus these record files.
