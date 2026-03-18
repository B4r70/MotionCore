---
description: Runs the complete development workflow — planning, implementation, review, and verification as a pipeline with subagents.
---

# Full Development Workflow

You are now orchestrating the complete development cycle for the following task:

**Task:** $ARGUMENTS

## Pipeline

### Phase 1: Planning
Delegate to the **motioncore-planner** agent:
- Analyze the requirement
- Create a detailed plan in `tasks/todo.md`
- Identify affected files and risks

**Wait for the result and present the plan to the user.**
**Ask the user: "Soll ich mit der Implementierung fortfahren?" (Should I proceed with implementation?)**

### Phase 1.5: Domain Validation
Delegate to the **[project]-fitness-expert** agent:
- Validate the plan against real-world training practices
- Check default values and formulas

**If the expert flags issues: Present them to the user before proceeding.**

### Phase 2: Development
Only if the user confirmed the plan. Delegate to the **motioncore-developer** agent:
- Execute the plan from `tasks/todo.md` step by step
- Mark each completed step

**Summarize the changes.**

### Phase 3: Review
Delegate to the **motioncore-reviewer** agent:
- Review the implemented code
- Document findings in `tasks/todo.md`

**If critical findings exist: Inform the user and wait for instructions.**

### Phase 4: Verification
Delegate to the **motioncore-verifier** agent:
- Check consistency and potential build errors
- Create a list of manual verification steps

**Present the overall result with a summary to the user.**

## Rules
- Report to the user between phases
- On critical issues in any phase: STOP and ask the user
- At the end: Summary of all changes and next steps