--------------------------------------------------------------------------------
-- Letting the game add a block category of its own
--
-- From a mod that names codeblock in its own `depends`, at load time - that
-- dependency is what puts this function in place before the caller runs:
--
--     codeblock.register_blocks('wool', {
--         red = 'wool:red',
--         blue = 'wool:blue'
--     })
--
-- and `wool.red` is a block a player's program can place, listed in the editor
-- beside the mod's own colors, glass and lamps. The keys are the names a
-- program spells; the values are itemstrings the game has registered. Names are
-- listed alphabetically, because a Lua table with string keys has no order and
-- an arbitrary one would change between runs.
--
-- Validated, then trusted. codeblock checks only what it alone can know: the
-- names are usable as table keys, they collide with nothing already in the API,
-- and the node exists. What the node *does* - on_construct, timers, an
-- inventory, a drop - is the game's business, and refusing any of it would be
-- codeblock second-guessing a game about its own nodes. (F11)
--
-- **Registration is queued at the call and validated once every mod has
-- loaded.** That is the ordering constraint, and it is the reason for the
-- queue: `core.registered_nodes` is only complete after the last mod has run,
-- so checking a node's existence at the call would refuse a perfectly good node
-- belonging to a mod that happens to load later. Do not move the check into
-- register_blocks.
--
-- A refusal is logged and dropped, never raised. lib/api.lua raises on a
-- description that disagrees with its implementations, but that is codeblock's
-- own inconsistency; a game's typo aborting the server would take down
-- everything else that game does. Every line names the calling mod, the name it
-- gave and the rule it broke, which is the whole value of validating at all.
-- None of it reaches a player, so none of it is translated.
--------------------------------------------------------------------------------

local blocks = {}
codeblock.blocks = blocks

--- False until every mod has loaded, true afterwards.
-- On the module rather than in an upvalue so a spec can drive the late-call
-- refusal, which is otherwise unreachable from a suite that runs at load time.
blocks.sealed = false

-- What a game has asked for and not yet had checked. Each entry is
-- {mod, category, entries}: the calling mod's name is only knowable at the
-- call, so it is captured there and carried to the check.
local pending = {}

-- A name a program reads as a table key has to be spellable as one. LuaJIT
-- rejects `t.goto` although plain 5.1 does not, so `goto` is in here with the
-- 5.1 keywords: player code runs on whichever the server is built with.
local RESERVED = {}
for word in ([[and break do else elseif end false for function goto if in local
nil not or repeat return then true until while]]):gmatch('%S+') do
    RESERVED[word] = true
end

-- `[%w_]` and not `%w`, which excludes the underscore Lua identifiers allow and
-- would refuse half of them. (C20)
local function identifier(s)
    return type(s) == 'string' and s:match('^[%a_][%w_]*$') ~= nil and
               not RESERVED[s]
end

