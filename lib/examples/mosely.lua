function mosely(size, block)

    local empty_pos = {}
    local solid_pos = {}
    local s, m, M
    for nx = 0, 2, 1 do
        for ny = 0, 2, 1 do
            for nz = 0, 2, 1 do
                s = nx + ny + nz
                m = min(nx, ny, nz)
                M = max(nx, ny, nz)
                if s == 0 or s == 6 or (s == 2 and M == 2) or
                    (s == 3 and M == 1) or (s == 4 and m == 0) then
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
            cube(inc, inc, inc, blocks.air)
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

up()
mosely(pow(3, 3), blocks.snowblock)
