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

**92 findings. 86 resolved, 5 open (`S9`, `S8`, `C24`, `A17`, `A18`), 1 won't
fix (`B34`).**

**Two sandbox findings were filed on 2026-09-07, and they are the first ones
open since Phase 2.** Both come out of one probe session under plain Lua 5.1
against the real `lib/env.lua` and the real `tests/game/mods/vector3/vector3.lua`,
and **both are open with their options rather than fixed**, because each needs a
decision the code cannot make. **`S9`, high, is ranked above `S8`**: any
`vector3` instance hands back the shared class table as `v.__index`, so a
player program can replace vector3's methods — and its metamethods — **for every
other mod on the server**, and a freshly constructed vector suffices. **`S8`,
medium**, is that `env.snapshot` is shallow: `vector`'s fourteen load-time
constants are shared, so `dir = vector.one; dir.x = -dir.x` corrupts the
module's own constant for every player until restart, and the symptom
**alternates** run to run. The entries are under *Open and won't fix* with the
probe output, the fix options, and what a spec can have. **Neither is
escalation** — `getfenv` and `debug` are out of the environment, so a poisoned
method still cannot reach `core`; both are corruption that outlives the run.
**One shipped example aliased a constant and is fixed uncommitted**
(`lib/examples/game.lua`, `dir = vector.one` → `dir = vector(1, 1, 1)`); the
aliasing itself never shipped, the defect behind it did. That fix is
**compile-verified only** — `tests/preprocess_spec.lua` compiles every example
and nothing runs one — so it has a playtest, `F-6`, which is now the one unrun
check in `PLAYTEST.md`.

**Two playtest sessions ran on 2026-09-07, engine 5.17.0, and between them they
produced exactly one finding: `B54`.** The first, at `8e6350f`, gave sixteen
results in one sitting, fifteen of them passes; the one fail is `F12-4`, and its
cause is `B54` rather than anything `F12` or `F13` did. **Every result line from
it carries `8e6350f`**, the commit it was run at, not `HEAD` — `B54`'s fix
landed afterwards at `24842d3`. The second cleared the six checks that were
left — `F11-10`, `F11-11`, `F12-6`, `E17`, `W7` and `F12-4` re-run — **all six
passing, with no defect reported and so no finding filed**, at `2feadb1` over
code `24842d3`. **`PLAYTEST.md` had no unrun check and no fail after them** —
`F-6`, written later the same day for `S8`, is now the one unrun check.

**`B54` is `print` printing only its first argument, and the entry below is worth
reading for what its coverage does *not* witness.** `print` took one parameter,
so `print("is: ", is_block(colors.red))` sent `> is: ` and stopped with no error,
while the concatenated form raised correctly and unhelpfully. Twelve new spec
cases pin the **charge** — one call is one command however many arguments — and
**all twelve would have been green before the fix**, because what `print` sends
is observable from no spec at all: `test-agent` established that by probe rather
than by argument, and the probe read `nil`. **Playtest `W7` passed on
2026-09-07** at `2feadb1` over code `24842d3` — all three programs, and no
exception reported against the space-joined line wrapping on a narrow console,
which the recipe asked for on that basis and was the one part of the reasoning
nothing else could ever confirm. The fix is now confirmed in a
world.

**Three passes from that session close things that were being carried.**
**`F12-2` passed and did not hand its decision back** — the flat pure white
solid tile reads acceptably in a wall, so `F11`'s grain is not coming back to the
solids and the exact hex is kept; that question had been open for the author since
`F12` shipped and is now settled in `ROADMAP.md`. **`F11-1` passed**, so a legacy
dropdown returns the stored item and not the displayed text, which is the one
failure that would have meant converting the editor out of legacy coordinates.
**`F11-3` passed**, which is `F11`'s whole purpose observed in a third-party game.

**The game-author path was what the first session could not reach, and the
second closed it.** `F11-10`, `F11-11` and `F12-6` all need a second mod calling
`codeblock.register_blocks`; it was written to `../codeblock-test-mod` and all
three passed on 2026-09-07. So the contract in `lib/blocks.lua`, its three
refusals, the late-call seal, a registered category reaching `place()`,
`get_block()` and player meta, and a registered category's own ramp are each
**observed** rather than committed-and-unseen. **`F11-11` is the `rev_blocks`
fix's only possible evidence and it passed**, so that fix stops being written up
as correct-by-reading; it is the last thing on this document's *gates green,
unproven in a world* list to come off.

**`B53` was found by the author, filed and fixed on 2026-09-07 at `de3bcbb`**,
and it is the worst kind of defect this project has shipped into a working tree:
**every file a player created with `+` or Enter since `F11` landed on 2026-09-04
raised an error on its first statement.** The new-file template said
`place(blocks.obsidian)`, and `F11` deleted both the `blocks` category and every
`default:` node three days earlier. The full entry is in *B · Bugs*; what makes
it worth reading is why five gates stayed green over it, which is that the
template is **player code inside a Lua string literal** and nothing lints,
compiles or generates it.

**`C23` came out of covering `B53` and is resolved at `63c3c33`, 2026-09-07 —
with one caveat that is now `C24`.** `tests/preprocess_spec.lua` checked the
bundled examples against an **explicit list of names** rather than against the
directory, so an example added to `lib/examples/` and not to the list was
compiled by nothing. Both directions are now checked, against
`codeblock.examples.examples` — the set `lib/examples.lua` builds at load from
`core.get_dir_list` and ships to every player on join — and each fails **by
name** rather than by count. What unblocked the second direction was the author
deciding on 2026-09-07 to **track `lib/examples/game.lua`**; the decision and its
consequences are in `ROADMAP.md`. **The caveat: `core.get_dir_list` is in-engine
only, and CI boots no engine**, so both enumeration cases run locally and not in
CI. That is `C24`, filed the same day, and it is not `C23` left half open — the
check exists, is complete in both directions, and says `skipped:` in the one
environment that cannot run it.

**`A17` and `A18` are pre-existing and low, and neither blocks the tag.**
They were filed on 2026-09-05 while recording `F11`, and neither is a
defect `F11` introduced. **`C22` was filed on 2026-09-06 and fixed the same day
at `4450ce1`**; `C23` was filed and resolved inside 2026-09-07, and `C24`, filed
the same day out of closing it, is the only compliance finding open. No bug or
sandbox finding is.
`A17` is three exported functions in `lib/utils.lua` with no caller left,
kept rather than deleted because `codeblock.utils` is a published global and a
game may be reading them; what it wants is the author's decision. `A18` is
`meta.active = #meta.tabs` written as a loop in two places in
`lib/formspecs.lua`, verified equivalent, and the last `LUACHECK_STRICT=1`
`W421` in that file.

**`F14` is committed at `e3e2178`, `test-agent` filed no finding against it, and
all three of its checks passed on 2026-09-07 at `8e6350f`** — including
**`F14-2`**, which is the one no spec can ever replace and is now observed — `light_hues`, `dark_hues`, `neutrals` and `ramp.of(list, v, min, max)`,
adding names and renaming none. **There is no new id here.** What it left this
document is one correction, marked below: the `F12` ramp coverage entry now
records that those 57 assertions **caught the `ramp_pick` extraction** when it
was deliberately made to wrap, which is the only evidence that pulling the index
arithmetic out of `ramp_over` did not orphan them.

**`F13` is committed at `4450ce1` and closed `C22` with it.** `is_block(block,
n_right, n_up, n_forward)` is the predicate form of `F12`'s `get_block`, and the
same commit gave `.luacheckrc`'s sandbox std the both-directions check that
`C22` asked for. The finding's full entry is under *C · Compliance and
packaging* below. Its in-world checking folds into `F12-3` and `F12-4`, which
were extended rather than joined by new entries. **Both passed on 2026-09-07** —
`F12-3` at `8e6350f`, and `F12-4` on a re-run at `2feadb1` over code `24842d3`
after failing on `print` before reaching the reads — so `is_block`'s rotation is
observed.

