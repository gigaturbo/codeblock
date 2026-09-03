# TODO

The inbox and the wanted-features list for the CodeBlock mod. One line each,
mostly features. The author writes here; `project-manager` rewords a line when a
discussion changes what it means, and adds the lines that come out of an answer.

**A `FIX:` or `BUG:` line here is a hand-off.** It gets a finding id in
`AUDIT.md`, with the reasoning and the state; the line stays here until the
author deletes it. What the work involves is in `ROADMAP.md`; what shipped is in
`CHANGELOG.md`. Completed items are not kept here — they are in those two files.

Finding ids are never renumbered. `F` ids are features, this project's own.

# v1.0.0

Features

- [x] FEAT: Make a UI for drone info : running or not, blocks placed, allow pause,
      start, cancel, etc — includes showing the program's budget while it runs,
      not just its totals at the end — shipped as `F4`, made readable by `F8`,
      and playtested 2026-09-02: eight of nine `H` checks pass. The three
      wordings that run asked for are `F9` below (audit F4, F8)
- [x] FEAT: the panel and HUD in the words asked for on 2026-09-02 — HUD `CPU`
      becomes *CPU time* / *Temps CPU*; the idle panel reads `<program> :
      inactif` like the running one; the heading carries the run's clock time,
      `<program> : <state> (<duration>)` — shipped the same day with four gates
      green, the duration bold and just after the state on your second look;
      playtest `F9-1` passed 2026-09-02 at `029fab9`, both languages (audit F9)
- [x] FEAT: stop the panel's elapsed clock while a run is paused — asked for
      2026-09-02 on seeing `F9` in a world, reversing that feature's decision
      that it should keep counting. Built the same day with four gates green:
      `Drone.elapsed_us` is now the one answer both the panel and the finish
      message read, and `Drone.toggle_pause` the only writer of `paused`.
      Playtested the same day: `F9-1` case 4, rewritten and passed (audit F9)
- [x] BUG: buttons on the drone panel are sometimes unresponsive, a second click
      needed. Cause confirmed in the engine source: the 0.5 s refresh makes the
      client destroy and rebuild every element, and a button's press lives on
      the object it destroys, so a click held across a refresh is dropped with
      no error. Fixed 2026-09-02 the way you asked: the beat is 1 s, HUD and
      panel together since they share the one constant. It halves the dropped
      window rather than closing it — about one click in ten, was one in five —
      so playtest H10 is what says whether that is enough (audit B47)
- [x] BUG: opening several programs marks every one but the active tab as
      modified, without a keystroke — reported 2026-09-03. `read_file` opened
      the file `'rb'`, so a CRLF file kept its `\r\n` while the client's textarea
      returns LF, and F7's dirty check compared unequal for anything still
      carrying its original line endings. All fourteen bundled examples are
      CRLF, which is why the four files you had already saved never showed the
      mark and `plot2D.lua` showed it every time. Fixed the same day, one line
      in `lib/filesystem.lua`, five gates green, **committed as 4179877**;
      playtest E16's new case passed 2026-09-03, so the fix is confirmed in a
      world (audit B48)
- [x] BUG: a block name that does not exist falls back to stone without an error
      — reported 2026-09-03. `blocks`, `plants` and `wools` are name-indexed, so
      `blocks.notablock` is just a missing key and reads nil, and `placement`
      cannot tell that nil from the one you get for a bare `place()`: the default
      block was substituted and nothing said so. It hit `place`,
      `place_relative` and all eight shape commands. Fixed the same day where the
      name is *read* rather than where the block is placed, so the message can
      name what you typed: `blocks`, `plants` and `wools` now warn **once per
      run** and the program carries on with the default block, since you asked
      for a warning and not an error. One accepted side effect —
      `if blocks[name] then` as a membership test costs one chat line per run.
      Gates green over the whole tree with 13 new env_spec cases, **committed as
      d8c32f7**, and playtest W4 passed 2026-09-03 at 16cd05c — so the
      once-per-run warning is confirmed in a world, which no spec could do
      (audit B49)
