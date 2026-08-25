codeblock = {modpath = minetest.get_modpath('codeblock')}

dofile(codeblock.modpath .. "/lib/intl.lua")
dofile(codeblock.modpath .. "/lib/config.lua")
dofile(codeblock.modpath .. "/lib/api.lua")
dofile(codeblock.modpath .. "/lib/utils.lua")
dofile(codeblock.modpath .. "/lib/pathjoin.lua")
dofile(codeblock.modpath .. "/lib/filesystem.lua")
dofile(codeblock.modpath .. "/lib/examples.lua")
--
-- codeblock.examples.load_examples() -- read at init time
--
dofile(codeblock.modpath .. "/lib/shapes.lua")
dofile(codeblock.modpath .. "/lib/commands.lua")
dofile(codeblock.modpath .. "/lib/preprocess.lua")
dofile(codeblock.modpath .. "/lib/env.lua")
dofile(codeblock.modpath .. "/lib/strguard.lua")
dofile(codeblock.modpath .. "/lib/sandbox.lua")
dofile(codeblock.modpath .. "/lib/forms.lua")
dofile(codeblock.modpath .. "/lib/drone.lua")
dofile(codeblock.modpath .. "/lib/stepper.lua")
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

-- Regenerate the API reference from lib/api.lua when asked.
-- scripts/gen_docs.lua does the same thing under a bare interpreter and writes
-- doc/api.md in place; this path exists so the docs can be regenerated with
-- nothing installed but the game itself.
--
-- It writes into the world directory rather than the mod directory, because
-- Luanti's mod security blocks writes to a mod's own files - reads are fine,
-- writes are not. Copy the result over doc/api.md. Slightly manual, but it
-- beats requiring a Lua toolchain, and CI's `gen_docs.lua --check` catches it if
-- the copy is forgotten.
if minetest.settings:get_bool("codeblock_gen_docs") then
    local source = codeblock.modpath .. "/doc/api.md"
    local path = minetest.get_worldpath() .. "/api.md"
    local current = ""
    local f = io.open(source, "rb")
    if f then
        current = f:read("*a")
        f:close()
    end

    -- Sorted rather than in declaration order: sorting needs no parsing of
    -- config.lua's source, gives the same answer here and in
    -- scripts/gen_docs.lua, and makes a name easier to find in a long list.
    -- iwools keeps its own order, which is meaningful - it is a rainbow.
    local sorted = codeblock.utils.table_convert_ik
    local allowed = codeblock.config.allowed_blocks
    local wanted, why = codeblock.api.compose_markdown(current, {
        blocks = sorted(allowed.cubes),
        plants = sorted(allowed.plants),
        wools = sorted(allowed.wools),
        iwools = allowed.iwools
    })

    if not wanted then
        print("[codeblock] doc/api.md: " .. tostring(why))
    elseif wanted == current then
        print("[codeblock] doc/api.md is already up to date")
    else
        local out = io.open(path, "wb")
        if out then
            out:write(wanted)
            out:close()
            print("[codeblock] wrote " .. path)
            print("[codeblock] copy it over doc/api.md to update the reference")
        else
            print("[codeblock] cannot write " .. path)
        end
    end
end

-- Run the test suite in-engine when asked. Mirrors worldedit_run_tests, and
-- means the specs are runnable without a Lua toolchain installed.
if minetest.settings:get_bool("codeblock_run_tests") then
    dofile(codeblock.modpath .. "/tests/api_spec.lua")
    dofile(codeblock.modpath .. "/tests/preprocess_spec.lua")
    dofile(codeblock.modpath .. "/tests/env_spec.lua")
    dofile(codeblock.modpath .. "/tests/shapes_spec.lua")
    dofile(codeblock.modpath .. "/tests/strguard_spec.lua")
    dofile(codeblock.modpath .. "/tests/forms_spec.lua")
    dofile(codeblock.modpath .. "/tests/stepper_spec.lua")
    dofile(codeblock.modpath .. "/tests/integration_spec.lua")
end
