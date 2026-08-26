# Roadmap — CodeBlock

Where the mod stands and what to do next. CodeBlock is the main project; the
`codecube` game is a consumer of its releases, and its own work is listed in
[the game's roadmap](https://github.com/gigaturbo/codecube/blob/main/ROADMAP.md).
Read this one first.

The reasoning behind every item lives in **this mod's own audit**,
`.audit/audit.html` beside this file — gitignored, generated locally, and the
main audit of the two. The ids below are stable and are never renumbered, so a
finding can be looked up there.

Two numbering conventions, so a commit message always resolves:

- **Phases** are this project's, `Phase 0` to `Phase 8`, and are quoted in
  commit messages. They are never renumbered.
- **Ids** are shared with the game's audit — a `B`, `S`, `C` or `A` number is
  allocated once across both, so it never means two things. Eleven ids are the
  game's and live in its audit: `C2`–`C5`, `A14`, `B20`, `A13`, `B19`, `B24`,
  `A7`, `A8`, plus `C15`. The game orders its own work as `G1`–`G5` and never
  says "Phase N".

Target is **v1.0.0**, major because several changes break saved player programs.

## Now

Start Phase 7 with the drone seam (A11). Phase 6 is **done** — committed, pushed
and green in CI at `2647228`, adopted by the game at `33bdae8` — so nothing is
waiting on a gate. This is also the next step for the project as a whole; the
game's roadmap defers to it. A11 comes first
within the phase because the budget display in Phase 8 needs to read drone state
across the `drone.lua` / `drone_entity.lua` seam, and it closes B10 and B11 on
the way.

## Milestones

### 0. Make change safe — done (2/2)

Run on the current engine, put the sandbox under test, restore linting.

### 1. Ship the compliance fixes — done (4/4 here, 8/8 across both)

No version ceiling, licensing settled, the user-visible command and editor bugs
fixed. Split rather than shared: the licensing half was the game's (C2–C5, its
G1); this repository's share is C1, B5, B8, B9. C1's residue is still here —
`mods/vector3/mod.conf` carries a 5.5 ceiling.

### 2. Rewrite the sandbox preprocessor — done (11/11)

Stop corrupting valid programs; make the environment something a program cannot
reach out of.

### 3. Replace ActiveFormspecs — done (3/3 here, 5/5 across both)

Last unmaintained dependency gone; documentation generated from the code. Split
rather than shared: the CI split and the boot warnings were the game's (A14, B20,
its G2); this repository's share is A1, A2, B22.

### 4. Performance — done (4/4)

The drone builds at the speed the hardware allows, not one pinned to the tick
rate; bulk shapes are one VoxelManip pass each.

### 5. Limits that track real load — done (4/4)

Committed as `43e95a8`, CI green. Every limit given a resource to stand for, the
step budget made a shared pool, `settingtypes.txt` added, the default codelevel
split between singleplayer and server. Three of its items were **superseded
within the week** by Phase 6 and no longer exist as described — read the audit,
not the old wording.

### 6. Limits that stand for what the server spends — done (3/3)

Committed as `2647228` and adopted by the game at `33bdae8`; CI green on both by
`head_sha` — `luacheck`, the six standalone specs and `gen_docs.lua --check`.
Eleven per-codelevel limits counted proxies; seven now count what the server
actually spends, in units a player and an administrator can read.

Shipped: `lib/limits.lua`, the seven limits that replaced eleven proxies, sliced
bulk shapes so a large one is slow rather than a freeze, and the mapblock-memo
fix that could otherwise lose a write. (S5, C13, A5, B25, B26, C14; the full
list is in `CHANGELOG.md`.)

Still open around it, not part of the phase: playtesting of pacing and the
map-footprint throttle. A `pace_ms` figure changed afterwards needs the
`doc/api.md` row and `settingtypes.txt` changed with it, and
`gen_docs.lua --check` is what catches the omission.

### 7. Clear the way for features — not started (4/19 here)

Remove the duplication and dead weight that make every new feature cost more
than it should. Four of its findings are already closed — CI for this repository
(A16), the changelog corrections (C11), the `.luacheckrc` exemptions (C12) and
the release archive (C10). Five more belong to the game — vendored `default`,
`cc_day`, `cc_security` — and are its milestones G3 and G4.

