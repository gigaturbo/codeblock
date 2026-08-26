local funs = {
    function() place(blocks.obsidian) end,
    function() place_relative(1, 1, 1, wools.cyan, _) end,
    function() cube(_, _, _, wools.yellow) end,
    function() sphere(_, wools.green) end, function() dome(_, wools.blue) end,
    function() vertical.cylinder(_, _, wools.red) end,
    function() horizontal.cylinder(_, _, wools.orange) end,
    function() centered.vertical.cylinder(_, _, wools.white) end,
    function() centered.horizontal.cylinder(_, _, wools.magenta) end,
    function() centered.cube(_, _, _, wools.black) end,
    function() centered.sphere(5, wools.pink) end,
    function() centered.dome(5, wools.violet) end
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
