--- The four bulk shapes a program can place.
--
-- A VoxelManip pass per box of the shape: read the area, write node ids into
-- the flat data array, write it back. Ported from the WorldEdit fork this mod
-- used to depend on, keeping only cube, sphere, dome and cylinder.
--
-- The data array is the area's real contents, read with get_data, and the
-- filler overwrites only the voxels the shape claims. Never prefill it with
-- `ignore` instead: write_to_map skips an ignore voxel when relighting as well
-- as when writing, so every voxel the shape does not claim keeps its old light.
-- That left a hollow shape's inside lit and a darker row on every mapblock
-- border around any shape. (B-S-1)
--
-- Tiled into boxes rather than written in one pass, because a pass cannot be
-- interrupted: a 150-node cube is 3.4M nodes and froze the server for 0.44s,
-- against the 16ms the whole mod is allowed per step. See SLICE_BLOCKS below.
-- Every filler clips itself to the area it is handed, which is what makes a box
-- correct without narrowing the shape.

codeblock.shapes = {}

local shapes = codeblock.shapes

local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min
local get_voxel_manip = core.get_voxel_manip
local get_content_id = core.get_content_id
local load_area = core.load_area

local others = {x = {'y', 'z'}, y = {'x', 'z'}, z = {'x', 'y'}}

-- One scratch buffer for the whole mod, refilled per pass rather than
-- reallocated. It keeps the largest size it has been asked for.
--
-- It holds the contents of `open`, the last box read, which stays unwritten
-- while the shapes that follow land inside it: a program of many small shapes
-- then pays one read, write and relight per mapblock rather than per shape,
-- which is most of what a pass costs in open air. (F-S-1)
--
-- Shared safely across yields and drones because shapes.flush() writes it back
-- before stepper.advance returns: nothing else can run inside a step, so it
-- never survives one.
local data = {}
local open

-- The open box's param2, fetched only once a palette shape lands in it, so a
-- plain shape keeps the path above. From then on a plain shape in that box
-- writes a 0 here too: a VoxelManip write keeps the old param2, and a node
-- with a facing written over a palette colour would inherit a random one.
-- (F15)
local param2 = {}

-- How many mapblocks one VoxelManip pass may emerge.
--
-- A pass cannot be interrupted, so this is the longest stall the mod can cause:
-- at the measured 7.7M nodes a second, 16 mapblocks is 65k nodes and under
-- 10ms - about what the whole mod is allowed for one server step. It is also
-- why nothing limits a shape's dimensions any more, since a large shape is many
-- passes and so is slow rather than a freeze. Bigger boxes are slightly cheaper
-- per node and stall the server for proportionally longer.
local SLICE_BLOCKS = 16

--- How many mapblocks a span of nodes covers, aligned outward like the engine.
local function span(lo, hi) return floor(hi / 16) - floor(lo / 16) + 1 end

-------------------------------------------------------------------------------
-- bounds
--
-- Each returns the shape's origin plus the corners to emerge. The origin is the
-- reference point the caller in commands.lua already computed, kept so the
-- fillers do not have to derive it again.
-------------------------------------------------------------------------------

local bounds = {

    cube = function(s)
        local o = {
            x = s.pos.x - floor(s.w / 2),
            y = s.pos.y,
            z = s.pos.z - floor(s.l / 2)
        }
        -- Minus one on each axis: the filler writes 0 .. w-1 relative to `o`, so
        -- the last node is o + w - 1. Returning o + w emerged a node-layer past
        -- the shape on all three axes, free when it fell inside a mapblock
        -- already being read and a whole extra layer of blocks when it did not -
        -- which on a thin shape is a doubling, not a rounding error. (B43)
        return o, o, {x = o.x + s.w - 1, y = o.y + s.h - 1, z = o.z + s.l - 1}
    end,

    sphere = function(s)
        local p, r = s.pos, s.r
        return p, {x = p.x - r, y = p.y - r, z = p.z - r},
               {x = p.x + r, y = p.y + r, z = p.z + r}
    end,

    dome = function(s)
        local p, r = s.pos, s.r
        return p, {x = p.x - r, y = p.y, z = p.z - r},
               {x = p.x + r, y = p.y + r, z = p.z + r}
    end,

    cylinder = function(s)
        local p, r = s.pos, s.r
        local a = s.axis
        local o1, o2 = others[a][1], others[a][2]
        -- Minus one along the length, for the same reason as the cube: the
        -- filler runs 0 .. l-1 along the axis. The two radius axes are exact
        -- already, the filler running -r .. r. (B43)
        local p1 = {[a] = p[a], [o1] = p[o1] - r, [o2] = p[o2] - r}
        local p2 = {[a] = p[a] + s.l - 1, [o1] = p[o1] + r, [o2] = p[o2] + r}
        return p, p1, p2
    end

}

