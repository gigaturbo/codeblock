# Audit — CodeBlock

Findings only: what is wrong, how it was fixed, and the reasoning a future
change would re-break. Order of work and features are in `ROADMAP.md`; manual
checks in `PLAYTEST.md`; what shipped, for a player, in `CHANGELOG.md`.

**Ids are never renumbered** — commit messages cite them. `B` bugs, `S` sandbox
and security, `C` compliance and packaging, `A` architecture and performance;
`F` features live in `ROADMAP.md`. **A gap is a finding that lives in the
`codecube` game's audit**: `B19`, `B20`, `B24`, `C2`–`C5`, `C15`, `A7`, `A8`,
`A13`, `A14`. `C9` was never used.

**States:** resolved, open, won't fix, withdrawn (none).
**Severities:** critical, high, medium, low.

## Status

| Series | Total | Resolved | Open | Won't fix |
|---|---|---|---|---|
| `B` bugs | 52 | 51 | — | `B34` |
| `S` sandbox and security | 9 | 9 | — | — |
| `C` compliance and packaging | 18 | 17 | `C24` | — |
| `A` architecture and performance | 14 | 14 | — | — |
| **Total** | **93** | **91** | **1** | **1** |

| Id | Sev | What | Waiting on |
|---|---|---|---|
| `C24` | medium | CI boots no engine, so three specs and every engine-guarded case never run in CI | a CI job that boots Luanti |
| `B34` | low | won't fix: a file cannot be removed without opening it first | decided — a working route exists |

## Open and won't fix

### C24 · medium · open — CI boots no engine, so an in-engine-only check never runs in CI

**Mechanism.** `.github/workflows/ci.yml` has three jobs: luacheck, the six
standalone specs under plain Lua 5.1, and the three `--check` generators. **No
job boots Luanti.** So `forms_spec`, `stepper_spec` and `integration_spec` never
run in CI, and neither does any case guarded on an engine global inside the six
that do.

**What made it its own id** is `C23`'s close-out. The cases that check the
shipped examples against the directory need `core.get_dir_list`, so an example
added to `lib/examples/` and left off the list is caught by a local
`run_tests.ps1` run and not by CI, which sees a `skipped:` line and goes green.

**Keep — this is not `C20`'s failure mode.** `C20` was a check that could not
fail and said nothing about it. This one fails correctly wherever it runs and
**announces its own absence**: `run_tests.ps1`'s report filter keeps only lines
matching `passed|failed|FAIL|want|got|skipped|xfail`, so **a spec note about an
environment it cannot run in must begin with one of those words**.

**Closing it needs a CI job that boots the engine** — the real fix, and the
larger piece of work, which would also put `integration_spec`'s 300 assertions
under CI for the first time. **Not by adding `lfs` to the standalone path** to
enumerate a directory: a dependency for one case is not a trade worth making. It
does not block the tag; the release is built from a tree a local run has
covered.

### B34 · low · won't fix — a file cannot be removed without opening it first

`lib/formspecs.lua` builds all four file buttons inside the `meta.active ~= 0`
block. Three belong there; *Remove file* could act on the selection.
**The author's decision: "won't fix now, not really needed"** — open it, then
remove it.

**Its permanent second effect is why it was filed:** `B14`'s cold-cache removal
path can never be reached from the editor, since opening a file populates the
cache. The one route left is removing a file immediately after a rejoin.

**Keep — the fix's shape, so it is not re-derived.** Move *Remove file* out of
the block, beside the help-panel switches already outside it, and act on the
file-list selection rather than `meta.tabs[meta.active]` — which makes "remove a
file open in a tab" and "remove one that is not" two cases. Whether a delete
should confirm is a separate question.

## Keep — rules a future change would re-break

Each line is a constraint, with the finding that paid for it. Where a skill
under `.claude/skills/` carries the mechanism, it is named rather than
restated.

### Sandbox and the environment

- **`S3` — the security boundary is the environment table plus the read-only API
  surface, never the forbidden-name list.** That list is a diagnostics aid: it
  matches identifier tokens, skips fields, and must name both `minetest` and
  `core`.
- **`S1` — copies, not read-only proxies.** Lua 5.1 has no `__pairs` and no
  table `__len`, so a proxy breaks `pairs(colors)` and `#hues` for player code.
  vector3's copy must carry its metatable or `vector(x, y, z)` stops resolving.
  Read-only names need the API in a separate table, since `__newindex` fires
  only for absent keys — so a program using an API name as its own global stops
  working.
- **`S1` — the guarantee is shallow.** It isolates assigning into a snapshot,
  not mutating through it. `env.snapshot_module` stays that way and stays
  dependency-free; the caller owns the leaves. That is `S8`.
- **`S8` — the leaves are copied at the call site, not in `lib/env.lua`.**
  `snapshot_vector3` in `lib/sandbox.lua` takes `env.snapshot_module(vector3)`
  and replaces every table-valued entry that passes vector3's own duck test —
  numeric `x`, `y`, `z` — with `vector3(v)`. Fourteen constructions per program
  start. Deepening `env.snapshot` instead would copy tables of strings on every
  other call site for nothing.
- **`S8` — the duck test, not `vector3(v)` on every table.** A future `vector3`
  release exporting a table of another shape must not raise at the start of
  every program.
- **`S8` — rebuild with the constructor, never by copying the keys and
  reattaching `getmetatable(v)`.** Against a frozen v2.0.x constant that yields
  an empty table aliased to the original. The reading is under *Corrections*.
- **`S8` — one player-visible consequence, and it is intended.** Inside a
  program on v2.0.x, `pairs(vector.one)` yields three keys and `table.copy` and
  `core.serialize` over a constant work, because the run's copy is an ordinary
  vector rather than a frozen empty table. **Mod code still holds the frozen
  originals**, so the `run-tests` support matrix still describes them.
- **`S8` — aliasing a constant is contained to the run that does it.**
  `getScriptEnv` builds the environment per run and calls `snapshot_vector3()`
  there, so `dir = vector.one; dir.x = -dir.x` reaches nothing outside that run,
  whoever writes it — a shipped example, or a player. **That is why `F-6` no
  longer watches `game.lua`'s starting direction.**
- **`S9` — a metatable is not a methods table.** `vector3.__index = vector3`
  made the class table an ordinary field of every instance, so a player program
  could replace `unpack`, `__add` or `__eq` for every mod using the `vector3`
  global. **That is live on v1.5 and v2.0.1**, both of which a player may have
  installed; the support matrix in `run-tests` is where that is tracked.
- **`S9` — `init.lua` names an exposed method table in the log, and detects it
  read-only.** The test is `vector3(1, 1, 1).__index ~= nil`. **Never probe by
  writing to a constant**: that succeeds on v1.5 and changes the constant
  server-wide, causing `S8` in order to test for `S9`. The line is English and
  untranslated, `debug.txt` being for whoever runs the server, and it is silent
  on a library without the hole. Its check is `R5`.
- **`S9` — this mod does not write-protect another package's tables.** Sealing
  `getmetatable(vector3.one)` at load is `C18`'s mistake on another author's
  package, and every other mod using the global would be subject to it. Leave-
  and-document was refused too: this one crosses to other mods.
- **`S9` — nothing here reads `v.__add` as a field**, which is what made the
  upstream separation safe to adopt.
- **`B49` — an `__index` on a real copy is not the proxy `S1` rejects.** It
  fires only for an absent key, so iteration, length and every present key are
  untouched. Do not simplify it into a proxy. Warn **at the read**, where the key
  the player typed is still in hand — at `placement` only a nil survives.
  Integer-indexed views are excluded: reading past the end of an array is
  legitimate.
