save("home")
cube(30, 10, 50, colors.dark_grey, true)
up(9)
cube(30, 1, 50, air)
go("home", 15, 1, 25)
dir = vector(1, 0, 1)

while 1 == 1 do

  if get_block(dir:unpack()) == "air" then

    place(air)
    move(dir:unpack())
    place(lamps.yellow)
    sleep(0.03)

  else

    if get_block(vector.x:unpack()) ~= "air" or get_block(vector.nx:unpack()) ~= "air" then
      dir.x = -dir.x
    end
    if get_block(vector.z:unpack()) ~= "air" or get_block(vector.nz:unpack()) ~= "air" then
      dir.z = -dir.z
    end

    place(air)
    move(dir:unpack())
    place(lamps.yellow)

  end

end
