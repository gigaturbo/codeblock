# Playtest — CodeBlock

The manual checks the automated suite cannot reach. The nine specs run **at mod
load**, before a map, a player or a user directory exists, so the editor, drone
placement, the filesystem and every write into the world have no spec coverage at
all and cannot have. Six findings closed in Phase 7 rest on reading the code
only. This file is where that gap is written down, so it can be reviewed rather
than rediscovered from prose scattered across `ROADMAP.md` and `AUDIT.md`.

`PLAYTEST.md` has its own `export-ignore` line in `.gitattributes`, so this file
never ships to a player.

## How to record a result

Each check carries a **Result** line. Leave it as `unchecked` until someone
actually does it in a running world, then replace it with:

```
Result: pass — <commit> · engine <version> · <YYYY-MM-DD> — <one line of detail>
```

`fail` and `partial` take the same shape. **Always keep the commit and the
date**: a pass recorded three phases ago is not evidence about today's code, and
the point of the line is that a stale pass reads as stale rather than as current.
A `fail` is not a finding — report it and let `AUDIT.md` allocate or widen an id.

Reference the finding or feature id in brackets after the title; the reasoning is
in `AUDIT.md` under that id, or in `ROADMAP.md` for an `F` id.

---

## Editor

**Run of 2026-08-27.** E1–E7 were all run in one session, against the tree at
`3293a2c` **plus uncommitted F1 changes** — the editor was not stock `3293a2c`;
`lib/formspecs.lua` already carried the Settings panel. Engine Luanti 5.17.0, in
the author's own test game `codeblock_test` (flat terrain, a simplified codecube,
the mod linked in by junction). Five passes, one partial (E2), one fail (E5).
What they turned up: **B34** newly filed, **B33 widened to three losing paths**.

**Second run, 2026-08-27, after the fixes.** Against the code that became
`500dd85` — run before the commit, identical content — engine Luanti 5.17.0. The player confirmed the two
symptoms they had reported are gone: the tab selection coming back wrong after
**Load and close** (E5, now a pass) and the typed text disappearing on a help
panel button (E11, new). **E8, E9, E10 and E12 are new and unrun** — the
disconnect and shutdown halves of B33 and the checkbox defaults are the paths
still carrying no evidence.

