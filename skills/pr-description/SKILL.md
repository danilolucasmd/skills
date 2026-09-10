---
name: pr-description
description: Write a pull request description in the user's required format. Use when asked to write, draft, update, or fix up a PR description, PR body, or PR title. Emits the title and body as two separate code blocks, derives a [TICKET-123] title prefix from the branch name, and fills a fixed body template.
---

# PR descriptions

## Output shape

Always emit two fenced code blocks, never one combined block: first a block containing only the title line, then a separate block containing the Markdown body. The user copies the title and the body into different fields.

## Title

Format is `[TICKET-123] Title of the PR`, with the ticket ID taken from the branch name. Branch `ddias/abc-123-some-slug` gives `[ABC-123]`. No Conventional Commit type or scope prefix, even when a repository guide asks for one.

If the branch name carries no ticket ID, emit the title without a prefix and say so, rather than inventing one.

## Body template

Use exactly this template:

````md
<!-- Keep prose under 250 words; most pull requests need much less. -->

## Context

<!-- Why is this change needed? Keep only context that affects the review decision. -->

## What Changed

<!--
Use 1-4 reviewer-level bullets. Cover behavior, contracts, and tradeoffs;
do not list files.
-->

<!--
Add `## Call Stack / Flow` only for a non-obvious path across several components.
Show the entrypoint, decisions, and side effect in a 5-10 line text tree.
-->

## Validation

<!--
What behavior did you observe beyond CI? If none, say why.
Add concise media for visible UI changes.
-->

<!-- Optional footer, no heading: `Fix ENG-1234` and related links. -->
````

## Rules for filling it in

- Keep the HTML comments in the emitted body as ongoing guidance, unless the user asks for them stripped.
- Keep prose under 250 words total. Brevity beats exhaustive explanation.
- Under "What Changed", use 1 to 4 reviewer-level bullets covering behavior, contracts, and tradeoffs. Never list files.
- Add `## Call Stack / Flow` only when a runtime path crosses several components in a non-obvious way, as a short text tree going from entrypoint to decisions to side effect.
- Under "Validation", say what was observed beyond CI, or why nothing further was needed. Add concise media for visible UI changes.
- Do not invent sections beyond this template unless asked.
- No hard wraps in the body: one line per paragraph and per list item.
- No em dashes, en dashes, or spaced hyphens as sentence punctuation. Grep the body for them before handing it over.
