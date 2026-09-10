---
name: hunk-review
description: Read and address the user's inline review comments from a Hunk diff session. Use whenever the user says they added, made, or left "comments" on the code and asks to fix or address them, when they mention reviewing a diff, or when they name Hunk directly. Their "comments" almost never means code comments or GitHub PR comments.
---

# Addressing Hunk review comments

The user reviews diffs in Hunk, an interactive terminal diff viewer, and leaves inline notes there. Those notes are what they mean by "comments".

Never run `hunk diff` or `hunk show`. Those launch the user's TUI and will hang the session. Use the read-only CLI subcommands below.

## Flow

1. Find the session:

   ```sh
   hunk session list --json
   ```

   There may be several live sessions across repos. Pick the one whose repo or title matches the work in front of you. If two plausibly match, ask rather than guessing.

2. Read the user-authored notes:

   ```sh
   hunk session comment list <session-id> --type user --json
   ```

   Each note carries a `filePath`, a `newRange` line number, and a `body`. Address every one of them, and say explicitly if you are leaving one alone and why.

3. Make the fixes in the working tree.

4. Optionally reply on each note so the user sees what happened:

   ```sh
   hunk session reload <session-id> -- diff
   hunk session comment add <session-id> --file <path> --new-line <n> --summary "..." --author agent --focus
   ```

   Reload first so the line numbers in the reply match the post-fix diff.

Run `hunk skill path` for the full command reference.

## Constraints

- No git operations. Reading Hunk comments and fixing them is not permission to stage, commit, or push. Leave the working tree for the user to review.
- Fix the code, not the comment. A note pointing at a line is about the behavior there, not a request to annotate it.
