---
name: logbook-gh-acquisition
description: Generate a markdown logbook summary of my GitHub activity on karavela-ai/acquisition, including merged PRs, open PRs, and reviewed PRs.
---

# Logbook GitHub Activity Summary for karavela-ai/acquisition

Use this skill when the user asks for a logbook / weekly update / status update / markdown summary of their activity on the GitHub repository `karavela-ai/acquisition`.

## Goal

Produce a markdown-only summary of the user's GitHub activity on:

- `karavela-ai/acquisition`

Include exactly these sections:

- `## Merged PRs`
- `## Open PRs`
- `## Reviews`

Under each section, output one bullet per PR with this exact item format:

- PR title [(#XXX)](Link)

Example:

- Improve stimuli import pipeline [(#123)](https://github.com/karavela-ai/acquisition/pull/123)

## Rules

- Output markdown only.
- Do not add prose before or after the markdown.
- Do not include repositories other than `karavela-ai/acquisition`.
- Detect the authenticated GitHub login automatically.
- Prefer `gh` CLI.
- Sort items by most recently updated first.
- Deduplicate PRs within each section.
- If a section has no items, write:
  - `- None`
- Reviews means PRs reviewed by the authenticated user.
- For reviews, exclude PRs authored by the authenticated user when possible.
- Keep the format compact and suitable for posting in a company logbook channel.

## Execution

Run:

```bash
bash "$(dirname "$0")/scripts/logbook_gh_acquisition.sh"
```
