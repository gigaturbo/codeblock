--- The palette: from a colour a program asks for to the key of the entry it
-- rounds to.
--
-- palette.new(entries) takes the list in lib/palette_hexes.lua and answers a
-- record:
--
--   keys          'color_#rrggbb' per entry, in index order
--   hex(s)        '#rgb' or '#rrggbb', any case
--   rgb(r, g, b)  0 to 255 per channel, rounded and clamped
--   oklch(L, c, h)  CSS numbers: L 0 to 1, c from 0, h in degrees
--   okhsv(h, s, v)  Ottosson's Okhsv: h in degrees, the same hue as oklch's,
--                 s and v 0 to 1, s = v = 1 being the hue's most vivid colour
--   okhsl(h, s, l)  Ottosson's Okhsl: the same h, s and l 0 to 1, l being the
--                 toe L the grid's levels step through
--
-- Each of the five answers a key, or nil for an argument that is not a colour
-- at all: a string that is not a hex, or a channel that is not a number. The
-- caller raises, in the player's language. A number out of range, NaN or
-- infinite is an arithmetic accident and clamps instead (B6); a hue wraps,
-- being circular.
--
-- The list is a grid in OKLCh with L through Ottosson's toe: lightness
-- levels, chroma rings, and on each ring a number of hues growing with its
-- chroma, kept where sRGB can show it, plus the six pure colours off it; see
-- scripts/gen_palette.py. The snap rounds one axis at a time, the level, then
-- the ring, then the hue on that ring, so a ramp in any one of them never
-- steps back in the other two, which the nearest entry would. Where that cell
-- holds no entry, at the edge of what sRGB can show, the second-nearest hue
-- is tried, then the ring steps in; ring 0, the grey, always holds one. A
-- pure colour nearer than that answer wins, sitting off the grid. Change
-- neither this nor the sampler without the other.
--
-- Dependency-free, so tests/palette_spec.lua runs it under a bare interpreter.

local palette = {}

local floor, min, max = math.floor, math.min, math.max
local cos, sin, rad, sqrt = math.cos, math.sin, math.rad, math.sqrt
local atan2, pi = math.atan2, math.pi

-- Lightness levels past 0, the chroma between rings, and the hue step on a
-- ring in ring steps: gen_palette.py's.
local LEVELS, RING, HUE = 46, 0.022, 1.5

-- Ottosson's toe, the lightness Okhsl uses: plain OKLab L crowds the dark end.
local K1, K2 = 0.206, 0.03
local K3 = (1 + K1) / (1 + K2)

local function toe(L)
    local t = K3 * L - K1
    return (t + sqrt(t * t + 4 * K2 * K3 * L)) / 2
end

local function untoe(Lr) return (Lr * Lr + K1 * Lr) / (K3 * (Lr + K2)) end

local function to_linear(c)
    c = c / 255
    if c <= 0.04045 then return c / 12.92 end
    return ((c + 0.055) / 1.055) ^ 2.4
end

--- The grid's space of an 8-bit sRGB triple. Every coefficient of the first
-- matrix is positive, so a channel in 0..255 never hands the cube root a
-- negative, which x^(1/3) would answer NaN for under Lua 5.1.
local function lab_of(r, g, b)
    r, g, b = to_linear(r), to_linear(g), to_linear(b)
    local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
    local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
    local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
    return toe(0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s),
           1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
           0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

--- Linear sRGB of plain OKLab L, a, b.
local function linear(L, a, b)
    local l = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
    local m = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
    local s = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3
    return 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
           -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
           -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
end

--- Whether plain OKLab L, a, b is a colour sRGB can show.
local function in_gamut(L, a, b)
    local r, g, bl = linear(L, a, b)
    local e = 1e-7
    return r >= -e and r <= 1 + e and g >= -e and g <= 1 + e and bl >= -e and
               bl <= 1 + e
end

