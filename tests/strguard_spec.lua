--- Tests for lib/strguard.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua mods/codeblock/tests/strguard_spec.lua
--
-- Or in-engine by starting the game with codeblock_run_tests = true.
--
-- The important tests here are the negative ones. This module modifies a
-- metatable shared by every string in the process, so "does it block the bad
-- case" matters less than "is it completely inert the rest of the time".

local strguard
do
    if rawget(_G, 'codeblock') and codeblock.strguard then
        strguard = codeblock.strguard
    else
        local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
        local candidates = {
            here and (here .. '/../lib/strguard.lua') or nil,
            'mods/codeblock/lib/strguard.lua', '../lib/strguard.lua',
            'lib/strguard.lua'
        }
        for _, p in ipairs(candidates) do
            local f = io.open(p, 'r')
            if f then
                f:close()
                strguard = dofile(p)
                break
            end
        end
    end
end

assert(strguard, 'could not locate lib/strguard.lua')

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

local function raises(f, ...)
    local ok, err = pcall(f, ...)
    return (not ok), tostring(err)
end

-- Installed once by init.lua in-engine; standalone we install it here.
if not strguard.is_active and true then end
local installed = strguard.install()
it('installs onto the string metatable', (installed == true), true)

--------------------------------------------------------------------------------
-- inert when no program is running
--
-- If any of these fail, the mod has broken string handling for the entire
-- server, which is far worse than the DoS it is guarding against.
--------------------------------------------------------------------------------

strguard.leave()

it('rep works normally when disarmed', ('ab'):rep(3), 'ababab')
it('a large rep is allowed when disarmed', #(('x'):rep(2000000)), 2000000)
it('format works normally when disarmed', ('%05d'):format(42), '00042')

-- Lua bounds format widths itself: the format-spec scanner accepts at most two
-- digits, so a padding attack is not possible and needs no guard from us. These
-- two tests record where that boundary actually is, rather than assuming it.
it('a two-digit format width is accepted', #(('%99d'):format(1)), 99)
it('a three-digit format width is rejected by Lua itself',
   (raises(function() return ('%100d'):format(1) end)), true)
it('an absurd format width is rejected by Lua itself',
   (raises(function() return ('%1000000000d'):format(1) end)), true)
it('gsub works normally when disarmed', ('aaa'):gsub('a', 'bb'), 'bbbbbb')
it('unguarded methods are untouched', ('abc'):upper(), 'ABC')
it('sub still works', ('abcdef'):sub(2, 4), 'bcd')
it('find still works', ('hello'):find('ll'), 3)
it('the string table itself is unaffected', string.rep('z', 3), 'zzz')

--------------------------------------------------------------------------------
-- armed: the amplifying calls are refused before they allocate
--------------------------------------------------------------------------------

strguard.enter(1024) -- a deliberately tiny ceiling for testing

it('the limit is what we set', strguard.get_limit(), 1024)
it('reports that it is armed', strguard.is_active(), true)

do
    local blocked, err = raises(function() return ('x'):rep(1e9) end)
    it('blocks the case this exists for: rep(1e9)', blocked, true)
    it('and says how big it would have been',
       (err:find('byte limit', 1, true) ~= nil), true)
end

it('blocks rep just over the limit', (raises(function()
    return ('x'):rep(1025)
end)), true)

it('allows rep just under the limit', #(('x'):rep(1000)), 1000)

it('accounts for the separator in rep', (raises(function()
    -- 600 chars of content, plus 599 separators of 1 char = 1199 > 1024
    return ('x'):rep(600, 'y')
end)), true)

it('blocks an amplifying gsub', (raises(function()
    return (('a'):rep(100)):gsub('a', ('b'):rep(100))
end)), true)

it('allows a non-amplifying gsub', (('aaa'):gsub('a', 'b')), 'bbb')

-- Methods that cannot amplify must stay unguarded even when armed.
it('sub is not restricted while armed', ('abcdef'):sub(2, 3), 'bc')
it('upper is not restricted while armed', ('abc'):upper(), 'ABC')
it('reverse is not restricted while armed', ('abc'):reverse(), 'cba')

--------------------------------------------------------------------------------
-- leaving restores full behaviour
--------------------------------------------------------------------------------

strguard.leave()

it('disarming restores large rep', #(('x'):rep(100000)), 100000)
it('disarming clears the armed flag', strguard.is_active(), false)

--------------------------------------------------------------------------------
-- installing twice must not lose the guards or double-wrap them
--------------------------------------------------------------------------------

do
    local again = strguard.install()
    it('re-installing succeeds', (again == true), true)
    strguard.enter(1024)
    it('guards still work after re-installing',
       (raises(function() return ('x'):rep(1e9) end)), true)
    strguard.leave()
    it('and still inert after leaving', #(('x'):rep(5000)), 5000)
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  strguard_spec'
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
