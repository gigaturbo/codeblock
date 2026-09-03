CodeBlock
=========================

[![CI](https://github.com/gigaturbo/codeblock/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/gigaturbo/codeblock/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/License-AGPLv3-blue.svg)
[![ContentDB](https://content.minetest.net/packages/giga-turbo/codeblock/shields/downloads/)](https://content.minetest.net/packages/giga-turbo/codeblock/)

**CodeBlock allows to use `lua` code in Minetest to build anything you want**

A drone you program in Lua, an in-game editor, a sandbox and a documented API. It works in any game that provides the blocks it places, and it depends on [vector3](https://content.minetest.net/packages/giga-turbo/vector3/). The [Codecube](https://content.minetest.net/packages/giga-turbo/codecube/) game bundles it with a flat world and settings made for it, which is the easiest way to try it.

**The reference is [`doc/api.md`](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#lua-api)**, generated from `lib/api.lua` and therefore always describing the API this mod actually has. The same source builds the help panel in the editor.

**License:** AGPLv3   
**Credits:** inspired by [Gnancraft](http://gnancraft.net/), [ComputerCraft](http://www.computercraft.info/), [Visual Bots](https://content.minetest.net/packages/Nigel/vbots/), [TurtleMiner](https://content.minetest.net/packages/BirgitLachner/turtleminer/), [basic_robot](https://github.com/ac-minetest/basic_robot)

![screenshot](https://raw.githubusercontent.com/gigaturbo/codeblock/master/screenshot.png)

## Quick start

### Run your first program

1. Create an empty (flat) world, enable `codeblock` mod ant its dependencies
2. Enable creative mode and start the game
3. Get the two drone tools: search for `drone` in the creative inventory, or run `/codeblock tools`. The mod never puts anything in your inventory by itself
4. Right click with ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png) tool on a block to place the drone, choose `stairs.lua` then left click with ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png) to start the drone

### Write your first program

1. Right click with ![drone_setter](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_setter.png) tool to open the `lua` editor
2. Create a new file with the `new file` field and write some code on the main window
3. Click `load and exit` to load your code in the drone
4. Right click with ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png) tool on a block and run the code with a left click on ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png)
5. Read the [Lua API](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#lua-api) in `doc/api.md` to know which commands and blocks you can use

### Watch and steer a running program

- While your program runs, a **HUD** in the top-right corner names the file, says
  whether it is running or paused, and shows the one limit the run **will stop
  on**. Untick *Show the drone HUD* on the editor's **Settings** panel to turn it
  off, or set `codeblock_drone_hud = false` for the server's default.
- **Left click your drone with the drone setter** to open its panel, whatever it
  is doing: every limit with what the run has spent beside it, a line saying what
  each one means, and buttons to **pause**, **resume**, **cancel** and **remove
  the drone**. With no drone placed, it tells you that instead.
- Two things the panel is careful about, because both misled at first. *Server
  time used* is the time the server actually gave the drone — roughly a tenth of
  the time you watch pass — not clock time, so a ceiling of 1800 s is nearer five
  hours than thirty minutes. And *Map held* says `throttled` rather than a
  percentage when it is full: reaching that one makes the drone **wait**, not
  stop, and it frees itself.

### Explore and tweak

- More built-in examples are available, just open the editor and choose an example to run
- User `codelevel` can be adjusted to tweak drone performance and capacities, see [permisisons](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#codelevel) and [chat commands](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#chat-commands)
