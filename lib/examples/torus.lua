local r = 10
local R = 30

up(R + r)
save('o')

local v
local vy = vector.y
local vz = vector.z
local vx = vector.x
for A = 0, 2 * pi, 1 / (R + r) / 2 do
    for a = 0, 2 * pi, 1 / r do
        v = vector.fromPolar(r, a):rotate_around(vz, pi / 2):offset(0, 0, R)
        v = v:rotate_around(vy, A)
        place_relative(v.x, v.y, v.z, colors.apricot, 'o')
    end

end

for A = 0, 2 * pi, 1 / (R + r) / 2 do
    for a = 0, 2 * pi, 1 / r do
        v = vector.fromPolar(r, a):offset(0, 0, R)
        v = v:rotate_around(vx, A):offset(0, 0, R)
        place_relative(v.x, v.y, v.z, colors.ink, 'o')
    end
end
