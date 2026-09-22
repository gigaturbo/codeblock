# v1.0.0

The first release that installs into any game. Three changes carry the rest: the
mod brings its own blocks instead of borrowing Minetest Game's, the per-codelevel
limits now measure what a program really spends, and a running program no longer
dies when nobody is watching it.

**Read *Breaking* first.** Every block name a program writes has changed, and no
game can migrate a saved program for you.

## Breaking

### Blocks and colours

- **Every block name has changed, and the mod now brings its own blocks.**
  `blocks`, `plants`, `wools` and `iwools` are gone, replaced by `colors`,
  `glass`, `lamps`, `hues` and `air`. `place(blocks.stone)` becomes
  `place(colors.grey)` by hand. The bundled examples were all ported.
- **Why it was worth it.** `default` and `wool` are Minetest Game's and are not
  ContentDB packages, so the engine refused to load this mod in any game that
  lacked them. It now installs anywhere, and a program means the same thing
  everywhere.
- **`color(v, min, max)` is replaced by `ramp`, with no alias.**
  `ramp.hues(v, min, max)` is what `color` was, a number mapped onto the colour
  wheel. `ramp.of(list, v, min, max)` maps a number onto any array, so
  `glass[ramp.of(dark_hues, v, 1, n)]` ramps one material. Both clamp at the
  ends instead of wrapping.
- **One random picker, `random.of(list)`, with no alias.** `random.block`,
  `random.plant`, `random.wool` and `table.randomizer` are removed.
  `random.of(colors)` is what `random.block` was, and `random.hues()` answers a
  colour name, so `lamps[random.hues()]` is the matching lamp.
- **The `table` namespace has left player code entirely.** `randomizer` was the
  only thing on it, so `table.randomizer(t)` now raises *attempt to index global
  'table'* on that line. Write `function() return random.of(t) end` instead.

### The sandbox

- **API names cannot be reassigned.** Using `place` or `colors` as your own
  global fails on that line. The tables themselves are still writable, but each
  run gets its own copies, so nothing a program does escapes it.
- **Unavailable names fail immediately.** `os`, `io`, `pcall` and the rest name
  what you asked for instead of reading as nil and failing further down.
- **`round(x, decimals)` takes its arguments in that order.** They were the
  reverse of what the documentation said, so `round(3.14159, 2)` returned about
  2.

### Limits and codelevels

- **The limits were rewritten around resources a program actually spends.**
  `max_calls`, `max_commands`, `max_volume`, `max_distance`, `max_dimension`,
  `max_mapblocks`, `commands_before_yield` and `calls_before_yield` are gone.
  `max_runtime_s`, `max_nodes_written`, `map_memory_mb` and `pace_ms` replace
  them, and `max_memory_kb` and `max_string_bytes` became `heap_mb` and
  `max_string_mb`. An old name in `minetest.conf` warns at load, and names what
  took over from it where something did.
- **The numbers were retuned, and a program that fitted before may not now.**
  `max_nodes_written` is `1e5 / 5e5 / 1e6 / 5e7`, a tenth of what it was at
  levels 1 to 3; `max_runtime_s` is `30 / 60 / 120 / 300`, counting only time
  the server actually gave your drone. A shape over the ceiling is refused with
  *"Maximum number of nodes written"*, and the fix is a smaller shape or a
  higher codelevel.
- **Nothing limits a shape's dimensions or the drone's distance from home.**
  `max_nodes_written` bounds a shape instead, and a large one is written in
  slabs with a pause between them, so it no longer freezes the server.
- **Codelevels 1 and 2 are paced.** The drone waits 250 ms at level 1 and 5 ms
  at level 2 after every command, so a beginner can watch the loop happen.
  Levels 3 and 4 do not wait. Set `codeblock_pace_ms` to change it.
- **A program is bounded by how much world it holds at once, not by how much it
  loads.** Over the `map_memory_mb` ceiling it is slowed down rather than
  stopped, because the engine frees idle mapblocks by itself.
- **The default codelevel for a new player is 3 in singleplayer and 2 on a
  server**, instead of 4 everywhere. Level 3 already waits for nothing, so a
  single player loses no speed. Existing players keep the level in their meta,
  so upgrading demotes nobody. Set `codeblock_default_auth_level` to override.

### Commands and tools

- **`/codelevel` and `/codegenerate` are now `/codeblock level` and
  `/codeblock generate`, with no aliases.** The old names report an unknown
  command. Bare `/codeblock`, or an unknown subcommand, prints the three usages.
