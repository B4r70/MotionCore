# Dashboard Redesign — Variante B (Command Center)

**Komplexität:** Large
**Status:** Phase 6 abgeschlossen — Quality Gate bereit
**Konzept-Quelle:** `Documentation/Concepts/MotionCore_Redesign_Dashboard_Body_Instruction.md`

## Summary

SummaryView und BodyView komplett neustrukturieren ("Clean Slate") nach dem Command-Center-Design. 7 neue wiederverwendbare Building-Blocks unter `Views/Shared/Redesign/`, eine neue `RecoveryRecommendationCalcEngine`, neue Hero/Chip-Cards für SummaryView und neuer Tab-Switch + Composite-Score-Card für BodyView. Liquid-Glass-Look bleibt; Variante-B-Farbpalette wird zentralisiert.

## Scope

**Inkludiert:**
- 7 neue UI-Komponenten unter `MotionCore/Views/Shared/Redesign/`
- `RecoveryRecommendationCalcEngine` als pures Struct
- `SummaryViewModel`-Erweiterung um `recommendation` Property
- `BodyViewModel`-Erweiterung um `recommendation` Property
- Komplett neuer Aufbau von `SummaryView.swift`
- Komplett neuer Aufbau von `BodyView.swift`
- Cleanup nicht mehr genutzter Cards (cross-reference-checked)

**Explizit ausgeschlossen:**
- Body-Map-SVG (Variante B nutzt MiniRing-Grid)
- Erweiterung von `TrendCalcEngine`/`MuscleRecoveryCalcEngine` mit historischen Series-Daten
- Anpassungen an `MuscleHeatmapView`, Watch, Widgets, Live Activity
- Änderungen an `ExerciseRating`, `PlanUpdateCalcEngine`, SwiftData-Models
- Tab-Reihenfolge / `BaseView.Tab`-Enum (bleibt unverändert)

## UX Placement

- **SummaryView:** Command-Center-Hero oben → Chip-Row → Aktions-Cards (MiniRing-Grid, 2×2 Spark) → Detail-Cards
- **BodyView:** Composite-Score-Card → Tab-Switch (Erholung / Tagesform / Trend) → Tab-Content → AvoidCard

## Affected Files

### Neu

- `MotionCore/Views/Shared/Redesign/MCColorPalette.swift`
- `MotionCore/Views/Shared/Redesign/MCFactorBar.swift`
- `MotionCore/Views/Shared/Redesign/MCChip.swift`
- `MotionCore/Views/Shared/Redesign/MCSparkline.swift`
- `MotionCore/Views/Shared/Redesign/MCMiniRing.swift`
- `MotionCore/Views/Shared/Redesign/MCHeroRing.swift`
- `MotionCore/Services/Calculation/RecoveryRecommendationCalcEngine.swift`
- `MotionCore/Views/Summary/Components/SummaryCommandHero.swift`
- `MotionCore/Views/Summary/Components/SummaryChipRow.swift`
- `MotionCore/Views/Summary/Components/SummaryMuscleRingsCard.swift`
- `MotionCore/Views/Summary/Components/SummaryStatGridCard.swift`
- `MotionCore/Views/Body/BodyCompositeScoreCard.swift`
- `MotionCore/Views/Body/BodyTabSwitch.swift`
- `MotionCore/Views/Body/BodyRecoveryListCard.swift`
- `MotionCore/Views/Body/BodyReadinessFactorsCard.swift`
- `MotionCore/Views/Body/BodyRecoveryTrendCard.swift`
- `MotionCore/Views/Body/BodyAvoidCard.swift`

### Geändert

- `MotionCore/Services/ViewModels/SummaryViewModel.swift` — `recommendation: RecoveryRecommendation` ergänzen
- `MotionCore/Views/Summary/View/SummaryView.swift` — komplett neu strukturieren
- `MotionCore/Views/Body/BodyViewModel.swift` — `recommendation: RecoveryRecommendation` ergänzen
- `MotionCore/Views/Body/BodyView.swift` — komplett neu strukturieren

### Cleanup-Kandidaten (entscheidet sich in Phase 6)

