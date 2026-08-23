--- Source-text preprocessing for player programs.
--
-- This module is deliberately free of any Luanti or codeblock dependency so it
-- can be exercised by tests/preprocess_spec.lua under a bare Lua interpreter.
-- It is pure string -> string; nothing in here touches the world or the player.
--
-- Extracted verbatim from lib/sandbox.lua. Behaviour is unchanged, including
-- the known defects documented in tests/preprocess_spec.lua.
--
-- Originally adapted from
-- https://github.com/ac-minetest/basic_robot/blob/master/init.lua

local preprocess = {}

--------------------------------------------------------------------------------
-- forbidden constructs
--------------------------------------------------------------------------------

-- Substrings refused outright. Note these are plain substring searches, so they
-- also match inside identifiers and string literals (see spec).
local forbidden = {"repeat", "until", "_c_", "_G", "while%(", "while{"}

--- Returns the first forbidden pattern present in `code`, or nil if clean.
-- The caller is responsible for turning this into a translated message.
function preprocess.find_forbidden(code)
    for _, v in pairs(forbidden) do
        if string.find(code, v) then return v end
    end
    return nil
end

--------------------------------------------------------------------------------
-- string literal detection
--------------------------------------------------------------------------------

--- Returns a list of {start, end} positions of literal strings in Lua code.
function preprocess.identify_strings(code)

    local i = 0;
    local j;
    local _;
    local length = string.len(code);
    local mode = 0; -- 0: not in string, 1: in '...', 2: in "...", 3: in [==[ ... ]==]
    local modes = {
        {"'", "'"}, -- inside ' '
        {"\"", "\""}, -- inside " "
        {"%[=*%[", "%]=*%]"} -- inside [=[ ]=]
    }
    local ret = {}
    while i < length do
        i = i + 1

        local jmin = length + 1;
        if mode == 0 then -- not yet inside string
            for k = 1, #modes do
                j = string.find(code, modes[k][1], i);
                if j and j < jmin then -- pick closest one
                    jmin = j
                    mode = k
                end
            end
            if mode ~= 0 then -- found something
                j = jmin
                ret[#ret + 1] = {jmin}
            end
            if not j then break end -- found nothing
        else
            _, j = string.find(code, modes[mode][2], i); -- search for closing pair
            if not j then break end
            if (mode ~= 2 or (string.sub(code, j - 1, j - 1) ~= "\\") or
                string.sub(code, j - 2, j - 1) == "\\\\") then -- not (" and not \" - but "\\" is allowed)
                ret[#ret][2] = j
                mode = 0
            end
        end
        i = j -- move to next position
    end
    if mode ~= 0 then ret[#ret][2] = length end
    return ret
end

--- Is `pos` inside one of the string ranges returned by identify_strings?
function preprocess.is_inside_string(strings, pos)
    local low = 1;
    local high = #strings;
    if high == 0 then return false end
    local mid = high;
    while high > low + 1 do
        mid = math.floor((low + high) / 2)
        if pos < strings[mid][1] then
            high = mid
        else
            low = mid
        end
    end
    if pos > strings[low][2] then
        mid = high
    else
        mid = low
    end
    return strings[mid][1] <= pos and pos <= strings[mid][2]
end

--- Find `pattern` in `script` at or after `pos`, skipping string literals.
function preprocess.find_outside_string(script, pattern, pos, strings)
    local found = true;
    local i1 = pos;
    while found do
        found = false
        local i2 = string.find(script, pattern, i1);
        if i2 then
            if not preprocess.is_inside_string(strings, i2) then return i2 end
            found = true;
            i1 = i2 + 1;
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- call-counter instrumentation
--------------------------------------------------------------------------------

--- Strip comments and inject `_G.use_call()` into every loop and function so
-- the call budget in commands.lua can be enforced.
function preprocess.preprocess_code(script)

    local identify_strings = preprocess.identify_strings
    local find_outside_string = preprocess.find_outside_string

    -- strip comments
    script = script:gsub("%-%-%[%[.*%-%-%]%]", ""):gsub("%-%-[^\n]*\n", "\n")

    -- process script to insert call counter in every function
    local _use_call_code = " _G.use_call(); "

    local i1 = 0;
    local i2 = 0;
    local found = true;

    local strings = identify_strings(script);

    local inserts = {};

    local constructs = {
        {"while%s", "%sdo%s", 2, 6}, -- numbers: insertion pos = i2+2, after skip to i1 = i12+6
        {"function", ")", 0, 8}, {"for%s", "%sdo%s", 2, 4},
        {"goto%s", nil, -1, 5}
    }

    for i = 1, #constructs do
        i1 = 0;
        found = true
        while (found) do -- PROCESS SCRIPT AND INSERT COUNTER AT PROBLEMATIC SPOTS

            found = false;

            i2 = find_outside_string(script, constructs[i][1], i1, strings) -- first part of construct
            if i2 then
                local i21 = i2;
                if constructs[i][2] then
                    i2 = find_outside_string(script, constructs[i][2], i2,
                                             strings); -- second part of construct ( if any )
                    if i2 then
                        inserts[#inserts + 1] = i2 + constructs[i][3]; -- move to last position of construct[i][2]
                        found = true;
                    end
                else
                    inserts[#inserts + 1] = i2 + constructs[i][3]
                    found = true -- 1 part construct
                end

                if found then
                    i1 = i21 + constructs[i][4]; -- skip to after constructs[i][1]
                end
            end

        end
    end

    table.sort(inserts)

    -- add inserts
    local ret = {};
    i1 = 1;
    for i = 1, #inserts do
        i2 = inserts[i];
        ret[#ret + 1] = string.sub(script, i1, i2);
        i1 = i2 + 1;
    end
    ret[#ret + 1] = string.sub(script, i1);
    script = table.concat(ret, _use_call_code)

    return script;

end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

-- Expose under the mod namespace when running inside Luanti, and always return
-- the module so a bare interpreter can `dofile` it.
if rawget(_G, 'codeblock') then codeblock.preprocess = preprocess end

return preprocess
