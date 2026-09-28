# v1.1.0 (unreleased)

- [x] FEATURE: New codelevel limit `max_map_generated`, the new map one program may make the server generate. Shown on the HUD and in the drone panel.
- [x] FEATURE: New setting `codeblock_wait_for_mapgen`, on by default. Turn it off only in a game that pre-generates all the map drones can reach.
- [x] FEATURE: New settings `codeblock_server_share`, the percent of the step all drones share, and `codeblock_step_share`, each codelevel's part of it.  They replace `codeblock_step_budget_us` and `codeblock_server_step_budget_us`, which now only warn in the log.
- [x] PACKAGING: Declared on ContentDB as working in any game, with a new description and its AI disclosure.
- [x] PERF: Programs of many small shapes run several times faster: shapes in the same mapblock share one write.
- [x] PERF: A wide or flat shape no longer stalls the server, being written in boxes of at most 16 mapblocks.
- [x] PERF: The drone moves on screen once per server step instead of once per command, which costs the server less.
- [x] PERF: A drone runs for a share of each server step rather than a fixed time: twice as long in singleplayer at the default codelevel, and about seven times on a server. It no longer slows down when the game window loses focus.
- [x] PERF: What a paced, waiting or low-codelevel drone leaves of the step goes to the other drones instead of being lost.
- [x] PERF: Drones in unexplored ground ask the map generator one at a time, so players' own terrain keeps loading.
- [x] FIX: A build beside freshly explored ground no longer comes out with mapblock-sized holes.
  The drone waits for the map around a write to be generated first.
- [x] FIX: A carve into unexplored ground no longer grows the game's grass and dirt on its floor.
- [x] FIX: Shapes are lit correctly: a hollow shape is dark inside, with no dark lines every 16 nodes around it.
- [x] FIX: A long shape facing west or south is built from the drone's end, as the others are, instead of starting at its far end, out of sight.
- [x] FIX: A retired setting with no replacement says so, instead of naming a setting that does not exist.
