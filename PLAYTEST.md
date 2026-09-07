# Playtest — CodeBlock

The manual checks the automated suite cannot reach. The nine specs run **at mod
load**, before a map, a player or a user directory exists, so the editor, drone
placement, the filesystem and every write into the world have no spec coverage
and cannot have.

This file has its own `export-ignore` line, so it never ships to a player.

## How to record a result

```
Result: pass — de3bcbb · engine <version> · <YYYY-MM-DD> — <one line of detail>
```

`fail` and `partial` take the same shape. **Always keep the commit and the
date**: a pass recorded three phases ago is not evidence about today's code. A
`fail` is not a finding — report it and let `AUDIT.md` allocate or widen an id.
Reasoning lives in `AUDIT.md` under the bracketed id, or `ROADMAP.md` for an `F`.

## How a check is written

**Hand the runner an actual program or command to run**, not a description of
one. The author's note on 2026-09-04: *"playtest 'DO' with examples/commands
given is nice."* `W1`'s reproducer, `W4`'s loop and `W5`'s three lines are what
that means; the older checks in this file describe a gesture and leave the
program to be invented, which is slower and is not the same program twice.
A recipe also **names the shell it is for** — that has cost a session twice
(`F-3` case 2, `D2`'s removed case).

## Where it stands

**82 entries, of which `F11-4` is retired — so 81 live checks. Five are unrun
and one carries a fail**, which is the smallest this document has been able to
say since `F11` landed and the first time it has had to say *fail* since
2026-09-03.

**The session of 2026-09-07 at `8e6350f`, engine 5.17.0, is the largest run this
project has had: sixteen results in one sitting.** Fifteen passes — `F11-1`,
`F11-2`, `F11-3`, `F11-5` to `F11-9`, `F12-1`, `F12-2`, `F12-3`, `F12-5` and all
three `F14-n` — and **one fail, `F12-4`, which is `B54`**. It was run at
`8e6350f`, so every result line carries that commit and not `HEAD`; `B54`'s fix
landed afterwards at `24842d3`.

**What is outstanding, and it is five entries and one re-run:**

- **`F11-10`, `F11-11` and `F12-6` — all three need a second mod calling
  `codeblock.register_blocks`.** That is the **entire game-author path**, and it
  now has **no in-world evidence at all** while every other part of `F11`, `F12`
  and `F14` has. The contract, the refusals, the late-call seal, a registered
  category reaching `place()`, `get_block()` and player meta, and a registered
  category's own ramp are all committed, gated and unseen. They are cheapest run
  in one session, since `F11-11` and `F12-6` both want `F11-10`'s mod. **`F11-11`
  is also the `rev_blocks` fix's only possible evidence.**
- **`E17`**, written 2026-09-07 at `de3bcbb` for `B53` — a brand new file
  running as it is. Nothing in the *Editor* group would have caught `B53`, because
  every other check there opens a file that already exists.
- **`W7`**, written 2026-09-07 for `B54` — what `print` puts in the chat. No
  spec can see it, which `test-agent` established by running a probe and watching
  it read `nil`.
- **`F12-4` must be re-run**, on `24842d3` or later. Its fail is against `print`
  and says nothing about the rotation it exists for: the recipe's own first line
  prints three values, so on the broken build the check stopped before the reads
  were looked at.

**This is outstanding *checking*, not unfinished work** for the four features:
`F11` to `F14` are committed with their gates green and no finding against any of
them. `B54` is the one finding this session produced, and it is fixed.

**`F13` added no entry, and that is deliberate.** `is_block` is `get_block`'s
read path, so `F12-3` and `F12-4` were **extended** at `4450ce1` rather than
joined by a group of their own: a separate group would walk to the same three
positions twice. `F12-3` passed; `F12-4` is the one owed a re-run. `F12-5` was
narrowed the same day: `ramp_over`'s clamping now has spec coverage, so what was
left there was the visual half, and it passed.

**`F11-1` was run first and passed, which is the expensive question answered.**
It was the only one of the twenty whose failure would have cost anything: a
legacy dropdown returning displayed text rather than the stored item would have
meant converting the editor out of legacy coordinates. **It returns the stored
item**, in French and in English, so the editor stays where it is.

**`F12-2` passed and did not hand the decision back.** It was written expecting
to: `F12` made the solid tile a flat pure white so `^[multiply` reproduces each
hex exactly, which removed the grain `F11` had deliberately put there and left a
wall of one solid colour with no node-edge definition at all. **The wall reads
acceptably**, so the flat tile stays, the exact hex is kept, and the question is
closed rather than carried. It is in `ROADMAP.md` under *other decisions* so it
is not proposed again.

**`F11-4` is retired rather than superseded-and-owed.** It checked 33 colours
reading as their hexes and a wall showing the grain; `F12` replaced the palette
with 35 and removed the grain from the solids, so both halves moved — the hexes
to `F12-1`, the wall to `F12-2`. **Both passed on 2026-09-07**, so everything it
was for has been looked at in its current form. The entry stays in place as a
pointer, because `F11`'s checks are numbered in commit messages and the record.

**Two passes are worth more than a tick.** **`F14-2`** is the check `test-agent`
could not turn into a spec — reading past the end of a palette view stays silent
while a genuine misspelling still reports — and it is now **observed rather than
reasoned**, which is the only kind of evidence it can ever have. **`F11-3`** is
the whole point of `F11`: the mod loading and building in a third-party game that
ships neither `default` nor `wool`, which nothing local could show.

**One fail is the most recent result on one check** — `F12-4`, above — and one
result is a partial, `H8`, only because two of its cases cannot be performed.
`F9-1`, `R1`, `E16`, `W1`, `W3` and the four `F10-n` checks each carry two
results or more. **`H10` passed 2026-09-02 with a few presses still missing** —
the residue `B47`'s fix leaves, accepted rather than closed.

**Three check recipes could not have run at all, and were repaired on
2026-09-07.** `F-3`, `W4` and `W5` each handed the runner a program saying
`place(blocks.…)` — the category `F11` deleted on 2026-09-04 — so each would
have failed on its first line for a reason that is not what it tests, and `W1`
quotes two more in its results. They are fixed the way `B53`'s template was:
`place(hues[1])` and `colors.notablock`, structural names rather than one that
moves. **`W1`'s two historical programs are left exactly as they were run** and
carry a warning instead, because a result is evidence about the program that
produced it; the loop is restated in today's spelling in the check's own body.
A wrong check is a defect in this document and gets no finding id.

**`R1` and `R2` are stale rather than unrun, and `F11` made them more so.** Both
describe the release archive, which now carries the mod's own textures and no
`default` or `wool` dependency; `R2` last ran at `7c5bceb`, before `F4` and
before `.gitattributes` changed. `F11-3` overlaps them and replaces neither: it
checks a real install into a foreign game, not what the archive contains.

- **`D7` passed on 2026-09-04 and lost half its recipe in the same run.** It
  asked for two routes and one of them stopped existing at `F8`: the setter
  removes nothing, and `Drone.on_remove` has exactly two callers — the panel's
  **Stop** button and `register_on_leaveplayer`. The disconnect line reaches
  nobody, so **Stop** is the only route a player can perform and the check now
  asks for that one. The *Drone is busy, please wait!* the author saw trying the
  other is `Drone.on_place`'s guard, correct, and got no id: the defect was in
  this document, like `D3` and `F-3` before it.

- **The whole *Writing to the world* group ran on 2026-09-04 at `23f0227`, and
  all six checks passed.** That is **`B50` and `B52` confirmed in a running
  world**: the three checks that were the whole of their evidence — `W1` at
  codelevel 1, `W5` and `W6` — have all now been played. **`W1` passed at every
  codelevel**, the first run to report above *and* below level 2 together, so the
  level this check had been asking for since 2026-08-28 is answered along with
  the three it had never reached; its **third observation is finally made**, the
  program running to its end, so no *le drone a disparu* line and no leaked
  record. **`W5` and `W6` had no result at all before this run**, and `W6` passed
  on all four of its cases, `/clearobjects` not ending a program included. **The
  engine version was not restated by the author** and is recorded as not
  recorded rather than inferred from earlier runs.

- **`W1`'s two fails of 2026-09-03 describe code that has since been replaced.**
  They are `B50`, at codelevel 1, on `16cd05c`; `1b991ae` decoupled the record
  from the entity and the 2026-09-04 pass is that fix seen in a world. They stay
  below the pass in `W1`'s entry, with the 320/352-node measurement and the
  sampled-race reading that came out of them, because that is `B50`'s diagnosis
  and `B51`'s only in-world observation.

- **`W3` is 0.27 s at `23f0227` against 0.34 s on 2026-08-28.** Both are passes
  and **the difference is not a finding** — nothing about that shape has been
  measured twice under controlled conditions. The earlier result and its cost
  breakdown stay: that arithmetic is `S5`'s.

- **`W4` passed 2026-09-03 at `16cd05c`** and **confirms `B49` in a world**. Its case 2 — a second
  drone in the same session warning on its own account — is the **only** way the
  per-run scope is observable, the flag being a closure upvalue in a file-local
  function, so no spec will ever cover it.

- **`F10-1` became a pass on 2026-09-03**, having been recorded partial earlier
  the same day. The author's second report supplied the two missing cases: a
  fresh player's inventory holds neither tool, and `/privs` shows no `fly`,
  `fast` or `noclip`. That second one **confirms `C21` in a world**, and it was
  that finding's only possible evidence.

- **`E16`'s pristine-example case passed 2026-09-03** on `b9143b0` plus what was
  then the uncommitted tree, which **confirms `B48` in a world**; the fix is
  `4179877`. The case was added the
  same day: the earlier run at `afbe504` passed and still missed `B48`, because
  it tested a file the runner had typed into, and the defect only shows on a
  **bundled example nobody has saved yet**, since those ship CRLF. A check whose
  setup normalises away the condition it is looking for is the failure mode here.

- **All four `F10-n` checks passed 2026-09-03**, first on `b9143b0` plus the
  then-uncommitted tree and again at `16cd05c`, `F10`'s code having landed at
  `b23a8bc` unchanged. The chat line arrives — the open
  risk, since `chat_send_player` from `register_on_newplayer` fires before the
  client has finished loading — the fresh player is given no tools, and `/privs`
  shows none of the three privileges, which is **the only in-world evidence
  `C21` will ever have**. Every part of `F10` is in the class the specs cannot
  see, so those four checks are the whole of what is known about it. **`D4` is
  superseded by this group**, the condition on its own note — `F10` committed —
  having been met at `b23a8bc`.

- **A new `S()` key ships English-by-default and nothing fails.**
  `gen_locale --check` passes on `template.txt` alone and only *reports* an
  incomplete `.tr`, which is correct — an untranslated message legitimately falls
  back. The consequence is that **a feature adding player-facing strings is not
  finished until the `.tr` files are written, and the only thing that will tell
  you is playing it in another language.** `F10` demonstrated it: both the chat
  line and the `/codeblock tools` replies read English on a French client on
  2026-09-03. The French was written later that day, and **the author read it in
  a world on 2026-09-04 — *"F10: french works ok"***, which closes the owed
  reading `F10-1` case 4 and `F10-2` were both carrying. The English passes
  stand: that was the known state when they were taken. What the episode leaves
  is the rule, not a gap.

- **Group `H` (HUD and panel): re-run 2026-09-02 at `8f5bb2e`, eight pass and one
  partial.** `F8`'s display work is proven in a world. It produced `B47` — panel
  buttons sometimes needing a second click — and three wanted display changes,
  which are `F9`.
- **`F9-1` passed 2026-09-02, in both languages**, which closes the three display
  changes `H2`–`H7` asked for. Its case 4 is the one place a check passed and the
  behaviour changed anyway — the elapsed clock now stops while a run is paused —
  so it carries a second result, at `dc09d48`.
- **`H8` stays partial because two of its four cases cannot be performed**, not
  because they failed: a shown formspec holds the pointer, so *while the panel is
  open* rules out any gesture needing a tool. Case 3's mechanism moved into
  `forms_spec`.
- **`R4` and `F-5` both passed 2026-09-02**, so `S6`'s singleplayer 3 is observed
  and the bundled examples fitting codelevel 2 is measured rather than counted —
  including under the same day's `max_runtime_s` cut to 60 s at that level.
- **Three untestable halves were removed on 2026-09-02**, all on the author's
  call: `D2` case 2, `E2`'s cold-cache half and `H8` case 3. Each entry keeps
  what it was for and why nobody can reach it, because the reasons are what would
  otherwise get the case written again. `B10`'s refusal and `B14`'s cold path are
  the two findings left with no route.
- **`F-3` case 2's log half is unlooked-at** — one grep of `debug.txt`.
- **`W3` needs codelevel 4 now**, not 3: its shape exceeds level 3's new ceiling.
- **`R1` was re-checked at `7dbe18f` and passes**; it carries two results, the
  first predating a `.gitattributes` change. **`R2` is the one the release still
  wants**: it last ran at `7c5bceb`, before `F4` put `lib/hud.lua` in the
  `dofile` list, and it is the only check that the shipped archive loads at all.
  **Its entry now carries the `git archive` recipe**, which it had never said —
  a check that does not say how to produce the thing it checks is a check nobody
  can repeat.
- **`H10` passed, and it is the one result that reports a defect surviving.** A
  few presses in twenty still miss. That is `B47`'s residue, observed rather than
  computed, and above what the check as written allowed — the author's judgement
  that it is acceptable is what decides, and the fallback that would close it
  outright stays named under `B47`.

---

## Editor

E1–E17. Runs of 2026-08-27 and 2026-08-28, engine 5.17.0, in the author's test
game. They produced `B33` (widened to three losing paths), `B34`, `B35`, `B36`
and `B37`. **`E17` is newer and unrun**: written 2026-09-07 for `B53`, which
nothing in this group would have caught, because every check here opens a file
that already exists.

### E1 · Open, save and close a program [A9, B13, B17]

Open a file, type, save, close with **Save**, reopen.

**Pass:** the edit is on disk and comes back; no `set_string` error in the log
(B13 passed nil, B17 passed a number).

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E2 · Create and remove a file [B14, A9]

Create a new file from the chooser, then remove it.

**Pass:** both succeed.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

**A second half was removed on 2026-09-02 as untestable**, on the author's call.
It asked for the removal of a file never opened this session — `B14`'s cold-cache
path — and the editor cannot do it: the four file buttons are drawn only inside
`if meta.active ~= 0 then`, which is `B34`, won't fix. So every removal the
editor can perform is a warm-cache one. **`B14` stays committed-but-unproven with
no route from this check**; the only one left is removing a file immediately after
a rejoin, the reconnect being its trigger, and that is a different check nobody
has written.

### E3 · Tabs [B33]

Open three files, switch between them, close the middle one, then the last.

**Pass:** each tab shows its own content, the active tab is sensible after a
close, and closing the last leaves an empty editor rather than an error.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E4 · Tab state survives ESC [B33]

Open two files, close with **ESC**, reopen.

**Pass:** both files are open again and the active tab is restored.
`save_editor_state()` is called from exactly one branch, `fields.quit == 'true'`;
whether ESC reaches it could not be established by reading. **It does.** Settled
— only re-run if that branch changes.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E5 · Tab state after **Load and close** [B33]

Open two files and leave with the **Load and close** button. Reopen.

**Pass:** both files are open and the active tab is the one you were on. `exit()`
goes through `core.close_formspec`, and a server-side close sends no field table
back, so the `fields.quit` branch never ran for this path. The file's *contents*
were always saved; only the tab layout was lost.

Result: pass — `500dd85` content, run pre-commit · engine 5.17.0 · 2026-08-27.

Earlier: fail — `3293a2c` + uncommitted F1 · 2026-08-27 — all three exits lost
the tabs. That is what widened `B33` from one losing path to three.

### E6 · The two checkboxes [B5]

Toggle **Load program on exit** and **Save on tab switch**, close, reopen.

**Pass:** both persist and both take effect. With *Save on tab switch* **off**,
editing and switching tab must discard the edit — the half `B5` destroyed work
through, `0` being truthy in Lua.

The third box, *Save on exit*, is commented out and **deliberately dead — do not
restore it.** What is wanted instead is a warning on unsaved changes (`TODO.md`).

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E7 · The help panels [A2, B22]

Open Blocks, Plants, Wools, API and Settings in turn; scroll the first three to
the bottom.

**Pass:** every panel draws, every item shows a texture, the three block panels
keep independent scroll positions, and the API hypertext renders — generated from
`lib/api.lua`, the same source as `doc/api.md`.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — four
panels; the fifth (Settings) has its own check below.

### E8 · Tab state survives a disconnect [B33]

Open two files and **disconnect**. Rejoin and open the editor.

**Pass:** both files are open and the active tab is restored.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27. **What this does not
exercise:** the engine callback hands the handler a `{quit = 'true'}` the mod
builds itself, with no scrollbar field, so it was never exposed to `B37` — which
is why it passed while ESC did not (`E14`).

### E9 · Tab state survives a server shutdown [B33]

Open two files, shut the server down cleanly, restart, open the editor.

**Pass:** both files are open and the active tab is restored. That **player meta
written from `on_shutdown` is still saved** was an assumption about the engine's
shutdown order; this check settled it. If it ever fails, check the log for the
handler running at all before concluding the callback never fired.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27 — **the significant pass**,
observed rather than inferred. Same `B37` caveat as `E8`.

### E10 · The checkboxes for a player who has never set them [B36]

Join as a player who has **never existed in this world** — a genuinely new name
or a fresh world. Untick one, close, reopen.

**Pass:** both boxes start **ticked**; the untick survives.

**The fresh name is not optional.** Any player who joined before `1f7cd97` still
carries the `0` `register_on_newplayer` used to write, correctly honoured as a
deliberate untick. Re-running as an existing player will look like a failure and
is not one.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27 — re-run with a fresh name;
both halves. `B36` confirmed fixed.

Earlier: fail — `dee0bc7` · 2026-08-27 — both boxes unchecked for a new player.
That is `B36`.

### E11 · Typing survives every button that is not Save [B35]

Type into a file, then press each of **Blocks**, **Plants**, **Wools**, **API**
and **Settings** without saving.

**Pass:** the text is still there after every one.

Result: pass — `500dd85` content, run pre-commit · engine 5.17.0 · 2026-08-27.

### E12 · **Save on tab switch** off really does not write to disk [B35]

Untick it. Edit tab A without saving, switch to B, switch back, leave with **ESC
only**. Reopen and reopen A.

**Two claims, not equally strong:**

1. **The strong one:** the edit is **absent** from disk. Nothing on the tab-switch
   path may write.
2. **The weak one, which reads as a failure:** the edit is still in the text area
   when you switch back. **That retention is intended and stays** — an unsaved tab
   holds its edit. Three runs called it a save; it is a dirty buffer with no sign
   that it is dirty, which is `F7`'s job.

**Leave by ESC and nothing else.** *Load and close* and *Save* both write
unconditionally by design.

**Look at the file itself, not at the editor** — read
`<worldpath>/codeblock_files/<playername>/<file>.lua` from outside the game and
note its size or mtime. That is the only observation that separates the two
claims, and it is what the first two runs were missing.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — after ESC and a reopen,
**the edit is gone**. The three earlier fails (`dee0bc7`, `f274245`) were claim 2
reported as a save. **No finding id was ever allocated, correctly.**

### E13 · **Create a copy** [F2]

With an unsaved edit, click **Create a copy**. Then copy the copy, several times.
Then reopen the original.

**Pass**, six parts: the copy is `<name>_1.lua` containing **what was on screen**;
it opens as the active tab; copying increments without nesting suffixes or losing
a character; the **original is unchanged on disk**; past ten copies the list reads
`_9`, `_10`, `_11`, not alphabetically; and the button's **right edge sits flush**
with the file list and `+` — a legacy `button` is 0.2 units narrower than its `W`
says, hence `3.2` and `0.95` against a 3-wide list.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27 — all six, the flush edge
included after the geometry was wrong twice.

### E14 · Closing the editor with **ESC** saves the open tabs [B37, B33]

Open two files, leave the help panel on **Blocks**, close with **ESC** or the
window **X**. Reopen.

**Pass:** both files are open and the active tab is the one you were on.

**This is the path that had no check, which is how `B37` hid.** A scrollbar
reports its position on *every* submit, so the three help-panel scroll branches —
above `quit` in one `elseif` chain — swallowed the quit event whenever Blocks,
Plants or Wools was showing. Run this with each of the five panels open;
**Settings** and **API** draw no scrollbar and were never affected.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### E15 · **Enter** in the New file field creates the file [B37]

With the panel on **Blocks**, type a name into **New file** and press **Enter**
rather than clicking `+`.

**Pass:** the file is created and opens as the active tab, exactly as `+` does.
The branch is keyed on `fields.key_enter_field == 'newfile'`, which the engine
sets on `EGET_EDITBOX_ENTER`; `field_close_on_enter[newfile;false]` keeps the
form open so the handler sees it.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### E16 · The unsaved marker on a tab [F7]

Type into a file, then press anything that is **not Save**. Look at the tab label.
Press **Save** and look again. Then leave an unsaved tab with **ESC**, reopen, and
look at the file.

**Pass:** the tab reads `thing.lua*` while the buffer differs from the file, and
`thing.lua` once written. It clears on **Save**, on a tab switch with *Save on tab
switch* ticked, and on **Load and close** — not on a tab switch with that option
off, because nothing was written.

Three more things:

- **The mark is legible on a tab.** A `tabheader` sizes itself to its labels, so a
  marked tab is one character wider and the row shifts as you type. That is the
  cost of the design and this is where it is seen.
- **The file is still called `thing.lua`.** A file named `thing.lua*` in the list
  means the marker reached `meta.tabs`, which would corrupt the player's
  directory.
- **Create a copy leaves the source marked** and the copy unmarked.

**A known and accepted wrongness, not a fail:** type a character and undo it and
the tab stays marked until the next save. Report it only if the mark appears
without any typing at all — that would mean it is set from the field arriving.

**The case this check was missing, added 2026-09-03 for `B48`.** Open **three or
four bundled examples you have never saved** — `plot2D.lua` is the one that
failed, `donuts.lua` and `torus.lua` will do as well — one after another, and
**type nothing at all**. Every tab but the active one must be **unmarked**. The
mark appearing here is the clause above: it is the field arriving, not an edit.
It happened because the examples ship CRLF and the client's textarea returns LF,
so the buffer never equalled the field. **Do it on a fresh player directory** — a
file you have already saved through the editor is LF on disk and cannot show the
defect, which is exactly why the first run of this check missed it.

Result: pass — `afbe504` · engine 5.17.0 · 2026-08-28 — the day it shipped.
**`F7` confirmed**, but the pristine-example case above did not exist and was not
covered; the author hit `B48` in ordinary use on 2026-09-03.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03 —
the pristine-example case, on the tree carrying `B48`'s fix. Four bundled
examples opened untouched and no tab but the active one marked. **`B48` is now
confirmed in a world**, which is the one thing no spec could reach: the CRLF-vs-LF
comparison only happens through a real client textarea.

### E17 · A brand new file runs as it is [B53]

**Written 2026-09-07 with `B53`'s fix.** Press `+` in the editor, type a name,
and **run the file that appears without editing it**.

**Pass:** a **ten-block vertical rainbow column** rises from the drone, and no
error in chat.

**What distinguishes a pass from *did not crash*: count the colours.** The column
must be ten blocks of ten **different** colours, one per hue family in
colour-wheel order. A template that resolved all its names but ramped wrongly —
ten blocks of one colour, or the same two alternating — would still place
something and would still print no error, and that is a fail here.

`B53` was this template placing nothing at all: it said `place(blocks.obsidian)`
and `F11` had deleted the `blocks` category three days earlier, so every file
created with `+` or Enter died on its first statement. The fix reads
`for i = 1, #hues do place(hues[i]) up(1) end`, which is why the pass is a
rainbow and why the count of colours is the discriminator. `integration_spec`
covers the template compiling and running; **what only a world can show is the
route from the button to a program a player actually runs.**

Result: not yet run.

---

## Drone placement and the setter tool

D1–D7. Runs of 2026-08-27 and 2026-08-28. They produced `B38`, `B39`, `B41` and
`B44` — all four in code nobody had exercised in a running world. **`D7` was
added 2026-09-04 with `B51`'s fix and passed the same day.**

**Read *setter* in the pre-`F8` checks here as *poser*.** `D1` and `D3` were
written when one tool both placed and removed a drone. Since `F8` the **poser**
places and the **setter** only opens the panel or the editor, so those recipes
name the poser's gesture; their results stand as performed on the day. `D7` had
the same error and was corrected on 2026-09-04.

### D1 · Place a drone and run a program [B10, A11]

Point at loaded ground with the poser, place, pick a file, watch it finish.

**Pass:** one completion message, from `Drone.finish` and only there.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### D2 · Place a drone at nothing [B10, B38]

With the **poser**, aim into the sky, so there is **no node** under the
crosshair, and place.

**Pass:** *"Please target a node"*, and no record created.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28, and
at `246bb37` before it, confirming `B38`.

Earlier: fail — `f274245` · 2026-08-27 — it had no implementation at all. That is
`B38`.

**A second case was removed on 2026-09-02 as untestable**, on the author's call
after two failed attempts. It asked for a node the client shows but the *server*
has unloaded — the `add_entity`-returns-nil path, and the only route to `B10`'s
*"Cannot place the drone there, move closer"*. Producing it needs the client to
show **more** than the server holds, and `server_unload_unused_data_timeout`
bounds when the engine *may* drop an idle mapblock, not when it does. Two
sessions waited out the timeout and found the block still resident. **A check
nobody can perform is not a check**; `B10`'s refusal is unprovable by hand and
recorded as such in `AUDIT.md`. Do not write this case again without a way to
*observe* that the server has let go.

### D3 · Replace a drone under the same name [B29, B30]

1. Place a drone, run a program, and try to place a second **before** it
   finishes. **Pass:** refused with *"Drone is busy, please wait!"*. Then place
   again after it finishes: that works.
2. The re-entrancy window `B29` is about is reached by **removing a running
   drone and replacing it inside the second**. That was the setter's right click
   when this check was written; since `F8` it is the panel's **Stop** button.
   Remove a running drone that way and place a new one at once. **Pass:** the replacement survives and runs
   to its own end, and the removed run announces its statistics **once** —
   `Drone.on_remove` calls `Drone.finish` on purpose. **What that line says is
   `D7`'s business, not this one's** — it read *completed* when this check was
   written, which was `B51`, and since the 2026-09-04 fix it reads *stopped*.
   This case counts the announcement; `D7` reads it.

**The old second condition is gone, and so is what it named.** It asked that
*"The drone has disappeared, program stopped"* not appear; `1b991ae` deleted that
message outright, nothing sends it, and its `S()` key is out of
`locale/template.txt`. So the condition is now trivially met and is not worth
checking.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both parts. **`B29`'s
serial guard was confirmed in a running world**; this was the one path to it.
**That result predates `1b991ae`**, which changed what the serial guards — the
replacement's object rather than its record. **`W6` case 2 covered the new form
on 2026-09-04 at `23f0227`** — one drone and not two after a re-spawn under the
same name — so `B29` has in-world evidence on current code and this part needs no
re-run for that reason. What is still only pre-`1b991ae` is the *a running drone
is removed and a replacement goes in within the second* gesture, which is
`B29`'s narrowest window and no other check performs — and it is now made with
the panel's **Stop** button, the setter having stopped removing anything at `F8`.

Earlier: partial — `f274245` · 2026-08-27 — part 1 only. **The check was wrong,
not the code**: it asked for a mid-run replacement, which `on_place` refuses on
purpose. No id. The pass condition was wrong a second time too, demanding that
nothing be announced for the removed run. **Both errors were the record.**

### D4 · Join with a full inventory [B16, B39]

1. Join a world that already has the mod, carrying items. **Pass:** nothing is
   removed.
2. Take a world **without** this mod, collect items, quit, add the mod, join.
   **Pass:** the two tools are added and **nothing else is removed**. This is
   `B39` — the one case `B16`'s narrowing left behind.

Worth trying once with a **completely full** main inventory: the refusal — *"No
room for the drone tools, free a slot and rejoin"* — is answered in the code but
that branch has never been seen run.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both cases; the tools are
added after the player's own items. **`B39` confirmed fixed.**

Earlier: fail — `f274245` · 2026-08-27 — case 2 exactly: *"inventory was replaced
with the 2 drone tools and the rest was empty"*. That is `B39`.

**Superseded by `F10-1` and `F10-2` at `b23a8bc`.** `F10` deleted what this check
checks: with the handout gone, case 2's *"the two tools are added"* is no longer
the pass condition and the refusal quoted above no longer exists. **Do not run
this check against current code** — run `F10-1` for what a fresh player is given
and `F10-2` for the command that replaced the handout. The results above stay as
the evidence they were: they are what `B16` and `B39` were confirmed by, on the
code that shipped the handout, and `B39`'s reasoning is what `F10-2` case 2
inherits. `B39`'s rule does not retire with the handout: it moves to
`/codeblock tools`, which can be run repeatedly and so reaches the duplication
case more easily than joining ever did.

### D5 · Cancelling the file chooser [B41]

Place the poser with no previously loaded file; the chooser opens. Press
**Cancel**. Place again and press **ESC**. A third time, **choose a file** — the
drone must stay.

**Pass:** neither Cancel nor ESC leaves a drone standing, and choosing a file
still leaves one that runs. **The third part is the one to actually do**: the fix
removes the drone whenever the chooser closes with no file set, so a bug in it
would take away the drone the player *did* choose for.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — all
three parts. **`B41` confirmed**, its ESC half observed for the first time.

Earlier: fail — `246bb37` · 2026-08-27, reported unprompted. That is `B41`.

### D6 · Removing the file a drone is holding [B44]

Place a drone and give it a file. Open the editor, **Remove file**, close. Look at
the drone. Then run it.

**Pass:** the drone goes **with the file**, at the removal — not one gesture later
on the run.

Also check the other order, which has a guard already: remove the file, then place
a **new** drone. `Drone.on_place` tests `codeblock:last_file` against the player's
file list, so a stale last-file opens the chooser.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28. **`B44` confirmed.**

Earlier: fail — `326f739` + uncommitted fixes · 2026-08-28 — found while running
`D5`, by doing the obvious next thing. That is `B44`.

### D7 · A run cut short says *stopped* [B51, B12, B30]

**Written 2026-09-04 with the fix, and the only evidence `B51` can ever have** —
no spec asserts what `Drone.finish` sends, and the wording, the French and the
partial counts are all in-world.

**There is exactly one route a player can perform, and this check asks for that
one.** `Drone.on_remove` has two callers — the drone panel's **Stop** button
(`lib/formspecs.lua`) and `register_on_leaveplayer` (`lib/register.lua`). A
player disconnecting mid-run is the second, and **nobody is there to read the
line it sends**, so that path is settled by reading the code and not in a world.
The setter is not a route at all: since `F8` its left click opens the panel, its
right click the editor, and it removes nothing. This check said *cut it with the
setter* from the day it was written until 2026-09-04, which was wrong when
written — `B51`'s own text carried the same error.

Write a program that builds long enough to interrupt — `cube(30,30,30)` at
codelevel 2, or a `for` loop of 200 `place()` calls — and run it. Then cut it
short **with the panel's Stop button**: left click with the setter, press
**Stop**.

**Pass:**

- **exactly one** chat line, not two and not none — that is `B12` and `B30`, and
  `Drone.finish` is the one place it comes from;
- it reads `Program '<file>' stopped:` and **not** *completed*;
- the tail after it is the **partial** count — a node count well below what the
  program asked for, and a duration shorter than a full run's.

**Do it in French as well.** `Program '@1' stopped: @2` is a new `S()` key
and its French is `Programme '@1' arrêté : @2`; half of what `C17` covers is only
visible in the other language. Note that the timeout line is *also* `arrêté` —
*Programme '@1' arrêté : il a épuisé ses @2 s de temps d'exécution* — and that
sharing was weighed and accepted, because that line says why. If the two ever
read as one message, that is a finding.

Also let a program **finish on its own** in the same session: it must still say
*completed*. The two words must not have swapped.

Result: pass — `8de3cea` plus a comment-only edit in `lib/drone.lua` · engine
version not restated · 2026-09-04. *Stopped* with a partial node count, and
*arrêté* in French. **This is `B51`'s only in-world evidence and the whole of it.**
The author also tried the case this check then asked for — placing a drone over
the running one — and got *Drone is busy, please wait!*: `Drone.on_place`'s guard
in `lib/drone.lua`, reached by the **poser**, correct behaviour, unrelated to `B51`,
and the observation that showed this check named a route that does not exist. No
id: the defect was in this record.

---

## The drone HUD and panel

H1–H9. **First run 2026-08-29 at `729c255`: six pass, three partial.** It produced
`B45` and `B46` and four wanted changes; `F8` then shipped the same day and was
revised twice more from screenshots.

**Second run 2026-09-02 at `8f5bb2e`: eight pass, one partial** — the `F8`
behaviour, and the first performance of `H2` and `H4` in their current form. It
produced `B47`, three wanted display changes now held by `F9`, and the answer to
`H8` case 1: the gesture it asks for is impossible. `H9` was not re-run and its
`F4` pass still stands, nothing in `F8` having touched the leave path.

This group carries more unverifiable surface than any other: the specs reach the
binding arithmetic (`limits_spec`), the pause field (`stepper_spec`) and the
panel's session routing (`forms_spec`), and reach **none** of the drawing, the
cadence, the colour, the toggle or the setter gesture.

If nothing is top-right, check *Show the drone HUD* in the editor's *Settings*
panel and `codeblock_drone_hud` in `minetest.conf` before assuming it is broken.

### H1 · The HUD appears, updates and goes [F4, F8]

Run a program that takes ten seconds or so.

**Pass:** a **five-line block** appears top-right the moment it starts:

```
mosely.lua : running          <- bold
Budget usage
Blocks: 72%
CPU: 0%
Memory: 4%
```

The filename is right, the block is **flush to the top-right corner**, the
percentages move, and **every line disappears when the program ends** — without a
reload and without a leftover from the previous run. The header is bold and the
other four are not.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — the five-line block, in
the corner, tracking the run and gone at the end. Supersedes the `F4` pass at
`729c255`, where only two lines existed.

Observed in the same run and not a `H1` failure: **a program running 387 s of
clock time spent about 18 s of server time**, ~4.6%. That is `B46`'s arithmetic
behaving — a codelevel-4 drone is given ~8 ms of a ~90 ms step — and it is what
retuned `max_runtime_s` to `30 / 60 / 120 / 300` the same day: at that ratio the
old 2000 s was eleven hours of building and bounded nothing. Level 4's
`max_nodes_written` went `1e7` → `5e7` with it. The reasoning is in `ROADMAP.md`.

### H2 · The binding limit is the one it names, and it changes [F4, B26, B45]

**This check has never actually been performed** — map memory saturated the
comparison both times it was attempted. That resource no longer competes, so it
is possible for the first time.

Run two programs at the same codelevel: one that writes a great many nodes
quickly, and one that spends time without writing much.

**Pass:** in the panel, the first is closest on **Blocks placed** and the second
on **Server time used**; on the HUD the same two lead. **Map held cannot appear
at all** — neither compared nor listed on either surface, which is `B45` plus the
author's *"only list hard limits"*.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — **performed for the first
time**, the comparison now being possible: the binding limit is the one the run
is actually closest on, and *Map held* appears on neither surface. `B45` and
`B46` are both confirmed fixed in a world.

Wanted change from this run: **the HUD's `CPU` should read *CPU time* /
*Temps CPU***. `CPU` alone reads as a load percentage, which is the same misreading
`B46` was filed for one word later. Carried by `F9`.

### H3 · The toggle, whose choice wins, and where it lives [F4, B5, C18, F8]

0. **Where it is:** *Show the drone HUD* is on the editor's **Settings** panel,
   beside the default-block picker, with *Load program on exit* and *Save on tab
   switch*. `F8` moved all three off the form's bottom edge.
1. Untick it with a program running: the HUD goes at once and stays gone across a
   relog.
2. Set `codeblock_drone_hud = false` server-side. **Pass:** a player who has
   never expressed a preference sees no HUD; a player who ticked it **does** —
   the player's own choice wins over the server default.

The `get_string` read is what makes case 2 expressible at all: `get_int` cannot
tell an unset key from a stored `0` (`B5`).

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — including case 0, the
box's new home on the *Settings* panel. The `F4` run at `729c255` had already
covered cases 1 and 2 with the rejoin that catches the `B5` trap.

### H4 · The setter's left click always opens the panel [F4, F8, B39]

**Rewritten in `F8`.** The gesture has meant three things in turn — it removed the
drone, then `F4` split it by state, and that split lasted exactly one playtest:
**an effect that depends on state the player cannot see is one they have to guess
at, and the guess destroys a build.**

Left click with the **setter** in each of three states:

1. **No drone at all.** The panel opens and says *You have no drone*, offering
   only *Close*.
2. **An idle drone.** The panel opens naming the file it holds, with **Stop** and
   the close `x` — and **nothing is removed until Stop is pressed**.
3. **A running drone.** The panel opens with the three hard limits, **Pause**,
   **Stop** and the `x`. The run is **not** cancelled by opening the panel.

Then the button:

4. **Stop** on an **idle** drone: it goes, silently, as the old left click did.
5. **Stop** on a **running** drone: it goes and the run is announced — **exactly
   one message**. Two or none would be `B12`/`B30` returning.

There is **one** destructive button on purpose. *Cancel* and *Remove drone*
shipped together for one afternoon and called the same function; if two ever
reappear, that is the defect, not the fix.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — **performed for the first
time in this form**, all five cases: the panel opens in each of the three states,
and Stop is the only thing that removes a drone. The `F4` version's pass at
`729c255` is what decided the state-dependent split had to go.

Wanted change from this run: **the idle heading should be built like the running
one** — `<program> : inactif`, the filename bold and the state coloured, instead
of the sentence *Drone inactif, chargé avec @1*. Two states of one panel reading
in two shapes is what it looks like now. Carried by `F9`.

### H5 · The panel's numbers, and its own refresh [F4, F8, B46]

With a long program running, open the panel and leave it open, at **codelevel 4**
where `max_nodes_written` is 5e7 — the case the number formatting exists for.

**Pass:** **three rows** — blocks, server time, Lua memory — each with what the
run has spent against its ceiling, in the units `minetest.conf` uses: seconds and
megabytes, not microseconds and mapblocks. The numbers **update while the panel
sits open**, without touching anything.

What the later passes added, all of it part of the check and all of it read on
2026-09-02:

- **Three rows, not four.** *Map held* is **not listed at all**: it stops nothing,
  and a table mixing it with three ceilings that do end a run is what `B45` was
  about. There is **no *Will stop on…* line** any more.
- **Long counts are readable** — `1.2K / 10.0M`, not `1247 / 10000000`. The
  threshold is 10 000, so a small count still reads as a plain integer.
- **Each name is bold, and its description starts at the same left edge.** The
  description is allowed **two lines** and must not be cut off at the panel edge
  — check this **in French**, which is where the single-line version clipped.
- **The heading is bold and its state coloured** — `running` green, `paused`
  yellow, checked by pressing *Pause* and watching the word change colour as well
  as text. Neither may be the amber or red used on the rows. It is one label, so
  the state is bold too; that is expected, a label's font being per element.
- **The *Server time used* description says it is not clock time.** That is
  `B46`'s fix and the reason the row was renamed.
- **The percentage is coloured, and at most one thing is amber.** Amber marks the
  limit reached first; **red at 80% or more** and red wins. A run nowhere near any
  ceiling shows three plain percentages.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — every point above,
including the three rows without *Map held*, the abbreviated counts, the two-line
descriptions in French, the coloured heading and the at-most-one-amber rule.
Supersedes the four-row `F4` pass at `729c255`.

Wanted change from this run: **the heading should carry the run's clock time** —
`<program> : <state> (<duration>)`, the duration **not** bold. Nothing on either
surface says how long the run has been going; *Server time used* deliberately
does not, which is the whole of `B46`. Carried by `F9`.

### H6 · Pause and Resume [F4, F3, B46]

Pause a running program from the panel.

**Pass:** the drone stops building, the HUD says **paused**, the button becomes
*Resume*. Leave it a full minute, then resume: it carries on and **does not**
report running out of time — a pause is charged no runtime. A second drone keeps
its full pace while the first is paused.

Then the `F3` interaction: pause a program **inside a `sleep(10)`**, wait past the
ten seconds, and resume. It should resume promptly rather than sleeping ten more.

**Two things this check must not report as bugs, both settled 2026-08-29:**

- **A drone resuming from a long pause races before settling.** The map footprint
  decays over `server_unload_unused_data_timeout` (29 s), so a two-minute pause
  leaves nothing held. The engine really did unload those mapblocks. Not `B45`,
  not a pause defect, **and not to be filed a third time**.
- **The time figure advancing at roughly a tenth of the clock.** *Server time
  used* is what the drone was actually given — 8 ms of a 90 ms step at codelevel
  4. `B46` fixed the wording; the arithmetic was never wrong. **The row's
  describing line should now say so, and checking that it does is part of this
  check.**

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — Pause, Resume, the
`sleep` interaction, and the renamed row's describing line read and accepted.
Supersedes the partial at `729c255`, which produced `B46` and the `B45`
explanation.

### H7 · Stop [F4, F8, B12, B30]

Press **Stop** on a running program, then on an idle drone.

**Pass:** the drone goes both times and the panel closes. On the running one,
**exactly one** message in chat — not two, not none. On the idle one, no message.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — both cases of the merged
button, exactly one message on the running drone and none on the idle one.
Supersedes the `F4` pass at `729c255`, where it was named *Cancel* and the idle
case did not exist.

**This check counts the message; `D7` reads it.** The pass above stands and says
nothing about the wording, which was *completed* at the time and is `B51`. Do not
re-run this one for the word.

### H8 · The panel over the editor, and a run that ends under it [F4, F8, B33, B29]

1. **Not performable as written, and now known why** (2026-09-02): a shown
   formspec takes the pointer, so **no tool can be used while the panel is
   open** — the setter's right click never reaches the game and the editor cannot
   be opened over the panel. The gesture this case describes does not exist.
   What *can* be done, and is what to check instead: **close the panel and open
   the editor immediately**, within the panel's refresh interval, then wait two
   seconds without touching anything. Still the editor, unchanged, is the pass;
   the panel's content arriving in its place is the defect the `forms_spec` case
   guards and no spec can see on a screen.
2. Let the program **finish on its own** while the panel is open. It **switches to
   the idle view** rather than freezing on stale numbers or throwing.
3. **Not performable either, for the reason case 1 is not** (2026-09-02): placing
   a drone is a tool use, and the panel holds the pointer while it is open, so
   *with the panel still open* cannot be arranged. What it wanted to prove — that
   a panel left open describes a **replacement** drone under the same name rather
   than the run it was opened for (`B29`) — is now pinned by `forms_spec`
   instead, which swaps the record under an open panel between two `get_form`
   calls. That is the whole of the mechanism; what is lost is only seeing it on a
   screen.
4. **New in `F8`:** open the panel on an idle drone and press **Stop**. It closes;
   it does not sit there describing a drone that no longer exists, and the next
   left click says *You have no drone*.

**How to tell case 1 apart from "it happened to be harmless."** The defect would
show as the *editor* being replaced by the panel's content about half a second
after opening it — so the two seconds of waiting, untouched, is the whole check.

Result: partial — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — **cases 2 and 4 pass**,
and **cases 1 and 3 cannot be performed at all**, which is this run's real
finding: a shown formspec holds the pointer, so *while the panel is open* rules
out every gesture that needs a tool. Both cases now say so, and case 3's
mechanism moved into `forms_spec`. The earlier partial at `729c255` recorded the
author *"unsure — can use 'open the editor' while in a panel"*; the answer is
that they cannot.

**It stays partial rather than becoming a pass**, because two of its four cases
are unreachable by hand rather than passing. The thing to take from it: **on this
form, "with the panel still open, do X with a tool" is never a check** — the two
that were written that way both died the same death.

### H9 · Leaving and rejoining with a program running [F4]

Run a long program, disconnect while it runs, rejoin.

**Pass:** no orphaned HUD line, and no error in the log about a HUD element
belonging to a player who is gone.

Result: pass — `729c255` · engine 5.17.0 · 2026-08-29.

### H10 · A panel button responds to one click [B47]

**New 2026-09-02, first run the same day.** `B47`'s fix is a longer refresh beat — `PERIOD`
`0.5` → `1` s — which **halves the dead window rather than removing it**, so this
check is the only thing that can say whether the residue is still noticeable.
Nothing in the suite reaches it: the gates call the handler directly and the
defect is in the client's menu.

With a long program running, open the panel and **click *Pause* and *Resume*
alternately, twenty times, at an ordinary pace** — not slowly and deliberately,
which is what hides it. Count the presses that do nothing.

1. **Pass: no dropped click in twenty, or at most one.** Before the fix the rate
   was roughly one in five on a ~100 ms press; the arithmetic says one in ten
   now. **A dropped click is silent** — `on_close` never runs, so nothing appears
   in the log and the only evidence is the state word not changing.
2. **Now do the same with the panel on an idle drone**, where the string is
   constant. **Pass: no dropped click at all, however fast.** The engine skips a
   byte-identical formspec entirely, so this half is the control — a drop here
   would mean the mechanism in `AUDIT.md` is wrong.
3. **Check the HUD is still readable at 1 s.** Three percentages that step once a
   second rather than twice. **Pass: it reads as live**, not as stuck. This is
   the price the fix paid and the author accepted; a fail here is a reason to
   take one of `B47`'s other three directions instead.
4. **The panel and the HUD still agree.** They share the one beat, so a number
   differing between the two surfaces means `hud.tick`'s return value has stopped
   driving the panel.

**A fail on case 1 is not a new finding** — it widens `B47`, and the direction to
take next is *stop the self-refresh*, which removes the defect completely at the
cost of the liveness `F8` wanted.

Result: pass — `d8d44cd` · engine 5.17.0 · 2026-09-02 — **a few presses still
miss**, on the author's call that this is acceptable. Note what that is and is
not: **the residue is real and observed**, and it is *more* than case 1 as
written allowed — "at most one in twenty" was arithmetic over the mechanism, and
a few is what a person actually counted. The author's threshold is the one that
decides, and the written one was tighter than it. So `B47` ships mitigated, not
closed, and `ROADMAP.md`'s *What ships broken* says so in the observed figure
rather than the computed one.

**What this leaves available rather than spent.** *Stop the self-refresh* is
still the direction that would close it outright, and the reason not to take it
is unchanged — it costs the liveness `F8` was built for. If the misses become
irritating in ordinary use rather than under a deliberate twenty-press count,
that is the change to make, and it needs no new finding.

---

## Filesystem and example generation

F-1 – F-5. Four runs across 2026-08-27 and 2026-08-28, which produced `B40` — the
worst defect this project has recorded against committed code — and `S7`.

### F-1 · `/codegenerate` on your own files [B8, B15]

Run it as an unprivileged player, twice.

**Pass:** the examples appear the first time; the second run leaves existing files
alone, and needs no privilege for your own files.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### F-2 · `/codegenerate <player>` [B8, C17]

Run it against another player's files, with and without the `codeblock`
privilege. **Run it once with the game in French**, since half of what this check
covers is only visible there.

**Pass:** refused without the privilege; with it, the files land under the named
player, not the caller — the old argument pattern read a bare number as a player
name. And every line it prints is in the game's language.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — *"everything in french"*.
**`C17` confirmed**, including the refusal whose key was built with `..` and so
had never been translatable at all.

Earlier: partial — `f274245` · 2026-08-27 — privilege behaviour passed, the words
came out in English. That is `C17`.

### F-3 · A file that cannot be read [B7, B15]

`read_file` refuses in two ways and both must name the file.

**1. A precompiled chunk.** A file whose first byte is `0x1B`:

```bash
cd .../worlds/<world>/codeblock_files/<player>
echo 'place(hues[1])' > src.lua && luac5.1 -o bytecode.lua src.lua
rm src.lua && head -c 4 bytecode.lua | xxd   # 1b4c7561 - the 0x1B is the point
```

It must be **small**, or `max_file_kb` refuses it first and this branch is never
reached (`B40`). **Pass:** *"Compilation error in bytecode.lua: Binary bytecode
prohibited"*, naming the file, and the editor carries on with the rest of the
list. This is the branch after `handle:close()`, so it is also where a leaked
handle would show.

**2. A genuinely unreadable file.** On Windows, **in PowerShell**:

```powershell
$f = "<worldpath>\codeblock_files\<playername>\test.lua"
icacls $f /deny "$($env:USERNAME):(R)"     # now unreadable
icacls $f /remove:d $env:USERNAME          # put it back
```

**Write it that way and not the `cmd` way.** The obvious
`icacls ... /deny "%USERNAME%":(R)` is a `cmd.exe` line: PowerShell does not
expand `%USERNAME%`, and the bare `(R)` parses as a **subexpression**, so it runs
`R` — an alias for `Invoke-History` — and answers *"Most recent history not
found"* without ever calling `icacls`. Hence `$($env:USERNAME):(R)` inside one
quoted string. The deny must name **your own** account, because the server runs as
you, and the `/remove:d` must go back or that file stays unreadable to everything.

**Pass:** the message names `test.lua` — no path, translated if the game is — and
no other file in the list is lost with it.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — both cases. Case 2 reads
*"Impossible de lire le fichier ..."*, showing both halves of `S7`'s fix at once:
a translation key, so it came out in French, and the filename rather than the
server's install layout. Case 1 passed at `246bb37` + `B40`'s fix, confirming
`B7` a phase after it was fixed.

**The log half is not confirmed.** `S7` moved `io.open`'s real reason to
`warning` rather than discarding it, and no run has looked. One grep of
`debug.txt`, next time an unreadable file is to hand.

Earlier, and worth keeping: fail — `246bb37` · 2026-08-27 — case 1 run with a
168 MB executable renamed `test.lua` took Luanti to ~14 GB and froze it twice.
**That is `B40`, not a failure of the bytecode refusal** — the refusal was checked
*after* `handle:read('*a')`. And unchecked — 2026-08-28 — case 2 blocked by the
`cmd` recipe above. **A recipe written for one shell and run in another is a
procedure defect, not a finding**; that is twice a recipe here has cost a session
(`D2`'s removed second case is the other), so a recipe added here names the shell
it is for.

### F-4 · A file too large to open [B40]

Put a large file — tens of megabytes, need not be valid Lua — into
`<worldpath>/codeblock_files/<playername>/` with a `.lua` name and click it.

**Pass:** refused by name and by size — *"File @1 is too large: over 128 kB"* —
and the editor carries on. **Fail is anything that reads it**: watch the server
process's resident memory, not just the screen.

Two more gestures: load the same file onto a **drone** (the refusal must name the
size — the sandbox used to say *"not found"* for every refusal); and check an
ordinary save still works. Exceeding the ceiling from an unmodified client cannot
be reached at all, the engine dropping any submission whose fields total 640 kB.

Result: pass — `246bb37` + `B40`'s fix · engine 5.17.0 · 2026-08-28 — the file
that took the server to 14 GB is refused instead of read. Which of the three
gestures were made is not recorded, so the **run path is worth a pass of its
own**.

### F-5 · Every bundled example finishes at codelevel 2 [S6]

**New 2026-08-30, first run 2026-09-02.** The limits were retuned and
`planet.lua`, `death_star.lua` and `mosely.lua` shrank so the whole set fits the
level a server hands out. That claim was arithmetic until it was run.

`/codeblock generate`, set yourself to **codelevel 2**, run every example the
command wrote — **fourteen** since `63c3c33` tracked `game.lua`; it was thirteen
after `b752ea3` deleted `tests.lua`, and the 2026-09-02 result below is over a
different fourteen. Run whatever is in your directory rather than a count:
`generate` enumerates `lib/examples/`, so an untracked file of your own there is
written out with them.

**`game.lua` is the exception to this check and must not be read as a failure.**
It ends in `while 1 == 1 do` with no exit, so it is the one shipped example that
never terminates: at codelevel 2 it stops with *"Maximum running time"*, and that
is the intended behaviour, not a limit that needs retuning. Judge the other
thirteen.

**Pass:** every one completes. None stops with *"Maximum number of nodes
written"*, *"Maximum running time"* or *"Memory limit exceeded"*.

The counted margins, so a failure can be read against them: `planet.lua` is
largest at roughly 353k of level 2's 5e5 nodes, then `death_star.lua` at ~207k;
everything else is under 100k. **A node-limit failure on a *third* example means
the counting method is wrong**, not that one example needs shrinking.

**What the counting cannot see:**

- **Runtime, not nodes, may be what bites — and more so since 2026-09-02**, when
  level 2's `max_runtime_s` went **500 s → 60 s**. `torus.lua` issues ~63k
  single-node commands and `density.lua` ~45k loop iterations; at level 2's 5 ms
  pace that is minutes of wall clock. Pace is not charged to `max_runtime_s`, but
  the advancing time is, **nothing has measured it, and the margin is now an
  eighth of what it was**. A *"Maximum running time"* failure here is a real
  result about the new number, not a broken example.
- **Map footprint throttles rather than fails**, so `forest(100)` — ~340 mapblocks
  over a 200-node square — should simply be slow. If it *errors*, that is a single
  request larger than the whole ceiling and a real defect.
- **`planet.lua` uses `random()`**, so its count varies. The 353k is the worst
  case; run it more than once.

**Codelevel 1 is deliberately not in scope**: `planet.lua` and `death_star.lua`
are both over its 1e5 and always were. Changing that is a decision about the
examples, not a defect in them.

Result: pass — `cd13414` · engine 5.17.0 · 2026-09-02 — all fourteen complete at
codelevel 2. **This is now a measurement and not arithmetic**, which is what the
check was written to change, and it covers the same day's `max_runtime_s` cut at
that level, 500 s → 60 s: the runtime nobody had measured is inside 60 s of
charged time for every example, `torus.lua` and `density.lua` included.

---

## Writing to the world

W1–W7. **`W7` is the one check in this group about what a program *says* rather
than what it writes**, added 2026-09-07 for `B54`, and it is here because a
running program's own output has no other group and the per-feature series is
reserved for `F<feature>-<n>` ids. Everything else here is a map write.

W1–W3 played 2026-08-28, and that run **settled questions rather than
finding defects**: `W2` answered `A4`, the oldest thing on the audit's *not
verified anywhere* list. **The `W1` re-run of 2026-09-03 broke that**: at
codelevel 1 the drone vanishes, which is `B50` — and diagnosing that produced
`B51` and `B52`, with the same day's discriminator run then **observing `B51` in
a world**.

**The whole group was then played on 2026-09-04 at `23f0227`, all six passing**,
`W5` and `W6` for the first time and `W1` at every codelevel. That run is the
only in-world evidence `B50` and `B52` will ever have, and it is what took both
off the audit's *gates green, unproven in a world* list. It found no defect and
it does not bear on `B51`, whose remaining path — a run cut short from the
panel's **Stop** button — no check in this group points at. **`B51` was fixed
later the same day and its check is `D7`**, in the *Drone placement* group rather
than this one, and `D7` passed that day too. The engine version was not restated
for either run.

### W1 · `place()` far from spawn [A4, S5, B25, B50, B51]

Fly a long way out, place a drone, and run a program that walks and places one
node at a time across several mapblocks **and back over ground it already
visited**.

**Pass:** no holes — **and the drone survives the run.**

**`B50`'s fix landed as `1b991ae` and this check ran against it on 2026-09-04,
at every codelevel, and passed.** It decouples the record from the entity, so
what this check shows is the whole program running to its end — **all 50 obsidian
placements and the brick line back**, no *le drone a disparu*, and the entity
visible again whenever the player is near enough to see it. A drone that vanishes
from view part-way and reappears later is a **pass**, not a fail: after the fix
the view going away is not an ending. Observation 3 is answered — placing a new
drone straight afterwards works rather than answering *"Drone is busy, please
wait!"*.

**Use the deterministic reproducer, not the loop.**

    -- bbb.lua
    forward(500)
    sleep(20)

**Before `1b991ae` this killed the drone in one to two seconds, every time.**
`forward` is a teleport (`lib/commands.lua:123-134` adds the whole offset in one
command), so the drone is 500 nodes out immediately, and `sleep(20)` then makes
no call, so nothing calls `load_area`; the 2.0 s deactivation sweep took it on
its first or second pass. **After the fix it must survive the full 20 seconds and
then finish normally.** The 50-iteration loop is a coin flip and this is
not, so run this one first. The loop, in the spelling that works at `HEAD`:

    -- aaa.lua
    for i = 1, 50 do
      place(hues[1])
      forward(16)
    end

**The two programs quoted in the results below are pre-`F11` and will not run**
— they say `place(blocks.obsidian)`, and `F11` deleted the `blocks` category on
2026-09-04. They are left exactly as they were run, because that is what the
results are evidence about; copy the loop above instead. (`B53` was the same
rot in the editor's new-file template.)

**The expectation was wrong as written, corrected 2026-09-03.** *No holes* was
the whole of it, and it cannot be met at a paced codelevel while `B50` stands:
the drone is deleted at about 192 nodes from the player, so there are no holes
because there is no drone. **Do not read this check's two earlier passes as
evidence about codelevels 1 and 2** — both were taken above level 2, where the
program finishes inside a step or two and the engine's 2-second object
management never sees it. **This check could not pass at level 1 before `1b991ae`**,
and a fail there was that finding rather than a new one. A fail *now* is a new
finding, or the fix not working, and either way it is worth reporting as such.

**Run it at codelevel 1 or 2, not 3 or 4.** The pass condition is *no holes*, but
what this check is *for* is the per-resume memo reset, and the codelevel decides
how often that runs: `end_command` yields after **every** command while
`pace_ms > 0`, and only when the step budget is spent when pace is 0. A
2000-command program clears and rebuilds the memo 2000 times at level 1 and a
handful of times at level 4. **That is also why only a paced level reaches
`B50`** — the same slowness is what gives the engine time to unload the block the
drone is standing in.

**Three observations to make explicitly, from `B50`.** Two events happen seconds
apart and only one is a defect: at ~128 nodes the client is told to forget the
object, which is a correct and silent vanish; at ~192 nodes the object is
deleted, which should announce itself. **Which one was seen is not decidable by
reading the source**, so these three are what settle it and each must be
recorded, not just the overall outcome.

1. **Where the obsidian stops, counted in multiples of 16.** Near **192–256**
   means the object was deleted. A full **400**, plus the brick line coming back,
   means only the *view* was lost and the run carried on unseen.
2. **Whether a chat line arrived, and how long after** the drone left the
   screen. **After `1b991ae` the pass is *no line at all*** — losing the view is
   not an ending, and the message that used to be printed here, *The drone has
   disappeared, program stopped*, was deleted with the fix because nothing sends
   it any more. Before the fix, both lines arriving was what showed the teardown
   path was intact; now any line before the program's own finish line is a
   defect.
3. **Whether a new drone can be placed immediately**, or the answer is *"Drone is
   busy, please wait!"*. **This is the expensive case and the one to be sure
   about.** A leaked record keeps `cor ~= nil` for ever, locking that player out
   of placing a drone at all, and counts a phantom in `on_step`'s running total —
   which permanently shrinks every other drone's share of
   `server_step_budget_us` for the life of the world.

Past about 2000 nodes in one direction the program stops with *"The drone cannot
leave the world"*. **That is the world-edge guard working, not a limit being
hit** — the number depends on the world's own `mapgen_limit`.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — **at all four
codelevels**, which no earlier run of this check managed: every pass before this
was taken above level 2, and the fail below was level 1 alone. **This is `B50`'s
fix confirmed in a running world**, and it is the only in-world evidence that fix
will ever have. All three observations are answered together by the program
finishing: the obsidian goes the whole way, **no chat line arrives before the
program's own finish line** — the *le drone a disparu* message is deleted and
nothing sends it — and **a new drone places immediately afterwards**, so the
leaked record that observation 3 exists for is **ruled out** rather than
unlikely. The author reported the check as a whole and did not restate the
engine version.

Result: **fail, with the three observations made** — `16cd05c` · engine not
recorded · 2026-09-03 — **the discriminator run, twice**, on a plain outward walk
with no return leg:

    -- aaa.lua
    for i = 1,50 do
      place(blocks.obsidian)
      forward(16)
    end

1. **The obsidian stops at 352 nodes in the first run and 320 in the second** —
   22 and 20 mapblocks. **That is not the ~192 the diagnosis predicted, and it
   confirms rather than contradicts it**: ~192 is where nothing else loads blocks
   any more, so it is where the drone becomes *killable*, not where it dies. The
   drone is exposed only in the gap between `forward` and the next `place`, which
   is about half of each 0.5 s iteration, and `deactivateFarObjects` samples every
   2.0 s — so past 192 nodes each sweep is roughly a coin flip. **Two runs dying
   32 nodes apart is the signature of a sampled race, not of a fixed boundary.**
2. **Both chat lines arrived**, in French: *le drone a disparu*, then
   *programme terminé*. **So there is no second defect** — `on_deactivate` fires,
   `on_lost` runs and `Drone.finish` is reached. The clause this check carried,
   *no line at all is a second, separate defect*, is answered and closed. What
   the author saw vanish at 6–8 seconds was the **first** event, the client being
   told to forget the object at ~128 nodes.
3. **Not run.** So a leaked record is **unlikely rather than ruled out**: both
   messages together mean the teardown path ran to its end, which is the path
   that clears the record, but nobody has tried to place a drone afterwards.
   **Do the third observation on the next run** — it is one gesture and it is the
   expensive case.

**The codelevel was not restated for these two runs.** The first run below was
level 1 and these are read as the same; that is an inference, not a report.
**And this run also observed `B51`**: *programme terminé* announced a run killed
roughly 48 blocks short of the 50 it asked for, immediately after
*le drone a disparu*. The two lines the player saw contradicted each other. Both
are gone — the first with `1b991ae`, the second with `B51`'s fix on 2026-09-04,
which `D7` observed in a world the same day.

Result: **fail** — `16cd05c` · engine not recorded · 2026-09-03 — **at codelevel
1, the drone disappeared after 6–8 seconds.** Not an error, not a refusal, and
not *"The drone cannot leave the world"* — it vanished. **This is the level the
check has been asking for since 2026-08-28**, and it is the level it fails at:
both passes above were taken at a codelevel above 2, where the memo reset this
check exists for barely runs. Filed as `B50`, **and the cause is now known**: an
entity with `static_save = false` is deleted when the mapblock under it leaves
server memory, and nothing keeps the drone's own block loaded past ~192 nodes
from a player. **No fix is chosen** — the options are with the author. **This run did not
record the three observations**, which is why the discriminator run above was
made; between them the two runs are one `W1` result in two halves.

The program, as run:

    -- aaa.lua

    for i = 1, 25 do
      place(blocks.obsidian)
      forward(16)
    end

    back(2)

    for i = 1, 25 do
      place(blocks.brick)
      back(16)
    end

**What happens at codelevels 2, 3 and 4 is unknown.** The report was cut off
mid-sentence before it said, so nothing here claims any other level passes; the
two passes below were at a level above 2 and on much older code. **Neither
earlier pass is contradicted by this** — they answered *no holes* on the code of
their day, and the 2026-08-25 one is where `S5`'s measurements come from.

Neither the commit nor the engine version was stated in the report. `16cd05c` was
`HEAD` when it arrived, with nothing but `CONTENTDB.md` modified in the tree, so
that is what is recorded; read it as *at or about* `16cd05c` rather than as a
commit the author named.

Earlier: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — no
holes, at a codelevel above 2. Two 1000-node lines, the second offset so the
return leg re-crosses ~63 mapblocks the outward leg had written into. **A level 1
or 2 re-run is still worth one session**, the memo reset being barely exercised at
that pace. That re-run is the fail above.

Earlier: pass — `43e95a8` · engine not recorded · 2026-08-25 — where `S5`'s
measurements come from: **16.3 kB resident per mapblock** over a 400-block sweep,
and about **1700 loads a second** served.

### W2 · A node written into never-generated ground [A4]

Place a node in an area that has never been generated, leave, come back so the
area generates, and look.

**Pass:** the node is still there. This was **unknown either way**.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — the node was placed
**1000 nodes out**, the area then generated on a return trip, and the block is
still there. `A4`'s answer holds on current code.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 —
**`A4`'s open question is answered**: mapgen does not overwrite it. `load_area`
plus `set_node` does not merely make the write land — the engine then treats the
block as generated and leaves it alone.

### W3 · A large bulk shape [A5, A15]

Run `cube(200, 200, 200)` **at codelevel 4** and watch the server.

**Pass:** the shape appears slab by slab and the server stays responsive. It must
not freeze — a 150-node cube stalled it for 0.44 s before shapes were sliced.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — **0.27 s** at
codelevel 4, server responsive. **The 0.07 s against 2026-08-28 is not a
finding**: neither figure was taken under controlled conditions, and this shape
has never been timed twice on the same machine state. Read it as the same
measurement, not as an improvement.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 —
**0.34 s**, server responsive.

**What that shape costs, since the 0.34 s is the smallest part of it.** Arithmetic
over the source and the one measured constant (16.3 kB a block); the timing is the
only measurement.

- **8,000,000 nodes**, **codelevel 4 only** since 2026-08-30: the ceiling at
  level 3 is 1e6 and this shape is refused there outright. Level 4's ceiling was
  1e7 when this was measured — a fifth of margin, `cube(216,216,216)` at 1.008e7
  being the first refused — and is **5e7** since 2026-09-02, where the first
  refused cube is 369 on a side.
- **~2200 mapblocks emerged**, ~13 on each axis. `SLICE_BLOCKS` is 16 and the
  cross-section ~169, so `layers` clamps to 1: **every slab is one mapblock thick
  and 169 across** — the "large in two dimensions" case slicing cannot reduce.
- **~36 MB pinned**, against 8192 blocks allowed at level 4, so it never
  throttles. That is why it did not wait.
- **CPU:** 13 slabs, each a VoxelManip read, a full-volume fill and a write over
  ~692k nodes — about 18M Lua table stores. 0.34 s is what the model predicts.

**What nothing charges for.** Serialising ~2200 mapblocks into the map database
and pushing them to every client happen **outside the run and are charged to
nobody**. Neither was measured. Noted under `S5` rather than filed.

### W4 · An unknown block name warns, once [B49]

**Written 2026-09-03 with the fix.** The warning is a chat line to
the running player, so no spec can reach it: the suite runs at mod load, before a
player exists.

1. **A typo warns once and builds anyway.** Run a program that places an unknown
   name in a loop, for example:

       for i = 1, 20 do place(colors.notablock) forward(1) end

   Expect **exactly one** chat line, naming `notablock` and saying the default
   block was used instead, and a line of twenty default blocks rather than a
   stopped program. Not one warning per iteration, and no error.
2. **It is per run, not once for the server.** Without leaving the world, place a
   **second drone** on the same program: it warns on its own account. **No spec
   can reach this** — the flag is a closure upvalue in `getScriptEnv`, which is
   file-local and unexported, and `integration_spec` builds its own `api` table
   by hand — so this case is the only way the per-run scope is ever observed.
3. **The accepted side effect.** A program that probes membership —
   `if colors[name] then ... end` with a name that is not there — also produces
   the one warning. That is known and accepted, not a defect; it is recorded
   under `B49`.

Run case 1 in French too. The key is new `S()` text and the French was written
the same day, so this is where it is read.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — the fix being `d8c32f7`.
**`B49` is now confirmed in a world.** (This result claimed it left the file with
no check without one; `W5` and `W6` were written the same day and had none. That
became true on 2026-09-04, when both ran.) The author reported the check as a whole rather than case by case, so
what is recorded is a pass on the check as written above; case 2 is the part no
spec will ever cover, the per-run flag being a closure upvalue in a file-local
function.

### W5 · A drone that stands still far away keeps running [B52, B50]

**Written 2026-09-03 for the fix committed as `1b991ae`; first run 2026-09-04.** `B52` has
never had a check of its own, and no spec can reach it: the mechanism is the engine unloading a mapblock on
`server_unload_unused_data_timeout` while an object stands in it, which needs a
world, a map and a clock.

Both cases start the same way: fly at least 300 nodes from anywhere a player is,
place a drone, and then leave it alone — do not follow it, do not stand near it.

1. **`sleep` longer than the unload timeout.** Run a program that goes out and
   then sleeps well past the default 29 s:

       forward(500)
       sleep(45)
       place(hues[1])

   **Pass:** after the sleep the block is placed and the run announces itself
   normally. The drone must not disappear silently at about 29 seconds, and no
   *le drone a disparu* line may arrive.
2. **A run left paused.** Start a long program that walks a long way out, then
   **Pause** it from the panel and wait more than a minute before resuming.

   **Pass:** Resume carries on from where it stopped. The panel must still
   describe the same run, and the elapsed clock must not have been reset by a
   restart.

**What a pass means**, and it is why this check is written as the fixed
behaviour: the entity may well vanish from view in both cases — the block under
it genuinely is unloaded — and that is not a failure. The run continuing and
finishing is the whole condition. Before `1b991ae` both cases failed by
construction, so a fail here is the fix not working rather than the old defect.
**This is `B52`'s only possible evidence**: the finding was read out of the
engine and had never been observed in either state.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — **the first result
this check has ever had, and `B52`'s only in-world evidence.** Both cases pass:
the sleeping drone places its obsidian after the timeout and announces itself
normally, and a paused run resumes where it stopped. The author reported the
check as a whole rather than case by case, so what is recorded is a pass on the
two cases as written above. `B52` is no longer a mechanism with nothing observed
against it.

### W6 · The drone's entity goes away and comes back [B50, B29]

**Written 2026-09-03, first run 2026-09-04**, for the fix committed that day as `1b991ae`:
after it, the entity is a *view* of a drone rather than the drone itself, and
losing the view is not an ending. Nothing in the suite can see this — it needs two players' worth of
distance, a real map and the engine's own object management.

1. **Walk away from a running drone.** Start a long program, then fly a few
   hundred nodes away and watch the chat.

   **Pass:** the drone model disappears from view with **no chat line at all**,
   and no finish line. *The drone has disappeared, program stopped* cannot appear
   — `1b991ae` deleted the message and its `S()` key, nothing sends it, and a
   line resembling it would mean a stale build. The panel and the HUD go on
   describing a running program, with the numbers still moving.
2. **Come back.** Fly back to where the drone should be by now.

   **Pass:** the entity is there again, in the right place, and what it has built
   since you left is on the ground behind it. One drone, not two — the re-spawn
   uses the **same serial**, which is `B29`'s guard, so a second model standing
   next to the first is a defect and should be reported as one.
3. **Place a new drone afterwards.** When the program has finished, place a drone
   under the same name.

   **Pass:** it places. *"Drone is busy, please wait!"* means a leaked record,
   which is `B50`'s expensive case.
4. **`/clearobjects` does not end the program.** With a program running, run
   `/clearobjects`.

   **Pass:** the model goes and then comes back — within about a second, which
   is `respawn_period_s` — and the program keeps running throughout. **This is a
   deliberate consequence of the fix, not a bug** — the command blanks the view
   and the mod re-spawns it. It is recorded under `B50` as one of the two costs
   the decision accepted.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — **all four cases**,
reported as *all pass*, and the first result this check has had. So the view
going away is silent, the entity comes back where it should be with its work
behind it, a new drone places afterwards, and **`/clearobjects` does not end a
running program** — the cost the decision accepted, now observed rather than
reasoned. Case 2's *one drone, not two* is **`B29`'s serial guard confirmed in
its post-`1b991ae` form**, where what it guards is the replacement's object
rather than its record; `D3` part 2 was the only earlier in-world evidence and it
predates the change.

### W7 · `print` sends every argument, in one line [B54]

**Written 2026-09-07 with `B54`'s fix at `24842d3`, and it is the only evidence
that fix can have.** What `print` puts in the chat is not observable from any
spec, and that was established by experiment rather than by argument:
`test-agent` added a probe capturing `core.chat_send_player` around a real
`print("a", "b")` and asserted `> a b`; the probe read **`want: > a b, got:
nil`**, because two load-time locals each shut the interception off —
`lib/commands.lua:26` binds `chat_send_player`, `lib/sandbox.lua:36` binds
`drone_send_message` — and there is no logged-in player to receive the line
anyway. The probe was removed and the result kept as a comment. **The twelve
spec cases that do exist pin the charge, not the text**: one call is one command
however many arguments it carries.

As a player at **codelevel 4**, with a block of a known colour in front of the
drone, run these three programs and **read the chat**:

```lua
print("is: ", is_block(colors.red))
```

**Pass: one line reading `> is: true`** — one message, both arguments, one space
between them.

```lua
print()
```

**Pass: a bare `> `**, an empty separator line, and **not** `> nil`. That is
deliberate: `print()` in real Lua is a blank line, and refusing to send would
make it the one API call that silently does nothing. It still costs one command,
so it cannot be spammed free.

```lua
print("a", nil, "b")
```

**Pass: `> a nil b`** — the line does **not** truncate at the nil. That is what
reading the varargs with `select('#', ...)` buys, and it is not theoretical:
`get_block()` answers `nil` over map that was never generated, so a player prints
a nil routinely, and `{...}` with `#` would have thrown away everything after it.

**What separates a pass from *did not crash*, and this is the whole reason the
entry exists: the broken build printed `> is: ` and stopped, with no error
anywhere.** So *no error in chat* is not the check — the boolean being visibly
present is. Writing it the other way, `print("is: " .. is_block(...))`, raised
*attempt to concatenate a boolean value*, which is correct Lua and is not
something the mod works around; a player was walled both ways, which is why the
report read *"the print function in the game cannot concatenate arguments"*.

**The separator is checkable nowhere else either.** The join is a **space** and
not real Lua's tab, on the reasoning that Luanti's chat console has no tab stops
— a tab goes through the client font as an ordinary glyph — and that the engine's
chat wrapping breaks on spaces, so a tab-joined line would refuse to wrap on a
narrow console. **`lua_api.md` says nothing about either**, so that is reasoned
from the client's text path and **is not verified**. Look at a long `print` on a
narrow console once, and say if it does not wrap.

**`error` was deliberately not widened** — real Lua's `error(message, level)` is
not variadic — so there is nothing to check there.

Result: not yet run.

---

## Pacing, slabs and the footprint throttle

P1–P4. Three runs across 2026-08-27 and 2026-08-28, which produced `B42` and —
from a *measurement* rather than a failure, the only finding here with that
provenance — `B43`.

### P1 · `pace_ms` at the low codelevels [S5, B26]

Run the same loop at codelevel 1, then 2, then 4.

**Pass:** level 1 visibly waits about 250 ms between commands and level 2 about
5 ms, so a beginner can watch the loop happen; levels 3 and 4 do not wait.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27, when level 2 was 15 ms.

### P2 · Slab progression under the step budget [A5, B26]

Run a shape large enough to take many slabs and watch the server step time.

**Pass:** the deadline is honoured at every drone command and before every slab.
The known overshoot is **one slab** — a VoxelManip pass cannot be interrupted,
the deliberate trade that lets a shape be any size.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### P3 · The footprint throttle actually throttling [S5]

Run `cube(2, 2, 30000)` at codelevel 1, **both facings**.

**Pass:** the drone **waits** and then continues. It must not die: over the
ceiling `limits.hold` returns how long to wait, because the engine frees idle
mapblocks by itself. **Facing does not matter any more**, and checking that it
does not is half of this check (`B42`).

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — the re-timing that proved
`B43`'s fix, at codelevel 1, view distance 500: **78 s one way, 95 s the other**,
where a doubled emerge would have cost 183 s. Before the fix the same shape spread
**78 / 160 / 183 s** across three facings. The factor of two is gone.

Result: pass — `febf16f` · engine 5.17.0 · 2026-08-28 — **the first measurement of
the throttle**, which `S5` had claimed from reading since Phase 5: the shape
completed in **93 s** against a predicted ≈80 s (512 mapblocks decaying over 29 s
is 17.7 a second; the shape emerges ~1877 with the first 512 free). Consistent,
the gap in the direction the estimate is coarse.

Earlier: fail — `246bb37` · 2026-08-27 — the drone died where the ceiling exists
to make it wait. That is `B42`.

**Two things this leaves, recorded rather than filed.** The 95 s is 23% over the
78 s and the emerge model does not explain it — the multipliers can only be 1, 2
or 4. And only two of four facings were timed, at a different codelevel from the
pre-fix run. **Neither is `B43` returning**; the doubling is what the numbers rule
out.

**Also observed, no id:** at codelevel 1, view distance 30, nothing of the shape
appeared until the drone was stopped. Not a deferred write — nothing here touches
the map when a drone stops — and at view distance 500 it was visible as it built,
so it is most likely what the client drew.

### P4 · Several drones at once [A5]

Run four or more drones simultaneously.

**Pass:** they share one slice of each server step rather than taking one budget
each, and a waiting drone takes no share.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — four drones shared.

---

## Release and install

### R1 · The archive contains no `tests/` [C16, C10]

**Pass:** no `tests/` directory. ContentDB builds releases with `git archive`, and
nothing in CI checks `.gitattributes`.

**Read the top level, not a grep of the whole listing.**
`git archive HEAD | tar -t | grep tests` answered *fail* on a correct archive for
the project's whole life, because `lib/examples/tests.lua` — a player-facing
example — matched it. **That file was deleted at `b752ea3`**, so the grep no
longer misleads for that reason; use the top-level listing anyway, because it is
the question being asked:

```bash
git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u
```

Result: pass — `afbe504` · engine 5.17.0 · 2026-08-28 — eleven top-level entries,
all player-facing, **none of the record**. `screenshot.png` survives, which it
must. **`C10` confirmed**, the rules having been right for the project's whole
life with nothing ever having looked.

Result: pass — `7dbe18f` · engine n/a · 2026-09-02 — re-checked because
`.gitattributes` changed at `60dc8dd`, after the first run. The same eleven
entries, and `textures/` ships four PNGs with the two `.svg` sources excluded.
No engine is needed for this one: it reads `git archive`, not an install. **That
is also what it cannot tell you** — whether the archive *loads* is `R2`.

**Both results are stale on the texture count.** `F11` added
`codeblock_block.png` and `codeblock_glass.png` and `F12` added
`codeblock_lamp.png`, so `textures/` now holds **seven PNGs and two `.svg`
sources**, and `lib/examples/tests.lua` is gone while `lib/examples/game.lua` is
now tracked at `63c3c33`, so `lib/examples/` holds **fourteen**. Nothing in CI
checks `.gitattributes`, so the next run is what says whether the new PNGs ship,
whether `game.lua` ships with the other examples, and whether the `.svg` pair
still does not.

### R2 · A real install with the test flag set [C16]

**Building the archive**, which nothing here used to say. ContentDB builds
releases with `git archive`, so that is what reproduces what a player gets:

```bash
git archive --format=zip --prefix=codeblock/ -o /tmp/codeblock.zip HEAD
```

Three things about that command decide whether the check means anything.

- **`git archive` archives a commit, not the working tree.** Anything
  uncommitted is absent, so commit first — and for the release itself pass the
  **tag**, not `HEAD`, because the tag is what ContentDB builds from.
- **`export-ignore` is read from the `.gitattributes` at that revision**, not
  from the file on disk. So a rule added but not committed does not apply, and
  the archive is the only place that shows it.
- **`--prefix=codeblock/`** makes the zip extract straight into `mods/codeblock/`.
  It is a convenience rather than a requirement: `mod.conf` sets
  `name = codeblock`, so the engine does not care what the directory is called.

Then extract it into a game's `mods/` as a player would, set
`codeblock_run_tests = true`, and start. **The dependencies have to be real
ones:** `default` and `wool` come from `minetest_game`, and **`vector3` is
installed separately from its own ContentDB package** — the copy under
`tests/game/mods/` is `export-ignore`d, exists for the suite, and is not in the
archive.

**Pass:** the mod loads normally and logs *"codeblock_run_tests is set, but this
build ships no tests/ directory"*. **Fail is the mod refusing to load** — nine
bare `dofile`s of files the archive does not contain.

**Do it in a game that is not `codecube`.** `B38`, `B39` and `C18` were each
invisible there, and that is the rule this phase paid for twice.

Result: pass — `7c5bceb` · engine 5.17.0 · 2026-08-28 — extracted into
`minetest_game`'s `mods/` beside `vector3`; loaded and warned. **`C16` confirmed**
— the one thing only an install could show.

### R3 · The sky belongs to the game [C18]

Install into a game with an ordinary day/night cycle — anything but `codecube` —
and join. Then set `codeblock_flat_sky = true`, restart, join again.

**Pass:** the first join leaves the sky alone; the second holds daylight at noon
with sun, moon, stars and clouds gone. The setting is read once at mod load, so
**a restart is part of the check**.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — both
positions. **`C18` confirmed**, and the first time its player-visible half was
*seen* rather than inferred: inside `codecube` the flat sky is the game's own
design and looks correct.

### R4 · A brand new world hands out the right codelevel [S6]

**New 2026-08-30, first run 2026-09-02.** The singleplayer default moved from 4 to 3, and
`register_on_newplayer` is the only place it is written — so **a world with any
history in it proves nothing here**. Create a fresh world each time.

1. **Singleplayer, fresh world.** `/codeblock level` with no argument. **Pass: 3.**
2. **A server, fresh world, a joiner who has never connected.** **Pass: 2.**
3. **Either, with `codeblock_default_auth_level = 4`** and a restart. **Pass: 4**
   — the setting wins over both built-in defaults.
4. **An existing player in an existing world, after upgrading the mod.** **Pass:
   unchanged.** The write is on *new player*, so an upgrade must neither demote
   nor promote anyone — the half of `S6` that surprises people.

Worth reading the log once while you are there: `codeblock_default_auth_level = 9`
must warn and fall back rather than giving a player nil limits.

Result: pass — `cd13414` · engine 5.17.0 · 2026-09-02 — **`S6`'s narrowing to 3
in singleplayer is now observed rather than reasoned**, which is what this check
was written for. The out-of-range guard was read in `debug.txt` and is right,
naming the bound and saying what it did:

```
2026-09-02 11:50:08: WARNING[ServerStart]: [codeblock] setting
codeblock_default_auth_level is not a codelevel from 1 to 4; ignored
```

So an administrator who writes `9` gets the built-in default, not a player with
nil limits.

---

## Per-feature checks

Added as each feature lands, for the paths it puts beyond the specs.

**A check here is named `F<feature>-<n>`** — `F10-2` is the second check written
for `F10` — numbered in the order they appear below, and **never renumbered**,
the same rule the finding ids follow. A feature with one check still gets the
`-1`. Before 2026-09-03 they were all titled with the bare feature id, so four
checks were called `F10` and two `F1` and a citation could not name one of them;
write the suffix from the start. **`F<feature>` on its own always means the
feature**, whose entry is in `ROADMAP.md` — the group heading below, `F10-2`'s
`[F10, B16, B39]` brackets and every `(audit F9)` elsewhere are references to the
feature, not to a check. Note also that the *Filesystem and example generation*
group above is `F-1`–`F-5`, where the `F-` is **filesystem**: unrelated to this
series despite the shape.

### F1-1 · The Settings panel [F1]

Open the editor and click **Settings** beside Blocks / Plants / Wools / API.

**The control is not what the plan first described.** The panel draws the chosen
block's texture plus a button reading **`Default block: <name>`**; clicking it
opens a `textlist` of names. A `scroll_container` of `item_image_button` rows was
abandoned — this formspec is legacy coordinates, where a container clips to its
own rectangle and a button inside one gets a hit area that does not match where it
is drawn. The price is that the rows are names only.

**Pass:** the button shows the current default; clicking it opens and closes the
list; selecting a row changes both the name and the texture; `air` is offered and
selectable; switching panels and back leaves it usable.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F1-2 · The preference survives a relog [F1]

Pick a block, close with **ESC**, disconnect, rejoin, run a program whose
`place()` names no block.

**Pass:** the chosen block is what gets built. The meta write happens the moment a
row is selected, not on form close — precisely so the preference does not depend
on the editor-state save path.

Then change the preference mid-run: **pass** is that the running program keeps
building the block it started with, the preference being read once per run.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F3-1 · `sleep(seconds)` in a running world [F3]

Run a program that places a node, calls `sleep(1)`, and repeats — at codelevel 3
or 4, where `pace_ms` is 0 and the wait is the only thing pacing it. Then run one
asking `sleep(1e9)`.

**Pass:** the drone visibly builds one node a second; the server stays responsive
and any other drone keeps its own rate while this one waits; and the unbounded ask
ends the program with the same timeout message a program that never finishes gets,
rather than parking the drone for ever.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F9-1 · The words on the panel and the HUD [F9, B46]

Everything here is words and placement, so **the suite cannot see any of it** —
`forms_spec` pins the formspec string, not what it looks like drawn. Do this
**in French as well as English**, which is where the panel's earlier layout
defects showed first.

1. **The HUD's third line reads *CPU time*, not *CPU*** — *Temps CPU* in French —
   and the five-line block still fits the corner without wrapping.
2. **The idle panel reads `<program> : idle`**, filename bold, state bold, **no
   colour**, and looks like the running heading rather than a sentence. *Drone
   idle, holding …* is gone.
3. **A running panel's heading carries the elapsed time in parentheses**,
   immediately after the state word and **bold with the rest of the line** — only
   the state is coloured, the parentheses and the number are not.
4. **It counts up while the panel sits open**, matches a stopwatch, and **stops
   dead while the run is paused** — press *Pause*, watch a minute go by, and the
   number does not move while the state word says paused. Press *Resume* and it
   carries on from that number rather than jumping the minute forward. Rewritten
   2026-09-02: this checked the opposite until the author saw it in a world.
5. **It reads `43s`, then `6m 27s`, then `1h 12m`** as the run passes a minute
   and an hour. The last needs a long program or a paused one left alone.
6. **The duration and the `Server time used` row disagree, by a lot** — some 4.6%
   of it at codelevel 4 — and that is the pass, not a defect. Two numbers about
   time on one form is what `B46` was filed for; check the row's describing line
   still says it is not clock time.
7. **A long filename does not push it off the panel.** Open a program at the
   15-character cap, in French, and look: it is one label, so a long line runs on
   rather than overlapping anything, and the panel edge is what it can reach.
8. **When the run ends, the `duration:` in the chat message matches the last
   number the panel showed.** They are one call to `Drone.elapsed_us`, so a
   mismatch means one of the two is reading something else — and a run paused
   part-way is the case that tells them apart.

Result: pass — `029fab9` · engine 5.17.0 · 2026-09-02 — cases 1–3 and 5–8 in both
languages, against the behaviour `F9` first chose.

Result: pass — `dc09d48` · engine 5.17.0 · 2026-09-02 — case 4 only, in its
rewritten form: the number stops with the pause and carries on from there.
Checked on the tree that became that commit.

Case 4 passed twice, once each way round: as `F9` first chose it and then as the
author asked for on seeing it. Case 8 pairs with it — the panel and the finish
message read one function, so a pause is out of both.

### F10-1 · A fresh player is given nothing [F10, C21, C18, B39]

**Written 2026-09-03, before the code existed; the code is `b23a8bc`.** Every
part of `F10` is beyond the specs — a join
callback, an inventory write, a privilege grant, a chat command — so this group
is the only evidence there will be. Case 2 is `C21`'s only route.

Take a world this player has **never joined**, in a game that is **not**
`codecube` — `B38`, `B39` and `C18` were all invisible there — and join it.

1. **No tools.** The inventory is exactly what the game gives a new player, and
   neither the Drone placer nor the Drone setter is in it.
2. **No privileges.** `/privs` lists what the game grants; **`fly`, `fast` and
   `noclip` are not there** unless the game or the server granted them itself.
   This is the check for the grant `F10` removed, and the reason it matters is
   that the mod was giving them away in every game that installed it.
3. **One chat line, naming both routes.** It says how to get the tools —
   `/codeblock tools` and the creative inventory — and nothing else.
4. **It is said once.** Quit and rejoin: no second line.

Do case 4 in French as well. The line is new `S()` text, and half of what `C17`
covers is only visible in the other language.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03.
Recorded partial first and **completed the same day** on the author's second
report: **case 1**, the fresh player's inventory holds neither the Drone placer
nor the Drone setter; **case 2**, `/privs` shows no `fly`, no `fast` and no
`noclip`, which is **`C21`'s only possible in-world evidence** and is now
observed rather than inferred; **case 3**, the chat line arrives — the open risk
`code-expert` said it could not confirm, since `chat_send_player` from
`register_on_newplayer` fires before the client has finished loading and the
message is *not* dropped. On the first report the line appeared in English on a
French client, which was the expected state at the time and is not a defect; the
eight French strings were written later the same day. See `F10`'s roadmap entry.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — re-affirmed once `F10`
was committed at `b23a8bc`. Same four cases, same code, now under a hash rather
than a working tree.

Result: pass in French — commit not restated · engine version not restated ·
2026-09-04 — the author reports *"F10: french works ok"*, read on a French
client. **That closes case 4's French half**, which the two runs above left owed:
they read the first-join line in English, the eight French strings not yet having
been written. The strings are unchanged since `b23a8bc`, so any tree from that
commit forward carries them and `HEAD` was `23f0227`; the commit and the engine
version are recorded as not recorded rather than inferred.

### F10-2 · `/codeblock tools` [F10, B16, B39]

1. **It hands both tools over.** Run it with an empty inventory: the Drone placer
   and the Drone setter appear, and nothing else changes.
2. **It does not duplicate a tool already carried.** Run it again: still one of
   each. Then **park one tool in the craft grid** and run it again — still one of
   each. That is `B39`'s rule, and the command reaches it far more easily than
   the once-per-join handout ever did, because it can be run any number of times.
3. **A full inventory is refused cleanly.** Fill `main` completely and run it:
   the message says what happened, and the player is not left holding one tool of
   two. The old join-time refusal was answered in code and never once seen run.
4. **For another player it needs the priv.** Without `codeblock`,
   `/codeblock tools <someone>` is refused; with it, the tools land under the
   named player and not under the caller.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03.
The command's replies read in English on a French client, which was the state at
the time of the run — the eight new `S()` keys were deliberately left
untranslated and have since been written. Not a defect; `F10`'s roadmap entry
carries it.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — re-affirmed at the
committed code, `b23a8bc`.

Result: pass in French — commit not restated · engine version not restated ·
2026-09-04 — covered by the author's *"F10: french works ok"*, which is one
report over the whole of `F10` and not a case-by-case run. **The replies are read
in French**, which the two runs above could not show. Recorded with the same
caveat as `F10-1`'s French line: the strings are unchanged since `b23a8bc`, the
commit and the engine version were not restated.

### F10-3 · The two renamed subcommands [F10, B8, B9, C17]

`/codelevel` and `/codegenerate` are gone, deliberately and with no aliases.

1. **`/codeblock generate` works on your own files with no privilege**, and a
   second run leaves existing files alone — `F-1` under the new name.
2. **`/codeblock generate <player>` needs the priv**, and with it the files land
   under the named player — `F-2` under the new name. **Run this one in French.**
3. **`/codeblock level` is privileged either way**, including for yourself. A
   player without `codeblock` cannot raise their own level, which is the whole of
   `B9`: codelevel bounds resource use, so setting your own is lifting your own
   ceilings.
4. **Bare `/codeblock`, and a subcommand that does not exist**, each print the
   three usages rather than failing silently or claiming success.
5. **The old names are gone**, and the engine says so — `/codelevel` reports an
   unknown command rather than doing anything.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — re-affirmed at the
committed code, `b23a8bc`.

### F10-4 · A dropped tool can be recovered [F10]

The `on_drop` stubs are removed, which is only safe because the command exists.

1. **Drop the Drone setter.** It leaves the inventory and lands in the world, as
   any other item would.
2. **Get it back with `/codeblock tools`.** Both tools are in the inventory
   again, one of each.
3. **The dropped item is still a working tool** if picked up instead — this is
   the case where a player could end up with two, and case 2 of the command check
   is what keeps that from being the command's doing.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — re-affirmed at the
committed code, `b23a8bc`.

### F11-1 · The category selector, in French [F11, B37]

**Run this one first.** It is the only check here whose failure is expensive: it
would mean converting the editor out of legacy coordinates.

Play on a **French** client. Open the editor.

1. **Move the category selector to *Verre*, then press `Blocks`.** The **glass**
   panel must open — not the colours panel, and not nothing.
2. **Press `API`.** The API panel opens.
3. **Press `ESC`.** The editor closes and **the open tabs are still saved** —
   the same thing `E14` checks, re-checked here because the selector is an
   always-sent field sitting in the same handler.
4. Repeat 1 in **English**, moving it to *Glass*.

**Pass:** the selector switches the panel in both languages, and ESC still saves.

**If it works in English and does nothing in French, that is a finding and not a
mystery:** the client is returning the *displayed* text rather than the stored
item, so a translated label never matches the untranslated one the guard
compares against. The fix would be formspec-version-4 `index event`
(`lua_api.md` 5.17.0 line 3579), which this form cannot use while it is in
legacy coordinates — see `F11` in `ROADMAP.md`.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all four cases. The selector switches
the panel in French and in English, and ESC still saves the tabs. **So a legacy
dropdown returns the stored item and not the displayed text**, which is the
expensive failure this check was run first to rule out: the editor does not have
to leave legacy coordinates.

### F11-2 · The help row's geometry [F11, F1]

The arithmetic is exact and derived from `src/gui/guiFormSpecMenu.cpp`, and it
has **never been on a screen**. A legacy button's `W` is short by a fixed 0.2
units and a dropdown's is not, which is the trap the whole row is built around.

Look at the top right of the editor, in **English and in French**, whose words
are longer.

**Pass:** `Blocks`, the selector, `API` and `Settings` sit flush on one row, the
same height, none overlapping another, and no label clipped.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the row is flush in both
languages, nothing clipped and nothing overlapping. **The 0.2-unit button offset
was arithmetic off `guiFormSpecMenu.cpp` until this run** and is now on a screen.

### F11-3 · The mod installs into a game that ships neither `default` nor `wool` [F11, C16, C10]

**This is the whole point of the feature and nothing local proves it** —
`tests/game` is a fixture this project wrote for itself.

Install the mod, plus `vector3`, into a third-party game from ContentDB that
ships neither `default` nor `wool`. Start a world, get the tools with
`/codeblock tools`, place a drone and run a program that places a block.

**Pass:** the game starts, the mod loads with no dependency error, and the block
lands. **Anything in `debug.txt` naming `codeblock` is worth reading** even on a
pass.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the mod loads and builds in a
third-party game that ships neither `default` nor `wool`. **That is the whole
point of `F11` observed rather than reasoned about**, and nothing local could
have shown it.

### F11-4 · Retired 2026-09-07 — superseded by `F12-1` and `F12-2` [F11, F12]

**Do not run this one, and it is no longer owed.** It asked for a row of the 33
solids reading as their hexes and a wall showing the tile's grain. `F12` replaced
the palette with 35 colours and made the solid tile a flat pure white, so both
halves moved: the hexes and the palette order are **`F12-1`**, the wall is
**`F12-2`**. The id is kept so nothing that cites it dangles. Never run, so no
result was lost.

**Both successors passed on 2026-09-07 at `8e6350f`**, which is what retires it
rather than leaving it superseded-but-outstanding: everything this check was for
has now been looked at, in its current form.

### F11-5 · Coloured glass and coloured lamps [F11]

1. **Build a glass wall** of two or three colours, with light behind it. Join two
   faces at a corner.
2. **Put one lamp in a dark room**, then swap it for a different colour.

**Pass:** the glass tints what you see through it and **does not go opaque where
two faces meet**; a lamp lights the room.

**Every colour of lamp lights the room identically, and that is correct, not a
defect.** Luanti's light carries no hue — a light source has a level and no
colour — so a blue lamp gives white light. A player will test this first, so it
is written down here rather than left to be filed.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the glass tints, the corner
where two faces meet does not go opaque, and a lamp lights a dark room.

### F11-6 · The blocks are silent, deliberately [F11]

Walk on one, dig one, place one, and listen.

**Pass:** nothing. **None of the 105 has a `sounds` field**, on purpose: every
`node_sound_*_defaults()` belongs to a game, and calling one would put the mod
back to needing a game to provide something. **A player will read silence as
broken**, so the point of this check is to have it seen once and recorded as
intended.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — silent, and read as intended
rather than as broken. **That is the point of this check and it is now spent**:
the silence has been seen once and recorded.

### F11-7 · Digging, in a game that is not `codecube` [F11, B48]

Dig one of the mod's blocks **by hand** and then **with a pick**, in a game that
provides its own tools.

**Pass:** the block breaks in a sensible time by each route and drops itself.
Watch for the block reappearing after it looked broken — that is client-side dig
prediction disagreeing with the server, and it is the shape `B48` was.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — by hand and with a pick, in a
game providing its own tools; the block drops itself and does not reappear after
looking broken.

### F11-8 · The creative inventory [F11]

Open the creative inventory in a game with a small item set, and search
`codeblock`.

**Pass:** 105 items with descriptions that read sensibly, and the mod's section
does not swamp the game's own. **`F12-1` counts them**; what this check is for
is whether they read sensibly and whether 105 of them swamp a small game's own
item set.

**The descriptions read *"Bloc red"* on a French client, and that is
deliberate** — the colour name is the identifier a program types, so translating
it would show a word `place()` does not accept.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the descriptions read sensibly
and 105 items do not swamp a small game's own item set.

### F11-9 · `is_ground_content = false` survives mapgen [F11]

In a game that **generates terrain** — not a flat or singlenode world — build
something with the mod's blocks, then travel far enough that the area unloads and
come back. Better still, build near a cave or an ore-bearing depth.

**Pass:** the build is intact. `is_ground_content = false` is what keeps mapgen
from carving a player's structure away, and only a real mapgen can show it.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the build is intact after the
area unloaded and came back. `is_ground_content = false` behaves, and only a real
mapgen could have shown it.

### F11-10 · A real game mod calls `register_blocks` [F11]

Write a small mod that names `codeblock` in its `depends` and calls
`codeblock.register_blocks` at load time — the contract is in `lib/blocks.lua`'s
header.

1. **A good call.** Two or three names pointing at nodes the game registers.
   **Pass:** the category appears in the sandbox, in the editor's block picker
   and in the help panel's selector, showing its **raw** name.
2. **A bad call.** A name that is not a valid identifier, a name colliding with
   one of the mod's own, and an itemstring naming no node. **Pass:** each is
   refused with a line in `debug.txt` **naming your mod, the name and the rule**,
   and the server keeps running.
3. **A late call.** Call `register_blocks` from inside a `core.after` or a
   globalstep, after loading is done. **Pass:** it is **refused** and logged —
   not accepted, and not merely warned about. It cannot be validated after the
   seal, so accepting it would be accepting an unchecked name.

Result: not yet run.

### F11-11 · A registered category reaches `place()`, `get_block()` and player meta [F11]

With the mod from `F11-10` installed. **This is the `rev_blocks` fix's only
possible evidence.** A spec *can* call `get_block` —
`codeblock.commands.drone_get_block` is exported and `integration_spec` asserts
its out-of-world branch — but **no spec can make a read land inside the world**:
`lib/commands.lua` captures `core.get_node` at load, and a probe at the origin
at mod load dies inside builtin with `bad argument #1 to '__index' (number
expected, got nil)`, content ids not being cached yet. Measured 2026-09-06, not
assumed.

1. Run `place('wool.red')`.
   **Pass:** the node lands.
2. Print `get_block(0, 0, 1)` from one step behind it, then move onto it and
   print `get_block()`.
   **Pass:** both answer the name for that node — **not `false`**, which is what
   a load-time snapshot of the reverse map would have given for every
   game-registered node, and **not `nil`**, which is what a missing
   `load_block` would give.
3. **Pick `wool.red` as your default block** in the editor's *Settings* panel,
   disconnect and rejoin.
   **Pass:** the dotted key survived in player meta as `default_block`, and a
   bare `place()` builds it.

Result: not yet run.

### F12-1 · 105 nodes register, and the picker shows them in palette order [F12]

Written 2026-09-06 at `01f9641`. This replaces the counting half of `F11-4`.

1. **Count them.** Creative inventory, search `codeblock`.
   **Pass:** 105 items — 35 solids, 35 glass, 35 lamps.
2. **Open the editor's block picker** and read the `colors` list top to bottom.
   **Pass:** five neutrals light to dark — `white`, `light_grey`, `grey`,
   `dark_grey`, `black` — then ten families in wheel order, `pink red orange
   yellow olive lime green cyan blue violet`, each as `light_<name>`, `<name>`,
   `dark_<name>`. Not alphabetical.
3. **Build a row of all 35 solids** and look at them together.
   **Pass:** each reads as the hex `lib/config.lua` gives it, and adjacent ones
   are distinguishable at a glance.

**The five neutral hexes are `project-manager`'s, not the author's** — an even
grey ramp `#ffffff #c0c0c0 #808080 #404040 #101010`, chosen because the author
named the five neutrals and gave no values. **They are the easiest thing here to
change**, so say if they read wrong.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all three cases: 105 items, the
picker in palette order rather than alphabetical, and 35 solids each reading as
its hex and distinguishable from its neighbours. **The five neutral hexes were
`project-manager`'s choice and are accepted as they are** — nothing was said
against them, so the even grey ramp `#ffffff #c0c0c0 #808080 #404040 #101010`
stands.

### F12-2 · A lamp wall shows the grid; a solid wall shows nothing [F12]

Written 2026-09-06 at `01f9641`. This replaces the wall half of `F11-4`, and
**it is the check that may hand a decision back.**

`F12` made `textures/codeblock_block.png` a **flat pure white**, so
`^[multiply:#rrggbb` reproduces the palette hex exactly and a solid block is a
flat fill of its colour. The grain `F11` chose is gone from the solids. Glass
keeps its frame and highlight; the new `textures/codeblock_lamp.png` is a faint
grid, ground 252 with lines at 234 every 8 px.

1. **Build a wall of one lamp colour**, several blocks each way, and stand back.
   **Pass:** the grid is visible enough that individual blocks read as blocks,
   and faint enough that it is not a pattern you look at.
2. **Build the same wall in the matching solid** and stand back from it.
   **Pass is a judgement, not a behaviour:** decide whether a flat wall with no
   node-edge definition reads acceptably in a build, or whether it reads as a
   texture-missing surface — which is the reason `F11` put a grain there in the
   first place.
3. **Put the two walls side by side** and look at the corner where they meet.

**If (2) reads badly, that is not a finding — it is the decision coming back.**
Say so and the solid tile gets a grain again, at the cost of the hex no longer
being reproduced exactly. Both options are in `ROADMAP.md` under `F12`.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — **and it did not hand the
decision back.** The lamp grid reads as blocks without becoming a pattern, and
the flat solid wall reads acceptably rather than as a missing texture. **So the
flat pure white tile stays and the question is closed**: `F11`'s grain is not
coming back to the solids, the exact hex is kept, and `ROADMAP.md` records it
under *other decisions* so it is not proposed again. This check had been carried
as an open question for the author since `F12` shipped; it is not one now.

### F12-3 · `get_block` and `is_block` answer over real map [F12, F13]

Written 2026-09-06 at `01f9641`, **extended the same day at `4450ce1`** with
`is_block`, which is the same read path — a separate group would mean walking to
the same three positions twice. In a game with **ungenerated map** you can
reach — not a fully pre-generated world.

1. Place one of the mod's blocks, move the drone onto it, and
   `print(get_block(), is_block(colors.red), is_block(colors.blue))`,
   substituting the colour you placed for the first of the two.
   **Pass:** the block's name, then `true`, then `false`.
2. Move the drone onto a node the game provides that no program can place —
   any node not in the mod's palette and not in a registered category — and
   `print(get_block(), is_block(colors.red))`.
   **Pass:** `false`, then `false`.
3. Point the drone at map the engine has never generated — far out, or well
   above or below the generated band — and
   `print(get_block(), is_block(colors.red), is_block(colors.typo))`.
   **Pass:** `nil`, then `false`, then `false`.
   **The third of those is the one worth watching.** `colors.typo` is `nil` and
   so is the read, so the guard that stops `nil == nil` reading as `true` is
   what makes it `false`. A `true` here means that guard has been simplified
   away. Expect one chat line naming `typo` as an unknown block — that warning
   says *the default block is used instead*, which is wrong for `is_block` and
   is a known imprecision, not a fail (`F13` in `ROADMAP.md`).

**What distinguishes a pass from *did not crash*: `false` and `nil` must be
different answers.** If the unplaceable node in (2) also reads `nil`, the
`load_block` call is not happening and every read is coming back `ignore`, so
everything reads as absent. That is the one failure this check exists for.

**`nil` in (3) is permanent and correct.** `core.load_area` does not run mapgen,
so reading never generates terrain and waiting will not turn it into a name.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all three cases, with `false`
and `nil` coming back as **different** answers, which is the one failure this
check exists for. `colors.typo` read `false` and not `true`, so the guard against
`nil == nil` is in place.

### F12-4 · The read offsets turn with the drone and move nothing [F12, F13]

Written 2026-09-06 at `01f9641`, **extended the same day at `4450ce1`**:
`is_block` takes `get_block`'s offsets and has to turn with the drone the same
way. **Genuinely unreachable by any spec** — every
rotation that moves a target outside the world moves another one inside it, and
an in-world read cannot be asked for at mod load at all.

Stand the drone one node from a wall of a known colour, facing it, then:

```lua
for i = 1, 4 do
    print(i, get_block(0, 0, 1), is_block(colors.red, 0, 0, 1))
    turn_left()
end
place()
```

**Pass:** the wall is reported at exactly one of the four facings — the one
pointing at it — and `nil` or the surrounding node at the other three, with
`is_block` `true` at that one facing and `false` at the other three. Then the
`place()` afterwards lands **where it would have landed before the reads**: the
drone has not moved and, after four `turn_left()`, is facing where it started.
That covers both calls: `is_block` reads through `get_block`'s implementation,
so a move introduced in one would show here.

**This check cannot be performed on a build whose `print` takes one argument**,
and that is how `B54` was found: the recipe's own first line prints three values,
and until `24842d3` only `i` came out. The reads themselves were never reached
by the eye. **Re-run it in full** — the rotation half is still unobserved.

Result: fail — `8e6350f` · engine 5.17.0 · 2026-09-07 — **the check could not get
past its own first line.** `print(i, get_block(0, 0, 1), is_block(colors.red, 0,
0, 1))` printed the loop counter and stopped, with no error, and writing it as
one concatenated string raised *attempt to concatenate a boolean value*. That is
**`B54`**, filed and fixed the same day at `24842d3`. **Nothing is known about
the rotation this check exists for**: the fail is against `print`, not against
`get_block` or `is_block`, and this entry stays owed until it is re-run on
`24842d3` or later.

### F12-5 · A ramp reads as a gradient, and the other ramps strobe [F12]

Written 2026-09-06 at `01f9641`, **narrowed the same day at `4450ce1`**: the
clamping is no longer uncovered — `ramp_over` gained 57 assertions across all
four built-in ramps, run as real programs in the sandbox rather than by
exporting a private closure factory. **What is still observable nowhere else is
the visual half**, which is cases one and two below; the clamp in case three is
now belt and braces.

```lua
for i = 1, 20 do place(ramp.hues(i, 1, 20)); up(1) end
```

**Pass:** the column walks the colour wheel once, smoothly, and the first and
last blocks are visibly different colours.

Then the same loop with `ramp.colors`.

**Pass:** it **strobes** — light, plain, dark inside each family in turn. That
is correct and not a defect: it follows from the author's own answer that every
category gets a ramp, and `colors` is ordered by family rather than by
lightness. `ramp.hues` is the one that reads as a rainbow.

Finally check the clamp: `ramp.hues(-5, 1, 20)` and `ramp.hues(99, 1, 20)`.

**Pass:** the first and last hue, not a wrap round to the other end.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — `ramp.hues` walks the wheel once
and reads as a gradient; `ramp.colors` strobes, as designed; the clamp gives the
first and last hue rather than wrapping.

### F12-6 · A game-registered category gets a ramp of its own [F12, F11]

Written 2026-09-06 at `01f9641`. With the mod from `F11-10` installed, so it is
cheapest run in the same session.

1. `print(ramp.wool(1, 1, 3))` — substituting your category's name and a range
   matching how many entries it has.
   **Pass:** a name from that category, and walking the range gives each of them
   in turn.
2. **Open the help panel's *Choosing blocks* group.**
   **Pass:** `ramp.<name>` is listed there beside `ramp.hues`, `ramp.colors`,
   `ramp.glass` and `ramp.lamps`, and its text says the order is alphabetical
   and therefore a lookup rather than a gradient.

**A registered category is sorted alphabetically**, so its ramp is not a
gradient and the generated documentation says so. That is deliberate: the mod
cannot know a game's colour order, or whether its category is colours at all.

Result: not yet run.

### F14-1 · The API help panel lists the new views and `ramp.of` [F14]

Written 2026-09-07 while `F14` was still being built; `F14` shipped the same day
at `e3e2178` with its gates green, so it is ready to run. `api.to_hypertext`
runs **only** in a running world, so what the panel renders is observable
nowhere else.

1. **Open the editor's API help panel and find the *Choosing blocks* group.**
   **Pass:** `light_hues`, `dark_hues` and `neutrals` are listed there beside
   `hues`, each with its text, and `ramp.of` is listed beside `ramp.hues`,
   `ramp.colors`, `ramp.glass` and `ramp.lamps`. Nothing is truncated, and the
   group scrolls to the bottom with the new rows in it.
2. **Read `ramp.of`'s description.** **Pass:** it says it takes a list, so a
   player can see it accepts one of their own and not only a built-in view.
3. **Then run `F14-3`**, which is that same program with the pass criteria the
   panel cannot give you. It was a step here and became an entry of its own on
   2026-09-07, so that the program and the colours it must produce are described
   in one place.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — `light_hues`, `dark_hues`,
`neutrals` and `ramp.of` are all listed with their text, nothing truncated.
`api.to_hypertext` runs only in a world, so this is the only evidence there will
be that `F14`'s rows render.

### F14-2 · Reading past the end of a palette view is silent [F14]

Written 2026-09-07 at `e3e2178`, out of `F14`'s coverage work. **No spec can
ever replace this one, so do not delete it as redundant.** `lib/sandbox.lua`
binds `chat_send_player` as a load-time local, so a spec cannot intercept the
misspelling report by replacing `core.chat_send_player` around a run, and there
is no logged-in player to receive it either. A spec asserting *nothing was
raised* would pass against a **reporting** version too, which makes it vacuous.

The four views are arrays, and reading past the end of one is a legitimate thing
for a program to do: it answers `nil`, which `place()` reads as *no block named*
and therefore as *use the default*. So the unknown-block warning must **not**
fire for it, while still firing for a genuine misspelling.

1. Run this program:

   ```lua
   local x = dark_hues[99]
   place(x)
   ```

   **Pass:** the block is built with your default block, and **no chat line
   appears**.
2. In the **same session**, run a second program:

   ```lua
   place(colors.gray)
   ```

   **Pass:** the misspelling is reported once, naming the wrong name. That is
   what tells a pass apart from a mere non-crash — one of the two must report and
   the other must not.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — both cases, and this is the one
that mattered most. `dark_hues[99]` built the default block with **no chat
line**, and `colors.gray` in the same session **was** reported once by name.
**So the asymmetry is observed rather than reasoned**: `test-agent` could not
turn it into a spec, because the load-time binding shuts the interception off
and a *nothing was raised* assertion would pass against a reporting version too.
This is the only kind of evidence the behaviour can have, and it is in.

### F14-3 · A gradient built through a view actually lands [F14]

Written 2026-09-07 at `e3e2178`, out of `F14`'s coverage work. The specs prove
`ramp.of`'s mapping and prove each view holds the names it should; what they
cannot see is a real build in a world, in a material the view was not written
for. That indexing — one axis the view, the other the category — is what `F14`
exists for.

1. Run this program:

   ```lua
   for i = 1, 10 do place(glass[ramp.of(dark_hues, i, 1, 10)]) up() end
   ```

   **Pass:** ten glass blocks in a column, `dark_pink` at the bottom through to
   `dark_violet` at the top, **all see-through**.
2. **Look at the colours, not the count.** **Pass:** the ten differ from each
   other, and they differ from the same loop over `hues`, which gives the plain
   shades. Ten identical blocks, or ten plain ones, is a fail even though
   nothing crashed.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — ten see-through glass blocks,
`dark_pink` at the bottom to `dark_violet` at the top, visibly different from
each other and from the same loop over `hues`. **A view crossed with a category
lands in a world**, which is what `F14` exists for.

---

Sources: `AUDIT.md` (per-finding reasoning), `ROADMAP.md` (the `F` entries and
*what ships broken*). When a check moves, update the finding entry too — that is
the record, this is the procedure.