- **`B49` — accepted side effect.** A program probing membership with
  `if colors[name] then` gets one chat line per run. Suspected and deliberately
  unfiled: a very long absent key would be echoed into that line, bounded by
  `strguard`, `max_string_mb` and the per-run flag. **An unprobed report is not
  evidence**; what would settle it is one line run in a world, and it belongs in
  `W4`.
- **`S2` — two methods amplify, not three:** `rep` and `gsub`. Lua's format-spec
  scanner rejects an outsized width itself.
- **`S4` — `worldedit` stays in the forbidden list.** A server can load the real
  WorldEdit alongside.
- **`B4` — the four instrumentation points pair no constructs and track no
  nesting**, because `while f(function() ... end) do` is legal Lua. The cost is
  that a plain `do ... end` is charged one harmless count — the suite's single
  `xfail`. **Fixing that `xfail` by pairing constructs undoes the design.**
- **`B54` — `print` reads varargs with `select('#', ...)` and `select(i, ...)`,
  never `{...}` and `#`; joins with a space, never a tab; `print()` sends a bare
  `> ` and still costs one command; `error` stays non-variadic.** The reasons
  are in `code-standards`.
- **`B6` — clamp, never wrap, and never answer nil past the maximum.**
  `place(nil)` silently builds the default block. `color()` is gone; `ramp_pick`
  inherits the rule.
- **`B23` — argument order is a contract.** `round(3.14159, 2)` returned ≈2:
  plausible and silently wrong.

### Limits and writing to the world

- **`S5` — `core.load_area` does not trigger mapgen**, so a load is a resident
  MapBlock plus a disk read: 16.3 kB and ~1700 loads/s, measured. The ceiling
  bounds what is **resident**, not what was loaded, so over it `use_map` sleeps
  the drone rather than killing the run. The throttle holds only while every
  request is smaller than the whole ceiling — a shape large in two dimensions
  still exceeds it.
- **`S5` — no limit stands for what a shape costs the server.** Serialising the
  mapblocks into the map database and pushing them to every client in range are
  charged to nobody and land after the run reports *completed*. A limit added
  later must not be sold as bounding them.
- **`B25` — there is exactly one `coroutine.yield()` in `lib/cost.lua`**, inside
  `release(drone)`, and everything that yields goes through it. A new yield site
  must too, or the per-resume mapblock memo (`program-pipeline`) breaks.
- **`B42` — the fillers clip on all three axes.** Do not re-narrow them to one.
  Ties go to `z` because `z` is the outermost loop, so a `z` slab stays one
  contiguous run of the data array. A shape large in *two* dimensions is still
  not fixed by slicing.
- **`B43` — `shapes.build` returns 0 when any axis is inverted.**
  `cube(0, 0, 0)` reaches `round0(abs(w))` and gives `pos2 = pos1 - 1`, which
  must never reach `read_from_map`. Do not remove that check while the emerge
  bounds are inclusive.
- **`A15` — three things to know before touching `lib/shapes.lua`.** The data
  array is prefilled with `ignore`, which `set_data` leaves untouched. The
  scratch buffer is one module-level table reused across shapes, safe only
  because nothing in it survives a yield. `c_ignore` resolves on first use.
- **`A4` — batching into `core.bulk_set_node` is decided against for v1.0.0.**
  The prize is the engine's 1.3x on the write half; the price is a pending-writes
  buffer flushed at **five** sites — every yield, before `get_block`, before each
  shape command, and on end, error and abort. **Omitting one is a silently wrong
  build.**
- **`A5` — one slab still overshoots**, ~65k nodes and under 10 ms, because a
  VoxelManip pass cannot be interrupted. The budget is the smaller of the
  codelevel cap and a share of one server-wide pool; a sleeping drone takes no
  share.
- **`B45` — `limits.binding` walks spent resources only.** A held resource sits
  at its ceiling by design, so a full map footprint means *being throttled*, not
  *about to fail*. Do not merge `binding` and `report` into one list. The panel
  no longer lists the held row at all, so **why a drone is slow is unsurfaced** —
  a known gap, not an oversight.
- **`B46` — do not charge wall clock for the runtime budget.** That punishes a
  program for a busy server and for its own pace.
- **`B27` — keep `dir` exactly on a multiple of `pi/2`.** `turn_by` counts whole
  quarters and multiplies back once; `Drone.angle` rounds. Widening the rotation
  table is not a fix. **A test that reimplements what it tests cannot fail** —
  the stub drone carried its own copy of the old formula.
- **`B28` — error levels in `lib/commands.lua`: 3 from a command, 4 from a
  helper one frame below, 5 through `move_by`.** A tail call does not preserve
  the old depth.

### The drone and its entity

- **`B50` — an object with `static_save = false` is deleted when the mapblock it
  stands in leaves server memory**, not when it leaves active-block range.
  Anything given `static_save = false` here needs the same treatment. **A record
  with no object is a run nobody can see, not a run that stopped.**
- **`B50` — the running count is per step, not per drone.** `Drone.on_step`
  counts once and skips sleeping drones. Counting from inside each entity was a
  scan of every drone for every drone.
- **`B50` — two costs the decision accepted.** A far-away runaway loses its
  accidental stop, so `max_nodes_written`, `max_runtime_s` and `map_memory_mb`
  carry it alone; and `/clearobjects` no longer ends a running program.
- **`B50` — the deterministic reproducer:** `forward(500)` then `sleep(20)`.
  `forward` is a teleport and `sleep` makes no call, so nothing calls
  `load_area`. Before the fix this killed the drone in one to two seconds.
- **`B50` — do not re-raise the objection that a globalstep driver inverts
  `A11`.** `lib/register.lua` already registers a globalstep and already owns
  orchestration. Forceloading was rejected as a `C18`-class imposition on the
  surrounding game.
- **`B29` — staticdata is `<serial> <name>`**, split on the first space because
  a player name cannot contain one, with `drone.serial` stored as a string. **Do
  not compare `ObjectRef`s instead** — 5.17.0's `lua_api.md` says nothing about
  their identity.
- **`B29` — what the serial protects today is the replacement's *object*.** A
  dying object's deferred `on_deactivate` would otherwise blank `drone.obj` on
  the new drone and leave it invisible until the next re-spawn. Re-spawning
  under the same name makes that case more common, not less.
- **`B29` — clear the record before `obj:remove()`, for its own reason.**
  `markForDeactivation` sets `m_pending_deactivation` **after** the Lua callback
  returns, so a second `on_deactivate` fires from inside the first and the
  already-cleared record absorbs it. Do not reorder it on the strength of the
  serial guard, or drop the serial guard on the strength of the ordering.
- **`B30` — `on_lost` announces nothing, removes nothing, and must not test
  `drone.cor`.** A parked drone with no coroutine keeps its record and gets its
  view back on the next re-spawn. A program that never started is still never
  reported as having ended.
- **`B52` — `load_area` never calls `resetUsageTimer`**, so a standing drone
  loses the block under it after `server_unload_unused_data_timeout`.
  `map_window_s` reads that same setting for an unrelated purpose — footprint
  decay.
- **`B51`, `B12`, `B30` — `Drone.finish` is the single place a run's outcome is
  announced.** Add vocabulary there; never a second announcement path. One
  failure, one message. A new outcome word is a new `S()` key (`C17`).
- **`B11` — the entity holds a name and a serial and caches nothing**, so a name
  that names no drone reads nil.
- **`A11` — `drone.lua` does not know forms exist.** `Drone.on_place` *returns*
  whether a file is still needed and `register.lua` shows the chooser. Drive a
  live refresh from the form side reading `drone.budget`, never by `drone.lua`
  calling into forms.
