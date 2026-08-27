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
2. **The weak one:** the edit to A is still in the text area when you switch back,
   whether or not it reached disk. The option gates only `save_active()`; it used
   to gate the in-memory capture as well, so switching tabs with it off lost the
   edit outright.

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

---

## Drone placement and the setter tool

**First run, 2026-08-27, at `f274245`**, engine Luanti 5.17.0 — one pass, two
fails, one partial, and the partial turned out to be this document being wrong
rather than the code. Both fails were in code nobody had exercised in a running
world since it was written: **B38** (aiming at nothing is silently ignored,
because the engine calls a different callback than `on_place`) and **B39** (the
first join after installing the mod wipes the inventory).

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
   **Pass:** the replacement runs, and **no** *"program ended"* line is announced
   for the one that was removed. `ObjectRef:remove()` takes effect at the end of
   the step, so `on_deactivate` can fire after the replacement is installed under
   the same name; the serial is what protects it, not the clear-before-remove
   ordering.

Result: partial — `f274245` · engine 5.17.0 · 2026-08-27 — "when placing during
run it says '... wait busy...', after a run it works". That is part 1 passing.
**The check was wrong, not the code**: it asked for a replacement mid-run, which
`on_place` refuses on purpose, and so pointed at a path that cannot reach B29's
window at all. No finding id — nothing in committed code is defective here.
Part 2 is unchecked and is the one that tests the serial guard.

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

---

## Filesystem and example generation

**First run, 2026-08-27, at `f274245`**, engine Luanti 5.17.0 — one pass, one
partial, one that could not be run because no procedure was written for it. The
partial is **C17**: the behaviour is right and the words are in the wrong
language. F-3 now has two recipes, which is what it was missing.

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

### F-3 · A file that cannot be read [B7, B15]

`read_file` refuses in two ways and both name the file. The cheap one first:

1. **A precompiled chunk.** Put a file whose first byte is `0x1B` into
   `<worldpath>/codeblock_files/<playername>/` — `luac5.1 -o bytecode.lua
   any.lua` makes one, or any binary renamed to `.lua` — then open the editor and
   click it in the file list. **Pass:** the chat says *"Compilation error in
   bytecode.lua: Binary bytecode prohibited"*, naming the file, and the editor
   carries on with the rest of the list. This is the branch that runs after
   `handle:close()`, so it is also where a leaked handle would show.
2. **A genuinely unreadable file**, which is the awkward one. On Windows, deny
   yourself read on one of your `.lua` files and reopen the editor:

   ```
   icacls "<worldpath>\codeblock_files\<playername>\test.lua" /deny "%USERNAME%":(R)
   icacls "<worldpath>\codeblock_files\<playername>\test.lua" /remove:d "%USERNAME%"
   ```

   **Pass:** the message names `test.lua`, and no other file in the list is lost
   with it — a single bad file must not cost the player the session.

Do case 1 at least; case 2 opportunistically rather than blocking a release on it.

Result: unchecked — "not sure what to do to test" at `f274245`, which is a
procedure that was not written down rather than a defect. No finding id. The two
recipes above are new with the commit this line was added in.

---

## Writing to the world

### W1 · `place()` far from spawn [A4, S5, B25]

Fly a long way out, place a drone, and run a program that walks and places one
node at a time across several mapblocks and back over ground it already visited.

**Pass:** no holes. Every node is where the program said. `place_block` calls
`core.load_area` before `set_node`, memoised per mapblock — and the memo is
cleared before every yield, **per resume, not per run**, which is exactly what
this check exercises.

Result: pass — `43e95a8` · engine not recorded · 2026-08-25 — the mapblock memo,
the per-crossing footprint charge and the per-resume reset all behaved. Measured
over a 400-block sweep: **16.3 kB resident per mapblock**, and the engine served
about **1700 loads a second**. Recorded in the audit under S5 and quoted again as
the measurement that forced Phase 6's `map_memory_mb`. The engine version was not
written down at the time; the audit cites `lua_api.md` 5.17.0 for `load_area` not
triggering mapgen. **Re-run before v1.0.0** — this predates the Phase 6 and
Phase 7 rewrites of `lib/cost.lua`.

### W2 · A node written into never-generated ground [A4]

Place a node in an area that has never been generated, leave, come back so the
area generates, and look.

**Pass:** the node is still there. **Unknown either way** — whether mapgen can
overwrite it is one of the things v1.0.0 ships not knowing.

Result: unchecked

### W3 · A large bulk shape [A5, A15]

Run `cube(200, 200, 200)` or similar at codelevel 4 and watch the server.

**Pass:** the shape appears slab by slab and the server stays responsive. It must
not freeze — a 150-node cube stalled it for 0.44 s before shapes were written in
mapblock-aligned slabs.

Result: unchecked

---

## Pacing, slabs and the footprint throttle

None of this has ever been verified in a running world. Untested, not known
broken.

### P1 · `pace_ms` at the low codelevels [S5, B26]

Run the same loop at codelevel 1, then 2, then 4.

**Pass:** level 1 visibly waits about 250 ms between commands and level 2 about
15 ms, so a beginner can watch the loop happen; levels 3 and 4 do not wait.

Result: unchecked

### P2 · Slab progression under the step budget [A5, B26]

Run a shape large enough to take many slabs and watch the server step time.

**Pass:** the deadline is honoured at every drone command and before every slab.
The known overshoot is **one slab** — a VoxelManip pass cannot be interrupted,
which is the deliberate trade that lets a shape be any size.

Result: unchecked

### P3 · The footprint throttle actually throttling [S5]

Run a program that exceeds `map_memory_mb` — a long sweep at a low codelevel.

**Pass:** the drone **waits** and then continues. It must not die: over the
ceiling `limits.hold` returns how long to wait, because the engine frees idle
mapblocks by itself. The audit records the throttle's live behaviour under a
program that genuinely exceeds the ceiling as still unmeasured, and the decay as
an estimate by construction.

Result: unchecked

### P4 · Several drones at once [A5]

Run four or more drones simultaneously.

**Pass:** they share one slice of each server step rather than taking one budget
each, and a waiting drone takes no share.

Result: unchecked

---

## Release and install

### R1 · The archive contains no `tests/` [C16, C10]

```bash
git archive HEAD | tar -t | grep tests
```

**Pass:** no output. ContentDB builds releases with `git archive`, and nothing in
CI checks `.gitattributes`.

Result: unchecked

### R2 · A real install with the test flag set [C16]

Install the built archive as a package and set `codeblock_run_tests = true` in
`minetest.conf`, then start the game.

**Pass:** the mod loads normally and logs *"codeblock_run_tests is set, but this
build ships no tests/ directory"*. Before C16 this was nine bare `dofile`s and the
whole mod refused to load. **Committed, not verified — nobody has built an
archive and installed it.** Do this once as part of the next release check; the
release path is exactly where the failure would be met.

Result: unchecked

---

## Per-feature checks

Added as each feature lands, for the paths that feature puts beyond the specs.

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

Result: unchecked

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

Result: unchecked — the three 2026-08-27 runs covered the editor group only. F1
shipped at `500dd85` with CI green and `integration_spec` 90 → 98, so **these two
checks are the whole of what is outstanding for it**. Run them against that commit
or later, and record the commit, not "current".

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

Result: unchecked — F3 shipped at `90cfb70` with its gates green (374 passed, 0
failed) and no in-world check run.

---

Sources: `AUDIT.md` (per-finding reasoning), `ROADMAP.md` (the `F` entries and
*what ships broken*). When a check moves, update the finding entry too — that is
the record, this is the procedure.
