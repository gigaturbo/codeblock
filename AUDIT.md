# Audit — CodeBlock

Findings only: what was wrong, how it was fixed, and the reasoning a future
change would otherwise re-break. Order of work and features are in `ROADMAP.md`;
manual checks in `PLAYTEST.md`; what shipped, for a player, in `CHANGELOG.md`.

Ids are **never renumbered** — commit messages cite them. `B` bugs, `S` sandbox
and security, `C` compliance and packaging, `A` architecture and performance.
They were allocated once across this audit and the `codecube` game's, so **a gap
here is a finding that lives in the game's audit**: `C2`–`C5`, `C15`, `A7`, `A8`,
`A13`, `A14`, `B19`, `B20`, `B24`. `C9` was never used. `F` ids are in
`ROADMAP.md`.

States: resolved, open, won't fix, withdrawn (none). Severities: critical, high,
medium, low.

A **Keep** paragraph marks reasoning someone could undo by accident. Where
`CLAUDE.md` already carries a rule, the entry points at it rather than restating
it.

## Where it stands

**83 findings. 82 resolved, none open, 1 won't fix (`B34`).**

**`B50` and `B52` are fixed in `1b991ae` and now verified in a running world.**
The fix is the one chosen on 2026-09-03 — decouple the drone record from its
entity — and it closed both findings together: every drone is advanced from the
one globalstep `lib/register.lua` already registered, `on_deactivate` sets
`drone.obj = nil` instead of ending the run, and `Drone.on_step` hands a drone
another object, with the same serial, once its mapblock is back in server memory.
`test-agent`'s evidence is in `tests/integration_spec.lua`; the three in-world
checks that were the whole of the rest — `W1` at codelevel 1, `W5` and `W6` —
**all ran on 2026-09-04 at `23f0227` and all passed**, `W1` at every codelevel
and `W5` and `W6` for the first time ever. The engine version was not restated by
the author. So both findings have left *gates green, unproven in a world*, and
that list is back down to two.

**`B51` was the one left, is fixed at `8de3cea` and is confirmed in a world.**
`Drone.on_remove` passes `'stopped'`, and `Drone.finish` gained a branch for it
sending the new key `Program '@1' stopped: @2` with the same two arguments the
`completed` branch uses, so the commands/nodes/duration tail reads as the partial
count it is. The word was the author's choice on 2026-09-04 and the grounds are
in `ROADMAP.md`. `locale/template.txt` and `locale/codeblock.fr.tr` moved with
it, per `C17`. **No spec reaches it** — nothing asserts what `Drone.finish`
sends, so playtest `D7` is the only evidence there will be, and **it ran on
2026-09-04 and passed**: *stopped* with a partial node count, *arrêté* in French,
engine version not restated. **So nothing on this project is now fixed-but-unseen
on this finding's account.** `D7` also lost half its recipe in that run — it
asked for a setter route that stopped existing at `F8`, as `B51`'s own text did;
both are corrected, and the correction is under the entry below.

| Category | Count | Open |
|---|---|---|
| B bugs | 49 | — (`B51` fixed at `8de3cea` and confirmed in a world by `D7`) — and `B34` won't fix, `B47` resolved with a residue, `B48` fixed at `4179877` and confirmed by `E16`, `B49` fixed at `d8c32f7` and confirmed by `W4`, `B50` and `B52` fixed at `1b991ae` and confirmed in a world by `W1`, `W5` and `W6` on 2026-09-04 |
| S sandbox and security | 7 | — |
| C compliance and packaging | 15 | — (`C21` fixed by `F10` at `b23a8bc`, confirmed in a world by `F10-1`) |
| A architecture and performance | 12 | — |

CI was green on all three jobs through `471526e` (runs 44 and 45), so the limit
retuning, `F9` and the paused clock are covered by CI rather than by local gates
alone. **`B47`'s fix, `settingtypes.txt`'s generator and `C20` are `d8d44cd` and
have local gates only**, pending the next run — which also proves the fourth CI
step that commit adds. Everything committed since is the record, the images and
the README, and touches no code. **The three changes that sat in one working tree
at `b9143b0` are now committed, all on 2026-09-03**: `B48`'s one-line fix is
`4179877`, `F10`'s rework of `lib/register.lua` — which resolves `C21` and
renames two chat commands — is `b23a8bc`, and `B49`'s unknown-block warning in
`lib/env.lua` and `lib/sandbox.lua` is `d8c32f7`, with the record following at
`16cd05c`. **CI has still seen none of them**: the last run was `471526e`
(run 45), so everything from `d8d44cd` up carries local gates only.
**The gates are green at `1b991ae` and again over `B51`'s fix, now `8de3cea`, on
2026-09-04**, with the same figures both times — engine 5.17.0, read from output rather
than exit codes: luacheck silent, `doc/api.md`, `locale/template.txt` and
`settingtypes.txt` each *up to date*, `locale/*.tr` covering every message and
nothing else, **nine in-engine specs 474 passed / 0 failed / 1 xfail / 0 xpass**
and six standalone under Lua 5.1. The xfail is `preprocess_spec`'s and
pre-existing. The in-engine count has moved 458 → 471 → 474: 13 `env_spec` cases
for `B49`, then three for `B50`/`B52` in `integration_spec`'s drone-seam block,
which went from six cases to nine. Nothing was added for `B47`, because **no
spec can reach it** — the gates call the handler directly and the defect is in
the client's menu. **CI has seen none of this**: the last run was `471526e`
(run 45), so everything from `d8d44cd` up carries local gates only. The
standalone run is the same command CI runs, so plain Lua 5.1 is covered locally;
a real CI run waits on a push.

**Every defect the playtests found is fixed, and no finding is open.** `W1`'s
re-run at codelevel 1 on 2026-09-03 was `B50`, and diagnosing it produced `B51`
and `B52`; `B50` and `B52` are fixed in `1b991ae` and confirmed in a world on
2026-09-04, and `B51` is fixed at `8de3cea` on 2026-09-04 and confirmed by `D7`
the same day. The one thing **not verified anywhere** is `B10`'s refusal, aimed
at twice through playtest `D2` and missed twice — the recipe is the suspect and
its check was removed as untestable on 2026-09-02.
**Gates green, unproven in a world — two:** `B14`, permanently blocked on
`B34` being won't-fix, and `S7`'s log half. **`B51` was on it for a few hours of
2026-09-04 and left the same day**, `D7` reading *stopped* and *arrêté* in a
world. **`B50` and `B52` left it that day too**, when `W1` at every codelevel,
`W5` and `W6` all passed at `23f0227` — the list had been exactly four since
`1b991ae`, and it is now the smallest it has been.
`C21` left it on 2026-09-03: playtest `F10-1` was completed the same day
and `/privs` on a fresh player shows no `fly`, `fast` or `noclip`, which was that
finding's only possible evidence. **`B48` left it the same day**, `E16`'s new
pristine-example case passing. **And `B49` left it that day too** — `W4` was
written with the fix, ran at `16cd05c` and passed, so the once-per-run chat
warning is observed rather than only green. All three fixes are now committed as
well, so none of the three is outstanding in either sense. **`B47`'s fix left this list the day it
shipped**, `H10` passing with the residue it predicted — a few presses in twenty
still miss, which the author accepted. `F9-1` passed the same day `F9` shipped, including the paused clock
reversed out of that very run, as did `R4` and `F-5`, which takes `S6` and the
retuning's effect on the bundled examples off this list too.

---

## Open and won't fix

**Nothing is open.** `B51` was the last, and it is fixed at `8de3cea` on
2026-09-04 and **observed fixed in a world the same day** — the entry is in
*B · Bugs* below, with the wording decision, the second caller whose behaviour
changed with it, and the constraint the fix was built to.

`B34` is the one **won't fix**: it is in *B · Bugs* below. `B47` is resolved with
a residue that ships, also below, and that residue is under *What ships broken*
in `ROADMAP.md`. **`B50` and `B52` were open until `1b991ae`** and are below with
the diagnosis, the reproducer and the costs the fix accepted; both are
**confirmed in a world** since 2026-09-04.

---

## B · Bugs

49 findings, 48 resolved, `B34` won't fix, none open. `B19`, `B20`, `B24` are
the game's. `B47` is resolved with a residue that ships. **`B50` and `B52` are
resolved and confirmed in a world**, and so is **`B51`, resolved at `8de3cea`
and confirmed by `D7`**; all three keep their full reasoning below, because the
fixes are recent and their costs were accepted knowingly, so what a future
change would re-break is still load-bearing.

- **B1 · critical · resolved** — comment stripping deleted the code between two
  block comments. Fixed in Phase 2 with B2–B4: instrumentation runs over a real
  Lua token stream, so comments are never stripped.
- **B2 · critical · resolved** — standard `--[[ ]]` comments were not handled;
  only `--]]` matched, leaving a normal comment body as bare code. Fixed by the
  token stream.
- **B3 · critical · resolved** — a string containing `--` was truncated
  mid-literal. Fixed: strings are tokens.
- **B4 · high · resolved** — `"function"` matched as a substring, injecting a
  statement into unrelated expressions. Fixed: `function` is a keyword.
  **Keep — the insertion points, and the `xfail`.** The four points (after `do`,
  after `repeat`, at the `)` closing a parameter list, before `goto`) pair no
  constructs and track no nesting, because `while f(function() ... end) do` is
  legal Lua. The cost is that a plain `do ... end` is charged one harmless count
  — the suite's single `xfail`. **Anyone "fixing" that `xfail` by pairing
  constructs is undoing the design.**
- **B5 · high · resolved** — two editor checkboxes did nothing, because `0` is
  truthy in Lua. Fixed in Phase 1: booleans in memory, ints only at the
  persistence boundary. It destroyed work rather than merely being ignored. Both
  boxes changed default in `500dd85`: `loe` and `sos` read with `get_string`, so
  a player who never set them gets both *on*; `soe` keeps `false`, being the
  deliberately dead one.
  **Keep — the second half of the `get_int` trap.** The `get_string` rule is in
  `CLAUDE.md`. What is not: it only holds if **nothing writes the key before the
  player has chosen**. That half was missed and became `B36` — the read was
  correct and dead for two commits.
- **B6 · medium · resolved** — `color()` wrapped instead of clamping and returned
  nil past its maximum, indexing into `place(nil)`, which silently built stone.
  Fixed: clamps to the end colours.
- **B7 · medium · resolved** — a file-read error printed a file handle instead of
  the filename. Fixed in Phase 7, `37c416e`, once rather than twice because `A9`
  collapsed the duplicated read path first. Confirmed by playtest `F-3` case 1, a
  phase later, once `B40`'s size bound stopped standing in front of the branch.
- **B8 · high · resolved** — `/codegenerate` had no privilege check and overwrote
  the caller's files. Fixed in Phase 1: your own files need no privilege,
  another's needs `codeblock`, the parsed name is used, existing files are left
  alone. Parsing moved to `utils.parse_target` and is tested — including a bare
  number read as a player name, because `%w` matches digits.
- **B9 · medium · resolved** — `/codelevel` was unreachable in singleplayer,
  which it special-cased. Fixed in Phase 1: the privilege is granted in
  singleplayer and the dead branch is gone.
  **Keep — a near-miss that can repeat.** An intermediate version removed privs
  altogether so players could set their own level. **That is privilege
  escalation** — codelevel is the bound on resource use. Reverted before it
  shipped. The bug was that the privilege was unobtainable, not that it existed.
