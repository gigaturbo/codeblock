--- End-to-end test of the program pipeline, in-engine only.
--
-- The other specs test lib/preprocess.lua and lib/env.lua in isolation, which
-- says nothing about whether they are wired together correctly. This one runs a
-- player program through the real path - forbidden-name check, real
-- instrumentation, real environment construction, real budget counter from
-- lib/commands.lua - inside a real coroutine, and checks it behaves.
--
-- It needs codeblock.commands, so it is skipped under a bare interpreter rather
-- than duplicating the mod's setup.

if not (rawget(_G, 'codeblock') and codeblock.commands) then
    io.write('\n  integration_spec\n  skipped (needs the mod loaded)\n\n')
    return {skipped = true}
end

local preprocess = codeblock.preprocess
local envlib = codeblock.env
local use_call = codeblock.commands.drone_use_call

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

--------------------------------------------------------------------------------
-- a stub drone, carrying only what the budget counter touches
--------------------------------------------------------------------------------

local function stub_drone(auth_level)
    return {
        name = 'test_player',
        file = 'spec.lua',
        auth_level = auth_level or 4,
        calls = 0,
        commands = 0,
        volume = 0,
        checkpoints = {}
    }
end

--- Run `src` through the real pipeline. Returns ok, drone, yields, err.
local function run(src, auth_level)

    local drone = stub_drone(auth_level)

    local bad = preprocess.find_forbidden(src)
    if bad then return false, drone, 0, 'forbidden: ' .. bad end

    local chunk, msg = loadstring(preprocess.preprocess_code(src))
    if not chunk then return false, drone, 0, 'compile: ' .. tostring(msg) end

    -- Built the same way lib/sandbox.lua builds it.
    local api = {
        print = function() end,
        error = error,
        ipairs = ipairs,
        pairs = pairs,
        floor = math.floor,
        -- stand-ins for the drone commands, so the read-only checks below have
        -- a real API name to attack
        place = function() end,
        up = function() end,
        blocks = envlib.snapshot({stone = 'stone', air = 'air'})
    }
    api._G = envlib.seal({
        print = api.print,
        error = api.error,
        use_call = function() use_call(drone) end
    }, '_G')

    setfenv(chunk, envlib.new_env(api))

    local co = coroutine.create(chunk)
    local yields = 0
    while true do
        local ok, err = coroutine.resume(co)
        if not ok then return false, drone, yields, tostring(err) end
        if coroutine.status(co) == 'dead' then break end
        yields = yields + 1
        if yields > 10000 then return false, drone, yields, 'runaway' end
    end
    return true, drone, yields, nil
end

--------------------------------------------------------------------------------
-- the pipeline works end to end
--------------------------------------------------------------------------------

do
    local ok, drone = run('local x = 0\nfor i = 1, 5 do x = x + 1 end\n')
    it('a bounded loop completes', ok, true)
    it('the real counter charged once per iteration', drone.calls, 5)
end

do
    local ok, drone = run('local x = 1 + 2\n')
    it('a loop-free program completes', ok, true)
    it('a loop-free program is charged nothing', drone.calls, 0)
end

do
    -- The counter yields periodically so the drone gives time back to the
    -- engine. At codelevel 4 that is every 600 calls, so 1500 iterations must
    -- have yielded at least twice.
    local ok, _, yields = run('for i = 1, 1500 do end\n', 4)
    it('a long loop completes', ok, true)
    it('a long loop yields back to the engine', (yields >= 2), true)
end

do
    -- repeat/until was refused outright before Phase 2.
    local ok, drone = run('local i = 0\nrepeat i = i + 1 until i >= 4\n')
    it('repeat/until runs', ok, true)
    it('repeat/until is charged per iteration', (drone.calls >= 4), true)
end

do
    local ok, drone = run(
                          'function add(a, b) return a + b end\nlocal s = add(1, 2)\n')
    it('a function definition and call runs', ok, true)
    it('the function body is charged', (drone.calls >= 1), true)
end

--------------------------------------------------------------------------------
-- comments and strings survive the real pipeline (B1-B3)
--------------------------------------------------------------------------------

