Write a program in Lua and watch your drone build it! You get an editor inside
the game and an API of shapes and maths to build procedurally any structure you
can imagine: learn to code, or give your inner computer artist somewhere to play.

## Features

- **An editor in the game.** A per-player program list, create, edit and save,
  and helpers beside the code for when you forget a command or a block name.
- **A large API.** Shapes, maths and conveniences: cubes, spheres, domes and
  cylinders, a random block, plant or wool colour, and named checkpoints the
  drone can return to.
- **Real Lua.** Loops, functions, recursion and maths, everything in a sandbox
  that cannot harm the server.
- **Example programs to discover.** Spirals, fractals, 3D plots and other more
  artistic examples. Open one and change a number to see what happens.
- **A control panel.** A nice UI gives you every limit with what your program has
  spent beside it, as well as pause, resume and stop controls on the drone.
- **Per-player limits** an administrator can tune, so the mod is usable on a
  public server and not only in singleplayer: how many blocks one program may
  write, how much CPU time it may use, how much of the map it may hold and how
  much memory it may grow by.

## Quick start

1. New flat world, creative mode, mod enabled. Run `/codeblock tools` to be given
   the **Drone placer** and the **Drone setter**, or take them from the creative
   inventory.
2. **Right click a block with the Drone placer.** A list of programs appears,
   pick `stairs.lua`.
3. **Left click with the Drone placer.** The drone builds the staircase in front
   of you.

To change what it builds:

4. **Right click with the Drone setter** to open the editor. Open `stairs.lua`,
   change the number of stairs, click *Load and close*.
5. Place a drone and left click again.

Experiment and discover with the other examples, or write your own!

## Important notes

- **Every player has a `codelevel`**, and it bounds what one program may spend of
  the server: how long it runs, how many blocks it writes, how much of the map it
  holds at once. If a program stops early, that is usually why, and the chat says
  which limit it hit. While it is still running, the corner display says which
  limit it is heading for.
- **At codelevels 1 and 2 the drone builds slowly on purpose**, so a beginner can
  watch a loop happen. Levels 3 and 4 do not wait.
- **A very large shape takes time and memory on the server.** It is not
  refused — it is paced, and the drone waits when the map is holding too much.
- A single player starts high enough not to wait; on a server, new players start
  lower and an administrator raises it. The widest ceilings are never given out
  by default — someone has to ask.

## Recent changes

- **HUD** A display in the top right corner while a program runs, showing how
  much of its budget it has spent.
- **Control panel** Left click with the **drone setter** tool to show a panel with the drone limits, plus pause and stop buttons.
- **Default block** Can be set in `Editor` > `Settings`, then a bare `place()` builds using this block. A program can override it for its *own run* with `default_block(block)`.
- **`sleep(seconds)`** Pauses a program for a given duration.
- **Create a copy** New button in the editor to open a copy of a program.
- **Unsaved tabs** Now marked with a `*` so you can see the editor is holding an
  edit you have not saved.
- **Performance** Bulk shapes no longer depend on WorldEdit, and large builds no longer freeze
  the server.

The **Codecube** game bundles this mod with a flat world and settings chosen for
it, which is the quickest way to try it without setting a world up yourself.

Inspired by Gnancraft, ComputerCraft, Visual Bots, TurtleMiner and basic_robot.
