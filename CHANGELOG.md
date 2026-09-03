# v1.0.0 (unreleased)

**Breaking for existing player programs, for server operators and for
redistributors.** The sixteen items under *Breaking* change behaviour you may be
relying on.

## Breaking

- Wool names lost their prefix: `wools.wool_red` is now `wools.red`
- `color(v, min, max)` clamps instead of wrapping past the palette
- `round(x, decimals)` fixed, its arguments having been the reverse of what was documented
- API names are read-only: assigning to `place`, `blocks`, etc. now raises. A saved program using an API name as its own global fails on that line
- Unavailable names (`os`, `io`, `pcall`, ...) fail immediately, naming what you asked for
- Generating the examples no longer overwrites existing files (the command is now `/codeblock generate`)
- Dropped the `worldedit` dependency: cube, sphere, dome and cylinder are now `lib/shapes.lua`, one VoxelManip pass each
- Relicensed GPL-3.0-only to AGPL-3.0-only, matching the Codecube game
- **The per-codelevel limits were rewritten around the resources a program actually spends.** `max_calls`, `max_commands`, `max_volume`, `max_distance`, `max_dimension`, `max_mapblocks`, `commands_before_yield` and `calls_before_yield` are gone; `max_runtime_s`, `max_nodes_written`, `map_memory_mb` and `pace_ms` replace them, and `max_memory_kb`/`max_string_bytes` became `heap_mb`/`max_string_mb`. No API name changed, but a `minetest.conf` setting an old name now warns in the log and does nothing, naming its replacement
- **Codelevels 1 and 2 are paced:** the drone waits 250 ms (level 1) or 5 ms (level 2) after every command, so a beginner can watch the loop happen. Levels 3 and 4 do not wait. Set `codeblock_pace_ms` to change it
- A program is limited in how much of the world it holds at once (`map_memory_mb`) rather than how many mapblocks it loads in total. Over the ceiling it is slowed down rather than stopped, because the engine frees idle mapblocks by itself
- Nothing limits a shape's dimensions or the drone's distance from home. What bounds a shape is `max_nodes_written`, and a large one is written in slabs with a pause between them, so it no longer freezes the server — a 150-node cube stalled it for 0.44 s
- **The default codelevel for a *new* player is 3 in singleplayer and 2 on a server**, instead of 4 everywhere. Level 3 already waits for nothing, so the single player loses no speed; level 4 is the widest set of ceilings there is and is now given out only when asked for. Existing players keep the level stored in their meta, so upgrading a server demotes nobody — and tightens nobody either. Set `codeblock_default_auth_level` to override
- **The per-codelevel numbers were retuned.** `max_nodes_written` is now `1e5 / 5e5 / 1e6 / 5e7` (was `2e5 / 1e6 / 1e7 / 1e8`) — **the ceiling on how much a program may build is a tenth of what it was at levels 1 to 3**, while level 4, which waits for nothing and is given out only when asked for, keeps room for a 368-node cube. `max_runtime_s` became `30 / 60 / 120 / 300`, and note what it counts: time the drone was actually *advanced*, which for a fast level is under a tenth of the clock — 300 s of it is hours of building, and a program that never finishes still stops in minutes. Level 2 gained room in three places: `pace_ms` 15 → 5 ms, `map_memory_mb` 16 → 32, `max_string_mb` 4 → 8. **A saved program that fitted before may not now** — a shape over the new ceiling is refused with *"Maximum number of nodes written"*, and the fix is a smaller shape or a higher codelevel. `cube(200,200,200)`, for instance, needs codelevel 4 where level 3 used to do
- **`/codelevel` and `/codegenerate` are now `/codeblock level` and `/codeblock generate`.** One command with subcommands instead of two top-level names, plus the new `/codeblock tools`. **There are no aliases:** the old names report an unknown command. Bare `/codeblock`, or a subcommand that does not exist, prints the three usages. Privileges are unchanged — `tools` and `generate` are free for your own files and need the `codeblock` privilege for someone else's; `level` needs it either way, for yourself included, because a codelevel is what bounds what a program may spend
- **The two drone tools are no longer put into your inventory when you join.** This mod stops writing into a player's inventory at all: take the **Drone placer** and the **Drone setter** from the creative inventory, or run **`/codeblock tools`**, which adds whichever of the two you are not already carrying and refuses cleanly if `main` is full. Both tools can now be **dropped**, which they could not be before — there is a way to get them back. **Note for a server with no creative inventory:** the command is the only route, and a first-join chat line names it
- **Installing this mod no longer grants `fly`, `fast` and `noclip` to every new player.** It did, in any game, unguarded, with no way for the game to decline — and nothing here needs creative movement: the drone flies, the player does not. Removed outright rather than put behind a setting. **Note for a server:** if your players were relying on those privileges, they were coming from this mod and now they will not; grant them in your own configuration