- **B10 · medium · resolved** — `add_entity`'s result was used without a nil
  check. Fixed in Phase 7, `742a1ca`: `Drone.new` returns nil and "Cannot place
  the drone there, move closer", creating no record — without an entity nothing
  steps the program, so a record with no object is a drone that silently never
  runs. Committed, **not verified, and now with no route to verifying it**: it
  needs a player pointing at a node the server has unloaded, and playtest `D2`'s
  second case asked exactly that and was **removed as untestable on 2026-09-02**
  after two failed attempts.
  **Keep — why nobody could produce it, so a third attempt is not made blind.**
  `server_unload_unused_data_timeout` bounds when the engine *may* drop an idle
  mapblock, not when it does, and anything keeping the block active holds it. Both
  sessions waited out the timeout and found the block resident. A route wants a
  way to **observe** that the server has let go — a server-side read of what is
  loaded, not a guess from the client's side of the glass. The fix itself is three
  lines and reviewed; what is unproven is the path reaching them.
- **B11 · medium · resolved** — `on_deactivate` dereferenced `_data` without the
  guard `on_step` had. Fixed in `742a1ca` by removing the cache rather than
  adding the guard: the entity holds a name, so a name that names no drone reads
  nil.
- **B12 · medium · resolved** — a runtime error reported twice and left the
  coroutine attached. Fixed in Phase 4 with `A5`: the error path removes the
  drone. One failure, one message.
- **B13 · low · resolved** — `save_editor_state` could pass nil to `set_string`.
  Fixed in `37c416e`: defaults to `""`, which the reader already compared against.
- **B14 · medium · resolved, unprovable from the editor** — `write_file` and
  `remove_file` indexed the per-player cache without populating it. Fixed in
  `37c416e`: both go through `get_user_data`. The trigger was reconnecting —
  `remove_user_data` on disconnect emptied the cache, so the first save after a
  rejoin crashed. The warm path passes (`E2`); **the cold path is permanently out
  of reach from the editor while `B34` stands**, and `E2`'s half asking for it was
  removed as untestable on 2026-09-02 rather than left standing as a partial. The
  one route left is *removing a file immediately after a rejoin* — the reconnect
  being the trigger — which is a check nobody has written.
- **B15 · low · resolved** — example loading had no error handling and leaked
  handles. Fixed in `37c416e`: an unreadable example is skipped with a warning
  instead of taking the mod down at load, and the `.lua` strip is anchored to the
  end of the name.
- **B16 · medium · resolved, then reopened as B39** — every join wiped the
  player's inventory. Fixed in `37c416e` by gating the clear on a tool being
  missing — which left the wipe in the one case with something to lose.
- **B17 · low · resolved** — a number was passed to `set_string`. Fixed in
  `37c416e`: initialised to `""`.
- **B18 · low · resolved** — a dead branch left cylinder coordinates nil. Fixed
  in `834f69f` by deleting the arm: orientation is normalised to V or H once, so
  there are two arms and no third.
- **B21 · low · resolved** — 61 trailing-whitespace sites across 16 files. Fixed
  in `834f69f`.
  **Keep — the one site that must survive a formatter pass.** `README.md:14`'s
  trailing spaces are a Markdown hard break separating the licence line from
  Credits. Stripping them joins two lines on the ContentDB page.
  **Method note, because it bit twice.** In Git Bash `grep '[ \t]$'` does not
  mean tab — the bracket expression is literal, so it also matches every line
  ending in `t`. Use `grep -E '[[:blank:]]$'`, and normalise CRLF first.
- **B22 · medium · resolved** — `gen_cdb_json.sh` produced different output on
  Windows and Linux. Fixed by normalising CRLF before escaping; git does not save
  you, because inside one long JSON line a CR is not a line ending.
  **Residue:** it escapes neither `"` nor a backslash, so a source containing
  either produces invalid JSON, and nothing verifies this script.
- **B23 · medium · resolved** — `round()` took its arguments in the opposite
  order to its own documentation. Calling it the documented way had not errored:
  `round(3.14159, 2)` took `10^3.14159` as its multiplier and returned about 2 —
  plausible and silently wrong. Fixed in Phase 3; found while writing the API
  descriptors, which is the argument for doing that work.
- **B25 · high · resolved** — `use_call` yielded without dropping the mapblock
  memo, so a lost write could return. Fixed in Phase 6 by construction.
  **Keep — the invariant every new yield site depends on.** The per-resume memo
  rule is in `CLAUDE.md`. What is not: **there is exactly one
  `coroutine.yield()` in `lib/cost.lua`**, inside `release(drone)`, and
  everything that yields goes through it — `use_call`, `end_command`'s pace,
  `yield_if_spent`, `use_map`'s wait, `F3`'s sleep. A new yield site must too.
  Pinned by `integration_spec`.
- **B26 · low · resolved** — a program's reported duration was the server's CPU
  time. On POSIX `os.clock` is process CPU time, so on a real Linux server the
  one number a player got counted everything else the server did meanwhile.
  Fixed in Phase 6: both readings are `core.get_us_time()`.
- **B27 · critical · resolved** — the rotation table is keyed by exact integers
  and was indexed with a float, so one ordinary `turn(n)` could make the next
  move crash. A regression from `A3`. Fixed at both ends in `7d9ca47`.
  **Keep — the arithmetic, because widening the table is not a fix.**
  Accumulating `dir = (dir + quarters * (pi/2)) % (2*pi)` and reading it back as
  `(2/pi) * (dir % (2*pi))` is two inexact float operations per turn. Under
  lua5.1, `turn(1000)` produced `6.2831853071795649` — a hair under `2*pi`, so
  the `%` did not wrap and the angle came out ≈4, outside 0..3 entirely. So the
  key must be rounded or the direction normalised where it is stored: `turn_by`
  counts in whole quarters and multiplies back once, `Drone.angle` returns
  `floor(self.dir / tmp3 + .5) % 4`. Keeping `dir` exactly on a multiple of
  `pi/2` is also what the entity rotation and `Drone.new`'s `dir % (pi/2) == 0`
  assume.
  **Hazard:** the stub drone in `integration_spec` carried its own copy of the
  old `angle()` formula, so the spec would have masked this indefinitely. **A
  test that reimplements what it tests cannot fail.**
- **B28 · medium · resolved** — `check_inside_world`'s error level was one short
  on the movement path, losing the player's line. A regression from `A3`: routing
  seven commands through a shared `move_by` added a frame. Fixed in `7d9ca47`.
  **Keep — the rule.** Error levels in `lib/commands.lua`: **3 from a command, 4
  from a helper one frame below, 5 through `move_by`.** No single level works —
  `place_relative` and `goto_checkpoint` call the check directly and are correct
  at 4. The mistaken reasoning, asserted in the file header for a whole phase,
  was that a tail call preserves the old depth. It does not.
- **B29 · high · resolved** — placing a second drone destroyed it immediately,
  because `on_lost` fired after the replacement was installed. Fixed in
  `191b533`.
  **Keep — beyond `CLAUDE.md`'s statement of the serial guard.** Staticdata is
  `<serial> <name>`, split on the first space because a player name cannot
  contain one; `drone.serial` is stored as `tostring(serial)` to match what the
  pattern yields. **Do not compare `ObjectRef`s instead** — which is what the
  first fix did: the pinned 5.17.0 `lua_api.md` says nothing about `ObjectRef`
  identity. Anything reading a drone by name from a callback — `F4`'s panel — is
  subject to this. Confirmed by playtest `D3` part 2.
  **Keep — what the guard protects changed at `1b991ae`, and it still matters.**
  It used to stop a deferred `on_deactivate` tearing down the **record** of the
  drone that replaced it, and to stop a deferred entity `on_step` spending the
  replacement's **budget**. Neither path exists now: `on_lost` removes nothing
  and there is no entity `on_step` at all. What the serial guards today is the
  replacement's **object** — a dying object's deferred `on_deactivate` would
  otherwise blank `drone.obj` on the new drone and leave it **invisible until the
  next re-spawn**, up to `respawn_period_s`. Weaker in consequence, not gone,
  and `B50`'s re-spawn under the same name makes the case it exists for more
  common rather than less. `integration_spec` pins it, and **`W6` case 2 is its
  first in-world evidence in this form** — one drone and not two after a
  re-spawn under the same name, 2026-09-04 at `23f0227`. `D3` part 2's pass
  predates the change and is evidence about the older guard.
  **Keep — the clear-before-remove ordering matters more than its own comment
  claims**, read out of the 5.17.0 source on 2026-09-03 while diagnosing `B50`.
  `markForDeactivation` sets `m_pending_deactivation` **after** the Lua callback
  returns, so **a second `on_deactivate` fires from inside the first**, and it is
  the already-cleared record that absorbs it. `CLAUDE.md` says the ordering is
  *not* what makes the replacement safe — that is the serial guard, and that
  remains true — but the ordering is load-bearing for its own reason. **Do not
  reorder the clear after `obj:remove()` on the strength of the serial guard
  either.**
- **B30 · low · resolved** — `on_lost` reported the end of a program that was
  never running. A regression from `A11`. Fixed in `7d9ca47`: `on_lost` tested
  `drone.cor` and, with no coroutine, removed the record and said nothing.
  **Keep — the behaviour changed at `1b991ae` and the rule did not.** `on_lost`
  no longer announces or removes anything at all, so a parked drone with no
  coroutine is **no longer taken away when its mapblock unloads**: it keeps its
  record and gets its view back on the next re-spawn. That is a deliberate
  consequence of `B50`'s fix, and it is bounded — one drone per player, and
  `register_on_leaveplayer` removes it — so it is not a leak. `W6` cases 3 and 4
  are where a leak would have shown, and both passed on 2026-09-04. **`B30`'s own rule
  is intact:** a program that never started is still never reported as having
  ended. Do not reintroduce a `drone.cor` test in `on_lost` to "clean up" the
  parked case; that is the path `B50` removed.
- **B31 · high · resolved** — `scripts/run_tests.ps1` wrote a UTF-8 BOM into the
  user's real `minetest.conf`, silently killing its first setting. Fixed in
  `7d9ca47`: both writes go through `[IO.File]` with an explicit
  `UTF8Encoding $false`, and the read is `[IO.File]::ReadAllText`, which strips a
  mark already present — so the `finally` rewrite repairs rather than preserves.
  **The trap if either write is touched:** in Windows PowerShell 5.1
  `-Encoding utf8` means UTF-8 *with* a BOM, and Luanti's parser trims whitespace
  but not a BOM.
- **B32 · medium · resolved** — the same script appended the enable line with no
  separator, so on some configs the suite silently never ran, permanently: a
  glued `some_setting = xcodeblock_run_tests = true` line is inert and can never
  match the `finally` filter again. Fixed in `7d9ca47`.
- **B33 · medium · resolved** — the editor saved its open-tab state on one exit
  path and lost it on three, including the ordinary *Load and close* button.
  Fixed by `500dd85` at three sites: `fields.load` calls `save_editor_state()`
  before `exit()`; `lib/forms.lua`'s `register_on_leaveplayer` routes through a
  local `close_session(player)` that forgets the session then hands the handler
  the engine's own `{quit = 'true'}`; and a new `register_on_shutdown` reaches
  every open session through the same function, copying the session names before
  iterating because a handler may open a form and adding a key during `pairs` is
  undefined. A fourth path was broken the whole time with no check — ESC, behind
  a scrollbar branch: `B37`.
  **Keep — three things the fix rests on.** *Player meta written from
  `on_shutdown` is still saved* — an assumption until playtest `E9` passed at
  `dee0bc7` on 5.17.0, now observed. *The load-order constraint* is in
  `CLAUDE.md` and commented on `register_on_leaveplayer`. *`forms.forget` is
  deliberately unchanged* and is what the specs use for cleanup — folding
  `close_session` into it would fire a quit event through a handler on every
  spec teardown.
  **Keep — why its two checked exits proved less than they looked.** `E8` and
  `E9` both go through `close_session`, which builds `{quit = 'true'}` itself, so
  neither carries a scrollbar field — which is exactly why both passed while ESC
  failed. **When a fix routes several exits through one function, a check on the
  synthetic exits says nothing about the engine-driven one.**
