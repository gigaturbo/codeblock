# Roadmap — CodeBlock

Where the mod stands and what to do next. CodeBlock is the main project; the
`codecube` game is a consumer of its releases and keeps its own record.

The reasoning behind every item lives in **this mod's own audit**,
`.audit/audit.html` beside this file — gitignored, and the main audit of the two.

Numbering, so a commit message always resolves: phases are `Phase 0`–`Phase 8`,
never renumbered; ids are `B` bug, `S` sandbox and security, `C` compliance and
packaging, `A` architecture — allocated once across both audits, so twelve are the
game's (`C2`–`C5`, `A14`, `B20`, `A13`, `B19`, `B24`, `A7`, `A8`, `C15`) — and `F`
is features, `F1`–`F6`, this project's own. Nothing is ever renumbered.

The manual checks no spec can reach are in **`tests/PLAYTEST.md`** with their
results: thirty checks, nine with one. How a feature gets built here is in
`CLAUDE.md`.

Target is **v1.0.0**, major because several changes break saved player programs.

## Now

**One more editor playtest session, then `F2`.** Six checks are open on code that
has just shipped, all of them in the same form, so one session covers them: `E9`
first — the editor's tab state surviving a server shutdown, the one part of
`B33`'s fix that rests on an assumption about the engine rather than on read
code — then `E8`, `E10`, `E12`, and `F1`'s two, the relog being the weightier.

`F1` shipped at `500dd85` with **CI green** (run 23), carrying `B33` and `B35`
with it. Nothing is waiting on a commit, and `F2` has nothing in front of it.

## Milestones

Phases 0–7 are closed: one line each, no reasons — the audit holds them, under
the ids given.

- **0. Make change safe** — done (2/2). (C8, A12)
- **1. Ship the compliance fixes** — done (4/4 here, 8/8 across both). (C1, B5,
  B8, B9)
- **2. Rewrite the sandbox preprocessor** — done (11/11). (B1–B4, B6, B23, S1–S4,
  A10)
- **3. Replace ActiveFormspecs** — done (3/3 here, 5/5 across both). (A1, A2,
  B22)
- **4. Performance** — done (4/4). (A5, B12, A4, A15)
- **5. Limits that track real load** — done (4/4), `43e95a8`. (S5, S6, C7, C13)
- **6. Limits that stand for what the server spends** — done (3/3), `2647228`.
  (B25, B26, C14)
- **7. Clear the way for features** — done (26/26 here, 26/31 across both),
  `742a1ca`–`191b533`, CI green at `3293a2c`. (A3, A6, A9, A11, A16, C6, C10–C12,
  B7, B10, B11, B13–B18, B21, B27–B32, C16)

"Done" through Phase 7 means the findings are closed and the gates green, not
that the editor and drone paths were exercised by hand.

### 8. Features — in progress (1/6 shipped, 3/3 findings closed)

Add rather than repair, easiest to hardest, one at a time. `F4` and `F5` want the
drone and pacing playtest groups run before they start.

Shipped and closed:

- The default block: a Settings panel in the editor, plus a run-local
  `default_block(block)`. `500dd85`, CI green. (F1)
- The editor's tab state is written on every exit, not one branch. `500dd85`.
  (B33)
- The text typed since the last save survives every button. `500dd85`. (B35)
- Both editor checkboxes start ticked for a player who never set them.
  `500dd85`. (no finding)

Still to do — run the open in-world checks, then the features in order:

- Play `E9`, `E8`, `E10`, `E12` and `F1`'s two checks. (F1, B33, B35)
- Open a copy of a program, from the editor or the chooser. Decide the collision
  naming before writing it, and keep `lib/examples.lua`'s end-anchored `.lua`
  strip in mind. (F2)
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

## What ships broken

- `heap_mb` cannot stop one huge allocation, and a pathological Lua pattern can
  still burn CPU inside a single `find` or `match`. (S2's residue)
- The step budget is never checked *inside* one VoxelManip pass, so a single
  slab — around 65k nodes, under 10 ms — still overshoots it.
- The map footprint decays linearly over the unload window rather than tracking
  each block, so it estimates what is resident rather than measuring it.
- `place()` writes one node per call; the four bulk shapes do not. (A4)
- A file cannot be removed from the editor without opening it first — decided
  against fixing. (B34)
- The editor's tab state surviving a **server shutdown** is unverified: it rests
  on `on_shutdown` meta writes still being saved, never observed here. (B33)
- Most of what needs a running world is unverified — pacing, slabs, the footprint
  throttle, the filesystem, drone placement, C16's install guard. Nine of thirty
  `tests/PLAYTEST.md` checks carry a result.
- B14's cold-cache removal is unreachable from the editor for good; only a
  removal straight after a rejoin can settle it. (B14, B34)
- Unknown whether mapgen can overwrite a node written into never-generated ground.
- `mods/vector3/mod.conf` still carries a 5.5 version ceiling — separate
  repository, not fixable from here. (C1)
- `scripts/gen_cdb_json.sh` is verified by nothing and escapes neither `"` nor `\`.
- `.gitattributes` decides what reaches a player and **no CI checks it**. (C10)
- `README.md:14`'s trailing whitespace is deliberate — a Markdown hard break
  `gen_cdb_json.sh` folds into the ContentDB description. (B21)

## Deliberately not doing

- **Batching `place()` into `core.bulk_set_node`.** 1.3x, against five flush
  sites whose omission is a silently wrong build; the arithmetic wants redoing
  since Phase 6 changed the yield cadence. (A4)
- **A persist flag on `default_block()`.** The only API call that would outlive
  its run, and a shared program would rewrite the reader's preference. (F1)
- **Blockly in 1.0.0.** Needs an HTTP allowance only an administrator can grant.
  Not abandoned: `F6`, first after the release. (Confirm or overrule.)
- **Chasing the remaining `minetest` names.** What is left must stay: the config
  filename, the forbidden-identifier list naming both aliases, the `vector3`
  submodule. Same for `loadstring`, `setfenv`, `math.pow`, `math.atan2`. (C6)
- **The last `.editorconfig` difference.** `align_call_args = true` fixes wrapped
  arguments but pushes a table constructor out to the paren column.
- **Computing the codelevel limits instead of overriding literals.** It would
  silently disable `gen_docs.lua`'s check that every limit is documented. (C7,
  C14)
- **Letting a file be removed without opening it first.** "Won't fix now, not
  really needed" — and B14's cold path stays unreachable as a result. (B34)
- **Resurrecting the `soe` checkbox.** Deliberately dead; what is wanted instead
  is a warning when the editor closes with unsaved changes (in `TODO.md`).
- **Moving the settings to the game.** They are all this mod's, and it is its own
  ContentDB package. (C7)

---

2026-08-27 · codeblock `500dd85` (master), pushed; `HEAD` and `origin/master`
agree, and only the record documents are uncommitted. **CI green on `500dd85`** —
run 23, all three jobs. **Local gates green too**, engine 5.17.0: luacheck clean,
`gen_docs.lua --check` up to date, nine in-engine specs **365 passed, 0 failed,
0 xpass, 1 xfail**. Those specs reach no formspec and no player meta, so the
editor work rests on the code plus two hand checks. Local results are the
author's report, not runs made for this document.
