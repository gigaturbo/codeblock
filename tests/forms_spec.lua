--- Tests for lib/forms.lua
--
-- In-engine only: the module registers engine callbacks at load. The session
-- logic itself is driven through a stubbed backend, so no client is needed.
--
-- This matters more than the usual spec, because replacing the formspec layer
-- cannot be checked by eye from here - there is no client in a headless server.
-- What can be checked is the part that actually broke things if wrong: which
-- events reach a handler, whether state survives a redraw, and whether sessions
-- are cleaned up.

if not (rawget(_G, 'codeblock') and codeblock.forms) then
    io.write('\n  forms_spec\n  skipped (needs the mod loaded)\n\n')
    return {skipped = true}
end

local forms = codeblock.forms

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
-- a fake engine and a fake player
--------------------------------------------------------------------------------

local shown, closed
local function reset_backend()
    shown, closed = {}, {}
end

local real_backend = forms.set_backend({
    show = function(pname, formname, spec)
        shown[#shown + 1] = {player = pname, form = formname, spec = spec}
    end,
    close = function(pname, formname)
        closed[#closed + 1] = {player = pname, form = formname}
    end
})

local function fake_player(name)
    return {get_player_name = function() return name end}
end

local function last_shown() return shown[#shown] end

--------------------------------------------------------------------------------
-- showing and redrawing
--------------------------------------------------------------------------------

reset_backend()
forms.forget('alice')
forms.forget('bob')

do
    local seen = {}
    local meta = {tabs = {}, counter = 0}
    local formname = forms.show('alice', 'codeblock:editor', meta, 'FS1',
                                function(m, p, f)
                                    seen[#seen + 1] = {m = m, f = f}
                                end)

    it('shows the formspec once', #shown, 1)
    it('to the right player', last_shown().player, 'alice')
    it('with the given formspec', last_shown().spec, 'FS1')
    it('the form name carries the prefix',
       (formname:find('codeblock:editor', 1, true) == 1), true)
    it('a session is open', forms.is_open('alice'), true)

    -- a redraw must reuse the same form name, which is how Luanti updates in
    -- place rather than opening a second window
    forms.update('alice', 'FS2')
    it('redrawing shows again', #shown, 2)
    it('redrawing reuses the form name', last_shown().form, formname)
    it('redrawing sends the new formspec', last_shown().spec, 'FS2')

    -- state has to survive a redraw, because the editor keeps its tabs in it
    meta.counter = 7
    forms.on_receive_fields(fake_player('alice'), formname, {save = 'x'})
    it('the handler ran', #seen, 1)
    it('and got the same state table back', seen[1].m.counter, 7)
    it('and the fields', seen[1].f.save, 'x')
    it('the session is still open after a button press', forms.is_open('alice'),
       true)
end

--------------------------------------------------------------------------------
-- events that must be ignored
--
-- The handlers act on a player's files, so an event that did not come from a
-- form we sent must not reach them.
--------------------------------------------------------------------------------

do
    local ran = 0
    local formname = forms.show('bob', 'codeblock:editor', {}, 'FS',
                                function() ran = ran + 1 end)

    it('ignores a form name we never sent',
       forms.on_receive_fields(fake_player('bob'), 'codeblock:editor:999999',
                              {save = 'x'}), false)
    it('and the handler did not run', ran, 0)

    it('ignores an event for a player with no form open',
       forms.on_receive_fields(fake_player('carol'), formname, {save = 'x'}),
       false)
    it('still did not run', ran, 0)

    it('accepts the matching form', forms.on_receive_fields(
           fake_player('bob'), formname, {save = 'x'}), true)
    it('which does run the handler', ran, 1)

    -- after the player closes it, a late event for the same name is stale
    forms.on_receive_fields(fake_player('bob'), formname, {quit = 'true'})
    it('closing ran the handler once more', ran, 2)
    it('the session is gone', forms.is_open('bob'), false)
    it('a late event for the closed form is ignored',
       forms.on_receive_fields(fake_player('bob'), formname, {save = 'x'}),
       false)
    it('so the handler did not run again', ran, 2)
end

--------------------------------------------------------------------------------
-- closing from the mod's side
--------------------------------------------------------------------------------

do
    reset_backend()
    local ran = 0
    forms.show('alice', 'codeblock:chooser', {}, 'FS',
               function() ran = ran + 1 end)

    it('closing tells the client', (function()
        forms.close('alice')
        return #closed
    end)(), 1)
    it('and forgets the session', forms.is_open('alice'), false)

    -- Deliberate: a programmatic close does not run the quit path. The old mod
    -- called the handler with a non-'true' quit value, which matched no branch,
    -- so this is the same behaviour with less indirection.
    it('and does not invoke the handler', ran, 0)

    it('closing again is harmless', forms.close('alice'), false)
end

--------------------------------------------------------------------------------
-- cleanup
--------------------------------------------------------------------------------

do
    forms.forget('alice')
    forms.forget('bob')
    forms.forget('carol')
    it('no sessions leak between tests', forms.count(), 0)

    forms.show('dave', 'codeblock:editor', {}, 'FS', function() end)
    it('a session is counted', forms.count(), 1)
    it('forgetting a disconnected player drops it', (function()
        forms.forget('dave')
        return forms.count()
    end)(), 0)
    it('forgetting an unknown player is harmless', forms.forget('nobody'), false)
end

--------------------------------------------------------------------------------
-- one form per player
--------------------------------------------------------------------------------

do
    reset_backend()
    local first = forms.show('erin', 'codeblock:editor', {}, 'A', function() end)
    local second = forms.show('erin', 'codeblock:chooser', {}, 'B',
                              function() end)
    it('opening a second form replaces the first',
       (first ~= second), true)
    it('only one session exists for the player', forms.count(), 1)
    it('an event for the replaced form is ignored',
       forms.on_receive_fields(fake_player('erin'), first, {save = 'x'}), false)
    it('an event for the current form is accepted',
       forms.on_receive_fields(fake_player('erin'), second, {save = 'x'}), true)
    forms.forget('erin')
end

--------------------------------------------------------------------------------
-- the drone panel: who it redraws, and when it stops (F4)
--
-- The drawing needs a client and the numbers need a running program, so neither
-- is reachable from here. What is reachable is the part that would break the
-- editor if wrong: the panel refreshes itself on a timer, and forms.lua allows
-- one form per player, so a stale watch would push the panel's formspec into
-- whatever form the player actually has open.
--------------------------------------------------------------------------------

local panel = codeblock.formspecs.drone_panel

do
    reset_backend()
    panel.show('frank')

    it('the panel opens a session', forms.count(), 1)
    -- It opens for a player with no drone at all and says so, rather than the
    -- gesture doing nothing. That is the whole of the F8 change to this form:
    -- one meaning, an answer in every state. (F8)
    it('and with no drone it says so',
       (last_shown().spec:find('no drone', 1, true) ~= nil), true)
    it('offering nothing to act on but Close',
       (last_shown().spec:find('remove', 1, true) == nil), true)

    local before = #shown
    panel.tick()
    it('a tick redraws it', (#shown > before), true)
    it('into its own form', last_shown().form, shown[before].form)

    forms.on_receive_fields(fake_player('frank'), last_shown().form,
                            {quit = 'true'})
    it('the quit event drops the session', forms.count(), 0)

    before = #shown
    panel.tick()
    it('and no tick redraws it afterwards', #shown, before)
end

do
    -- The regression this exists for: opening the editor over an open panel
    -- replaces the session, and forms.update writes to whichever form the
    -- player has open - so a watch left behind would redraw the panel's
    -- formspec into the editor.
    reset_backend()
    panel.show('grace')
    forms.show('grace', 'codeblock:file_editor', {}, 'EDITOR', function() end)

    local before = #shown
    panel.tick()
    it('a panel whose session was replaced is not redrawn', #shown, before)
    it('so the form that is open keeps its own content',
       last_shown().spec, 'EDITOR')

    before = #shown
    panel.tick()
    it('and the stale watch is gone rather than retried', #shown, before)
    forms.forget('grace')
end

do
    -- Cancel with no drone still closes the panel rather than leaving it up:
    -- Drone.on_remove finds nothing, which is exactly the case of a run that
    -- ended between the redraw the player clicked and this event arriving.
    reset_backend()
    panel.show('heidi')
    forms.on_receive_fields(fake_player('heidi'), last_shown().form,
                            {cancel = 'x'})
    it('cancelling closes the session', forms.count(), 0)
    it('and closes the client side too', #closed, 1)
end

--------------------------------------------------------------------------------
-- restore the real backend, or the editor stops working for the rest of the run
--------------------------------------------------------------------------------

forms.set_backend(real_backend)
it('the engine backend is restored', (forms.is_open('nobody') == false), true)

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  forms_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''
print(table.concat(out, '\n'))

return {passed = pass, failed = fail}
