local R = 30

up(R * 2)
save('center')
centered.sphere(R, wools.grey)
centered.sphere(R - 1, wools.black)

local r, pos
for i = 1, R do
    r = random(round0(R / 3), round0(R / 2))
    pos = vector.srandom(1, 1):scale(R + 0.90 * r)
    go('center', pos.x, pos.y, pos.z)
    centered.sphere(r, blocks.air)
end

local v
for i = 1, round0(R * R / 3) do
    v = vector.prandom(round0(R * 2), round0(R * 3)):rotate_around(vector.xz, pi / 6)
    go('center', v.x, v.y, v.z)
    centered.sphere(random(1, 2), blocks.obsidian)
end
