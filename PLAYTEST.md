# Playtest — CodeBlock

The manual checks no spec can reach. The suite runs **at mod load**, before a
map, a player or a user directory exists, so the editor, drone placement, the
filesystem, inventories, locale files and every write into the world have no spec
coverage and cannot have.

Reasoning for a defect lives in `AUDIT.md` under the bracketed id, and for a
feature in `ROADMAP.md`. This file has its own `export-ignore` line and never
ships to a player.

## How to record a result

```
Result: pass — <commit> · engine <version> · <YYYY-MM-DD> — <one line of detail>
```

`fail` and `partial` take the same shape. The commit, the engine version and the
date are always kept; a pass without them is not evidence.

**Name both commits when the checkout was at a record-only commit.** Write it
`2feadb1`, record-only over `24842d3` — the checkout, then the last commit that
touched `lib/`.

**Results run oldest first within an entry.** `W1` is the only exception and runs
the other way; leave it.

**A `fail` is not a finding.** Report it and let `AUDIT.md` allocate or widen an
id. A wrong *check* is a defect in this document and gets no id.

**The states a check can be in**, beyond the outcome of its last result:

| State | Means |
|---|---|
| `unrun` | Never run. Waiting on a runner. |
| `owed` | Carries a pass, but the code under it changed. Waiting on a re-run. |
| `stale` | Carries a pass whose commit or counts no longer describe the tree. |
| `unreachable` | The remaining cases are impossible to perform on this form. Nothing is owed and no future run improves it. |

**`unreachable` is not `partial`.** `partial` says a result could improve.
`unreachable` says it cannot, so the check leaves *Checks needing action*.

## How a check is written

**Hand the runner an actual program or command**, not a description of one.

**A recipe names the shell it is for.** A `cmd.exe` line pasted into PowerShell
has cost a session twice.

Template:

```
### <id> · <title> [<finding ids>]

<numbered steps, or a fenced program to paste>

**Pass:** <short observable statements>

Result: ...
```

## Where it stands

| | Count |
|---|---|
| Entries | 85 |
| Retired | 1 — `F11-4` |
| Live checks | 84 |
| Most recent result a pass | 81 |
| Unreachable | 1 — `H8` |
| Unrun | 2 — `F-6`, `R5` |
| Stale | 3 — `R1`, `R2`, `R4` |
| Fail as most recent result | 0 |

Checks needing action:

