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

**76 findings. 74 resolved, 1 open (`B47`), 1 won't fix (`B34`).**

| Category | Count | Open |
|---|---|---|
| B bugs | 44 | `B47` (`B34` won't fix) |
| S sandbox and security | 7 | — |
| C compliance and packaging | 13 | — |
| A architecture and performance | 12 | — |

All code pushed, and **CI green on every commit through `471526e` (runs 44 and
45, all three jobs each)** — so the limit retuning, `F9` and the paused clock are
covered by CI, not by local gates alone. `dc09d48` is the last commit to touch
code, which is the one to compare a later run against; a record commit's own run
can never be named in it. Nine in-engine specs at `dc09d48`: **458 passed / 0 failed / 1 xfail / 0 xpass**,
up from 439 as `F9`, `H8`'s displaced case and the paused clock added nineteen to
`forms_spec` — re-run 2026-09-02 with luacheck and both `--check` gates over each
of those, all four green each time. **Re-checked at `7dbe18f`**, the current head
and record-only: luacheck silent, both `--check` gates up to date, six standalone
specs **238 passed / 0 failed / 1 xfail** under Lua 5.1.

Every defect the playtests found is fixed except `B47`, which the 2026-09-02
group `H` re-run filed and whose mechanism is now read out of the engine source
rather than suspected. That run also **confirmed `B45` and `B46` fixed in a
world** and proved `F8`'s display work. The one thing **not verified anywhere** is
`B10`'s refusal, aimed at twice through playtest `D2` and missed twice —
the recipe is the suspect and its check was removed as untestable on 2026-09-02.
**Gates green, unproven in a world:** `B14`, permanently blocked on `B34` being
won't-fix, and `S7`'s log half — the two left. `F9` passed the same day it
shipped, including the paused clock reversed out of that very run, as did `R4`
and `F-5`, which takes `S6` and the retuning's effect on the bundled examples off
this list too.

---

## Open

**One open: `B47`.** `B34` is the one won't-fix.

### B47 · medium · open — a button on the drone panel needs a second click

From playtest `H2`–`H7`, 2026-09-02 at `8f5bb2e`: *"buttons on the drone panel may
be a bit unresponsive at times (second click needed)."* Not reproducible on
demand, and no spec can see it — the four gates exercise the handlers, not the
client's menu.

**The cause is the panel's own refresh, and the mechanism is now read out of the
engine** (5.17.0 source, not `lua_api.md`, which describes none of this). The
panel is the one form here that redraws itself unprompted: `formspecs.tick`
re-sends the whole formspec through `core.show_formspec` every `PERIOD` (0.5 s in
`lib/hud.lua`), on the same beat as the HUD. The chain from there:

1. `GameFormSpec::showFormSpec` → `GUIFormSpecMenu::create`, which for a menu
   already open takes its `else` branch and only swaps the form *source*
   (`src/client/game_formspec.cpp:235`, `src/gui/guiFormSpecMenu.cpp:142`).
2. `GUIFormSpecMenu::drawMenu` then compares the new string with the one it holds
   and **does nothing at all if they are byte-identical**; otherwise it clears
   `m_is_form_regenerated` and calls `regenerateGui`
   (`guiFormSpecMenu.cpp:3691`).
3. `regenerateGui` preserves table state and the focused element *by field name*,
   and then calls `removeAll()` → `removeAllChildren()`: every element in the
   form is destroyed and built again (`guiFormSpecMenu.cpp:3161`, `:3057`).
4. A button records its own press **on the object**. `EMIE_LMOUSE_PRESSED_DOWN`
   sets `Pressed = true`; `EMIE_LMOUSE_LEFT_UP` sends `EGET_BUTTON_CLICKED` only
   if `wasPressed` was true (`guiButton.cpp:185`–`228`). The replacement button
   has `Pressed = false`, so the release arrives at a button that was never
   pressed, no event is sent, and nothing anywhere reports it.

So the dead window is **the player's own click hold**: a ~100 ms press against a
500 ms beat loses roughly one click in five. `on_close` never runs, so no amount
of work in the handler can see it, and the four gates cannot either — they call
the handler directly.

**What this rules out, and what it changes about the fix.** It is not focus:
focus *is* carried across a regeneration, which is why the "no text field, so a
redraw costs no input focus" reasoning was true and still missed this. Input
focus and a press in flight are different questions.

And *"refresh only when a drawn number changed"* is already the engine's own
behaviour, from step 2 — which is why the **idle** and **no-drone** panels never
lose a click: their string is constant, so the tick regenerates nothing. During a
run the string moves on nearly every beat, and `F9`'s elapsed clock is what makes
a **paused** panel move too, where before it stood still. The direction is
therefore not *detect* a change but *make the string change less often*.

Four directions, none chosen:

- **Slow the beat** — shrinks the window proportionally, removes nothing.
- **Quantise what is drawn** so the string is stable across several ticks.
  Bounded by the elapsed second, which changes on its own.
- **Stop the self-refresh**: a static panel with an explicit refresh, the live
  figures left to the HUD, which never touches the menu. Kills the defect and
  costs the liveness `F8` wanted.
- **Act on mouse-down instead.** `GUITable::OnEvent` selects and sends
  `EGET_TABLE_CHANGED` while `isLeftPressed()` (`guiTable.cpp:870`–`930`), so a
  `textlist` row is immune to this window entirely — the same legacy element the
  editor's block picker was forced onto for its own reasons. Poor shape for
  *Pause* and *Stop*, but it is the one element here that cannot lose a click.

**Keep — the reason a live formspec was affordable here at all.** The panel has no
text field, so a redraw costs no input focus (unlike the editor, which is why it
is never refreshed under the player). Input focus and *button presses* turn out to
be different questions, and only the first was considered.

### B34 · low · won't fix — a file cannot be removed without opening it first

`lib/formspecs.lua`: all four file buttons are built inside the
`meta.active ~= 0` block, so with no file open the editor offers no way to act on
a file. Three of the four belong there; *Remove file* does not, since it could
act on the selection. **The author's decision: "won't fix now, not really
needed"** — there is a working route (open it, then remove it).

Its permanent second effect is why it was filed: **`B14`'s cold-cache removal
path can never be reached from the editor**, since opening a file populates the
cache. Playtest `E2` carried that as a permanent partial until 2026-09-02, when
the half was removed as untestable and `E2` became the pass it actually is; the
only route left to `B14` is removing a file immediately after a rejoin.

**Keep — the fix's shape, so it is not re-derived.** Move *Remove file* out of
the block, alongside the help-panel switches already outside it, and act on the
file-list selection rather than `meta.tabs[meta.active]` — which makes "remove a
file open in a tab" and "remove one that is not" two cases. Whether a delete
should confirm is a separate question.

---

## B · Bugs

44 findings, 42 resolved, `B47` open, `B34` won't fix. `B19`, `B20`, `B24` are
the game's.

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
  identity. `on_step`'s hole is the more damaging half: a deferred entity can be
  stepped once and would spend its replacement's budget, mis-charging a running
  program rather than visibly killing an idle drone. Three `integration_spec`
  assertions pin it, the third in `pcall`. Anything reading a drone by name from
  a callback — `F4`'s panel — is subject to this. Confirmed by playtest `D3`
  part 2.
- **B30 · low · resolved** — `on_lost` reported the end of a program that was
  never running. A regression from `A11`. Fixed in `7d9ca47`: `on_lost` tests
  `drone.cor` and, with no coroutine, removes the record and says nothing.
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

13 findings, all resolved. `C2`–`C5` and `C15` are the game's; `C9` never used.

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
  1.60 MB → 1.42 MB. `screenshot.png` is kept with an explicit `-export-ignore`,
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
  callbacks, and that the entity caches no drone.
- **A12 · low · resolved** — no tests, on the component that most needs them.
  Fixed from Phase 0 onward: nine specs, **458 passed / 0 failed / 1 xfail / 0
  xpass** in-engine, six of them also standalone under Lua 5.1, which is how CI
  runs them.
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
  gates. **CI never runs the nine in-engine specs**, which is why the editor
  findings rest on the local suite and the playtests.
- **Verified locally** (engine 5.17.0, read from output rather than exit codes —
  `$?` does not survive this machine's WSL layer): nine in-engine specs, 453
  passed / 0 failed / 1 xfail / 0 xpass at `cd13414` plus the uncommitted `H8`
  cases.
- **Verified in a running world.** All 39 `PLAYTEST.md` checks written before
  `F8` carry a result; see that file for the commit and date on each. Between
  them they confirm `A2`, `A9`, `A11`, `B5`, `B7`, `B10`'s happy path, `B13`,
  `B17`, `B22`, `B29`, `B33` on all three losing paths, `B35`, `B36`, `B37`,
  `B38`, `B39`, `B40`, `B41`, `B42`, `B43`, `B44`, `C10`, `C16`, `C17`, `C18`,
  `S5`'s measurements, `S7`, `F1`, `F2`, `F3` and `F7` — and answer `A4`. The
  group `H` re-run of 2026-09-02 at `8f5bb2e` adds `B45`, `B46` and `F8`, eight
  of its nine checks passing, and `R4` and `F-5` the same day add `S6` twice
  over — the default a fresh world hands out, and every bundled example fitting
  the level a server hands out.
- **Verified by reading the engine's own source** (`luanti-org/luanti` at 5.6.0,
  5.7.0, 5.8.0, 5.9.0, 5.17.0): the 640 kB formspec-submission cap and the
  version it arrives in (`B40`); `parseScrollBar` and `acceptInput` (`B37`);
  `label`'s `font=bold` and `halign` being area-label only (`F8`).
- **Gates green, unproven in a world:** `B14`, blocked on `B34` being won't-fix;
  `S7`'s log line; and **`F9`**, which is words and placement only, so the suite
  reaches none of it by construction.
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
  one measured constant. Only the 0.34 s is a measurement. **The bundled examples
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
- `A11`'s resolution once said `drone_entity.lua` is 55 lines; it is 67 — the
  figure predated `B29`'s serial parsing.
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

2026-09-02 · describes codeblock at `dc09d48`, the last commit touching code,
pushed · CI green there (run 44, all three jobs) and at `471526e` (run 45), so
the limit retuning (`96dd4bc`), `F9` and the paused clock are all covered by CI.
