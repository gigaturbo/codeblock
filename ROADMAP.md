# Roadmap — CodeBlock

What to do next, in order, and **what has been agreed** — the shape of a feature
as settled in conversation, a part argued out, a rewording, a default chosen.
Those decisions are recorded nowhere else: git holds the code and `CHANGELOG.md`
holds what shipped, but neither says why a question is settled, so without this
file a settled question gets re-litigated. Compressed as it grows; only the
minimum past information stays.

Findings and their reasoning are in `AUDIT.md`. Manual checks are in
`PLAYTEST.md`. Intentions not yet planned are in `TODO.md`.

Numbering, so a commit message always resolves: phases are `Phase 0`–`Phase 10`,
features are `F1`–`F7`, and finding ids are `B`/`S`/`C`/`A`. **Nothing is ever
renumbered.**

Three releases, settled 2026-08-28. **`Phase 8` is v1.0.0** — a correct sandbox,
no unmaintained dependencies, documentation generated from the code, tests enough
that changes are safe; major, because several changes break saved player
programs. **`Phase 9` is v1.x.y**, features and defect work after the release.
**`Phase 10` is v2.0.0**, the Blockly editor and nothing else, because it needs
thinking rather than a queue position.

## Now

**No defect is open, and everything fixed is proven in a running world.** The
playtest run of 2026-08-27 at `246bb37` closed the backlog of *checking* and
opened one of *fixing*; that backlog is now empty too, and so is the one after
it. Six findings came out of this phase's playtests, **all six are fixed**, and
on 2026-08-28 at `6fea453` the last three were confirmed in a world by their own
checks — `D6` for `B44`, `F-3` case 2 for `S7`, and a re-timed `P3` for `B43`,
which spread **78 s and 95 s** where the same shape spread 78 / 160 / 183 before.
The *gates green, unproven in a world* list held **one** entry — `B14`, blocked
on `B34` being won't-fix — after `R2` closed `C16`'s install guard the same day.
**`F4` is the second, and it is a whole feature rather than one cold path:** its
nine `H` checks are all unrun.

**`C19` was filed and fixed the same day, and it is the only finding here ever
raised by a published rule rather than by a defect.** The long description was
`README.md` verbatim and broke six of ContentDB's *do not include* rules — worst
of them, its nine images reach nobody browsing in-game, and five were tool icons
used *inline in the instructions*, so those sentences lost their object. It now
has its own source, `CONTENTDB.md`, which the generator embeds instead. **No gate
in this repository could have caught it**, because the rules live on a page
nothing here reads; `release-check` gate 9 now carries them, which is what would
catch the next one.

**Write `CONTENTDB.md`, never `.cdb.json`.** ContentDB reads `long_description`
from that JSON only, and a JSON string cannot hold a newline, so the shipped
field is one enormous escaped line. That is the artefact and not the source —
anyone finding it unreadable and reaching for a multi-line format is about to
break the upload.

**`F7` shipped the same day and `E16` passed it the same day** — a `*` on a tab
whose buffer differs from the file, confirmed in a running world at `afbe504`.
`F6` is no longer one of them: Blockly is `Phase 10` and v2.0.0.

**`F4` shipped the same day and is the phase's fifth of six, leaving only `F5`.**
It is also the first feature here to ship with **none** of its in-world checks
run: a HUD and a formspec panel showing what a running program spends, plus
Pause, Resume and Cancel, and the setter's left click on a *running* drone
repointed from cancelling the run to opening that panel. The specs reach its
arithmetic (`limits.binding`, `limits.report`), its pause field and the panel's
session routing, and reach nothing a player sees. **That is playtest group `H`,
nine checks, all unchecked** — so *every shipped feature is proven in a world* is
no longer true, and `H` is the group to run before `F5` starts. The rule this
phase paid for says as much: run a group that has never been run before writing
the next feature.

**`R2` passed on 2026-08-28 too, and every check that existed then carries a
result** — 39 of 39, 37 pass and 2 partial, which had never been true before;
`F4`'s nine take the file to 39 of 48. It closed `C16`'s install guard: the
archive extracted into
`minetest_game`'s own `mods/` beside `vector3`, with `codeblock_run_tests = true`,
loaded normally and logged the warning instead of refusing to load. The one thing
still unproven anywhere is `B14`, and it is blocked on `B34` being won't-fix
rather than on anyone finding time.