- **B35 · high · resolved** — every editor button but *Save* discarded everything
  typed since the last save. Only 3 of 11 branches captured `fields.content`
  before the redraw re-rendered the text area. A second case: the `fields.tabs`
  branch gated the *in-memory* capture on *Save on tab switch* along with the
  disk write.
  **Keep — the capture must stay before the chain.** The rule is in `CLAUDE.md`.
  What is not: **the guard is what makes it correct, in two ways.**
  `fields.content` is absent from the quit event, which carries no field but
  `quit`, so the read falls through instead of blanking the file; and at that
  point `meta.active` is still the *old* active tab, which is what the tab and
  file-list branches need.
  **A branch chain where each arm is responsible for remembering a shared step is
  the shape to distrust** — it survived every review of `lib/formspecs.lua` in
  Phase 7, and recurred immediately as `B37`.
- **B36 · medium · resolved** — the new-player initialiser wrote a `0` into the
  editor preference keys, making the ticked default unreachable for every player
  who had ever existed. Fixed by `1f7cd97`: the three keys are no longer written
  at creation and the reader owns the default. `auth_level` stays — a privileged
  default that must be set.
  **Keep.** `B5`'s `get_string` read only works if nothing writes the key first,
  and the two halves of that rule live in different files, which is why the
  defect survived the change that introduced it. **Any player who joined before
  `1f7cd97` still carries the stored `0`, correctly honoured**, so re-running
  `E10` needs a genuinely fresh player name or world.
- **B37 · high · resolved** — three help-panel scroll branches shadowed four
  others, so closing the editor with ESC never saved the open tabs. `meta.help`
  starts at `'cubes'`, so that is the panel the editor opens on. Cost, in order:
  ESC and the X never saved the tabs; Enter in *New file* never created a file
  while `+` worked; `F1`'s block picker survived only because Settings draws no
  scrollbar. Fixed by `1f7cd97`.
  **Keep — beyond `CLAUDE.md`'s statement of which fields arrive.** The engine
  facts are `parseScrollBar` setting `send = true` at parse time and
  `acceptInput` emitting `VAL:n` unconditionally; **neither is in `lua_api.md` at
  5.17.0** — `src/gui/guiFormSpecMenu.cpp` is where they are visible. `newfile`
  is keyed on `fields.key_enter_field == 'newfile'`, which `EGET_EDITBOX_ENTER`
  sets and nothing else does; with `field_close_on_enter[newfile;false]` the
  engine calls `acceptInput()` without closing. The old "is non-empty" test could
  claim neither.
- **B38 · medium · resolved** — aiming the poser at nothing was silently ignored,
  because the engine calls `on_secondary_use` and not `on_place`. Fixed by
  `b5d2e40`: both route into one `drone_on_place(name, nil)`, and the `if not
  pos` check moved above the busy check. Its worse second cost was that `B10`'s
  refusal became reachable only by pointing at a node the server had unloaded —
  a message with no way in. Confirmed by playtest `D2` case 1.
  **Keep — the callback nobody read.** `lua_api.md` **does** document this one:
  `on_secondary_use` runs "when the item is used without pointing at a node". So
  the failure was documented behaviour and a stub written to satisfy the shape of
  a table. **An empty callback is a decision and should carry a comment saying
  what the empty means.**
- **B39 · high · resolved** — the first join after installing the mod wiped the
  player's inventory: the one case `B16`'s narrowing left behind. Since both
  tools are undroppable, "a tool is missing" is exactly and only that join.
  **A guard that fires only in the worst case is worse than one that fires
  always, because it also stops anyone noticing.** Fixed by `b5d2e40`. Severity
  high: irreversible loss of player data in a world the player cared about,
  triggered by installing the mod. **The most damaging defect this project has
  recorded against committed code.** Confirmed by playtest `D4` case 2.
  **Keep — both rules are in `CLAUDE.md`.** *Never clear an inventory, add what
  is missing*, and *both carrying reads (`main` **or** `craft`) must stay*.
  **Keep — where `B38` and `B39` were invisible.** Both were unreachable in
  `codecube`, where a player carries nothing but the two tools and has no reason
  to aim at the sky. **Play the mod outside its own game before a release.**
- **B40 · high · resolved** — a player's file was read whole, with no bound, then
  sent to the client. A 168 MB file named `test.lua` took **Luanti to about 14 GB
  resident**, froze the game on exit and froze it again on the next editor open.
  `read('*a')` was one of three multipliers: the content was cached on the record
  for the session, and the editor escaped it into a `textarea` on every redraw.
  The bytecode refusal did not help — `content:byte(1) == 27` is checked *after*
  the read. Fixed 2026-08-28 by reading `max_file_kb * 1024 + 1` bytes and
  refusing by name when it comes back longer, with the same ceiling in
  `write_file`. Confirmed by playtest `F-4`.
  **Keep — the bound belongs in `read_file`, not the editor.** Every caller — the
  editor, `Drone.set_file`, the sandbox — is bounded by construction there.
  `max_string_mb` is **not** this bound: it is per codelevel and covers strings a
  running program builds, and a file is read long before any of that exists.
  **Keep — `read(n)` answers nil at end of file**, not `""`. A file created and
  not yet written is exactly that, so the read is `or ''`.
  **Keep — what the engine caps, and from which version.**
  `pkt_read_formspec_fields` sums every field name and value in one submission
  and **drops the whole submission** at 640 kB. That check arrives in **5.7.0**;
  it is absent in 5.6.0, and `mod.conf` declares `min_minetest_version = 5.4`,
  where one field is bounded only by `LONG_STRING_MAX_LEN`, 64 MB. So a modified
  client's route into `write_file` is real but bounded — which is why this stays
  a `B` and is not also an `S`.
  **Keep — the sandbox reports `read_file`'s own message now.** It discarded the
  second return and said *"@1 not found."* for every refusal, so a file refused
  for its size would have read as missing.
- **B41 · low · resolved** — cancelling the file chooser left a drone that could
  not run: `Drone.on_place` creates the drone and *then* asks for a file, and
  cancel called `close_form` and nothing else. ESC landed in the same state.
  Fixed 2026-08-28: `file_chooser.on_close` closes through one local `close`,
  which removes the drone when it still has no file, reached by cancel, an empty
  choose, and a new `fields.quit` branch. Confirmed by playtest `D5`, all three
  parts.
  **Keep — why removing is safe, and why `quit` is last.** `show_file_chooser`
  has one call site, reached only when the drone has no file, so *no file* means
  *this chooser placed it*. The tidier alternative — do not create the drone
  until a file is picked — is a larger change, because `Drone.new` establishes
  the position and facing the chooser's answer is applied to. `quit` sits at the
  end of the chain under `B37`'s rule.
- **B43 · low · resolved** — the emerged box was one node larger than the shape
  on every axis, and the drone's facing decided what that cost. Opened by
  *timing* `P3` rather than by anything failing. `bounds.cube` returned
  `pos2 = o + (w, h, l)` while the filler writes `0 .. w-1`; `bounds.cylinder`
  did the same along its length. `read_from_map` aligns outward to whole
  mapblocks, so the extra layer was free inside a block already emerged and cost
  a whole layer of blocks where it was not — **on a thin shape a doubling, not a
  rounding error**. Measured at three facings: 78 s, 160 s, 183 s. Fixed
  2026-08-28: one subtraction per axis.
  **Keep — the guard the subtraction made necessary.** `cube(0, 0, 0)` is
  reachable, because `drone_place_cube` does `round0(abs(w))` and does not floor
  at 1. With the fix that gives `pos2 = pos1 - 1`, an **inverted** box, which must
  never reach `read_from_map`. `shapes.build` returns 0 before the loop when any
  axis is inverted. Do not remove that check while the subtraction stands.
  **Keep — the spec numbers were recomputed, not fitted.** The fix was run
  against the old bounds and the four changed assertions fail there with exactly
  the old numbers, so none passes vacuously.
  **Unexplained, recorded rather than filed:** after the fix, two facings at
  codelevel 1 gave 78 s and 95 s against predictions of 77 s and 183 s. Both are
  at the multiplier-1 end, so the doubling is gone — but the 23% between them
  fits none of the multipliers, which can only be 1, 2 or 4.
- **B42 · medium · resolved** — a shape wider than the footprint ceiling raised
  instead of throttling, and the drone's facing decided it. Slabs were cut along
  **z** whatever the shape, so `across` was the whole x-y extent.
  `cube(2, 2, 30000)` facing east needed ~1877 mapblocks against codelevel 1's
  512, `limits.hold` returned nil, and `lib/cost.lua` raised on the first slab;
  facing north the same call completed. **A program that worked and one that died
  differed only by where the player was looking.** Medium rather than high
  because the failure is clean — `charge` runs before the pass, so nothing is
  written. Fixed 2026-08-28: slabs follow the axis with the largest span.
  Confirmed by playtest `P3`.
  **Keep — the fillers clip on all three axes now, and that was the actual work.**
  This was filed saying every filler already clipped to the area it is handed.
  **That was wrong** — all three clipped along *z* only and relied on the area
  covering the full x and y extent. Do not re-narrow those clips to one axis.
  **Keep — ties go to z on purpose**: z is the outermost loop of every filler, so
  a z slab stays one contiguous run of the data array.
  **Keep — what this does not fix.** A shape large in *two* dimensions still asks
  for more than one pass should cost, because only one axis can be sliced away.
- **B44 · low · resolved** — removing a file left a drone still naming it, and
  the drone was taken away on the *run* rather than at the removal — one gesture
  after the thing that invalidated it. Fixed 2026-08-28 in `lib/formspecs.lua`'s
  `remove_active`. Confirmed by playtest `D6`.
  **Keep — the two answers had to agree, and where the fix belongs.** The choice
  was to clear `drone.file` or to take the drone with the file. `B41` had just
  decided that question the second way, so this went the same way; a mod that
  answers *what happens to a drone with no usable file* two different ways is
  worse than either answer. It belongs at the caller: `lib/filesystem.lua` has no
  drone dependency and must not acquire one.
- **B45 · medium · resolved** — the HUD almost always named *map memory* as the
  binding limit, drowning out the one thing `F4` exists to teach. From playtest
  `H2`. **`limits.binding` compared a held resource against spent ones, and a
  held one sits at its ceiling by design**: `use_map` loops on `limits.hold`
  until there is room, pinning `used.map` to `caps.map` for as long as the
  program keeps loading mapblocks. 100% there does not mean *about to fail*; it
  means *being throttled right now, as intended*. Fixed 2026-08-29: the table
  `binding` walks is `SPENT`, three keys.
  **This also explains `H6`'s pause observation** — resume after two minutes and
  the footprint has decayed over `map_window_s`, so the drone builds unthrottled
  until it rebuilds. One phenomenon, one root cause; not two findings.
  **Keep — do not "simplify" `binding` and `report` back to one list.** They
  answer different questions: *what will stop this run* and *what is this run
  using*. The map footprint belongs in the second and never the first.
  **Second decision, reversing the one first recorded here: the panel no longer
  lists the held row at all.** *Throttled* shipped and was dropped the same day
  on the author's call — three ceilings that end a run and one that does not,
  side by side, invite exactly the misreading this finding is about.
  `limits.report` still returns the row with its `held` flag. **What is now
  unsurfaced anywhere is why a drone is slow** — the `H6` confusion able to
  return. A known gap, not an oversight.
