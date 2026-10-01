function recursion(checkpoint, block_list, MAX_DEPTH, depth)

    local depth = depth or 1

    if depth > MAX_DEPTH then return end

    for j = 1, 4 do
        for i = 1, 10 do

            up(1)
            forward(1)
            place(block_list[(depth % #block_list) + 1])

        end

        save(checkpoint .. j .. depth)
        recursion(checkpoint .. j .. depth, block_list, MAX_DEPTH, depth + 1)
        go(checkpoint)
        turn_left()
        save(checkpoint)

    end

end

---

save('origin')
local mblocks = {
    colors.hex('#808080'), colors.hex('#a5672e'),
    colors.hex('#101010'), colors.hex('#f3e583')
}
recursion('origin', mblocks, #mblocks)
