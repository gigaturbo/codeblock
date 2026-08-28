# Audit — CodeBlock

Findings only: what was wrong, what it cost, how it was fixed, and the reasoning
a future change would otherwise re-break. **No roadmap and no features here** —
the order of work, the phases and the `F` series live in `ROADMAP.md`, which is
also where a decision agreed in conversation is recorded. The manual checks are
in `PLAYTEST.md`. What shipped, for a player, is in `CHANGELOG.md`.

Ids are **never renumbered**, because commit messages cite them: `B` bugs, `S`
sandbox and security, `C` compliance and packaging, `A` architecture and
performance. They were allocated once across this audit and the `codecube` game's,
so a number never means two things and **a gap here is a finding that lives in the
game's audit**, not one dropped: `C2`–`C5`, `C15`, `A7`, `A8`, `A13`, `A14`, `B19`,
`B20`, `B24`. `C9` was never used in either. `F` ids are this project's own and
are in `ROADMAP.md`.

States: **resolved**, **open**, **won't fix** (the defect is real, the decision is
not to fix it), **withdrawn** (no longer applies — none is). Severities: critical,
high, medium, low.

Compression rule: a closed finding whose reasoning is spent is one line. A closed
finding whose reasoning is load-bearing keeps a **Keep** paragraph, because
someone could otherwise undo it by accident. Nothing has ever been renumbered and
nothing dropped.

## Where it stands

72 findings, this project's own. **71 resolved, none open, 1 won't fix
(`B34`).** That is the first time this file has had nothing open. Everything
through `326f739` is pushed and **CI is green at `0385099`, run 27, all three
jobs**; the five fixes after it — `B41`, `C18`, `S7`, `B44`, `B43` — are
**in the working tree with the four local gates green, uncommitted**.

