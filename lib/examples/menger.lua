function menger(size, block)

    local empty_pos = {}
    local solid_pos = {}
    for nx = 0, 2, 1 do
        for ny = 0, 2, 1 do
            for nz = 0, 2, 1 do

                if (nx == ny and nx == 1) or (ny == nz and nz == 1) or
                    (nz == nx and nx == 1) then
                    empty_pos[#empty_pos + 1] = {nx, ny, nz}
                else
                    solid_pos[#solid_pos + 1] = {nx, ny, nz}
                end

            end
        end
    end

    local function recursion(size, x, y, z)

        local inc = floor(size / 3)
        if size == 1 then return end

        for _, n in ipairs(empty_pos) do
            go('origin', x + n[1] * inc, y + n[2] * inc, z + n[3] * inc)
            cube(inc, inc, inc, air)
        end

        for _, n in ipairs(solid_pos) do
            recursion(inc, x + n[1] * inc, y + n[2] * inc, z + n[3] * inc)
        end

    end

    save('origin')
    cube(size, size, size, block)
    recursion(size, 0, 0, 0)
    go('origin')

end

--

local sizes = {pow(3, 3), pow(3, 2), pow(3, 1), pow(3, 0)}

up()
for i, size in ipairs(sizes) do menger(size, color(i, 1, #sizes)) end
