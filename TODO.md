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

- [ ] FEAT: Make a UI for drone info : running or not, blocks placed, allow pause,
      start, cancel, etc — includes showing the program's budget while it runs,
      not just its totals at the end (audit F4)
- [ ] FEAT: Make possible to change codelevel while running a program (audit F5)
- [ ] warn when the editor is closed with unsaved changes — `soe` is read, written
      and acted on nowhere (no finding)

Decisions wanted from the author

- [ ] decide what happens to the five sky overrides on join — permanent daylight,
      no sun, moon, stars or clouds, for every installing game (audit C18)
- [ ] decide whether settingtypes.txt gets a generator and a --check, like
      doc/api.md and locale/template.txt (audit C7, C17)
- [ ] confirm or overrule keeping Blockly out of 1.0.0 (audit F6)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [ ] re-run D2 both cases, D4 case 2, and F-2 in French, against b5d2e40+
      (audit B38, B39, C17)
- [ ] run D3 part 2 — remove a running drone with the setter, place another at
      once (audit B29)
- [ ] run F-3 case 1 — a precompiled chunk in the player's directory (audit B7,
      B15)
- [ ] run F1's two checks — the Settings panel and the relog (audit F1)
- [ ] run F3's sleep check in a world (audit F3)
- [ ] playtest the world-write and pacing groups (audit S5, A5)
- [ ] settle E12 by reading the file's size or mtime from outside the game —
      reading the code is exhausted, three fails and two traces (no finding)
- [ ] build the release archive and install it once, to prove C16's guard
      (audit C16)

Elsewhere

- [ ] drop the 5.5 ceiling in tests/game/mods/vector3/mod.conf — separate
      repository (audit C1)


# After 1.0.0

- [ ] FEAT: Blockly web-based editor (audit F6) — planned, deliberately not in
      1.0.0


# Other ideas

- minetest.set_timeofday(val)
- minetest.fix_light(pos1, pos2)
- minetest.is_protected(pos, name)
- minetest.place_schematic(pos, schematic, rotation, replacements, force_placement, flags)
- minetest.create_schematic(p1, p2, probability_list, filename, slice_prob_list)
- HTTPApiTable.fetch(HTTPRequest req, callback)
- format lua when saving ? https://github.com/LuaDevelopmentTools/luaformatter/blob/master/formatter.lua
- render code with html widget? (highlight)
- show line error on save?
- colored concrete instead of wool? : https://github.com/nikolaus-albinger/colored_concrete - block list is the mod's, the nodes come from the game
