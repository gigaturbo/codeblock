function plot2D(XMIN, XMAX, ZMIN, ZMAX, FMIN, FMAX, NPOINTS, SIZE, fun)

    local increment = (XMAX - XMIN) / (NPOINTS - 1)

    local rx, ry, rz, y
    for x = XMIN, XMAX, increment do
        for z = ZMIN, ZMAX, increment do

            y = fun(x, z)

            rx = (x - XMIN) / (XMAX - XMIN) * SIZE
            ry = 0
            rz = (z - ZMIN) / (ZMAX - ZMIN) * SIZE

            place_relative(rx, ry, rz, color(y, FMIN, FMAX))

        end
    end
end

fun = function(x, z) return cos(x + pi / 2) * sin(z) end

plot2D(-2 * pi, 2 * pi, -2 * pi, 2 * pi, -1, 1, 101, 100, fun)