- **The two drone tools are no longer put into your inventory when you join.**
  This mod stops writing into a player's inventory at all: take them from the
  creative inventory or run `/codeblock tools`. Both tools can now be dropped,
  which they could not be before.

### Server operators

- **Installing this mod no longer grants `fly`, `fast` and `noclip` to every new
  player.** It did so in any game, unguarded. If your players relied on them,
  they came from here and now will not; grant them in your own configuration.
- **Joining no longer rewrites your sky.** The mod used to hold every world at
  permanent noon and hide the sun, moon, stars and clouds. Those five overrides
  are gone, with no setting to restore them.

### Packaging and dependencies

- **Dropped the `worldedit` dependency.** `cube`, `sphere`, `dome` and
  `cylinder` are now `lib/shapes.lua`, one VoxelManip pass each. `mod.conf`
  reads `depends = vector3` and nothing else.
- **Relicensed from GPL-3.0-only to AGPL-3.0-only**, matching the Codecube game.
- **`codeblock.utils` is gone**, and a mod reading anything on it now reads nil.
  Four entries moved: `path_join` to `codeblock.path_join`, `check_auth_level`
  to `codeblock.config.check_auth_level`, `parse_target` to
  `codeblock.parse_target`, `html_commands` to `codeblock.api.html_commands`.
  The rest are private or deleted.
- **`vector3` 2.0 behaves differently from 1.5, and either may be installed.**
  Luanti gives a mod no way to ask for a version. In 2.0 the named constants are
  read only outside a program, `pairs()` over one sees nothing, and a bad
  argument raises instead of answering quietly. **Install 2.0.2 or newer:**
  before that, a sandboxed program could change what `vector` does for every
  other mod on the server. The mod warns in the log when it finds an older one.

## Added

### Writing programs

- **`get_block(right, up, forward)` reads without moving the drone.** The three
  offsets are optional and turn with the drone. It loads the map it reads, so a
  block the drone has never visited answers properly: a block name, `false` for
  a node you could not place, or nil where there is no answer at all.
- **`is_block(block, right, up, forward)`** asks whether the block at an offset
  is the one you named, as in `if is_block(air, 0, 0, 1) then forward(1) end`.
  It answers true only on an exact match, so everything else is false. Use
  `get_block` when you need to tell those cases apart.
- **`sleep(seconds)`** pauses the drone and hands the server its step back, so
  other drones keep building while yours waits. Fractions are allowed, and a
  missing or non-positive argument means one second. The wait is charged against
  the runtime ceiling before it starts, so `sleep` cannot make a program live
  for ever.
- **`default_block(block)`** changes the default for the rest of one run without
  touching what you have saved. Nothing a program does can rewrite your saved
  choice. Unlike `place()`, an unknown name here raises rather than falling
  back.
- **Four ways of walking the palette.** `hues` is joined by `light_hues`,
  `dark_hues` and `neutrals`, ordered arrays of colour names rather than blocks.
  Every block table is indexed by the same names, so four arrays across three
  categories give twelve gradients: `place(dark_hues[i])`,
  `glass[dark_hues[i]]`, `lamps[dark_hues[i]]`.
- **A warning when a program names a block that does not exist.**
  `place(colors.notablock)` used to build your default silently. It now says
  which name was wrong, once per run, and carries on with the default.

### The editor

- **A default block for `place()`.** A *Settings* panel picks what a bare
  `place()` builds. It is saved with your player and read once per run, so
  changing it cannot split a build in progress. `air` can be chosen, which makes
  a bare `place()` erase.
- **Create a copy** writes what is on screen to the next free `<name>_N.lua` and
  opens it, so you can try a variation without touching the version that works.
  It copies what you can see, not what is on disk, and a freed number is reused.
- **A `*` on a tab whose text differs from the file on disk**, so an unsaved
  edit is visible. Leaving with ESC discards that buffer without asking, which
  is correct and was invisible before.
- **A file list sorted so `spiral_2.lua` comes before `spiral_10.lua`**, in both
  the editor's list and the drone's file chooser.

### Watching a program run

- **A live view of what a running program is spending.** A corner block shows
  the file, its state, and `Blocks`, `CPU` and `Memory` as percentages; the
  limit reached first is amber, anything at 80% or more red. It can be turned
  off per player, or for everyone with `codeblock_drone_hud`.
- **Left clicking with the drone setter opens a panel** showing every limit
  against what the run has spent, with **Pause** and **Stop**. **This changes an
  existing gesture:** that click used to end the run outright with nothing
  asked. A paused program holds its place indefinitely and is charged no running
  time.

### Commands

