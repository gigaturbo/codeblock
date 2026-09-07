# TODO

The inbox and the wanted-features list for the CodeBlock mod. One line each,
mostly features. The author writes here; `project-manager` rewords a line when a
discussion changes what it means, and adds the lines that come out of an answer.

**A `FIX:` or `BUG:` line here is a hand-off.** It gets a finding id in
`AUDIT.md`, with the reasoning and the state; the line stays here until the
author deletes it. What the work involves is in `ROADMAP.md`; what shipped is in
`CHANGELOG.md`. Completed items are not kept here — they are in those two files.

Finding ids are never renumbered. `F` ids are features, this project's own.

# v1.0.0

Features

- [x] FEAT: Make a UI for drone info : running or not, blocks placed, allow pause,
      start, cancel, etc — includes showing the program's budget while it runs,
      not just its totals at the end — shipped as `F4`, made readable by `F8`,
      and playtested 2026-09-02: eight of nine `H` checks pass. The three
      wordings that run asked for are `F9` below (audit F4, F8)
- [x] FEAT: the panel and HUD in the words asked for on 2026-09-02 — HUD `CPU`
      becomes *CPU time* / *Temps CPU*; the idle panel reads `<program> :
      inactif` like the running one; the heading carries the run's clock time,
      `<program> : <state> (<duration>)` — shipped the same day with four gates
      green, the duration bold and just after the state on your second look;
      playtest `F9-1` passed 2026-09-02 at `029fab9`, both languages (audit F9)
- [x] FEAT: stop the panel's elapsed clock while a run is paused — asked for
      2026-09-02 on seeing `F9` in a world, reversing that feature's decision
      that it should keep counting. Built the same day with four gates green:
      `Drone.elapsed_us` is now the one answer both the panel and the finish
      message read, and `Drone.toggle_pause` the only writer of `paused`.
      Playtested the same day: `F9-1` case 4, rewritten and passed (audit F9)
- [x] BUG: buttons on the drone panel are sometimes unresponsive, a second click
      needed. Cause confirmed in the engine source: the 0.5 s refresh makes the
      client destroy and rebuild every element, and a button's press lives on
      the object it destroys, so a click held across a refresh is dropped with
      no error. Fixed 2026-09-02 the way you asked: the beat is 1 s, HUD and
      panel together since they share the one constant. It halves the dropped
      window rather than closing it — about one click in ten, was one in five —
      so playtest H10 is what says whether that is enough (audit B47)
- [x] BUG: opening several programs marks every one but the active tab as
      modified, without a keystroke — reported 2026-09-03. `read_file` opened
      the file `'rb'`, so a CRLF file kept its `\r\n` while the client's textarea
      returns LF, and F7's dirty check compared unequal for anything still
      carrying its original line endings. All fourteen bundled examples are
      CRLF, which is why the four files you had already saved never showed the
      mark and `plot2D.lua` showed it every time. Fixed the same day, one line
      in `lib/filesystem.lua`, five gates green, **committed as 4179877**;
      playtest E16's new case passed 2026-09-03, so the fix is confirmed in a
      world (audit B48)
- [x] BUG: a block name that does not exist falls back to stone without an error
      — reported 2026-09-03. `blocks`, `plants` and `wools` are name-indexed, so
      `blocks.notablock` is just a missing key and reads nil, and `placement`
      cannot tell that nil from the one you get for a bare `place()`: the default
      block was substituted and nothing said so. It hit `place`,
      `place_relative` and all eight shape commands. Fixed the same day where the
      name is *read* rather than where the block is placed, so the message can
      name what you typed: `blocks`, `plants` and `wools` now warn **once per
      run** and the program carries on with the default block, since you asked
      for a warning and not an error. One accepted side effect —
      `if blocks[name] then` as a membership test costs one chat line per run.
      Gates green over the whole tree with 13 new env_spec cases, **committed as
      d8c32f7**, and playtest W4 passed 2026-09-03 at 16cd05c — so the
      once-per-run warning is confirmed in a world, which no spec could do
      (audit B49)