**`R1` passed on 2026-08-28** and took **`C10`** with it — `.gitattributes` was
doing its job for the project's whole life and nothing had ever looked. The
archive holds eleven top-level entries, all player-facing, and none of the
record. Worth keeping from that run: **the check's own command is misleading.**
`git archive HEAD | tar -t | grep tests` prints `lib/examples/tests.lua` even
when the archive is correct — it is one of the fourteen example programs, the one
that exercises every API command. Reading `grep` output as a pass/fail is how
that reads as a fail; listing the top level is what actually answers it, and the
check now says so.

Two loose ends worth naming, neither of them blocking:

- **`S7`'s log line is unlooked-at.** `F-3` case 2 confirmed what the player
  sees — *"Impossible de lire le fichier ..."*, translated and naming the file —
  but not that `io.open`'s real reason is at `warning` in `debug.txt`. One grep,
  next time an unreadable file is to hand.
- **`P3` left a 23% gap unexplained**, 78 s against 95 s across two of four
  facings. The emerge multipliers can only be 1, 2 or 4, so it is not `B43`
  returning; it is recorded in `PLAYTEST.md` and `AUDIT.md` rather than filed,
  the same way the old unexplained 160 s was.

Then `F4`, `F5`, `settingtypes.txt`'s generator, and v1.0.0.

**The three fixed on 2026-08-28 after the world group, all three now confirmed.**

- **`S7` · low** — a failed file open handed the player `io.open`'s own string,
  so the server's **absolute path** reached them, in English whatever language
  the game was in. Fixed by returning the message built four lines above and
  unreachable until now, with `err` logged at `warning`. **The class matters more
  than the line**: an error value passed straight through from an engine or C
  call is a player-facing string that is not a translation key, and
  `gen_locale.lua --check` cannot see it — the next one will not be reported
  either.
- **`B44` · low** — removing a file left the drone holding it standing there
  naming a program that was gone, going away only on the next run. Fixed in the
  editor's *Remove file* handler, **not** in `lib/filesystem.lua`, which has no
  drone dependency and must not gain one. It takes the drone with the file, the
  same answer `B41` gave for a cancelled chooser: the two had to agree.
- **`B43` · low** — one subtraction per axis in `bounds.cube`, one along the
  length in `bounds.cylinder`. Three `shapes_spec` cases were **recomputed from
  the geometry and then run against the old bounds to prove they were not fitted
  to the new output**: they fail there with exactly the old numbers. The
  subtraction made `cube(0,0,0)` produce an inverted box, so `build` now returns
  before the loop when any axis is inverted — that guard and the subtraction go
  together.

**The pattern worth naming: three of those six came from a session going one step
past the written procedure.** `B41` was reported while checking something else;
`B44` came out of re-running `B41`'s own check and then doing the obvious next
thing to a drone; and `S7` came out of a check that **passed on behaviour and
failed on its message**, which no pass/fail line on its own would have caught.
Read what the game actually said, not just whether it did the right thing.

**Fixed earlier in the phase, both confirmed in a world.**

- **`B40` · high · `62cf464`, confirmed by `F-4` and `F-3` case 1** — `read_file`
  read a file whole with no bound and the editor sent it to the client; a 168 MB
  file took Luanti to ~14 GB and froze it. It now reads one byte past the ceiling
  and refuses the file by name, and `write_file` refuses at the same size so the
  editor cannot save what it would then decline to open. The ceiling is a new
  setting, `codeblock_max_file_kb`, **128 kB** by default. Its open question is
  answered too: the engine drops a formspec submission whose fields total 640 kB,
  from **5.7.0** on and not before, so a modified client's route in is real,
  bounded, and now closed on this side as well.
