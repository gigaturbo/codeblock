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
- [ ] FEAT: stop forcing the two tools into every joining player's inventory —
      a command that hands them out, or a setting so an embedding game decides.
      Today `set_tools` adds what is missing on every join and says so in chat
      when there is no room (no finding; from playtest D4 at `246bb37`)
- [ ] warn when the editor is closed with unsaved changes — `soe` is read, written
      and acted on nowhere; `F7` marks unsaved tabs first, which may be enough
      (audit F7)

Decisions wanted from the author

- [ ] decide what happens to the five sky overrides on join — permanent daylight,
      no sun, moon, stars or clouds, for every installing game (audit C18)
- [ ] decide whether settingtypes.txt gets a generator and a --check, like
      doc/api.md and locale/template.txt (audit C7, C17)
- [ ] confirm or overrule keeping Blockly out of 1.0.0 (audit F6)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [ ] run D2 case 2 — a drone placed where the client shows a node the server has
      unloaded; the recipe is in the check (audit B10)
- [ ] run F-3 case 2 — a file the process cannot read, denied with icacls; the
      last thing in the filesystem group nothing has exercised (audit B15)
- [ ] run W2 and W3, the two world-write checks never run at all
- [ ] re-run W1 — its pass predates the Phase 6 and 7 rewrites of lib/cost.lua
      and never recorded an engine version (audit S5, A4)
- [ ] build the release archive and install it once, to prove C16's guard —
      playtest R1 and R2, never run (audit C16)

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
