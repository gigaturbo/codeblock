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
- [x] Fixed logging in wiping your entire inventory. Joining used to empty your hotbar, main inventory and craft grid before handing you the two drone tools. **Nothing is cleared now**: whichever tool is missing is added, and if there is no room for it you are told so in chat instead of having a slot emptied. This took two goes - the first narrowed the wipe to "only when a tool has gone missing", which turned out to be exactly and only the first join after the mod is installed, so **adding this mod to a world that already had players wiped their inventories on the next join**. If you installed an earlier development version of this release into an existing world, that is what happened, and it is not recoverable. A tool parked in the craft grid now counts as carried, so you are no longer handed a duplicate on every join
- [x] Fixed a crash when saving or deleting a program after reconnecting: the file cache was emptied on disconnect and not rebuilt
- [x] Fixed placing a drone somewhere the server has not loaded - it now says "Cannot place the drone there, move closer" instead of raising an error
- [x] Fixed the drone poser doing nothing at all when you aim it at no node - into the sky, or past what your client has loaded. That gesture reaches a different engine callback than aiming at a block does, and the mod had left it empty, so the most natural way to find out how far the tool reaches was the one that answered nothing. It now says "Please target a node". This also means the "move closer" message above is reachable in practice for the first time
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
- [x] An editor tab whose text differs from the file on disk is now marked with a trailing `*`, so you can see at a glance that the editor is holding an edit you have not saved. The mark appears as soon as you type and a button, a tab or a panel sends the text back to the server, and it clears when the file is written - by **Save**, by a tab switch with *Save on tab switch* ticked, or by **Load and close**. It is display only: the file is still called `spiral.lua`, not `spiral.lua*`. This exists because leaving the editor with **ESC** discards an unsaved buffer without asking, which is correct and was invisible
- [x] Added a **live view of what a running program is spending**, in two places. A small display in the top-right corner while your program runs names the file, says whether it is running or paused, and shows the single limit the run is closest to as a percentage, coloured as it fills - so you learn which resource your programs actually spend rather than being told only once they stop. And **left clicking a running drone with the drone setter** now opens a panel: all four limits with what the run has spent beside each ceiling, in the same units `minetest.conf` uses, plus **Pause**, **Resume** and **Cancel**. **Note, this changes an existing gesture:** that click used to end the run outright with nothing asked. It now opens the panel, and **Cancel** is the button that ends it - one click further away, deliberately, because there was no way to undo an accidental one. Left clicking an *idle* drone still takes it away, unchanged. A paused program holds its place indefinitely, is charged no running time while it waits, and gives its share of the server's step to the other drones. The corner display can be turned off per player with *Show the drone HUD* in the editor, or for everyone with `codeblock_drone_hud = false`; a player's own choice wins over the server's
- [x] Fixed the editor's **Enter** key in the *New file* field doing nothing while a block panel was open. The `+` button always worked
- [x] Fixed the editor throwing away everything typed since the last save whenever the button pressed was not **Save**. Any of the five help/Settings panel buttons, either checkbox, the F1 block picker or `+` re-rendered the text area from the last saved copy, so the edit was gone. Switching tabs with "Save on tab switch" off lost the edit the same way. The text you have typed is now kept in memory on every button, and the option decides only whether it is also written to disk
- [x] Fixed the editor forgetting which files were open, and which one you were on, on three of its exits: the **Load and close** button, leaving or being disconnected with the editor open, and a server shutdown with the editor open. ESC already worked. A form now closes by one path however it was reached, so what the editor holds is written on all of them
- [x] Fixed closing the editor with **ESC** or the window **X** not remembering which files were open, whenever one of the Blocks, Plants or Wools panels was showing - which is the panel the editor opens on, so it was the usual case. Leaving the game and a server shutdown were unaffected. This was the last hole in the exit above; with it closed, *Load program on exit* also takes effect when you leave by ESC
- [x] The two editor checkboxes, **Load program on exit** and **Save on tab switch**, now start **ticked** for a player who has never set them. They could not previously tell a box you had unticked from one you had never seen, so both started off; an untick you make yourself is still honoured. Note for an existing world: a player created before this release had an explicit "off" stored for them at the moment they joined, and that is honoured as a deliberate choice - the ticked default is what a player joining from now on sees
- [x] Fixed the French translation, which was missing twelve of the mod's messages and carried seventeen that no longer exist. Three more looked translated and were not: a message whose text had been changed by a single character in the source - a trailing space, a plural, a capital - silently stopped matching its translation, so it came out in English. One message, the refusal when you run `/codegenerate <player>` without the `codeblock` privilege, could never have been translated at all, because its text was assembled in two pieces and so was invisible to anything collecting strings. `locale/template.txt` is now generated from the source and checked in CI, so it cannot quietly fall behind again, and `locale/codeblock.fr.tr` covers every message the mod sends. If you translate this mod, the template is now trustworthy
- [x] A program file is now read up to a size limit rather than whole. One too large is refused by name and by size - in the editor's file list, and when a drone is given it - instead of being loaded into memory and sent to your screen. A 168 MB file that happened to be sitting in a player's directory took the server to about 14 GB, froze the game on exit and froze it again the next time the editor was opened; it is now declined in an instant. The limit is **128 kB**, a program you can edit being a few kilobytes at most, and it is settable as `codeblock_max_file_kb` from the settings menu under Mods. Saving is held to the same limit, so the editor cannot write a file it would then refuse to open. Note for an existing world: a file already over the ceiling stops opening, and the ceiling cannot be raised from inside the game
- [x] Fixed a long shape failing outright instead of building slowly, depending on which way the drone happened to face. A bulk shape is written in slabs so it never freezes the server, and those slabs were always cut across the same axis: a shape long the other way needed more of the world in memory for a single slab than a codelevel is allowed in total, and the program stopped with "Maximum map footprint exceeded" - the message from the one limit that is meant to slow a program down rather than stop it. `cube(2, 2, 30000)` at codelevel 1 completed facing north and died facing east, the same program either way. Slabs now follow the shape's longest axis. Nothing had been built when it failed, so no half-finished shape was ever left behind. A shape large in *two* dimensions at once can still exceed the ceiling in one slab; only one axis can be sliced away
- [x] Joining no longer rewrites your sky. Installing this mod used to hold every player's world at permanent noon and hide the sun, moon, stars and clouds, with no setting and no way to decline - it was there for the Codecube game, whose building world has no day/night cycle, and it followed the mod into every other game it was installed in. Your game's own daylight is now left alone. If you *want* that flat, sunless sky, it is a new setting: `codeblock_flat_sky`, in the settings menu under Mods, or in `minetest.conf`. Note for the Codecube game and anyone who liked the old behaviour: set it, or your world gets its day/night cycle back on the next join
- [x] Cancelling the drone's file chooser no longer leaves a drone behind. Placing the poser with no program chosen opens the file list; declining it - **Cancel** or **ESC** - used to leave a drone standing in the world named `?.lua` that answered "Not a valid file" every time you used it. The drone is now taken back when you decline, and placing again was never refused, so this only ever cost you a puzzle
- [x] Removing a program no longer leaves the drone holding it standing in the world. Delete the file a drone is running and the drone used to stay, still named after a program that no longer existed, and only disappear the next time you tried to run it. The drone now goes with the file - the same answer as cancelling the file chooser above, so the two cases behave alike. Removing a file and *then* placing a new drone was always fine and still is: it opens the file chooser
- [x] Bulk shapes no longer load a node-thick layer of the world they never build into. `cube`, and `cylinder` along its length, asked the server for a region one node larger than the shape on every axis. Where that extra node fell inside a chunk of world already being loaded it cost nothing; where it did not, it cost a whole extra layer of chunks - and for a thin shape that is a doubling rather than a rounding error. `cube(2, 2, 30000)` took 78 seconds facing one way and 183 facing another, the same program either way, because which extent crossed a chunk boundary depended on which way the drone was pointing. A large shape now holds less of the world and finishes in a time that does not depend on where you were looking when you placed the drone
- [x] Fixed a file the server cannot read reporting the full path to that file on the server, in English regardless of the game's language. It now names just the file, like every other refusal, and the operating system's reason goes to the server log where an administrator can see it
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