-- Okhsv and Okhsl, ported from Ottosson's reference code ("Okhsv and Okhsl",
-- 2021, MIT): the polynomial for the most chroma per lightness a hue can
-- reach, which channel it runs out through first deciding the coefficients,
-- then Halley's method. Each row is k0 to k4, then that channel's row of the
-- OKLab-to-linear-sRGB matrix.
local SATURATION = {
    {1.19086277, 1.76576728, 0.59662641, 0.75515197, 0.56771245,
     4.0767416621, -3.3077115913, 0.2309699292},
    {0.73956515, -0.45954404, 0.08285427, 0.12541070, 0.14503204,
     -1.2684380046, 2.6097574011, -0.3413193965},
    {1.35733652, -0.00915799, -1.15130210, -0.50559606, 0.00692167,
     -0.0041960863, -0.7034186147, 1.7076147010}
}

--- The largest C / L a hue reaches in sRGB, for a, b of unit length.
local function max_saturation(a, b)
    local k = SATURATION[3]
    if -1.88170328 * a - 0.80936493 * b > 1 then
        k = SATURATION[1]
    elseif 1.81444104 * a - 1.19445276 * b > 1 then
        k = SATURATION[2]
    end
    local S = k[1] + k[2] * a + k[3] * b + k[4] * a * a + k[5] * a * b
    local kl = 0.3963377774 * a + 0.2158037573 * b
    local km = -0.1055613458 * a - 0.0638541728 * b
    local ks = -0.0894841775 * a - 1.2914855480 * b
    -- The reference takes one step. In the degree before pure blue that
    -- stops up to 2% short, and three converge.
    for _ = 1, 3 do
        local l_, m_, s_ = 1 + S * kl, 1 + S * km, 1 + S * ks
        local f = k[6] * l_ ^ 3 + k[7] * m_ ^ 3 + k[8] * s_ ^ 3
        local f1 = 3 * (k[6] * kl * l_ * l_ + k[7] * km * m_ * m_ + k[8] * ks *
                       s_ * s_)
        local f2 = 6 * (k[6] * kl * kl * l_ + k[7] * km * km * m_ + k[8] * ks *
                       ks * s_)
        S = S - f * f1 / (f1 * f1 - 0.5 * f * f2)
    end
    return S
end

--- The cusp of a hue, where it reaches its most chroma: its L and C, for a, b
-- of unit length.
local function find_cusp(a, b)
    local S = max_saturation(a, b)
    local r, g, bl = linear(1, S * a, S * b)
    local L = (1 / max(r, g, bl)) ^ (1 / 3)
    return L, L * S
end

--- The most chroma sRGB shows at plain L along a, b of unit length, searched
-- below hi, a chroma it cannot show.
local function max_chroma(L, a, b, hi)
    local lo = 0
    for _ = 1, 24 do
        local mid = (lo + hi) / 2
        if in_gamut(L, mid * a, mid * b) then
            lo = mid
        else
            hi = mid
        end
    end
    return lo
end

--- Plain OKLab of Okhsv: h in radians, s and v in 0..1.
local function okhsv_lab(h, s, v)
    local a_, b_ = cos(h), sin(h)
    local L_cusp, C_cusp = find_cusp(a_, b_)
    local S_max, T_max = C_cusp / L_cusp, C_cusp / (1 - L_cusp)
    local S_0 = 0.5
    local k = 1 - S_0 / S_max
    local d = S_0 + T_max - T_max * k * s
    local L_v, C_v = 1 - s * S_0 / d, s * T_max * S_0 / d
    local L, C = v * L_v, v * C_v
    if L <= 0 then return 0, 0, 0 end
    -- The toe and the curved top of the gamut, compensated.
    local L_vt = untoe(L_v)
    local C_vt = C_v * L_vt / L_v
    local L_new = untoe(L)
    C, L = C * L_new / L, L_new
    local r, g, b = linear(L_vt, a_ * C_vt, b_ * C_vt)
    local scale = (1 / max(r, g, b, 0)) ^ (1 / 3)
    L, C = L * scale, C * scale
    return L, C * a_, C * b_
