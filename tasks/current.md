# SummaryView Redesign — Gamifiziertes Trainings-Dashboard

**Complexity:** Large
**Status:** Implementierung abgeschlossen — bereit für Xcode Build
**Konzeptdokument:** `Documentation/Concepts/MotionCore_SummaryView_Redesign_Concept.md`

## Summary

Das SummaryView-Dashboard wird von einer statischen Zahlen-Liste in ein gamifiziertes Trainings-Dashboard verwandelt. Neue Features: XP-System mit Leveln und Rängen, Wochenziel-Ring, 7-Tage-Aktivitäts-Strip mit expandierbarem Monats-Kalender, Trend-Vergleiche, Muskel-Heatmap, Übung der Woche, CountUp-Animationen. Bestehende Cards (Streak, Records, TypeBreakdown, ProgressionSummary) werden beibehalten und teilweise redesigned.

## Geklärte Entscheidungen

| Frage | Entscheidung |
|---|---|
| Timeframe-Abhängigkeit | Sektionen 1–3 zeigen aktuelle Woche; ab Sektion 5 folgt alles SummaryTimeframe |
| Kalender-Expansion | Inline mit `if showCalendar` + `.animation(.easeInOut)` |
| Kalorien-Trendpfeil | Mehr Kalorien = grüner Pfeil (positiv) |
| CountUpText | `targetValue: Int`, Volumen gerundet auf ganze kg, Dauer in "min" |
| Wochenziel-Schnitt | Durchschnitt der letzten 4 Wochen |
| XP-Gewinne Liste | Letzte 6 Workouts mit ihren XP-Gewinnen |

## Scope

**Enthalten:**
- 5 neue CalcEngines: `XPCalcEngine`, `StreakCalcEngine`, `TrendCalcEngine`, `ActivityGridCalcEngine`, `WeeklyGoalCalcEngine`
- 1 neue Types-Datei: `SummaryDashboardTypes.swift`
- 9 neue View-Dateien: `CountUpText`, `SummaryHeroCard`, `SummaryWeekStrip`, `SummaryActivityCalendar`, `SummaryWeeklyGoalRing`, `SummaryTrendCard`, `SummaryMuscleHeatmapCard`, `SummaryBestExerciseCard`, `SummaryXPCard`
- Modifikation von 7 bestehenden Dateien: `SummaryView`, `SummaryViewModel`, `SummaryCalcEngine`, `StreakCard`, `SummaryRecordsCard`, `AppSettings`, `WorkoutSettingsView`
- Wiederverwendung bestehender `MuscleHeatmapCalcEngine`, `MiniSparkline`, `ProgressionCalcEngine`

**Explizit ausgeschlossen:**
- Persistierung von XP in SwiftData
- Localization
- Änderungen an `TimeframePicker`, `SummaryTimeframe`, `TypeBreakdownCard`, `ProgressionSummaryCard`, `StatisticDonutChart`
- Parallax- oder Spring-Animationen
- Supabase-Änderungen

## UX Placement

- **Tab:** `BaseView.Tab.summary` — erster Tab, Hauptscreen
- **Layout (von oben nach unten):**
  1. Hero Card (Begrüßung + XP-Level + Motivationstext)
  2. 7-Tage-Strip (expandierbar zum Monats-Kalender)
  3. Wochenziel-Ring + Trend-Stats (side-by-side HStack)
  4. TimeframePicker (bestehend, verschoben)
  5. Stat-Grid 2×2 (bestehend, mit CountUp)
  6. Muskel-Heatmap
  7. Übung der Woche
  8. Streak-Card (redesigned)
  9. XP & Rang Card
  10. Typ-Aufschlüsselung (bestehend)
  11. Rekorde (redesigned)
  12. Progressions-Empfehlungen (bestehend)

## Abhängigkeitsgraph

```
SummaryDashboardTypes.swift (keine Abhängigkeiten)
    |
    +-- XPCalcEngine.swift
    +-- StreakCalcEngine.swift
    +-- TrendCalcEngine.swift
    +-- ActivityGridCalcEngine.swift
    +-- WeeklyGoalCalcEngine.swift
    |
CountUpText.swift (unabhängig)
    |
    +-- SummaryHeroCard.swift
    +-- SummaryTrendCard.swift
    +-- SummaryXPCard.swift
    |
SummaryWeekStrip.swift, SummaryActivityCalendar.swift
SummaryWeeklyGoalRing.swift
SummaryMuscleHeatmapCard.swift (+ bestehender MuscleHeatmapCalcEngine)
SummaryBestExerciseCard.swift (+ bestehender ProgressionCalcEngine)
    |
    v
SummaryViewModel.swift (orchestriert alle CalcEngines)
    |
    v
SummaryView.swift (rendert alle Cards)
```

