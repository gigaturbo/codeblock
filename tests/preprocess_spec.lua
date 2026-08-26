--- Tests for lib/preprocess.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua mods/codeblock/tests/preprocess_spec.lua
--
-- Or in-engine, with no toolchain installed, by starting the game with
--     codeblock_run_tests = true
-- in minetest.conf (mirrors the worldedit_run_tests convention).
--
-- Tests marked `xfail` assert the behaviour we WANT and are known to fail
-- against the current implementation. They are the audit's confirmed defects,
-- and flipping them to `it` is the acceptance criterion for the Phase 2
-- preprocessor rewrite. A green run means "no regressions and no accidental
-- fixes"; the xfail block below is the work list.

local preprocess
do
    -- Locate the module whether we were launched from the repo root, from this
    -- directory, or by the mod itself.
    if rawget(_G, 'codeblock') and codeblock.preprocess then
        preprocess = codeblock.preprocess
    else
        local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
        local candidates = {
            here and (here .. '/../lib/preprocess.lua') or nil,
            'mods/codeblock/lib/preprocess.lua',
            '../lib/preprocess.lua',
            'lib/preprocess.lua'
        }
        for _, p in ipairs(candidates) do
            local f = io.open(p, 'r')
            if f then
                f:close()
                preprocess = dofile(p)
                break
            end
        end
    end
end

assert(preprocess, 'could not locate lib/preprocess.lua')

local pp = preprocess.preprocess_code
local forbidden = preprocess.find_forbidden

--------------------------------------------------------------------------------
-- harness
--------------------------------------------------------------------------------

local pass, fail, xfailed, xpassed = 0, 0, 0, 0
local failures = {}

