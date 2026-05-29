---
description: "Hands selected review findings to motioncore-developer for implementation. Findings marked 'Discussion Wanted: Yes' are rejected — discuss with Claude first."
argument-hint: "<ID1> [ID2] [ID3] ... (e.g. L3-007 L3-012 L1-Watch-003)"
---

# /fix-review {{args}}

You orchestrate the implementation of selected review findings via
`motioncore-developer`. You do not implement anything yourself.

## Argument parsing

Arguments: one or more issue IDs in the format
`L{layer}[-{scope}]-{seq:03d}`, where `{layer}` is `1`–`5`, `{scope}`
is an optional `UpperCamelCase` tag with no digits and no inner
hyphens, and `{seq:03d}` is a zero-padded 3-digit number.

Valid: `L3-007`, `L3-012`, `L1-Watch-003`, `L4-LiveActivity-012`
Invalid: `L3-7`, `L6-001`, `L1-watch-003`, `L1-Watch-3`

A trailing `--force` (must be the last argument) is recognized
separately and is not parsed as an ID.

If no ID is provided: ask Bartosz which findings to fix, then abort.
Do NOT speculatively start the developer.

If an ID does not match the format: show an error message naming the
offending token and abort.

## Flow

### 1. Collect findings

Read all review files under:

`~/developments/MotionCore/.claude/reviews/review-L*-*.md`

For each requested ID:

- **Found** → extract the full finding block. A finding runs from its
  `### [ID] ...` header to the next `### ` header (or end of file). Per
  schema, findings contain no inner `###`-level headers, so this slice
  is unambiguous; if you ever encounter an inner `###`, treat the first
  one after the ID header as a schema violation and flag it to Bartosz
  rather than silently truncating.
- **Not found** → record in a "Not found IDs" list
- **Found multiple times** (e.g. overlapping reviews) → take the
  finding from the most recent review file (by filename date, then
  file mtime as tiebreak)

### 2. Check gates

Before anything goes to the developer, check each found finding:

#### Gate A: Discussion wanted
If the field `Discussion Wanted:` has the value `Yes` → **reject**.
Tell Bartosz: "Finding {ID} is marked as needing discussion. Discuss
with Claude first, then call /fix-review again."

#### Gate B: Locked areas
Read the finding's `Touches Locked Area:` field.
- If it is `Yes` → **reject**. Reason: "Finding {ID} touches a locked
  area (ExerciseRating / PlanUpdateCalcEngine). Apply as a minimal bug
  patch only — not via /fix-review."
- If the field is **missing** from the finding (older review file
  predating the schema field) → fall back to a heuristic: if the
  finding text or fix mentions `ExerciseRating` or
  `PlanUpdateCalcEngine` structurally, **reject** with the same reason
  and note that the field was absent. When in doubt, reject and ask
  Bartosz.

#### Gate C: Severity sanity
If the list contains more than one 🔴 Critical and Bartosz did not pass
`--force` as the last argument → **warn**: "{n} Critical findings at
once. Recommendation: implement one by one with a build verify in
between. Proceed anyway?" Wait for an answer.

### 3. Cluster grouping

If multiple IDs were passed, check the `Related Findings:` field of
each finding. Form groups:

- IDs that reference each other → one group
- All others → their own single-item groups

Example:
- `L3-007` lists "Related: L3-012"
- `L3-012` lists "Related: L3-007"
- `L1-Watch-003` lists no related findings
→ Two groups: `{L3-007, L3-012}` and `{L1-Watch-003}`

### 4. Brief motioncore-developer

One separate call to the developer per group (sequential, NOT
parallel). Task template:

```
Phase {n} of {total}: implement review findings {IDs of the group}

Source: ~/developments/MotionCore/.claude/reviews/{review file}

Embedded finding block:
---
{full finding block, copied from the review file}
---

Task:
1. Implement ALL findings of this group in one coherent edit.
2. Follow the "Concrete Fix" suggestion exactly where technically
   possible. On deviation: briefly justify.
3. Respect MotionCore conventions (swift-standards skill, file-size
   discipline, ExerciseRating/PlanUpdateCalcEngine untouched).
4. After every file change: short status report with path and
   line range.
5. Do NOT build, do NOT test — Bartosz does that manually.
   STOP gate.

Note: if while implementing you find the fix suggestion is wrong or
would create a follow-up problem: STOP, describe the issue, wait for
instructions. Do not silently replan.
```

### 5. Build verification (mandatory STOP gate)

After all code changes of a phase are done:

5a. **Send the build request** using EXACTLY this wording:

    "Phase {n} ({IDs}) — code changes complete.

     Changed files:
     - <path>
     - <path>

     Now in Xcode: Cmd+Shift+K (Clean), then Cmd+B (Build).

     Reply with:
       • 'green' if the build succeeded
       • 'red: <error message>' if it failed

     I am waiting for this explicit reply before continuing."

5b. **Wait for the reply.** Accept only:
    - "green" / "grün" / "build green" / "build grün" → phase verified
    - "red: …" / "rot: …" / a clear error message → phase NOT verified

    Do NOT accept as a build confirmation:
    - "yes" / "ja"
    - "ok"
    - "go on" / "weiter"
    - "patch the review file" / "patche die Review-Datei"
    - "all good" / "alles gut"

    If the reply is ambiguous: ask again, this time with the hint:
    "I need an explicit 'green' or 'red'."

5c. **If 'red':** hand the error message to motioncore-debugger or
    directly to Bartosz for a decision. Do NOT patch the review file.
    End the phase without a status marker.

5d. **If 'green':** only then patch the review file with
    `**Status:** ✅ Implemented on {YYYY-MM-DD}. {short description}`
    at the top of the finding block.

    Then ask Bartosz: "Phase {n} verified ✅. Should I prepare a commit,
    or will you commit manually?"

### 6. Wrap-up

When all phases are done:

- List of implemented IDs
- List of rejected IDs (with reason per ID)
- Note: "Implemented findings should be marked in the review file.
  Want me to patch
  `~/developments/MotionCore/.claude/reviews/{file}` and mark the IDs
  as `**Status:** ✅ Implemented on {date}`?"

Wait for an answer — mark only after confirmation.

## Important

- You (the Claude Code main conversation) do NOT modify any source files.
- You orchestrate; the developer implements; Bartosz verifies.
- Never two phases without a STOP gate in between.
- Unsure about a finding's content → back to Bartosz, not the developer.
- If the developer wants to implement a fix differently than the
  finding proposes → STOP, escalate to Bartosz.