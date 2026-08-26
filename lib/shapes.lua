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
        return o, o, {x = o.x + s.w, y = o.y + s.h, z = o.z + s.l}
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
        local p1 = {[a] = p[a], [o1] = p[o1] - r, [o2] = p[o2] - r}
        local p2 = {[a] = p[a] + s.l, [o1] = p[o1] + r, [o2] = p[o2] + r}
        return p, p1, p2
    end

}

-------------------------------------------------------------------------------
-- fillers
--
-- Each writes only the part of the shape inside the area it is handed, which is
-- one z slab of it. The clip comes from the area rather than from a range passed
-- in, so it is exactly the extent `data` covers - the invariant that has to hold
-- whatever build() slices the shape into.
-------------------------------------------------------------------------------

--- A sphere between `ymin` and `r`. A dome is the half of one above its centre.
local function ball(s, area, id, o, ymin)

    local r, hollow = s.r, s.hollow
    local ystride, zstride = area.ystride, area.zstride
    local mn = area.MinEdge
    local ox, oy, oz = o.x - mn.x, o.y - mn.y, o.z - mn.z

    -- Squared-radius window: inside the outer surface, and for a hollow shape
    -- not so far inside that it is buried. r*(r+1) and r*(r-1) rather than r*r
    -- give a shell one voxel thick with no gaps.
    local rmin, rmax = r * (r - 1), r * (r + 1)

    for z = max(-r, mn.z - o.z), min(r, area.MaxEdge.z - o.z) do
        local iz = (z + oz) * zstride + 1
        for y = ymin, r do
            local iy = iz + (y + oy) * ystride
            for x = -r, r do
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
        local mn = area.MinEdge
        local ox, oy, oz = o.x - mn.x, o.y - mn.y, o.z - mn.z

        for z = max(0, mn.z - o.z), min(l - 1, area.MaxEdge.z - o.z) do
            local iz = (oz + z) * zstride + 1
            for y = 0, h - 1 do
                local iy = iz + (oy + y) * ystride
                for x = 0, w - 1 do
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

        -- Ranges by axis, so the z clip lands on whichever of the three loops
        -- runs along z - the length for a cylinder lying that way, a radius for
        -- one lying across it.
        local lo = {[a] = 0, [o1] = -r, [o2] = -r}
        local hi = {[a] = s.l - 1, [o1] = r, [o2] = r}
        lo.z = max(lo.z, mn.z - o.z)
        hi.z = min(hi.z, area.MaxEdge.z - o.z)

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

    -- Slabs of whole mapblocks along z. Whole blocks because the engine emerges
    -- them whole anyway: a slab boundary inside a block would emerge and charge
    -- that block twice. Along z because it is the outermost loop of every
    -- filler, so a slab stays one contiguous run of the data array.
    local across = span(pos1.x, pos2.x) * span(pos1.y, pos2.y)
    local layers = floor(SLICE_BLOCKS / across)
    if layers < 1 then layers = 1 end

    c_ignore = c_ignore or get_content_id('ignore')
    local id = get_content_id(spec.node)
    local total = 0
    local z = pos1.z

    while z <= pos2.z do

        -- Last node of the last whole mapblock in this slab.
        local zend = min((floor(z / 16) + layers) * 16 - 1, pos2.z)
        local emerged = across * span(z, zend)

        -- Before the pass, not after: the caller pays for the memory before it
        -- is pinned, and can make the drone wait for room first.
        if spec.charge then spec.charge(emerged) end
        total = total + emerged

        local manip = get_voxel_manip()
        local emin, emax = manip:read_from_map({
            x = pos1.x,
            y = pos1.y,
            z = z
        }, {x = pos2.x, y = pos2.y, z = zend})
        local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

        for i = 1, area:getVolume() do data[i] = c_ignore end
        fillers[spec.kind](spec, area, id, origin)

        manip:set_data(data)
        manip:write_to_map()

        z = zend + 1
    end

    return total

end
