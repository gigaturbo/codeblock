# v1.0.0 (unreleased)

Major version because several changes are breaking for existing player programs
and for redistributors. Read the first two sections before upgrading a world.

## Breaking for player programs

- **Wool names lost their prefix**: `wools.wool_red` is now `wools.red`, and the
  same for every colour. `iwools` and all bundled examples were updated to match.
  Saved programs written against the old names will fail with "Cannot place this
  block".
- **`color(v, min, max)` clamps instead of wrapping.** Values above `max` used to
  index past the palette and return nil, which `place()` silently built in stone,
  and larger values wrapped around to the low end. Programs that relied on the
  wrap-around will produce different colours.
- **API names are read-only.** Assigning to `place`, `up`, `blocks` and so on now
  raises instead of silently shadowing the function for the rest of the run. Your
  own globals and locals are unaffected.
- **Unavailable names are reported by name.** Reaching for `os`, `io`,
  `loadstring`, `pcall`, `minetest` and similar now fails immediately with a
  message naming what you asked for, rather than dying later with "attempt to
  index a nil value".
- **`/codegenerate` no longer overwrites existing files.** It writes only the
  examples that are missing. To restore one you have edited, delete it in the
  editor first.

## Breaking for redistributors

- **Relicensed from GPL-3.0-only to AGPL-3.0-only**, matching the Codecube game
  that bundles this mod, which cannot be relicensed to GPL because it vendors
  WorldEdit under AGPLv3.
- `max_minetest_version` removed; `min_minetest_version` raised from 5.3 to 5.4,
  which is what the editor's `formspec_version[4]` actually requires.

## Added

- **`repeat ... until` works.** It was refused outright before, only because the
  old instrumenter could not handle it.
- Per-codelevel `max_memory_kb`, checked at yield points. It stops a program that
  accumulates memory; it cannot stop a single enormous allocation.
- `color()` is now documented, having been usable but absent from the API
  reference while three bundled examples relied on it.
- A test suite (`tests/`), runnable standalone or in-engine via
  `codeblock_run_tests = true`, plus lint and CI for this repository - which
  previously had none of its own.

## Fixed

- **The code preprocessor silently corrupted valid programs.** Four defects, all
  from instrumenting raw text rather than tokens: code between a file's first and
  last block comment was deleted; a standard `--[[ ... ]]` comment had its body
  left behind as executable code; a `--` inside a string truncated the string;
  and any identifier merely containing the letters `function` injected a
  statement after the next `)` in the file. Instrumentation now runs over a real
  token stream.
- **Programs could corrupt shared state for every player.** `blocks`, `plants`,
  `wools`, `iwools` and `vector` were handed out by reference, so assigning to
  them changed the mod's own configuration - and `vector3` - until the server
  restarted. Each run now gets its own snapshot.
- **The editor's two checkboxes did nothing.** They were tested for truthiness
  while holding 0 or 1, and 0 is truthy in Lua. "Save on tab switch" being stuck
  on meant closing a tab always wrote to disk, so unticking it to discard an edit
  lost the original anyway.
- **`/codelevel` was unusable in singleplayer**, because the privilege it requires
  was never granted there.
- `/codegenerate` had no privilege check and ignored the player name it parsed,
  so it could only ever act on the caller.
- Removed `worldedit.lua()` and `worldedit.luatransform()` from the bundled
  WorldEdit fork - unreachable, but arbitrary Lua execution has no place in a game
  built to run untrusted player code.
- Several dead locals, a discarded function parameter, and a `.cdb.json`
  generator whose output depended on the checkout's line endings.

## Known limitations

- `max_memory_kb` cannot stop a single huge allocation such as
  `("x"):rep(1e9)` - it returns before any check can run.
- The API is still described in three places (the sandbox environment, the
  in-game help, and `doc/api.md`); a generator is planned.
- The editor still depends on the unmaintained `formspecs` mod.

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