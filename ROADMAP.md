# Roadmap — CodeBlock

What to do next, and **what has been agreed** — a feature's shape as settled, a
part argued out, a default chosen. Those decisions are recorded nowhere else: git
holds the code and `CHANGELOG.md` holds what shipped, but neither says why a
question is settled. Compressed as it grows; only the minimum past information
stays.

Findings and their reasoning are in `AUDIT.md`. Manual checks are in
`PLAYTEST.md`. Intentions not yet planned are in `TODO.md`.

Phases are `Phase 0`–`Phase 10`, features `F1`–`F9`, findings `B`/`S`/`C`/`A`.
**Nothing is ever renumbered.**

Three releases, settled 2026-08-28. **`Phase 8` is v1.0.0** — a correct sandbox,
no unmaintained dependencies, documentation generated from the code, tests enough
that changes are safe; major, because several changes break saved player
programs. **`Phase 9` is v1.x.y**, features and defect work after the release.
**`Phase 10` is v2.0.0**, the Blockly editor and nothing else, because it needs
thinking rather than a queue position.

## Now

**Group `H` was re-run on 2026-09-02 at `8f5bb2e`: eight pass, one partial.**
`F8`'s display work is proven in a world and `B45` and `B46` with it. Code is
still `60dc8dd`, CI green there (run 42, all three jobs). What the run left:

1. **`F9`** — the three display changes it asked for, specified under *The
   features* and not started.
2. **`B47`** — a panel button sometimes needing a second click, the only open
   finding. The suspect is the panel's own 0.5 s refresh, not the handlers.
3. **`settingtypes.txt`'s generator and `--check`**, decided yes 2026-08-28. The
   third hand-kept mirror and the only one without one.

Plus two checks from the 2026-08-30 retuning, neither run: **`R4`** (the default
codelevel on a fresh world) and **`F-5`** (every bundled example completing at
codelevel 2).

**The run also retuned two limits** — under *Other decisions worth not
re-litigating*. Uncommitted in the working tree at the time of writing, with the
three mirrors moved with it.

**The lesson group `H` produced, twice over.** `F4` shipped with four green gates
and the first ten minutes in a world found two defects — `B45` and `B46`, both
about what the display *said* rather than what it computed, and neither reachable
by any spec. `F8` rewrote enough of `F4` that a pass in that first run meant *it
did what was asked*, not *it is settled*. The re-run of `F8` then did the same
thing again at a smaller scale: the behaviour passed everywhere and the **words**
were wrong in three more places (`F9`), plus one thing no spec could ever see
(`B47`). **Displays are the part of this mod that only playing can check**, and a
second playtest of a rewritten display is not a formality.

**The 2026-08-30 retuning.** The per-codelevel limits changed, the bundled
examples shrank to fit codelevel 2, and the singleplayer default moved 4 → 3. The
reasoning is under *Other decisions worth not re-litigating*. It invalidated one
recorded result: `W3` measured `cube(200,200,200)` at codelevel 3, where the
ceiling is now 1e6 and that shape is refused — the measurement stands, the level
it is reproducible at is now 4.

**Two loose ends, neither blocking.** `S7`'s log line is unlooked-at — one grep of
`debug.txt`, next time an unreadable file is to hand. And `P3` left a 23% gap
unexplained, 78 s against 95 s across two of four facings; the emerge multipliers
can only be 1, 2 or 4, so it is not `B43` returning.

## Milestones

Phases 0–7 are closed; one line each, with the findings they covered.
`AUDIT.md` holds the reasoning.

- **0 · Make change safe** — done (2/2). Run on the current engine, put the
  riskiest code under test, restore linting. (C8, A12)
- **1 · Ship the compliance fixes** — done (4/4). The ContentDB version ceiling
  gone, licensing settled, the user-visible command and editor bugs fixed.
  (C1, B5, B8, B9)
- **2 · Rewrite the sandbox preprocessor** — done (11/11). Instrumentation over a
  token stream, per-run environment snapshots with unassignable API names, the
  blacklist retired to a diagnostics aid, the string metatable bounded.
  (B1–B4, B6, B23, S1–S4, A10)
- **3 · Replace ActiveFormspecs** — done (3/3). The last unmaintained dependency
  gone, and with it the only code patching the engine namespace; documentation
  generated from `lib/api.lua` landed alongside. (A1, A2, B22)
- **4 · Performance** — done (4/4). The drone builds at the speed the hardware
  allows, bulk shapes are one VoxelManip pass each, the WorldEdit fork is gone.
  (A5, B12, A4, A15)
- **5 · Limits that track real load** — done (4/4), `43e95a8`. Gave each limit a
  resource to stand for, made the step budget a shared pool, added
  `settingtypes.txt`. (S5, S6, C7, C13)