## Added

- **A default block for `place()`**: a *Settings* panel in the editor picks the block a bare `place()` builds. Saved with your player and read once at the start of every run, so changing it will not split a build in progress. `air` can be chosen, which makes a bare `place()` erase. **Note:** a saved program calling `place()` with no argument built stone before and now builds whatever you have chosen
- `default_block(block)`, which changes the default for the rest of one run without touching what you have saved. Deliberately run-only: nothing a program does can rewrite your saved choice
- `sleep(seconds)`, which pauses the drone and hands the server its step back, so a program can build at a pace it chooses. Fractions allowed; defaults to one second. Other drones keep building while yours waits. The wait counts against the same runtime ceiling as everything else and is charged before it starts, so `sleep` cannot make a program live for ever
- **Create a copy** in the editor: writes what is on screen to the next free `<name>_N.lua` and opens it, so you can try a variation without touching the version that works. It does **not** save the original first — what you copy is what you can see. A freed number is reused. One quirk: filenames cap at 15 characters, so copying a name already at the cap shortens it to fit `_10` onwards
- **A `*` on an editor tab whose text differs from the file on disk**, so you can see the editor is holding an unsaved edit. It clears when the file is written. Display only — the file is still called `spiral.lua`. This exists because leaving with **ESC** discards an unsaved buffer without asking, which is correct and was invisible
- **A live view of what a running program is spending**, in two places. A block in the top-right corner while your program runs: the file and whether it is running or paused, then `Budget usage` and one line each for **Blocks**, **CPU** and **Memory** as percentages. The limit reached first is **amber**, anything at 80% or more **red**, and a run nowhere near a ceiling shows no colour. And **left clicking with the drone setter** opens a panel, wherever you are aiming: every limit with what the run has spent beside it and what each one means, plus **Pause** and **Stop**. It answers for all three states, including when you have no drone at all. **Note, this changes an existing gesture:** that click used to end the run outright with nothing asked. A paused program holds its place indefinitely, is charged no running time, and gives its share of the server's step to other drones. The corner display can be turned off per player in the editor's *Settings* panel, or for everyone with `codeblock_drone_hud = false`; a player's own choice wins
- **`/codeblock tools`**, which puts the Drone placer and the Drone setter in your main inventory on demand, replacing the hand-out on join. It adds only what is missing, so running it twice does not leave you with four tools, and it counts one parked in your craft grid as carried. With the `codeblock` privilege it works on another player
- **A warning when a program names a block that does not exist.** `place(blocks.notablock)` used to build your default block and say nothing, because a missing name reads as no name at all and *no name* means *use the default*. It now says which name was wrong, **once per run**, and carries on building with the default rather than stopping. A string that is not a block — `place('notablock')` — was always an error and still is. **One consequence:** a program testing `if blocks[name] then` on a name that is not there now produces that one line too
- A file list sorted so `spiral_2.lua` comes before `spiral_10.lua`. Both the editor's list and the drone's file chooser use it
- `settingtypes.txt`: every codelevel limit is settable from the settings menu under Mods, or in `minetest.conf`. Read at load, so a change needs a restart; a malformed value warns and falls back. It is **generated from the code and checked in CI**, so the numbers the menu offers cannot disagree with the mod's real defaults, and a setting the mod reads cannot be missing from the menu
- `server_step_budget_us`: all running drones share one slice of each server step instead of each having its own, so sixteen drones no longer cost sixteen budgets. `step_budget_us` became a per-drone cap on that share, and a waiting drone takes no share at all
- `heap_mb` against runaway accumulation, checked where the drone yields, and `max_string_mb` bounding `("x"):rep(1e9)` and amplifying `gsub`
- A test suite (`tests/`): six specs run standalone under Lua 5.1, all nine in-engine via `codeblock_run_tests`. Plus luacheck and CI, which this repository had none of
- `ROADMAP.md` alongside `TODO.md` and `CHANGELOG.md`: this mod is now versioned and released on its own cadence, and the Codecube game adopts a tagged release rather than following every commit

