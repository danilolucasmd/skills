---
name: pr-comments-review
description: Address a reviewer's comments on a GitHub pull request one comment at a time, with the user approving each fix before it is committed. Use when the user says "address the review comments", "go through the comments on PR 123", "fix the review comments one by one", "let's handle the comments on this PR", or pastes a PR review link (a URL ending in `#pullrequestreview-<id>`). This is about comments left on GitHub, not inline Hunk notes; if the user just says they "left comments" with no PR or link, that is `hunk-review`.
---

# Addressing PR review comments

The user walks through a reviewer's GitHub comments with you, one at a time. You fix one, show it, and wait. They approve, ask for changes, or set it aside. Nothing is committed or pushed until they say so, and nothing is ever posted on GitHub unless they ask for that specifically.

## Read the comments

Fetch the review's comments, or all of the PR's comments if no review was named:

```sh
gh api "repos/<owner>/<repo>/pulls/<n>/reviews/<review-id>/comments?per_page=100"
gh api "repos/<owner>/<repo>/pulls/<n>/comments?per_page=100"
```

For each comment note its `id`, author, `path`, line, body, and `in_reply_to_id`.

- A comment with `in_reply_to_id` is a reply in someone else's thread. Fetch the parent (`gh api repos/<owner>/<repo>/pulls/comments/<parent-id>`) before acting on it. A reply such as "+1, this is confusing" is about the parent comment's subject, not a standalone request.
- List the comments for the user in order, with id, file, and line, and say which are top-level and which are replies.
- If the user asks to focus on one reviewer's top-level comments first, do those and park the reply threads until the end.

## One comment at a time

1. Make the fix for exactly one comment, on the branch that PR belongs to. For a stacked PR that is the PR's own branch, not the top of the stack. If that means switching branches in the worktree the user's dev server runs from, say so, since the app they are testing will change.
2. Verify before showing it: typecheck, the tests scoped to what changed, and lint and format on the changed files.
3. Leave it uncommitted. Show the diff, quote the comment, say in a few lines what changed and which checks ran, and stop.
4. Wait. When the user says something like "commit and go to the next comment", commit only that change, then take the next comment. If they ask for changes, revise and show the diff again.

When comments overlap, so that fixing a later one would undo or subsume an earlier one (a rename now and a removal later, for example), ask whether to do them separately or together before editing anything.

To set a comment aside, save its edit and clean the tree so it cannot slip into the next commit:

```sh
git diff > /tmp/<pr>-comment-<id>.patch
git apply -R /tmp/<pr>-comment-<id>.patch
```

Reapply it later with `git apply`. This rewrites working tree files only, not history.

## Mechanical changes

- For a rename or other edit repeated across many files, use a script that asserts the number of replacements per file, then confirm nothing of the old name remains.
- Rename files with plain `mv`, not `git mv`. When the user approves, stage both the deletion and the new file so git records a rename.

## Git

This workflow grants no git authority beyond what the user states for each step.

- Commit only when the user says to, one commit per approved comment, in the user's name, with no co-author or session trailer.
- Do not push, rebase, restack, force push, create a branch, or create a worktree unless the user asks for that in so many words. "Commit and go to the next comment" is permission to commit, nothing more.
- If you run a git operation the user did not ask for, say so plainly and ask how to undo it rather than undoing it on your own.
- Never reply to, resolve, or react to review comments on GitHub unless the user explicitly asks you to. Approving a fix, committing it, or finishing the review is not a request to reply. Draft a reply in the chat if it helps, but do not post it.

## Finishing

When every comment is handled and the user says to wrap up:

1. Restack the branches above, if the PR is part of a stack (see `stacked-prs`). Carry any renames from this PR into the branches above, which may still use the old names.
2. Push.
3. Only if the user explicitly asks: reply on each thread with the commit that addressed it, or why it was left as is.