- **6 · Limits for what the server spends** — done (3/3), `2647228`. Eleven proxy
  limits became seven real ones, each in a unit a player reads, converted once in
  `lib/limits.lua`. (B25, B26, C14)
- **7 · Clear the way for features** — done (26/26), `742a1ca`–`191b533`. Removed
  the duplication that made every feature cost more than it should. Two reviews
  of the range then opened seven findings, five of them regressions the phase
  itself introduced. (A3, A6, A9, A11, A16, C6, C10–C12, B7, B10, B11, B13–B18,
  B21, B27–B32, C16)

"Done" through Phase 7 means the findings are closed and the gates green, **not**
that the editor and drone paths were exercised by hand. Phase 8's playtests have
since found **twelve** defects in code earlier phases called done (B36–B44, C17,
C18, S7) — the newest of them were the largest. **All twelve are fixed.**

### 8 · Features for v1.0.0 — 6 of 7 shipped, 18 findings, 1 open (`B47`)

The last phase before v1.0.0 and the only one that adds rather than repairs.
Started as seven features: `F6` moved out on 2026-08-28 (Blockly is `Phase 10`)
and `F5` was **dropped unbuilt on 2026-08-29** — *"not very interesting in the
end."*

Shipped: `F1` `500dd85`, `F2` `dee0bc7`, `F3` `90cfb70`, `F7` `afbe504`,
`F4` `729c255`, `F8` `d619fba` revised `60dc8dd`. **`F9` was added on 2026-09-02**
out of `F8`'s playtest, the second time a feature here has come from playing the
one before it.

Left in the phase: `F9`, `B47`, `settingtypes.txt`'s `--check`, `R4` and `F-5`,
and **`D2` case 2** — the last half nothing has exercised, needing a way to
observe the server has released a mapblock rather than another session. (B10)

Also standing, and unchecked by anything: **keep `CONTENTDB.md`'s *Recent
changes* current at each release.** It is a hand-kept summary of `CHANGELOG.md`
— the same family as `doc/api.md` and `locale/template.txt`, and it will drift
the same way. The release skill names it as a step, which is a note about
remembering, and this project's own lesson is that those do not hold. (C19)

### 9 · v1.x.y — features and defects after the release

**Allocated 2026-08-28.** Everything that is not 1.0.0 and not Blockly: features
too late for the release, defects the release turns up, and the playtest groups
only a shipped version can reach. **No fixed content on purpose** — a phase for
what comes back from players is worth more empty than filled in advance.

The one thing already in it: **the first release under real use is where a finding
series meets people who did not write it.** Everything in `AUDIT.md` was found by
the author, one reviewer or one spec. That is a narrow sample.

### 10 · v2.0.0 — the Blockly editor

**Allocated 2026-08-28.** `F6` alone, and a major version because it is the change
that most plausibly breaks how a program is stored and edited. Its four obstacles
are under `F6` and **none has an answer yet**. The author's framing is the point:
*time to plan and think*, not a queue position. **Do not start building it because
the phase exists.**

## The features

Ids are quotable in commit messages and never renumbered. A shipped entry keeps
only the constraints a future change would re-break; the survey of options that
led to it is in git and `CHANGELOG.md`.

### F1 · small · shipped `500dd85` — the default block for a bare `place()`

The player picks a default in a Settings panel in the editor, stored per player
under `codeblock:default_block`; a program overrides it for its own run with
`default_block(block)`. **Two levels deliberately:** *what do I usually build
with* belongs to the player and outlives the session; *what does this program
build with* belongs to the program and travels with it when shared.

**Agreed, and load-bearing.**

- **The picker is a `textlist`, not item rows in a `scroll_container`.** The
  editor formspec is in **legacy coordinates**, where a `scroll_container` maps
  its contents into a different space and clips them to its own rectangle, and an
  `item_image_button` inside one gets a hit area that does not match where it is
  drawn. The help panels get away with a container only because `item_image`
  takes no clicks. Do not "restore" the item-row plan without first converting
  the whole editor to the new coordinate system.
- **A legacy button's `W` is not a width.** From `src/gui/guiFormSpecMenu.cpp` at
  5.17.0: a `button` gets `geom.X = W*spacing.X - (spacing.X - imgsize.X)` while
  a `textlist` gets `geom.X = W*spacing.X`, with `spacing = imgsize * 5/4`. So a
  button is short by a fixed **0.2 units whatever `W` is** — the offset does not
  scale. Hence `F2`'s *Create a copy* is `3.2` against a 3-wide file list and `+`
  is `0.95`. `H` is not a height either: the height is fixed and `H` only shifts
  it down. **`lua_api.md` records none of this**, so the reference cannot settle
  a misalignment here.