- [x] BUG: the drone disappears at codelevel 1 — reported 2026-09-03 from the W1
      re-run: `aaa.lua` places obsidian and brick along two 25-step lines, and
      after 6–8 seconds the drone vanished. No error, no refusal, and not the
      "cannot leave the world" stop. Filed as B50, and the cause is now read out
      of the engine source: the drone entity is `static_save = false`, so Luanti
      deletes it as soon as the mapblock under it leaves server memory, and
      nothing keeps the drone's *own* block loaded — only the block it writes
      into. Past about 192 nodes the client is no longer keeping it alive either.
      Time is what matters rather than distance, which is why levels 3 and 4
      finish before the engine's 2 s sweep ever sees them and why W1's old passes
      could not have caught it. **You chose the fix on 2026-09-03, and it is a
      fourth option rather than either of the two put to you: decouple the drone
      record from its entity**, so the step driver moves to the globalstep
      register.lua already has, `on_deactivate` only drops the view, and the
      entity comes back with the same serial when the block does. It closes B52
      as well, and it saves a sleeping or paused drone, which neither of the
      other options did. **Written and committed the same day as 1b991ae**, with
      the gates green — 474 in-engine assertions, 0 failed, 0 xpass — and
      **nothing about it has been played yet**: W1, W5 and W6 are written and
      unrun, and they are the only evidence it will ever have. You also
      supplied a much better reproducer — `forward(500)` then `sleep(20)` kills
      it in one to two seconds every time, where the loop was a coin flip.
      Level 2 genuinely depends on
      singleplayer versus dedicated, and the other levels are still unreported.
      Your two discriminator runs on 2026-09-03 confirmed it: both chat lines
      arrive, so nothing is being swallowed, and the obsidian stopped at 352 and
      320 nodes. That spread is the point — 192 is where the drone becomes
      killable rather than where it dies, and two runs 32 nodes apart is a
      sampled race. One observation still owed, one gesture: after the drone
      goes, try to place a new one. If it says "Drone is busy, please wait!" the
      record has leaked (audit B50; playtest W1)
- [ ] BUG: a run that was cut short says "completed" — found 2026-09-03 while
      diagnosing B50, not reported. Drone.finish has no word for it, so a run you
      stop with the setter says the program completed, with a node count nowhere
      near what it asked for. **This is the only one of the three still open, and
      since 1b991ae it is the only remaining path to the wrong word** — the
      mid-flight case went with that fix, along with the "drone a disparu" line
      it used to pair with. No fix is chosen; a new word means a new S() key and
      its .tr lines. **You have seen it**: your discriminator run showed "le drone a disparu" and then
      "programme terminé", one after the other, about a run killed 48 blocks
      short of the 50 it asked for. The two lines contradict each other
      (audit B51)
- [x] BUG: a drone standing still far from you dies at about 29 seconds — found
      2026-09-03 the same way. It survives most fixes to B50 — `load_area` does
      not reset the mapblock's usage timer, so the block is unloaded on
      `server_unload_unused_data_timeout` regardless of the drone standing in it.
      `sleep(30)` out at 300 nodes, or a run left paused, both reach it — and
      both are things the mod invites you to do. **The fix you chose for B50
      does close it**, which is one of the two reasons it was chosen over the
      others, and it is **committed as 1b991ae**; playtest W5 is the check this
      has never had, in either state, and it is still unrun (audit B52)
- [ ] FEAT: Make possible to change codelevel while running a program (audit F5)
- [x] FEAT: stop forcing the two tools into every joining player's inventory —
      settled 2026-09-03 as `F10`, your choice of the two: a command, not a
      setting. `set_tools` and its join callback go, the tools become droppable,
      and `/codeblock tools` hands them out on demand; `/codelevel` and
      `/codegenerate` become `/codeblock level` and `/codeblock generate` with
      no aliases, since the rename is free before the tag. A first-join chat
      line names the command and the creative inventory. Written into
      `lib/register.lua` with the gates green and **committed as b23a8bc**; all
      four of its playtest checks — F10-1 to F10-4 — passed 2026-09-03. The
      eight new French strings were written the same day, after you saw the chat
      line and the command replies come out in English. The shape and what was
      argued out are in ROADMAP.md under `F10`
      (no finding; from playtest D4 at `246bb37`)
- [x] FEAT: stop granting `fly`, `fast` and `noclip` to every new player — found
      while building `F10` on 2026-09-03, not reported: `register_on_newplayer`
      was granting all three in any game that installs this mod, the same shape
      as C18's sky and B39's inventory wipe. Removed outright rather than put
      behind a setting, which you declined: nothing here needs creative flight
      to be reachable. Filed as C21 on your say-so, fixed by F10 and **committed
      as b23a8bc**, gates green; confirmed in a world 2026-09-03 when you
      reported /privs on a fresh player showing none of the three, which was the
      only
      evidence this finding could ever have (audit C21)