- **`B10` — why nobody could produce the refusal, so a third attempt is not made
  blind.** `server_unload_unused_data_timeout` bounds when the engine *may* drop
  an idle mapblock, not when it does. A route wants a **server-side** read of
  what is loaded, not a guess from the client's side.

### Formspecs and the editor

- **`A1` — the form contract.** One form per player, cleaned up on leave,
  handler `handler(meta, player, fields)` with the same `meta` across redraws. A
  programmatic close does not run the quit path, and form names carry a counter
  so an event from a closed form cannot be mistaken for a live one. The editor
  declares no `formspec_version`: adding one moves every element.
- **`B33` — a form closes by one path however it was reached.** `close_session`
  forgets the session and then hands the handler the engine's own
  `{quit = 'true'}`. **`forms.forget` stays unchanged** and is what the specs use
  for cleanup; folding `close_session` into it would fire a quit event through a
  handler on every spec teardown. Load order is load-bearing (`editor-formspecs`), and
  player meta written from `on_shutdown` is saved — observed by `E9`.
- **`B33` — a check on the synthetic exits says nothing about the engine-driven
  one.** `E8` and `E9` go through `close_session`, which builds its own quit
  event and carries no scrollbar field, which is exactly why both passed while
  ESC failed.
- **`B35` — capture `fields.content` once, guarded, before the branch chain.**
  The guard is what makes it correct: the field is absent from the quit event, so
  the read falls through instead of blanking the file, and `meta.active` is still
  the *old* tab, which the tab and file-list branches need. **Distrust any branch
  chain where each arm must remember a shared step.**
- **`B37` — a scrollbar is in the field table on every submit; a checkbox is
  absent unless it was the box clicked.** So **every always-sent field comes last
  in an `elseif` chain, or is read before the chain**. `newfile` is keyed on
  `fields.key_enter_field == 'newfile'`, which only `EGET_EDITBOX_ENTER` sets.
  `lua_api.md` documents neither; `guiFormSpecMenu.cpp` does.
- **`B5` — read a boolean preference with `get_string`, not `get_int`**
  (`editor-formspecs`) — and that only works if **nothing writes the key before the
  player has chosen** (`B36`). A player who joined before `1f7cd97` still carries
  a stored `0`, correctly honoured, so re-running `E10` needs a fresh player name
  or world.
- **`B47` — do not shorten `PERIOD` in `lib/hud.lua` for a smoother HUD.** It is
  the panel's refresh as well, and its length *is* the mitigation. Re-showing a
  form destroys and rebuilds every element, so a press in flight is lost
  (`editor-formspecs`, `luanti-reference`).
- **`B47` — the unspent fallback is stopping the self-refresh**, at the cost of
  the liveness `F8` was built for. The bar for taking it is misses in **ordinary
  use**, not under a deliberate rapid-press count. Quantising cannot beat the
  elapsed clock, which changes every beat; mouse-down means a `textlist`, and a
  destructive action on mouse-down is worse than a dropped click.
- **`B41` — `show_file_chooser` has one call site**, reached only when the drone
  has no file, so *no file* means *this chooser placed it* and removing is safe.
  `quit` sits last under `B37`'s rule.
- **`B44` — a drone with no usable file is taken away**, the same answer `B41`
  gave; two answers to one question is worse than either. The fix belongs at the
  caller: `lib/filesystem.lua` has no drone dependency and must not acquire one.
- **`A18` — `meta.active = #meta.tabs` is equivalent only while `meta.tabs` has
  no holes.** It is grown by `table.insert` and shrunk by `table.remove` alone,
  so `#` agrees with where `ipairs` stops. A write that leaves a nil in the
  middle breaks the fallback silently. `meta.dirty` is kept dense for the
  neighbouring reason.
- **`B53` — the new-file template names no individual colour** (`generated-files`),
  and `integration_spec` **reads it out of `lib/formspecs.lua`** rather than
  copying it, keeping the pre-`F11` text as a control that must fail. A copy
  would be one more unchecked mirror.

### Files, strings and locale

- **`B40` — the size bound belongs in `read_file`**, so the editor,
  `Drone.set_file` and the sandbox are all bounded by construction.
  `max_string_mb` is **not** this bound. `read(n)` answers nil at end of file, so
  the read is `or ''`. The sandbox reports `read_file`'s own message, or a file
  refused for size reads as missing.
- **`B40` — what the engine caps, and from when.** `pkt_read_formspec_fields`
  drops a whole submission at 640 kB, and that check arrives in **5.7.0**;
  `mod.conf` declares 5.4, where one field is bounded only by 64 MB. So a
  modified client's route into `write_file` is real but bounded — which is why
  this is a `B` and not also an `S`.
- **`B48` — normalise CRLF to LF in `read_file`**, after the size check (or a
  CRLF file could shrink under `max_file_kb`) and after the bytecode-signature
  check. **Any equality between a buffer off disk and a field back from a
  formspec is a line-ending comparison** unless something normalises first.
- **`B15` — an unreadable example is skipped with a warning**, not taken as a
  load failure, and the `.lua` strip is anchored to the end of the name.
- **`C17` — never build a translation key with `..`, and never edit a key in the
  source alone.** Both are in `generated-files`. The `.tr` report is advisory because
  an untranslated message legitimately falls back to English; a template that
  lies does not.
- **`S7` — a player-facing string that is not a translation key cannot be
  translated and nothing reports it**, because the checker only sees literals. An
  error value handed through from an engine or C call is exactly that.
- **`S7` — the locale checker reads comments too.** Prose about translation must
  not spell the `S()` call out, or it is reported as a non-literal key.
- **`B8` — parse the target player name and use it.** A bare number is a legal
  name, because `%w` matches digits.
- **`B55` — the engine's player-name charset is written in the engine source and
  nowhere else.** `PLAYERNAME_ALLOWED_CHARS` in `src/player.h` is
  `[A-Za-z0-9_-]`. Neither `lua_api.md` nor the settings example mentions it. A
  parser anchored on `[%a]` rejects legal players; check the source before
  narrowing one again.
- **`B55` — a single argument resolves in favour of the codelevel.** `^[1-4]$`
  is a level, anything else is a player name. **Players actually named `1`, `2`,
  `3` or `4` cannot have their codelevel read.** That is irreducible on a
  one-argument form, it is accepted, and it is not a defect to file.
- **`B55` — the dispatcher's set-before-read order is load-bearing.** The two
  parsers used to be mutually exclusive and now overlap. Reordering them is a
  behaviour change, not a refactor.
- **`B55` — `/codeblock level 5` reaches the read path**, because `5` is not a
  codelevel and is therefore taken as a name. Its refusal has to serve both
  readings: no such player, and a codelevel is 1 to 4. A message naming only one
  of them is wrong for the other.
- **`B9` — codelevel is the bound on resource use, so letting players set their
  own is privilege escalation.** The bug was that the privilege was
  unobtainable, not that it existed.
- **`S6` — the codelevel default is written in `register_on_newplayer`**, so
  upgrading a live server demotes nobody and equally tightens nobody: the numbers
  are a decision about new worlds only. Singleplayer is **3**, not 4 — level 4 is
  every ceiling at its widest at once, and nothing sits there without someone
  asking.
- **`B31` — in Windows PowerShell 5.1 `-Encoding utf8` means UTF-8 *with* a
  BOM**, and Luanti's config parser trims whitespace but not a BOM. Both writes
  in `run_tests.ps1` go through `[IO.File]` with `UTF8Encoding $false`.
- **`B21` — `README.md:14`'s trailing spaces are a Markdown hard break.**
  Stripping them joins two lines on the ContentDB page. And in Git Bash
  `grep '[ \t]$'` also matches every line ending in `t`: use
  `grep -E '[[:blank:]]$'`, and normalise CRLF first.
