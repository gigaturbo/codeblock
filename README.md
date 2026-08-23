CodeBlock
=========================

![License](https://img.shields.io/badge/License-AGPLv3-blue.svg)
[![ContentDB](https://content.minetest.net/packages/giga-turbo/codeblock/shields/downloads/)](https://content.minetest.net/packages/giga-turbo/codeblock/)

**CodeBlock allows to use `lua` code in Minetest to build anything you want**

**License:** AGPLv3   
**Credits:** inspired by [Gnancraft](http://gnancraft.net/), [ComputerCraft](http://www.computercraft.info/), [Visual Bots](https://content.minetest.net/packages/Nigel/vbots/), [TurtleMiner](https://content.minetest.net/packages/BirgitLachner/turtleminer/), [basic_robot](https://github.com/ac-minetest/basic_robot)

![screenshot](https://raw.githubusercontent.com/gigaturbo/codeblock/master/screenshot.png)

## Quick start

### Run your first program

1. Create an empty (flat) world, enable `codeblock` mod ant its dependencies
2. Enable creative mode and start the game
3. Right click with ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/dp.png) tool on a block to place the drone, choose `stairs.lua` then left click with ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/dp.png) to start the drone

### Write your first program

1. Right click with ![drone_setter](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/ds.png) tool to open the `lua` editor
2. Create a new file with the `new file` field and write some code on the main window
3. Click `load and exit` to load your code in the drone
4. Right click with ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/dp.png) tool on a block and run the code with a left click on ![drone_poser](https://raw.githubusercontent.com/gigaturbo/codeblock/master/doc/dp.png)
5. Read the [Lua API](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#lua-api) in `doc/api.md` to know which commands and blocks you can use

### Explore and tweak

- More built-in examples are available, just open the editor and choose an example to run
- User `codelevel` can be adjusted to tweak drone performance and capacities, see [permisisons](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#codelevel) and [chat commands](https://github.com/gigaturbo/codeblock/blob/master/doc/api.md#chat-commands)