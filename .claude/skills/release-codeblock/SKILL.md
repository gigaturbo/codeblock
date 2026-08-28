---
name: release-codeblock
description: Cut a release of the CodeBlock mod — version bump, regenerated reference and ContentDB metadata, verification, tag on master, ContentDB upload or release webhook, and what the page's long description may and may not contain. It releases on its own cadence; a game that embeds it adopts a release later and separately, in its own repository.
when_to_use: When releasing, tagging or publishing this mod. Also read it before changing anything that ships in a release, to see what will need regenerating.
disable-model-invocation: true
argument-hint: "[version]"
allowed-tools: Bash, Read, Glob, Grep
---

# Releasing CodeBlock

CodeBlock releases on its own cadence, from this repository, branch `master`.
Nothing here touches any game that embeds it: a game adopts a release when it
chooses to, on its own schedule and with its own procedure.

Do not start until `release-check` reports ready, or you have done its checks
yourself. This skill is the procedure; that agent is the gate.

## 1. Decide the version

Semantic, and the question that decides it is **whether existing player programs
break**. Programs are data written by players and stored in worlds; nothing can
migrate them.

Anything in this list is major:

- a name in `lib/api.lua` removed, renamed, or given different arguments
- `color()`, `round()` or similar changing what they return for the same input
- a block name changing (`wools.wool_red` → `wools.red` was one)
- a previously-allowed construct being refused
- relicensing, which breaks redistributors rather than players

v1.0.0 is major for several of these at once.

## 2. The release

- `CHANGELOG.md` — add the version heading, in the existing `- [x]` style.
  **Lead with what breaks**, then additions, then fixes, then known limitations
  as `- [ ]`. Someone upgrading reads the first section and stops.
- `mod.conf` — confirm `min_minetest_version` still matches what the code needs.
  Only raise it when something actually requires it; an honest floor widens the
  audience. Do not add `max_minetest_version`: the engine ignores it and
  ContentDB uses it to hide the package. Confirm `depends` still names
  `vector3`.
- Regenerate the reference if anything in `lib/api.lua` changed:
  `lua scripts/gen_docs.lua`, or boot with `codeblock_gen_docs = true` and copy
  the result out of the world directory (mod security blocks writing into the mod
  directory). `lua scripts/gen_docs.lua --check` must then exit 0.
- Regenerate `locale/template.txt` if any message text changed:
  `lua scripts/gen_locale.lua`. `lua scripts/gen_locale.lua --check` must then
  say *up to date*, and its `.tr` report names any message a translation is
  missing — advisory, since an untranslated string falls back to English.
- Regenerate `.cdb.json`: `bash scripts/gen_cdb_json.sh`. It embeds `README.md`,
  so any README edit needs this — and **nothing checks it for you**.
- `ROADMAP.md` and `TODO.md` — strike what this release closed. Or ask
  `project-manager` to, which is cheaper and more honest. The reasoning behind
  each item is in `AUDIT.md` beside them.
- `.gitattributes` — confirm nothing added since the last release will ship in
  the archive. Nothing in CI checks it, so check what actually ships:
  `git archive --format=tar HEAD | tar -t | awk -F/ '{print $1}' | sort -u`.
- `tests/game/mods/vector3` — confirm the pinned commit is pushed. It ships in no
  archive, but a fresh clone needs it to run the suite.
- Commit, then **push**: `git push origin master`.
- Tag: `git tag -a v<version> -m "v<version>"` and `git push origin v<version>`.

## 3. Verify

- CI green on the tagged commit itself: `luacheck`, the six standalone specs and
  `docs are generated from the code`, which now checks `doc/api.md` **and**
  `locale/template.txt`. Check `head_sha`; a green run on an earlier commit tells
  you nothing.
- The in-engine suite via `run-tests`, which boots the fixture game in
  `tests/game`. All nine specs reported, none skipped, `0 failed`, `0 xpass`.
- A fresh clone, which is how a standalone install gets it — and then the suite
  from that clone, because a release that cannot test itself from a clean
  checkout is not ready:

```bash
git clone --recurse-submodules git@github.com:gigaturbo/codeblock.git /tmp/cb-check
ls /tmp/cb-check/lib/                 # the new work is actually present
git -C /tmp/cb-check submodule status  # vector3 populated
```

## 4. ContentDB

The `codeblock` package at <https://content.luanti.org>, uploaded on its own.

- The long description comes from `.cdb.json`, generated from `README.md`.
  Regenerate before uploading or the listing goes stale.
- Screenshots load from raw GitHub URLs on `master`. GitHub currently redirects
  an old default-branch name, so a wrong branch may *look* fine — do not rely on
  that.
- Confirm the licence field matches the `LICENSE` file: AGPL-3.0-only.

### What belongs in the long description, and what does not

ContentDB's own guidance is <https://content.luanti.org/help/appealing_page/>,
and the index of the rest is <https://content.luanti.org/help/>. The short
version, because it decides what `long_description` may contain:

**Leave out** — a heading repeating the package title; the short description
restated; a link to the ContentDB page itself, the git repository or a forum
topic, all of which have their own fields; licence text, which has a field;
API documentation and development instructions, which belong in the repository
README; and **images**, including screenshots already uploaded.

**Put in** — what the package contains, what distinguishes it from the
alternatives, and how to use it once installed.

Two reasons this is not cosmetic. A reader of the long description is **already
on the package page**, so a link back to it is circular. And ContentDB's stated
reason for the images rule is that **"images ... are not visible inside
Luanti"** — its words — so an image reaches the website's readers and nobody
browsing in-game.

**Check whether any image is load-bearing before treating that as cosmetic.**
The README's *Quick start* uses the two tool icons *inline in its instructions* —
"Right click with ![drone_poser] tool on a block" — so without them the sentence
loses its object three times over. An image carrying meaning has to become words,
not simply be deleted.

**`README.md` is a good README and a bad long description, and today it is
both.** That is `C19` in `AUDIT.md`, open: the generator is faithful, the source
is wrong. Fixing it means `long_description` stops being the README — a separate
file, or a marked section of it — and the replacement text is player-facing copy,
so it is the author's to write. Do not quietly rewrite it as part of a release.

### The release webhook

<https://content.luanti.org/help/release_webhooks/>. Optional; it replaces the
manual upload with a push from the repository.

- An API token from *Profile → API Tokens → Manage* on ContentDB is the webhook
  **secret**. Payload URL `https://content.luanti.org/github/webhook/`, content
  type JSON, under the repository's *Settings → Webhooks*.
- **Select "Branch or tag creation", not push events.** This project tags — step
  2 above — so a tag is the release. Push events are for rolling releases and
  would publish every commit on `master`.
- A push-triggered webhook only watches the default branch; a tag-triggered one
  works on any branch. If more than one ContentDB package matches the repository,
  **only the first gets the release**.
- Once it exists, step 5 gains a check: after pushing the tag, confirm the
  release actually appeared. A webhook that has silently stopped looks exactly
  like one nobody configured.

## 5. After

- Watch CI on the tagged commit; a red build on a tag is worth fixing
  immediately rather than after someone downloads it.
- Ask `project-manager` to update the audit, changelog and roadmap.
- **Do not touch any game that embeds this mod.** Adopting the release is that
  project's decision, taken with its own documentation update, in its own
  repository.

## Things that have gone wrong here before

- `max_minetest_version` left at an old value, hiding a working package from
  everyone on a current release. The engine never enforced it, so nothing local
  ever failed.
- A limit shipped undocumented, because the check that every codelevel limit has
  a row in `doc/api.md` matched by name prefix. It matches by table shape now,
  and `gen_docs.lua --check` is what enforces it.
- `.cdb.json` regenerated on a checkout whose line endings differed, producing a
  spurious diff.
- The long description shipped as `README.md` for the whole project's life, with
  badges, repository links, a licence line and nine images that Luanti's own
  content browser cannot render. **A generator being faithful says nothing about
  its source being right** — `gen_cdb_json.sh` never drifted, and a `--check` on
  it would pass today. `C19`.
