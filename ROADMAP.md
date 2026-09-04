# Roadmap — CodeBlock

What to do next, and **what has been agreed** — a feature's shape as settled, a
part argued out, a default chosen. Those decisions are recorded nowhere else: git
holds the code and `CHANGELOG.md` holds what shipped, but neither says why a
question is settled. Compressed as it grows; only the minimum past information
stays.

Findings and their reasoning are in `AUDIT.md`. Manual checks are in
`PLAYTEST.md`. Intentions not yet planned are in `TODO.md`.

Phases are `Phase 0`–`Phase 10`, features `F1`–`F10`, findings `B`/`S`/`C`/`A`.
**Nothing is ever renumbered.**

Three releases, settled 2026-08-28. **`Phase 8` is v1.0.0** — a correct sandbox,
no unmaintained dependencies, documentation generated from the code, tests enough
that changes are safe; major, because several changes break saved player
programs. **`Phase 9` is v1.x.y**, features and defect work after the release.
**`Phase 10` is v2.0.0**, the Blockly editor and nothing else, because it needs
thinking rather than a queue position.

## Now

**`B50` and `B52` are done — fixed, and now played.** They were fixed on
2026-09-03 in **`1b991ae`**, *B50, B52: drive a program from the server step, not
from its drone entity*, with the gates green over it, and the three checks that
were the whole of the remaining evidence — `W1` at codelevel 1, `W5` and `W6` —
**all ran on 2026-09-04 at `23f0227` and all passed**, along with the rest of the
*Writing to the world* group. `W1` passed **at every codelevel**, which no
earlier run of it managed, and `W5` and `W6` had never run at all. The engine
version was not restated. **So the unnumbered step at the head of the release
list is closed, and `B51` is fixed behind it. What comes next is step 4 onward:
`README.md`, the screenshots, `R2` and a CI run.**

**No finding is open.** `B51` was the last and was fixed on 2026-09-04, in the
working tree and **not yet committed**. Its check `D7` is written and unrun, so
what is outstanding about it is *checking*, not work.

**What the fix did**, kept short because `AUDIT.md` under `B50` has the grounds.
An object with `static_save = false` is deleted the moment its mapblock leaves
server memory, so a drone past ~192 nodes from a player, or standing still for
the unload timeout, took its running program with it. Now every drone is advanced
from the one globalstep `lib/register.lua` already registered, `on_deactivate`
only drops the view, and a drone is handed another object — with the same serial
— once its block is back. **A record without an object is a run nobody can see,
not a run that stopped.** Two consequences were accepted with the decision:
`/clearobjects` no longer ends a program, and a far-away runaway loses its
accidental stop, so `max_nodes_written`, `max_runtime_s` and `map_memory_mb`
carry that load alone.

**`B51` was the last of the three and is fixed, uncommitted, on 2026-09-04.**
`Drone.on_remove` passes `'stopped'`, and `Drone.finish` gained a branch for it
sending the new key `Program '@1' stopped: @2` with the same two arguments the
`completed` branch uses, so the tail reads as the partial count it is. **The
vocabulary was added to `Drone.finish`, not a second announcement path** — that
is `B12` and `B30`. The word is the author's, chosen from three; the grounds are
under *other decisions worth not re-litigating*. `locale/template.txt` and
`locale/codeblock.fr.tr` moved with it (`C17`). **No spec reaches it**, so
`PLAYTEST.md`'s new `D7` is the whole of the evidence, and it is unrun.

**Two things `1b991ae` changed about older findings, recorded so they are not
re-broken.** `B29`'s serial now guards the **replacement's object** rather than
its record or its budget — `on_lost` removes nothing, so what the guard prevents
is a dying object's deferred `on_deactivate` blanking the new drone's `obj` and
leaving it invisible until the next re-spawn. And `B30`'s **behaviour** changed
while its rule did not: a parked drone with no coroutine used to be removed when
its mapblock unloaded, and now it persists and gets its view back — bounded, one
drone per player and `register_on_leaveplayer` removes it — while a program that
never started is still never reported as having ended.

**Behind it, the release list has shortened again.** `B48` `4179877`, `F10`
`b23a8bc` with `C21`, and `B49` `d8c32f7` are all committed and all confirmed in
a world. **`CONTENTDB.md` is done too** — `c2e541f`, with `.cdb.json`
regenerated from it — which was step 3 and the oldest thing on the list.
`CHANGELOG.md` has taken `F10`'s three breaking changes, `B48`, `B49` and now
`B50`/`B52`, so step 4 is down to dropping `(unreleased)` from the heading at the
tag. **What is left before the tag is `README.md`'s two problems, the
screenshots, `R2` on the release archive, and a CI run** — CI has seen nothing
since `471526e`, and `HEAD` is ahead of `origin/master`.

**The gates are green at `1b991ae`** — luacheck silent, the three `--check`
generators up to date, `locale/*.tr cover every message and nothing else`, nine
in-engine specs **474 passed / 0 failed / 1 xfail / 0 xpass** and six standalone
under Lua 5.1. The xfail is `preprocess_spec`'s and pre-existing. The in-engine
count is up 3 on `integration_spec`'s drone-seam block, which went from six cases
to nine for `B50`/`B52`. **CI has seen none of it** — the last run was `471526e`
— so the outstanding gate is a push and a CI run.

**The playing is done for `B48`, `F10`/`C21` and `B49`**, all on 2026-09-03,
engine 5.17.0: `E16`'s new pristine-example case, the four `F10-n` checks with
the inventory and `/privs` cases that were `C21`'s only possible evidence, and
`W4` at `16cd05c`. **And it is done for `B50` and `B52` as of 2026-09-04**, so
*gates green, unproven in a world* is back down to two: `B14`, permanently
blocked on `B34` being won't-fix, and `S7`'s log half.

