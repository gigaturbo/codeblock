# Roadmap — CodeBlock

What to do next, in order, and **what has been agreed** — the shape of a feature
as settled in conversation, a part argued out, a rewording, a default chosen.
Those decisions are recorded nowhere else: git holds the code and `CHANGELOG.md`
holds what shipped, but neither says why a question is settled, so without this
file a settled question gets re-litigated. Compressed as it grows; only the
minimum past information stays.

Findings and their reasoning are in `AUDIT.md`. Manual checks are in
`PLAYTEST.md`. Intentions not yet planned are in `TODO.md`.

Numbering, so a commit message always resolves: phases are `Phase 0`–`Phase 8`,
features are `F1`–`F6`, and finding ids are `B`/`S`/`C`/`A`. **Nothing is ever
renumbered.**

Target is **v1.0.0** — a correct sandbox, no unmaintained dependencies,
documentation generated from the code, tests enough that changes are safe. Major,
because several changes break saved player programs.

## Now

**Play the five outstanding in-world checks.** Everything is pushed and CI is
green at `b8b30e3` (run 25 — the first to run `gen_locale.lua --check`), so
nothing is outstanding against code and the whole backlog is *checking*: `D2`
both cases, `D4` case 2 and `F-2` in French are the three fixes in `b5d2e40`
that no machine can verify; `D3` part 2 is the only route to `B29`'s serial
window; `F-3` case 1 now has a procedure. Then the pacing group, which is the
behaviour `F4` exists to display.

One thing wants an answer rather than an action: **`C18`**, the five sky
overrides forced on every joining player. Recommended: one setting, defaulting
off. It blocks nothing but should not reach v1.0.0 undecided.

`E12` is not on that list: it wants the file's size or mtime read from **outside**
the game, and reading the code is exhausted.

## Milestones

Phases 0–7 are closed; one line each, with the findings they covered — `AUDIT.md`
holds the reasoning.

- **0 · Make change safe** — done (2/2). Run on the current engine, put the
  riskiest code under test, restore linting. (C8, A12)
- **1 · Ship the compliance fixes** — done (4/4). Installable and honest: the
  ContentDB version ceiling gone, licensing settled, the user-visible command and
  editor bugs fixed. (C1, B5, B8, B9)
- **2 · Rewrite the sandbox preprocessor** — done (11/11). Instrumentation over a
  token stream, per-run environment snapshots with unassignable API names, the
  blacklist retired to a diagnostics aid, the string metatable bounded.
  (B1–B4, B6, B23, S1–S4, A10)
- **3 · Replace ActiveFormspecs** — done (3/3). The last unmaintained dependency
  gone, and with it the only code patching the engine namespace; documentation
  generated from `lib/api.lua` landed alongside. (A1, A2, B22)
- **4 · Performance** — done (4/4). The drone builds at the speed the hardware
  allows, bulk shapes are one VoxelManip pass each, the WorldEdit fork is gone
  entirely. (A5, B12, A4, A15)
- **5 · Limits that track real load** — done (4/4), `43e95a8`. Gave each limit a
  resource to stand for, made the step budget a shared pool, added
  `settingtypes.txt`. (S5, S6, C7, C13)
- **6 · Limits for what the server spends** — done (3/3), `2647228`. Eleven
  proxy limits became seven real ones, each in a unit a player reads, converted
  once in `lib/limits.lua`. (B25, B26, C14)
- **7 · Clear the way for features** — done (26/26), `742a1ca`–`191b533`.
  Removed the duplication that made every feature cost more than it should. Two
  reviews of the range then opened seven findings, five of them regressions the
  phase itself introduced. (A3, A6, A9, A11, A16, C6, C10–C12, B7, B10, B11,
  B13–B18, B21, B27–B32, C16)

"Done" through Phase 7 means the findings are closed and the gates green, **not**
that the editor and drone paths were exercised by hand. Phase 8's playtests have
since found five defects in code earlier phases called done (B36–B39, C17) plus
one open finding (C18).

### 8 · Features — in progress (3/6 shipped · 8 findings closed, 1 open)

