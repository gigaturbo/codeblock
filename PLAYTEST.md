# Playtest — CodeBlock

The manual checks the automated suite cannot reach. The nine specs run **at mod
load**, before a map, a player or a user directory exists, so the editor, drone
placement, the filesystem and every write into the world have no spec coverage
and cannot have.

This file has its own `export-ignore` line, so it never ships to a player.

## How to record a result

```
Result: pass — <commit> · engine <version> · <YYYY-MM-DD> — <one line of detail>
```

`fail` and `partial` take the same shape. **Always keep the commit and the
date**: a pass recorded three phases ago is not evidence about today's code. A
`fail` is not a finding — report it and let `AUDIT.md` allocate or widen an id.
Reasoning lives in `AUDIT.md` under the bracketed id, or `ROADMAP.md` for an `F`.

## Where it stands

**52 checks, 51 with a result**, and `H8` the only one carrying a partial. The
one outstanding is **`H10`, new with `B47`'s fix** — the only thing that can say
whether a dropped panel click is still noticeable, since the fix halves that
window rather than removing it. `F9` and `R1` each carry two results.

- **Group `H` (HUD and panel): re-run 2026-09-02 at `8f5bb2e`, eight pass and one
  partial.** `F8`'s display work is proven in a world. It produced `B47` — panel
  buttons sometimes needing a second click — and three wanted display changes,
  which are `F9`.
- **`F9` passed 2026-09-02, in both languages**, which closes the three display
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
- **`H10` is new and unrun**, for `B47`'s fix. Its case 2 is a deliberate
  control: on an idle panel the formspec string never changes, so the engine
  regenerates nothing and no click can be lost — a drop there would mean the
  mechanism `AUDIT.md` records is wrong.

---

## Editor

E1–E16. Runs of 2026-08-27 and 2026-08-28, engine 5.17.0, in the author's test
game. They produced `B33` (widened to three losing paths), `B34`, `B35`, `B36`
and `B37`.

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

Result: pass — `afbe504` · engine 5.17.0 · 2026-08-28 — the day it shipped.
**`F7` confirmed.**

---

## Drone placement and the setter tool

D1–D6. Runs of 2026-08-27 and 2026-08-28. They produced `B38`, `B39`, `B41` and
`B44` — all four in code nobody had exercised in a running world.

### D1 · Place a drone and run a program [B10, A11]

Point at loaded ground with the setter, place, pick a file, watch it finish.

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
2. The re-entrancy window `B29` is about is reached with the **setter**, which
   removes a drone mid-run and is allowed to. Remove a running drone with it and
   place a new one in the same second. **Pass:** the replacement survives and runs
   to its own end, and the removed run announces its statistics **once** —
   `Drone.on_remove` calls `Drone.finish(drone, 'completed')` on purpose. What
   must **not** appear is *"The drone has disappeared, program stopped"*.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both parts. **`B29`'s
serial guard is confirmed in a running world**; this was the one path to it.

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

**New 2026-09-02, never run.** `B47`'s fix is a longer refresh beat — `PERIOD`
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

Result: —

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
echo 'place(blocks.stone)' > src.lua && luac5.1 -o bytecode.lua src.lua
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

`/codegenerate`, set yourself to **codelevel 2**, run all fourteen.

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

W1–W3, played 2026-08-28. The group **settled questions rather than finding
defects**: `W2` answered `A4`, the oldest thing on the audit's *not verified
anywhere* list.

### W1 · `place()` far from spawn [A4, S5, B25]

Fly a long way out, place a drone, and run a program that walks and places one
node at a time across several mapblocks **and back over ground it already
visited**.

**Pass:** no holes.

**Run it at codelevel 1 or 2, not 3 or 4.** The pass condition is only *no holes*,
but what this check is *for* is the per-resume memo reset, and the codelevel
decides how often that runs: `end_command` yields after **every** command while
`pace_ms > 0`, and only when the step budget is spent when pace is 0. A
2000-command program clears and rebuilds the memo 2000 times at level 1 and a
handful of times at level 4.

Past about 2000 nodes in one direction the program stops with *"The drone cannot
leave the world"*. **That is the world-edge guard working, not a limit being
hit** — the number depends on the world's own `mapgen_limit`.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — no
holes, at a codelevel above 2. Two 1000-node lines, the second offset so the
return leg re-crosses ~63 mapblocks the outward leg had written into. **A level 1
or 2 re-run is still worth one session**, the memo reset being barely exercised at
that pace.

Earlier: pass — `43e95a8` · engine not recorded · 2026-08-25 — where `S5`'s
measurements come from: **16.3 kB resident per mapblock** over a 400-block sweep,
and about **1700 loads a second** served.

### W2 · A node written into never-generated ground [A4]

Place a node in an area that has never been generated, leave, come back so the
area generates, and look.

**Pass:** the node is still there. This was **unknown either way**.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 —
**`A4`'s open question is answered**: mapgen does not overwrite it. `load_area`
plus `set_node` does not merely make the write land — the engine then treats the
block as generated and leaves it alone.

### W3 · A large bulk shape [A5, A15]

Run `cube(200, 200, 200)` **at codelevel 4** and watch the server.

**Pass:** the shape appears slab by slab and the server stays responsive. It must
not freeze — a 150-node cube stalled it for 0.44 s before shapes were sliced.

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

**The obvious command misleads.** `git archive HEAD | tar -t | grep tests` prints
`lib/examples/tests.lua` even when the archive is correct — a player-facing
example, the one that exercises every API command. Read as a bare pass/fail it
says *fail*. What answers the question is listing the top level:

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

### R2 · A real install with the test flag set [C16]

Extract the archive into a game's `mods/` as a player would, set
`codeblock_run_tests = true`, and start.

**Pass:** the mod loads normally and logs *"codeblock_run_tests is set, but this
build ships no tests/ directory"*. **Fail is the mod refusing to load** — nine
bare `dofile`s of files the archive does not contain.

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

**New 2026-08-30, never run.** The singleplayer default moved from 4 to 3, and
`register_on_newplayer` is the only place it is written — so **a world with any
history in it proves nothing here**. Create a fresh world each time.

1. **Singleplayer, fresh world.** `/codelevel` with no argument. **Pass: 3.**
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

### F1 · The Settings panel [F1]

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

### F1 · The preference survives a relog [F1]

Pick a block, close with **ESC**, disconnect, rejoin, run a program whose
`place()` names no block.

**Pass:** the chosen block is what gets built. The meta write happens the moment a
row is selected, not on form close — precisely so the preference does not depend
on the editor-state save path.

Then change the preference mid-run: **pass** is that the running program keeps
building the block it started with, the preference being read once per run.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F3 · `sleep(seconds)` in a running world [F3]

Run a program that places a node, calls `sleep(1)`, and repeats — at codelevel 3
or 4, where `pace_ms` is 0 and the wait is the only thing pacing it. Then run one
asking `sleep(1e9)`.

**Pass:** the drone visibly builds one node a second; the server stays responsive
and any other drone keeps its own rate while this one waits; and the unbounded ask
ends the program with the same timeout message a program that never finishes gets,
rather than parking the drone for ever.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F9 · The words on the panel and the HUD [F9, B46]

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

---

Sources: `AUDIT.md` (per-finding reasoning), `ROADMAP.md` (the `F` entries and
*what ships broken*). When a check moves, update the finding entry too — that is
the record, this is the procedure.