## Risiken

### Kritisch
- **Performance:** `XPCalcEngine` iteriert über ALLE Sessions bei jedem vollen `recalculate()`. Bei 500+ Sessions könnte das spürbar sein. Mitigation: XP-Berechnung nur beim vollen `recalculate()`, nicht bei Timeframe-Wechsel.
- **SummaryViewModel Größe:** Wächst von ~108 auf ~200 Zeilen. Akzeptabel aber nah an Grenze.

### Mittel
- **MuscleHeatmapMiniSVGView ist `private`** — muss auf `internal` geändert werden (minimaler Eingriff).
- **CountUp + ScrollView:** Animation könnte bei schnellem Scrollen neu starten. Mitigation: `hasAnimated`-Flag.

### Gering
- **15 neue Dateien** müssen manuell in Xcode dem MotionCore-Target zugewiesen werden.

## Referenz-Dateien (vor Implementierung lesen)

| Datei | Warum |
|---|---|
| `Views/Summary/View/SummaryView.swift` | Aktuelles Layout, Einfügepunkte |
| `Services/ViewModels/SummaryViewModel.swift` | recalculate()-Pattern, gecachte Properties |
| `Services/Calculation/SummaryCalcEngine.swift` | Streak-Code der extrahiert wird |
| `Services/Calculation/MuscleHeatmapCalcEngine.swift` | API für MuscleHeatmapCard |
| `Views/Workouts/Components/MuscleHeatmapMiniView.swift` | MuscleHeatmapMiniSVGView Signatur |
| `Views/Progression/Components/MiniSparkline.swift` | API für BestExerciseCard |
| `Services/Calculation/ProgressionCalcEngine.swift` | API für BestExerciseCard |
| `Views/Statistics/Workouts/Components/StatisticCard.swift` | StatisticGridCard Signatur |
| `Models/Core/AppSettings.swift` | UserDefaults-Pattern für weeklyWorkoutGoal |
| `Views/Settings/View/WorkoutSettingsView.swift` | Einfügepunkt Wochenziel-Section |
| `Models/Types/MuscleHeatmapTypes.swift` | MuscleHeatData, MuscleHeatmapAnalysis |
| `Views/Summary/Components/StreakCard.swift` | Bestehendes Layout + Parameter |
| `Views/Summary/Components/SummaryRecordsCard.swift` | Bestehendes Layout + Parameter |

---

## Implementation Steps

### Phase 1: Fundament — Types + CalcEngines

- [x] **1. `SummaryDashboardTypes.swift` erstellen**
  - Pfad: `MotionCore/Models/Types/SummaryDashboardTypes.swift`
  - Kein SwiftUI-Import, nur Foundation
  - Typen:
    - `enum Rank: Int, CaseIterable` — 7 Cases (rookie/athlet/warrior/champion/elite/master/legende) mit `icon: String` und `displayName: String`
    - `struct XPLevel` — level: Int, totalXP: Int, xpForCurrentLevel: Int, xpRequiredForNextLevel: Int, rank: Rank, progressToNextLevel: Double (0.0–1.0)
    - `struct WeeklyGoal` — target: Int, current: Int, averageLast4Weeks: Double, isReached: Bool, isAboveAverage: Bool, progressFraction: Double
    - `struct ActivityDay: Identifiable` — id: Date, date: Date, workoutTypes: [WorkoutType], workoutCount: Int, isToday: Bool
    - `struct TrendComparison` — currentValue: Double, previousValue: Double, percentageChange: Double, trend: TrendDirection
    - `enum TrendDirection` — up, down, stable
    - `enum StreakMilestone: Int, CaseIterable` — 7, 14, 30, 60, 100 mit `icon: String` und `text: String`
    - `struct XPGain: Identifiable` — id: UUID, description: String, xpAmount: Int, date: Date
    - `struct MotivationalContext` — greeting: String, motivationalText: String
  - Geschätzte Größe: ~150 Zeilen

