---
description: "Starts a code review of a given layer (L1–L5) via the motioncore-reviewer agent. Produces a structured Markdown file in .claude/reviews/."
argument-hint: "<L1|L2|L3|L4|L5|all> [optional scope hint]"
---

# /review {{args}}

You are starting a code review of the MotionCore code via the
`motioncore-reviewer` agent.

## Argument parsing

First argument: layer selection. Allowed: `L1`, `L2`, `L3`, `L4`, `L5`,
`all`. If invalid or empty: ask Bartosz which layer is meant, then
abort. Do NOT start the agent with an unclear scope.

All further arguments: an optional scope hint (e.g. "without Watch
companion", "Workouts area only", "Watch target only"), passed verbatim
to the agent. A scope hint that narrows to a sub-area (e.g. "Watch")
tells the reviewer to use sub-scope IDs like `L1-Watch-001`.

## Layer definitions

| Layer | Focus | Areas to examine |
|---|---|---|
| **L1** | Architecture | Module boundaries, SwiftData→CloudKit→Supabase principle, CoreSession protocol consistency, cross-layer dependencies, god objects |
| **L2** | Models & persistence | `@Model` classes, relationships, default values, CloudKit suitability, Supabase sync consistency, migration risks |
| **L3** | CalcEngines & services | Pure-struct discipline, side-effect freedom, edge cases, service singletons, async hygiene |
| **L4** | Views & state | SwiftUI state management, `@Published` hygiene, re-render traps, performance, `.sheet(item:)` convention |
| **L5** | Cross-cutting | Error handling, logging, file-size compliance (400/600/800), dead code, naming, TODOs |

## Flow

1. **Pre-flight check** — confirm these before starting the agent:
   - Does `~/developments/MotionCore/.claude/review-schema.md` exist?
     (If not: tell Bartosz and abort.)
   - Does the directory `~/developments/MotionCore/.claude/reviews/`
     exist? (If not: create it.)

2. **Determine the date** — `YYYY-MM-DD` for the filename.

3. **For `all`** — process L1, L2, L3, L4, L5 sequentially. Before
   starting L2 (and every further layer), explicitly ask Bartosz
   whether the next layer should really start, or whether he wants to
   review the L1 file first. This is a STOP gate.

4. **Start the agent** — hand the `motioncore-reviewer` exactly this
   task (fill in the values):

   ```
   Layer: {selected layer}
   Date: {YYYY-MM-DD}
   Output file: ~/developments/MotionCore/.claude/reviews/review-L{scope}-{YYYY-MM-DD}.md
   Schema: ~/developments/MotionCore/.claude/review-schema.md

   Additional scope hint from Bartosz: {further arguments, or "(none)"}

   Stick strictly to your system prompt and the schema.
   Write NOTHING outside the output file.
   If it is unclear whether something belongs to this layer, leave it
   out when in doubt and note it briefly under "Observations for other
   layers" at the end of the file.
   ```

   Note on `{scope}` in the output filename: if the scope hint narrows
   to a sub-area, use the sub-scope suffix (e.g. `L1-Watch`); otherwise
   just the layer (e.g. `L3`).

5. **After the agent finishes** — give Bartosz this summary in chat:
   - Path to the created file
   - Severity distribution (read from the executive summary)
   - Number of findings with "Discussion Wanted: Yes"
   - Note: "You can paste the file into chat now, or hand individual
     findings to motioncore-developer with `/fix-review {IDs}`."

## Important

- You (the Claude Code main conversation) do NOT review yourself.
  You only orchestrate the agent.
- You do NOT modify any source files in this command.
- If the agent is unsure mid-run and asks a question: forward it to
  Bartosz, do not answer it yourself.
- For `all`, never jump from layer to layer without a STOP gate.
- Output in german