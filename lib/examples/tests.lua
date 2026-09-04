local funs = {
    function() place(colors.ink) end,
    function() place_relative(1, 1, 1, colors.cyan, _) end,
    function() cube(_, _, _, colors.yellow) end,
    function() sphere(_, colors.green) end, function() dome(_, colors.blue) end,
    function() vertical.cylinder(_, _, colors.red) end,
    function() horizontal.cylinder(_, _, colors.orange) end,
    function() centered.vertical.cylinder(_, _, colors.white) end,
    function() centered.horizontal.cylinder(_, _, colors.magenta) end,
    function() centered.cube(_, _, _, colors.black) end,
    function() centered.sphere(5, colors.pink) end,
    function() centered.dome(5, colors.violet) end
}

for _, fun in ipairs(funs) do
    fun()
    right(15)
end

move(1, 1, 1)
forward(5)
back(6)
left(2)
right(3)
up(6)
down(1)
turn_left()
turn_right()
turn(4)
save('chk')
go('chk')
