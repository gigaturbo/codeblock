function wavy_donut(r, R, H, block)

    save('origin')

    local v
    local vy = vector.y
    local vz = vector.z
    local visited = {}
    local h = round0(0.5 * r)
    for x = -R - r, R + r do
        visited[x] = {}
        for y = -r - h, r + h do
            visited[x][y] = {}
            for z = -R - r, R + r do visited[x][y][z] = false end
        end
    end

    for A = 0, 2 * pi, 1 / (R + r) / 2 do
        for a = 0, 2 * pi, 1 / r do

            v = vector.fromPolar(r, a):rotate_around(vz, pi / 2):offset(0, 0, R)
            v = v:rotate_around(vy, A):offset(0, r * 0.5 * sin(H * A), 0)
                    :round()

            if not visited[v.x][v.y][v.z] then
                place_relative(v.x, v.y, v.z, block, 'origin')
                visited[v.x][v.y][v.z] = true
            end

        end

    end

    go('origin')

end

--

local r = 6
local R = 15

save('grid')
local h = 3
for nx = 0, 2 do
    for nz = 0, 2 do
        go('grid', nx * 2 * (R + r + 2) + 30, 2 * r, nz * 2 * (r + R + 2))
        wavy_donut(r, R, h, color(h))
        h = h + 1
    end
end
