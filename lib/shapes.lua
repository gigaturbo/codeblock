--- The four bulk shapes a program can place.
--
-- A VoxelManip pass per slab of the shape: read the area, write node ids into
-- the flat data array, write it back. Ported from the WorldEdit fork this mod
-- used to depend on, keeping only cube, sphere, dome and cylinder.
--
-- The data array is filled with `ignore` first, which set_data leaves untouched
-- on write, so only the voxels the shape claims are changed.
--
-- Sliced rather than written in one pass, because a pass cannot be interrupted:
-- a 150-node cube is 3.4M nodes and froze the server for 0.44s, against the
-- 16ms the whole mod is allowed per step. See SLICE_BLOCKS below. Every filler
-- clips itself to the area it is handed, which is what makes a slab correct
-- without narrowing the shape.

codeblock.shapes = {}

local shapes = codeblock.shapes

local floor = math.floor
local max = math.max
local min = math.min
local get_voxel_manip = core.get_voxel_manip
local get_content_id = core.get_content_id

-- Resolved on first use rather than at load: content ids are only settled once
-- every mod has registered its nodes.
local c_ignore

local others = {x = {'y', 'z'}, y = {'x', 'z'}, z = {'x', 'y'}}

-- One scratch buffer for the whole mod, refilled per pass rather than
-- reallocated. It keeps the largest size it has been asked for.
--
-- Shared safely even though build() yields between passes: a pass fills the
-- buffer and hands it to set_data before anything else can run, so nothing in
-- it has to survive the yield. Only its length does.
local data = {}

-- How many mapblocks one VoxelManip pass may emerge.
--
-- A pass cannot be interrupted, so this is the longest stall the mod can cause:
-- at the measured 7.7M nodes a second, 16 mapblocks is 65k nodes and under
-- 10ms - about what the whole mod is allowed for one server step. It is also
-- why nothing limits a shape's dimensions any more, since a large shape is many
-- passes and so is slow rather than a freeze. Bigger slabs are slightly cheaper
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
-- one slab of it. The clip comes from the area rather than from a range passed
-- in, so it is exactly the extent `data` covers - the invariant that has to hold
-- whatever build() slices the shape into.
--
-- Clipped on all three axes, not just the one build() happens to slice along:
-- that is what lets it slice along whichever axis is longest. (B42)
-------------------------------------------------------------------------------

--- A sphere between `ymin` and `r`. A dome is the half of one above its centre.
local function ball(s, area, id, o, ymin)

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
                    data[iy + ox + x] = id
                end
            end
        end
    end

end

local fillers = {

    cube = function(s, area, id, o)

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
                    if wall then data[iy + ox + x] = id end
                end
            end
        end

    end,

    sphere = function(s, area, id, o) ball(s, area, id, o, -s.r) end,

    dome = function(s, area, id, o) ball(s, area, id, o, 0) end,

    cylinder = function(s, area, id, o)

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
                        data[iu + (v + oo2) * s2] = id
                    end
                end
            end
        end

    end

}

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

--- Place one shape.
--
-- spec fields:
--   kind    'cube', 'sphere', 'dome' or 'cylinder'
--   pos     reference point, as commands.lua computes it per shape and angle
--   node    node name
--   hollow  surface only
--   w, h, l cube extents
--   r       radius, for sphere, dome and cylinder
--   axis    'x', 'y' or 'z', for cylinder
--   l       length, for cylinder
--   charge  optional, called before each pass with the mapblocks that pass will
--           emerge. It may yield, which is how a large shape is spread over
--           several server steps instead of stalling one.
--
-- Returns how many mapblocks were emerged in all. read_from_map aligns the
-- region outward to mapblock boundaries, so this is exact rather than an
-- estimate, and it is what the caller charges against its map footprint - a
-- shape pins blocks in server memory just as place() does. (S5)
function shapes.build(spec)

    local origin, pos1, pos2 = bounds[spec.kind](spec)

    -- A zero dimension is reachable - cube(0, 0, 0) rounds to w = h = l = 0 -
    -- and since B43 the bounds for it are pos2 = pos1 - 1 on that axis. An
    -- inverted box must never reach read_from_map, and there is nothing to
    -- write anyway. Before B43 the same shape emerged one mapblock and filled
    -- nothing.
    if pos2.x < pos1.x or pos2.y < pos1.y or pos2.z < pos1.z then return 0 end

    -- Slabs of whole mapblocks along the shape's longest axis. Whole blocks
    -- because the engine emerges them whole anyway: a slab boundary inside a
    -- block would emerge and charge that block twice.
    --
    -- The longest axis, not z, because `across` - the slab's cross-section, the
    -- part no slicing can reduce - is what a pass costs at minimum. Slicing a
    -- shape 30000 nodes long across its length left every slab emerging 1877
    -- mapblocks, past a low codelevel's whole footprint ceiling, so the run died
    -- where the ceiling exists to make it wait. Ties go to z, which is the
    -- outermost loop of every filler and so keeps a slab contiguous in the data
    -- array. A shape large in two dimensions is still bigger than one pass
    -- should be, and slicing cannot fix that. (B42)
    local sp = {
        x = span(pos1.x, pos2.x),
        y = span(pos1.y, pos2.y),
        z = span(pos1.z, pos2.z)
    }
    local axis = 'z'
    if sp.x > sp[axis] then axis = 'x' end
    if sp.y > sp[axis] then axis = 'y' end
    local o1, o2 = others[axis][1], others[axis][2]

    local across = sp[o1] * sp[o2]
    local layers = floor(SLICE_BLOCKS / across)
    if layers < 1 then layers = 1 end

    c_ignore = c_ignore or get_content_id('ignore')
    local id = get_content_id(spec.node)
    local total = 0
    local a = pos1[axis]

    while a <= pos2[axis] do

        -- Last node of the last whole mapblock in this slab.
        local aend = min((floor(a / 16) + layers) * 16 - 1, pos2[axis])
        local emerged = across * span(a, aend)

        -- Before the pass, not after: the caller pays for the memory before it
        -- is pinned, and can make the drone wait for room first.
        if spec.charge then spec.charge(emerged) end
        total = total + emerged

        local manip = get_voxel_manip()
        local emin, emax = manip:read_from_map({
            [axis] = a,
            [o1] = pos1[o1],
            [o2] = pos1[o2]
        }, {[axis] = aend, [o1] = pos2[o1], [o2] = pos2[o2]})
        local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

        for i = 1, area:getVolume() do data[i] = c_ignore end
        fillers[spec.kind](spec, area, id, origin)

        manip:set_data(data)
        manip:write_to_map()

        a = aend + 1
    end

    return total

end