- `MotionCore/Views/Readiness/ReadinessSummaryCard.swift` — Cross-Ref-Check → ggf. löschen
- `MotionCore/Views/Summary/Components/SummaryHeroCard.swift` — Cross-Ref-Check → ggf. löschen
- `MotionCore/Views/Summary/Components/SummaryWeeklyGoalRing.swift` — Cross-Ref-Check → ggf. löschen
- `MotionCore/Views/Summary/Components/SummaryTrendCard.swift` — Cross-Ref-Check → ggf. löschen
- `MotionCore/Views/Body/MuscleRecoveryCard.swift` — Cross-Ref-Check → ggf. löschen

## Risks

- **"Heute trainieren"-Button-Action:** Tab-Switch zu Training-Tab erfordert Binding bis BaseView; vorerst `NewWorkoutSheet` lokal öffnen (Open Question)
- **`Color(hex:)`-Extension-Pfad:** Developer muss Pfad ermitteln bevor `MCColorPalette` angelegt wird
- **Hero-Sparkline + BodyView Trend-Tab:** keine historischen Daten vorhanden → Stub bzw. EmptyState
- **Cleanup-Kandidaten:** Cross-Reference-Check Pflicht vor Löschung
- **`MuscleRecoveryCalcEngine` Rückgabe-Typ:** `MuscleRecoveryAnalysis.muscleGroupScores` prüfen (Array von `MuscleGroupRecovery` mit `.recoveryPercent`, `.displayName`, `.wasTrainedInTimeframe`)

## Entschiedene Fragen

1. **"Heute trainieren"-Button:** Öffnet denselben `NewWorkoutSheet` wie der FAB-Button. Umsetzung: `SummaryView` und `BodyView` erhalten `onStartWorkoutTap: () -> Void` Callback; `BaseView` übergibt `{ showingWorkoutPicker = true }`. Kein lokaler Duplikat-Sheet, kein NotificationCenter.
2. **Tagesform-Score in BodyReadinessFactorsCard:** Wird angezeigt → `score: Int?` Property in `BodyViewModel` ergänzen.
3. **`MCRecoveryHeatmapGrid`:** Verschoben auf Phase 7+ (keine 4-Wochen-Daten vorhanden).

---

## Phase 1 — Wiederverwendbare Building-Blocks

Neues Verzeichnis: `MotionCore/Views/Shared/Redesign/`

- [x] **Step 1.1 — `MCColorPalette.swift`:** Pfad der vorhandenen `Color(hex:)`-Extension ermitteln. `enum MCColor` mit: `mcEnergy = #F5B400` + `mcEnergySoft` (.opacity 0.18) + `mcEnergyInk` (.opacity 0.85); analog `mcBody = #5CC63F`, `mcStat = #2E6DF0`, `mcStreak = #FF6B4A`. Pure Konstanten.
- [x] **Step 1.2 — `MCFactorBar.swift`:** Props: `label: String`, `subLabel: String?`, `value: Double` (0…1), `color: Color`. Layout: HStack(label, Spacer, subLabel `.caption.monospacedDigit()`); darunter Capsule-Hintergrund + gefüllte Capsule (Breite = `geo.size.width * value`). Einblend-Animation via `@State filled: Bool`. `#Preview` mit low/mid/high.
- [x] **Step 1.3 — `MCChip.swift`:** Props: `icon: Image`, `value: String`, `label: String`, `tint: Color = .primary`. Layout: HStack(Icon mit `tint`-Farbe, VStack(value `.headline.monospacedDigit()`, label `.caption2.secondary`)). Glass-Background (Capsule `.ultraThinMaterial`). `#Preview` 3 Beispiele.
- [x] **Step 1.4 — `MCSparkline.swift`:** Props: `data: [Double]`, `color: Color`, `showFill: Bool = true`. Canvas/Path mit Auto-Min/Max. Gefüllter Bereich `color.opacity(0.18)`, Linie `color, lineWidth: 1.5`. Default-Frame 70×24, expandierbar. Edge-Case `data.count < 2` → leerer View. `#Preview` mit Beispieldaten.
- [x] **Step 1.5 — `MCMiniRing.swift`:** Props: `value: Int` (0…100), `label: String`, `size: CGFloat = 62`, `stroke: CGFloat = 6`, `tint: Color? = nil` (default `recoveryColor(percent:)`). ZStack: Hintergrundring + Trim-Ring + innen VStack(Zahl monospaced, Label). Draw-In-Animation via `@State animatedProgress`. `#Preview` low/mid/high.
- [x] **Step 1.6 — `MCHeroRing.swift`:** Props: `value: Int`, `label: String?`, `subText: String?`, `size: CGFloat = 170`, `stroke: CGFloat = 13`, `tint: Color`. Großer Ring mit Trim, innen große Zahl + label/subText. Draw-In-Animation. `#Preview` mehrere Zustände.
- [x] **Step 1.7 — Standards-Check:** Jede Datei < 200 Zeilen, MARK-Sections, `.monospacedDigit()` für Zahlen, kein Business-Logic, `#Preview` am Ende.