| Check | State | Reason |
|---|---|---|
| [`F-6`](#f-6--gamelua-starts-in-the-same-direction-every-time-s8) | unrun | `S8`'s only in-world reading, and now the check that confirms the fix. |
| [`R5`](#r5--an-old-vector3-is-named-in-the-log-at-mod-load-s9) | unrun | The load-time warning about an old `vector3`. Needs the submodule swapped by hand. |
| [`R1`](#r1--the-archive-contains-no-tests-c16-c10) | stale | Texture and example counts have changed since the last run. |
| [`R2`](#r2--a-real-install-with-the-test-flag-set-c16) | stale | Last run at `7c5bceb`, before `F4` and two `.gitattributes` changes. |
| [`R4`](#r4--a-brand-new-world-hands-out-the-right-codelevel-s6) | stale | `check_auth_level` reads the default at call time since `A17`. The pass predates that contract. |

---

## Editor

E1–E17. The editor formspec is in legacy coordinates; the help row is a
**Blocks** button, a category selector, **API** and **Settings**.

### E1 · Open, save and close a program [A9, B13, B17]

Open a file, type, save, close with **Save**, reopen.

**Pass:** the edit is on disk and comes back; no `set_string` error in the log.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E2 · Create and remove a file [B14, A9, A18]

1. Create a new file from the chooser, then remove it.
2. With **two** files open, remove the active one.

**Pass:** case 1 succeeds both ways and leaves an empty editor. In case 2 the
remaining file becomes the active tab and its content is on screen.

**Why the two cases.** `remove_active` sets `meta.active = #meta.tabs`. Case 1
reaches the empty branch and **case 2 is the fallback branch**.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — case 1
only; case 2 was added later.

Result: pass — `fffdded`, record-only over `c089f78` · engine 5.17.0 ·
2026-09-08 — both cases. Case 2 is `A18`'s `remove_active` fallback reached in a
real world for the first time: two files open, the active one removed, the
remaining file active with its content on screen.

**A second case was removed 2026-09-02 as untestable**, on the author's call. It
asked for the removal of a file never opened this session — `B14`'s cold-cache
path — and the editor cannot do it: the four file buttons draw only inside
`if meta.active ~= 0 then` (`B34`, won't fix). **`B14` has no route from this
check.**

### E3 · Tabs [B33, A18]

Open three files, switch between them, close the middle one, then the last.

**Pass:** each tab shows its own content; the active tab is sensible after a
close; closing the last leaves an empty editor rather than an error.

**Why both closes.** `close_active` sets `meta.active = #meta.tabs`, and this
check walks both branches of it — closing the middle one is the fallback,
closing the last is the empty case.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

Result: pass — `fffdded`, record-only over `c089f78` · engine 5.17.0 ·
2026-09-08 — both branches after `A18`. This is `A18`'s in-world evidence for
`close_active`.

### E4 · Tab state survives ESC [B33]

Open two files, close with **ESC**, reopen.

**Pass:** both files are open again and the active tab is restored.

Settled — only re-run if `save_editor_state()`'s single branch
(`fields.quit == 'true'`) changes.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E5 · Tab state after **Load and close** [B33]

Open two files and leave with the **Load and close** button. Reopen.

**Pass:** both files are open and the active tab is the one you were on.

Result: pass — `500dd85` content, run pre-commit · engine 5.17.0 · 2026-08-27.

Earlier: fail — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — all
three exits lost the tabs. That widened `B33` to three losing paths.

### E6 · The two checkboxes [B5]

Toggle **Load program on exit** and **Save on tab switch**, close, reopen.

**Pass:** both persist and both take effect. With *Save on tab switch* **off**,
editing and switching tab discards the edit.

The third box, *Save on exit*, is commented out and **deliberately dead — do not
restore it.** A warning on unsaved changes is wanted instead (`TODO.md`).

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27.

### E7 · The help panels [A2, B22]

Open the **Blocks** panel for each category in the selector, then **API** and
**Settings**. Scroll each block panel to the bottom.

**Pass:** every panel draws, every item shows a texture, each category keeps its
own scroll position, and the API hypertext renders.

Result: pass — `3293a2c` + uncommitted F1 · engine 5.17.0 · 2026-08-27 — four
panels; Settings has its own check below.

### E8 · Tab state survives a disconnect [B33]

Open two files and **disconnect**. Rejoin and open the editor.

**Pass:** both files are open and the active tab is restored.

**Not exposed to `B37`:** the leave callback builds its own `{quit = 'true'}`
with no scrollbar field, which is why it passed while ESC did not (`E14`).

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27.

### E9 · Tab state survives a server shutdown [B33]

Open two files, shut the server down cleanly, restart, open the editor.

**Pass:** both files are open and the active tab is restored. This is what
settles that **player meta written from `on_shutdown` is still saved**. Same
`B37` caveat as `E8`.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27.

### E10 · The checkboxes for a player who has never set them [B36]

Join as a player who has **never existed in this world** — a genuinely new name
or a fresh world. Untick one, close, reopen.

**Pass:** both boxes start **ticked**; the untick survives.

**The fresh name is not optional.** Any player who joined before `1f7cd97`
carries the `0` `register_on_newplayer` used to write, honoured as a deliberate
untick. Re-running as an existing player looks like a failure and is not one.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27 — fresh name, both halves.

Earlier: fail — `dee0bc7` · engine 5.17.0 · 2026-08-27 — both boxes unchecked for
a new player. That is `B36`.

### E11 · Typing survives every button that is not Save [B35]

Type into a file, then press **Blocks** in each category, **API** and
**Settings** without saving.

**Pass:** the text is still there after every one.

Result: pass — `500dd85` content, run pre-commit · engine 5.17.0 · 2026-08-27.

### E12 · **Save on tab switch** off really does not write to disk [B35]

Untick it. Edit tab A without saving, switch to B, switch back, leave with **ESC
only**. Reopen and reopen A.

**Leave by ESC and nothing else** — *Load and close* and *Save* both write
unconditionally by design.

**Look at the file, not at the editor.** Read
`<worldpath>/codeblock_files/<playername>/<file>.lua` from outside the game and
note its size or mtime.

**Pass:** the edit is **absent** from disk. The edit still being in the text area
when you switch back is **intended** — an unsaved tab holds its edit — and is not
a fail; the unsaved marker is `E16`.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — after ESC and a reopen,
the edit is gone. Three earlier reports at `dee0bc7` and `f274245` read the
retention as a save; the check was wrong and no id was allocated.

### E13 · **Create a copy** [F2]

With an unsaved edit, click **Create a copy**. Then copy the copy, several times.
Then reopen the original.

**Pass**, six parts:

1. The copy is `<name>_1.lua` containing **what was on screen**.
2. It opens as the active tab.
3. Copying increments without nesting suffixes or losing a character.
4. The **original is unchanged on disk**.
5. Past ten copies the list reads `_9`, `_10`, `_11`, not alphabetically.
6. The button's **right edge sits flush** with the file list and `+`.

Result: pass — `dee0bc7` · engine 5.17.0 · 2026-08-27 — all six.

### E14 · Closing the editor with **ESC** saves the open tabs [B37, B33]

Open two files, leave the help panel on a **block category**, close with **ESC**
or the window **X**. Reopen. Repeat with each block category open, then with
**API** and with **Settings**, which draw no scrollbar.

**Pass:** both files are open and the active tab is the one you were on.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### E15 · **Enter** in the New file field creates the file [B37]

With the panel on a block category, type a name into **New file** and press
**Enter** rather than clicking `+`.

**Pass:** the file is created and opens as the active tab, exactly as `+` does.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### E16 · The unsaved marker on a tab [F7]

Type into a file, then press anything that is **not Save**. Look at the tab
label. Press **Save** and look again. Then leave an unsaved tab with **ESC**,
reopen, and look at the file.

**Pass:**

- The tab reads `thing.lua*` while the buffer differs from the file, and
  `thing.lua` once written.
- It clears on **Save**, on a tab switch with *Save on tab switch* ticked, and on
  **Load and close** — not on a tab switch with that option off.
- **The mark is legible on a tab.** A `tabheader` sizes itself to its labels, so
  a marked tab is one character wider and the row shifts as you type.
- **The file is still called `thing.lua`.** A file named `thing.lua*` in the list
  means the marker reached `meta.tabs`.
- **Create a copy leaves the source marked** and the copy unmarked.

**Accepted wrongness, not a fail:** type a character and undo it and the tab
stays marked until the next save. Report it only if the mark appears with no
typing at all.

**The pristine-example case, for `B48`.** Open **three or four bundled examples
you have never saved** — `plot2D.lua`, `donuts.lua`, `torus.lua` — one after
another and **type nothing**. Every tab but the active one must be **unmarked**.
**Do it on a fresh player directory**: a file already saved through the editor is
LF on disk and cannot show the defect.

Result: pass — `afbe504` · engine 5.17.0 · 2026-08-28 — `F7` confirmed; the
pristine-example case did not exist yet.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03 —
the pristine-example case, four bundled examples opened untouched and no tab but
the active one marked.

### E17 · A brand new file runs as it is [B53]

Press `+` in the editor, type a name, and **run the file that appears without
editing it**.

**Pass:** a **ten-block vertical rainbow column** rises from the drone, and no
error in chat.

**Count the colours.** Ten blocks of ten **different** colours, one per hue
family in wheel order. Ten of one colour, or two alternating, is a fail.

Result: pass — `2feadb1`, record-only over `24842d3` · engine 5.17.0 ·
2026-09-07 — the file ran untouched, ten different hues in wheel order.

---

## Drone placement and the setter tool

D1–D7. **Read *setter* in `D1` and `D3` as *poser*** — they were written when one
tool both placed and removed a drone. Since `F8` the poser places and the setter
only opens the panel or the editor.

### D1 · Place a drone and run a program [B10, A11]

Point at loaded ground with the poser, place, pick a file, watch it finish.

**Pass:** one completion message, from `Drone.finish` and only there.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27.

### D2 · Place a drone at nothing [B10, B38]

With the **poser**, aim into the sky, so there is **no node** under the
crosshair, and place.

**Pass:** *"Please target a node"*, and no record created.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28, and at
`246bb37` before it.

Earlier: fail — `f274245` · engine 5.17.0 · 2026-08-27 — no implementation at
all. That is `B38`.

**A second case was removed 2026-09-02 as untestable**, on the author's call. It
asked for a node the client shows but the *server* has unloaded — the only route
to `B10`'s *"Cannot place the drone there, move closer"*. Two sessions waited out
`server_unload_unused_data_timeout` and found the block still resident. **Do not
write this case again without a way to observe that the server has let go.**

### D3 · Replace a drone under the same name [B29, B30]

1. Place a drone, run a program, and try to place a second **before** it
   finishes. **Pass:** refused with *"Drone is busy, please wait!"*. Placing
   again after it finishes works.
2. Remove a running drone with the panel's **Stop** button and place a new one
   **within the second**. **Pass:** the replacement survives and runs to its own
   end, and the removed run announces its statistics **once**.

**What that line says is `D7`'s business.** This case counts the announcement.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both parts.

**That result predates `1b991ae`**, which changed what the serial guards — the
replacement's object rather than its record. `W6` case 2 covers the new form at
`23f0227`. What is still only pre-`1b991ae` is the *remove and replace within the
second* gesture, now made with the panel's **Stop** button.

Earlier: partial — `f274245` · engine 5.17.0 · 2026-08-27 — part 1 only. The
check was wrong, not the code; no id.

### D4 · Join with a full inventory [B16, B39]

**Superseded by `F10-1` and `F10-2` at `b23a8bc`. Do not run against current
code** — `F10` removed the join-time handout. Run `F10-1` for what a fresh player
is given and `F10-2` for the command that replaced it.

1. Join a world that already has the mod, carrying items. **Pass:** nothing is
   removed.
2. Take a world **without** this mod, collect items, quit, add the mod, join.
   **Pass:** the two tools are added and **nothing else is removed**.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — both cases; the tools are
added after the player's own items.

Earlier: fail — `f274245` · engine 5.17.0 · 2026-08-27 — case 2: *"inventory was
replaced with the 2 drone tools and the rest was empty"*. That is `B39`.

### D5 · Cancelling the file chooser [B41]

Place the poser with no previously loaded file; the chooser opens. Press
**Cancel**. Place again and press **ESC**. A third time, **choose a file**.

**Pass:** neither Cancel nor ESC leaves a drone standing, and choosing a file
still leaves one that runs. **The third part is the one to actually do** — the
fix removes the drone whenever the chooser closes with no file set.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — all
three parts.

Earlier: fail — `246bb37` · engine 5.17.0 · 2026-08-27. That is `B41`.

### D6 · Removing the file a drone is holding [B44]

Place a drone and give it a file. Open the editor, **Remove file**, close. Look
at the drone. Then run it.

**Pass:** the drone goes **with the file**, at the removal — not one gesture
later on the run.

Also check the other order: remove the file, then place a **new** drone. A stale
`codeblock:last_file` opens the chooser.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28.

Earlier: fail — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28. That
is `B44`.

### D7 · A run cut short says *stopped* [B51, B12, B30]

**There is one route a player can perform.** `Drone.on_remove` has two callers —
the panel's **Stop** button and `register_on_leaveplayer`; nobody is there to
read the line the second sends, and the setter removes nothing since `F8`.

Write a program that builds long enough to interrupt — `cube(30,30,30)` at
codelevel 2, or a `for` loop of 200 `place()` calls — and run it. Cut it short
with the panel's **Stop**: left click with the setter, press **Stop**.

**Pass:**

- **Exactly one** chat line, not two and not none.
- It reads `Program '<file>' stopped:` and **not** *completed*.
- The tail is the **partial** count — nodes well below what the program asked
  for, and a shorter duration.

**Do it in French as well.** `Program '@1' stopped: @2` is
`Programme '@1' arrêté : @2`. The timeout line is *also* `arrêté` —
*Programme '@1' arrêté : il a épuisé ses @2 s de temps d'exécution* — and that
sharing was weighed and accepted, because that line says why. **If the two ever
read as one message, that is a finding.**

Also let a program **finish on its own** in the same session: it must still say
*completed*.

Result: pass — `8de3cea` plus a comment-only edit in `lib/drone.lua` · engine
version not restated · 2026-09-04 — *stopped* with a partial node count, and
*arrêté* in French.

---

## The drone HUD and panel

H1–H10. The specs reach the binding arithmetic (`limits_spec`), the pause field
(`stepper_spec`) and the panel's session routing (`forms_spec`), and **none** of
the drawing, the cadence, the colour, the toggle or the setter gesture.

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
the corner, tracking the run and gone at the end.

**Observed in the same run, not a `H1` failure:** a program running 387 s of
clock time spent about 18 s of server time, ~4.6%. That is `B46`'s arithmetic
behaving.

### H2 · The binding limit is the one it names, and it changes [F4, B26, B45]

Run two programs at the same codelevel: one that writes a great many nodes
quickly, and one that spends time without writing much.

**Pass:** in the panel, the first is closest on **Blocks placed** and the second
on **Server time used**; on the HUD the same two lead. **Map held cannot appear
at all** — neither compared nor listed on either surface.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — the binding limit is the
one the run is closest on, and *Map held* appears on neither surface.

### H3 · The toggle, whose choice wins, and where it lives [F4, B5, C18, F8]

0. **Where it is:** *Show the drone HUD* is on the editor's **Settings** panel,
   beside the default-block picker, with *Load program on exit* and *Save on tab
   switch*.
1. Untick it with a program running: the HUD goes at once and stays gone across a
   relog.
2. Set `codeblock_drone_hud = false` server-side. **Pass:** a player who has
   never expressed a preference sees no HUD; a player who ticked it **does**.

The `get_string` read is what makes case 2 expressible: `get_int` cannot tell an
unset key from a stored `0` (`B5`).

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — including case 0.

### H4 · The setter's left click always opens the panel [F4, F8, B39]

Left click with the **setter** in each of three states:

1. **No drone at all.** The panel opens and says *You have no drone*, offering
   only *Close*.
2. **An idle drone.** The panel opens naming the file it holds, with **Stop** and
   the close `x` — and **nothing is removed until Stop is pressed**.
3. **A running drone.** The panel opens with the three hard limits, **Pause**,
   **Stop** and the `x`. The run is **not** cancelled by opening the panel.

Then the button:

4. **Stop** on an **idle** drone: it goes, silently.
5. **Stop** on a **running** drone: it goes and the run is announced — **exactly
   one message**.

There is **one** destructive button on purpose. If two ever reappear, that is the
defect.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — all five cases.

### H5 · The panel's numbers, and its own refresh [F4, F8, B46]

With a long program running, open the panel and leave it open, at **codelevel 4**
where `max_nodes_written` is 5e7 — the case the number formatting exists for.

**Pass:**

- **Three rows** — blocks, server time, Lua memory — each with what the run has
  spent against its ceiling, in the units `minetest.conf` uses.
- The numbers **update while the panel sits open**, without touching anything.
- **Three rows, not four.** *Map held* is not listed, and there is **no *Will
  stop on…* line**.
- **Long counts are readable** — `1.2K / 10.0M`, not `1247 / 10000000`. The
  threshold is 10 000.
- **Each name is bold, and its description starts at the same left edge.** The
  description is allowed **two lines** and must not be cut off at the panel edge
  — check this **in French**.
- **The heading is bold and its state coloured** — `running` green, `paused`
  yellow, neither the amber nor the red used on the rows.
- **The *Server time used* description says it is not clock time.**
- **The percentage is coloured, and at most one thing is amber.** Amber marks the
  limit reached first; **red at 80% or more** and red wins.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — every point above.

### H6 · Pause and Resume [F4, F3, B46]

Pause a running program from the panel.

**Pass:** the drone stops building, the HUD says **paused**, the button becomes
*Resume*. Leave it a full minute, then resume: it carries on and **does not**
report running out of time. A second drone keeps its full pace while the first is
paused.

Then the `F3` interaction: pause a program **inside a `sleep(10)`**, wait past
the ten seconds, and resume. It resumes promptly rather than sleeping ten more.

**Two things this check must not report as bugs:**

- **A drone resuming from a long pause races before settling.** The map footprint
  decays over `server_unload_unused_data_timeout` (29 s), so a two-minute pause
  leaves nothing held. Not `B45`, **and not to be filed a third time**.
- **The time figure advancing at roughly a tenth of the clock.** *Server time
  used* is what the drone was given — 8 ms of a 90 ms step at codelevel 4. Check
  the row's describing line says so.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — Pause, Resume, the
`sleep` interaction, and the renamed row's describing line.

### H7 · Stop [F4, F8, B12, B30]

Press **Stop** on a running program, then on an idle drone.

**Pass:** the drone goes both times and the panel closes. On the running one,
**exactly one** message in chat. On the idle one, no message.

**This check counts the message; `D7` reads it.** Do not re-run this one for the
wording.

Result: pass — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — both cases.

### H8 · The panel over the editor, and a run that ends under it [F4, F8, B33, B29]

1. **Not performable as written.** A shown formspec takes the pointer, so **no
   tool can be used while the panel is open**: the setter's right click never
   reaches the game and the editor cannot be opened over the panel. **Do this
   instead:** close the panel and open the editor immediately, within the panel's
   refresh interval, then wait two seconds without touching anything. **Pass:**
   still the editor, unchanged. The panel's content arriving in its place is the
   defect.
2. Let the program **finish on its own** while the panel is open. **Pass:** it
   switches to the idle view rather than freezing on stale numbers or throwing.
3. **Not performable either, for the same reason.** Placing a drone is a tool
   use, so *with the panel still open* cannot be arranged. What it wanted to
   prove — that a panel left open describes a **replacement** drone under the
   same name (`B29`) — is pinned by `forms_spec`, which swaps the record under an
   open panel between two `get_form` calls.
4. Open the panel on an idle drone and press **Stop**. **Pass:** it closes; the
   next left click says *You have no drone*.

Result: partial — `8f5bb2e` · engine 5.17.0 · 2026-09-02 — **cases 2 and 4 pass;
cases 1 and 3 cannot be performed at all.**

**State: `unreachable`.** Cases 1 and 3 cannot be performed by hand at all and
no future run changes that, so nothing is owed. The `partial` result line above
stays as it was written. **On this form, "with the panel still open, do X with a
tool" is never a check.**

### H9 · Leaving and rejoining with a program running [F4]

Run a long program, disconnect while it runs, rejoin.

**Pass:** no orphaned HUD line, and no error in the log about a HUD element
belonging to a player who is gone.

Result: pass — `729c255` · engine 5.17.0 · 2026-08-29.

### H10 · A panel button responds to one click [B47]

With a long program running, open the panel and **click *Pause* and *Resume*
alternately, twenty times, at an ordinary pace** — not slowly and deliberately,
which is what hides it. Count the presses that do nothing.

1. **Pass: no dropped click in twenty, or at most one.** **A dropped click is
   silent** — `on_close` never runs, so the only evidence is the state word not
   changing.
2. **The same with the panel on an idle drone**, where the string is constant.
   **Pass: no dropped click at all, however fast.** The engine skips a
   byte-identical formspec, so this half is the control.
3. **The HUD is still readable at 1 s.** **Pass: it reads as live**, not as
   stuck.
4. **The panel and the HUD still agree.** A number differing between the two
   means `hud.tick`'s return value has stopped driving the panel.

**A fail on case 1 is not a new finding** — it widens `B47`, and the next
direction is *stop the self-refresh*, which closes it outright at the cost of the
liveness `F8` wanted.

Result: pass — `d8d44cd` · engine 5.17.0 · 2026-09-02 — **a few presses still
miss**, which is more than case 1 as written allows, and accepted on the author's
call. `B47` ships mitigated, not closed.

---

## Filesystem and example generation

F-1 – F-7. The `F-` prefix is **filesystem** and is unrelated to the
`F<feature>-<n>` series below.

### F-1 · `/codeblock generate` on your own files [B8, B15]

Run it as an unprivileged player, twice.

**Pass:** the examples appear the first time; the second run leaves existing
files alone, and needs no privilege for your own files.

Result: pass — `f274245` · engine 5.17.0 · 2026-08-27 — run as `/codegenerate`,
which `F10` later renamed.

### F-2 · `/codeblock generate <player>` [B8, C17]

Run it against another player's files, with and without the `codeblock`
privilege. **Run it once with the game in French.**

**Pass:** refused without the privilege; with it, the files land under the named
player, not the caller. Every line it prints is in the game's language.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — *"everything in french"*,
run as `/codegenerate`, which `F10` later renamed.

Earlier: partial — `f274245` · engine 5.17.0 · 2026-08-27 — privilege behaviour
passed, the words came out in English. That is `C17`.

### F-3 · A file that cannot be read [B7, B15]

`read_file` refuses in two ways and both must name the file.

**1. A precompiled chunk.** A file whose first byte is `0x1B`, **in bash**:

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

**2. A genuinely unreadable file. On Windows, in PowerShell:**

```powershell
$f = "<worldpath>\codeblock_files\<playername>\test.lua"
icacls $f /deny "$($env:USERNAME):(R)"     # now unreadable
icacls $f /remove:d $env:USERNAME          # put it back
```

**Write it that way and not the `cmd` way.** `icacls ... /deny "%USERNAME%":(R)`
is a `cmd.exe` line: PowerShell does not expand `%USERNAME%`, and the bare `(R)`
parses as a subexpression, so it runs `R` — an alias for `Invoke-History`. The
deny must name **your own** account, because the server runs as you, and the
`/remove:d` must go back.

**Pass:** the message names `test.lua` — no path, translated if the game is — and
no other file in the list is lost with it.

**The log half is unconfirmed.** `S7` moved `io.open`'s real reason to `warning`.
One grep of `debug.txt`, next time an unreadable file is to hand.

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — both cases. Case 2 reads
*"Impossible de lire le fichier ..."*: a translation key, and the filename rather
than the server's install layout. Case 1 passed at `246bb37` + `B40`'s fix.

Earlier: fail — `246bb37` · engine 5.17.0 · 2026-08-27 — case 1 run with a 168 MB
executable renamed `test.lua` took Luanti to ~14 GB and froze it twice. That is
`B40`, not a failure of the bytecode refusal. Case 2 was unchecked on 2026-08-28,
blocked by the `cmd` recipe.

### F-4 · A file too large to open [B40]

Put a large file — tens of megabytes, need not be valid Lua — into
`<worldpath>/codeblock_files/<playername>/` with a `.lua` name and click it.

**Pass:** refused by name and by size — *"File @1 is too large: over 128 kB"* —
and the editor carries on. **Fail is anything that reads it**: watch the server
process's resident memory.

Two more gestures: load the same file onto a **drone** (the refusal must name the
size); and check an ordinary save still works. Exceeding the ceiling from an
unmodified client cannot be reached at all, the engine dropping any submission
whose fields total 640 kB.

Result: pass — `246bb37` + `B40`'s fix · engine 5.17.0 · 2026-08-28 — the file
that took the server to 14 GB is refused instead of read. Which of the three
gestures were made is not recorded, so **the drone route is worth a pass of its
own**.

### F-5 · Every bundled example finishes at codelevel 2 [S6]

`/codeblock generate`, set yourself to **codelevel 2**, and run every example the
command wrote. Run whatever is in your directory rather than a count: `generate`
enumerates `lib/examples/`.

**Pass:** every one completes. None stops with *"Maximum number of nodes
written"*, *"Maximum running time"* or *"Memory limit exceeded"*.

**`game.lua` is the exception and must not be read as a failure.** It ends in an
unconditional `while` loop, so at codelevel 2 it stops with *"Maximum running
time"*. Judge the other thirteen.

**The counted margins**, so a failure can be read against them: `planet.lua` is
largest at roughly 353k of level 2's 5e5 nodes, then `death_star.lua` at ~207k;
everything else is under 100k. **A node-limit failure on a *third* example means
the counting method is wrong.**

**What the counting cannot see:**

- **Runtime, not nodes, may be what bites.** Level 2's `max_runtime_s` is 60 s.
  `torus.lua` issues ~63k single-node commands and `density.lua` ~45k loop
  iterations. A *"Maximum running time"* failure is a real result about that
  number, not a broken example.
- **Map footprint throttles rather than fails**, so `forest(100)` — ~340
  mapblocks over a 200-node square — should simply be slow. If it *errors*, that
  is a single request larger than the whole ceiling and a real defect.
- **`planet.lua` uses `random()`**, so its count varies; run it more than once.

**Codelevel 1 is deliberately out of scope**: `planet.lua` and `death_star.lua`
are both over its 1e5.

Result: pass — `cd13414` · engine 5.17.0 · 2026-09-02 — all fourteen complete at
codelevel 2, including under the same day's `max_runtime_s` cut to 60 s at that
level.

### F-6 · `game.lua` starts in the same direction every time [S8]

**Setup, because `generate` will not overwrite.** Remove your own `game.lua` in
the editor first, then run `/codeblock generate` for the fixed copy. Place a
drone with the **poser** on open ground with room above it. Codelevel 2 or above;
the program never terminates, so cut it short with the panel's **Stop**.

**Name the `vector3` version in the result line.** v1.5, v2.0.1 and v2.0.2 are
all installable and case 3 reads differently on v1.5; the matrix is in the
`run-tests` skill. The submodule pins **v2.0.2**, so that is what a local world
runs unless you swap the library by hand.

**Case 1 — the example itself. Pass:** the drone builds a 40-cube of cyan glass,
then **bounces around inside it**, leaving a trail of yellow lamps, and does not
escape it. No error in chat on the opening statements.

**Case 2 — the same run three times.** Stop it and run it again, then a third
time. **Pass: it sets off in the same direction every time** — up and away,
`+1 +1 +1`. **A fail reads as `1 1 1`, then `-1 -1 -1`, then `1 1 1`.** **Do not
stop at two runs** — two runs that differ could be read as a fresh drone facing
differently.

**Case 2 is a regression guard, not `S8` evidence.** `game.lua` reads
`dir = vector(1, 1, 1)` since `3548d58`, so it uses the constructor and never
touches a constant. **A pass here closes nothing.** Case 3 is the one that reads
on `S8`.

**Case 3 — the `S8` reproducer.** Put this in a file of its own and run it
**three times**:

```lua
dir = vector.one
print(dir.x, dir.y, dir.z)
dir.x = -dir.x
```

**Pass, on every version: `1 1 1` three times, and no raise.** The run's
`vector.one` is its own object, rebuilt with the constructor in
`snapshot_vector3`, so writing to it reaches nothing outside the run and nothing
after it.

**What a fail looks like on each version.** On v1.5, `1 1 1`, then `-1 1 1`,
then `1 1 1` — the module's own constant, shared by every player until the server
restarts. On v2.0.1 and v2.0.2, the third line raising `read only` — the freeze
showing through, which means the copy did not happen. **Record what it prints and
which version you ran.**

**This is `S8`'s only in-world reading.** The fix is probe-verified at the
library level on all three versions and unproven through a real drone.

Result: not yet run.

### F-7 · every shipped example still runs, after a dependency bump [C23, C24, S8]

**A standing check: run it after any `vector3` submodule bump, and before any
release.** `tests/preprocess_spec.lua` **compiles** every shipped example and
**nothing runs one**, so a compile cannot see a call that raises.


In a world at codelevel 3 or 4, on open ground with room around and above the
drone: run `/codeblock generate`, then open each generated example in the editor
and run it with the poser, one at a time. Remove your own copy of a file first if
`generate` left an older one alone (`F-1`). **Name the `vector3` version in the
result line.**

**Pass:** every example builds something and ends with the run's normal outcome.
`game.lua` never terminates and stops on *"Maximum running time"*, which is
expected.

**Fail:** any example stops with a Lua error on a line it did not choose to stop
on — report the file, the line and the message.

Result: pass — `72b614d` · engine 5.17.0 · 2026-09-07 — `vector3` v2.0.2, every
shipped example still runs after the bump. Run against a clean `72b614d`, before
the `S8` fix, so this reads on the bump alone.

Result: pass — `01b2af9`, record-only over `124d032` · engine 5.17.0 ·
2026-09-08 — `vector3` v2.0.2, every shipped example still runs with the `S8`
per-constant copy in place. The `A17` and `A18` edits were in the working tree
and reach no example: the three deleted exports have no caller anywhere in it,
and `A18` is editor code.

---

## Writing to the world

W1–W7. Map writes, plus `W7`, which is about what a program *says*.

### W1 · `place()` far from spawn [A4, S5, B25, B50, B51]

**Results in this entry run newest first.**

Fly a long way out, place a drone, and run a program that walks and places one
node at a time across several mapblocks **and back over ground it already
visited**.

**Pass:** no holes — **and the drone survives the run.** A drone that vanishes
from view part-way and reappears later is a **pass**: after `1b991ae` the view
going away is not an ending.

**Run it at codelevel 1 or 2, not 3 or 4.** What this check is *for* is the
per-resume memo reset, and the codelevel decides how often that runs:
`end_command` yields after **every** command while `pace_ms > 0`. That is also
the only pace at which the engine has time to unload the block the drone stands
in.

**Use the deterministic reproducer, not the loop:**

```lua
-- bbb.lua
forward(500)
sleep(20)
```

`forward` is a teleport, so the drone is 500 nodes out immediately, and
`sleep(20)` makes no call, so nothing calls `load_area`. **It must survive the
full 20 seconds and then finish normally.** The loop is a coin flip; run the
reproducer first.

```lua
-- aaa.lua
for i = 1, 50 do
  place(hues[1])
  forward(16)
end
```

**Three observations to record explicitly, not just the overall outcome.**

1. **Where the placed line stops, counted in multiples of 16.** Near **192–256**
   means the object was deleted. A full **400**, plus the line coming back, means
   only the *view* was lost and the run carried on unseen.
2. **Whether a chat line arrived, and how long after** the drone left the screen.
   **The pass is *no line at all*** before the program's own finish line.
3. **Whether a new drone can be placed immediately**, or the answer is *"Drone is
   busy, please wait!"*. **This is the expensive case.** A leaked record keeps
   `cor ~= nil` for ever and counts a phantom in `on_step`'s running total,
   shrinking every other drone's share of `server_step_budget_us` for the life of
   the world.

Past about 2000 nodes in one direction the program stops with *"The drone cannot
leave the world"*. **That is the world-edge guard working**, not a limit.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — **at all four
codelevels.** All three observations are answered: the line goes the whole way,
no chat line arrives before the program's own finish line, and a new drone places
immediately afterwards, so the leaked record is **ruled out**.

Result: **fail, with the three observations made** — `16cd05c` · engine not
recorded · 2026-09-03 — the discriminator run, twice, on a plain outward walk of
50 iterations with no return leg. The program was pre-`F11` and said
`place(blocks.obsidian)`, a category that no longer exists.

1. **The line stops at 352 nodes in the first run and 320 in the second** — 22
   and 20 mapblocks. **Two runs dying 32 nodes apart is the signature of a
   sampled race**, not of a fixed boundary: ~192 is where the drone becomes
   killable, and `deactivateFarObjects` samples every 2.0 s.
2. **Both chat lines arrived**, in French: *le drone a disparu*, then
   *programme terminé*. So the teardown path is intact.
3. **Not run.** A leaked record was left unlikely rather than ruled out.

**This run also observed `B51`**: *programme terminé* announced a run killed
roughly 48 blocks short of the 50 it asked for.

Result: **fail** — `16cd05c` · engine not recorded · 2026-09-03 — **at codelevel
1, the drone disappeared after 6–8 seconds.** Not an error, not a refusal, and
not *"The drone cannot leave the world"* — it vanished. Filed as `B50`. The
program was pre-`F11`: 25 × `place(blocks.obsidian)` and `forward(16)` out,
`back(2)`, then 25 × `place(blocks.brick)` and `back(16)`. Neither the commit nor
the engine version was stated; `16cd05c` was `HEAD` when the report arrived, so
read it as *at or about*.

Earlier: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — no
holes, at a codelevel above 2. Two 1000-node lines, the second offset so the
return leg re-crosses ~63 mapblocks.

Earlier: pass — `43e95a8` · engine not recorded · 2026-08-25 — where `S5`'s
measurements come from: **16.3 kB resident per mapblock** over a 400-block sweep,
and about **1700 loads a second** served.

### W2 · A node written into never-generated ground [A4]

Place a node in an area that has never been generated, leave, come back so the
area generates, and look.

**Pass:** the node is still there.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 —
mapgen does not overwrite it. `load_area` plus `set_node` makes the engine treat
the block as generated and leave it alone. That answers `A4`.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — the node was placed
**1000 nodes out** and survived the area generating on a return trip.

### W3 · A large bulk shape [A5, A15]

Run `cube(200, 200, 200)` **at codelevel 4** and watch the server.

**Pass:** the shape appears slab by slab and the server stays responsive. It must
not freeze — a 150-node cube stalled it for 0.44 s before shapes were sliced.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 —
**0.34 s**, server responsive.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — **0.27 s** at
codelevel 4. **The 0.07 s difference is not a finding**: neither figure was taken
under controlled conditions.

**What that shape costs.** Arithmetic over the source and one measured constant
(16.3 kB a block); the timing is the only measurement.

- **8,000,000 nodes**, **codelevel 4 only**: level 3's ceiling is 1e6 and the
  shape is refused there. Level 4's ceiling is 5e7, where the first refused cube
  is 369 on a side.
- **~2200 mapblocks emerged.** `SLICE_BLOCKS` is 16 and the cross-section ~169,
  so `layers` clamps to 1: **every slab is one mapblock thick and 169 across** —
  the "large in two dimensions" case slicing cannot reduce.
- **~36 MB pinned**, against 8192 blocks allowed at level 4, so it never
  throttles.
- **CPU:** 13 slabs, each a VoxelManip read, a full-volume fill and a write over
  ~692k nodes — about 18M Lua table stores.

**What nothing charges for.** Serialising ~2200 mapblocks into the map database
and pushing them to every client happen **outside the run and are charged to
nobody**. Neither was measured; noted under `S5`.

### W4 · An unknown block name warns, once [B49]

1. **A typo warns once and builds anyway.**

   ```lua
   for i = 1, 20 do place(colors.notablock) forward(1) end
   ```

   **Pass:** **exactly one** chat line, naming `notablock` and saying the default
   block was used instead, and a line of twenty default blocks. Not one warning
   per iteration, and no error.
2. **It is per run, not once for the server.** Without leaving the world, place a
   **second drone** on the same program: it warns on its own account. **No spec
   can reach this** — the flag is a closure upvalue in a file-local function.
3. **The accepted side effect.** A program that probes membership —
   `if colors[name] then ... end` with a name that is not there — also produces
   the one warning. Known and accepted (`B49`).

Run case 1 in French too.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — reported as a pass on the
check as a whole, the fix being `d8c32f7`.

### W5 · A drone that stands still far away keeps running [B52, B50]

Both cases start the same way: fly at least 300 nodes from anywhere a player is,
place a drone, then leave it alone — do not follow it, do not stand near it.

1. **`sleep` longer than the unload timeout.**

   ```lua
   forward(500)
   sleep(45)
   place(hues[1])
   ```

   **Pass:** after the sleep the block is placed and the run announces itself
   normally. The drone must not disappear silently at about 29 seconds, and no
   *le drone a disparu* line may arrive.
2. **A run left paused.** Start a long program that walks a long way out, then
   **Pause** it from the panel and wait more than a minute before resuming.
   **Pass:** Resume carries on from where it stopped, the panel still describes
   the same run, and the elapsed clock was not reset by a restart.

**The entity may well vanish from view in both cases** — the block under it
genuinely is unloaded — and that is not a failure. The run continuing and
finishing is the whole condition.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — both cases,
reported as a pass on the check as a whole. This is `B52`'s only in-world
evidence.

### W6 · The drone's entity goes away and comes back [B50, B29]

1. **Walk away from a running drone.** Start a long program, then fly a few
   hundred nodes away and watch the chat.
   **Pass:** the model disappears from view with **no chat line at all**, and no
   finish line. *The drone has disappeared, program stopped* cannot appear —
   `1b991ae` deleted the message and its `S()` key, so a line resembling it means
   a stale build. The panel and the HUD go on describing a running program.
2. **Come back.** Fly back to where the drone should be by now.
   **Pass:** the entity is there again, in the right place, with what it has
   built behind it. **One drone, not two** — the re-spawn uses the same serial,
   which is `B29`'s guard, so a second model beside the first is a defect.
3. **Place a new drone afterwards**, under the same name, once the program has
   finished.
   **Pass:** it places. *"Drone is busy, please wait!"* means a leaked record.
4. **`/clearobjects` does not end the program.**
   **Pass:** the model goes and comes back within about a second
   (`respawn_period_s`), and the program keeps running throughout. **A deliberate
   consequence of the fix**, recorded under `B50`.

Result: pass — `23f0227` · engine not recorded · 2026-09-04 — all four cases.
Case 2 is `B29`'s serial guard confirmed in its post-`1b991ae` form, where what
it guards is the replacement's object rather than its record.

### W7 · `print` sends every argument, in one line [B54]

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

**Pass: a bare `> `**, an empty separator line, and **not** `> nil`. `print()` in
real Lua is a blank line, and it still costs one command.

```lua
print("a", nil, "b")
```

**Pass: `> a nil b`** — the line does **not** truncate at the nil. That is what
reading the varargs with `select('#', ...)` buys, and `get_block()` answers `nil`
over ungenerated map, so a player prints a nil routinely.

**What separates a pass from *did not crash*: the boolean being visibly
present.** The broken build printed `> is: ` and stopped, with no error anywhere,
so *no error in chat* is not the check.

**The separator is checkable nowhere else.** The join is a **space**, not real
Lua's tab: Luanti's chat console has no tab stops and its wrapping breaks on
spaces. Check the wrapping on a narrow console **on an exception-only basis** —
say if it does not wrap.

**`error` was deliberately not widened** — real Lua's `error(message, level)` is
not variadic — so there is nothing to check there.

Result: pass — `2feadb1`, record-only over `24842d3` · engine 5.17.0 ·
2026-09-07 — all three programs: `> is: true` on one line with one space,
`print()` a bare `> `, and `> a nil b` with no truncation. **No exception was
reported against the space-joined line wrapping**, so the separator stands.

---

## Pacing, slabs and the footprint throttle

P1–P4.

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
ceiling `limits.hold` returns how long to wait. **Facing does not matter any
more**, and checking that it does not is half of this check (`B42`).

Result: pass — `febf16f` · engine 5.17.0 · 2026-08-28 — **the first measurement
of the throttle**: **93 s** against a predicted ≈80 s (512 mapblocks decaying
over 29 s is 17.7 a second; the shape emerges ~1877 with the first 512 free).

Result: pass — `6fea453` · engine 5.17.0 · 2026-08-28 — the re-timing that proved
`B43`'s fix, at codelevel 1, view distance 500: **78 s one way, 95 s the other**,
where a doubled emerge would have cost 183 s. Before the fix the same shape
spread **78 / 160 / 183 s** across three facings.

Earlier: fail — `246bb37` · engine 5.17.0 · 2026-08-27 — the drone died where the
ceiling exists to make it wait. That is `B42`.

**Two things recorded rather than filed.** The 95 s is 23% over the 78 s and the
emerge model does not explain it — the multipliers can only be 1, 2 or 4. And
only two of four facings were timed, at a different codelevel from the pre-fix
run. **Neither is `B43` returning.**

**Also observed, no id:** at codelevel 1, view distance 30, nothing of the shape
appeared until the drone was stopped; at view distance 500 it was visible as it
built. Most likely what the client drew.

### P4 · Several drones at once [A5]

Run four or more drones simultaneously.

**Pass:** they share one slice of each server step rather than taking one budget
each, and a waiting drone takes no share.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27 — four drones shared.

---

## Release and install

R1–R5.

### R1 · The archive contains no `tests/` [C16, C10]

**Read the top level, not a grep of the whole listing.** In bash:

```bash
git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u
```

**Pass:** no `tests/` directory, and `screenshot.png` survives. ContentDB builds
releases with `git archive`, and nothing in CI checks `.gitattributes`.

Result: pass — `afbe504` · engine 5.17.0 · 2026-08-28 — eleven top-level entries,
all player-facing, none of the record. **`C10` confirmed.**

Result: pass — `7dbe18f` · engine n/a · 2026-09-02 — re-checked after
`.gitattributes` changed at `60dc8dd`. The same eleven entries; `textures/`
shipped four PNGs with the two `.svg` sources excluded. No engine is needed: this
reads `git archive`, not an install. Whether the archive *loads* is `R2`.

**Both results are stale on the counts.** `textures/` now holds **seven PNGs and
two `.svg` sources** (`F11` and `F12`), and `lib/examples/` holds **fourteen**
(`tests.lua` deleted, `game.lua` tracked at `63c3c33`). The next run says whether
the new PNGs ship, whether `game.lua` ships with the other examples, and whether
the `.svg` pair still does not.

### R2 · A real install with the test flag set [C16]

**Build the archive** the way ContentDB does. In bash:

```bash
git archive --format=zip --prefix=codeblock/ -o /tmp/codeblock.zip HEAD
```

- **`git archive` archives a commit, not the working tree.** Commit first — and
  for the release itself pass the **tag**, not `HEAD`.
- **`export-ignore` is read from the `.gitattributes` at that revision.** A rule
  added but not committed does not apply.
- **`--prefix=codeblock/`** is a convenience: `mod.conf` sets `name = codeblock`,
  so the engine does not care what the directory is called.

Extract it into a game's `mods/` as a player would, set
`codeblock_run_tests = true`, and start. **The one dependency is real:**
`mod.conf` reads `depends = vector3`, installed separately from its own ContentDB
package — the copy under `tests/game/mods/` is `export-ignore`d and is not in the
archive.

**Pass:** the mod loads normally and logs *"codeblock_run_tests is set, but this
build ships no tests/ directory"*. **Fail is the mod refusing to load** — bare
`dofile`s of files the archive does not contain.

**Do it in a game that is not `codecube`.** `B38`, `B39` and `C18` were each
invisible there.

Result: pass — `7c5bceb` · engine 5.17.0 · 2026-08-28 — extracted into a game's
`mods/` beside `vector3`; loaded and warned. **`C16` confirmed.**

### R3 · The sky belongs to the game [C18]

Install into a game with an ordinary day/night cycle — anything but `codecube` —
and join. Then set `codeblock_flat_sky = true`, restart, join again.

**Pass:** the first join leaves the sky alone; the second holds daylight at noon
with sun, moon, stars and clouds gone. The setting is read once at mod load, so
**a restart is part of the check**.

Result: pass — `326f739` + uncommitted fixes · engine 5.17.0 · 2026-08-28 — both
positions.

### R4 · A brand new world hands out the right codelevel [S6]

`register_on_newplayer` is the only place a codelevel is written, so **a world
with any history proves nothing here**. Create a fresh world each time.

1. **Singleplayer, fresh world.** `/codeblock level` with no argument.
   **Pass: 3.**
2. **A server, fresh world, a joiner who has never connected. Pass: 2.**
3. **Either, with `codeblock_default_auth_level = 4`** and a restart.
   **Pass: 4** — the setting wins over both built-in defaults.
4. **An existing player in an existing world, after upgrading the mod. Pass:
   unchanged** — an upgrade must neither demote nor promote anyone.

Read the log once while you are there: `codeblock_default_auth_level = 9` must
warn and fall back rather than giving a player nil limits.

**State: `stale`.** `check_auth_level` reads
`codeblock.config.default_auth_level` at call time rather than capturing it
(`A17`), and `lib/config.lua:137` calls it while validating the setting that
assigns that field at line 142. So the fallback return is `nil` on that one
call, by design and unused there. Every case below reads on the new contract and
the pass predates it.

**This is the only in-world evidence for the `A17` behaviour change.** The
out-of-range log line is the case that touches it directly.

Result: pass — `cd13414` · engine 5.17.0 · 2026-09-02 — all four cases, and the
out-of-range guard read in `debug.txt`:

```
2026-09-02 11:50:08: WARNING[ServerStart]: [codeblock] setting
codeblock_default_auth_level is not a codelevel from 1 to 4; ignored
```

### R5 · An old `vector3` is named in the log at mod load [S9]

`init.lua` logs one `core.log('warning', ...)` when the installed `vector3`
exposes its method table, detected by `vector3(1, 1, 1).__index ~= nil`. **No
spec can reach it:** it fires at mod load before any spec runs, and the fixture
pins v2.0.2, where the branch is never taken.

**Swap the submodule by hand and start a world each time.** In bash, from the
repository root:

```bash
git -C tests/game/mods/vector3 checkout 1662164   # v1.5
git -C tests/game/mods/vector3 checkout 5077617   # v2.0.1
git -C tests/game/mods/vector3 checkout fc8a5b8   # v2.0.2, the pin
```

Start a world on each and read `debug.txt`. **Put the pin back before running
the suite.**

**Pass:** on v1.5 and v2.0.1, exactly one `[codeblock]` warning, naming the
guessed version and saying *Install vector3 2.0.2 or newer*. On v2.0.2,
silence — a line on every start that reports nothing is noise.

**Read the version it guessed.** v1.5 and v2.0.1 are told apart by whether the
constants iterate, so a wrong name means the guess is wrong, not the detection.

Result: not yet run.

---

## Per-feature checks

Added as each feature lands, for the paths it puts beyond the specs.

**A check here is named `F<feature>-<n>`**, numbered in the order they appear
below and **never renumbered**. A feature with one check still gets the `-1`.
**`F<feature>` on its own always means the feature**, whose entry is in
`ROADMAP.md`.

### F1-1 · The Settings panel [F1]

Open the editor and click **Settings**, beside **Blocks**, the category selector
and **API**.

**Pass:** the panel draws the chosen block's texture plus a button reading
**`Default block: <name>`**; clicking it opens and closes a `textlist` of names;
selecting a row changes both the name and the texture; `air` is offered and
selectable; switching panels and back leaves it usable.

**The rows are names only.** A `scroll_container` of `item_image_button` rows was
abandoned — this formspec is legacy coordinates, where a container clips to its
own rectangle and a button inside one gets a hit area that does not match where
it is drawn.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F1-2 · The preference survives a relog [F1]

Pick a block, close with **ESC**, disconnect, rejoin, run a program whose
`place()` names no block.

**Pass:** the chosen block is what gets built. The meta write happens the moment
a row is selected, not on form close.

Then change the preference mid-run: **pass** is that the running program keeps
building the block it started with, the preference being read once per run.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F3-1 · `sleep(seconds)` in a running world [F3]

Run a program that places a node, calls `sleep(1)`, and repeats — at codelevel 3
or 4, where `pace_ms` is 0 and the wait is the only thing pacing it. Then run one
asking `sleep(1e9)`.

**Pass:** the drone visibly builds one node a second; the server stays responsive
and any other drone keeps its own rate while this one waits; and the unbounded
ask ends the program with the usual timeout message rather than parking the drone
for ever.

Result: pass — `246bb37` · engine 5.17.0 · 2026-08-27.

### F9-1 · The words on the panel and the HUD [F9, B46]

Everything here is words and placement, so **the suite cannot see any of it**. Do
this **in French as well as English**.

1. **The HUD's third line reads *CPU time*, not *CPU*** — *Temps CPU* in French —
   and the five-line block still fits the corner without wrapping.
2. **The idle panel reads `<program> : idle`**, filename bold, state bold, **no
   colour**. *Drone idle, holding …* is gone.
3. **A running panel's heading carries the elapsed time in parentheses**,
   immediately after the state word and **bold with the rest of the line** — only
   the state is coloured.
4. **It counts up while the panel sits open**, matches a stopwatch, and **stops
   dead while the run is paused**. Press *Resume* and it carries on from that
   number rather than jumping the minute forward.
5. **It reads `43s`, then `6m 27s`, then `1h 12m`** as the run passes a minute
   and an hour.
6. **The duration and the `Server time used` row disagree, by a lot** — some 4.6%
   of it at codelevel 4 — **and that is the pass**. Check the row's describing
   line still says it is not clock time.
7. **A long filename does not push it off the panel.** Open a program at the
   15-character cap, in French.
8. **When the run ends, the `duration:` in the chat message matches the last
   number the panel showed.** They are one call to `Drone.elapsed_us`; a run
   paused part-way is the case that tells them apart.

Result: pass — `029fab9` · engine 5.17.0 · 2026-09-02 — cases 1–3 and 5–8 in both
languages.

Result: pass — `dc09d48` · engine 5.17.0 · 2026-09-02 — case 4 only, in its
rewritten form: the number stops with the pause and carries on from there.

### F10-1 · A fresh player is given nothing [F10, C21, C18, B39]

Take a world this player has **never joined**, in a game that is **not**
`codecube`, and join it.

1. **No tools.** The inventory is exactly what the game gives a new player, and
   neither the Drone placer nor the Drone setter is in it.
2. **No privileges.** `/privs` lists what the game grants; **`fly`, `fast` and
   `noclip` are not there** unless the game or the server granted them itself.
3. **One chat line, naming both routes** — `/codeblock tools` and the creative
   inventory — and nothing else.
4. **It is said once.** Quit and rejoin: no second line. **Do this in French as
   well.**

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03 —
cases 1 to 3, the chat line arriving despite `register_on_newplayer` firing
before the client has finished loading. Case 2 is **`C21`'s only possible
in-world evidence**.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — re-affirmed once `F10`
was committed at `b23a8bc`.

Result: pass in French — commit not restated · engine version not restated ·
2026-09-04 — *"F10: french works ok"*, read on a French client, which closes case
4's French half. The strings are unchanged since `b23a8bc`.

### F10-2 · `/codeblock tools` [F10, B16, B39]

1. **It hands both tools over.** Run it with an empty inventory: the Drone placer
   and the Drone setter appear, and nothing else changes.
2. **It does not duplicate a tool already carried.** Run it again: still one of
   each. Then **park one tool in the craft grid** and run it again — still one of
   each. That is `B39`'s rule, which the command reaches far more easily than the
   once-per-join handout ever did.
3. **A full inventory is refused cleanly.** Fill `main` completely and run it:
   the message says what happened, and the player is not left holding one tool of
   two.
4. **For another player it needs the priv.** Without `codeblock`,
   `/codeblock tools <someone>` is refused; with it, the tools land under the
   named player and not under the caller.

Result: pass — `b9143b0` + uncommitted `B48`/`F10` · engine 5.17.0 · 2026-09-03 —
replies in English on a French client, which was the state at the time.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — re-affirmed at the
committed code, `b23a8bc`.

Result: pass in French — commit not restated · engine version not restated ·
2026-09-04 — covered by *"F10: french works ok"*; the replies read in French.

### F10-3 · The two renamed subcommands [F10, B8, B9, C17]

`/codelevel` and `/codegenerate` are gone, deliberately and with no aliases.

1. **`/codeblock generate` works on your own files with no privilege**, and a
   second run leaves existing files alone.
2. **`/codeblock generate <player>` needs the priv**, and with it the files land
   under the named player. **Run this one in French.**
3. **`/codeblock level` is privileged either way**, including for yourself. A
   player without `codeblock` cannot raise their own level (`B9`).
4. **Bare `/codeblock`, and a subcommand that does not exist**, each print the
   three usages.
5. **The old names are gone** — `/codelevel` reports an unknown command.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — at the committed code,
`b23a8bc`.

### F10-4 · A dropped tool can be recovered [F10]

The `on_drop` stubs are removed, which is only safe because the command exists.

1. **Drop the Drone setter.** It leaves the inventory and lands in the world.
2. **Get it back with `/codeblock tools`.** Both tools are in the inventory
   again, one of each.
3. **The dropped item is still a working tool** if picked up instead.

Result: pass — `16cd05c` · engine 5.17.0 · 2026-09-03 — at the committed code,
`b23a8bc`.

### F11-1 · The category selector, in French [F11, B37]

**Run this one first.** Its failure would mean converting the editor out of
legacy coordinates.

Play on a **French** client. Open the editor.

1. **Move the category selector to *Verre*, then press `Blocks`.** The **glass**
   panel must open — not the colours panel, and not nothing.
2. **Press `API`.** The API panel opens.
3. **Press `ESC`.** The editor closes and **the open tabs are still saved**.
4. Repeat 1 in **English**, moving it to *Glass*.

**Pass:** the selector switches the panel in both languages, and ESC still saves.

**If it works in English and does nothing in French, that is a finding:** the
client is returning the *displayed* text rather than the stored item. The fix
would be formspec-version-4 `index event` (`lua_api.md` 5.17.0 line 3579), which
this form cannot use in legacy coordinates.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all four cases. **A
legacy dropdown returns the stored item and not the displayed text**, so the
editor does not have to leave legacy coordinates.

### F11-2 · The help row's geometry [F11, F1]

Look at the top right of the editor, in **English and in French**, whose words
are longer.

**Pass:** `Blocks`, the selector, `API` and `Settings` sit flush on one row, the
same height, none overlapping another, and no label clipped.

**A legacy button's `W` is short by a fixed 0.2 units and a dropdown's is not**,
which is the trap the whole row is built around.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — flush in both languages,
nothing clipped and nothing overlapping.

### F11-3 · The mod installs into a game that ships neither `default` nor `wool` [F11, C16, C10]

Install the mod, plus `vector3`, into a third-party game from ContentDB that
ships neither `default` nor `wool`. Start a world, get the tools with
`/codeblock tools`, place a drone and run a program that places a block.

**Pass:** the game starts, the mod loads with no dependency error, and the block
lands. **Anything in `debug.txt` naming `codeblock` is worth reading** even on a
pass.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the mod loads and builds
in a third-party game that ships neither `default` nor `wool`.

### F11-4 · Retired 2026-09-07 — superseded by `F12-1` and `F12-2` [F11, F12]

**Do not run this one.** It asked for a row of the 33 solids reading as their
hexes and a wall showing the tile's grain; `F12` moved the hexes to `F12-1` and
the wall to `F12-2`, both of which passed at `8e6350f`. The id is kept so nothing
that cites it dangles.

The author ran it after the retirement and reported a pass — `1aa2f29`, engine
5.17.0, 2026-09-07 — against criteria that have since been replaced. It is not
written as a `Result:` line and does not revive the entry.

### F11-5 · Coloured glass and coloured lamps [F11]

1. **Build a glass wall** of two or three colours, with light behind it. Join two
   faces at a corner.
2. **Put one lamp in a dark room**, then swap it for a different colour.

**Pass:** the glass tints what you see through it and **does not go opaque where
two faces meet**; a lamp lights the room.

**Every colour of lamp lights the room identically, and that is correct.**
Luanti's light carries no hue, so a blue lamp gives white light.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the glass tints, the
corner does not go opaque, and a lamp lights a dark room.

### F11-6 · The blocks are silent, deliberately [F11]

Walk on one, dig one, place one, and listen.

**Pass:** nothing. **None of the 105 has a `sounds` field**, on purpose: every
`node_sound_*_defaults()` belongs to a game.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — silent, and read as
intended rather than as broken.

### F11-7 · Digging, in a game that is not `codecube` [F11, B48]

Dig one of the mod's blocks **by hand** and then **with a pick**, in a game that
provides its own tools.

**Pass:** the block breaks in a sensible time by each route and drops itself.
Watch for the block reappearing after it looked broken — client-side dig
prediction disagreeing with the server.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — by hand and with a pick;
the block drops itself and does not reappear.

### F11-8 · The creative inventory [F11]

Open the creative inventory in a game with a small item set, and search
`codeblock`.

**Pass:** 105 items with descriptions that read sensibly, and the mod's section
does not swamp the game's own. **`F12-1` counts them.**

**The descriptions read *"Bloc red"* on a French client, and that is
deliberate** — the colour name is the identifier a program types.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the descriptions read
sensibly and 105 items do not swamp a small game's own item set.

### F11-9 · `is_ground_content = false` survives mapgen [F11]

In a game that **generates terrain** — not a flat or singlenode world — build
something with the mod's blocks, then travel far enough that the area unloads and
come back. Better still, build near a cave or an ore-bearing depth.

**Pass:** the build is intact.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — intact after the area
unloaded and came back.

### F11-10 · A real game mod calls `register_blocks` [F11]

**The mod is at `../codeblock-test-mod`.** Copy the whole folder into a world's
`worldmods/`, a game's `mods/` or `%APPDATA%\Minetest\mods\` and enable it beside
`codeblock`. Its folder name does not matter — `mod.conf` declares
`name = codeblock_test`.

**It is outside this repository on purpose and is not versioned by anything.**
`tests/game/mods/` is all-enabled, so a mod registering a category there would
change `api.names()` and the palette underneath every spec run. **If the
directory is lost, rebuild it from this:** three files. `mod.conf` —
`name = codeblock_test`, `depends = codeblock`, that dependency being what puts
`register_blocks` in place before it runs. `init.lua` registers three nodes of
its own — `codeblock_test:red`, `:green`, `:blue`, each
`codeblock_block.png^[multiply:<hex>`, so it drops into any game — then makes the
five calls below. `README.md` is the install and pass note. The bad and late
calls sit behind `codeblock_test_bad_calls`, default true.

1. **A good call.** `register_blocks('wool', {red = …, green = …, blue = …})`,
   three entries so `ramp.wool(v, 1, 3)` in `F12-6` walks all of them.
   **Pass:** `debug.txt` says `[codeblock] the game added 1 block category`, and
   the category appears in the sandbox, in the editor's block picker and in the
   help panel's selector, showing its **raw** name.
2. **A bad call.** Three of them: `'bad name'`, not an identifier; `'colors'`,
   already taken; and `'ghost'` with
   `{missing = 'codeblock_test:no_such_node'}`.
   **Pass:** each is refused with a line in `debug.txt` **naming your mod, the
   name and the rule**, and the server keeps running.
   **Count four lines, not three.** `'ghost'` produces two — the entry refused
   for naming a node no mod registered, then the category refused for holding
   nothing that can be placed. A bad entry is dropped by name and the rest of the
   category still installs, so a category whose every entry was dropped has to be
   refused separately.
3. **A late call**, from inside a `core.after`.
   **Pass:** it is **refused** and logged, and `register_blocks` returns
   `false` — not accepted, not queued, and not merely warned about.
   **The line reads `mod ?`, and that is correct.**
   `core.get_current_modname()` answers nil outside mod load, so the fallback
   shows; this is not fixable from inside `register_blocks` and has no finding
   id. **The pass here is `the late call returned false`.**

Result: pass — `2feadb1`, record-only over `24842d3` · engine 5.17.0 ·
2026-09-07 — all three cases, and `lib/blocks.lua`'s only in-world evidence. The
good call logged its line and the category appeared everywhere; the three
refusals produced **four** lines; the late call was refused and returned `false`,
with `mod ?` reading as intelligible rather than as a trap.

### F11-11 · A registered category reaches `place()`, `get_block()` and player meta [F11]

With the mod from `F11-10` installed, which offers `wool` with `red`, `green` and
`blue`, so the programs below run verbatim.

1. Run `place('wool.red')`. **Pass:** the node lands.
2. Print `get_block(0, 0, 1)` from one step behind it, then move onto it and
   print `get_block()`.
   **Pass:** both answer the name for that node — **not `false`**, which a
   load-time snapshot of the reverse map would have given for every
   game-registered node, and **not `nil`**, which a missing `load_block` would
   give.
3. **Pick `wool.red` as your default block** in the editor's *Settings* panel,
   disconnect and rejoin.
   **Pass:** the dotted key survived in player meta as `default_block`, and a
   bare `place()` builds it.

**No spec can make a read land inside the world**: `lib/commands.lua` captures
`core.get_node` at load, and a probe at the origin at mod load dies inside
builtin with `bad argument #1 to '__index'`, content ids not being cached yet.

Result: pass — `2feadb1`, record-only over `24842d3` · engine 5.17.0 ·
2026-09-07 — all three cases. `get_block()` answered the category's own name and
not `false` from both positions, and the dotted key survived a rejoin.

### F12-1 · 105 nodes register, and the picker shows them in palette order [F12]

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

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all three cases. The five
neutral hexes `#ffffff #c0c0c0 #808080 #404040 #101010` are accepted as they are.

### F12-2 · A lamp wall shows the grid; a solid wall shows nothing [F12]

1. **Build a wall of one lamp colour**, several blocks each way, and stand back.
   **Pass:** the grid is visible enough that individual blocks read as blocks,
   and faint enough that it is not a pattern you look at.
2. **Build the same wall in the matching solid** and stand back.
   **Pass:** a flat wall with no node-edge definition reads acceptably in a
   build.
3. **Put the two walls side by side** and look at the corner where they meet.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — the lamp grid reads as
blocks without becoming a pattern, and the flat solid wall reads acceptably.
**The flat pure white tile stays and the question is closed**; `ROADMAP.md`
records it under *other decisions*.

### F12-3 · `get_block` and `is_block` answer over real map [F12, F13]

In a game with **ungenerated map** you can reach — not a fully pre-generated
world.

1. Place one of the mod's blocks, move the drone onto it, and
   `print(get_block(), is_block(colors.red), is_block(colors.blue))`,
   substituting the colour you placed.
   **Pass:** the block's name, then `true`, then `false`.
2. Move the drone onto a node the game provides that no program can place, and
   `print(get_block(), is_block(colors.red))`.
   **Pass:** `false`, then `false`.
3. Point the drone at map the engine has never generated, and
   `print(get_block(), is_block(colors.red), is_block(colors.typo))`.
   **Pass:** `nil`, then `false`, then `false`.
   **The third is the one worth watching.** `colors.typo` is `nil` and so is the
   read, so the guard that stops `nil == nil` reading as `true` is what makes it
   `false`. Expect one chat line naming `typo` as an unknown block; that warning
   says *the default block is used instead*, which is a known imprecision for
   `is_block`, not a fail.

**What distinguishes a pass from *did not crash*: `false` and `nil` must be
different answers.** If the unplaceable node in (2) also reads `nil`, the
`load_block` call is not happening and every read is coming back `ignore`.

**`nil` in (3) is permanent and correct.** `core.load_area` does not run mapgen.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all three cases, with
`false` and `nil` coming back as different answers, and `colors.typo` reading
`false`.

### F12-4 · The read offsets turn with the drone and move nothing [F12, F13]

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
`place()` lands **where it would have landed before the reads**.

Result: fail — `8e6350f` · engine 5.17.0 · 2026-09-07 — **the check could not get
past its own first line.** The `print` gave the loop counter and stopped, with no
error, and writing it as one concatenated string raised *attempt to concatenate a
boolean value*. That is **`B54`**. **Nothing was learned about the rotation.**
Kept because it is how `B54` was found.

Result: pass — `2feadb1`, record-only over `24842d3` · engine 5.17.0 ·
2026-09-07 — the re-run, in full: the wall reported at exactly one facing with
`is_block` `true` there, and the `place()` landing where it would have before.

### F12-5 · A ramp reads as a gradient, and the other ramps strobe [F12]

```lua
for i = 1, 20 do place(ramp.hues(i, 1, 20)); up(1) end
```

**Pass:** the column walks the colour wheel once, smoothly, and the first and
last blocks are visibly different colours.

Then the same loop with `ramp.colors`. **Pass:** it **strobes** — light, plain,
dark inside each family in turn. That is correct: `colors` is ordered by family
rather than by lightness, and `ramp.hues` is the one that reads as a rainbow.

Finally the clamp: `ramp.hues(-5, 1, 20)` and `ramp.hues(99, 1, 20)`.
**Pass:** the first and last hue, not a wrap round to the other end.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — `ramp.hues` reads as a
gradient, `ramp.colors` strobes as designed, and the clamp does not wrap.

### F12-6 · A game-registered category gets a ramp of its own [F12, F11]

With the mod from `F11-10` installed, so it is cheapest run in the same session.
Its category is `wool` with three entries.

1. `print(ramp.wool(1, 1, 3))`, then `2` and `3`.
   **Pass:** `wool.blue`, `wool.green`, `wool.red` in that order — the flat keys
   `place()` takes, alphabetical, because that is the only order a registered
   category has.
2. **Open the help panel's *Choosing blocks* group.**
   **Pass:** `ramp.<name>` is listed beside `ramp.hues`, `ramp.colors`,
   `ramp.glass` and `ramp.lamps`, and its text says the order is alphabetical and
   therefore a lookup rather than a gradient.

Result: pass — `2feadb1`, record-only over `24842d3` · engine 5.17.0 ·
2026-09-07 — both cases.

### F14-1 · The API help panel lists the new views and `ramp.of` [F14]

`api.to_hypertext` runs **only** in a running world, so what the panel renders is
observable nowhere else.

1. **Open the editor's API help panel and find the *Choosing blocks* group.**
   **Pass:** `light_hues`, `dark_hues` and `neutrals` are listed beside `hues`,
   each with its text, and `ramp.of` is listed beside `ramp.hues`, `ramp.colors`,
   `ramp.glass` and `ramp.lamps`. Nothing is truncated, and the group scrolls to
   the bottom with the new rows in it.
2. **Read `ramp.of`'s description.** **Pass:** it says it takes a list.
3. **Then run `F14-3`.**

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — all rows listed with
their text, nothing truncated.

### F14-2 · Reading past the end of a palette view is silent [F14]

**No spec can ever replace this one, so do not delete it as redundant.**
`lib/sandbox.lua` binds `chat_send_player` as a load-time local, so a spec cannot
intercept the misspelling report, and a *nothing was raised* assertion would pass
against a reporting version too.

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

   **Pass:** the misspelling is reported once, naming the wrong name. **One of
   the two must report and the other must not.**

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — both cases.
`dark_hues[99]` built the default block with no chat line, and `colors.gray` in
the same session was reported once by name.

### F14-3 · A gradient built through a view actually lands [F14]

1. Run this program:

   ```lua
   for i = 1, 10 do place(glass[ramp.of(dark_hues, i, 1, 10)]) up() end
   ```

   **Pass:** ten glass blocks in a column, `dark_pink` at the bottom through to
   `dark_violet` at the top, **all see-through**.
2. **Look at the colours, not the count.** **Pass:** the ten differ from each
   other, and from the same loop over `hues`, which gives the plain shades. Ten
   identical blocks, or ten plain ones, is a fail even though nothing crashed.

Result: pass — `8e6350f` · engine 5.17.0 · 2026-09-07 — ten see-through glass
blocks, `dark_pink` to `dark_violet`, visibly different from each other and from
the same loop over `hues`.

---

Sources: `AUDIT.md` (per-finding reasoning), `ROADMAP.md` (the `F` entries and
*what ships broken*). When a check moves, update the finding entry too.
