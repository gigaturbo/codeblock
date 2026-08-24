--- Source-text preprocessing for player programs.
--
-- Instruments a program so that every loop iteration and every function call
-- pays into the budget in commands.lua. That is what stops a runaway program
-- instead of freezing the server.
--
-- Done over a token stream rather than by pattern matching: patterns cannot
-- tell code from comments or strings, which cost the previous version four
-- separate bugs. tests/preprocess_spec.lua covers them.
--
-- Pure string -> string, with no Luanti or codeblock dependency, so the spec
-- runs under a bare interpreter.

local preprocess = {}

local sub = string.sub
local find = string.find
local match = string.match

--------------------------------------------------------------------------------
-- lexer
--------------------------------------------------------------------------------

local keywords = {
    ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true,
    ['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true,
    ['function'] = true, ['if'] = true, ['in'] = true, ['local'] = true,
    ['nil'] = true, ['not'] = true, ['or'] = true, ['repeat'] = true,
    ['return'] = true, ['then'] = true, ['true'] = true, ['until'] = true,
    ['while'] = true,
    -- LuaJIT / 5.2+; harmless to treat as a keyword under 5.1, where it can
    -- only ever appear as an ordinary name that we simply never act on.
    ['goto'] = true
}

--- If a long bracket opens at `i`, return the position just after it and its
-- level. Handles `[[`, `[=[`, `[==[` and so on.
local function long_bracket_open(src, i)
    if sub(src, i, i) ~= '[' then return nil end
    local j = i + 1
    local level = 0
    while sub(src, j, j) == '=' do
        level = level + 1
        j = j + 1
    end
    if sub(src, j, j) == '[' then return j + 1, level end
    return nil
end

--- Find the end of a long bracket of `level` starting at `from`.
-- Returns the position of the last character of the closing bracket, or the end
-- of the string when unterminated (matching how Lua reports it as one token).
local function long_bracket_close(src, from, level)
    local close = ']' .. string.rep('=', level) .. ']'
    local s, e = find(src, close, from, true)
    if s then return e end
    return #src
end

--- Tokenise Lua source.
-- Returns a list of {type, i, j, value} where i..j are inclusive byte offsets
-- into `src`. Types: 'name', 'keyword', 'string', 'number', 'comment', 'op'.
-- The lexer is permissive: it never raises on malformed input, because invalid
-- programs are meant to fail later in loadstring() with Lua's own message.
function preprocess.tokenize(src)

    local tokens = {}
    local i = 1
    local n = #src

    local function push(kind, from, to, value)
        tokens[#tokens + 1] = {type = kind, i = from, j = to, value = value}
    end

    while i <= n do
        local c = sub(src, i, i)

        if match(c, '%s') then
            i = i + 1

        elseif c == '-' and sub(src, i + 1, i + 1) == '-' then
            -- comment: long form first, then to end of line
            local after, level = long_bracket_open(src, i + 2)
            if after then
                local stop = long_bracket_close(src, after, level)
                push('comment', i, stop)
                i = stop + 1
            else
                local stop = find(src, '\n', i, true)
                stop = stop and (stop - 1) or n
                push('comment', i, stop)
                i = stop + 1
            end

        elseif c == '[' and long_bracket_open(src, i) then
            local after, level = long_bracket_open(src, i)
            local stop = long_bracket_close(src, after, level)
            push('string', i, stop)
            i = stop + 1

        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = sub(src, j, j)
                if d == '\\' then
                    j = j + 2
                elseif d == c then
                    j = j + 1
                    break
                elseif d == '\n' then
                    -- unterminated; let loadstring report it
                    break
                else
                    j = j + 1
                end
            end
            push('string', i, j - 1)
            i = j

        elseif match(c, '%d') or
            (c == '.' and match(sub(src, i + 1, i + 1), '%d')) then
            local j = i
            local hex = false
            if c == '0' and match(sub(src, i + 1, i + 1), '[xX]') then
                hex = true
                j = i + 2
            end
            while j <= n do
                local d = sub(src, j, j)
                if match(d, '%x') or d == '.' then
                    j = j + 1
                elseif (not hex and match(d, '[eE]')) or
                    (hex and match(d, '[pP]')) then
                    j = j + 1
                    if match(sub(src, j, j), '[%+%-]') then j = j + 1 end
                elseif not hex and match(d, '[a-zA-Z_]') then
                    -- malformed literal like 1abc; consume so we do not emit a
                    -- spurious name token that could look like a keyword
                    j = j + 1
                else
                    break
                end
            end
            push('number', i, j - 1)
            i = j

        elseif match(c, '[%a_]') then
            local s, e, word = find(src, '^([%a_][%w_]*)', i)
            push(keywords[word] and 'keyword' or 'name', s, e, word)
            i = e + 1

        else
            -- operators; longest match first so '...' beats '..' beats '.'
            local three = sub(src, i, i + 2)
            local two = sub(src, i, i + 1)
            if three == '...' then
                push('op', i, i + 2, three)
                i = i + 3
            elseif two == '==' or two == '~=' or two == '<=' or two == '>=' or
                two == '..' or two == '::' then
                push('op', i, i + 1, two)
                i = i + 2
            else
                push('op', i, i, c)
                i = i + 1
            end
        end
    end

    return tokens
end

--------------------------------------------------------------------------------
-- forbidden constructs
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- forbidden constructs
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- forbidden constructs
--------------------------------------------------------------------------------

-- Not a security boundary - that is the environment table in lib/sandbox.lua,
-- which simply does not contain these names. This list exists to turn an
-- obscure runtime failure into a useful message: without it a program calling
-- os.time() dies with an attempt-to-index-nil error on some later line, which
-- tells a beginner nothing. Matched as identifier tokens, so `local until_done`
-- and the word `_G` inside a comment are not hits.
local unavailable = {
    -- loading code at runtime would sidestep instrumentation entirely
    ['load'] = true, ['loadstring'] = true, ['loadfile'] = true,
    ['dofile'] = true, ['require'] = true,
    -- would let a program reach outside the sandbox
    ['os'] = true, ['io'] = true, ['debug'] = true, ['package'] = true,
    ['getfenv'] = true, ['setfenv'] = true, ['rawget'] = true,
    ['rawset'] = true, ['rawequal'] = true, ['setmetatable'] = true,
    ['getmetatable'] = true, ['newproxy'] = true,
    -- pcall would swallow the errors that enforce the budget, and in Lua 5.1
    -- you cannot yield across it, so the drone's pacing would break too
    ['pcall'] = true, ['xpcall'] = true, ['coroutine'] = true,
    -- the engine itself
    ['minetest'] = true, ['core'] = true, ['worldedit'] = true
}

--- Returns the first unavailable name a program mentions, or nil if clean.
-- The caller turns this into a translated message.
--
-- Only names used as globals count. A name after `.` or `:` is a field, so a
-- player's own `t.os` or `shape:load()` is their business and must not be
-- refused - the old substring check had no way to tell the difference.
function preprocess.find_forbidden(code)
    local tokens = preprocess.tokenize(code)
    for k = 1, #tokens do
        local t = tokens[k]
        if t.type == 'name' and unavailable[t.value] then
            local prev = tokens[k - 1]
            local is_field = prev and prev.type == 'op' and
                                 (prev.value == '.' or prev.value == ':')
            if not is_field then return t.value end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- call-counter instrumentation
--------------------------------------------------------------------------------

local INJECT = ' _G.use_call(); '

--- Byte offsets in `src` after which the counter call must be inserted.
--
-- Every construct that can repeat, plus every function body, has to pay in:
--
--   do        opens every while and for body, so instrumenting each `do`
--             covers both without pairing a loop header with its body. A plain
--             `do ... end` block is matched too, which costs one harmless
--             count and is cheaper than tracking nesting to exclude it.
--   repeat    the one loop form whose body is not introduced by `do`.
--   function  after the `)` closing the parameter list, so the count lands
--             inside the body. This is what makes recursion pay in.
--   goto      counted at the jump, since a backwards goto is a loop.
--
-- Returns a sorted list of positions.
function preprocess.insertion_points(src)

    local tokens = preprocess.tokenize(src)
    local points = {}

    for k = 1, #tokens do
        local t = tokens[k]

        if t.type == 'keyword' and (t.value == 'do' or t.value == 'repeat') then
            points[#points + 1] = t.j

        elseif t.type == 'keyword' and t.value == 'function' then
            -- Walk to the '(' that opens the parameter list, then to its match.
            -- Parameter lists cannot themselves contain parentheses, but depth
            -- is tracked anyway so a malformed program cannot mislead us.
            local depth = 0
            local m = k + 1
            while m <= #tokens do
                local u = tokens[m]
                if u.type == 'op' and u.value == '(' then
                    depth = depth + 1
                elseif u.type == 'op' and u.value == ')' then
                    depth = depth - 1
                    if depth <= 0 then
                        points[#points + 1] = u.j
                        break
                    end
                elseif depth == 0 and u.type == 'keyword' then
                    -- ran past the header without finding a parameter list;
                    -- malformed, leave it to loadstring
                    break
                end
                m = m + 1
            end

        elseif t.type == 'keyword' and t.value == 'goto' then
            local nxt = tokens[k + 1]
            if nxt and nxt.type == 'name' then
                points[#points + 1] = t.i - 1
            end
        end
    end

    table.sort(points)
    return points
end

--- Insert the budget counter into every loop and function body.
-- Comments and strings are left exactly as written: nothing is stripped.
function preprocess.preprocess_code(src)

    local points = preprocess.insertion_points(src)
    if #points == 0 then return src end

    local out = {}
    local from = 1
    for k = 1, #points do
        local p = points[k]
        out[#out + 1] = sub(src, from, p)
        out[#out + 1] = INJECT
        from = p + 1
    end
    out[#out + 1] = sub(src, from)

    return table.concat(out)
end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

-- Expose under the mod namespace when running inside Luanti, and always return
-- the module so a bare interpreter can `dofile` it.
if rawget(_G, 'codeblock') then codeblock.preprocess = preprocess end

return preprocess