- Give the drone record one owner and split `drone.lua` / `drone_entity.lua` by
  direction of dependency; move the two form builders to `formspecs.lua` and
  report completion from one place. Closes B10 and B11 with it. (A11)
- Split `lib/commands.lua`, now 971 lines of largely mechanical repetition. (A3)
- Flatten the entity prototype's two-level metatable chain. (A6)
- De-duplicate the filesystem read path and its six near-identical getters. (A9)
- Fix the file-read error that prints a file handle instead of a filename. (B7)
- Fix `save_editor_state` passing nil to `set_string`, `write_file` /
  `remove_file` indexing an unpopulated cache, a number passed to `set_string`,
  and the dead branch that leaves cylinder coordinates nil. (B13, B14, B17, B18)
- Stop wiping the player's whole inventory on every join. (B16)
- Add error handling to example loading, which also leaks handles. (B15)
- Fold `minetest.*` → `core.*` into other edits; style, not breakage. (C6)
- Clear the last 8 trailing-whitespace sites. (B21)

### 8. Show the budget — not started (0/1)

The last thing before v1.0.0, and a feature rather than a fix: a player should
see what a program is spending while it runs.

- Show each count beside its limit, live rather than only on completion, and the
  *binding* constraint as a percentage. `drone.budget` already pairs `caps` with
  `used`; peak heap is still not kept, and the charged-CPU figure dropped from
  the completion line belongs here as a share. The live half depends on A11.
  (`TODO.md`)

## What ships broken

- `heap_mb` cannot stop one huge allocation, and a pathological Lua pattern can
  still burn CPU inside a single `find` or `match`. (S2's residue)
- The step budget is never checked *inside* one VoxelManip pass, so a single
  slab — around 65k nodes, under 10 ms — still overshoots it.
- The map footprint decays linearly over the unload window rather than tracking
  each block, so it estimates what is resident rather than measuring it.
- `place()` writes one node per call; the four bulk shapes do not. (A4)
- Pacing, slab progression and the footprint throttle have no in-world
  verification: the specs run before a map exists, so `place()` is unreachable
  from them. Untested, not known broken.
- Unknown whether mapgen can overwrite a node written into a never-generated
  area when a player later visits and it generates.
- `scripts/gen_cdb_json.sh` here is verified by nothing; the game's copy is
  diffed by `check_game.sh`, this one is not.
- `.gitattributes` decides what reaches a player and **no CI checks it**, in
  either repository. A file added here ships in the ContentDB archive unless a
  rule excludes it, and nothing local fails when one does. (C10)
- `mods/codeblock` has no `.gitignore`, so the audit beside this file shows as
  untracked and can be committed by accident. It needs one containing `.audit/`.

## Deliberately not doing

- **Batching `place()` into `core.bulk_set_node`.** 1.3x by the engine's own
  figure, against five flush sites whose omission is a silently wrong build.
  Contingent on the yield cadence, which Phase 6 changed, so the arithmetic
  under A4 in the audit wants redoing before the decision is quoted again.
- **Migrating off `minetest.*` as a project.** `minetest` is a permanent alias
  for `core`, with no deprecation warning and no removal date. (C6)
- **Chasing the last `.editorconfig` difference.** `align_call_args = true`
  fixes the wrapped-argument alignment but pushes a table constructor passed to
  a call out to the paren column, which is worse. Alignment stays off and the
  tree drifts to the hanging indent one file at a time.
- **Computing the codelevel limits instead of overriding literals.**
  `gen_docs.lua` reads `lib/config.lua` for a name assigned a table of numbers,
  so a computed value would silently disable the check that every limit is
  documented. (C7, C14)
- **Moving the settings to the game.** Every one of them is this mod's, and this
  mod is its own ContentDB package; here it works for a standalone install and
  appears under Mods. (C7)
- **Blockly web editor.** Wanted, out of scope for 1.0.0.

---

2026-08-26 · codeblock `2647228` (master) · codecube `33bdae8` (main), which is
the commit that adopted it. Both at `origin`, both green in CI. Phases 7 and 8
have no code. Uncommitted in the working tree as this was written: the
`.gitattributes` rewrite (C10), the deletion of `doc/api.html` and
`scripts/gen_doc_html.sh`, and these record files.