- [x] BUG: the drone disappears at codelevel 1 — reported 2026-09-03 from the W1
      re-run: `aaa.lua` places obsidian and brick along two 25-step lines, and
      after 6–8 seconds the drone vanished. No error, no refusal, and not the
      "cannot leave the world" stop. Filed as B50, and the cause is now read out
      of the engine source: the drone entity is `static_save = false`, so Luanti
      deletes it as soon as the mapblock under it leaves server memory, and
      nothing keeps the drone's *own* block loaded — only the block it writes
      into. Past about 192 nodes the client is no longer keeping it alive either.
      Time is what matters rather than distance, which is why levels 3 and 4
      finish before the engine's 2 s sweep ever sees them and why W1's old passes
      could not have caught it. **You chose the fix on 2026-09-03, and it is a
      fourth option rather than either of the two put to you: decouple the drone
      record from its entity**, so the step driver moves to the globalstep
      register.lua already has, `on_deactivate` only drops the view, and the
      entity comes back with the same serial when the block does. It closes B52
      as well, and it saves a sleeping or paused drone, which neither of the
      other options did. **Written and committed the same day as 1b991ae**, with
      the gates green — 474 in-engine assertions, 0 failed, 0 xpass — and
      **confirmed in a world on 2026-09-04 at 23f0227**: W1, W5 and W6 all
      passed, and they are the only evidence it will ever have. W1 passed **at
      every codelevel**, which no earlier run of it managed, so the levels that
      were unreported are reported. You also
      supplied a much better reproducer — `forward(500)` then `sleep(20)` kills
      it in one to two seconds every time, where the loop was a coin flip.
      Your two discriminator runs on 2026-09-03 confirmed it: both chat lines
      arrive, so nothing is being swallowed, and the obsidian stopped at 352 and
      320 nodes. That spread is the point — 192 is where the drone becomes
      killable rather than where it dies, and two runs 32 nodes apart is a
      sampled race. The observation that was owed is made: a new drone places
      straight after the program finishes, so a leaked record is ruled out
      rather than unlikely (audit B50; playtest W1, W5, W6)
- [x] BUG: a run that was cut short says "completed" — found 2026-09-03 while
      diagnosing B50, not reported. Drone.finish had no word for it, so a run you
      stopped from the drone panel said the program completed, with a node count
      nowhere near what it asked for. **You saw it**: your discriminator run
      showed "le drone a disparu" and then "programme terminé", one after the
      other, about a run killed 48 blocks short of the 50 it asked for. **Fixed
      2026-09-04**, with the word you chose: a cut-short run now says "stopped",
      "arrêté" in French, with the partial counts after it. **Committed at
      8de3cea and played the same day** — D7 passed, in both languages — so this
      one is closed in every sense. Your run also caught the record naming the
      setter as a way to cut a run short, which it has not been since F8; that
      is corrected in four places (audit B51; playtest D7)
- [x] BUG: a drone standing still far from you dies at about 29 seconds — found
      2026-09-03 the same way. It survives most fixes to B50 — `load_area` does
      not reset the mapblock's usage timer, so the block is unloaded on
      `server_unload_unused_data_timeout` regardless of the drone standing in it.
      `sleep(30)` out at 300 nodes, or a run left paused, both reach it — and
      both are things the mod invites you to do. **The fix you chose for B50
      does close it**, which is one of the two reasons it was chosen over the
      others, and it is **committed as 1b991ae**; playtest W5 is the check this
      has never had, in either state, and it **passed 2026-09-04 at 23f0227**,
      both cases — so the fixed behaviour is observed while the defect itself
      never was (audit B52)