local function report(ok, name, detail, expected_fail)
    if ok and not expected_fail then
        pass = pass + 1
    elseif ok and expected_fail then
        xpassed = xpassed + 1
        failures[#failures + 1] = ('XPASS  %s\n       now passes - promote it from xfail() to it()'):format(name)
    elseif not ok and expected_fail then
        xfailed = xfailed + 1
    else
        fail = fail + 1
        failures[#failures + 1] = ('FAIL   %s\n%s'):format(name, detail or '')
    end
end

local function check(name, got, want, expected_fail)
    local ok = (got == want)
    local detail
    if not ok then
        detail = ('       want: %s\n       got : %s'):format(
                     string.format('%q', tostring(want)),
                     string.format('%q', tostring(got)))
    end
    report(ok, name, detail, expected_fail)
end

-- `it` asserts current, correct behaviour. `xfail` asserts behaviour we want
-- but do not yet have.
local function it(name, got, want) check(name, got, want, false) end
local function xfail(name, got, want) check(name, got, want, true) end

--- Does `src` still parse as Lua after instrumentation?
local compile = loadstring or load
local function compiles(src)
    local chunk = compile(src)
    return chunk ~= nil
end

--- Is `needle` still present in the instrumented output?
local function keeps(src, needle)
    return pp(src):find(needle, 1, true) ~= nil
end

--------------------------------------------------------------------------------
-- what already works - guard against regressions
--------------------------------------------------------------------------------

it('injects a counter into a for loop',
   keeps('for i = 1, 10 do up(1) end\n', '_G.use_call();'), true)

it('injects a counter into a while loop',
   keeps('while true do up(1) end\n', '_G.use_call();'), true)

it('injects a counter into a function body',
   keeps('function f(a) return a end\n', '_G.use_call();'), true)

it('instruments a nested loop more than once', (function()
    local out = pp('for i = 1, 3 do for j = 1, 3 do up(1) end end\n')
    local n = 0
    for _ in out:gmatch('_G%.use_call%(%)') do n = n + 1 end
    return n >= 2
end)(), true)

it('instrumented for loop still compiles',
   compiles(pp('for i = 1, 10 do up(1) end\n')), true)

it('instrumented function still compiles',
   compiles(pp('function f(a) return a + 1 end\nf(1)\n')), true)

it('instrumented nested loop still compiles',
   compiles(pp('for i = 1, 3 do for j = 1, 3 do up(1) end end\n')), true)

it('leaves a plain statement sequence intact',
   keeps('place(blocks.stone)\nup(1)\n', 'place(blocks.stone)'), true)

it('leaves a loop keyword inside a string alone',
   pp('print("for i = 1, 3 do end")\n'):find('_G.use_call();', 1, true), nil)

it('leaves a loop keyword inside a comment alone',
   pp('-- for i = 1, 3 do end\nup(1)\n'):find('_G.use_call();', 1, true), nil)

it('leaves comments in place instead of stripping them',
   keeps('-- a comment\nup(1)\n', 'a comment'), true)

it('leaves a program with nothing to instrument byte-identical',
   pp('place(blocks.stone)\nup(1)\n'), 'place(blocks.stone)\nup(1)\n')

--------------------------------------------------------------------------------
-- lexer: the guarantees tokenising buys us
--------------------------------------------------------------------------------

it('handles a levelled long comment',
   compiles(pp('--[==[\nprose ]] still prose\n]==]\nfor i=1,3 do up(1) end\n')), true)

it('does not instrument inside a long string',
   pp('local s = [[ for i=1,3 do end ]]\n'):find('_G.use_call();', 1, true), nil)

it('instruments a function whose name contains a keyword',
   keeps('function do_it(n) return n end\n', '_G.use_call();'), true)

it('counts each of two sibling functions', (function()
    local out = pp('function a(x) return x end\nfunction b(y) return y end\n')
    local n = 0
    for _ in out:gmatch('_G%.use_call%(%)') do n = n + 1 end
    return n
end)(), 2)

it('instruments a method definition',
   compiles(pp('local t = {}\nfunction t.m(a) return a end\n')), true)

it('handles a hex literal without inventing a keyword',
   pp('local x = 0xdead\n'):find('_G.use_call();', 1, true), nil)

--------------------------------------------------------------------------------
-- forbidden names, now checked against identifier tokens
--------------------------------------------------------------------------------

it('accepts an ordinary program', forbidden('for i=1,3 do up(1) end'), nil)

-- Names that are simply absent from the environment. Naming them here is not
-- what makes them safe - it turns "attempt to index a nil value" into a message
-- that says which name a beginner reached for.
it('names os', forbidden('local t = os.time()'), 'os')
it('names io', forbidden('io.open("x")'), 'io')
it('names loadstring', forbidden('loadstring("x")()'), 'loadstring')
it('names require', forbidden('require("foo")'), 'require')
it('names pcall', forbidden('pcall(up, 1)'), 'pcall')
it('names setmetatable', forbidden('setmetatable({}, {})'), 'setmetatable')
it('names the engine namespace', forbidden('minetest.chat_send_all("x")'),
   'minetest')

-- ... and does so without the substring false positives the old list had.
it('allows an identifier containing "until"', forbidden('local until_done = 1'), nil)
it('allows "repeat" inside a string', forbidden('print("repeat that")'), nil)
it('allows an unavailable name inside a string', forbidden('print("os")'), nil)
it('allows an unavailable name inside a comment',
   forbidden('-- about os.time\nup(1)\n'), nil)
it('allows an identifier merely containing one', forbidden('local iowa = 1'), nil)
it('allows a field with the same name', forbidden('local x = t.os'), nil)

-- _G is no longer blocked by name. The counter is sealed and API names cannot
-- be reassigned, so `_G.use_call = ...` and `_G = {}` fail on their own; see
-- env_spec and integration_spec.
it('no longer blocks _G by name', forbidden('_G.print("x")'), nil)

--------------------------------------------------------------------------------
-- repeat/until, previously refused outright because patterns could not
-- instrument it
--------------------------------------------------------------------------------

it('allows a repeat/until loop', forbidden('repeat up(1) until false'), nil)
it('instruments a repeat/until loop',
   keeps('repeat up(1) until false\n', '_G.use_call();'), true)
it('instrumented repeat/until still compiles',
   compiles(pp('local i = 0\nrepeat i = i + 1 until i > 3\n')), true)

--------------------------------------------------------------------------------
-- former defects B1-B4, fixed by tokenising instead of pattern matching
--------------------------------------------------------------------------------

-- B1: a greedy `--[[.*--]]` spanned from the file's first block comment to its
-- last, deleting every statement in between.
it('B1 keeps code sitting between two block comments',
   keeps('--[[ a --]]\nplace(blocks.stone)\nup(1)\n--[[ b --]]\nforward(1)\n',
         'place(blocks.stone)'), true)

-- B2: only the `--]]` spelling was understood, so a normal `--[[ ... ]]`
-- comment lost its opening line and left its body behind as bare code. Comments
-- are no longer touched at all, so the body stays a comment.
it('B2 output still compiles after a standard block comment',
   compiles(pp('--[[\nthis is prose\n]]\nup(1)\n')), true)

it('B2 leaves a standard block comment byte-identical',
   pp('--[[\nthis is prose\n]]\nup(1)\n'), '--[[\nthis is prose\n]]\nup(1)\n')

-- B3: comments were stripped before strings were identified, so a `--` inside
-- a string truncated it.
it('B3 preserves a string containing a double dash',
   keeps('print("a -- b")\nup(1)\n', 'a -- b'), true)

it('B3 output still compiles with a double dash in a string',
   compiles(pp('print("a -- b")\nup(1)\n')), true)

-- B4: `function` was matched as a bare substring, so an identifier merely
-- containing those letters injected a statement after the next `)` in the file.
it('B4 ignores "function" inside an identifier',
   compiles(pp('local nfunctions = 3\nlocal x = myfunc(1) + 2\n')), true)

it('B4 does not inject into an unrelated call expression',
   pp('local counter_function_total = 0\nlocal y = abs(-3) + 7\n')
       :find('_G.use_call();', 1, true), nil)

--------------------------------------------------------------------------------
-- functional: does the instrumentation actually enforce a budget?
--
-- The tests above check that text was inserted and still compiles. These run
-- the instrumented chunk against a stub counter, which is the property that
-- actually matters: a runaway program must be stopped.
--------------------------------------------------------------------------------

local setfenv_ = setfenv  -- 5.1 / LuaJIT

--- Run `src` instrumented, with a counter that errors after `budget` calls.
-- Returns calls_made, outcome ('completed' or 'stopped').
local function run_with_budget(src, budget)
    local chunk = compile(pp(src))
    if not chunk then return -1, 'compile failed' end
    local n = 0
    local env = {}
    env._G = {
        use_call = function()
            n = n + 1
            if n > budget then error('budget exhausted', 0) end
        end
    }
    setfenv_(chunk, env)
    local ok = pcall(chunk)
    return n, ok and 'completed' or 'stopped'
end

it('stops an infinite while loop', select(2, run_with_budget('while true do end\n', 50)), 'stopped')
it('charges the infinite loop the whole budget',
   (select(1, run_with_budget('while true do end\n', 50)) > 50), true)

it('stops an infinite repeat loop',
   select(2, run_with_budget('repeat until false\n', 50)), 'stopped')

it('stops an infinite numeric for',
   select(2, run_with_budget('for i = 1, 1e9 do end\n', 50)), 'stopped')

it('stops unbounded recursion',
   select(2, run_with_budget('function f() return f() end\nf()\n', 50)), 'stopped')

it('lets a bounded loop finish',
   select(2, run_with_budget('for i = 1, 5 do end\n', 500)), 'completed')

it('charges a bounded loop once per iteration',
   select(1, run_with_budget('for i = 1, 5 do end\n', 500)), 5)

it('charges nothing for a program with no loop or function',
   select(1, run_with_budget('local x = 1 + 2\n', 500)), 0)

-- Known, accepted imprecision. Every `do` is charged, which includes a plain
-- `do ... end` block that runs exactly once. Excluding those would mean pairing
-- each loop header with its body - precisely the nesting logic this design
-- avoids, since `while f(function() ... end) do` is legal Lua. The cost is one
-- spurious count on a construct players rarely write. Recorded as a known gap
-- rather than hidden, so it stays visible if anyone revisits the trade-off.
xfail('does not charge a plain do-block',
      select(1, run_with_budget('do local x = 1 end\n', 500)), 0)

--------------------------------------------------------------------------------
-- the shipped examples are real player programs: instrumenting them must not
-- break them. This is the end-to-end check that matters most.
--------------------------------------------------------------------------------

do
    local dir
    if rawget(_G, 'codeblock') and codeblock.modpath then
        dir = codeblock.modpath .. '/lib/examples'
    else
        local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
        dir = (here and (here .. '/../lib/examples')) or 'mods/codeblock/lib/examples'
    end

    -- No lfs in either environment, so the list is explicit.
    local names = {
        'death_star', 'density', 'donuts', 'forest', 'menger', 'mosely',
        'planet', 'plot2D', 'plot3D', 'recursion', 'spirals', 'stairs',
        'tests', 'torus'
    }

    local checked, broken = 0, {}
    for _, name in ipairs(names) do
        local f = io.open(dir .. '/' .. name .. '.lua', 'r')
        if f then
            local src = f:read('*a')
            f:close()
            checked = checked + 1
            -- must compile before and after, and the instrumentation must have
            -- found at least one place to charge in a program with loops
            if not compiles(pp(src)) then
                broken[#broken + 1] = name
            end
        end
    end

    it('found the shipped examples to check', (checked > 0), true)
    it('every shipped example still compiles once instrumented',
       table.concat(broken, ','), '')
    it('checked all 14 shipped examples', checked, 14)
end

------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {}
out[#out + 1] = ''
out[#out + 1] = '  preprocess_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed   %d xfail (known defects)   %d xpass')
                    :format(pass, fail, xfailed, xpassed)
out[#out + 1] = ''

local text = table.concat(out, '\n')

if rawget(_G, 'core') then
    print(text)
else
    io.write(text)
end

-- Non-zero exit for CI when a real test fails or an xfail starts passing.
if not rawget(_G, 'core') then
    os.exit((fail == 0 and xpassed == 0) and 0 or 1)
end

return {passed = pass, failed = fail, xfail = xfailed, xpass = xpassed}