Before that: `B47` was decided, fixed and playtested on 2026-09-02, and
`settingtypes.txt` has its generator and its `--check`.
**`PLAYTEST.md` stands at 59 checks, every one of them carrying a result** since
2026-09-04, when `W5` and `W6` were played for the first time. **No check has a
fail as its most recent result**; the one partial is `H8`, and only because two
of its cases cannot be performed. `W1`'s two fails of 2026-09-03 stay below its
pass, as `B50`'s evidence at code that has since been replaced. Its per-feature
checks were renamed `F<feature>-<n>` on 2026-09-03, so `F10-1`–`F10-4` and
`F1-1`/`F1-2` can be cited one at a time. The ordered list is the next section.

**`B47` was answered by slowing the beat**, `PERIOD` `0.5` → `1` s in
`lib/hud.lua`, the HUD moving with the panel because they share the one constant
— *"the HUD also so everything matches"*. It **halves the dead window rather
than removing it**: roughly one dropped click in ten where it was one in five.
That is the trade the author took over the three directions that cost more.
**`H10` then ran and found a few presses in twenty still missing** — a pass on
the author's call, and *more* than the check as written allowed, so the figure
under *What ships broken* is the observed one rather than the arithmetic. `B47`
ships **mitigated, not closed**, and the direction that would close it outright —
a panel that does not refresh itself — stays named and unspent.

**Writing the generator found a dead check, `C20`.** `gen_docs.lua`'s guard that
every per-codelevel limit has a documentation row had been matching **nothing**
since it was written: Lua's `%w` excludes the underscore, and every limit name
has one. No documentation was actually missing — the table was kept correct by
hand for the whole time the guard was dead. Both generators now match `[%w_]+`,
and both were **made to fail once**, against a fake limit, which is the only
evidence that separates a check that passes from one that cannot fail.

**Two loose ends, neither blocking.** `S7`'s log line is unlooked-at — one grep of
`debug.txt`, next time an unreadable file is to hand. And `P3` left a 23% gap
unexplained, 78 s against 95 s across two of four facings; the emerge multipliers
can only be 1, 2 or 4, so it is not `B43` returning.

**What group `H` and `F9` taught, kept because the next release will be tempted
to skip it.** `F4` shipped with four green gates and the first ten minutes in a
world found two defects — `B45` and `B46`, both about what the display *said*
rather than what it computed, neither reachable by any spec. `F8` rewrote enough
of `F4` that its first pass meant *it did what was asked*, not *it is settled*,
and the re-run did the same thing again at a smaller scale: the behaviour passed
everywhere and the **words** were wrong in three more places (`F9`), plus one
thing no spec could ever see (`B47`). **Displays are the part of this mod that
only playing can check**, and a second playtest of a rewritten display is not a
formality. The other four rules the phase paid for are at the bottom of this file.

## Finalising v1.0.0

In order. **Steps 7 to 11 are the `release-codeblock` skill's procedure** and are
not restated here; what is below is what *this* version still needs, and
`release-check` is the gate that says whether it got it.

**The work — everything through step 3 is done, so is the unnumbered playtest
step ahead of them, and so is `B51`; what is left is committing `B51`, the
README, the screenshots, `R2`, `D7` and the tag.**

**The unnumbered step before step 0 — play `W1`, `W5` and `W6` — is done,
2026-09-04 at `23f0227`, all three passing.** It is kept unnumbered so the steps
below keep the numbers commit messages and the release skill cite. `B50` and
`B52` were **fixed in `1b991ae`** with the gates green, and these three checks
were the whole of the rest of the evidence. `W1` ran **at every codelevel** — the
level-2-and-below case it had been asking for since 2026-08-28 *and* the three
levels above, in one session — with the third observation finally made: a drone
places straight afterwards, so a leaked record is **ruled out** rather than
unlikely. `W5` gave `B52` its first result ever, both cases. `W6` passed all
four of its cases, `/clearobjects` not ending a program included. **The engine
version was not restated by the author** and `PLAYTEST.md` records it as not
recorded.

**`B51` is fixed, and it goes in v1.0.0** — the question of deferring it to
`Phase 9` did not arise, the fix being one branch and one `S()` key. A run cut
short now says *stopped*, in English and French. **Two things about it are still
outstanding and neither is work:** the change is in the working tree with **no
commit**, and its check **`D7` has never been run** — no spec asserts what
`Drone.finish` sends, so that check is the only evidence there can be.
`CHANGELOG.md` gains a *Fixed* line **when the commit lands**, not before.
**Do not tag before `D7` has been played.** (B51)

0. **`B50` and `B52` — fixed at `1b991ae` and played; `B48`, `F10` and `B49` — committed
   and all three confirmed in a world.** `1b991ae` decoupled the drone record and
   the run from the entity: one globalstep advances every drone, `on_deactivate`
   only drops the view, and an object is handed back once the block is in memory.
   It touched `lib/drone.lua`, `lib/drone_entity.lua`, `lib/register.lua`,
   `lib/stepper.lua`, both locale files — the *drone has disappeared* key is
   deleted — and `tests/integration_spec.lua`. `B29`'s guard and `B30`'s
   behaviour both moved with it; see *Now*. Its gates are green and **its three
   checks passed on 2026-09-04 at `23f0227`**, which closes the unnumbered step
   above. The other three
   shared one working tree with the gates green over all of it, and went out
   as three commits on 2026-09-03: `B48` `4179877`, one line in
   `lib/filesystem.lua`; `F10` `b23a8bc`, covering `lib/register.lua`, `C21`, the
   hand-written region of `doc/api.md`, `README.md`'s Quick start and the eight
   French translations in `locale/codeblock.fr.tr`; `B49` `d8c32f7`, covering
   `lib/env.lua`, `lib/sandbox.lua`, `lib/api.lua`'s `blocks` entry with
   `doc/api.md` regenerated, one new locale key with its French, and 13 new
   `env_spec` cases. The playing is done for all three — `E16`, the four `F10-n`
   checks and `W4` — and now for `B50` and `B52` too, `W1`, `W5` and `W6` on
   2026-09-04. **CI has seen none of any of it**, so a push and a green run
   over `1b991ae` is what is left. (B50, B52, B48, F10, C21, B49)
