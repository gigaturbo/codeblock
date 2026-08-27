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
- [x] playtest the drone and filesystem groups (2026-08-27: D1 pass, D2/D4 fail, D3 partial, F-1 pass, F-2 partial)
- [ ] playtest the world-write and pacing groups - the checklist is tests/PLAYTEST.md
- [x] playtest the editor group by hand (2026-08-27: 5 pass, E2 partial, E5 fail)
- [ ] run F1's two playtest checks - the Settings panel and the relog (audit F1)
- [x] run F2's playtest check E13, the flush button edge included (audit F2)
- [ ] push the seven unpushed commits, dee0bc7 to b5d2e40 - gates green, awaiting the author (no finding)
- [ ] build the release archive and install it once, to prove C16's guard (audit C16)
- [ ] drop the 5.5 ceiling in mods/vector3/mod.conf - separate repository (audit C1)
- [x] FEAT: option to set drone default block to place (audit F1)
- [x] FEAT: open copy of program (audit F2)
- [x] sort a file list so foo_2 comes before foo_10 (audit F2)
- [x] FEAT: option to pause the drone a certain time - sleep(seconds) (audit F3)
- [ ] FEAT: Make a UI for drone info : running or not, blocks placed, allow pause, start, cancel, etc (audit F4)
- [ ] show the program's budget while it runs, not just its totals at the end (audit F4)
- [ ] FEAT: Make possible to change codelevel while running a program (audit F5)
- [x] BUG: editor loses its open tabs on leave, on shutdown and on Load and close (audit B33)
- [x] BUG: every editor button but Save discarded the text typed since the last save (audit B35)
- [x] start the two editor checkboxes ticked for a player who has never set them (audit B36)
- [x] run the disconnect and shutdown editor checks - both pass, shutdown now observed (audit B33)
- [x] BUG: the new-player initialiser made the ticked checkbox default unreachable (audit B36)
- [x] BUG: three help-panel scroll branches shadowed quit, the block picker and new file (audit B37)
- [x] re-run E10 with a fresh player name - pass, B36 confirmed in world (audit B36)
- [x] run E14 and E15: ESC saves the open tabs, Enter in New file creates it - both pass (audit B37)
- [ ] settle E12 by reading the file's size or mtime from outside the game - reading the code is exhausted, three fails and two traces (no finding)
- [ ] warn when the editor is closed with unsaved changes - soe is read, written, and acted on nowhere (no finding)
- [x] BUG: aiming the poser at nothing was silently ignored - the engine calls on_secondary_use (audit B38)
- [x] BUG: the first join after installing the mod wiped the player's inventory (audit B39)
- [x] BUG: locale/template.txt drifted both ways and three translations were orphaned by a key edit (audit C17)
- [ ] re-run D2 both cases, D4 case 2, and F-2 in French, against b5d2e40 (audit B38, B39, C17)
- [ ] run D3 part 2 - remove a running drone with the setter, place another at once (audit B29)
- [ ] run F-3 case 1 - a precompiled chunk in the player's directory (audit B7, B15)
- [ ] decide whether settingtypes.txt gets a generator and a --check, like doc/api.md and locale/template.txt (audit C7, C17)
- [ ] decide what happens to the five sky overrides on join - permanent daylight, no sun, moon, stars or clouds, for every installing game (audit C18)

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
