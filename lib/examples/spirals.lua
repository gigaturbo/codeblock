function spiral(TURNS, MAX_RADIUS, MAX_Y, BLOCK)

    save('origin')

    local MAX_PHI = 2 * pi * TURNS

    local phi = 0
    local R, y, pos, lpos, p
    while phi < MAX_PHI do

        p = phi / MAX_PHI
        R = (p * (MAX_RADIUS - 0.5)) + 0.5
        y = p * MAX_Y
        pos = vector.fromCylindrical(R, phi, y):round()

        if pos ~= lpos then
            place_relative(pos.x, pos.y, pos.z, BLOCK, 'origin')
            lpos = pos
        end

        phi = phi + 1 / (2 * pi * R)

    end

    go('origin')

end

--

local mblocks = {
    colors.light_yellow, colors.light_grey, colors.orange
}

for i = 1, #mblocks do
    spiral(5, 25, 100, mblocks[i])
    right(50)
end