- [x] BUG: "default file doesn't work anymore" — reported 2026-09-07. The
      program a new file starts with said `place(blocks.obsidian)`, and F11 had
      deleted the `blocks` category and every `default:` node three days
      earlier, so **every file created with `+` or Enter since 2026-09-04 failed
      on its first statement**. Nothing caught it because the template is player
      code inside a Lua string: nothing lints, compiles or generates it. **Fixed
      the same day at de3bcbb**, and not by renaming the colour — the template
      now reads `for i = 1, #hues do place(hues[i]) up(1) end`, which names no
      individual colour and fits itself to whatever the palette holds, so the
      same rot cannot recur. Covered by four cases that read the template out of
      lib/formspecs.lua rather than copying it. **Playtest E17 passed
      2026-09-07** with the colours counted, which is this fix's only possible
      evidence (audit B53; playtest E17)
- [x] BUG: "the print function in the game cannot concatenate arguments" —
      reported 2026-09-07 while you were running F12-4, the first check here
      that made anyone want to print a boolean. `print` took exactly one
      parameter, so `print("is: ", is_block(colors.red))` printed `> is: ` and
      stopped with no error, and `print("is: " .. is_block(...))` raised
      *attempt to concatenate a boolean value*, which is correct Lua and not
      something to work around — so you were walled both ways. **Fixed the same
      day at 24842d3**, variadic like real Lua: the varargs are read with
      `select('#', ...)` so a nil in the middle of the list does not truncate
      it, which matters because `get_block()` answers nil over ungenerated map;
      they are joined with a space rather than Lua's tab, the chat console
      having no tab stops and the engine wrapping on spaces; `print()` alone
      sends a bare `> ` rather than nothing; and `error` was left alone, real
      Lua's not being variadic either. Twelve new spec cases pin that one call
      is one command however many arguments it carries — **and all twelve would
      have been green before the fix**, because what print puts in the chat is
      observable from no spec at all. **Playtest W7 passed 2026-09-07** — all
      three programs, and the space-joined line wrapping on a narrow console,
      which was the last part of the reasoning nothing had confirmed
      (audit B54; playtest W7, F12-4)
- [x] DECIDE: what to do with the untracked `lib/examples/game.lua` in your
      working tree — **answered 2026-09-07: track it**, committed at 63c3c33. It
      is a shipped example now, written into every player's directory by
      `/codeblock generate` alongside the other thirteen, and tracking it
      unblocked the second half of C23, which is closed. The file is the only
      shipped example that never terminates: it ends in `while 1 == 1 do` with no
      exit and runs until `max_runtime_s` stops it, and its `sleep(0.03)` is in
      the moving branch only, so a bounce runs at full speed. Both were flagged,
      neither is a defect, neither was changed (audit C23)
- [ ] FEAT: Make possible to change codelevel while running a program (audit F5)
- [x] FEAT: the mod brings its own blocks and drops the `default` and `wool`
      dependencies — settled 2026-09-04 as `F11` and **shipped in two passes**,
      d075742 and 6126abe. `mod.conf` is `depends = vector3`; the mod registers
      its own nodes, each colour as a solid, a glass and a lamp. `blocks`,
      `plants`, `wools` and `iwools` became `colors`, `glass`, `lamps`, `hues`
      and a top-level `air`, and `codeblock.register_blocks` lets a game add a
      category of its own in its own namespace. **All three open questions were
      settled:** `air` is a plain top-level name, the tile carried a faint grain
      (since reversed for the solids by `F12`), and each family's mid-tone is
      its plain word. Gates green over both passes and no finding filed.
      **Played 2026-09-07: eight of its ten live checks passed and no finding
      was filed against it.** F11-1 was run first and passed in both languages,
      so the editor does not have to leave legacy coordinates, and F11-3 passed,
      which is the whole point of the feature seen in a third-party game.
      F11-4 is retired, both its successors having passed. **F11-10 and F11-11
      then passed later the same day**, with the test mod at
      `../codeblock-test-mod`, so all ten live checks pass and the game-author
      path has in-world evidence — F11-11 being the rev_blocks fix's only
      possible one. **What is left is pushing, since CI has seen no part of
      it.** The shape and the decisions are in ROADMAP.md under `F11`
      (audit F11)