## Changed

- `repeat ... until` now works — it was refused outright before
- The drone advances for a time budget each server step instead of exactly one coroutine resume, so throughput follows the headroom the server has spare
- The step budget is honoured at every drone command and before every slab of a bulk shape, rather than only between resumes
- `place()` calls `core.load_area` once per mapblock the drone crosses into instead of once per node
- The drone is kept inside the world edge (`mapgen_limit`) instead of within a distance of its spawn point: past that edge a write silently does nothing, which is the failure the distance limit stood in for
- Removed `max_minetest_version`; raised `min_minetest_version` 5.3 → 5.4 (`formspec_version[4]`)
- Dropped the `formspecs` dependency: form sessions are now `lib/forms.lua` on `core.show_formspec`
- `doc/api.md` and the in-game help are generated from `lib/api.lua`, which also builds the sandbox environment. Removed `doc/commands.md`, `doc/api.html` and their two generator scripts, a superseded pipeline nothing referenced
- `lib/commands.lua` went from 971 to 608 lines, with a new `lib/cost.lua` holding what a command spends and when it yields. No player-facing command changed
- The drone record has a single owner: the entity holds only its owner's name and a serial, and a program's outcome is reported from one place instead of three
- **The drone panel and HUD were rewritten after their first playtest.** Neither mentions *map memory* any more — that row is a throttle rather than a deadline, so it sits at 100% for any large build by design and was drowning out the three limits that actually stop a program. And *Running time* became **Server time used**, because it never was clock time: a drone is charged only the time the server gave it, roughly a tenth of the time you watch pass. Nothing about what is counted changed. Long counts read as `1.2K / 10.0M`; each limit's name is bold with its explanation underneath, and the panel's heading carries the program name in **bold** with its state in **green** or **yellow**
- The panel opens **whatever the drone is doing** — including when you have no drone at all, where it says so rather than doing nothing
- **The panel's heading says how long the run has been going**, as `spiral.lua : running (6m 27s)`. That is clock time, and deliberately not the *Server time used* row beside it, which counts only the time the server gave your drone — the two disagreeing by a factor of twenty is expected. **It stops while a run is paused** and picks up where it left off, so what it shows is how long the build has taken rather than how long ago you started it — and the `duration:` in the completion line is the same number. An idle drone reads `spiral.lua : idle` in the same shape, instead of a sentence
- The HUD's third line is **CPU time**, not *CPU*, which read as a percentage of a processor rather than a share of the time budget
- **Both displays now refresh once a second rather than twice.** The reason is the panel, not the HUD: re-sending a formspec makes the client rebuild every element in it, and a button press that was in flight when that happens is thrown away — which is why a panel button sometimes needed a second click. A slower refresh halves how often that can happen. The two surfaces share one beat deliberately, so a number can never differ between them
- The editor's three preference checkboxes — **Load program on exit**, **Save on tab switch** and **Show the drone HUD** — moved onto the **Settings** panel, from loose along the form's bottom edge
- The two editor checkboxes start **ticked** for a player who has never set them. **Note for an existing world:** a player created before this release had an explicit "off" stored at the moment they joined, honoured as a deliberate choice
- The two tool icons were redrawn, with SVG editable sources; neither source ships in the release archive
- **The bundled examples shrank so every one completes at codelevel 2.** `planet.lua`, `death_star.lua` and `mosely.lua` are smaller
- The release archive holds only what the mod needs at runtime, plus the `README.md` and `doc/api.md` a player is told to read — 1.60 MB of it down to 1.42 MB. It is **2.21 MB** as shipped, the difference being a new `screenshot.png`: Luanti shows that one in the main menu's Mods tab, so it is kept deliberately and is now the current editor rather than a four-feature-old one
- Documented `color()`, and corrected block lists that had drifted from the config