-------------------------------------------------------------------------------
-- fillers
--
-- Each writes only the part of the shape inside the area it is handed, which is
-- one box of it. The clip comes from the area rather than from a range passed
-- in, so it is exactly the extent `data` covers - the invariant that has to hold
-- whatever build() tiles the shape into.
--
-- Each writes `v` into `buf` at every voxel the shape claims: the node id into
-- `data`, and a second pass the param2 into `param2` when the box carries it.
--
-- Clipped on all three axes, which is what lets build() cut along all three.
-- (B42, F-S-4)
-------------------------------------------------------------------------------

--- A sphere between `ymin` and `r`. A dome is the half of one above its centre.
local function ball(s, area, buf, v, o, ymin)

    local r, hollow = s.r, s.hollow
    local ystride, zstride = area.ystride, area.zstride
    local mn, mx = area.MinEdge, area.MaxEdge
    local ox, oy, oz = o.x - mn.x, o.y - mn.y, o.z - mn.z

    -- Squared-radius window: inside the outer surface, and for a hollow shape
    -- not so far inside that it is buried. r*(r+1) and r*(r-1) rather than r*r
    -- give a shell one voxel thick with no gaps.
    local rmin, rmax = r * (r - 1), r * (r + 1)

    local xlo, xhi = max(-r, mn.x - o.x), min(r, mx.x - o.x)

    for z = max(-r, mn.z - o.z), min(r, mx.z - o.z) do
        local iz = (z + oz) * zstride + 1
        for y = max(ymin, mn.y - o.y), min(r, mx.y - o.y) do
            local iy = iz + (y + oy) * ystride
            for x = xlo, xhi do
                local sq = x * x + y * y + z * z
                if sq <= rmax and (not hollow or sq >= rmin) then
                    buf[iy + ox + x] = v
                end
            end
        end
    end

end

local fillers = {

    cube = function(s, area, buf, v, o)

        local w, h, l, hollow = s.w, s.h, s.l, s.hollow
        local ystride, zstride = area.ystride, area.zstride
        local mn, mx = area.MinEdge, area.MaxEdge
        local ox, oy, oz = o.x - mn.x, o.y - mn.y, o.z - mn.z

        local xlo, xhi = max(0, mn.x - o.x), min(w - 1, mx.x - o.x)

        for z = max(0, mn.z - o.z), min(l - 1, mx.z - o.z) do
            local iz = (oz + z) * zstride + 1
            for y = max(0, mn.y - o.y), min(h - 1, mx.y - o.y) do
                local iy = iz + (oy + y) * ystride
                for x = xlo, xhi do
                    local wall = not hollow or x == 0 or x == w - 1 or y == 0 or
                                     y == h - 1 or z == 0 or z == l - 1
                    if wall then buf[iy + ox + x] = v end
                end
            end
        end

    end,

    sphere = function(s, area, buf, v, o) ball(s, area, buf, v, o, -s.r) end,

    dome = function(s, area, buf, v, o) ball(s, area, buf, v, o, 0) end,

    cylinder = function(s, area, buf, value, o)

        local r, hollow = s.r, s.hollow
        local a = s.axis
        local o1, o2 = others[a][1], others[a][2]
        local stride = {x = 1, y = area.ystride, z = area.zstride}
        local mn = area.MinEdge
        local off = {x = o.x - mn.x, y = o.y - mn.y, z = o.z - mn.z}
        local sa, s1, s2 = stride[a], stride[o1], stride[o2]
        local oa, oo1, oo2 = off[a], off[o1], off[o2]
        local rmin, rmax = r * (r - 1), r * (r + 1)

        -- Ranges by axis, so a clip lands on whichever of the three loops runs
        -- along that axis - the length for a cylinder lying that way, a radius
        -- for one lying across it.
        local lo = {[a] = 0, [o1] = -r, [o2] = -r}
        local hi = {[a] = s.l - 1, [o1] = r, [o2] = r}
        local mx = area.MaxEdge
        lo.x, hi.x = max(lo.x, mn.x - o.x), min(hi.x, mx.x - o.x)
        lo.y, hi.y = max(lo.y, mn.y - o.y), min(hi.y, mx.y - o.y)
        lo.z, hi.z = max(lo.z, mn.z - o.z), min(hi.z, mx.z - o.z)

        for i = lo[a], hi[a] do
            local ia = (oa + i) * sa
            for u = lo[o1], hi[o1] do
                local iu = ia + (u + oo1) * s1 + 1
                for v = lo[o2], hi[o2] do
                    local sq = u * u + v * v
                    if sq <= rmax and (not hollow or sq >= rmin) then
                        buf[iu + (v + oo2) * s2] = value
                    end
                end
            end
        end

    end

}