- [x] FEAT: a new palette, a ramp per block category, and coordinates for
      `get_block` — your five notes of 2026-09-06, shaped in one exchange and
      **shipped as `F12` at 01f9641** (with b752ea3 for your own example edits).
      The palette is the 35 colours you gave: five neutrals, then ten families
      `pink red orange yellow olive lime green cyan blue violet` in wheel order,
      each `light_x` / `x` / `dark_x` — 105 nodes. **The five neutral hexes are
      mine, not yours** — an even grey ramp, since you named them without
      values, and the easiest thing here to change. The solid tile is flat so
      each hex comes out exact, and the lamps got a faint grid.
      `color(v, min, max)` is gone with no alias, replaced by `ramp.hues` plus
      one ramp per category including a game's; only `ramp.hues` reads as a
      gradient, the others strobe, which follows from your own answer that every
      category gets one. `get_block(right, up, forward)` turns with the drone,
      moves nothing, and loads the map it reads, charged as footprint as you
      asked — `nil` still means never-generated or outside the world, and that
      one is permanent. Gates green, no finding filed. **All six of its checks
      passed on 2026-09-07**: four first time, F12-6 later the same day with the
      test mod, and F12-4 on a re-run after failing on the print defect above —
      so the rotation it exists for is observed at last. **F12-2
      passed and did not hand the flat-solid decision back** — the flat wall
      reads acceptably, so the tile stays and the exact hex is kept; that is now
      in ROADMAP.md's decisions log so it is not proposed again. The shape is in
      ROADMAP.md under `F12` (audit F12)
- [x] FEAT: `is_block(block, nx, ny, nz)` to check whether the block at a
      position is the one specified, offsets optional and defaulting to the
      drone's own block, in the *Choosing blocks* category — your words of
      2026-09-06, **shipped as `F13` at 4450ce1** with the parameter names made
      `get_block`'s (`n_right`, `n_up`, `n_forward`). It reads through
      `get_block`, so the map load, the footprint charge and the one-command
      cost are identical. `true` only on an exact match; **everything else is
      false**, including a name that does not exist — a query does not fall back
      to your default block the way `place()` does, and a misspelt name is
      already warned about once per run. **One thing you may want to decide:**
      that warning says *"the default block is used instead"*, which is not true
      when `is_block` asked it; rewording the key would orphan the French
      translation and it is right for `place()`, so it was left. Gates green.
      Its playtest folds into F12-3 and F12-4, **and both passed on 2026-09-07**
      — F12-3 first time, F12-4 on a re-run after the print defect above stopped
      it short — so is_block answering over real map and its offsets turning
      with the drone are both observed (audit F13)
- [x] FEAT: palette views and a generic ramp — `light_hues`, `dark_hues`,
      `neutrals` and `ramp.of(list, v, min, max)`, settled with you on
      2026-09-07 as `F14` and **shipped the same day with every gate green**.
      The point that decided its shape: a palette view is one axis and a block
      category is the other, and every category is indexed by the same short
      name — so `glass[h]` and `lamps[h]` turn any of the four arrays into a
      glass or lamp gradient, and four arrays give twelve gradients with no
      extra names. Your first reading, twelve arrays of blocks, is eleven names
      for what indexing already does; nested `colors.dark.red` tables were
      dropped as well, mostly because a game-registered category has no shade
      tiers and the shape would break the equal footing `F11` and `F12` gave it.
      `ramp.of` does not validate — ramp a list of your own if you like, and a
      non-table answers `nil` rather than stopping the program. The palette
      itself does not change. **One thing you did not ask for and now have:**
      `light_hues`, `dark_hues` and `neutrals` are three more names a game
      cannot use for a registered category. **All three in-world checks passed
      on 2026-09-07** — F14-1 the help panel, F14-2 that reading past the end of
      a view stays silent while a genuine misspelling still reports, F14-3 that
      a gradient through a view lands. **F14-2 is the one worth noting**: no
      spec can ever replace it, so that behaviour is now observed rather than
      reasoned. The shape, the four decisions and the gate figures are in
      ROADMAP.md under `F14` (audit F14)
