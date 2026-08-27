# Roadmap — CodeBlock

Where the mod stands and what to do next. CodeBlock is the main project; the
`codecube` game is a consumer of its releases and keeps its own record.

The reasoning behind every item lives in **this mod's own audit**,
`.audit/audit.html` beside this file — gitignored, and the main audit of the two.

Numbering conventions, so a commit message always resolves:

- **Phases** are this project's, `Phase 0` to `Phase 8`. Never renumbered.
- **Finding ids** — `B` bug, `S` sandbox and security, `C` compliance and
  packaging, `A` architecture — are allocated once across both audits, so a
  number never means two things. Twelve are the game's: `C2`–`C5`, `A14`, `B20`,
  `A13`, `B19`, `B24`, `A7`, `A8`, plus `C15`.
- **`F` is features**, a new series allocated when Phase 8 became the feature
  phase. `F1`–`F6` exist, quotable in a commit message exactly like a `B` or an
  `A`, and never renumbered either.

Target is **v1.0.0**, major because several changes break saved player programs.

## Now

**Push, and let CI see Phase 7 for the first time.** Twelve commits sit on local
`master`, eight of them the Phase 7 rewrite of the movement path, the drone
record, the filesystem and the editor; the newest green run is the phase before
it. CI is the only thing that runs six of the specs under plain Lua 5.1 rather
than the engine's LuaJIT, which is why those six exist.

A green run at `191b533` is **the precondition for every feature below** — each
edits a file Phase 7 rewrote, and every feature commit widens the range a red run
would have to be bisected out of. Then `F1`, the smallest feature.

## Milestones

### 0. Make change safe — done (2/2)

Run on the current engine, put the sandbox under test, restore linting. (C8, A12.)

### 1. Ship the compliance fixes — done (4/4 here, 8/8 across both)

No version ceiling, licensing settled, the user-visible command and editor bugs
fixed. (C1, B5, B8, B9.) C1's residue is still open and not fixable from here:
`mods/vector3/mod.conf` carries a 5.5 ceiling, in a separate repository.

### 2. Rewrite the sandbox preprocessor — done (11/11)

Stop corrupting valid programs; make the environment something a program cannot
reach out of. (B1–B4, B6, B23, S1–S4, A10.)

### 3. Replace ActiveFormspecs — done (3/3 here, 5/5 across both)

Last unmaintained dependency gone; docs generated from the code. (A1, A2, B22.)

### 4. Performance — done (4/4)

The drone builds at the speed the hardware allows; bulk shapes are one
VoxelManip pass each; the WorldEdit fork is gone. (A5, B12, A4, A15.)

### 5. Limits that track real load — done (4/4)

`43e95a8`, CI green. (S5, S6, C7, C13.) Three of its mechanisms were superseded
within the week by Phase 6 — read the audit, not the old wording.

### 6. Limits that stand for what the server spends — done (3/3)

`2647228`, CI green. Seven limits now count what the server spends, where eleven
counted proxies. (B25, B26, C14.)

### 7. Clear the way for features — done (26/26 here, 26/31 across both)

Remove the duplication and dead weight that make every new feature cost more
than it should. Eight commits, `742a1ca` through `191b533`, **none pushed and
none seen by CI**.

- Drone record with one owner, one place an outcome is announced. (A11, B10,
  B11, A6)
- One record per file in the filesystem layer; five editor and join fixes.
  (A9, B7, B13–B17)
- `lib/commands.lua` split 971 → 608 lines with a new `lib/cost.lua`. (A3, B18,
  B21)
- `minetest.*` → `core.*` finished; packaging and lint debt cleared.
  (C6, C10, C11, C12, A16)
- Seven findings from two reviews of the range, five of them regressions the
  phase itself introduced. (B27–B32, C16)

"Done" means every finding closed and every local gate green — not
independently verified.

### 8. Features — not started (0/6 features, 0/1 finding)

Add rather than repair. Was "Show the budget" (0/1); widened to hold every
feature item, which is what the `F` series is for. Ordered easiest to hardest and
meant to be taken one at a time. **Every one has the same precondition: the
Phase 7 range through CI.** `F4` and `F5` also want the hands-on playtest first.

