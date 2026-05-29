# MotionCore Review Schema

Binding format for all review findings produced by the
`motioncore-reviewer` agent. Every finding follows this schema exactly,
so the output stays both machine-parseable (for `motioncore-developer`
and `/fix-review`) and human-readable in chat.

---

## File Structure

Each review file is stored at:

`~/developments/MotionCore/.claude/reviews/review-L{scope}-{YYYY-MM-DD}.md`

where `{scope}` is the layer, optionally with a sub-scope suffix
(see "Issue ID Format" below). Examples:

- `review-L3-2026-05-15.md` (full L3 review)
- `review-L1-Watch-2026-05-15.md` (L1 review scoped to the Watch target)

File layout:

1. **Header block** with metadata
2. **Executive Summary** (themes + severity counts + top wins + recommendation)
3. **Findings** — grouped by file, sorted by severity within each file
4. **Observations for other layers** (optional)
5. **Statistics** and **Next Steps** (mandatory)

---

## Issue ID Format (binding — parsed by `/fix-review`)

```
L{layer}[-{scope}]-{seq:03d}
```

- `{layer}` — one of `1`, `2`, `3`, `4`, `5` (the review layer)
- `{scope}` — OPTIONAL sub-scope tag, `UpperCamelCase`, no digits, no
  hyphens inside the tag (e.g. `Watch`, `LiveActivity`, `Widgets`).
  Only used when a review deliberately narrows to a sub-area of a layer.
- `{seq:03d}` — zero-padded 3-digit sequence, unique **within one
  review file**

Valid: `L3-007`, `L1-Watch-001`, `L4-LiveActivity-012`
Invalid: `L3-7` (not padded), `L6-001` (no layer 6),
`L1-Watch-01` (seq not 3 digits), `L1-watch-001` (scope not capitalized)

**Cross-run uniqueness:** sequence numbers are only unique within a
single review file, not across review runs. To address the case where
two review files for the same layer both contain e.g. `L3-007`,
`/fix-review` always resolves an ID against the **most recent** review
file. When citing an older finding, archive or delete the superseded
review file first, or pass the explicit file path.

---

## Header Block (mandatory, top of file)

```markdown
# Code Review — Layer {scope}: {Layer/Scope Name}

**Date:** YYYY-MM-DD
**Reviewer:** motioncore-reviewer (Opus)
**Scope:** {short description of the areas examined}
**Codebase State:** {git commit hash or branch — single source of truth}
**Files Read:** {count}
**Issues Found:** {count}
```

The `Codebase State` value is the global reference commit. Individual
findings may add a per-finding `Code State:` field (see below) when a
finding's line numbers are likely to drift before it gets fixed.

---

## Executive Summary (mandatory, directly after header)

```markdown
## Executive Summary

### Severity Distribution
- 🔴 Critical: {n}
- 🟠 High: {n}
- 🟡 Medium: {n}
- 🔵 Low: {n}
- ⚪ Info: {n}

### Top Themes (what runs through the review? — list 3 to 5)
1. {theme} — affects {n} findings
2. {theme} — affects {n} findings
3. {theme} — affects {n} findings

### Top 3 Wins (what is done well?)
1. {concrete observation with file reference}
2. {concrete observation with file reference}
3. {concrete observation with file reference}

### Recommendation
{1–3 sentences: what should be tackled first? Which findings can wait?
Are there clusters that should be fixed together?}
```

The total issue count lives **only** in the header (`Issues Found`).
The severity distribution here is the per-severity breakdown — do not
restate the total to avoid drift during manual edits.

---

## Finding Schema (identical for every finding)

````markdown
### [L{layer}[-{scope}]-{seq:03d}] {short, precise headline}

**Severity:** {🔴 Critical | 🟠 High | 🟡 Medium | 🔵 Low | ⚪ Info}
**Category:** {e.g. "CalcEngine purity", "SwiftUI state", "Persistence"}
**File:** {relative path from MotionCore/}:{startLine}–{endLine}
**Related Findings:** {optional: [L3-002], [L3-005] when clustered, else —}
**Touches Locked Area:** {Yes | No}
**Code State:** {optional: commit hash — only if line numbers may drift}

**Location:**
```swift
{code excerpt — max 15 lines, unambiguously showing the spot}
```

**Problem:**
{1–3 sentences: what is the technical problem? Factual, no judgment.}

**Impact:**
- {concrete consequence 1, e.g. "tests become flaky"}
- {concrete consequence 2, e.g. "crash on empty plan"}
- {concrete consequence 3, if relevant}

**Recommended Correction:**
{1–3 sentences: which strategy solves the problem? Why this one and
not another?}

**Concrete Fix:**
```swift
{patch-ready code that can be applied directly. For larger changes:
 only the relevant lines, rest marked with // ... unchanged.}
```