1. **`B47` — done, and playtested.** Answered by slowing the beat to 1 s rather
   than stopping the self-refresh, quantising, or moving to mouse-down;
   `AUDIT.md` keeps why each of the other three was not taken. `H10` passed with
   a few presses in twenty still missing, which the author accepted — so what
   ships is a mitigation with its residue named. (B47)
2. **`settingtypes.txt`'s generator and `--check` — done**, `scripts/gen_settingtypes.lua`,
   with a step in the CI job that already runs the other two. The defaults come
   from `lib/config.lua`, the prose and the menu bounds from the script, and it
   **also fails on a setting `config.lua` reads that the menu does not offer** —
   the half no hand-kept file could do. It found `C20` on its first run. (C7,
   C17, C20)
3. **`CONTENTDB.md` — done, `c2e541f`**, with `.cdb.json` regenerated from it in
   the same commit. It had drifted exactly as `C19` said it would: the corner
   display *"naming the one limit the run will actually stop on"* was `F4`'s
   two-line HUD that `F8` replaced, *"pause, resume, cancel and remove"* was the
   four-button panel `F8` cut to **Stop** and **Pause/Resume**, and `F10` had
   made the Quick start's step 1 false. **Nothing checks this file against the
   code or against `CHANGELOG.md`**, so it will drift again — its *Recent
   changes* list is hand-kept and `B50`/`B52` are not in it, which is a judgement
   call rather than an omission: a player does not read *the drone no longer
   disappears* as a feature. Edit the Markdown and run
   `bash scripts/gen_cdb_json.sh` — **never `.cdb.json` by hand**. (C19, F10)
4. **`CHANGELOG.md` loses `(unreleased)` from its heading** at the tag, and its
   *Known limitations* section carries `B47`'s residue, since step 1 mitigated it
   rather than closing it. **v1.0.0's breaking list gained three of `F10`'s
   changes on 2026-09-03**, once they were committed and green and not before —
   the `/codeblock` command rename, the end of the tool handout, the end of the
   privilege grant — and `B48` and `B49` are in *Fixed* beside them. So this step
   is now the heading alone. (F10)
5. **`README.md`'s ContentDB URLs are on `content.minetest.net`**, the pre-rename
   domain. It redirects, so this is stale rather than broken — but the README
   ships in the archive. Its Quick start has the same `F10` problem as
   `CONTENTDB.md`'s: it does not say where the tools come from, and after `F10`
   they do not come from joining. (C19, F10)
6. **Upload the new screenshots to the ContentDB page.** They load from raw
   GitHub URLs on `master`, so the page needs the new names and the dropped 2021
   file removing. (C19)

**The release.**

7. **Re-run `R2` on the archive built from the release commit**, which is
   `git archive --format=zip --prefix=codeblock/ -o /tmp/codeblock.zip <tag>` —
   the tag rather than `HEAD`, because that is what ContentDB builds from, and
   `export-ignore` is read from the `.gitattributes` at that revision. `R1` was
   re-checked at `7dbe18f` and passes — eleven top-level entries, `textures/`
   shipping PNGs only, no `tests/` or `scripts/`. `R2` is the one that matters
   more and is older: it last ran at `7c5bceb`, before `F4` added
   `lib/hud.lua` to the `dofile` list and before `.gitattributes` changed at
   `60dc8dd`. The `C16` probe itself is untouched, so the guard is not in doubt;
   what is unproven is that *this* archive loads in a game that is not
   `codecube`. **Play it outside its own game** — `B38`, `B39` and `C18` were all
   invisible in `codecube`.
8. **`release-check`**, and do not start the tag until it says ready: the nine
   in-engine specs, the six standalone, luacheck, **all three** `--check`
   generators, CI green on the tagged commit's own `head_sha`, the licence field,
   ContentDB's rules against the long description, and a fresh clone that can run
   its own suite.
9. **Strike what the release closed** from `ROADMAP.md` and `TODO.md`, confirm
   `tests/game/mods/vector3`'s pinned commit is pushed, then commit, push, and
   tag `v1.0.0` on `master`.
10. **Upload to ContentDB**, long description from the regenerated `.cdb.json`.
11. **Configure the release webhook** — trigger **Branch or tag creation**, not
   push, because this project tags and push would publish every commit on
   `master`.

**After the tag, and deliberately not before.** `Phase 9` opens on what comes
back from players; `codecube` adopts the release on its own schedule and must set
`codeblock_flat_sky = true` in its own `minetest.conf` when it does (`C18`).
`Phase 10` is Blockly and needs the four obstacles under `F6` answered in writing
before any code.

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
since found **fifteen** defects in code earlier phases called done (B36–B44,
C17, C18, S7, and now `B50`–`B52`) — the newest of them were the largest.
**All fifteen are fixed.** All three of the newest were filed 2026-09-03 out of
`W1`'s fail at codelevel 1 and the reading that explained it; `B50` and `B52`
were fixed the same day at `1b991ae` and **confirmed in a world on 2026-09-04**,
and `B51` was fixed on 2026-09-04 with its check `D7` unrun. So fourteen of the
fifteen fixes are played.

### 8 · Features for v1.0.0 — in progress (8/8 shipped, 25 findings, none open)

The last phase before v1.0.0 and the only one that adds rather than repairs.
Started as seven features: `F6` moved out on 2026-08-28 (Blockly is `Phase 10`)
and `F5` was **dropped unbuilt on 2026-08-29** — *"not very interesting in the
end."* **`F10` was added on 2026-09-03** and is in `Phase 8` rather than `Phase 9`
for one reason: it renames two chat commands, and a rename is free before the
first tag and breaking after it.

Shipped: `F1` `500dd85`, `F2` `dee0bc7`, `F3` `90cfb70`, `F7` `afbe504`,
`F4` `729c255`, `F8` `d619fba` revised `60dc8dd`, `F9` `8869d8c` revised
`cd13414`, `F10` `b23a8bc`. **`F9` was added and shipped on 2026-09-02** out of `F8`'s playtest,
the second time a feature here has come from playing the one before it — and the
second time in a row that what a display *said* was the thing playing it found.

