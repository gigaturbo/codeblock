--- The resource budget of one program run.
--
-- One table per run, made by limits.new and carried on the drone: every ceiling
-- a program can reach, with its counter beside it. That pairing is the point -
-- it is what the budget display prints, and why the caps are converted once
-- here instead of being read out of the config at every check.
--
-- Dependency-free, the caller passing the config and the clock, so
-- tests/limits_spec.lua runs it under a bare interpreter.
--
-- Two kinds of resource, and the difference between them is the design:
--
--   spent   Nodes written, runtime. Gone once used, so going over has to stop
--           the run. limits.charge.
--   held    The map footprint. The engine unloads a mapblock nothing has
--           touched for server_unload_unused_data_timeout seconds, so this one
--           drains by itself; a program over the ceiling should be made to wait
--           rather than killed. limits.hold.
--
-- The Lua heap is neither. It is measured rather than counted, so it is
-- compared against caps.heap_kb where it is sampled and needs nothing here.

local limits = {}

-- A MapBlock is 16x16x16 nodes at 4 bytes each: 16 KiB resident, measured at
-- 16.3 kB per block over a 400-block sweep. (S5)
local BLOCKS_PER_MB = 64

-- What the engine's unload timer defaults to, in seconds, when the config does
-- not say. The footprint decays over exactly that window, so the two have to
-- agree or the budget describes a footprint the server does not have.
local DEFAULT_WINDOW_S = 29

--------------------------------------------------------------------------------
-- one run's budget
--------------------------------------------------------------------------------

--- The budget for a run at `level`, from `config` (codeblock.config, or a table
-- shaped like it). `now` is a microsecond clock reading.
--
-- The caps land here in the units the checks use - microseconds, mapblocks, kB,
-- bytes. The player-facing units stay in the config, which is what an
-- administrator sets and what doc/api.md documents.
function limits.new(config, level, now)
    return {
        level = level,
        caps = {
            nodes = config.max_nodes_written[level],
            runtime = config.max_runtime_s[level] * 1e6,
            map = config.map_memory_mb[level] * BLOCKS_PER_MB,
            heap_kb = config.heap_mb[level] * 1024,
            string_bytes = config.max_string_mb[level] * 1024 * 1024,
            pace = config.pace_ms[level] * 1000,
            step = config.step_budget_us[level]
        },
        -- heap_kb is the peak growth seen, not a running total: it is measured
        -- rather than counted, so nothing charges it. Kept so the display can
        -- show the heap beside the other three instead of leaving a ceiling
        -- nobody can see how close they are to. (F4)
        used = {nodes = 0, runtime = 0, map = 0, heap_kb = 0},
        map_at = now,
        window = (config.map_window_s or DEFAULT_WINDOW_S) * 1e6
    }
end

--------------------------------------------------------------------------------
-- spending
--------------------------------------------------------------------------------

--- Charge `n` units of a spent resource - 'nodes' or 'runtime'.
--
-- Returns false once the run is over that ceiling; raising the player-facing
-- error is the caller's job, so the message stays beside the other ones. The
-- charge is recorded either way, so the display shows what was really spent.
function limits.charge(budget, what, n)
    local used = budget.used[what] + n
    budget.used[what] = used
    return used <= budget.caps[what]
end

--------------------------------------------------------------------------------
-- holding
--------------------------------------------------------------------------------

--- Ask to hold `blocks` more mapblocks, at time `now`.
--
-- Returns 0 when they fit, or the microseconds to wait before asking again.
-- Returns nil when `blocks` on its own is over the ceiling, where no amount of
-- waiting helps: a caller writing in slices never sees that, which is why
-- slicing in lib/shapes.lua and this ceiling belong together.
--
-- The footprint decays linearly over the unload window, so a run that has
-- loaded nothing for a whole window holds nothing, and one loading steadily
-- settles at about rate x window blocks - which is what is actually resident.
-- Approximate on purpose: the exact figure needs the timestamp of every block
-- the run has ever touched.
function limits.hold(budget, blocks, now)

    local cap = budget.caps.map
    local elapsed = now - budget.map_at
    local held = budget.used.map

    if elapsed >= budget.window then
        held = 0
    elseif elapsed > 0 then
        held = held * (1 - elapsed / budget.window)
    end

    budget.used.map, budget.map_at = held, now

    if held + blocks <= cap then
        budget.used.map = held + blocks
        return 0
    end

    if blocks > cap then return nil end

    -- How long `held` needs to decay to cap - blocks, so the same request fits
    -- on the retry. Under the window, because the target is never negative, and
    -- above zero, because held + blocks is over the cap and blocks is not.
    return budget.window * (1 - (cap - blocks) / held)

end

--------------------------------------------------------------------------------
-- reading the budget back
--------------------------------------------------------------------------------

-- The four resources a run fills up, in the order ties are broken. Every one is
-- a counter in `used` over a ceiling in `caps` under the same key, which is the
-- pairing limits.new exists to keep.
--
-- The other three caps are not here and are not oversights. `string_bytes` is a
-- ceiling on one allocation rather than a total, so there is nothing to be a
-- fraction of; `pace` and `step` are cadence, not a resource a program spends.
local FILLABLE = {'nodes', 'runtime', 'map', 'heap_kb'}

--- The resource closest to its ceiling: its key, and how full it is.
--
-- Returns a key from FILLABLE and a fraction, which is what a display needs to
-- say *which* limit a program actually spends rather than listing four numbers
-- and leaving the player to compare them. Not clamped at 1: a run is stopped
-- after the charge that went over, so the honest figure is briefly above it.
--
-- A ceiling of zero admits no use at all, so anything spent against it is fully
-- binding and nothing spent is not - there is no fraction to compute either way.
--
-- Pure arithmetic over `caps` and `used`, deliberately: it is the one part of
-- this feature tests/limits_spec.lua can reach.
function limits.binding(budget)

    local worst, worst_at = FILLABLE[1], -1

    for _, what in ipairs(FILLABLE) do
        local cap, used = budget.caps[what], budget.used[what]
        local at
        if cap > 0 then
            at = used / cap
        else
            at = used > 0 and 1 or 0
        end
        if at > worst_at then worst, worst_at = what, at end
    end

    return worst, worst_at
end

-- The same four, converted back into the units lib/config.lua is written in and
-- doc/api.md documents - seconds and megabytes, not microseconds and mapblocks.
--
-- The conversion belongs here for the reason limits.new's does: this file is the
-- only one that knows a mapblock is 1/64 of a megabyte, and a display doing that
-- arithmetic itself would be a second place to get it wrong.
local REPORT = {
    {what = 'nodes', unit = '', scale = 1},
    {what = 'runtime', unit = 's', scale = 1 / 1e6},
    {what = 'map', unit = 'MB', scale = 1 / BLOCKS_PER_MB},
    {what = 'heap_kb', unit = 'MB', scale = 1 / 1024}
}

--- Every fillable resource as {what, used, cap, unit}, in player-facing units.
--
-- Ordered, so a display shows the same four rows in the same order every time.
-- No formatting and no translation: the numbers are this file's, the words are
-- the caller's.
function limits.report(budget)
    local out = {}
    for i, r in ipairs(REPORT) do
        out[i] = {
            what = r.what,
            used = budget.used[r.what] * r.scale,
            cap = budget.caps[r.what] * r.scale,
            unit = r.unit
        }
    end
    return out
end

--------------------------------------------------------------------------------
-- export
--------------------------------------------------------------------------------

if rawget(_G, 'codeblock') then codeblock.limits = limits end

return limits
