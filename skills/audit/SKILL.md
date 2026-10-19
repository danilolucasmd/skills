---
name: audit
description: Audit the local changes on the current branch and post the findings as inline notes in the user's live Hunk session, plus a short summary in chat. Use when the user says "audit", "/audit", "audit my changes", "audit this branch", "review my changes", "look over what we did", or "check the diff". Local only: never reads or writes a remote PR. Not for addressing the user's own Hunk comments (that is `hunk-review`).
---

# Auditing the local changes

The user wants a second pair of eyes on work that was just done on this branch. The audit lands in Hunk, where the user already reads diffs, so findings sit next to the code they are about.

The audit is read-only. Do not edit files until the user says to fix the findings, and never run git operations beyond read-only inspection. Look only at the local repo: no `gh`, no fetch, no remote PR. Hunk and the chat are the only places output goes.

## 1. Scope the diff

1. Find the base: the branch this one was cut from. That is the default branch, unless this branch is stacked on another local branch, in which case it is the nearest local branch that `HEAD` descends from (`git merge-base --is-ancestor <branch> HEAD`). If more than one candidate fits, ask.
2. Take `git merge-base HEAD <base>` and audit everything since it: commits, staged, unstaged, and untracked files. When the current branch is the default branch itself, audit only the uncommitted changes against `HEAD`.
3. Read `git log <merge-base>..HEAD` so the audit checks the code against what the commits say they do.

## 2. Gather existing notes

Do this before touching Hunk, since a reload can drop notes.

1. Run `hunk session list --json` and pick the session for this repo. If none exists, ask the user to open Hunk and stop there. If two plausibly match, ask which one.
2. Read any notes the user already left with `hunk session comment list --repo . --type user --json`.

## 3. Load it into Hunk

Never run `hunk diff` or `hunk show`. They launch the TUI and hang the session.

1. Point it at the branch diff: `hunk session reload --repo . -- diff <merge-base>`.
2. Run `hunk session review --repo . --json` for the file and hunk structure.

## 4. Build context before judging

- Read each changed file in full, not just its hunks.
- Read the callers of any changed function, type, or exported value.
- Read the repo's `AGENTS.md` or `CLAUDE.md` for its conventions.
- Run the project's lint, typecheck, and tests when they are discoverable and cheap, in a mode that does not rewrite files (`check`, `--no-fix`). A failure is a finding. Say so if you skipped them.

## 5. What to look for

In priority order:

1. **Correctness.** Logic errors, unhandled edge cases, wrong error handling, races, callers broken by a changed signature.
2. **Security.** Injection, leaked secrets, missing authorization, unsafe handling of input.
3. **Tests.** Changed behavior with no test, assertions that were weakened or deleted.
4. **Leftovers.** Debug output, commented-out code, stray TODOs, files that should not be in the diff.
5. **Conventions.** The repo's own naming and idiom, and the user's global rules: no dash punctuation, the comment policy (flag narration and restating comments), no hard wraps in markdown.
6. **Simplification.** Duplicated logic, an existing helper that should have been reused. Only when the gain is clear.

Every finding needs a concrete failure scenario or a concrete rule it breaks. Drop anything that is only taste. Do not narrate what the diff does. Skip a point the user already made in Hunk.

## 6. Post the notes

Post everything in one batch with `comment apply`:

```sh
hunk session comment apply --repo . --stdin --focus <<'EOF'
{"comments":[{"filePath":"src/a.ts","newLine":42,"summary":"[blocker] ...","rationale":"...","author":"agent"}]}
EOF
```

- Prefix each `summary` with its severity: `[blocker]`, `[should-fix]`, or `[nit]`. Keep it to one line.
- Put the failure scenario and the suggested fix in `rationale`, in two sentences at most.
- Anchor on the new-side line the finding is about. For a deleted line use `oldLine`. If the problem is in code outside the diff, anchor on the changed line that causes it.
- Order the batch most severe first so `--focus` lands on the worst one.

## 7. Summarize in chat

After posting, give a very short summary: the counts by severity, one line per blocker and should-fix with its `file:line`, and a one-line verdict on whether the changes are ready for a PR. Do not repeat the nits or the rationale; they are in Hunk.

With zero findings, skip `comment apply` and report a clean verdict in chat.

If the user then says to fix the findings, follow `hunk-review` for the fix and reply flow, with two changes: read the audit's notes with `--type agent` as well as the user's own with `--type user`, and reload with `hunk session reload --repo . -- diff <merge-base>` rather than a bare `diff`, so the replies land on the branch diff.