Shipped with them: **`F10` `b23a8bc`, played and committed 2026-09-03**, with
`B48` `4179877` and `B49` `d8c32f7` out of the same tree. **Every feature in the
phase has shipped.** **The three playtest checks against `1b991ae` — `W1`, `W5`
and `W6`, the only evidence `B50` and `B52` will ever have — all passed on
2026-09-04 at `23f0227`.** **`B51` was fixed the same day** — a run cut short says
*stopped* — leaving the phase with **no open finding**, an uncommitted tree and an
unrun `D7`. Left in it: `README.md`, the screenshots, `R2` on the release archive
— the one check whose result has gone stale — and a CI run, which has seen
nothing since `471526e`. `H10` passed 2026-09-02. **`F9`
passed its playtest on 2026-09-02** — all eight cases in both languages, no
defect, and one decision reversed: the paused clock, built and re-checked the same
day. **`B47` and `settingtypes.txt` closed the same day**, and writing the second
found `C20`, a check that had never once matched anything.
**`B10`'s refusal is out of the phase rather than done** — its check was removed
as untestable, and a route to it needs a way to observe the server releasing a
mapblock, which nothing here has.

**`CONTENTDB.md` drifted, which settled the argument rather than illustrating
it, and it was corrected at `c2e541f`.** It is a hand-kept summary of
`CHANGELOG.md` — the same family as `doc/api.md` and `locale/template.txt` — and
two of its claims described `F4`'s displays, which `F8` had replaced two features
ago. Nothing failed, nothing reported it, and the release skill's step naming the
file is precisely the note about remembering that this project has twice found
does not hold. **It is still hand-kept**, so it will drift again. (C19)

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

`PLAYTEST.md`'s `F1-1` and `F1-2` both passed at `246bb37`.

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

`PLAYTEST.md`'s `F3-1` passed at `246bb37`.

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
- **That comparison is line-ending-sensitive, and it was wrong for eleven months
  of shipped examples** (`B48`, 2026-09-03). `read_file` opens `'rb'` and the
  client's textarea returns LF, so a CRLF file never equalled the field coming
  back and **every bundled example was permanently marked** the moment it lost
  focus. `read_file` now normalises to LF. Anything else here that compares a
  buffer from disk against a field from a formspec has the same problem.

### F8 · medium · shipped `d619fba`, revised `60dc8dd`, playtested — make the drone panel readable

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

### F9 · small · shipped `8869d8c`, revised `cd13414`, playtested `029fab9` — say the state and the time in the same words

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

**The author's four choices, 2026-09-02.**

- **The idle state is bold and not coloured.** Green and yellow on that line mean
  *a run is happening*; idle is the absence of one, and a third colour would
  quietly change what the colour is for.
- **`6m 27s`**, seconds alone under a minute and `1h 12m` past an hour. Minutes
  are the scale a build runs at.
- **Bold, immediately after the state** — asked for as *not bold*, reversed the
  same day once it was on screen. The entry below says what that forced.
- **It keeps counting through a pause**, staying one honest answer to *how long
  since I started this*. The state word beside it already says nothing is
  advancing, and it needs no accumulator on the drone. **Reversed 2026-09-02
  after the playtest — see below.**
- **The panel only, not the HUD.** This is the panel earning its space: the corner
  block is four words and a number a line.

**Built, and load-bearing.**

- **The duration closes the heading, in parentheses and bold with the rest of
  it — one label.** It first shipped as a second, unbolded label right-aligned
  into the gap before the close `x`, because a label's font is per element and
  *not bold* was the ask. **The author reversed that within the hour: bold, just
  after the state.** Which settles the trade the right-aligned version was
  dodging — adjacency was worth more than the weight of the type.
  **Take the reason for that first attempt with the reversal, not instead of
  it:** nothing in Lua can measure rendered text, so *adjacent and differently
  styled* is the combination that cannot be built. In one label it needs no
  position of its own and cannot drift from the words it follows; as two, the x
  where `<file> : running` ends varies with the player's font and `gui_scaling`.
  Do not reintroduce the second label to unbold it.
- **`core.colorize` resets to `#fff` after the word it wraps**, which is what
  keeps the state coloured and the parentheses after it plain, inside one label.
- **`elapsed` reads `drone.tstart`, the same `get_us_time` stamp the finish
  message reports as `duration:`**, so the live figure and the final one cannot
  disagree.
- **What a translated string holds server-side is neither the key nor the rendered
  text.** `core.translate` wraps the whole in `\27(T@codeblock)` and substitutes
  each `@n` with its argument between `\27F` and `\27E`. A spec that asserts on
  `1m 30s` fails, and so does one that asserts on `@1m @2s`; `forms_spec` builds
  its expected value with the same `S()` call instead. Three assertions were
  written the wrong way first and the suite caught all three.

**Playtested 2026-09-02 at `029fab9` — `F9-1`: pass, all eight cases, both
languages.** No defect, and one reversal.

**The clock stops while a run is paused — asked for 2026-09-02 on seeing it,
built the same day with four gates green.** Case 4 checked the opposite and
passed; the decision above is what changed, not the code's fidelity to it. *How
long since I started this* turned out to be the wrong question for a paused run,
the same way *CPU* was the wrong word for `used.runtime`: the number a player
wants is how long the build has taken, and a pause is not part of it.

- **`max_runtime_s` already ignored a pause**, which is why this was small.
  `stepper.advance` returns at once for a drone that is not awake and charges
  only the time it spent advancing, so the wall clock was the one figure a pause
  inflated. Now the two agree.
- **`Drone.elapsed_us(drone)` is the single answer**, and both surfaces read it:
  the panel's heading through `elapsed`, which now formats microseconds instead
  of reading `tstart` itself, and the finish message through `__tostring`. The
  live number and the final one are the same call, not two expressions that have
  to be kept equal — which is what `F9-1` case 8 is checking.