- [x] **2. `XPCalcEngine.swift` erstellen**
  - Pfad: `MotionCore/Services/Calculation/XPCalcEngine.swift`
  - Kein SwiftUI-Import, nur Foundation
  - `struct XPCalcEngine`
  - Input: `cardioSessions: [CardioSession]`, `strengthSessions: [StrengthSession]`, `outdoorSessions: [OutdoorSession]`, `weeklyGoal: Int`, `strengthRecordDates: [Date]`
  - Methoden:
    - `func calculateTotalXP() -> Int` — iteriert über ALLE Sessions chronologisch
    - `func calculateLevel(totalXP: Int) -> XPLevel` — Schwelle Level N: `500 * N * (N+1) / 2`, Max-Level 50
    - `func recentXPGains(lastCount: Int = 6) -> [XPGain]` — letzte N Workouts mit XP-Gewinnen
    - `func motivationalContext(streak: Int, workoutsThisWeek: Int, weeklyGoal: Int, lastWorkoutDate: Date?) -> MotivationalContext` — Prioritäts-Reihenfolge aus Konzept
  - XP-Quellen: Basis +100, Dauer +1/min, Streak-Bonus +10×streak (max 500), PR +250, Wochenziel +200, Konsistenz-Bonus +500
  - Geschätzte Größe: ~250 Zeilen
  - Abhängigkeit: `SummaryDashboardTypes.swift`

- [x] **3. `StreakCalcEngine.swift` erstellen**
  - Pfad: `MotionCore/Services/Calculation/StreakCalcEngine.swift`
  - Kein SwiftUI-Import, nur Foundation
  - `struct StreakCalcEngine`
  - Input: `allTrainingDays: [Date]`
  - Streak-Logik 1:1 aus `SummaryCalcEngine.swift` extrahiert
  - Neue Methoden: `func currentMilestone(streak: Int) -> StreakMilestone?`, `func nextMilestone(streak: Int) -> StreakMilestone?`
  - Geschätzte Größe: ~100 Zeilen
  - Abhängigkeit: `SummaryDashboardTypes.swift` (StreakMilestone)

- [x] **4. `TrendCalcEngine.swift` erstellen**
  - Pfad: `MotionCore/Services/Calculation/TrendCalcEngine.swift`
  - Kein SwiftUI-Import, nur Foundation
  - `struct TrendCalcEngine`
  - Input: `cardioSessions: [CardioSession]`, `strengthSessions: [StrengthSession]`, `outdoorSessions: [OutdoorSession]`
  - Methoden: `volumeTrend() -> TrendComparison`, `caloriesTrend() -> TrendComparison`, `durationTrend() -> TrendComparison`
  - Diese Woche vs. Vorwoche. Mehr = positiv für alle drei Metriken.
  - Geschätzte Größe: ~120 Zeilen
  - Abhängigkeit: `SummaryDashboardTypes.swift` (TrendComparison, TrendDirection)

- [x] **5. `ActivityGridCalcEngine.swift` erstellen**
  - Pfad: `MotionCore/Services/Calculation/ActivityGridCalcEngine.swift`
  - Kein SwiftUI-Import, nur Foundation
  - `struct ActivityGridCalcEngine`
  - Input: Alle 3 Session-Typen
  - Methoden: `currentWeekStrip() -> [ActivityDay]`, `monthGrid(for month: Date) -> [[ActivityDay?]]`, `monthStats(for month: Date) -> (trainingDays: Int, averagePerWeek: Double)`
  - Geschätzte Größe: ~150 Zeilen
  - Abhängigkeit: `SummaryDashboardTypes.swift` (ActivityDay)

- [x] **6. `WeeklyGoalCalcEngine.swift` erstellen**
  - Pfad: `MotionCore/Services/Calculation/WeeklyGoalCalcEngine.swift`
  - Kein SwiftUI-Import, nur Foundation
  - `struct WeeklyGoalCalcEngine`
  - Input: Alle 3 Session-Typen + `weeklyGoal: Int`
  - Methoden: `currentWeekGoal() -> WeeklyGoal`, `consecutiveWeeksGoalReached() -> Int`
  - Durchschnitt = letzte 4 Wochen
  - Geschätzte Größe: ~80 Zeilen
  - Abhängigkeit: `SummaryDashboardTypes.swift` (WeeklyGoal)

