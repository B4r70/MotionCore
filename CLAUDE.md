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

## UI Conventions
- Cards: `.glassCard()`
- Background: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty: `EmptyState()`
- Scroll padding: `scrollViewContentPadding()`, not manual

## Key Types
- Stats: `TrendPoint`, `IntensitySummary`, `DonutChartData`, `ProgramSummary` → `StatisticCalcEngine.swift`
- Records: `StrengthRecord` → `StrengthRecordCalcEngine.swift`
- Time: `SummaryTimeframe`, `TimeframePicker`
- UI: `StatisticGridCard`, `StatisticCard`, `RecordGridCard`

## MotionCore Rules
- Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`
- `StatsAndRecordsView`: `.statistics`, `.records`, `.heatmap` segments
- `BaseView.Tab`: `summary`, `workouts`, `stats`, `body`, `training` (5 tabs)
- **Supabase: all tables UNRESTRICTED (no RLS)** — never `ENABLE ROW LEVEL SECURITY`

## Artifacts
Active plan: `tasks/current.md`. Quality: `tasks/quality/`. Domain: `tasks/domain/`. Archive: `tasks/archive/`. Lessons: `tasks/lessons.md`.

## Git
Prefixes: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`. Branches: `feature/`, `refactor/`, `fix/`. No force-push to `main`.