- **One panel, not a second form.** `lib/forms.lua` holds one form per player, so
  a settings form would displace the editor. Every future setting adds a row here.
- **Not privileged, unlike everything beside it.** Codelevel is privileged
  because it bounds resource use; block choice does not — stone and red wool cost
  the server the same. `air` is selectable, so a bare `place()` can erase.
- **The preference is read once per run** into `drone.default_block`, so a mid-run
  change cannot split one build between two blocks. **The read validates through
  `blocks` and falls back to stone** — meta outlives a palette change, and
  validating *through* `blocks` rather than around it is what stops a default
  arriving from a form becoming a way to place any node name. Because the
  fallback is mandatory, **no init line was added** to the meta block in
  `lib/register.lua`, unlike its neighbours. **Meta is written on click**, not on
  form close, which kept the preference immune to `B33`.
- **Argued out: a `persist` flag on `default_block()`.** It would be the only API
  call whose effect outlives its run; a shared program would silently rewrite the
  reader's saved preference with no undo; in a loop it is a meta write per
  iteration from inside a budgeted run; and no spec could reach it. If
  persistence from a program is ever wanted it gets its own command.

Both `PLAYTEST.md` checks passed at `246bb37`.

### F2 · small · shipped `dee0bc7` — open a copy of a program

*Create a copy* writes what is on screen to a derived name and opens it. Plus,
asked for after the first playtest: the file list sorts `foo_2` before `foo_10`.

**Agreed, and load-bearing.**

- **The naming derivation.** `foo.lua` → `foo_1.lua` → `foo_2.lua`, first free
  *N* up to 99. **Numeric because the author asked for it explicitly:**
  language-agnostic, so the name does not depend on the server's locale. **Strip
  a trailing `_%d+` before appending**, and never widen either strip to match
  mid-name — both are anchored to the end. The first implementation used `_copy`
  and took the whole stem, so the previous suffix became part of the next base;
  since the base is also what gets trimmed to the 15-character limit, each round
  both nested and lost a character. Trimming the suffix instead is not an option
  — it hands back the original name for any stem already at the limit.
- **Two behaviours are deliberate.** A freed number is reused. And a name already
  at the limit shifts base at the tenth copy, so copying *that* starts a new
  family; fixing it would let copies past the length rule every other filename
  obeys.
- **Scope.** Bottom-left, **not** the Save/Remove/Close row — that row already
  runs to `x=14.08` against a help row starting at 14. The copy contains **what
  is on screen, not what is on disk**. The name is **derived, not typed**. The
  drone's file chooser does not get the button.
- **Argued out:** saving the original before copying — a copy is a copy; and a
  `filesystem.copy_file` helper — a copy is a derived name plus `write_file`,
  already the module's one write path, so a helper called from one branch would
  hide ownership of a write.
- **The natural sort key** lives in `lib/filesystem.lua` and prefixes each digit
  run with its own length (`('%03d'):format(#digits) .. digits`), so `foo_2`
  precedes `foo_10` **without guessing a padding width**. The key is injective,
  so no tie-break is needed. The drone's file chooser reads the same `ud.list` —
  one sort, two consumers, which is why the key belongs in the filesystem layer.

No spec reaches it and none was added: `forms_spec` stubs `core.show_formspec`.
Evidence is `PLAYTEST.md` `E13`, pass.

### F3 · medium · shipped `90cfb70` — `sleep(seconds)`

Parks the drone and hands the step back, so a program builds at a pace it chooses
rather than the codelevel's. Defaults to one second, takes fractions. The
mechanism was already there — `drone.wake_at`. **Named `sleep`, not the `wait`
first specified.**

**Agreed, and load-bearing.**

- **The risk was wall time, not CPU, and it is answered by charging up front.**
  `max_runtime_s` charges the time a *step* spent, so a sleeping drone is charged
  nothing and an unbounded wait would let a program live for ever holding a
  record, an entity and a slot in the shared pool. The wait is charged *before*
  it starts: `sleep(1e9)` puts the run past its ceiling and the stepper reports
  the same timeout a program that never finishes gets. **That is
  `max_runtime_s`'s one exception** — it now bounds time the program did not
  spend on CPU — and both places it is documented say so.
- **Argued out: a per-codelevel cap on `sleep`.** The up-front charge bounds it
  without another limit, mirror row or documented row.
- **Argued out: routing it through `end_command`.** That writes `wake_at` from
  `pace_ms` and the last writer wins. **A sleep is not a command:** it pays no
  pace and is not counted as one.
