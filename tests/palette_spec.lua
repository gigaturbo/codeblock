--- Tests for lib/palette.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua tests/palette_spec.lua
--
-- Or in-engine by starting the game with codeblock_run_tests = true.
--
-- What a snap like this gets wrong is the edge: an input that is not a colour
-- answered with one, a NaN or an infinity reaching the snap, a hue that does
-- not wrap, an out-of-gamut sweep drifting off its hue, a colour at the edge of
-- sRGB whose grid cell is empty, a ramp stepping back. And the list itself,
-- which a world stores by index: it must stay distinct entries that each snap
-- back to themselves.

local palette, entries
do
    local here = rawget(_G, 'arg') and arg[0] and
                     arg[0]:match('^(.*)[/\\][^/\\]*$')
    local lib
    local existing = rawget(_G, 'codeblock')
    if existing and existing.modpath then
        lib = existing.modpath .. '/lib/'
    else
        for _, dir in ipairs({here and (here .. '/../lib/') or nil,
                              'mods/codeblock/lib/', '../lib/', 'lib/'}) do
            local f = io.open(dir .. 'palette.lua', 'r')
            if f then
                f:close()
                lib = dir
                break
            end
        end
    end
    assert(lib, 'could not locate lib/palette.lua')
    palette = existing and existing.palette or dofile(lib .. 'palette.lua')
    entries = dofile(lib .. 'palette_hexes.lua')
end

local p = palette.new(entries)

--------------------------------------------------------------------------------
-- harness
--------------------------------------------------------------------------------

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

local function lin(c)
    c = c / 255
    return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

--- Plain OKLab of three channels, written apart from the module so a slip in
-- its matrices is not measured with the same slip.
local function oklab_rgb(r, g, b)
    r, g, b = lin(r), lin(g), lin(b)
    local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
    local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
    local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
    return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
           1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
           0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

local function oklab(key)
    return oklab_rgb(tonumber(key:sub(8, 9), 16), tonumber(key:sub(10, 11), 16),
                     tonumber(key:sub(12, 13), 16))
end

--- The snapping space: OKLab with L through Ottosson's toe.
local function space(L, a, b)
    local k1, k2 = 0.206, 0.03
    local k3 = (1 + k1) / (1 + k2)
    local t = k3 * L - k1
    return (t + math.sqrt(t * t + 4 * k2 * k3 * L)) / 2, a, b
end

--------------------------------------------------------------------------------
-- the list
--------------------------------------------------------------------------------

