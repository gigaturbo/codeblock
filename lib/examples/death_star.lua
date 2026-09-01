local R1 = 25
local R2 = R1

local mvt = vector(-1, -1, -1)
local pos = mvt:scale(0.95 * (R1 + R2)):floor()

up(2 * R1 + R2)
save('center')
centered.sphere(R1, wools.grey)
centered.sphere(R1 - 1, wools.cyan)

move(pos.x, pos.y, pos.z)
centered.sphere(R2, blocks.air)

go('center')
for i = 1, 2 * R1 + R2, 1 do
    centered.sphere(2, blocks.meselamp)
    move(mvt.x, mvt.y, mvt.z)
end
