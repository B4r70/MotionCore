# MotionCore — CLAUDE.md

## Language & Communication

- Respond in German
- English for code + variable names
- German for code comments
- Keep technical terms, type names, class names, method names original

## Guiding Principles

- Simplest viable solution
- Fix root cause, no workarounds
- Minimize impact: change only what needed
- Respect existing architecture
- No silent assumptions on product decisions

## Working Mode

- Plan first for non-trivial tasks
- Bug fixes: analyze autonomously, resolve
- No asking on technical uncertainty if analysis can clarify
- Follow-up questions only for real product / UX / data model decisions
- Never mark task done without quality gate
- After relevant user correction, check if `tasks/lessons.md` needs update

## Project Context

MotionCore is iOS fitness app: SwiftUI, SwiftData, Swift Charts, HealthKit, ActivityKit, Supabase.
Deployment target: iOS 17+.
No XCTest suite; verify via Xcode build, SwiftUI previews, simulator.

## Build & Test

- Build only in Xcode via `Cmd+B`
- No invented CLI build commands
- Previews use `PreviewData.sharedContainer` as `modelContainer`
- Previews use `AppSettings.shared` as `EnvironmentObject`

## Architecture

- Business logic in `Services/Calculation/` as pure, stateless CalcEngines
- Views render UI + coordinate interaction, no business logic
- Check existing shared types before creating new ones
- Swift standards, file size limits, extraction rules: see `.claude/skills/swift-standards/SKILL.md`

## SwiftData / CloudKit

- Attributes optional or with defaults
- Inverse relationships mandatory
- No lightly changing production schema
- Risky schema work: prefer local / dev-safe paths

## UI Conventions

- Cards use `.glassCard()`
- Background: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty state: `EmptyState()`
- Use `scrollViewContentPadding()` instead of manual horizontal padding

## Important Existing Types

- Statistics: `TrendPoint`, `IntensitySummary`, `DonutChartData`, `ProgramSummary` → `StatisticCalcEngine.swift`
- Records: `StrengthRecord` → `StrengthRecordCalcEngine.swift`
- Time filtering: `SummaryTimeframe`, `TimeframePicker`
- UI components: `StatisticGridCard`, `StatisticCard`, `RecordGridCard`, `StrengthRecordGridCard`

## MotionCore-Specific Rules

- Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`
- `StatsAndRecordsView` only uses `.statistics` and `.records`
- `BaseView.Tab`: `summary`, `workouts`, `stats`, `training`

## File System for Work Artifacts

- Active plan: `tasks/current.md`
- Quality reports: `tasks/quality/`
- Domain validations: `tasks/domain/`
- Archived plans: `tasks/archive/`
- Lessons learned: `tasks/lessons.md`

Agents auto-create subdirs if missing.

## Git Conventions

- Commit prefixes: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`
- Branch schema: `feature/`, `refactor/`, `fix/`
- No force-push to `main`