- **`/codeblock tools`** puts the Drone placer and Drone setter in your
  inventory on demand, replacing the hand-out on join. It adds only what is
  missing and counts one parked in your craft grid as carried.
- **`/codeblock level` now reports a codelevel.** Nothing in the mod would tell
  you what bounded your programs; the only way to learn it was to hit a ceiling.
  Reading your own is free, reading someone else's needs the `codeblock`
  privilege, and setting still needs it either way.

### For server operators

- **`settingtypes.txt`:** every codelevel limit is settable from the settings
  menu under Mods, or in `minetest.conf`. It is generated from the code and
  checked in CI, so the menu cannot disagree with the mod's real defaults.
- **`server_step_budget_us`:** all running drones share one slice of each server
  step instead of each having its own, so sixteen drones no longer cost sixteen
  budgets. `step_budget_us` became a per-drone cap on that share.
- **`heap_mb` and `max_string_mb`** bound runaway accumulation and a single huge
  allocation such as `("x"):rep(1e9)`.

### For game authors

- **`codeblock.register_blocks(category, entries)`.** A mod that depends on
  `codeblock` can add a block category of its own, and `wool.red` becomes a
  block a program can place, listed in the editor beside `colors`. A bad entry
  is logged naming your mod and dropped, never aborting the server.
- **A category costs a game one name, not two.** There is no `ramp.wool`: reach
  it in order with `ramp.of(wool, v, 1, n)`, which walks it alphabetically, and
  at random with `random.of(wool)`.

### The project

- **A test suite.** Six specs run standalone under Lua 5.1 and all nine in a
  real Luanti server in CI, so the three that need the mod loaded are covered by
  every push. This repository had neither tests nor CI before.
- **`ROADMAP.md` beside `TODO.md` and `CHANGELOG.md`.** The mod is versioned and
  released on its own cadence, and the Codecube game adopts a tagged release
  rather than following every commit.

## Changed

### Programs and the drone

- **`print` takes any number of arguments**, joined by a space, so a label and a
  value go out in one line. It took exactly one before. `nil` prints as `nil`,
  which matters because `get_block()` answers nil over ungenerated map.
- **`repeat ... until` now works.** It was refused outright before.
- **The drone advances for a time budget each server step** instead of exactly
  one resume, so throughput follows the headroom the server has spare. The
  budget is honoured at every command and before every slab of a bulk shape.
- **`place()` loads the map once per mapblock the drone crosses into**, rather
  than once per node.
- **The drone is kept inside the world edge (`mapgen_limit`)** instead of within
  a distance of its spawn point. Past that edge a write silently does nothing,
  which is the failure the distance limit stood in for.
- **The drone record has a single owner.** The entity holds only its owner's
  name and a serial, and a program's outcome is reported from one place instead
  of three.

### The editor and displays

- **The drone panel and HUD were rewritten after their first playtest.** Neither
  mentions *map memory* any more: that row is a throttle rather than a deadline,
  so it sat at 100% for any large build and drowned out the three limits that
  actually stop a program.
- **`Running time` became `Server time used`**, because it never was clock time.
  A drone is charged only the time the server gave it, roughly a tenth of the
  time you watch pass. Nothing about what is counted changed.
- **The panel's heading says how long the run has taken**, as
  `spiral.lua : running (6m 27s)`. That is clock time, deliberately not the row
  beside it, and it stops while a run is paused.
- **Both displays refresh once a second rather than twice.** Re-sending a
  formspec makes the client rebuild it, and a button press in flight at that
  moment is thrown away, which is why a panel button sometimes needed a second
  click.
- **The panel opens whatever the drone is doing**, including when you have no
  drone at all, where it says so rather than doing nothing.
- **The three preference checkboxes moved onto the Settings panel**, from loose
  along the form's bottom edge. They now start ticked for a player who has never
  set them.
- **The help row is one `Blocks` button and a category selector** in every game,
  instead of three fixed Blocks / Plants / Wools buttons. It is drawn the same
  whether a game has registered a category or not.

### Packaging and documentation

- **Removed `max_minetest_version`; raised `min_minetest_version` from 5.3 to
  5.4** for `formspec_version[4]`.
- **Dropped the `formspecs` dependency.** Form sessions are now `lib/forms.lua`
  on `core.show_formspec`.
- **`doc/api.md` and the in-game help are generated from `lib/api.lua`**, which
  also builds the sandbox environment. `doc/commands.md`, `doc/api.html` and
  their generators are removed as a superseded pipeline.
- **`lib/commands.lua` went from 971 to 608 lines**, with a new `lib/cost.lua`
  holding what a command spends and when it yields. No player-facing command
  changed.