- **It must keep yielding through `release()`** — the only `coroutine.yield` in
  `lib/cost.lua`, which clears the mapblock memo first. Yielding any other way
  reintroduces `B25`'s silent lost write.
- **Adding a name is breaking even though nothing was renamed.** `env.new_env`
  raises on assignment to any name the API defines, so a saved program using
  `sleep` as its own global now fails on that line. The edit spans `lib/api.lua`,
  `impls` in `lib/sandbox.lua`, regenerated `doc/api.md` and `api_spec`'s name
  list.

`PLAYTEST.md` `F3` passed at `246bb37`.

### F4 · large · shipped `729c255` — a live drone panel

Two surfaces, because one cannot do the other's job. A **HUD** carries the live
read-out while a program runs; a **formspec panel** carries the per-limit
breakdown and the buttons.

**Merged from three `TODO.md` lines, because they are one feature:** the drone
info UI, "show the program's budget while it runs", and the player-side half of
"option to pause the drone" (the in-program half is `F3`).

**Settled 2026-08-28.**

- **A HUD cannot carry buttons, and that is what splits the feature.** 5.17.0 has
  nine element types — `image`, `text`, `statbar`, `inventory`, `hotbar`,
  `waypoint`, `image_waypoint`, `compass`, `minimap` — none is a button, and **no
  HUD click callback exists anywhere in the API**.
  `register_on_player_receive_fields` is formspec-only; `get_player_control` is
  key *state*, not a click target.
- **The HUD is nevertheless right for the read-out.** `hud_change(id, stat,
  value)` updates one field: no formspec string, **no input focus reset**, and it
  does not go through `lib/forms.lua`, so it does not collide with the
  one-form-per-player rule. The editor can stay open with the HUD live over it.
- **It shows only while that player's own drone is running.** A permanent status
  area is decoration, and decoration imposed on every game that installs this mod
  is exactly the `C18` shape.
- **Player toggle over a server default.** A `flag` in `lib/config.lua`,
  overridden per player in meta — read with `get_string`, because `get_int`
  cannot tell an unset key from a stored `0` (`B5`).
- **Pause is not `wake_at`.** Reusing it would clobber a pending `sleep()`:
  resuming sets `wake_at = nil` and the drone wakes early. A separate
  `drone.paused`, checked in `stepper.awake`, leaves a sleeping program's own wake
  time intact — and a paused drone already takes no share of the step pool.
- **Do not reintroduce the dependency `A11` removed.** `lib/drone.lua` does not
  know forms exist and must not learn that a HUD exists either. Drive both from
  the other side, reading `drone.budget`.
- **Stop must go through `Drone.finish`**, the single place an outcome is
  announced, or the player gets two messages or none (`B12`, `B30`). Anything
  reading a drone by name from a callback must respect the **serial guard**
  (`B29`): read the record fresh — a panel that caches a drone table across
  redraws hits exactly that, and so does a panel left open while its run ends.

**Argued out, so it is not proposed again.**

- **A Start button.** Duplicates the poser's left-click and doubles the entries
  into `get_safe_coroutine`.
- **An admin view of another player's drone.** No one asked, and it adds a
  privilege surface to a feature that otherwise has none.
- **A `statbar` for the percentage.** It needs a texture pair and draws in
  half-image steps; a coloured `text` says the same thing to the pixel.
- **A live-refreshing panel that reproduces the HUD.** The panel refreshes on the
  same tick but does not duplicate the HUD's job. Two surfaces, one each.
- **Two destructive buttons.** *Cancel* and *Remove drone* shipped side by side
  for one afternoon and were **the same `Drone.on_remove` call** under different
  labels. The author asked what the difference was; there was none. **A second
  button that offers a distinction the code does not make is worse than no
  button.**

### F5 · large · dropped 2026-08-29 — change a codelevel while a program runs

**Cut by the author, unbuilt:** *"not very interesting in the end."* `F4` covers
the watching half of what it was for. Kept because two of its rules outlive the
feature, and because a feature with no recorded reason for its absence gets
proposed again.

- **Codelevel is privileged, and this is the feature most able to break that.** An
  intermediate version once removed privs so players could set their own level — a
  privilege escalation, reverted before it shipped (`B9`). If a codelevel control
  is ever exposed in `F4`'s panel it must be privilege-gated **per press, not per
  form**.
- **The subtler hole is the counters, not the privilege.** Rebuilding the budget
  from a new codelevel mid-run **must carry `used` across**; a rebuild that resets
  it turns re-levelling into a way to spend `max_nodes_written` or
  `max_runtime_s` twice over — a limit bypass through a legitimate command.

### F6 · Phase 10 / v2.0.0 · planned — Blockly web-based editor

Build programs by dragging blocks in a browser instead of typing Lua.