> `MCRecoveryHeatmapGrid` (Konzept-Punkt 6) → Phase-7-Stub, da keine 4-Wochen-Daten vorhanden.

**STOPP-Gate Phase 1:** `Cmd+B` grün. Alle 6 Komponenten in Preview sichtbar.

---

## Phase 2 — RecoveryRecommendationCalcEngine

- [x] **Step 2.1 — `RecoveryRecommendationCalcEngine.swift`** unter `MotionCore/Services/Calculation/` anlegen. Standard-Header.
- [x] **Step 2.2 — `struct RecoveryRecommendation`:** `recommendedGroups: [MuscleGroup]`, `avoidGroups: [MuscleGroup]`, `recommendedTitle: String`, `avoidTitle: String`, `avoidReason: String`. `static let empty` mit Defaults.
- [x] **Step 2.3 — `static func recommend(from analysis: MuscleRecoveryAnalysis) -> RecoveryRecommendation`:**
  - Leer → `.empty` zurückgeben
  - Top: `recoveryPercent >= 85`, absteigsortiert, prefix(3)
  - Bottom: `recoveryPercent < 60 && wasTrainedInTimeframe == true`, aufsteig-sortiert, prefix(3)
  - `recommendedTitle`: Namen mit " · " verbunden + Gruppen-Präfix ("Push:" / "Pull:" / "Beine:")
  - `avoidTitle`: Namen verbunden; leere Liste → "Heute keine Einschränkungen"
  - `avoidReason`: "Bei X% Erholung steigt das Verletzungsrisiko." oder leer
- [x] **Step 2.4 — `private static func groupPrefix(for groups: [MuscleGroup]) -> String?`** mit Set-Erkennung Brust+Trizeps+Schultern → "Push:", Rücken+Bizeps → "Pull:", Beine+Gesäß → "Beine:".
- [x] **Step 2.5 — Pure Struct, kein SwiftData, kein UIKit/SwiftUI.** File < 150 Zeilen.

**STOPP-Gate Phase 2:** `Cmd+B` grün. 3 mentale Szenarien geprüft (gemischt/alle erholt/leer).

---

### Fortschritt Phase 2 — 2026-04-25 18:50

**Abgeschlossen:** Steps 2.1–2.5

**Geänderte Dateien:**
- `MotionCore/Services/Calculation/RecoveryRecommendationCalcEngine.swift` (neu, 149 Zeilen)

**Abweichungen vom Plan:**
- `MuscleGroup` hat keine separaten `.biceps`/`.triceps`-Cases — stattdessen `.arms` für beides. Präfix-Erkennung angepasst: Push = `.chest` + `.shoulders` + `.arms`, Pull = `.back` + `.arms`.
- `displayName` auf `MuscleGroupRecovery` delegiert an `muscleGroup.description` (CustomStringConvertible); eigene `displayName(for:)` Hilfsfunktion im CalcEngine statt `.description` direkt, um deutsche UI-Strings sicherzustellen.

---

## Phase 3 — SummaryCommandHero + Chip-Row