### Phase 2: Shared Component

- [x] **7. `CountUpText.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/CountUpText.swift`
  - `struct CountUpText: View`
  - Parameter: `targetValue: Int`, `duration: Double = 0.8`, `font: Font = .system(size: 26, weight: .bold, design: .rounded)`, `suffix: String = ""`
  - `@State private var displayValue: Int = 0`, `@State private var hasAnimated = false`
  - Animation via `.task {}` + SwiftUI-native Interpolation — KEIN `Timer.scheduledTimer`
  - Werte > 10.000: Animation startet bei 80% des Zielwerts
  - Geschätzte Größe: ~80 Zeilen

### Phase 3: Neue Cards

- [x] **8. `SummaryHeroCard.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryHeroCard.swift`
  - Parameter: `motivationalContext: MotivationalContext`, `xpLevel: XPLevel`
  - Inhalt: Tageszeit-Begrüßung + Rang-Badge, Motivationstext, kompakter XP-Fortschrittsbalken
  - Design: `.glassCard()` + 2px Gradient-Akzent oben (`#C9E6FF` → `#9BD2FF`)
  - Geschätzte Größe: ~120 Zeilen

- [x] **9. `SummaryWeekStrip.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryWeekStrip.swift`
  - Parameter: `days: [ActivityDay]`, `showCalendar: Binding<Bool>`
  - 7 Kreise à 36pt, 8pt Spacing, Buchstaben Mo–So
  - Heute: pulsierender Rand (einmalig beim Erscheinen)
  - Kein eigenes `.glassCard()` — kompakte eingebettete Zeile
  - Geschätzte Größe: ~100 Zeilen

- [x] **10. `SummaryWeeklyGoalRing.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryWeeklyGoalRing.swift`
  - Parameter: `goal: WeeklyGoal`
  - Animierter Ring (Circle + trim), Zahltext innen, Kontexttext darunter
  - `.glassCard()`
  - Geschätzte Größe: ~100 Zeilen

- [x] **11. `SummaryTrendCard.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryTrendCard.swift`
  - Parameter: `volumeTrend: TrendComparison`, `caloriesTrend: TrendComparison`, `durationTrend: TrendComparison`
  - 3 Zeilen: Icon + CountUp-Wert + Trendpfeil + Prozent
  - Volumen in kg (gerundet), Kalorien in kcal, Dauer in "min"
  - `.glassCard()`
  - Geschätzte Größe: ~120 Zeilen

- [x] **12. `SummaryMuscleHeatmapCard.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryMuscleHeatmapCard.swift`
  - Parameter: `analysis: MuscleHeatmapAnalysis`
  - Header "Trainierte Muskeln", `MuscleHeatmapMiniSVGView` (internal gemacht), Top-2-3-Muskelgruppen-Tags
  - Nur anzeigen wenn `analysis.totalSets > 0`
  - `.glassCard()`
  - Geschätzte Größe: ~100 Zeilen

- [x] **13. `SummaryBestExerciseCard.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryBestExerciseCard.swift`
  - Parameter: `analysis: ProgressionAnalysis`, `trendPoints: [TrendPoint]`
  - Header "⭐ Übung der Woche", Übungsname, Progressions-Info, MiniSparkline
  - Nur anzeigen wenn Progressionsdaten vorhanden
  - `.glassCard()`
  - Geschätzte Größe: ~80 Zeilen

- [x] **14. `SummaryXPCard.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryXPCard.swift`
  - Parameter: `xpLevel: XPLevel`, `recentGains: [XPGain]`
  - Rang-Badge groß, Level-Text, animierter Fortschrittsbalken, letzte 6 XP-Gewinne
  - `.glassCard()`
  - Geschätzte Größe: ~130 Zeilen

- [x] **15. `SummaryActivityCalendar.swift` erstellen**
  - Pfad: `MotionCore/Views/Summary/Components/SummaryActivityCalendar.swift`
  - Parameter: `monthGrid: [[ActivityDay?]]`, `displayedMonth: Binding<Date>`, `stats: (trainingDays: Int, averagePerWeek: Double)`
  - Kalender-Grid (7 Spalten), farbcodierte Tage, Monats-Navigation, Statistik-Zeile
  - Farben: kein Training → transparent, 1 → `#C9E6FF`, 2 → `#9BD2FF`, 3+ → `#3B82F6`
  - `.glassCard()`
  - Geschätzte Größe: ~150 Zeilen