do
    local ok = run('--[[ a --]]\nlocal x = 1\n--[[ b --]]\nlocal y = 2\n')
    it('B1 two block comments no longer delete the code between them', ok, true)
end

do
    local ok = run('--[[\nprose\n]]\nlocal x = 1\n')
    it('B2 a standard block comment runs', ok, true)
end

do
    local ok = run('local s = "a -- b"\n')
    it('B3 a string containing a double dash runs', ok, true)
end

do
    local ok = run('local nfunctions = 3\nlocal x = math_missing\n')
    it('B4 an identifier containing "function" runs', ok, true)
end

--------------------------------------------------------------------------------
-- the environment holds under attack
--------------------------------------------------------------------------------

do
    local ok, _, _, err = run('place = function() end\n')
    it('reassigning an API name is refused', ok, false)
    it('and says why', (err and err:find('cannot be reassigned', 1, true) ~= nil),
       true)
end

do
    local ok, _, _, err = run('_G.use_call = function() end\n')
    -- _G is still on the forbidden list; either rejection is a pass, but the
    -- seal is what makes it safe to relax that later.
    it('disabling the budget counter is refused', ok, false)
    it('the refusal is reported', (err ~= nil), true)
end

do
    -- S1: a program must not be able to corrupt shared config for everyone.
    local ok = run('blocks.stone = "tampered"\n')
    it('mutating the block table is allowed within the run', ok, true)
    it('but the real config is untouched',
       codeblock.config.allowed_blocks.cubes.stone, 'stone')
end

do
    local ok = run('my_helper = function() return 1 end\nlocal v = my_helper()\n')
    it('a player global still works', ok, true)
end

--------------------------------------------------------------------------------
-- the vendored WorldEdit fork still provides what this mod depends on
--
-- That fork has had modules removed from it (code.lua, which loadstring'd
-- arbitrary Lua). These four are the entire surface codeblock uses, so if a
-- future trim goes too far this catches it at load time rather than the first
-- time a player asks for a sphere.
--------------------------------------------------------------------------------

do
    it('worldedit.cube is available', type(worldedit and worldedit.cube),
       'function')
    it('worldedit.sphere is available', type(worldedit and worldedit.sphere),
       'function')
    it('worldedit.dome is available', type(worldedit and worldedit.dome),
       'function')
    it('worldedit.cylinder is available', type(worldedit and worldedit.cylinder),
       'function')
    it('the removed arbitrary-execution entry point is gone',
       (worldedit and worldedit.lua), nil)
    it('and so is its per-node variant', (worldedit and worldedit.luatransform),
       nil)
end

--------------------------------------------------------------------------------
-- chat command argument parsing (B8, B9)
--
-- Both commands mishandled their optional player name: /codegenerate parsed one
-- and then ignored it, always acting on the caller, and /codelevel carried a
-- dead singleplayer branch. Parsing is where they went wrong, so it is tested.
--------------------------------------------------------------------------------

do
    local parse = codeblock.utils.parse_target

    local function both(caller, params, pat)
        local a, b = parse(caller, params, pat)
        return tostring(a) .. '|' .. tostring(b)
    end

    it('level only, addressed to the caller', both('bob', '3', '%d+'), 'bob|3')
    it('name and level', both('bob', 'alice 2', '%d+'), 'alice|2')
    it('tolerates surrounding space', both('bob', '  alice   2  ', '%d+'),
       'alice|2')
    it('rejects empty arguments', both('bob', '', '%d+'), 'nil|nil')
    it('rejects a name with no level', both('bob', 'alice', '%d+'), 'nil|nil')
    it('rejects a non-numeric level', both('bob', 'alice x', '%d+'), 'nil|nil')
    it('rejects trailing junk', both('bob', 'alice 2 3', '%d+'), 'nil|nil')
    it('accepts names with underscore and dash',
       both('bob', 'a_player-1 4', '%d+'), 'a_player-1|4')
    -- A digit-led token is a level, not a name: this is the case the old
    -- `([%w_-]*)%s*([%d]*)` pattern got wrong, since %w matches digits.
    it('does not read a bare number as a player name', both('bob', '4', '%d+'),
       'bob|4')
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  integration_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''
print(table.concat(out, '\n'))

return {passed = pass, failed = fail}