The last phase before v1.0.0 and the only one that adds rather than repairs.
Ordered easiest to hardest, one at a time. `F4` and `F5` want the pacing group
played first, because both build on paths no spec reaches.

Shipped, gates green, pushed and CI-green at `b8b30e3`:

- `F1` default block — a Settings panel plus a run-local `default_block(block)`.
  `500dd85`.
- `F2` *Create a copy*, and a file list sorting `foo_2` before `foo_10`.
  `dee0bc7`.
- `F3` `sleep(seconds)`, charged against `max_runtime_s` up front. `90cfb70`.

Left in the phase:

- Run `D2` (both cases), `D4` case 2 and `F-2` in French. (B38, B39, C17)
- Run `D3` part 2 — remove a running drone with the setter and place another at
  once — and `F-3` case 1. (B29, B7)
- Run `F1`'s two checks and `F3`'s `sleep` check. (F1, F3)
- Run the pacing group before starting `F4`. (S5, A5)
- Decide `C18`, the five sky overrides. **Open, the author's call.**
- Decide whether `settingtypes.txt` gets a generator and a `--check`, as
  `doc/api.md` and `locale/template.txt` have. Open question. (C7, C17)
- Settle `E12` from outside the game; reading is exhausted. (no finding)
- Build `F4`, the live drone panel.
- Build `F5`, changing a codelevel mid-run.
- `F6`, Blockly — planned, **out of 1.0.0**, first item after it.

## The features

Ids are quotable in commit messages and never renumbered. A shipped entry keeps
only the constraints a future change would re-break; the survey of options that
led to it is in git and `CHANGELOG.md`.

### F1 · small · shipped `500dd85` — the default block for a bare `place()`

A bare `place()` built `default:stone` always. Now the player picks a default in a
Settings panel in the editor, stored per player in meta under
`codeblock:default_block`, and a program can override it for its own run with
`default_block(block)`. **Two levels deliberately:** *what do I usually build
with* belongs to the player and outlives the session; *what does this program
build with* belongs to the program and travels with it when shared.

**Agreed, and load-bearing.**

- **The picker is a `textlist`, not item rows in a `scroll_container`.** The
  editor formspec is in **legacy coordinates**, where a `scroll_container` maps
  its contents into a different space from the elements around it and clips them
  to its own rectangle, and an `item_image_button` inside one gets a hit area that
  does not match where it is drawn. The help panels get away with a container only
  because `item_image` takes no clicks. Do not "restore" the item-row plan without
  first converting the whole editor to the new coordinate system.
- **A legacy button's `W` is not a width.** From `src/gui/guiFormSpecMenu.cpp` at
  tag 5.17.0: a `button` gets `geom.X = W*spacing.X - (spacing.X - imgsize.X)`
  while a `textlist` gets `geom.X = W*spacing.X`, with `spacing = imgsize * 5/4`.
  So a button is short by a fixed **0.2 units whatever `W` is** — the offset does
  not scale. Hence `F2`'s *Create a copy* is `3.2` against a 3-wide file list and
  `+` is `0.95`. `H` is not a height either: the height is fixed and `H` only
  shifts it down. **`lua_api.md` 5.17.0 records none of this**, so the reference
  cannot settle a misalignment here.
- **One panel, not a second form.** `lib/forms.lua` holds one form per player, so
  a settings form would displace the editor. Every future setting adds a row to
  this panel.
- **Not privileged, unlike everything beside it.** No setting, no
  `settingtypes.txt` entry, no codelevel row: codelevel is privileged because it
  bounds resource use, and block choice does not — stone and red wool cost the
  server the same. `air` is selectable, being already legal for `place()`, so a
  bare `place()` can erase; visible at once, and useful for carving.
- **The preference is read once per run** into `drone.default_block`, so a mid-run
  change cannot split one build between two blocks, and the resolution is a plain
  field `integration_spec` can set without a player. **The read validates through
  `blocks` and falls back to stone** — meta outlives a palette change, and without
  the fallback the failure surfaces as *"Cannot place this block"* on a line that
  named no block. Validate *through* `blocks`, not around it, or a default
  arriving from a form becomes a way to place any node name. **Because the
  fallback is mandatory, no init line was added** to the meta block in
  `lib/register.lua`, unlike its neighbours. **Meta is written on click**, not on
  form close, which is what kept the preference immune to `B33`.
