---
name: editor-formspecs
description: The CodeBlock editor's forms — the per-player session in lib/forms.lua, the editor built in lib/formspecs.lua, why it is in legacy coordinates and what that forbids, where the text area is captured, the single close path and the load-order dependency it creates with lib/register.lua. Engine-general formspec behaviour is in the luanti-reference skill and is not repeated here.
when_to_use: Before editing lib/forms.lua or lib/formspecs.lua, or any handler taking (meta, player, fields). Also when adding an element to the editor, when a click or a typed change is lost, when a panel refreshes itself, or when reading a preference out of player meta.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# The editor's forms

**`lib/forms.lua` is a per-player form session on `core.show_formspec`** — state
that survives a redraw, field routing, one form per player.
**`lib/formspecs.lua` builds the editor itself.** Handlers are
`handler(meta, player, fields)`, where `meta` is the same table across redraws.

**Read `luanti-reference` first for the engine's part.** Which fields arrive, the
rebuild that swallows a click, the legacy button width offset, `scroll_container`
clipping and the `get_int` trap are general Luanti facts and live there. This
skill is what follows from them in this editor.

## Legacy coordinates

**The editor formspec is in legacy coordinates**, not `formspec_version`
coordinate mode. Three consequences (`F1`, `F2`):

- **The block picker is a `textlist`**, because a `scroll_container` maps its
  contents into a different space and clips them, and an `item_image_button`
  inside one gets a hit area that does not match where it is drawn. A `textlist`
  scrolls itself, as the file list in the same form already does. The help panels
  get away with a container only because `item_image` takes no clicks.
- **A button is short by a fixed 0.2 units** whatever `W` is, and the offset does
  not scale. That is why *Create a copy* is `3.2` wide against the 3-wide file
  list and `+` is `0.95`.
- **A legacy button's `H` is not a height.** The height is fixed; `H` only shifts
  it down.

**Every legacy element's `W` is its own unit, so two of them do not line up by
sharing a number.** Legacy `spacing` is `(1.25·S, 15/13·S)` for imgsize `S`, and
a position is always `x · spacing.X` — but a `button` is `W · spacing.X − 0.25·S`
wide, a `textlist` is `W · spacing.X`, and a **`dropdown` is `W · spacing.Y`**,
with no offset. Converting between them is arithmetic, not a guess: the editor's
selector spans a button row's 2.625·S at `W = 2.275`, and sits at `y = -0.025` so
its rectangle (`y` to `y + 2·m_btn_height`) lands on the buttons' (`H·S/2 ±
m_btn_height`). A **dropdown returns the item's *text*, not its index**, unless
the `index event` parameter is given — which is a formspec version 4 parameter
and so unavailable in a legacy form. Neither the widths nor that last point is
in `lua_api.md`; `parseButton`, `parseDropDown` and `acceptInput` are.

**Anything new in this form has to know all of it**, and converting the editor to
the new coordinate system is a change to the whole form.

## Fields and state

**Capture `fields.content` once, by a guarded read before the branch chain in
`on_close`** — never inside a branch that happens to need it. Every redraw
re-renders the text area from `meta.contents[meta.active]`, and eight of eleven
branches used to redraw without the capture and threw away everything typed since
the last save (`B35`). The guard also carries the quit event, which sends no
field but `quit`.

**Every always-sent field comes last in a single `elseif` chain, or is read
before the chain entirely.** `fields.content` (`B35`), the three panel scrollbars
and `newfile` (`B37`) are all in that class.

**`newfile` is keyed on `fields.key_enter_field == 'newfile'`**, which the engine
sets on `EGET_EDITBOX_ENTER` and nothing else sets — not on the field being
non-empty.

**Read a boolean preference with `get_string`, never `get_int`.** An absent key
is `""`, so a default of *on* is expressible and a deliberate untick still reads
as off. Two defaults here depend on it (`B5`).

**A live panel loses clicks.** A form that refreshes itself under the player
loses roughly one click in five per 0.5 s beat, and *no text field, so no focus to
lose* does not make it safe: focus and a press in flight are different questions
(`B47`).

**A dropdown is always-sent** (`parseDropDown` sets `send = true`), with two
exceptions: on the submit a dropdown's *own* change fires, `OnEvent` clears
`send` on every **other** dropdown and restores it after; and a dropdown drawn
with selected index `0` selects nothing, so `acceptInput` skips it and the field
is absent. Compare an arriving value against the state it was **drawn** from,
never against something else that happens to correlate (`B37`, `F11`).

**Branch on a value *matching* something you drew, never on it *differing*.**
For an always-sent field whose round trip you cannot check offline — a dropdown's
item text, which for a translated label is an escape sequence — the two are not
symmetric. Match, and a value you do not recognise is ignored: the control
silently does nothing. Differ, and an unrecognised value reads as a change on
every submit, consuming whatever else the player did in the same event, ESC
included. The first failure is cosmetic and the second loses their work, so pick
the shape rather than the fact you could not verify.

## Closing

**A form closes by one path however it was reached** (`B33`). Leaving and server
shutdown both go through the local `close_session`, which drops the session and
then hands the handler the engine's own `{quit = 'true'}`, so a handler holding
unsaved state has one place to write it. `forms.forget` is unchanged and is what
the specs use for cleanup; only the engine callbacks close a session this way. A
close from the mod's side (`forms.close`) deliberately sends nothing.

**Load order is load-bearing.** Leave callbacks run in load order, `forms.lua` is
dofiled before `register.lua`, and it must stay that way — the editor's quit path
reads the player's file list, which `register.lua`'s own leave callback drops via
`remove_user_data`. Reordering the `dofile` list in `init.lua` silently breaks
*Load program on exit* on disconnect. The constraint is commented on
`register_on_leaveplayer` in `lib/register.lua`.

**Both of those callbacks build the `{quit = 'true'}` they pass in**, so neither
carries a scrollbar field. That is why they kept working while closing the same
editor with ESC did not (`B37`): the two paths with playtest checks were the two
that worked.

**Player meta written from `register_on_shutdown` is saved.** Observed on engine
5.17.0 at `dee0bc7`, `PLAYTEST.md` check `E9` — not inferred.

## The new-file template

**The program `create_file` writes into a new file is player code inside a Lua
string literal in `lib/formspecs.lua`.** Nothing lints, compiles or generates it,
so it is covered instead by `tests/integration_spec.lua` reading the string out
of the source. The rules it must keep are in the **`generated-files`** skill
(`B53`).

## Related

- **`luanti-reference`** — the engine facts this skill builds on.
- **`drone-and-tools`** — `Drone.on_place` asking for the file chooser.
- **`generated-files`** — the new-file template's coverage and the `S()` rules for
  any string the form shows.
