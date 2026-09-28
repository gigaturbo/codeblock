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
-- before there is a map to read, nor the light the engine recomputes on write
-- (B-S-1, an in-world check).

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
local READ = 3 -- what the fake map holds everywhere before a shape

local written -- data array from the last set_data
local area -- area of the last read_from_map
local passes = 0 -- set_data calls, ie. how many boxes the shape was written in
local world = {} -- every node written, in world coordinates, across all passes
local loads = 0 -- load_area calls, ie. boxes the shape skipped
local floors = {} -- lowest y of every box read or loaded, in order

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
    floors[#floors + 1] = p1.y
    return emin, emax
end
function manip:get_data(buf)
    for i = 1, area:getVolume() do buf[i] = READ end
    return buf
end
-- Also accumulates what was written in world coordinates. build() cuts a large
-- shape into boxes, one set_data each, and every box has its own index space,
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
            load_area = function(p1)
                loads = loads + 1
                floors[#floors + 1] = p1.y
            end,
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
    -- rawget, as for codeblock above: `arg` exists under a standalone
    -- interpreter and not in-engine, where a bare read of it made Luanti warn
    -- about an undeclared global on every run.
    local argv = rawget(_G, 'arg')
    local here = argv and argv[0] and argv[0]:match('^(.*)[/\\][^/\\]*$')
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
    shapes.flush()
    written, area = nil, nil
    shapes.build(spec)
    shapes.flush()
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

    -- Everything the shape did not claim must carry what the map held, never
    -- `ignore`: the engine skips an ignore voxel when relighting, so it would
    -- keep stale light. (B-S-1)
    local untouched = 0
    for i = 1, area:getVolume() do
        if written[i] == READ then untouched = untouched + 1 end
    end
    it('everything else is what the map held', untouched, area:getVolume() - 1)
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
    shapes.flush()
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
    shapes.flush()
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
    shapes.flush()
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
    shapes.flush()
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
-- tiling
--
-- A shape wider than SLICE_BLOCKS mapblocks is written in several passes, so
-- that no single uninterruptible pass stalls the server - a 150-node cube took
-- 0.44s as one pass. Each filler then has to write only the box it was handed
-- and still, across every box, exactly the shape it would have written in one
-- go. That clipping arithmetic is what these cases pin: they compare in world
-- coordinates, which is the only space the boxes share.
--------------------------------------------------------------------------------

do
    --- Every node a shape wrote across all its passes, how many passes, what
    -- they were charged, and the corner each box starts at.
    local function sliced(spec)
        shapes.flush()
        world, passes, loads, floors = {}, 0, 0, {}
        local charged, starts = {}, {}
        spec.charge = function(n, lo)
            charged[#charged + 1] = n
            starts[#starts + 1] = lo.x .. ',' .. lo.z
        end
        local total = shapes.build(spec)
        shapes.flush()
        return world, passes, total, charged, starts
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
    -- boundary and take four. The fullest box with the least surface is
    -- 2 x 2 x 4, which leaves four passes: two of 16 at the bottom, two of 8
    -- over the last mapblock of y, 48 in total. Before B43 it read 4 x 4 x 4
    -- and charged 64 for a box a node larger than the shape on every axis.
    local got, n, total, charged = sliced({
        kind = 'cube',
        pos = o,
        w = 48,
        h = 48,
        l = 48,
        node = 'x',
        hollow = false
    })
    it('a large cube is cut into boxes', n, 4)
    it('and writes every node it should', same(got, box({
        x = -24,
        y = 0,
        z = -24
    }, {x = 23, y = 47, z = 23}, function() return true end)), 'ok')
    it('the whole charge is the emerged box', total, 48)
    it('charged once per pass', #charged, 4)
    it('and per pass for what that pass emerged', charged[1], 16)

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

    -- A cylinder reaches its axes through a lookup table, so the box clip
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

    -- A shape long in x is cut across x. It used to be sliced along z whatever
    -- its shape, so every slab emerged the whole x extent: more than one pass
    -- should cost, and past a low codelevel's entire footprint ceiling the run
    -- died where the ceiling exists to make it wait. Here that is 26 mapblocks
    -- a slab against the budget of 16. (B42)
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

    --- The corners of a 400 x 400 plate's first and last box, built from `from`.
    local function ends(from)
        local _, _, _, _, starts = sliced({
            kind = 'cube',
            pos = o,
            w = 400,
            h = 2,
            l = 400,
            node = 'x',
            hollow = false,
            from = from
        })
        return starts[1] .. ' to ' .. starts[#starts]
    end
    -- From the end nearest the drone, so a shape facing -x or -z starts beside
    -- it rather than 400 nodes away, out of sight. (B-S-4)
    it('a shape is built from its lowest corner without a start', ends(nil),
       '-200,-200 to 176,176')
    it('and from the end nearest the drone', ends({x = 199, z = 199}), '176,176 to -200,-200')
    it('on each axis alone', ends({x = 199, z = -200}), '176,-200 to -200,176')

    --- The largest charge in a list, which is the largest pass.
    local function largest(list)
        local m = 0
        for _, c in ipairs(list) do if c > m then m = c end end
        return m
    end

    --- Whether every box was read or loaded no lower than the one before it.
    local function bottom_up()
        for i = 2, #floors do
            if floors[i] < floors[i - 1] then return false end
        end
        return true
    end

    -- Wide in two dimensions, the case slicing along one axis could not cut
    -- down: 14 x 1 x 14 mapblocks, which was one slab of 14 per x layer at
    -- best. Every pass is now within the budget. (F-S-4)
    local plate, _, _, pcharged = sliced({
        kind = 'cube',
        pos = o,
        w = 200,
        h = 1,
        l = 200,
        node = 'x',
        hollow = false
    })
    it('a shape wide in two dimensions keeps every pass in budget',
       largest(pcharged) <= 16, true)
    it('and writes every node of it', same(plate, box({
        x = -100,
        y = 0,
        z = -100
    }, {x = 99, y = 0, z = 99}, function() return true end)), 'ok')

    -- A hollow sphere of radius 64 spans 9 x 9 x 9 mapblocks. The boxes wholly
    -- beyond its surface in a corner get no pass, and are loaded instead, so
    -- the shadow the shell casts can reach them. They are still charged:
    -- loading pins them just as a pass would.
    local shell, spasses, stotal, scharged = sliced({
        kind = 'sphere',
        pos = o,
        r = 64,
        node = 'x',
        hollow = true
    })
    it('a hollow sphere writes every node of its shell', same(shell, box({
        x = -64,
        y = -64,
        z = -64
    }, {x = 64, y = 64, z = 64}, function(x, y, z)
        local sq = x * x + y * y + z * z
        return sq <= 64 * 65 and sq >= 64 * 63
    end)), 'ok')
    it('and skips the boxes it does not reach', loads > 0, true)
    it('loading each one it skips', spasses + loads, #scharged)
    it('and charging for them all', stotal, 729)
    it('bottom up, so a box is loaded before the one above it is written',
       bottom_up(), true)
    it('with every pass in budget', largest(scharged) <= 16, true)

    -- A hollow cube skips its inside the same way. It takes 10 mapblocks a
    -- side before a box of 2 x 2 x 4 can sit clear of every wall.
    local hollow = sliced({
        kind = 'cube',
        pos = o,
        w = 160,
        h = 160,
        l = 160,
        node = 'x',
        hollow = true
    })
    it('a hollow cube skips its inside', loads > 0, true)
    it('and writes every node of its walls', same(hollow, box({
        x = -80,
        y = 0,
        z = -80
    }, {x = 79, y = 159, z = 79}, function(x, y, z)
        return x == -80 or x == 79 or y == 0 or y == 159 or z == -80 or z == 79
    end)), 'ok')

    -- Nothing small is cut: a shape inside the box budget stays one pass,
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
-- the open box (F-S-1)
--
-- The last box a shape read stays open, and the shapes after it that land
-- inside it are written into it: one read, one write and one relight for all of
-- them. What must hold is that nothing is lost or read stale on the way, which
-- is what shapes.flush is for.
--------------------------------------------------------------------------------

do
    --- A one-node cube at x, y, z, recording what it was charged.
    local function dot(x, y, z, charged)
        return shapes.build({
            kind = 'cube',
            pos = {x = x, y = y, z = z},
            w = 1,
            h = 1,
            l = 1,
            node = 'x',
            hollow = false,
            charge = function(n) charged[#charged + 1] = n end
        })
    end

    shapes.flush()
    world, passes, floors = {}, 0, {}
    local charged = {}
    local first = dot(1, 1, 1, charged)
    local second = dot(5, 9, 2, charged)
    it('a shape leaves its box open, unwritten', passes, 0)
    it('the next one inside it reads nothing more', #floors, 1)
    it('and is charged nothing more', #charged .. ' ' .. first .. ' ' .. second,
       '1 1 0')

    shapes.flush({x = 20, y = 1, z = 1})
    it('a flush for a node outside the box leaves it open', passes, 0)
    shapes.flush({x = 15, y = 0, z = 15})
    it('one for a node inside writes it back', passes, 1)
    it('with both shapes in it', world['1,1,1'] and world['5,9,2'], true)
    shapes.flush()
    it('and a second flush has nothing left to write', passes, 1)

    world, passes = {}, 0
    dot(1, 1, 1, {})
    dot(17, 1, 1, {})
    it('a shape outside the open box writes that box back first', passes, 1)
    it('before reading its own', world['1,1,1'] and not world['17,1,1'], true)
    shapes.flush()
    it('whose node lands when it is written back in turn', world['17,1,1'], true)
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
