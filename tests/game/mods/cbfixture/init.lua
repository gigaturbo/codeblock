-- The three mapgen aliases and nothing else.
--
-- The engine validates them at startup whatever the mapgen is, and an unset
-- alias logs an ERROR on every run. scripts/run_tests.ps1 does not grep for
-- ERROR; its filter catches this one on the word `invalid`, which the alias
-- message happens to carry. So a permanent one there would fail every run.
-- singlenode generates nothing, so what they point at is immaterial.
--
-- This mod is what is left of the `default` and `wool` stubs that used to sit
-- beside it: codeblock no longer depends on either, so the only reason to have
-- a mod here at all is the three lines below. If a spec ever needs a real node,
-- register that one node and no more.

core.register_alias('mapgen_stone', 'air')
core.register_alias('mapgen_water_source', 'air')
core.register_alias('mapgen_river_water_source', 'air')
