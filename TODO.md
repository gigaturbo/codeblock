# TODO

The author's inbox and wanted-features list. One line each. **A `FIX:` or `BUG:`
line is a hand-off**: it gets a finding id in `AUDIT.md` and stays here until the
author deletes it. The long form lives elsewhere — the work in `ROADMAP.md`, the
reasoning in `AUDIT.md`, what shipped in `CHANGELOG.md`. Completed items are not
kept here.

# v1.0.0

Features

- [ ] FEAT: `place(colorhex("#F7A8E7"))` — shaped as `F15`, feasible only as
      *nearest of 256* through a palette node, deliberately not scheduled. Two
      questions open: which 256 colours, and how the value reaches `place()`
      (audit F15)
- [ ] warn when the editor is closed with unsaved changes — `soe` is read,
      written and acted on nowhere; `F7` marks unsaved tabs first, which may be
      enough (audit F7)
- [ ] doc/api.md's Chat commands and Codelevel sections are hand-written and no
      check reads them. Not closable without a source of truth for chat commands
      that does not exist (no finding)
- [ ] configure the ContentDB release webhook — trigger "Branch or tag
      creation", not push. Procedure in the release-codeblock skill (no finding)
- [ ] the ContentDB URLs in README.md are on content.minetest.net, the
      pre-rename domain (audit C19)
- [ ] upload the new screenshots to the ContentDB package page — new names, and
      the dropped 2021 file removed (audit C19)
- [ ] screenshots/mozaic.png is byte-identical to screenshot.png, so a clone
      carries 1.83 MB twice while only one copy ships. Say if you want it gone
      (no finding)

Decisions wanted from the author

- [ ] DECIDE: what `tests/game/mods/vector3` should pin, now that three releases
      are in the wild and the submodule is at v2.0.2. Pin the newest, the oldest
      supported, or document a floor (audit S8)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [ ] re-run R1 and R2 against the release tag — both passed against f700410,
      and C24 puts commits above it, so both go stale. R2 is the one with
      something new to read: C24 changes init.lua, which ships (audit C16, C10;
      playtest R1, R2)
- [ ] watch the first CI run of the new "the nine specs in Luanti" job — it has
      never executed, this machine having no docker, so its container half is
      unverified (audit C24)


# After 1.0.0

- [ ] FEAT: Blockly web-based editor (audit F6) — planned, deliberately not in
      1.0.0
- [ ] FEAT: Allow disconnect issues on servers, drone paused and can be resumed
- [ ] BUG : fix light on large builds (minetest.fix_light(pos1, pos2))
- [ ] FEAT : protect areas (minetest.is_protected(pos, name))
- [ ] FEAT : allow save and place schematic files
- [ ] FEAT : put a limit on drone distance to start pos
- [ ] FEAT : allow to rename programs


# Other ideas

- format lua programs when saving ? https://github.com/LuaDevelopmentTools/luaformatter/blob/master/formatter.lua
- render code with html widget? (highlight)
- show line error on save?
