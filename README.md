CodeBlock
=========================

[![CI](https://github.com/gigaturbo/codeblock/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/gigaturbo/codeblock/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/License-AGPLv3-blue.svg)
[![ContentDB](https://content.luanti.org/packages/giga-turbo/codeblock/shields/downloads/)](https://content.luanti.org/packages/giga-turbo/codeblock/)

**CodeBlock allows to use `lua` code in Luanti to build anything you want**

A drone you program in Lua, an in-game editor, a sandbox and a documented API. It brings its own blocks: 35 colours, each as a solid block, a glass and a lamp. It depends only on [vector3](https://content.luanti.org/packages/giga-turbo/vector3/). The [Codecube](https://content.luanti.org/packages/giga-turbo/codecube/) game bundles it with a flat world and settings made for it, which is the easiest way to try it. The Lua and block reference is at [`doc/api.md`](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#lua-api).

**License:** AGPLv3   
**Credits:** inspired by [Gnancraft](http://gnancraft.net/), [ComputerCraft](http://www.computercraft.info/), [Visual Bots](https://content.luanti.org/packages/Nigel/vbots/), [TurtleMiner](https://content.luanti.org/packages/BirgitLachner/turtleminer/), [basic_robot](https://github.com/ac-minetest/basic_robot)

![screenshot](https://raw.githubusercontent.com/gigaturbo/codeblock/master/screenshot.png)

## Quick start

### Run your first program

1. Create an empty (flat) world, enable the `codeblock` mod and its one dependency `vector3`
2. Enable creative mode and start the game
3. Get the two drone tools: run the `/codeblock tools` command (or use creative inventory)
4. Right click with ![drone_placer](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png) tool on a block to place the drone, choose `stairs.lua` then left click with ![drone_placer](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png) to start the drone

### Write your first program

1. Right click with ![drone_setter](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_setter.png) tool to open the `lua` editor
2. Create a new file with the `new file` field and write some code on the main window
3. Click `load and close` to load your code in the drone
4. Right click with ![drone_placer](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png) tool on a block and run the code with a left click on ![drone_placer](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/drone_poser.png)
5. Read the [Lua API](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#lua-api) in `doc/api.md` to know which commands and blocks you can use

### Watch and steer a running program

- While your program runs, a **HUD** in the top-right corner names the file, says
  whether it is running or paused, and shows the limits of the drone. Untick *Show the drone HUD* on the editor's **Settings** panel to turn it
  off or set `codeblock_drone_hud = false` for the server's default.
- **Left click your drone with the drone setter** to open its panel, whatever it
  is doing: every limit with what the run has spent beside it, a line saying what
  each one means, and buttons to **pause**/**resume** and **stop**
  the drone.

### Explore and tweak

- More built-in examples are available, just open the editor and choose an example to run
- User `codelevel` can be adjusted to tweak drone performance and capacities, see [permissions](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#codelevel) and [chat commands](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#chat-commands)

## For game authors

Your game can add a block category of its own. Call this from a mod that names
`codeblock` in its `depends`, at load time:

```lua
codeblock.register_blocks('wool', {
    red = 'wool:red',
    blue = 'wool:blue'
})
```

`wool.red` is then a block a player's program can place, listed in the editor
beside the mod's own colours, glass and lamps. The keys are the names a program
spells; the values are itemstrings your game has registered.

Registrations are queued at the call and checked once every mod has loaded, so a
node belonging to a mod that loads later is still accepted. A name that collides
with the existing API, cannot be a table key, or names no node is logged and
dropped — never raised, so a typo in your game cannot stop the server.