**`F12` is committed at `01f9641` and `test-agent` filed no finding against it
either** — a new 35-colour palette (105 nodes), one `ramp` per block category in
place of `color(v, min, max)`, and relative coordinates for `get_block`. Nothing
in the committed or the uncommitted code was demonstrable as a defect, so
**there is no new id here**; what `F12` changed in this document is two wordings,
both marked below — `C10`'s misleading-command note, whose example file was
deleted at `b752ea3`, and the *unprovable by running* entry, which claimed no
spec could reach `get_block()` at all and was narrower than that. Its six
in-world checks are `F12-1` to `F12-6` in `PLAYTEST.md`, and **all six pass as
of 2026-09-07**: four at `8e6350f`, then `F12-6` and `F12-4`'s re-run at
`2feadb1` over code `24842d3`, `F12-4` having first failed on `B54`.

**`F11` is committed in two passes and `test-agent` filed no finding against
it.** `d075742` gives the mod its own 99 nodes and drops `default` and `wool`;
`6126abe` adds `codeblock.register_blocks`. (`F12` has since replaced that
palette with 105 nodes; the number here is what `d075742` did.) Both passes were verified
independently, every gate was made to fail before it was trusted, and every new
assertion was killed by a named mutant. **Three gaps were found and closed
before either commit, so none of them is a finding here**: two load-time palette
snapshots in `lib/formspecs.lua` (`pickable`, `help_categories`) and a third in
`lib/commands.lua` (`rev_blocks`) that a later `add_category` would not have
reached. The third **was a live defect** — `get_block()` would have answered
`false` for every game-registered node — and it was wrong only in code that never
shipped, which is the `F2` precedent: a feature wrong before it ships is recorded
in its `ROADMAP.md` entry, not given an id. The reasoning is under `F11` there.
**One thing about `F11` is outstanding and it is not a finding: CI has seen no
part of it**, both commits being unpushed. **All ten of its live checks now
pass** — eight at `8e6350f` on 2026-09-07 and `F11-10` and `F11-11` at
`2feadb1` over code `24842d3` the same day, with the mod at
`../codeblock-test-mod` — and `F11-4` is retired. **`F11-11` is the `rev_blocks`
snapshot fix's only possible evidence, so that fix is now observed** rather than
correct-by-reading. **The CI half is true of `F12`, `F13` and `F14` as well.** `origin/master` is at `65b4c46`; `d075742`, `6126abe`, `7514f39`,
`b752ea3`, `01f9641`, `6aadd16`, `4450ce1`, `84da24e`, `e3e2178`, `35f2aff`,
`de3bcbb`, `1865310`, `63c3c33`, `8e6350f`, `24842d3`, `1aa2f29` and `2feadb1` —
**seventeen commits**, taken from `git rev-list --count origin/master..HEAD`,
which reads **17** at `2feadb1`.
**Take the number from that command and never from counting the hashes**: it was
recorded low four passes running, each time by counting a copied-forward list by
hand. All seventeen are unpushed, so **CI has looked at
nothing since `B51`**, and it has never run the
new `.luacheckrc` check. Anything below claiming a CI state describes `65b4c46` and no later
commit.

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
| B bugs | 51 | — (`B54` found by playtest `F12-4`, filed and fixed 2026-09-07 at `24842d3`, confirmed in a world by `W7` the same day; `B53` filed and fixed 2026-09-07 at `de3bcbb`, confirmed by `E17` the same day; `B51` fixed at `8de3cea` and confirmed in a world by `D7`) — and `B34` won't fix, `B47` resolved with a residue, `B48` fixed at `4179877` and confirmed by `E16`, `B49` fixed at `d8c32f7` and confirmed by `W4`, `B50` and `B52` fixed at `1b991ae` and confirmed in a world by `W1`, `W5` and `W6` on 2026-09-04 |
| S sandbox and security | 7 | — |
| C compliance and packaging | 18 | `C24` — filed 2026-09-07: CI boots no engine, so nothing CI runs reaches an in-engine-only check. (`C23` filed and resolved inside 2026-09-07, `de3bcbb` then `63c3c33`; `C21` fixed by `F10` at `b23a8bc`, confirmed in a world by `F10-1`; `C22` filed and fixed 2026-09-06 at `4450ce1`) |
| A architecture and performance | 14 | `A17`, `A18` — both low, both pre-existing, both filed 2026-09-05 while recording `F11` |

