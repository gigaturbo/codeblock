--- Bounding the string methods that can allocate more than they are handed.
--
-- Leaving `string` out of the sandbox is not enough: in Lua 5.1 every string
-- shares one metatable, so `("x"):rep(1e9)` reaches string.rep from any
-- literal, costs a single call against the budget, and allocates a gigabyte
-- before any counter runs.
--
-- The metatable cannot be hidden, so `getmetatable('').__index` is replaced at
-- load with a copy in which the two methods that can turn a small input into a
-- large output - rep and gsub - refuse an absurd result before computing it.
-- Indexing costs the same, and the wrappers are inert unless a program is
-- running; lib/stepper.lua opens that window around coroutine.resume.
--
-- `format` needs no guard: its width field takes at most two digits, so
-- `%100d` already raises. tests/strguard_spec.lua pins that. Not covered: the
-- CPU a pathological Lua pattern can burn inside one find or match call.

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

    -- string.rep's separator is a 5.2 addition. LuaJIT has it; plain Lua 5.1
    -- ignores a third argument entirely. Probe rather than assume, or the size
    -- estimate would count separators that the interpreter never emits and
    -- reject calls that would in fact have been fine.
    local sep_supported = (#real_rep('x', 2, 'yy') == 4)

    proxy.rep = function(s, n, sep)
        if active then
            local count = tonumber(n) or 0
            if count > 0 then
                local size = #s * count
                if sep and sep_supported then
                    size = size + #sep * (count - 1)
                end
                -- #s * count can reach inf for an absurd n; the comparison
                -- below still does the right thing.
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