- **Argued out: a `persist` flag on `default_block()`.** Cut on four grounds — it
  would be the only API call whose effect outlives its run; a shared program would
  silently rewrite the reader's saved preference with no undo; in a loop it is a
  meta write per iteration from inside a budgeted run; and no spec could reach it.
  If persistence from a program is ever wanted it gets its own command, not a flag
  on an innocuous-looking call.

Open against it: two `PLAYTEST.md` checks, the Settings panel and the preference
surviving a relog. Outstanding *checking*, not unfinished work.

### F2 · small · shipped `dee0bc7` — open a copy of a program

A *Create a copy* button in the editor, bottom-left beside `+`, drawn only with a
file open. It writes what is on screen to a derived name and opens it, so a player
can try a variation without touching the version that works. Plus, asked for after
the first playtest: the file list is sorted so `foo_2` precedes `foo_10`.

**Agreed, and load-bearing.**

- **The naming derivation.** `foo.lua` → `foo_1.lua` → `foo_2.lua`, scanning for
  the first free *N* up to 99. **Numeric because the author asked for it
  explicitly:** language-agnostic, so the name does not depend on the server's
  locale. **Strip a trailing `_%d+` before appending**, and never widen either
  strip to match mid-name — both are anchored to the end, as `lib/examples.lua`'s
  `.lua` strip is. The first implementation used a `_copy` suffix and took the
  whole stem, so the previous suffix became part of the next base; since the base
  is also what gets trimmed to `create_file`'s 15-character limit, each round both
  nested and lost a character (`spirals_c__copy.lua`, `spirals_co_copy.lua`).
  Trimming the suffix instead of the base is not an option — it hands back the
  original name for any stem already at the limit.
- **Two behaviours are deliberate.** A freed number is reused: copying
  `foo_2.lua` with `foo_1.lua` deleted gives `foo_1.lua`. And a name already at
  the 15-character limit shifts base at the tenth copy
  (`spirals_conce_9` → `spirals_conc_10`), so copying *that* starts a new family;
  fixing it would let copies past the length rule every other filename obeys.
- **The four scope decisions.** Bottom-left, **not** the Save/Remove/Close row —
  that row already runs to `x=14.08` against a help row starting at 14, so a fifth
  button there means re-laying-out four that work. The copy contains **what is on
  screen, not what is on disk**. The name is **derived, not typed**. The drone's
  file chooser does **not** get the button.
- **Argued out:** saving the original before copying it — a copy is a copy, and
  the original is left exactly as it is; and a `filesystem.copy_file` helper — a
  copy is a derived name plus `write_file`, already the module's one write path, so
  a helper called from one branch would hide ownership of a write and be a second
  write path.
- **The natural sort key** lives in `lib/filesystem.lua` and prefixes each digit
  run with its own length (`('%03d'):format(#digits) .. digits`), so `foo_2`
  precedes `foo_10` **without guessing a padding width**. Case is not folded, so
  the rest of the ordering is the byte order it has always been; the key is
  injective, so no tie-break is needed. The drone's file chooser reads the same
  `ud.list` and is sorted with it for free — one sort, two consumers, which is why
  the key belongs in the filesystem layer and not in the form.

No spec reaches it and none was added: `forms_spec` stubs `core.show_formspec` and
tests the session layer only, so driving this would need a stubbed filesystem and
a stubbed player. Evidence is the code plus `PLAYTEST.md` `E13`, pass.

### F3 · medium · shipped `90cfb70` — `sleep(seconds)`

`sleep(2)` parks the drone for two seconds and hands the step back, so a program
builds at a pace it chooses rather than the codelevel's. Defaults to one second,
takes fractions. The mechanism was already there — `drone.wake_at`, which
`pace_ms` and the map throttle both use — so this is a new API name plus a charge,
not new machinery. **Named `sleep`, not the `wait` first specified.**

**Agreed, and load-bearing.**

