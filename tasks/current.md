# Smart Progression + Readiness + Training Intelligence (Phase 1)

**Complexity:** Large

## Summary

Einführung eines neuen Smart-Progression-Systems, eines Readiness-Signals und einer Training-Intelligence-Schicht (Volumen, Split-Hints, Session-Qualität). Phase 1 ersetzt die komplette bestehende `ProgressionCalcEngine`/`ProgressionAnalyseView`-Welt durch ein schlankes, datengetriebenes Modell (Studio-Equipment-Profil, `ExerciseProgressionState`, RIR am letzten Satz). Die Umsetzung erfolgt in 22 streng sequentiellen, einzeln freigegebenen Schritten gemäß Instruction-Doc v1.1.

## Scope

**Drin (Phase 1):**
- Neue SwiftData-Modelle: `Studio`, `StudioEquipment`, `ExerciseProgressionState`, `SessionReadiness`, `HealthBaseline` + zugehörige Enums (`StudioEquipmentType`, `ProgressionMode`, `HealthMetricType`)
- Additive Felder auf `Exercise`, `ExerciseSet`, `StrengthSession`
- Cross-Reference-Check und Legacy-Entfernung aller alten Progression-Views, -ViewModels, -CalcEngines
- Neue `ProgressionCalcEngine`, `RollbackDetectionCalcEngine`, `SessionQualityCalcEngine`
- Studio-Setup-UI + Default-Seeder + Medikamenten-Schalter
- Smart-Fill / Feintuning-Chips / RIR-Sheet am letzten Satz / Quick-Config in ActiveWorkout
- Rollback-Insight-Karte + manueller Rollback-Service
- Supabase-Schema-Erweiterung (neue Tabellen + Spalten)

**Draußen (in Phase 1):**
- Adaptive Learning pro User
- Periodisierung über Wochen / Exercise-Swap-Vorschläge
- Cardio-/E-Bike-Progression
- Multi-Studio-UI (Datenmodell vorbereitet, UI zeigt nur eins)
- Medikamenten-Liste (nur Schalter)
- `ExerciseRating`-System (bleibt unverändert)
- `PlanUpdateCalcEngine` (bleibt unverändert)
- Readiness-Logik (Phase 2)
- Volumen-Ampel + Dynamic-Split-Hints (Phase 3)

## Referenzen

- Concept: `Documentation/Concepts/MotionCore_SmartProgression_Concept_v1.1.md`
- Instruction: `Documentation/Instructions/MotionCore_SmartProgression_Instruction_v1.1.md`
- Abhängigkeits-Graph: Anhang A im Instruction-Doc
- Agent-Briefing-Template: Anhang B im Instruction-Doc

## UX Placement

- Primär-Touchpoint: **ActiveWorkoutView** (Smart-Fill, Feintuning-Chips, RIR-Sheet, Quick-Config über ⚙️)
- Sekundär: **SummaryView** (Rollback-Insight-Karte, Session-Qualitätsscore)
- Setup: **Settings → Studio einrichten** (neue View `StudioSetupView`) + **Settings → Gesundheit/Tagesform** (Medikamenten-Schalter)
- Rationale: Progression ist eine Laufzeit-Entscheidung, nicht ein Konfigurations-Ort. Daten folgen dem User, nicht dem Formular.
- Rejected Alternatives:
  - Eigener Tab "Progression" (abgelehnt — `ProgressionAnalyseView` war der eigentliche Pain Point)
  - Progression-Section im `ExerciseForm` (abgelehnt — zu versteckt, kommt nur als Quick-Config-Link wieder)

## Affected Files (Gesamt Phase 1 — grober Scope)

