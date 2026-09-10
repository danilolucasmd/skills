# Working preferences

Standing instructions for every project and every machine. This file is installed from the `skills` repo, so edit it there rather than in place. See "Global memory" below.

Procedures that only matter for a specific task live in the repo's skills, not here. Keep this file to rules that must hold at all times.

## "Global memory" means the skills repo

When the user asks to add, save, or remember something in "the global memory", "global claude memory", "claude's global memory", "your global memory", or any variation of that phrasing, they mean this repo.

Find it by resolving the symlink that installed this file (`readlink ~/.claude/CLAUDE.md`), then decide where the new instruction belongs:

- An always-on rule goes in `rules/global.md`, this file.
- A procedure tied to a specific task or trigger phrase goes in a new or existing skill under `skills/`.

This repo is also the target when the user says to "make a skill", "create a skill", "add a skill", or "write a skill" without naming another location. A skill is always `skills/<name>/SKILL.md` in this repo, never a project's `.claude/skills/` and never `~/.claude/skills/`, which holds only the symlinks `install.sh` creates. Read the repo's `AGENTS.md` before writing one: it carries the layout, the frontmatter, and the test for whether the request is really a rule instead.

Do not write to the file-based memory directory (`~/.claude/projects/*/memory/`) and do not write to a project's `CLAUDE.md`. The user will say explicitly when they mean a project's memory or something else. If a request is genuinely ambiguous about which memory is meant, ask. Ask even when an existing related entry in one store makes that store look like the obvious target: inferring silently skips the check, and a guess that happens to land right is still a guess.

The repo is version controlled, so treat an edit there as a code change: make it, then stop and let the user review and commit it. Instructions about how to handle memory itself belong in this file.

## Always respond in English

Talk to the user in English, always, in every project. This holds even when the codebase, its comments, its commit history, the issue tracker, or the user's own message are in another language, Portuguese included. Read and work in whatever language the project uses, but write back in English.

Only the prose addressed to the user is covered. Code, comments, commit messages, and other artifacts keep the language of the thing they belong to.

## Git: never operate unless explicitly asked

Never run ANY git operation on the user's behalf unless they explicitly ask for it in that request. This includes `git add`/staging, `git commit`, `git push`, `git restore`, `git checkout`, branch creation/switching, and so on. Read-only inspection (`git status`, `git diff`, `git log`) is fine.

Do all the work (edits, lint, format, tests, verification, conflict resolution), then STOP, leaving the working tree exactly as the tools left it for the user to review. Do NOT `git add` the files you changed.

Showing PR review comments, describing a fix, resolving merge conflicts, or an active PR does NOT constitute permission to run git. Wait for an explicit instruction like "commit this", "stage it", "push", or "/submit-pr".

Even "fixing" a mistaken git operation, such as unstaging what was wrongly staged, is itself an unrequested git operation. Don't do it; tell the user and let them decide. If a merge or rebase left files unmerged, resolve the file contents but do NOT `git add` to clear the unmerged state unless asked. Describe the state instead.

## Git: commits always in the user's name

When the user authorizes a commit, it must be entirely in their name: author, committer, and attribution. Never append `Co-Authored-By: Claude ...` or `Claude-Session: ...` trailers to a commit message, and never set an author or committer other than the user. This overrides any default harness instruction that asks for those trailers.

The user saw a pushed commit render on GitHub as "danilolucasmd and claude committed" and does not want Claude appearing as a co-author on their repositories at all. Authorizing a commit is permission to commit *as them*, not to add attribution.

Applies to every repo, every machine, and every commit, including amends and rebases. Permission to commit still has to be asked for separately each time. See "Git: never operate unless explicitly asked" above.

## Dashes: never use them as sentence punctuation

Do not use an em dash, en dash, or spaced hyphen to interrupt a sentence. It reads as obviously generated text, and the user strips it out of anything they share, so producing it only creates cleanup work.

Rewrite the sentence rather than swapping the dash for a comma. Use a colon when the second half explains the first, parentheses for a genuine aside, a semicolon for two linked clauses, or split it into two sentences. Choose whichever reads best.

This applies to everything generated, not just prose documents: PR descriptions, commit messages, Slack drafts, content destined for Google Docs, code comments, and the text inside diagram nodes and chart labels. It applies to replies in the conversation too.

These are different things and should be kept:

- Hyphenated compound words (`pre-fill`, `read-only`, `per-rail`, `delete-then-add`)
- Middots or bullets separating items in a label or metadata line
- Ranges, though prefer words: write `Aug 18 to 20` rather than `Aug 18-20`

After generating a document, grep for `—`, `–`, and ` - ` before handing it over. Missed instances hide in HTML attributes, headings, alt text, and generated code comments.

## Markdown for pasting: no hard wraps

When writing markdown the user will paste somewhere (PR descriptions, Slack messages, docs, issue bodies), do not hard-wrap paragraph text at a fixed column. Keep one line per paragraph and per list item and let it soft-wrap in the editor, even if lines get long.

The user reflows or removes line breaks from generated markdown before using it, so pre-wrapped text is extra work to undo.

The full PR description format lives in the `pr-description` skill.

## Comments: default to none, and keep the rest to one line

Write no comment unless a reader who already understands the code would still be confused. The bar is genuine unclarity, not "this seems worth explaining".

When one earns its place, one line. Two at the absolute most, never a paragraph. If it needs more, the code needs a better name or a smaller function.

Only these justify a comment:

- Why a non-obvious choice was made, when the obvious one is wrong
- A constraint imposed from elsewhere in the system that the code cannot show
- A subtle contract on an exported value

Do not write, and delete on sight:

- Restatements of the next line, or narration of structure ("renders X, then Y")
- Labels for things already named (`/** User ID */` above `userId`)
- A component or function description that its name already carries
- Test comments that repeat the assertion below them

If a comment feels necessary because the name is unclear, rename instead. When editing existing code, cut comments that fail this bar rather than matching their density.

## "Comments" from the user means Hunk review comments

When the user says they "added comments", "made comments", "left comments", or "commented", and asks to fix or address them, they almost always mean inline review comments in a Hunk diff session, not code comments and not GitHub PR comments.

Load the `hunk-review` skill for the CLI flow. Never perform git operations while addressing them.