- **`B22` — `gen_cdb_json.sh` escapes neither `"` nor a backslash**, so a source
  containing either produces invalid JSON, and nothing verifies this script.

### Gates, mirrors and what ships

- **`C20` — a check that cannot fail is indistinguishable from a check that
  passes.** Make a new one fail once before trusting it. Lua's `%w` excludes the
  underscore every limit name contains, so `[%w_]+` is the fix wherever an
  identifier is matched.
- **`B43` — the same rule for a spec number:** the four changed assertions were
  run against the old bounds and failed there with exactly the old numbers, so
  none passes vacuously.
- **`C7`, `C14` — `lib/config.lua`'s limit tables stay plain literals, and every
  settings read is guarded with `rawget(_G, 'core')`** (`program-pipeline`). Adding a
  limit means all three: the literal, the `settingtypes.txt` entry, the
  documented row. A malformed value warns and falls back; a negative is rejected
  and zero allowed, because `pace_ms` uses it for *no pacing*; a `replaced` table
  warns when a retired name is still set.
- **`C22` — `.luacheckrc`'s sandbox std holds API names and nothing else**, which
  is what makes the comparison a plain equality. Anything else — the bare `_` the
  examples pass — goes in `files["lib/examples/**"].read_globals`.
- **`C22` — a bare string entry is a silent escape hatch.** luacheck accepts
  every field of a bare-string name, so replacing `ramp = {fields = {...}}` with
  `"ramp"` passes the check and switches typo-catching off with nothing going
  red. Spell out the fields of a name whose fields are all described. The check
  reads the config with `loadfile`+`setfenv`, not by pattern-matching it.
- **`C17`, `C19`, `C20`, `C22`, `C23`, `B53` — a file that restates the source
  and is read by a human, a linter, ContentDB or a player will drift, silently.**
  Nothing fails when it is wrong. The only fix that holds is a `--check` in CI; a
  note about remembering does not. **A generator guarantees the output matches
  its input and nothing more** — `.cdb.json` never drifted, and was faithfully
  generated from the wrong source for the project's life.
- **`C19` — the shipped long description is one enormous line because a JSON
  string cannot contain a newline.** Edit `CONTENTDB.md` and run the generator.
  Nothing in this repository can see the rendered result, so ContentDB's rules
  are the only test, and they are a gate in `release-check`. Its *Recent changes*
  list against `CHANGELOG.md` is hand-kept and unchecked.
- **`C10` — `.gitattributes` decides what reaches a player and nothing in CI
  checks it.** Read the archive by its top level, never by grepping the listing:

  ```bash
  git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u
  ```

  **A check whose command needs its output interpreted has to say so.**
- **`C16` — the suite probe tests for a file with `io.open`, not for a
  directory.** Lua 5.1 has no portable directory test, and a release build with
  `tests` export-ignored must answer rather than fail.
- **`C18`, `C21`, `B38`, `B39` — code correct in `codecube` and destructive in
  every other game.** A mod that ships to any game does not rewrite its sky,
  grant `fly`/`fast`/`noclip`, or clear an inventory. **The routine that finds
  this class is playing the mod in another game.**
- **`B39` — never clear an inventory; add what is missing**, and **both carrying
  reads (`main` *or* `craft`) must stay** (`drone-and-tools`). A guard that fires only
  in the worst case is worse than one that fires always, because it also stops
  anyone noticing.
- **`C21` and `C18` — removed rather than put behind a flag.** A setting no code
  path here depends on is a setting maintained for nobody. The principle carries
  no exception: `C18`'s `flat_sky` was the one this project allowed itself, its
  single beneficiary was a downstream game, and that game now sets its own sky,
  so the setting and the five overrides went the same way as `C21`'s grant. A
  presentation setting this mod's own code never reads belongs to the game.
- **`B38` — an empty callback is a decision and should carry a comment saying
  what the empty means.** `lua_api.md` documents `on_secondary_use`; the cost was
  not reading it.
- **`C6` — what must still say `minetest`:** the filename `minetest.conf`,
  `lib/preprocess.lua`'s forbidden list (which must forbid **both** aliases), and
  the `vector3` submodule.
- **`C1` — the engine does not enforce `min`/`max_minetest_version`, but
  ContentDB filters on them.**
- **`C13` — distance from spawn was never the resource.** What replaced the limit
  is a hard edge: `check_inside_world` against `mapgen_limit`.
- **`C11` — released changelog entries are a record, not a draft.**
- **`A2` — the API descriptors carry no closures and no dependency on the mod
  being loaded**, which is what lets a bare interpreter render them and
  `api_spec` check every name without constructing a drone. Only the reference
  below the marker is generated; `doc/api.md`'s codelevel table and command prose
  above it are hand-written.
- **`A16` — adding an API name is an `api_spec` edit too.**
- **`A17` — `codeblock.config.check_auth_level` reads
  `codeblock.config.default_auth_level` at call time and must not capture it.**
  `config.lua`'s validation of the `default_auth_level` setting is that
  function, so the function runs before the field it reads exists. Capturing the
  field breaks the setting's validation.
- **`A17` — `codeblock.api.html_commands` does not cost `A2`.** `to_hypertext`
  reads nothing but `api.groups`: no closures, no engine, no mod. `lib/api.lua`
  stays pure data under a bare interpreter. Neither `scripts/gen_docs.lua` nor
  `api_spec` iterates `api`'s own keys, so the extra key is invisible to both.
- **`A17` — `codeblock.parse_target` is published because a spec needs it.**
  `tests/integration_spec.lua` covers it, and the suite runs at mod load before
  a player exists, so it cannot be driven through the chat commands.
- **`A12` — the specs run at mod load**, before a map, a player or a user
  directory exists, and every feature inherits that. **Static counting is unsafe
  here:** counting `it(` in `shapes_spec` gave 4 against a real 15.
- **`A3` — a refactor's findings should not be closed without a review of what
  the refactor introduced.** Closing `A3`, `A6`, `A9` and `A11` left `B27`,
  `B28`, `B29` and `B30` behind.
- **`A9` — the filesystem layer has no spec coverage at all**, the suite running
  before a user directory exists.
- **`B14` — the cold-cache removal path is unreachable from the editor while
  `B34` stands.** The one route left is removing a file immediately after a
  rejoin.

## Resolved

One row each: what was wrong, how it was fixed, and where the fix landed. Where
a row carries a rule, it is above under *Keep*.

### B · Bugs