do
    -- The count is the frozen list's: it changes only by re-sampling, which
    -- a world already built cannot survive.
    it('the palette holds 3930 entries', #p.keys, 3930)
    it('which sixteen nodes of 256 hold', #p.keys <= 16 * 256, true)

    local distinct, wellformed, self, greys = 0, 0, 0, 0
    local seen = {}
    for _, key in ipairs(p.keys) do
        if not seen[key] then distinct = distinct + 1 end
        seen[key] = true
        if key:match('^color_#[0-9a-f]+$') and #key == 13 then
            wellformed = wellformed + 1
        end
        if p.hex(key:sub(7)) == key then self = self + 1 end
        local d = key:sub(8, 9)
        if key:sub(10, 11) == d and key:sub(12, 13) == d then
            greys = greys + 1
        end
    end
    it('every entry is distinct', distinct, #p.keys)
    it('every key is color_# and six lower-case digits', wellformed, #p.keys)
    it('every entry snaps to itself', self, #p.keys)
    it('the grid holds 47 greys, black and white included', greys, 47)

    -- Index 0 is what the creative inventory shows.
    it('index 0 is white', p.keys[1], 'color_#ffffff')
    it('the greys come first, down to black', p.keys[47], 'color_#000000')
end

--------------------------------------------------------------------------------
-- nearest
--------------------------------------------------------------------------------

do
    -- 512 colours spread over the cube. Rounding each axis by half a step,
    -- 0.011 in lightness and chroma and 0.017 around a ring, puts an answer
    -- within 0.023. At the tips of yellow and green the gamut narrows fast
    -- with lightness: the level rounds to where the ring no longer exists and
    -- steps in, 0.069 at #ffff87 where the nearest entry is 0.020. That is
    -- the price of a ramp that never steps back. A wrong axis or a wrong hue
    -- count is several times more.
    local worst = 0
    for r = 0, 255, 36 do
        for g = 0, 255, 36 do
            for b = 0, 255, 36 do
                local L, A, B = space(oklab_rgb(r, g, b))
                local gl, ga, gb = space(oklab(p.rgb(r, g, b)))
                worst = math.max(worst, math.sqrt((gl - L) ^ 2 + (ga - A) ^ 2 +
                                                      (gb - B) ^ 2))
            end
        end
    end
    it('a colour snaps to within 0.08 of itself', worst < 0.08, true)
end

--------------------------------------------------------------------------------
-- ramps
--------------------------------------------------------------------------------

--- Toe lightness, chroma and hue in degrees of a key.
local function lch(key)
    local L, a, b = space(oklab(key))
    return L, math.sqrt(a * a + b * b), math.deg(math.atan2(b, a)) % 360
end

do
    -- The snap rounds one axis at a time so that a ramp in one never steps
    -- back, in it or in the other two: the nearest entry would, lightness
    -- wobbling along a hue sweep. A step back is past an entry's own 8-bit
    -- jitter, about 0.003, and short of a level or a ring, 0.022.
    local back = 0
    for h = 0, 330, 30 do
        local last = -1
        for i = 0, 100 do
            local L = lch(p.oklch(i / 100, 0.08, h))
            if L < last - 0.01 then back = back + 1 end
            last = math.max(last, L)
        end
    end
    it('a lightness ramp never darkens', back, 0)

    back = 0
    for h = 0, 330, 30 do
        local last = -1
        for i = 0, 60 do
            local _, c = lch(p.oklch(0.6, i / 200, h))
            if c < last - 0.01 then back = back + 1 end
            last = math.max(last, c)
        end
    end
    it('a chroma ramp never dulls', back, 0)

    -- Every hue reaches chroma 0.12 at L 0.75, so the sweep stays on one
    -- level and one ring.
    local lo_l, hi_l, lo_c, hi_c, turned = 1, 0, 1, 0, 0
    local last = 0
    for h = 0, 359 do
        local L, c, got = lch(p.oklch(0.75, 0.12, h))
        lo_l, hi_l = math.min(lo_l, L), math.max(hi_l, L)
        lo_c, hi_c = math.min(lo_c, c), math.max(hi_c, c)
        if h > 20 and h < 340 then
            if got < last - 5 then turned = turned + 1 end
            last = math.max(last, got)
        end
    end
    it('a hue sweep holds its lightness', hi_l - lo_l < 0.01, true)
    it('a hue sweep holds its chroma', hi_c - lo_c < 0.01, true)
    it('a hue sweep never turns back', turned, 0)

    -- Past what sRGB shows, the chroma follows the gamut's edge, and the
    -- nearest entry hops between levels along it.
    local spread = 0
    for _, want in ipairs({0.3, 0.4, 0.5, 0.6, 0.7}) do
        lo_l, hi_l = 1, 0
        for h = 0, 359 do
            local L = lch(p.oklch(want, 0.3, h))
            lo_l, hi_l = math.min(lo_l, L), math.max(hi_l, L)
        end
        spread = math.max(spread, hi_l - lo_l)
    end
    it('a sweep past sRGB holds its lightness', spread < 0.01, true)
end

--------------------------------------------------------------------------------
-- hex and rgb
--------------------------------------------------------------------------------

do
    it('a short hex is the long one', p.hex('#FF0'), p.hex('#ffff00'))
    it('case does not matter', p.hex('#FFFF00'), 'color_#ffff00')
    it('the six corners are exact', table.concat({
        p.rgb(255, 0, 0), p.rgb(255, 255, 0), p.rgb(0, 255, 0),
        p.rgb(0, 255, 255), p.rgb(0, 0, 255), p.rgb(255, 0, 255)
    }, ' '), 'color_#ff0000 color_#ffff00 color_#00ff00 ' ..
           'color_#00ffff color_#0000ff color_#ff00ff')
    it('black is exact', p.rgb(0, 0, 0), 'color_#000000')
    it('white is exact', p.rgb(255, 255, 255), 'color_#ffffff')

    it('a hex without its # is not a colour', p.hex('ffffff'), nil)
    it('five digits are not a colour', p.hex('#12345'), nil)
    it('a non-hex digit is not a colour', p.hex('#ggg'), nil)
    it('trailing text is not a colour', p.hex('#fff '), nil)
    it('a number is not a hex', p.hex(0xffffff), nil)
    it('nil is not a hex', p.hex(nil), nil)

    it('a channel that is not a number is not a colour', p.rgb(1, '2', 3), nil)
    it('a missing channel is not a colour', p.rgb(1, 2), nil)
    it('channels clamp', p.rgb(300, -5, 0.4), 'color_#ff0000')
    it('NaN is zero', p.rgb(0 / 0, 255, 0 / 0), 'color_#00ff00')
    it('infinity clamps', p.rgb(math.huge, -math.huge, 0), 'color_#ff0000')
    it('channels round', p.rgb(254.6, 0.4, 0), 'color_#ff0000')
end

--------------------------------------------------------------------------------
-- oklch
--------------------------------------------------------------------------------

do
    it('full lightness is white', p.oklch(1, 0, 0), 'color_#ffffff')
    it('no lightness is black', p.oklch(0, 0.2, 90), 'color_#000000')
    it('a hue wraps upwards', p.oklch(0.7, 0.1, 370), p.oklch(0.7, 0.1, 10))
    it('a hue wraps downwards', p.oklch(0.7, 0.1, -350), p.oklch(0.7, 0.1, 10))
    it('lightness clamps', p.oklch(2, 0, 0), 'color_#ffffff')
    it('a negative chroma is grey', p.oklch(0.5, -1, 0), p.oklch(0.5, 0, 0))
    it('infinity clamps', p.oklch(math.huge, math.huge, math.huge),
       'color_#ffffff')
    it('NaN is zero', p.oklch(0 / 0, 0 / 0, 0 / 0), 'color_#000000')
    it('a string is not a number', p.oklch('0.5', 0, 0), nil)

    -- Chroma far past sRGB at every hue, at four lightnesses. The entry must
    -- keep the lightness and the hue asked for, to within about one grid
    -- step: 0.025 in L, against a measured worst of 0.008, and 24 degrees,
    -- against 19. At the edge of sRGB the answer may take the hue either side
    -- on its ring, one hue step, 21 degrees on the ring these land on.
    -- Snapping the raw point instead pulls towards the pure colours, whatever
    -- their lightness.
    local worst_l, worst_h = 0, 0
    for _, L in ipairs({0.4, 0.6, 0.7, 0.8}) do
        for h = 0, 355, 5 do
            local l, a, b = oklab(p.oklch(L, 0.4, h))
            local d = math.abs(math.deg(math.atan2(b, a)) % 360 - h) % 360
            worst_l = math.max(worst_l, math.abs(l - L))
            worst_h = math.max(worst_h, d > 180 and 360 - d or d)
        end
    end
    it('an out-of-gamut sweep keeps its lightness', worst_l <= 0.025, true)
    it('an out-of-gamut sweep keeps its hue', worst_h <= 24, true)
end

--------------------------------------------------------------------------------
-- okhsv
--------------------------------------------------------------------------------

do
    -- The port's own check: each pure colour is the cusp of its hue, the
    -- most vivid colour the hue has, so s = v = 1 at its hue lands on it. A
    -- slip in the saturation polynomial, the Halley step or the scaling
    -- lands on a neighbour instead.
    local wrong = {}
    for _, key in ipairs({'color_#ff0000', 'color_#ffff00', 'color_#00ff00',
                          'color_#00ffff', 'color_#0000ff', 'color_#ff00ff'}) do
        local _, a, b = oklab(key)
        local got = p.okhsv(math.deg(math.atan2(b, a)), 1, 1)
        if got ~= key then wrong[#wrong + 1] = key .. ' -> ' .. got end
    end
    it('full saturation and value at a pure hue is that pure colour',
       table.concat(wrong, ', '), '')

    it('no value is black', p.okhsv(40, 1, 0), 'color_#000000')
    it('no saturation at full value is white', p.okhsv(40, 0, 1),
       'color_#ffffff')
    local grey = p.okhsv(40, 0, 0.5)
    it('no saturation is a grey', grey:sub(8, 9) == grey:sub(10, 11) and
           grey:sub(8, 9) == grey:sub(12, 13), true)
    it('the same grey in every hue', p.okhsv(200, 0, 0.5), grey)
    it('a hue wraps', p.okhsv(370, 0.8, 0.8), p.okhsv(10, 0.8, 0.8))
    it('saturation and value clamp', p.okhsv(10, 2, 5), p.okhsv(10, 1, 1))
    it('NaN is zero', p.okhsv(0 / 0, 0 / 0, 0 / 0), 'color_#000000')
    it('a string is not a number', p.okhsv('0', 1, 1), nil)
    it('a missing value is not a colour', p.okhsv(0, 1), nil)

    -- Half the value is half the toe-corrected lightness, as Okhsv defines
    -- it, in every hue, to within the grid's snap.
    local worst = 0
    for h = 0, 350, 10 do
        local half = space(oklab(p.okhsv(h, 0.6, 0.5)))
        local full = space(oklab(p.okhsv(h, 0.6, 1)))
        worst = math.max(worst, math.abs(half - full / 2))
    end
    it('value scales the lightness in every hue', worst < 0.04, true)
end

--------------------------------------------------------------------------------
-- okhsl
--------------------------------------------------------------------------------

do
    -- Entries with their Okhsl from another port of the reference
    -- (coloraide), one per band of s and third of the hue circle, and two
    -- where the curve from s 0.8 to 1 decides the ring: each lands back on
    -- itself, as every entry of the list does.
    local wrong = {}
    for _, t in ipairs({{'color_#be8a82', 28.723, 0.3439, 0.6305},
                        {'color_#53704b', 139.003, 0.4216, 0.4348},
                        {'color_#a5afcd', 270.767, 0.2941, 0.7164},
                        {'color_#cfab58', 86.152, 0.6610, 0.7170},
                        {'color_#48a2b2', 210.942, 0.6409, 0.6098},
                        {'color_#964c8f', 330.862, 0.5719, 0.4570},
                        {'color_#f25078', 9.621, 0.8705, 0.6090},
                        {'color_#5d8625', 129.778, 0.8718, 0.5012},
                        {'color_#3c9ef3', 248.590, 0.9087, 0.6303},
                        {'color_#61f247', 140.893, 0.9414, 0.8256},
                        {'color_#1539a3', 264.700, 0.9206, 0.3044}}) do
        local got = p.okhsl(t[2], t[3], t[4])
        if got ~= t[1] then wrong[#wrong + 1] = t[1] .. ' -> ' .. got end
    end
    it('an entry\'s Okhsl lands on it', table.concat(wrong, ', '), '')

    -- Each pure colour is on the edge of sRGB, so full saturation at its own
    -- hue and lightness is that colour. Pure blue is the one a search along
    -- the chroma misses.
    wrong = {}
    for _, key in ipairs({'color_#ff0000', 'color_#ffff00', 'color_#00ff00',
                          'color_#00ffff', 'color_#0000ff', 'color_#ff00ff'}) do
        local l, _, h = lch(key)
        local got = p.okhsl(h, 1, l)
        if got ~= key then wrong[#wrong + 1] = key .. ' -> ' .. got end
    end
    it('full saturation at a pure colour\'s hue and lightness is that colour',
       table.concat(wrong, ', '), '')

    it('no lightness is black', p.okhsl(40, 1, 0), 'color_#000000')
    it('full lightness is white', p.okhsl(40, 1, 1), 'color_#ffffff')
    local grey = p.okhsl(40, 0, 0.5)
    it('no saturation is a grey', grey:sub(8, 9) == grey:sub(10, 11) and
           grey:sub(8, 9) == grey:sub(12, 13), true)
    it('the same grey in every hue', p.okhsl(200, 0, 0.5), grey)
    it('a hue wraps', p.okhsl(370, 0.8, 0.6), p.okhsl(10, 0.8, 0.6))
    it('saturation and lightness clamp', p.okhsl(10, 2, 5), 'color_#ffffff')
    it('saturation clamps', p.okhsl(10, 2, 0.6), p.okhsl(10, 1, 0.6))
    it('infinity clamps', p.okhsl(math.huge, math.huge, math.huge),
       'color_#ffffff')
    it('NaN is zero', p.okhsl(0 / 0, 0 / 0, 0 / 0), 'color_#000000')
    it('a string is not a number', p.okhsl('0', 1, 1), nil)
    it('a missing value is not a colour', p.okhsl(0, 1), nil)

    -- l is the toe lightness the levels step through, so l = n / 46 is level
    -- n at any hue and saturation, to within an entry's 8-bit jitter.
    local worst = 0
    for n = 0, 46 do
        for h = 0, 330, 30 do
            for _, s in ipairs({0.3, 0.6, 0.9, 1}) do
                worst = math.max(worst, math.abs(lch(p.okhsl(h, s, n / 46)) -
                                                     n / 46))
            end
        end
    end
    it('lightness n / 46 is level n', worst < 0.005, true)

    -- Turning h keeps one level, in soft rainbows and vivid ones.
    local spread = 0
    for _, s in ipairs({0.3, 0.6, 1}) do
        for _, l in ipairs({0.3, 0.5, 0.7}) do
            local lo, hi = 1, 0
            for h = 0, 359 do
                local L = lch(p.okhsl(h, s, l))
                lo, hi = math.min(lo, L), math.max(hi, L)
            end
            spread = math.max(spread, hi - lo)
        end
    end
    it('a rainbow holds its lightness', spread < 0.01, true)

    -- A low saturation is about one chroma in every hue: at s 0.3 and l 0.7
    -- the rainbow stays on one ring.
    local lo, hi = 1, 0
    for h = 0, 359 do
        local _, c = lch(p.okhsl(h, 0.3, 0.7))
        lo, hi = math.min(lo, c), math.max(hi, c)
    end
    it('a soft rainbow holds its chroma', hi - lo < 0.01, true)

    local darker, duller = 0, 0
    for h = 0, 330, 30 do
        for _, s in ipairs({0.5, 1}) do
            local last = -1
            for i = 0, 100 do
                local L = lch(p.okhsl(h, s, i / 100))
                if L < last - 0.01 then darker = darker + 1 end
                last = math.max(last, L)
            end
        end
        for _, l in ipairs({0.3, 0.5, 0.7}) do
            local last = -1
            for i = 0, 100 do
                local _, c = lch(p.okhsl(h, i / 100, l))
                if c < last - 0.01 then duller = duller + 1 end
                last = math.max(last, c)
            end
        end
    end
    it('a lightness ramp never darkens', darker, 0)
    it('a saturation ramp never dulls', duller, 0)
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  palette_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''

local text = table.concat(out, '\n')
if rawget(_G, 'core') then
    print(text)
else
    io.write(text)
    os.exit(fail == 0 and 0 or 1)
end

return {passed = pass, failed = fail}