- **B46 · medium · resolved** — the HUD and panel labelled the runtime budget
  *Running time*, which reads as wall clock and is not. From playtest `H6`:
  `mosely.lua` reported **22 s** against a **180 s** completion line, climbing at
  ~0.1 s/s. **The number is right and the word was wrong** — `stepper.advance`
  charges only the microseconds spent advancing, and a codelevel-4 drone gets
  8 ms of a 90 ms step, about 9%. Fixed 2026-08-29 in `lib/hud.lua` with a rename
  and a describing line per row.
  **Keep — do not "fix" this by charging wall clock.** That would punish a
  program for a busy server and for its own pace, which is the whole reason the
  budget is counted this way — it replaced `max_calls` for being in units nobody
  could reason about.
- **B48 · medium · resolved `4179877`** — the editor marked every
  unsaved tab modified the moment it lost focus, so opening several programs put
  `F7`'s `*` on all of them but the active one. Reported by the author on
  2026-09-03. `read_file` in `lib/filesystem.lua` opens `'rb'`, so a CRLF file
  keeps its `\r\n`; the client's textarea returns LF whatever it was given; and
  `F7`'s dirty check in `lib/formspecs.lua` is
  `fields.content ~= meta.contents[meta.active]`, which therefore never matched
  for a file still carrying its original line endings. **All fourteen bundled
  examples in `lib/examples/` are CRLF**, so every pristine example was
  permanently "modified", and only a file the player had already saved through
  the editor — which writes the client's LF content back — compared equal. Fixed
  by normalising `\r\n` to `\n` in `read_file` before the content is cached and
  returned.
  **Keep — where the normalisation has to sit.** *After* the size check, or a
  CRLF file could shrink its way under `max_file_kb` (`B40`), and after the
  bytecode-signature check.
  **Keep — the general shape.** Any equality test between a buffer that came off
  disk and a field that came back from a formspec is a line-ending comparison
  unless something normalises first. Do not add a second such test elsewhere on
  the assumption the disk side is LF.
  **Evidence, and why the symptom was file-by-file.** In the author's world
  `aaa`, the four files that never showed the mark — `spirals.lua`, `plot3D.lua`,
  `menger.lua`, `stairs.lua` — hold zero CR bytes and differ from
  `lib/examples/`, i.e. they had been saved through the editor. `plot2D.lua`
  there is byte-identical to the shipped example and still holds its 23 CRs, and
  it showed the mark every time. The split matches the report exactly.
  **State.** Committed as `4179877`; the gates were run over the working tree it
  came out of and all say green (luacheck silent; the six
  standalone specs under Lua 5.1; nine in-engine specs, 0 failed and 0 xpass; the
  three `--check` generators up to date). **No spec reaches it** — the round trip
  through a real client textarea is not available at mod load.
  **Confirmed in a world.** Playtest `E16`'s pristine-example case — added the
  same day, and the case the run at `afbe504` was missing — **passed on
  2026-09-03**, engine 5.17.0, on `b9143b0` plus what was then the uncommitted
  tree: several bundled examples opened untouched, and no tab but the active one
  marked. The fix is observed rather than only green, and nothing on this finding
  is outstanding.
- **B49 · medium · resolved `d8c32f7`** — a misspelled block name built
  the default block and said nothing. `blocks`, `plants` and `wools` are
  name-indexed tables handed to a player's program, so `blocks.notablock` is a
  missing key and reads nil, and that nil reached `placement` in
  `lib/commands.lua:99`:

      local real_block = blocks[block or drone.default_block]

  With `block` nil the player's default is substituted and a valid node comes
  back. **The command cannot tell `place(blocks.typo)` from `place()`** — both
  arrive as nil — so a typo built stone, or whatever the default was, with no
  error and no warning. It affected `place`, `place_relative` and all eight shape
  commands; `default_block()` was the one exception, already erroring.
  **The scope is exactly a table read.** A bogus *string* literal was never
  silent: `place('notablock')` reaches `placement`, finds `blocks['notablock']`
  nil and raises *Cannot place this block*. The silent fallback existed only for
  the nil that came back from reading a missing key out of `blocks`, `plants` or
  `wools` — which is precisely what the fix catches. Reported
  by the author on 2026-09-03: *"when using a block name that does not exists,
  the program fallback to stone without error."* Fixed the same day:
  `env.snapshot(t, on_miss)` takes an optional callback and, when given one, puts
  an `__index` on the copy that fires only on an absent key;
  `getScriptEnv` in `lib/sandbox.lua` passes a closure with a `warned` upvalue to
  the `blocks`, `plants` and `wools` snapshots. **One warning per run**, naming
  the key; the program continues and still places the default block, because the
  author asked for a warning rather than an error and erroring would break saved
  programs.
  **Keep — why the warning is at the read and not at the call site.** At
  `placement` all that survives is a nil, so the message could only say *some
  block was wrong*. At the read the key the player typed is still in hand. It
  also covers every block-taking command at once, including ones added later, and
  it fires when the value is stored in a variable and placed much later.
  Warning at the call site would need `select('#', ...)` in a dozen sandbox
  wrappers just to tell an omitted argument from a nil one.
  **Keep — this is not the read-only proxy `S1` argues against.** That
  constraint rejects proxies because Lua 5.1 has no `__pairs` and no table
  `__len`, so a proxy breaks `pairs(blocks)` and `#iwools` for player code. An
  `__index` on a **real copy** fires *only* when a key is absent, so iteration,
  length and every present key are untouched. That distinction is the whole
  safety argument and `lib/env.lua`'s header now states it. Do not "simplify"
  this into a proxy. **That claim is now covered by a spec rather than by a
  comment:** of the 13 cases `test-agent` added to `tests/env_spec.lua`, the
  load-bearing ones assert that `pairs` over the copy still sees every entry and
  that `#` on an array copy is still right, with the callback firing for neither
  — which is the evidence that `__index` is consulted only for an absent key.
  **Keep — `iwools` is excluded on purpose.** It is integer-indexed, so a program
  reading past the end is doing something legitimate and must not be warned at.
  **Accepted side effect, recorded rather than left to be noticed.** A program
  that probes membership with `if blocks[name] then` now gets one chat line per
  run. Once only, so it is cheap, but it is a visible behaviour change for that
  idiom and it was accepted knowingly.
  **What it drags, all done the same day:** `lib/api.lua`'s `blocks` entry
  documents the behaviour and `doc/api.md` was regenerated from it;
  `locale/template.txt` gained the key `Warning: no block named '@1', the default
  block is used instead` and the French was written, so the locale gate reports
  full coverage again.
  **State: fixed, committed as `d8c32f7`, and confirmed in a world.** A chat line
  reaching a player is beyond every spec, so the evidence is playtest `W4`,
  written the same day with the fix and **run at `16cd05c` on 2026-09-03, engine
  5.17.0 — pass**. What `W4` reaches that no spec can is that the warning is
  **per run**: the flag is a closure upvalue in `getScriptEnv`, which is
  file-local and unexported, and `integration_spec` builds its own `api` table by
  hand — so a second drone in the same session warning on its own account is
  observable only in a world. The author reported the check as a whole rather
  than case by case, so what is recorded is a pass on `W4` as written.
- **B50 · high · resolved `1b991ae`, confirmed in a world 2026-09-04** — the drone
  disappeared mid-run at codelevel 1, taking its program with it, with no error
  and no refusal. Found by playtest `W1`'s re-run on 2026-09-03 — the codelevel
  that check had been asking for since 2026-08-28 — and fixed the same day by
  **decoupling the drone record from its entity**: every drone is advanced from
  the one globalstep `lib/register.lua` already registered, `on_deactivate` sets
  `drone.obj = nil` instead of ending the run, and `Drone.on_step` hands a drone
  another object, **with the same serial**, once its mapblock is back in server
  memory.
  **Keep — the cause, read out of the 5.17.0 engine source.** The drone entity
  sets `static_save = false`, and for such an object the unload rule is **not**
  *out of active-block range* but *the mapblock it stands in is not in server
  memory* — `src/server/serveractiveobject.h:123-129` states the two rules and
  `src/serverenvironment.cpp:1685-1690` is the test:

      isStaticAllowed() ? m_active_blocks.contains(blockpos)
                        : getBlockNoCreateNoEx(blockpos) != nullptr

  With no static data to write, `deactivateFarObjects` **deletes** the object
  rather than saving it, on `active_block_mgmt_interval`, 2.0 s. Nothing in the
  mod keeps the drone's *own* block loaded: `cost.place_block` loads the block it
  **writes** in (`B25`), so `place(); forward(16)` rests the drone one block ahead
  of its trail. The client keeps a nearby block alive —
  `active_object_send_range_blocks` is 8, so at **128 nodes** the client is told
  to forget the object, and `viewing_range` runs out at **190–192** — past which
  nothing loads it at all. **Anything given `static_save = false` here is subject
  to this, and a new object of that kind needs the same treatment.**
  **Keep — why *time* far from the player was the discriminator and not
  distance.** At 250 ms of pace a mapblock takes ~0.53 s, so ~192 nodes arrives
  at ~6.4 s and the next 2-second sweep catches it — the 6–8 seconds reported,
  from the arithmetic rather than from the report. **At codelevels 3 and 4 the
  whole program is over inside a step or two, so the sweep never sees it**, which
  is why `W1`'s two passes above level 2 could not have caught this. Level 2 is
  genuinely undecided and depends on singleplayer against dedicated. It was never
  a regression at some commit: it is a defect the check was pointed away from for
  as long as it was run at the wrong level.
  **Keep — the observed 320–352 nodes, against the ~192 the diagnosis
  predicted.** Two runs of a plain outward walk stopped at **352** and **320**
  nodes. That **confirms** the mechanism rather than denying it: ~192 is where
  the drone becomes *killable*, not where it dies; `place()` reloads the block
  250 ms after the drone enters it, so the exposed window is about half of each
  iteration; and the sweep samples every 2.0 s, so each pass past 192 is roughly
  a coin flip. **Two runs dying 32 nodes apart is the signature of a sampled
  race, not of a fixed boundary.** A program that **moves without placing** has
  no `load_area` at all and dies at the first sweep, so 320–352 was the lucky
  case rather than the typical one.
  **Keep — the reproducer, and it is deterministic.** From the author,
  2026-09-03, in preference to the 50-iteration loop, which is a coin flip:

      -- bbb.lua
      forward(500)
      sleep(20)

  `forward` is a teleport (`lib/commands.lua:123-134` adds the whole offset in
  one command), so the drone is 500 nodes out the instant the program starts,
  and `sleep(20)` then makes no call, so nothing calls `load_area`. **Before the
  fix this killed the drone in one to two seconds, every time.** It is the check
  to run first, and it is `W1`'s.
  **Keep — the earlier rejection of a globalstep driver was reconsidered and was
  wrong.** It had been turned down as inverting `A11`'s direction of dependency.
  That reading was mistaken: `register.lua` already registers a globalstep and
  already owns orchestration, so driving the drones from it **follows** `A11`
  rather than inverting it. Do not re-raise the objection. The two options put to
  the author were both worse: one closed neither of `B52`'s cases, and the other
  closed them only by forceloading, which spends the game's shared
  `max_forceloaded_blocks` and runs ABMs wherever a drone goes — a `C18`-class
  imposition of this mod's needs on the surrounding game.
  **Keep — the two costs the decision accepted, written down rather than
  glossed.** A far-away runaway **loses its accidental stop**: it used to be
  killed by its own entity vanishing, and now `max_nodes_written`,
  `max_runtime_s` and `map_memory_mb` carry the whole load. That is not new
  exposure — those three already carried it for anything in range — but it is the
  last unintended backstop going away, so a weakness in any of them now shows
  everywhere rather than only near a player. And **`/clearobjects` stops ending
  programs**: it blanks the view, which the globalstep then brings back.
  **Keep — the running count is per step, not per drone.** The share each drone
  gets needs the number of them running, and counted from inside each entity that
  was a scan of every drone for every drone. `Drone.on_step` counts once, skipping
  sleeping drones so they take no share, and counts rather than keeping a running
  total because a drone can stop by paths that never pass through there.
  **Evidence, from `test-agent`.** `tests/integration_spec.lua`'s drone-seam
  block — six cases before, **nine** after — pins
  `codeblock.DroneEntity.on_step` as **absent**, `Drone.on_step` as a one-pass
  `dtime` call that leaves a non-running drone alone, and `Drone.on_lost` as
  clearing only `obj`. **Keep the reason a placeholder `obj` was added to the
  fake record**: without one, *cleared* and *left alone* are indistinguishable and
  **both assertions pass vacuously**. That is this project's recurring failure
  mode — the family of `C20` and the `%w+` guard — and it is why a new assertion
  is made to fail once before it is trusted.
  **State: fixed, committed and confirmed in a world.** The three checks written
  for it all ran on **2026-09-04 at `23f0227`** and all passed — `W1` **at every
  codelevel**, which no earlier run of that check managed, `W5` and `W6`. What
  they settle beyond the run surviving: **observation 3 is answered**, a drone
  placing immediately after the program finishes, so the leaked record that was
  the expensive case is **ruled out** rather than unlikely; **no chat line
  arrives** before the program's own finish line, the *drone has disappeared*
  message having gone with the fix; and **`/clearobjects` does not end a running
  program**, one of the two costs the decision accepted, now observed rather than
  reasoned. The engine version was not restated by the author. Note the second
  constraint the fix leans on harder than before — `B29`'s serial guard, since a
  re-spawn under the same name is exactly the case it exists for; **`W6` case 2
  is that guard's first in-world evidence in its post-`1b991ae` form**, one drone
  and not two after a re-spawn.