| Id | Sev | Was | Fixed | Where |
|---|---|---|---|---|
| `B1` | critical | comment stripping deleted the code between two block comments | instrumentation runs over a real Lua token stream, so comments are never stripped | Phase 2 |
| `B2` | critical | `--[[ ]]` unhandled; only `--]]` matched, leaving a comment body as bare code | the token stream | Phase 2 |
| `B3` | critical | a string containing `--` was truncated mid-literal | strings are tokens | Phase 2 |
| `B4` | high | `"function"` matched as a substring, injecting a statement into unrelated expressions | `function` is a keyword | Phase 2 |
| `B5` | high | two editor checkboxes did nothing, because `0` is truthy in Lua; it destroyed work rather than being ignored | booleans in memory, ints only at the persistence boundary; `loe` and `sos` default on, `soe` stays off | Phase 1, `500dd85` |
| `B6` | medium | `color()` wrapped instead of clamping and answered nil past its maximum, so `place(nil)` silently built stone | clamps to the end colours | Phase 3 |
| `B7` | medium | a file-read error printed a file handle instead of the filename | reported once rather than twice, `A9` having collapsed the read path first | `37c416e` |
| `B8` | high | `/codegenerate` had no privilege check and overwrote the caller's files | own files free, another player's needs `codeblock`, existing files left alone, parsing in `utils.parse_target` | Phase 1 |
| `B9` | medium | `/codelevel` was unreachable in singleplayer, which it special-cased | the privilege is granted in singleplayer and the dead branch is gone | Phase 1 |
| `B10` | medium | `add_entity`'s result was used without a nil check | `Drone.new` returns nil and refuses, creating no record | `742a1ca` |
| `B11` | medium | `on_deactivate` dereferenced `_data` without the guard `on_step` had | the cache was removed rather than the guard added | `742a1ca` |
| `B12` | medium | a runtime error was reported twice and left the coroutine attached | the error path removes the drone | Phase 4 |
| `B13` | low | `save_editor_state` could pass nil to `set_string` | defaults to `""` | `37c416e` |
| `B14` | medium | `write_file` and `remove_file` indexed the per-player cache without populating it, so the first save after a rejoin crashed | both go through `get_user_data` | `37c416e` |
| `B15` | low | example loading had no error handling and leaked handles | an unreadable example is skipped with a warning | `37c416e` |
| `B16` | medium | every join wiped the player's inventory | the clear was gated on a tool being missing — which left the wipe in the one case with something to lose, reopened as `B39` | `37c416e` |
| `B17` | low | a number was passed to `set_string` | initialised to `""` | `37c416e` |
| `B18` | low | a dead branch left cylinder coordinates nil | the arm was deleted; orientation is normalised to V or H once | `834f69f` |
| `B21` | low | 61 trailing-whitespace sites across 16 files | stripped, except one Markdown hard break | `834f69f` |
| `B22` | medium | `gen_cdb_json.sh` produced different output on Windows and Linux | CRLF normalised before escaping | `5832bf2` |
| `B23` | medium | `round()` took its arguments in the opposite order to its own documentation, plausibly and silently | argument order corrected; found while writing the API descriptors | Phase 3 |
| `B25` | high | `use_call` yielded without dropping the mapblock memo, so a lost write could return | one yield site, which clears the memo | Phase 6 |
| `B26` | low | a program's reported duration was the server's CPU time, so on Linux it counted everything else the server did | both readings are `core.get_us_time()` | Phase 6 |
| `B27` | critical | the rotation table is keyed by exact integers and was indexed with a float, so one `turn(n)` could make the next move crash — a regression from `A3` | fixed at both ends: whole quarters in, rounding out | `7d9ca47` |
| `B28` | medium | `check_inside_world`'s error level was one short on the movement path, losing the player's line — a regression from `A3` | levels 3 / 4 / 5 by call depth | `7d9ca47` |
| `B29` | high | placing a second drone destroyed it immediately, because `on_lost` fired after the replacement was installed | a serial in staticdata, compared before any teardown | `191b533` |
| `B30` | low | `on_lost` reported the end of a program that was never running — a regression from `A11` | it announces nothing at all | `7d9ca47`, `1b991ae` |
| `B31` | high | `run_tests.ps1` wrote a UTF-8 BOM into the user's real `minetest.conf`, killing its first setting | `[IO.File]` with `UTF8Encoding $false`; the read strips a mark already present, so the `finally` repairs | `7d9ca47` |
| `B32` | medium | the same script appended its enable line with no separator, so on some configs the suite silently never ran, permanently | a separator | `7d9ca47` |
| `B33` | medium | the editor saved its open-tab state on one exit path and lost it on three, including *Load and close* | three sites, all closing through one `close_session` | `500dd85` |
| `B35` | high | every editor button but *Save* discarded everything typed since the last save: 3 of 11 branches captured `fields.content` | one guarded capture before the branch chain | `500dd85` |
| `B36` | medium | the new-player initialiser wrote `0` into the editor preference keys, making the ticked default unreachable | the three keys are not written at creation; the reader owns the default | `1f7cd97` |
| `B37` | high | three help-panel scroll branches shadowed four others, so ESC never saved the tabs and Enter never created a file | always-sent fields moved to the end of the chain; `newfile` keyed on `key_enter_field` | `1f7cd97` |
| `B38` | medium | aiming the poser at nothing was silently ignored, because the engine calls `on_secondary_use`, and `B10`'s refusal became unreachable | both routes call one `drone_on_place(name, nil)`, with the no-node check above the busy check | `b5d2e40` |
| `B39` | high | the first join after installing the mod wiped the player's inventory — the case `B16`'s narrowing left behind | add what is missing, never clear | `b5d2e40` |
| `B40` | high | a player's file was read whole with no bound: a 168 MB file took Luanti to ~14 GB resident and froze the game twice | read `max_file_kb * 1024 + 1` bytes and refuse by name, same ceiling in `write_file` | `62cf464` |
| `B41` | low | cancelling the file chooser left a drone that could not run | one local `close`, which removes a drone that still has no file | `6fea453` |
| `B42` | medium | a shape wider than the footprint ceiling raised instead of throttling, and the drone's facing decided which | slabs follow the axis with the largest span | `febf16f` |
| `B43` | low | the emerged box was one node larger than the shape on every axis, doubling the cost of a thin shape | one subtraction per axis, plus an inverted-box guard | `6fea453` |
| `B44` | low | removing a file left a drone still naming it, taken away one gesture later | the drone goes at the deletion, from the caller | `6fea453` |
| `B45` | medium | the HUD almost always named *map memory* as the binding limit, because a held resource sits at its ceiling by design | `binding` walks spent resources only; the held row is no longer drawn | `d619fba` |
| `B46` | medium | the runtime budget was labelled *Running time*, which reads as wall clock and is not | renamed, with a describing line per row | `d619fba` |
| `B47` | medium | a button on the drone panel needed a second click: the panel's own 0.5 s refresh rebuilds every element, and a button's `Pressed` dies with the object | **mitigated, residue ships** — the beat is 1 s on both surfaces, halving the loss; `H10` still found a few presses in twenty missing, accepted | `d8d44cd` |
| `B48` | medium | the editor marked every unsaved tab modified on losing focus: a CRLF file never compared equal to the client's LF textarea | `read_file` normalises to LF | `4179877` |
| `B49` | medium | a misspelled block name built the default block and said nothing, `place(colors.typo)` being indistinguishable from `place()` | `env.snapshot(t, on_miss)` warns once per run, naming the key, and the program continues | `d8c32f7` |
| `B50` | high | the drone disappeared mid-run at codelevel 1, taking its program with it: `static_save = false` deletes the object when its mapblock leaves server memory | the record is decoupled from the entity — one globalstep drives every run, `on_deactivate` clears `drone.obj`, and the object is re-spawned with the same serial | `1b991ae` |
| `B51` | medium | a run cut short was announced as *completed*, with a fraction of the node count it asked for | `Drone.on_remove` passes `'stopped'` and `Drone.finish` gained a branch and an `S()` key for it | `8de3cea` |
| `B52` | medium | a drone standing still far from any player died at about 29 s, `load_area` never resetting the block's usage timer | closed by `B50`'s fix: such a drone loses its view, not its run | `1b991ae` |
| `B53` | high | the new-file template said `place(blocks.obsidian)`, a category `F11` had deleted, so **every file a player created failed on its first statement** for three days, with five gates green | the template loops over `hues` and names no colour; `integration_spec` reads it out of the source | `de3bcbb` |
| `B54` | medium | `print` took exactly one parameter, so it dropped every argument after the first with no error, while the concatenated form raised | variadic through `select`, joined with a space, still one command per call | `24842d3` |
| `B55` | medium | both argument parsers in `lib/register.lua` required a leading `[%a]`, so a player named `007`, `4player` or `_bob` — all legal to the engine — could not be named to `tools`, `generate` or `level`, and the answer was the usage string | both parsers take `[%w_%-]+`; `parse_target` gains `rest_pattern` and `solo_pattern`, so a lone `[1-4]` is a codelevel and anything else is a name | `7c1442d` |

