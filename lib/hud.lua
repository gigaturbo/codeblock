--- The drone HUD: what a running program is spending, on screen.
--
-- A five-line block hanging from the top-right corner while the player's own
-- program runs, and nothing at all otherwise:
--
--     mosely.lua : running          <- bold
--     Budget usage:
--     - Blocks: 72%
--     - CPU: 0%
--     - Memory: 4%
--
-- The three that can stop a program, as percentages, with the one that will be
-- reached first in amber and anything at 80% or more in red - so a glance finds
-- either nothing or one thing. The map footprint is absent: it throttles rather
-- than stops, so a percentage of it says nothing about whether the run survives.
-- (B45)
--
-- This replaced a two-line version that named only the binding limit. Naming one
-- was meant to teach which resource a program spends; in a world it just meant
-- the other two were invisible, and the answer was almost always the same. Three
-- short lines cost four more elements and say all of it. (F4, F8)
--
-- The full table, with what each limit means and what it has spent against its
-- ceiling, is the drone panel's job.
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
local report = codeblock.limits.report
local default_on = codeblock.config.drone_hud

-- How often the numbers are redrawn, in seconds. At most one hud_change per line
-- that actually changed, and only for a player whose own program is running, so
-- the cost is bounded by the number of players actually building rather than by
-- the player count.
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

-- The HUD's own line height and top inset, in pixels. Both adapt to screen DPI
-- and the player's scaling factor, which is what `offset` promises.
local LINE_H = 20
local TOP = 6

-- Bold, from the `style` bitfield on a text element: 1 bold, 2 italic,
-- 4 monospace. Only the first line gets it, so the block reads as a title over
-- its numbers.
local BOLD = 1

--- What colour a percentage should be drawn in, or nil to leave it plain.
--
-- Red once a limit is nearly spent, amber for the one that will be reached
-- first, nothing otherwise - so a glance finds either nothing or one thing. Red
-- wins, because "nearly out" matters more than "first to run out".
--
-- Exported because the drone panel applies the same rule to the same numbers: a
-- player looking at both must not be told two different things about one figure.
-- Returned as an integer, which is what a HUD element takes; the panel formats it
-- for `core.colorize`.
local RED = 0xFF4040
local AMBER = 0xFFC040
local ALARM_AT = 0.8

function hud.pct_colour(fraction, is_binding)
    if fraction >= ALARM_AT then return RED end
    if is_binding then return AMBER end
    return nil
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
    nodes = function() return S('Blocks placed') end,
    runtime = function() return S('Server time used') end,
    map = function() return S('Map held') end,
    heap_kb = function() return S('Lua memory') end
}

-- One line each, and short on purpose: the panel gives each two wrapped lines,
-- and a translation runs longer than the English.
--
-- None of them says "it stops the program", because the panel lists only the
-- limits that do - the held one is not shown there at all. Saying it on every
-- row would be three copies of the same sentence. (F8)
local DESCRIPTIONS = {
    nodes = function() return S('How many blocks this program has placed.') end,
    runtime = function()
        return S(
            'Server CPU time used by your drone.')
    end,
    map = function()
        return S(
            'World the program holds in memory. Here the drone waits rather than stopping, and it frees itself.')
    end,
    heap_kb = function()
        return S('The most memory the program has grown by at any point.')
    end
}

-- The same three resources named for the HUD, where there is room for one word
-- and no room for an explanation.
--
-- A second naming, and the duplication is the point rather than a slip: the
-- panel's row is a heading over a sentence, the HUD's is an item in a five-line
-- glance. `Server time used` earns its length beside a description saying it is
-- not clock time; on the HUD it would be most of the line, and `CPU` is what it
-- actually is. (F8)
local SHORT_LABELS = {
    nodes = function() return S('Blocks') end,
    runtime = function() return S('CPU') end,
    heap_kb = function() return S('Memory') end
}

