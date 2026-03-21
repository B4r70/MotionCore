# MotionCore — CLAUDE.md

## Language & Communication

- Always respond in German
- Use English for code and variable names
- Use German for code comments
- Keep technical terms, type names, class names, and method names in their original form

## Guiding Principles

- Prefer the simplest viable solution
- Fix the root cause instead of adding workarounds
- Minimize impact: only change what is actually necessary
- Respect the existing architecture
- Do not make silent assumptions on product decisions

## Working Mode

- Plan first for all non-trivial tasks
- For bug fixes, analyze autonomously and resolve the issue
- Do not ask about technical uncertainty if it can be clarified through analysis
- Only ask follow-up questions for real product / UX / data model decisions
- Never mark a task as done without review and verification
- After every relevant user correction, check whether `tasks/lessons.md` should be updated

## Project Context

MotionCore is an iOS fitness app built with SwiftUI, SwiftData, Swift Charts, HealthKit, ActivityKit, and Supabase.
Deployment target: iOS 17+.
There is no XCTest suite; verification is done through Xcode build, SwiftUI previews, and the simulator.

## Build & Test

- Build only in Xcode with `Cmd+B`
- Do not invent CLI build commands
- Use `PreviewData.sharedContainer` as the `modelContainer` in previews
- Use `AppSettings.shared` as the `EnvironmentObject` in previews

## Architecture

- Business logic belongs in `Services/Calculation/` as pure, stateless CalcEngines
- Views render UI and coordinate interaction, but do not contain business logic
- Always check for existing shared types before creating new ones
- For detailed Swift coding standards, file size limits, and extraction rules, see `.claude/skills/swift-standards/SKILL.md`

## SwiftData / CloudKit

- Attributes should be optional or have default values
- Inverse relationships are mandatory
- Do not change the production schema lightly
- For risky schema work, prefer local / dev-safe paths

## UI Conventions

- Cards should always use `.glassCard()`
- Background: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty state: `EmptyState()`
- Use `scrollViewContentPadding()` instead of duplicating manual horizontal padding

## Important Existing Types

- Statistics: `TrendPoint`, `IntensitySummary`, `DonutChartData`, `ProgramSummary` → `StatisticCalcEngine.swift`
- Records: `StrengthRecord` → `StrengthRecordCalcEngine.swift`
- Time filtering: `SummaryTimeframe`, `TimeframePicker`
- UI components: `StatisticGridCard`, `StatisticCard`, `RecordGridCard`, `StrengthRecordGridCard`

## MotionCore-Specific Rules

- Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`
- `StatsAndRecordsView` only uses `.statistics` and `.records`
- `BaseView.Tab`: `summary`, `workouts`, `stats`, `analyse`, `training`

## File System for Work Artifacts

- Active plan: `tasks/current.md`
- Reviews: `tasks/reviews/`
- Verifications: `tasks/verifications/`
- Domain validations: `tasks/domain/`
- Archived plans: `tasks/archive/`
- Lessons learned: `tasks/lessons.md`

Agents create subdirectories automatically if they do not exist yet.

## Git Conventions

- Commit prefixes: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`
- Branch schema: `feature/`, `refactor/`, `fix/`
- No force-push to `main`