- **B51 · medium · resolved `8de3cea` 2026-09-04, confirmed in a world the same
  day** — a run
  cut short was announced as *completed*. `Drone.finish` had **no vocabulary for
  a run that was stopped**: every non-error ending fell into the `else` branch
  and read `Program '@1' completed`, so a run the player stopped from the drone
  panel's **Stop** button told them the program completed, with a node count a
  fraction of what it asked for. `Drone.on_remove` passed `'completed'`
  explicitly, and after `1b991ae` it was the **only** caller doing so wrongly —
  `on_lost` no longer ends a run at all, so the mid-flight case the same word
  used to cover went with it.
  **Fixed by adding the vocabulary, not a second announcement path.**
  `Drone.on_remove` passes `'stopped'`; `Drone.finish` gained an
  `elseif outcome == 'stopped'` branch before the final `else`, sending the new
  key `Program '@1' stopped: @2` with `drone.file` and `tostring(drone)` — the
  same two arguments the `completed` branch uses, so the
  commands/nodes/duration tail reads as the partial count it is. New key in
  `locale/template.txt`, French `Programme '@1' arrêté : @2`. **The word was the
  author's choice** from three options on 2026-09-04; the grounds are in
  `ROADMAP.md`'s decisions log. `Drone.finish`'s doc comment used to say
  `outcome` was the stepper's minus `'yielded'`, which is no longer true and now
  says `'stopped'` comes from `Drone.on_remove` alone.
  **Found while diagnosing `B50`, and independent of it.** It made `B50` harder
  to read from a chat log than it should have been — *completed* is exactly the
  word that stops a player looking — but it was wrong on its own account, and
  the deliberate-stop case never had anything to do with `B50`.
  **Observed broken in a world on 2026-09-03**, in `W1`'s discriminator run:
  the player was shown *le drone a disparu* and then *programme terminé*, **one
  after the other, about the same run**. The program had asked for 50 placements
  and got as far as 22 mapblocks, so *terminé* announced a run killed roughly 48
  blocks short. **The two lines contradicted each other** — that is the whole
  finding in one observation, and why it was not merely cosmetic. The codelevel
  was not restated. That exact pairing went with `B50`'s fix; the panel's
  **Stop** path is what this fix addresses.
  **`Drone.on_remove` has exactly two callers, and only one is a player
  gesture** — the panel's **Stop** button in `lib/formspecs.lua`, and
  `register_on_leaveplayer` in `lib/register.lua`. So a player who disconnects
  mid-run is now told *stopped* rather than *completed*; nobody sees either line,
  and *stopped* is the truer of the two. **This finding's own text said *the
  setter* until 2026-09-04 and was wrong from the day it was written**: `F4`
  split that tool's gestures and `F8` collapsed the split, and since then the
  setter's left click opens the panel, its right click the editor, and it removes
  nothing. Playtest `D7` inherited the error and is corrected with it. The
  defect and the fix were unaffected — only the route named for them.
  **Confirmed in a world on 2026-09-04**, at `8de3cea` plus a comment-only edit
  in `lib/drone.lua`, engine version not restated: `D7` read *stopped* with a
  partial node count and *arrêté* on a French client. No spec asserts what
  `Drone.finish` sends, so that run is the whole of the evidence this finding
  can ever have.
  **Keep — the constraint the fix was built to.** `Drone.finish` is **the single
  place a run's outcome is announced**, which is `B12` and `B30`: two messages or
  none is the failure that centralisation exists to prevent. Add vocabulary to
  that function; never a second announcement path. And a new outcome word is a
  new `S()` key, so `locale/template.txt` and every `.tr` move with it or the
  existing translations are orphaned with no error anywhere — the `C17` rule.
- **B52 · medium · resolved `1b991ae`, confirmed in a world 2026-09-04** — a drone standing
  still far from any player died at about 29 seconds, whatever happened to
  `B50`. `resetUsageTimer` is called only for blocks in the active list and
  **never by `load_area`**, and `Map::timerUpdate` unloads on
  `server_unload_unused_data_timeout` with no regard for objects standing in the
  block, so a drone that was not moving lost the block under it after that
  timeout and, being `static_save = false`, was deleted. **What reached it:**
  `sleep(30)` out at 300 nodes, or a run left **paused** from the panel for half
  a minute — both things the mod invites, `F3` having added `sleep` and `F4`
  Pause. Closed by `B50`'s fix, which was one of the two reasons that option was
  chosen: a drone whose block is unloaded now loses its **view** and not its run.
  **Never observed in the broken state, and observed in the fixed one.** It was
  a mechanism read out of the engine with nothing timed against it, and `W5` is
  its first and only check: written 2026-09-03, **run 2026-09-04 at `23f0227`
  and passed on both cases** — the sleeping drone past the timeout places and
  finishes, and a run left paused for over a minute resumes where it stopped. So
  the fixed behaviour is measured while the defect itself never was, which is
  the strongest evidence this finding can have.
  **Keep — `map_window_s` reads the same setting for a different purpose.**
  `lib/limits.lua`'s footprint decay is timed to
  `server_unload_unused_data_timeout` because the map footprint decays over
  exactly that window; that is correct and unrelated. **This finding was that
  `load_area` does not reset the timer**, which is a property of the engine
  rather than of the limit.
---

## S · Sandbox and security

7 findings, all resolved. `S2`'s residue is one of the things v1.0.0 ships
broken.

- **S1 · high · resolved** — player programs got live references to shared module
  and config tables, and the damage was global until restart. Fixed in Phase 2:
  each run gets snapshots and API names are unassignable.
  **Keep — three constraints on the environment.** *Copies, not read-only
  proxies*: Lua 5.1 has no `__pairs` and no table `__len`, so a proxy breaks
  `pairs(blocks)` and `#iwools` for player code. *`vector3`'s copy must carry its
  metatable* or `vector(x, y, z)` stops resolving; the metatable stays shared,
  safe only because `getmetatable` is not in the environment. *Read-only names
  need the API in a separate table*, since `__newindex` fires only for keys
  absent from the target. Consequence for any new name: a program using it as its
  own global stops working.
- **S2 · high · resolved** — one builtin call could exhaust server memory,
  invisibly to the call counter. The earlier "cannot be fixed" call was too
  pessimistic: the premise was right (the string metatable belongs to the type,
  so `("x"):rep(1e9)` is reachable from any literal) and the inference wrong.
  `lib/strguard.lua` replaces `getmetatable('').__index` at load with a copy whose
  amplifying entries are wrapped, inert unless a player program is running.
  **Two methods amplify, not three:** `rep` and `gsub`. Lua's format-spec scanner
  takes at most two digits of width and rejects `("%1000000000d")` itself; a
  guard was written and deleted as dead code, and `strguard_spec` keeps that
  boundary tested.
  **Keep — the residue v1.0.0 ships with.** `heap_mb` cannot stop one huge
  allocation, and a pathological Lua pattern can still burn CPU inside a single
  `find` or `match`. No counter here sees either.
- **S3 · medium · resolved (retired)** — the blacklist refused any file containing
  `repeat`, `until`, `_G` or `_c_` as substrings, so `repeat_count` was refused.
  Retired in Phase 2.
  **Keep — where the boundary actually is.** *The security boundary is the
  environment table plus the read-only API surface, not the forbidden-name list.*
  That list is a diagnostics aid: it turns "attempt to index a nil value" into a
  message naming what the player reached for. It matches identifier tokens and
  skips fields, so `local until_done` and `t.os` are accepted, and it must name
  both `minetest` and `core` (`C6`).
- **S4 · medium · resolved** — the vendored WorldEdit fork still carried its
  arbitrary-code-execution module. `code.lua` was deleted in Phase 2, then the
  whole fork went (`A15`). `integration_spec` asserts
  `rawget(_G, 'worldedit') == nil`. `worldedit` stays in the forbidden list on
  purpose: a server can load the real WorldEdit alongside.
- **S5 · medium · resolved** — `place()` could pin an unbounded number of
  mapblocks in server memory, and no existing limit could see them. Phase 6
  settled on `map_memory_mb` plus the memoised same-mapblock skip and one shared
  step pool.
  **Keep — what a load costs.** `core.load_area` is documented as **not**
  triggering mapgen, so a load is a resident MapBlock plus a synchronous disk
  read. Measured in a running world: **16.3 kB resident per mapblock**, **~1700
  loads/s** served. **The ceiling bounds what is resident, not what was loaded**
  — over it, `use_map` sleeps the drone rather than killing the program, because
  the engine frees idle mapblocks by itself. 128 MB over 29 s is ~280 loads/s
  against the ~1700/s available. Confirmed by playtest `P3`: a throttled
  `cube(2, 2, 30000)` waited and completed in 93 s against a predicted ≈80 s.
  The decay stays an estimate by construction, since the exact figure needs a
  timestamp per block ever touched. The throttle holds only while every request
  is smaller than the whole ceiling — `B42` made `lib/shapes.lua` keep to that
  for a shape long in one dimension; one large in two still exceeds it.
  **Keep — what no limit stands for.** From `W3`: `cube(200, 200, 200)` took
  0.34 s of program time, and that is the *smallest* part of what it cost.
  **Serialising the ~2200 mapblocks into the map database and pushing them to
  every client in range are charged to nobody**, and both land after the run
  reports `completed`. Not a defect — every mod writing to the map has it — but a
  limit added later must not be sold as bounding what a shape costs the server.
  Also from `W3`: at 13 mapblocks per axis the cross-section is ~169 and
  `floor(SLICE_BLOCKS / across)` clamps to 1, so **every slab of a large cube is
  one mapblock thick and 169 across**.
