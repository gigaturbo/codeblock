codeblock = {modpath = minetest.get_modpath('codeblock')}

dofile(codeblock.modpath .. "/lib/intl.lua")
dofile(codeblock.modpath .. "/lib/config.lua")
dofile(codeblock.modpath .. "/lib/utils.lua")
dofile(codeblock.modpath .. "/lib/pathjoin.lua")
dofile(codeblock.modpath .. "/lib/filesystem.lua")
dofile(codeblock.modpath .. "/lib/examples.lua")
--
-- codeblock.examples.load_examples() -- read at init time
--
dofile(codeblock.modpath .. "/lib/commands.lua")
dofile(codeblock.modpath .. "/lib/preprocess.lua")
dofile(codeblock.modpath .. "/lib/env.lua")
dofile(codeblock.modpath .. "/lib/strguard.lua")
dofile(codeblock.modpath .. "/lib/sandbox.lua")
dofile(codeblock.modpath .. "/lib/drone.lua")
dofile(codeblock.modpath .. "/lib/drone_entity.lua")
dofile(codeblock.modpath .. "/lib/formspecs.lua")
dofile(codeblock.modpath .. "/lib/register.lua")

-- Bound the string methods that can allocate more than they are given.
-- Inert until a player program is actually running; see lib/strguard.lua.
local ok, why = codeblock.strguard.install()
if not ok then
    minetest.log("warning", "[codeblock] string guards not installed: " ..
                     tostring(why))
end

if not minetest.mkdir(codeblock.filesystem.data_path) then
    error("[editor] failed to create directory!")
end

-- Run the test suite in-engine when asked. Mirrors worldedit_run_tests, and
-- means the specs are runnable without a Lua toolchain installed.
if minetest.settings:get_bool("codeblock_run_tests") then
    dofile(codeblock.modpath .. "/tests/preprocess_spec.lua")
    dofile(codeblock.modpath .. "/tests/env_spec.lua")
    dofile(codeblock.modpath .. "/tests/strguard_spec.lua")
    dofile(codeblock.modpath .. "/tests/integration_spec.lua")
end
