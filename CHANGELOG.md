# v1.1.0 (unreleased)

- [ ] FIX: A build beside freshly explored ground no longer comes out with mapblock-sized holes.
  The drone waits for the map around a write to be generated first.
- [ ] FIX: A carve into unexplored ground no longer grows the game's grass and dirt on its floor.
- [ ] FIX: Shapes are lit correctly: a hollow shape is dark inside, with no dark lines every 16 nodes around it.
- [ ] FIX: A retired setting with no replacement says so, instead of naming a setting that does not exist.
- [ ] FEATURE: New codelevel limit `max_map_generated`, the new map one program may make the server generate.
  Shown on the HUD and in the drone panel.
- [ ] FEATURE: New setting `codeblock_wait_for_mapgen`, on by default. Turn it off only in a game that pre-generates all the map drones can reach.
- [ ] PERF: Programs of many small shapes run several times faster: shapes in the same mapblock share one write.
- [ ] PERF: A wide or flat shape no longer stalls the server, being written in boxes of at most 16 mapblocks.
- [ ] PERF: The drone moves on screen once per server step instead of once per command, which costs the server less.
- [ ] PERF: Drones in unexplored ground ask the map generator one at a time, so players' own terrain keeps loading.
- [ ] PACKAGING: Declared on ContentDB as working in any game, with a new description and its AI disclosure.
