--- Building the environment a player program runs in.
--
-- Two jobs, both about isolation:
--
-- 1. `snapshot` gives each program run its own copy of the tables the API
--    exposes. They used to be handed out by reference: `blocks`, `plants`,
--    `wools`, `iwools` are the real entries of codeblock.config, and `vector`
--    was the real vector3 module. A program could therefore assign into them,
--    and the damage was global and lasted until the server restarted -
--    overwriting `vector.new` corrupted every player's programs and any other
--    mod using vector3; mutating `iwools` changed what color() returned for
--    everyone.
--
--    A copy rather than a read-only proxy, deliberately: Lua 5.1 has no
--    __pairs and no __len for tables, so a proxy would silently break
--    `pairs(blocks)`, `ipairs(iwools)` and `#iwools` for player code. Copying
--    ~150 small entries once per program start is not worth optimising.
--
-- 2. `new_env` makes the API surface itself unassignable, so a program cannot
--    replace `place` with its own function, and - the reason this matters -
--    cannot reach the injected budget counter to disable it. Player globals
--    still work normally, which matters because several shipped examples
--    declare top-level helper functions.
--
-- Dependency-free so tests/env_spec.lua can exercise it under a bare Lua
-- interpreter.

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
-- `api` holds everything the program may read. The returned table starts empty,
-- so:
--   * reading an API name falls through __index to `api`;
--   * assigning an API name raises, rather than silently shadowing it - note
--     this needs `api` to be a separate table, because __newindex is only
--     consulted for keys absent from the target;
--   * assigning anything else lands in the environment as a normal player
--     global.
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
