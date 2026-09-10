---
name: stacked-prs
description: Restack and push the branches above the current one in a stacked-PR chain. Use when the user says "rebase the stack", or asks to restack, rebase, or update the branches sitting on top of the current branch.
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