- **`tstart` is shifted forward on resume, rather than a `paused_us` being
  accumulated.** One field to keep correct instead of two, and every reader still
  reads `tstart`: one that forgot `paused_at` would be right except while paused.
  The whole of it is `(paused_at or now) - (tstart or now)`.
- **`Drone.toggle_pause` is the only thing that may write `drone.paused`**, since
  the two fields are one fact in halves — stated on both, and the reason the
  toggle moved out of the formspec handler into the file that owns the run's
  timing. `on_run` clearing both is the only other writer.
- **What it costs:** a drone paused an hour and resumed reports the build's time,
  not the time since it was started. That is the point.
- **Proved by five `forms_spec` assertions**, and the hold is *fabricated* — the
  stamps are the whole of a paused reading, no wall clock enters it, which is
  what makes 105 s of elapsed wall time showing as `45s` assertable at all.
- **Checked in a world the same day**: `PLAYTEST.md`'s `F9-1` case 4, rewritten and
  passed. So that case has passed once each way round, which is the clearest
  evidence there is that this was a decision and not a defect.

### F10 · medium · shipped `b23a8bc`, playtested — the mod stops imposing itself

Three things happened to a player on first contact with this mod without anything
asking for them. Two go, one is replaced by a command. The author's words:
*"It's better if this mod does not touch the inventory, so the user installing it
would need to pick the tools in creative mode, and add a /codeblock tool or
similar so the user can quickly make the 2 tools appear."*

This is the same shape as `C18`'s sky override and `B39`'s inventory wipe:
`codecube`'s presentation living in the mod and imposed on every other game that
installs it. **`B16` and `B39` were both partial fixes to the line this closes** —
`B39` narrowed an inventory wipe to the one case where the player had something
to lose, and the real answer is that a mod should not be writing into a player's
inventory unasked at all.

**What it does.**

- **The tools are no longer handed out on join.** `set_tools` and its
  `register_on_joinplayer` call are deleted. Players take the two tools from the
  creative inventory or ask for them. The *"No room for the drone tools, free a
  slot and rejoin"* refusal goes with the function — and it was never once seen
  run, which `D4`'s entry says in as many words.
- **Both tools become droppable**, the `on_drop` stubs removed. Undroppable made
  sense only while the mod forced them on the player: without the handout, a
  player who picks one up could otherwise never be rid of it, and the command
  makes them replaceable at any time.
- **The privilege grant is gone**, and it is a finding in its own right:
  **`C21`**. `register_on_newplayer` granted `fly`, `fast` and `noclip` to every
  new player of **any** game that installs this mod. Removed outright. **Found
  while building `F10`, not reported by anyone** — the author was asking about
  the inventory and this was in the same twenty lines. Being found inside a
  feature is not a reason to escape an id: it is a defect in committed code, the
  same as `C18` and `B39`.
- **One chat line on first join**, from `register_on_newplayer`, naming the
  command and the creative inventory as the two routes to the tools. Never
  repeated. Chosen over saying nothing, because a player joining a server with no
  creative inventory would otherwise have no route into the mod at all.
- **One command replaces two.** `/codelevel` and `/codegenerate` become
  subcommands of `/codeblock`:

      /codeblock tools    [<player>]        put both tools in a player's main inventory
      /codeblock level    [<player>] <1-4>  as /codelevel did
      /codeblock generate [<player>]        as /codegenerate did

  Bare `/codeblock`, or an unrecognised subcommand, prints the three usages.

**Agreed, and load-bearing.**

- **Privileges are unchanged in effect and now uniform.** `tools` and `generate`
  are free for yourself and need the `codeblock` priv for someone else; `level`
  is privileged either way. That last one is not symmetry for its own sake:
  codelevel bounds resource use, so a player able to raise their own would be
  lifting their own ceilings. That is `B9`, reverted before it ever shipped, and
  `F5`'s entry says the same thing from the other side.
- **`/codeblock tools` must add what is missing, never clear.** The whole point
  of the feature is that the mod stops writing into an inventory unasked, so the
  command inherits `B39`'s rule rather than escaping it: both carrying reads stay
  — `main` **or** `craft` — because a tool parked in the craft grid would
  otherwise be duplicated every time the command is run, silently. It is now run
  on demand and repeatedly, which makes that failure easier to reach than the
  once-per-join version ever was.
- **A full inventory is a refusal, not a partial hand-out.** The old join-time
  refusal was unreachable in practice; the command's is a thing a player can
  produce deliberately, so it has to say what happened rather than half-succeed.
- **The first-join line names only the tools.** No hint about the editor, the
  examples or the drone.

**Argued out, so it is not proposed again.**

- **Aliases keeping `/codelevel` and `/codegenerate` working.** Cut on two
  grounds: v1.0.0 is unreleased and already carries a thirteen-item breaking
  list, so the rename is free now and never will be again; and two names for one
  command is a second surface to document, translate and keep in step. **This is
  the omission most likely to be proposed again.**
- **A setting to keep the privilege grant, `C18`-style.** A `flag` in
  `lib/config.lua`, off by default, was offered and declined. Nothing in this mod
  needs creative flight to be reachable, and a game that wants it sets it in its
  own config. **A setting no code path here depends on is a setting maintained
  for nobody** — which is the one respect in which this is *not* `C18`, where the
  sky override at least had a game asking for it.

**What it drags, none of it automatic.**

New and retired `S()` keys, so `locale/template.txt` is regenerated and every
`.tr` moves with them or the existing translations are orphaned with no error
anywhere (the `C17` rule); three keys are now legitimately orphaned, being the
usages this replaced. **`doc/api.md`'s *Chat commands* section**, which is the
one part of that file no generator writes and no `--check` reads — see the entry
under *other decisions worth not re-litigating*; it documented `/codelevel` and
`/codegenerate` while the gate reported the file up to date. The Quick start in
**`CONTENTDB.md`** and in **`README.md`**, both of which told the player they are
given the two tools; `README.md` has been rewritten, `CONTENTDB.md` is left for
the author's pending wording review, and `.cdb.json` follows it through
`bash scripts/gen_cdb_json.sh` — **that one is still outstanding**, and it is
step 3 under *Finalising v1.0.0*. `CHANGELOG.md`'s v1.0.0 breaking list **gained
the command rename, the end of the handout and the end of the grant on
2026-09-03**, once the commit made them true. `PLAYTEST.md`
gains four checks, `F10-1`–`F10-4`, because **every part of this is in the class no spec can
reach** — a tool callback, an inventory write, a privilege grant, a chat
command, a first-join path.

