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

Rules:
- The plan must be fully self-contained for a novice with only the repo + this plan file.
- Use the PLANS.md skeleton and requirements, including Progress/Surprises/Decision Log/Outcomes.
- Name repository-relative files precisely; verify by reading the repo as needed.
- Include concrete commands and expected outputs.
- Do not ask the user for next steps; proceed to a complete plan.
- When writing the plan file whose only content is the ExecPlan, omit outer triple-backticks (per PLANS.md).