--- Check one request and add it to the palette. Appends to `refusals`, one
-- line per rule broken, and returns whether the category was installed.
--
-- `taken` is the set of names already spoken for: every top-level API name,
-- which covers the mod's own categories, plus anything installed earlier in
-- this same batch.
local function install_one(request, taken, refusals)

    local who, name = request.mod, request.category
    local function refuse(fmt, ...)
        refusals[#refusals + 1] = ('mod %s: %s'):format(who,
                                                        fmt:format(...))
    end

    if not identifier(name) then
        refuse("'%s' is not a usable category name - a program reads it as " ..
                   "a table key, so it must be a Lua identifier",
               tostring(name))
        return false
    end
    if taken[name] then
        refuse("the category name '%s' is already taken", name)
        return false
    end
    if type(request.entries) ~= 'table' then
        refuse("category '%s' was given %s instead of a table of " ..
                   "name = itemstring", name, type(request.entries))
        return false
    end

    -- Each bad entry is refused by name and the rest of the category still
    -- installs: one unregistered node is not worth costing a game its palette.
    local list = {}
    for short, item in pairs(request.entries) do
        if not identifier(short) then
            refuse("'%s' is not a usable block name in category '%s' - a " ..
                       "program reads it as a table key", tostring(short), name)
        elseif type(item) ~= 'string' then
            refuse("%s.%s must name a node, and is %s", name, short, type(item))
        elseif not core.registered_nodes[item] then
            refuse("%s.%s names '%s', which no mod has registered", name, short,
                   item)
        else
            -- The flat key carries the category, unlike the mod's own, so a
            -- game's `red` can never shadow colors.red however many games
            -- register one. It is what place() takes and what the editor's
            -- settings line shows.
            list[#list + 1] = {short, name .. '.' .. short, item}
        end
    end

    if #list == 0 then
        refuse("category '%s' holds nothing that can be placed", name)
        return false
    end
    table.sort(list, function(a, b) return a[1] < b[1] end)

    codeblock.config.add_category(name, list)
    taken[name] = true

    -- The sandbox pairs every name with an implementation and lib/api.lua
    -- refuses a run where the two disagree, so the description has to grow with
    -- the palette: a category is two names, the table itself and its ramp.
    -- Matched by group id and not by title, which is a wording and may change.
    -- This text reaches doc/api.md and nothing else: that file is generated
    -- with no game loaded, and deliberately describes the built-in palette
    -- only. What the running game registered is in the help panel.
    for _, group in ipairs(codeblock.api.groups) do
        if group.id == 'blocks' then
            group.entries[#group.entries + 1] = {
                name = name,
                kind = 'value',
                doc = ('Blocks the %s mod added, indexed by name.'):format(who)
            }
        elseif group.id == 'choosing' then
            group.entries[#group.entries + 1] = {
                name = 'ramp.' .. name,
                params = {'v', 'min', 'max'},
                doc = ('Map a number onto the blocks the %s mod added.'):format(
                    who),
                note = 'The names are in alphabetical order, which is the ' ..
                    'only order a registered category has, so this is a ' ..
                    'lookup rather than a gradient.'
            }
        end
    end

    return true
end

--- Validate and install a batch of requests.
--
-- Returns how many categories were installed and an array of refusal lines.
-- Reporting rather than logging, so the caller decides: the one registered
-- below logs each line as an error, and tests/integration_spec.lua drives its
-- own batch and reads the lines back, which is what makes the refusals
-- provable.
function blocks.install(requests)

    -- Every top-level name the environment already holds, which covers the
    -- mod's own categories and everything else a program can call. A dotted
    -- name reserves its first segment, so `ramp` is spoken for by ramp.hues and
    -- a category could never shadow it. Seeded from the
    -- palette as well, so a second batch cannot re-register a category the
    -- first one added.
    local taken = {}
    for _, dotted in ipairs(codeblock.api.names()) do
        taken[dotted:match('^[^%.]+')] = true
    end
    for name in pairs(codeblock.config.allowed_blocks.by_name) do
        taken[name] = true
    end

    local installed, refusals = 0, {}
    for _, request in ipairs(requests) do
        if install_one(request, taken, refusals) then
            installed = installed + 1
        end
    end
    return installed, refusals
end

--- Add a category of blocks the game has registered. See the header.
-- Returns false when the call itself is too late; every other refusal is
-- reported once the last mod has loaded.
function codeblock.register_blocks(category, entries)

    local who = core.get_current_modname() or '?'

    if blocks.sealed then
        core.log('error', ('[codeblock] mod %s: register_blocks(\'%s\') came ' ..
                     'after every mod had loaded, and was ignored - call it ' ..
                     'at load time'):format(who, tostring(category)))
        return false
    end

    pending[#pending + 1] = {
        mod = who,
        category = category,
        entries = entries
    }
    return true
end

-- Everything the queue was waiting for: core.registered_nodes is complete, and
-- no mod can still be loading.
core.register_on_mods_loaded(function()

    blocks.sealed = true
    local installed, refusals = blocks.install(pending)
    pending = {}

    for _, why in ipairs(refusals) do
        core.log('error', '[codeblock] ' .. why)
    end

    if installed > 0 then
        -- The editor's API panel is rendered once from the description, so it
        -- has to be rendered again now that the description has grown.
        codeblock.api.html_commands = codeblock.api.to_hypertext()
        core.log('action', ('[codeblock] the game added %d block %s'):format(
                     installed,
                     installed == 1 and 'category' or 'categories'))
    end

end)
