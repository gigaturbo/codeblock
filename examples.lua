codeblock.examples = {}

codeblock.examples.example1 = [[
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

codeblock.examples.example2 = [[
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

codeblock.examples.example3 = [[
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