---
description: Performs static plausibility checks and creates a manual test checklist.
---

# Verify Task

Delegate to `motioncore-verifier`.

**Scope:** $ARGUMENTS

If no scope is provided:

- use `tasks/current.md` as context
- check all affected files from the current task

Write the report to:
`tasks/verifications/YYYY-MM-DD-[task-slug]-verification.md`
