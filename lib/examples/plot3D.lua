function plot3D(XMIN, XMAX, ZMIN, ZMAX, FMIN, FMAX, NPOINTS, SIZE, fun)

    local visited = {}
    local increment = (XMAX - XMIN) / (NPOINTS - 1)
    local rx, ry, rz, y, i
    for x = XMIN, XMAX, increment do
        for z = ZMIN, ZMAX, increment do

            y = fun(x, z)

            rx = round0((x - XMIN) / (XMAX - XMIN) * SIZE)
            ry = round0((y - FMIN) / (FMAX - FMIN) * SIZE / 2)
            rz = round0((z - ZMIN) / (ZMAX - ZMIN) * SIZE)

            i = (rx - XMIN) / NPOINTS + (ry - FMIN) / NPOINTS * NPOINTS +
                    (rz - ZMIN) / NPOINTS * NPOINTS * NPOINTS + 3
            if not visited[i] then
                place_relative(rx, ry, rz, ramp.hues(y, FMIN, FMAX))
                visited[i] = true
            end

        end
    end
end

fun = function(x, z) return cos(x + pi / 2) * sin(z) end

plot3D(-2 * pi, 2 * pi, -2 * pi, 2 * pi, -1, 1, 300, 100, fun)
