# v1.0.0 (unreleased)

Breaking for existing player programs, for server operators and for
redistributors - the first thirteen items below change behaviour you may be
relying on.

- [x] **BREAKING** wool names lost their prefix: `wools.wool_red` is now `wools.red`
- [x] **BREAKING** `color(v, min, max)` clamps instead of wrapping past the palette
- [x] **BREAKING** fixed `round(x, decimals)`, whose arguments were the reverse of what was documented
- [x] **BREAKING** API names are read-only: assigning to `place`, `blocks`, etc. now raises
- [x] **BREAKING** unavailable names (`os`, `io`, `pcall`, ...) fail immediately, naming what you asked for
- [x] **BREAKING** `/codegenerate` no longer overwrites existing files
- [x] **BREAKING** dropped the `worldedit` dependency: cube, sphere, dome and cylinder are now `lib/shapes.lua`, one VoxelManip pass each
- [x] **BREAKING** relicensed GPL-3.0-only to AGPL-3.0-only, matching the Codecube game
- [x] **BREAKING** the per-codelevel limits were rewritten around the resources a program actually spends. `max_calls`, `max_commands`, `max_volume`, `max_distance`, `max_dimension`, `max_mapblocks`, `commands_before_yield` and `calls_before_yield` are gone; `max_runtime_s`, `max_nodes_written`, `map_memory_mb` and `pace_ms` replace them, and `max_memory_kb`/`max_string_bytes` became `heap_mb`/`max_string_mb`. Programs are unaffected - no API name changed - but a `minetest.conf` setting an old name now warns in the log and does nothing, naming its replacement
- [x] **BREAKING** codelevels 1 and 2 are paced: the drone now waits 250 ms (level 1) or 15 ms (level 2) after every command, so a beginner can watch the loop happen. Levels 3 and 4 do not wait at all. Set `codeblock_pace_ms` to change it
- [x] **BREAKING** a program is now limited in how much of the world it holds at once (`map_memory_mb`) rather than how many mapblocks it loads in total. Over the ceiling it is slowed down rather than stopped, because the engine frees idle mapblocks by itself
- [x] **BREAKING** nothing limits a shape's dimensions or the drone's distance from home any more. What bounds a shape is `max_nodes_written`, and a large one is written in slabs with a pause between them, so it no longer freezes the server - a 150-node cube stalled it for 0.44 s
- [x] **BREAKING** the default codelevel for a **new** player is now 4 in singleplayer and 2 on a server, instead of 4 everywhere. Existing players keep the level already stored in their meta, so upgrading a server does not demote anyone - and does not tighten anyone either. Set `codeblock_default_auth_level` to override
- [x] Added `settingtypes.txt`: every codelevel limit is now settable from the settings menu under Mods, or in `minetest.conf`, instead of only by editing `lib/config.lua`. Read at load, so a change needs a restart; a malformed value warns in the log and falls back to the default
- [x] Added `server_step_budget_us`: all running drones now share one slice of each server step instead of each having its own, so sixteen drones no longer cost sixteen budgets. `step_budget_us` became a per-drone cap on that share, and a waiting drone takes no share at all
- [x] The step budget is now honoured at every drone command and before every slab of a bulk shape, rather than only between resumes, so a long run of commands can no longer overshoot it
- [x] `place()` calls `core.load_area` once per mapblock the drone crosses into instead of once per node
- [x] The drone is kept inside the world edge (`mapgen_limit`) instead of within a distance of its spawn point: past that edge a write silently does nothing, which is the failure the distance limit was standing in for
- [x] Removed `max_minetest_version`; raised `min_minetest_version` 5.3 to 5.4 (`formspec_version[4]`)
- [x] `repeat ... until` now works - it was refused outright before
- [x] Fixed the preprocessor deleting code between two block comments
- [x] Fixed a standard `--[[ ... ]]` comment leaving its body behind as code
- [x] Fixed a `--` inside a string truncating the string
- [x] Fixed any identifier containing `function` injecting a statement after the next `)`
- [x] Instrumentation now runs over a token stream instead of pattern-matched text
- [x] Programs can no longer corrupt `blocks`/`plants`/`wools`/`iwools`/`vector` for every player
- [x] The injected call counter can no longer be disabled from player code
- [x] Bounded `("x"):rep(1e9)` and amplifying `gsub` (new `max_string_mb`)
- [x] Added `heap_mb` against runaway accumulation, checked where the drone yields
- [x] Fixed the editor's two checkboxes doing nothing (0 is truthy in Lua)
- [x] Fixed the editor's help panel opening on Blocks with no way to reach Plants, Wools or API until a file was open
- [x] Fixed `/codelevel` being unusable in singleplayer
- [x] Fixed `/codegenerate` having no privilege check and ignoring its playername
- [x] Fixed `place()` silently doing nothing where the mapblock was not in memory, which left holes in builds away from spawn
- [x] Fixed the same lost write returning through the call path: a program whose pauses came from loops and function calls rather than drone commands could skip a mapblock load it needed, and lose a node with no error
- [x] Fixed the reported duration of a program: on a Linux server it was the whole server's CPU time, not how long the program took. The completion line now reads `commands:N nodes:N duration:X.XXs`
- [x] Fixed the check that every codelevel limit has a documented row, which matched by name and so never checked `pace_ms`, `heap_mb` or `map_memory_mb`
- [x] Removed `worldedit.lua()` / `worldedit.luatransform()` from the bundled fork before dropping it
- [x] Documented `color()`, and corrected block lists that had drifted from the config
- [x] Added a test suite (`tests/`): six specs run standalone under Lua 5.1, all nine via `codeblock_run_tests`
- [x] Added luacheck and CI for this repository, which had none of its own
- [x] Dropped the `formspecs` dependency: formspec sessions are now `lib/forms.lua` on `core.show_formspec`
- [x] The drone now advances for a time budget each server step instead of exactly one coroutine resume (new `step_budget_us`)
- [x] Fixed a runtime error reporting twice and leaving the coroutine attached
- [x] Generated `doc/api.md` and the in-game help from `lib/api.lua`, which also builds the sandbox environment
- [x] Removed `doc/commands.md` and `scripts/gen_api_html.sh`, a superseded documentation pipeline nothing referenced. The in-game help is generated at runtime from `lib/api.lua`, and the written reference is `doc/api.md`
- [x] Removed `doc/api.html` and `scripts/gen_doc_html.sh` as well, the second half of that pipeline. Nothing referenced either, and the README sends the reader to `doc/api.md`
- [x] The ContentDB release archive now holds only what the mod needs at runtime, plus the `README.md` and `doc/api.md` a player is told to read. Excluded: hidden files, `tests/`, `scripts/`, the project record, the 8.9 MB screenshot gallery, `doc/*.png` and the GIMP sources - `textures/*.xcf` were shipping inside the archive and no longer do. 1.60 MB down to 1.42 MB. `screenshot.png` is kept deliberately: Luanti shows it in the main menu's Mods tab
- [x] This mod is now versioned and released on its own cadence: the Codecube game adopts a tagged release rather than following every commit here. Added `ROADMAP.md` alongside `TODO.md` and `CHANGELOG.md`, so the mod's plan is readable without the game
- [x] Fixed logging in wiping your entire inventory. It was cleared on every single join; it is now cleared only when one of the drone tools has actually gone missing
- [x] Fixed a crash when saving or deleting a program after reconnecting: the file cache was emptied on disconnect and not rebuilt
- [x] Fixed placing a drone somewhere the server has not loaded - it now says "Cannot place the drone there, move closer" instead of raising an error
- [x] A failed program read now names the file it could not read, instead of printing an internal file handle
- [x] Fixed an unreadable example file taking the whole mod down at load; it is now skipped with a warning
- [x] Fixed an example whose name contains `.lua` anywhere losing that text from its title
- [x] Fixed the editor storing no open tab as a missing value, and storing a number where it reads a string
- [x] Fixed `turn(n)` leaving the drone facing a direction the movement commands did not recognise. Turns were accumulated as radians, so counts such as `turn(11)` or `turn(1000)` drifted a fraction off a quarter-turn and the next `forward`, `move`, `go` or `place_relative` silently did nothing. Turns are now counted in whole quarter-turns
- [x] Unloading a drone that was not running a program no longer reports "The drone has disappeared, program stopped" followed by a completion line for a program that never started
- [x] The drone record now has a single owner: the entity holds only its owner's name and a serial, and a program's outcome is reported from one place instead of three. Removing, replacing or unloading a drone can no longer act on a stale copy of it - placing a second drone no longer risks the departing one taking the new one away with it, or spending its budget
- [x] `lib/commands.lua` went from 971 to 608 lines, with a new `lib/cost.lua` holding what a command spends and when it yields. No player-facing command changed name, arguments or behaviour
- [x] Removed a dead branch in the centred cylinder that could produce a shape with no coordinates
- [x] Added a **default block** for `place()`: a *Settings* panel in the editor, beside Blocks / Plants / Wools / API, picks the block a bare `place()` builds. The choice is yours alone, saved with your player, and read once at the start of every program run, so changing it will not split a build in progress. `air` can be chosen, which makes a bare `place()` erase - useful for carving. **Note for existing programs:** a saved program calling `place()` with no argument built stone before and now builds whatever you have chosen
- [x] Added `default_block(block)`, which changes the default for the rest of one run without touching what you have saved. A program that shares its own default travels with it. It is deliberately run-only: nothing a program does can rewrite your saved choice. One caveat, as with any new name: a saved program that used `default_block` as a global of its own will now fail on that line, because API names cannot be assigned to. A local variable of that name is unaffected
- [x] Added **Create a copy** to the editor, bottom-left below the file list and shown only while a file is open. It writes what is currently on screen to the next free `<name>_N.lua` - `spiral.lua` becomes `spiral_1.lua`, then `spiral_2.lua` - and opens the copy as the active tab, so you can try a variation without touching the version that works. Copying a copy increments rather than piling up suffixes, and the number rather than a word keeps the name the same whatever language the server runs in. It deliberately does **not** save the original first: the original is left exactly as it is on disk, so what you copy is what you can see. A freed number is reused, so copying `foo_2.lua` when `foo_1.lua` has been deleted gives you `foo_1.lua`. One quirk, left alone on purpose: filenames are capped at 15 characters, so copying a name already at the cap has to shorten it to fit `_10` onwards, and the tenth copy starts a new family of names
- [x] A file list is now sorted so `spiral_2.lua` comes before `spiral_10.lua` instead of after it. Both the editor's list and the drone's file chooser use it
- [x] Added `sleep(seconds)`, which pauses the drone for that long and hands the server its step back, so a program can build at a pace it chooses rather than the one its codelevel sets. Fractions are allowed; it defaults to one second. Other drones keep building while yours waits. The wait counts against the same runtime ceiling as everything else and is charged before it starts, so `sleep` cannot be used to make a program live for ever - asking for more time than is left stops the program there. Same caveat as any new name: a saved program that used `sleep` as a global of its own will fail on that line
- [x] Fixed the editor's **Enter** key in the *New file* field doing nothing while a block panel was open. The `+` button always worked
- [x] Fixed the editor throwing away everything typed since the last save whenever the button pressed was not **Save**. Any of the five help/Settings panel buttons, either checkbox, the F1 block picker or `+` re-rendered the text area from the last saved copy, so the edit was gone. Switching tabs with "Save on tab switch" off lost the edit the same way. The text you have typed is now kept in memory on every button, and the option decides only whether it is also written to disk
- [x] Fixed the editor forgetting which files were open, and which one you were on, on three of its exits: the **Load and close** button, leaving or being disconnected with the editor open, and a server shutdown with the editor open. ESC already worked. A form now closes by one path however it was reached, so what the editor holds is written on all of them
- [x] Fixed closing the editor with **ESC** or the window **X** not remembering which files were open, whenever one of the Blocks, Plants or Wools panels was showing - which is the panel the editor opens on, so it was the usual case. Leaving the game and a server shutdown were unaffected. This was the last hole in the exit above; with it closed, *Load program on exit* also takes effect when you leave by ESC
- [x] The two editor checkboxes, **Load program on exit** and **Save on tab switch**, now start **ticked** for a player who has never set them. They could not previously tell a box you had unticked from one you had never seen, so both started off; an untick you make yourself is still honoured. Note for an existing world: a player created before this release had an explicit "off" stored for them at the moment they joined, and that is honoured as a deliberate choice - the ticked default is what a player joining from now on sees
- [ ] Known: the file manager, the code editor and placing a drone in the world have no automated tests - the suite runs before a map or a player exists, so those paths are checked by review only. The drone record's own teardown and stepping are covered
- [ ] Known: `heap_mb` cannot stop one huge allocation; a pathological Lua pattern can still burn CPU inside a single `find` or `match`
- [ ] Known: the step budget is checked between drone commands and between the slabs of a shape, never inside one, so a single slab - a few thousand nodes, around 10 ms - still overshoots it
- [ ] Known: the map footprint decays linearly over the unload window rather than tracking each block, so it is an estimate of what is resident, not a measurement
- [ ] Known: `place()` still writes one node per call and is not batched, unlike the four bulk shapes
- [ ] Known: a file can only be removed from the editor once it has been opened - the *Remove file* button appears only with a file open. Deliberately left as it is for this release
- [ ] Known: nothing in CI checks `.gitattributes`, so a file added to this repository ships inside the release archive unless a rule excludes it, and nothing fails locally when one does