- `MotionCore/Models/Core/Studio.swift` — neues Model
- `MotionCore/Models/Core/StudioEquipment.swift` — neues Model
- `MotionCore/Models/Core/StudioEquipmentType.swift` — neues Enum
- `MotionCore/Models/Core/ExerciseProgressionState.swift` — neues Model
- `MotionCore/Models/Core/ProgressionMode.swift` — neues Enum
- `MotionCore/Models/Core/SessionReadiness.swift` — neues Model
- `MotionCore/Models/Core/HealthBaseline.swift` — neues Model
- `MotionCore/Models/Core/HealthMetricType.swift` — neues Enum
- `MotionCore/Models/Core/Exercise.swift` — neue Felder, später Feld-Entfernung
- `MotionCore/Models/Core/ExerciseSet.swift` — `isLastSetOfExercise`
- `MotionCore/Models/Core/StrengthSession.swift` — Quality-Score, Readiness-Link
- `MotionCore/App/MotionCoreApp.swift` — Schema + Seeder-Hook
- `MotionCore/Services/Calculation/ProgressionCalcEngine.swift` — ersetzt
- `MotionCore/Services/Calculation/RollbackDetectionCalcEngine.swift` — neu
- `MotionCore/Services/Calculation/SessionQualityCalcEngine.swift` — neu
- `MotionCore/Services/EquipmentWeightRounding.swift` — neuer Helper
- `MotionCore/Services/DefaultStudioSeeder.swift` — neu
- `MotionCore/Services/ProgressionRollbackService.swift` — neu
- `MotionCore/Views/Settings/StudioSetupView.swift` + zwei Hilfs-Views — neu
- `MotionCore/Views/ActiveWorkout/*` — RIR-Sheet, Feintuning-Chips, Quick-Config
- `MotionCore/Views/Summary/RollbackInsightCard.swift` — neu
- `MotionCore/Views/Progression/*` — mehrere Files werden gelöscht (Legacy)
- `MotionCore/Services/Supabase/SupabaseFullBackupService.swift` — neue Tabellen

## Risks

- **SwiftData-Migration:** Feld-Entfernungen auf `Exercise` (Schritt 1.11) dürfen bestehende Stores nicht bricken — lightweight migration muss greifen, Production-CloudKit-Schema bleibt additiv.
- **CloudKit-Schema:** Neue Models müssen alle Properties optional/default haben und Inverse-Relations korrekt gepaart.
- **Cross-Dependencies bei Löschungen:** `TrendPoint`, `AnalyseSegment`, `SessionSnapshot` usw. können außerhalb der zu löschenden Files benutzt werden — Schritt 1.7 ist Pflicht-Gate.
- **File-Size:** `ActiveWorkoutView.swift` liegt bereits bei ~2000 Zeilen → Splits in 1.16/1.18/1.19 zwingend, Quality-Gate entscheidet.
- **Watch-Target-Parität:** `WatchMessageKeys.swift` / `WatchHealthDataTypes.swift` müssen synchron gepflegt werden, wenn neue Felder die Watch erreichen (erst ab 2.x relevant — trotzdem überwachen).
- **Supabase-Schema:** Neue Tabellen in `motioncore`-Schema müssen UNRESTRICTED angelegt werden (kein RLS).
- **Naming-Konflikte:** `StudioEquipmentType` (nicht `EquipmentType`), weil `ExerciseEquipment` bereits existiert — bestätigt via Grep in `MotionCore/Models/Types/ExerciseTypes.swift:53`.

## Phase-1-Checkliste (22 Schritte)

> Policy: Jeder Schritt hat einen STOPP-Gate. Kein Schritt startet ohne explizite Freigabe durch Barto. Status unten wird pro Schritt gepflegt.

- [x] **1.1** Datenmodell: Studio & StudioEquipment
- [x] **1.2** Datenmodell: `ExerciseProgressionState` + `ProgressionMode`
- [x] **1.3** Additive Model-Erweiterungen (Exercise + ExerciseSet + Readiness-Models + StrengthSession) — committed (d668e6b)
- [x] **1.7** Cross-Reference-Check vor Legacy-Entfernung — Report liegt vor (`tasks/domain/2026-04-18-phase1-1.7-cross-reference-check.md`)
- [ ] ~~1.8 TrendPoint-Extraktion~~ — **n/a, entfällt** (TrendPoint lebt bereits in StatisticCalcEngine.swift)
- [x] **1.9** Legacy-UI-Entfernung (Views) — committed (726fce1) + Heatmap-Rewire (8c0f0db)
- [x] **1.10** Legacy-CalcEngines + ViewModel entfernen — committed (bf14fee)
- [x] **1.11** Exercise-Felder entfernen + SetConfigSheet-UI + ProgressionTypes.swift löschen — committed (c3629c8)
- [x] **1.12** Studio-Setup + Default-Seeder — committed (428e801)
- [x] **1.13** Medikamenten-Schalter in Settings — committed (148bda8)
- [x] **1.14** Neue `ProgressionCalcEngine` *(implementiert 2026-04-18)*
- [ ] 1.15 `RollbackDetectionCalcEngine` *(geplant nach Freigabe)*
- [ ] 1.16 Smart-Fill im ActiveWorkoutView *(geplant nach Freigabe)*
- [ ] 1.17 Feintuning-Button für Zwischengewichte *(geplant nach Freigabe)*
- [ ] 1.18 RIR-Sheet am letzten Satz *(geplant nach Freigabe)*
- [ ] 1.19 Quick-Config aus ActiveWorkout *(geplant nach Freigabe)*
- [ ] 1.20 Rollback-Insight-Karte + manueller Rollback *(geplant nach Freigabe)*
- [ ] 1.21 `SessionQualityCalcEngine` + Integration *(geplant nach Freigabe)*
- [ ] 1.22 Supabase-Schema-Erweiterung *(geplant nach Freigabe)*