end

--- Plain OKLab of Okhsl: h in radians, s and l in 0..1, l being toe L.
-- Ottosson's reference, but for the chroma at the edge of sRGB above the
-- cusp, which the same search as oklch's finds instead of his one Halley
-- step. The chroma runs through three anchors: C_0 the slope at s 0, the
-- same in every hue; C_mid at s 0.8, a smooth fit to the gamut; C_max at s 1.
local function okhsl_lab(h, s, l)
    local L = untoe(l)
    -- Past these the soft minima below divide zero by zero.
    if s <= 0 or l <= 1e-6 or l >= 1 - 1e-6 then return L, 0, 0 end
    local a, b = cos(h), sin(h)
    local L_cusp, C_cusp = find_cusp(a, b)
    -- Below the cusp the edge is the line from black through it, exactly:
    -- darkening a colour scales its three channels alike. A search there
    -- misses the sliver of the hue next to pure blue that reaches it.
    local C_max = L <= L_cusp and L * C_cusp / L_cusp or
                      max_chroma(L, a, b, 0.5)
    -- How far the gamut's curved top reaches past the triangle through the
    -- cusp.
    local k = C_max / min(L * C_cusp / L_cusp, (1 - L) * C_cusp / (1 - L_cusp))
    -- The reference's fit to the cusp's C / L and C / (1 - L), kept below them.
    local S_mid = 0.11516993 + 1 / (7.44778970 + 4.15901240 * b + a *
                      (-2.19557347 + 1.75198401 * b + a *
                          (-2.13704948 - 10.02301043 * b + a *
                              (-4.24894561 + 5.38770819 * b + 4.69891013 * a))))
    local T_mid = 0.11239642 + 1 / (1.61320320 - 0.68124379 * b + a *
                      (0.40370612 + 0.90148123 * b + a *
                          (-0.27087943 + 0.61223990 * b + a *
                              (0.00299215 - 0.45399568 * b - 0.14661872 * a))))
    local C_a, C_b = L * S_mid, (1 - L) * T_mid
    local C_mid = 0.9 * k * (1 / (1 / C_a ^ 4 + 1 / C_b ^ 4)) ^ 0.25
    C_a, C_b = L * 0.4, (1 - L) * 0.8
    local C_0 = sqrt(1 / (1 / (C_a * C_a) + 1 / (C_b * C_b)))
    local C
    if s < 0.8 then
        local t, k1 = 1.25 * s, 0.8 * C_0
        C = t * k1 / (1 - (1 - k1 / C_mid) * t)
    else
        local t, k1 = 5 * (s - 0.8), 0.2 * 1.5625 * C_mid * C_mid / C_0
        C = C_mid + t * k1 / (1 - (1 - k1 / (C_max - C_mid)) * t)
    end
    return L, C * a, C * b
end

--- A number in lo..hi, NaN counting as lo.
local function clamp(v, lo, hi)
    if v ~= v then return lo end
    return min(hi, max(lo, v))
end

--- One integer per grid cell. Inside sRGB a ring stays below 16 and its hues
-- below 64, so the fields never overlap.
local function code(level, ring, hue) return (level * 32 + ring) * 64 + hue end

--- How many hues ring k holds, the first at hue 0.
local function hues(k)
    if k == 0 then return 1 end
    return max(3, floor(2 * pi * k / HUE + 0.5))
end