-------------------------------------------------------------------------------
-- reach
--
-- Whether the shape writes any node in the box `lo` .. `hi`, which lies inside
-- its bounds. A box it cannot reach gets no pass: a sphere's corners, the inside
-- of a hollow shape. Answering true when unsure only costs a pass.
-------------------------------------------------------------------------------

--- Squared distance from `c` to the nearest and the farthest point of the box,
-- over the axes named in `axes`.
local function reach2(c, lo, hi, axes)
    local near, far = 0, 0
    for i = 1, #axes do
        local a = axes[i]
        local dlo, dhi = lo[a] - c[a], hi[a] - c[a]
        if dlo > 0 then near = near + dlo * dlo end
        if dhi < 0 then near = near + dhi * dhi end
        far = far + max(dlo * dlo, dhi * dhi)
    end
    return near, far
end

local xyz = {'x', 'y', 'z'}

--- A sphere or a dome, whose bounds already keep a dome's box above its centre.
local function ball_reaches(s, o, lo, hi)
    local r = s.r
    local near, far = reach2(o, lo, hi, xyz)
    return near <= r * (r + 1) and (not s.hollow or far >= r * (r - 1))
end

local reaches = {

    -- A hollow cube misses only a box wholly inside its walls.
    cube = function(s, o, lo, hi)
        if not s.hollow then return true end
        local inside = lo.x > o.x and hi.x < o.x + s.w - 1 and
                           lo.y > o.y and hi.y < o.y + s.h - 1 and
                           lo.z > o.z and hi.z < o.z + s.l - 1
        return not inside
    end,

    sphere = ball_reaches,

    dome = ball_reaches,

    -- The length is always reached, so only the two radius axes decide.
    cylinder = function(s, o, lo, hi)
        local r = s.r
        local near, far = reach2(o, lo, hi, others[s.axis])
        return near <= r * (r + 1) and (not s.hollow or far >= r * (r - 1))
    end

}

--- Write one shape into the open box `o`: its node id, then its param2 once
-- the box carries param2, fetched the first time a palette shape needs it.
local function fill(spec, o, id, origin)
    local f = fillers[spec.kind]
    f(spec, o.area, data, id, origin)
    if spec.param2 and not o.param2 then
        o.manip:get_param2_data(param2)
        o.param2 = true
    end
    if o.param2 then f(spec, o.area, param2, spec.param2 or 0, origin) end
end

--- The box to tile a shape of `sp` mapblocks into, in mapblocks per axis.
--
-- The largest that fits SLICE_BLOCKS, then the least surface, then the one that
-- leaves the fewest passes. Least surface because it has the least border to
-- relight, and because a slab one mapblock thick always touches a hollow shape's
-- wall and so never skips its inside. A shape thin in two dimensions still gets
-- a long box, since nothing else fills one.
local function box_size(sp)
    local best, bv, bs, bn
    for a = 1, min(SLICE_BLOCKS, sp.x) do
        for b = 1, min(floor(SLICE_BLOCKS / a), sp.y) do
            for c = 1, min(floor(SLICE_BLOCKS / (a * b)), sp.z) do
                local v, s = a * b * c, a * b + b * c + c * a
                local n = ceil(sp.x / a) * ceil(sp.y / b) * ceil(sp.z / c)
                local better = not best or v > bv or
                                   (v == bv and (s < bs or (s == bs and n < bn)))
                if better then
                    best, bv, bs, bn = {x = a, y = b, z = c}, v, s, n
                end
            end
        end
    end
    return best
end

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

--- Write the open box back to the map, relighting it.
--
-- With `pos`, only when the open box holds it: call it so before any single
-- node read or write, which would otherwise see the map behind the box, or be
-- overwritten by it. Without, always: stepper.advance does before it returns.
function shapes.flush(pos)

    local o = open
    if not o then return end
    if pos then
        local mn, mx = o.area.MinEdge, o.area.MaxEdge
        local inside = pos.x >= mn.x and pos.x <= mx.x and pos.y >= mn.y and
                           pos.y <= mx.y and pos.z >= mn.z and pos.z <= mx.z
        if not inside then return end
    end

    open = nil
    o.manip:set_data(data)
    if o.param2 then o.manip:set_param2_data(param2) end
    o.manip:write_to_map()

end

