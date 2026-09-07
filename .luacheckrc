-- Luacheck configuration for CodeBlock.
--
--   luacheck .
--
-- This mod is developed in its own repository and shipped as its own ContentDB
-- package, so it owns its own lint and test run. The Codecube game that embeds
-- it has a separate, integration-level CI which deliberately does NOT re-lint
-- this directory.

std = "lua51"
cache = true
codes = true

-- Formatting is handled by the existing lua-format style; don't fight it.
max_line_length = false

-- Engine callbacks have signatures fixed by Luanti - on_step(self, dtime,
-- moveresult), on_punch(self, puncher, time_from_last_punch, ...) - and must
-- declare every parameter whether the body uses it or not. Reporting those as
-- unused is noise: all 10 findings in the first clean CI run were exactly this,
-- in lib/drone_entity.lua. Unused *locals* are still reported.
unused_args = false

-- Baseline exemptions, disabled when LUACHECK_STRICT is set so CI can report
-- what they hide without the build depending on it. Everything NOT listed here
-- is a hard failure, so new classes of defect still break the build.
ignore = os.getenv("LUACHECK_STRICT") and {} or {
    -- 412: "shadowing argument". The normalisation idiom used throughout is
    --   local n = (type(n) == 'number') and round0(n) or 1
    -- which deliberately shadows the parameter to coerce it in place. There are
    -- 36 of these, 34 in lib/commands.lua alone. Consolidating them is audit
    -- finding A3 (movement/placement de-duplication); until then, flagging every
    -- one drowns out real findings.
    "412",
    -- 411/421/431: the same shadowing pattern applied to locals and upvalues,
    -- from the same idiom. Revisit together with 412 under A3.
    "411", "421", "431",
    -- 213: unused loop variable, e.g.
    --   for i, filename in ipairs(meta.tabs) do meta.active = i end
    -- in lib/formspecs.lua, which is a convoluted way to write #meta.tabs and is
    -- already called out under audit finding A1's editor rewrite.
    "213",
    -- 611/612/613/614: whitespace-only findings. There are 61 across 16 files,
    -- left behind by the existing lua-format style. That is a formatter's job,
    -- not a linter's - consistent with max_line_length above. Fold into a
    -- formatter pass once the Phase 2/3 rewrites have landed.
    "611", "612", "613", "614"
}

-- The engine namespace and the globals our dependencies publish.
read_globals = {
    -- Luanti / Minetest engine
    "core", "minetest", "dump", "dump2", "vector", "ItemStack", "VoxelManip",
    "VoxelArea", "PseudoRandom", "PcgRandom", "PerlinNoise", "PerlinNoiseMap",
    "ValueNoise", "ValueNoiseMap", "SecureRandom", "Settings", "AreaStore",
    "Raycast", "ItemStackMetaRef", "DEFAULT_ALLOW_MOVE", "INIT",
    -- declared dependencies (see mod.conf)
    "vector3",
    -- Lua 5.1 / LuaJIT builtins that luacheck's lua51 std can miss
    "jit"
}

-- Our own mod namespace is written across many files by design.
globals = {"codeblock"}

exclude_files = {
    -- Toolchain, not source. gh-actions-luarocks installs into .luarocks/
    -- inside the workspace, and luacheck would otherwise lint luafilesystem's
    -- own test suite and luarocks' generated config.
    ".luarocks/**",
    ".install/**",
    ".lua/**",
    -- The vector3 dependency, vendored as a submodule so the in-engine specs
    -- have a game to boot in. Third-party, and not ours to restyle.
    "tests/game/mods/vector3/**"
}

files["tests/**"] = {
    -- The spec is written to run standalone too, so it touches arg/io/os.
    read_globals = {"arg"}
}

-- The shipped example programs are *player* code: they run inside the sandbox
-- environment built by lib/sandbox.lua, not in a Luanti mod environment. Given
-- their own std, luacheck will catch typo'd API names and stray globals in the
-- examples - which is exactly the drift described in audit finding A2.
--
-- This list is a mirror of lib/api.lua and nothing but: it must name every
-- described API name and nothing else. scripts/gen_docs.lua --check compares
-- the two in both directions and fails CI on a difference (C22) - so an entry
-- that is *not* an API name goes in the files[] block below, not here.
--
-- A bare string accepts any field of that name, which is what `table` and
-- `vector` need; a name whose fields are all described is spelled out, so a
-- typo in an example is caught.
stds.codeblock_sandbox = {
    read_globals = {
        -- movement
        "move", "forward", "back", "left", "right", "up", "down",
        "turn_left", "turn_right", "turn", "sleep",
        -- placement
        "place", "place_relative", "default_block",
        "cube", "sphere", "dome", "cylinder",
        vertical = {fields = {"cylinder"}},
        horizontal = {fields = {"cylinder"}},
        centered = {
            fields = {
                "cube", "sphere", "dome", "cylinder",
                vertical = {fields = {"cylinder"}},
                horizontal = {fields = {"cylinder"}}
            }
        },
        -- checkpoints
        "save", "go",
        -- blocks
        "colors", "glass", "lamps", "air",
        -- The four palette views: arrays of colour names, one axis of the
        -- palette against the category's material.
        "hues", "light_hues", "dark_hues", "neutrals",
        -- One ramp per block category, plus the generic one over any array.
        -- Spelled out rather than left open, so a typo in an example is caught;
        -- a category a game registers gets a ramp too, but no example can name
        -- one.
        ramp = {fields = {"hues", "colors", "glass", "lamps", "of"}},
        -- utilities. `table` and `vector` are left open: a program sees the
        -- whole standard library and the whole vector3 module through them,
        -- and only table.randomizer is an API name of ours.
        "get_block", "is_block", "print", "ipairs", "pairs", "table", "vector",
        "error",
        random = {fields = {"color", "glass", "lamp"}},
        -- math
        "floor", "ceil", "round", "round0", "deg", "rad", "exp", "log", "max",
        "min", "pow", "sqrt", "abs", "sin", "sinh", "asin", "cos", "cosh",
        "acos", "tan", "tanh", "atan", "atan2", "pi", "e"
    }
}

files["lib/examples/**"] = {
    std = "codeblock_sandbox",
    -- Added to the std above rather than listed in it: examples pass a bare `_`
    -- to mean "use the default for this argument", and it is never assigned, so
    -- it reads as nil by design. It is not an API name and the std holds
    -- nothing but API names.
    read_globals = {"_"},
    -- Player code runs under setfenv with its own environment table, so a
    -- top-level `function foo()` is a normal, working way to declare a helper -
    -- it just lands in the sandbox env rather than the real _G. Eight examples
    -- do this (menger, forest, recursion, plot2D, ...), often recursively.
    allow_defined_top = true,
    -- 212/213: player programs legitimately use short throwaway names.
    -- 431/432: menger.lua and mosely.lua declare an inner
    --   local function recursion(size, x, y, z)
    -- inside an outer function that also takes `size`. The shadowing is
    -- deliberate and correct - the helper is called both with a subdivided size
    -- and with the outer one - and `size` is the clearest name for a teaching
    -- example, so renaming it to silence the warning would make it worse.
    ignore = {"212", "213", "431", "432"}
}
