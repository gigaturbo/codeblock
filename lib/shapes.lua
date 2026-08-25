--- The four bulk shapes a program can place.
--
-- One VoxelManip pass each: read the area, write node ids into the flat data
-- array, write it back. Ported from the WorldEdit fork this mod used to depend
-- on, keeping only cube, sphere, dome and cylinder.
--
-- The data array is filled with `ignore` first, which set_data leaves untouched
-- on write, so only the voxels the shape claims are changed.

codeblock.shapes = {}

local shapes = codeblock.shapes

local floor = math.floor
local get_voxel_manip = minetest.get_voxel_manip
local get_content_id = minetest.get_content_id

-- Resolved on first use rather than at load: content ids are only settled once
-- every mod has registered its nodes.
local c_ignore

local others = {x = {'y', 'z'}, y = {'x', 'z'}, z = {'x', 'y'}}

-- One scratch buffer for the whole mod, refilled per shape rather than
-- reallocated: a radius-20 sphere emerges around 100k voxels, and Luanti runs
-- mods on one thread so no two shapes are ever in flight at once. It keeps the
-- largest size it has been asked for.
local data = {}

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

    for z = -r, r do
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

        for z = 0, l - 1 do
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

        for i = 0, s.l - 1 do
            local ia = (oa + i) * sa
            for u = -r, r do
                local iu = ia + (u + oo1) * s1 + 1
                for v = -r, r do
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
function shapes.build(spec)

    local origin, pos1, pos2 = bounds[spec.kind](spec)

    local manip = get_voxel_manip()
    local emin, emax = manip:read_from_map(pos1, pos2)
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

    c_ignore = c_ignore or get_content_id('ignore')
    for i = 1, area:getVolume() do data[i] = c_ignore end
    fillers[spec.kind](spec, area, get_content_id(spec.node), origin)

    manip:set_data(data)
    manip:write_to_map()

end