**Written, played and committed on 2026-09-03 — `b23a8bc`.** The
gates were run over the working tree holding `F10` and `B48` together: luacheck
silent, `doc/api.md`, `locale/template.txt` and `settingtypes.txt` each *up to
date*, nine in-engine specs **458 passed / 0 failed / 1 xfail / 0 xpass** with no
errors; the tree was gated again after `B49` joined it and read 471. By
`build-feature`'s rule the feature is **done** — committed with its gates green,
and its in-world checks run rather than merely written. **CI has not seen it**,
which is a push away.

**The playtest, 2026-09-03, engine 5.17.0, on `b9143b0` plus what was then the
uncommitted tree, and re-affirmed at `16cd05c` after the commit.** All four
checks — `F10-1`–`F10-4` in `PLAYTEST.md` — pass. Three passed outright:
`/codeblock tools`, the two renamed subcommands, and recovering a dropped tool.
The first was recorded **partial** and completed later the same day. It settled the risk `code-expert`
had flagged as unconfirmable — **the first-join chat line does arrive**, because
`chat_send_player` called from `register_on_newplayer` fires before the client
has finished loading and the message is not dropped — and then the two cases that
had been unreported: a fresh player's inventory holds **neither tool**, and
`/privs` shows **no `fly`, `fast` or `noclip`**. That last one is **`C21`'s only
possible in-world evidence**, so the removal is observed rather than green.
**`D4` is superseded by this group**, its own note having said so on the
condition that `F10` be committed; that condition was met at `b23a8bc` and
`PLAYTEST.md` now says the check is not to be run against current code.

**The English-only observation, and the rule it leaves behind.** Both the chat
line and the `/codeblock tools` replies appeared in English on a French client.
That was the known state, not a defect: this feature added eight `S()` keys and
`code-expert` was deliberately told not to invent French, so
`gen_locale.lua --check` had been listing all eight as untranslated and three
retired usage keys as orphaned — the legitimate fallback state per `C17`. **The
eight French translations were written and the three orphans removed later the
same day**, and the check now reads `locale/*.tr cover every message and nothing
else` alongside `locale/template.txt is up to date`. **And the author read them
in a world on 2026-09-04 — *"F10: french works ok"*** — which closes the owed
reading, recorded against `F10-1` and `F10-2` in `PLAYTEST.md`. The commit and
the engine version were not restated; the strings have not changed since
`b23a8bc`. No finding id: nothing was committed untranslated, so this is a
feature being incomplete before it ships, which `build-feature` records here
rather than in `AUDIT.md`. The rule generalises and
is in `CLAUDE.md` beside the two `C17` rules: **a new `S()` key ships
English-by-default and nothing fails**, because an untranslated message
legitimately falls back, so a feature adding player-facing strings is not
finished until the `.tr` files are written — and the only thing that will tell
you is playing it in another language. `F10` is the first feature here to
demonstrate it.

## Other decisions worth not re-litigating

- **A run cut short says *stopped***, the author's choice on 2026-09-04 from
  three options, fixing `B51`. **The grounds:** *stopped* matches the panel
  button's own label — **Stop**, *Arrêter* — so the word names the gesture the
  player just made. **The rejected two were *cancelled* and *stopped before
  finishing***: the first names no gesture in the interface, the second is a
  sentence where the other outcomes are one word. **The shared verb with the
  timeout line was weighed and accepted**: *Program '@1' stopped: it used all @2 s
  of running time* self-describes, so the two do not blur — and if they ever read
  as one message in a world, that is a finding rather than a re-opening of this.
  A fourth caller came with it, knowingly: `register_on_leaveplayer` also calls
  `Drone.on_remove`, so a player who disconnects mid-run is now told *stopped*.
  Nobody sees that line and *stopped* is the truer of the two.
- **Decoupling the drone record from its entity**, chosen 2026-09-03 for `B50`
  and **shipped the same day as `1b991ae`**, and **a fourth option rather than
  either of the two that were put to the author**. The entity is a *view* of a
  drone instead of the thing that owns it: every drone is advanced from the one
  globalstep `lib/register.lua` already registered, `on_deactivate` sets
  `drone.obj = nil` rather than ending the run, and the entity is re-spawned with
  the **same serial** once the drone's mapblock is loaded again — at most once a
  second, gated on `get_node_or_nil` rather than on `add_entity` failing, which
  would log an engine warning per attempt.
  **The earlier rejection of a globalstep driver was reconsidered and was
  wrong.** It had been refused as inverting `A11`'s direction of dependency, and
  that reading was mistaken: `register.lua` already registers a globalstep and
  already owns orchestration, so driving the drones from it **follows** `A11`.
  Do not re-raise it.
  **Why this over the other two.** It closes **`B50` and `B52` both**. Option A
  closed neither of `B52`'s cases. Option B closed them only by forceloading,
  which spends the game's shared `max_forceloaded_blocks` and runs ABMs wherever
  a drone goes — a `C18`-class imposition of this mod's needs on the surrounding
  game, which is the one thing this project has already decided once not to do.
  It also **saves a sleeping or paused drone**, which A did not.
  **Its two costs were accepted with the decision, not overlooked.** A far-away
  runaway loses its accidental stop: it used to be killed by its own entity
  vanishing, and now `max_nodes_written`, `max_runtime_s` and `map_memory_mb`
  carry the whole load. That is not new exposure — they already carried it for
  anything in range — but it is **the last unintended backstop going away**. And
  **`/clearobjects` stops ending programs**: it blanks the view, which comes
  back. Neither is a defect and neither should be filed as one.
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
- **A full-size cover in the release archive**, 2026-09-02. `screenshot.png` is
  the mosaic verbatim, 1.83 MB, which puts the archive at **2.21 MB** — above the
  1.60 MB the `.gitattributes` work trimmed to 1.42 MB. Deliberate: it is the one
  image Luanti draws in the Mods tab and the one the README embeds, and it had
  been four features stale, showing an editor with no tabs, no *Create a copy*
  and the checkboxes `F8` moved. **A stale cover misrepresents the mod to every
  player deciding whether to install it; 0.7 MB does not.** If the size ever
  matters, resize the cover rather than reverting to an old one — and note
  `screenshots/mozaic.png` is now byte-identical to it, so the repository carries
  the image twice while only one copy ships.
