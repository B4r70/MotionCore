# MotionCore — CLAUDE.md

## Language & Communication
- Always respond in German
- Code comments in German
- Variable names and code in English

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Minimal code impact.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Only touch what's necessary. Don't introduce bugs.

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep the main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until the mistake rate drops
- Review lessons at session start for the relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Verify build (`Cmd+B`), check SwiftUI Previews, test in Simulator
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing builds — then resolve them
- Zero context switching required from the user

## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

---

## Project
iOS Fitness Tracking App. SwiftUI, SwiftData, Swift Charts, HealthKit, ActivityKit, Supabase.
Deployment Target: iOS 17+. No XCTest — verification via SwiftUI Previews + Simulator.

## Build & Test
- Build: Xcode (`Cmd+B`) — no CLI build command
- Previews: `PreviewData.sharedContainer` as modelContainer, `AppSettings.shared` as EnvironmentObject
- No unit tests
- Git remote: Forgejo on git.barto.cloud

## File Conventions
- Every Swift file starts with the standard comment header (copy from existing file)
- Cards: always use `.glassCard()` modifier
- Background: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty state: `EmptyState()` component

## Important Shared Types (do not redefine)
- `TrendPoint` — `Services/Calculation/StatisticCalcEngine.swift`
- `IntensitySummary`, `DonutChartData`, `ProgramSummary` — `Services/Calculation/StatisticCalcEngine.swift`
- `StrengthRecord` — `Services/Calculation/StrengthRecordCalcEngine.swift`
- `SummaryTimeframe` — `Views/Summary/Types/SummaryTimeframe.swift`
- `TimeframePicker` — `Views/Summary/Components/TimeframePicker.swift`
- `StatisticGridCard` / `StatisticCard` — `Views/Statistics/Workouts/Components/StatisticCard.swift` (takes `icon: IconTypes` via `.system("...")`)
- `RecordGridCard` — `Views/Statistics/Records/Components/RecordCard.swift` (CardioSession-bound)
- `StrengthRecordGridCard` — `Views/Statistics/Records/Components/StrengthRecordGridCard.swift` (takes `StrengthRecord`)

## Architecture
- Calc Engines: `Services/Calculation/` (pure structs, no state)
- Models (SwiftData): `Models/Core/` — `StrengthSession`, `CardioSession`, `OutdoorSession`, `ExerciseSet`, `Exercise`
- `StrengthSession.totalVolume`, `.totalSets`, `.safeExerciseSets`, `.exercisesPerformed` are computed properties
- Prefer `ExerciseSet.exerciseNameSnapshot` (over `.exerciseName`)
- `StatsAndRecordsView` uses `StatsSegment` enum: only `.statistics` and `.records` (no `.strength`)
- `BaseView.Tab`: `summary, workouts, stats, analyse, training` (`.health` removed, `.analyse` = ProgressionAnalyseView)
- `ProgressionAnalyseView` — `Views/Progression/View/` — Tab 4, icon `brain.head.profile`
- `ProgressionDetailView` — Sheet with 1RM/volume charts + `ProgressionInsightCard` + stats card
- `ProgressionOverviewCard` — Hero card with improving/stable/declining + deload warning
- `ProgressionExerciseCard` — Compact card per exercise (trend icon, name, action, weight, confidence)
- `StatisticCalcEngine` takes all 3 session types: `init(cardioSessions:strengthSessions:outdoorSessions:)` + `filtered(by: SummaryTimeframe)`
- `StrengthRecordCalcEngine` — 7 strength records (highestVolumeSession, mostSetsSession, mostRepsSession, longestStrengthSession, mostExercisesSession, heaviestSingleSet, highestEstimated1RM via Epley)
- `StrengthStatisticCalcEngine` — Volume trend + 1RM progression for charts
- `ProgressionAnalyseCalcEngine` — Aggregates all exercise analyses; `trainedExercises`, `analysis(for:)`, `oneRMTrend(for:)`, `volumeTrend(for:)`, `improvingCount`, `stableCount`, `decliningCount`, `needsDeload`
- `ProgressionCalcEngine` — Per-exercise analysis; `analyze(exercise:sessions:)` → `ProgressionAnalysis`; `extractSnapshots(for:from:)` → `[SessionSnapshot]`
- `HealthKitManager.shared`: `activeBurnedCalories: Int?`, `todaySleepSummary: SleepStagesSummary?`
- `HealthMetricSleepHeroCard(sleepSummary:)` — directly reusable
- `scrollViewContentPadding()` modifier: 13pt horizontal + 22pt top + 100pt bottom — no additional `.padding(.horizontal)` needed on section headers

## Large Files
- `ActiveWorkoutView.swift` (~800 lines, 63KB) — read with `offset`/`limit`

## Git Conventions
- Commit prefixes: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`
- Branch scheme: `feature/`, `refactor/`, `fix/`
- No force-push on main

## Plans & Docs
- Design documents: `Documentation/plans/YYYY-MM-DD-*-design.md`
- Implementation plans: `Documentation/plans/YYYY-MM-DD-*-plan.md`
- Task tracking: `tasks/todo.md`
- Lessons learned: `tasks/lessons.md`