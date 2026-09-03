---
name: code-standards
description: The standards and the traps for writing Lua in the CodeBlock mod — what the security boundary actually is, the Lua 5.1 and Luanti behaviours that have already cost findings here, and what has to be regenerated when a change touches a name, a string or a setting. Use before writing or changing any code under lib/, and when auditing it.
when_to_use: Before editing any Lua under lib/ or init.lua, when auditing code for defects or for what a player's program could reach, when a change touches a player-facing name, a translated string or a setting, and whenever you are about to state that an engine function exists or behaves in a particular way.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Writing code in CodeBlock

The architecture — the run pipeline, the API's single source, the limits, the
formspec session, the two tools — is in `CLAUDE.md` and is not restated here.
Read it. This skill is the craft: what to verify, what a change drags with it,
and the behaviours that have already cost findings.

The editing, coding and helper conventions are in `~/.claude/CLAUDE.md`. They are
the author's, they apply here unchanged, and they are not restated either. The
two that get broken most often: **inline a helper that only checks for `nil`**,
and **never wrap an engine call in a function containing nothing else**.

## Verify, never recall

Use the **`luanti-reference`** skill before stating that a `core.*` function
exists, is deprecated, takes particular arguments, or behaves a certain way. It
bundles `lua_api.md`, the Lua 5.1 manual, ContentDB's rules and the engine
behaviours that have already cost findings. Answering from memory is how three
findings got here.

Where `lua_api.md` is silent or misleading, the engine source settles it —
`src/gui/guiFormSpecMenu.cpp` for anything about a formspec's geometry or which
fields arrive. `lua_api.md` records a legacy button's spacing and padding but not
its fixed **0.2 unit** width offset, so the reference *cannot* settle a
misalignment in the editor form.

## The security boundary

**The environment table plus the read-only API surface.** Not the
forbidden-identifier list in `lib/preprocess.lua` — that is message quality, and
treating it as the boundary is the mistake to avoid.

Six questions for any change that runs while player code runs:

1. Can player code reach the injected counter? `lib/env.lua` makes API names
   unassignable for exactly this reason.
2. Can it allocate without bound? Every Lua 5.1 string shares one metatable, so
   `("x"):rep(1e9)` is reachable from a literal even with `string` out of the
   environment — that is what `lib/strguard.lua` bounds, and only for the span
   player code runs in.
3. Can it loop without paying? Instrumentation in `lib/preprocess.lua` is what
   makes a loop or a call charge a budget. A path that skips `use_call` freezes
   the server.
4. Can it run uninterruptibly for longer than one slab? A VoxelManip pass cannot
   be yielded out of, so the slab size *is* the longest stall this mod can cause.
5. Can it write or read outside the player's own directory, or past
   `max_file_kb`?
6. Can a player set a limit that bounds what the server spends? Codelevel is
   privileged — never player-settable, in any new form.

A snapshot gives each run **copies** of the API's tables, not read-only proxies:
Lua 5.1 has no `__pairs` or `__len`, so a proxy would break `pairs(blocks)` for
player code. Do not "improve" that into a proxy.

Everything a player's program can spend has a ceiling in `lib/limits.lua`, in the
unit it is checked in, converted once. `charge` stops the run; `hold` makes the
drone wait. Adding a cost means adding it there, not counting it locally.

## Lua 5.1 / LuaJIT, as it actually is here

- `loadstring`, `setfenv`, `math.pow`, `math.atan2` all exist. `goto` is
  instrumented by the preprocessor, so it is reachable in player code.
- **`0` is truthy.** So is `""`.
- **You cannot yield across `pcall`.** Anything on the coroutine's path that
  wants to yield must not be wrapped in one.
- No `__pairs`, no `__len`, no integer division, no `#` on a table with holes
  that means anything.
- `collectgarbage('count')` is the **Lua** heap. A MapBlock is C++ side and
  invisible to it — that is why `map_memory_mb` exists beside `heap_mb`.

## The engine behaviours that cost findings here

Do not re-derive these, and do not undo the guards they bought.