- **`B42` · medium · `febf16f`, confirmed by `P3`** — `lib/shapes.lua` sliced
  along z only, so a shape long in x asked for more mapblocks than the whole
  ceiling and the run *died* where the ceiling exists to make it *wait*:
  `cube(2, 2, 30000)` at codelevel 1 worked facing north and failed facing east.
  Slabs now follow the longest axis, and the fillers clip on all three rather
  than on z alone — which the finding had assumed they already did. The same run
  **measured the throttle for the first time**: 93 s for that shape, against the
  ≈ 80 s the ceiling over the unload window predicts. `S5` had claimed that
  behaviour from reading since Phase 5.

**Nothing is unrun any more.** `R1` and `R2`, the release-archive pair and the
last two checks with no result, both passed on 2026-08-28, taking `C10` and
`C16`'s install guard with them. `E16`, new with `F7` the same day, passed the day
it was written. The world group — `W1`, `W2`, `W3` — was
played on 2026-08-28 and all three passed, the last group to have had nothing in
it.

**That run settled questions rather than finding defects, which is new here.**
`W2` **answers `A4`**: mapgen does not overwrite a node written into ground it
had not generated. That had been on the audit's *not verified anywhere* list
since Phase 4, was the oldest entry it ever had, and its departure leaves that
list holding one thing — `B10`'s refusal. `W1` passed at current code, so `S5`'s
16.3 kB measurement no longer rests on a run predating the Phase 6 and Phase 7
rewrites of `lib/cost.lua`. `W3` priced a large shape, written up under `S5`.

**The one thing `W3` is worth remembering for.** `cube(200, 200, 200)` took
0.34 s of program time — and that is the *smallest* part of what it cost. The
budget charges nodes, runtime and footprint; serialising ~2200 mapblocks into the
map database and pushing them to every client happen **after the run reports
`completed` and are charged to nobody**. Neither was measured. Not a defect and
not filed as one, but a limit added later must not be sold as bounding what a
shape costs the server, because none of them do.

**`F-3` case 2 cost two sessions before it passed on behaviour**, and the second
of those is a lesson. The `icacls` recipe was `cmd` syntax run in PowerShell,
which read the bare `(R)` as a subexpression and ran the `r` alias for
`Invoke-History` instead of calling `icacls` at all. **A recipe written for one
shell and run in another is a procedure defect, not a finding** — that is twice a
`PLAYTEST.md` recipe has cost a session (`D2` case 2 is the other), so a recipe
added here names the shell it is for. The corrected one is verified as a round
trip. Case 1 **passed on 2026-08-28** — reachable at last because an oversized
file is refused before the bytecode branch, which also confirmed `B7` a phase
after it was fixed.

**`D2` case 2 has now been aimed at twice and missed twice**, the second time
with the written recipe: *"hard to produce case 2, looks not unloaded"*. The
recipe is the suspect, not the tester — `server_unload_unused_data_timeout`
bounds when the engine *may* drop an idle mapblock, not when it does. Do not
spend a third session waiting out a timeout and hoping; find a way to observe
that the server has let go first. It is the only route to `B10`'s refusal.

**One number decided `B43`, and it is worth remembering how.** `P3` turned up
that the facing changed the run, and there were two explanations — what the
client drew, or a real difference in the work — that no amount of watching could
separate. Timing three facings did it in one go: 78 s and 183 s land within one
per cent of a doubled and a quadrupled emerge. **Ask for the number the two
explanations disagree on.** The 160 s run fits neither and is recorded as
fitting neither, rather than rounded into the story.

**`C18` was decided on 2026-08-28: one setting, defaulting off** — the middle of
the three options the finding put up, and the one it recommended. The mod touches
nobody's sky unless asked; a game that wants a flat, sunless one says so in its
own `minetest.conf`. The cost lands outside this repository and is one line:
`codecube` sets `codeblock_flat_sky = true` when it adopts a release with this in
it, or its world gets an ordinary day/night cycle back. **The author accepted
that cost on 2026-08-28** — *"when codecube will be updated it will take this
into account"* — so nothing here is waiting on the game and nothing here should
change to accommodate it. The one thing to keep: this repository does not track
whether that line was added, so a `codecube` release that adopts a version with
`C18` in it and forgets it looks like a regression in the game's sky. That
belongs to the game's own record, not to this one.