- [x] CONTENTDB.md's Quick start tells the player they are given the two tools,
      which `F10` made false at b23a8bc. README.md had the same problem and has
      been rewritten with a step saying where the tools come from; CONTENTDB.md is
      left for the wording review you have pending, since you have an
      uncommitted edit to that line already. **Done 2026-09-03 at c2e541f**,
      with .cdb.json regenerated from it in the same commit
      (audit C19; F10)
- [ ] doc/api.md's Chat commands and Codelevel sections are hand-written and no
      check reads them — gen_docs.lua owns the file only from the `# Lua api`
      heading down. The gate said "up to date" while the file documented
      /codelevel and /codegenerate after F10 renamed them; fixed by hand the
      same day. Recorded in CLAUDE.md and ROADMAP.md as a property of the file,
      not closed — teaching the generator to write that region needs a source
      of truth for chat commands that does not exist (no finding)
- [ ] warn when the editor is closed with unsaved changes — `soe` is read, written
      and acted on nowhere; `F7` marks unsaved tabs first, which may be enough
      (audit F7)
- [x] a ContentDB long description that is not README.md — done 2026-08-28,
      CONTENTDB.md, with the shape you asked for. Revise the copy freely; edit
      that file and run scripts/gen_cdb_json.sh, never .cdb.json (audit C19)
- [x] fix CONTENTDB.md, which has drifted two features behind — the corner
      display "naming the one limit the run will actually stop on" (said twice)
      and the panel's "pause, resume, cancel and remove" both describe F4's
      displays, which F8 replaced with three coloured lines and with Stop plus
      Pause/Resume. Add F9's elapsed clock, then run scripts/gen_cdb_json.sh.
      Hand-kept against CHANGELOG.md and nothing checks the two agree, which is
      how it drifted silently. **Done 2026-09-03 at c2e541f**, together with the
      Quick start line above; it is still hand-kept, so it will drift again
      (audit C19)
- [ ] configure the ContentDB release webhook — trigger "Branch or tag
      creation", not push, because this project tags. The procedure is in the
      release-codeblock skill (no finding; from the author, 2026-08-28)
- [ ] the ContentDB URLs in README.md are on content.minetest.net, the
      pre-rename domain; it redirects but is stale (audit C19)