| Behaviour | Finding |
|---|---|
| `set_node` into a mapblock not in memory silently does nothing — `core.load_area` first. Bulk shapes need no call; `read_from_map` emerges the region. | S5 |
| The mapblock memo in `place_block` is **per-resume**, not per-run; `release` clears it before every yield. Widening its lifetime brings back the silent lost write. | S5 |
| `ObjectRef:remove()` takes effect at the end of the step, so `on_deactivate` can fire after a replacement drone exists under the same name. The **serial** guard is what protects it, not the clear-before-remove ordering. And `markForDeactivation` sets `m_pending_deactivation` *after* the Lua callback returns, so **a second `on_deactivate` fires from inside the first** and the cleared record absorbs it — so the ordering is load-bearing too, for its own reason. | B29 |
| An entity with `static_save = false` is unloaded when the mapblock it stands in is **not in server memory** — not when it leaves active-block range — and is then deleted outright, there being nothing to save. Nothing but `load_area`/`forceload_block` keeps that block loaded past ~192 nodes from a player, and **`load_area` does not reset the block's usage timer**, so a stationary drone loses its block after `server_unload_unused_data_timeout`. | B50, B52 |
| `Drone.finish` is the single place an outcome is announced (B12, B30) and has **no word for *cut short***: every non-error ending reads `Program '@1' completed`. Do not add a second announcement path; add the vocabulary. | B51 |
| `get_int` cannot tell an unset key from a stored `0`. Read a boolean preference with `get_string`, where absent is `""`. | B5 |
| A **scrollbar arrives in the field table on every submit**; a **checkbox is absent unless it was the box clicked**. `lua_api.md` reads as though the opposite. So: in one `elseif` chain, every always-sent field comes last or is read before the chain. | B37 |
| Every editor redraw re-renders the text area, so `fields.content` is captured once before the branch chain, never inside a branch. | B35 |
| `on_place` fires only with a node under the crosshair; aiming at sky or unloaded ground calls `on_secondary_use`. Both route into one call, and the no-node check sits above the busy check. | B38 |
| **Never clear a player's inventory** — add what is missing, and read both `main` and `craft` so a tool parked in the craft grid is not duplicated on every join. | B39 |
| A form closes by one path however it was reached, so load order is load-bearing: `forms.lua` is dofiled before `register.lua`. | B33 |
| Never build a translation key with `..`, and never edit an `S()` key in the source alone. | C17 |

The editor formspec is in **legacy coordinates**. A `scroll_container` maps its
contents into a different space and clips them; an `item_image_button` inside one
gets a hit area that does not match where it is drawn; a legacy button's `W` is
short by a fixed 0.2 units and its `H` only shifts it down. Anything new in that
form has to know all of it.

## What a change drags with it

Three files here restate the source, are read by a human or by ContentDB rather
than by the code, and **drift silently — nothing fails when they are wrong**.

| A change to | drags | checked by |
|---|---|---|
| a player-facing name | `lib/api.lua`, the `impls` table in `lib/sandbox.lua`, `doc/api.md`, the explicit name list in `tests/api_spec.lua` | `api.build` refuses to load on a mismatch in either direction; `lua scripts/gen_docs.lua --check` |
| any `S()` literal | `locale/template.txt`, and the orphaned key in every `locale/*.tr` | `lua scripts/gen_locale.lua --check` — template only; a `.tr` gap is legitimate |
| a codelevel limit or setting | the plain literal in `lib/config.lua`, then regenerate `settingtypes.txt`; the codelevel row in `doc/api.md` is hand-written | `lua scripts/gen_settingtypes.lua --check` and `gen_docs.lua`'s documented-row guard, both matching **by shape** — a computed table turns both off without failing |
| the ContentDB long description | `CONTENTDB.md`, then `bash scripts/gen_cdb_json.sh` | nothing. Never edit `.cdb.json` |
| any file added to the tree | `.gitattributes` | nothing. ContentDB builds with `git archive`, so a file with no `export-ignore` rule ships to a player |

Regenerating is part of the change, not a follow-up: `gen_docs.lua`,
`gen_locale.lua` and `gen_settingtypes.lua` all run under a bare Lua 5.1 from the
repo root, and `gen_locale.lua` lists `lib/` through `ls`, so it wants WSL rather
than PowerShell.

**A check that cannot fail is indistinguishable from a check that passes.** Two
of the guards here were written, committed, believed and matched nothing — the
second because Lua's `%w` excludes the underscore that every limit name contains
(C20). So `[%w_]` wherever an identifier is matched, and **make a new check fail
once**, against a deliberately broken input, before trusting it.

A player-facing rename breaks saved player programs, which are data no game can
migrate. That is a **major version bump**, and it is the author's call before you
write it.

## Comments

A few lines saying what a module or function does, plus what is genuinely
non-obvious: a constraint that would be re-broken if forgotten, an argument
order, a contract. A finding id is a fine short reference.

Never the history of what the code replaced — that is git's and the changelog's,
and in a comment it goes stale. One comment here claimed for months that nothing
in Lua 5.1 could stop a huge string allocation, long after `strguard.lua` started
doing exactly that.

## Before handing the change back

```bash
luacheck . --formatter plain --codes          # LUACHECK_STRICT=1 to see what the baseline hides
lua scripts/gen_docs.lua --check
lua scripts/gen_locale.lua --check
lua scripts/gen_settingtypes.lua --check
```

The suite is the **`run-tests`** skill's, and in-engine: nine specs, six of which
also run standalone under Lua 5.1, which is the only thing that catches plain 5.1
differing from the engine's LuaJIT.

**Read the output, not the exit code** — `$?` does not survive this machine's WSL
layer. A gate is green when it says so.

Then say plainly, in the reply: which gates ran and what they printed, what a
spec cannot reach and therefore needs a `PLAYTEST.md` entry, and any defect found
in code you did not write, so it can get a finding id.