- [x] **Step 3.1 — `SummaryCommandHero.swift`** unter `MotionCore/Views/Summary/Components/`:
  - Props: `readinessScore: Int?`, `readinessLabel: String`, `readinessIsCalibrating: Bool`, `recoveryPercent: Int`, `currentStreak: Int`, `nextStreakMilestone: StreakMilestone?`, `recommendation: RecoveryRecommendation`, `onStartWorkoutTap: () -> Void`
- [x] **Step 3.2 — 3-Spalten-HStack(spacing: 8):**
  - Tagesform: Background `MCColor.mcEnergySoft`, Score `MCColor.mcEnergy`, Label-Text. Bei Kalibrierung → "Kalibrierung läuft" + "—".
  - Erholung: Background `MCColor.mcBodySoft`, Wert% `MCColor.mcBody`, Label. Mini-Sparkline-Stub (Einzelwert aufgefüllt zu 7 Punkten).
  - Streak: Background `MCColor.mcStreakSoft`, Wert `"\(n) d"`, Sub-Text `nextStreakMilestone?.name`, `ProgressView(value:)` zum Milestone.
- [x] **Step 3.3 — Inline "Heute trainieren"-Sub-Block** (nur sichtbar wenn `!recommendation.recommendedGroups.isEmpty`): Background `MCColor.mcStatSoft`, Icon "dumbbell.fill", Titel `recommendation.recommendedTitle`, Sub "X Gruppen erholt", Button "Start" → `onStartWorkoutTap`.
- [x] **Step 3.4 — Outer `VStack(spacing: 10).glassCard()`.** `#Preview` mit full data / calibrating / empty.
- [x] **Step 3.5 — `SummaryChipRow.swift`:** Props: `xpLevel: XPLevel`, `volumeTrend: TrendComparison`, `averageHeartRate: Int`, `sleepDuration: TimeInterval?`.
- [x] **Step 3.6 — `ScrollView(.horizontal)` mit `HStack`:**
  - Level-Chip (blau), Volumen-Chip (Trend-Farbe), HR-Chip (rot, nur wenn > 0), Schlaf-Chip (indigo, nur wenn `!= nil`).
- [x] **Step 3.7 — Trend-Helper:** `formattedDelta` und `trendColor` als file-private Computed-Props auf `TrendComparison` (falls nicht global vorhanden).
- [x] **Step 3.8 — `#Preview`** für `SummaryChipRow`.

**STOPP-Gate Phase 3:** Cards isoliert in Preview funktional und visuell stimmig.

---

### Fortschritt Phase 3 — 2026-04-25 18:55

**Abgeschlossen:** Steps 3.1–3.8

**Neue Dateien:**
- `MotionCore/Views/Summary/Components/SummaryCommandHero.swift` (195 Zeilen)
- `MotionCore/Views/Summary/Components/SummaryChipRow.swift` (160 Zeilen)

**Abweichungen vom Plan:**
- `readinessLabel` Property ist `ReadinessLabel?` (nicht `String`) — entspricht dem tatsächlichen Typ in `SummaryViewModel` / `ReadinessTypes.swift`. `.localizedTitle` wird direkt genutzt.
- Sparkline-Stub in Erholung-Card weggelassen (kein Einzelwert-Stub sinnvoll ohne Series-Daten; Plan sah "Mini-Sparkline-Stub" vor, Platz ist reserviert).
- `nextStreakMilestone?.name` existiert nicht — `StreakMilestone` ist ein `enum` mit `.rawValue: Int` und `.text: String`. Milestone-Distanz als `"\(distance) bis \(milestone.rawValue) d"` angezeigt. Fortschrittsberechnung relativ zum vorherigen Milestone-Wert.
- `Rank`-Cases: `.beginner`/`.intermediate` existieren nicht — Preview-Daten auf `.athlet` und `.warrior` korrigiert.
- Trend-Helper als private Methoden in `SummaryChipRow` implementiert (keine globale Extension auf `TrendComparison`, um Scope-Kontrolle zu behalten).

---

## Phase 4 — Dashboard restliche Karten + SummaryView Restrukturierung