- **Slowing the display beat rather than making the panel static**, decided
  2026-09-02 for `B47`. `PERIOD` `0.5` → `1` s, one constant in `lib/hud.lua`
  driving both surfaces. It halves a dropped-click window it does not close, and
  three directions that would have closed it were each rejected for what they
  cost: *stop the self-refresh* takes away the liveness `F8` was built for,
  *quantise the string* cannot beat `F9`'s elapsed clock (which at a 1 s beat
  changes on every beat, so there is nothing left to quantise), and *act on
  mouse-down* means a `textlist` where *Pause* and *Stop* are buttons — a
  destructive action on mouse-down being worse than a dropped click. **The
  fallback is named and still unspent:** `H10` did find a few misses in twenty,
  and the next direction is the static panel rather than a shorter beat — the bar
  for taking it being misses in *ordinary use*, which is not what a rapid-press
  count measures. `AUDIT.md` holds the engine-source chain behind all of it.
- **A generator for `settingtypes.txt`, with its prose in the script rather than
  parsed out of `lib/config.lua`**, built 2026-09-02. Two audiences, two
  documents: `config.lua`'s comments are for whoever edits the code and cite
  finding ids, the menu's descriptions are for an administrator. So the script
  derives the **numbers** and owns the **words**, which is all a generator can
  honestly promise (`C19`). What it adds beyond the numbers agreeing is a
  completeness check in both directions — a setting `config.lua` reads and the
  menu does not offer, or a menu entry nothing reads — and that is the half a
  hand-kept file could never have.
- **Making a new check fail once before trusting it**, forced by `C20` on
  2026-09-02. Two checks in a row here were written, committed, believed and
  matched nothing: three name prefixes that missed every limit, then a shape
  match whose `%w+` missed the same names for a different reason. **A check that
  cannot fail is indistinguishable from a check that passes.** Both generators
  have now been run against a deliberately undrawn limit and seen to exit 1.
- **The duration on the HUD as well** — cut from `F9` on 2026-09-02. The corner
  block is four words and a number a line by design, and its first line already
  carries a filename and a state. The two surfaces disagreeing is the objection,
  and they do not: the panel says more than the HUD everywhere else too.
- **Freezing the duration while a run is paused** — cut with it, then **reversed
  the same day on seeing it in a world**, and it is the entry here that has
  changed. The objection was a paused-time accumulator disagreeing with the
  `duration:` the finish message prints; what answers it is `Drone.elapsed_us`,
  one call both surfaces read, with `tstart` shifted forward on resume rather
  than a second field kept correct. So the decision that stands is **the clock
  stops** — *how long has this build taken* rather than *how long since I started
  it*. The reasoning is under `F9`; do not re-cut it from this line.
- **Unbolding the duration by splitting it off into its own label** — decided
  against 2026-09-02, after it shipped that way for an hour. A label's font is
  per element, so *adjacent* and *not bold* cannot both hold; the author chose
  adjacent. See `F9`.
- **`doc/api.md` has a hand-written region that no check covers**, established
  2026-09-03. `gen_docs.lua` owns the file only from the `# Lua api` heading
  onward; `# Codelevel` and `# Chat commands` sit above it, are written by hand,
  and `--check` never reads them. The gate therefore reported *doc/api.md is up
  to date* while the file still documented `/codelevel` and `/codegenerate`,
  which `F10` had renamed. **Same family as `C17`, `C19` and `C20` — a mirror of
  the source drifting in silence — but the blindness is by design**, because the
  region describes chat commands and privileges and `lib/api.lua` knows nothing
  about either. Do not close it by teaching the generator to write that section:
  it would need a second source of truth for something no other file describes.
  Edit it by hand whenever a command or a codelevel limit moves, and never read
  a green `--check` as covering it. It went stale for exactly one feature.
- **A per-feature playtest check is named `F<feature>-<n>`** — asked for by the
  author 2026-09-03, when four checks were all titled `F10` and two `F1`, so no
  citation could name one of them. Numbered in document order, never renumbered,
  and a feature with one check still takes the `-1`. `F<feature>` on its own goes
  on meaning the feature, whose entry is in this file. The *Filesystem and
  example generation* group stays `F-1`–`F-5`, where the `F-` is filesystem and
  not a feature at all — confusable beside `F1-1`, and left alone on purpose:
  renaming it would break the references in `AUDIT.md` and `TODO.md` for a
  cosmetic gain.
- **No rendering has a next-step panel** — decided 2026-09-03, `playtest.html`
  first and the other two later the same day. `.reports/playtest.html`'s *What is
  outstanding* does that job instead, short and visual, each row linking to the
  category it belongs to. **`audit.html` then lost *Next step for this document*
  and `roadmap.html` its *Now* panel**, on the same reason in each case: **the
  document's own first section already says what is outstanding**, so the panel
  was a second, shorter answer to the question the section below it answers at
  length — and two answers drift. `audit.html` now opens on *The categories*
  after its summary strip, and `roadmap.html` on *Finalising v1.0.0*. Everything
  else about the three stands: summary strip, anchors matching the ids,
  self-contained, `prefers-color-scheme`, and a footer naming the commit.
  Recorded in `.claude/agents/project-manager.md`, which prescribed a panel for
  two of the three.
