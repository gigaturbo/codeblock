#!/usr/bin/env bash
#
# Regenerate .cdb.json, embedding README.md as the ContentDB long description.
#
# CRLF is normalised to LF before escaping. Without that the output depends on
# the checkout's line endings: on Windows, README.md arrives as CRLF and the raw
# CR bytes survive into the JSON string, so the file differs from one generated
# on Linux.

printf \
'{
    "type": "MOD",
    "title": "CodeBlock",
    "name": "codeblock",
    "dev_state": "ACTIVELY_DEVELOPED",
    "short_description": "Use lua code to build anything you want",
    "long_description": "%s",
    "tags": [
        "education",
        "tools"
    ],
    "license": "AGPL-3.0-only",
    "media_license": "AGPL-3.0-only",
    "repo": "https://github.com/gigaturbo/codeblock",
    "issue_tracker": "https://github.com/gigaturbo/codeblock/issues"
}' "$(perl -0777 -pe 's|\r\n|\n|gs; s|\n|\\n|gs' README.md)" > .cdb.json