--- Place one shape.
--
-- spec fields:
--   kind    'cube', 'sphere', 'dome' or 'cylinder'
--   pos     reference point, as commands.lua computes it per shape and angle
--   node    node name
--   param2  optional, the palette index a palette colour rides in
--   hollow  surface only
--   w, h, l cube extents
--   r       radius, for sphere, dome and cylinder
--   axis    'x', 'y' or 'z', for cylinder
--   l       length, for cylinder
--   from    optional, a point with x and z: the boxes are written from the
--           shape's end nearest it, the lowest corner without
--   charge  optional, called before each box with the mapblocks that box will
--           emerge and the box's corners in nodes. It may yield, which is how a
--           large shape is spread over several server steps instead of
--           stalling one.
--
-- Returns how many mapblocks were charged in all. read_from_map aligns the
-- region outward to mapblock boundaries, so this is exact rather than an
-- estimate, and it is what the caller charges against its map footprint - a
-- shape pins blocks in server memory just as place() does. (S5) A box the
-- shape does not reach is loaded rather than passed, and charged the same. A
-- box inside the open one is neither read nor charged again: it is already
-- pinned.
--
-- The last box is left open, unwritten: see shapes.flush.
function shapes.build(spec)

    local origin, pos1, pos2 = bounds[spec.kind](spec)

    -- A zero dimension is reachable - cube(0, 0, 0) rounds to w = h = l = 0 -
    -- and since B43 the bounds for it are pos2 = pos1 - 1 on that axis. An
    -- inverted box must never reach read_from_map, and there is nothing to
    -- write anyway. Before B43 the same shape emerged one mapblock and filled
    -- nothing.
    if pos2.x < pos1.x or pos2.y < pos1.y or pos2.z < pos1.z then return 0 end

    -- Boxes of whole mapblocks, at most SLICE_BLOCKS each, on all three axes.
    -- Whole blocks because the engine emerges them whole anyway: a box boundary
    -- inside a block would emerge and charge that block twice. All three axes
    -- because a pass over anything larger than one box is a stall no yield can
    -- break, and past a low codelevel's footprint ceiling a run that dies where
    -- the ceiling exists to make it wait. (B42, F-S-4)
    local sp = {
        x = span(pos1.x, pos2.x),
        y = span(pos1.y, pos2.y),
        z = span(pos1.z, pos2.z)
    }
    local size = sp
    if sp.x * sp.y * sp.z > SLICE_BLOCKS then size = box_size(sp) end
    local nx, nz = ceil(sp.x / size.x), ceil(sp.z / size.z)
    local count = nx * ceil(sp.y / size.y) * nz

    local b0 = {x = floor(pos1.x / 16), y = floor(pos1.y / 16),
                z = floor(pos1.z / 16)}
    local id = get_content_id(spec.node)
    local reached = reaches[spec.kind]
    local total = 0

    -- From the end nearest `from`, so a long shape grows away from the drone
    -- instead of starting out of sight, past what a client is sent. (B-S-4)
    local from = spec.from or pos1
    local back_x = from.x > (pos1.x + pos2.x) / 2
    local back_z = from.z > (pos1.z + pos2.z) / 2

    -- Bottom up, y outermost. A box the shape does not reach is loaded instead
    -- of passed, before the box above it is written: a write pushes its new
    -- shadow down into the blocks below it only if they are in memory, and stale
    -- sunlight is never repaired afterwards, so an unloaded inside of a hollow
    -- shape would stay sky-lit for good. So only x and z follow `from`. (B-S-1)
    for i = 0, count - 1 do

        local k = {x = i % nx, z = floor(i / nx) % nz, y = floor(i / (nx * nz))}
        if back_x then k.x = nx - 1 - k.x end
        if back_z then k.z = nz - 1 - k.z end
        local lo = {
            x = max(pos1.x, (b0.x + k.x * size.x) * 16),
            y = max(pos1.y, (b0.y + k.y * size.y) * 16),
            z = max(pos1.z, (b0.z + k.z * size.z) * 16)
        }
        local hi = {
            x = min(pos2.x, (b0.x + (k.x + 1) * size.x) * 16 - 1),
            y = min(pos2.y, (b0.y + (k.y + 1) * size.y) * 16 - 1),
            z = min(pos2.z, (b0.z + (k.z + 1) * size.z) * 16 - 1)
        }
        local o = open
        local mn, mx = o and o.area.MinEdge, o and o.area.MaxEdge
        local within = o and lo.x >= mn.x and lo.y >= mn.y and lo.z >= mn.z and
                           hi.x <= mx.x and hi.y <= mx.y and hi.z <= mx.z

        if not within then
            local emerged = span(lo.x, hi.x) * span(lo.y, hi.y) * span(lo.z, hi.z)
            -- Before the pass, not after: the caller pays for the memory before
            -- it is pinned, and can make the drone wait for room first.
            if spec.charge then spec.charge(emerged, lo, hi) end
            total = total + emerged
        end

        if within then
            fill(spec, o, id, origin)
        elseif reached(spec, origin, lo, hi) then
            -- After the charge, which may yield and so end the step, closing
            -- whatever was open then.
            shapes.flush()
            local manip = get_voxel_manip()
            local emin, emax = manip:read_from_map(lo, hi)
            local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

            manip:get_data(data)
            open = {manip = manip, area = area}
            fill(spec, open, id, origin)
        else
            load_area(lo, hi)
        end
    end

    return total

end