## Fixed

**The sandbox and the preprocessor**

- Code between two block comments being deleted; a standard `--[[ ... ]]` comment leaving its body behind as code; a `--` inside a string truncating it; any identifier containing `function` injecting a statement after the next `)`. Instrumentation now runs over a token stream instead of pattern-matched text
- Programs could corrupt `blocks`/`plants`/`wools`/`iwools`/`vector` for every player, and the injected call counter could be disabled from player code
- Removed `worldedit.lua()` / `worldedit.luatransform()` from the bundled fork before dropping it

**The world**

- `place()` silently doing nothing where the mapblock was not in memory, which left holes in builds away from spawn — and the same lost write returning through the call path, so a program whose pauses came from loops rather than drone commands could skip a mapblock load and lose a node with no error
- `turn(n)` leaving the drone facing a direction the movement commands did not recognise. Turns were accumulated as radians, so counts such as `turn(11)` drifted a fraction off a quarter-turn and the next move silently did nothing. Turns are now counted in whole quarter-turns
- A long shape failing outright instead of building slowly, depending on which way the drone faced. Slabs were always cut across the same axis, so a shape long the other way needed more of the world in memory for one slab than a codelevel allows in total. `cube(2, 2, 30000)` at codelevel 1 completed facing north and died facing east. Slabs now follow the shape's longest axis. Nothing had been built when it failed
- Bulk shapes loading a node-thick layer of the world they never build into. `cube`, and `cylinder` along its length, asked for a region one node larger than the shape on every axis — free where that fell inside a chunk already being loaded, and a whole extra layer of chunks where it did not, which on a thin shape is a doubling. The same call took 78 seconds facing one way and 183 facing another
- A dead branch in the centred cylinder that could produce a shape with no coordinates

**The drone**

- **Logging in wiping your entire inventory.** Joining used to empty your hotbar, main inventory and craft grid before handing you the two drone tools. **Nothing is cleared now.** This took two goes — the first narrowed the wipe to "only when a tool has gone missing", which turned out to be exactly the first join after the mod is installed, so **adding this mod to a world that already had players wiped their inventories on the next join**. If you installed an earlier development version into an existing world, that is what happened, and it is not recoverable
- The drone poser doing nothing at all when aimed at no node — into the sky, or past what your client has loaded. That gesture reaches a different engine callback, and the mod had left it empty. It now says *"Please target a node"*, which also makes *"move closer"* reachable in practice for the first time
- Cancelling the drone's file chooser leaving a drone behind, named `?.lua` and answering *"Not a valid file"* on every use. The drone is now taken back when you decline
- Removing a program leaving the drone holding it standing in the world, only disappearing the next time you tried to run it. The drone now goes with the file — the same answer as cancelling the chooser
- A runtime error reporting twice and leaving the coroutine attached; and unloading a drone that was not running reporting *"The drone has disappeared"* followed by a completion line for a program that never started
- Placing a drone somewhere the server has not loaded now says *"Cannot place the drone there, move closer"* instead of raising

**The editor and files**