- **S6 · medium · resolved** — every player got the widest limits by default.
  Fixed in Phase 5: resolved once from `core.is_singleplayer()`, overridable by
  `codeblock_default_auth_level`, and validated against `auth_levels` rather than
  trusted, so a level that does not exist gives nil limits rather than wide ones.
  The write is in `register_on_newplayer`, so **upgrading a live server demotes
  nobody — and equally tightens nobody**. That second half is the one that
  surprises, and it makes the numbers a decision about new worlds only.
  **Tightened 2026-08-30: singleplayer is 3, not 4.** The original reasoning —
  the single player is the administrator, so a lower level is only an annoyance —
  proves too much: it argues for the *unpaced* levels, which is 3. Level 4 is
  every ceiling at its widest at once, and the difference is headroom rather than
  capability. Nothing sits at 4 without someone asking. Server default unchanged
  at 2. Checks: `R4` and `F-5`, both passed 2026-09-02 — observed, not reasoned,
  and the out-of-range guard read in `debug.txt` while there.
- **S7 · low · resolved** — a failed file open told the player the server's
  absolute path, in English whatever the game's language. From playtest `F-3`
  case 2, which **passed on behaviour and failed on its message**. `read_file`
  handed back `io.open`'s own string where every other refusal names the bare
  filename. Two defects on one line: the install layout disclosed, and a message
  that could never be translated. Fixed 2026-08-28: the player gets `unreadable`,
  and `err` goes to the log at `warning`. Confirmed by `F-3` case 2 —
  *"Impossible de lire le fichier ..."*, both halves at once. **The log half was
  not looked at** and is the one thing still resting on reading.
  **Keep — the class, not the line.** `C17`'s lesson one level down: a string
  that reaches a player and is not a translation key cannot be translated and
  **nothing reports it**, because the checker only sees literals. An error value
  handed straight through from an engine or C call is exactly that.
  **Keep — the locale checker reads comments too.** An explanatory comment
  containing the literal call syntax made it report a non-literal key, in the
  source it was documenting. Prose about translation must not spell the call out.

---

## C · Compliance and packaging

15 findings, all resolved — `C21` by `F10`, committed at `b23a8bc`. `C2`–`C5`
and `C15` are the game's; `C9` never used.

- **C1 · high · resolved** — the version ceiling hid the package from every
  modern user. The engine does not enforce these keys, but **ContentDB filters on
  them**. Fixed in Phase 1: `max_minetest_version` removed and the floor raised
  5.3 → 5.4, which was simply a false claim (`formspec_version[4]`).
  **Residue, not fixable from here:** `tests/game/mods/vector3/mod.conf` carries
  a 5.5 ceiling — a separate repository and package.
- **C6 · low · resolved** — `minetest.*` → `core.*`, style rather than breakage.
  Finished in Phase 7 because it became cheap: `lua_api.md` says `minetest` "will
  keep existing as an alias" — no warning, no removal date.
  **Keep — what must still say `minetest`.** The filename `minetest.conf`;
  `lib/preprocess.lua`'s forbidden list, which must forbid **both** aliases or
  the sandbox's messages stop naming what the player typed; and the `vector3`
  submodule, converting which would move a submodule pointer.
- **C7 · medium · resolved** — no `settingtypes.txt`: every limit was source-only.
  Fixed in Phase 5, **in the mod rather than the game root, deliberately**: every
  setting is codeblock's and it ships as its own ContentDB package. A malformed
  value warns and falls back; a negative is rejected and zero allowed, because
  `pace_ms` uses it for "no pacing". A `replaced` table warns when a retired name
  is still set, because an administrator's `minetest.conf` outlives a rewrite and
  a silently ignored limit reads as being in force.
  **Keep — two constraints easy to undo by accident.** Both are in `CLAUDE.md`:
  the tables stay **plain literals** (a computed value turns `C14`'s check off
  without failing), and every settings read is guarded with `rawget(_G, 'core')`
  because `gen_docs.lua` dofiles this under a bare interpreter. Adding a limit
  means all three: literal, `settingtypes.txt` mirror, documented row.
  **`settingtypes.txt` is a hand-kept mirror and nothing checks it** — the third
  such mirror and the only one left without a generator. See `C17`.
- **C8 · low · resolved** — linting and CI had been set up, then removed. Restored
  in Phase 0, and it earned its keep immediately: five dead locals, and — via the
  specs, not the linter — a regression that had silently disabled the sandbox's
  call-counter instrumentation.
- **C10 · low · resolved** — a malformed `.gitattributes` line, and a release
  archive nothing had decided the contents of. Fixed before Phase 7; archive
  1.60 MB → 1.42 MB, and **2.21 MB again since 2026-09-02**, when the Mods-tab
  cover was replaced with the full-size mosaic — larger than before the trimming,
  on the author's call. `screenshot.png` is kept with an explicit `-export-ignore`,
  because Luanti shows it in the main menu's Mods tab. Confirmed by playtest `R1`
  — the first time anything had looked.
  **Keep — the standing hazard, which outlives the fix.** It is in `CLAUDE.md`:
  `.gitattributes` decides what reaches a player and **nothing in CI checks it**.
  **Keep — `R1`'s own command misleads.** `git archive HEAD | tar -t | grep tests`
  prints `lib/examples/tests.lua` even when the archive is correct — a
  player-facing example. What answers the question is listing the top level:
  `git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u`.
  **A check whose command needs its output interpreted has to say so.**
- **C11 · low · resolved** — the changelog shipped two "known limitations" the
  same section contradicted. Both deleted rather than reworded, since a reworded
  limitation would have been an invented one. Released entries untouched — they
  are a record.
- **C12 · low · resolved** — `.luacheckrc` still configured two mods that no
  longer exist, under a comment asserting a correspondence that did not hold.
  Deleting the `worldedit` global also restored a real check.
- **C13 · low · resolved** — `max_distance` was stored squared while its
  documentation gave it in nodes. Internally consistent, so nothing was wrong for
  a player; `C7` made it a defect by exposing it as a setting, where an
  administrator entering a distance would have got its square root. Phase 6
  removed the limit: distance from spawn was never the resource. What replaced it
  is a hard edge — `check_inside_world` keeps the drone inside `mapgen_limit`.
- **C14 · medium · resolved** — `gen_docs.lua`'s "every limit is documented" check
  matched by name prefix, so `pace_ms`, `heap_mb` and `map_memory_mb` were
  invisible to it. **The failure mode is the bad one for a guard: it passes.**
  Fixed in Phase 6: it matches by table shape, the same rule `config.lua`'s
  override loop uses, so the two agree by construction.
  **Keep.** This check exists because a limit once shipped undocumented.
  Committed, **not verified that it now catches an absent row** — a guard that
  passes has not been shown to fail.
- **C16 · medium · resolved** — `codeblock_run_tests` aborted mod load on a
  ContentDB install: nine bare `dofile`s under a setting an administrator can
  find. A regression from `C10`'s `tests` export-ignore. Fixed in `7d9ca47`:
  `init.lua` probes for `tests/api_spec.lua` and, absent, logs and loads normally.
  Proven on a real install by playtests `R1` and `R2` — the one thing only an
  install could show.
  **Keep the probe's shape**: it tests for a file with `io.open` rather than for
  the directory, because Lua 5.1 has no portable directory test, and a release
  build must answer rather than fail.
- **C17 · medium · resolved** — `locale/template.txt` had drifted in both
  directions, and three translations had been unhooked by a one-character key
  edit. From playtest `F-2` being partial: behaviour passed, words came out in
  English. Three layers: one key assembled with `..` from two literals and so
  never in the template at all; 12 messages absent and 17 listed that no longer
  exist; and three of the 12 orphaned by a trailing space, a plural and a capital.
  Each looks translated in the `.tr` file and falls back to English in the game.
  Fixed by `b5d2e40`, with **`gen_locale.lua --check` added to CI**.
  **Keep — two rules for a translatable string.** Both are in `CLAUDE.md`: never
  build a key with `..`, never edit a key in the source alone. The `.tr` report
  is advisory, because an untranslated message legitimately falls back to English
  while a template that lies about what needs translating does not.
  **Keep — the pattern behind the hand-kept mirrors.** `doc/api.md` drifted first
  and got `gen_docs.lua --check`; `locale/template.txt` drifted second and got
  `gen_locale.lua --check`; **`settingtypes.txt` is the one left with neither.**
  A file that restates the source and is read by a human or by ContentDB rather
  than by the code will drift, silently, and the only fix that holds is a
  `--check` in CI.
- **C18 · medium · resolved** — five sky overrides were forced on every joining
  player, unguarded and marked `TODO: TEMP fix`. Install the mod into any world
  and every player lost the day/night cycle, with no way to refuse. Nothing the
  mod does needs it. Same class as `B38` and `B39`: code whose effect is
  invisible in the game it was written for and destructive in any other. Fixed
  2026-08-28 behind `config.flat_sky`, **off by default**. Confirmed by playtest
  `R3` in both positions — the first time this finding's player-visible half was
  *seen* rather than inferred.
  **Keep — `codecube` has to ask for it now**, one line in the game and nothing
  here. Deliberately not defaulted the other way: a mod that ships to any game
  must not rewrite its sky to suit one of them.
- **C19 · medium · resolved** — the ContentDB long description was `README.md`
  verbatim, breaking six of ContentDB's *do not include* rules at once: a heading
  repeating the title, the short description restated, links to the repository
  and to the ContentDB page itself, licence text, API documentation, and images.
  ContentDB's stated reason for the images rule is that **"images ... are not
  visible inside Luanti"** — its words — so the nine here reached the website's
  readers and nobody browsing in-game.
  **Five of the nine were load-bearing**, which is what made this more than
  tidiness: the *Quick start* used the two tool icons *inline in the
  instructions*, so stripping them left *"Right click with tool on a block"*
  three times over. **A rule about images turned out to be a rule about a
  sentence that cannot be read.**
  Fixed 2026-08-28: the long description has its own source, **`CONTENTDB.md`**,
  which `gen_cdb_json.sh` embeds instead. It is `export-ignore`d — ContentDB
  reads `.cdb.json` from the repository, so shipping it would only be a second
  README.
  **Keep — why the shipped field is one enormous line.** A JSON string cannot
  contain a newline, so the escaped one-liner **is** the required form. Anyone
  finding it unreadable and reaching for a multi-line format is about to break
  the upload; edit `CONTENTDB.md` and run the generator.
  **Keep — `.cdb.json` is the fourth hand-kept mirror and fails differently.** It
  is *generated*, so it never drifts — it was faithfully generated from the wrong
  source, and a `--check` would have passed on it. **A generator guarantees the
  output matches its input, and nothing more.**
  **Keep — nothing in this repository can see the result.** ContentDB renders the
  description and Luanti's content browser renders it again, differently, and
  neither is reachable from here. The rules are the only test there is, so they
  are written into `release-check` as a gate.
  **Two things this leaves, and the first has now happened.** `CONTENTDB.md`'s
  *Recent changes* is a hand-kept summary of `CHANGELOG.md` that nothing checks —
  the same family again — and by 2026-09-02 it had drifted two features behind
  the code, silently. Two claims describe `F4`'s displays, which `F8` replaced:
  the corner display *"naming the one limit the run will actually stop on"*
  (under both *Features* and *Recent changes*), where `F8` put three lines and a
  colour and deleted the binding-limit line outright; and the panel offering
  *"pause, resume, cancel and remove"*, where `F8` cut four buttons to **Stop**
  and **Pause/Resume** with closing moved to an `x`. **What that proves is the
  narrow point, not the general one:** a page nothing in the repository can read
  cannot be checked from here (see the *Keep* above), so the only defence
  available is the release gate — and a step in a skill saying *update this file*
  is the note about remembering that failed. It is item 3 of *Finalising v1.0.0*
  in `ROADMAP.md`. The second thing left: every ContentDB URL in `README.md` is
  on `content.minetest.net`, the pre-rename domain; it redirects today.