- **The risk was wall time, not CPU, and it is answered by charging up front.**
  `max_runtime_s` charges the time a *step* spent, so a sleeping drone is charged
  nothing and an unbounded wait would let a program live for ever holding a
  record, an entity and a slot in the shared pool. The wait is therefore charged
  against `max_runtime_s` *before* it starts: `sleep(1e9)` puts the run past its
  ceiling and the stepper reports the same timeout a program that never finishes
  gets. **That is `max_runtime_s`'s one exception** — it now bounds time the
  program did not spend on CPU — and both places it is documented say so.
- **Argued out: a per-codelevel cap on `sleep`.** The up-front charge bounds it
  without another limit, so no new limit, no `settingtypes.txt` mirror and no
  `doc/api.md` codelevel row were needed.
- **Argued out: routing it through `end_command`.** That writes `wake_at` from
  `pace_ms` and the last writer wins, so a sleep routed through it would be
  overwritten or would overwrite the pace. **A sleep is not a command:** it pays
  no pace and is not counted as one.
- **It must keep yielding through `release()`** — the only `coroutine.yield` in
  `lib/cost.lua`, which clears the mapblock memo first. Yielding any other way
  reintroduces `B25`'s silent lost write.
- **Adding a name is breaking even though nothing was renamed.** `env.new_env`
  raises on assignment to any name the API defines, so a saved program using
  `sleep` as its own global now fails on that line. The edit spans `lib/api.lua`,
  `impls` in `lib/sandbox.lua`, regenerated `doc/api.md` and `api_spec`'s explicit
  name list. **`api_spec` needs no reverse "no unexpected name" check** — that
  would duplicate `api.build` and turn every future API addition into a spec edit.

Spec coverage is unusually good: `integration_spec` gained nine assertions
(98 → 107), and `stepper_spec` already injects the clock and the budget, so "a
sleeping drone is skipped and takes no share" is assertable without a world. What
only a world shows is the pace being watchable and other drones being unaffected —
`PLAYTEST.md` `F3`, unrun.

### F4 · large · planned — a live drone panel

One panel per drone: running or idle, which file, each count beside its limit, the
**binding** constraint as a percentage so a player learns which limit their
program actually spends, and buttons to start, pause and cancel. Today a player
learns all of this only from `Drone.finish`'s one completion line.

**Merged from three `TODO.md` lines, because they are one formspec:** the drone
info UI, "show the program's budget while it runs" (the original Phase 8 item), and
the player-side half of "option to pause the drone" (the timed, in-program half is
`F3`). Splitting them would mean two features editing the same form and the second
rewriting the first.

**Constraints and risks.**

- **The data is already shaped for it.** `lib/limits.lua` keeps `caps` and `used`
  in one table on `drone.budget` precisely so it can be printed. Two numbers are
  missing rather than hidden: **peak heap is never retained** (`heap_mb` is
  sampled and compared, never kept), and the charged-CPU figure was dropped from
  the completion line in Phase 6 as meaningless against a ceiling in minutes — it
  belongs here as a **share** of the budget (`B26`).
- **Do not reintroduce the dependency `A11` removed.** `lib/drone.lua` does not
  know forms exist. Drive the live refresh from the form side reading
  `drone.budget`, not by `drone.lua` calling `update_form`. `Drone.on_place`
  already sets the precedent: it *returns* whether a file is needed and
  `register.lua` shows the chooser.
- **A live formspec is a redraw cadence, and that is the performance risk.**
  `core.show_formspec` per server step per player is a packet per step; pick an
  interval and state it in the code. Redraw also resets input focus, so a panel
  that redraws while a text field is focused is unusable — keep it separate from
  the editor form, or refresh only non-editable fields. `lib/forms.lua` holds one
  form per player, so opening this panel closes whatever else was open: **decide
  that explicitly rather than discovering it.**
- **Pause and cancel touch the lifecycle.** Cancel must go through
  `Drone.finish`, the single place an outcome is announced, or the player gets two
  messages or none (`B12`, `B30`). Pause is `drone.wake_at` again, so `F3`'s
  constraints apply. Anything reading a drone by name from a callback must respect
  the **serial guard** (`B29`): read the record fresh, as `lib/drone_entity.lua`
  does — a panel that caches a drone table across redraws hits exactly that.
