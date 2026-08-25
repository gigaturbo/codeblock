--- Tests for lib/shapes.lua
--
-- Run standalone with any Lua 5.1+ interpreter:
--     lua mods/codeblock/tests/shapes_spec.lua
--
-- Or in-engine by starting the game with codeblock_run_tests = true.
--
-- The shapes were ported out of the vendored WorldEdit fork, and what a port
-- like that breaks is the index arithmetic, not the geometry. So each case
-- states the geometry a second time here, in plain world coordinates, converts
-- those to indices with a formula written independently of the module, and
-- compares the two sets. A wrong stride, a dropped MinEdge offset or a swapped
-- axis all show up as a mismatch.
--
-- What this cannot cover is the real VoxelManip: these specs run at mod load,
-- before there is a map to read. The engine call itself is three lines and
-- unchanged from the fork.

--------------------------------------------------------------------------------
-- a map that is only a table
--
-- Enough of VoxelArea and VoxelManip for shapes.lua to run under a bare
-- interpreter. The emerged region is aligned outward to 16 the way the engine
-- aligns to MapBlocks, so MinEdge never coincides with the requested corner -
-- an offset the module forgot to subtract would otherwise still pass.
--------------------------------------------------------------------------------

local IGNORE = -1
local NODE = 7

local written -- data array from the last set_data
local area -- area of the last read_from_map

local function align(v, dir) return math.floor(v / 16) * 16 + (dir > 0 and 15 or 0) end

-- Local, not the global the engine provides: the module reaches it through the
-- environment it is loaded into, so nothing here needs to shadow the real one.
local fake_area = {}
function fake_area.new(_, t)
    local a = {MinEdge = t.MinEdge, MaxEdge = t.MaxEdge}
    a.ystride = t.MaxEdge.x - t.MinEdge.x + 1
    a.zstride = a.ystride * (t.MaxEdge.y - t.MinEdge.y + 1)
    a.getVolume = function()
        return a.zstride * (a.MaxEdge.z - a.MinEdge.z + 1)
    end
    return a
end

local manip = {}
function manip:read_from_map(p1, p2)
    local emin = {x = align(p1.x, -1), y = align(p1.y, -1), z = align(p1.z, -1)}
    local emax = {x = align(p2.x, 1), y = align(p2.y, 1), z = align(p2.z, 1)}
    area = fake_area:new({MinEdge = emin, MaxEdge = emax})
    return emin, emax
end
function manip:set_data(d) written = d end
function manip:write_to_map() end

