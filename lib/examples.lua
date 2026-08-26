codeblock.examples = {}

-------------------------------------------------------------------------------
-- local
-------------------------------------------------------------------------------

local get_dir_list = minetest.get_dir_list
local path_join = codeblock.utils.path_join
local examples_path = path_join(codeblock.modpath, 'lib', 'examples')

-------------------------------------------------------------------------------
-- private
-------------------------------------------------------------------------------

--- Read every bundled example into memory, keyed by name without the extension.
--
-- One unreadable file is skipped with a warning rather than taken down the
-- whole mod: these are documentation, and the sandbox works without them. (B15)
local function read_examples_at_init()

    local examples = {}
    local files = get_dir_list(examples_path, false)
    table.sort(files)

    for _, filename in ipairs(files) do

        local file = io.open(path_join(examples_path, filename), 'rb')

        if not file then
            minetest.log('warning',
                         '[codeblock] cannot read example ' .. filename)
        else
            local content = file:read('*a')
            file:close()
            -- Anchored, so an example called `mylua.luaX` keeps its name
            -- instead of losing the substring from the middle of it.
            examples[filename:gsub('%.lua$', '')] = content
        end

    end

    return examples

end

-------------------------------------------------------------------------------
-- export
-------------------------------------------------------------------------------

codeblock.examples.examples = read_examples_at_init()
