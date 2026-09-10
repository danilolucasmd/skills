# Working on this repo

This repo is the single source of truth for the user's agent instructions across machines and harnesses. It replaces the hand-maintained `~/.claude/CLAUDE.md` that used to be edited separately on each computer.

Nothing here is the live config. `install.sh` symlinks these files into a harness. Editing a file here changes behavior immediately on any machine where the install has run, so treat every edit as a change to the user's live setup on several computers.

## The one decision that matters

Every addition is either an always-on rule or a task-scoped procedure. Put it in the right place.

| | `rules/global.md` | `skills/<name>/SKILL.md` |
| --- | --- | --- |
| Loaded | Always, every request | Description always, body on demand |
| Costs tokens | On every request | Only when it fires |
| Belongs here | Style, safety, language, attribution: things that must hold at all times | Steps, templates, command sequences, anything tied to a trigger phrase |

The test: if it only matters while doing one kind of task, it is a skill. If violating it would be wrong in any conversation, it is a rule.

Bias toward skills. `rules/global.md` is in context for every single request on every machine, so a paragraph added there is a permanent tax. Keep it short and move anything procedural out.

## Layout

```
rules/global.md          Always-on rules. Installed as the harness's global instruction file.
skills/<name>/SKILL.md   One skill per directory.
install.sh               Symlinks the above into a harness.
AGENTS.md                This file.
CLAUDE.md                Satellite pointer to this file.
```

`CLAUDE.md` at the root is *not* the global instruction file. It is a project-level pointer to this document, for agents working on the repo. The global rules live in `rules/global.md`.

## Adding a skill

Create `skills/<name>/SKILL.md` with YAML frontmatter:

```md
---
name: my-skill
description: What it does, and the phrases or situations that should pull it in.
---
```

Spend the effort on `description`. It is the only part the model sees before deciding whether to load the skill, so it has to name the concrete words the user actually says. `hunk-review` is the model to copy: it lists "added, made, or left comments" and then states what the user does *not* mean, because that phrase is ambiguous.

`install.sh` discovers skills by scanning for directories containing `SKILL.md`, so a new skill needs no change to the script. Rerun `./install.sh` to link it, and restart Claude Code so it is picked up.

If a rule and a skill overlap, put the trigger in `rules/global.md` and the procedure in the skill. See the "comments means Hunk" rule for that pattern.

## Style for content authored here

`rules/global.md` applies to the files in this repo, not just to the user's other projects. The two that get violated most while writing docs here:

- No em dash, en dash, or spaced hyphen as sentence punctuation. Rewrite the sentence rather than swapping in a comma. Grep for `—`, `–`, and ` - ` before handing work over. The only legitimate hits are inside backticks on the two lines that state this rule, here and in `rules/global.md`.
- No hard wraps. One line per paragraph and per list item, however long.

Write for a reader who will act on it, not for completeness. These files are prompts, so vague wording produces vague behavior. Prefer imperatives and name the trigger phrases verbatim.

## Constraints

- **Nothing machine-specific or employer-specific.** No absolute paths outside the repo, no work ticket prefixes, no internal project or service names, no tooling that exists on only one of the user's computers. Content has to make sense on both a work macOS machine and a personal Arch machine. Genericize examples: a PR branch example is `ddias/abc-123-slug`, not a real ticket.
- **No git operations.** Make the edits and stop, leaving the tree for the user to review. This holds here as everywhere.
- **Do not install into the live `~/.claude` unless asked.** Verify against a throwaway config dir instead. See below.

## Verifying install.sh

Never test against the real config root. `install.sh` honors `CLAUDE_CONFIG_DIR`, so point it at a temp dir:

```sh
bash -n install.sh                                  # syntax
./install.sh --dry-run                              # plan against the real root, writes nothing
TMP=$(mktemp -d); CLAUDE_CONFIG_DIR="$TMP" ./install.sh
CLAUDE_CONFIG_DIR="$TMP" ./install.sh               # must be idempotent
CLAUDE_CONFIG_DIR="$TMP" ./install.sh --uninstall
rm -rf "$TMP"
```

Cover these cases, all of which have regressed at least once:

- Fresh install, then a rerun reporting `already linked` and changing nothing.
- A real file at a destination gets moved to `<name>.backup.<timestamp>`, never overwritten.
- A symlink pointing outside the repo is left alone by `--uninstall`.
- `--uninstall` on a config dir with nothing installed exits 0.

That last one is the live gotcha: the script runs under `set -euo pipefail`, and a bare `return` in a function propagates the status of the last command. A trailing `[ -e "$x" ] && note ...` therefore returns 1 when the file is absent, which kills the whole run at the call site. Return `0` explicitly from any function whose last statement is a test that may fail.

## Invariants of install.sh

Preserve these when changing it:

- Symlinks only, never copies. Copies would let the installed state drift from the repo.
- Never overwrite or delete anything that is not a symlink into this repo. Back it up first.
- Idempotent. Running it twice is a no-op the second time.
- `--dry-run` writes nothing and prints the same plan with `would` verbs.
- `--uninstall` removes only symlinks resolving into this repo, and leaves backups in place for the user to restore by hand.
- `rules/` and `skills/` stay harness-neutral. All harness knowledge lives in a `harness_<name>` function plus an entry in `SUPPORTED_HARNESSES`.

## Adding a harness

Only Claude Code is supported. To add another, write a `harness_<name>` function that links `rules/global.md` to that harness's global instructions path and each `skills/*` directory to its skills path, then add the name to `SUPPORTED_HARNESSES`. Hyphens in the name map to underscores in the function name.

For a harness with no skill loader, do not point its instructions file at this directory and hope the agent reads it. Generate a managed block delimited by markers so the block can be refreshed and removed cleanly. This was considered and deferred; there is no second harness yet.
