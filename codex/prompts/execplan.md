---
description: Create or update an ExecPlan using ~/.codex/.agent/PLANS.md
argument-hint: GOAL="<what to build/refactor>" OUT="<repo-relative path to plan md>"
---

You are Codex running in a repository workspace.

First, read and fully internalize these instruction sources:
- ~/.codex/AGENTS.md (global agent instructions)
- ~/.codex/.agent/PLANS.md (ExecPlan specification)

Then, produce an ExecPlan that follows PLANS.md *to the letter*.

Task goal: $GOAL
Write the ExecPlan to: $OUT