-- Which resources the HUD lists, in order. The same three the panel lists and
-- the same three limits.binding compares - the held one stops nothing, so it is
-- not a budget to show a percentage of. (B45)
local HUD_ROWS = {'nodes', 'runtime', 'heap_kb'}

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
-- max_nodes_written is 1e7 at codelevel 4, so the panel was printing an
-- eight-digit integer against another eight-digit integer and nobody read either.
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

-- name -> {ids = {n...}, text = {n...}, colour = {n...}}
--
-- One element per line, five of them: the header, "Budget usage:", and one row
-- per resource. Not one element holding newlines, for two reasons - colour is a
-- property of the whole element, so per-line colouring needs per-line elements
-- anyway, and `number` is documented for every client while inline
-- `core.colorize` in HUD text needs protocol 44.
--
-- `text` and `colour` are the last values sent. They are what makes the tick
-- cheap: a hud_change goes only for a line that actually changed, so a paused
-- drone costs nothing at all.
local live = {}

local LINES = 2 + #HUD_ROWS

local function add(player, name)

    local ids = {}

    for i = 1, LINES do
        -- Anchored at the top-right corner and extending left and down, so the
        -- block hangs from the corner: alignment {-1, 1} puts the element's
        -- top-right at the anchor plus the offset.
        ids[i] = player:hud_add({
            type = 'text',
            position = ANCHOR,
            alignment = ALIGN,
            offset = {x = -8, y = TOP + (i - 1) * LINE_H},
            text = '',
            number = WHITE,
            -- The header only. Bold is per element, so only a whole line can
            -- have it - the name and its state read as one title anyway.
            style = i == 1 and BOLD or 0,
            z_index = Z,
            name = 'codeblock:drone_hud_' .. i
        })
        -- hud_add returns nil rather than an id if an element could not be made.
        -- Part of a HUD is worse than none, so they all go or none does.
        if not ids[i] then
            for j = 1, i - 1 do player:hud_remove(ids[j]) end
            return nil
        end
    end

    live[name] = {ids = ids, text = {}, colour = {}}
    return live[name]
end

--- Send one line, if it differs from what this player was last sent.
local function set_line(player, rec, i, text, colour)
    colour = colour or WHITE
    if rec.text[i] ~= text then
        player:hud_change(rec.ids[i], 'text', text)
        rec.text[i] = text
    end
    if rec.colour[i] ~= colour then
        player:hud_change(rec.ids[i], 'number', colour)
        rec.colour[i] = colour
    end
end

--- Take a player's HUD away, if they have one. Safe to call for a player who
-- has left: the elements went with them, so only the record has to go.
function hud.clear(name)
    local rec = live[name]
    if not rec then return end
    live[name] = nil
    local player = get_player_by_name(name)
    if not player then return end
    for _, id in ipairs(rec.ids) do player:hud_remove(id) end
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

            local rec = live[name] or add(player, name)

            if rec then

                set_line(player, rec, 1, S('@1 : @2', drone.file or '?.lua',
                    (drone.paused and S('paused') or
                        S('running'))))
                set_line(player, rec, 2, S('Budget usage'))

                -- Which of the three will be reached first, so exactly one of
                -- them can be marked amber. It is never the map footprint: that
                -- one is a throttle and stops nothing. (B45)
                local worst = binding(drone.budget)

                -- limits.report returns every resource in its own fixed order,
                -- so index it by key and let HUD_ROWS decide what is shown and
                -- in what order. That is what skips the held one.
                local at = {}
                for _, r in ipairs(report(drone.budget)) do at[r.what] = r.at end

                for i, what in ipairs(HUD_ROWS) do
                    local f = at[what] or 0
                    set_line(player, rec, 2 + i,
                        S('@1: @2%', SHORT_LABELS[what](),
                            math.floor(f * 100 + 0.5)),
                        hud.pct_colour(f, what == worst))
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