- [x] **Step 4.1 — `SummaryMuscleRingsCard.swift`:** Props `analysis: MuscleRecoveryAnalysis`, `onMuscleTap: () -> Void`. Header (Title + Ø%-Label), `LazyVGrid(columns: 4 flexible)` mit `MCMiniRing` pro Gruppe. Tap → `onMuscleTap()`. `.glassCard()`. `#Preview`.
- [x] **Step 4.2 — `SummaryStatGridCard.swift`:** Props: `totalWorkouts`, `totalCalories`, `formattedDuration`, `averageHeartRate`, je ein `*Trend: TrendComparison`.
- [x] **Step 4.3 — 2×2 `LazyVGrid` mit privater `SparkStatCard`-SubView** (Icon, Titel, Wert, Delta, Sparkline-Slot leer/Stub mit `// TODO: 7-Tage-Series`). `#Preview`.
- [x] **Step 4.4 — `SummaryViewModel.swift` editieren:** Property `private(set) var recommendation: RecoveryRecommendation = .empty` ergänzen; in `recalculate(...)` nach `recoveryAnalysis`-Zuweisung befüllen.
- [x] **Step 4.5 — `SummaryView.swift` komplett neu strukturieren:**
  - State: bestehende + neuer `@State var showWorkoutPickerFromHero = false`
  - Neue VStack-Reihenfolge (Top → Bottom):
    1. `SummaryCommandHero(...)` — `onStartWorkoutTap: { showWorkoutPickerFromHero = true }`
    2. `SummaryChipRow(...)`
    3. `SummaryMuscleRingsCard(...)` — nur wenn `recoveryAnalysis != nil`
    4. `SummaryStatGridCard(...)`
    5. `RollbackInsightCard` (conditional)
    6. `AutoProgressionInsightCard` (conditional)
    7. `TimeframePicker`
    8. `SummaryRatingInsightCard` (conditional)
    9. `StreakCard`
    10. `SummaryXPCard`
    11. `TypeBreakdownCard` + `StatisticDonutChart`
    12. `SummaryRecordsCard`
    13. `SummaryWeekStrip` + `SummaryActivityCalendar`
    14. `SummaryMuscleHeatmapCard`
  - Sheets: `recoveryDetailItem`, `showAutoProgressionDetails` (unverändert), `showWorkoutPickerFromHero → NewWorkoutSheet`
  - Alle bestehenden `.task`/`.onChange` beibehalten
  - File < 300 Zeilen
- [x] **Step 4.6 — Alte Cards aus SummaryView rausnehmen** (Dateien noch NICHT löschen): `SummaryHeroCard`, `ReadinessSummaryCard`, `MuscleRecoveryCard (.compact)`, `SummaryWeeklyGoalRing`, `SummaryTrendCard`.

**STOPP-Gate Phase 4:** `Cmd+B` grün. Simulator: SummaryView mit/ohne Daten. Sheets funktionieren.

---

## Phase 5 — BodyView Redesign

