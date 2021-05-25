codeblock.examples = {}

codeblock.examples.recursion = [[
    function recursion(checkpoint, block_list, MAX_DEPTH, depth)

        local depth = depth or 1
    
        if depth > MAX_DEPTH then return end
    
        for j = 1, 4 do
            for i = 1, 10 do
    
                up(1)
                forward(1)
                place(block_list[(depth % #block_list) + 1])
    
            end
    
            save(checkpoint .. j .. depth)
            recursion(checkpoint .. j .. depth, block_list, MAX_DEPTH, depth + 1)
            go(checkpoint)
            turn_left()
            save(checkpoint)
    
        end
    
    end
    
    ---
    ---
    
    save('origin')
    local mblocks = {blocks.stone, blocks.dirt, blocks.obsidian, blocks.sandstone}
    recursion('origin', mblocks, #mblocks)    
]]

codeblock.examples.density = [[
local R = 10
local YMAX = 100

local scale_density = function(f, MIN, MAX)
    return function(x) return (f(x) - MIN) / (MAX - MIN) end
end

local f = function(x) return pow(x, 2) end
local density = scale_density(f, f(0), f(YMAX))

save('o')
for x = -R, R do
    for y = 0, YMAX do
        for z = -R, R do

            if (pow(x, 2) + pow(z, 2) < pow(R, 2)) then
                if random() < density(y) then
                    place_relative(x, y, z, blocks.stone, 'o')
                end
            end

        end
    end
end
]]

codeblock.examples.spirals = [[
    function spiral(TURNS, MAX_RADIUS, MAX_Y, BLOCK, ORIGIN)

        local increment = 0.01
    
        for a = 0, 2 * pi * TURNS, increment do
    
            local R = a / (2 * pi * TURNS) * MAX_RADIUS
            local x = R * cos(a)
            local y = a / (2 * pi * TURNS) * MAX_Y
            local z = R * sin(a)
    
            place_relative(x, y, z, BLOCK, ORIGIN)
            left()
            place(BLOCK)
            right()
            place(BLOCK)
            forward()
            place(BLOCK)
            back()
            place(BLOCK)
    
        end
    
    end
    
    --
    
    local mblocks = {
        blocks.sandstone, blocks.silver_sandstone, blocks.desert_sandstone
    }
    
    for i = 1, #mblocks do
        spiral(5, 25, 100, mblocks[i % (#mblocks + 1)], 'spiral' .. i)
        go('spiral' .. i)
        right(50)
    end
]]


codeblock.examples.plot2D = [[
    function plot2D(XMIN, XMAX, ZMIN, ZMAX, FMIN, FMAX, NPOINTS, f)

        local increment = (XMAX - XMIN) / (NPOINTS - 1)
    
        for nx = 1, NPOINTS do
            for nz = 1, NPOINTS do
                local x = XMIN + ((nx - 1) * increment)
                local z = ZMIN + ((nz - 1) * increment)
                local y = f(x, z)
    
                local color = floor((y - FMIN) / (FMAX - FMIN) * (#iwools - 1))
                local block = iwools[(color % #iwools) + 1]
    
                place_relative(nx - 1, 0, nz - 1, block)
            end
        end
    end
    
    f = function(x, z) return cos(x + pi / 2) * sin(z) end
    
    plot2D(-2 * pi, 2 * pi, -2 * pi, 2 * pi, -1, 1, 100, f)    
]]

codeblock.examples.plot3D = [[
    function plot3D(XMIN, XMAX, ZMIN, ZMAX, FMIN, FMAX, NPOINTS, H, f)

        local increment = (XMAX - XMIN) / (NPOINTS - 1)
    
        for nx = 1, NPOINTS do
            for nz = 1, NPOINTS do
                local x = XMIN + ((nx - 1) * increment)
                local z = ZMIN + ((nz - 1) * increment)
                local y = f(x, z)
                local h = floor((y - FMIN) / (FMAX - FMIN) * H)
    
                local color = floor((y - FMIN) / (FMAX - FMIN) * (#iwools - 1))
                local block = iwools[(color % #iwools) + 1]
    
                place_relative(nx - 1, h, nz - 1, block)
            end
        end
    end
    
    f = function(x, z) return cos(x + pi / 2) * sin(z) end
    
    plot3D(-2 * pi, 2 * pi, -2 * pi, 2 * pi, -1, 1, 100, 100, f)    
]]

codeblock.examples.menger = [[
    function menger(size, block)

        local function recursion(size, x, y, z)
    
            local inc = floor(size / 3)
    
            save(size)
    
            if size == 1 then return end
    
            for nx = 0, size - 1, inc do
                for ny = 0, size - 1, inc do
                    for nz = 0, size - 1, inc do
    
                        if (nx == ny and nx == inc) or (ny == nz and nz == inc) or
                            (nz == nx and nx == inc) then
                            go(size)
                            move(x + nx, y + ny, z + nz)
                            cube(inc, inc, inc, blocks.air)
                        else
                            go(size)
                            recursion(inc, x + nx, y + ny, z + nz)
                        end
    
                    end
                end
            end
    
        end
    
        cube(size, size, size, block)
        recursion(size, 0, 0, 0)
    
    end
    
    --
    
    local sizes = {pow(3, 1), pow(3, 2), pow(3, 3), pow(3, 4)}
    
    up()
    for i, s in ipairs(sizes) do
        menger(s, iwools[i])
        right(s + 3)
    end  
]]

-- codeblock.examples.exampleN = [[
  
-- ]]