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

it('does not instrument a loop keyword inside a string',
   pp('print("for i = 1, 3 do end")\n'):find('_G.use_call();', 1, true), nil)

it('strips a single-line comment',
   keeps('-- a comment\nup(1)\n', 'a comment'), false)

-- The blacklist, including its false positives (see audit S3).
it('rejects repeat', forbidden('repeat up(1) until false'), 'repeat')
it('rejects _G access', forbidden('_G.print("x")'), '_G')
it('accepts an ordinary program', forbidden('for i=1,3 do up(1) end'), nil)
it('false-positives on an identifier containing "until"',
   forbidden('local until_done = 1'), 'until')
it('false-positives on "repeat" inside a string',
   forbidden('print("repeat that")'), 'repeat')

--------------------------------------------------------------------------------
-- confirmed defects - these are the Phase 2 work list
--------------------------------------------------------------------------------

-- B1: greedy `.*` spans from the first `--[[` to the last `--]]`, deleting
-- every statement in between.
xfail('B1 keeps code sitting between two block comments',
      keeps('--[[ a --]]\nplace(blocks.stone)\nup(1)\n--[[ b --]]\nforward(1)\n',
            'place(blocks.stone)'), true)

-- B2: a standard Lua block comment closes with `]]`, not `--]]`, so only its
-- opening line is stripped and the body is left behind as bare code.
xfail('B2 removes a standard --[[ ... ]] comment body',
      pp('--[[\nthis is prose\n]]\nup(1)\n'):find('this is prose', 1, true), nil)

xfail('B2 output still compiles after a standard block comment',
      compiles(pp('--[[\nthis is prose\n]]\nup(1)\n')), true)

-- B3: comments are stripped before string literals are identified, so a `--`
-- inside a string truncates it.
xfail('B3 preserves a string containing a double dash',
      keeps('print("a -- b")\nup(1)\n', 'a -- b'), true)

xfail('B3 output still compiles with a double dash in a string',
      compiles(pp('print("a -- b")\nup(1)\n')), true)

-- B4: "function" is matched as a bare substring with no word boundary, so an
-- identifier merely containing those letters causes a statement to be injected
-- after the next `)` anywhere in the file.
xfail('B4 ignores "function" inside an identifier',
      compiles(pp('local nfunctions = 3\nlocal x = myfunc(1) + 2\n')), true)

xfail('B4 does not inject into an unrelated call expression',
      pp('local counter_function_total = 0\nlocal y = abs(-3) + 7\n')
          :find('_G.use_call();', 1, true), nil)

--------------------------------------------------------------------------------
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

if rawget(_G, 'core') or rawget(_G, 'minetest') then
    print(text)
else
    io.write(text)
end

-- Non-zero exit for CI when a real test fails or an xfail starts passing.
if not (rawget(_G, 'core') or rawget(_G, 'minetest')) then
    os.exit((fail == 0 and xpassed == 0) and 0 or 1)
end

return {passed = pass, failed = fail, xfail = xfailed, xpass = xpassed}