**Settled 2026-08-28: `F6` is `Phase 10` and v2.0.0.** The author's reason is that
it needs thinking rather than scheduling: *"Blockly will be 2.0.0 so I have time
to plan and think."* Four obstacles, none of which has moved:

- **This mod has no HTTP allowance and cannot give itself one.**
  `core.request_http_api` only returns a table for a mod named in the server's
  `secure.http_mods` or `secure.trusted_mods` — the administrator's setting, not
  something a ContentDB package can arrange. **A feature that silently does
  nothing on a correctly configured server is worse than one that is absent.**
- **Mod security blocks the write side.** A mod may not write into its own
  directory, so generated Lua would land in the player's file area through
  `lib/filesystem.lua`, which has no spec coverage.
- **The assets have to come from somewhere.** Blockly is JavaScript and the engine
  has no browser. Either the player loads a page hosted elsewhere — a third-party
  runtime dependency for an offline single-player game, and a licensing and
  privacy question under AGPL-3.0-only — or something in-tree serves it, which is
  a server this mod does not have.
- **What would settle feasibility:** one written-down answer to *where do the
  assets live and who allows the HTTP call*, before any code.

### F7 · small · shipped `afbe504`, confirmed by `E16` — show which tabs are unsaved

A tab whose buffer differs from what is on disk gets a trailing `*`.

**Why it exists.** `E12` failed three times and was traced twice for a write that
was never happening. What the player saw each time was the unsaved edit surviving
a tab switch — correct — and then vanishing on ESC, also correct with *Save on tab
switch* unticked. The sequence is only surprising because nothing said the buffer
was dirty.

**The alternative stays rejected.** Resetting the text area to the file's content
on a tab switch would make the state visible by throwing the player's typing away.
That is exactly `B35`. **Do not gate the capture again.**

**Constraints.**

- **The marker is render-only.** `meta.tabs[i]` holds the filename `write_file`,
  `read_file` and `remove_file` are handed; a `*` appended there would create a
  file named `foo.lua*`. Decorate the label as the `tabheader` is built and
  nowhere else.
- **A flag, not a diff against a kept pristine copy** — chosen by the author: one
  boolean per tab against doubling the editor's memory for a cosmetic mark.
  `meta.dirty` is a third array beside `meta.tabs` and `meta.contents`,
  maintained at the same four sites and **kept dense rather than sparse**, because
  `table.remove` on a table with nil holes has no defined behaviour in Lua 5.1.
- **The flag cannot be set from `fields.content` *arriving*** — the textarea
  reports itself on every submit, so that would mark every tab on the first button
  press. It is set from `fields.content ~= meta.contents[active]`, compared before
  the buffer is overwritten. So the mark means *differs from what was last
  written*, not *differs from disk*: type a character and undo it and the tab
  stays marked, which is the harmless direction.
- `save_active` clears the flag **only on a write that happened**: a refused save
  leaves the buffer differing from the file, which is what the mark is for.

### F8 · medium · shipped `d619fba`, revised `60dc8dd`, playtest due — make the drone panel readable

Everything `F4`'s first playtest asked for, in one feature because all of it edits
the same two surfaces: the two findings that session filed (`B45`, `B46`) and the
changes it asked for, then two more passes from screenshots.

**Settled, and load-bearing.**

- **The panel is unconditional and the setter's left click means *drone info***
  — from `H4` and `H8`. No two-meanings-by-state: click, get the panel, and if
  nothing is running it says so. **An effect that depends on state the player
  cannot see is one they have to guess at, and the guess destroyed builds.**
  `on_punch` was considered and rejected: a stray punch destroying a long build is
  the objection that moved Cancel into the panel to begin with.
- **One destructive button.** *Cancel* and *Remove drone* were the same call; they
  are now **Stop**, with **Pause/Resume** beside it and closing moved to an `x` at
  the top right.
- **Hard limits only, three rows.** The map footprint is a throttle that sits at
  its ceiling by design (`B45`); listing it beside three ceilings that do end a
  run invites exactly the misreading. The *Will stop on: …* summary line is gone —
  the binding limit is shown by colouring its percentage **amber**, with **red**
  at 80% or more, so there is either nothing to look at or one thing.
- **Layout, from the author's screenshot.** The limit name is **bold** and shares
  its left edge with the description; the description is an **area label**
  (`label[x,y;w,h;text]`), which the engine wraps and gives no scrollbar, because
  the single-line version was cut off at the panel edge in French.
- **Long numbers get `K`/`M`/`G`** and every row its own percentage, threshold
  10 000 so a small count still reads as a plain integer.
