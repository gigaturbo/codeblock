# Playtest — CodeBlock

The manual checks the automated suite cannot reach. The nine specs run **at mod
load**, before a map, a player or a user directory exists, so the editor, drone
placement, the filesystem and every write into the world have no spec coverage at
all and cannot have. Six findings closed in Phase 7 rest on reading the code
only. This file is where that gap is written down, so it can be reviewed rather
than rediscovered from prose scattered across `ROADMAP.md` and the audit.

`tests` is `export-ignore`d in `.gitattributes`, so this file never ships to a
player.

## How to record a result

Each check carries a **Result** line. Leave it as `unchecked` until someone
actually does it in a running world, then replace it with:

```
Result: pass — <commit> · engine <version> · <YYYY-MM-DD> — <one line of detail>
```

`fail` and `partial` take the same shape. **Always keep the commit and the
date**: a pass recorded three phases ago is not evidence about today's code, and
the point of the line is that a stale pass reads as stale rather than as current.
A `fail` is not a finding — report it and let the audit allocate or widen an id.

Reference the finding or feature id in brackets after the title; the reasoning is
in `.audit/audit.html` under that id.

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

Result: unchecked

### E9 · Tab state survives a server shutdown [B33 — the unverified one]

Open two files with the editor open, shut the server down cleanly, restart, and
open the editor.

**Pass:** both files are open again and the active tab is restored. This is the
weakest of the three paths by evidence: `register_on_shutdown` reaches every open
session, but that **player meta written from `on_shutdown` is still saved** follows
from the engine's shutdown order and **has not been observed here**. If this check
fails, the finding is the write being dropped, not the callback not firing — check
the log for the handler running at all before concluding.

Result: unchecked

### E10 · The checkboxes for a player who has never set them [no finding]

Join as a **new** player — one with no `codeblock:load_on_exit` or
`codeblock:save_on_switch` in their meta — and open the editor. Then untick one,
close the editor, and reopen it.

**Pass:** both boxes start **ticked**; the one you unticked is still unticked when
you come back. Both keys are read with `get_string`, where an absent key is `""`
and a stored `0` reads back as `'0'` — `get_int` returned 0 for both cases and
could not tell them apart. `soe` uses the same string read but keeps its `false`
default and its checkbox stays commented out (E6).

Result: unchecked

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

### E12 · Typing survives a tab switch with **Save on tab switch** off [B35]

Untick **Save on tab switch**. Edit tab A without saving, switch to tab B, switch
back to A.

**Pass:** the edit to A is still there — in memory, whether or not it reached
disk. The option now gates only `save_active()`; it used to gate the in-memory
capture as well, so switching tabs with it off lost the edit outright. This case
was found by reading, not reported, and has not been run.

Result: unchecked

---

## Drone placement and the setter tool

### D1 · Place a drone and run a program [B10, A11]

Point at loaded ground with the setter, place a drone, pick a file, watch it run
to completion.

**Pass:** one completion message, from `Drone.finish` and only there.

Result: unchecked

### D2 · Place a drone at nothing [B10]

Point past loaded ground — far out over an unloaded area or into the sky at
range — and use the setter.

**Pass:** the chat says *"Cannot place the drone there, move closer"* and no
record is created. This is the `add_entity`-returns-nil path; `Drone.new` must
create no record, because a record with no object is a drone that silently never
runs.

Result: unchecked

### D3 · Replace a drone under the same name [B29, B30]

Place a drone, run a program, and place a second drone before the first has
finished — then again after it has.

**Pass:** the replacement keeps running and no *"program ended"* line is
announced for the drone that was removed. `ObjectRef:remove()` takes effect at
the end of the step, so `on_deactivate` can fire after the replacement is
installed; the serial is what protects it, not the clear-before-remove ordering.

Result: unchecked

### D4 · Join with a full inventory [B16]

Join with items in the hotbar and main inventory.

**Pass:** the poser and setter are added and **nothing else is removed**. Every
join used to wipe the inventory.

Result: unchecked

---

## Filesystem and example generation

### F-1 · `/codegenerate` on your own files [B8, B15]

Run `/codegenerate` as an unprivileged player, twice.

**Pass:** the examples appear the first time; the second run leaves existing
files alone rather than overwriting them, and needs no privilege for your own
files.

Result: unchecked

### F-2 · `/codegenerate <player>` [B8]

Run it against another player's files, with and without the `codeblock`
privilege.

**Pass:** refused without the privilege; with it, the files land under the named
player, not the caller — the old argument pattern read a bare number as a player
name.

Result: unchecked

### F-3 · A file that cannot be read [B7, B15]

Make one file in the player's directory unreadable, or an example file
unreadable, and open the editor / run `/codegenerate`.

**Pass:** the error names the **filename**, not a file handle, and no handle is
leaked. Awkward to arrange; do it opportunistically rather than blocking a
release on it.

Result: unchecked

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

Result: unchecked — both 2026-08-27 runs covered the editor group only. F1 shipped
at `500dd85` with CI green and `integration_spec` 90 → 98, so **these two checks
are the whole of what is outstanding for it**. Run them against that commit or
later, and record the commit, not "current".

---

Sources: `.audit/audit.html` (per-finding reasoning) and `ROADMAP.md`'s *what
ships broken*. When a check moves, update the audit entry too — the audit is the
record, this is the procedure.
