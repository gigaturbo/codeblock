#!/usr/bin/env bash

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
}' "$(perl -0777 -pe 's|\n|\\n|gs' README.md)" > .cdb.json