- **Every limit gets a describing line** — where `B46`'s fix lands. This is the
  panel earning its space over the HUD: the HUD is four words and a number, the
  panel can afford a sentence.
- **The panel's heading is bold, its state coloured** — settled 2026-08-30:
  `running` **green**, `paused` **yellow**, deliberately neither of the amber and
  red used on the rows below. **One colour meaning two things on one form is worse
  than no colour.** Built by **concatenation**, not from the `S('@1 : @2')` key
  the HUD still uses, because only half the line is coloured. `lua_api.md` permits
  exactly that — *"string concatenation will still work as expected (note that you
  should only use this for things like formspecs) … and operations such as
  `core.colorize` which are also concatenation"*. A label's `font` is **per
  element**, so the state is bold too; splitting it would need a second label at a
  guessed x, nothing in Lua being able to measure rendered text. `bold` is a
  documented `font` value for `label` (a *font modification option*), and `halign`
  works on labels **only** in the area-label form.
- **The HUD is a five-line block** hanging from the top-right corner:
  `<file> : running` in bold, `Budget usage`, then `Blocks: n%`, `CPU: n%`,
  `Memory: n%`, with the same colour rule as the panel. The `- ` prefixes and the
  heading's `:` were dropped on 2026-08-30 — a fixed-width corner block three
  items long is already a list. **The two-line version that named only the binding
  limit is gone**: naming one was meant to teach which resource a program spends,
  and in a world it only meant the other two were invisible while the answer was
  nearly always the same.
  Three facts made it cheap: a HUD `text` element has a **`style` bitfield**
  (1 bold, 2 italic, 4 monospace); colour is per element through `number`, which
  every client honours, so **one element per line** gives per-line colour without
  `core.colorize` and its protocol-44 floor; and `alignment = {x = -1, y = 1}`
  hangs the block down-and-left from the corner.
- **The HUD gets its own short names** — `Blocks`, `CPU`, `Memory` — and that
  duplication is deliberate: the panel's row is a heading over a sentence, the
  HUD's is one line of five. `Server time used` earns its length beside an
  explanation; on the HUD it would be the whole line.
- **The three preference checkboxes moved onto the *Settings* panel**, beside the
  default-block picker, from the editor form's bottom edge.

**Playtested 2026-09-02 at `8f5bb2e`, group `H`: eight pass, one partial.** Every
point above is confirmed in a world, and `B45` and `B46` with them. The run asked
for three more display changes, which are `F9`, and filed `B47`.

**Constraints.**

- **The editor form is legacy coordinates and the panel is `formspec_version[4]`.**
  Work inside the editor is subject to the button-width and `scroll_container`
  traps in `CLAUDE.md`; the panel is not.
- **`limits.report` and `limits.binding` stay pure functions of `caps` and
  `used`** so `limits_spec` keeps pinning them. `K`/`M`/`G` formatting is
  presentation and belongs with the display — `lib/limits.lua` converts units, it
  does not choose words.
- **The panel tick must check the session is still the panel's.** `lib/forms.lua`
  is one form per player, so opening the editor over an open panel silently
  replaces the session; the tick compares the stored meta table against
  `forms.get_meta(name)` before redrawing. Pinned by `forms_spec`.

### F9 · small · specified, not started — say the state and the time in the same words

From the group `H` re-run of 2026-09-02, in the same relation to `F8` as `F8` was
to `F4`: the behaviour passed, and playing it showed three things the words get
wrong. All three are on the two surfaces `F8` owns, so they are one feature.

**Asked for, and the reasoning.**

- **The HUD's `CPU` becomes *CPU time* / *Temps CPU*.** `CPU` alone reads as a
  load percentage, which is the misreading `B46` was filed for one word further
  along. It costs a line on a five-line block, and the block is fixed-width
  already. `F8`'s short-names decision stands otherwise — `Blocks` and `Memory`
  do not become sentences.
- **The idle panel reads `<program> : inactif`**, filename bold and state
  coloured, replacing the sentence `Drone idle, holding @1`. One panel telling
  two states in two shapes is what it looks like today. The colour is a third
  one, neither `RUNNING_COLOUR` nor `PAUSED_COLOUR` carrying a meaning that fits
  *idle* — and `F8`'s rule holds: one colour meaning two things on one form is
  worse than no colour.
- **The panel heading carries the run's clock time** —
  `<program> : <state> (<duration>)`, the duration **not** bold. Nothing on
  either surface says how long a run has been going: *Server time used* is
  deliberately not that number, which is the whole of `B46`, and after it the
  player has no way at all to ask *how long has this been building*. So this is
  `B46`'s missing half, not a duplicate of it.

**Constraints.**

