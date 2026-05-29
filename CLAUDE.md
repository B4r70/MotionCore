# MotionCore — CLAUDE.md

## Language & Communication
German responses, English code/vars, German comments. Keep technical terms original.

## Working Mode
Plan first for non-trivial tasks. Fix root cause, no workarounds. Minimize impact. No silent product assumptions. Follow-up questions only for real UX/data decisions. Check `tasks/lessons.md` after user corrections.

## Project Context
iOS fitness app: SwiftUI, SwiftData, Swift Charts, HealthKit, ActivityKit, Supabase. iOS 17+. No XCTest. Build via Xcode `Cmd+B`. Previews use `PreviewData.sharedContainer` + `AppSettings.shared`.

## Architecture
- CalcEngines in `Services/Calculation/` (pure, stateless)
- Views coordinate, no business logic
- Check existing types before creating new
- `App/AppSchema.swift` is the single source for the SwiftData model schema — add new models there
- See `.claude/skills/swift-standards/SKILL.md` for standards

## Critical Gotchas (⚠️ NOT OBVIOUS FROM CODE)

### Supabase CodingKeys Trap
**If CodingKeys enum exists, ALL fields must be listed explicitly.** Otherwise fields silently missing from payload (even without `convertToSnakeCase`).

### CloudKit UUID Default Bug
**`var xxxUUID: UUID = UUID()` evaluated ONCE on schema migration**, not per record. Use `deduplicateAllSyncUUIDs()` when adding new models.

### Sheet Pattern
**Always `.sheet(item:)`, NEVER `.sheet(isPresented:)` + separate ID.** Empty sheet on first call after app-start.

### HealthKit Read Auth
**`authorizationStatus` for read types always `.notDetermined`**. New types need fresh `requestAuthorization()` before first query.

### Watch Message Drop
**`WCSession.sendMessage` dropped when `isReachable == false`.** Fix: `onWatchBecameReachable` sends `startHealthTracking` + heartbeat when `isWatchTrackingActive == false`.

### Watch Discard Workflow
**`HKLiveWorkoutBuilder.discardWorkout()` only valid after `await builder.endCollection(at:)`.** Without await, discard silently ignored → workout saved to Health. Must be async.

### Watch Countdown Display
**Use `Text(timerInterval: Date()...endDate, countsDown: true)`**, NOT `Text(date, style: .timer)` (counts up after expiry).

### Smart Progression RIR/RPE
**`ExerciseSet.rpe` stores `10 - RIR`** (RIR 0→rpe 10, RIR 4→rpe 6). **`rpe == 0` means "not captured"**, NOT RIR 10. `ProgressionCalcEngine.hasRIRData` guards with `rpe > 0`.

### ExerciseQualityRating Split
**`icon`/`label` in `StrengthTypes.swift` (Foundation), `color: Color` extension in `TypesUI.swift` (SwiftUI).** Use pattern for enums with UI properties.

### Muscles Heatmap SVG
**`Muscles_Heatmap.svg` has inline `fill` on paths.** CSS-override in WebView needs `!important`.

## Project Rules (kritisch, immer beachten)
- **Supabase: all tables UNRESTRICTED (no RLS)** — never `ENABLE ROW LEVEL SECURITY`
- Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`

UI-Conventions, Key-Types und weitere Project-Rules siehe `.claude/skills/swift-standards/SKILL.md`.

## Artifacts
Active plan: `tasks/current.md`. Quality: `tasks/quality/`. Domain: `tasks/domain/`. Archive: `tasks/archive/`. Lessons: `tasks/lessons.md`.

## Git
Prefixes: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`. Branches: `feature/`, `refactor/`, `fix/`. No force-push to `main`.

<!-- caliber:managed:pre-commit -->
## Before Committing

**IMPORTANT:** Before every git commit, you MUST ensure Caliber syncs agent configs with the latest code changes.

First, check if the pre-commit hook is already installed:
```bash
grep -q "caliber" .git/hooks/pre-commit 2>/dev/null && echo "hook-active" || echo "no-hook"
```

