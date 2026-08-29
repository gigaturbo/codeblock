--- The drone HUD: what a running program is spending, on screen.
--
-- Two lines in the top-right corner while the player's own program runs, and
-- nothing at all otherwise. The first says which file and whether it is running
-- or paused; the second says which single limit the run is closest to, and how
-- close. One limit rather than four, because the point is to teach a player
-- which resource their program actually spends - the full table is the drone
-- panel's job.
--
-- Why a HUD and not a formspec. core.show_formspec resets input focus and goes
-- through lib/forms.lua, which allows one form per player, so a live formspec
-- would fight the editor for the screen. hud_change touches one field of one
-- element, takes no focus and holds no session, so this can be live while the
-- player is typing. What it cannot do is take a click: there is no button
-- element and no HUD click callback in the engine at all, which is why pause and
-- cancel are a formspec and this is not. (F4)
--
-- Knows nothing about the drone beyond reading its record, which is what keeps
-- lib/drone.lua from having to know a HUD exists. The record is read fresh every
-- tick and never held across one: a drone can be replaced by another under the
-- same name between ticks, and a cached table would be the stale one. (A11, B29)

codeblock.hud = {}

local hud = codeblock.hud

local S = codeblock.S
local get_player_by_name = core.get_player_by_name
local binding = codeblock.limits.binding
local default_on = codeblock.config.drone_hud

-- How often the numbers are redrawn, in seconds. Two hud_change calls at most,
-- and only for a player whose own program is running, so the cost is bounded by
-- the number of players actually building rather than by the player count.
local PERIOD = 0.5

-- Top-right: the one corner the engine draws nothing in by default. Chat is top
-- left, the hotbar and the health and breath bars are along the bottom, and the
-- crosshair is the centre.
local ANCHOR = {x = 1, y = 0}
local ALIGN = {x = -1, y = 1}

-- 100 is the engine's own recommendation for a temporary notification, which is
-- exactly what this is: it is on screen only while a program runs.
local Z = 100

local WHITE = 0xFFFFFF

-- How full the binding limit is, coloured, so the second line can be read
-- without reading it. Ordered worst first.
local BANDS = {{0.9, 0xFF4040}, {0.7, 0xFFC040}, {0, 0x60E060}}

local function band(fraction)
    for _, b in ipairs(BANDS) do if fraction >= b[1] then return b[2] end end
    return WHITE
end

-- What each key from limits.binding and limits.report is called on screen, and
-- one line saying what it actually means.
--
-- Deliberately one set for both surfaces: two would be two translation keys for
-- the same resource, free to drift apart and to be translated differently in the
-- same sentence. This module owns how a limit is *named* to a player, which is
-- the same job as showing one.
--
-- **`runtime` is not wall-clock time and its name must not imply that** - the
-- whole of B46. A drone is charged only the microseconds it actually spent being
-- advanced, which is a small fraction of elapsed time by construction: 8 ms of a
-- 90 ms server step at codelevel 4. Called *Running time*, it read as a stopwatch
-- and made the ceiling unreadable - 1800 s at codelevel 4 is nearer five hours
-- of wall clock than thirty minutes. The fix is the words, not the arithmetic.
local LABELS = {
    nodes = function() return S('Blocks written') end,
    runtime = function() return S('Server time used') end,
    map = function() return S('Map held') end,
    heap_kb = function() return S('Lua memory') end
}

local DESCRIPTIONS = {
    nodes = function()
        return S('Blocks this program has placed. It stops at the ceiling.')
    end,
    runtime = function()
        return S(
                   'Server time the drone was actually given, not time on the clock - far less. It stops at the ceiling.')
    end,
    map = function()
        return S(
                   'World the program is holding in memory. At the ceiling the drone waits instead of stopping, and it drains by itself.')
    end,
    heap_kb = function()
        return S('Most memory the program has grown by. It stops at the ceiling.')
    end
}

--- What to call the resource `what`, or the key itself if it has no name here -
-- a limit added to limits.report and not here shows as its key rather than as a
-- blank row.
function hud.limit_label(what)
    local f = LABELS[what]
    return f and f() or what
end

--- One line saying what `what` is and whether reaching it stops the program.
-- Empty for a resource with no description, so a caller can concatenate blindly.
function hud.limit_description(what)
    local f = DESCRIPTIONS[what]
    return f and f() or ''
end

--- `n` with a K/M/G suffix once it stops being readable, else as an integer.
--
-- max_nodes_written is 1e8 at codelevel 4, so the panel was printing a
-- nine-digit integer against another nine-digit integer and nobody read either.
-- Thresholded rather than always applied: 850 is clearer than 0.9K. (F8)
function hud.short_number(n)
    local abs = n < 0 and -n or n
    if abs >= 1e9 then return ('%.1fG'):format(n / 1e9) end
    if abs >= 1e6 then return ('%.1fM'):format(n / 1e6) end
    if abs >= 1e4 then return ('%.1fK'):format(n / 1e3) end
    return ('%d'):format(n + (n < 0 and -0.5 or 0.5))
