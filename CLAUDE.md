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

## UI/Design
Siehe **`DESIGN.md`** (verbindliches Design-System, Calm 2026) — nur `Theme.*`/`AppFont.*`/`.card()` + die Bausteine aus AP 1, Akzent ist `Theme.accent` (#2C6BCB), kein Glas/Blobs, eine Leitfarbe pro Kennzahl, Dark Mode über die Asset-Catalog-Colorsets.

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

## GBrain
<!-- gstack-gbrain-search-guidance:start -->
Local PGLite, corpus: markdown docs (109 pages), repo: read-write. No embedding provider → keyword-only (no semantic ranking). Prefer gbrain for semantic/unknown-identifier queries, grep for exact strings/regex. `/sync-gbrain` to refresh.
<!-- gstack-gbrain-search-guidance:end -->