- No API name, no new limit, no codelevel change. Spec coverage partial:
  `forms_spec` for session and handler routing, `limits_spec` for the binding-
  constraint arithmetic (**keep it a pure function of `caps` and `used`** so it
  can be), `stepper_spec` for pause. The drawing and the cadence cannot be
  spec'd, so this one wants its playtest group run first.

### F5 · large · planned — change a codelevel while a program runs

`/codelevel` takes effect on the next run, because `limits.new` converts the seven
ceilings once when the run starts. This would let a level change reach a run
already in progress — most usefully to slow a drone down to watch it, since
`pace_ms` is the level-1 and level-2 pacing.

**Constraints and risks.**

- **Codelevel is privileged, and this is the feature most able to break that.** An
  intermediate version once removed privs so players could set their own level — a
  privilege escalation, reverted before it shipped (`B9`). A player must not be
  able to raise their own level, and if it is exposed in `F4`'s panel the button
  has to be privilege-gated **per press, not per form**.
- **The subtler hole is the counters, not the privilege.** Rebuilding the budget
  from a new codelevel mid-run **must carry `used` across**; a rebuild that resets
  it turns re-levelling into a way to spend `max_nodes_written` or
  `max_runtime_s` twice over — a limit bypass through a legitimate command. That
  is the assertion to write first.
- The **held** resource is harder than the spent ones: the map footprint decays
  over `map_window_s` and is compared against a converted mapblock count, so
  lowering `map_memory_mb` under a run already over the new ceiling must make the
  drone **wait**, the existing behaviour, rather than fail. And `pace_ms` takes
  effect at the next `end_command`, so a level change while the drone sleeps does
  not shorten the sleep already scheduled — decide whether that matters.
- **Where it lands:** `lib/limits.lua` is dependency-free and does all the unit
  conversion, so add a re-derive there; nothing outside that file should do the
  arithmetic. No API name, no new limit, no new setting; it touches neither the
  serial guard nor the mapblock memo. Spec coverage good — `limits_spec` runs
  standalone and can pin the whole thing; the privilege path in
  `lib/register.lua` is not spec-reachable.

### F6 · post-1.0.0 · planned — Blockly web-based editor

Build programs by dragging blocks in a browser instead of typing Lua — the obvious
next step for the educational goal, and the reason it keeps coming back. **Planned
and deliberately out of 1.0.0**, keeping its id so a commit can cite it, and it is
the first item after the release. *A decision to confirm or overrule, not a
settled fact.*

Why it is last, and what would have to be true first:

- **This mod has no HTTP allowance and cannot give itself one.**
  `core.request_http_api` only returns a table for a mod named in the server's
  `secure.http_mods` or `secure.trusted_mods` — the administrator's setting, not
  something a ContentDB package can arrange, and something many servers refuse. A
  feature that silently does nothing on a correctly configured server is worse
  than one that is absent.
- **Mod security blocks the write side.** A mod may not write into its own
  directory — the same restriction that makes `codeblock_gen_docs` write
  `api.md` into the world directory. So generated Lua would have to land in the
  player's file area through `lib/filesystem.lua`, which has no spec coverage.
- **The assets have to come from somewhere.** Blockly is JavaScript and the engine
  has no browser. Either the player loads a page hosted elsewhere — a third-party
  runtime dependency for an offline single-player game, and a licensing and
  privacy question under AGPL-3.0-only — or something in-tree serves it, which is
  a server this mod does not have and `.gitattributes` would have to exclude from
  the archive.
- **What would settle whether it is feasible at all:** one written-down answer to
  *where do the assets live and who allows the HTTP call*, before any code. None of
  v1.0.0's goals depend on it.

## Other decisions worth not re-litigating

- **Batching `place()` into `core.bulk_set_node`** — not for 1.0.0. 1.3x against
  five flush sites whose omission is a silently wrong build; the arithmetic wants
  redoing since Phase 6 changed the yield cadence. (A4)
- **Letting a file be removed without opening it first** — won't fix, the author's
  words: "won't fix now, not really needed". `B14`'s cold path stays unreachable
  as a result. (B34)
