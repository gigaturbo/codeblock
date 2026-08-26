-- Deliberately empty.
--
-- codeblock's mod.conf hard-depends on `default`, but it calls no function from
-- it and borrows no texture or sound: the only use is the 121 node names in the
-- palette tables of lib/config.lua. The in-engine specs never place a node -
-- integration_spec stubs `place`, shapes_spec stubs `get_content_id` - so
-- nothing here needs registering for them to run.
--
-- Register a node here only if a spec is added that genuinely needs one.

-- The one exception. The engine validates these three aliases at startup
-- whatever the mapgen is, and an unset alias logs an ERROR on every run. The
-- harness greps stderr for errors, so a permanent one there would hide a real
-- failure. singlenode generates nothing, so what they point at is immaterial.
minetest.register_alias('mapgen_stone', 'air')
minetest.register_alias('mapgen_water_source', 'air')
minetest.register_alias('mapgen_river_water_source', 'air')
