# TODO

# v1.0.0 goals

- [x] User associated filesystem to store programs
- [x] Allow to set drone's file with in-game interface + remember last program started
- [x] Control drone operating speed
- [x] In-game lua code editor
- [ ] Blockly web-based editor

# maybe

- [ ] option to set drone default block to place
- [ ] open copy of program
- [ ] option to pause the drone a certain time?
- [ ] make mod configurable (see https://github.com/AntumMT/mod-hovercraft/)
- [x] fix place() in non-loaded chunks (audit A4): load_area before set_node
    - verified in a live world: without it the write silently vanishes and the
      node stays `ignore`; with it the node is written even where terrain was
      never generated, and is still there on recheck
    - not verified: whether mapgen can later overwrite a block written that way,
      when a player finally visits and the area generates
- [ ] batch place() into core.bulk_set_node
    - worth 1.3x by the engine's own figure, and needs a pending-writes buffer
      flushed before every world read, at each yield, and on program end, error
      and abort. Deferred on that ratio, not forgotten. The 20x case was the
      bulk shapes, and those are VoxelManip already (lib/shapes.lua).
- [x] fix color(v,m,M) function (or remove)
- [ ] rebuild construction when re-running code (save previous area) 
- [ ] Update Vector3 package (min, max version, bugs, etc)
- [ ] unify drone.lua and drone_entity.lua (audit A11)
    - one owner for drone state: the instance table, entity holds a name not `_data`
    - move show_set_file_form / show_file_editor_form out to formspecs.lua
    - report "Program completed" from one place, not three
    - removes the re-entrancy dance between Drone.remove and on_deactivate

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
