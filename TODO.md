# TODO

Intentions for the CodeBlock mod, one line each. What the work involves is in
`ROADMAP.md`; why, in this mod's audit at `.audit/audit.html` (gitignored). The
game keeps its own list and its own audit, at the root of a `codecube` checkout.
Finding ids are shared between the two audits and are never renumbered.

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
- [ ] add a .gitignore containing .audit/ - the mod has none, so its audit shows as untracked
- [ ] show the program's budget while it runs, not just its totals at the end (Phase 8, no finding)
- [ ] unify drone.lua and drone_entity.lua (audit A11)
- [ ] option to set drone default block to place
- [ ] open copy of program
- [ ] option to pause the drone a certain time?
- [ ] Make the UI show drone info : running or not, blocks placed, allow pause, start, cancel, etc
- [ ] Bug ? Remember last opened file and reopen with editor
- [ ] rebuild construction when re-running code (save previous area)
- [ ] Make possible to change codelevel while running a program
- [ ] Update Vector3 package (min, max version, bugs, etc) (audit C1)
- [ ] Blockly web-based editor
- [ ] batch place() into core.bulk_set_node (audit A4) - decided against for 1.0.0

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