-- The module is loaded into a private environment holding those fakes, in-engine
-- as well as standalone. It cannot be tested through codeblock.shapes: the specs
-- run at mod load, when minetest.get_voxel_manip() has no map yet and returns
-- nil. Loading a second copy leaves the mod's own untouched.
local shapes
do
    local box = {
        codeblock = {},
        math = math,
        minetest = {
            get_voxel_manip = function() return manip end,
            get_content_id = function(name)
                return name == 'ignore' and IGNORE or NODE
            end
        },
        VoxelArea = fake_area
    }

    -- Built with insert rather than as a literal: a nil first element leaves a
    -- hole that ipairs stops at, which is exactly what happens standalone, where
    -- there is no codeblock.modpath.
    local candidates = {}
    local existing = rawget(_G, 'codeblock')
    if existing and existing.modpath then
        candidates[#candidates + 1] = existing.modpath .. '/lib/shapes.lua'
    end
    local here = arg and arg[0] and arg[0]:match('^(.*)[/\\][^/\\]*$')
    if here then candidates[#candidates + 1] = here .. '/../lib/shapes.lua' end
    candidates[#candidates + 1] = 'mods/codeblock/lib/shapes.lua'
    candidates[#candidates + 1] = '../lib/shapes.lua'
    candidates[#candidates + 1] = 'lib/shapes.lua'

    for _, path in ipairs(candidates) do
        local chunk = loadfile(path)
        if chunk then
            setfenv(chunk, box)
            chunk()
            break
        end
    end

    shapes = box.codeblock.shapes
end

assert(shapes, 'could not locate lib/shapes.lua')

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

--------------------------------------------------------------------------------
-- comparing a shape against the same shape stated in world coordinates
--------------------------------------------------------------------------------

--- Every index the module wrote a node to, as a set.
--
-- Only the emerged volume counts, which is all set_data reads. The module keeps
-- one buffer across calls, so a shape run after a larger one leaves entries
-- above that volume; the engine never looks at them.
local function produced(spec)
    written, area = nil, nil
    shapes.build(spec)
    local set = {}
    for i = 1, area:getVolume() do
        if written[i] == NODE then set[i] = true end
    end
    return set
end

--- The same, from a list of world positions, indexed independently.
local function expected(positions)
    local set = {}
    local mn = area.MinEdge
    for _, p in ipairs(positions) do
        local i = (p.z - mn.z) * area.zstride + (p.y - mn.y) * area.ystride +
                      (p.x - mn.x) + 1
        set[i] = true
    end
    return set
end

--- Compares two index sets, reporting the first disagreement in a readable way.
local function same(a, b)
    local na, nb = 0, 0
    for i in pairs(a) do
        na = na + 1
        if not b[i] then return 'index ' .. i .. ' set but should not be' end
    end
    for i in pairs(b) do
        nb = nb + 1
        if not a[i] then return 'index ' .. i .. ' not set but should be' end
    end
    if na ~= nb then return ('%d nodes, wanted %d'):format(na, nb) end
    return 'ok'
end

--- Run `spec`, and describe it a second time by walking a box in world
-- coordinates and keeping the positions `inside` accepts.
local function check(name, spec, p1, p2, inside)
    local set = produced(spec)
    local positions = {}
    for x = p1.x, p2.x do
        for y = p1.y, p2.y do
            for z = p1.z, p2.z do
                if inside(x, y, z) then
                    positions[#positions + 1] = {x = x, y = y, z = z}
                end
            end
        end
    end
    it(name, same(set, expected(positions)), 'ok')
end

--------------------------------------------------------------------------------
-- cube
--
-- The origin is the ground-level centre: x and z are centred on it, y rises
-- from it. That is the convention every caller in commands.lua computes for.
--------------------------------------------------------------------------------

do
    local pos = {x = 100, y = 20, z = -30}
    local w, h, l = 5, 3, 7
    local x0, z0 = pos.x - math.floor(w / 2), pos.z - math.floor(l / 2)
    local x1, y1, z1 = x0 + w - 1, pos.y + h - 1, z0 + l - 1

    check('a solid cube fills its box', {
        kind = 'cube',
        pos = pos,
        w = w,
        h = h,
        l = l,
        node = 'x',
        hollow = false
    }, {x = x0, y = pos.y, z = z0}, {x = x1, y = y1, z = z1},
          function() return true end)

    check('a hollow cube keeps only its faces', {
        kind = 'cube',
        pos = pos,
        w = w,
        h = h,
        l = l,
        node = 'x',
        hollow = true
    }, {x = x0, y = pos.y, z = z0}, {x = x1, y = y1, z = z1},
          function(x, y, z)
        return x == x0 or x == x1 or y == pos.y or y == y1 or z == z0 or z == z1
    end)

    local flat = produced({
        kind = 'cube',
        pos = pos,
        w = 1,
        h = 1,
        l = 1,
        node = 'x',
        hollow = true
    })
    local n = 0
    for _ in pairs(flat) do n = n + 1 end
    it('a 1x1x1 hollow cube is one node, not zero', n, 1)
end

--------------------------------------------------------------------------------
-- sphere and dome
--
-- Centred on the origin. The radius test is squared and asymmetric - r*(r+1)
-- outside, r*(r-1) inside - which is what gives a hollow shell no gaps.
--------------------------------------------------------------------------------

do
    local pos = {x = -8, y = 40, z = 3}
    local r = 6
    local lo = {x = pos.x - r, y = pos.y - r, z = pos.z - r}
    local hi = {x = pos.x + r, y = pos.y + r, z = pos.z + r}

    local function sq(x, y, z)
        local dx, dy, dz = x - pos.x, y - pos.y, z - pos.z
        return dx * dx + dy * dy + dz * dz
    end

    check('a solid sphere', {
        kind = 'sphere',
        pos = pos,
        r = r,
        node = 'x',
        hollow = false
    }, lo, hi, function(x, y, z) return sq(x, y, z) <= r * (r + 1) end)

    check('a hollow sphere is a shell', {
        kind = 'sphere',
        pos = pos,
        r = r,
        node = 'x',
        hollow = true
    }, lo, hi, function(x, y, z)
        local s = sq(x, y, z)
        return s <= r * (r + 1) and s >= r * (r - 1)
    end)

    check('a dome is the half above its centre', {
        kind = 'dome',
        pos = pos,
        r = r,
        node = 'x',
        hollow = false
    }, lo, hi, function(x, y, z)
        return y >= pos.y and sq(x, y, z) <= r * (r + 1)
    end)

    check('a hollow dome', {
        kind = 'dome',
        pos = pos,
        r = r,
        node = 'x',
        hollow = true
    }, lo, hi, function(x, y, z)
        local s = sq(x, y, z)
        return y >= pos.y and s <= r * (r + 1) and s >= r * (r - 1)
    end)
end

--------------------------------------------------------------------------------
-- cylinder
--
-- Runs `l` nodes along `axis` starting at the origin, radius `r` in the other
-- two. All three axes are covered because the module reaches them through a
-- lookup table, which is exactly the kind of thing a port gets subtly wrong.
--------------------------------------------------------------------------------

do
    local pos = {x = 12, y = -5, z = 64}
    local r, l = 4, 5

    local others = {x = {'y', 'z'}, y = {'x', 'z'}, z = {'x', 'y'}}

    for _, axis in ipairs({'x', 'y', 'z'}) do
        local o1, o2 = others[axis][1], others[axis][2]
        local lo, hi = {}, {}
        lo[axis], hi[axis] = pos[axis], pos[axis] + l - 1
        lo[o1], hi[o1] = pos[o1] - r, pos[o1] + r
        lo[o2], hi[o2] = pos[o2] - r, pos[o2] + r

        local function radial(x, y, z)
            local p = {x = x, y = y, z = z}
            local d1, d2 = p[o1] - pos[o1], p[o2] - pos[o2]
            return d1 * d1 + d2 * d2
        end

        check('a solid cylinder along ' .. axis, {
            kind = 'cylinder',
            pos = pos,
            axis = axis,
            l = l,
            r = r,
            node = 'x',
            hollow = false
        }, lo, hi, function(x, y, z) return radial(x, y, z) <= r * (r + 1) end)

        check('a hollow cylinder along ' .. axis, {
            kind = 'cylinder',
            pos = pos,
            axis = axis,
            l = l,
            r = r,
            node = 'x',
            hollow = true
        }, lo, hi, function(x, y, z)
            local s = radial(x, y, z)
            return s <= r * (r + 1) and s >= r * (r - 1)
        end)
    end
end

--------------------------------------------------------------------------------
-- the scratch buffer
--------------------------------------------------------------------------------

do
    -- The module keeps one data array and refills it. A small shape run after a
    -- large one must not inherit the large one's nodes.
    produced({
        kind = 'sphere',
        pos = {x = 0, y = 0, z = 0},
        r = 10,
        node = 'x',
        hollow = false
    })
    local small = produced({
        kind = 'cube',
        pos = {x = 0, y = 0, z = 0},
        w = 1,
        h = 1,
        l = 1,
        node = 'x',
        hollow = false
    })
    local n = 0
    for _ in pairs(small) do n = n + 1 end
    it('the buffer is cleared between shapes', n, 1)

    -- Everything the shape did not claim must stay `ignore`, which is what
    -- makes set_data leave the surrounding map alone.
    local untouched = 0
    for i = 1, area:getVolume() do
        if written[i] == IGNORE then untouched = untouched + 1 end
    end
    it('everything else is left as ignore', untouched, area:getVolume() - 1)
end

--------------------------------------------------------------------------------
-- summary
--------------------------------------------------------------------------------

local out = {''}
out[#out + 1] = '  shapes_spec'
out[#out + 1] = '  ' .. string.rep('-', 52)
for _, f in ipairs(failures) do out[#out + 1] = '  ' .. f end
out[#out + 1] = ('  %d passed   %d failed'):format(pass, fail)
out[#out + 1] = ''

local text = table.concat(out, '\n')
if rawget(_G, 'core') or rawget(_G, 'minetest') then
    print(text)
else
    io.write(text)
    os.exit(fail == 0 and 0 or 1)
end

return {passed = pass, failed = fail}
