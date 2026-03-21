---
description: Runs the MotionCore workflow with automatic complexity scaling. Small tasks skip planning; all tasks end with a single quality gate.
---

# Dev Workflow

Task: $ARGUMENTS

## Phase 1 — Planning

1. Delegate to `motioncore-planner`
2. Create `tasks/current.md` (compact, standard, or full format based on assessed complexity)
3. Present the plan to the user

**HARD STOP**
Request exactly **one** approval for implementation.

**Exception — Small complexity:**
If the planner assesses the task as **Small** (bug fix, single file, < 50 lines), skip the hard stop and proceed directly to Phase 3 after presenting the plan.

## Phase 2 — Optional Domain Validation

Only if fitness logic is affected **and** complexity is Medium or Large:

1. Delegate to `motioncore-fitness-expert`
2. Write the report to `tasks/domain/...`
3. If major domain issues exist: inform the user and stop

## Phase 3 — Implementation

1. Delegate to `motioncore-developer`
2. Implement all approved open steps from `tasks/current.md`
3. Developer updates progress in `tasks/current.md`

No stop after every individual step.
Only stop if:
- a real product decision is missing
- a critical issue changes the direction
- a step from `tasks/current.md` cannot be completed as specified

## Phase 4 — Quality Gate

1. Delegate to `motioncore-quality-gate`
2. Write the report to `tasks/quality/...`

This is a single pass covering both code review and static verification.

If fundamental issues are found:
- inform the user
- stop before claiming completion

## Phase 5 — Wrap-Up

- What was implemented?
- Which files were changed?
- What does the quality gate say?
- Which manual checks still need to be performed?

## Rules

- Provide short updates between phases
- Do not ask unnecessary questions
- Stop only for real direction-changing decisions
- Never mark the task complete without the quality gate
- Small tasks: 3 phases (plan → implement → quality gate)
- Medium tasks: 3–4 phases (plan → [domain] → implement → quality gate)
- Large tasks: 4–5 phases (plan → [domain] → implement → quality gate)