### Phase 4: Integration

- [x] **16. `AppSettings.swift` erweitern**
  - Neues Property: `@Published var weeklyWorkoutGoal: Int`
  - Key: `"workout.weeklyWorkoutGoal"`, Default: 4, Range 1–7 (Validierung via Stepper)

- [x] **17. `WorkoutSettingsView.swift` erweitern**
  - Neue Section "Wochenziel" mit `Stepper("Workouts pro Woche: \(appSettings.weeklyWorkoutGoal)", value: $appSettings.weeklyWorkoutGoal, in: 1...7)`
  - ~5 Zeilen Änderung

- [x] **18. `SummaryCalcEngine.swift` — Streak extrahieren**
  - `allTrainingDays` von `private` auf `internal`
  - `currentStreak` und `longestStreak` zu Forwarding-Properties → `StreakCalcEngine`
  - Originalen Streak-Code entfernen
  - Rückwärtskompatible API bleibt erhalten

- [x] **19. `MuscleHeatmapMiniView.swift` — Access-Level fix**
  - `MuscleHeatmapMiniSVGView` von `private` auf `internal`
  - Neuen Initializer mit `svgStylesCSS: String` hinzufügen (bestehender `trainedRegionIds`-Initializer bleibt)
  - ~10 Zeilen Änderung

- [x] **20. `SummaryViewModel.swift` erweitern**
  - Neue gecachte Properties (zeitraum-unabhängig):
    - `xpLevel: XPLevel`, `recentXPGains: [XPGain]`, `motivationalContext: MotivationalContext`
    - `currentStreakMilestone: StreakMilestone?`, `nextStreakMilestone: StreakMilestone?`
    - `weeklyGoal: WeeklyGoal`, `currentWeekStrip: [ActivityDay]`
    - `volumeTrend: TrendComparison`, `caloriesTrend: TrendComparison`, `durationTrend: TrendComparison`
    - `bestExerciseAnalysis: ProgressionAnalysis?`, `bestExerciseTrendPoints: [TrendPoint]`
  - Neue gecachte Properties (timeframe-gefiltert): `filteredHeatmapAnalysis: MuscleHeatmapAnalysis?`
  - `recalculate()` bekommt Parameter `weeklyGoal: Int`
  - Kalender-Methode: `func calendarData(for month: Date) -> (grid: [[ActivityDay?]], stats: (Int, Double))`
  - Geschätzte Endgröße: ~200 Zeilen

- [x] **21. `StreakCard.swift` redesignen**
  - Neue Parameter (mit Default `nil`): `streakMilestone: StreakMilestone? = nil`, `nextMilestone: StreakMilestone? = nil`
  - Milestone-Badge-Bereich wenn vorhanden
  - Flammen-Glow-Animation bei aktiver Streak (einmalig)

- [x] **22. `SummaryRecordsCard.swift` redesignen**
  - Neuer Parameter: `recentRecordDates: [Date] = []`
  - "Neu!"-Badge (Capsule, .orange) bei Rekord aus den letzten 7 Tagen
  - Kompakteres Layout

- [x] **23. `SummaryView.swift` — neues Layout**
  - Neue `@State`: `showCalendar: Bool = false`, `displayedMonth: Date = Date()`
  - Neues Layout: alle 12 Sektionen in ScrollView VStack(spacing: 20)
  - `.task {}` mit `weeklyGoal: appSettings.weeklyWorkoutGoal`
  - `.onChange(of: appSettings.weeklyWorkoutGoal)` für Live-Update
  - `.onChange(of: displayedMonth)` für Kalender-Daten
  - Geschätzte Endgröße: ~120 Zeilen

### Phase 5: Build + Verifikation

- [ ] **24. Xcode Build (`Cmd+B`)** — alle Compile-Errors beheben, Target Membership prüfen
- [ ] **25. UI-Feinschliff** — Spacing/Padding, CountUp-Timing, Kalender-Animation

---

## Fortschritt

**Datum:** 2026-04-02

**Abgeschlossene Schritte:** 1–23 (Phasen 1–4 vollständig)

**Geänderte/erstellte Dateien:**