- Choose the block `place()` uses when a program names none — today hardcoded to
  `default:stone` in `placement()`. Cheapest as a field on the drone record; as
  an in-program command it is a new API name. (F1)
- Open a copy of a program, from the editor or the chooser. Decide the collision
  naming before writing it. (F2)
- Let a program pause the drone for a given time. New API name, and `wake_at`
  already exists — but bound the wait, or a program lives forever holding a
  record and is charged nothing. (F3)
- A live drone panel: running or idle, counts beside their limits, the binding
  constraint as a percentage, and start / pause / cancel. Absorbs the old Phase 8
  budget item. Drive the refresh from the form side; `drone.lua` must not learn
  that forms exist. (F4)
- Change a codelevel while a program runs. Rebuild the budget while carrying
  `used` across, or re-levelling becomes a limit bypass. Stays privileged. (F5)
- Blockly web-based editor — **planned, out of 1.0.0**, first item after it. (F6)
- Editor tab state is saved on only one exit path, so a disconnect loses which
  files were open. Filed from the `BUG?` line in `TODO.md`: it is a bug, because
  the restore is already implemented. (B33)

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
  for the same reason. Six findings closed in Phase 7 rest on reading only —
  playtest before calling v1.0.0 finished, and it is what settles B33.
- C16's fix is unproven against a real ContentDB install; it wants one
  archive-and-install during the next release check.
- Unknown whether mapgen can overwrite a node written into a never-generated
  area when a player later visits and it generates.
- `scripts/gen_cdb_json.sh` is verified by nothing, and escapes neither `"` nor
  backslashes.
- `.gitattributes` decides what reaches a player and **no CI checks it**. A file
  added here ships unless a rule excludes it, and nothing local fails. (C10)
- `README.md:14` keeps its trailing whitespace on purpose: it is a Markdown hard
  break that `gen_cdb_json.sh` folds into the ContentDB description. (B21)

## Deliberately not doing

- **Batching `place()` into `core.bulk_set_node`.** 1.3x by the engine's own
  figure, against five flush sites whose omission is a silently wrong build.
  Contingent on the yield cadence, which Phase 6 changed, so the arithmetic
  under A4 in the audit wants redoing before the decision is quoted again.
- **Blockly in 1.0.0.** Stays out: it needs an HTTP allowance only a server
  administrator can grant, its assets must be served from outside the engine,
  and no v1.0.0 goal depends on it. Not abandoned — it is `F6`, planned, and the
  first item after the release. (The old wording, "wanted, out of scope",
  contradicted planning it as the last feature. Confirm or overrule.)
- **Chasing the remaining `minetest` names.** C6 is finished for engine calls;
  what is left must stay — `minetest.conf` as a filename, the
  forbidden-identifier list in `lib/preprocess.lua` and its spec case, which
  have to forbid both aliases, and the `vector3` submodule, a separate package.
  Same for `loadstring`, `setfenv`, `math.pow`, `math.atan2`: still Lua 5.1.
- **Chasing the last `.editorconfig` difference.** `align_call_args = true`
  fixes the wrapped-argument alignment but pushes a table constructor passed to
  a call out to the paren column, which is worse.
- **Computing the codelevel limits instead of overriding literals.**
  `gen_docs.lua` reads `lib/config.lua` for a name assigned a table of numbers,
  so a computed value would silently disable the check that every limit is
  documented. (C7, C14)
- **Moving the settings to the game.** Every one of them is this mod's, and this
  mod is its own ContentDB package. (C7)

---

2026-08-26 · codeblock `191b533` (master), twelve commits ahead of
`origin/master` at `2647228`. **No CI run exists for any Phase 7 commit**; the
newest green run is `2647228`. Local gates reported green at `191b533`: luacheck,
`gen_docs.lua --check`, six standalone specs, nine in-engine specs (0 failed,
0 xpass, 1 xfail in `preprocess_spec`). Those results are the author's report,
not a run made for this document.