- [ ] FEAT: `place(colorhex("#F7A8E7"))` — your question of 2026-09-07,
      **shaped as `F15` and deliberately not scheduled**. It is feasible but
      **not as an arbitrary colour**: nodes can only be registered at mod load,
      so what the engine offers is `paramtype2 = "color"` with a 256-pixel
      palette texture — one node carrying 256 colours indexed by `param2`.
      `colorhex` would therefore snap to the **nearest of 256**, and would have
      to say so. It is additive — three nodes and one PNG, the 105 stay — and
      the mod's flat white solid tile is exactly what a palette tints. The cost
      is `lib/shapes.lua`: a second full-size `set_param2_data` array per slab
      in the one path that has to stay fast, plus `get_block`/`is_block`
      learning to read `param2` and a picker that cannot list 256 × 3. Two
      questions are open on purpose — which 256 colours, and how the value
      reaches `place()`, whose one-string contract is load-bearing. The whole
      investigation is in ROADMAP.md under `F15`, written so nobody repeats it
      (audit F15)
- [ ] DECIDE: three exported functions in `lib/utils.lua` have no caller left —
      `table_reverse`, `table_convert_ik`, `table_convert_iv`. Found 2026-09-05
      while recording `F11`, which took the last caller of two of them. They are
      on `codeblock.utils`, a global this mod publishes, so a game could be
      reading them and deleting them is a silent breaking change to an
      unversioned surface. Either delete all three in v1.0.0, where breaking is
      free, or say `codeblock.utils` is public and keep them. Doing nothing keeps
      three dead functions and the question (audit A17)
- [x] FEAT: stop forcing the two tools into every joining player's inventory —
      settled 2026-09-03 as `F10`, your choice of the two: a command, not a
      setting. `set_tools` and its join callback go, the tools become droppable,
      and `/codeblock tools` hands them out on demand; `/codelevel` and
      `/codegenerate` become `/codeblock level` and `/codeblock generate` with
      no aliases, since the rename is free before the tag. A first-join chat
      line names the command and the creative inventory. Written into
      `lib/register.lua` with the gates green and **committed as b23a8bc**; all
      four of its playtest checks — F10-1 to F10-4 — passed 2026-09-03. The
      eight new French strings were written the same day, after you saw the chat
      line and the command replies come out in English, and **you read them in a
      world on 2026-09-04 — "F10: french works ok"**, which is the last thing
      this feature was owed. The shape and what was argued out are in ROADMAP.md
      under `F10`
      (no finding; from playtest D4 at `246bb37`)
- [x] FEAT: stop granting `fly`, `fast` and `noclip` to every new player — found
      while building `F10` on 2026-09-03, not reported: `register_on_newplayer`
      was granting all three in any game that installs this mod, the same shape
      as C18's sky and B39's inventory wipe. Removed outright rather than put
      behind a setting, which you declined: nothing here needs creative flight
      to be reachable. Filed as C21 on your say-so, fixed by F10 and **committed
      as b23a8bc**, gates green; confirmed in a world 2026-09-03 when you
      reported /privs on a fresh player showing none of the three, which was the
      only
      evidence this finding could ever have (audit C21)
- [x] CONTENTDB.md's Quick start tells the player they are given the two tools,
      which `F10` made false at b23a8bc. README.md had the same problem and has
      been rewritten with a step saying where the tools come from; CONTENTDB.md is
      left for the wording review you have pending, since you have an
      uncommitted edit to that line already. **Done 2026-09-03 at c2e541f**,
      with .cdb.json regenerated from it in the same commit
      (audit C19; F10)
- [ ] doc/api.md's Chat commands and Codelevel sections are hand-written and no
      check reads them — gen_docs.lua owns the file only from the `# Lua api`
      heading down. The gate said "up to date" while the file documented
      /codelevel and /codegenerate after F10 renamed them; fixed by hand the
      same day. Recorded in CLAUDE.md and ROADMAP.md as a property of the file,
      not closed — teaching the generator to write that region needs a source
      of truth for chat commands that does not exist (no finding)
- [ ] warn when the editor is closed with unsaved changes — `soe` is read, written
      and acted on nowhere; `F7` marks unsaved tabs first, which may be enough
      (audit F7)