**The ContentDB rules were read into the tooling on 2026-08-28, before the
release rather than during it.** The author supplied the guidance
(<https://content.luanti.org/help/appealing_page/>, the index at
<https://content.luanti.org/help/>) and the intention to configure a release
webhook (<https://content.luanti.org/help/release_webhooks/>). Both are now in
`release-check` as gates 9 and 10 and in the `release-codeblock` skill, so they
are checked rather than remembered. Reading them turned up `C19`: **the long
description is `README.md` verbatim and breaks six of the *do not include* rules
at once.** The webhook's one decision is written down — **the trigger is *Branch
or tag creation*, not push**, because this project tags; push events would
publish every commit on `master` as a release.

**Four things the author settled on 2026-08-28**, all of them recorded where they
apply rather than only here: `C18`'s cost accepted by `codecube` (above);
`settingtypes.txt` **gets a generator**, on the grounds that it unifies a process
`doc/api.md` and `locale/template.txt` already share (`C7`, `C17`, and the phase
list); **Blockly becomes v2.0.0** with `Phase 9` for v1.x.y in between (`F6`, and
the milestone list); and `F7` takes **the flag, not the pristine copy** — built
the same day.

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
since found **twelve** defects in code earlier phases called done (B36–B44, C17,
C18, S7) — the newest of them were the largest. **All twelve are fixed.**

### 8 · Features for v1.0.0 — in progress (4/6 shipped · 15 findings closed, none open)

The last phase before v1.0.0 and the only one that adds rather than repairs.
Ordered easiest to hardest, one at a time. **The pacing and world groups have now
been played**, which is what `F4` and `F5` were waiting on — between them they
produced `B42` and `B43`, and answered `A4`.

**`F6` is no longer in this phase**: Blockly is `Phase 10` and v2.0.0, decided
2026-08-28. So this phase is six features, not seven.

Shipped, gates green, pushed and CI-green at `b8b30e3`:

- `F1` default block — a Settings panel plus a run-local `default_block(block)`.
  `500dd85`.
- `F2` *Create a copy*, and a file list sorting `foo_2` before `foo_10`.
  `dee0bc7`.
- `F3` `sleep(seconds)`, charged against `max_runtime_s` up front. `90cfb70`.

Shipped, gates green, and **confirmed in a world by `E16`** at `afbe504`:

- `F7` a `*` on a tab whose buffer differs from the file.

**The playtest backlog this phase carried is gone.** `R1` and `R2`, the
release-archive pair, both passed on 2026-08-28 and took `C10` and `C16` with
them; `D6`, `F-3` case 2 and a re-timed `P3` were run at `6fea453` the same day
and all three pass, confirming `B44`, `S7` and `B43`. Nothing in the phase waits
on a code change any more.

Left in the phase:

- `D2` case 2 — the last half nothing has exercised. Aimed at twice and missed
  twice; it needs a way to observe the server has released a mapblock, not
  another session. (B10)
- Give `settingtypes.txt` a generator and a `--check`, **decided yes** on
  2026-08-28: it is the third hand-kept mirror and the only one without one, and
  a generator unifies a process the other two already share. (C7, C17)
- **Rewrite the ContentDB long description so it stops being `README.md`.** The
  README broke six of ContentDB's own *do not include* rules at once, and the
  worst of them was that its nine images are not visible inside Luanti — five
  being tool icons used *inline in the instructions*, so those sentences lost
  their object rather than just their decoration. **Done 2026-08-28**:
  `long_description` now comes from `CONTENTDB.md`. Its shape was the author's
  — a short lead, main features, a quick start that reaches a visible result in
  three steps, the limits worth warning about, and recent changes as
  advertising. (C19)
- **Keep `CONTENTDB.md`'s *Recent changes* current at each release.** It is a
  hand-kept summary of `CHANGELOG.md` and nothing checks the two agree — the same
  family as `doc/api.md` and `locale/template.txt`, and it will drift the same
  way. The release skill names it as a step, which is a note about remembering,
  and this project's own lesson is that those do not hold. (C19)
- Build `F4`, the live drone panel.
- Build `F5`, changing a codelevel mid-run.

### 9 · v1.x.y — features and defects after the release

**Allocated 2026-08-28**, when `F6` moved to its own phase. Everything that is
not 1.0.0 and not Blockly lands here: features too late for the release, defects
the release itself turns up, and the playtest groups that only a shipped version
can reach. It has no fixed content on purpose — a phase for what comes back from
players is worth more empty than filled in advance.

The one thing already in it: **the first release under real use is where a
finding series meets people who did not write it.** Everything in `AUDIT.md` was
found by the author, one reviewer or one spec. That is a narrow sample and this
phase is where it widens.

### 10 · v2.0.0 — the Blockly editor

**Allocated 2026-08-28.** `F6` alone, and a major version because it is the
change that most plausibly breaks how a program is stored and edited. Its four
obstacles are written up under `F6` and **none of them has an answer yet** — no
HTTP allowance a ContentDB package can arrange, mod security on the write side,
where the assets come from, and what a generated program is stored as. The
author's own framing is the point: *time to plan and think*, not a queue
position. **Do not start building it because the phase exists.**

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

Its two `PLAYTEST.md` checks — the Settings panel and the preference surviving a
relog — both passed at `246bb37` on 2026-08-27. Nothing is outstanding.

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
`PLAYTEST.md` `F3`, which passed at `246bb37` on 2026-08-27.

### F4 · large · shipped in the commit this entry was added in, playtest unrun — a live drone panel

Two surfaces, because one of them cannot do the other's job. A **HUD** carries the
live read-out while a program runs; a small **formspec panel** carries the
per-limit breakdown and the two buttons. Today a player learns all of this only
from `Drone.finish`'s one completion line.

**Merged from three `TODO.md` lines, because they are one feature:** the drone
info UI, "show the program's budget while it runs" (the original Phase 8 item),
and the player-side half of "option to pause the drone" (the timed, in-program
half is `F3`). Splitting them would mean two features editing the same surface
and the second rewriting the first.

**Settled 2026-08-28, in conversation with the author.**

- **A HUD cannot carry buttons, and that is what splits the feature.** The
  element types in 5.17.0 are `image`, `text`, `statbar`, `inventory`, `hotbar`,
  `waypoint`, `image_waypoint`, `compass` and `minimap` — there is no button, and
  **no HUD click callback exists anywhere in the API**.
  `register_on_player_receive_fields` is formspec-only. The only input a HUD can
  answer is polling `get_player_control()`, which is key *state*, not "which
  element was clicked".
- **The HUD is nevertheless the right surface for the read-out**, and it dissolves
  the two risks the original entry named. `hud_change(id, stat, value)` updates
  one field: no formspec string, **no input focus reset**, and it does not go
  through `lib/forms.lua`, so it does not collide with the one-form-per-player
  rule. The editor can stay open with the HUD live over it.
- **The HUD shows only while that player's own drone is running** — it appears
  when a program starts and goes when it ends. Nothing on screen otherwise:
  a permanent status area is decoration, and decoration imposed on every game
  that installs this mod is exactly the `C18` shape.
- **On screen: the state and the binding constraint, and nothing else.** Which
  file, running or paused, and the one limit closest to its ceiling as a
  percentage — so a player learns which limit their program actually spends. The
  full count-beside-limit table is the panel's, not the HUD's, which keeps the
  live tick to two `hud_change` calls.
- **Player toggle over a server default.** A `flag` in `lib/config.lua`, the
  boolean sibling `flat_sky` already uses, overridden per player in player meta —
  read with `get_string`, because `get_int` cannot tell an unset key from a stored
  `0` (`B5`). Costs one `settingtypes.txt` mirror row and one toggle in the editor.
- **0.5 s cadence, only while running.** Affordable now that a tick is a
  `hud_change` per field that actually moved rather than a whole formspec.
- **The panel opens by left-clicking a *running* drone with the setter** — the
  gesture that today cancels the run. Left-clicking an idle drone still removes
  it, unchanged. **The consequence is deliberate: stopping a runaway program
  becomes two clicks rather than one**, and the accidental cancel that gesture
  allowed becomes impossible.
- **Pause/Resume and Cancel, no Start.** The poser's left-click is the gesture
  that starts a run; a second one means a second entry into the one place a
  drone's budget, coroutine and block preference are built.

**Constraints and risks.**

- **The data is already shaped for it.** `lib/limits.lua` keeps `caps` and `used`
  in one table on `drone.budget` precisely so it can be printed. Two numbers are
  missing rather than hidden: **peak heap is never retained** (`heap_mb` is
  sampled and compared, never kept), and the charged-CPU figure was dropped from
  the completion line in Phase 6 as meaningless against a ceiling in minutes — it
  belongs here as a **share** of the budget (`B26`). Both are wanted, so the
  binding-constraint function is total over what it can see.
- **Do not reintroduce the dependency `A11` removed.** `lib/drone.lua` does not
  know forms exist, and must not learn that a HUD exists either. Drive both from
  the other side, reading `drone.budget`. `Drone.on_place` is the precedent: it
  *returns* whether a file is needed and `register.lua` shows the chooser.
- **Pause is not `wake_at`.** Reusing it would clobber a pending `sleep()` from
  `F3`: resuming sets `wake_at = nil` and the drone wakes early. A separate
  `drone.paused`, checked in `stepper.awake`, leaves a sleeping program's own
  wake time intact — and a paused drone already takes no share of the step pool,
  because `Drone.on_step` counts only drones that are awake.
- **Cancel must go through `Drone.finish`**, the single place an outcome is
  announced, or the player gets two messages or none (`B12`, `B30`). Anything
  reading a drone by name from a callback must respect the **serial guard**
  (`B29`): read the record fresh, as `lib/drone_entity.lua` does — a panel that
  caches a drone table across redraws hits exactly that, and so does a panel left
  open while the run it describes ends.
- No API name, no codelevel change; one new `flag` setting. Spec coverage
  partial: `limits_spec` for the binding-constraint arithmetic (**keep it a pure
  function of `caps` and `used`** so it can be), `stepper_spec` for pause,
  `forms_spec` for the panel's session and handler routing. **The HUD itself, the
  cadence, the drawing and the setter gesture cannot be spec'd at all** — they
  need a player, a screen and a world — so this one wants its playtest group run
  first and carries more `PLAYTEST.md` weight than any feature so far.

**Argued out, so it is not proposed again.**

- **A Start button.** Duplicates the poser's left-click and doubles the entries
  into `get_safe_coroutine`.
- **An admin view of another player's drone.** No one asked, and it adds a
  privilege surface to a feature that otherwise has none.
- **A `statbar` for the percentage.** It needs a texture pair and draws in
  half-image steps; a colorized `text` says the same thing to the pixel and costs
  no asset.
- **A live-refreshing panel that reproduces the HUD.** The panel refreshes on the
  same tick — it has no text field, so a redraw costs no focus — but it does not
  duplicate the HUD's job. Two surfaces, one each.

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

### F6 · Phase 10 / v2.0.0 · planned — Blockly web-based editor

Build programs by dragging blocks in a browser instead of typing Lua — the obvious
next step for the educational goal, and the reason it keeps coming back.

**Settled on 2026-08-28: `F6` is `Phase 10` and v2.0.0**, not the first item after
1.0.0. It keeps its `F6` id, which is never renumbered. The author's reason is
that it needs thinking rather than scheduling, and a major version gives it the
room: *"Blockly will be 2.0.0 so I have time to plan and think."* `Phase 9` —
`v1.x.y` features and defect work — comes between, so the release after 1.0.0 does
not have to wait on the largest unanswered design question in the project. The
four obstacles below are that question, and none of them has moved.

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

### F7 · small · shipped `afbe504`, confirmed by `E16` — show which tabs are unsaved

A tab whose buffer differs from what is on disk is drawn with a trailing `*`, so
a player can see the editor is holding an edit they have not saved. Nothing
showed it before.

**Why it exists.** `E12` failed three times and was traced twice for a write that
was never happening. What the player was seeing each time was the unsaved edit
surviving a tab switch — correct, and what any tabbed editor does — and then
vanishing on ESC, which is also correct with *Save on tab switch* unticked. The
sequence is only surprising because nothing in the form says the buffer is dirty.
Reported as *"not really a bug but more something not expected in the user
experience"* (2026-08-27).

**The alternative was rejected, and stays rejected.** Resetting the text area to
the file's content on a tab switch would make the state visible by throwing the
player's typing away. That is exactly `B35`: gating the in-memory capture on
`meta.sos` alongside the write lost the edit outright, and the comment on that
branch in `lib/formspecs.lua` says so. **Do not gate the capture again.** Warning
before a discard is a fair follow-up, but a marker makes the warning optional
rather than necessary, which is why it comes first.

**Constraints.**

- **The marker is render-only.** `meta.tabs[i]` holds the filename `write_file`,
  `read_file` and `remove_file` are handed; a `*` appended there would create a
  file named `foo.lua*`. Decorate the label as the `tabheader` is built and
  nowhere else. `fields.tabs` is an index, so no branch reads the label back.
- **Where the flag is set is already decided by `B35`.** `fields.content` is
  captured once, before the branch chain, and that is where a buffer becomes
  dirty. `save_active` and `create_file` are where it becomes clean. `copy_active`
  writes a *different* file, so it clears nothing on the source tab.
- **A flag, not a comparison, unless the pristine text is kept.** Keeping a second
  copy of every open file to diff against doubles the editor's memory for a
  cosmetic mark; a set-on-edit flag costs one boolean per tab and is wrong only in
  the harmless direction (typing a character and undoing it leaves the tab
  marked). Pick one deliberately.
- No API name, no new limit, no codelevel change. `forms_spec` can cover the flag
  transitions through the handler; **the drawing cannot be spec'd**, so this needs
  a `PLAYTEST.md` entry beside `E12` — and `E12` itself is unaffected, since the
  behaviour it checks does not change.

**Built on 2026-08-28, the flag, as chosen by the author.** `meta.dirty` is a
third array beside `meta.tabs` and `meta.contents`, one boolean per tab, and the
three are maintained at the same four sites — inserted together in `show` and
`open`, removed together in `remove_active` and `close_active`. **Kept dense
rather than sparse** for exactly one reason: `table.remove` on a table with nil
holes has no defined behaviour in Lua 5.1, and the removals are what keep the
flag with its tab when the indices shift.

**One thing the constraint above did not say, and it decides whether the mark
means anything.** The flag cannot be set from `fields.content` *arriving*: the
textarea reports itself on every submit, so that would mark every tab on the
first button press. It is set from `fields.content ~= meta.contents[active]`,
compared before the buffer is overwritten. That is **not** the pristine-copy
design rejected above — the buffer is a copy already held, so it costs no memory
— but it does mean the mark says *differs from what was last written*, not
*differs from disk*. Typing a character and undoing it leaves the tab marked
until the next save, which is the harmless direction the constraint asked for.

`save_active` clears the flag **only on a write that happened**: a refused save
leaves the buffer differing from the file, which is what the mark is for.

`integration_spec` pins the two things that fail silently — the label carries the
`*` and `meta.tabs` does not — by calling `get_form` on a built meta and reading
the `tabheader` back out. What a player can see was `E16`, **passed at `afbe504`
on 2026-08-28**, the day this shipped.

## Other decisions worth not re-litigating

- **Putting a button in a HUD** — impossible, not merely unwise. 5.17.0 has nine
  HUD element types and none is a button, and no HUD click callback exists;
  `register_on_player_receive_fields` is formspec-only, and `get_player_control`
  is key state, not a click target. Anything interactive is a formspec. (`F4`)
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
- A file over `max_file_kb` — 128 kB by default — cannot be opened or saved at
  all: the refusal names the file and the size, and there is no way to raise the
  ceiling from inside the game. That is the price of not reading it whole. (B40)
- A shape large in **two** dimensions still asks for more mapblocks than the
  footprint ceiling in a single pass, and the run dies instead of waiting. Only
  one axis can be sliced away, so the fix for a shape long in one dimension does
  not reach this. (B42)
- Cancelling the drone's file chooser removes the drone it placed, rather than
  never placing one — the tidier shape, deferring `Drone.new` until a file is
  picked, is a larger change and was not taken. Fixed and confirmed in a world,
  `D5` on 2026-08-28. (B41)
- Removing the file a standing drone is holding takes the drone with it, rather
  than clearing its name and leaving it asking for another — the same answer
  `B41` gave, and the two had to agree. Fixed and confirmed in a world, `D6` on
  2026-08-28. (B44)
- A tab whose buffer is unsaved is marked with a trailing `*`, so an edit
  surviving a tab switch and then vanishing on ESC no longer reads as a lost
  save. It never was one — `E12` passed at `246bb37`; what was missing was
  anything saying the buffer was dirty. Shipped 2026-08-28 at `afbe504`,
  and confirmed in a world by `E16` the same day. (F7)
- The mark is a **flag, not a diff against a kept pristine copy**, chosen by the
  author on 2026-08-28: one boolean per tab against doubling the editor's memory
  for a cosmetic mark. It is therefore wrong in the harmless direction — type a
  character, undo it, and the tab stays marked until the next save. (F7)
- **All 39 `PLAYTEST.md` checks carry a result** — 37 pass, 2 partial, nothing
  failing and nothing unrun; the partials are `E2`, permanent while `B34` is
  won't-fix, and `D2` case 2. `R1` and `R2` both passed on 2026-08-28: the archive
  holds eleven player-facing entries and none of the record (`C10`), and installed
  as a package with `codeblock_run_tests = true` it loads and warns instead of
  refusing to load (`C16`). The footprint throttle left this list on 2026-08-28,
  having been on it since Phase 5: `P3` measured it, and then re-timed it against
  `B43`'s fix.
- A failed file open names the file and logs the operating system's reason at
  `warning` rather than showing the player the server's absolute path. Fixed and
  confirmed in a world, `F-3` case 2 on 2026-08-28 — though only the player's
  half; the log line is still unlooked-at. **The class is the thing to
  remember:** an
  error value passed through from an engine or C call is a player-facing string
  that is not a translation key, and nothing reports it. (S7)
- `settingtypes.txt` mirrors `lib/config.lua` by hand and nothing checks it — the
  third such mirror, and the only one without a `--check`. (C7, C17)
- The flat, sunless sky is now `codeblock_flat_sky`, off by default, so
  **`codecube` must set it in its own `minetest.conf`** when it adopts a release
  with this in it or its world gets an ordinary day/night cycle. One line in the
  game, nothing here. Confirmed in a world, `R3` in both positions on
  2026-08-28. (C18)
- Nothing charges for writing a shape to the map database or pushing it to
  clients: both happen after a run reports `completed`. Not a defect — every mod
  writing to the map has it — but no limit bounds what a large shape costs the
  server, and none should be sold as if it did. (S5, from `W3`)
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
  project has recorded against committed code (`B39`).
- **Play the mod outside its own game before a release.** `B38`, `B39` and `C18`
  are all invisible in `codecube`, where a player carries nothing but the two
  drone tools and the sunless sky is the game's design.
- **A check is a starting point, not a script — do the obvious next thing to
  whatever it leaves on screen.** `B41` was reported while a session was checking
  something else, and `B44` came out of re-running `B41`'s own check and then
  removing the file the drone was holding. Neither is in any written procedure,
  and no check would have caught either. The written steps are what stops a
  session forgetting; they are not what finds things.
- **Read what the game actually said, not just whether it did the right thing.**
  `F-3` case 2 passed on behaviour — the file listed, the failure reported, the
  session intact — and the message it printed was the server's absolute
  filesystem path in English. That is `S7`, and a pass/fail line on its own
  would have buried it.

---

2026-08-28 · codeblock `9e04990` (master), pushed · CI green, run 36, all three
jobs — the run covering `C19`'s corrected ContentDB long description and `C16`'s
install-guard playtest. `F4` is in the commit this line was added in, gates
green, awaiting its own CI run.
Local gates green over that commit, engine 5.17.0, read from output rather than
exit codes: luacheck silent, `doc/api.md` and `locale/template.txt` up to date,
`locale/*.tr` covering every message, nine in-engine specs **428 passed, 0
failed, 1 xfail, 0 xpass**, six standalone specs green under plain Lua 5.1.