end

--------------------------------------------------------------------------------
-- per-player elements
--------------------------------------------------------------------------------

-- name -> {state = id, limit = id, last_state = string, last_limit = string,
--          last_colour = number}
--
-- The last_* fields are what makes the tick cheap: a hud_change is sent only for
-- a field whose text actually differs, so a paused drone costs nothing at all.
local live = {}

local function add(player, name)

    local ids = {
        state = player:hud_add({
            type = 'text',
            position = ANCHOR,
            alignment = ALIGN,
            offset = {x = -12, y = 26},
            text = '',
            number = WHITE,
            z_index = Z,
            name = 'codeblock:drone_state'
        }),
        limit = player:hud_add({
            type = 'text',
            position = ANCHOR,
            alignment = ALIGN,
            offset = {x = -12, y = 48},
            text = '',
            number = WHITE,
            z_index = Z,
            name = 'codeblock:drone_limit'
        })
    }

    -- hud_add returns nil rather than an id if the element could not be made.
    -- Half a HUD is worse than none, so both go or neither does.
    if not (ids.state and ids.limit) then
        if ids.state then player:hud_remove(ids.state) end
        if ids.limit then player:hud_remove(ids.limit) end
        return nil
    end

    live[name] = ids
    return ids
end

--- Take a player's HUD away, if they have one. Safe to call for a player who
-- has left: the elements went with them, so only the record has to go.
function hud.clear(name)
    local ids = live[name]
    if not ids then return end
    live[name] = nil
    local player = get_player_by_name(name)
    if not player then return end
    player:hud_remove(ids.state)
    player:hud_remove(ids.limit)
end

--------------------------------------------------------------------------------
-- the player's preference
--------------------------------------------------------------------------------

--- Does this player want the HUD?
--
-- get_string, not get_int: an unset key and a stored 0 both read as 0 through
-- get_int, so a default of *on* could not be expressed and a deliberate untick
-- would read as never having chosen. An absent key is "" and falls through to
-- the server's default. (B5)
function hud.wanted(player)
    local stored = player:get_meta():get_string('codeblock:drone_hud')
    if stored == '' then return default_on end
    return stored == '1'
end

--- Remember a choice. Writes '1' or '0', never the empty string, so that
-- choosing the same value the default already has still counts as choosing.
function hud.set_wanted(player, on)
    player:get_meta():set_string('codeblock:drone_hud', on and '1' or '0')
end

--------------------------------------------------------------------------------
-- the tick
--------------------------------------------------------------------------------

local elapsed = 0

--- Redraw every running drone's HUD, at most once per PERIOD.
--
-- Driven from lib/register.lua's globalstep rather than registering one here, so
-- the drone panel's refresh shares the same tick and the two cannot drift apart.
-- Returns whether this call was a redraw rather than a skipped one, which is how
-- the caller knows to refresh the panel on the same beat: the period is a
-- display cadence and belongs in one place, and that place is here.
function hud.tick(dtime)

    elapsed = elapsed + dtime
    if elapsed < PERIOD then return false end
    elapsed = 0

    -- Every player who has one now, so a drone that finished, was removed or was
    -- replaced between ticks loses its HUD even though nothing told us. Copied,
    -- because hud.clear writes to the table being walked.
    local had = {}
    for name in pairs(live) do had[#had + 1] = name end

    for _, name in ipairs(had) do
        local drone = codeblock.Drone.get(name)
        if not (drone and drone.cor and drone.budget) then hud.clear(name) end
    end

    for name, drone in pairs(codeblock.Drone.instances) do

        local player = drone.cor and drone.budget and get_player_by_name(name)

        if player and hud.wanted(player) then

            local ids = live[name] or add(player, name)

            if ids then

                local state = (drone.file or '?.lua') .. '  ' ..
                                  (drone.paused and S('paused') or S('running'))

                local what, fraction = binding(drone.budget)
                local limit = S('@1: @2%', hud.limit_label(what),
                                math.floor(fraction * 100 + 0.5))
                local colour = band(fraction)

                if state ~= ids.last_state then
                    player:hud_change(ids.state, 'text', state)
                    ids.last_state = state
                end
                if limit ~= ids.last_limit then
                    player:hud_change(ids.limit, 'text', limit)
                    ids.last_limit = limit
                end
                if colour ~= ids.last_colour then
                    player:hud_change(ids.limit, 'number', colour)
                    ids.last_colour = colour
                end

            end

        elseif live[name] then
            -- Running, but the player has just turned the HUD off.
            hud.clear(name)
        end

    end

    return true

end

--------------------------------------------------------------------------------
-- engine wiring
--------------------------------------------------------------------------------

-- The elements go with the player; only the record would be left behind, and it
-- would be handed to the next drone of the same name as though it were live.
core.register_on_leaveplayer(function(player)
    live[player:get_player_name()] = nil
end)

return hud
