--- Showing a formspec and routing what comes back.
--
-- Replaces the `formspecs` mod (ActiveFormspecs v2.4, sorcerykid), which the
-- audit records as finding A1. That mod was last touched in February 2018, lives
-- on Bitbucket, and installs itself into the engine namespace: it defines
-- minetest.create_form, update_form, destroy_form and six FORMSPEC_SIG*
-- constants, and - the part that actually mattered - it *replaces*
-- minetest.register_node and minetest.override_item for every mod loaded after
-- it, with an override_item wrapper that silently drops the del_fields argument
-- added in 5.9.
--
-- Everything codeblock used it for was four names across eight call sites. What
-- it really provided was a per-player session: state that survives a redraw,
-- routing fields to the right handler, and cleanup when a player leaves. That is
-- what this file is, in about a tenth of the size and with no engine namespace
-- touched.
--
-- One form per player at a time, which is what the old mod allowed and what the
-- editor assumes.
--
-- Handler contract, kept identical to ActiveFormspecs so lib/formspecs.lua did
-- not have to be rewritten alongside this:
--
--     handler(meta, player, fields)
--
-- `meta` is the same table across every redraw, so a handler can keep editor
-- state in it. `fields.quit == 'true'` means the player closed the form; the
-- engine sends that, not us.

codeblock.forms = {}

local forms = codeblock.forms

--------------------------------------------------------------------------------
-- backend
--
-- Indirected so tests can drive the session logic without a running server.
-- Defaults to the engine.
--------------------------------------------------------------------------------

local backend = {
    show = function(...) return minetest.show_formspec(...) end,
    close = function(...) return minetest.close_formspec(...) end
}

--- Replace the engine calls. Returns the previous backend so a test can restore.
function forms.set_backend(t)
    local previous = backend
    backend = t
    return previous
end

--------------------------------------------------------------------------------
-- sessions
--------------------------------------------------------------------------------

local sessions = {}
local counter = 0

--- Show a formspec and remember who it belongs to.
--
-- `prefix` names the form for the engine; a counter is appended so a late event
-- from a form the player has already closed cannot be mistaken for a live one.
-- ActiveFormspecs used minetest.get_password_hash for this, which is an odd tool
-- for a nonce - a counter is enough, since the session table is what actually
-- decides whether an event is accepted.
function forms.show(player_name, prefix, meta, formspec, handler)

    assert(type(player_name) == 'string', 'forms.show needs a player name')
    assert(type(formspec) == 'string', 'forms.show needs a formspec')
    assert(type(handler) == 'function', 'forms.show needs a handler')

    counter = counter + 1
    local formname = prefix .. ':' .. counter

    sessions[player_name] = {
        formname = formname,
        meta = meta or {},
        handler = handler
    }

    backend.show(player_name, formname, formspec)
    return formname
end

--- Redraw the form this player already has open, keeping its state.
-- Re-showing the same form name is how Luanti updates a formspec in place.
function forms.update(player_name, formspec)
    local s = sessions[player_name]
    if not s then return false end
    backend.show(player_name, s.formname, formspec)
    return true
end

--- Close the form from the mod's side.
--
-- Deliberately does NOT call the handler. ActiveFormspecs did, passing
-- quit = FORMSPEC_SIGPROC, but no branch in lib/formspecs.lua matched that value
-- so nothing ran - and it is the behaviour we want either way: a programmatic
-- close should not re-run the quit path that a player pressing Escape triggers.
function forms.close(player_name)
    local s = sessions[player_name]
    if not s then return false end
    sessions[player_name] = nil
    backend.close(player_name, s.formname)
    return true
end

--- Is a form currently open for this player?
function forms.is_open(player_name) return sessions[player_name] ~= nil end

--- The live state table for this player's form, or nil.
function forms.get_meta(player_name)
    local s = sessions[player_name]
    return s and s.meta or nil
end

--- Drop a player's session without touching the client. For disconnects.
function forms.forget(player_name)
    local had = sessions[player_name] ~= nil
    sessions[player_name] = nil
    return had
end

--- How many sessions are live. Tests use this to catch leaks.
function forms.count()
    local n = 0
    for _ in pairs(sessions) do n = n + 1 end
    return n
end

--------------------------------------------------------------------------------
-- routing
--------------------------------------------------------------------------------

--- Handle one fields event. Returns true if it was ours.
--
-- Events are ignored unless this player has a form open and the name matches,
-- which is what stops a crafted or stale submission reaching a handler that
-- would act on the player's files.
function forms.on_receive_fields(player, formname, fields)

    if not player then return false end
    local player_name = player:get_player_name()
    local s = sessions[player_name]

    if not s or formname ~= s.formname then return false end

    -- Clear the session before dispatching: the player has closed the form, so
    -- there is nothing left to redraw, and the handler still gets its state.
    if fields.quit == 'true' then sessions[player_name] = nil end

    s.handler(s.meta, player, fields)
    return true
end

--------------------------------------------------------------------------------
-- engine wiring
--------------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
    return forms.on_receive_fields(player, formname, fields)
end)

minetest.register_on_leaveplayer(function(player)
    forms.forget(player:get_player_name())
end)

return forms
