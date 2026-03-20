---
description: Runs the full MotionCore workflow: Plan → optional domain validation → implementation → review → verification.
---

# Full Dev Workflow

Task: $ARGUMENTS

## Phase 1 — Planning

1. Delegate to `motioncore-planner`
2. Create `tasks/current.md`
3. Present the plan to the user

**HARD STOP**
Request exactly **one** approval for implementation.

## Phase 2 — Optional Domain Validation

Only if fitness logic is affected:

1. Delegate to `motioncore-fitness-expert`
2. Write the report to `tasks/domain/...`
3. If major domain issues exist: inform the user and stop

## Phase 3 — Implementation

1. Delegate to `motioncore-developer`
2. Implement all approved open steps from `tasks/current.md`
3. Update progress in `tasks/current.md`

No stop after every individual step.
Only stop if:
- a real product decision is missing
- a critical issue changes the direction
- a step from `tasks/current.md` cannot be completed as specified

## Phase 4 — Review

1. Delegate to `motioncore-reviewer`
2. Write the report to `tasks/reviews/...`

If fundamental issues are found:

- inform the user
- stop before claiming completion

## Phase 5 — Verification

1. Delegate to `motioncore-verifier`
2. Write the report to `tasks/verifications/...`
3. List manual build / preview / simulator checks

## Phase 6 — Wrap-Up

- What was implemented?
- Which files were changed?
- What does the review say?
- What does the verification say?
- Which manual checks still need to be performed?

## Rules

- Provide short updates between phases
- Do not ask unnecessary questions
- Stop only for real direction-changing decisions
- Never mark the task complete without review and verification