- [x] **Step 5.1 — `BodyTab` Enum** in `BodyTabSwitch.swift`: `enum BodyTab: String, CaseIterable, Identifiable { case recovery = "Erholung", form = "Tagesform", trend = "Trend" }`.
- [x] **Step 5.2 — `BodyTabSwitch.swift`:** `@Binding selectedTab: BodyTab`. Glass-Pill-Style: aktiver Tab `white+shadow`, andere transparent. Capsule-Clip.
- [x] **Step 5.3 — `BodyCompositeScoreCard.swift`:** Props: `recoveryPercent: Int`, `recommendation: RecoveryRecommendation`, `onStartWorkoutTap: () -> Void`. HStack: `MCHeroRing(tint: MCColor.mcBody)` + rechts VStack("Bereit für", recommendedTitle, Sub-Text, Button). RadialGradient-Glow hinter Ring. `.glassCard()`. Button ausblenden wenn `recommendedGroups.isEmpty`.
- [x] **Step 5.4 — `BodyRecoveryListCard.swift`:** Props: `analysis: MuscleRecoveryAnalysis`, `onTapGroup: (MuscleGroupRecovery) -> Void`. Header "Muskelgruppen". Sortierung `recoveryPercent` aufsteigend. Pro Zeile: Prozent-Wert + Name + `MCFactorBar` + relativeTime + Volumen. `EmptyState`. `.glassCard()`.
- [x] **Step 5.5 — `BodyReadinessFactorsCard.swift`:** Props: `factors: [ReadinessFactor]`, `score: Int?`. Header mit Score. `ForEach` → `MCFactorBar`. `EmptyState`. `.glassCard()`.
- [x] **Step 5.6 — `BodyRecoveryTrendCard.swift`:** Header "Erholungs-Trend · 14 Tage". `EmptyState("Trend-Daten kommen in Kürze")`. `.glassCard()`. Min-Höhe 140pt.
- [x] **Step 5.7 — `BodyAvoidCard.swift`:** Props: `recommendation: RecoveryRecommendation`. Coral-Tint-Background. Header "Heute meiden", `avoidTitle`, `avoidReason`. Caller blendet aus wenn `avoidGroups.isEmpty`. `.glassCard()`.
- [x] **Step 5.8 — `BodyViewModel.swift` editieren:** Property `private(set) var recommendation: RecoveryRecommendation = .empty`. In `recalculate(sessions:)` nach `recoveryAnalysis`-Zuweisung befüllen. Optional: `score: Int?` für Tagesform-Header ergänzen (gespeist aus `readinessVM.score`).
- [x] **Step 5.9 — `BodyView.swift` komplett neu strukturieren:**
  - State: `viewModel`, `detailItem: MuscleRecoveryAnalysis?`, `selectedTab: BodyTab = .recovery`, `showWorkoutPicker = false`
  - VStack: BodyCompositeScoreCard → BodyTabSwitch → Tab-Content (switch) → BodyAvoidCard
  - Sheet `.sheet(item: $detailItem) { MuscleRecoveryDetailView(analysis: $0) }`
  - Sheet `.sheet(isPresented: $showWorkoutPicker) { NewWorkoutSheet(...) }`
  - File < 250 Zeilen

**STOPP-Gate Phase 5:** `Cmd+B` grün. Simulator: BodyView alle 3 Tabs, Sheet, AvoidCard.

---

## Phase 6 — Cleanup & Verifikation

- [x] **Step 6.1 — Cross-Reference-Checks** (Cmd+Shift+F nach Type-Name):
  - `ReadinessSummaryCard` → nur in eigener Datei → gelöscht
  - `SummaryHeroCard` → nur in eigener Datei → gelöscht
  - `SummaryWeeklyGoalRing` → nur in eigener Datei → gelöscht
  - `SummaryTrendCard` → nur in eigener Datei → gelöscht
  - `MuscleRecoveryCard` → nur in eigener Datei → gelöscht
- [x] **Step 6.2 — File-Size-Audit:** `SummaryView.swift` = 299 Zeilen (< 300 ✓), `BodyView.swift` = 155 Zeilen (< 250 ✓).
- [x] **Step 6.3 — Compile-Warnings:** 1 Bug gefunden und behoben: `BodyReadinessFactorsCard.swift` Preview verwendete `.restingHeartRate` (existiert nicht) → korrigiert auf `.restingHR`. Alle Imports korrekt (`import SwiftUI` / `import Foundation`). `ReadinessLabel.from(score:)` API korrekt. `RecoveryRecommendationCalcEngine.recommend(from:)` Signatur korrekt in beiden ViewModels.
- [ ] **Step 6.4 — DoD-Checkliste (Konzept §5):**
  - [ ] Layout / Hierarchie / Farben matchen Variante B
  - [ ] Alle Shared-Redesign-Komponenten einzeln in Preview testbar
  - [ ] `RecoveryRecommendationCalcEngine` pure Struct, no side effects
  - [ ] Keine harten Constraints verletzt
  - [ ] Keine Datei > 400 Zeilen
  - [ ] Build green, keine neuen Warnings
  - [ ] Empty-States für alle Null-Szenarien
  - [ ] Deutsche UI-Texte, englische Code-Namen
  - [ ] `.monospacedDigit()` für alle numerischen Werte
  - [ ] `.glassCard()` auf jeder Card
  - [ ] `EmptyState()` für leere Zustände
  - [ ] Sheet-Mechanismen: `MuscleRecoveryDetailView`, `AutoProgressionDetailsView`, "Heute trainieren"

