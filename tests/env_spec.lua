--- Tests for lib/env.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua mods/codeblock/tests/env_spec.lua
--
-- Or in-engine by starting the game with codeblock_run_tests = true.

local env
do
    if rawget(_G, 'codeblock') and codeblock.env then
        env = codeblock.env
    else
        local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
        local candidates = {
            here and (here .. '/../lib/env.lua') or nil,
            'mods/codeblock/lib/env.lua', '../lib/env.lua', 'lib/env.lua'
        }
        for _, p in ipairs(candidates) do
            local f = io.open(p, 'r')
            if f then
                f:close()
                env = dofile(p)
                break
            end
        end
    end
end

assert(env, 'could not locate lib/env.lua')

--------------------------------------------------------------------------------
-- harness
--------------------------------------------------------------------------------

local pass, fail = 0, 0
local failures = {}

local function it(name, got, want)
    if got == want then
        pass = pass + 1
    else
        fail = fail + 1
        failures[#failures + 1] = ('FAIL   %s\n       want: %s\n       got : %s')
                                      :format(name, tostring(want), tostring(got))
    end
end

--- Did calling f() raise?
local function raises(f, ...)
    local ok = pcall(f, ...)
    return not ok
end

--------------------------------------------------------------------------------
-- snapshot: a program must not be able to reach shared state
--------------------------------------------------------------------------------

do
    local shared = {red = 'wool:red', blue = 'wool:blue'}
    local copy = env.snapshot(shared)

    it('snapshot copies every entry', copy.red, 'wool:red')

    copy.red = 'tampered'
    it('writing to the copy leaves the original alone', shared.red, 'wool:red')

    copy.extra = 'new'
    it('adding to the copy does not add to the original', shared.extra, nil)

    -- The reason a copy was chosen over a read-only proxy: Lua 5.1 has no
    -- __pairs or table __len, so a proxy would break these for player code.
    local n = 0
    for _ in pairs(copy) do n = n + 1 end
    it('pairs() still works over a snapshot', n, 3)

    local arr = env.snapshot({'a', 'b', 'c'})
    it('# still works over a snapshot', #arr, 3)
    local m = 0
    for _ in ipairs(arr) do m = m + 1 end
    it('ipairs() still works over a snapshot', m, 3)
end

--------------------------------------------------------------------------------
-- snapshot_module: vector3 is callable, so the metatable has to travel
--------------------------------------------------------------------------------

do
    local mod = setmetatable({scale = function(n) return n * 2 end},
                             {__call = function(_, x) return 'made ' .. x end})
    local copy = env.snapshot_module(mod)

    it('module copy keeps its functions', copy.scale(4), 8)
    it('module copy is still callable via __call', copy('v'), 'made v')

    copy.scale = function() return 0 end
    it('overwriting the copy leaves the real module intact', mod.scale(4), 8)
end

--------------------------------------------------------------------------------
-- seal: the budget counter must be unassignable
--------------------------------------------------------------------------------

do
    local calls = 0
    local sealed = env.seal({use_call = function() calls = calls + 1 end}, '_G')

    sealed.use_call()
    it('a sealed table can be read through', calls, 1)

    it('assigning to a sealed field raises',
       raises(function() sealed.use_call = function() end end), true)

    it('the counter still works after a failed tamper', (function()
        pcall(function() sealed.use_call = nil end)
        sealed.use_call()
        return calls
    end)(), 2)

    it('adding a new field to a sealed table also raises',
       raises(function() sealed.anything = 1 end), true)
end

--------------------------------------------------------------------------------
-- new_env: API read-only, player globals free
--------------------------------------------------------------------------------

do
    local api = {place = function() return 'placed' end, blocks = {stone = 1}}
    local e = env.new_env(api)

    it('an API name reads through', e.place(), 'placed')

    it('assigning over an API name raises',
       raises(function() e.place = function() return 'hijacked' end end), true)

    it('the API is intact after a failed hijack', e.place(), 'placed')

    -- Several shipped examples declare top-level helper functions, so ordinary
    -- player globals have to keep working.
    e.my_helper = function() return 'mine' end
    it('a player global can be defined', e.my_helper(), 'mine')

    e.counter = 1
    e.counter = e.counter + 1
    it('a player global can be reassigned', e.counter, 2)

    it('an undefined name still reads as nil', e.nonexistent, nil)

    -- This is the case the whole design exists for.
    local sealed_counter = env.seal({use_call = function() end}, '_G')
    api._G = sealed_counter
    it('the counter cannot be replaced wholesale',
       raises(function() e._G = {use_call = function() end} end), true)
    it('the counter field cannot be replaced either',
       raises(function() e._G.use_call = function() end end), true)
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  env_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''

local text = table.concat(out, '\n')
if rawget(_G, 'core') or rawget(_G, 'minetest') then
    print(text)
else
    io.write(text)
    os.exit(fail == 0 and 0 or 1)
end

return {passed = pass, failed = fail}
