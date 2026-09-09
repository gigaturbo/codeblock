---
name: program-pipeline
description: How a player's program runs in the CodeBlock mod — the preprocess, env, sandbox, stepper, limits and strguard chain, the per-codelevel limits and settings in lib/config.lua, and what a command spends when it writes to the world through lib/cost.lua and lib/shapes.lua. Carries the constraints a change to any of them would re-break, including the per-resume mapblock memo and the security boundary.
when_to_use: Before editing lib/preprocess.lua, lib/env.lua, lib/sandbox.lua, lib/stepper.lua, lib/limits.lua, lib/strguard.lua, lib/config.lua, lib/cost.lua, lib/shapes.lua or lib/commands.lua. Also when adding or changing a limit or a setting, when asked what stops a runaway program, or when reasoning about what a player's program can reach.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Running a player's program

Six files in order. Each is one stage, and the stages are testable apart.

1. **`lib/preprocess.lua` instruments the source.** Over a token stream it
   inserts `_G.use_call()` after every `do`, every `repeat` and every function
   parameter list, and before every `goto`. That is what makes loops and calls
   pay into a budget, so a runaway program stops instead of freezing the server.
   No Luanti dependency, so it tests standalone. It also reports forbidden
   identifiers — message quality, **not** the security boundary.
2. **`lib/env.lua` builds the environment.** `snapshot` gives each run its own
   copy of the API's tables. Copies, not read-only proxies: Lua 5.1 has no
   `__pairs` or `__len`, so a proxy would break `pairs(colors)` for player code.
   `new_env` makes API names unassignable, which is what stops a program reaching
   the injected counter.
3. **`lib/sandbox.lua` pairs every name with an implementation**, calls
   `api.build`, `setfenv`s the chunk and returns a coroutine.
4. **`lib/stepper.lua` resumes that coroutine** repeatedly each server step until
   a time budget is spent, so throughput follows spare headroom rather than the
   tick rate.
5. **`lib/limits.lua` holds the run's budget** — every ceiling converted once
   into the unit it is checked in, with its counter beside it. `charge` for what
   is spent (nodes, runtime) and stops the run; `hold` for the map footprint,
   which decays over the engine's unload window and makes the drone *wait*
   rather than fail. Dependency-free, so it tests standalone.
6. **`lib/strguard.lua` bounds `rep` and `gsub`** on the shared string metatable
   for the span in which player code runs. Leaving `string` out of the
   environment is not enough: every Lua 5.1 string shares one metatable, so
   `("x"):rep(1e9)` is reachable from any literal.

**The security boundary is the environment table plus the read-only API
surface.** Not the forbidden-name list.

**The snapshot copies are one level deep.** They isolate *assigning into* a table
and not *mutating through* it, and `lib/env.lua`'s own header states the
guarantee more widely than it holds, so **the caller owns the leaves**. That is
`S8`: `vector`'s fourteen load-time constants were shared by every run, and
`snapshot_vector3` in `lib/sandbox.lua` now rebuilds each one with `vector3(v)`
before the module goes out. `env.snapshot_module` stays shallow. **Any table-
valued entry added to the environment needs the same question asked.**

**`S9` was the other leak and is fixed upstream.** Up to `vector3` v2.0.1 any
instance handed back the shared class table as `v.__index`, letting a program
replace its methods for every other mod on the server; v2.0.2 carries them on a
separate `meta` table. Neither leak was escalation: `getfenv` and `debug` are out
of the environment, so a poisoned method still cannot reach `core`.

**The step's budget is shared, not per drone.** It is the smaller of the
codelevel cap and an equal share of one server-wide pool, so N drones do not cost
N budgets. It is published as `drone.deadline` and checked at every drone command
and every slab of a shape as well as between resumes, so what overshoots it is
one slab. The step also charges the time it spent against `max_runtime_s` — the
bound on a program that never finishes — and skips a drone that is asleep
(`drone.wake_at`). The globalstep that drives all of this is in `lib/register.lua`
and belongs to the **`drone-and-tools`** skill.

## What `print` costs

**One `print` call is one command** however many arguments it carries. The join
happens in the sandbox, so `drone_send_message` keeps taking one value.

**The chat line itself is unobservable from a spec.** `lib/sandbox.lua:8` binds
`chat_send_player` as a load-time local and `lib/commands.lua:26` binds the one
`drone_send_message` goes through, so replacing `core.chat_send_player` around a
run intercepts neither. Do not "correct" either local into the other. The specs
pin the charge; the chat line is `PLAYTEST.md` `W7`, and the unknown-block
warning is `F14-2`.

# Per-codelevel limits

**Seven limits in `lib/config.lua` are four-element arrays** indexed by the
player's codelevel (1–4): `pace_ms`, `step_budget_us`, `max_runtime_s`,
`max_nodes_written`, `map_memory_mb`, `heap_mb`, `max_string_mb`. Each stands for
a resource the server spends. Counts of calls, commands, volume, distance and
dimension were proxies and are gone.