- **C20 · medium · resolved** — `gen_docs.lua`'s documented-limit check matched
  nothing, and had matched nothing since it was written. It greps `config.lua`
  for `codeblock%.config%.(%w+)%s*=%s*{%s*%d`, and **Lua's `%w` is alphanumeric
  and excludes the underscore**: every per-codelevel limit has one in its name,
  so `%w+` stopped at the underscore, the `=` then failed to match, and the loop
  body never ran. Zero matches against seven limits. Found 2026-09-02 while
  writing `gen_settingtypes.lua`, whose own completeness check was copied from
  it and reported every limit as undrawn. Fixed in both: `[%w_]+`.
  **No documentation was actually missing** — the codelevel table in
  `doc/api.md` has a row for all seven, kept correct by hand for the whole time
  the guard was dead. Verified by running the fixed pattern, and proved live by
  adding a fake limit to `config.lua`: both generators now name it and exit 1.
  **Keep — what this is really an instance of.** The check exists because
  `step_budget_us` once shipped undocumented, and its predecessor was replaced
  *because it listed three name prefixes that matched none of the limits being
  added*. The replacement failed the same way for the same names, and the
  comment recording that lesson sat directly above the line repeating it. **A
  check that cannot fail is indistinguishable from a check that passes**, so a
  new one is not finished until it has been made to fail once — which is now how
  both of these are recorded.
  **Keep — the wider version, since two mirrors turn on it.** `%w` excluding `_`
  is a Lua 5.1 pattern behaviour, not a typo, and `[%w_]` is the fix wherever an
  identifier is matched. Both generators depend on `config.lua`'s limit tables
  staying **plain literals** for this shape match to see them at all; that
  constraint is commented there and is now load-bearing twice over.
- **C21 · medium · resolved by `F10`, `b23a8bc`** — `register_on_newplayer`
  in `lib/register.lua` granted `fly`, `fast` and `noclip` to every new player,
  unguarded, in **any** game that installs this mod. A mod that adds programming
  to a game was handing out creative movement to everyone who joined, and no
  setting, privilege or callback let the game refuse. Nothing this mod does needs
  any of the three: the drone flies, the player does not.
  **Same class as `C18` and `B39`, and found the same way — by accident.** `C18`
  was five sky overrides, `B39` an inventory wipe, this a privilege grant; all
  three are `codecube`'s presentation living in the mod and imposed on every
  other game, and all three are invisible in `codecube`, where creative flight is
  the game's own design. It was **found while building `F10` on 2026-09-03, not
  reported by anyone** — the author asked about the tool handout and this was in
  the same twenty lines. Fixed by `F10`: removed outright, gates green, and
  committed as `b23a8bc` on 2026-09-03.
  **Keep — removed rather than put behind a flag, deliberately.** `C18`'s
  treatment was offered and declined: a `flag` in `lib/config.lua`, off by
  default. **A setting no code path here depends on is a setting maintained for
  nobody** — `flat_sky` at least has a game asking for it, and it is the
  exception this project allows itself, not a precedent. A game wanting creative
  movement grants it in its own config.
  **Keep — what makes the class hard to see.** Three findings now have the shape
  *correct in the game it was written for, destructive in every other*, and none
  of the three was found by a spec, a gate or a review. Two were found by playing
  the mod outside `codecube` and this one by reading twenty lines while doing
  something else. **The routine that finds them is playing it in another game**,
  which is `R2` and the rule under `ROADMAP.md`'s *four rules this phase paid
  for*.
  **Confirmed in a world, 2026-09-03.** Playtest `F10-1` ran that day
  and came back partial — the chat line only — and was **completed later the same
  day on the author's report**: a fresh player's `/privs` shows no `fly`, no
  `fast` and no `noclip`, and the inventory holds neither tool. That was this
  finding's **only possible evidence** — nothing else here has ever looked at a
  privilege *not* being granted — so the removal is now observed rather than
  merely green. Same run: `b9143b0` plus what was then the uncommitted tree,
  engine 5.17.0, and re-affirmed at `16cd05c` once the code was committed.
  Nothing on this finding is outstanding.

---

## A · Architecture and performance

12 findings, all resolved. `A7`, `A8`, `A13`, `A14` are the game's. Closing `A3`,
`A6`, `A9` and `A11` in Phase 7 left four regressions behind (`B27`, `B28`,
`B29`, `B30`): **a clean architecture section was not a clean phase, and a
refactor's findings should not be closed without a review of what the refactor
introduced.**

- **A1 · high · resolved** — the entire UI rested on an unmaintained mod that
  installed ten names into the engine namespace and replaced `register_node` and
  `override_item` globally for every mod loaded after it. Fixed in Phase 3 by
  `lib/forms.lua`, ~180 lines against 420.
  **Keep — the form contract `F2` and `F4` build on.** One form per player,
  cleaned up on leave, handler `handler(meta, player, fields)` with the same
  `meta` across redraws. Two behaviours are decisions, not leftovers: a
  programmatic close does not run the quit path, and form names carry a counter
  so an event from a closed form cannot be mistaken for a live one.
  **Deliberately layout-neutral:** the editor declares no `formspec_version` and
  is read with legacy coordinates, so adding one moves every element.
- **A2 · medium · resolved** — the player-facing API was defined in three places
  and had already drifted. Fixed in Phase 3 at the cause: `lib/api.lua` is pure
  data and the single description.
  **Keep — the rule every API change obeys.** It is in `CLAUDE.md`. What is not:
  the descriptors carry no closures and no dependency on the mod being loaded,
  which is what lets a bare interpreter render them and `api_spec` check every
  name without constructing a drone. Only the reference is generated; the
  codelevel table and the command prose above the marker are hand-written and
  preserved byte for byte.
- **A3 · medium · resolved** — `lib/commands.lua` was largely mechanical
  repetition, 971 lines. Fixed in `834f69f`: 608 lines, plus `lib/cost.lua`.
  Seven movement commands became one rotation table plus a shared `move_by`,
  twelve placement preambles became `placement()`, and four `w, l = w, l` no-ops
  (a real read and a real write, so luacheck never flagged them) went with the
  four-way `ccube` branch. **It introduced two regressions, which is the honest
  reading of it: `B27` and `B28`.**
- **A4 · medium · resolved** — `place()` wrote one node at a time and failed
  silently off-map. Fixed by `f413758`: `place_block` calls `core.load_area`
  before `set_node`. **Answered by playtest `W2`, and the answer is no** — mapgen
  does not later overwrite such a node. `load_area` plus `set_node` makes the
  engine treat the block as generated. This was the oldest thing on the *not
  verified anywhere* list, open since Phase 4.
  **Keep — the batching decision, and why its arithmetic wants redoing.**
  Batching into `core.bulk_set_node` is decided against for 1.0.0. The prize is
  the engine's own 1.3x on the write half of a short run. The price is a
  pending-writes buffer flushed at **five** sites: at every yield, before
  `get_block`, before each shape command, and on end, error and abort.
  **Omitting any one of them is a silently wrong build.** The decision is
  contingent: the gain depends on run length between flushes, which depends on
  the yield cadence, and Phase 6 changed that cadence.
- **A5 · high · resolved** — the drone advanced exactly one coroutine resume per
  server step, pinning throughput near 400 commands/s regardless of headroom.
  Fixed in Phase 4 **and measured**: with an injected clock a 300 µs budget does
  3 resumes, 1000 µs does 10, 2000 µs does 20, against exactly 1 before.
  **Keep — the overshoot that remains.** What still overshoots is **one slab** —
  ~65k nodes, under 10 ms — because a shape's VoxelManip pass is the only thing
  left that cannot be interrupted. The budget is the smaller of the codelevel cap
  and an equal share of one server-wide pool, published as `drone.deadline`; a
  sleeping drone takes no share, which is what `F3` and `F4` lean on.
- **A6 · low · resolved** — the entity prototype relied on a two-level metatable
  chain that resolved only by a coincidence of two independent designs. Fixed in
  `742a1ca`: the callbacks sit directly on the prototype table.
- **A9 · medium · resolved** — the filesystem layer duplicated its read path and
  exported six near-identical getters. Fixed in `37c416e`: 157 lines, one sorted
  list of records plus `ud.byname` indexing the same tables. Collapsing
  `read_file`'s two branches is what let `B7` be fixed once instead of twice.
  **No spec coverage at all**, the suite running before a player or user
  directory exists, so this is verified by reading and a clean in-engine load.
- **A10 · low · resolved** — `get_safe_coroutine` overwrote its own parameter.
  Behaviour unchanged, the only caller passing `drone.file` anyway.
- **A11 · medium · resolved** — `drone.lua` and `drone_entity.lua` did not divide
  by responsibility, and drone state had no owner. Fixed in `742a1ca`.
  **Keep — the split, because every UI feature crosses it.** It is in
  `CLAUDE.md`. What is not: **`drone.lua` does not know forms exist** —
  `Drone.on_place` *returns* whether a file is still needed and `register.lua`
  shows the chooser, which is what broke the drone↔formspecs cycle. `F4` must
  respect this: drive the live refresh from the form side reading `drone.budget`,
  not by `drone.lua` calling into forms. `integration_spec`'s "drone seam (A11)"
  section pins the function surface, the form-layer entry points, the prototype
  callbacks, and that the entity caches no drone. **It grew from six cases to
  nine at `1b991ae`**, which added the direction of the seam itself: the entity
  has no `on_step`, the run is advanced from the globalstep, and `on_lost`
  clears only `obj` (`B50`, `B52`).
- **A12 · low · resolved** — no tests, on the component that most needs them.
  Fixed from Phase 0 onward: nine specs, **474 passed / 0 failed / 1 xfail / 0
  xpass** in-engine at `1b991ae`, six of them also standalone under Lua 5.1,
  which is how CI runs them.
  **Keep — what the suite cannot reach, which every feature inherits.** Nothing
  exercises the filesystem, the editor or drone placement: the specs run at mod
  load, before a map, a player or a user directory exists. The 14 movement
  assertions were added because that arithmetic *is* reachable, and still did not
  catch `B27` — they test the four exact facings and the defect was in keys that
  are not exact. **Static counting is unsafe here**: counting `it(` in
  `shapes_spec` gave 4 against a real 15, one `it(` sitting inside a helper.
- **A15 · medium · resolved** — only a fifth of the vendored WorldEdit fork was
  reachable: 448 of 2,299 lines, and the whole dependency was four functions.
  Fixed in Phase 4 with the stronger option — the fork is gone rather than
  trimmed. `shapes_spec` covers the geometry against a stubbed VoxelManip and
  runs standalone, which matters because these were ported by hand.
  **Keep — three things to know before touching `lib/shapes.lua`.** The data
  array is prefilled with `ignore`, which `set_data` leaves untouched, so only
  claimed voxels change. The scratch buffer is **one module-level table reused
  across shapes** — safe because Luanti runs mods on one thread and nothing in it
  has to survive a yield, only its length does. `c_ignore` is resolved on first
  use, since content ids settle only after every mod has registered.
- **A16 · medium · resolved** — `api_spec` was standalone-capable but not run by
  CI. Fixed by `a023ceb`. It matters more than a coverage number because it pins
  every API name explicitly: the change most likely to break every saved player
  program at once was the one change CI could not see, `gen_docs.lua --check`
  checking the description against itself and `api.build`'s bidirectional raise
  firing only in-engine. **Consequence: adding an API name is an `api_spec` edit
  too.**

---

## Evidence: verified, committed, claimed

Never blurred. **Verified** means a run or a reading demonstrates it,
**committed** means the code is there and unproven, **claimed** means only a
document says so.