**Effort:** {<5 min | ~10 min | ~30 min | ~1h | several hours}
**Risk:** {Low | Medium | High}
**Discussion Wanted:** {Yes | No}
**Discussion Reason:** {only if "Yes": concrete note on what is unclear}
````

### Field notes

- **Touches Locked Area** — set to `Yes` if the fix would structurally
  touch `ExerciseRating` (and all groupKey-based matching) or
  `PlanUpdateCalcEngine`. This field is read deterministically by
  `/fix-review` Gate B. The reviewer has the code context; do not make
  `/fix-review` guess from prose. A pure bug-fix that does not change
  structure in those areas stays `No`, but call it out in the fix text.
- **Code State** — only add when a finding sits in a file likely to
  change before the fix lands (e.g. large, actively edited files). It
  lets `motioncore-developer` notice when cited line numbers no longer
  match. Omit otherwise; the global header commit is enough.

---

## Rules for Findings

### Severity Calibration

| Severity | When to use | Examples |
|---|---|---|
| 🔴 Critical | Data loss, crash, sync corruption, memory leak in a hot path | `try?` swallows a CloudKit save error; force-unwrap on an optional from the network |
| 🟠 High | Established convention violated, clear bug trap, noticeable performance trap | CalcEngine writes UserDefaults; `@Published` triggers a view storm |
| 🟡 Medium | Code smell, moderate maintainability limit, inconsistency with neighbouring code | file at 750 lines; duplicated logic across two views |
| 🔵 Low | Style, naming, comment quality | `func calc()` instead of `func calculateScore()` |
| ⚪ Info | Observation, no action needed — awareness only | "module could later become Watch-capable" |

**Important:** do not inflate severity. If everything is "High",
nothing is "High".

### Discussion Wanted: Yes vs. No

- **No** = clear convention violation, unambiguous bug, mechanical fix
- **Yes** = real architecture trade-off, multiple valid solutions,
  unclear impact on other modules, or findings adjacent to locked areas
  (`ExerciseRating`, `PlanUpdateCalcEngine`)

For "Yes", the reason must be *concrete* ("solution A saves tokens,
solution B is more robust — trade-off open"), not generic ("could be
discussed").

### Locked Areas

Findings in the following modules are reported **as bug notes only**,
never as refactoring proposals:

- `ExerciseRating` and all groupKey-based matching
- `PlanUpdateCalcEngine` (structural changes)
- Deliberate German/English mix (UI = German, identifiers = English,
  comments = German, agent prompts = English)

If a genuine bug appears there: assign severity, set
**Touches Locked Area: Yes**, and note explicitly in the fix:
"Structural change locked — minimal patch:".

### Code Snippet Rules

- Maximum 15 lines per location
- No `...` elision in the middle of the code that demonstrates the problem
- For long methods: cite only the problematic region, with a comment
  like `// ... setup above omitted`
- Do **not** use `###`-level (or higher) Markdown headers inside a
  finding body. `/fix-review` slices a finding from its `### [ID]`
  header to the next `###`; an inner `###` would truncate the finding.
  Use bold labels or `####`+ only inside fenced code if needed.

---

## Example Finding (reference template)

````markdown
### [L3-007] ProgressionCalcEngine: side effect via UserDefaults

**Severity:** 🟠 High
**Category:** CalcEngine purity
**File:** Services/Calculation/ProgressionCalcEngine.swift:142–158
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
```swift
static func calculate(input: Input) -> Output {
    let result = computeProgression(input)
    UserDefaults.standard.set(Date(), forKey: "lastProgression")
    return result
}
```

**Problem:**
Per project convention, CalcEngines are pure structs without side
effects. The UserDefaults write breaks that guarantee.

**Impact:**
- Engine is no longer deterministically testable (tests become flaky)
- Engine cannot be used in SwiftUI previews
- State leaks between sessions without being visible to the caller

**Recommended Correction:**
Pull the side effect out of the engine. The engine returns only the
result; the caller (`WorkoutSessionManager.finishSession`) handles the
UserDefaults persistence.

**Concrete Fix:**
```swift
// In ProgressionCalcEngine.calculate(): remove the UserDefaults line
static func calculate(input: Input) -> Output {
    return computeProgression(input)
}

// In WorkoutSessionManager.finishSession(): add after the call
let result = ProgressionCalcEngine.calculate(input: progressionInput)
UserDefaults.standard.set(Date(), forKey: "lastProgression")
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** No
````

---

## File Footer (mandatory)

At the end of the review file:

```markdown
---

## Statistics

- Files read: {n}
- Lines examined (total): {n}
- Findings per 1,000 lines: {n}
- Reviewer runtime: {if known}

## Next Steps

For `motioncore-developer`:
- Recommended fix order: {list of IDs in a sensible order}
- Clusters to fix together: {ID groups}
- Findings that need manual testing: {list}

For Bartosz (discussion):
- Issues with "Discussion Wanted: Yes": {list of IDs}
```