- [x] rework the screenshots and the ContentDB cover — done 2026-09-02:
      screenshots/mozaic.png and editor.png redone against the current editor,
      one stale 2021 file dropped. doc/dp.png and doc/ds.png became
      doc/drone_poser.png and doc/drone_setter.png for the wiki; README.md
      linked the old names five times and now points at the new ones. Nothing
      new needs a .gitattributes rule — doc/*.png and screenshots/ are both
      already excluded, and the archive still holds eleven top-level entries
      (no finding)
- [x] screenshot.png at the repo root — done 2026-09-02: the mosaic copied over
      it verbatim, so the Mods-tab cover is the current editor rather than one
      from four features ago. It costs what was predicted: the release archive
      is 2.21 MB, up from 1.48 MB and above the 1.60 MB the .gitattributes work
      trimmed. Your call and recorded as one; resize the cover rather than
      revert if that ever matters (no finding)
- [ ] screenshots/mozaic.png is now byte-identical to screenshot.png, so the
      repository carries the same 1.83 MB twice while only one copy ships.
      Dropping it would keep mozaic.xcf as the editable source and halve that in
      a clone — say if you want it gone (no finding)
- [ ] upload the new screenshots to the ContentDB package page — the files are
      loaded from raw GitHub URLs on master, so the page needs the new names
      and the dropped file removing (audit C19)

Decisions wanted from the author

- [x] is `max_runtime_s` to come down? Yes, answered by doing it, 2026-09-02:
      `30 / 60 / 120 / 300`, with level 4's `max_nodes_written` `1e7` → `5e7`
      going the other way. A 387 s program spent about 18 s of server time, so
      2000 s of charged time was eleven hours of building. From playtest `H1`;
      the reasoning is in `ROADMAP.md` (no finding)
- [x] settingtypes.txt gets a generator and a --check, like doc/api.md and
      locale/template.txt — answered yes, 2026-08-28: "can have a generator if
      this simplifies and unify the process". Built 2026-09-02,
      scripts/gen_settingtypes.lua, with a CI step beside the other two. Writing
      it found C20: gen_docs.lua's own limit check had been matching nothing
      since it was written, Lua's %w excluding the underscore that every limit
      name has (audit C7, C17, C20)
- [x] Blockly is out of 1.0.0 — answered 2026-08-28 and made larger than that:
      it is v2.0.0 and Phase 10 on its own, with Phase 9 for v1.x.y in between
      (audit F6)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [x] run H10 — passed 2026-09-02: a few presses in twenty still miss, and you
      called that acceptable. So B47 ships mitigated rather than closed, and the
      figure in "what ships broken" is what you counted rather than what the
      arithmetic predicted. The change that would close it outright — a panel
      that does not refresh itself, live figures left to the HUD — stays
      available; say the word if the misses annoy you in ordinary use rather
      than under a deliberate fast count (audit B47)
- [x] run F9-1 — passed 2026-09-02 at `029fab9`, all eight cases in both
      languages, and case 4 again after you asked for the opposite: it has now
      passed once each way round (audit F9)
- [x] run E16 — the unsaved-tab marker, new with F7: passed 2026-08-28 at
      `afbe504`, the day it shipped (audit F7)
- [x] re-run E16 for its new pristine-example case — passed 2026-09-03 on
      `b9143b0` plus the uncommitted tree, which confirms B48 in a world. The
      original run used a file it had typed into, which is LF on disk and cannot
      show the defect (audit B48, F7)
- [x] run F10-1's two unreported cases — passed 2026-09-03: the fresh
      player's inventory holds neither tool and `/privs` shows no `fly`, `fast`
      or `noclip`. That second one **confirms C21 in a world** and was the only
      evidence it could ever have, so all four F10-n checks now pass, and they
      were re-affirmed at 16cd05c once F10 was committed
      (audit C21; playtest F10-1)
- [x] run W4 — passed 2026-09-03 at 16cd05c: the unknown-block warning behaves,
      and it was the last check in PLAYTEST.md with no result. Case 2 — a second
      drone in the same session warning on its own account — is the only way the
      per-run scope is observable at all, since no spec can reach it (audit B49)
- [x] run H8 cases 2, 3 and 4 — 2 and 4 passed 2026-09-02; cases 1 and 3 are
      unperformable, a shown formspec holding the pointer, so no tool can be
      used while the panel is open. Case 3's mechanism moved into `forms_spec`
      (audit F8, B29)
- [x] run D2 case 2 — removed as untestable 2026-09-02, after two attempts. It
      is the only route to `B10`'s refusal, which now has none: reaching it
      needs a way to observe the server releasing a mapblock (audit B10)
- [x] build the release archive and install it once, to prove C16's guard —
      playtest R1 passed at `afbe504` and R2 at `7c5bceb`, both 2026-08-28
      (audit C16)
- [ ] run W1 at codelevels 2, 3 and 4 — level 1 failed 2026-09-03 and is B50.
      Whether the other three behave is unreported, so nothing claims they pass;
      whichever levels do work is also the first thing that narrows the cause
      (audit B50; playtest W1)
- [ ] once the B50 fix is committed, run three checks: W1 again at codelevel 1
      with the `forward(500); sleep(20)` reproducer and its third observation
      made, W5 — new, the check B52 has never had — and W6, new: the drone's
      entity going away when you walk off and being back when you return, with
      no chat line either way (audit B50, B52; playtest W1, W5, W6)
- [ ] re-run R2 on the archive built from the release commit — R1 was
      re-checked at `7dbe18f` and still passes, but R2 last ran before F4 added
      lib/hud.lua and before .gitattributes changed at `60dc8dd`. Install it in
      a game that is not codecube: B38, B39 and C18 were all invisible there
      (audit C16, C10)

Elsewhere

- [ ] drop the 5.5 ceiling in tests/game/mods/vector3/mod.conf — separate
      repository (audit C1)


# After 1.0.0

- [ ] FEAT: Blockly web-based editor (audit F6) — planned, deliberately not in
      1.0.0
- [ ] FEAT: Allow disconnect issues on servers, drone paused and can be resumed
- [ ] BUG : fix light on large builds (minetest.fix_light(pos1, pos2))
- [ ] FEAT : protect areas (minetest.is_protected(pos, name))
- [ ] FEAT : allow save and place schematic files
- [ ] FEAT : put a limit on drone distance to start pos


# Other ideas

- format lua programs when saving ? https://github.com/LuaDevelopmentTools/luaformatter/blob/master/formatter.lua
- render code with html widget? (highlight)
- show line error on save?
- colored concrete instead of wool? : https://github.com/nikolaus-albinger/colored_concrete - block list is the mod's, the nodes come from the game