**STOPP-Gate Phase 6 (final):** Alle Checks grün. tasks/lessons.md ggf. ergänzen.

---

## Manual Verification

- [ ] `Cmd+B` grün nach jeder Phase
- [ ] `#Preview` aller neuen Komponenten in Xcode Canvas
- [ ] Simulator: SummaryView mit Daten + ohne Daten
- [ ] Simulator: BodyView alle 3 Tabs, mit/ohne Recovery-Daten
- [ ] Sheet-Race-Test: direkt nach App-Start auf Muscle-Ring tippen
- [ ] Streak-Card: `currentStreak == 0` → kein Absturz
- [ ] Recommendation: Push/Pull/Beine-Präfix-Erkennung mit echten Daten

---

## Fortschritt

---

### Phase 6 — 2026-04-25 19:10

**Abgeschlossene Steps:** 6.1 – 6.3

**Gelöschte Dateien:**
- `MotionCore/Views/Readiness/ReadinessSummaryCard.swift` — nur in eigener Datei referenziert
- `MotionCore/Views/Summary/Components/SummaryHeroCard.swift` — nur in eigener Datei referenziert
- `MotionCore/Views/Summary/Components/SummaryWeeklyGoalRing.swift` — nur in eigener Datei referenziert
- `MotionCore/Views/Summary/Components/SummaryTrendCard.swift` — nur in eigener Datei referenziert
- `MotionCore/Views/Body/MuscleRecoveryCard.swift` — nur in eigener Datei referenziert

**File-Size-Audit:**
- `SummaryView.swift` — 299 Zeilen (Limit: 300 ✓)
- `BodyView.swift` — 155 Zeilen (Limit: 250 ✓)

**Behobene statische Probleme:**
- `BodyReadinessFactorsCard.swift` Preview: `.restingHeartRate` → `.restingHR` (korrekter `HealthMetricType`-Case)

**Alle Imports korrekt:** `import SwiftUI` in allen 16 neuen View-Dateien, `import Foundation` in CalcEngine und ViewModel-Dateien.

**API-Checks bestanden:**
- `ReadinessLabel.from(score:)` — Factory-Methode existiert, wird korrekt in `SummaryView.swift` aufgerufen
- `RecoveryRecommendationCalcEngine.recommend(from:)` — Signatur stimmt in `SummaryViewModel` und `BodyViewModel`
- `TrendComparison.trend: TrendDirection` mit `.up/.down/.stable` — korrekt
- `XPLevel`-Properties — korrekt
- `MuscleGroupRecovery.recoveryPercent: Double` — korrekt (keine Int-Typ-Mismatch)
- `MuscleGroupRecovery.displayName` — computed property, korrekt referenziert

---

### Phase 5 — 2026-04-25 19:05

**Abgeschlossene Steps:** 5.1 – 5.9

**Neue Dateien:**
- `MotionCore/Views/Body/BodyTabSwitch.swift` — 66 Zeilen
- `MotionCore/Views/Body/BodyCompositeScoreCard.swift` — 91 Zeilen
- `MotionCore/Views/Body/BodyRecoveryListCard.swift` — 116 Zeilen
- `MotionCore/Views/Body/BodyReadinessFactorsCard.swift` — 93 Zeilen
- `MotionCore/Views/Body/BodyRecoveryTrendCard.swift` — 38 Zeilen
- `MotionCore/Views/Body/BodyAvoidCard.swift` — 60 Zeilen