- **The release archive holds only what the mod needs at runtime**, plus the
  `README.md` and `doc/api.md` a player is told to read. It is 2.00 MB as
  shipped, most of the difference being a current `screenshot.png`.
- **The two tool icons were redrawn**, with SVG sources that do not ship in the
  release archive.

### The bundled examples

- **All fourteen were ported to the new palette** and build the same shapes in
  the nearest colours. `planet.lua`, `death_star.lua` and `mosely.lua` shrank so
  that they complete at codelevel 2.
- **A fourteenth example, `game.lua`:** a lamp that bounces around a walled
  arena it builds for itself, using `get_block` to find the walls and reverse.
  **It is the only example that never ends**, looping until the runtime ceiling
  for your codelevel stops it, which is intended rather than a failure.

## Removed

- **The `default` and `wool` dependencies.** Neither is a ContentDB package, and
  nothing here ever used more than their node names. This is the change that
  lets the mod install into any game, and it is why the whole palette had to be
  replaced.
- **The `blocks`, `plants`, `wools` and `iwools` tables**, replaced as described
  under *Breaking*.

## Fixed

### The sandbox and the preprocessor

- **`print` printing only its first argument and dropping the rest**, with no
  error, so there was no way to print a label beside a boolean. This is not new:
  `print` took a single parameter for the project's whole life and every earlier
  release has it.
- **Four preprocessor defects that silently changed your program.** Code between
  two block comments was deleted, a `--[[ ... ]]` comment left its body behind
  as code, a `--` inside a string truncated it, and an identifier containing
  `function` injected a statement. Instrumentation now runs over a token stream
  rather than pattern-matched text.
- **Programs could corrupt the block tables and `vector` for every player**, and
  the injected call counter could be disabled from player code.
- **The named `vector` constants are each run's own again, on every `vector3`
  version.** `dir = vector.one; dir.x = -1` now changes your copy only. Before,
  on 1.5 that line changed `vector.one` for every player on the server until it
  restarted; on 2.0 it raised `read only`.
- **`pairs`, `table.copy` and `core.serialize` over a `vector` constant work
  inside a program on `vector3` 2.0.x**, where outside one they silently read it
  as empty.

### The world

- **`place()` silently doing nothing where the mapblock was not in memory**,
  which left holes in builds away from spawn. The same lost write also returned
  through the call path, so a program pausing in loops rather than on drone
  commands could skip a load and lose a node with no error.
- **`turn(n)` leaving the drone facing a direction the movement commands did not
  recognise.** Turns were accumulated as radians, so `turn(11)` drifted a
  fraction off a quarter-turn and the next move silently did nothing. They are
  counted in whole quarter-turns now.
- **A long shape failing outright depending on which way the drone faced.**
  Slabs were always cut across the same axis, so `cube(2, 2, 30000)` at
  codelevel 1 completed facing north and died facing east. Slabs now follow the
  shape's longest axis.
- **Bulk shapes loading a node-thick layer of the world they never build into.**
  `cube`, and `cylinder` along its length, asked for a region one node larger on
  every axis, which on a thin shape doubles the map loaded. The same call took
  78 seconds facing one way and 183 facing another.
- **A dead branch in the centred cylinder** that could produce a shape with no
  coordinates.

### The drone

- **Logging in wiping your entire inventory.** Joining used to empty your
  hotbar, main inventory and craft grid before handing you the tools. Nothing is
  cleared now. If you installed a development version into an existing world,
  that is what happened, and it is not recoverable.
- **A program dying when its drone went out of view, or stood still.** A drone
  more than about 200 nodes from any player, or still for half a minute, was
  deleted by the engine along with its program, so a long walk out or a
  `sleep(45)` ended the build. A program now survives both, and `/clearobjects`
  no longer ends a run.
- **A run you stopped yourself being announced as *completed***, with a node
  count a fraction of what the program had asked for. It reads *stopped* now,
  and the counts read as the partial ones they are.
- **The drone poser doing nothing when aimed at no node**, into the sky or past
  what your client has loaded. That gesture reaches a different engine callback
  the mod had left empty. It now says *"Please target a node"*.
- **Cancelling the file chooser leaving a drone behind**, named `?.lua` and
  useless, and removing a program leaving its drone standing in the world. The
  drone now goes with the file either way.
- **A runtime error reporting twice and leaving the coroutine attached**, and
  unloading an idle drone reporting a completion line for a program that never
  started.
- **Placing a drone where the server has not loaded** now says *"Cannot place
  the drone there, move closer"* instead of raising.

### The editor and files

