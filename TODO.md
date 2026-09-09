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

- [ ] run F-6 — three lines pasted into a file of their own, run three times,
      the only in-world reading the `S8` fix can have. It must print `1 1 1`
      three times on every version. **Name which vector3 you are running**
      (audit S8; playtest F-6)
- [ ] run R5 — swap the vector3 submodule to v1.5 and v2.0.1 by hand, start a
      world on each, and read `debug.txt` for the one warning naming the version.
      Put the pin back afterwards (audit S9; playtest R5)
- [ ] re-run R2 on the archive built from the release commit. Install it in a
      game that is not codecube (audit C16, C10)
- [ ] run F17-1 to F17-4 and re-run F12-6 — `random.of`, `random.hues()`,
      `ramp.of` over a category, and the help panel with the deleted rows gone.
      F17-3 and F12-6 both want the codeblock-test-mod installed, so they are one
      session (audit F17; playtest F17-1 to F17-4, F12-6)
- [ ] run R4 in a fresh world — its four cases are performable for the first
      time now that `/codeblock level` reads (audit A17; playtest R4)


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
