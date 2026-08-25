# v1.0.0 (unreleased)

Breaking for existing player programs and for redistributors - the first six
items below change behaviour you may be relying on.

- [x] **BREAKING** wool names lost their prefix: `wools.wool_red` is now `wools.red`
- [x] **BREAKING** `color(v, min, max)` clamps instead of wrapping past the palette
- [x] **BREAKING** API names are read-only: assigning to `place`, `blocks`, etc. now raises
- [x] **BREAKING** unavailable names (`os`, `io`, `pcall`, ...) fail immediately, naming what you asked for
- [x] **BREAKING** `/codegenerate` no longer overwrites existing files
- [x] **BREAKING** relicensed GPL-3.0-only to AGPL-3.0-only, matching the Codecube game
- [x] Removed `max_minetest_version`; raised `min_minetest_version` 5.3 to 5.4 (`formspec_version[4]`)
- [x] `repeat ... until` now works - it was refused outright before
- [x] Fixed the preprocessor deleting code between two block comments
- [x] Fixed a standard `--[[ ... ]]` comment leaving its body behind as code
- [x] Fixed a `--` inside a string truncating the string
- [x] Fixed any identifier containing `function` injecting a statement after the next `)`
- [x] Instrumentation now runs over a token stream instead of pattern-matched text
- [x] Programs can no longer corrupt `blocks`/`plants`/`wools`/`iwools`/`vector` for every player
- [x] The injected call counter can no longer be disabled from player code
- [x] Bounded `("x"):rep(1e9)` and amplifying `gsub` (new `max_string_bytes`)
- [x] Added `max_memory_kb` against runaway accumulation, checked at yield points
- [x] Fixed the editor's two checkboxes doing nothing (0 is truthy in Lua)
- [x] Fixed the editor's help panel opening on Blocks with no way to reach Plants, Wools or API until a file was open
- [x] Fixed `/codelevel` being unusable in singleplayer
- [x] Fixed `/codegenerate` having no privilege check and ignoring its playername
- [x] Fixed `place()` silently doing nothing where the mapblock was not in memory, which left holes in builds away from spawn
- [x] **BREAKING** dropped the `worldedit` dependency: cube, sphere, dome and cylinder are now `lib/shapes.lua`, one VoxelManip pass each
- [x] Removed `worldedit.lua()` / `worldedit.luatransform()` from the bundled fork before dropping it
- [x] Documented `color()`, and corrected block lists that had drifted from the config
- [x] Added a test suite (`tests/`): five specs run standalone under Lua 5.1, all eight via `codeblock_run_tests`
- [x] Added luacheck and CI for this repository, which had none of its own
- [x] Dropped the `formspecs` dependency: formspec sessions are now `lib/forms.lua` on `core.show_formspec`
- [x] The drone now advances for a time budget each server step instead of exactly one coroutine resume (new `step_budget_us`)
- [x] Fixed a runtime error reporting twice and leaving the coroutine attached
- [x] Generated `doc/api.md` and the in-game help from `lib/api.lua`, which also builds the sandbox environment
- [x] **BREAKING** fixed `round(x, decimals)`, whose arguments were the reverse of what was documented
- [ ] Known: `max_memory_kb` cannot stop one huge allocation; a pathological Lua pattern can still burn CPU

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