- **`/codeblock tools`, not `/codetools`** — chosen by the author 2026-09-03. A
  subcommand namespace over a fourth top-level name in the `/code*` family, and
  the two existing commands folded into it rather than the family left split:
  *"and we'll unify by renaming /codelevel also"*. The alternative kept three
  flat names and no room to grow.
- **Aliases for `/codelevel` and `/codegenerate`** — cut with `F10` on
  2026-09-03, on two grounds. v1.0.0 is unreleased and already carries a
  thirteen-item breaking list, so the rename costs nothing now and will cost
  something for ever afterwards; and two names for one command is a second
  surface to document, translate and keep in step. Of everything `F10` left out
  this is the one most likely to be asked for again — the answer is that it is
  cheap only until the tag.
- **A setting to keep the `fly`/`fast`/`noclip` grant** — declined 2026-09-03.
  `C18`'s treatment was offered, a `flag` in `lib/config.lua` off by default, and
  the grant was removed outright instead: nothing in this mod needs creative
  flight to be reachable, and a game that wants it sets it in its own config. **A
  setting no code path here depends on is a setting maintained for nobody.** Do
  not read `C18` as a precedent for keeping the next piece of `codecube`
  presentation behind a flag; `C18` is the exception and its own entry says so.
- **A first-join hint about anything but the tools** — cut with `F10`. The line
  names the command and the creative inventory and stops there.
- **Warning about an unknown block name at the read, not at the call site** —
  decided 2026-09-03 with `B49`. By the time a nil reaches `placement` the key
  the player typed is gone, so the message could only say *some block was wrong*;
  at the read it names `notablock`. It also covers every block-taking command at
  once, including ones added later, and it fires when the value is stored in a
  variable and placed much later. Warning at the call site would instead need
  `select('#', ...)` in a dozen sandbox wrappers just to distinguish an omitted
  argument from a nil one. **The scope is a table read and only that**:
  `place('notablock')` was never silent — it raises *Cannot place this block*.
- **A warning rather than an error, and once per run** — the author's choice,
  2026-09-03. Erroring would break saved player programs, which is a bar this
  project sets high; one line per run keeps a typo inside a loop from filling
  chat. **The accepted side effect is recorded rather than left to be
  rediscovered:** `if blocks[name] then` as a membership probe now costs one chat
  line per run. Cheap, but a visible behaviour change for that idiom.
- **An `__index` on the copy is not the read-only proxy `S1` rejects** —
  established 2026-09-03 and now pinned by `env_spec`. Proxies are refused here
  because Lua 5.1 has no `__pairs` or table `__len`, so they break `pairs(blocks)`
  and `#iwools` for player code. An `__index` on a real copy fires **only** for an
  absent key, so iteration, length and every present key are untouched. Do not
  collapse the two ideas back together. `iwools` is deliberately excluded: it is
  integer-indexed, and reading past the end of an array is legitimate.
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
- A program that probes membership with `if blocks[name] then` on a name that is
  not there gets one warning line per run. Accepted knowingly with the fix, not
  overlooked: the warning fires on an absent key and cannot tell a probe from a
  typo. (B49)
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
- **A panel button still misses a few presses in twenty**, measured by `H10` at
  a deliberate rapid pace. The 1 s beat halves the window rather than closing it,
  and there is no way to close it without giving up the panel's liveness. A
  dropped click is silent — `on_close` never runs — so the symptom is a button
  that needs pressing twice. **Accepted, not overlooked**, and the change that
  would close it is named under `B47`. (B47)
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

2026-09-04 · codeblock master at `23f0227`, which is **ahead of
`origin/master`**, plus an **uncommitted working tree holding `B51`'s fix**.
**No finding is open.** `B51` was the last: a run cut short now says *stopped*,
in English and French, and its check `D7` is written and unrun. **`B50` and `B52`
are fixed in `1b991ae` and confirmed in a running world** — the drone record and
the run are decoupled from the entity — the three checks that settle it, `W1`,
`W5` and `W6`, having all passed on **2026-09-04 at `23f0227`**, `W1` at every
codelevel. The engine version was not restated for that run.

Committed since the last record pass: `4179877` (`B48`), `b23a8bc` (`F10`,
`C21`), `d8c32f7` (`B49`), `16cd05c` (record), `0837b58` (record), `c2e541f`
(`CONTENTDB.md` and `.cdb.json`), `1b991ae` (`B50`, `B52`), `23f0227` (record).

**Gates at `1b991ae`, and again over `B51`'s uncommitted tree with the same
figures**, engine 5.17.0, read from output rather than exit codes:
luacheck silent, `doc/api.md`, `locale/template.txt` and `settingtypes.txt` all
up to date, `locale/*.tr` covering every message and nothing else, nine in-engine
specs **474 passed, 0 failed, 1 xfail, 0 xpass** — the xfail `preprocess_spec`'s
and pre-existing — and the six standalone under Lua 5.1. **CI has seen none of
it**: it was last green on all three jobs at `dc09d48` (run 44) and `471526e`
(run 45), so everything from `d8d44cd` up carries local gates only, and the first
run over `d8d44cd` also proves the fourth CI step that commit added.

**`PLAYTEST.md` stands at 60 checks, 59 of them carrying a result.** The one
without is **`D7`**, written 2026-09-04 for `B51`. No check has a fail as its
most recent result; the one partial is `H8`, only because two of its cases cannot
be performed, and `W1`'s two fails of 2026-09-03 sit below its pass as evidence
about replaced code. **`F10`'s French was read in a world on 2026-09-04** —
*"F10: french works ok"* — which closes the reading `F10-1` and `F10-2` were
owed. **`R2` still wants re-running on the release archive**, which is
**2.21 MB**.

What is left before the tag: commit `B51` and give `CHANGELOG.md` its line; play
`D7`; `README.md`'s ContentDB URLs and its Quick start; the screenshots; `R2`; a
push and a CI run; then `release-check`, the heading, and the tag.
