# TODO

# v1.0.0 goals

- [x] User associated filesystem to store programs
- [x] Allow to set drone's file with in-game interface + remember last program started
- [x] Control drone operating speed
- [x] In-game lua code editor
- [ ] limits that reflect real load (audit S5)
- [ ] show the program's budget while it runs, not just its totals at the end (audit S5)
- [ ] Blockly web-based editor

# maybe

- [ ] option to set drone default block to place
- [ ] open copy of program
- [ ] option to pause the drone a certain time?
- [ ] Make the UI show drone info : running or not, blocks placed, allow pause, start, cancel, etc
- [ ] Bug ? Remember last opened file and reopen with editor
- [ ] make mod configurable (see https://github.com/AntumMT/mod-hovercraft/) (audit C7)
- [ ] one default codelevel for singleplayer, a lower one for servers (audit S6)
- [x] fix place() in non-loaded chunks (audit A4): load_area before set_node
- [ ] batch place() into core.bulk_set_node (audit A4) - decided against for 1.0.0
- [x] fix color(v,m,M) function (or remove)
- [ ] rebuild construction when re-running code (save previous area) 
- [ ] Update Vector3 package (min, max version, bugs, etc) (audit C1)
- [ ] unify drone.lua and drone_entity.lua (audit A11)

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
- colored concrete instead of wool? : https://github.com/nikolaus-albinger/colored_concrete

# Game ideas

- [x] generate flat clean world https://github.com/srifqi/superflat (cc_mapgen)
- [ ] teleport function?
- [x] always day, etc (cc_day)
- [ ] fog distance
