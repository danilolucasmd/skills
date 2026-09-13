---
name: github-cli
description: Do anything that lives on GitHub through the `gh` CLI. Use when the user asks to open, create, update or list a pull request, push a branch for review, file or read an issue, check CI or a failing check run, look at a PR's diff or status, merge, tag or cut a release. `gh` is installed and already authenticated on the user's machines, so never send them to the web UI and never ask them to paste a token.
---

# GitHub through `gh`

Everything that touches GitHub goes through `gh`. It is installed and authenticated on every machine the user works on.

Never tell the user to open a browser, click "New pull request", or copy a URL into the GitHub web UI. Never run `gh auth login`, and never ask for a token: if a command reports missing auth, say so and stop, because the fix is theirs.

Prefer a real subcommand over `gh api`. Reach for `gh api` only when no subcommand covers the request.

## Authorization

The global git rule stands: no git operation unless the user asked for it in that request.

"Open a PR", "create the PRs", "push this for review" IS the authorization, and it covers exactly the push of the branches involved and the create. It does not extend to merging, closing, deleting branches, or editing anything else on the repo. Merging is a separate ask, every time.

## Pull requests

The title and body format is the `pr-description` skill. Load it rather than inventing a shape.

Write the body to a file and pass `--body-file`. A multi-line body through `--body` gets mangled by shell quoting, and backticks in it will run as commands.

```sh
git push -u origin <branch>
gh pr create --base <base> --head <branch> --title "<title>" --body-file <file>
```

`gh pr create` needs the branch on the remote first, so push before creating.

## Stacked PRs

Each PR in a stack targets the branch below it, not the default branch. Only the bottom one targets the default branch. Push every branch before creating any of them, so each `--base` already exists on the remote.

Say in each body which PR it sits on, so a reviewer landing on the fifth one knows what came before.

After creating them, verify the chain reads the way you intended:

```sh
gh pr list --state open --json number,title,baseRefName,headRefName
```

`stacked-prs` is the skill for rebasing a chain that already exists.

## Reading state

Use `--json` with `-q` for anything you are going to act on, and plain output only for something the user reads.

```sh
gh pr checks <number>
gh run list --branch <branch> --limit 5
gh run view <run-id> --log-failed
```

`--log-failed` is the one worth remembering: it prints only the failing step's log instead of the whole run.

## Reporting back

Give the user the URL. That is what they asked for, and a PR number alone makes them go look it up.