### S · Sandbox and security

| Id | Sev | Was | Fixed | Where |
|---|---|---|---|---|
| `S1` | high | player programs got live references to shared module and config tables, and the damage was global until restart | each run gets snapshots and API names are unassignable | Phase 2 |
| `S2` | high | one builtin call could exhaust server memory, invisibly to the call counter | `lib/strguard.lua` wraps the two amplifying string methods for the span a program runs | Phase 4 |
| `S3` | medium | the blacklist refused any file containing `repeat`, `until`, `_G` or `_c_` as substrings, so `repeat_count` was refused | retired; the list matches identifier tokens and is a diagnostics aid | Phase 2 |
| `S4` | medium | the vendored WorldEdit fork still carried its arbitrary-code-execution module | `code.lua` deleted, then the whole fork (`A15`); `integration_spec` asserts `worldedit` is absent | Phase 2, Phase 4 |
| `S5` | medium | `place()` could pin an unbounded number of mapblocks in server memory, and no limit could see them | `map_memory_mb`, the per-resume same-mapblock memo, and one shared step pool | Phase 6 |
| `S6` | medium | every player got the widest limits by default | resolved once from `core.is_singleplayer()`, validated against `auth_levels`; singleplayer tightened to 3 | Phase 5, `af018d0` |
| `S7` | low | a failed file open told the player the server's absolute path, in English whatever the game's language | the player gets `unreadable`; `err` goes to the log at `warning` | `6fea453` |
| `S8` | medium | `env.snapshot` copies one level, so `vector`'s fourteen load-time constants were the module's own: `dir = vector.one; dir.x = -dir.x` wrote into a constant every player read, until restart | `snapshot_vector3` in `lib/sandbox.lua` rebuilds each constant with `vector3(v)`, behind vector3's own duck test; `lib/env.lua`'s header no longer overclaims and `env.snapshot_module` stays shallow | `124d032` |
| `S9` | high | `vector3.__index = vector3` made the class table an ordinary field of every instance, so `v.__index.unpack = f` replaced a method for every mod using the `vector3` global | fixed upstream in `vector3` v2.0.2: a separate `meta` table carries `__index` and every metamethod, `new` sets it, and `frozen()` copies from it and skips `__index` — `v.__index` reads nil, on a constant as well as a fresh vector | submodule bumped to `fc8a5b8` |

### C · Compliance and packaging

| Id | Sev | Was | Fixed | Where |
|---|---|---|---|---|
| `C1` | high | a `max_minetest_version` ceiling hid the package from every modern user, and the floor was a false claim | ceiling removed, floor 5.3 → 5.4; the vector3 submodule's own 5.5 ceiling went with the v2.0.1 bump | Phase 1 |
| `C6` | low | `minetest.*` throughout, style rather than breakage | converted to `core.*` where it was safe to | Phase 7 |
| `C7` | medium | no `settingtypes.txt`: every limit was source-only | added, in the mod rather than the game root, and later generated from `lib/config.lua` | Phase 5, `d8d44cd` |
| `C8` | low | linting and CI had been set up, then removed | restored, and immediately caught five dead locals and a disabled instrumentation pass | Phase 0 |
| `C10` | low | a malformed `.gitattributes` line, and a release archive nothing had decided the contents of | archive contents decided and checked by hand; `screenshot.png` kept with an explicit `-export-ignore` | pre-Phase 7 |
| `C11` | low | the changelog shipped two known limitations the same section contradicted | both deleted; released entries untouched | Phase 7 |
| `C12` | low | `.luacheckrc` configured two mods that no longer exist, under a comment asserting a correspondence that did not hold | deleted, which restored a real check | Phase 7 |
| `C13` | low | `max_distance` was stored squared while its documentation gave it in nodes, which `C7` turned into a defect | the limit was removed; `check_inside_world` is the edge | Phase 6 |
| `C14` | medium | `gen_docs.lua`'s documented-limit check matched by name prefix, so three limits were invisible to it | matches by table shape, the rule `config.lua`'s override loop uses | Phase 6 |
| `C16` | medium | `codeblock_run_tests` aborted mod load on a ContentDB install, `tests` being export-ignored | `init.lua` probes for `tests/api_spec.lua` and, absent, logs and loads normally | `7d9ca47` |
| `C17` | medium | `locale/template.txt` had drifted 12 messages one way and 17 the other, one key was built with `..`, and three translations were orphaned by a one-character edit | all three layers fixed, with `gen_locale.lua --check` added to CI | `b5d2e40` |
| `C18` | medium | five sky overrides were forced on every joining player, unguarded, under a `TODO: TEMP fix` comment | the five overrides and `flat_sky` are gone; the sky is the game's | `6fea453`, removed `3fa9d0c` |
| `C19` | medium | the ContentDB long description was `README.md` verbatim, breaking six of ContentDB's *do not include* rules, five of its nine images load-bearing in the instructions | its own source, `CONTENTDB.md`, embedded by `gen_cdb_json.sh` | `7c5bceb`, `9e04990` |
| `C20` | medium | `gen_docs.lua`'s limit check matched nothing and had matched nothing since it was written: Lua's `%w` excludes the underscore every limit name contains | `[%w_]+` in both generators, each then made to fail against a fake limit | `d8d44cd` |
| `C21` | medium | `register_on_newplayer` granted `fly`, `fast` and `noclip` to every new player, in any game that installed the mod | removed outright | `b23a8bc` |
| `C22` | low | `.luacheckrc`'s sandbox std had drifted: `sleep` and `default_block` were missing, so a correct example would have been reported as a typo | `gen_docs.lua --check` compares the std with `api.names()` in both directions | `4450ce1` |
| `C23` | medium | the shipped examples were checked against a hand-kept list of names, not against the directory, and the count agreed only by a dead entry | both directions checked against `codeblock.examples.examples`, each failing by name | `de3bcbb`, `63c3c33` |

### A · Architecture and performance

| Id | Sev | Was | Fixed | Where |
|---|---|---|---|---|
| `A1` | high | the entire UI rested on an unmaintained mod that installed ten names into the engine namespace and replaced `register_node` globally | `lib/forms.lua`, ~180 lines against 420 | Phase 3 |
| `A2` | medium | the player-facing API was defined in three places and had already drifted | `lib/api.lua` is pure data and the single description | Phase 3 |
| `A3` | medium | `lib/commands.lua` was 971 lines of mechanical repetition | 608 lines plus `lib/cost.lua`; it introduced `B27` and `B28` | `834f69f` |
| `A4` | medium | `place()` wrote one node at a time and failed silently off-map | `place_block` calls `core.load_area` before `set_node`; playtest `W2` answered that mapgen does not later overwrite such a node | `f413758` |
| `A5` | high | the drone advanced one coroutine resume per server step, pinning throughput near 400 commands/s regardless of headroom | a time budget per step, measured at 3 / 10 / 20 resumes against exactly 1 before | Phase 4 |
| `A6` | low | the entity prototype relied on a two-level metatable chain that resolved by coincidence | the callbacks sit directly on the prototype table | `742a1ca` |
| `A9` | medium | the filesystem layer duplicated its read path and exported six near-identical getters | 157 lines, one sorted list plus `ud.byname` | `37c416e` |
| `A10` | low | `get_safe_coroutine` overwrote its own parameter | renamed; behaviour unchanged | Phase 7 |
| `A11` | medium | `drone.lua` and `drone_entity.lua` did not divide by responsibility, and drone state had no owner | the record, lifecycle and `Drone.finish` in `drone.lua`; a name, a serial and one callback in the entity | `742a1ca` |
| `A12` | low | no tests, on the component that most needs them | nine specs, six of them also standalone under Lua 5.1 | Phase 0 onward |
| `A15` | medium | only 448 of the vendored WorldEdit fork's 2,299 lines were reachable, and the whole dependency was four functions | the fork is gone; `lib/shapes.lua` owns the geometry, covered standalone | Phase 4 |
| `A16` | medium | `api_spec` was standalone-capable but not run by CI, so the change most likely to break every saved player program was the one CI could not see | added to the CI job | `a023ceb` |
| `A17` | low | `codeblock.utils` was a published global holding ten unrelated entries, three of them with no caller anywhere in the tree | the three dead ones deleted; `lib/utils.lua` then dissolved — four names rehomed to `codeblock.path_join`, `codeblock.parse_target`, `codeblock.config.check_auth_level` and `codeblock.api.html_commands`, three made file-local or inlined | `c089f78`, `6a4fa91`, `fd219ef` |
| `A18` | low | `meta.active = #meta.tabs` was written as a `0` followed by a guarded `ipairs` loop assigning the index every iteration, at two sites | one assignment and a comment at each site; the `init.lua` shadow the entry misnamed as the file's last went with it | `c089f78` |

