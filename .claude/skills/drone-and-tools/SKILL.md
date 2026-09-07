---
name: drone-and-tools
description: The drone's record, its entity and the two tools in the CodeBlock mod — why lib/drone.lua owns the lifecycle while lib/drone_entity.lua is only a view, why the run is driven by the globalstep in lib/register.lua and never by an entity on_step, the serial guard and teardown ordering, and the rules for the poser and setter and a player's inventory.
when_to_use: Before editing lib/drone.lua, lib/drone_entity.lua, or the globalstep, join, leave and tool registrations in lib/register.lua. Also when a drone goes invisible, a run stops unexpectedly, /clearobjects is involved, or anything touches a player's inventory or a tool callback.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# The drone record and its entity

**They divide by direction of dependency** (`A11`).

**`lib/drone_entity.lua` is 69 lines and owns nothing.** It holds the owner's
**name** and a **serial**, arriving together as `core.add_entity` staticdata in
the form `<serial> <name>`, and routes one engine event onto the record —
`on_deactivate`. It caches nothing, so a name that names no drone reads nil.

**`lib/drone.lua` owns the record, the lifecycle and `Drone.finish`** — the
single place a run's outcome is announced. It does not know forms exist:
`Drone.on_place` returns whether the player still needs to pick a file, and
`lib/register.lua` shows the chooser.

**The entity is a view. The run is driven by the globalstep in
`lib/register.lua`** — one registration, which calls `Drone.on_step(dtime)` and
then the HUD and panel tick. `Drone.on_step` loops over `Drone.instances`, counts
the running drones **once** so each gets its share of `server_step_budget_us`,
advances each one, and hands an object back to any drone that has lost one.
**There is no `on_step` on the entity, and adding one would undo all of this**
(`B50`, `B52`).

**An object with `static_save = false` is deleted the moment its mapblock leaves
server memory** — not when it leaves active-block range — and nothing keeps the
drone's own block loaded. So any drone past about 192 nodes from a player, or
standing still for `server_unload_unused_data_timeout`, loses its object.

**A record without an object is a run nobody can see, not a run that stopped.**
`Drone.on_lost` clears `drone.obj` and does nothing else: it announces nothing,
tears nothing down, and does not test `drone.cor` — a parked drone with no
coroutine waits for its view too. `Drone.on_step` re-spawns the object with the
**same serial** once `get_node_or_nil` says the block is back, at most once a
second.

**Two consequences are deliberate.** `/clearobjects` no longer ends a running
program, and a runaway drone far from any player loses its accidental stop, so
`max_nodes_written`, `max_runtime_s` and `map_memory_mb` carry that load alone.

**`Drone.finish` is the single place an outcome is announced** (`B12`, `B30`). A
new ending is a new **branch and a new `S()` key inside it**, never a second
announcement path. That is how *cut short* was added: `Drone.on_remove` passes
`'stopped'`, which the stepper never produces (`B51`).

## Teardown

**`Drone.remove` clears the record before `obj:remove()`**, because that fires
`on_deactivate`, which looks the drone up.

**That ordering is not what makes it safe.** `ObjectRef:remove()` takes effect at
the end of the step, so `on_deactivate` can fire after a replacement drone has
been installed under the same name. **What protects the replacement is the
serial**: `on_lost` ignores any record whose serial is not the one it was called
for. Without it, a dying object would blank the new drone's `obj` and leave it
invisible until the next re-spawn. Re-spawning under the same name makes that
case more common, not less, so **do not remove either guard on the strength of
the other** (`B29`).

# The two tools and the player's inventory

`lib/register.lua` registers `codeblock:poser` and `codeblock:setter`. **Neither
is handed out on join** — `F10` ended that. A player takes them from the creative
inventory or runs `/codeblock tools`, which is what calls `give_tools`; the
first-join chat line names the command. Two rules there are load-bearing and both
were bugs first.

**`on_place` fires only when the client has a node under the crosshair.** Aim at
the sky, or past what the client has loaded, and the engine calls
`on_secondary_use` instead. Both now route into one `Drone.on_place` call, with
`pos` nil for the no-node case, and **that check sits above the busy check**:
with no node it is the aim that failed, not the drone (`B38`).

**Never clear a player's inventory. Add what is missing.** `give_tools` adds only
the tools the player is not carrying, and reports `full` rather than making room.
It must never empty `main`, `craft`, `craftpreview` or `craftresult` (`B16`,
`B39`).

**Read `main` and `craft` both.** `contains_item` is checked against each. A tool
parked in the craft grid would otherwise be duplicated every time `give_tools`
runs, silently.

**Play the mod outside its own game.** Both defects were invisible in the game
that embeds it, where a player carries nothing but the two tools and has no
reason to aim at the sky.

## Related

- **`program-pipeline`** — the stepper the globalstep drives, and the budget it
  shares out.
- **`editor-formspecs`** — the file chooser `Drone.on_place` asks for, and the
  load-order constraint between `forms.lua` and `register.lua`.
- **`luanti-reference`** — the engine behaviours behind `on_secondary_use`, entity
  lifetime and the inventory rule.
