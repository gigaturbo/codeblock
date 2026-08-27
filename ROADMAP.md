# Roadmap — CodeBlock

Where the mod stands and what to do next. CodeBlock is the main project; the
`codecube` game is a consumer of its releases and keeps its own record.

The reasoning behind every item lives in **this mod's own audit**,
`.audit/audit.html` beside this file — gitignored, and the main audit of the two.

Numbering, so a commit message always resolves: phases are `Phase 0`–`Phase 8`;
ids are `B` bug, `S` sandbox and security, `C` compliance and packaging, `A`
architecture, allocated once across both audits so twelve are the game's
(`C2`–`C5`, `A14`, `B20`, `A13`, `B19`, `B24`, `A7`, `A8`, `C15`), and `F` is
features, `F1`–`F6`, this project's own. Nothing is ever renumbered.

The manual checks no spec can reach are in **`tests/PLAYTEST.md`** with their
results: thirty-four checks, twenty-two with one — sixteen pass, three partial,
three fail. How a feature gets built here is in `CLAUDE.md`.

Target is **v1.0.0**, major because several changes break saved player programs.

## Now

**Push the seven commits — `dee0bc7` through `b5d2e40` — to `origin/master` at
`98619e5`.** No fix is outstanding, and this is the author's to authorise, not an
action to take from here: the gates are green at `b5d2e40`, read from their output
rather than from exit codes. CI has seen none of the seven, and `b5d2e40` adds a
step — `gen_locale.lua --check` has run nowhere but this machine. Then five short
in-world checks: `D2` both cases, `D4` case 2, `F-2` in **French**, `D3` part 2
(the setter, the only route to `B29`'s serial window) and `F-3` case 1.

One thing wants an answer rather than an action: **C18**, the five sky overrides
forced on every joining player. Recommended: one setting, defaulting off. It does
not block the push and should not reach v1.0.0 undecided. `F4` is next after
that, and wants the pacing group played first.

## Milestones

Phases 0–7 are closed: one line each, no reasons — the audit holds them, under
the ids given.

- **0. Make change safe** — done (2/2). (C8, A12)
- **1. Ship the compliance fixes** — done (4/4). (C1, B5, B8, B9)
- **2. Rewrite the sandbox preprocessor** — done (11/11). (B1–B4, B6, B23, S1–S4, A10)
- **3. Replace ActiveFormspecs** — done (3/3). (A1, A2, B22)
- **4. Performance** — done (4/4). (A5, B12, A4, A15)
- **5. Limits that track real load** — done (4/4), `43e95a8`. (S5, S6, C7, C13)
- **6. Limits for what the server spends** — done (3/3), `2647228`. (B25, B26, C14)
- **7. Clear the way for features** — done (26/26), `742a1ca`–`191b533`, CI green
  at `3293a2c`. (A3, A6, A9, A11, A16, C6, C10–C12, B7, B10, B11, B13–B18, B21,
  B27–B32, C16)

"Done" through Phase 7 means the findings are closed and the gates green, not
that the editor and drone paths were exercised by hand. Phase 8's playtests have
since found three defects in code earlier phases had called done — one of them
introduced by a Phase 7 fix (B38, B39, C17).

### 8. Features — in progress (3/6 shipped, 8 findings closed, 1 open)

Add rather than repair, easiest to hardest, one at a time. `F4` and `F5` want the
pacing playtest group run before they start; the drone group has now been run and
cost two findings.

Shipped and closed (gates green on all; only `500dd85` is pushed):

- The default block: a Settings panel, plus a run-local `default_block(block)`.
  `500dd85`, CI green. (F1)
- Create a copy, and a file list sorting `foo_2` before `foo_10`. `dee0bc7`. (F2)
- `sleep(seconds)`, the wait charged against `max_runtime_s` up front so it cannot
  run for ever. `90cfb70`, gates green. (F3)
- The editor's tab state written on every exit, and the typed text surviving every
  button. `500dd85`. (B33, B35)
- The ticked checkbox default reachable, and ESC and Enter reaching their own
  branches past three always-sent scrollbars. `1f7cd97`. (B36, B37)
- Aiming the poser at nothing is refused instead of ignored — the engine calls
  `on_secondary_use`, not `on_place`. `b5d2e40`. (B38)
- The first join after an install no longer wipes the inventory: `set_tools` adds
  what is missing and clears nothing. `b5d2e40`. (B39)
- `locale/template.txt` regenerated, the French locale completed, and
  `gen_locale.lua --check` added to CI. `b5d2e40`. (C17)

Still to do — the push, the open in-world checks, then the features in order:

- Push the seven commits, `dee0bc7` to `b5d2e40` — gates green, CI has seen none.
  Awaiting the author. (F3, B36, B37, B38, B39, C17)
- Re-run `D2` (both cases), `D4` (case 2) and `F-2` in French. (B38, B39, C17)
- Run `D3` part 2 — remove a running drone with the setter and place another at
  once, the only route to the serial window — and `F-3` case 1. (B29, B7)
- Play `F1`'s two checks and `F3`'s `sleep` check. (F1, F3)
- Decide what happens to the five sky overrides in `register_on_joinplayer` —
  permanent daylight, no sun, moon, stars or clouds, on every player of every
  installing game, from a block commented `TODO: TEMP fix`. Recommended: one
  setting, defaulting off. **Open, and the author's call.** (C18)
- Decide whether `settingtypes.txt` gets a generator and a `--check`, as
  `doc/api.md` and `locale/template.txt` now have. Open question. (C7, C17)
- Settle `E12` by reading the file's size or mtime from outside the game; reading
  the code is exhausted. No finding id until there is evidence. (no finding)
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
- A file cannot be removed from the editor without opening it first, so B14's
  cold-cache removal is unreachable for good; only a removal straight after a
  rejoin can settle it. (B34, B14)
- A copy of a name already at the 15-character limit shifts base at the tenth
  copy — fixing it would let copies past the length rule. (F2)
- A player created before `1f7cd97` keeps the stored "off" for both editor
  checkboxes; the ticked default reaches new players only. (B36)
- `save_on_exit` is read, written and acted on nowhere: the checkbox stays
  commented out and a warning on unsaved changes is what is wanted instead.
- Most of what needs a running world is unverified — pacing, slabs, the footprint
  throttle, `sleep`, C16's install guard. Twenty-two of thirty-four
  `tests/PLAYTEST.md` checks carry a result; two of the three fails are fixed at
  `b5d2e40` and await a re-run.
- `E12` is unexplained: **Save on tab switch** off is reported to write anyway,
  in three runs, and no write has been found by reading. No finding id.
- `settingtypes.txt` mirrors `lib/config.lua` by hand and nothing checks it — the
  third such mirror, and the only one without a `--check`. (C7, C17)
- Joining forces permanent daylight and hides the sun, moon, stars and clouds,
  with no setting and no way to decline. Open, undecided. (C18)
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
- **Saving the original before copying it**, and **a `filesystem.copy_file`
  helper.** A copy is a copy; and it is a derived name plus `write_file`, the
  module's one write path, so a helper would hide a write. (F2)
- **A persist flag on `default_block()`.** The only API call that would outlive
  its run, and a shared program would rewrite the reader's preference. (F1)
- **A per-codelevel cap on `sleep`**, and **routing it through `end_command`.**
  The wait is charged against `max_runtime_s` up front, which bounds it without
  another limit; and `end_command` writes `wake_at` from `pace_ms`, last writer
  winning. A sleep is not a command. (F3)
- **Blockly in 1.0.0.** Needs an HTTP allowance only an administrator can grant.
  Not abandoned: `F6`, first after the release. (Confirm or overrule.)
- **Chasing the remaining `minetest` names.** What is left must stay: the config
  filename, the forbidden-identifier list naming both aliases, the `vector3`
  submodule. Same for `loadstring`, `setfenv`, `math.pow`, `math.atan2`. (C6)
- **The last `.editorconfig` difference.** `align_call_args = true` fixes wrapped
  arguments but pushes a table constructor out to the paren column.
- **Computing the codelevel limits instead of overriding literals.** It would
  silently disable `gen_docs.lua`'s documented-limit check. (C7, C14)
- **Letting a file be removed without opening it first.** "Won't fix now, not
  really needed" — B14's cold path stays unreachable as a result. (B34)
- **Resurrecting the `soe` checkbox.** Deliberately dead; a warning on unsaved
  changes is what is wanted instead (in `TODO.md`).
- **Moving the settings to the game.** They are all this mod's, and it is its own
  ContentDB package. (C7)

---

2026-08-27 · codeblock `b5d2e40` (master), **not pushed** — `origin/master` is
`98619e5`, seven commits behind, and only `tests/PLAYTEST.md`'s fourth-run
results and the record documents are uncommitted. **CI green at `98619e5`**
(run 24); no CI run has seen any of the seven, and one of them adds a CI step.
**Local gates green at `b5d2e40`**, engine 5.17.0, read from their output rather
than from exit codes: luacheck silent, `doc/api.md is up to date`,
`locale/template.txt is up to date`, nine in-engine specs **374 passed, 0 failed,
1 xfail, 0 xpass**, six standalone specs green under plain Lua 5.1. Those specs
reach no formspec, tool callback, inventory, filesystem, player meta or locale
file, so `F2`, `B36`–`B39`, `C17` and the rest of the editor and drone work rest
on the code plus what the author played. Local results are the author's report,
not runs made for this document.