- If **hook-active**: the hook handles sync automatically — just commit normally. Tell the user: "Caliber will sync your agent configs automatically via the pre-commit hook."
- If **no-hook**: run Caliber manually before committing:
  1. Tell the user: "Caliber: Syncing agent configs with your latest changes..."
  2. Run: `caliber refresh && git add CALIBER_LEARNINGS.md CLAUDE.md .claude/ 2>/dev/null`
  3. After it completes, briefly tell the user what Caliber updated. Then proceed with the commit.

**Valid `caliber refresh` options:** `--quiet` (suppress output) and `--dry-run` (preview without writing). Do not pass any other flags — options like `--auto-approve`, `--debug`, or `--force` do not exist and will cause errors.

**`caliber config`** takes no flags — it runs an interactive provider setup. Do not pass `--provider`, `--api-key`, or `--endpoint`.

If `caliber` is not found, tell the user: "This project uses Caliber for agent config sync. Run /setup-caliber to get set up."
<!-- /caliber:managed:pre-commit -->

<!-- caliber:managed:learnings -->
## Session Learnings

Read `CALIBER_LEARNINGS.md` for patterns and anti-patterns learned from previous sessions.
These are auto-extracted from real tool usage — treat them as project-specific rules.
<!-- /caliber:managed:learnings -->

<!-- caliber:managed:model-config -->
## Model Configuration

Recommended default: `claude-sonnet-4-6` with high effort (stronger reasoning; higher cost and latency than smaller models).
Smaller/faster models trade quality for speed and cost — pick what fits the task.
Pin your choice (`/model` in Claude Code, or `CALIBER_MODEL` when using Caliber with an API provider) so upstream default changes do not silently change behavior.

<!-- /caliber:managed:model-config -->

<!-- caliber:managed:sync -->
## Context Sync

This project uses [Caliber](https://github.com/caliber-ai-org/ai-setup) to keep AI agent configs in sync across Claude Code, Cursor, Copilot, and Codex.
Configs update automatically before each commit via `caliber refresh`.
If the pre-commit hook is not set up, run `/setup-caliber` to configure everything automatically.
<!-- /caliber:managed:sync -->

## GBrain Configuration (configured by /setup-gbrain)
- Mode: local-stdio
- Engine: pglite
- Config file: ~/.gbrain/config.json (mode 0600)
- Setup date: 2026-05-29
- MCP registered: yes (user scope)
- Embedding provider: none working (OPENAI_API_KEY returns 401) — keyword/full-text search works, semantic + symbol search disabled until a valid embedding provider is set + `gbrain embed --stale` runs once
- Artifacts sync: artifacts-only → private repo github.com/B4r70/gstack-artifacts-bartosz (federated gbrain source "gstack-artifacts-bartosz")
- Transcript ingest: incremental (historical bulk deferred until embeddings work; then run `/sync-gbrain --full`)
- Current repo policy: read-write (git.barto.cloud/barto/motioncore)
- gstack: upgraded to v1.52.1.0

## GBrain Search Guidance (configured by /sync-gbrain)
<!-- gstack-gbrain-search-guidance:start -->

GBrain is set up on this machine (local PGLite). The agent should prefer gbrain
over Grep when the question is semantic or when you don't know the exact
identifier yet. Indexed corpus available via the `gbrain` CLI / `mcp__gbrain__*`:
- This repo's markdown docs (registered read-write; 109 pages imported).

Prefer gbrain when:
- "Where is X handled?" / semantic intent, no exact string yet:
    `gbrain search "<terms>"` or `gbrain query "<question>"`
- "What did we decide last time?" / past plans, concepts, docs:
    `gbrain search "<terms>"`

Note: embeddings are NOT yet generated (no embedding provider configured), so
`gbrain search` currently runs keyword/full-text matching only. Semantic ranking
and `gbrain code-def`/`code-refs`/`code-callers` activate once an embedding
provider (Voyage/OpenAI API key, or local Ollama) is set and `gbrain embed --stale`
has run. Until then, Grep remains the right tool for exact code-symbol lookups.

Grep is still right for known exact strings, regex, multiline patterns, and
file globs. Run `/sync-gbrain` to force-refresh, `/sync-gbrain --full` for full reindex.

<!-- gstack-gbrain-search-guidance:end -->