---

## Aktueller Schritt: 1.14 — Neue ProgressionCalcEngine

### Ziel

Pure, stateless `ProgressionCalcEngine` (Input → Output) gemäß Concept 4.1 aufbauen, inkl. Typen-Datei und Equipment-aware Rounding-Helper. Keine SwiftUI-Imports, keine State-Mutation, deterministisch.

### Files (erwartet)

**NEU (3):**
- `MotionCore/Services/Calculation/ProgressionCalcEngine.swift` — Pure Engine mit `Input`, `Output`, `static func calculate(input:)`
- `MotionCore/Services/Calculation/ProgressionTypes.swift` — `ProgressionReasoning`-Enum
- `MotionCore/Services/EquipmentWeightRounding.swift` — Equipment-aware Rounding-Helper (wiederverwendbar für 1.17)

### Cross-References (bestehende Typen)

- `ExerciseProgressionState` (workingWeight, previousWorkingWeight, targetReps, minTargetReps, maxTargetReps, progressionMode, lastProgressionDate)
- `ProgressionMode` (.smart/.advanced/.off)
- `ExerciseSet` (weight, reps, rpe, calculatedRIR, isLastSetOfExercise, isCompleted, setKindRaw, sortOrder)
- `StudioEquipment` (startWeight, increment, minWeight, maxWeight, intermediateIncrements)

Pfad-Konflikt-Check: Legacy-Files `ProgressionCalcEngine.swift` und `ProgressionTypes.swift` in 1.10/1.11 gelöscht. Kein Konflikt.

### Detail-Steps

#### 1.14.1 — ProgressionTypes.swift
```swift
enum ProgressionReasoning: String, Codable {
    case holdWeight, increaseWeight, bigIncrease
    case rollbackSuggested, firstSession, readinessReduced, noProgression
}
```
Top-Level, String-RawValue für Debug/Supabase. Keine weiteren Typen hier (Input/Output bleiben engine-lokal).

#### 1.14.2 — EquipmentWeightRounding.swift
```swift
enum EquipmentWeightRounding {
    static func roundToValidWeight(_ weight: Double, equipment: StudioEquipment?, fallbackStep: Double) -> Double
}
```
- `equipment == nil`: auf Vielfache von `fallbackStep` (Guard: > 0, sonst 2.5)
- `equipment != nil`: `steps = ((weight - startWeight) / increment).rounded()`, `candidate = startWeight + steps * increment`, dann `max(minWeight)` und optional `min(maxWeight)`
- `intermediateIncrements` werden **nicht** verwendet (reserviert für 1.17)
- Div-by-Zero-Guard: `step = max(increment, 0.0001)`

#### 1.14.3 — ProgressionCalcEngine.swift

Struct mit `Input`/`Output` gemäß Concept 4.1. Entscheidungsbaum in dieser Reihenfolge:

1. **`currentSessionSetIndex > 0 && !currentSessionPreviousSets.isEmpty`** → `.holdWeight`: Gewicht = letzter abgeschlossener Work-Set der aktuellen Session, Reps = `progressionState.targetReps`
2. **`lastSessionSets.isEmpty`** → `.firstSession`: Gewicht = `workingWeight`, Reps = `targetReps`
3. **Modus `.off` oder `.advanced`** → `.noProgression`: unverändert aus `progressionState`
4. **`readinessModifier < 0.9`** → `.readinessReduced`: `roundToValidWeight(workingWeight × modifier, ..., floor)`, Reps unverändert
5. **Letzte-Session-Analyse** (nur `isCompleted && setKindRaw == "work"` nach `sortOrder`):
   - `lastSet = workSets.first { $0.isLastSetOfExercise } ?? workSets.last` (Fallback für Legacy-Sessions)
   - `allHitTarget = workSets.allSatisfy { reps ≥ targetReps }`
   - `lastRIR = lastSet?.calculatedRIR ?? 0`
   - **5a** `allHitTarget && lastRIR ≤ 1` → `.increaseWeight` (+1×increment, gerundet), `isProgressionStep = true`
   - **5b** `allHitTarget && lastRIR ≥ 3` → `.bigIncrease` (+2×increment), `isProgressionStep = true`
   - **5c** `repsBelowMin && lastRIR == 0 && !recentProgression` → `.holdWeight`
   - **5d** `repsBelowMin && recentProgression` → `.rollbackSuggested`, Gewicht = `previousWorkingWeight ?? workingWeight` (gerundet), `isRollbackCandidate = true`
   - `recentProgression = lastProgressionDate < 14 Tage alt` (Engine-Proxy; finale Session-Prüfung in 1.15)
6. **Fallback** → `.holdWeight`

Reihenfolge 5a → 5b → 5d → 5c: Progressions-Zweig zuerst, dann Rollback vor Hold.

**Kommentar-Block am Ende** mit allen 8 Testszenarien.

### Manuelle Tests (8 Szenarien)

1. Empty history → `.firstSession`
2. Modus `.off` → `.noProgression`
3. Alle Sätze ≥ target, lastSet rpe=9 → `.increaseWeight`
4. Alle Sätze ≥ target, lastSet rpe=6 → `.bigIncrease`
5. Reps < min, lastSet rpe=10, lastProgressionDate > 14d → `.holdWeight`
6. Reps < min, lastProgressionDate = heute-5d → `.rollbackSuggested` mit `previousWorkingWeight`
7. readinessModifier=0.85 → `.readinessReduced`, Gewicht floor-gerundet
8. currentSessionSetIndex=1, prev=60kg → Gewicht 60kg, `.holdWeight`

### Build-Check

- [ ] iOS Build grün
- [ ] watchOS Build grün (Kontrolle — Engine iOS-only, Models shared)
- [ ] Keine neuen Warnings
- [ ] App startet (Engine noch nicht aufgerufen)

### Risks / Edge Cases

- **RIR/rpe-Verwechslung:** IMMER `calculatedRIR` nutzen, nicht `rpe`. `rpe == 0` bei leerem Default wäre sonst fälschlich "RIR 10"
- **RIR 2 (mittel) + alle Reps erreicht** → fällt in Fallback `.holdWeight`, Concept-konform, Inline-Kommentar für Reviewer
- **`lastProgressionDate`-Proxy** (< 14 Tage) — Engine kennt keine Session-Zahl; finale Prüfung in 1.15
- **`isLastSetOfExercise`-Fallback** für Legacy-Sessions vor 1.4: auf `workSets.last` zurück
- **Equipment-Div-by-Zero:** `increment = 0` → Guard `max(increment, 0.0001)`
- **`startWeight > weight`:** Rounder liefert `max(candidate, minWeight)` — nicht negativ
- **Nur-Warmup-Sätze in aktueller Session:** currentSessionPreviousSets ohne Work-Set → Pfad 1 feuert nicht (prüfe `filter { isCompleted && setKindRaw == "work" }.isEmpty`)
- **`targetReps`-Trennung:** Engine nutzt nur `progressionState.targetReps`. Caller in 1.16 berechnet effektive Target aus `customTargetReps ?? repRangeMin/Max`. Engine bleibt pure.
- **Determinismus:** Keine Date-Reads in Engine außer `recentProgression`-Check (Parameter `Date.now` in Aufrufer übergeben? → nein, Engine liest `Date()` lokal, Dokumentation im Kommentar)

### Offene Produktfrage