- [x] a ContentDB long description that is not README.md — done 2026-08-28,
      CONTENTDB.md, with the shape you asked for. Revise the copy freely; edit
      that file and run scripts/gen_cdb_json.sh, never .cdb.json (audit C19)
- [x] fix CONTENTDB.md, which has drifted two features behind — the corner
      display "naming the one limit the run will actually stop on" (said twice)
      and the panel's "pause, resume, cancel and remove" both describe F4's
      displays, which F8 replaced with three coloured lines and with Stop plus
      Pause/Resume. Add F9's elapsed clock, then run scripts/gen_cdb_json.sh.
      Hand-kept against CHANGELOG.md and nothing checks the two agree, which is
      how it drifted silently. **Done 2026-09-03 at c2e541f**, together with the
      Quick start line above; it is still hand-kept, so it will drift again
      (audit C19)
- [ ] configure the ContentDB release webhook — trigger "Branch or tag
      creation", not push, because this project tags. The procedure is in the
      release-codeblock skill (no finding; from the author, 2026-08-28)
- [ ] the ContentDB URLs in README.md are on content.minetest.net, the
      pre-rename domain; it redirects but is stale (audit C19)
- [x] rework the screenshots and the ContentDB cover — done 2026-09-02:
      screenshots/mozaic.png and editor.png redone against the current editor,
      one stale 2021 file dropped. doc/dp.png and doc/ds.png became
      doc/drone_poser.png and doc/drone_setter.png for the wiki; README.md
      linked the old names five times and now points at the new ones. Nothing
      new needs a .gitattributes rule — doc/*.png and screenshots/ are both
      already excluded, and the archive still holds eleven top-level entries
      (no finding)
- [x] screenshot.png at the repo root — done 2026-09-02: the mosaic copied over
      it verbatim, so the Mods-tab cover is the current editor rather than one
      from four features ago. It costs what was predicted: the release archive
      is 2.21 MB, up from 1.48 MB and above the 1.60 MB the .gitattributes work
      trimmed. Your call and recorded as one; resize the cover rather than
      revert if that ever matters (no finding)
- [ ] screenshots/mozaic.png is now byte-identical to screenshot.png, so the
      repository carries the same 1.83 MB twice while only one copy ships.
      Dropping it would keep mozaic.xcf as the editable source and halve that in
      a clone — say if you want it gone (no finding)
- [ ] upload the new screenshots to the ContentDB package page — the files are
      loaded from raw GitHub URLs on master, so the page needs the new names
      and the dropped file removing (audit C19)

Decisions wanted from the author

- [x] expand the neutrals from five to ten shades black-to-white, with a naming
      convention or aliases — asked 2026-09-07 and **answered no the same day**,
      after seeing the `F15` feasibility: a 256-colour palette node gives a
      smooth greyscale and every other colour with it, so ten hand-named greys
      would be redundant. Both schemes are written into ROADMAP.md's decisions
      log so neither is proposed again — `grey_1`…`grey_10` with the five
      existing names kept as aliases onto the same flat keys, and ten
      hand-picked English names, argued against for having no guessable order.
      Either way, ten *even* steps moves the existing five hexes, so
      `colors.grey` would change shade in worlds already built (audit F15)
- [x] is `max_runtime_s` to come down? Yes, answered by doing it, 2026-09-02:
      `30 / 60 / 120 / 300`, with level 4's `max_nodes_written` `1e7` → `5e7`
      going the other way. A 387 s program spent about 18 s of server time, so
      2000 s of charged time was eleven hours of building. From playtest `H1`;
      the reasoning is in `ROADMAP.md` (no finding)
- [x] settingtypes.txt gets a generator and a --check, like doc/api.md and
      locale/template.txt — answered yes, 2026-08-28: "can have a generator if
      this simplifies and unify the process". Built 2026-09-02,
      scripts/gen_settingtypes.lua, with a CI step beside the other two. Writing
      it found C20: gen_docs.lua's own limit check had been matching nothing
      since it was written, Lua's %w excluding the underscore that every limit
      name has (audit C7, C17, C20)
- [x] Blockly is out of 1.0.0 — answered 2026-08-28 and made larger than that:
      it is v2.0.0 and Phase 10 on its own, with Phase 9 for v1.x.y in between
      (audit F6)

Checks left in a running world — the checklist is `PLAYTEST.md`

- [x] run H10 — passed 2026-09-02: a few presses in twenty still miss, and you
      called that acceptable. So B47 ships mitigated rather than closed, and the
      figure in "what ships broken" is what you counted rather than what the
      arithmetic predicted. The change that would close it outright — a panel
      that does not refresh itself, live figures left to the HUD — stays
      available; say the word if the misses annoy you in ordinary use rather
      than under a deliberate fast count (audit B47)
- [x] run F9-1 — passed 2026-09-02 at `029fab9`, all eight cases in both
      languages, and case 4 again after you asked for the opposite: it has now
      passed once each way round (audit F9)
- [x] run E16 — the unsaved-tab marker, new with F7: passed 2026-08-28 at
      `afbe504`, the day it shipped (audit F7)
- [x] re-run E16 for its new pristine-example case — passed 2026-09-03 on
      `b9143b0` plus the uncommitted tree, which confirms B48 in a world. The
      original run used a file it had typed into, which is LF on disk and cannot
      show the defect (audit B48, F7)
- [x] run F10-1's two unreported cases — passed 2026-09-03: the fresh
      player's inventory holds neither tool and `/privs` shows no `fly`, `fast`
      or `noclip`. That second one **confirms C21 in a world** and was the only
      evidence it could ever have, so all four F10-n checks now pass, and they
      were re-affirmed at 16cd05c once F10 was committed
      (audit C21; playtest F10-1)
- [x] run W4 — passed 2026-09-03 at 16cd05c: the unknown-block warning behaves,
      and it was the last check in PLAYTEST.md with no result. Case 2 — a second
      drone in the same session warning on its own account — is the only way the
      per-run scope is observable at all, since no spec can reach it (audit B49)
- [x] run H8 cases 2, 3 and 4 — 2 and 4 passed 2026-09-02; cases 1 and 3 are
      unperformable, a shown formspec holding the pointer, so no tool can be
      used while the panel is open. Case 3's mechanism moved into `forms_spec`
      (audit F8, B29)
- [x] run D2 case 2 — removed as untestable 2026-09-02, after two attempts. It
      is the only route to `B10`'s refusal, which now has none: reaching it
      needs a way to observe the server releasing a mapblock (audit B10)
- [x] build the release archive and install it once, to prove C16's guard —
      playtest R1 passed at `afbe504` and R2 at `7c5bceb`, both 2026-08-28
      (audit C16)
- [x] run W1 at codelevels 2, 3 and 4 — done 2026-09-04 at 23f0227, and level
      1 with them: W1 passed at every codelevel, the first run of that check to
      report above and below level 2 together (audit B50; playtest W1)
- [x] once the B50 fix is committed, run three checks: W1 again, W5 and W6 —
      done 2026-09-04 at 23f0227, all three passing, and the whole Writing to
      the world group with them. W5 and W6 had never run at all. That is B50
      and B52 confirmed in a world, and it takes both off the audit's "gates
      green, unproven in a world" list, which is now B14 and S7's log half
      (audit B50, B52; playtest W1, W5, W6)
- [x] play F11, F12, F13 and F14 in one session — done 2026-09-07 at 8e6350f,
      engine 5.17.0: **sixteen results, fifteen passes and one fail**, the
      largest run this project has had. The fail is F12-4 and its cause is the
      print defect above, not anything F12 or F13 does. Three passes settled
      questions the record was carrying: F11-1 (the selector returns the stored
      item, so no editor conversion), F12-2 (the flat solid tile stays) and
      F14-2 (silence past the end of a view, observed at last). **A second
      session the same day cleared the six checks it left**, at 2feadb1 over
      code 24842d3, with no defect reported — see the two lines below
      (audit B54; playtest F11-*, F12-*, F14-*)
- [x] run F11-10, F11-11 and F12-6 — done 2026-09-07, all three passing, with
      the mod at ../codeblock-test-mod, which stays outside this repository so
      it cannot change api.names() under the specs. **That is the game-author
      path's only in-world evidence**, and F11-11 is the rev_blocks fix's only
      possible evidence, so that fix is observed rather than
      correct-by-reading. F11-10 is lib/blocks.lua's only in-world evidence and
      its `mod ?` line read as intelligible rather than as a trap
      (audit F11, F12; playtest F11-10, F11-11, F12-6)
- [x] run E17 and W7, and re-run F12-4 on 24842d3 or later — done 2026-09-07,
      all three passing. E17 is B53's only check and the colours were counted;
      W7 is B54's and settled the space separator and the wrapping, which
      nothing else could; F12-4's re-run observed the rotation for the first
      time, its earlier fail having been against print
      (audit B53, B54; playtest E17, W7, F12-4)
- [ ] DECIDE: which contract player code gets for `vector`'s constants — a
      **deep copy per run** in `snapshot_module`, recommended, 6.6 us and
      fourteen small tables per program start with no observable change for
      player code; or **freeze the constants read-only**, which costs nothing
      per run but turns `dir = vector.one; dir.x = -1` into a raise, breaking
      that idiom and your own program as you just wrote it. Nothing is fixed
      yet. Leaving it as documented is not defensible: the mutation is shared by
      every player until the server restarts (audit S8)
- [ ] DECIDE: whether vector3's own fix lands before or after the v1.0.0 tag —
      any instance hands back the class table as `v.__index`, so a player
      program can replace vector3's methods and metamethods **for every other
      mod on the server**. The fix is `local mt = {__index = vector3, ...}` in
      vector3 itself, so it means a release of that package and a submodule bump
      here. Write-protecting it from this mod is recommended against: that is
      C18's mistake on another author's package (audit S9)
- [ ] run F-6 — `game.lua` three times over, watching the start direction, plus
      its case 3 reproducer, which is the only in-world reading S8 can have. The
      one-line example fix is in your working tree and uncommitted
      (audit S8; playtest F-6)
- [ ] re-run R2 on the archive built from the release commit — R1 was
      re-checked at `7dbe18f` and still passes, but R2 last ran before F4 added
      lib/hud.lua and before .gitattributes changed at `60dc8dd`. Install it in
      a game that is not codecube: B38, B39 and C18 were all invisible there
      (audit C16, C10)

Elsewhere

- [ ] drop the 5.5 ceiling in tests/game/mods/vector3/mod.conf — separate
      repository (audit C1)
- [ ] separate vector3's metatable from its methods table — `local mt =
      {__index = vector3, __add = ...}`, after which `v.__index` reads nil.
      Separate repository, so a release there and a submodule bump here, and it
      reaches every other consumer of the package. Nothing in codeblock reads
      `v.__add` as a field. Could go out with the C1 line above in one vector3
      release (audit S9)


# After 1.0.0

- [ ] FEAT: Blockly web-based editor (audit F6) — planned, deliberately not in
      1.0.0
- [ ] FEAT: Allow disconnect issues on servers, drone paused and can be resumed
- [ ] BUG : fix light on large builds (minetest.fix_light(pos1, pos2))
- [ ] FEAT : protect areas (minetest.is_protected(pos, name))
- [ ] FEAT : allow save and place schematic files
- [ ] FEAT : put a limit on drone distance to start pos
- [ ] FEAT : allow to rename programs


# Other ideas

- format lua programs when saving ? https://github.com/LuaDevelopmentTools/luaformatter/blob/master/formatter.lua
- render code with html widget? (highlight)
- show line error on save?
- colored concrete instead of wool? : https://github.com/nikolaus-albinger/colored_concrete - block list is the mod's, the nodes come from the game — **answered by `F11` on 2026-09-04, the other way round**: the nodes come from this mod, and a game adds its own on top in its own namespace
