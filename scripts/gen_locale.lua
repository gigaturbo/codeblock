--- Keep locale/template.txt equal to the strings the code actually asks for.
--
--   lua5.1 scripts/gen_locale.lua           rewrite the template
--   lua5.1 scripts/gen_locale.lua --check   fail if it has drifted
--
-- The template is a translator's inventory of every message the mod can send, so
-- it is a mirror of the source the way settingtypes.txt is a mirror of
-- lib/config.lua - and it drifted the same way, silently, because nothing
-- compared the two. By the time anyone looked, twelve messages the code sends
-- were missing from it and eleven it listed no longer existed (C17).
--
-- Three of those twelve were worse than missing: they had been translated, and a
-- one-character edit to the key - a trailing space, a plural, a capital - left
-- the translation behind while the code went on asking for a key nobody had. A
-- diff of key lists is the only thing that sees that, which is why this exists
-- rather than a note about remembering.
--
-- Runs under a bare Lua 5.1 with no engine, like scripts/gen_docs.lua, and
-- lists lib/ through `ls`, so it wants a POSIX shell - which is where both are
-- run from here and in CI.
--
-- The .tr files are reported on but never fail the check. An untranslated
-- message falls back to English, which is a legitimate state for a translation
-- to be in; a template that lies about what needs translating is not.

local root = arg[0]:match('^(.*)[/\\]scripts[/\\]') or '.'
local check = arg[1] == '--check'

local HEADER = '# textdomain: codeblock'
local TEMPLATE = root .. '/locale/template.txt'

local function read(path)
    local f = io.open(path, 'rb')
    if not f then return nil end
    local s = f:read('*a')
    f:close()
    return s
end

--- Every file that can hold a translatable string.
--
-- Listed rather than enumerated by hand, because a hand-kept list of inputs is
-- the same defect one level up: a new lib/ file would be scanned by nobody and
-- its messages would go missing exactly as C17's did. The examples under
-- lib/examples/ are player programs and call no S(); the specs are not shipped.
local function sources()

    local list = {root .. '/init.lua'}

    local ls = io.popen('ls -1 "' .. root .. '/lib" 2>/dev/null')
    for name in ls:lines() do
        if name:match('%.lua$') then list[#list + 1] = root .. '/lib/' .. name end
    end
    ls:close()

    assert(#list > 1, 'could not list lib/ - this needs a POSIX shell')
    return list

end

--- Collect the keys `S(...)` is called with, and anything that is not one.
--
-- Scanned by position rather than by pattern, for two reasons that both cost a
-- wrong answer when tried the short way: several keys contain a `)` of their
-- own - "Memory limit exceeded (@1 MB)" - so the argument cannot be matched as
-- "everything up to the bracket"; and a call is free to break the line after
-- `S(`, which three do, so newlines are flattened first.
--
-- A concatenated key is recorded as a fault, not a key. The argument to S *is*
-- the translation key, so `S('a ' .. 'b')` asks at run time for a string no
-- reader of the source can see, and that is how one message here was never
-- offered for translation at all.
--
-- Comments are not stripped: an S() inside one would be collected, and the check
-- then reports it as a template key with no caller, which is visible rather than
-- silent. Not worth the parsing it would take to do better.
local function extract(text, path, keys, faults)

    local flat = text:gsub('[\r\n]', ' ')
    local pos = 1

    while true do

        local s, e = flat:find('S%(%s*', pos)
        if not s then return end
        pos = e + 1

        -- getS(, self.S(, tostring(S( - only a bare S is ours.
        if not flat:sub(s - 1, s - 1):match('[%w_.:]') then

            local quote = flat:sub(e + 1, e + 1)
            local close = (quote == "'" or quote == '"') and
                              flat:find(quote, e + 2, true)

            if not close then
                faults[#faults + 1] = path .. ': S(' ..
                                          flat:sub(e + 1, e + 40) ..
                                          ' - the key is not a literal'
            else
                keys[flat:sub(e + 2, close - 1)] = true
                pos = close + 1
                if flat:match('^%s*%.%.', close + 1) then
                    faults[#faults + 1] = path .. ': S(' ..
                                              flat:sub(e + 1, close) ..
                                              ' .. - the key is concatenated, ' ..
                                              'so nothing reading the source ' ..
                                              'can see it'
                end
            end

        end

    end

end

--- Case-insensitive, with the raw string as the tiebreak so the order is total.
-- The ordering is definitional: the file is generated, so it is right by
-- construction rather than by matching some other tool's collation.
local function sorted(keys)
    local list = {}
    for k in pairs(keys) do list[#list + 1] = k end
    table.sort(list, function(a, b)
        local la, lb = a:lower(), b:lower()
        if la ~= lb then return la < lb end
        return a < b
    end)
    return list
end

--- key -> value from a .tr or template file.
local function parse_tr(text)
    local map = {}
    for line in text:gmatch('[^\r\n]+') do
        local at = line:find('=', 1, true)
        if at and line:sub(1, 1) ~= '#' then
            map[line:sub(1, at - 1)] = line:sub(at + 1)
        end
    end
    return map
end

--------------------------------------------------------------------------------

local keys, faults = {}, {}
local strip = '^' .. root:gsub('%p', '%%%0') .. '/'

for _, path in ipairs(sources()) do
    local text = read(path)
    if text then extract(text, (path:gsub(strip, '')), keys, faults) end
end

local list = sorted(keys)

for _, key in ipairs(list) do
    if key:find('=', 1, true) or key:find('\n', 1, true) then
        faults[#faults + 1] =
            'a key holds "=" or a newline, which .tr uses as separators: ' .. key
    end
end

local lines = {HEADER}
for _, key in ipairs(list) do lines[#lines + 1] = key .. '=' end
local wanted = table.concat(lines, '\n') .. '\n'

--- What a translator would find missing, and what they would waste time on.
local function report_translations()

    local n = 0

    for _, lang in ipairs({'fr'}) do
        local text = read(root .. '/locale/codeblock.' .. lang .. '.tr')
        if text then
            local have = parse_tr(text)
            local stale = {}
            for _, key in ipairs(list) do
                if have[key] == nil then
                    n = n + 1
                    print(lang .. ': untranslated: ' .. key)
                end
            end
            for key in pairs(have) do
                if not keys[key] then stale[#stale + 1] = key end
            end
            table.sort(stale)
            n = n + #stale
            for _, key in ipairs(stale) do
                print(lang .. ': no longer in the code: ' .. key)
            end
        end
    end

    if n == 0 then print('locale/*.tr cover every message and nothing else') end

end

for _, fault in ipairs(faults) do print('FAULT ' .. fault) end

if not check then
    local out = assert(io.open(TEMPLATE, 'wb'))
    out:write(wanted)
    out:close()
    print('wrote locale/template.txt, ' .. #list .. ' messages')
    report_translations()
    os.exit(#faults == 0 and 0 or 1)
end

report_translations()

if #faults > 0 then
    print(#faults .. ' key(s) the source cannot be read for')
    os.exit(1)
end

if read(TEMPLATE) == wanted then
    print('locale/template.txt is up to date')
    os.exit(0)
end

local have = parse_tr(read(TEMPLATE) or '')
for _, key in ipairs(list) do
    if have[key] == nil then print('missing: ' .. key) end
end
for key in pairs(have) do
    if not keys[key] then print('stale:   ' .. key) end
end
print('locale/template.txt has drifted - run lua5.1 scripts/gen_locale.lua')
os.exit(1)
