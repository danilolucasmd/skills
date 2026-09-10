# skills

Agent instructions and skills, shared across machines and harnesses. This repo is the single source of truth for what used to live in a hand-maintained `~/.claude/CLAUDE.md` on each computer.

## Layout

```
rules/global.md        Always-on rules. Installed as the harness's global instruction file.
skills/<name>/SKILL.md One skill per directory. Loaded on demand when its description matches.
install.sh             Symlinks the above into a harness.
```

The split is the important part:

- **`rules/global.md`** holds only what must hold at all times: language, git safety, commit attribution, prose and comment style. It is always in context, so every line there costs tokens on every request. Keep it short.
- **`skills/`** holds procedures tied to a task or a trigger phrase. A skill's description is always visible to the model, but its body loads only when needed. Anything with steps, a template, or a command sequence belongs here.

When adding something new, ask which of those two it is. If it only matters while doing one kind of task, it is a skill.

## Install

```sh
./install.sh              # Claude Code, the default
./install.sh --dry-run    # show what would change, touch nothing
./install.sh --uninstall  # remove the symlinks, leave backups in place
```

Everything is installed as a symlink back into the repo, so editing a file here takes effect immediately with no reinstall. Restart Claude Code after adding or removing a skill so it picks up the change.

Anything already at a destination path is moved aside to `<name>.backup.<timestamp>` rather than overwritten, so a first install over an existing `~/.claude/CLAUDE.md` is safe and reversible.

`CLAUDE_CONFIG_DIR` is respected if set, otherwise `~/.claude` is used.

## Current skills

| Skill | Triggers on |
| --- | --- |
| `hunk-review` | The user saying they left "comments" on a diff, or naming Hunk |
| `pr-description` | Writing or updating a PR title and body |
| `stacked-prs` | "Rebase the stack", restacking branches above the current one |

## Adding a skill

```sh
mkdir -p skills/my-skill
```

Write `skills/my-skill/SKILL.md` with YAML frontmatter:

```md
---
name: my-skill
description: What it does, and the phrases or situations that should pull it in.
---

# Title

Body, loaded only when the skill fires.
```

The `description` is the only part the model sees before deciding to load the skill, so spend the effort there. Name the concrete trigger words the user actually says. Then run `./install.sh` to link it.

## Adding a harness

Only Claude Code is supported today. To add another:

1. Write a `harness_<name>` function in `install.sh` that links `rules/global.md` to wherever that harness reads global instructions, and each `skills/*` directory to wherever it reads skills.
2. Add the name to `SUPPORTED_HARNESSES`.

Nothing in `rules/` or `skills/` is Claude Code specific, so a new harness should need no content changes.
