# TODO

Intentions for the CodeBlock mod, one line each. What the work involves is in
`ROADMAP.md`; why, in this mod's audit at `.audit/audit.html` (gitignored). The
game keeps its own list and its own audit, at the root of a `codecube` checkout.
Finding ids are shared between the two audits and are never renumbered; `F` ids
are features, this project's own.

# v1.0.0 goals

- [x] User associated filesystem to store programs
- [x] Allow to set drone's file with in-game interface + remember last program started
- [x] Control drone operating speed
- [x] In-game lua code editor
- [x] limits that reflect real load (audit S5)
- [x] measure place() in a live world at codelevel 4: loaded blocks and RSS (audit S5)
- [x] pace the low codelevels so a beginner can watch the loop (audit S5)
- [x] slice bulk shapes so a large one is slow, not a server freeze (audit A5)
- [x] make mod configurable (see https://github.com/AntumMT/mod-hovercraft/) (audit C7)
- [x] one default codelevel for singleplayer, a lower one for servers (audit S6)
- [x] fix place() in non-loaded chunks (audit A4): load_area before set_node
- [x] fix color(v,m,M) function (or remove)
- [x] delete the superseded doc pipeline: doc/commands.md, scripts/gen_api_html.sh
- [x] delete the second dead pair too: doc/api.html, scripts/gen_doc_html.sh - both READMEs link to doc/api.md
- [x] .gitattributes: keep the release archive to what the mod needs, and stop textures/*.xcf shipping (audit C10)
- [x] add a .gitignore containing .audit/ - it exists and contains it; the entry was wrong
- [x] unify drone.lua and drone_entity.lua (audit A11)
- [x] split lib/commands.lua and remove its repetition (audit A3)
- [x] one record per file in the filesystem layer (audit A9)
- [x] round or normalise the rotation key so a turn() cannot crash the next move (audit B27)
- [x] tell drones apart by a serial so on_lost cannot kill a replacement (audit B29)
- [x] stop run_tests.ps1 writing a BOM into minetest.conf, and repair the damaged config (audit B31)
- [x] guard the spec dofiles in init.lua against a ContentDB install (audit C16)
- [x] fix check_inside_world's error level on the move_by path (audit B28)
- [x] add a separator when run_tests.ps1 appends the enable line (audit B32)
- [x] check drone.cor in on_lost before announcing a program ended (audit B30)
- [x] finish minetest.* -> core.* across lib/, tests/ and init.lua (audit C6)
- [x] push master and get a green CI run on the Phase 7 range (no finding)
- [ ] playtest the drone, filesystem, world-write and pacing groups - the checklist is tests/PLAYTEST.md
- [x] playtest the editor group by hand (2026-08-27: 5 pass, E2 partial, E5 fail)
- [ ] run F1's two playtest checks - the Settings panel and the relog (audit F1)
- [ ] run F2's playtest check E13, the flush button edge included (audit F2)
- [ ] push dee0bc7 and get a green CI run on it (no finding)
- [ ] build the release archive and install it once, to prove C16's guard (audit C16)
- [ ] drop the 5.5 ceiling in mods/vector3/mod.conf - separate repository (audit C1)
- [x] FEAT: option to set drone default block to place (audit F1)
- [x] FEAT: open copy of program (audit F2)
- [x] sort a file list so foo_2 comes before foo_10 (audit F2)
- [ ] FEAT: option to pause the drone a certain time (audit F3)
- [ ] FEAT: Make a UI for drone info : running or not, blocks placed, allow pause, start, cancel, etc (audit F4)
- [ ] show the program's budget while it runs, not just its totals at the end (audit F4)
- [ ] FEAT: Make possible to change codelevel while running a program (audit F5)
- [x] BUG: editor loses its open tabs on leave, on shutdown and on Load and close (audit B33)
- [x] BUG: every editor button but Save discarded the text typed since the last save (audit B35)
- [x] start the two editor checkboxes ticked for a player who has never set them (no finding)
- [ ] run the three unverified editor checks: disconnect, shutdown, checkbox defaults (audit B33, B35)
- [ ] warn when the editor is closed with unsaved changes - instead of the dead soe checkbox (no finding)

Decided against for 1.0.0, kept so it is not re-litigated: batching place() into
core.bulk_set_node (audit A4); letting a file be removed without opening it first
(audit B34 - "won't fix now, not really needed").


# After 1.0.0

- [ ] FEAT: Blockly web-based editor (audit F6) - planned, deliberately not in 1.0.0


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
