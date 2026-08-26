--- Tests for lib/api.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua mods/codeblock/tests/api_spec.lua
--
-- Or in-engine via codeblock_run_tests = true.
--
-- The list at the bottom is the important part. Moving the API description into
-- a data file means a name could silently disappear from the environment, and no
-- other spec would notice: the examples only have to *compile*, and
-- integration_spec exercises a handful of calls. So every name the environment
-- used to expose is pinned here explicitly.

local api
do
    if rawget(_G, 'codeblock') and codeblock.api then
        api = codeblock.api
    else
        local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
        local candidates = {
            here and (here .. '/../lib/api.lua') or nil,
            'mods/codeblock/lib/api.lua', '../lib/api.lua', 'lib/api.lua'
        }
        for _, p in ipairs(candidates) do
            local f = io.open(p, 'r')
            if f then
                f:close()
                api = dofile(p)
                break
            end
        end
    end
end

assert(api, 'could not locate lib/api.lua')

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

--- Resolve a dotted name against a built table.
local function resolve(root, dotted)
    local node = root
    for part in dotted:gmatch('[^%.]+') do
        if type(node) ~= 'table' then return nil end
        node = node[part]
        if node == nil then return nil end
    end
    return node
end

--------------------------------------------------------------------------------
-- the description itself
--------------------------------------------------------------------------------

it('has groups', (#api.groups > 0), true)
it('every group has a title', (function()
    for _, g in ipairs(api.groups) do
        if type(g.title) ~= 'string' or g.title == '' then return false end
    end
    return true
end)(), true)

it('every entry has a name and a doc line', (function()
    for _, e in ipairs(api.entries()) do
        if type(e.name) ~= 'string' or e.name == '' then return false end
        if type(e.doc) ~= 'string' or e.doc == '' then return false end
    end
    return true
end)(), true)

it('every callable entry declares its parameters', (function()
    for _, e in ipairs(api.entries()) do
        if e.kind ~= 'value' and type(e.params) ~= 'table' then return false end
    end
    return true
end)(), true)

it('no name is declared twice', (function()
    local seen = {}
    for _, n in ipairs(api.names()) do
        if seen[n] then return false end
        seen[n] = true
    end
    return true
end)(), true)

it('signatures read as a player writes them',
   api.signature({name = 'cube', params = {'width', 'height'}}),
   'cube(width, height)')
it('a value has no parentheses',
   api.signature({name = 'pi', kind = 'value'}), 'pi')

--------------------------------------------------------------------------------
-- build: the mismatch check is the whole point, so test both directions
--------------------------------------------------------------------------------

do
    local impls = {}
    for _, n in ipairs(api.names()) do impls[n] = function() end end

    it('builds when description and implementation agree',
       (pcall(api.build, impls)), true)

    -- something described but not implemented
    local short = {}
    for k, v in pairs(impls) do short[k] = v end
    short['cube'] = nil
    local blocked, err = raises(api.build, short)
    it('refuses a missing implementation', blocked, true)
    it('and names it', (err:find('cube', 1, true) ~= nil), true)
    it('and says which direction the gap runs',
       (err:find('not implemented', 1, true) ~= nil), true)

    -- something implemented but not described
    local extra = {}
    for k, v in pairs(impls) do extra[k] = v end
    extra['secret_backdoor'] = function() end
    local blocked2, err2 = raises(api.build, extra)
    it('refuses an undescribed implementation', blocked2, true)
    it('and names that too', (err2:find('secret_backdoor', 1, true) ~= nil), true)
end

--------------------------------------------------------------------------------
-- build: shape
--------------------------------------------------------------------------------

do
    local impls = {}
    for _, n in ipairs(api.names()) do
        impls[n] = function() return n end
    end
    local built = api.build(impls)

    it('a flat name resolves', type(resolve(built, 'forward')), 'function')
    it('a nested name resolves', type(resolve(built, 'centered.cube')),
       'function')
    it('a doubly nested name resolves',
       type(resolve(built, 'centered.vertical.cylinder')), 'function')
    it('the nested call reaches the right implementation',
       resolve(built, 'centered.horizontal.cylinder')(),
       'centered.horizontal.cylinder')

    -- `random` is callable AND a namespace; that combination is easy to break
    it('random is a table', type(built.random), 'table')
    it('random.block resolves', type(built.random.block), 'function')
    it('random is also callable', built.random(), 'random')
end

--------------------------------------------------------------------------------
-- rendering
--------------------------------------------------------------------------------

do
    local h = api.to_hypertext()
    it('hypertext is produced', (#h > 0), true)
    it('hypertext contains a group title',
       (h:find('Moving the drone', 1, true) ~= nil), true)
    it('hypertext contains a signature',
       (h:find('place_relative', 1, true) ~= nil), true)
    it('hypertext has one line per entry plus one per group', (function()
        local lines = 0
        for _ in h:gmatch('[^\n]+') do lines = lines + 1 end
        return lines
    end)(), #api.entries() + #api.groups)

    local m = api.to_markdown({blocks = {'stone', 'glass'}})
    it('markdown is produced', (#m > 0), true)
    it('markdown says where to edit instead',
       (m:find('lib/api.lua', 1, true) ~= nil), true)
    it('markdown lists every entry', (function()
        for _, e in ipairs(api.entries()) do
            if not m:find(api.signature(e), 1, true) then return false end
        end
        return true
    end)(), true)
    it('markdown includes the block tables it was given',
       (m:find('stone, glass', 1, true) ~= nil), true)
end

--------------------------------------------------------------------------------
-- every name the environment used to expose is still described
--
-- Captured from the api table as it stood before it became generated. If a name
-- disappears from lib/api.lua this fails, which is the regression this whole
-- refactor could otherwise introduce silently.
--------------------------------------------------------------------------------

do
    local expected = {
        'move', 'forward', 'back', 'left', 'right', 'up', 'down', 'turn_left',
        'turn_right', 'turn', 'place', 'place_relative', 'save', 'go', 'cube',
        'sphere', 'dome', 'cylinder', 'vertical.cylinder',
        'horizontal.cylinder', 'centered.cube', 'centered.sphere',
        'centered.dome', 'centered.cylinder', 'centered.vertical.cylinder',
        'centered.horizontal.cylinder', 'wools', 'iwools', 'blocks', 'plants',
        'vector', 'get_block', 'print', 'color', 'ipairs', 'pairs', 'random',
        'random.block', 'random.plant', 'random.wool', 'table.randomizer',
        'floor', 'ceil', 'round', 'round0', 'deg', 'rad', 'exp', 'log', 'max',
        'min', 'pow', 'sqrt', 'abs', 'sin', 'sinh', 'asin', 'cos', 'cosh',
        'acos', 'tan', 'tanh', 'atan', 'atan2', 'pi', 'e', 'error'
    }

    local described = {}
    for _, n in ipairs(api.names()) do described[n] = true end

    local lost = {}
    for _, n in ipairs(expected) do
        if not described[n] then lost[#lost + 1] = n end
    end

    it('no previously exposed name has been dropped',
       table.concat(lost, ', '), '')
    it('the expected list itself is complete', #expected, 67)
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  api_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''

local text = table.concat(out, '\n')
if rawget(_G, 'core') then
    print(text)
else
    io.write(text)
    os.exit(fail == 0 and 0 or 1)
end

return {passed = pass, failed = fail}
