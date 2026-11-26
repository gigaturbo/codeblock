# v2.1.0 (unreleased)

- [x] FIX: A block help panel scrolled to the end shows its last row whole instead of cut in half.
- [x] FIX: The French label above the New file field is shown in full in a small window.

- [x] FEATURE: `save()` with no name picks one, `cp1`, `cp2` and so on, and every `save` returns the name it saved under.
- [x] FEATURE: Programs can use `tonumber` and `tostring`. `tonumber` answers nil for a string that is not a number, where `"12" + 0` stops the program.
- [x] FEATURE: The editor, the drone panel and the file chooser show icons instead of words on their buttons, coloured by what they do, with a tooltip saying what each one does. Run comes first, and *Create a copy*, now *Duplicate*, moved up beside *Save*.
