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
      playtest `F9` is the in-world check (audit F9)
- [ ] BUG: buttons on the drone panel are sometimes unresponsive, a second click
      needed. The suspect is the panel's own 0.5 s refresh re-sending the
      formspec under the press, not the handlers (audit B47)
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
- [ ] keep CONTENTDB.md's "Recent changes" current at each release — hand-kept
      against CHANGELOG.md and nothing checks the two agree (audit C19)
- [ ] configure the ContentDB release webhook — trigger "Branch or tag
      creation", not push, because this project tags. The procedure is in the
      release-codeblock skill (no finding; from the author, 2026-08-28)
- [ ] the ContentDB URLs in README.md are on content.minetest.net, the
      pre-rename domain; it redirects but is stale (audit C19)

Decisions wanted from the author

- [x] is `max_runtime_s` to come down? Yes, answered by doing it, 2026-09-02:
      `30 / 60 / 120 / 300`, with level 4's `max_nodes_written` `1e7` → `5e7`
      going the other way. A 387 s program spent about 18 s of server time, so
      2000 s of charged time was eleven hours of building. From playtest `H1`;
      the reasoning is in `ROADMAP.md` (no finding)
- [x] settingtypes.txt gets a generator and a --check, like doc/api.md and
      locale/template.txt — answered yes, 2026-08-28: "can have a generator if
      this simplifies and unify the process" (audit C7, C17)
- [x] Blockly is out of 1.0.0 — answered 2026-08-28 and made larger than that:
      it is v2.0.0 and Phase 10 on its own, with Phase 9 for v1.x.y in between
      (audit F6)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [ ] run F9 — the panel's duration, the idle heading and the HUD's *CPU time*,
      shipped 2026-09-02 and words only, so no spec sees any of it. In French
      too (audit F9)
- [ ] run E16 — the unsaved-tab marker, new with F7 and never seen by a player
      (audit F7)
- [ ] run H8 cases 2, 3 and 4 — unreported in both runs of that check. Case 1 is
      now known to be unperformable: a shown formspec holds the pointer, so no
      tool can be used while the panel is open (audit F8, B29)
- [ ] run D2 case 2 — a drone placed where the client shows a node the server has
      unloaded; the recipe is in the check, and it has now been aimed at twice
      and missed twice, so the recipe is the suspect (audit B10)
- [x] build the release archive and install it once, to prove C16's guard —
      playtest R1 and R2, both passed 2026-08-28 at `7c5bceb` (audit C16)

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
