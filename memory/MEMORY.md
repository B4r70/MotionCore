# MotionCore — Claude Memory

## Projekt-Überblick
iOS Fitness-Tracking App. SwiftUI + SwiftData + HealthKit + ActivityKit + Supabase.
Deployment Target: iOS 17+. Kein XCTest. Verifikation via Previews + Simulator.
Git Remote: Forgejo auf git.barto.cloud

## Wichtige Architektur-Patterns
- **Calc-Engines**: Pure structs in `Services/Calculation/` — kein State, kein SwiftUI
- **SwiftData-Modelle**: `Models/Core/` — computed properties mit Raw-Werte-Pattern (z.B. `categoryRaw: String` + `var category: ExerciseCategory { get/set }`)
- **Cards**: immer `.glassCard()` Modifier; Divider: `GlassDivider` / `GlassDivider.tight` / `GlassDivider.compact`
- **Form-Sections**: in `Components/Forms/FormViewSection.swift` — wiederverwendbare `VStack`-Blöcke
- **@Bindable** mit computed properties funktioniert in SwiftData (getestet mit `category`, `progressionStrategy`)

## Progressionssystem (implementiert 2026-03-16)
**Konzept**: `Documentation/Concepts/MotionCore_ProgressionSystem_Concept.md`

### Neue Dateien
- `Models/Types/ProgressionTypes.swift` — Enums/Structs: `ProgressionStrategy`, `ProgressionConfidence`, `TrainingLevel`, `PerformanceTrend`, `ProgressionAction`, `ProgressionAnalysis`, `SessionSnapshot`
- `Views/Training/Exercises/Components/ProgressionInsightCard.swift` — Detailkarte für Übungsdetails
- `Views/Summary/Components/ProgressionSummaryCard.swift` — Dashboard-Karte

### Geänderte Dateien
- `Models/Core/Exercise.swift` — 6 neue SwiftData-Properties: `targetRIR`, `progressionSessionsRequired`, `progressionStrategyRaw`, `customProgressionStep`, `minDaysBetweenProgressions`, `lastProgressionDate` + computed: `progressionStrategy`, `effectiveProgressionStep`, `canRecommendProgression`
- `Services/Calculation/ProgressionCalcEngine.swift` — neue `analyze(exercise:sessions:)` Methode; alte `recommendation()` bleibt für `ProgressionBannerView`
- `Components/Forms/FormViewSection.swift` — neue `ExerciseProgressionSection` (Strategie-Picker, RIR, Sessions, Cooldown)
- `Views/Training/Exercises/View/ExerciseFormView.swift` — `ExerciseProgressionSection` + `ProgressionInsightCard` (Edit-Modus)
- `Views/Summary/View/SummaryView.swift` — `@Query` für Exercises + `progressionAnalyses` computed + `ProgressionSummaryCard`

### Key Decisions
- Bodyweight-Übungen werden von Analyse ausgeschlossen (`category != .bodyweight`)
- Kein Supabase-Sync für Analysen — rein lokal deterministisch
- Keine historischen Analyse-Snapshots in SwiftData (V1)
- SwiftData Lightweight Migration (alle neuen Properties haben Default-Werte)
- `targetRIR` auf `ExerciseSet` bleibt für `ProgressionBannerView` im aktiven Workout

## Bekannte große Dateien
- `ActiveWorkoutView.swift` (~800 Zeilen) → mit `offset`/`limit` lesen
- `FormViewSection.swift` (~1300+ Zeilen nach Progression-Erweiterung) → mit `offset`/`limit` lesen

## Commit-Präfixe
feat(), fix(), refactor(), docs(), bug()