- **Resurrecting the `soe` checkbox** — deliberately dead. A warning on unsaved
  changes is what is wanted instead (in `TODO.md`).
- **Chasing the remaining `minetest` names** — what is left must stay: the config
  filename, the forbidden-identifier list naming both aliases, the `vector3`
  submodule. Same for `loadstring`, `setfenv`, `math.pow`, `math.atan2`. (C6)
- **Computing the codelevel limits instead of overriding literals** — it would
  silently disable `gen_docs.lua`'s documented-limit check. (C7, C14)
- **Moving the settings to the game** — they are all this mod's, and it is its own
  ContentDB package. (C7)
- **The last `.editorconfig` difference** — `align_call_args = true` fixes wrapped
  arguments but pushes a table constructor out to the paren column.
- **A reverse "no unexpected API name" check in `api_spec`** — it would duplicate
  `api.build` and make every API addition a spec edit. (A16, F1)
- **Converting the editor form to the new coordinate system** — a change to the
  whole editor, unverifiable from a headless server, and not part of any feature
  that has needed it so far. (A1, F1)

## What ships broken

- `heap_mb` cannot stop one huge allocation, and a pathological Lua pattern can
  still burn CPU inside a single `find` or `match`. (S2)
- The step budget is never checked *inside* one VoxelManip pass, so a single slab
  — around 65k nodes, under 10 ms — still overshoots it. (A5)
- The map footprint decays linearly over the unload window rather than tracking
  each block, so it estimates what is resident rather than measuring it. (S5)
- `place()` writes one node per call; the four bulk shapes do not. (A4)
- A file cannot be removed from the editor without opening it first, so `B14`'s
  cold-cache removal is unreachable for good. (B34, B14)
- A copy of a name already at the 15-character limit shifts base at the tenth
  copy — fixing it would let copies past the length rule. (F2)
- A player created before `1f7cd97` keeps the stored "off" for both editor
  checkboxes; the ticked default reaches new players only. (B36)
- `save_on_exit` is read, written and acted on nowhere: the checkbox stays
  commented out.
- Most of what needs a running world is unverified — pacing, slabs, the footprint
  throttle, `sleep`, `C16`'s install guard. 22 of 34 `PLAYTEST.md` checks carry a
  result.
- `E12` is unexplained: **Save on tab switch** off is reported to write anyway, in
  three runs, and no write has been found by reading. No finding id.
- `settingtypes.txt` mirrors `lib/config.lua` by hand and nothing checks it — the
  third such mirror, and the only one without a `--check`. (C7, C17)
- Joining forces permanent daylight and hides the sun, moon, stars and clouds,
  with no setting and no way to decline. Open, undecided. (C18)
- Unknown whether mapgen can overwrite a node written into never-generated
  ground. (A4)
- `tests/game/mods/vector3/mod.conf` still carries a 5.5 version ceiling —
  separate repository, not fixable from here. (C1)
- `scripts/gen_cdb_json.sh` is verified by nothing and escapes neither `"` nor a
  backslash. (B22)
- `.gitattributes` decides what reaches a player and **no CI checks it**. (C10)
- `README.md:14`'s trailing whitespace is deliberate — a Markdown hard break
  `gen_cdb_json.sh` folds into the ContentDB description. (B21)

## Two rules this phase paid for

- **Run a playtest group that has never been run before writing the next
  feature.** Eight sessions on the editor found four findings; the one session
  that finally left the editor found three, including the worst defect this
  project has recorded against committed code (`B39`).
- **Play the mod outside its own game before a release.** `B38`, `B39` and `C18`
  are all invisible in `codecube`, where a player carries nothing but the two
  drone tools and the sunless sky is the game's design.

---

2026-08-27 · codeblock `b8b30e3` (master), pushed · CI green, run 25, all three
jobs. Local gates green at `b5d2e40`, engine 5.17.0, reported by the author and
read from output rather than exit codes: luacheck silent, `doc/api.md` and
`locale/template.txt` up to date, nine in-engine specs **374 passed, 0 failed, 1
xfail, 0 xpass**, six standalone specs green under plain Lua 5.1.
