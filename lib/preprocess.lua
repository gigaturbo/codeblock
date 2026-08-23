--- Source-text preprocessing for player programs.
--
-- A player's program is instrumented before it runs so that every loop
-- iteration and every function call pays into the budget in commands.lua. That
-- is what makes a runaway program stop instead of freezing the server, and what
-- lets the drone yield back to the engine between steps.
--
-- The instrumentation is done over a real token stream rather than by pattern
-- matching raw text. The previous pattern-based version had four defects that
-- all came from the same root cause - patterns cannot tell code from comments or
-- strings - and are covered by tests/preprocess_spec.lua:
--
--   * it stripped comments first, with a greedy `--[[.*--]]`, which deleted
--     every statement between a file's first and last block comment;
--   * it only understood the `--]]` spelling, so a normal `--[[ ... ]]` comment
--     had its opening line removed and its body left behind as bare code;
--   * stripping ran before string literals were identified, so a `--` inside a
--     string truncated it;
--   * it matched `function` as a bare substring, so an identifier merely
--     containing those letters caused a statement to be injected after the next
--     `)` anywhere in the file.
--
-- Tokenising removes all four: comments are never stripped, strings are a token
-- type, and `function` is a keyword rather than a run of characters.
--
-- This module is deliberately free of any Luanti or codeblock dependency so it
-- can be exercised by tests/preprocess_spec.lua under a bare Lua interpreter.
-- It is pure string -> string; nothing here touches the world or the player.

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

-- Names a player program may not mention. This is now checked against real
-- identifier tokens, so `"wait until done"` in a string or a variable called
-- `repeat_count` are no longer rejected - the old substring check refused both.
--
-- `repeat` and `until` used to be here because the pattern-based instrumenter
-- could not handle them. The tokeniser can, so repeat/until now works.
local forbidden_names = {
    -- reaching _G would let a program overwrite the injected budget counter
    ['_G'] = true
}

--- Returns the first forbidden name a program mentions, or nil if clean.
-- The caller turns this into a translated message.
function preprocess.find_forbidden(code)
    for _, t in ipairs(preprocess.tokenize(code)) do
        if t.type == 'name' and forbidden_names[t.value] then
            return t.value
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
--   do        every loop body opens with `do`, so instrumenting each `do`
--             covers `while ... do` and `for ... do` without having to pair a
--             loop header with its body. A plain `do ... end` block is also
--             matched, which costs one harmless count for a block that runs
--             once, and is far cheaper than tracking nesting to exclude it.
--   repeat    the one loop form whose body is not introduced by `do`.
--   function  after the `)` closing the parameter list, so the count lands
--             inside the body. This is what makes recursion pay in.
--   goto      counted at the jump itself, since a backwards goto is a loop.
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