function palette.new(entries)

    local keys, Ls, As, Bs, cells, pure = {}, {}, {}, {}, {}, {}
    for i, entry in ipairs(entries) do
        local hex = entry[1]
        keys[i] = 'color_' .. hex
        Ls[i], As[i], Bs[i] = lab_of(tonumber(hex:sub(2, 3), 16),
                                     tonumber(hex:sub(4, 5), 16),
                                     tonumber(hex:sub(6, 7), 16))
        if entry[2] then
            cells[code(entry[2], entry[3], entry[4])] = i
        else
            pure[#pure + 1] = i
        end
    end

    local function dist(i, L, a, b)
        local dl, da, db = Ls[i] - L, As[i] - a, Bs[i] - b
        return dl * dl + da * da + db * db
    end

    -- No cache, which a program sweeping rgb would grow without bound. An
    -- entry snaps to itself: the sampler kept only hexes that round back to
    -- their own cell.
    local function snap(L, a, b)
        local level = floor(L * LEVELS + 0.5)
        local k = floor(sqrt(a * a + b * b) / RING + 0.5)
        local turn = atan2(b, a) / (2 * pi) % 1
        local best
        repeat
            local n = hues(k)
            local j = floor(turn * n + 0.5)
            -- The second-nearest hue before stepping in: at the edge of sRGB
            -- the gamut narrows to a point at each pure colour.
            local other = turn * n < j and j - 1 or j + 1
            best = cells[code(level, k, j % n)] or
                       cells[code(level, k, other % n)]
            k = k - 1
        until best
        local bd = dist(best, L, a, b)
        for _, i in ipairs(pure) do
            local d = dist(i, L, a, b)
            if d < bd then best, bd = i, d end
        end
        return keys[best]
    end

    local function rgb(r, g, b)
        local t = type(r) == 'number' and type(g) == 'number' and
                      type(b) == 'number'
        if not t then return nil end
        return snap(lab_of(floor(clamp(r, 0, 255) + 0.5),
                              floor(clamp(g, 0, 255) + 0.5),
                              floor(clamp(b, 0, 255) + 0.5)))
    end

    local function hex(s)
        if type(s) ~= 'string' then return nil end
        local r, g, b = s:match('^#(%x%x)(%x%x)(%x%x)$')
        local k = 1
        if not r then
            r, g, b = s:match('^#(%x)(%x)(%x)$')
            k = 17
        end
        if not r then return nil end
        return rgb(tonumber(r, 16) * k, tonumber(g, 16) * k,
                   tonumber(b, 16) * k)
    end

    -- Out of gamut, the chroma comes down at the same L and h until sRGB can
    -- show it, and only then is it rounded: rounding the raw point drifts the
    -- hue, and a program sweeping h expects it to hold. 0.5 is past any sRGB
    -- chroma, and caps an infinite c before the search halves it.
    local function oklch(L, c, h)
        local t = type(L) == 'number' and type(c) == 'number' and
                      type(h) == 'number'
        if not t then return nil end
        L, c = clamp(L, 0, 1), clamp(c, 0, 0.5)
        h = rad(clamp(h % 360, 0, 360))
        local ca, sa = cos(h), sin(h)
        if not in_gamut(L, c * ca, c * sa) then c = max_chroma(L, ca, sa, c) end
        return snap(toe(L), c * ca, c * sa)
    end

    -- Always in gamut by construction, so no search: the polynomial is the
    -- reference code's own approximation, and the snap absorbs its error.
    local function okhsv(h, s, v)
        local t = type(h) == 'number' and type(s) == 'number' and
                      type(v) == 'number'
        if not t then return nil end
        local L, a, b = okhsv_lab(rad(clamp(h % 360, 0, 360)), clamp(s, 0, 1),
                                  clamp(v, 0, 1))
        return snap(toe(L), a, b)
    end

    -- l is the toe L the snap rounds, so it passes through untouched.
    local function okhsl(h, s, l)
        local t = type(h) == 'number' and type(s) == 'number' and
                      type(l) == 'number'
        if not t then return nil end
        l = clamp(l, 0, 1)
        local _, a, b = okhsl_lab(rad(clamp(h % 360, 0, 360)), clamp(s, 0, 1), l)
        return snap(l, a, b)
    end

    return {
        keys = keys,
        hex = hex,
        rgb = rgb,
        oklch = oklch,
        okhsv = okhsv,
        okhsl = okhsl
    }

end

if rawget(_G, 'codeblock') then codeblock.palette = palette end

return palette
