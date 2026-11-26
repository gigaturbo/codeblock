# v2.1.0 (unreleased)

- [x] FIX: A block help panel scrolled to the end shows its last row whole instead of cut in half.
- [x] FIX: The French label above the New file field is shown in full in a small window.

- [x] FEATURE: The two drone tools are now four, one action each and the same on either mouse button: the **Placer**, the **Runner**, the **Editor** and **Status**. An old Drone placer becomes the Placer and an old Drone setter the Editor; `/codeblock tools` gives the rest.
- [x] FEATURE: A quick start shows a new player how to write and run a first program, with buttons to get the tools and open the editor. It opens at join until *Do not show again* is ticked, and comes back with the editor's **?** button or `/codeblock help`. `codeblock_quickstart = false` stops it opening at join.
- [x] FEATURE: `save()` with no name picks one, `cp1`, `cp2` and so on, and every `save` returns the name it saved under.
- [x] FEATURE: Programs can use `tonumber` and `tostring`. `tonumber` answers nil for a string that is not a number, where `"12" + 0` stops the program.
- [x] FEATURE: The editor, the drone panel and the file chooser show icons instead of words on their buttons, coloured by what they do, with a tooltip saying what each one does. Run comes first, and *Create a copy*, now *Duplicate*, moved up beside *Save*.
