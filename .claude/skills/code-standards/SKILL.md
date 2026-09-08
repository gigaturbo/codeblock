---
name: code-standards
description: The standards and the traps for writing Lua in the CodeBlock mod — what the security boundary actually is, the Lua 5.1 and Luanti behaviours that have already cost findings here, and what has to be regenerated when a change touches a name, a string or a setting. Use before writing or changing any code under lib/, and when auditing it.
when_to_use: Before editing any Lua under lib/ or init.lua, when auditing code for defects or for what a player's program could reach, when a change touches a player-facing name, a translated string or a setting, and whenever you are about to state that an engine function exists or behaves in a particular way.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Writing code in CodeBlock

The architecture is in five skills and is not restated here. Read the one that
covers the file you are about to touch: **`program-pipeline`** for the run
pipeline, the limits and the world writes; **`drone-and-tools`** for the drone
record, its entity and the two tools; **`editor-formspecs`** for `forms.lua` and
`formspecs.lua`; **`blocks-and-palette`** for the nodes, the palette and the
ramps; **`generated-files`** for `lib/api.lua` and everything derived from it.
This skill is the craft: what to verify, what a change drags with it, and the
behaviours that have already cost findings.

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

**How the environment is built is the `program-pipeline` skill's.** What leaked
through it is `S8` and `S9` in `AUDIT.md`, both resolved; read them before adding
a table-valued entry to the environment, because a snapshot is one level deep and
the caller owns the leaves.

**A new cost goes in `lib/limits.lua`, never counted locally.** One ceiling, one
counter, in the unit it is checked in.

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

## Writing a line a player reads

- **Read varargs with `select('#', ...)` and `select(i, ...)`, never `{...}` and
  `#`.** Lua 5.1 cannot see a nil in the middle or at the end of a vararg list,
  and `get_block()` answers `nil` over ungenerated map, so a player prints a nil
  routinely and `{...}` truncates the line there (`B54`).
- **Join with a space, not real Lua's tab.** Luanti's chat console has no tab
  stops, so a tab renders as an ordinary glyph, and the engine's chat wrapping
  breaks on spaces, so a tab-joined line refuses to wrap on a narrow console.
  `lua_api.md` documents neither.
- **No spec can see the line.** Both senders are load-time locals, so a spec
  asserting that `print` merely does not raise is vacuous. The `run-tests` skill
  says what to pin instead.

## The guards that must not be undone

An index, not the reasoning. Read the skill named before changing the code the
row is about.

| Guard | Finding | Where it is written |
|---|---|---|
| `load_area` before a single-node write, and the per-resume mapblock memo | `S5` | `program-pipeline` |
| One ramp implementation, `ramp_pick`, behind every ramp | `F12`, `F14` | `blocks-and-palette` |
| `register_blocks` queued at the call, validated at `register_on_mods_loaded` | `F11` | `blocks-and-palette` |
| The serial guard, and clearing the record before `obj:remove()` | `B29` | `drone-and-tools` |
| No `on_step` on the drone entity; the globalstep drives the run | `B50`, `B52` | `drone-and-tools` |
| `on_place` and `on_secondary_use` routed into one call, aim checked before busy | `B38` | `drone-and-tools` |
| Add a missing tool, never clear an inventory; read `main` and `craft` | `B39` | `drone-and-tools` |
| `fields.content` captured before the branch chain | `B35` | `editor-formspecs` |
| Always-sent fields last in an `elseif` chain | `B37` | `editor-formspecs`, `luanti-reference` |
| One close path, and `forms.lua` dofiled before `register.lua` | `B33` | `editor-formspecs` |
| A boolean preference read with `get_string` | `B5` | `editor-formspecs`, `luanti-reference` |
| No `..` in a translation key; no key edited in the source alone | `C17` | `generated-files` |
| Limit tables kept as plain literals so two generators can see them | `C20` | `program-pipeline`, `generated-files` |
| `Drone.finish` the single announcement path; a new ending is a new branch | `B12`, `B30`, `B51` | `drone-and-tools` |
| A dropdown is always-sent, and its two exceptions | `B37`, `F11` | `editor-formspecs` |
| Every legacy element's `W` is its own unit | `F11` | `editor-formspecs` |
| Branch on a value matching what you drew, never on it differing | `B37` | `editor-formspecs` |

## What a change drags with it

A lookup table. **How each one is checked, and why, is the `generated-files`
skill's.** Read it before touching any row.

| A change to | drags |
|---|---|
| a player-facing name | `lib/api.lua`, the `impls` table in `lib/sandbox.lua`, `doc/api.md`, the name list in `tests/api_spec.lua`, `stds.codeblock_sandbox` in `.luacheckrc` |
| any `S()` literal | `locale/template.txt`, and the orphaned key in every `locale/*.tr` |
| a codelevel limit or setting | the literal in `lib/config.lua`, a regenerated `settingtypes.txt`, the hand-written codelevel row in `doc/api.md` |
| a chat command or a privilege | the hand-written region above `# Lua api` in `doc/api.md` |
| the ContentDB long description | `CONTENTDB.md`, then `bash scripts/gen_cdb_json.sh` |
| any file added to the tree | `.gitattributes` |
| the new-file template in `lib/formspecs.lua` | `tests/integration_spec.lua`, which reads it out of the source |

**Regenerating is part of the change, not a follow-up.**

**Make a new check fail once**, against a deliberately broken input, before
trusting it. A check that cannot fail is indistinguishable from one that passes.

**A player-facing rename breaks saved player programs**, which are data no game
can migrate. That is a **major version bump**, and it is the author's call before
you write it.

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

**A shell variable does not survive it either.** `wsl bash -lc '... for s in api
preprocess; do lua5.1 tests/$s_spec.lua; done'` reaches `bash` with `$s` already
stripped, whatever the quoting, and runs `tests/_spec.lua` six times — six
*cannot open* lines, no spec output, and nothing that reads as a gate failing.
Name each spec explicitly, or put the loop in a file and run that.

**An edit into a CRLF file can leave the inserted lines LF**, and it does so
only sometimes, so the file ends up mixed and nothing lints it. Half the `lib/`
tree is CRLF. Check the file you edited and repair it in place:

```bash
python -c "d=open('lib/config.lua','rb').read(); print(d.count(b'\r\n'), d.count(b'\n'))"
unix2dos -q lib/config.lua   # converts lone LF only, so the diff stays your lines
```

The two counts must be equal for a CRLF file and the first zero for an LF one.
**`cat -A` cannot answer this**: `sed` in this machine's Git Bash strips the CR
on read, so a piped `cat -A` shows a clean `$` on every line of a CRLF file.

Then say plainly, in the reply: which gates ran and what they printed, what a
spec cannot reach and therefore needs a `PLAYTEST.md` entry, and any defect found
in code you did not write, so it can get a finding id.