- **Verified by machine.** CI run 44 at `dc09d48`, all three jobs green:
  luacheck, the six standalone specs under plain Lua 5.1, and both `--check`
  gates — three now, `settingtypes.txt` having joined them. **CI never runs the
  nine in-engine specs**, which is why the editor findings rest on the local
  suite and the playtests.
- **Verified locally** (engine 5.17.0, read from output rather than exit codes —
  `$?` does not survive this machine's WSL layer): nine in-engine specs, **474
  passed / 0 failed / 1 xfail / 0 xpass** at `1b991ae`, with all five gates
  green. The count moved 458 → 471 → 474: 458 was the run after `B47`'s beat
  change and the `settingtypes.txt` generator, 471 added 13 `env_spec` cases for
  `B49`, and 474 added three to `integration_spec`'s drone-seam block for
  `B50`/`B52`.
- **Verified by making the check fail.** Both generators' completeness guards,
  by adding a fake per-codelevel limit to `config.lua` and watching each name it
  and exit 1 (`C20`). That is the only evidence that distinguishes a check which
  passes from one which cannot fail, and the reason `C20` existed unnoticed.
- **Verified in a running world.** All 39 `PLAYTEST.md` checks written before
  `F8` carry a result; see that file for the commit and date on each. Between
  them they confirm `A2`, `A9`, `A11`, `B5`, `B7`, `B10`'s happy path, `B13`,
  `B17`, `B22`, `B29`, `B33` on all three losing paths, `B35`, `B36`, `B37`,
  `B38`, `B39`, `B40`, `B41`, `B42`, `B43`, `B44`, `C10`, `C16`, `C17`, `C18`,
  `S5`'s measurements, `S7`, `F1`, `F2`, `F3` and `F7` — and answer `A4`. The
  group `H` re-run of 2026-09-02 at `8f5bb2e` adds `B45`, `B46` and `F8`, eight
  of its nine checks passing, and `R4` and `F-5` the same day add `S6` twice
  over — the default a fresh world hands out, and every bundled example fitting
  the level a server hands out. **2026-09-03 adds `B48`, through `E16`'s new
  pristine-example case; `C21`, through `F10-1` completed — a fresh
  player joins with neither tool and without `fly`, `fast` or `noclip`; and
  `B49`, through `W4`, the once-per-run warning for an unknown block name.**
  **2026-09-04 adds `B50` and `B52`**, through the whole *Writing to the world*
  group at `23f0227` — six checks, six passes, `W1` at every codelevel and `W5`
  and `W6` for the first time. That run also re-affirms `A4` and `S5`'s timing
  (`W2` and `W3`) and gives `B29`'s serial guard its first evidence in the form
  `1b991ae` left it. **The engine version was not restated for it.**
- **Verified by reading the engine's own source** (`luanti-org/luanti` at 5.6.0,
  5.7.0, 5.8.0, 5.9.0, 5.17.0): the 640 kB formspec-submission cap and the
  version it arrives in (`B40`); `parseScrollBar` and `acceptInput` (`B37`);
  `label`'s `font=bold` and `halign` being area-label only (`F8`); and the whole
  of `B47` — `drawMenu`'s byte-identical short-circuit, `regenerateGui`'s
  `removeAll`, and a button holding `Pressed` on the object that is destroyed.
  **`H10` then confirmed the mechanism from the other end**: `B47`'s residue
  survives a doubled beat, exactly as a window proportional to the beat must.
- **Verified by reading the files themselves.** `B48`'s file-by-file split: all
  fourteen of `lib/examples/` carry CRs, and in the author's world the four
  unmarked files carry none while `plot2D.lua` is byte-identical to the shipped
  example with its 23 CRs intact.
- **Gates green, unproven in a world:** two — `B14`, blocked on `B34` being
  won't-fix, and `S7`'s log line. **`B51` joined it and left it on the same day**,
  2026-09-04: fixed at `8de3cea` and read in a world by `D7` hours later. `B47`'s fix and `F9` both left this list by passing on the
  day they shipped, and **`B48`, `C21` and `B49` all left it on 2026-09-03** —
  `E16`'s new case, `F10-1` and `W4` respectively, and all three fixes are
  committed as well (`4179877`, `b23a8bc`, `d8c32f7`). **`B50` and `B52` left it
  on 2026-09-04**, when all three of the checks written for them passed at
  `23f0227`.
- **Gates green, playtest written and not yet run — none.** `B51` was the last
  entry, its check `D7` written with the fix on 2026-09-04 and run the same day.
  `B50` and `B52` were the two before it, at `1b991ae`, and both left on
  2026-09-04: `W1` at every codelevel, `W5` and `W6` all ran and all passed.
  `B49` left on 2026-09-03 through `W4` at `16cd05c`. **Every check in
  `PLAYTEST.md` now carries a result**, which has not been true before.
- **Explained by reading, confirmed by playing it, fixed, then confirmed again:**
  `B50`. The cause is a reading of the 5.17.0 engine source —
  `serveractiveobject.h:123-129` and `serverenvironment.cpp:1685-1690` for the
  `static_save = false` unload rule. **`W1`'s discriminator run on 2026-09-03
  measured what the reading could not settle**: both chat lines arrived, so the
  announcement path was intact and there was **no fourth finding**; and the
  obsidian stopped at **352 and 320 nodes** across two runs, not the ~192 the
  diagnosis predicted. **The 32-node spread is itself the evidence** — a sampled
  2.0 s race rather than a fixed boundary, ~192 being where the drone becomes
  killable and not where it dies. **Discriminator 3 was not run that day**, so a
  leaked record was *unlikely* rather than ruled out; **the 2026-09-04 run made
  it and ruled it out** — a drone places immediately after the program finishes.
  The gates were green over the fix and always were over the defect, because
  nothing in the suite runs in a world: **what proved `1b991ae` on the day was
  three `integration_spec` assertions about the seam, and what proves it now is
  `W1`, `W5` and `W6` at `23f0227`.**
- **Found by reading, observed broken, then observed fixed — all inside three
  days:** `B51`. It
  was a certainty from the source — two callers passing `'completed'` — and
  `W1`'s discriminator run of 2026-09-03 showed it to a player: *le drone a
  disparu* followed
  by *programme terminé*, about a run killed roughly 48 blocks short of what it
  asked for. **The two lines contradicted each other**, which is the finding. One
  of the two callers went with `B50`'s fix; `Drone.on_remove` now passes
  `'stopped'`. **Both states are observed**: `D7` on 2026-09-04, at `8de3cea`
  plus a comment-only edit, read *stopped* with a partial count and *arrêté* in
  French. No spec asserts what `Drone.finish` sends, so those two runs are the
  whole file on it.
- **Found by reading, never observed broken, observed fixed:** `B52`. Nobody
  reported it — it was `resetUsageTimer` and `Map::timerUpdate` read out of the
  engine with nothing timed against it — and `W5`, its first and only check, ran
  on 2026-09-04 at `23f0227` and passed on both cases. So the **fixed** state is
  measured and the broken one never was, which is the most this finding can have.
  The addition to `B29`'s Keep block was in the same class and is no longer:
  `W6` case 2 observed it.
- **Not verified anywhere, and with no route left:** `B10`'s refusal, twice aimed
  at through `D2`'s second case, which was removed as untestable on 2026-09-02.
  **That is the whole list**, and it is now a standing gap rather than a queued
  check.
- **Unreachable by hand, proven by a spec instead:** that an open drone panel
  describes a replacement drone under the same name rather than the run it was
  opened for (`B29`). Playtest `H8` case 3 asked for it and cannot be performed —
  the panel holds the pointer — so `forms_spec` swaps the record between two
  `get_form` calls.
- **Computed, not measured:** `W3`'s cost breakdown under `S5` — mapblock counts,
  slab geometry and the ~36 MB resident are arithmetic over the source and the
  one measured constant. Only the timing is a measurement — **0.34 s on
  2026-08-28 and 0.27 s on 2026-09-04**, both passes, and the difference is not a
  finding: neither was taken under controlled conditions. **The bundled examples
  fitting codelevel 2 left this list on 2026-09-02**, when `F-5` ran.
- **Recorded as not fitting the model:** `P3`'s pre-fix 160 s, and the post-fix
  23% between 78 s and 95 s. The spans can only multiply to 1, 2 or 4.
- **Observed and unattributed:** at codelevel 1 nothing of the shape appeared
  until the drone stopped, view distance 30; at 500 it was visible as it built,
  so most likely what the client drew. No id.
- **Reported, then disproved:** `E12`'s symptom, three fails and two traces.
  Settled as a pass: no write was happening, and the surprise was an unmarked
  dirty buffer, now `F7`. No id was ever allocated, correctly.
- **Claimed only:** nothing.

## Corrections kept rather than edited away

- `B42` was filed saying every filler already clipped to the area it was handed.
  All three clipped along **z** only; the fix had to widen them first.
- `A11`'s resolution once said `drone_entity.lua` is 55 lines; it was 67, and is
  69 since `1b991ae` — the first figure predated `B29`'s serial parsing.
- `C7`'s resolution once said the settings guard is `rawget(_G, 'minetest')`;
  since `C6` it is `core`.
- `C14`'s keep block once said `gen_docs.lua --check` had never run here. It runs
  at every gate pass, under lua5.1 in WSL — the same toolchain CI uses.
- `B45` first recorded the panel printing *throttled* on the held row. That
  shipped and was dropped the same day; the entry records both.
- `S6` first resolved to 4 in singleplayer. Narrowed to 3 on 2026-08-30.
- `W3`'s cost note once said `cube(215,215,215)` would exceed 1e7. It is 9.94e6
  and fits; `cube(216,216,216)` does not.
- Nine findings were filed with a conclusion later shown wrong or overtaken
  (`C2`, `S2`, `A12`, `B21`, `S4`, `A3`, `B28`, `B29`, `C6`). Each records the
  correction rather than being amended silently.
- Phases were renumbered once, before the scheme was fixed. `43e95a8` still says
  "Phase 5" and still means the committed phase.
- The record was split in two on 2026-08-26, eleven findings moving to the game's
  audit with their ids intact.
- **An id is for a defect in committed code.** A wrong check is a defect in this
  record and is fixed there: playtests `D3` and `F-3` got no ids, and `E12` has
  none after three fails.

---

2026-09-04 · describes codeblock at `8de3cea`, plus this record change and a
comment-only edit in `lib/drone.lua`, both uncommitted at the time of writing.
`origin/master` is at `7dbe18f` and **has seen none of the work since**.
**No finding is open.** `B51` was the last and is fixed at `8de3cea` — a run cut
short now says *stopped* — and its playtest `D7` **passed on 2026-09-04**, engine
version not restated.
**`B50` and `B52` are fixed in `1b991ae` and confirmed in a
running world**: the record and the run were decoupled from the drone's entity,
and the three checks that were the rest of the evidence — `W1` at every
codelevel, `W5`, `W6` — all passed at `23f0227` on 2026-09-04, engine version
not restated. **Gates green, unproven in a world is two**, `B14` and `S7`'s log
half. Gates at `1b991ae` and again at `8de3cea`, same
figures both times, engine 5.17.0, read from output rather than exit codes: luacheck silent,
`doc/api.md`, `locale/template.txt` and `settingtypes.txt` up to date,
`locale/*.tr` covering every message and nothing else, nine in-engine specs
**474 passed / 0 failed / 1 xfail / 0 xpass** — the xfail `preprocess_spec`'s and
pre-existing — and six standalone under Lua 5.1. **CI has seen none of it.** It
was last green on all three jobs at `dc09d48` (run 44) and `471526e` (run 45), so
everything from `d8d44cd` up carries local gates only, and `HEAD` is ahead of
`origin/master`.
