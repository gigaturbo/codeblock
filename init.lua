codeblock = {modpath = core.get_modpath('codeblock')}

dofile(codeblock.modpath .. "/lib/intl.lua")
dofile(codeblock.modpath .. "/lib/config.lua")
dofile(codeblock.modpath .. "/lib/nodes.lua")
dofile(codeblock.modpath .. "/lib/api.lua")
dofile(codeblock.modpath .. "/lib/blocks.lua")
dofile(codeblock.modpath .. "/lib/pathjoin.lua")
dofile(codeblock.modpath .. "/lib/filesystem.lua")
dofile(codeblock.modpath .. "/lib/examples.lua")
--
-- codeblock.examples.load_examples() -- read at init time
--
dofile(codeblock.modpath .. "/lib/limits.lua")
dofile(codeblock.modpath .. "/lib/shapes.lua")
dofile(codeblock.modpath .. "/lib/cost.lua")
dofile(codeblock.modpath .. "/lib/commands.lua")
dofile(codeblock.modpath .. "/lib/preprocess.lua")
dofile(codeblock.modpath .. "/lib/env.lua")
dofile(codeblock.modpath .. "/lib/strguard.lua")
dofile(codeblock.modpath .. "/lib/sandbox.lua")
dofile(codeblock.modpath .. "/lib/forms.lua")
dofile(codeblock.modpath .. "/lib/stepper.lua")
dofile(codeblock.modpath .. "/lib/drone.lua")
dofile(codeblock.modpath .. "/lib/drone_entity.lua")
dofile(codeblock.modpath .. "/lib/hud.lua")
dofile(codeblock.modpath .. "/lib/formspecs.lua")
dofile(codeblock.modpath .. "/lib/register.lua")

-- Bound the string methods that can allocate more than they are given.
-- Inert until a player program is actually running; see lib/strguard.lua.
local ok, why = codeblock.strguard.install()
if not ok then
    core.log("warning", "[codeblock] string guards not installed: " ..
                     tostring(why))
end

-- Name an installed vector3 that hands its method table back from every vector,
-- because a player program can then replace a vector3 method for every mod on
-- the server (S9). Fixed upstream in 2.0.2, which carries __index on a separate
-- metatable; mod.conf cannot ask for a version, Luanti having no version
-- constraint, so saying so is all this mod can do. Silent on a library without
-- the hole: a line on every start that reports nothing is noise.
--
-- Read-only detection, deliberately. Probing by writing to a constant succeeds
-- on 1.5 and changes that constant for the whole server, which would be causing
-- the other defect in order to test for this one (S8). Which version it is
-- follows from the same two reads: on 1.5 the constants are plain vectors, on
-- 2.0.1 they are frozen and iterate as empty. Not translated - this is a
-- debug.txt line for whoever runs the server, and engine logs are English.
if vector3(1, 1, 1).__index ~= nil then
    local guess = (type(vector3.one) == 'table' and next(vector3.one)) and
                      'v1.5' or 'v2.0.1'
    core.log('warning',
             '[codeblock] the installed vector3 (looks like ' .. guess ..
                 ') exposes its method table on every vector, so a player ' ..
                 'program can replace a vector3 method for every mod on this ' ..
                 'server. Install vector3 2.0.2 or newer.')
end

if not core.mkdir(codeblock.filesystem.data_path) then
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
if core.settings:get_bool("codeblock_gen_docs") then
    local source = codeblock.modpath .. "/doc/api.md"
    local path = core.get_worldpath() .. "/api.md"
    local current = ""
    local f = io.open(source, "rb")
    if f then
        current = f:read("*a")
        f:close()
    end

    -- The block lists come out in palette order, not sorted: that order is the
    -- rainbow a ramp maps onto, so a list in it reads as one. config.lua owns
    -- it, and both this and scripts/gen_docs.lua hand the same table to the
    -- same renderer, which is what keeps their answers identical.
    local wanted, err = codeblock.api.compose_markdown(current,
                                                      codeblock.config
                                                          .allowed_blocks)

    if not wanted then
        print("[codeblock] doc/api.md: " .. tostring(err))
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
--
-- Nothing is assumed to be there: `tests export-ignore` in .gitattributes keeps
-- the specs out of the ContentDB archive, so in a release build this setting
-- would take the whole mod down on a missing file. It says so instead. (C16)
if core.settings:get_bool("codeblock_run_tests") then

    local specs = {
        'api', 'preprocess', 'env', 'shapes', 'strguard', 'limits', 'forms',
        'stepper', 'integration'
    }

    local first = io.open(codeblock.modpath .. '/tests/api_spec.lua', 'r')

    if not first then
        core.log('warning', '[codeblock] codeblock_run_tests is set, but this ' ..
                     'build ships no tests/ directory')
    else
        first:close()
        for _, spec in ipairs(specs) do
            dofile(codeblock.modpath .. '/tests/' .. spec .. '_spec.lua')
        end
    end

end
