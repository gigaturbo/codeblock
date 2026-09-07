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
- [ ] DECIDE: three exported functions in `lib/utils.lua` have no caller left —
      `table_reverse`, `table_convert_ik`, `table_convert_iv`. Delete them in
      v1.0.0 where breaking is free, or declare `codeblock.utils` public and keep
      them (audit A17)
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

- [ ] DECIDE: whether vector3's own fix lands before or after the v1.0.0 tag.
      `S9` is unfixed on both v1.5 and v2.0.1 and reaches every other mod using
      the `vector3` global. Write-protecting it from this mod is recommended
      against (audit S9)
- [ ] DECIDE: what `tests/game/mods/vector3` should pin, now that the bump to
      v2.0.1 leaves the v1.5 half proven by nothing. Pin the newest, the oldest
      supported, or document a floor (audit S8)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [ ] run F-6 — `game.lua` three times over, plus its case 3 reproducer, the
      only in-world reading `S8` can have. **Name which vector3 you are running**
      (audit S8; playtest F-6)
- [ ] run F-7 — every shipped example, one at a time. Standing check, after any
      dependency bump and before a release (audit C23, C24, S8; playtest F-7)
- [ ] re-run R2 on the archive built from the release commit. Install it in a
      game that is not codecube (audit C16, C10)

Elsewhere

- [ ] separate vector3's metatable from its methods table — `local mt = {__index
      = vector3, __add = ...}`. Separate repository, so a release there and a
      submodule bump here. v2.0.1 did not include it (audit S9)


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