- **Rounding-Richtung bei `.readinessReduced`:** `.rounded()` (nearest) kann in Edge-Cases auf > `workingWeight` aufrunden (60 × 0.9 = 54 → nearest 55). **Vorschlag: `.floor` (abrunden)** — semantisch passt "nimm es leichter". Bestätigung erbeten.

🛑 **STOPP 1.14** — Warte auf Freigabe + Entscheidung zur Rounding-Richtung.

---

## Fortschritt

- **2026-04-18** — Schritt 1.9 implementiert. 13 Legacy-Files gelöscht, 5 Files bereinigt, Views/Progression/ → Views/Heatmap/ umbenannt, CLAUDE.md Tab-Liste auf 4 Einträge reduziert.
- **2026-04-18** — Plan 1.1 erstellt.
- **2026-04-18** — Schritt 1.1 implementiert. Dateien: `StudioEquipmentType.swift` (neu), `Studio.swift` (neu), `StudioEquipment.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
- **2026-04-18** — Schritt 1.1 committed (5744842). Plan 1.2 erstellt.
- **2026-04-18** — Schritt 1.2 implementiert. Dateien: `ProgressionMode.swift` (neu), `ExerciseProgressionState.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
- **2026-04-18** — Schritt 1.2 committed (28ea5b2). Schritte 1.3+1.4+1.5+1.6 zu neuem Schritt 1.3 gebündelt. Plan erstellt.
- **2026-04-18** — Schritt 1.3 implementiert. Dateien: HealthMetricType.swift (neu), HealthBaseline.swift (neu), SessionReadiness.swift (neu), Exercise.swift (+4 Felder), ExerciseSet.swift (+1 Feld), StrengthSession.swift (+2 Felder), MotionCoreApp.swift (Schema +2).
- **2026-04-18** — Schritt 1.3 committed (d668e6b). Bug-Fix (162877e) committed. Schritt 1.7 Cross-Reference-Check durchgeführt, Report unter `tasks/domain/2026-04-18-phase1-1.7-cross-reference-check.md`. 1.8 entfällt (n/a).
- **2026-04-18** — Heatmap-Rewire: MuscleHeatmapView als 3. Segment in StatsAndRecordsView integriert (Followup zu 1.9).
- **2026-04-18** — Schritt 1.9 committed (726fce1). Heatmap-Rewire committed (8c0f0db). Plan 1.10 erstellt.
- **2026-04-18** — Schritt 1.10 committed (bf14fee). Plan 1.11 erstellt.
- **2026-04-18** — Schritt 1.11 committed (c3629c8). Legacy-Progression komplett entfernt. Plan 1.12 erstellt.
- **2026-04-18** — Schritt 1.12 committed (428e801). Schritt 1.13 committed (148bda8). Plan 1.14 erstellt.
- **2026-04-18** — Schritt 1.10 implementiert. 3 Legacy-Files gelöscht, SummaryViewModel bereinigt.
- **2026-04-18** — Schritt 1.11 implementiert. 4 Stored Properties (progressionSessionsRequired, progressionStrategyRaw, customProgressionStep, minDaysBetweenProgressions) + 4 Computed Properties (progressionStrategy, baseProgressionStep, effectiveProgressionStep, canRecommendProgression) aus Exercise.swift entfernt. ExerciseProgressionSection (256 Zeilen) aus FormViewSection.swift gelöscht. 9 Stellen in SetConfigurationSheet.swift bereinigt (4 State-Inits, 4 @State-Declarations, If-Else-Block vereinfacht, 4 Save-Zuweisungen entfernt). 11-Zeilen-Block aus ExerciseFormView.swift entfernt. ProgressionTypes.swift per git rm gelöscht. Finale Grepping: alle Legacy-Typen 0 Treffer.
- **2026-04-18** — Schritt 1.12 implementiert. DefaultStudioSeeder + StudioSetupView + StudioEquipmentEditSheet + StudioEquipmentRow + MainSettings-Link + Seeder-Hook.
- **2026-04-18** — Schritt 1.13 implementiert. AppSettings.takesCardioMedication + Toggle in UserSettingsView.
- **2026-04-18** — Schritt 1.14 implementiert. ProgressionCalcEngine + ProgressionTypes + EquipmentWeightRounding (3 neue Files).
