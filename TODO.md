# TODO

The author's inbox of wanted features and bugs. One line each. **A `FIX:` or
`BUG:` line is a hand-off**: it gets a finding id in `AUDIT.md` and stays here
until the author deletes it. The long form lives elsewhere — the work in
`ROADMAP.md`, the findings in `AUDIT.md`, what shipped in `CHANGELOG.md`.
Completed items are deleted.

# v1.0.0

No feature work left. The release commit, the tag, the ContentDB upload and the
webhook are steps 3 to 6 of the ordered list in `ROADMAP.md`. `R1` and `R2` in
`PLAYTEST.md` are read after the tag.

One low bug ships open, `B57` in `AUDIT.md`. The author deferred it to a v1.x.


# After 1.0.0

- [ ] FEAT: Blockly web-based editor (roadmap F6)
- [ ] FEAT: `place(colorhex("#F7A8E7"))` (roadmap F15)
- [ ] FEAT: warn when the editor is closed with unsaved changes (roadmap F7)
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