Neu erstellt:
- `MotionCore/Models/Types/SummaryDashboardTypes.swift`
- `MotionCore/Services/Calculation/XPCalcEngine.swift`
- `MotionCore/Services/Calculation/StreakCalcEngine.swift`
- `MotionCore/Services/Calculation/TrendCalcEngine.swift`
- `MotionCore/Services/Calculation/ActivityGridCalcEngine.swift`
- `MotionCore/Services/Calculation/WeeklyGoalCalcEngine.swift`
- `MotionCore/Views/Summary/Components/CountUpText.swift`
- `MotionCore/Views/Summary/Components/SummaryHeroCard.swift`
- `MotionCore/Views/Summary/Components/SummaryWeekStrip.swift`
- `MotionCore/Views/Summary/Components/SummaryWeeklyGoalRing.swift`
- `MotionCore/Views/Summary/Components/SummaryTrendCard.swift`
- `MotionCore/Views/Summary/Components/SummaryMuscleHeatmapCard.swift`
- `MotionCore/Views/Summary/Components/SummaryBestExerciseCard.swift`
- `MotionCore/Views/Summary/Components/SummaryXPCard.swift`
- `MotionCore/Views/Summary/Components/SummaryActivityCalendar.swift`

Geändert:
- `MotionCore/Models/Core/AppSettings.swift` — weeklyWorkoutGoal hinzugefügt
- `MotionCore/Views/Settings/View/WorkoutSettingsView.swift` — Wochenziel-Section
- `MotionCore/Services/Calculation/SummaryCalcEngine.swift` — Streak extrahiert, allTrainingDays internal
- `MotionCore/Views/Workouts/Components/MuscleHeatmapMiniView.swift` — internal + neuer Initializer
- `MotionCore/Services/ViewModels/SummaryViewModel.swift` — vollständig erweitert
- `MotionCore/Views/Summary/Components/StreakCard.swift` — Milestone-Badge, Glow
- `MotionCore/Views/Summary/Components/SummaryRecordsCard.swift` — Neu!-Badge
- `MotionCore/Views/Summary/Components/SummaryRecordRow.swift` — isNew-Parameter
- `MotionCore/Views/Summary/View/SummaryView.swift` — neues Layout

**Offene Punkte:**
- Schritt 24: Xcode Build (Cmd+B) — muss manuell in Xcode ausgeführt werden
- Schritt 25: UI-Feinschliff nach Build-Verifikation
- Alle 15 neuen Dateien müssen in Xcode dem MotionCore-Target manuell zugewiesen werden

---

## Manual Verification Checklist

- [ ] Xcode Build kompiliert fehlerfrei
- [ ] SummaryView Preview: alle 12 Sektionen mit PreviewData sichtbar
- [ ] SummaryView Preview: EmptyState bei keinen Sessions
- [ ] HeroCard: Tageszeit-Begrüßung korrekt (Morgen/Tag/Abend)
- [ ] HeroCard: Rang-Badge und XP-Level angezeigt
- [ ] WeekStrip: 7 Tage farbcodiert, heute markiert
- [ ] WeekStrip Tap: Kalender expandiert inline mit Animation
- [ ] ActivityCalendar: Monatswechsel funktioniert
- [ ] WeeklyGoalRing: Ring-Animation beim Erscheinen
- [ ] WeeklyGoalRing: Kontexttext korrekt (unter/über Schnitt)
- [ ] TrendCard: 3 Zeilen mit CountUp und Trendpfeil
- [ ] TrendCard: Kalorien-Anstieg = grüner Pfeil
- [ ] StatGrid: CountUp-Animation spielt einmal beim Erscheinen
- [ ] MuscleHeatmapCard: Silhouette farbig (nur bei Kraft-Sessions)
- [ ] BestExerciseCard: Sparkline sichtbar (nur bei Progressionsdaten)
- [ ] StreakCard: Milestone-Badge bei Streak ≥ 7
- [ ] XPCard: Level + Fortschrittsbalken + letzte 6 Gains
- [ ] RecordsCard: "Neu!"-Badge bei Rekord aus letzten 7 Tagen
- [ ] TimeframePicker: Wechsel aktualisiert Sektionen 5+
- [ ] WorkoutSettingsView: Wochenziel-Stepper 1–7 funktional
- [ ] Wochenziel-Änderung: WeeklyGoalRing aktualisiert live
- [ ] Scrolling-Performance: Kein sichtbarer Lag