- **The heading is built by concatenation and stays that way** — the `S('@1 : @2')`
  key cannot carry a partly-coloured line, and a third part makes that more true,
  not less. The duration needs its own element or its own label to escape the
  heading's `font=bold`, a label's font being per element and nothing in Lua being
  able to measure rendered text.
- **A wall-clock duration must not be charged, displayed as, or derived from
  `used.runtime`.** Two numbers about time on one form is precisely the confusion
  `B46` closed, so the duration is a `get_us_time` delta and the row keeps its
  describing line saying it is not clock time.
- **Renaming `CPU` is an `S()` key change**, so the `.tr` files and
  `locale/template.txt` move with it or the existing translation is orphaned with
  no error anywhere — the `C17` rule.

## Other decisions worth not re-litigating

- **The per-codelevel numbers, retuned 2026-08-30, and the singleplayer default
  with them.** `max_nodes_written` came down an order of magnitude at every level
  — `1e5 / 5e5 / 1e6 / 1e7` — because the old top of 1e8 was a hundred million
  nodes nobody had ever asked a program for, and a ceiling that cannot be reached
  teaches nothing about what a program costs. `max_runtime_s` became
  `250 / 500 / 1000 / 2000`. Level 2 gained in three places at once — `pace_ms`
  15 → 5 ms, `map_memory_mb` 16 → 32, `max_string_mb` 4 → 8 — because it is the
  level a server hands out and it was the awkward one: paced enough to feel slow
  without the room to finish anything.
  The **singleplayer default went 4 → 3**, `S6` narrowed rather than reversed: the
  original argument proves too much, arguing for the *unpaced* levels, and 3 is
  already unpaced. Level 4 is every ceiling at its widest at once, and nothing
  should sit there without someone asking.
  The bundled examples were shrunk to match: **every one now completes at
  codelevel 2**, the largest being `planet.lua` at about 71% of that level's node
  budget. Two consequences before nudging any of these again — `planet.lua` and
  `death_star.lua` do **not** fit codelevel 1's 1e5 and never did, and
  `cube(200,200,200)` now needs codelevel 4.
- **`max_runtime_s` and level 4's node ceiling, retuned again 2026-09-02**, from
  the group `H` run: `max_runtime_s` `250 / 500 / 1000 / 2000` → **`30 / 60 /
  120 / 300`**, and `max_nodes_written`'s top **`1e7` → `5e7`** with the other
  three levels untouched.
  **What made 2000 s wrong was the unit, not the arithmetic.** The measurement
  behind it: a program that built for **387 s of clock time spent about 18 s** of
  server time, ~4.6%, because a codelevel-4 drone is given ~8 ms of a ~90 ms step
  (`B46`). At that ratio 2000 s of *charged* time is over eleven hours of
  building — a ceiling nothing could reach, which is exactly the objection that
  brought `max_nodes_written` down on 2026-08-30. 300 s at the same ratio is a
  couple of hours of building and still stops a runaway inside a few minutes of
  real time.
  **The two moved in opposite directions on purpose.** Time came down because it
  bounded nothing; level 4's node count went up because with `pace_ms` at 0 and
  no dimension limit, *how much may I build* is the only ceiling a poweruser
  meets, and 1e7 is a 215-node cube. 5e7 is a 368-node cube. Levels 1–3 stay
  where 2026-08-30 put them, so **the bundled examples still fit codelevel 2**
  and nothing in `F-5` or `W3` needs re-measuring.
  Three mirrors moved with it — `doc/api.md`'s codelevel table (**hand-written
  prose that `gen_docs.lua` does not check the numbers of**, only that every
  limit has a row), `settingtypes.txt`, and the worked example in
  `lib/config.lua`'s own comment.
- **Building `F5`** — dropped unbuilt 2026-08-29. Do not re-propose it as a small
  addition to the drone panel: the privilege gating and the counter-carrying under
  its entry are what make it large.
- **Putting a button in a HUD** — impossible, not merely unwise. See `F4`.
- **Batching `place()` into `core.bulk_set_node`** — not for 1.0.0. 1.3x against
  five flush sites whose omission is a silently wrong build; the arithmetic wants
  redoing since Phase 6 changed the yield cadence. (A4)
- **Letting a file be removed without opening it first** — won't fix: "not really
  needed". `B14`'s cold path stays unreachable as a result. (B34)
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
  that has needed it. (A1, F1)
- **Writing `.cdb.json` by hand** — never. ContentDB reads `long_description`
  from that JSON only and a JSON string cannot hold a newline, so the shipped
  field is one enormous escaped line: the artefact, not the source. Edit
  `CONTENTDB.md` and run the generator. (C19)
- **The release webhook's trigger is *Branch or tag creation*, not push**, because
  this project tags; push events would publish every commit on `master`.