# v0.7.0

- [x] Minetest v5.5 compatible
- [x] UI Fixes
- [x] Refactoring (blocks, examples)
- [x] Players now start with codelevel=4
- [x] Examples are generated when newplayer join
- [x] Moved optional dependencies to dependencies

# v0.6.0

- [x] add call yield
- [x] fix english translation
- [x] add help next to code editor (commands and block list)
- [x] optional depends on vector3, worldedit, wool, etc
- [x] added max number of functions/loops calls before yield
- [x] get block at drone position
- [x] function that returns a block at random in a list of blocks

# v0.5.0

- [x] update README (commands, directory)
- [x] check player meta state on join
- [x] editor : add options to create/remove files
- [x] change to 'close file'
- [x] checkboxes translations
- [x] editor : add checkboxes to save/load on exit (fix bug?)
- [x] filesystem : change to file names instead of indexes
- [x] file : put an initial simple example.lua ready to use
- [x] filesystem : handle removed/added files when restoring editor state

# v0.4.0

- [x] set drone limits/speed with authlevel (volume, calls, commands, dimension)
- [x] api now have a custom vector library
- [x] corrected centered shapes placement
- [x] tool fixes/textures

# v0.3.0

- [x] add cylinder() and dome()
- [x] WE center placing functions
- [x] separate H and V cylinder and centered funcitons
- [x] sanity checks of input types -> abs values !
- [x] fix trad
- [x] fix centered cylinders placement
- [x] rewrite programs with appropriate functions
- [x] review max volume allowed
- [x] update list of commands in README and contentDB

# v0.2.0

- [x] safe formspecs
- [x] check compatible versions of minetest
- [x] add turn(n) ?
- [x] add sphere()
- [x] add cube()
- [x] add move(r,f,u)
- [x] relative positioning
- [x] checkpoint saves drone dir
- [x] use minetest.write
- [x] remove error() when possible
- [x] default drone move by 1
- [x] drone label with program
- [x] remove drone on leave