- **A brand new file failing on its first line.** The starting program still
  named a block from before the palette changed, so anything created with `+`
  stopped immediately and built nothing. It now builds a rainbow column and
  names no individual colour, so a future palette change cannot break it again.
- **Every bundled example showing as unsaved the moment you clicked away.** The
  examples ship with Windows line endings and your client sends back Unix ones,
  so the editor concluded you had edited every file it had not written itself.
  Program files are now read as Unix line endings whatever they hold on disk.
- **The editor throwing away everything typed since the last save whenever the
  button pressed was not Save.** Any panel button, either checkbox, the block
  picker or `+` re-rendered the text area from the last saved copy. Typed text
  is now kept in memory on every button.
- **The editor forgetting which files were open on three of its exits:** Load
  and close, being disconnected, and a server shutdown. A form now closes by one
  path however it was reached.
- **Closing with ESC or the window X not remembering the open tabs** whenever a
  block panel was showing, which is the panel the editor opens on.
- **The Enter key in the *New file* field doing nothing** while a block panel
  was open. The `+` button always worked.
- **The two checkboxes doing nothing** (`0` is truthy in Lua), and the help
  panel opening on Blocks with no way to reach the others until a file was open.
- **A crash when saving or deleting a program after reconnecting**: the file
  cache was emptied on disconnect and not rebuilt.
- **A program file is read up to a size limit rather than whole.** A 168 MB file
  in a player's directory took the server to about 14 GB and froze the game. The
  limit is 128 kB, settable as `codeblock_max_file_kb`. **Note:** a file already
  over it stops opening, and the ceiling cannot be raised from inside the game.
- **A failed read naming the file rather than an internal handle**, and no
  longer reporting the full path in English regardless of the game's language.
  The operating system's reason goes to the server log.
- **An unreadable example file taking the whole mod down at load.** It is
  skipped with a warning now, and an example whose name contains `.lua` no
  longer loses that text from its title.

### Commands, documentation and translation

- **A player whose name starts with a digit, a dash or an underscore could not
  be named to any `/codeblock` subcommand.** Both argument parsers demanded a
  leading letter where the engine allows any order, so such a player could not
  be administered through this mod at all, and the answer was a usage line that
  never said why.
- **`/codeblock level` being unusable in singleplayer**, and `/codeblock
  generate` having no privilege check and ignoring its playername, both under
  their old names.
- **The reported duration of a program**, which on a Linux server was the whole
  server's CPU time. The completion line now reads
  `commands:N nodes:N duration:X.XXs`.
- **The check that every codelevel limit has a documented row, twice.** The
  first matched by name prefix and skipped three limits; its replacement matched
  by shape and, because Lua's `%w` excludes underscores, matched nothing at all.
  Both checks now match correctly and have been run against a deliberately
  undocumented limit to prove they can fail.
- **The French translation**, which was missing twelve messages and carried
  seventeen that no longer exist. Three more looked translated and were not.
  `locale/template.txt` is now generated from the source and checked in CI.

## Known limitations

- **No automated tests for the file manager, the code editor or placing a
  drone.** The suite runs before a map or a player exists, so those paths are
  checked by review and by hand.
- **`heap_mb` cannot stop one huge allocation**, and a pathological Lua pattern
  can still burn CPU inside a single `find` or `match`.
- **The step budget is never checked inside a slab**, so a single slab of a few
  thousand nodes, around 10 ms, still overshoots it.
- **A shape large in two dimensions at once** still asks for more of the world
  in memory than a codelevel allows in one slab, and the run stops rather than
  waiting. Only one axis can be sliced away.
- **The map footprint is estimated, not measured.** It decays linearly over the
  unload window rather than tracking each block.
- **Nothing on screen says why a drone is slow**, the map row having been
  deliberately dropped from both displays.
- **A drone panel button can still miss a click**, a few presses in twenty if
  you click quickly. The panel refreshes while a program runs and the client
  rebuilds the whole form, so a press held across that moment is dropped. Press
  it again.
- **`place()` still writes one node per call** and is not batched, unlike the
  four bulk shapes.
- **A file can only be removed once it has been opened**, the *Remove file*
  button appearing only with a file open.
- **The unsaved-tab `*` records that the buffer changed**, not that it differs
  from disk, so typing a character and undoing it leaves the tab marked.
- **Nothing in CI checks `.gitattributes`**, so a file added to this repository
  ships inside the release archive unless a rule excludes it.
- **The mod's 105 blocks are silent**, with no footstep, dig or place sound.
  Every sound set in Luanti belongs to a game, and using one would put this mod
  back to needing a game to provide something.

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
