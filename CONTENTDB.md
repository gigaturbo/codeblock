Program a drone in Lua and watch it build. You write a program in an editor
inside the game, hand it to a drone, and the drone places the blocks — a staircase,
a sphere, a torus, a Menger sponge, a plot of any function you can write.

It runs in any game that provides the blocks it places, and it is meant to be
safe on a shared server: a runaway program is slowed down or stopped rather than
freezing the world for everyone.

## Features

- **An editor in the game.** Tabs, several programs open at once, a file list,
  and your open tabs restored the next time you join.
- **A reference beside the code.** Every command and every block name is in the
  editor's own help panel, so you never leave the game to look something up.
- **Bulk shapes.** Cubes, spheres, domes and cylinders are written in one pass,
  so a large build is one command rather than a loop.
- **Example programs included** — spirals, a torus, a Menger sponge, 3D plots.
  Open one and change a number to see what happens.
- **Real Lua.** Loops, functions, recursion and maths, in a sandbox that cannot
  reach the server.
- **Per-player limits** an administrator can tune, so the mod is usable on a
  public server and not only in singleplayer.

## Quick start

1. New flat world, creative mode, mod enabled. You are given two tools.
2. **Right click a block with the Drone placer.** A list of programs appears —
   pick `stairs.lua`.
3. **Left click with the Drone placer.** The drone builds the staircase in front
   of you.

That is the whole loop. To change what it builds:

4. **Right click with the Drone setter** to open the editor. Open `spirals.lua`,
   change a number, click *load and exit*.
5. Place a drone and left click again.

## Worth knowing

- **Every player has a codelevel**, and it bounds what one program may spend of
  the server: how long it runs, how many blocks it writes, how much of the map it
  holds at once. If a program stops early, that is usually why — the chat says
  which limit it hit.
- **At codelevels 1 and 2 the drone builds slowly on purpose**, so a beginner can
  watch a loop happen. Levels 3 and 4 do not wait.
- **A very large shape takes time and memory on the server.** It is not
  refused — it is paced, and the drone waits when the map is holding too much.
- A single player starts at the highest codelevel; on a server, new players start
  lower and an administrator raises it.

## Recent changes

- **A default block** you pick in the editor, so a bare `place()` builds what you
  chose. A program can override it for its own run with `default_block(block)`.
- **`sleep(seconds)`**, so a program can build at a pace you choose rather than
  the one your codelevel sets. Other drones keep building while yours waits.
- **Create a copy** in the editor, to try a variation without touching the
  version that works.
- **Unsaved tabs are marked** with a `*`, so you can see the editor is holding an
  edit you have not saved.
- Bulk shapes no longer depend on WorldEdit, and large builds no longer freeze
  the server.

The **Codecube** game bundles this mod with a flat world and settings chosen for
it, which is the quickest way to try it without setting a world up yourself.

Inspired by Gnancraft, ComputerCraft, Visual Bots, TurtleMiner and basic_robot.
