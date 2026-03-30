---
name: logbook-gh
description: Generate a markdown logbook summary of my GitHub activity on a repository, including merged PRs, open PRs, and reviewed PRs.
---

# Logbook GitHub activity

Use this skill when the user asks for a logbook / weekly update / status update / markdown summary of their activity on a GitHub repository.

## Goal

Produce a markdown-only summary of the authenticated user's GitHub activity on a target repository.

Include exactly these sections:

- `## Merged PRs`
- `## Open PRs`
- `## Reviews`

Under each section, output one bullet per PR with this exact item format:

- PR title [(#XXX)](Link)

## Inputs

Determine the target repository from the user's request.

Accepted repository forms:

- `owner/repo`
- a GitHub repo URL like `https://github.com/owner/repo`

Determine an optional GitHub search qualifier for the time window.

Examples:

- `updated:>=2026-03-01`
- `merged:>=2026-03-01`
- `created:>=2026-03-01`

If the user says things like:
- `since last monday`
- `since 7 days`
- `from 2026-03-01`

convert that into a GitHub search qualifier before calling the script.

Recommended mapping:

- merged PRs: prefer `merged:>=YYYY-MM-DD`
- open PRs: prefer `created:>=YYYY-MM-DD`
- reviews: prefer `updated:>=YYYY-MM-DD`

If the user does not specify a repository, use the current git remote if available.
If there is no repository, fail with a short error.

## Rules

- Output markdown only.
- Do not add prose before or after the markdown.
- Detect the authenticated GitHub login automatically.
- Prefer `gh` CLI.
- Sort items by most recently updated first.
- Deduplicate PRs within each section.
- If a section has no items, write `- None`.
- Reviews means PRs reviewed by the authenticated user.
- For reviews, exclude PRs authored by the authenticated user when possible.
- Keep the format compact and suitable for posting in a company logbook channel.

## Execution

Run:

```bash
bash "$(dirname "$0")/scripts/logbook_gh.sh" "<repo>" "<date-filter>"