**Third run, 2026-08-27, at `dee0bc7`**, engine Luanti 5.17.0 — five checks: **E8**
pass, **E9** pass, **E10** fail, **E12** fail, **E13** now a full pass. (`90cfb70`,
F3's `sleep`, landed after this run and touches nothing the editor does.) **E9 is
the pass that mattered**: it was the one path in B33's fix resting on an assumption
about the engine rather than on read code — that player meta written from
`register_on_shutdown` is still saved — and it is now observed. All three of B33's
losing paths are confirmed fixed in a running world.

The two fails produced **B36** (the new-player initialiser wrote a `0` into the
preference keys, so the ticked default was unreachable) and, from diagnosing the
second of them, **B37** (three scroll branches shadowing four others, including
the one that saves the tabs on ESC). Both are fixed at `1f7cd97`; **E12 is
recorded as not reproduced rather than as fixed**, and both checks say what a
re-run needs. **E14** and **E15** are new with `1f7cd97` and cover the two paths
B37 had made dead — closing with ESC, and Enter in *New file*.

**Fourth run, 2026-08-27, at `f274245`**, engine Luanti 5.17.0 — **E14** pass,
**E15** pass, **E10** pass with a fresh player name, **E12** fail again. B36 and
B37 are both confirmed fixed in a running world, which closes the editor section
except for E12. **E12 has now failed three times and been traced twice without
finding a write**, so the check has been rewritten to ask for the file's size or
timestamp read from outside the game — the one observation none of the three runs
made. No id is allocated for it until there is that evidence.

The same run took the **Drone** and **Filesystem** sections for the first time and
found two real defects there, **B38** and **B39**; both are fixed at the commit
this paragraph was added in.

**Fifth run, 2026-08-27, at `246bb37`**, engine Luanti 5.17.0 — **E12** at last,
and it is a **pass**. The player ran it as written and reported the sequence
whole: edit A, switch to B, switch back to A — the edit is still in the text area
— then ESC, reopen, and *the edit is gone*. That last half is the observation the
three earlier runs never made, and it settles claim 1 by itself: had the tab
switch written, reopening would show the edit. Nothing was written. No finding is
allocated, and the editor section is now complete.

What the three fails were is claim 2 read as a save — the edit surviving a switch
**in memory**. The player's own reading: *"not really a bug but something not
expected in the user experience"*. Agreed and decided (2026-08-27): the retention
stays, because discarding a player's typing on a tab switch is the loss B35 was
filed for, and what is actually missing is any sign that a tab is unsaved. That
is `F7`.

### E1 · Open, save and close a program [A9, B13, B17]

Open the editor, open a file, type, save, close with the Save button, reopen.

**Pass:** the edit is on disk and comes back; no `set_string` error in the log
(B13 passed nil, B17 passed a number).

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — the edit
round-tripped, no `set_string` error in the log.

### E2 · Create and remove a file [B14, A9]

Create a new file from the chooser, then remove it. **Then try to remove a file
that was never opened in this session** — and note that on current code you
cannot: the four file buttons (Save, Load and close, Remove file, Close file) are
drawn only inside `if meta.active ~= 0 then`, so a file must be opened before it
can be removed. That is **B34**.

**Pass, first half:** create and remove of an open file both succeed.

**Second half — unreachable, and now permanently.** The author has decided B34
will not be fixed ("won't fix now, not really needed"), so the *Remove file*
button stays behind an open file and this half of the check can never be
performed from the editor. It was the point of this check:
B14 was `write_file` and `remove_file` indexing the per-player cache without
populating it, so the path that matters is the one where the cache is *cold*.
Opening the file first populates the cache, so every removal the editor can
perform is a warm-cache removal. **B14 therefore stays committed-but-unproven in
a running world** — this check cannot settle it. What would: fixing B34 and
re-running — which is now ruled out — or removing a file immediately after a
rejoin, the reconnect that empties the cache being B14's actual trigger. That
rejoin route is the only one left, and it is the one to use.

Result: partial — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 —
create and remove of an open file pass; removing a never-opened file is
impossible from the UI (B34 filed), so B14's cold-cache path was not exercised.

### E3 · Tabs [B33]

Open three files, switch between them, close the middle one, close the last one.

**Pass:** each tab shows its own content, the active tab is sensible after a
close, and closing the last file leaves an empty editor rather than an error.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — content
per tab, sane active tab after a close, empty editor after the last close.

### E4 · Tab state survives ESC [B33 — this is the check that settled it]

Open two files, leave both open, close the editor with **ESC** (not the Save
button, not a disconnect). Reopen the editor.

**Pass:** both files are open again and the active tab is restored.

`save_editor_state()` is called from exactly one branch, `fields.quit == 'true'`.
Whether ESC reaches that branch could not be established by reading. **It does.**
This check is settled and only wants re-running if that branch changes.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — ESC
reaches the `fields.quit == 'true'` branch; both tabs and the active tab were
restored. This is the evidence that B33 does not affect the ESC path.

### E5 · Tab state after **Load and close** [B33]

Open two files, leave both open, and leave the editor with the **Load and close**
button. Reopen the editor.

**Pass:** both files are open again and the active tab is the one you were on.
The `fields.load` branch now calls `save_editor_state()` before `exit()`, which
it did not: `exit()` goes through `core.close_formspec`, and a server-side close
sends no field table back, so the `fields.quit` branch never ran for this path.
The file's *contents* were always saved here; only the tab layout was lost.

**Scope narrowed after the fix.** This check originally carried all three exits
that skipped `save_editor_state()`; the disconnect and shutdown halves are now
**E8** and **E9**, because they are fixed in a different file and one of them
cannot be re-run without restarting a server.

Result: pass — `500dd85` content, run pre-commit · engine 5.17.0 ·
2026-08-27 — the player's reported symptom is gone: tab A is still the active tab
after **Load and close** and a reopen.

Earlier: fail — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — all
three exits lost the tabs. Path 3 was the one nobody had listed, and it is what
widened B33 from one losing path to three rather than a new id being allocated.
Kept because it is the evidence the fix answers.

### E6 · The two checkboxes [B5]

Toggle **Load program on exit** (`loe`) and **Save on tab switch** (`sos`), close
the editor, reopen, and check each does what it says.

**Pass:** both persist and both take effect. With `sos` **off**, editing a file
and switching tab must discard the edit — that is the half B5 was destroying
work through, because `0` is truthy in Lua and the box was stuck on.

Note: a third box, `Save on exit` (`soe`), is commented out in the formspec while
its meta key is still written on close. **It is deliberately dead — do not
restore it.** The author decided against resurrecting it after this run: what is
wanted instead is a warning when the editor is closed with unsaved changes. That
intention is in `TODO.md`; it is not a finding and not part of F1.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — both
boxes persist and both take effect, including `sos` off discarding the edit on a
tab switch.

### E7 · The four help panels [A2, B22]

Open Blocks (`cubes`), Plants (`plants`), Wools (`wools`) and API (`commands`) in
turn. Scroll each of the first three to the bottom.

**Pass:** every panel draws, every item shows a texture, each of the three block
panels keeps its own scroll position independently, and the API panel's hypertext
renders — it is generated from `lib/api.lua` by `api.to_hypertext`, the same
source as `doc/api.md`.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — all four
panels drew, textures present, the three scroll positions independent, the
hypertext rendered. Five panels since F1; the fifth has its own check below.

### E8 · Tab state survives a disconnect [B33]

Open two files, leave both open, and **disconnect** — quit to menu, or pull the
connection. Rejoin and open the editor.

**Pass:** both files are open again and the active tab is restored.
`register_on_leaveplayer` in `lib/forms.lua` now sends the handler the engine's
own `{quit = 'true'}` before forgetting the session, so the editor writes what it
holds. Load order is load-bearing here: `forms.lua`'s leave callback must run
before `register.lua`'s, which drops the player's file list the editor's quit path
reads.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27 — both files came back and
the active tab was restored. Note what this path does *not* exercise: the engine
callback hands the handler a `{quit = 'true'}` the mod builds itself, with no
scrollbar field in it, so it was never exposed to B37 — which is why it passed at
`dee0bc7` while closing the same editor with ESC did not (E14).

### E9 · Tab state survives a server shutdown [B33 — now observed]

Open two files with the editor open, shut the server down cleanly, restart, and
open the editor.

**Pass:** both files are open again and the active tab is restored. `register_on_shutdown`
reaches every open session through the same `close_session`. That **player meta
written from `on_shutdown` is still saved** was an assumption about the engine's
shutdown order rather than read code; this check is what settled it. If it ever
fails, the finding is the write being dropped, not the callback not firing — check
the log for the handler running at all before concluding.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27 — **the significant pass.**
The meta write from `register_on_shutdown` survives, observed rather than inferred,
so all three of B33's losing paths are now confirmed fixed in a running world. Same
caveat as E8: the shutdown path builds its own field table and so was not exposed
to B37.

### E10 · The checkboxes for a player who has never set them [B36]

Join as a player who has **never existed in this world before** — a genuinely new
name, or a fresh world — and open the editor. Then untick one, close the editor,
and reopen it.

**Pass:** both boxes start **ticked**; the one you unticked is still unticked when
you come back. Both keys are read with `get_string`, where an absent key is `""`
and a stored `0` reads back as `'0'` — `get_int` returned 0 for both cases and
could not tell them apart. `soe` uses the same string read but keeps its `false`
default and its checkbox stays commented out (E6).

**The fresh name is not optional.** Any player who joined before `1f7cd97` still
carries the `0` that `register_on_newplayer` used to write, and reads back as a
deliberate untick — correctly. Re-running this as an existing player will look
like a failure and is not one. If the boxes start unticked for a name that has
never joined, that is B36 again.

Result: fail — `dee0bc7` · engine 5.17.0 · 2026-08-27 — "both boxes are unchecked
with new player join, their state persists upon disconnect/reconnect". The first
half is **B36**: `register_on_newplayer` wrote `set_int(..., 0)` into all three
preference keys the moment a player was created, so the `get_string` read that
exists to tell "never chosen" from "unticked" (B5) saw a stored `0` for every
player who had ever existed, and the ticked default was unreachable. The second
half is the *other* half of this check passing — a stored `0` being honoured
across a relog. Fixed at `1f7cd97`: the three keys are no longer written at birth
and the reader owns the default. **Re-run against `1f7cd97` with a fresh player
name.**

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27 — re-run with a fresh
player name. Both boxes start ticked and an untick survives the relog, which is
both halves of the check. B36 confirmed fixed in world.

### E11 · Typing survives every button that is not Save [B35]

Open a file, type something, and press each of **Blocks**, **Plants**, **Wools**,
**API** and **Settings** in turn without saving.

**Pass:** the text is still in the text area after every one. Every redraw
re-renders the text area from `meta.contents[meta.active]`, and only three of
eleven branches used to capture `fields.content` first — so a help panel, a
checkbox, the F1 block picker or `+` discarded everything typed since the last
save. The capture is now one guarded read before the branch chain.

Result: pass — `500dd85` content, run pre-commit · engine 5.17.0 ·
2026-08-27 — the player's reported symptom is gone: the text survived the panel
buttons.

### E12 · **Save on tab switch** off really does not write to disk [B35]

Untick **Save on tab switch**. Edit tab A without saving, switch to tab B, switch
back to A — and then leave the editor **with ESC only**. Reopen it and reopen A.

**Pass**, two claims, and they are not equally strong:

1. **The strong one, and what this check is for:** the edit is **absent** from
   disk. Nothing on the tab-switch path may write. `write_file` is the only route
   to disk and `lib/formspecs.lua` calls it from exactly three places —
   `save_active`, `create_file`, `copy_active` — and the tab-switch branch's call
   is gated on `meta.sos`.
2. **The weak one, and the one that reads as a failure:** the edit to A is still
   in the text area when you switch back, whether or not it reached disk. The
   option gates only `save_active()`; it used to gate the in-memory capture as
   well, so switching tabs with it off lost the edit outright. **That retention
   is intended and stays** — an unsaved tab holds its edit, as any tabbed editor
   does. Three runs of this check called it a save, so read it as what it is: a
   dirty buffer with no sign that it is dirty, which is `F7`'s job.

**Leave by ESC and nothing else.** *Load and close* and *Save* both call
`save_active()` unconditionally and by design, so the file reaches disk however
the box is set — leaving by either and then finding the edit on disk is correct
behaviour, not a failure of this check. And **before `1f7cd97` this check could
not be run correctly at all**: ESC never reached its own branch (B37), so the tab
list was not written either.

**Look at the file itself, not at the editor.** This is the third run of this
check and reopening the editor has not settled it, so read the file from outside
the game:

```
<worldpath>/codeblock_files/<playername>/<file>.lua
```

Note its size or modification time before the edit and again after leaving. That
is the only observation that distinguishes the two claims above, and it is what
the previous two runs were missing. Type something unmistakable — `-- E12` on the
first line — so the answer does not depend on remembering what was there.

Result: fail — `dee0bc7` · engine 5.17.0 · 2026-08-27 — "code is **saved** when
box is cheched OR unchecked". **Not reproduced by reading, and not claimed fixed.**
The three `write_file` call sites and the `meta.sos` gate were re-read at
`1f7cd97`; with the box unticked a tab switch cannot write. Two explanations fit
what was seen, and a re-run should choose between them: either the edit was seen
surviving *in memory* — which the check's old wording ("whether or not it reached
disk") invited being called a save — or the editor was left by *Load and close* or
*Save*, both of which write by design. B37, fixed in the same commit, does not
explain it either: its effect on this path was that ESC failed to save the **tab
list**, not that anything extra was written. The check is reworded above to
separate the two claims. **Re-run against `1f7cd97`, leaving by ESC.**

Result: fail — `f274245` · engine 5.17.0 · 2026-08-27 — "fails, saved on both
cases". **Still not reproduced by reading, and no finding id is allocated for
it.** The whole write path was traced again at `f274245`, one layer wider than
last time: `core.safe_file_write` is called from exactly one place in the mod
(`lib/filesystem.lua`), `write_file` is called from four (`save_active`,
`create_file`, `copy_active`, `generate_examples`), and none of them is on the
ESC path — the `quit` branch calls `load_active` and `save_editor_state` and
neither writes a file. `Drone.set_file` does not write. Reopening the editor does
read the disk: `show` calls `read_file(..., true)`, which rebuilds the listing
and so drops every cached content. `forms.on_receive_fields` drops the session on
`quit`, so a reopened editor cannot be holding the old `meta.contents` either.

So either the write is happening somewhere none of that covers, or what is being
observed is not a write. The check above now asks for the one observation that
tells those apart — the file's size or timestamp, read outside the game. Reading
has now failed twice to settle this; the next step is evidence, not a third
reading.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — edit A, switch to B,
switch back to A (the edit is there), ESC, reopen: **the edit is gone**. Reopening
is the read this check wanted and it is decisive — a tab switch that had written
would show the edit back. The three earlier fails were claim 2, the in-memory
retention, reported as a save. Retention kept by decision; `F7` makes it visible.

### E13 · **Create a copy** [F2]

Open a file in the editor, type something without saving, and click **Create a
copy** (bottom-left, below the file list — it appears only with a file open).
Then copy the copy, several times. Then reopen the original.

**Pass**, six parts:

1. The copy is named `<name>_1.lua`, and its contents are **what was on screen**,
   including the unsaved edit.
2. It opens as the **active tab**.
3. Copying the copy gives `<name>_2.lua`, `<name>_3.lua` — it increments; it does
   not nest suffixes and does not lose a character each round.
4. The **original is unchanged on disk**: nothing is saved to it, so reopening it
   shows the last version you saved, not what was on screen when you copied.
5. Past ten copies the list is ordered `_2` … `_9`, `_10`, `_11` — not
   alphabetically.
6. The button's **right edge sits flush** with the file list above it and with
   `+` below it. This is the part with a history: a legacy-coordinate `button` is
   0.2 units narrower than its `W` says, so the widths are `3.2` and `0.95`
   against a 3-wide list. See `F1`'s legacy-coordinate notes in `ROADMAP.md`.

Not spec-reachable at all: `forms_spec` stubs `core.show_formspec` and stops at
the session layer, never reaching `formspecs.lua`'s `on_close`.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27 — all six parts, the flush
right edge included; that was the outstanding one, corrected after the geometry
was wrong twice and now looked at in-world. Supersedes the earlier *partial*,
which had parts 3 and 5 from F2's build only.

### E14 · Closing the editor with **ESC** saves the open tabs [B37, B33]

Open two files, switch to one of them, leave the help panel on **Blocks** — the
panel the editor opens on — and close with **ESC** or the window **X**. Reopen the
editor.

**Pass:** both files are open again and the active tab is the one you were on. The
`quit` branch is the only place `save_editor_state()` runs on this path, and it is
also where *Load program on exit* is honoured, so with that box ticked the drone
should have been handed the active file as well.

**This is the path that had no check, which is how B37 hid.** A scrollbar reports
its position on *every* submit, so the three help-panel scroll branches — sitting
above `quit` in one `elseif` chain — swallowed the quit event whenever Blocks,
Plants or Wools was showing. E8 and E9 passed at the same commit because leave and
shutdown build their own field table with no scrollbar in it: the two paths with
checks were the two that worked. Run this with each of the five panels open, not
just Blocks; **Settings** and **API** draw no scrollbar and were never affected.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27 — B37 confirmed fixed in
world on the exit that had no check.

### E15 · **Enter** in the New file field creates the file [B37]

With the help panel on **Blocks**, type a name into the **New file** field and
press **Enter** rather than clicking `+`.

**Pass:** the file is created and opens as the active tab, exactly as `+` does.
The branch is keyed on `fields.key_enter_field == 'newfile'`, which the engine
sets to the field's name on `EGET_EDITBOX_ENTER`; `field_close_on_enter[newfile;false]`
is what keeps the form open so the handler sees it. Before `1f7cd97` this branch
was both shadowed by the panel scrollbars and keyed on the field merely being
non-empty, so it fired on unclaimed events instead of on Enter. `+` worked
throughout — its branch sits above the scrollbars.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### E16 · The unsaved marker on a tab [F7]

Open a file. Type into it, then press anything that is **not Save** — a help
panel button, a checkbox, `+`, the block picker, another tab. Look at the tab
label. Then press **Save** and look again.

Then, with an unsaved tab open, leave with **ESC**, reopen the editor, and look
at the file: the edit is gone and the tab is unmarked, which is correct and is
the thing the marker exists to warn about.

**Pass:** the tab reads `thing.lua*` while the buffer differs from the file, and
`thing.lua` once it has been written. It clears on **Save**, on a tab switch with
*Save on tab switch* ticked, and on **Load and close**. It does *not* clear on a
tab switch with that option unticked, because nothing was written.

Three things worth checking beyond that first pass:

- **The mark is legible on a tab.** A `tabheader` sizes itself to its labels, so
  a marked tab is one character wider than an unmarked one and the row shifts as
  you type. That is the cost of the design and this is where it is seen.
- **The file is still called `thing.lua`.** Save a marked tab and look at the
  file list on the left: a file named `thing.lua*` means the marker reached
  `meta.tabs`, which is what `integration_spec` pins and what would corrupt the
  player's directory. Nothing should ever create one.
- **Create a copy leaves the source marked.** With an unsaved edit, press
  *Create a copy*: the copy opens **unmarked**, because what was written to it is
  what is in the buffer, and the source tab **stays marked**, because its own
  file was deliberately not saved.

**A known and accepted wrongness, not a fail:** type a character and undo it, and
the tab stays marked until the next save. The flag records *the buffer changed*,
not *the buffer differs from disk* — a diff would need a pristine copy of every
open file, which was rejected for a cosmetic mark. Report it only if the mark
appears without any typing at all, which would mean it is being set from the
field arriving rather than from the text differing.

Result: unchecked — `F7` shipped 2026-08-28 at gates green; nothing in a world
has seen it. `integration_spec` pins the drawn label and that `meta.tabs` is
undecorated, so what is unproven here is what a player can see and the flag's
transitions across tab and file operations.

Result: pass — `afbe504` · engine 5.17.0 · 2026-08-28 — the marker works in a
running world, the day it shipped. **`F7` is confirmed**, and with it the flag's
transitions across tab and file operations, which no spec reaches: only the drawn
label and the undecorated `meta.tabs` are pinned by `integration_spec`.

---

## Drone placement and the setter tool

**First run, 2026-08-27, at `f274245`**, engine Luanti 5.17.0 — one pass, two
fails, one partial, and the partial turned out to be this document being wrong
rather than the code. Both fails were in code nobody had exercised in a running
world since it was written: **B38** (aiming at nothing is silently ignored,
because the engine calls a different callback than `on_place`) and **B39** (the
first join after installing the mod wipes the inventory).

**Second run, 2026-08-27, at `246bb37`** — B38 and B39 both confirmed fixed in a
world, D3 complete at last, and the group is a pass but for D2's second case,
which was aimed at and missed. It also turned up a defect no check was looking
for: cancelling the file chooser leaves a drone that cannot run, now **B41** and
**D5**.

**Third and fourth runs, 2026-08-28** — `D5` passes on all three parts at
`326f739`+fixes, confirming `B41`, and turns up `B44` by doing the obvious next
thing to the drone it left on screen; `D6` then passes at `6fea453`, confirming
that one too. **The group's only outstanding item is `D2` case 2**, aimed at
twice and missed twice, and the recipe is the suspect rather than the code.

### D1 · Place a drone and run a program [B10, A11]

Point at loaded ground with the setter, place a drone, pick a file, watch it run
to completion.

**Pass:** one completion message, from `Drone.finish` and only there.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### D2 · Place a drone at nothing [B10, B38]

Two cases, and they are different paths. With the **poser**:

1. Aim into the sky or past what the client has loaded, so there is **no node**
   under the crosshair, and press place.
2. Aim at a node the client is showing but the **server** has unloaded — far out
   over ground you flew past. Harder to arrange, and mostly reachable by flying
   away and coming back before the area is re-emerged.

**Pass:** both are refused in chat, (1) with *"Please target a node"* and (2) with
*"Cannot place the drone there, move closer"*, and no record is created. Case 2 is
the `add_entity`-returns-nil path; `Drone.new` must create no record, because a
record with no object is a drone that silently never runs (B10).

Case 1 is what B38 was: the engine calls `on_secondary_use` and **not** `on_place`
when there is no node under the crosshair, and the poser's was an empty function.
So the one gesture a player makes to find the tool's reach was the one that
answered nothing, and B10's message could only ever be seen by arranging case 2.
It is now routed into the same `Drone.on_place` call with no position, so there is
one refusal and not two — and that check was moved above the busy check, because
with no node it is the aim that failed and not the drone.

Result: fail — `f274245` · engine 5.17.0 · 2026-08-27 — "no message when clicking
far away, I think I never implemented this". Correct: case 1 had no
implementation at all. **B38**, fixed at the commit this line was added in.
Re-run both cases.

Result: partial — `246bb37` · engine 5.17.0 · 2026-08-27 — "hard to tell, the sky
part works". **Case 1 passes and B38 is confirmed fixed in a world.** Case 2 was
attempted with view distance set to 30 and was *not* reached: the drone placed
and then took a moment to appear, which is the client drawing an entity in a
mapblock it has not received yet — the server placed it, so this is the success
path, not `add_entity` returning nil.

**A recipe for case 2, since aiming far away is not it.** Lowering the *client's*
view distance shows the client less, and this case needs the client to show
*more* than the server holds. Set `server_unload_unused_data_timeout = 5` in
`minetest.conf` and keep `active_block_range` small, stand still while an area you
already have the mesh for falls outside it, wait past the timeout, and place at a
node you can still see. **Pass:** *"Cannot place the drone there, move closer"*
and no record created. This is the only route to B10's message and so to the
`add_entity`-returns-nil path; case 1 gives *"Please target a node"* and is a
different branch.

Result: partial — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 ·
2026-08-28 — case 2 attempted again with the recipe above and **still not
reached**: "hard to produce case 2, looks not unloaded". The area stayed resident,
so the placement kept landing on the success path. Case 1 remains a pass.

**Case 2 is now two attempts old, and the recipe is the suspect rather than the
tester.** `server_unload_unused_data_timeout` bounds when the engine *may* drop an
idle mapblock, not when it does, and a block stays resident while anything keeps
it active — a nearby player, an active object, the drone already standing there.
Before spending a third session on it, read what actually holds a block: the next
attempt wants a way to *observe* that the server has let go, rather than waiting a
timeout and hoping. Until then `B10`'s refusal stays committed and unproven, which
is where it has been since Phase 7, and this check is the only route to it.

### D3 · Replace a drone under the same name [B29, B30]

Two things, and the first is not what this check used to say.

1. Place a drone, run a program, and try to place a second drone **before** the
   first has finished. **Pass:** it is refused with *"Drone is busy, please
   wait!"* — `Drone.on_place` returns early while `drone.cor` is non-nil, so a
   run cannot be yanked out from under itself by a stray click. Then place again
   after it finishes: that works.
2. The re-entrancy window B29 and B30 are actually about is reached with the
   **setter**, which removes a drone mid-run and is allowed to. Remove a running
   drone with the setter and immediately place a new one in the same second.
   **Pass:** the replacement survives and runs to its own end, and the removed
   run announces its statistics **once** — `Drone.on_remove` calls
   `Drone.finish(drone, 'completed')` on purpose, so a stats line there is the
   design and not a fault. What must **not** appear is *"The drone has
   disappeared, program stopped"*, and the replacement must not die. That is the
   whole of B29: `ObjectRef:remove()` takes effect at the end of the step, so
   `on_deactivate` fires *after* the replacement is installed under the same
   name, and `on_lost` would then finish and remove the new drone. The serial is
   what protects it, not the clear-before-remove ordering.

Result: partial — `f274245` · engine 5.17.0 · 2026-08-27 — "when placing during
run it says '... wait busy...', after a run it works". That is part 1 passing.
**The check was wrong, not the code**: it asked for a replacement mid-run, which
`on_place` refuses on purpose, and so pointed at a path that cannot reach B29's
window at all. No finding id — nothing in committed code is defective here.
Part 2 is unchecked and is the one that tests the serial guard.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both parts. Part 1:
*"drone busy, wait"* during a run, and placing works once it ends. Part 2:
removing a running drone with the setter and placing another in the same second
worked, "just stating the stats of the program" — one statistics line, no
*"disappeared"* message, and the replacement ran. **B29's serial guard is now
confirmed in a running world**; this was the one path to it and the last thing
the guard rested on reading alone. The pass wording above was corrected in the
same edit: it demanded that *nothing* be announced for the removed run, which
`Drone.on_remove` announces by design. **Second wrong pass condition in this
check** — both were the record, not the code.

### D4 · Join with a full inventory [B16, B39]

Two cases, and the second is the one that was broken:

1. Join a world that already has the mod, carrying items in the hotbar and main
   inventory. **Pass:** nothing is removed. Every join used to wipe the inventory
   (B16).
2. Take a world **without** this mod, collect some items, quit, add the mod, and
   join again. **Pass:** the poser and setter are added and **nothing else is
   removed**.

Case 2 is B39. `set_tools` used to empty `main`, `craft`, `craftpreview` and
`craftresult` before adding the two tools, and B16 narrowed that to "only when a
tool is missing" — which is exactly and only the first join after an install, so
the wipe survived in the one case where the player has something to lose. It now
adds whichever tool is missing and clears nothing.

Also worth trying with a **completely full** main inventory: there is no room for
the tools, and the refusal is now said in chat rather than passed over, because a
player with no drone tools and no explanation has no way in.

Result: fail — `f274245` · engine 5.17.0 · 2026-08-27 — "I started a minetest
game, added items to inventory, quit then added codeblock mod and then inventory
was replaced with the 2 drone tools and the rest was empty". That is case 2
exactly. **B39**, fixed at the commit this line was added in.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both cases. Case 1 still
passes; case 2 now adds the two tools "after the hotbar item" and removes
nothing. **B39 confirmed fixed in a running world.**

The full-inventory question the run raised is already answered in the code, and
the answer is the one the player expected: `set_tools` adds nothing and says *"No
room for the drone tools, free a slot and rejoin"* in chat. It reads `add_item`'s
leftover, so a tool is added or it is not — never half. Worth doing once as a
check anyway, since it has never been run.

### D5 · Cancelling the file chooser [B41]

Place the poser with no previously loaded file — a fresh player, or one whose
`codeblock:last_file` names a file that is gone. The chooser opens. Press
**Cancel**. Then place again and press **ESC** instead.

Then a third time: place, and this time **choose a file** — the drone must stay.

**Pass:** neither Cancel nor ESC leaves a drone standing, and choosing a file
still leaves one that runs. Before `B41`'s fix both declining paths left a drone
nametagged `[<player>] ?.lua` that answered *"Not a valid file"* on every use.
Placing again was not refused, so it cost the player nothing but a puzzle.

The third part is the one to actually do: the fix removes the drone whenever the
chooser closes with no file set, so a bug in it would take away the drone the
player *did* choose for.

Result: fail — `246bb37` · engine 5.17.0 · 2026-08-27 — reported unprompted: "when
no program selected, try place, it opens the dialog to choose, click cancel: it
place a drone with ?.lua and refuses to run with invalid file". **B41**, fixed on
2026-08-28.

Result: pass — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 · 2026-08-28
— **all three parts**. Cancel leaves no drone, ESC leaves no drone, and choosing a
file still leaves one that runs. **B41 is confirmed fixed in a running world**,
and its ESC half is observed for the first time: that path was reasoned from the
field table from the day the finding was filed, through the fix, until this run.

That session turned up a defect no check was looking for, in the same class:
place a drone, open the editor, **remove the file the drone is holding**, close
the editor — the drone stands there naming a file that no longer exists, and is
only taken away when you run it. **B44**, and `D6` below.

### D6 · Removing the file a drone is holding [B44]

Place a drone and give it a file, so its nametag reads `[<player>] thing.lua`.
Open the editor, open that file, **Remove file**, and close the editor. Look at
the drone. Then run it.

**Pass:** removing the file does not leave a drone naming it — either the drone
goes with the file, or its nametag stops claiming a program it cannot run. Today
neither happens: `remove_file` deletes the file and refreshes the player's cache
and knows nothing about drones, so `drone.file` still holds the name. The drone
is taken away on the *run*, where `get_safe_coroutine` fails to read it — so the
error and the disappearance both arrive one gesture later than the cause.

Also check the other order, which is the one that has a guard already: remove the
file, then place a **new** drone. That is fine — `Drone.on_place` tests
`codeblock:last_file` against the player's file list before using it, so a stale
last-file is ignored and the chooser opens instead.

Result: fail — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 · 2026-08-28
— found while running `D5`: "if I pose the drone, open editor, remove the file,
then close editor, drone is now here with a file that does not exists (drone
removed on run)". **B44**, fixed the same day; this line predates the fix and the
check is due a re-run. The drone is now removed when the file it holds is the one
deleted, so the pass to look for is the drone going *with* the file — and the
second half above, placing a new drone after a removal, must still open the
chooser rather than do nothing.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — the drone now goes with
the file, at the removal rather than one gesture later on the run. `B44` is
confirmed in a running world, and with `D5` the mod answers *a drone with no
usable file* the same way in both places it can happen.

---

## Filesystem and example generation

**First run, 2026-08-27, at `f274245`**, engine Luanti 5.17.0 — one pass, one
partial, one that could not be run because no procedure was written for it. The
partial is **C17**: the behaviour is right and the words are in the wrong
language. F-3 now has two recipes, which is what it was missing.

**Second run, 2026-08-27, at `246bb37`** — F-2 passes in French, and F-3's first
recipe found the worst defect this project has recorded against committed code:
the file is read **whole**, with no bound, and then sent to the client. **B40**,
open. `F-4` is new and is that finding's own check.

**Third run, 2026-08-28, against `246bb37` plus B40's uncommitted fix** — `F-4`
passes: the file that took the server to 14 GB is now refused. `F-3` case 1
passes too, at last, and only because of that fix: the size bound refuses a
168 MB file before the bytecode branch, so a small `luac5.1` chunk is what
reaches it. **This group is now green apart from `F-3` case 2**, the unreadable
file, which nothing has ever exercised.

**Fourth run, 2026-08-28, at `6fea453`** — `F-3` case 2 passes and **the group is
green**. It took three attempts: the first was blocked by a `cmd` recipe run in
PowerShell, the second passed on behaviour and failed on its message and opened
`S7`, and this one reads *"Impossible de lire le fichier ..."* — translated, with
the filename and no absolute path. What is not yet looked at is the server log,
where `S7` put the operating system's real reason.

### F-1 · `/codegenerate` on your own files [B8, B15]

Run `/codegenerate` as an unprivileged player, twice.

**Pass:** the examples appear the first time; the second run leaves existing
files alone rather than overwriting them, and needs no privilege for your own
files.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### F-2 · `/codegenerate <player>` [B8, C17]

Run it against another player's files, with and without the `codeblock`
privilege. **Run it once with the game in French**, since half of what this check
now covers is only visible there.

**Pass:** refused without the privilege; with it, the files land under the named
player, not the caller — the old argument pattern read a bare number as a player
name. And every line it prints is in the game's language: the refusal, the
`@1: @2 examples written, @3 already present` summary, the usage line, and the
failure line.

Result: partial — `f274245` · engine 5.17.0 · 2026-08-27 — "test pass but text
shown for the refusal without privilege is in EN and no FR if game in FR". The
privilege behaviour passes; the language is **C17**. That refusal's key was built
with `..` from two literals, so nothing reading the source for strings to
translate could see it and it was never in `locale/template.txt` at all. It was
one of twelve, and three of the twelve were worse — translated once, then
unhooked by a one-character edit to the key (a trailing space, a plural, a
capital). Fixed at the commit this line was added in, along with a
`scripts/gen_locale.lua --check` in CI so the template cannot drift again.
**Re-run in French.**

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — "everything in french".
**C17 confirmed fixed in a running world**, including the refusal whose key was
built with `..` and so had never been translatable at all.

### F-3 · A file that cannot be read [B7, B15]

`read_file` refuses in two ways and both name the file. The cheap one first:

1. **A precompiled chunk.** Put a file whose first byte is `0x1B` into
   `<worldpath>/codeblock_files/<playername>/` — `luac5.1 -o bytecode.lua
   any.lua` makes one, or any binary renamed to `.lua` — then open the editor and
   click it in the file list. `luac5.1` is in WSL on this machine, with the
   worlds under `/mnt/c/Users/lacba/AppData/Roaming/Minetest/worlds`:

   ```bash
   cd .../worlds/<world>/codeblock_files/<player>
   echo 'place(blocks.stone)' > src.lua && luac5.1 -o bytecode.lua src.lua
   rm src.lua && head -c 4 bytecode.lua | xxd   # 1b4c7561 - the 0x1B is the point
   ```

   It must be **small**, or `max_file_kb` refuses it first and this branch is
   never reached (B40). **Pass:** the chat says *"Compilation error in
   bytecode.lua: Binary bytecode prohibited"*, naming the file, and the editor
   carries on with the rest of the list. This is the branch that runs after
   `handle:close()`, so it is also where a leaked handle would show.
2. **A genuinely unreadable file**, which is the awkward one. On Windows, deny
   yourself read on one of your `.lua` files and reopen the editor. **In
   PowerShell**, which is the shell on this machine:

   ```powershell
   $f = "<worldpath>\codeblock_files\<playername>\test.lua"
   icacls $f /deny "$($env:USERNAME):(R)"     # now unreadable
   icacls $f /remove:d $env:USERNAME          # put it back
   ```

   **Write it that way and not the `cmd` way.** The obvious
   `icacls ... /deny "%USERNAME%":(R)` is a `cmd.exe` line and PowerShell
   mis-parses it twice over: `%USERNAME%` is not expanded, and the bare `(R)` is
   read as a **subexpression**, so PowerShell runs `R` — an alias for
   `Invoke-History` — and answers *"Most recent history not found"* without ever
   calling `icacls`. Hence `$($env:USERNAME):(R)` inside one quoted string, where
   the subexpression is explicit and the parentheses are literal. Verified as a
   round trip on 2026-08-28: deny, read refused with `UnauthorizedAccessException`,
   `/remove:d`, readable again.

   The deny must name **your own** account, because the server runs as you. Put
   the `/remove:d` back afterwards, or that file stays unreadable to everything.

   **Pass:** the message names `test.lua`, and no other file in the list is lost
   with it — a single bad file must not cost the player the session.

Do case 1 at least; case 2 opportunistically rather than blocking a release on it.

Result: unchecked — "not sure what to do to test" at `f274245`, which is a
procedure that was not written down rather than a defect. No finding id. The two
recipes above are new with the commit this line was added in.

Result: fail — `246bb37` · engine 5.17.0 · 2026-08-27 — case 1 run with a 168 MB
executable renamed `test.lua`. Selecting it in the list is fine; **opening it read
the whole file**, took Luanti to about 14 GB resident, froze the game on exit and
froze it again the next time the editor was opened. The text area then showed
`MZ` — the executable's first two bytes — because the file is not bytecode, so the
`0x1B` refusal never fires and 168 MB went into a formspec. A `.jpg` and a `.pdf`
renamed `.lua` were read as text and reached a compilation error, which is the
same path one step further on.

**That is B40, not a failure of the bytecode refusal.** The refusal was checked
*after* `handle:read('*a')`, so even the case that works paid the whole read
first. Case 1 with a genuine `luac5.1` chunk is still unrun and is the one this
check was written for; the size defect has its own check below. Case 2 unrun.

B40 was fixed on 2026-08-28: the read stops one byte past `max_file_kb`, so a
168 MB file is now refused by name and never reaches a string. **Re-running case 1
is the point** — a `luac5.1` chunk is small, so it goes past the size bound and
lands on the `0x1B` refusal this check was written for, which the size defect has
been standing in front of.

Result: pass — `246bb37` + B40's and B42's fixes, uncommitted · engine 5.17.0 ·
2026-08-28 — **case 1**, with a real `luac5.1` chunk. The bytecode refusal names
the file and the editor carries on with the rest of the list, so the branch after
`handle:close()` is exercised for the first time and **B7** is confirmed in a
running world. Case 2, the unreadable file, is still unrun.

Result: unchecked — 2026-08-28 — **case 2 attempted and blocked by the recipe,
not by the mod.** The `icacls` line as written was `cmd` syntax run in PowerShell,
which answered `R : Historique le plus récent introuvable.` — PowerShell had read
`(R)` as a subexpression and run the `r` alias for `Invoke-History` instead of
calling `icacls` at all. **The recipe above is corrected and the round trip is
verified**; the check itself is still to do. No finding: nothing in the mod was
reached.

Result: partial — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 ·
2026-08-28 — case 2, with the corrected recipe. **The behaviour passes**: the
file stays in the list, opening it reports the failure, and no other file is
lost with it, so `B7`'s half of this check is confirmed for the second branch.

**But the message is wrong twice over, and that is `S7`.** It read
*"&lt;full path&gt; ... permission denied"* — the server's **absolute filesystem
path**, in English with the game in any language. `read_file` returns `io.open`'s
own error string for this one branch (`return nil, err or unreadable`), where
every other refusal beside it uses `S()` and names the bare filename. So the
pass condition as written — *the message names `test.lua`* — is not met: it names
the whole path instead.

Case 2 stays **partial** until `S7` is fixed and the message names the file.

**`S7` was fixed the same day, so this is due a re-run.** What to look for now:
*"Cannot read file test.lua"* and nothing else — no path, and translated if the
game is in French. The real reason still exists, at `warning` level in the
server log with the filename beside it, which is where an operator should look
and where a path is not a disclosure. Check the log too: the point of the fix is
that the detail moved, not that it was thrown away.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — case 2 re-run after
`S7`. The message now reads *"Impossible de lire le fichier ..."* — the
translated form of `Cannot read file`, in the player's language, with the
filename and **no absolute path**. Both halves of the fix are visible in one
line: it is a translation key, so it came out in French, and it names the file
rather than the server's install layout. `F-3` is a full pass at last, both
cases, and `S7` and `B7` are each confirmed in a running world.

**The log half is not confirmed.** The fix moved `io.open`'s real reason to
`warning` level rather than discarding it, and this run reported only what the
player saw. Nothing suggests it is missing; it is simply unlooked-at. Whoever
next has an unreadable file to hand can settle it in one grep of `debug.txt`.

### F-4 · A file too large to open [B40]

Put a large file — tens of megabytes is enough, and it need not be valid Lua —
into `<worldpath>/codeblock_files/<playername>/` with a `.lua` name, then open the
editor and click it.

**Pass:** the file is refused by name and by size — *"File @1 is too large: over
128 kB"* at the default `codeblock_max_file_kb` — the way a bytecode file is, and
the editor carries on with the rest of the list. **Fail is anything that reads
it**: watch the server process's resident memory while clicking, not just the
screen.

**The bound is in `read_file`**, which is the only route from disk to a string, so
checking it there covers the editor, `Drone.set_file` and the sandbox at once. The
run path is a separate gesture and worth making: load the same file onto a drone
rather than opening it in the editor, and the refusal must name the size — before
this fix the sandbox threw away `read_file`'s message and said *"not found"* for
every refusal.

A third gesture, for the write half: with a file open, the editor must not be able
to save more than the ceiling either. From an unmodified client this cannot be
reached — the engine drops a formspec submission whose fields total 640 kB — so
what is actually being checked is that an ordinary save of an ordinary program
still works.

Result: fail — `246bb37` · engine 5.17.0 · 2026-08-27 — no bound existed yet; see
the F-3 result above for what was observed.

Result: pass — `246bb37` + B40's fix, uncommitted · engine 5.17.0 · 2026-08-28 —
the file that took the server to 14 GB is refused instead of read. Reported as a
pass by the author; which of the three gestures were made is not recorded, so the
run path — the same file loaded onto a drone — is worth a pass of its own.

---

## Writing to the world

### W1 · `place()` far from spawn [A4, S5, B25]

Fly a long way out, place a drone, and run a program that walks and places one
node at a time across several mapblocks and back over ground it already visited.

**Pass:** no holes. Every node is where the program said. `place_block` calls
`core.load_area` before `set_node`, memoised per mapblock — and the memo is
cleared before every yield, **per resume, not per run**, which is exactly what
this check exercises.

**Run it at codelevel 1 or 2, not 3 or 4.** The pass condition is only *no
holes*, but what this check is *for* is the per-resume memo reset, and the
codelevel decides how often that runs. `end_command` yields after **every**
command while `pace_ms > 0` — levels 1 and 2 — and only when the step budget is
spent when pace is 0. So a 2000-command program clears and rebuilds the memo
2000 times at level 1 and a handful of times at level 4. The high-codelevel run
proves the writes land; the low-codelevel run is the one that exercises the
thing the check exists for.

Result: pass — `43e95a8` · engine not recorded · 2026-08-25 — the mapblock memo,
the per-crossing footprint charge and the per-resume reset all behaved. Measured
over a 400-block sweep: **16.3 kB resident per mapblock**, and the engine served
about **1700 loads a second**. Recorded in the audit under S5 and quoted again as
the measurement that forced Phase 6's `map_memory_mb`. The engine version was not
written down at the time; the audit cites `lua_api.md` 5.17.0 for `load_area` not
triggering mapgen.

Result: pass — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 ·
2026-08-28 — **no holes**, at a codelevel above 2. Two 1000-node lines, the
second offset by `right(5)` and built in a different block after
`default_block(blocks.brick)`, so the return leg re-crosses about 63 mapblocks
the outward leg had already written into — which is the case the memo is for.
This clears the re-run the 2026-08-25 line was flagged for: it now postdates the
Phase 6 and Phase 7 rewrites of `lib/cost.lua`.

Both lines appearing **instantly is the program's speed, not a shortcut**: at
codelevels 3 and 4 `pace_ms` is 0, so the drone never waits between commands and
2000 of them fit in a few server steps. 2000 nodes is also nothing against
`max_nodes_written`, which is 1e7 at level 3. Nothing about the speed weakens
the *no holes* result — but per the note above, the memo reset is barely
exercised at that pace, so **a level 1 or 2 re-run is still worth one session**.

Past about 2000 nodes in one direction the program stops with *"The drone cannot
leave the world (@1 nodes)"*. **That is the world-edge guard working, not a
limit being hit** — `lib/commands.lua` keeps the drone inside `mapgen_limit`,
because past that edge a write silently does nothing, which is the lost write
`load_area` exists to stop. It is `B25`'s half of this check and it reports the
edge by name. The number depends on the world's own `mapgen_limit`, so a build
world with a small one stops sooner than the engine's 31000 default.

### W2 · A node written into never-generated ground [A4]

Place a node in an area that has never been generated, leave, come back so the
area generates, and look.

**Pass:** the node is still there. This was **unknown either way** and was one of
the things v1.0.0 was going to ship not knowing.

Result: pass — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 ·
2026-08-28 — the node survives. **`A4`'s open question is answered**: mapgen does
not overwrite a node already written into ground it had not generated. That
question had been on the audit's *not verified anywhere* list since Phase 4 and
is the oldest thing on it to be settled. `place_block`'s `core.load_area` call
is what makes the write real in the first place; this says the engine then
treats the block as generated and leaves it alone.

### W3 · A large bulk shape [A5, A15]

Run `cube(200, 200, 200)` or similar at codelevel 4 and watch the server.

**Pass:** the shape appears slab by slab and the server stays responsive. It must
not freeze — a 150-node cube stalled it for 0.44 s before shapes were written in
mapblock-aligned slabs.

Result: pass — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 ·
2026-08-28 — `cube(200, 200, 200)` in **0.34 s**, server responsive.

**What that shape costs, since the 0.34 s is the smallest part of it.** Worked
out from the code and the one measured constant, `16.3 kB` resident per mapblock
(`S5`); the timing is the only measured number here.

- **8,000,000 nodes**, against `max_nodes_written` = 1e7 at codelevel 3. It fits
  with a fifth to spare, so `cube(215,215,215)` would not.
- **~13 mapblocks on each axis**, so a cross-section of ~169 and a total of
  **~2200 mapblocks** emerged. `SLICE_BLOCKS` is 16, so `layers` computes to 0
  and is clamped to 1: **every slab is one mapblock thick and 169 across**. This
  is the "large in two dimensions" case slicing cannot reduce — a slab is 169
  blocks whatever the axis.
- **~36 MB of server RAM pinned**, decaying over the engine's 29 s unload
  window. Against `map_memory_mb` that is 4096 blocks allowed at level 3 and
  8192 at level 4, so ~2200 never comes near the ceiling and the run never
  throttles. That is why it did not wait.
- **CPU**: 13 slabs, each a VoxelManip read, a full-volume fill and a write over
  ~692k nodes — about 18M Lua table stores in total. 0.34 s is consistent with
  that under LuaJIT, so the number is what the model predicts rather than a
  surprise.

**What nothing charges for.** The 0.34 s is the *program's* time, and the budget
covers nodes, runtime and footprint. Serialising ~2200 mapblocks into the map
database, and pushing them to every client in range, happen **outside the run
and are charged to nobody** — they land after the program has already reported
`completed`. Neither was measured here. That is not this shape misbehaving; it
is the shape of the limits model, and it is noted under `S5` rather than filed,
because every mod writing to the map has it and `map_memory_mb` is the closest
thing to a proxy.

---

## Pacing, slabs and the footprint throttle

**First run, 2026-08-27, at `246bb37`**, engine Luanti 5.17.0 — three passes and
one fail, and the fail is **B42**: a shape wider than the footprint ceiling
raises instead of waiting, and which way the drone is facing decides whether it
happens. Everything else in the group behaves as the audit said it would from
reading alone: the pacing, the slab progression and the shared step budget.

**Second run, 2026-08-28, at `febf16f`** — `P3` passes, and with it the group.
The throttle has now been seen throttling, which is the one thing `S5` claimed
from reading and no run had reached: the same `cube(2, 2, 30000)` that died
before completed in 93 s, a rate consistent with the ceiling divided by the
engine's unload window. The run also turned up that **how long it takes depends
on which way the drone faces** — every orientation completes, so not `B42`
returning. Timing three of them settled it and opened **`B43`**: 78 s, 160 s and
183 s for the same call from the same spot, two of the three landing on what a
doubled or quadrupled emerge predicts. **A measurement, not a failure, is what
found that one**, and it is the first finding here to arrive that way.

**Third run, 2026-08-28, at `6fea453`** — `P3` re-timed against `B43`'s fix, and
the spread is gone: **78 s and 95 s** at codelevel 1, where a doubled emerge
would have cost 183 s. The group stays green and `B43` is closed by the same
kind of evidence that opened it. Two facings, not four, and 23% of the gap is
still unaccounted for; both are written into the result below rather than
smoothed over.

### P1 · `pace_ms` at the low codelevels [S5, B26]

Run the same loop at codelevel 1, then 2, then 4.

**Pass:** level 1 visibly waits about 250 ms between commands and level 2 about
15 ms, so a beginner can watch the loop happen; levels 3 and 4 do not wait.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### P2 · Slab progression under the step budget [A5, B26]

Run a shape large enough to take many slabs and watch the server step time.

**Pass:** the deadline is honoured at every drone command and before every slab.
The known overshoot is **one slab** — a VoxelManip pass cannot be interrupted,
which is the deliberate trade that lets a shape be any size.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### P3 · The footprint throttle actually throttling [S5]

Run a program that exceeds `map_memory_mb` — a long sweep at a low codelevel.

**Pass:** the drone **waits** and then continues. It must not die: over the
ceiling `limits.hold` returns how long to wait, because the engine frees idle
mapblocks by itself. The audit records the throttle's live behaviour under a
program that genuinely exceeds the ceiling as still unmeasured, and the decay as
an estimate by construction.

Use a shape that is long in one dimension — `cube(2, 2, 30000)` at codelevel 1
does it. **Facing does not matter any more**, and checking that it does not is
half of this check now: the run used to die facing east or west, where the
extents land on x and nothing sliced along it (**B42**, fixed). Run it both ways.

Result: fail — `246bb37` · engine 5.17.0 · 2026-08-27 — `cube(2, 2, 30000)` at
codelevel 1 ended with *"Empreinte mémoire maximale de la carte dépassée"*. The
drone died where the whole point of this ceiling is that it waits. **B42**, open:
`lib/shapes.lua` slices along z only, so with the shape running along x the
cross-section is about 1877 mapblocks against codelevel 1's ceiling of 512, and
`limits.hold` returns nil — the case its own comment says a slicing caller never
reaches. Nothing was written, because `charge` runs before the pass. **The
throttle itself is still unmeasured**: re-run facing north, where each slab is 16
blocks and the wait is what should be observed.

Result: pass — `febf16f` · engine 5.17.0 · 2026-08-28 — `cube(2, 2, 30000)` at
codelevel 1 **completed, in 93 s**. The drone waited instead of dying, which is
what this check is for and what no run had ever reached. **The first measurement
of the throttle**, and it matches the design: codelevel 1 holds 8 MB, which is
512 mapblocks, decaying over the engine's 29 s unload window, so the rate it
should settle at is 512/29 ≈ 17.7 mapblocks a second. The shape emerges about
1877 mapblocks, the first 512 of them free, which predicts ≈ 80 s against the
93 s observed — consistent, with the gap in the direction the estimate is coarse
(`limits.hold` decays linearly rather than tracking each block, and the server
steps in between).

Re-run at codelevel 2, same commit and day: **both orientations complete**, so
`B42` is closed either way, but the *cadence differs by orientation* — in one the
blocks appear and then the drone pauses, in the other the drone pauses until the
blocks appear. At codelevel 1 nothing appeared at all until the drone was
stopped, and then part of it did.

**What it was.** Not a deferred write: `lib/shapes.lua` calls `write_to_map()` in
every pass, and **nothing in this mod touches the map when a drone stops** —
`Drone.finish` sends a chat line and removes the drone. Two candidates were
open, and a number rather than an impression told them apart:

1. **What the client drew.** The shape grows along a different axis each way, so
   one run grows across the player's view and the other away from it, and the
   view distance decides how much of either is on screen. It was set to 30 for
   `D2`.
2. **A real difference in the work.** The emerged box covers one node more than
   the shape on every axis, so a 2-node extent covers 3 and straddles a mapblock
   boundary at twice as many positions; which extent is where changes with the
   angle, because `bounds.cube` centres `w` on x and `l` on z while
   `drone_place_cube` gives each angle its own origin.

**Settled, and it is the second.** Timed at three facings from one spot,
codelevel 2, **view distance 500** so nothing was hidden: **78 s, 160 s, 183 s**.
Codelevel 2 holds 1024 mapblocks decaying over 29 s, so it settles at 35.3 blocks
a second; the long axis is about 1877 mapblocks and each short axis multiplies by
1 or 2, giving predicted times of 24 s, 77 s and 184 s. **78 and 183 land on two
of those to within one per cent**, so the work really does differ with the
facing — that is **`B43`**, filed. The 160 s run fits none of them and is
recorded as fitting none: the products can only be 1, 2 or 4.

At view distance 500 the shape was visible as it built, so the codelevel-1 run
above — nothing appearing until the drone was stopped — was the client and not
the server. No id for that half.

**Due a re-timing, and this is the check that proves `B43`'s fix.** The
subtraction landed on 2026-08-28: `bounds.cube` and `bounds.cylinder` no longer
run a node past the shape. Repeat the three facings from one spot at codelevel 2,
view distance 500. **Pass:** the three times are within noise of each other and
near the 78 s end, because a 2-node extent now covers 2 nodes and straddles a
boundary at 1 position in 16 rather than 2 — the factor-of-two spread between
facings should be gone. The specs pin the charge arithmetic and were checked
against the old bounds so they are not vacuous, but **only this check can say
whether the time a player waits actually changed**, which is what the finding was
about.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — the re-timing, **at
codelevel 1**, view distance 500: **78 s one way, 95 s the other**. The
factor-of-two the finding was about is gone. At codelevel 1 the hold is 512
mapblocks decaying over 29 s, so the rate is 17.7 a second and the first 512 are
free; against a long axis of about 1877 mapblocks that predicts **77 s at
multiplier 1 and 183 s at multiplier 2**. Both facings land at the multiplier-1
end. Before the fix the same shape spread 78 / 160 / 183 s across three facings.

Two things to keep straight about this as evidence. It was run at **codelevel 1
where the pre-fix timing was at codelevel 2**, so the absolute seconds are not a
like-for-like pair — but the *ratio between facings* is what `B43` is about, and
that ratio barely moves with codelevel: the free initial hold makes a doubling
cost 2.37x at level 1 against 2.05x at level 2, so if anything this run was the
sharper test. And **only two of the four facings were timed**; the other two are
untimed, as is the third that was 160 s before.

The 95 s is 23% over the 78 s and the emerge model does not explain it — the
multipliers can only be 1, 2 or 4, and 1.23 is none of them. Recorded rather
than filed, as the old 160 s was: the coarse linear decay in `limits.hold`, the
drone's own traverse and whatever else the server was doing all live in that
gap, and none of them is the doubled emerge this check was looking for. The
93 s codelevel-1 run at `febf16f` sits beside today's 95 s, but its facing was
never recorded, so it is not a before/after pair either.

### P4 · Several drones at once [A5]

Run four or more drones simultaneously.

**Pass:** they share one slice of each server step rather than taking one budget
each, and a waiting drone takes no share.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — four drones shared the
steps.

---

## Release and install

### R1 · The archive contains no `tests/` [C16, C10]

```bash
git archive HEAD | tar -t | grep tests
```

**Pass:** no `tests/` directory. ContentDB builds releases with `git archive`,
and nothing in CI checks `.gitattributes`.

**The grep is not the pass condition — read what it prints.** `lib/examples/`
contains a player-facing example named `tests.lua`, so this command has a match
even when the archive is correct. It is one of the fourteen example programs a
player can open and run, and it exercises every API command in one go, which is
exactly why it is called that. What would be a fail is a path *beginning*
`tests/`. Better to list the top level and read it whole:

```bash
git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u
```

Result: pass — `afbe504` · 2026-08-28 — run in WSL by the author. `grep tests`
returned `lib/examples/tests.lua` and nothing else, which is the example, not the
suite. Listed in full the archive holds eleven top-level entries, all
player-facing: `CHANGELOG.md`, `LICENSE`, `README.md`, `doc`, `init.lua`, `lib`,
`locale`, `mod.conf`, `screenshot.png`, `settingtypes.txt`, `textures`. No
`.claude/`, `.reports/`, `.github/`, `tests/`, `scripts/`, and **none of the
record** — `AUDIT.md`, `PLAYTEST.md`, `ROADMAP.md`, `TODO.md` and `CLAUDE.md` are
all absent. `screenshot.png` survives, which it must: Luanti shows it in the
Mods tab. **`C10` is confirmed for the first time** — `.gitattributes` was doing
its job, but nothing had ever looked.

### R2 · A real install with the test flag set [C16]

Install the built archive as a package and set `codeblock_run_tests = true` in
`minetest.conf`, then start the game.

**Pass:** the mod loads normally and logs *"codeblock_run_tests is set, but this
build ships no tests/ directory"*. Before C16 this was nine bare `dofile`s and the
whole mod refused to load. **Committed, not verified — nobody has built an
archive and installed it.** Do this once as part of the next release check; the
release path is exactly where the failure would be met.

Result: unchecked

### R3 · The sky belongs to the game [C18]

Install the mod into a game that has an ordinary day/night cycle — anything but
`codecube` — and join. Then set `codeblock_flat_sky = true` in `minetest.conf`,
restart, and join again.

**Pass:** the first join leaves the sky alone — the cycle runs, the sun, moon and
stars are where the game put them, clouds are drawn. The second join has daylight
held at noon with none of them visible. Before the fix every joining player got
the second sky and there was no way to ask for the first.

The setting is read once at mod load, so a restart is part of the check and not an
impatience. Nothing needs undoing between the two: the overrides are per-player
and re-applied on join.

Result: pass — `326f739` + uncommitted B41/C18 fixes · engine 5.17.0 · 2026-08-28
— both positions. With the setting absent the game's own sky is left alone; with
`codeblock_flat_sky = true` the daylight is held and the sun, moon, stars and
clouds are gone. **C18 is confirmed fixed in a running world**, and this is the
first time the finding's player-visible half has been seen at all: that a joining
player loses the day/night cycle was read from the source for the whole life of
the finding, because inside `codecube` the flat sky is the game's own design and
looks correct.

---

## Per-feature checks

Added as each feature lands, for the paths that feature puts beyond the specs.

**Run of 2026-08-27, at `246bb37`** — all three pass. `F1` and `F3` are now proven
in a running world and nothing is outstanding for either.

### F1 · The Settings panel [F1]

Open the editor and click **Settings** beside Blocks / Plants / Wools / API.

**The control is not what the plan first described.** The panel draws the chosen
block's texture plus one button reading **`Default block: <name>`**. Clicking the
button opens a `textlist` of block names; clicking a row selects that block and
closes the list; clicking the button again closes it unselected. A
`scroll_container` of `item_image_button` rows — the help panels' rendering — was
abandoned: this formspec is in legacy coordinates, where a container maps its
contents into a different space and clips them to its own rectangle, and an
`item_image_button` inside one gets a hit area that does not match where it is
drawn. The price is that the rows are names only, with the texture of the chosen
block shown above them.

**Pass:** the button shows the current default; clicking it opens the list and
clicking it again closes it; selecting a row changes both the name on the button
and the texture beside it; `air` is offered and selectable; switching to Blocks /
Plants / Wools / API and back leaves the panel usable. Not spec-reachable — it is
a formspec.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F1 · The preference survives a relog [F1]

Pick a block in the Settings panel, close the editor with **ESC**, disconnect,
rejoin, and run a program whose `place()` names no block.

**Pass:** the chosen block is what gets built. The meta write happens the moment
a row is selected, not on form close — precisely so the preference does not
depend on the editor-state save path. **Expect this to pass even though E5 fails**
on three exits: that is by design, not an inconsistency between the two checks.
Selecting a row through **Load and close**, or a disconnect straight after
picking, should also keep the preference while losing the tabs.

Then change the preference mid-run: **pass** is that the running program keeps
building the block it started with, because the preference is read once per run
into `drone.default_block`.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — with the panel check
above, **F1 is now proven in a running world** and nothing is outstanding for it.

### F3 · `sleep(seconds)` in a running world [F3]

Run a program that places a node, calls `sleep(1)`, and repeats — at codelevel 3
or 4, where `pace_ms` is 0 and the wait is therefore the only thing pacing it.
Then run one asking for far more time than the codelevel allows, `sleep(1e9)`.

**Pass:** the drone visibly builds one node a second; the server stays responsive
and any other drone keeps building at its own rate while this one waits; and the
unbounded ask ends the program with the same timeout message a program that never
finishes gets, rather than parking the drone for ever. The wait is charged against
`max_runtime_s` before it starts, which is that limit's one exception.

`stepper_spec` and `integration_spec` cover the skip and the charge without a
world; what only a world shows is the *pace* being watchable and other drones
being unaffected.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — **F3 is now proven in a
running world.**

---

Sources: `AUDIT.md` (per-finding reasoning), `ROADMAP.md` (the `F` entries and
*what ships broken*). When a check moves, update the finding entry too — that is
the record, this is the procedure.
