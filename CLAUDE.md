# MotionCore — CLAUDE.md

## Projekt
iOS Fitness-Tracking App. SwiftUI, SwiftData, Swift Charts, HealthKit, ActivityKit, Supabase.
Deployment Target: iOS 17+. Kein XCTest — Verifikation via SwiftUI Previews + Simulator.

## Build & Test
- Build: Xcode (`Cmd+B`) — kein CLI-Build-Command
- Previews: `PreviewData.sharedContainer` als modelContainer, `AppSettings.shared` als EnvironmentObject
- Keine Unit-Tests vorhanden
- Git Remote: Forgejo auf git.barto.cloud

## Datei-Konventionen
- Jede Swift-Datei beginnt mit dem Standard-Kommentar-Header (von bestehender Datei kopieren)
- Cards: immer `.glassCard()` Modifier
- Hintergrund: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty State: `EmptyState()` Komponente

## Wichtige Shared Types (nicht neu definieren)
- `TrendPoint` — `Services/Calculation/StatisticCalcEngine.swift`
- `IntensitySummary`, `DonutChartData`, `ProgramSummary` — `Services/Calculation/StatisticCalcEngine.swift`
- `StrengthRecord` — `Services/Calculation/StrengthRecordCalcEngine.swift`
- `SummaryTimeframe` — `Views/Summary/Types/SummaryTimeframe.swift`
- `TimeframePicker` — `Views/Summary/Components/TimeframePicker.swift`
- `StatisticGridCard` / `StatisticCard` — `Views/Statistics/Workouts/Components/StatisticCard.swift` (nimmt `icon: IconTypes` via `.system("...")`)
- `RecordGridCard` — `Views/Statistics/Records/Components/RecordCard.swift` (CardioSession-gebunden)
- `StrengthRecordGridCard` — `Views/Statistics/Records/Components/StrengthRecordGridCard.swift` (nimmt `StrengthRecord`)

## Architektur
- Calc-Engines: `Services/Calculation/` (pure structs, kein State)
- Models (SwiftData): `Models/Core/` — `StrengthSession`, `CardioSession`, `OutdoorSession`, `ExerciseSet`, `Exercise`
- `StrengthSession.totalVolume`, `.totalSets`, `.safeExerciseSets`, `.exercisesPerformed` sind bereits computed
- `ExerciseSet.exerciseNameSnapshot` bevorzugen (statt `.exerciseName`)
- `StatsAndRecordsView` nutzt `StatsSegment` Enum: nur `.statistics` und `.records` (kein `.strength` mehr)
- `BaseView.Tab`: `summary, workouts, stats, analyse, training` (`.health` entfernt, `.analyse` = ProgressionAnalyseView)
- `ProgressionAnalyseView` — `Views/Progression/View/` — Tab 4, Icon `brain.head.profile`
- `ProgressionDetailView` — Sheet mit 1RM/Volumen-Charts + `ProgressionInsightCard` + Statscard
- `ProgressionOverviewCard` — Hero-Card mit improving/stable/declining + Deload-Warnung
- `ProgressionExerciseCard` — kompakte Card pro Übung (Trend-Icon, Name, Aktion, Gewicht, Konfidenz)
- `StatisticCalcEngine` nimmt alle 3 Session-Typen: `init(cardioSessions:strengthSessions:outdoorSessions:)` + `filtered(by: SummaryTimeframe)`
- `StrengthRecordCalcEngine` — 7 Kraft-Rekorde (highestVolumeSession, mostSetsSession, mostRepsSession, longestStrengthSession, mostExercisesSession, heaviestSingleSet, highestEstimated1RM via Epley)
- `StrengthStatisticCalcEngine` — Volumen-Trend + 1RM-Progression für Charts
- `ProgressionAnalyseCalcEngine` — aggregiert alle Übungsanalysen; `trainedExercises`, `analysis(for:)`, `oneRMTrend(for:)`, `volumeTrend(for:)`, `improvingCount`, `stableCount`, `decliningCount`, `needsDeload`
- `ProgressionCalcEngine` — Einzel-Analyse pro Übung; `analyze(exercise:sessions:)` → `ProgressionAnalysis`; `extractSnapshots(for:from:)` → `[SessionSnapshot]`
- `HealthKitManager.shared`: `activeBurnedCalories: Int?`, `todaySleepSummary: SleepStagesSummary?`
- `HealthMetricSleepHeroCard(sleepSummary:)` — direkt wiederverwendbar
- `scrollViewContentPadding()` Modifier: 13pt horizontal + 22pt top + 100pt bottom — kein zusätzliches `.padding(.horizontal)` bei Section-Headern nötig

## Große Dateien
- `ActiveWorkoutView.swift` (~800 Zeilen, 63KB) — Read mit `offset`/`limit` lesen

## Git-Konventionen
- Commit-Präfixe: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`
- Branch-Schema: `feature/`, `refactor/`, `fix/`
- Kein Force-Push auf main

## Pläne & Docs
- Design-Dokumente: `Documentation/plans/YYYY-MM-DD-*-design.md`
- Implementierungspläne: `Documentation/plans/YYYY-MM-DD-*-plan.md`
