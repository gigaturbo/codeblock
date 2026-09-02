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
      playtest `F9` passed 2026-09-02 at `029fab9`, both languages (audit F9)
- [x] FEAT: stop the panel's elapsed clock while a run is paused — asked for
      2026-09-02 on seeing `F9` in a world, reversing that feature's decision
      that it should keep counting. Built the same day with four gates green:
      `Drone.elapsed_us` is now the one answer both the panel and the finish
      message read, and `Drone.toggle_pause` the only writer of `paused`.
      Playtested the same day: `F9` case 4, rewritten and passed (audit F9)
- [x] BUG: buttons on the drone panel are sometimes unresponsive, a second click
      needed. Cause confirmed in the engine source: the 0.5 s refresh makes the
      client destroy and rebuild every element, and a button's press lives on
      the object it destroys, so a click held across a refresh is dropped with
      no error. Fixed 2026-09-02 the way you asked: the beat is 1 s, HUD and
      panel together since they share the one constant. It halves the dropped
      window rather than closing it — about one click in ten, was one in five —
      so playtest H10 is what says whether that is enough (audit B47)
- [ ] FEAT: Make possible to change codelevel while running a program (audit F5)
- [ ] FEAT: stop forcing the two tools into every joining player's inventory —
      a command that hands them out, or a setting so an embedding game decides.
      Today `set_tools` adds what is missing on every join and says so in chat
      when there is no room (no finding; from playtest D4 at `246bb37`)
- [ ] warn when the editor is closed with unsaved changes — `soe` is read, written
      and acted on nowhere; `F7` marks unsaved tabs first, which may be enough
      (audit F7)
- [x] a ContentDB long description that is not README.md — done 2026-08-28,
      CONTENTDB.md, with the shape you asked for. Revise the copy freely; edit
      that file and run scripts/gen_cdb_json.sh, never .cdb.json (audit C19)
- [ ] fix CONTENTDB.md, which has drifted two features behind — the corner
      display "naming the one limit the run will actually stop on" (said twice)
      and the panel's "pause, resume, cancel and remove" both describe F4's
      displays, which F8 replaced with three coloured lines and with Stop plus
      Pause/Resume. Add F9's elapsed clock, then run scripts/gen_cdb_json.sh.
      Hand-kept against CHANGELOG.md and nothing checks the two agree, which is
      how it drifted silently (audit C19)
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
- [x] run F9 — passed 2026-09-02 at `029fab9`, all eight cases in both
      languages, and case 4 again after you asked for the opposite: it has now
      passed once each way round (audit F9)
- [x] run E16 — the unsaved-tab marker, new with F7: passed 2026-08-28 at
      `afbe504`, the day it shipped (audit F7)
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


# Other ideas

- format lua programs when saving ? https://github.com/LuaDevelopmentTools/luaformatter/blob/master/formatter.lua
- render code with html widget? (highlight)
- show line error on save?
- colored concrete instead of wool? : https://github.com/nikolaus-albinger/colored_concrete - block list is the mod's, the nodes come from the game
