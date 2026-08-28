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
local passes = 0 -- set_data calls, ie. how many slabs the shape was cut into
local world = {} -- every node written, in world coordinates, across all passes

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
-- Also accumulates what was written in world coordinates. build() cuts a large
-- shape into slabs, one set_data each, and every slab has its own index space,
-- so the only way to see the whole shape is to convert as it goes.
function manip:set_data(d)
    written = d
    passes = passes + 1
    local mn, mx = area.MinEdge, area.MaxEdge
    for z = mn.z, mx.z do
        local iz = (z - mn.z) * area.zstride + 1
        for y = mn.y, mx.y do
            local iy = iz + (y - mn.y) * area.ystride
            for x = mn.x, mx.x do
                if d[iy + (x - mn.x)] == NODE then
                    world[x .. ',' .. y .. ',' .. z] = true
                end
            end
        end
    end
end
function manip:write_to_map() end

-- The module is loaded into a private environment holding those fakes, in-engine
-- as well as standalone. It cannot be tested through codeblock.shapes: the specs
-- run at mod load, when core.get_voxel_manip() has no map yet and returns
-- nil. Loading a second copy leaves the mod's own untouched.
local shapes
do
    local box = {
        codeblock = {},
        math = math,
        core = {
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
-- what the caller is charged (S5)
--
-- build returns the mapblocks the pass emerged, and commands.lua charges them
-- against max_mapblocks. The fake VoxelManip aligns outward to 16 exactly as the
-- engine aligns to mapblocks, so the count is checkable here: it is the emerged
-- box measured in blocks, not the shape's own size.
--------------------------------------------------------------------------------

do
    -- A 1x1x1 cube at the origin: pos1 == pos2 == one node, and the emerged
    -- region is the single mapblock containing it.
    local one = shapes.build({
        kind = 'cube',
        pos = {x = 0, y = 0, z = 0},
        w = 1,
        h = 1,
        l = 1,
        node = 'x',
        hollow = false
    })
    it('a one-node shape is charged one mapblock', one, 1)

    -- cube(0, 0, 0) is reachable - the command rounds abs(w) and does not floor
    -- at 1 - and since B43 its bounds are pos2 = pos1 - 1 on every axis. An
    -- inverted box must never reach read_from_map, so build answers 0 without a
    -- pass. Before B43 the same call emerged one mapblock and wrote nothing.
    local empty = shapes.build({
        kind = 'cube',
        pos = {x = 0, y = 0, z = 0},
        w = 0,
        h = 0,
        l = 0,
        node = 'x',
        hollow = false
    })
    it('a zero-sized shape emerges nothing', empty, 0)

    -- A radius-20 sphere spans -20..20 on every axis, which aligns out to
    -- -32..31 - four mapblocks per axis, not two, because the shape crosses a
    -- boundary in both directions.
    local big = shapes.build({
        kind = 'sphere',
        pos = {x = 0, y = 0, z = 0},
        r = 20,
        node = 'x',
        hollow = false
    })
    it('a radius-20 sphere is charged 4x4x4', big, 64)

    -- Straddling a boundary costs more than sitting inside one, which is the
    -- property that makes the charge track what was actually pinned.
    --
    -- Origin is {14, 15, 14} and the last node {15, 16, 15}, so only y crosses:
    -- 1 x 2 x 1. It was 8 before B43, when pos2 ran a node past the shape and
    -- put all three axes across a boundary that the shape itself never reaches.
    local across = shapes.build({
        kind = 'cube',
        pos = {x = 15, y = 15, z = 15},
        w = 2,
        h = 2,
        l = 2,
        node = 'x',
        hollow = false
    })
    it('a shape across a boundary is charged for both sides', across, 2)
end

--------------------------------------------------------------------------------
-- slicing
--
-- A shape wider than SLICE_BLOCKS mapblocks is written in several passes, so
-- that no single uninterruptible pass stalls the server - a 150-node cube took
-- 0.44s as one pass. Each filler then has to write only the slab it was handed
-- and still, across every slab, exactly the shape it would have written in one
-- go. That clipping arithmetic is what these cases pin: they compare in world
-- coordinates, which is the only space the slabs share.
--------------------------------------------------------------------------------

do
    --- Every node a shape wrote across all its passes, and how many passes.
    local function sliced(spec)
        world, passes = {}, 0
        local charged = {}
        spec.charge = function(n) charged[#charged + 1] = n end
        local total = shapes.build(spec)
        return world, passes, total, charged
    end

    --- The same set, stated by walking a box in world coordinates.
    local function box(p1, p2, inside)
        local set = {}
        for x = p1.x, p2.x do
            for y = p1.y, p2.y do
                for z = p1.z, p2.z do
                    if inside(x, y, z) then
                        set[x .. ',' .. y .. ',' .. z] = true
                    end
                end
            end
        end
        return set
    end

    local o = {x = 0, y = 0, z = 0}

    -- 48 nodes on a side, from {-24, 0, -24} to {23, 47, 23}. That is 4 x 3 x 4
    -- mapblocks: y sits at 0..47, three whole blocks, while x and z straddle a
    -- boundary and take four. Sliced along z (ties go to z), so `across` is
    -- 4 x 3 = 12 and one z layer fits in a pass of 16: four passes of 12, 48 in
    -- total. Before B43 it read 4 x 4 x 4 and charged 64 for a box a node
    -- larger than the shape on every axis.
    local got, n, total, charged = sliced({
        kind = 'cube',
        pos = o,
        w = 48,
        h = 48,
        l = 48,
        node = 'x',
        hollow = false
    })
    it('a large cube is cut into slabs', n, 4)
    it('and writes every node it should', same(got, box({
        x = -24,
        y = 0,
        z = -24
    }, {x = 23, y = 47, z = 23}, function() return true end)), 'ok')
    it('the whole charge is the emerged box', total, 48)
    it('charged once per pass', #charged, 4)
    it('and per pass for what that pass emerged', charged[1], 12)

    -- The sphere clips its outer loop the same way, over a radius rather than
    -- an extent, and the radius test must still be the asymmetric one.
    local ball = sliced({
        kind = 'sphere',
        pos = o,
        r = 20,
        node = 'x',
        hollow = false
    })
    it('a large sphere survives being sliced', same(ball, box({
        x = -20,
        y = -20,
        z = -20
    }, {x = 20, y = 20, z = 20}, function(x, y, z)
        return x * x + y * y + z * z <= 20 * 21
    end)), 'ok')

    -- A cylinder reaches its axes through a lookup table, so the slab clip
    -- lands on a different one of its three loops depending on which way it
    -- lies: along the length for z, across a radius for x.
    local along = sliced({
        kind = 'cylinder',
        pos = o,
        axis = 'z',
        l = 40,
        r = 20,
        node = 'x',
        hollow = false
    })
    it('a cylinder sliced along its length', same(along, box({
        x = -20,
        y = -20,
        z = 0
    }, {x = 20, y = 20, z = 39}, function(x, y)
        return x * x + y * y <= 20 * 21
    end)), 'ok')

    local across = sliced({
        kind = 'cylinder',
        pos = o,
        axis = 'x',
        l = 40,
        r = 20,
        node = 'x',
        hollow = true
    })
    it('a hollow cylinder sliced across it', same(across, box({
        x = 0,
        y = -20,
        z = -20
    }, {x = 39, y = 20, z = 20}, function(_, y, z)
        local sq = y * y + z * z
        return sq <= 20 * 21 and sq >= 20 * 19
    end)), 'ok')

    -- A shape long in x is sliced along x. It used to be sliced along z
    -- whatever its shape, so every slab emerged the whole x extent: more than
    -- one pass should cost, and past a low codelevel's entire footprint ceiling
    -- the run died where the ceiling exists to make it wait. Here that is 26
    -- mapblocks a slab against the budget of 16. (B42)
    local long, _, ltotal, lcharged = sliced({
        kind = 'cube',
        pos = o,
        w = 400,
        h = 2,
        l = 2,
        node = 'x',
        hollow = false
    })
    local worst = 0
    for _, c in ipairs(lcharged) do if c > worst then worst = c end end
    it('a cube long in x is sliced along x', worst, 16)
    it('and writes every node of it', same(long, box({
        x = -200,
        y = 0,
        z = -1
    }, {x = 199, y = 1, z = 0}, function() return true end)), 'ok')
    it('and the whole charge is still the emerged box', ltotal, 52)

    -- Nothing small is sliced: a shape inside the slab budget stays one pass,
    -- which is what keeps the common case as cheap as it was.
    local _, one = sliced({
        kind = 'cube',
        pos = o,
        w = 4,
        h = 4,
        l = 4,
        node = 'x',
        hollow = false
    })
    it('a small shape is still a single pass', one, 1)
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
if rawget(_G, 'core') then
    print(text)
else
    io.write(text)
    os.exit(fail == 0 and 0 or 1)
end

return {passed = pass, failed = fail}
