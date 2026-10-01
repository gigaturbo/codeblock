function forest(radius)
    local function tree(HMIN, HMAX)

        local H = random(HMIN, HMAX)
        local W = random(floor(HMIN * 0.5), floor(HMIN * 0.6))
        local R = floor(W / 2)
        local D = 3

        cube(1, H, 1, colors.dark_orange)
        up(H)
        cube(W + 1, 1, 1, colors.dark_orange)
        right(W)
        down(D)
        cube(1, D, 1, colors.dark_orange)

        move(-R, -2 * R, -R)
        sphere(R, lamps.light_yellow)
        sphere(R, colors.green, true)
    end

    --

    local HMIN = 8
    local HMAX = 12
    local SPACING = floor(HMAX * 0.6 * 2.2)

    save('o')
    for i = -radius, radius, SPACING do
        for j = -radius, radius, SPACING do

            if sqrt(i * i + j * j) < radius then
                go('o')
                move(i + random(-5, 5), 0, j + random(-5, 5))
                turn(random(0, 3))
                tree(HMIN, HMAX)
            end

        end
    end

end

forest(100)
