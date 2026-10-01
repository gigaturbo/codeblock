local S = 10

while true do
    for i = 1, S do
        centered.sphere(i, lamps[random.hues()], true)
        sleep(0.1)
    end

    for i = S, 1, -1 do
        centered.sphere(i, air, true)
        sleep(0.1)
    end
end