- **Every bundled example showing as unsaved the moment you clicked away from it.** Opening several programs put the unsaved `*` on all of them but the one you were looking at, without a keystroke. The examples ship with Windows line endings and your client sends back Unix ones, so the editor compared the two and concluded you had edited every file it had not written itself. Program files are now read as Unix line endings whatever they hold on disk
- **The editor throwing away everything typed since the last save whenever the button pressed was not Save.** Any of the five help/Settings panel buttons, either checkbox, the block picker or `+` re-rendered the text area from the last saved copy. Switching tabs with *Save on tab switch* off lost the edit the same way. Typed text is now kept in memory on every button, and the option decides only whether it is also written to disk
- The editor forgetting which files were open on three of its exits: **Load and close**, being disconnected, and a server shutdown. A form now closes by one path however it was reached
- Closing with **ESC** or the window **X** not remembering the open tabs whenever a Blocks, Plants or Wools panel was showing — which is the panel the editor opens on, so it was the usual case
- The **Enter** key in the *New file* field doing nothing while a block panel was open. The `+` button always worked
- The editor's two checkboxes doing nothing (`0` is truthy in Lua), and the help panel opening on Blocks with no way to reach Plants, Wools or API until a file was open
- The editor storing no open tab as a missing value, and a number where it reads a string
- A crash when saving or deleting a program after reconnecting: the file cache was emptied on disconnect and not rebuilt
- **A program file is read up to a size limit rather than whole.** One too large is refused by name and by size instead of being loaded into memory and sent to your screen. A 168 MB file sitting in a player's directory took the server to about 14 GB, froze the game on exit and froze it again the next time the editor was opened. The limit is **128 kB**, settable as `codeblock_max_file_kb`. **Note for an existing world:** a file already over the ceiling stops opening, and the ceiling cannot be raised from inside the game
- A failed program read naming the file it could not read, instead of printing an internal file handle — and a file the server cannot read no longer reports the full path to it, in English regardless of the game's language. The operating system's reason goes to the server log
- An unreadable example file taking the whole mod down at load; it is now skipped with a warning. And an example whose name contains `.lua` anywhere losing that text from its title

**Commands, documentation and translation**

- `/codeblock level` being unusable in singleplayer, and `/codeblock generate` having no privilege check and ignoring its playername — both under their old names, `/codelevel` and `/codegenerate`
- The reported duration of a program: on a Linux server it was the whole server's CPU time. The completion line now reads `commands:N nodes:N duration:X.XXs`
- **The check that every codelevel limit has a documented row — twice, the first attempt having been just as dead as the one it replaced.** It first matched by name prefix and so never checked `pace_ms`, `heap_mb` or `map_memory_mb`; the replacement matched by shape and, because Lua's `%w` excludes the underscore that every limit name contains, matched **nothing at all** from the day it was written. No row was ever actually missing. Both the reference check and the new settings check now match correctly, and each has been run against a deliberately undocumented limit to prove it can fail
- **The French translation**, which was missing twelve of the mod's messages and carried seventeen that no longer exist. Three more looked translated and were not: a message whose text had been changed by a single character silently stopped matching its translation. One message could never have been translated at all, its text being assembled in two pieces and so invisible to anything collecting strings. `locale/template.txt` is now generated from the source and checked in CI
- **Joining no longer rewrites your sky.** Installing this mod used to hold every player's world at permanent noon and hide the sun, moon, stars and clouds, with no way to decline — it was there for the Codecube game and followed the mod into every other game. If you want that flat, sunless sky it is now `codeblock_flat_sky`. **Note for the Codecube game:** set it, or your world gets its day/night cycle back on the next join

## Known limitations

- The file manager, the code editor and placing a drone in the world have no automated tests — the suite runs before a map or a player exists, so those paths are checked by review and by hand
- `heap_mb` cannot stop one huge allocation; a pathological Lua pattern can still burn CPU inside a single `find` or `match`
- The step budget is checked between drone commands and between the slabs of a shape, never inside one, so a single slab — a few thousand nodes, around 10 ms — still overshoots it
- A shape large in **two** dimensions at once still asks for more of the world in memory than a codelevel allows in one slab, and the run stops rather than waiting. Only one axis can be sliced away
- The map footprint decays linearly over the unload window rather than tracking each block, so it estimates what is resident rather than measuring it
- Nothing on screen says why a drone is slow: the map row was deliberately dropped from both displays
- **A drone panel button can still miss a click** — a few presses in twenty if you click quickly, where it used to be closer to one in five. The panel refreshes itself while a program runs, and the client rebuilds the whole form each time; a press held across that moment is dropped silently. Press it again. Closing the gap completely would mean a panel that does not update on its own
- `place()` still writes one node per call and is not batched, unlike the four bulk shapes
- A file can only be removed from the editor once it has been opened — the *Remove file* button appears only with a file open
- The unsaved-tab `*` records that the buffer changed, not that it differs from disk, so typing a character and undoing it leaves the tab marked until the next save
- Nothing in CI checks `.gitattributes`, so a file added to this repository ships inside the release archive unless a rule excludes it, and nothing fails locally when one does

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
