#!/usr/bin/env bash
#
# Verify doc/api.md still describes what lib/config.lua and lib/sandbox.lua
# actually provide.
#
# The audit calls this out as finding A2: the player-facing API is defined in
# three places - the environment table in lib/sandbox.lua, the in-game help
# string in lib/utils.lua, and doc/api.md - with nothing connecting them. They
# had already drifted: doc/api.md advertised `cave_ice` and
# `dirt_with_grass_footsteps` after both were dropped from the config, listed
# `pine_bush_needles` among the plants, omitted `junglegrass`, and never
# mentioned color() at all.
#
# This is not the generator A2 asks for. It is the cheap half: it cannot write
# the docs, but it fails the build when they stop matching, which keeps the drift
# from returning while the generator is still on the list.
#
# Usage: scripts/check_docs.sh   (from the mod root)

set -uo pipefail
cd "$(dirname "$0")/.."

# Find an interpreter that actually runs. `command -v python3` is not enough:
# on Windows it finds the Microsoft Store stub, which exits with an error, and
# an early version of this script read that empty output as "no problems" and
# reported success. So probe each candidate, and below, require the checker to
# print an explicit OK - never infer success from silence.
PY=""
for cand in python3 python py; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "pass" >/dev/null 2>&1; then
        PY="$cand"
        break
    fi
done
if [ -z "$PY" ]; then
    echo "  SKIPPED: no working python interpreter found"
    echo "  (documentation was NOT checked)"
    exit 0
fi

problems=$("$PY" - <<'EOF'
import re, io

cfg = io.open('lib/config.lua', encoding='utf-8').read()
doc = io.open('doc/api.md', encoding='utf-8').read()
sandbox = io.open('lib/sandbox.lua', encoding='utf-8').read()

problems = []

def cfg_block(section):
    m = re.search(r'    %s = \{(.*?)\n    \}' % section, cfg, re.S)
    if not m:
        problems.append('could not find the %s table in lib/config.lua' % section)
        return []
    return re.findall(r'^\s*([a-z_0-9]+) =', m.group(1), re.M)

# 1. the documented block lists must match the config exactly
for section, heading in (('cubes', 'blocks'), ('plants', 'plants'),
                         ('wools', 'wools')):
    want = cfg_block(section)
    m = re.search(
        r'### `%s`\n\nString-indexed table with the following values:\n\n```lua\n(.*?)\n```'
        % heading, doc, re.S)
    if not m:
        problems.append('doc/api.md has no `%s` list in the expected format' % heading)
        continue
    got = [x.strip() for x in m.group(1).split(',') if x.strip()]
    missing = [b for b in want if b not in got]
    extra = [b for b in got if b not in want]
    if missing:
        problems.append('`%s`: in config but undocumented: %s'
                        % (heading, ', '.join(missing)))
    if extra:
        problems.append('`%s`: documented but absent from config: %s'
                        % (heading, ', '.join(extra)))

# 2. every per-codelevel limit needs a row in the codelevel table
for name in re.findall(r'^codeblock\.config\.(max_\w+|\w+_before_yield) = \{',
                       cfg, re.M):
    if not re.search(r'^\| %s\s' % re.escape(name), doc, re.M):
        problems.append('the codelevel table has no row for %s' % name)

# 3. every name the sandbox exposes should appear somewhere in the doc
m = re.search(r'local api = \{(.*?)\n    \}\n', sandbox, re.S)
if not m:
    problems.append('could not find the api table in lib/sandbox.lua')
else:
    exposed = set(re.findall(r'^        ([a-z_0-9]+) =', m.group(1), re.M))
    # documented as members of another table, or Lua builtins with no section
    ignore = {'ipairs', 'pairs', 'table', 'error', 'print', 'vertical',
              'horizontal', 'centered', 'e', 'pi'}
    undoc = sorted(n for n in exposed - ignore if n not in doc)
    if undoc:
        problems.append('exposed by the sandbox but never mentioned in doc/api.md: %s'
                        % ', '.join(undoc))

for p in problems:
    print(p)
# Positive completion marker. Without it, an interpreter that died before
# producing output would look identical to a clean run.
print('__CHECKED__')
EOF
)

if ! grep -q '__CHECKED__' <<< "$problems"; then
    echo "  FAIL: the documentation checker did not run to completion"
    printf '%s\n' "$problems" | sed 's/^/        /'
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::error::check_docs.sh could not run its checker"
    fi
    exit 1
fi

problems=$(grep -v '__CHECKED__' <<< "$problems" | sed '/^$/d')

if [ -n "$problems" ]; then
    while IFS= read -r line; do
        printf '  FAIL: %s\n' "$line"
        if [ -n "${GITHUB_ACTIONS:-}" ]; then
            echo "::error file=doc/api.md::$line"
        fi
    done <<< "$problems"
    echo
    echo "documentation checks FAILED"
    exit 1
fi

echo "  doc/api.md matches config.lua and the sandbox environment"
echo
echo "documentation checks passed"