## Evidence: verified, committed, claimed

**Verified** means a run or a reading demonstrates it. **Committed** means the
code is there and unproven. **Claimed** means only a document says so. Never
blurred.

**Claimed only: nothing.**

**`A17` and `A18` landed at `c089f78`**, touching `init.lua`,
`lib/formspecs.lua` and `lib/utils.lua`. Gates over it: luacheck baseline
silent, `LUACHECK_STRICT=1` reporting **no `W421` in the tree**, the three
`--check` generators up to date, 253 standalone and 665 in-engine assertions
with 0 failed, 0 xpass and the one known `B4` xfail. **No count moved.**

**`A17`'s deletion is verified by reading, not by the suite.** A grep over the
whole tree with `.git` excluded — so `lib/examples/`, `doc/`, `locale/` and
`CONTENTDB.md` were in scope — found six hits: the three definitions and three
mentions in the record. A second grep for `codeblock\.utils` and `utils\[` found
no dynamic indexing, so every reader names a field literally. No spec covered
the three, so no count could have moved.

**`A17`'s dissolution of `lib/utils.lua` landed at `6a4fa91` and is gated
green.** At `fd219ef`: luacheck silent, `doc/api.md`, `locale/template.txt` and
`settingtypes.txt` each up to date, the six standalone specs pass, and the
in-engine nine report **671 assertions, 0 failed, 0 xpass, the one known `B4`
xfail, no errors**. `fd219ef` adds six `tests/integration_spec.lua` cases
pinning `check_auth_level` at its new home, one of them the call-time read of
`default_auth_level`; all six were driven to failure with a stub before being
accepted. **The load order is verified by a boot, not by inspection** —
`lib/examples.lua`, `lib/filesystem.lua` and `lib/config.lua` each call a
rehomed symbol at file scope and would take the mod down in the wrong order.

**`A17`'s in-world reading is owed, and one route to it is open.** Setting
`codeblock_default_auth_level = 9` and reading the warning in `debug.txt`
exercises the call-time read and needs no command. Playtest `R4` carries that
reading at `cd13414`, before `6a4fa91`, so it has to be taken again.

**`R4`'s four numbered cases became performable at `7c1442d`.** They ask for a
codelevel to be read back, which `F16` added. The check is `owed`, and its
`dd98aab` fail is superseded.

**Neither runtime call site of `check_auth_level` is pinned.** The function is
covered; `lib/drone.lua:148`, the read path at `lib/register.lua:399` and the
set path at `lib/register.lua:414` are not. Playtests `R4`, `F16-4` and `F10-3`
exercise them, and all last passed before this change or have never run.

**`B55` is verified in a world.** Playtest `F16-8` passes at `fb75bc8`, engine
5.17.0, 2026-09-08 — `tools`, `generate` and `level` each act on a player named
`007`, `-bob` or `_carol`, and no usage string appears. **No spec can reach a
real player name**, so that run is the finding's only in-world evidence. Its fix
landed at `7c1442d`, and `2608dc3` adds 28 `tests/integration_spec.lua` cases
over the two parsers: the engine charset on all three subcommands, the
one-argument resolution rule, and the set-before-read order. Gates at `2608dc3`:
luacheck silent, the three `--check` generators up to date, **703 in-engine
assertions, 0 failed, 0 xpass, the one known `B4` xfail**, 253 standalone.

**`F16`'s read path is verified in a world.** `F16-1` to `F16-8` all pass at
`fb75bc8`, engine 5.17.0, 2026-09-08 — the free read, the privileged read, both
refusals, the `get_int` fallback, the four setting forms, the usage strings and
the French client.

**`F17` landed at `be3155f` and is gated green.** luacheck silent, `doc/api.md`,
`locale/template.txt` and `settingtypes.txt` each up to date, **725 in-engine
assertions, 0 failed, 0 xpass, the one known `B4` xfail, errors `none`**, and 254
standalone under Lua 5.1 with one legitimate skip. `integration_spec` carries 359
of them, up from 294. No `S()` key was added or removed, and
`codeblock_run_tests` was confirmed out of the real `minetest.conf` afterwards.

**`F17`'s coverage is mutation-verified, and the pre-port failures were read
rather than taken on trust.** Deleting seven names failed 43 existing
assertions; `test-agent` read all 43 and confirmed each was a deleted-name
failure rather than accepting that account from the agent that wrote the change.
**Every new assertion was then driven to failure against three separate
mutations** of `lib/sandbox.lua` and `lib/blocks.lua`. That is stronger than the
usual green run and is recorded as such.

**No defect was found in `F17`'s implementation, so it carries no finding id.**
A feature wrong before it ships is its `ROADMAP.md` entry's business.

**`F17` is verified in a world.** `F17-1` to `F17-4` and `F12-6` all pass at
`6440ca0`, record-only over `3fa9d0c`, engine 5.17.0, 2026-09-09. `F17-4` is the
only reading of the reduced *Choosing blocks* group and the absent
`table.randomizer` row, `api.to_hypertext` running only in a running world. Its
case 4 was **measured, not assumed**: the error for the missing `table` global
names `table`. `F12-6` is `ramp.of` over a game-registered category walking
alphabetical order, on the post-`F17` form of the check.

**Committed with gates green, unproven in a world — three:**

- **`B14`** — the cold-cache save-after-rejoin path. Permanently out of reach
  from the editor while `B34` stands; the one route left is removing a file
  immediately after a rejoin, and no check has been written for it.
- **`S7`'s log half** — that the server's absolute path reaches `debug.txt` at
  `warning`. The player-facing half is confirmed by `F-3` case 2.
- **`lib/examples/game.lua`'s constant fix (`3548d58`)** — that it sets off in
  the same direction every run. **No check reads it any more.** `F-7` runs the
  example and does not watch its direction, and `F-6`'s two `game.lua` cases
  were dropped 2026-09-08. Nothing is at risk: `snapshot_vector3` gives every
  run its own constants, so an aliased `vector.one` reaches nothing outside its
  run.

**`A18` is verified in a world.** `E2` and `E3` both pass at `fffdded`,
record-only over `c089f78`, engine 5.17.0, 2026-09-08. `E3` walks `close_active`
end to end — three files open, close the middle one, then the last — covering
both branches the assignment replaced. `E2` case 2 reaches `remove_active`'s
fallback with two files open, for the first time in a real world.

**Unproven in a world — the `S9` load-time warning.** `init.lua` logs one
`warning` when the installed `vector3` hands back its method table. No spec can
reach it: it fires at mod load, and the fixture pins v2.0.2, where the branch is
not taken. Its check is `R5`, unrun.