## What ships broken

- `heap_mb` cannot stop one huge allocation, and a pathological Lua pattern can
  still burn CPU inside a single `find` or `match`. (S2)
- The step budget is never checked *inside* one VoxelManip pass, so a single slab
  — around 65k nodes, under 10 ms — still overshoots it. (A5)
- A shape large in **two** dimensions still asks for more mapblocks than the
  footprint ceiling in a single pass, and the run dies instead of waiting. Only
  one axis can be sliced away. (B42)
- The map footprint decays linearly over the unload window rather than tracking
  each block, so it estimates what is resident rather than measuring it. (S5)
- Nothing charges for writing a shape to the map database or pushing it to
  clients: both happen after a run reports `completed`. Not a defect — every mod
  writing to the map has it — but no limit bounds what a large shape costs the
  server, and none should be sold as if it did. (S5, from `W3`)
- **Nothing on screen says why a drone is slow.** The map row was dropped from
  both surfaces deliberately (`B45`), which leaves the `H6` pause confusion able
  to return. A known gap, not an oversight.
- `place()` writes one node per call; the four bulk shapes do not. (A4)
- A file cannot be removed from the editor without opening it first, so `B14`'s
  cold-cache removal is unreachable for good. (B34, B14)
- A copy of a name already at the 15-character limit shifts base at the tenth
  copy — fixing it would let copies past the length rule. (F2)
- The unsaved-tab mark is a flag, not a diff, so typing a character and undoing it
  leaves the tab marked until the next save. (F7)
- A player created before `1f7cd97` keeps the stored "off" for both editor
  checkboxes; the ticked default reaches new players only. (B36)
- `save_on_exit` is read, written and acted on nowhere: the checkbox stays
  commented out.
- A file over `max_file_kb` — 128 kB by default — cannot be opened or saved at
  all, and the ceiling cannot be raised from inside the game. That is the price of
  not reading it whole. (B40)
- Cancelling the file chooser removes the drone it placed, rather than never
  placing one; removing a file takes the drone holding it. Both deliberate, and
  the two had to agree. (B41, B44)
- **`codecube` must set `codeblock_flat_sky = true`** in its own `minetest.conf`
  when it adopts a release with `C18` in it, or its world gets an ordinary
  day/night cycle. One line in the game, nothing here. This repository does not
  track whether it was added, so forgetting it looks like a regression in the
  game's sky — which belongs to the game's record, not this one.
- `settingtypes.txt` mirrors `lib/config.lua` by hand and nothing checks it. (C7,
  C17)
- `tests/game/mods/vector3/mod.conf` still carries a 5.5 version ceiling —
  separate repository, not fixable from here. (C1)
- `scripts/gen_cdb_json.sh` is verified by nothing and escapes neither `"` nor a
  backslash. (B22)
- `.gitattributes` decides what reaches a player and **no CI checks it**. (C10)
- `README.md:14`'s trailing whitespace is deliberate — a Markdown hard break
  `gen_cdb_json.sh` folds into the ContentDB description. (B21)

## Four rules this phase paid for

- **Run a playtest group that has never been run before writing the next
  feature.** Eight sessions on the editor found four findings; the one session
  that finally left the editor found three, including the worst defect this
  project has recorded against committed code (`B39`). `F4` repeated the lesson:
  four green gates, and ten minutes in a world found two more.
- **Play the mod outside its own game before a release.** `B38`, `B39` and `C18`
  are all invisible in `codecube`, where a player carries nothing but the two
  drone tools and the sunless sky is the game's design.
- **A check is a starting point, not a script — do the obvious next thing to
  whatever it leaves on screen.** `B41` was reported while a session was checking
  something else, and `B44` came out of re-running `B41`'s own check and then
  removing the file the drone was holding. The written steps are what stops a
  session forgetting; they are not what finds things.
- **Read what the game actually said, not just whether it did the right thing.**
  `F-3` case 2 passed on behaviour and printed the server's absolute filesystem
  path in English. That is `S7`, and a pass/fail line would have buried it.

---

2026-08-30 · codeblock `60dc8dd` (master), pushed, CI green (run 42, all three
jobs), plus the uncommitted limit retuning. Local gates green, engine 5.17.0,
read from output rather than exit codes: luacheck silent, `doc/api.md` and
`locale/template.txt` up to date, `locale/*.tr` covering all 79 messages, nine
in-engine specs **439 passed, 0 failed, 1 xfail, 0 xpass**.

**No defect is open.** `PLAYTEST.md` stands at 50 checks: seven of group `H` due a
second run, `R4` and `F-5` never run. Then `settingtypes.txt`'s `--check`, then
v1.0.0.
