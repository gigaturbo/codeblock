cube(40, 40, 40, glass.cyan, true)
move(11, 7, 3)
dir = vector(1, 1, 1)

while true do

  if is_block("air", dir:unpack()) then
    place(air)
    move(dir:unpack())
    place(lamps.yellow)
    sleep(0.03)
  end

  if (not is_block("air", vector.x:unpack())) or (not is_block("air", vector.nx:unpack())) then
    dir.x = -dir.x
  end

  if (not is_block("air", vector.y:unpack())) or (not is_block("air", vector.ny:unpack())) then
    dir.y = -dir.y
  end

  if (not is_block("air", vector.z:unpack())) or (not is_block("air", vector.nz:unpack())) then
    dir.z = -dir.z
  end

end