| Category | Count | Open |
|---|---|---|
| B bugs | 41 | — (B34 won't fix) |
| S sandbox and security | 7 | — |
| C compliance and packaging | 12 | — |
| A architecture and performance | 12 | — |

**Every defect the playtests found this phase is fixed, and all but two are
confirmed in a world.** The run of 2026-08-27 at `246bb37` took the drone,
filesystem, pacing and per-feature groups and found three things no reading had:
an unbounded file read (`B40`, high), a shape wider than the footprint ceiling
raising instead of throttling (`B42`, medium), and a cancelled file chooser
leaving an unusable drone (`B41`, low). All three are fixed and all three are
confirmed — `F-4`, `F-3` case 1, `P3` and `D5`. That range also confirmed `B29`,
`B38`, `B39`, `C17` and, a phase late, `B7`.

**The re-runs and the world group then opened three more, and all three are now
fixed but unproven in a world**: `B43` from timing `P3`, `B44` from re-running
`D5`, and `S7` from `F-3` case 2. `D6` and `F-3` case 2 are the checks that close
them, and `P3` wants re-timing against `B43`'s fix.

**The world group was played on 2026-08-28 and it settled two long-standing
questions rather than finding defects.** `W2` passed, which **answers `A4`** —
mapgen does not overwrite a node written into ground it had not generated, the
oldest thing on the *not verified anywhere* list and open since Phase 4. `W1`
passed at current code, so `S5`'s 16.3 kB measurement no longer rests on a run
predating two rewrites. `W3` passed, `cube(200,200,200)` in 0.34 s, and its
arithmetic is written up under `S5`: the program's own time is the smallest part
of what a large shape costs, and the map write and client push are charged to
nobody.

**Three of the six findings this phase's playtests opened came from a session
going one step past the written procedure.** `B41` was reported while checking
something else; `B44` came out of re-running `B41`'s own check and then removing
the file the drone held; and `S7` came out of a check that **passed on behaviour
and failed on its message**. A pass/fail line would have buried the last of
those.

36 of 38 `PLAYTEST.md` checks carry a result — 32 pass, 3 partial, 1 fail. The
fail is `D6` and one partial is `F-3` case 2; **both now describe fixed code and
are waiting on a re-run rather than on a change.** The other partials are `E2`
(permanent, `B34`) and `D2` case 2. **Only `R1` and `R2` have never been run at
all**, and both belong to the release check.

---

## Open

**Nothing is open.** `B34` below is the one won't-fix.

### B34 · low · won't fix — a file cannot be removed without opening it first

`lib/formspecs.lua`, the `meta.active ~= 0` block. All four file buttons — *Save*,
*Load and close*, *Remove file*, *Close file* — are built inside it, so with no
file open the editor offers no way to act on a file. Three of the four belong
there; *Remove file* does not, since it could act on the selection.

**The author's decision, in their words: "won't fix now, not really needed".**
There is a working route (open it, then remove it), so nothing is unreachable for
a player.

Its second effect is permanent and is why it was filed: **`B14`'s cold-cache
removal path can never be reached from the editor**, because opening a file
populates the per-player cache, so every removal the UI can perform is a warm one.
Playtest `E2` stays partial for good. The only route left to `B14` is removing a
file immediately after a rejoin, since `remove_user_data` on disconnect is the
trigger that finding was about.

Kept so it is not re-derived: a fix would move *Remove file* out of the block,
alongside the help-panel switches already outside it for the same reason, and act
on the file-list selection rather than `meta.tabs[meta.active]` — which makes
"remove a file open in a tab" and "remove one that is not" two cases. Whether a
delete should confirm is a separate question.

---

## B · Bugs

41 findings, 40 resolved, `B34` won't fix. `B19`, `B20` and `B24` are the
game's.

- **B1 · critical · resolved** — comment stripping deleted the code between two
  block comments. `lib/sandbox.lua`, pre-Phase 2. Fixed in Phase 2 with B2–B4:
  instrumentation runs over a real Lua token stream, so comments are never
  stripped.
- **B2 · critical · resolved** — standard `--[[ ]]` block comments were not
  handled at all; only the `--]]` form matched, so a normal comment body was left
  as bare code. Fixed in Phase 2 by the token stream.
- **B3 · critical · resolved** — a string containing `--` was truncated
  mid-literal. Fixed in Phase 2: strings are tokens.
- **B4 · high · resolved** — `"function"` matched as a substring, injecting a
  statement into unrelated expressions. Fixed in Phase 2: `function` is a keyword,
  not a run of characters.
  **Keep — why the insertion points are what they are.** The four points (after
  `do`, after `repeat`, at the `)` closing a parameter list, before `goto`) were
  chosen so no construct pairing is needed and no nesting is tracked, because
  `while f(function() ... end) do` is legal Lua. The cost is that a plain
  `do ... end` is charged one harmless count — the suite's single `xfail`,
  recorded rather than hidden. Anyone "fixing" that `xfail` by pairing constructs
  is undoing the design.
- **B5 · high · resolved** — two editor checkboxes did nothing, because `0` is
  truthy in Lua. `lib/formspecs.lua`. Fixed in Phase 1: booleans in memory, ints
  only at the persistence boundary. It destroyed work rather than merely being
  ignored — with *save on tab switch* stuck on, unticking the box to discard an
  edit lost the original anyway. Both boxes changed default in `500dd85`: `loe`
  and `sos` are read with `get_string`, so a player who has never set them gets
  both *on*; `soe` uses the same read but keeps its `false` default, being the
  deliberately dead one (its checkbox is still commented out in `get_form`).
  **Keep — the `get_int` trap, in two halves.** `get_int` cannot tell an unset key
  from a stored `0` — both return 0 — so any boolean preference in player meta
  must be read with `get_string`, where an absent key is `""`. That only holds if
  **nothing writes the key before the player has chosen**, which is the half that
  was missed and became `B36`: the read was correct and dead for two commits.
- **B6 · medium · resolved** — `color()` wrapped instead of clamping and returned
  nil just past its maximum, indexing past the palette into `place(nil)`, which
  silently built stone. Fixed in Phase 2: clamps to the end colours.
- **B7 · medium · resolved** — a file-read error printed a file handle instead of
  the filename. `lib/filesystem.lua`. Fixed in Phase 7, `37c416e`, once rather
  than twice because `A9` collapsed the duplicated read path first. No spec
  reaches `read_file`, so this waited on playtest `F-3` — which **passed case 1
  on 2026-08-28**, a phase after the fix and only once `B40`'s size bound stopped
  standing in front of the branch. Confirmed in a running world.
- **B8 · high · resolved** — `/codegenerate` had no privilege check and overwrote
  the caller's files. Fixed in Phase 1: your own files need no privilege,
  another player's needs `codeblock`, the parsed name is used and existing files
  are left alone. Argument parsing moved to `utils.parse_target` and is tested,
  including the case the old pattern got wrong (a bare number read as a player
  name, because `%w` matches digits).
- **B9 · medium · resolved** — `/codelevel` was unreachable in singleplayer, which
  it explicitly special-cased. Fixed in Phase 1: the privilege is granted in
  singleplayer, where the player is the administrator, and the dead branch is gone.
  **Keep — the near-miss `F5` can repeat.** An intermediate version removed privs
  altogether so players could set their own level. That is a privilege escalation,
  because codelevel is the bound on resource use; reverted before it shipped. The
  bug was that the privilege was unobtainable, not that it existed.
- **B10 · medium · resolved** — `add_entity`'s result was used without a nil
  check. `lib/drone.lua`. Fixed in Phase 7, `742a1ca`: `Drone.new` returns nil and
  "Cannot place the drone there, move closer", creating no record — without an
  entity nothing would ever step the program, so a record with no object is a
  drone that silently never runs. The owner's name now travels as `add_entity`
  staticdata instead of being written in from outside. Committed, not verified: it
  needs a player pointing at a node the server has unloaded (playtest `D2`
  case 2). `B38` is why it stayed unreachable so long.
  **Two attempts have now failed to arrange it** — `246bb37` and `326f739`, the
  second with the written recipe: *"hard to produce case 2, looks not unloaded"*.
  The suspect is the recipe, not the tester.
  `server_unload_unused_data_timeout` bounds when the engine *may* drop an idle
  mapblock, not when it does, and anything keeping the block active holds it. A
  third attempt wants a way to **observe** that the server has let go, rather than
  waiting out a timeout and hoping; until there is one, this stays the only route
  to the refusal and the refusal stays unseen.
- **B11 · medium · resolved** — `on_deactivate` dereferenced `_data` without the
  guard `on_step` had. Fixed in Phase 7, `742a1ca`, by removing the cache rather
  than adding the guard: the entity holds a name, so a name that names no drone
  reads nil. The 5.9 removal flag is accepted and discarded; what makes that safe
  is the serial, not the ordering (`B29`).
- **B12 · medium · resolved** — a runtime error reported twice and left the
  coroutine attached. Fixed in Phase 4 with `A5`: the error path removes the
  drone. One failure, one message — the invariant `F4`'s cancel button must not
  break.
- **B13 · low · resolved** — `save_editor_state` could pass nil to `set_string`.
  Fixed in Phase 7, `37c416e`: defaults to `""`, which is what the reader already
  compared against. Same function as `B33`.
- **B14 · medium · resolved, unprovable from the editor** — `write_file` and
  `remove_file` indexed the per-player cache without populating it. Fixed in
  Phase 7, `37c416e`: both go through `get_user_data`, which creates the entry.
  The trigger was reconnecting — `remove_user_data` on disconnect emptied the
  cache, so the first save after a rejoin crashed, which reads as random rather
  than as a missing initialisation. The warm path passes (`E2`); the cold path is
  permanently out of reach from the editor while `B34` stands, and the one
  remaining route is a removal immediately after a rejoin.
- **B15 · low · resolved** — example loading had no error handling and leaked
  handles. Fixed in Phase 7, `37c416e`: an unreadable example is skipped with a
  warning instead of taking the mod down at load, the handle is closed, and the
  `.lua` strip is anchored to the end of the name. `F2`'s copy naming honoured
  that — both of its strips are end-anchored too.
- **B16 · medium · resolved, then reopened as B39** — every join wiped the
  player's entire inventory. Fixed in Phase 7, `37c416e`, by gating the clear on a
  tool being missing — which left the wipe in the one case with something to lose.
  See `B39`. Case 1 of playtest `D4` (an ordinary join into a world that already
  has the mod) is the half this finding now covers.
- **B17 · low · resolved** — a number was passed to `set_string`.
  `lib/register.lua`. Fixed in Phase 7, `37c416e`: initialised to `""`, matching
  what the reader tests and what `B13` writes.
- **B18 · low · resolved** — a dead branch left cylinder coordinates nil. Fixed in
  Phase 7, `834f69f`, by deleting the arm rather than filling it in: orientation
  is normalised to V or H once, so there are two arms and no third.
- **B21 · low · resolved** — 61 trailing-whitespace sites across 16 files, now one
  kept deliberately. Fixed in Phase 7, `834f69f`. The filed count (8 across 8
  files, including `TODO.md`) was wrong: there were seven and `TODO.md` had none.
  **Keep — the one site that must survive a formatter pass.** `README.md:14`'s
  trailing spaces are a Markdown hard break separating the licence line from the
  Credits line, and that block is what `scripts/gen_cdb_json.sh` folds into
  `long_description` for the ContentDB listing. Stripping them silently joins two
  lines on the package page.
  **Method note, because it bit twice.** In Git Bash `grep '[ \t]$'` does not mean
  tab — the bracket expression is literal, so it also matches every line ending in
  `t`. Use `grep -E '[[:blank:]]$'`, and normalise CRLF first or the CRLF files
  are missed entirely.
- **B22 · medium · resolved** — `gen_cdb_json.sh` produced different output on
  Windows and Linux. Fixed by normalising CRLF before escaping; git does not save
  you, because inside one long JSON line a CR is not a line ending. **Residue:**
  it escapes neither `"` nor a backslash, so a README containing either produces
  invalid JSON, and nothing verifies this script.
- **B23 · medium · resolved** — `round()` took its arguments in the opposite order
  to its own documentation. Fixed in Phase 3 with the generator. Calling it the
  documented way had not errored: `round(3.14159, 2)` took `10^3.14159` as its
  multiplier and returned about 2 — plausible and silently wrong. Found while
  writing the API descriptors, which is the argument for doing that work.
- **B25 · high · resolved** — `use_call` yielded without dropping the mapblock
  memo, so a lost write could return. Fixed in Phase 6 by construction, not by a
  second reset.
  **Keep — the invariant every new yield site depends on.** There is exactly one
  `coroutine.yield()` in `lib/cost.lua`, inside `release(drone)`, and it clears
  `drone.bx/by/bz` first. The memo in `place_block` is **per-resume, not
  per-run**: the engine may unload a block while the drone is not running, so a
  memo that outlives a yield can skip a `load_area` that has become necessary
  again, and the failure is `A4`'s silent lost write — a hole in the build, no
  error. Everything that yields (`use_call`, `end_command`'s pace,
  `yield_if_spent`, `use_map`'s wait, `F3`'s sleep) goes through `release`, and a
  new yield site must too. Pinned by `integration_spec`. The original defect was
  `use_call` calling `coroutine.yield()` directly; a long computation between two
  `place()` calls was enough to trigger it.
- **B26 · low · resolved** — a program's reported duration was the server's CPU
  time, not the program's. Fixed in Phase 6: both readings are
  `core.get_us_time()`. On POSIX `os.clock` is process CPU time, so on a real
  Linux server the one number a player got counted everything else the server did
  meanwhile. The completion line is now
  `commands:N nodes:N duration:X.XXs`; the charged-CPU figure dropped from it
  belongs in `F4` as a share of the budget.
- **B27 · critical · resolved** — the rotation table is keyed by exact integers
  and was indexed with a float, so one ordinary `turn(n)` could make the next move
  crash. `lib/commands.lua` `turn_by`, `lib/drone.lua` `Drone.angle`. A regression
  from `A3`'s movement rewrite, fixed at both ends in Phase 7, `7d9ca47`.
  **Keep — the arithmetic, because widening the table is not a fix.** Accumulating
  `dir = (dir + quarters * (pi/2)) % (2*pi)` and reading it back as
  `(2/pi) * (dir % (2*pi))` is two inexact float operations per turn. Confirmed
  under lua5.1: `turn(1000)` produced `6.2831853071795649`, a hair under `2*pi`,
  so the `%` did not wrap and the angle came out ≈4 — outside 0..3 entirely, not
  off by an ulp. So the key must be rounded or the direction normalised where it
  is stored: `turn_by` counts in whole quarters and multiplies back once (`% 4` on
  an integer always wraps) and `Drone.angle` returns
  `floor(self.dir / tmp3 + .5) % 4`. Keeping `dir` exactly on a multiple of
  `pi/2` is also what the entity's rotation and the `dir % (pi/2) == 0` test in
  `Drone.new` assume.
  **Hazard worth remembering:** the stub drone in `integration_spec` carried its
  own copy of the old `angle()` formula, so the spec would have masked this
  indefinitely. A test that reimplements what it tests cannot fail.
- **B28 · medium · resolved** — `check_inside_world`'s error level was one short
  on the movement path, losing the player's line. A regression from `A3`: routing
  seven commands through a shared `move_by` added a frame, so level 4 landed on
  the sandbox closure, which carries no player source. Fixed in Phase 7,
  `7d9ca47`, a level per caller. Verified by a lua5.1 frame-shape probe; no spec
  drives a program into the world edge.
  **Keep — the rule, and the reasoning that got it wrong once.** Error levels in
  `lib/commands.lua`: **3 from a command, 4 from a helper one frame below, 5
  through `move_by`.** No single level works — `place_relative` and
  `goto_checkpoint` call the check directly and are correct at 4. The mistaken
  reasoning, asserted in the file header for a whole phase, was that a tail call
  does not collapse the frame for error-level counting (true) and that calling
  `move_by` directly therefore preserved the old depth (false).
- **B29 · high · resolved** — placing a second drone destroyed it immediately,
  because `on_lost` fired after the replacement was installed. Fixed in Phase 7,
  `7d9ca47`, then properly in `191b533`. Filed as a disagreement between two
  reviews of the Phase 7 range and resolved as a verdict: the second review was
  right.
  **Keep — the serial guard, and what does not protect.**
  `ObjectRef:remove()` takes effect at the end of the step ("the object is removed
  after returning from Lua", `lua_api.md` 5.17), so the old entity's
  `on_deactivate` can fire *after* `Drone.set` has installed a replacement under
  the same name. The clear-record-before-`obj:remove()` ordering in `Drone.remove`
  therefore protects nothing, whatever a comment beside it once claimed.
  What protects is the **serial**: `Drone.new` builds staticdata as
  `<serial> <name>`, split on the first space because a player name cannot contain
  one; `drone_entity.lua` parses it in `on_activate` into `self.serial` and
  `self.owner`; and both `Drone.on_lost` and `Drone.on_step` return early on any
  record whose serial does not match. Strings on both sides — `drone.serial` is
  stored as `tostring(serial)` to match what the pattern yields. **Do not compare
  `ObjectRef`s instead**, which is what the first fix did: the pinned 5.17.0
  `lua_api.md` says nothing about `ObjectRef` identity.
  `on_step` had the identical hole and it is the more damaging half — a deferred
  entity can still be stepped once and would spend its replacement's budget,
  silently mis-charging a running program rather than visibly killing an idle
  drone. **Both guards are needed; neither may be removed on the strength of the
  ordering.** Three record-level assertions in `integration_spec` pin it, the
  third wrapped in `pcall` because without the guard it walks into the
  replacement's budget and raises. Anything new that reads a drone by name from a
  callback — `F4`'s panel — is subject to this. **Confirmed in a running world at
  `246bb37`**, playtest `D3` part 2: a drone removed with the setter mid-run and
  replaced in the same second announced its statistics once and the replacement
  survived and ran. That was the last thing this finding rested on reading alone.
- **B30 · low · resolved** — `on_lost` reported the end of a program that was
  never running. A regression from `A11`: making `Drone.finish` the single
  announcement point did not add a test for whether there was an outcome, so an
  idle drone whose mapblock unloaded produced "program stopped" and "Program 'nil'
  completed". Fixed in Phase 7, `7d9ca47`: `on_lost` tests `drone.cor` and, with
  no coroutine, removes the record and says nothing.
- **B31 · high · resolved** — `scripts/run_tests.ps1` wrote a UTF-8 BOM into the
  user's real `minetest.conf`, silently killing its first setting (observed live:
  `menu_last_game` was dead in the author's config). Pre-existing, not a Phase 7
  regression. Fixed in Phase 7, `7d9ca47`: both writes go through `[IO.File]` with
  an explicit `UTF8Encoding $false`, and the read side is
  `[IO.File]::ReadAllText`, which strips a mark already present — so the `finally`
  rewrite repairs rather than preserves. **The trap if either write is touched:**
  in Windows PowerShell 5.1 `-Encoding utf8` means UTF-8 *with* a BOM, and
  Luanti's parser trims whitespace but not a BOM.
- **B32 · medium · resolved** — the same script appended the enable line with no
  separator, so on some configs the suite silently never ran, permanently: a glued
  `some_setting = xcodeblock_run_tests = true` line is inert and can never match
  the `finally` filter again. Fixed in Phase 7, `7d9ca47`: `Add-Content` is gone,
  the file is read whole and written with a separator supplied when the existing
  content does not end in one.
- **B33 · medium · resolved** — the editor saved its open-tab state on one exit
  path and lost it on three, including the ordinary *Load and close* button.
  Widened from low on evidence (playtest `E5`). Fixed by `500dd85`, CI green, at
  three sites: (1) the `fields.load` branch calls `save_editor_state()` before
  `exit()`; (2) `lib/forms.lua`'s `register_on_leaveplayer` no longer drops the
  session without telling the handler — a local `close_session(player)` forgets
  the session and then hands the handler the engine's own `{quit = 'true'}`, so a
  form closing has **one path however it was reached**; (3) a new
  `register_on_shutdown` reaches every session still open through the same
  function, copying the session names before iterating because a handler is free
  to open a form and adding a key during `pairs` is undefined. A fourth path was
  broken the whole time and had no check — closing with ESC, behind a scrollbar
  branch: that is `B37`.
  **Keep — three things the fix rests on.**
  *Player meta written from an `on_shutdown` callback is still saved.* It follows
  from the engine writing players out after mod shutdown callbacks, and it was an
  assumption until playtest `E9` passed at `dee0bc7` on engine 5.17.0 — now
  observed. If it ever fails, check whether the handler ran and the write was
  discarded before concluding the callback never fired.
  *A load-order constraint, commented on `register_on_leaveplayer` in
  `lib/register.lua`.* Leave callbacks run in load order; `forms.lua` is dofiled
  before `register.lua` in `init.lua` and must stay that way, because the editor's
  quit path reads the player's file list and `register.lua`'s own leave callback
  drops it via `remove_user_data`. Reordering the `dofile` list silently breaks
  *Load program on exit* on disconnect — silently, because nothing fails and no
  spec can reach it.
  *`forms.forget` is deliberately unchanged*, and is what the specs use for
  cleanup. Do not fold `close_session` into it: that would fire a quit event
  through a handler on every spec teardown.
  **Keep — why its two checked exits proved less than they looked.** `E8` and `E9`
  both go through `close_session`, which builds `{quit = 'true'}` itself, so
  neither carries a scrollbar field — which is exactly why both passed while ESC,
  where the engine sends the real field table, failed. **When a fix routes several
  exits through one function, a check on the synthetic exits says nothing about
  the engine-driven one.**
- **B35 · high · resolved** — every editor button but *Save* discarded everything
  the player had typed since the last save. `lib/formspecs.lua`, the `on_close`
  branch chain. Player-reported, filed high because it destroyed work on ordinary
  use with no warning — the same class as `B5`, the only other finding here that
  lost work rather than state. Every redraw re-renders the text area from
  `meta.contents[meta.active]`, and only 3 of 11 branches captured
  `fields.content` first, so the five panel buttons, both checkboxes, the block
  picker and `+` all threw the edit away. A second case found by reading: the
  `fields.tabs` branch gated the *in-memory* capture on *Save on tab switch*
  along with the disk write, so with that option off, switching tabs lost the edit
  outright.
  **Keep — the capture must stay before the chain.** Fixed by `500dd85`: one
  guarded read,
  `if fields.content and meta.active ~= 0 then meta.contents[meta.active] = fields.content end`,
  hoisted above the branch chain, the four in-branch copies gone and the
  one-line `update_active_content` helper inlined away; `fields.tabs` now gates
  only `save_active()`. **The guard is what makes it correct, in two ways:**
  `fields.content` is absent from the quit event, which carries no field but
  `quit`, so the read falls through instead of blanking the file; and at that
  point `meta.active` is still the *old* active tab, which is what the tab and
  file-list branches need. Do not move the capture back into a branch.
  **A branch chain where each arm is responsible for remembering a shared step is
  the shape to distrust** — it survived every review of `lib/formspecs.lua` in
  Phase 7, and the same shape recurred immediately as `B37`.
  Verified in world for the panel buttons (`E11`). `E12` — the option-off tab
  switch — has failed three times and is **not reproduced by reading**:
  `write_file` is the only path to disk, `lib/formspecs.lua` calls it from exactly
  three places (`save_active`, `create_file`, `copy_active`) and the tab-switch
  call is gated on `meta.sos`. Two explanations fit and the check now separates
  them: the edit surviving in memory being read as a save, or the editor being
  left by *Load and close* or *Save*, both of which write unconditionally by
  design. **No finding id, deliberately** — nothing in committed code has been
  shown defective — and reading is declared exhausted: what would settle it is the
  file's size or mtime read from outside the game.
- **B36 · medium · resolved** — the new-player initialiser wrote a `0` into the
  editor preference keys, making the ticked default unreachable for every player
  who had ever existed. `lib/register.lua`, `register_on_newplayer`; read in
  `lib/formspecs.lua`. From playtest `E10` failing at `dee0bc7`. Fixed by
  `1f7cd97`, one site: the three keys are no longer written at creation and the
  reader owns the default. `auth_level` and the two `set_string(..., "")` writes
  stay — the auth level is a privileged default that must be set. A comment at the
  call site says why the three are absent, because their absence is the mechanism.
  **Keep — two things.** `B5`'s `get_string` read only works if nothing writes the
  key first; the two halves of that rule live in different files, which is why the
  defect survived the change that introduced it. And **any player who joined
  before `1f7cd97` still carries the stored `0`, correctly honoured**, so
  re-running `E10` needs a genuinely fresh player name or a fresh world.
  Severity medium, not low: it silently falsified a shipped changelog claim and
  made a deliberate fix inoperative, with nothing failing anywhere to say so.
  Confirmed in world at `f274245` (`E10` pass).
- **B37 · high · resolved** — three help-panel scroll branches shadowed four
  others, so closing the editor with ESC never saved the open tabs. Found while
  diagnosing `E12`, reported by nobody. The three scroll branches (`c_scroll`,
  `p_scroll`, `w_scroll`) sat in the middle of `on_close`'s single `elseif` chain,
  above `pick_open`, `pick`, `quit` and `newfile` — and `meta.help` starts at
  `'cubes'`, so that is the panel the editor opens on. Cost, in order: ESC and the
  X never saved the open tabs (a live hole in `B33` on its most ordinary path);
  Enter in *New file* never created a file, while `+` worked; `F1`'s block picker
  survived only because Settings draws no scrollbar. Fixed by `1f7cd97`.
  **Keep — which fields arrive, and the rule that follows.** A **scrollbar is in
  the field table on every submit**, not only when it moved (`parseScrollBar` sets
  `send = true` at parse time; `acceptInput` emits `VAL:n` unconditionally and
  `CHG:n` only for the element that moved). A **checkbox is absent unless it was
  the box clicked** — while `lua_api.md` documents a checkbox's value as
  `"true"`/`"false"` with no caveat and says explicitly that a button is nil when
  not pressed, so the reference reads as though a checkbox always arrives. Neither
  fact is in `lua_api.md` at 5.17.0; `src/gui/guiFormSpecMenu.cpp` is where they
  are visible.
  **The rule: in a single `elseif` chain, every always-sent field must come last,
  or be read before the chain entirely.** `fields.content` (`B35`), the three
  scrollbars and `newfile` are all in that class. `newfile` is keyed on
  `fields.key_enter_field == 'newfile'`, which `EGET_EDITBOX_ENTER` sets and
  nothing else does — with `field_close_on_enter[newfile;false]` the engine calls
  `acceptInput()` without closing, so that test fires on Enter in that field and
  on nothing else. The old "is non-empty" test could claim neither.
  Confirmed in world at `f274245` (`E14`, `E15` pass).
- **B38 · medium · resolved** — aiming the poser at nothing was silently ignored,
  because the engine calls `on_secondary_use` and not `on_place`.
  `lib/register.lua` `codeblock:poser`, `lib/drone.lua` `Drone.on_place`. From
  playtest `D2` failing — the first run of the drone group, against code never
  exercised in a running world since it was written. `on_place` fires only when the
  client has a node under the crosshair; aim into the sky and the poser's
  `on_secondary_use` was `function() end`, so the one gesture a player makes to
  discover a tool's reach answered nothing at all. Its worse second cost: `B10`'s
  refusal was reachable only by pointing at a node the server had unloaded while
  the client still showed it — a message that existed with no way in. Fixed by
  `b5d2e40`, verified by reading the diff: `on_secondary_use` calls the same
  `drone_on_place(name, nil)`, so there is one refusal path and not two, and the
  `if not pos` check moved above the busy check — with no node it is the aim that
  failed, and whether a drone happens to be running is not what the player got
  wrong. `D2` was rewritten into its two cases; **case 1 passed at `246bb37`**, so
  this is confirmed in a running world. Case 2 — `B10`'s refusal — is still
  unreached, and `D2` now carries a recipe for it.
  **Keep — the callback you did not expect.** `B37`'s class of fact in a different
  file, with one difference: `lua_api.md` **does** document this one —
  `on_secondary_use` runs "when the item is used without pointing at a node". So
  the failure was a documented behaviour nobody read, and a stub written to
  satisfy the shape of a table rather than to answer anything. **An empty callback
  is a decision and should carry a comment saying what the empty means.**
  **Keep — where it was invisible, shared with `B39`.** Both were unreachable in
  `codecube`, the game this mod is written for: there a player carries nothing but
  the two drone tools, so there is no inventory to lose and no reason to aim at
  the sky. The mod ships standalone to any game and that is the only place either
  bug exists. **Play the mod outside its own game before a release.**
- **B39 · high · resolved** — the first join after installing the mod wiped the
  player's inventory: the one case `B16`'s narrowing left behind.
  `lib/register.lua` `set_tools`. From playtest `D4` failing. `set_tools` emptied
  `main`, `craft`, `craftpreview` and `craftresult` before adding the two tools;
  `B16` gated that on a tool being missing, which — since both tools are
  undroppable — is exactly and only the first join after the mod is installed.
  **A guard that fires only in the worst case is worse than one that fires always,
  because it also stops anyone noticing.** Fixed by `b5d2e40`, verified by reading
  the diff and confirmed in the current tree at `lib/register.lua:43`.
  **Keep — the shape of this bug, found twice four phases apart.** *Never clear a
  player's inventory. Add what is missing.* There is no case in which this mod
  needs a slot emptied.
  **Keep — both tool-carrying reads must stay.** `main` **or** `craft`: drop the
  second half and a parked tool is duplicated on every single join, silently —
  which is the failure the wipe was hiding all along. A full inventory is reported
  in chat ("No room for the drone tools, free a slot and rejoin", a translatable
  message — see `C17`) rather than passed over, because a player with no drone
  tools and no explanation has no way into the mod at all.
  Severity high: irreversible loss of player data, in a world the player already
  cared about, triggered by the ordinary act of installing the mod. **The most
  damaging defect this project has recorded against committed code.** **`D4` case 2
  passed at `246bb37`** — the tools are added after the player's own items and
  nothing is removed — so this is confirmed fixed in a running world.
- **B40 · high · resolved** — a player's file was read whole, with no bound, and
  then sent to the client. `lib/filesystem.lua` `read_file`. From playtest `F-3`:
  a 168 MB file renamed `test.lua` and dropped in
  `<worldpath>/codeblock_files/<playername>/` took **Luanti to about 14 GB
  resident**, froze the game on exit, and froze it again the next time the editor
  was opened. `read('*a')` was only the first of three multipliers — the content
  was then **cached on the record** for the rest of the session, and the editor
  escaped it into a `textarea` and pushed it down the connection on every redraw.
  The bytecode refusal did not help: `content:byte(1) == 27` is checked *after*
  the read, so the cheap refusal paid for the expensive one first. Fixed
  2026-08-28 by reading `max_file_kb * 1024 + 1` bytes and refusing the file by
  name when it comes back longer, with the same ceiling applied in `write_file`
  so the editor cannot save a file it will then decline to open. The ceiling is
  128 kB by default and settable as `codeblock_max_file_kb`. All nine specs,
  luacheck and both `--check` gates are green over it.
  **Keep — the bound belongs in `read_file`, not in the editor.** Every caller —
  the editor, `Drone.set_file`, the sandbox — is bounded by construction there,
  and a limit in the editor alone would have left the run path open.
  `max_string_mb` is **not** this bound: it is per codelevel and covers strings a
  running program builds through `lib/strguard.lua`, and a file is read long
  before any of that exists.
  **Keep — `read(n)` answers nil at end of file**, not `""`. A file created and
  not yet written is exactly that, and a new program in the editor is exactly
  that, so the read is `or ''`. Confirmed under Lua 5.1 rather than assumed.
  **Keep — what the engine caps and from which version, read from its source.**
  `pkt_read_formspec_fields` in `src/network/serverpackethandler.cpp` sums every
  field name and value in one submission and **drops the whole submission** once
  the total reaches 640 kB — *"640K ought to be enough for anyone"*. That check
  arrives in **5.7.0**; it is absent in 5.6.0, and `mod.conf` declares
  `min_minetest_version = 5.4`, where one field is bounded only by
  `LONG_STRING_MAX_LEN`, 64 MB. So a modified client's route into `write_file` is
  real but bounded, and on an old engine bounded at 64 MB — which is what the
  write ceiling closes. This answers the question the finding was filed with, and
  it is why this stays a `B` and is not also an `S`.
  **Keep — the sandbox reports `read_file`'s own message now.** It discarded the
  second return and said *"@1 not found."* for every refusal, so a file refused
  for its size would have run as missing. `read_file`'s messages are whole
  sentences naming the real reason, which is why they stand in rather than being
  prefixed.
  **`F-4` passed at this code on 2026-08-28**, so this is confirmed fixed in a
  running world: the file that took the server to 14 GB is refused instead of
  read. `F-3` case 1 — a real precompiled chunk — passed the same day, reachable
  for the first time because a 168 MB file no longer gets there first, and that
  run confirmed `B7` as well.
- **B42 · medium · resolved** — a shape wider than the footprint ceiling raised
  instead of throttling, and which way the drone faced decided it.
  `lib/shapes.lua` `build`. From playtest `P3`: `cube(2, 2, 30000)` at codelevel
  1. Slabs were cut along **z** whatever the shape, so `across` — the slab's
  cross-section, the part no slicing reduces — was the shape's whole x-y extent.
  `drone_place_cube` swaps `w` and `l` at angles 1 and 3, so facing east or west
  the shape ran 30000 nodes along x: about 1877 mapblocks against codelevel 1's
  ceiling of 512 (8 MB × 64), `limits.hold` returning nil — the case its own
  comment says a slicing caller never reaches — and `lib/cost.lua` raising
  *"Maximum map footprint exceeded"* on the first slab. Facing north the same
  call completed. **A program that worked and a program that died differed only
  by where the player was looking when they placed the drone.** A sphere or dome
  of radius over about 180 had the same problem at codelevel 1 with no
  orientation to escape by. Medium rather than high because the failure is clean
  — `charge` runs *before* the pass, so nothing is written and no half-built
  shape is left — and the message names the real ceiling; but it is the low
  codelevels that hit it, which is the beginner. Fixed 2026-08-28: slabs follow
  the axis with the largest span, `across` is the other two, and the same call is
  now 16 mapblocks a slab whichever way it faces.
  **Keep — the fillers clip on all three axes now, and that was the actual work.**
  This finding was filed saying every filler already clips itself to the area it
  is handed, so slicing along x or y is correct as it stands. **That was wrong.**
  All three clipped along *z* only and relied on the area always covering the
  full x and y extent; slicing along another axis without changing them would
  have written outside the slab. Do not re-narrow those clips to one axis.
  **Keep — ties go to z on purpose.** z is the outermost loop of every filler, so
  a z slab stays one contiguous run of the data array. The tie-break leaves a
  shape no longer in one axis than another sliced exactly where it was.
  **Keep — what this does not fix.** A shape large in *two* dimensions still asks
  for more than one pass should cost, because only one axis can be sliced away.
  The honest answers there are a message naming the codelevel, or slicing in two
  axes. Neither is done.
  Covered by a spec, which the shape module's slicing had only in the z case:
  `tests/shapes_spec.lua` builds a 400×2×2 cube and asserts the worst slab is 16
  mapblocks, not 26. It was run against the pre-fix module and fails there, so
  the case is known not to be vacuous. **`P3` passed at `febf16f` on 2026-08-28**
  — the call that died facing east completed in 93 s — so this is confirmed in a
  running world, and the same run finally made `S5`'s throttle measurement.
  The facing still changed how long the run took after this fix, which is **not**
  this finding returning — every orientation completes. Timing three of them
  turned that into `B43`: the emerged box is a node larger than the shape, which
  a thin shape pays for in whole mapblocks.
- **B41 · low · resolved** — cancelling the file chooser left a drone that could
  not run. From playtest `D5`. `Drone.on_place` creates the drone and *then*
  returns true so `lib/register.lua` shows the chooser, and the chooser's cancel
  called `close_form` and nothing else — so declining left a drone standing in
  the world with the nametag `[<player>] ?.lua` and answering *"Not a valid
  file"* on every use. Closing with **ESC** landed in the same state, that path
  sending no field any branch claimed. Low: recoverable unaided, because the
  busy check passes with no coroutine attached, so placing again and picking a
  file works. Fixed 2026-08-28 by the first of the two options this finding
  named — undo the placement rather than defer it: `file_chooser.on_close` now
  closes through one local `close`, which removes the drone when it still has no
  file, and every path reaches it — cancel, a choose that named nothing, and a
  new `fields.quit` branch for ESC.
  **Confirmed in a running world: `D5` passed at `326f739` + the uncommitted fix,
  2026-08-28, all three parts** — cancel, ESC, and choosing a file, that last
  being the case that would catch the repair taking away a drone it should keep.
  The **ESC half is observed for the first time**: it was reasoned from the field
  table from the day this was filed, through the fix, until that run. The same
  session opened `B44`, which is this defect's neighbour — a drone whose file is
  removed underneath it rather than never chosen.
  **Keep — why removing is safe, and why `quit` is last in the chain.**
  `show_file_chooser` has exactly one call site and it is reached only when the
  drone has no file, so *no file* means *this chooser placed it* and nothing
  else can be taken away. The other option — do not create the drone until a
  file is picked — is the tidier shape and a larger change, because `Drone.new`
  establishes the position and facing the chooser's answer is applied to. And
  `quit` sits at the end of the `elseif` chain under the rule `B37` set: it is
  sent only on an active close, never alongside a plain `button`, so it cannot
  mask a branch above it.
- **B43 · low · resolved** — the emerged box was one node larger than the shape
  on every axis, and which way the drone faced decided what that cost. Opened by
  *timing* `P3` rather than by anything failing, which is the only finding here
  with that provenance. `bounds.cube` returned `pos2 = o + (w, h, l)` while the
  filler writes `0 .. w-1`, so the last node is `o + w - 1`; `bounds.cylinder`
  did the same along its length. Sphere and dome were already exact.
  `read_from_map` aligns outward to whole mapblocks, so the extra node-layer was
  free where it fell inside a block already being emerged and cost a whole layer
  of blocks where it did not — **on a thin shape a doubling, not a rounding
  error**, since a 2-node extent covering 3 straddles a boundary on 2 positions
  in 16 rather than 1. Measured at three facings: 78 s, 160 s, 183 s for
  `cube(2, 2, 30000)`.
  Fixed 2026-08-28: one subtraction per axis in `bounds.cube`, one along the
  length in `bounds.cylinder`.
  **Keep — the guard the subtraction made necessary.** `cube(0, 0, 0)` is
  reachable, because `drone_place_cube` does `round0(abs(w))` and does not floor
  at 1. With the old bounds that gave `pos2 == pos1`, a degenerate but valid
  one-block box. With the fix it gives `pos2 = pos1 - 1`, an **inverted** box,
  and an inverted box must never reach `read_from_map`. `shapes.build` now
  returns 0 before the loop when any axis is inverted. Do not remove that check
  while the subtraction stands; `tests/shapes_spec.lua` pins it.
  **Keep — the three spec numbers were recomputed, not fitted, and the recompute
  is checkable.** `tests/shapes_spec.lua` encoded the old behaviour in three
  places, and each was derived again from the geometry: *a shape across a
  boundary* is `1 x 2 x 1 = 2` where it was 8 (origin `{14,15,14}`, last node
  `{15,16,15}` — only y crosses); the 48-node cube is `4 x 3 x 4 = 48` where it
  was 64 (`{-24,0,-24}` to `{23,47,23}`, y sitting inside three whole blocks);
  and its per-pass charge is `4 x 3 = 12` where it was 16. Its **slab count stays
  4**, and the 400x2x2 cube from `B42` is untouched at 26 x 1 x 2 either way —
  both were checked rather than assumed. **The fix was then run against the old
  bounds and those four assertions fail with exactly the old numbers**, so none
  of them passes vacuously.
  The two `same(got, box(...))` assertions never moved and could not have caught
  this: the filler always clipped to `w-1`, so the written set was right all
  along. Only the emerged box was too big, which is why nothing but the charge
  saw it.
- **B44 · low · resolved** — removing a file left a drone still naming it, and
  the drone was taken away on the run rather than at the removal. Found by
  re-running `D5` and then doing the obvious next thing. `remove_file` deletes
  the file and refreshes the player's cache and knows nothing about drones, so
  `drone.file` kept the name and `update_entity` was never called — even the
  nametag went on claiming a program that was gone. Running it then failed to
  read the file, `Drone.on_run`'s `get_safe_coroutine` returned false and the
  error path called `Drone.remove`, so the drone disappeared at the moment you
  asked it to build, one gesture after the thing that invalidated it.
  Same class as `B41`: a drone standing in the world naming a file it cannot run.
  Fixed 2026-08-28 in `lib/formspecs.lua`'s `remove_active`, **not** in
  `lib/filesystem.lua`: the drone is removed when its file is the one deleted.
  **Keep — the two answers had to agree, and where the fix belongs.** The choice
  was to clear `drone.file` and leave a drone asking for one, or to take the
  drone with the file. `B41` had just decided that question the second way for a
  cancelled chooser, so this went the same way; a mod that answers *what happens
  to a drone with no usable file* two different ways is worse than either answer.
  And it belongs at the caller: `lib/filesystem.lua` has no drone dependency and
  must not acquire one — modules here take their inputs and know nothing about
  each other.
  The opposite order needed nothing and still does: remove a file, then place a
  new drone, and `Drone.on_place` tests `codeblock:last_file` against the
  player's file list before using it, so a stale last-file opens the chooser.
  **Not provable by the specs** — it is the editor writing to the filesystem and
  a drone in a world. Playtest `D6`.

---

## S · Sandbox and security

7 findings, all resolved. Three carry constraints a future change would
re-break, and `S2`'s residue is one of the things v1.0.0 ships broken.

- **S1 · high · resolved** — player programs got live references to shared module
  and config tables: the real `vector`, `blocks`, `plants`, `wools`, `iwools`, and
  the damage was global until restart (overwriting `vector.new` corrupts every
  player's programs and any other mod using `vector3`). Fixed in Phase 2: each run
  gets snapshots and API names are unassignable. `lib/env.lua`.
  **Keep — three constraints on the environment.** *Copies, not read-only
  proxies*: Lua 5.1 has no `__pairs` and no table `__len`, so a proxy breaks
  `pairs(blocks)` and `#iwools` for player code. *`vector3`'s copy must carry its
  metatable* or `vector(x, y, z)` stops resolving; the metatable stays shared,
  safe only because `getmetatable` is not in the environment. *Read-only names
  need the API in a separate table*, since `__newindex` only fires for keys absent
  from the target. Consequence for any feature adding a name: assigning to a name
  the API defines raises, so a program using it as its own global stops working.
- **S2 · high · resolved** — one builtin call could exhaust server memory,
  invisibly to the call counter. Fixed in Phase 2; the earlier "cannot be fixed"
  call was too pessimistic. The premise was right (the string metatable belongs to
  the type, not the environment, so `("x"):rep(1e9)` is reachable from any
  literal) and the inference wrong (that hiding it was the only option).
  `lib/strguard.lua` replaces `getmetatable('').__index` at load with a copy whose
  amplifying entries are wrapped; the wrappers are inert unless a player program is
  running, a window that opens around `coroutine.resume`, and Luanti runs mods on
  one thread. **Two methods amplify, not three:** `rep` and `gsub`. `format`
  looked like a third, but Lua's format-spec scanner takes at most two digits of
  width and rejects `("%1000000000d")` itself; a guard was written and deleted as
  dead code, and `strguard_spec` keeps that boundary tested.
  **Keep — the residue v1.0.0 ships with.** `heap_mb` cannot stop one huge
  allocation, and a pathological Lua pattern can still burn CPU inside a single
  `find` or `match`. No counter here can see either.
- **S3 · medium · resolved (retired)** — the blacklist rejected legitimate code
  and could not be reasoned about: `check_code` refused any file containing
  `repeat`, `until`, `_G` or `_c_` as substrings, so `repeat_count` and "wait
  until done" were refused. Retired in Phase 2.
  **Keep — where the boundary actually is.** *The security boundary is the
  environment table plus the read-only API surface, not the forbidden-name list.*
  That list is a diagnostics aid only: it turns "attempt to index a nil value"
  into a message naming what the player reached for. It matches identifier tokens
  and skips fields, so `local until_done` and `t.os` are accepted, and it must
  name both `minetest` and `core` (`C6`).
- **S4 · medium · resolved** — the vendored WorldEdit fork still carried its
  arbitrary-code-execution module. `code.lua` was deleted in Phase 2, then the
  whole fork went (`A15`). `integration_spec` asserts
  `rawget(_G, 'worldedit') == nil`. `worldedit` stays in `lib/preprocess.lua`'s
  forbidden list on purpose: a server can load the real WorldEdit alongside, so
  naming it is a diagnostics aid, not a claim the fork is present.
- **S5 · medium · resolved** — `place()` could pin an unbounded number of
  mapblocks in server memory. Filed out of a review of `A4`'s fix: the
  `load_area` call is right, but nothing counted the mapblocks a run made resident
  and no existing limit could see them (`collectgarbage('count')` is the Lua heap;
  a MapBlock is C++ side). Phase 5 shipped the memoised same-mapblock skip, a
  `max_mapblocks` ceiling, a deadline inside a resume and one shared step pool;
  Phase 6 kept the first and last and replaced the middle with `map_memory_mb`.
  **Keep — what a load costs, and the two rules that follow.**
  `core.load_area` is documented as **not** triggering map generation
  (`lua_api.md` 5.17.0), so a load is a resident MapBlock plus a synchronous disk
  read, not mapgen CPU. Measured in a running world: **16.3 kB resident per
  mapblock** over a 400-block sweep, **~1700 loads/s** served. The engine unloads
  blocks nothing touched for `server_unload_unused_data_timeout`, so the real
  exposure is what one drone can touch inside that window, times the drones. **The
  ceiling bounds what is resident, not what was loaded:** over it, `limits.hold`
  returns how long to wait and `use_map` sleeps the drone rather than killing the
  program, because the engine frees idle mapblocks by itself. 128 MB over 29 s is
  ~280 loads/s against the ~1700/s available. The memo is per-resume, not per-run
  — see `B25`.
  **Measured at last, `P3` at `febf16f`, 2026-08-28.** The throttle's live
  behaviour under a program that genuinely exceeds the ceiling was the one claim
  here made from reading alone, and `P3` reached it only after `B42`: a
  `cube(2, 2, 30000)` at codelevel 1 **waited and completed, in 93 s**, against a
  predicted ≈ 80 s — 512 mapblocks of ceiling over the engine's 29 s window is
  17.7 blocks a second, and the shape emerges about 1877 of them with the first
  512 free. Consistent, and the gap is in the direction the estimate is coarse.
  The decay stays an estimate by construction, since the exact figure needs a
  timestamp per block ever touched.
  The sentence above, *"over it, `limits.hold` returns how long to wait and
  `use_map` sleeps the drone rather than killing the program"*, holds only while
  every request is smaller than the whole ceiling. `B42`'s fix makes
  `lib/shapes.lua` keep to that for a shape long in one dimension; one large in
  two dimensions still exceeds it.
  The live measurement is
  playtest `W1`, attributed to `43e95a8` with the engine version never written
  down. **`W1` was re-run at `326f739` on 2026-08-28 and passed**, so the
  measurement no longer rests on a run predating the Phase 6 and Phase 7
  rewrites of `lib/cost.lua`.
  **Keep — what no limit stands for, from `W3`.** `cube(200, 200, 200)` took
  0.34 s of program time at `326f739`, and that is the *smallest* part of what it
  cost. The budget charges nodes, runtime and footprint; **serialising the ~2200
  mapblocks into the map database and pushing them to every client in range are
  charged to nobody**, and both land after the run has already reported
  `completed`. Neither has been measured. It is not a defect and is not filed as
  one — every mod writing to the map has it, and `map_memory_mb` is the nearest
  proxy the model has — but a limit added later should not be sold as bounding
  what a shape costs the server, because that is not what any of them bound.
  Also from `W3`, and worth having in one place: at 13 mapblocks per axis the
  cross-section is ~169 and `floor(SLICE_BLOCKS / across)` is 0, clamped to 1, so
  **every slab of a large cube is one mapblock thick and 169 across**. That is
  the "large in two dimensions" case above, seen from the other side — it did not
  throttle only because ~2200 blocks is well under level 3's 4096.
- **S6 · medium · resolved** — every player got the widest limits by default.
  Fixed in Phase 5: resolved once from `core.is_singleplayer()` — 4 in
  singleplayer, 2 on a server, overridable by `codeblock_default_auth_level`, and
  validated against `auth_levels` rather than trusted, so a level that does not
  exist gives nil limits rather than wide ones. The write is in
  `register_on_newplayer`, not `register_on_joinplayer`, so **upgrading a live
  server demotes nobody — and equally tightens nobody**; existing players stay at
  4 until `/codelevel`. That second half is the one that surprises.
- **S7 · low · resolved** — a failed file open told the player the server's
  absolute path, in English whatever language the game was in. From playtest
  `F-3` case 2, which **passed on behaviour and failed on its message**.
  `lib/filesystem.lua`, `read_file`: `if not handle then return nil, err ... end`
  handed back `io.open`'s own string — `<absolute path>: Permission denied` —
  where every other refusal in the same function names the bare filename. Two
  defects on one line: the server's install layout disclosed to any player, and
  a message that could never be translated, the C runtime's errno string not
  being a translation key and so invisible to `gen_locale.lua --check` for the
  same reason a concatenated one is. The `unreadable` message built four lines
  above was unreachable: `err` is nil only if `io.open` fails without a reason.
  Reachable ordinarily, not only by contriving it — a file removed between the
  list being built and the file being opened gives the same thing.
  Fixed 2026-08-28: the player gets `unreadable`, and `err` goes to the log at
  `warning` with the filename beside it, which is where an operator can already
  see it and where the path is not a disclosure.
  **Keep — the class, not the line.** This is `C17`'s lesson one level down: a
  string that reaches a player and is not a translation key cannot be translated
  and **nothing reports it**, because the checker only sees literals. An error
  value handed straight through from an engine or C call is exactly that, and it
  is the shape to watch for — `gen_locale.lua --check` cannot find the next one
  either.
  Also worth keeping, from writing the comment: **the locale checker reads
  comments too.** An explanatory comment containing the literal call syntax made
  it report a non-literal key, in the source it was documenting. Prose about
  translation has to avoid spelling the call out.
  **Not provable by the specs** — no spec reaches `read_file`. Playtest `F-3`
  case 2, which stays partial until re-run.

---

## C · Compliance and packaging

12 findings, all resolved. `C2`–`C5` and `C15` are the game's;
`C9` was never used.

- **C1 · high · resolved, with residue elsewhere** — the version ceiling hid the
  package from every modern user. Fixed in Phase 1: `max_minetest_version`
  removed from both files and the floor raised 5.3 → 5.4, which was simply a false
  claim (the file chooser declares `formspec_version[4]`). The engine does not
  enforce these keys, but **ContentDB filters on them**, so a working package read
  as incompatible and was hidden. The keys are still spelled
  `min_`/`max_minetest_version`; the rename to Luanti did not reach them.
  **Residue, not fixable from here:** `tests/game/mods/vector3/mod.conf` carries a
  5.5 ceiling — a separate repository and a separate ContentDB package.
- **C6 · low · resolved** — `minetest.*` → `core.*`, style rather than breakage.
  Fixed in Phase 7 (`a00f87e` for 21 sites, `78b9934` and `7d9ca47` for the rest);
  verified by grep at `191b533`. Finished because it became cheap, not because it
  became necessary: `lua_api.md` says `minetest` "will keep existing as an alias"
  — no warning, no removal date.
  **Keep — what still says `minetest` and must.** The filename `minetest.conf`;
  `lib/preprocess.lua`'s forbidden-identifier list, which has to forbid **both**
  aliases or the sandbox's messages stop naming what the player typed, plus its
  `preprocess_spec` case; and the `vector3` submodule, whose four references were
  correctly left alone — converting them from here would move a submodule pointer.
- **C7 · medium · resolved** — no `settingtypes.txt`: every limit was source-only.
  Fixed in Phase 5, **in the mod rather than the game root, deliberately**: every
  setting is codeblock's, `lib/config.lua` reads them, and codeblock ships as its
  own ContentDB package, so in the mod it works for a standalone install and
  appears under Mods. Seven per-codelevel limits after Phase 6, each four
  comma-separated numbers, plus `default_auth_level` and `server_step_budget_us`.
  A malformed value warns and falls back rather than half-applying; a negative
  value is rejected and zero is allowed, because `pace_ms` uses it for "no
  pacing". A `replaced` table warns when a retired name is still set and names its
  successor, because an administrator's `minetest.conf` outlives a rewrite and a
  silently ignored limit reads as being in force.
  **Keep — two constraints in `config.lua` that are easy to undo by accident.**
  The limit tables stay **plain literals**, with the overrides applied in one loop
  afterwards, because `gen_docs.lua` greps this source for a name assigned a table
  whose first element is a number, to check each limit has a row in `doc/api.md` —
  **a computed value turns that check off without failing** (`C14`). And every
  settings read is guarded with `rawget(_G, 'core')`, because `gen_docs.lua`
  dofiles `config.lua` under a bare interpreter with no engine global.
  `config.lua` keeps the units a player and an administrator read — seconds,
  megabytes, milliseconds — and `limits.new` converts them once; nothing else does
  the arithmetic. `integration_spec` asserts every limit is still four numbers
  after the settings layer runs, and that `auth_levels` was left alone. Adding a
  limit means all three: literal, mirror, documented row.
  **`settingtypes.txt` is a hand-kept mirror and nothing checks it** — the engine
  reads no defaults from it, it only draws the menu, and its own header says so.
  It is the third such mirror here and the only one left without a generator; see
  `C17`. Whether it should get a `--check` is an open question in `ROADMAP.md`.
- **C8 · low · resolved** — linting and CI had both been set up, then removed.
  Restored in Phase 0, and it earned its keep immediately: between them lint and
  CI caught the game's `A8` independently, five dead locals, and — via the specs,
  not the linter — a regression that had silently disabled the sandbox's
  call-counter instrumentation.
- **C10 · low · resolved** — a malformed `.gitattributes` line, and a release
  archive nothing had decided the contents of. Fixed by the author before Phase 7:
  the file states what the archive is for rather than accumulating exclusions.
  `screenshot.png` is kept with an explicit `-export-ignore`, because Luanti shows
  it in the main menu's Mods tab; `doc/api.md` stays, because the shipped README
  tells the player to read it. Archive 1.60 MB → 1.42 MB, the author's
  measurement.
  **Keep — the standing hazard, which outlives the fix.** `.gitattributes` decides
  what reaches a player and **nothing in CI checks it** — not luacheck, not
  `gen_docs.lua --check`. ContentDB builds the release with `git archive`, so a
  file added to the tree ships unless a rule excludes it, and nothing local fails
  when one does. Add to that file when adding anything a player has no use for.
- **C11 · low · resolved** — the changelog shipped two "known limitations" the
  same section contradicted. Fixed by `a023ceb`: both deleted rather than
  reworded, since a reworded limitation would have been an invented one. Released
  entries were not touched — they are a record. It mattered at low severity
  because a known-limitations list is the part of a changelog a reader trusts
  most, being the part that admits something.
- **C12 · low · resolved** — `.luacheckrc` still configured two mods that no
  longer exist, under a comment asserting a correspondence with `mod.conf` that
  did not hold. Fixed by `3e143ea` / `0df328b`, CI green on both, so verified
  rather than merely committed. Deleting the `worldedit` global also restored a
  real check.
- **C13 · low · resolved** — `max_distance` was stored squared while its
  documentation gave it in nodes. Internally consistent, so nothing was ever wrong
  for a player; what made it a defect is that `C7` exposed every table as a
  setting, so an administrator entering a distance would have got its square root
  — a silent 12x tightening at codelevel 1. Phase 6 removed the limit altogether:
  distance from spawn was never the resource (the map footprint is), and it
  confused players, who could see a build they were not allowed to fly to. What
  replaced it is not a limit but a hard edge — `check_inside_world` keeps the
  drone inside `mapgen_limit`, past which a write silently does nothing.
- **C14 · medium · resolved** — `gen_docs.lua`'s "every limit is documented" check
  silently exempted three limits. It matched by name prefix, so `pace_ms`,
  `heap_mb` and `map_memory_mb` — three of seven, including both memory ceilings —
  were invisible to it. **The failure mode is the bad one for a guard: it passes.**
  Fixed in Phase 6: the check matches by table shape — any name in
  `codeblock.config` assigned a table whose first element is a number — which is
  the same rule the override loop in `config.lua` uses, so the two agree by
  construction.
  **Keep.** This check exists because a limit once shipped undocumented. It is why
  `lib/config.lua` must keep plain literals (`C7`) and why adding a limit means
  adding a row to the codelevel table in `doc/api.md`. Committed, not verified
  that it now *catches* an absent row: all seven names were confirmed present by
  hand and `--check` says up to date at every gate pass, but a guard that passes
  has not been shown to fail, and deleting a row to watch it fail is the only
  thing that would show it.
- **C16 · medium · resolved, unproven** — `codeblock_run_tests` aborted mod load
  on a ContentDB install: nine bare `dofile`s under a setting an administrator can
  find, whose failure mode was the whole mod refusing to load. A regression from
  `C10`'s `tests` export-ignore. Fixed in Phase 7, `7d9ca47`: `init.lua` probes
  for `tests/api_spec.lua` with `io.open` before the loop and, absent, logs
  "codeblock_run_tests is set, but this build ships no tests/ directory" and loads
  normally. A probe for one file rather than a directory test, because Lua 5.1 has
  no portable one.
  **Keep — the one thing an install would prove.** Nobody has built an archive,
  installed it and set the flag. What would settle it:
  `git archive HEAD | tar -t | grep tests` returning nothing, then a real install
  with `codeblock_run_tests = true`. Worth doing once in the next release check —
  this is a mod-load failure on a player's machine and the release path is exactly
  where it would be met. Both halves are playtest `R1` and `R2`.
- **C17 · medium · resolved** — `locale/template.txt` had drifted in both
  directions, and three translations had been unhooked by a one-character edit to
  their key. From playtest `F-2` being partial: the behaviour passed, the words
  came out in English with the game in French. Three layers. (1) The reported
  line's key was assembled with `..` from two literals — **the argument to `S()`
  is the translation key**, so a concatenated one is invisible to anything that
  reads the source, and it had never been in the template at all. (2) The template
  had drifted both ways: 12 messages the code sends were absent, 17 it listed no
  longer exist. (3) Three of the 12 were worse than absent — translated once, then
  orphaned by a one-character key edit: a trailing space
  (`Runtime error in @1: `), a plural (`...generating example` against the
  locale's `...examples`) and a capital (`binary bytecode prohibited` against
  `lib/filesystem.lua`'s `Binary...`, the same refusal keyed twice). Each looks
  translated in the `.tr` file and falls back to English in the game; only a diff
  of the two key lists sees it.
  Fixed by `b5d2e40`: template regenerated, the concatenated key made one literal,
  the plural and the capital aligned to the keys `locale/` already carried, the
  French locale completed and its translation of the compilation error corrected
  (it read "An error occured", an English string, as the French of
  `Compilation error in @1: `). **`scripts/gen_locale.lua --check` was added to
  CI's docs job** beside `gen_docs.lua --check`, and that step is green in CI run
  25 at `b8b30e3` — the first run to include it. Verified by comparing the files:
  template and `codeblock.fr.tr` hold **56 keys each, sets identical**, and every
  removed key was grepped against `lib/` and `init.lua` and none is still sent
  (`forward` survives only as an API name, never inside `S()`). **`F-2` passed in
  French at `246bb37`** — "everything in french" — so the client half is now
  observed too.
  **Keep — two rules for a translatable string.** *Never build a key with `..`* —
  a computed key cannot be extracted, cannot be translated, and nothing reports
  it. *Never edit a key in the source alone* — a trailing space, a plural or a
  capital silently orphans an existing translation with no error anywhere.
  `gen_locale.lua --check` now catches both; its `.tr` report is advisory, because
  an untranslated message legitimately falls back to English while a template that
  lies about what needs translating does not.
  **Keep — the three hand-kept mirrors, and the pattern behind them.**
  `doc/api.md` drifted first and got `gen_docs.lua --check`; `locale/template.txt`
  drifted second and now has `gen_locale.lua --check`; **`settingtypes.txt` is the
  one left with neither.** A file that restates the source and is read by a human
  or by ContentDB rather than by the code will drift, silently, and the only fix
  that holds is a `--check` in CI.
  `scripts` is export-ignored, so `gen_locale.lua` ships to nobody; it runs here
  and in CI under a bare Lua 5.1, like `gen_docs.lua`, and lists `lib/` through
  `ls`, so it needs a POSIX shell.
  Severity medium: no behaviour is wrong and nothing is lost, but the mod is
  educational and ships a French locale as a feature, and 12 of its messages could
  not be translated at all while three more looked translated and were not.
- **C18 · medium · resolved** — five sky overrides were forced on every joining
  player. `lib/register.lua`, inside `register_on_joinplayer`, unguarded and
  marked `TODO: TEMP fix`: `override_day_night_ratio(1)` and the sun, moon,
  stars and clouds all hidden. Install the mod into any existing world and every
  player lost the day/night cycle and the sky, with no way to refuse. Nothing the
  mod does needs it — a drone builds the same at midnight — and it contradicts the
  boundary `CLAUDE.md` states: a game contributes its own daylight and the two do
  not mix. `codecube`'s flat, sunless world is the game's design, which is why
  the author saw the intended result and nobody reported it. Same class as `B38`
  and `B39`: code whose effect is invisible in the game it was written for and
  destructive in any other. Fixed 2026-08-28 by the second of the three options
  this finding put to the author — **one setting, defaulting off**:
  `config.flat_sky`, read through a new `flag` helper beside `number` and
  `per_level`, with the five calls behind it and a matching entry under a new
  `[Appearance]` section of `settingtypes.txt`. No migration: the overrides are
  per-player and re-applied on join, so turning it off takes effect on the next
  one.
  **Keep — `codecube` has to ask for it now.** The game adopting a release with
  this in it gets an ordinary sky unless it sets `codeblock_flat_sky = true` in
  its own `minetest.conf`. That is one line in the game and nothing in this
  repository, and it is deliberately not defaulted the other way: a mod that
  ships to any game must not rewrite its sky to suit one of them.
  **Confirmed in a running world: `R3` passed at `326f739` + the uncommitted fix,
  2026-08-28, in both positions** — the game's own sky is left alone with the
  setting absent, and held flat with it set. That is the first time this
  finding's player-visible half has been *seen*: the claim that a joining player
  loses the cycle was inference from the source for the finding's whole life,
  because inside `codecube` the flat sky is the game's own design and looks
  correct. The gap this closes is exactly the one that let the defect live.

---

## A · Architecture and performance

12 findings, all resolved. `A7`, `A8`, `A13` and `A14` are the game's. Note that
closing `A3`, `A6`, `A9` and `A11` in Phase 7 left four regressions behind
(`B27`, `B28`, `B29`, `B30`): **a clean architecture section was not a clean
phase, and a refactor's findings should not be closed without a review of what the
refactor introduced.**

- **A1 · high · resolved** — the entire UI rested on an unmaintained mod that
  monkey-patched the engine namespace (ActiveFormspecs v2.4, last touched February
  2018): it installed ten names into the engine namespace and replaced
  `register_node` and `override_item` globally for every mod loaded after it.
  Fixed in Phase 3 by `lib/forms.lua`, ~180 lines against 420, touching nothing
  outside its own table.
  **Keep — the form contract `F2` and `F4` build on.** One form per player, cleaned
  up on leave, handler `handler(meta, player, fields)` with the same `meta` across
  redraws. Two behaviours are decisions, not leftovers: a programmatic close does
  not run the quit path, and form names carry a counter so an event from a closed
  form cannot be mistaken for a live one. **Deliberately layout-neutral:** the
  editor form declares no `formspec_version` and is read with legacy coordinates,
  so adding one moves every element — a visible change unverifiable from a
  headless server, left as separate work. `forms_spec`'s stale-event and
  wrong-player cases matter most, since these handlers write to a player's files.
- **A2 · medium · resolved** — the player-facing API was defined in three places
  and had already drifted. Fixed in Phase 3 at the cause: `lib/api.lua` is pure
  data and the single description. The interim fix, comparing docs against source
  and failing CI on a mismatch, still assumed two descriptions of one thing and is
  deleted.
  **Keep — the rule every API change obeys.** Changing or adding a player-facing
  name means `lib/api.lua`, the `impls` table in `lib/sandbox.lua`, and
  regenerating `doc/api.md` — and a **change** breaks saved player programs, which
  are data no game can migrate. `api.build` raises if description and
  implementation disagree **in either direction**, so a half-done edit stops the
  mod loading rather than shipping a reference that lies. The descriptors carry no
  closures and no dependency on the mod being loaded, which is what lets a bare
  interpreter render them and `api_spec` check every name without constructing a
  drone. Only the reference is generated; the codelevel table and the command
  prose above the marker are hand-written and preserved byte for byte.
- **A3 · medium · resolved** — `lib/commands.lua` was largely mechanical
  repetition, 971 lines. Fixed in Phase 7, `834f69f`: 608 lines, plus a new
  `lib/cost.lua` (195 lines) holding what a command spends and when it hands the
  server its step back (`use_nodes`, `slabs`, `use_call`, `end_command`,
  `place_block`). All three duplications went: seven movement commands became one
  rotation table plus a shared `move_by`, twelve placement preambles became
  `placement()`, and four `w, l = w, l` no-ops (a real read and a real write, so
  luacheck never flagged them) went with the four-way `ccube` branch. The public
  `codeblock.commands.*` surface is unchanged. **It introduced two regressions,
  which is the honest reading of it: `B27` and `B28`, both in the movement
  rewrite.**
- **A4 · medium · resolved** — `place()` wrote one node at a time, and failed
  silently off-map. Fixed by `f413758` for the half that was a defect:
  `place_block` calls `core.load_area` before `set_node`. **Verified in a live
  world**, the only way this one can be — without the call the node stays
  `ignore`; with it the node lands and is still there on recheck, even where
  terrain was never generated. The per-node cost was fixed where it was large by
  `A15` (one VoxelManip pass per shape, ~20x) and sliced in Phase 6.
  **Answered on 2026-08-28, and the answer is no.** Whether mapgen can later
  overwrite such a node when a player first visits and the area generates was
  left open here from Phase 4 and was the oldest thing on the *not verified
  anywhere* list. **`W2` passed** at `326f739`: the node survives generation.
  So `load_area` plus `set_node` does not merely make the write land, it makes
  the engine treat the block as generated and leave it alone — and this finding
  no longer ships with a question attached.
  **Keep — the batching decision, and why its arithmetic wants redoing.** Batching
  `place()` into `core.bulk_set_node` is decided against for 1.0.0. The prize is
  the engine's own 1.3x on the write half of a short run. The price is a
  pending-writes buffer flushed at **five** sites: at every yield, before
  `get_block`, before each shape command (they VoxelManip the region, so they
  would read around pending nodes and then write over them), and on end, error and
  abort. **Omitting any one of them is a silently wrong build.** The decision is
  contingent, not closed: the gain depends on run length between flushes, run
  length depends on the yield cadence, and Phase 6 changed that cadence — so the
  arithmetic wants redoing before the decision is quoted again.
  Also worth keeping: the cumulative consequence of loading per call became `S5`,
  and note the shape of that correction — `S5`'s first mitigation is the memoised
  same-mapblock skip this entry argued against, but as an exact `floor(x/16)`
  comparison rather than the heuristic that was rejected, and its main value is the
  counter it creates rather than the calls it saves.
- **A5 · high · resolved** — the drone advanced exactly one coroutine resume per
  server step. Throughput had been pinned near 400 commands/s regardless of
  headroom: a step finishing in 200 µs waited out its tick exactly like one taking
  40 ms. Fixed in Phase 4 **and measured, not asserted**: the logic moved out of
  the entity callback into `lib/stepper.lua` specifically so it could be measured,
  and with an injected clock a 300 µs budget does 3 resumes, 1000 µs does 10,
  2000 µs does 20, against exactly 1 before. That shows the mechanism scales with
  the budget, not what a resume costs, which is per-program.
  **Keep — the overshoot that remains, and the budget's composition.** What still
  overshoots the step budget is **one slab** — ~65k nodes, under 10 ms — because a
  shape's VoxelManip pass is the only thing left that cannot be interrupted. The
  budget is the smaller of the codelevel cap and an equal share of one
  server-wide pool, published as `drone.deadline`; a sleeping drone takes no
  share, which is what `F3` and `F4` lean on.
- **A6 · low · resolved** — the entity prototype relied on a two-level metatable
  chain. It had resolved, but by a coincidence of two independent designs that
  nothing in either file mentioned. Fixed in Phase 7, `742a1ca`: the callbacks sit
  directly on the prototype table, and `integration_spec` asserts they are
  present.
- **A9 · medium · resolved** — the filesystem layer duplicated its read path and
  exported six near-identical getters. Fixed in Phase 7, `37c416e`: 157 lines,
  keeping `ud.list`, one sorted list of `{name, path, index, content}` records,
  plus `ud.byname` indexing the same tables; the four parallel tables and both
  naming schemes are gone. `read_file`'s two ~25-line branches collapsed to one
  path, which is what let `B7` be fixed once instead of twice. All six getters
  removed — four were dead, two became a plain lookup at their five call sites.
  **No spec coverage at all**, since the suite runs before a player or a user
  directory exists, so this is verified by reading and by a clean in-engine load.
  The layer `F2` and `B33` both sit on.
- **A10 · low · resolved** — `get_safe_coroutine` overwrote its own parameter.
  Fixed in Phase 2; behaviour unchanged, since the only caller passed
  `drone.file` anyway.
- **A11 · medium · resolved** — `drone.lua` and `drone_entity.lua` did not divide
  by responsibility, and drone state had no owner: a drone existed as an entry in
  `Drone.instances`, as `_data` on the entity and as several keys in player meta,
  each file holding a piece of the other's job. Fixed in Phase 7, `742a1ca`. The
  author had raised the same seam independently.
  **Keep — the split, because every UI feature crosses it.** The two files divide
  **by direction of dependency**, which is what made the record ownable: the
  entity (67 lines) holds a name and a serial from staticdata and routes two
  engine events, owning and caching nothing; `drone.lua` owns the record, the
  lifecycle and `Drone.finish`, the single place an outcome is announced.
  **`drone.lua` does not know forms exist** — `Drone.on_place` *returns* whether a
  file is still needed and `register.lua` shows the chooser, which is what broke
  the drone↔formspecs cycle. `F4` must respect this: drive the live refresh from
  the form side reading `drone.budget`, not by `drone.lua` calling into forms.
  Teardown is shaped around re-entrancy, and whether that ordering protects became
  `B29` — it does not; the serial is what protects. `integration_spec`'s "drone
  seam (A11)" section pins `Drone`'s function surface, the form-layer entry
  points, the prototype callbacks, and that the entity caches no drone.
- **A12 · low · resolved** — no tests, on the one component that most needs them.
  Fixed from Phase 0 onward. Current figures **from a run, not arithmetic**
  (in-engine, engine 5.17.0, `b5d2e40`, reported by the author): api 30,
  preprocess 54 (1 `xfail`), env 21, shapes 27, strguard 29, limits 36, forms 35,
  stepper 35, integration 107 — **374 passed, 0 failed, 1 xfail, 0 xpass**. Six of
  the nine also run standalone under plain Lua 5.1, which is how CI runs them.
  **Keep — what the suite cannot reach, which every feature inherits.** Nothing
  exercises the filesystem, the editor or drone placement: the specs run at mod
  load, before a map, a player or a user directory exists. Note the 14 movement
  assertions were added precisely because that arithmetic *is* reachable, and
  still did not catch `B27` — they test the four exact facings and the defect was
  in keys that are not exact. **Static counting is unsafe here**, which is why the
  figures come from a run: counting `it(` in `shapes_spec` gave 4 against a real
  15, because one `it(` sat inside a helper called per case.
- **A15 · medium · resolved** — only a fifth of the vendored WorldEdit fork was
  reachable: of 2,299 lines, 448 were reachable and 1,851 were not, and the whole
  dependency was four functions. Fixed in Phase 4 with the stronger option — the
  fork is gone rather than trimmed (`f34ccea`, fixed in `a46247c` after failing
  CI, which is one of the places a "latest green" check would have misled).
  `shapes_spec` covers the geometry against a stubbed VoxelManip and runs
  standalone, which matters because these were ported by hand.
  **Keep — three things to know before touching `lib/shapes.lua`.** The data array
  is prefilled with `ignore`, which `set_data` leaves untouched, so only claimed
  voxels change. The scratch buffer is **one module-level table reused across
  shapes** — safe because Luanti runs mods on one thread and nothing in it has to
  survive a yield, only its length does. `c_ignore` is resolved on first use,
  since content ids settle only after every mod has registered.
- **A16 · medium · resolved** — `api_spec` was standalone-capable but not run by
  CI. Fixed by `a023ceb`, green, which also proved its standalone loader works
  outside the engine. It matters more than a coverage number because it pins every
  API name explicitly: the change most likely to break every saved player program
  at once was the one change CI could not see — the docs job does not cover it,
  because `gen_docs.lua --check` checks the description against itself and
  `api.build`'s bidirectional raise only fires in-engine. **Consequence: adding an
  API name is an `api_spec` edit too.**

---

## Evidence: verified, committed, claimed

Never blurred. **Verified** means a run or a reading demonstrates it,
**committed** means the code is there and unproven, **claimed** means only a
document says so.

**Verified by machine.** CI run 27 at `0385099`, all three jobs green, checked
against the GitHub API: luacheck, the six standalone specs under plain Lua 5.1
(`B42`'s new slicing case among them), and `doc/api.md` and
`locale/template.txt` both up to date. It is the first run to cover `B40` and
`B42`. CI never runs the nine in-engine specs.

**Verified locally, the author's report** (engine 5.17.0, read from output rather
than exit codes — `$?` does not survive this machine's WSL layer): nine in-engine
specs 374 passed / 0 failed / 1 xfail / 0 xpass.

**Verified in a running world** (2026-08-27 and 2026-08-28, engine 5.17.0):
`F-4` and `F-3` case 1 on 2026-08-28, confirming `B40` and — a phase late,
because `B40` stood in front of the branch — `B7`; and `P3` at `febf16f` the same
day, confirming `B42` and making `S5`'s throttle measurement; **`D5`, all three
parts, confirming `B41`** and pressing its ESC path for the first time;
**`R3` in both positions, confirming `C18`** and seeing its player-visible half
for the first time; and **the whole world group — `W1`, `W2`, `W3` — at
`326f739`**, which answered `A4`, re-based `S5`'s measurement on current code,
and priced a 200-node cube. Before that:
`E1`–`E7` at
`3293a2c`+F1, `E8`, `E9`, `E13` at `dee0bc7`, `E10`, `E11`, `E14`, `E15`, `D1`,
`D3` part 1, `F-1` at `f274245`, `E12`, `D2` case 1, `D3` part 2, `D4` both cases,
`F-2`, `P1`, `P2`, `P4` and all three per-feature checks at `246bb37`. Between
them they confirm `A9`, `B13`, `B17`, `B33` on
all three of its losing paths, `B5`, `B22`, `A2`, `B35`, `B36`, `B37`,
`B10`/`A11`'s happy path, `F2` and `S5`'s measurements — and, new at `246bb37`,
**`B29`'s serial guard, `B38`, `B39`, `C17`, `F1` and `F3`**.

**Verified by reading a diff or the source:** nothing, for the first time since
this list was written. `B41`'s ESC half was the last entry and `D5` pressed it on
2026-08-28.

**Verified by reading the engine's own source** (2026-08-28, `luanti-org/luanti`
at tags 5.6.0, 5.7.0, 5.8.0, 5.9.0 and 5.17.0): a formspec submission is dropped
whole once its field names and values total 640 kB, and that check exists from
**5.7.0** and not before. `B40`'s reachability question, open when it was filed,
is answered there.

**Gates green, unproven in a world:** `B14`, which cannot be proven from the
editor at all while `B34` stands; `C16`'s install guard, which needs a real
archive (`R1`, `R2`); and the three fixed on 2026-08-28 after the world group —
`S7`, `B44` and `B43` — whose checks are `F-3` case 2, `D6` and a re-timed `P3`.
`B7`, `B41` and `C18` all left this list on 2026-08-28.

**Not verified anywhere:** `B10`'s refusal, twice aimed at through `D2` case 2
and twice missed. **That is the whole list.** `A4`'s mapgen-overwrite question
left it on 2026-08-28 after `W2`, having been on it since Phase 4 and being the
oldest entry it ever had; `C18`'s player-visible half and the footprint throttle
*doing its throttling* left it the same day.

**Computed, not measured:** `W3`'s cost breakdown under `S5` — mapblock counts,
slab geometry, the ~36 MB resident and the ceilings they are compared against are
arithmetic over the source and the one measured constant (16.3 kB a block). Only
the 0.34 s is a measurement. The map write and the client push are neither: they
are named there as uncharged and unmeasured, and should not be quoted as figures.

**Measured, then explained:** the facing-dependent behaviour `P3` turned up was
timed at three angles on 2026-08-28 — 78 s, 160 s, 183 s — and is `B43`. Two of
the three land within one per cent of what a doubled or quadrupled emerge
predicts, so it is the work and not what the client drew. **The 160 s run fits
nothing** and is recorded as not fitting: the spans can only multiply to 1, 2 or
4.

**Observed and unattributed:** at codelevel 1 nothing of the shape appeared until
the drone was stopped, `P3` at `febf16f`, view distance 30. It is not a deferred
write — nothing here touches the map when a drone stops — and at view distance
500 the shape was visible as it built, so this is most likely what the client
drew. No id.

**Reported, then disproved:** `E12`'s symptom, three fails and two traces. Settled
as a pass at `246bb37`: no write was happening, and the surprise was an unmarked
dirty buffer, now `ROADMAP.md`'s `F7`. No finding id was ever allocated, correctly.

**Claimed only:** nothing.

## Corrections kept rather than edited away

- `B42` was filed saying every filler in `lib/shapes.lua` already clipped itself
  to the area it was handed, so slicing along another axis would be correct as it
  stood. All three clipped along **z** only. The fix had to widen them first.
- `A11`'s resolution once said `lib/drone_entity.lua` is 55 lines; it is 67 — the
  figure predated `B29`'s serial parsing.
- `C7`'s resolution once said every settings read is guarded with
  `rawget(_G, 'minetest')`; since `C6` finished it is `rawget(_G, 'core')`.
- `C14`'s keep block once said `gen_docs.lua --check` "has never run on this
  machine — no Lua toolchain here". It runs at every gate pass, under lua5.1 in
  WSL, which is also the toolchain CI uses.
- Seven findings (`C2`, `S2`, `A12`, `B21`, `S4`, `A3`, `B28`, plus `B29` and
  `C6`) were filed with a conclusion later shown wrong or overtaken. Each records
  the correction rather than being amended silently.
- Phases were renumbered once, before this scheme was fixed: the limits rewrite
  became Phase 6, the cleanup Phase 7, the budget display Phase 8. `43e95a8` still
  says "Phase 5" and still means the committed phase.
- The record was split in two on 2026-08-26, eleven findings moving to the game's
  audit with their ids intact.
- An id is for **a defect in committed code**. A wrong check is a defect in this
  record and is fixed there: playtest `D3` (asked for a mid-run replacement
  `on_place` refuses on purpose) and `F-3` (no procedure had been written) got no
  ids, and `E12` has none after three fails.

---

2026-08-28 · describes codeblock `0385099` (master), **pushed**, CI green (run
27, all three jobs) — the first run to cover `B40` and `B42`. Restructured at
`b8b30e3`: this file is new and holds the findings that
were in `.reports/audit.old.html`, which also held the roadmap and the `F` series
— those are now in `ROADMAP.md`. Nothing renumbered, nothing dropped.
