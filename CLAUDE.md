# MotionCore — CLAUDE.md

## Projekt
iOS Fitness-Tracking App. SwiftUI, SwiftData, Swift Charts, HealthKit, ActivityKit, Supabase.
Deployment Target: iOS 17+. Kein XCTest — Verifikation via SwiftUI Previews + Simulator.

## Build & Test
- Build: Xcode (`Cmd+B`) — kein CLI-Build-Command
- Previews: `PreviewData.sharedContainer` als modelContainer, `AppSettings.shared` als EnvironmentObject
- Keine Unit-Tests vorhanden

## Datei-Konventionen
- Jede Swift-Datei beginnt mit dem Standard-Kommentar-Header (von bestehender Datei kopieren)
- Cards: immer `.glassCard()` Modifier
- Hintergrund: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty State: `EmptyState()` Komponente

## Wichtige Shared Types (nicht neu definieren)
- `TrendPoint` — `Services/Calculation/StatisticCalcEngine.swift`
- `SummaryTimeframe` — `Views/Summary/Types/SummaryTimeframe.swift`
- `TimeframePicker` — `Views/Summary/Components/TimeframePicker.swift`
- `StatisticGridCard` — `Views/Statistics/Workouts/Components/StatisticCard.swift` (nimmt `icon: IconTypes` via `.system("...")`)

## Architektur
- Calc-Engines: `Services/Calculation/` (pure structs, kein State)
- Models (SwiftData): `Models/Core/` — `StrengthSession`, `CardioSession`, `ExerciseSet`, `Exercise`
- `StrengthSession.totalVolume` und `.safeExerciseSets` sind bereits computed
- `StatsAndRecordsView` nutzt `StatsSegment` Enum für Segmented Control

## Große Dateien
- `ActiveWorkoutView.swift` (~800 Zeilen, 63KB) — Read mit `offset`/`limit` lesen

## Git-Konventionen
- Commit-Präfixe: `feat()`, `fix()`, `refactor()`, `docs()`, `bug()`
- Branch-Schema: `feature/`, `refactor/`, `fix/`

## Pläne & Docs
- Design-Dokumente: `Documentation/plans/YYYY-MM-DD-*-design.md`
- Implementierungspläne: `Documentation/plans/YYYY-MM-DD-*-plan.md`
