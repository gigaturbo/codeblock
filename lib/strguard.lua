--- Bounding the string methods that can allocate more than they are handed.
--
-- The sandbox environment does not contain `string`, but that is not enough: in
-- Lua 5.1 every string shares one metatable, so `("x"):rep(1e9)` reaches
-- string.rep from any literal no matter what the environment holds. It is a
-- single call, so it costs one unit against the call budget, and it allocates a
-- gigabyte before returning - which is why the heap check at yield points cannot
-- catch it. The memory is gone before any counter runs.
--
-- Nothing inside Lua can hide that metatable. What it *can* do is make the few
-- methods that amplify refuse an absurd result before computing it. After
-- checking each of them, only two can turn a small input into an arbitrarily
-- large output:
--
--   rep     output = #s * n                  - the one that matters
--   gsub    output is bounded by #s * #replacement
--
-- `format` looked like a third - ("%1000000000d"):format(1) would allocate a
-- gigabyte of padding - but Lua rejects it on its own: the format-spec scanner
-- accepts at most two digits of width, so `%100d` already raises "invalid
-- option". It needs no guard, and an early version of this module carried a dead
-- one. tests/strguard_spec.lua records that boundary so the assumption is
-- checked rather than trusted.
--
-- Everything else (sub, upper, reverse, byte, find, ...) returns something no
-- larger than its input, or a number.
--
-- How the window works, and why it is safe: `getmetatable('').__index` is
-- replaced once, at load, with a copy of the string table in which those two
-- entries are wrapped. Indexing cost is unchanged - it is still one table lookup,
-- not a metamethod call - and the wrappers do nothing at all unless a player
-- program is currently running. That window is opened around
-- `coroutine.resume` in drone_entity, and Luanti runs mods on one thread, so no
-- other mod's code can execute inside it.
--
-- What this does NOT cover: a pathological Lua pattern can burn CPU inside a
-- single find/match call, which the call counter cannot see either. That is a
-- separate problem and is not addressed here.

local strguard = {}

local active = false
local limit = 16 * 1024 * 1024 -- bytes; replaced per run by enter()

--------------------------------------------------------------------------------
-- window
--------------------------------------------------------------------------------

--- Arm the guards for one program run. `max_bytes` is the largest single string
-- a call may produce.
function strguard.enter(max_bytes)
    active = true
    limit = tonumber(max_bytes) or limit
end

--- Disarm. Always call this, including on error, or every other mod on the
-- server keeps the restriction.
function strguard.leave() active = false end

function strguard.is_active() return active end

--- For tests: what the guards would allow right now.
function strguard.get_limit() return limit end

--------------------------------------------------------------------------------
-- install
--------------------------------------------------------------------------------

--- Wrap rep and gsub on the shared string metatable.
-- Returns true when installed, or false plus a reason.
function strguard.install()

    local mt = getmetatable('')
    if type(mt) ~= 'table' then return false, 'strings have no metatable' end

    local real = mt.__index
    if type(real) ~= 'table' then
        return false, '__index of the string metatable is not a table'
    end

    local real_rep, real_gsub = real.rep, real.gsub
    if not (real_rep and real_gsub) then
        return false, 'string table is missing rep or gsub'
    end

    local function too_big(what, size)
        error(("%s would produce %d bytes, over the %d byte limit for one call")
                  :format(what, size, limit), 3)
    end

    -- Copy whatever is there now rather than referencing `string` directly, so
    -- that a wrapper installed by another mod is preserved instead of undone.
    local proxy = {}
    for k, v in pairs(real) do proxy[k] = v end

    proxy.rep = function(s, n, sep)
        if active then
            local count = tonumber(n) or 0
            if count > 0 then
                local size = #s * count
                if sep then size = size + #sep * (count - 1) end
                -- #s * count can overflow into inf for absurd n; either way the
                -- comparison below is the one that matters.
                if size > limit then too_big('rep', size) end
            end
        end
        return real_rep(s, n, sep)
    end

    proxy.gsub = function(s, pattern, repl, n)
        if active and type(repl) == 'string' and #repl > 1 then
            -- Upper bound: every position replaced. Deliberately pessimistic -
            -- rejecting a little early beats allocating and then complaining.
            local size = #s * #repl
            if size > limit then too_big('gsub', size) end
        end
        return real_gsub(s, pattern, repl, n)
    end

    mt.__index = proxy

    return true
end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

if rawget(_G, 'codeblock') then codeblock.strguard = strguard end

return strguard