**CI is green on all three jobs at `65b4c46`, which is `origin/master` and is
sixteen commits behind `HEAD`** — run 47, checked against the Actions API on
2026-09-04. **The count is `git rev-list --count origin/master..HEAD` and nothing
else**: it reads **15** at `24842d3`, so **16** with this record change. So **CI
has seen no part of `F11`, `F12`, `F13`, `F14`, `B53`'s fix, `C23`'s or
`B54`'s**. So nothing here carries
local gates only any more, `B47`'s fix and `settingtypes.txt`'s generator
included, and run 46 over `7dbe18f` was the first to prove the fourth CI step
`d8d44cd` added. Everything committed since is the record, the images and
the README, and touches no code. **The three changes that sat in one working tree
at `b9143b0` are now committed, all on 2026-09-03**: `B48`'s one-line fix is
`4179877`, `F10`'s rework of `lib/register.lua` — which resolves `C21` and
renames two chat commands — is `b23a8bc`, and `B49`'s unknown-block warning in
`lib/env.lua` and `lib/sandbox.lua` is `d8c32f7`, with the record following at
`16cd05c`. **CI has since seen all of them**, run 47 at `65b4c46`.
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
the client's menu. **CI has since seen all of this**: run 47 is green on all
three jobs at `65b4c46`. The record claimed the opposite until 2026-09-04.
**`F11`, `F12`, `F13` and `F14` are past that line**: the gates at `01f9641`,
`4450ce1` and `e3e2178` were all local only. At `e3e2178` they read luacheck
silent, all three `--check` generators up to date — `gen_docs.lua --check` now
also comparing `.luacheckrc`'s sandbox std with `api.names()` both ways —
`locale/*.tr` covering every message and nothing else, six standalone specs
under Lua 5.1 at 251, and **nine in-engine specs 646 passed / 0 failed /
1 xfail / 0 xpass**, `integration_spec` alone at 284. At `4450ce1` the figures
were 610 and 248, at `01f9641` 544 and 182; the 66 assertions before those were
`is_block` and `ramp_over`, and the 36 after them are `F14`'s palette views and
`ramp.of`. **`de3bcbb` is the same again**, read from output: luacheck silent,
all three `--check` generators up to date, six standalone specs under Lua 5.1,
and nine in-engine at **651 passed / 0 failed / 1 xfail / 0 xpass**, none
skipped and no errors — `integration_spec` at **288** and `preprocess_spec` at
**55**, the five new assertions being `B53`'s four and `C23`'s one. The xfail is
`preprocess_spec`'s and was **confirmed still genuinely failing rather than
passing vacuously**, which is the check `CLAUDE.md` asks for and which has
mattered here before.
**`63c3c33` the same again**, read from output: luacheck silent — and
`lib/examples/game.lua` produces nothing even under `LUACHECK_STRICT=1`, so
tracking it needed no `.luacheckrc` change — all three `--check` generators up to
date, six standalone specs under Lua 5.1 with 0 failed, and nine in-engine at
**653 passed / 0 failed / 1 xfail / 0 xpass**, none skipped and no errors,
`integration_spec` at **288** and `preprocess_spec` at **57**. **`preprocess_spec`
reports 56 standalone against 57 in-engine, and that is not a discrepancy**: the
difference is exactly `C23`'s guarded enumeration case, which counts as one
placeholder assertion standalone and as two real ones in-engine.
**`24842d3`, `B54`'s fix, is the same again and is the current figure**: all five
gates green, read from output — luacheck silent, all three `--check` generators
up to date (`doc/api.md` regenerated with `print`'s new signature),
`locale/*.tr` covering every message and nothing else, six standalone specs under
Lua 5.1, and nine in-engine at **665 passed / 0 failed / 1 xfail / 0 xpass**,
none skipped, `integration_spec` moving **288 → 300**. The twelve new assertions
are `B54`'s charge cases, and **each was driven to failure** against a
per-argument `print` — five failing the expected way and the zero-argument one in
the opposite direction with `got: 0`, a per-argument implementation charging
nothing for `print()`. `lib/sandbox.lua` was md5-verified restored afterwards.

**Every defect the playtests found is fixed, and every one is now confirmed in a
world.** The latest is **`B54`, found running `F12-4` on 2026-09-07 at `8e6350f`
and fixed the same day at `24842d3`**; its own check, `W7`, **passed later that
day** at `2feadb1` over code `24842d3`, so the fix is verified and not merely
gated. `B53` was **not** found by a playtest — the author hit
it in ordinary use on 2026-09-07, before the `F11`–`F14` session had been played,
and it is fixed the same day. `W1`'s
re-run at codelevel 1 on 2026-09-03 was `B50`, and diagnosing it produced `B51`
and `B52`; `B50` and `B52` are fixed in `1b991ae` and confirmed in a world on
2026-09-04, and `B51` is fixed at `8de3cea` on 2026-09-04 and confirmed by `D7`
the same day. The one thing **not verified anywhere** is `B10`'s refusal, aimed
at twice through playtest `D2` and missed twice — the recipe is the suspect and
its check was removed as untestable on 2026-09-02.
**Gates green, unproven in a world — two:** `B14`, permanently blocked on
`B34` being won't-fix, and `S7`'s log half. **`B54` was on it for one day** —
its spec coverage witnesses the charge and not the chat line, so `W7` was its
only possible evidence, and `W7` passed 2026-09-07 at `2feadb1` over code
`24842d3`. **`B53` never reached the list**, `E17` passing the same day. **`B51`
was on it for a few hours of
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

- **S9 · high · open, filed 2026-09-07** — every `vector3` instance exposes the
  shared class table as a writable field, so a player program can replace
  vector3's methods for the whole server.
  `tests/game/mods/vector3/vector3.lua` sets `vector3.__index = vector3`, which
  makes the metatable and the methods table **the same table**, so any instance
  hands it back as an ordinary field:

  ```lua
  local v = vector(1, 2, 3)
  v.__index.unpack = function() return 'poisoned' end
  ```

  **It needs no named constant** — a freshly constructed vector will do — so no
  fix to `S8` touches it. And because the instance metatable *is* the class
  table, `__add`, `__eq` and the rest are in reach as well, not only the named
  methods.
  **`vector3` is a global set by `vector3/init.lua`, so the blast radius is
  every other mod in the game that uses it**, not just this mod's next run.
  **Probe-verified at the library level** under plain Lua 5.1, against the real
  `lib/env.lua` and the real `vector3.lua`, on 2026-09-07:
  `is __index reachable — want: nil, got: table`;
  `next run w:unpack() — want: 4 5 6, got: poisoned`;
  `other mods, module side — want: 7 8 9, got: poisoned`.
  **Not run through a real drone**, which would have meant writing a file into a
  world; the reachability is traced end to end and the mutation is observed.
  **It is corruption, not escalation.** The class table holds vector3's own
  functions; `getfenv` and `debug` are out of the environment, and a function a
  player defines carries the sandbox fenv, so another mod calling a poisoned
  method still cannot reach `core`. **Ranked above `S8` all the same** — a fresh
  vector suffices, it replaces methods *and* metamethods rather than one field,
  and it crosses out of this mod entirely.
  **The forbidden-name list does not and must not help**: it deliberately
  ignores a name after `.` (`S3`), and it is a diagnostics aid rather than the
  boundary.
  **The fix properly belongs to `vector3`** — `local mt = {__index = vector3,
  __add = …}`, separating the metatable from the methods table, after which
  `v.__index` reads nil. That is **a separate ContentDB package by the same
  author**, so it means a release there and a submodule bump here, and it
  reaches every other consumer. **Whether it lands before or after the v1.0.0
  tag is the author's decision**, recorded as open in `ROADMAP.md`. Nothing in
  this repository reads `v.__add` as a field, so the separation breaks nothing
  here.
  **Recommended against, and recorded so it is not proposed later as the obvious
  shortcut:** reaching `getmetatable(vector3.one)` from this mod at load and
  write-protecting it. That is **`C18`'s mistake** — this mod imposing on its
  host, and here on another author's package. **Leave-and-document is not
  defensible either**, because this one crosses to other mods and not only to
  other players.
  **What a spec can have:** not `env_spec`'s, this being vector3's shape rather
  than the environment's. The assertion that holds is
  `vector(1,1,1).__index == nil`, which belongs in `integration_spec`.
  Placement is `test-agent`'s.
- **S8 · medium · open, filed 2026-09-07** — a snapshot is **shallow**, so
  `vector`'s fourteen constants are shared and mutable, and a program that
  mutates one corrupts it for every player until the server restarts.
  `lib/env.lua:31`'s `env.snapshot` copies one level and `env.snapshot_module`
  wraps it, so `lib/sandbox.lua:237`'s `['vector'] = snapshot_module(vector3)`
  hands every run the **same nested objects**. `vector3.lua:488–501` builds
  fourteen `vector3` instances at load, once — `zero one x y z xy yz xz nx ny nz
  nxy nyz nxz` — so `dir = vector.one; dir.x = -dir.x` writes into the module's
  own constant.
  **`lib/env.lua`'s header states the guarantee this breaks**: *"`snapshot`
  gives each run its own copy of the tables the API exposes, so a program
  assigning into `colors` or `vector` cannot corrupt them for every other player
  until the server restarts."* It holds for **assigning into** the table —
  verified, `snap.y = 'clobbered'` leaves `vector3.y` a table — and fails for
  **mutating through** it. **That sentence is what hid this, and it needs the
  shallow-versus-deep distinction when the fix lands.**
  **The symptom alternates**, which is worth keeping: the constant does not stay
  wrong. `run 1 start — want: 1 1 1, got: 1 1 1`;
  `run 2 start — want: 1 1 1, got: -1 -1 -1`;
  `run 3 start — want: 1 1 1, got: 1 1 1`. So a player debugging it sees it work
  on every other attempt.
  **`vector` is the only table this reaches**, checked across every
  `snapshot`/`snapshot_module` call site: the palette views and every category's
  `spelled` map hold strings only; `random.*`, `ramp.*` and `table.randomizer`
  are closures over config tables never handed out; `api.build`'s nested tables
  are built fresh per run; `_G` is sealed. Probe-verified under plain Lua 5.1
  against the real `lib/env.lua` and the real `vector3.lua`; **not run through a
  real drone.**
  **Two fixes, and the choice is the author's because they are two different
  player-visible contracts** — per-run copies, or a loud failure. Recorded as an
  open decision in `ROADMAP.md`, not as settled.
  **Deep-copy in `snapshot_module`, which `code-expert` recommends and
  `project-manager` endorses:** measured at **6.6 µs and fourteen small tables
  per program start** under plain 5.1 — `snapshot_module` runs once per
  `get_safe_coroutine`, next to a disk read, so it is free. Copy each leaf with
  `setmetatable(copy, getmetatable(v))` and the methods survive. **No observable
  behaviour change for player code**, because `vector3.__eq` (line 407) is
  component-wise and both operands share the metatable, so identity is not
  observable through `==` at all. `snapshot_module` has one caller, so *one level
  deep, leaves are vector3 instances* is a guarantee worth stating rather than a
  generic deep-copier.
  **Freeze the constants read-only** instead: costs nothing per run, but turns
  `dir = vector.one; dir.x = -1` into a raise — which breaks the author's own
  program as they just wrote it, and a player idiom that reads perfectly
  reasonable. It does nothing for `S9` or for a fresh vector.
  **Leave-and-document is not defensible**: it crosses to other players.
  **Keep — the correction, before it is repeated.** It was put to `code-expert`
  that copy-on-read would make `vector.x == vector.x` answer false. **That is
  wrong** — `__eq` is component-wise and Lua 5.1 selects it when both operands
  share a metatable, so identity is unobservable. Copy-on-read's real costs are
  that **`pairs(vector)` stops seeing the constants** (they must be absent for
  `__index` to fire, and 5.1 has no `__pairs`), a vector used as a table key
  differs on every read, and `vector.one.x = -1` becomes a write that silently
  vanishes.
  **What a spec can have:** `S8` is cleanly pinnable in `tests/env_spec.lua`,
  which stays standalone if the spec builds its **own two-level fixture** rather
  than importing vector3, and it fails against today's code by construction.
  Placement is `test-agent`'s.
  **One shipped example aliased a constant and is fixed in the working tree,
  uncommitted:** `lib/examples/game.lua` line 3, `dir = vector.one` →
  `dir = vector(1, 1, 1)`. The constructor was chosen over `vector.one:clone()`
  for three reasons recorded in `ROADMAP.md`; nothing else in the file changed.
  **The aliasing itself never shipped** — that rewrite is the author's own, made
  during the `F12-4` playtest and never committed — while **the underlying defect
  did, for the project's whole life.** The fix is **compile-verified, not
  run-verified**: `tests/preprocess_spec.lua:314–348` compiles every example and
  **nothing ever runs one**, which is `B53`'s family one level up. Its check is
  playtest `F-6`, unrun.
- **C24 · medium · open, filed 2026-09-07** — CI boots no engine, so nothing CI
  runs reaches an in-engine-only check.
  `.github/workflows/ci.yml` has three jobs: luacheck, a *preprocessor spec* job
  that installs plain Lua 5.1 and runs the **six** standalone specs, and a
  *docs are generated from the code* job running the three `--check` generators.
  **No job boots Luanti.** So `forms_spec`, `stepper_spec` and `integration_spec`
  are never run by CI at all, and neither is any case guarded on an engine
  global inside the six that CI does run.
  **What made it worth an id of its own** is `C23`'s close-out. The enumeration
  cases that finally check the shipped examples against the directory need
  `core.get_dir_list`, which exists in-engine only, so **an example added to
  `lib/examples/` and left off the spec's list is caught by a local
  `run_tests.ps1` run and is not caught by CI** — CI sees the standalone
  `skipped:` line and goes green. `C23`'s hole is closed; what is left is that
  the thing closing it is not in the gate the pull request sees.
  **Keep — this is not `C20`'s failure mode, and the difference is the point.**
  `C20` was a check that *could not fail* and said nothing about it. This one
  fails correctly wherever it runs and **announces its own absence in the output
  of the run that lacks it**: the standalone path prints
  `skipped: the shipped examples match the list, both ways - not checked here:
  needs core.get_dir_list, in-engine only`. The wording is load-bearing and not
  stylistic — `run_tests.ps1`'s report filter keeps only lines matching
  `passed|failed|FAIL|want|got|skipped|xfail`, so a note phrased any other way is
  dropped from the report, which is the exact silence the note exists to break.
  **Anyone writing a spec note here must start it with one of those words.**
  **Closing it needs either a CI job that boots the engine, or a standalone way
  to enumerate a directory — and neither is a spec change.** The first is the
  real fix and is the larger piece of work: it would also put `forms_spec`,
  `stepper_spec` and `integration_spec` under CI for the first time, which is
  288 assertions in `integration_spec` alone. The second is narrower and worse:
  Lua 5.1 has no directory primitive without `lfs`, and adding a dependency to
  the standalone path to cover one case is not a trade worth making. Queued in
  `ROADMAP.md`; it does not block the tag, because the check does run and the
  release is built from a tree a local run has covered.

**Two more are open, `A17` and `A18`, both low and both pre-existing.** (So the
open set is five: `S9` high, `S8` and `C24` medium, `A17` and `A18` low.) Their entries
are in *A · Architecture and performance* below. Neither is a defect a player
can reach: `A17` is three dead exports on `codeblock.utils` kept because the
table is a published global and something downstream may read them — the author
decides whether v1.0.0 deletes them or the surface is declared public — and
`A18` is one clear-code fix in `lib/formspecs.lua`, verified equivalent and the
last `LUACHECK_STRICT=1` `W421` in it. **Neither blocks the tag.**

**No bug finding is open. Two sandbox findings are, both filed 2026-09-07 and
both above** — `S9` and `S8`, the first sandbox findings since `S7` on
2026-08-28 and the first ones open since Phase 2. Neither is fixed and **neither
is `test-agent`'s or `code-expert`'s to settle alone**: `S8` is a choice between
two player-visible contracts and `S9`'s real fix is in another repository.
`C24` above is the only compliance one. **`B54` is the last bug**, found running playtest `F12-4` on 2026-09-07 and
fixed the same day at `24842d3` and **confirmed in a world by `W7`** later that
day. Before it `B53`, also filed, fixed and confirmed inside 2026-09-07 —
`de3bcbb`, then `E17`.
`C23` was the last compliance finding to close, filed and resolved inside
2026-09-07 as well — `de3bcbb` for one direction, `63c3c33` for the other.
Before it, `C22`, open for
part of 2026-09-06 and fixed at `4450ce1` the same day; it needs no world, being
a lint configuration, and what proves it is the check having been made to fail
eight times. Before it, `B51` was the last, and it is
fixed at `8de3cea` on 2026-09-04 and **observed fixed in a world the same day** —
the entry is in *B · Bugs* below, with the wording decision, the second caller
whose behaviour changed with it, and the constraint the fix was built to.
**`F11` added none**: it was verified pass by pass and the three gaps that were
found were closed before either commit landed.

`B34` is the one **won't fix**: it is in *B · Bugs* below. `B47` is resolved with
a residue that ships, also below, and that residue is under *What ships broken*
in `ROADMAP.md`. **`B50` and `B52` were open until `1b991ae`** and are below with
the diagnosis, the reproducer and the costs the fix accepted; both are
**confirmed in a world** since 2026-09-04.

---

## B · Bugs

50 findings, 49 resolved, `B34` won't fix, none open. `B19`, `B20`, `B24` are
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
  **Suspected and deliberately given no id, 2026-09-07.** The absent key is
  passed straight into the message, so `colors[("x"):rep(200000)]` would make
  the mod send the player a very long chat line. **It is reasoned, not probed**,
  and three things bound it: `strguard` and `max_string_mb` bound the string,
  `warned` is a per-run upvalue so it happens once, and it needs a program to be
  started. Filed here rather than as a finding because **an unprobed report is
  not evidence**; what would settle it is running that one line in a world and
  reading the chat, and if it is worth doing it belongs in `W4`.
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
- **B53 · high · resolved `de3bcbb` 2026-09-07** — the program a new file starts
  with named a block category `F11` had deleted, so **every file created with
  `+` or Enter failed on its first statement.** In `create_file` in
  `lib/formspecs.lua` the template read
  `for i = 1, 10 do place(blocks.obsidian) up(1) end`. `blocks` was the pre-`F11`
  category and `default:obsidian` a node this mod no longer depends on; `F11` at
  `d075742` (2026-09-04) renamed the categories to `colors` / `glass` / `lamps`
  and dropped every `default:` node, so `blocks` is not in the sandbox
  environment at all and the program died with *attempt to index global 'blocks'
  (a nil value)*. Reported by the author on 2026-09-07 as *"default file doesn't
  work anymore"*, and fixed the same day. Severity **high**: it is not a corner
  case but the first thing a new player does, and it was broken for three days.
  **Why five green gates said nothing, and it is the whole point of this entry.**
  The template is **player code inside a Lua string literal**. Nothing lints it,
  nothing compiles it, nothing generates it from `lib/api.lua`, and no spec
  opened it. It is the **fifth** member of the family `C17`, `C19`, `C20` and
  `C22` are in — a restatement of the source that nothing reads back — and the
  only one of the five that a player runs directly.
  **Keep — the fix names no colour, and that was argued.** `code-expert` first
  proposed `colors.orange`, a one-word change. It was rejected: naming a current
  colour rebuilds exactly the dependency that broke. What shipped is

      for i = 1, #hues do
        place(hues[i])
        up(1)
      end

  `place`, `up` and `hues` are structural names that change only in a major
  version, and `#hues` fits the loop to whatever the palette holds, so a shorter
  palette makes a shorter tower rather than an error. It is also a better first
  program — a rainbow column instead of ten identical blocks. **Do not "simplify"
  it back to a named colour.**
  **Reproduced, not reasoned about.** Both agents ran the two templates
  independently. `test-agent` put each through `get_safe_coroutine` in-engine —
  the real forbidden-name check, instrumenter, environment and command budget,
  with a stub drone at the origin: the old template died on its first statement
  with **0 commands charged**; the new one ran to completion with the drone at
  `0,10,0` and **20 commands charged**, one `place` and one `up` per hue.
  **Now covered, four cases in `tests/integration_spec.lua`.** The spec **reads
  the template out of `lib/formspecs.lua` itself** — finding the
  `write_file(name, filename,` call, scanning to the matching close paren while
  skipping quoted text, and `loadstring`ing the concatenation — rather than
  copying the string, **because a copy would be another unchecked mirror of the
  same kind.** The fourth case runs the **pre-`F11` text as a permanent control
  that must fail**, so the coverage cannot pass vacuously by resolving nothing.
  Driven to failure by breaking the anchor: cases 1 and 3 failed by name.
  **Confirmed in a world by playtest `E17`** on 2026-09-07 at `2feadb1` over
  code `24842d3` — a file created with `+` ran untouched and raised the
  ten-block column, **with the colours counted**, ten different hues rather than
  one repeated. That is what the spec cannot reach: the route from the button to
  a program a player actually runs.
- **B54 · medium · resolved `24842d3` 2026-09-07** — `print` took **exactly one
  parameter**, so it printed its first argument and dropped the rest with no
  error. `print("is: ", is_block(colors.red))` put `> is: ` in the chat and
  stopped there; writing it the other way, `print("is: " .. is_block(...))`,
  raised *attempt to concatenate a boolean value*, which is correct Lua and not
  something to work around. **The player is walled both ways**, which is why the
  report read *"the print function in the game cannot concatenate arguments"*.
  In `lib/sandbox.lua` the entry was
  `['print'] = function(str) return send_message(drone, str) end`.
  **Found running playtest `F12-4` on 2026-09-07** at `8e6350f` — the first check
  written here that made anyone want to print a **boolean**, `F13`'s `is_block`
  being three days old. That check's own recipe prints three values, so it could
  not get past its first line, and `F12-4` is recorded as a fail against `print`
  rather than against the rotation it exists for; **it was re-run and passed
  later the same day**, so that fail is a `B54` sighting and nothing owed. Severity **medium**: nothing is
  corrupted and no build is lost, but `print` is how a player debugs, and a
  debugging tool that discards its arguments silently costs more than the minutes
  it takes to hit.
  **Keep — the four decisions, each with a reason a rewrite would not
  rediscover.**
  - **The varargs are read with `select('#', ...)` and `select(i, ...)`, never
    `{...}` and `#`.** Lua 5.1 cannot see a nil in the middle or at the end of a
    vararg list, so `print("a", nil, "b")` would have truncated at the nil. This
    is not a theoretical case: **`get_block()` answers `nil` over map that was
    never generated**, so a player prints a nil routinely, and truncating would
    silently eat the rest of the line.
  - **The parts are joined with a space, not real Lua's tab.** Luanti's chat
    console has no tab stops, so a tab goes through the client font as an
    ordinary glyph rather than as alignment, and the engine's chat wrapping
    breaks on spaces, so a tab-joined line would refuse to wrap on a narrow
    console. **`lua_api.md` says nothing about either**, so this was reasoned
    from the client's text path — and **playtest `W7` is what checked it**, on an
    exception-only basis (*say if it does not wrap*), passing on 2026-09-07 at
    `2feadb1` over code `24842d3` with no exception reported against a long
    space-joined line on a narrow console. `W7` was the only thing that could
    ever say so.
  - **Zero arguments sends a bare `> `, deliberately.** `print()` in real Lua is
    a blank separator line, and refusing to send would make it the one API call
    that silently does nothing. It still costs one command, so it cannot be
    spammed free. `drone_send_message` does `'> ' .. tostring(string)`, so an
    empty join gives `> ` and not `> nil`.
  - **`error` was deliberately not widened.** Real Lua's `error(message, level)`
    is not variadic, and matching real Lua is the whole contract here.
  **Keep — what the coverage does and does not witness, because the distinction
  is the honest reason `W7` is not optional.** **What `print` sends cannot be
  observed by any spec, and `test-agent` proved that by experiment rather than by
  argument**: it added a probe capturing `core.chat_send_player` around a real
  `print("a", "b")` and asserted `> a b`. The probe **failed**, reading
  `want: > a b, got: nil`; it was then removed and the result kept as a comment
  in `tests/integration_spec.lua`. **Two load-time locals each suffice to shut it
  off** — `lib/commands.lua:26` binds `chat_send_player` and `lib/sandbox.lua:36`
  binds `drone_send_message` — and there is no logged-in player to receive the
  line either. So **no case was written asserting that `print` merely does not
  raise**: the broken `print` did not raise, and such a case would have been
  green throughout the defect. What the **twelve** new cases pin instead is the
  one invariant a spec can see: **one call is one command however many arguments
  it carries**, the join happening in the sandbox so `drone_send_message` keeps
  taking one value and charging once. Driven to failure against the plausible
  re-break — `print` looping `send_message` per argument, which is what someone
  reaching for variadic writes first — **five of the six charge cases failed, and
  the zero-argument one failed in the opposite direction with `got: 0`**, a
  per-argument implementation charging nothing at all for `print()`.
  `lib/sandbox.lua` was restored and md5-verified afterwards.
  **State it plainly: all twelve would have been green before the fix.** They
  guard the new implementation against a refactor; they do not witness the
  defect. **`W7` is what witnesses it**, and nothing else will — and it did, on
  2026-09-07 at `2feadb1` over code `24842d3`, reading `> is: true`, a bare
  `> ` for `print()` and `> a nil b` with no truncation.
  The change also touched `lib/api.lua` — `params = {'message', '...'}` and
  *Print every argument in the chat, joined by a space* — with `doc/api.md`
  regenerated from it.
---

## S · Sandbox and security

9 findings, 7 resolved. **`S8` and `S9` are open**, both filed 2026-09-07; their
full entries are under *Open and won't fix* above and are not repeated here.
`S9` is high — `v.__index` is vector3's own class table, writable, and shared
with every other mod using the `vector3` global. `S8` is medium — `env.snapshot`
is shallow, so `vector`'s fourteen load-time constants are mutable through and
shared across runs. `S2`'s residue is one of the things v1.0.0 ships broken.

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
  **The guarantee is narrower than it was written, and `S8` and `S9` are
  where.** The copies are **shallow**: they isolate *assigning into* a snapshot
  and not *mutating through* it, so `vector`'s load-time constants are shared
  (`S8`). And the shared metatable is safe from `getmetatable` but not from
  `v.__index`, which vector3 exposes as an ordinary field (`S9`).
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

18 findings, 17 resolved — `C21` by `F10`, committed at `b23a8bc`, `C22`
at `4450ce1`, and `C23` at `de3bcbb` and `63c3c33`. **`C24` is open**; its full
entry is under *Open and won't fix* above and is not repeated here.
`C2`–`C5` and `C15` are the game's; `C9` never used.

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
  **Keep — read the archive by its top level, not by grepping it.**
  `git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u` is
  what answers the question. `grep tests` over the whole listing answered *fail*
  on a correct archive for the project's whole life, because `lib/examples/tests.lua`
  is a player-facing example and matched it. That file was **deleted at
  `b752ea3`**, so the example no longer bites — the rule it taught does.
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
- **C22 · low · resolved** — `.luacheckrc`'s `codeblock_sandbox` std is a
  **fourth hand-kept mirror of `lib/api.lua`** and had drifted: `sleep` (`F3`)
  and `default_block` (`F1`) were in the API, in `getScriptEnv`'s `impls` and in
  `doc/api.md`, and in neither case in the std list. The list's own comment said
  *keep this list in sync with `getScriptEnv()`*, which is the note-about-
  remembering that `C17`, `C19` and `C20` each proved does not hold. Filed by
  `test-agent` on 2026-09-06 while covering `is_block`, because `luacheck .` was
  not silent; fixed the same day at `4450ce1`.
  **How it failed.** The list exists so luacheck catches a typo'd API name in a
  shipped example (`A2`). A name missing from it inverts that: an example
  calling a **correct** name is reported `(W113) accessing undefined variable`,
  which reads as a typo and invites someone to change working player code.
  Nothing tracked used either name, so **the gate was silent on a clean
  checkout** and CI never saw it; committing any example that pauses or sets a
  default would have turned the luacheck job red for a correct program.
  **A third discrepancy surfaced during the fix**: `_` was in the std while
  `lib/api.lua` describes nothing of the kind. It is what the examples pass to
  mean *use the default for this argument*, and it moved to
  `files["lib/examples/**"].read_globals`, which luacheck adds to the std. That
  is what makes the comparison a clean equality rather than an equality with an
  exemption list.
  **Fixed by checking rather than generating**, which is the difference between
  this mirror and the other three: `.luacheckrc` is a linter configuration a
  human also edits, so it stays hand-written and
  `scripts/gen_docs.lua --check` compares its std against
  `codeblock.api.names()` **in both directions** and names what is missing on
  either side. It runs in write mode too, so the generator refuses to write
  `doc/api.md` while the two disagree.
  **Keep — the std holds API names and nothing else.** That rule is what the
  check enforces, and anything that is not an API name goes in the
  `files["lib/examples/**"]` block instead. Putting one back in the std fails
  the gate by name.
  **Keep — a bare string entry is an escape hatch, and a silent one.** luacheck
  accepts *every* field of a bare-string name, which is what `table` and
  `vector` need, so replacing `ramp = {fields = {...}}` with a plain `"ramp"`
  passes the check and switches off typo-catching for `ramp.*` with nothing
  going red. The check deliberately asserts what luacheck actually enforces
  rather than something stricter, and the script's comment states the leniency.
  `random` was tightened to `random = {fields = {"color", "glass", "lamp"}}` for
  the same reason `ramp` is spelled out.
  **Read by `loadfile` and `setfenv`, not by pattern-matching**, which is the
  `C20` lesson applied before the fact: two earlier checks here matched nothing
  from the day they were written because Lua's `%w` excludes the underscore
  every name they matched contains. Loading the config means a nested
  `ramp = {fields = {...}}` costs nothing to read correctly.
  **Made to fail before being trusted, twice over and independently.**
  `code-expert` broke it four ways; `test-agent` then broke it four ways of its
  own rather than taking the report, at both nesting levels and in both
  directions.
- **C23 · medium · resolved, `de3bcbb` then `63c3c33` 2026-09-07** — the shipped
  examples were checked against a hand-kept list of names, not against the
  directory, so an example added to `lib/examples/` was compiled by nothing.
  `tests/preprocess_spec.lua` is the only thing that compiles them. The list held
  fourteen names, one of which was `tests` — an example deleted at `b752ea3` —
  and **that dead entry was the only reason fourteen names asserted thirteen
  files.** The count agreed by coincidence.
  **It is a `C` deliberately.** `C17`, `C19`, `C20` and `C22` are each *a mirror
  of the source that drifts in silence*, and a hand-kept list of what is in a
  directory is one of those: the directory is the source, the list is the
  restatement, and nothing fails when they disagree.
  **Fixed in two commits.** `de3bcbb` removed the dead `tests` entry, made the
  expected count `#names` rather than a literal, and made a listed name with no
  file fail **by name**. `63c3c33` added the other direction, comparing the list
  with `codeblock.examples.examples` — which `lib/examples.lua` builds at load
  from `core.get_dir_list`, keyed by bare name with `%.lua$` stripped, and which
  is the set copied into every player's directory on join. Fourteen names, `game`
  among them.
  **Both directions were driven to failure and each names the offender.** A
  listed name with no file gives
  `every listed example is a file that exists — want: "" got: "nosuchexample"`;
  a file the list omits gives
  `every example shipped is on the list — want: "" got: "torus"`.
  **What unblocked it was a decision, not code.** The second direction was
  deferred at `de3bcbb` because the author's `lib/examples/game.lua` was
  untracked and sitting in that directory, so a two-way check would have gone
  **red locally and green in CI**, which is backwards. On 2026-09-07 the author
  chose to **track the file**; the decision and its two consequences are in
  `ROADMAP.md`.
  **Keep — the residual is `C24`, and it is not this finding left half open.**
  `core.get_dir_list` is in-engine only and CI boots no engine, so both
  enumeration cases run in a local `run_tests.ps1` run and not in CI. The check
  is complete; the gate that sees it is not.

---

## A · Architecture and performance

14 findings, 12 resolved, `A17` and `A18` open. `A7`, `A8`, `A13`, `A14` are the
game's. Closing `A3`,
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
- **A17 · low · open** — three exported functions in `lib/utils.lua` have no
  caller anywhere in the repository: `table_reverse` (line 47), which lost its
  last one in `F11`'s second pass, `table_convert_ik` (53), which lost its last
  in the first pass, and `table_convert_iv` (60), which never had one. Found
  2026-09-05 while recording `F11`; grepping `lib/`, `init.lua`, `scripts/` and
  `tests/` for each name returns only its own definition.
  **Not deleted, deliberately, and that is the whole finding.** They are on
  `codeblock.utils`, which is a global table this mod publishes, so a game or
  another mod could be reading them — the same reasoning `F11` used for
  `codeblock.register_blocks`, one level down. Deleting them is a silent
  breaking change to an unversioned surface; keeping them is three functions
  nothing exercises. **What is wanted is the author's decision, not a cleanup:**
  either delete all three in v1.0.0, where a breaking change is free, or state
  that `codeblock.utils` is public and leave them. Doing nothing keeps them dead
  and keeps the question.
- **A18 · low · open** — `lib/formspecs.lua` writes `meta.active = #meta.tabs`
  as a loop in two places: `remove_active` (line 470) and `close_active` (578)
  each end with
  `for i, filename in ipairs(meta.tabs) do meta.active = i end`, whose body runs
  once per tab to leave the last index behind, and whose `filename` is never
  read. **Verified equivalent**, so this is clarity and not correctness — and it
  is the last remaining `LUACHECK_STRICT=1` `W421` in that file, which is the
  only reason it is worth an id at all. Pre-existing; `F11` touched neither
  function. Fixing it is two one-line replacements and wants a spec run behind
  it like any other edit to that file.

---

## Evidence: verified, committed, claimed

Never blurred. **Verified** means a run or a reading demonstrates it,
**committed** means the code is there and unproven, **claimed** means only a
document says so.

- **Verified by machine.** CI runs 44 (`dc09d48`), 45 (`471526e`),
  46 (`7dbe18f`) and **47 (`65b4c46`, `origin/master`)**, all three jobs green in
  each: luacheck, the six standalone specs under plain Lua 5.1, and the three
  `--check` gates. **CI never runs the nine in-engine specs**, which is why the
  editor findings rest on the local suite and the playtests. **CI has seen no
  part of `F11`, `F12`, `F13`, `F14`, `B53`'s fix, `C23`'s or `B54`'s** —
  **eighteen commits**, `git rev-list --count origin/master..HEAD` reading 18 at
  `6f2dfe0`, all unpushed with `origin/master` still at `65b4c46`. Take that
  number from the command and never from counting hashes, which is how it was
  recorded low four passes running.
- **Verified locally** (engine 5.17.0, read from output rather than exit codes —
  `$?` does not survive this machine's WSL layer): nine in-engine specs, **474
  passed / 0 failed / 1 xfail / 0 xpass** at `1b991ae`, with all five gates
  green. The count moved 458 → 471 → 474: 458 was the run after `B47`'s beat
  change and the `settingtypes.txt` generator, 471 added 13 `env_spec` cases for
  `B49`, and 474 added three to `integration_spec`'s drone-seam block for
  `B50`/`B52`. **`F11` was verified the same way over both its passes** —
  luacheck silent, all four `--check` generators up to date, the six standalone
  specs under Lua 5.1 and the nine in-engine, **0 failed and 0 xpass**, with
  `integration_spec` at **167 assertions**. `test-agent` also **made every gate
  fail on purpose** before reading it as green, and killed each new assertion
  with a named mutant, which is the `C20` rule applied to a whole feature rather
  than to one check. **`F12` the same, at `01f9641`**: 544 in-engine assertions
  across the nine, `integration_spec` at **182**, 0 failed, 0 xpass, 1 known
  xfail, three `--check` generators up to date, `locale/*.tr` complete, six
  standalone specs green — and every changed or new assertion made to fail once
  against **ten separate deliberate breaks**, with `md5sum` confirming `lib/`
  was restored byte-identical afterwards. **`F14` the same, at `e3e2178`**: 646
  in-engine assertions across the nine, `integration_spec` at **284**, 0 failed,
  0 xpass, 1 known `preprocess_spec` xfail, none skipped and no errors; the six
  standalone specs unchanged at 251; luacheck silent and all three `--check`
  generators up to date — and `test-agent` ran them itself rather than taking
  `code-expert`'s word. Its 36 new assertions were driven to failure **three
  ways**, each reverted with `lib/sandbox.lua` confirmed byte-identical by
  SHA-256: the views bound to the wrong lists with one published unsnapshotted
  (11 failed, the config leak visible), `ramp.of` given a shifted argument list
  (9 failed), and `ramp_pick` wrapping instead of clamping (11 failed).
  `codeblock_run_tests` was confirmed
  gone from `%APPDATA%\Minetest\minetest.conf` after the run.
  **`de3bcbb` the same, over `B53` and `C23`**: luacheck silent, all three
  `--check` generators up to date, six standalone specs under Lua 5.1, nine
  in-engine at **651 passed / 0 failed / 1 xfail / 0 xpass**, none skipped and no
  errors, `integration_spec` at **288** and `preprocess_spec` at **55**. The one
  xfail was checked for being **genuinely failing rather than vacuous**, which is
  the distinction this project has been caught by before. `B53`'s four new cases
  were driven to failure by breaking the anchor the spec reads the template
  through, and `C23`'s by putting the deleted `tests` name back in the list.
  **`63c3c33` closes `C23` and is green on the same terms**: luacheck silent,
  including under `LUACHECK_STRICT=1` over the newly tracked
  `lib/examples/game.lua`; all three `--check` generators up to date; six
  standalone specs under Lua 5.1 at 0 failed; nine in-engine at **653 passed /
  0 failed / 1 xfail / 0 xpass**, none skipped and no errors, `integration_spec`
  at **288** and `preprocess_spec` at **57**. Both new enumeration cases were
  driven to failure and each named the offender rather than reporting a count.
  `preprocess_spec` reads 56 standalone against 57 in-engine, which is the
  guarded case counting once instead of twice and not a discrepancy.
  **`6f2dfe0` is green on the same terms, read on 2026-09-07 while filing `S8`
  and `S9`**: luacheck silent; `doc/api.md`, `locale/template.txt` and
  `settingtypes.txt` each *up to date*; the six standalone specs at
  **30 / 56 / 34 / 31 / 29 / 73** with 0 failed and 0 xpass; the nine in-engine
  at **665 assertions** (30, 57, 34, 31, 29, 73, 66, 45, 300), 0 failed, 0
  xpass, one known xfail, no errors. `codeblock_run_tests` confirmed gone from
  `%APPDATA%\Minetest\minetest.conf`, no BOM. **Nothing in that run covers `S8`
  or `S9`** — they were found by probe, not by the suite.
- **Verified by probe, at the library level, and not through a drone.** `S8` and
  `S9`, 2026-09-07: a script under plain Lua 5.1 loading the real `lib/env.lua`
  and the real `tests/game/mods/vector3/vector3.lua`, with the outputs quoted in
  each entry — the alternating constant for `S8`, the three poisoned reads for
  `S9`. **Neither was run through a real drone**, which would have meant writing
  a file into a world; the reachability is traced end to end from
  `lib/sandbox.lua:237` and the mutation is observed. That is the strongest
  evidence either has, and it is weaker than a playtest.
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
- **Gates green, playtest written and not yet run — one, `F-6`.** It is the
  check for the `lib/examples/game.lua` fix under `S8`, and the fix itself is
  **not committed**, so it is not even gates-green yet: what the gates cover is
  that every example **compiles**, `tests/preprocess_spec.lua:314–348`, and
  **nothing ever runs one**. `F-6` runs `game.lua` twice and reads the second
  start direction, which is the symptom the aliasing produced. This list was
  empty earlier the same day, and what it recorded then is below.
  `F11` and `F12` put
  sixteen checks on it: `F11-1` to `F11-11` written 2026-09-05 at `6126abe`,
  `F11-4` since superseded by `F12-1` and `F12-2`, leaving ten, and `F12-1` to
  `F12-6` written 2026-09-06 at `01f9641`. **All sixteen have now been run** —
  most at `8e6350f` on 2026-09-07 and the last three at `2feadb1` over code
  `24842d3` the same day — and so have `E17` and `W7`, added for `B53` and
  `B54`. That was the whole of the outstanding evidence for both features:
  **nothing either does is provable by the specs** — a registered node, a
  texture, a creative-inventory listing, the picker, the help row, a game's own
  registration, a ramp read as a gradient and a `get_block` that lands inside
  the world all need a world. No finding was behind them; a feature's checks
  being unrun is outstanding *checking*, not unfinished work.
- **Correct by reading, unprovable by running.** The `rev_blocks` fix in
  `lib/commands.lua` — the third of `F11`'s load-time snapshots, and the one
  that was a live defect. Its evidence is playtest `F11-11` and nothing else,
  and **`F11-11` passed on 2026-09-07** at `2feadb1` over code `24842d3`:
  `get_block()` answered a game-registered category's own name rather than
  `false`. **So it is no longer correct-by-reading — it is observed**, and the
  claim should not be written up as an outstanding risk again.
  **`F12` narrowed this claim and it is worth stating exactly, because it was
  overstated once.** `codeblock.commands.drone_get_block` is exported, so a spec
  *can* call `get_block`, and `integration_spec` now asserts its out-of-world
  branch. What no spec can do is a read that lands **inside** the world:
  `lib/commands.lua` captures `core.get_node` at load, and `test-agent` probed
  it at the origin at mod load, where it dies inside builtin with
  `bad argument #1 to '__index' (number expected, got nil)` because content ids
  are not cached yet. **There is no position anywhere at which an in-world read
  can be asked for from the suite** — measured, not assumed, so nobody spends
  the afternoon again.
- **Provable by running after all: the new-file template.** It sits in a Lua
  string in `lib/formspecs.lua`, a formspec file the suite otherwise cannot
  exercise, and it looked like editor code and therefore playtest territory. It
  is not: `integration_spec` **reads the string out of the source** and runs it
  through `get_safe_coroutine`, which is the real environment. That is `B53`'s
  coverage, and the reason it reads the source rather than holding a copy is
  that a copy would be one more mirror of the same kind.
- **Unprovable by running, and permanently so: a chat line the mod sends a
  player.** Found while covering `F14`. `lib/sandbox.lua` binds
  `chat_send_player` as a **load-time local**, so replacing
  `core.chat_send_player` around a run intercepts nothing, and there is no
  logged-in player to receive it in any case. A spec can only assert that the
  run did not raise — which passes against a **reporting** version as well, and
  is therefore vacuous, the same failure mode as the two checks in `C20`. So
  *the unknown-block warning does not fire for a legitimate read past the end of
  a palette view* is playtest `F14-2` and can never be a spec. It is checked
  against a genuine misspelling in the same session, because one must report and
  the other must not. **`F14-2` was run on 2026-09-07 at `8e6350f` and passed**,
  so that asymmetry is now observed rather than reasoned.
  **`B54` widened this entry, and it is a second local, not the same one.**
  `lib/commands.lua:26` binds `chat_send_player` too, and
  `lib/sandbox.lua:36` binds `drone_send_message`, so the route `print` takes is
  shut at both ends. `test-agent` **drove that to a result rather than asserting
  it**: a probe capturing `core.chat_send_player` around a real
  `print("a", "b")` read `want: > a b, got: nil`, and the probe was removed and
  the finding kept as a comment. So **what `print` puts in the chat is playtest
  `W7` and can never be a spec** — and **`W7` was run on 2026-09-07 at
  `2feadb1` over code `24842d3` and passed**, which is the only evidence `B54`
  can have. The twelve cases that were written pin the
  *charge* instead — one call is one command — all twelve of which would have
  been green before the fix. **Do not later "correct" the two locals into one.**
  The `F14-2` misspelling report goes through `lib/sandbox.lua`'s binding at
  line 8, used at line 126; `print` goes through `lib/commands.lua`'s. Both
  claims in this document are right as written, and this was checked on
  2026-09-07 after they were reported as a misattribution.
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

- **A wrong reason given to `code-expert` while shaping `S8`'s fix, 2026-09-07,
  recorded because it is the kind of claim that gets repeated.** It was put to
  it that copy-on-read would make `vector.x == vector.x` answer false. **It
  would not:** `vector3.__eq` is component-wise and Lua 5.1 selects it when both
  operands share a metatable, so identity is not observable through `==` at all.
  Copy-on-read's real costs are that **`pairs(vector)` stops seeing the
  constants** — they must be absent for `__index` to fire, and 5.1 has no
  `__pairs` — that a vector used as a table key differs on every read, and that
  `vector.one.x = -1` becomes a write which silently vanishes. The same fact is
  what makes the recommended deep copy invisible to player code.
- **A correction that was itself wrong, checked and not made, 2026-09-07.** It
  was reported that the `F14` comment in `tests/integration_spec.lua` and four
  sites in this record misattribute the load-time `chat_send_player` binding to
  `lib/sandbox.lua` when it belongs to `lib/commands.lua`. **Both files bind
  it.** `lib/sandbox.lua:8` binds `chat_send_player` and uses it at line 126,
  which *is* the misspelling report `F14-2` is about; `lib/commands.lua:26` binds
  the one `print` goes through. **The four sites are about the misspelling report
  and are correct as written**, and nothing was changed. Recorded so a future
  pass does not "fix" them.
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
- **Three things `F12` found the record had wrong, none of them a finding.**
  (1) `tests/api_spec.lua`'s name list was described here and in `ROADMAP.md` as
  a pre-existing historical capture; it was **68 names against 73 described**,
  `sleep` and `default_block` having been added to `lib/api.lua` and never
  written down, and the one-way check could not say so. It is now bidirectional.
  (2) `integration_spec`'s `refused_for('color', …)` was reported by
  `code-expert` as passing vacuously; it was **failing** in the baseline, `color`
  being free so the category installs. Replaced by `ramp`, which also proves a
  dotted name reserves its first segment. (3) `code-expert` reported `get_block`
  as unreachable from the suite; `codeblock.commands.drone_get_block` is
  exported, so only an **in-world** read is unreachable — see *unprovable by
  running* above.
- **The count of unpushed commits was wrong in three successive passes of this
  record**, always low and always by the same mistake: the list of hashes was
  copied forward and counted by hand, and the record change that was uncommitted
  when it was written became a commit nobody added. It is now taken from
  `git rev-list --count origin/master..HEAD` — **15 at `24842d3`, so 16 with
  this record change**. It went wrong a **fourth** time in the pass before this
  one, the same way: the list read fourteen where the command read fifteen.
  **Take the number from that command every time and never count the hashes.**
- **`B53` is the fifth member of the drifting-mirror family, and the first a
  player runs.** `C17`, `C19`, `C20` and `C22` are all a restatement of the
  source that nothing reads back; the new-file template was another, and it
  broke every file a player created for three days with five gates green over
  it. `C23`, filed the same day, is a sixth — and unlike the other five it is
  **fully closed rather than checked in one direction**, both at `63c3c33`.
- **One thing `F13` found the record had wrong, and it was this document's own
  and `ROADMAP.md`'s.** Both said `ramp_over`'s clamping *has no spec coverage
  at all* and that covering it would mean exporting a private closure factory.
  It has **57 assertions** across all four built-in ramps as of `4450ce1` — six
  clamping semantics plus the property `ramp.hues` exists for, that its answers
  are the plain shade of a family and never a `light_`/`dark_` one — and eight
  mutations of `lib/sandbox.lua` were each caught. **Exporting `getScriptEnv`
  was offered and refused**, because pinning a spec to a private closure factory
  is pinning to the implementation. What reaches it instead is the only real
  door: the spec **writes a program into the throwaway world** and runs it
  through `get_safe_coroutine`. What remains unprovable is the *visual* half —
  a gradient reading as a gradient — which is `F12-5`. **`F14` then made those
  57 assertions earn their keep**: extracting `ramp_over`'s index arithmetic
  into `ramp_pick`, which `ramp.of` now *is*, risked orphaning them, and
  `ramp_pick` deliberately made to wrap instead of clamp failed **eleven
  assertions, all of them in this pre-existing section**. The refactor is
  covered by the coverage it might have broken.

---

2026-09-07 · describes codeblock at `63c3c33`, plus this record change,
uncommitted at the time of writing.

**89 findings, three open — `A17`, `A18` and `C24`.** `A17` and `A18` are low
and pre-existing and neither blocks the tag; `C24` is medium, filed 2026-09-07
out of closing `C23`, and says that CI boots no engine so nothing CI runs
reaches an in-engine-only check. **`C23` is resolved**, both directions, at
`de3bcbb` and `63c3c33`. **`B53` was
filed and fixed on 2026-09-07 at `de3bcbb`** — the new-file template naming a
category `F11` deleted, so every file a player created since 2026-09-04 raised
on its first statement.
`F11` (`d075742`, `6126abe`) and `F12` (`01f9641`) each
landed with every gate green and **no finding filed against either**. `F13`
(`4450ce1`) added `is_block` and, filed against code older than any of the
three, `C22` — the fourth mirror of `lib/api.lua`, resolved in the same commit.
What this document gained from `F12` is
three corrections, all above: `C10`'s misleading-command note, whose example file
`lib/examples/tests.lua` was deleted at `b752ea3`; the claim that no spec can
reach `get_block()` at all, which was narrower than true; and the three things
the previous record had wrong about `tests/api_spec.lua` and
`integration_spec`.

**Gates at `de3bcbb`, local only**, read from output rather than
exit codes: luacheck silent, `doc/api.md`, `locale/template.txt` and
`settingtypes.txt` each *up to date*, six standalone specs under Lua 5.1, and
nine in-engine **651 passed / 0 failed / 1 xfail / 0 xpass**, none skipped and
no errors, `integration_spec` at 288 and `preprocess_spec` at 55. The
xfail is `preprocess_spec`'s, pre-existing, and confirmed still genuinely
failing. At `e3e2178` the same run was 646 and 284, at `4450ce1` 610 and 248, at
`01f9641` 544 and 182.

**CI has looked at none of it.** `origin/master` is at `65b4c46` — run 47, green
on all three jobs, checked against the Actions API on 2026-09-04 — and
**seventeen** commits are unpushed, `git rev-list --count origin/master..HEAD`
reading 17 at `2feadb1`. **With the playtests done, the push is the largest
thing outstanding in this project.**

**Gates green, unproven in a world is two**, `B14` and `S7`'s log half; `B54`
left the list on 2026-09-07 when `W7` passed. **No playtest check carries a
fail. One is unrun**, `F-6`, written later on 2026-09-07 for `S8`'s example fix;
before it the six that had been outstanding — `F11-10`, `F11-11`, `F12-6`,
`E17`, `W7` and `F12-4` re-run — all passed that day at `2feadb1` over code
`24842d3`, with no defect reported. `F11-4` is **retired**, both its successors
having passed.

**Two findings are open with no fix chosen**, `S8` and `S9`, and that is the
honest state: the reachability is traced, the mutation is probe-verified at the
library level, **nothing is fixed** except one uncommitted line in a shipped
example, and both fixes wait on the author — `S8` on which contract player code
gets, `S9` on a release of another package.

---

Last reviewed **2026-09-07**, describing commit **`6f2dfe0`** — record-only,
over code `24842d3`. It records `S8` and `S9`, filed the same day from one probe
session and both **open with their options**, the `lib/examples/game.lua` fix
that is in the working tree and uncommitted, and playtest `F-6` written for it.
