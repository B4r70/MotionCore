---
name: swift-standards
description: MotionCore Swift coding standards and conventions. Use when writing, reviewing, or refactoring Swift code. Also use when creating new files or splitting large files.
---

# Swift Coding Standards — MotionCore

## Naming

- Types: `UpperCamelCase` (`ExerciseSet`, `StatBubble`)
- Properties / Methods: `lowerCamelCase` (`totalVolume`, `formatDuration()`)
- CalcEngines: `[Domain]CalcEngine` (`ProgressionCalcEngine`, `RecordCalcEngine`)
- ViewModels: `[Domain]ViewModel` (`ProgressionViewModel`)
- Views: `[Feature]View`, `[Feature]Card`, `[Feature]Sheet`, `[Feature]Row`
- Types files: `[Domain]Types.swift` for domain-scoped enums + small structs

## File Structure

Swift file order:

1. File header (copy from existing file)
2. `import` statements
3. Main type definition
4. `// MARK: -` sections in order:
   - Properties
   - Body (Views)
   - Subviews (`private var`)
   - Helper Functions
5. Extensions
6. Preview

## File Size and Separation

- Target: **max 400 lines per file**
- Hard warning: files above **600 lines** split
- 800–1000+ lines (`ActiveWorkoutView.swift`) = extract now

### When to extract into a separate file

- Helper functions reused or reusable → utility file
- Subview has own state (`@State`, `@Binding`) → own View file
- `// MARK: -` section > ~150 lines → extract
- Same formatting logic in many files → shared helper (e.g. `AppFormatter.swift`)
- CalcEngine method group outgrows domain → split into focused CalcEngine

### How to name extracted files

- Subview from `ActiveWorkoutView` → `ActiveWorkout[Section]View.swift` (e.g. `ActiveWorkoutStatsSection.swift`)
- Shared helpers → `[Domain]Helper.swift` or existing utilities
- Reusable UI components → shared components directory

### What stays together

- View + tightly coupled private subviews (< 400 lines total)
- CalcEngine + directly related result types (if small)
- Extension only meaningful in parent file context

## SwiftUI Views

- Subviews as `private var` computed properties
- No business logic in `body` or computed view properties
- `@EnvironmentObject` for app-wide state (`AppSettings.shared`)
- Prefer `.task {}` over `.onAppear` for async work
- `.onChange(of:)` for reactive updates
- Large lists → `LazyVStack` / `LazyVGrid`
- `scrollViewContentPadding()` over manual `.padding(.horizontal)`
- Cards always `.glassCard()`
- Empty states always `EmptyState()`

## SwiftData Models

- Stored properties: optional or with default
- Inverse relationships mandatory
- Computed properties for derived data
- Safe accessor: `var safeItems: [Item] { items ?? [] }`
- Prefer `exerciseNameSnapshot` over `exerciseName`

## CalcEngine Pattern

- **Pure structs**, no state, no side effects
- Data via initializer or method parameters
- Return computed results, never modify models
- Views call CalcEngines, no business logic in Views
- One CalcEngine per domain (statistics, records, progression, etc.)

## Code Quality

- No workarounds — fix root cause
- No force-unwraps without documented reason
- No `\n` in SwiftUI `Text` — separate views
- No `Timer.scheduledTimer` for background-sensitive timing — use `Date` anchors
- Remove debug `print` before task done
- Check existing shared types before creating new ones

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

## MotionCore Project Rules

- `StatsAndRecordsView` segments: `.statistics`, `.records`, `.heatmap`
- `BaseView.Tab`: `summary`, `workouts`, `stats`, `body`, `training` (5 tabs)
- Architecture: CalcEngines in `Services/Calculation/` (pure, stateless), Views koordinieren ohne Business-Logik