**Not verified anywhere, with no route left: `B10`'s refusal.** Playtest `D2`'s
second case aimed at it twice and was removed as untestable; producing it needs
a server-side way to observe that a mapblock has been let go.

**`S8` has in-world evidence.** `F-6` passes at `6440ca0`, record-only over
`3fa9d0c`, engine 5.17.0, 2026-09-09 — the three-line reproducer run three times
in one session, no raise. **Two qualifications the result line carries.** The
`vector3` version is read from the submodule pin, v2.0.2, not restated by the
runner, so v1.5 and v2.0.1 stay probe-verified only. What the three runs printed
was not restated either, so the pass reads as *no raise and no complaint*.

**Weaker than a playtest, and said so: `S8` and `S9` are probe-verified at the
library level**, under plain Lua 5.1 against the real `lib/env.lua` and the real
`vector3.lua`, and neither was run through a real drone. **`S8`'s fix was read
independently of the agent that wrote it**: `snapshot_vector3` was lifted out of
`lib/sandbox.lua` by source and run against v1.5, v2.0.1 and v2.0.2. On each,
zero constants are shared with the module, `local d = r.one; d.x = -d.x`
succeeds on two successive runs, the module's own `one.x` stays `1`, the run's
copy holds `-1`, and `vector(1,2,3)` still resolves through `__call`. `S9`'s
close-out is the same kind of reading: at `fc8a5b8`, `v.__index`, `v.__add`, `v.__eq` and
`vector.one.__index` all read nil, `getmetatable(v) == vector3` is false, the
finding's own poisoning line raises, and `v:unpack()`, `v + v`, `==` and
`tostring` are unchanged. **No playtest was added for it** — a player program
cannot observe the fix and there is nothing to look at in a world.

**A gate is read from its output, never from `$?`**, which does not survive this
machine's WSL layer. Current local figures and the CI state belong to
`ROADMAP.md` and the run itself, not here.

## Corrections kept rather than edited away

Each of these is a wrong claim that would otherwise be repeated as fact.

- **`S8`'s first recommended fix was wrong, and stays recorded.** Deep-copying a
  frozen constant and reattaching `getmetatable(v)` produces an empty table
  aliased to the original, so it fixes nothing while looking fixed. Three probe
  readings: `pairs` over a frozen constant yields **no keys**; the reattached
  metatable makes the copy read through the original's backing vector; and a
  write into that copy still raises. Someone would implement it, see a green
  suite, and mark `S8` resolved having changed nothing. The constructor is what
  shipped.
- **`S8`'s suggested spec was the wrong shape and is replaced.** This document
  asked for a two-level fixture in `tests/env_spec.lua` — `{inner = {n = 1}}`,
  write through the copy, assert the original. `env.snapshot_module` is
  deliberately shallow, so that spec would assert against the contract. **The
  suggestion for `test-agent`**, not yet written: a program running
  `local a = vector.one a.x = -1` through `get_safe_coroutine` completes without
  raising, which fails against the old code on the pinned v2.0.2.
- **Copy-on-read would *not* make `vector.x == vector.x` false.** `vector3.__eq`
  is component-wise and Lua 5.1 selects it when both operands share a metatable,
  so identity is not observable through `==`. Its real costs are that
  `pairs(vector)` stops seeing the constants, a vector used as a table key
  differs on every read, and `vector.one.x = -1` silently vanishes.
- **Both `lib/sandbox.lua` and `lib/commands.lua` bind `chat_send_player`**, and
  a report that this record misattributed the binding was itself wrong.
  `lib/sandbox.lua:8` binds it and uses it at line 126 for the unknown-block
  warning (`F14-2`); `lib/commands.lua:26` binds the one `print` goes through.
  **Do not "correct" the two locals into one.**
- **`get_block` *is* reachable from a spec.** `codeblock.commands.drone_get_block`
  is exported and `integration_spec` asserts its out-of-world branch. What no
  spec can do is a read landing **inside** the world: `lib/commands.lua` captures
  `core.get_node` at load, and at mod load it dies inside builtin because content
  ids are not cached yet. Measured, not assumed.
- **`ramp_over`'s clamping *does* have spec coverage** — 57 assertions across all
  four built-in ramps, which caught `ramp_pick` deliberately made to wrap. This
  record and `ROADMAP.md` both said it had none and that covering it would mean
  exporting a private closure factory; exporting `getScriptEnv` was offered and
  refused, and the spec writes a program into the throwaway world instead.
- **`B42` was filed saying every filler already clipped to the area it was
  handed.** All three clipped along `z` only; the fix had to widen them first.
- **`C7`'s resolution once said the settings guard is `rawget(_G, 'minetest')`.**
  Since `C6` it is `core`.
- **`tests/api_spec.lua`'s name list was described as a historical capture.** It
  was 68 names against 73 described, and the one-way check could not say so. It
  is bidirectional now.
- **`integration_spec`'s `refused_for('color', …)` was reported as passing
  vacuously.** It was failing in the baseline, `color` being free so the category
  installs. Replaced by `ramp`, which also proves a dotted name reserves its
  first segment.
- **`W3`'s cost note once said `cube(215,215,215)` would exceed 1e7.** It is
  9.94e6 and fits; `cube(216,216,216)` does not.
- **The `rev_blocks` snapshot fix is observed, not correct-by-reading.** Playtest
  `F11-11` is its only possible evidence and it passed. Do not write it up as an
  outstanding risk again.
- **Take the unpushed commit count from
  `git rev-list --count origin/master..HEAD`, never by counting a copied-forward
  list of hashes.** That went wrong four passes running, always low.
- **An id is for a defect in committed code.** A wrong *check* is a defect in the
  record and is fixed in `PLAYTEST.md`: playtests `D3`, `F-3` and `R4` got no
  ids, and `E12`'s symptom got none after three fails and a disproof.
- **A pass can record cases that were never observable.** `R4`'s 2026-09-02 pass
  claimed four codelevel readings from a command that has only ever set one. A
  result line says what the runner saw; a check that asks for the unobservable
  will still collect a pass.
- **`A18` was filed as *the last `LUACHECK_STRICT=1` `W421` in that file*, and
  that reads as the last in the tree.** It was not. `init.lua`'s doc-generation
  block held a second — `local wanted, why` shadowing `strguard.install()`'s
  `why` — pre-existing and present at `72b614d`. The inner one is renamed `err`,
  so the tree now reports no `W421` at all. **A count scoped to one file is not
  a count of the tree**, and neither the entry nor the phrase said which.
- **`B34` and `B47` had no entries at all in this document** between `0837b58`
  and this pass, while five sections pointed at them. Both are restored above,
  from `16cd05c`.
- **Recorded as not fitting the model, and unfiled:** `B43`'s post-fix 78 s and
  95 s at the same multiplier — a 23% spread that no multiplier explains, the
  spans being able to multiply only to 1, 2 or 4. And at codelevel 1 nothing of a
  shape appears until the drone stops at view distance 30, while at 500 it is
  visible as it builds — most likely the client, no id.
- **Nine findings were filed with a conclusion later shown wrong or overtaken**
  (`C2`, `S2`, `A12`, `B21`, `S4`, `A3`, `B28`, `B29`, `C6`), and each records
  the correction rather than being amended silently.
- **Phases were renumbered once, before the scheme was fixed.** `43e95a8` still
  says "Phase 5" and still means the committed phase. **The record was split in
  two on 2026-08-26**, eleven findings moving to the game's audit with their ids
  intact.

---

Last reviewed **2026-09-09**, describing `6440ca0`, record-only over `3fa9d0c`.
`F17` is complete and played.
