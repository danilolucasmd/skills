---
name: stacked-prs
description: Work a stacked-PR chain: restack and push the branches above the current one, or split one branch into a stack. Use when the user says "rebase the stack", or asks to restack, rebase, or update the branches sitting on top of the current branch. Also use when they ask to split or break up a branch or PR into several branches or PRs, or to turn one PR into a stack.
---

# Rebasing a stack

When the user asks to "rebase the stack", they are working in a stacked-PR chain and have **already committed and pushed** the branch they are on. The ask is about the branches *above* it.

This request is the explicit git authorization the global git rule requires, and it covers the rebases and the force pushes below. It does not extend to anything else.

## Procedure

1. For each branch that sits on the current one, in order from the bottom up: check it out and rebase it onto its parent.
2. Push each rebased branch with `--force-with-lease`.
3. Leave the working tree checked out on the **last** branch of the stack, which is where the user tests.
4. Report the old and new tips.

If the user asks for this while on the base branch of the stack, rebase and push **every** branch above it, all the way up the chain.

## Rewritten parents

Use `git rebase --onto <new parent tip> <old parent tip>` whenever the parent's history was rewritten. A plain `git rebase <parent>` will try to replay the parent's pre-rebase commits by their old SHAs.

## Checks and conflicts

- Do not re-verify the current branch or re-run its checks. The user has already handled it.
- Run a typecheck on each rebased branch.
- Resolve conflicts by keeping both sides' behavior, unless one clearly supersedes the other.

# Splitting a branch into a stack

When the user asks to split a branch or PR into several, the branch they are **currently on** becomes the bottom of the stack. It keeps its name and its PR points at `main`. Every branch above it is named after that base branch with a number appended, counting up from 2:

```
ddias/abc-123-slug     ->  main
ddias/abc-123-slug-2   ->  ddias/abc-123-slug
ddias/abc-123-slug-3   ->  ddias/abc-123-slug-2
```

Never rename the base branch, and never create a `-1`. The suffix rule holds even when the base name already ends in a digit: `ddias/abc-123-slug2` becomes `ddias/abc-123-slug2-2`.

## Procedure

1. Read the full diff of the current branch against `main`, plus its commits, so the split is based on what actually changed.
2. Propose the split before touching anything: how many branches, what goes in each, in what order. Each one has to build and pass its own checks without the branches above it. Wait for the user to agree.
3. Reset the base branch to hold only the first chunk, then build each branch above it from its parent, in order.
4. Open or retarget each PR against its parent, bottom up. The base PR points at `main`.
5. Leave the working tree on the top branch of the stack.

Splitting rewrites the base branch, so a PR already open on it needs a force push. That is covered by the same authorization as the split itself. Anything beyond the branches and PRs in the stack is not.