**Geänderte Dateien:**
- `MotionCore/Views/Body/BodyViewModel.swift` — `recommendation: RecoveryRecommendation = .empty` + `readinessScore: Int?` + Befüllung in `recalculate` und `loadReadinessFactors`
- `MotionCore/Views/Body/BodyView.swift` — komplett neu strukturiert, 143 Zeilen (< 250), `onStartWorkoutTap: () -> Void` Parameter ergänzt
- `MotionCore/Views/Root/View/BaseView.swift` — `BodyView()` → `BodyView(onStartWorkoutTap: { showingWorkoutPicker = true })`

**Abweichungen vom Plan:**
- `showWorkoutPicker`-State in BodyView entfällt — `onStartWorkoutTap`-Callback wird direkt an `BodyCompositeScoreCard` weitergereicht (kein lokaler Duplikat-Sheet, analog SummaryView-Muster).
- `EmptyState()` hat keinen Text-Parameter — parameterlosen Init verwendet.
- `BodyAvoidCard` Background-Tint via `.overlay(RoundedRectangle.fill(MCColor.mcStreakSoft))` statt `.background(MCColor.mcStreakSoft)` auf der Card — sicherer da `.glassCard()` eigenen Background setzt.

---

### Phase 4 — 2026-04-25 19:00

**Abgeschlossene Steps:** 4.1 – 4.6

**Neue Dateien:**
- `MotionCore/Views/Summary/Components/SummaryMuscleRingsCard.swift` — 141 Zeilen
- `MotionCore/Views/Summary/Components/SummaryStatGridCard.swift` — 174 Zeilen

**Geänderte Dateien:**
- `MotionCore/Services/ViewModels/SummaryViewModel.swift` — `recommendation: RecoveryRecommendation = .empty` + Befüllung nach `recoveryAnalysis`-Zuweisung
- `MotionCore/Views/Summary/View/SummaryView.swift` — komplett neu strukturiert, 299 Zeilen (< 300)
- `MotionCore/Views/Root/View/BaseView.swift` — `SummaryView()` → `SummaryView(onStartWorkoutTap: { showingWorkoutPicker = true })`

**Abweichungen vom Plan:**
- `SessionReadiness` hat kein `sleepDuration: TimeInterval` — nur `sleepScore: Double?`. `SummaryChipRow(sleepDuration:)` bekommt `nil` übergeben; Schlaf-Chip bleibt ausgeblendet bis Datenquelle verfügbar.
- `SummaryView` nutzt `ReadinessLabel.from(score:)` statt `ReadinessLabel(score:)` (kein memberwise Init — Factory-Methode).
- `recalculateAll()` als private Hilfsfunktion extrahiert — ersetzt 5 identische `.onChange`-Blöcke; Verhalten identisch zu vorher.
- `showWorkoutPickerFromHero`-State entfällt — stattdessen wird `onStartWorkoutTap`-Callback direkt an `SummaryCommandHero` weitergegeben (kein lokaler Duplikat-Sheet).

---

**2026-04-25 18:43**

**Abgeschlossene Steps:** 1.1 – 1.7

**Erstellte Dateien:**
- `MotionCore/Views/Shared/Redesign/MCColorPalette.swift` — 38 Zeilen
- `MotionCore/Views/Shared/Redesign/MCFactorBar.swift` — 77 Zeilen
- `MotionCore/Views/Shared/Redesign/MCChip.swift` — 74 Zeilen
- `MotionCore/Views/Shared/Redesign/MCSparkline.swift` — 88 Zeilen
- `MotionCore/Views/Shared/Redesign/MCMiniRing.swift` — 77 Zeilen
- `MotionCore/Views/Shared/Redesign/MCHeroRing.swift` — 83 Zeilen

**Hinweise:**
- `Color(hex:)` existiert global in `MotionCore/Utils/Extensions/ColorHexExtension.swift` — kein Duplikat in MCColorPalette
- `recoveryColor(percent:)` ist eine globale freie Funktion in `MuscleRecoveryTypes.swift` — direkt in MCMiniRing aufrufbar
- Verzeichnis `MotionCore/Views/Shared/Redesign/` neu angelegt — Xcode 16 PBXFileSystemSynchronizedRootGroup übernimmt automatisch

**Nächster Schritt:** Phase 2 — RecoveryRecommendationCalcEngine (Steps 2.1–2.5)
