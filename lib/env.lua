--- Building the environment a player program runs in.
--
-- `snapshot` gives each run its own copy of the tables the API exposes, so a
-- program assigning into `blocks` or `vector` cannot corrupt them for every
-- other player until the server restarts. Copies rather than read-only proxies:
-- Lua 5.1 has no __pairs or __len, so a proxy would break pairs(blocks) and
-- #iwools for player code.
--
-- `new_env` makes the API names unassignable, so a program cannot replace
-- `place` or reach the injected budget counter. Player globals still work.
--
-- Dependency-free, so tests/env_spec.lua can run it under a bare interpreter.

local env = {}

--------------------------------------------------------------------------------
-- copies
--------------------------------------------------------------------------------

--- Shallow copy of a plain table.
function env.snapshot(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

--- Shallow copy that keeps the original's metatable.
-- vector3 is `setmetatable(mod, {__call = ...})`, so `vector(1, 2, 3)` only
-- works while the metatable travels with the copy. The metatable itself stays
-- shared, which is safe because getmetatable is not in the environment.
function env.snapshot_module(t)
    return setmetatable(env.snapshot(t), getmetatable(t))
end

--------------------------------------------------------------------------------
-- read-only API surface
--------------------------------------------------------------------------------

--- Wrap a table so reads pass through and every write fails.
-- Used for the injected counter: the instrumenter emits `_G.use_call()`, and a
-- program that could assign to that field would switch its own budget off.
function env.seal(t, what)
    return setmetatable({}, {
        __index = t,
        __newindex = function(_, k)
            error(("cannot modify %s.%s"):format(what or '_G', tostring(k)), 2)
        end
    })
end

--- Build the environment table handed to setfenv.
--
-- Starts empty, so reading an API name falls through to `api` and assigning
-- anything else lands as a normal player global, while assigning an API name
-- raises. `api` has to be a separate table for that: __newindex is only
-- consulted for keys absent from the target.
function env.new_env(api)
    return setmetatable({}, {
        __index = api,
        __newindex = function(t, k, v)
            if api[k] ~= nil then
                error(("'%s' is part of the API and cannot be reassigned"):format(
                          tostring(k)), 2)
            end
            rawset(t, k, v)
        end
    })
end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

if rawget(_G, 'codeblock') then codeblock.env = env end

return env