**Codelevel bounds resource use, so it is privileged.** Never let players set
their own.

**Adding a limit means adding a row to the codelevel table in `doc/api.md`.**
`gen_docs.lua` enforces it, because a limit once shipped undocumented.

**Every one of those tables is overridable** from the settings menu or
`minetest.conf`, as four comma-separated numbers, plus the scalars
`default_auth_level`, `server_step_budget_us`, `max_file_kb` and `drone_hud`.
`max_file_kb` bounds a file read out of a player's directory rather than a
running program, so it is not a codelevel limit (`B40`). `map_window_s` is not a
codeblock setting at all: it is read from the engine's
`server_unload_unused_data_timeout`, because the map footprint decays over
exactly that window.

**Keep the tables as plain literals with the overrides applied in one loop
afterwards.** Two generators grep this source for a name assigned a table whose
first element is a number — `gen_docs.lua` for the documented row and
`gen_settingtypes.lua` for the menu entry — and a computed value turns both
checks off without failing.

**Guard every settings read with `rawget(_G, 'core')`.** Both scripts dofile
`config.lua` under a bare interpreter with no engine global, which is also what
makes the defaults they read the built-in ones rather than this machine's.

**`config.lua` keeps the units a player and an administrator read** — seconds,
megabytes, milliseconds. `limits.new` converts them once and nothing else does
the arithmetic. A retired setting name still in someone's `minetest.conf` warns
at load and names its replacement, from the `replaced` table.

**Do not edit `settingtypes.txt`.** It only draws the menu; the engine reads no
defaults from it. It is generated — see the **`generated-files`** skill.

**Every setting here is this mod's, and none of them is presentation.** A game
that embeds it contributes its own — mapgen, daylight, build restrictions — and
the two do not mix. `register_on_joinplayer` in `lib/register.lua` once called
`override_day_night_ratio(1)` and hid the sun, moon, stars and clouds for every
player of every game, unguarded (`C18`); putting it behind a `flat_sky` setting
bought a consumer that no longer exists, and a setting no code path here depends
on is maintained for nobody (`C21`), so both the setting and the five overrides
are gone. **The join callback applies no sky, sound or camera override, and must
not gain one** — a game that wants the look writes those calls in a mod of its
own. `drone_hud` is not a counter-example: it is on screen only while that
player's own program runs, and it is the only place a run's budget is visible.
Read a boolean setting through `flag`, the sibling of `number` and `per_level`.

# Writing to the world

**`lib/shapes.lua` owns the four bulk shapes** — cube, sphere, dome, cylinder —
through `shapes.build(spec)`, in mapblock-aligned slabs of `SLICE_BLOCKS`, one
VoxelManip pass each, with `spec.charge` called before every pass and free to
yield. A pass cannot be interrupted, so **the slab size is the longest stall the
mod can cause**; that is what lets a shape be any size at all.

**Every filler clips itself to the area it is handed**, not to a range passed in,
which keeps the clip equal to the extent the data array covers.

**Bulk shapes are charged per slab**, through the `slabs(drone)` callback.
Without it, `cube(1,1,1)` in a loop bypasses the ceiling exactly.

**`place_block` in `lib/cost.lua` must call `core.load_area` first.** `set_node`
into a mapblock that is not in memory silently does nothing, which used to leave
holes in builds far from spawn. Bulk shapes need no such call — `read_from_map`
emerges the region itself.

**`lib/cost.lua` holds what a command spends and when it gives the step back** —
`use_nodes`, `slabs`, `use_call`, `end_command`, `place_block`.
`lib/commands.lua` holds the geometry that calls them.

**The load is memoised per mapblock crossing**, comparing `floor(x/16)` on three
axes against the last write, taking footprint for each crossing. Two things about
that memo are load-bearing:

- **`load_area` does not trigger mapgen**, so a load costs a resident MapBlock
  plus a disk read — and `heap_mb` cannot see it, because `collectgarbage('count')`
  is the Lua heap and a MapBlock is C++ side. That is why `map_memory_mb` exists.
- **The memo is per-resume, not per-run.** `release` clears `drone.bx/by/bz`
  before every yield, and it is the only `coroutine.yield` in `lib/cost.lua` for
  exactly that reason. Widening its lifetime brings back the silent lost write
  the `load_area` call was added to fix (`S5`).

**No spec exercises `place()`.** The suite runs at mod load, before a map exists.
Checked by hand in a running world (`S5`): the memo, the per-crossing charge and
the per-resume reset all behave, a mapblock costs 16.3 kB resident, and the
engine serves about 1700 loads a second.

## Related

- **`blocks-and-palette`** — what `place` and `get_block` take, and where a block
  name resolves.
- **`drone-and-tools`** — the globalstep that calls the stepper.
- **`generated-files`** — `lib/api.lua` as the single source, and the checks over
  `config.lua`.
