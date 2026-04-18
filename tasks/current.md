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
- [x] **1.14** Neue `ProgressionCalcEngine` — committed (c99b6d4)
- [x] **1.15** `RollbackDetectionCalcEngine` — committed (d322ad2)
- [x] **1.16** Smart-Fill im ActiveWorkoutView — committed (548eb0f)
- [x] **1.17** Feintuning-Chips für Zwischengewichte — committed (e0abe61)
- [x] **1.18** RIR-Sheet am letzten Satz *(implementiert 2026-04-18)*
- [ ] 1.19 Quick-Config aus ActiveWorkout *(geplant nach Freigabe)*
- [ ] 1.20 Rollback-Insight-Karte + manueller Rollback *(geplant nach Freigabe)*
- [ ] 1.21 `SessionQualityCalcEngine` + Integration *(geplant nach Freigabe)*
- [ ] 1.22 Supabase-Schema-Erweiterung *(geplant nach Freigabe)*

---

## Aktueller Schritt: 1.18 — RIR-Sheet am letzten Satz

### Ziel

Beim Abschließen des letzten Work-Sets einer Übung öffnet sich ein kompaktes Sheet: kompakter RestTimer oben (~60% Höhe) + einzeilige RIR-Buttons `0 1 2 3 4+` (je ~48pt, gleich breit) + Skip-Link. Tap → `set.rpe = 10 - rir` (4+ → `rpe = 6`). Skip → `rpe` bleibt 0. Setzt `isLastSetOfExercise = true` auf dem Set. Zeitlich getrennt von `ExerciseRatingCard` (kommt danach im `ExerciseCompletedCard`).

### Files

**NEU (2):**
- `MotionCore/Views/Workouts/Active/Components/RIRInputSheet.swift` (~150 Zeilen)
- `MotionCore/Views/Workouts/Active/Components/CompactRestTimerView.swift` (~80 Zeilen, eigene View statt `isCompact`-Parameter)

**ÄNDERN (1):**
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` (~50 Zeilen):
  - `@State rirSheetSet: ExerciseSet?`
  - In `completeSet(_:)` nach `isCompleted = true`: `isLastWorkSet(of:)` prüfen → Flag setzen
  - Am Ende `completeSet(_:)` (Nicht-Superset-Pfad): `rirSheetSet = set` bei `isLastSetOfExercise`
  - `.sheet(item: $rirSheetSet) { ... }` mit `.presentationDetents([.fraction(0.45)])`
  - Optional Cleanup-Helper bei Add-Set/Delete-Set (Produktfrage)

### Compact-RestTimer: eigene View statt Parameter

Begründung: `RestTimerCard` hat Ring 210pt + Next-Set-Block + Superset-Block + Adjust-Buttons + Skip-Button — alles auf Standalone-Card ausgelegt. Eine `isCompact`-Variante würde fast jede Subview conditional machen. 15 Zeilen Formatter-Duplikation sind akzeptabel.

### Erkennung-Letzter-Satz

```swift
private func isLastWorkSet(of set: ExerciseSet) -> Bool {
    guard set.setKind == .work else { return false }
    let workSets = session.safeExerciseSets.filter {
        $0.groupKey == set.groupKey && $0.setKind == .work
    }
    return workSets.allSatisfy { $0.isCompleted }
}
```

Warmup-Sätze zählen nicht. Check erfolgt NACH `set.isCompleted = true`, daher "alle completed" stabil.

### Timer-Verhalten

**Variante C (gewählt):** `restTimerManager.start(seconds:)` läuft **immer**, auch beim letzten Set. Hero-Card zeigt großen Timer im Hintergrund. RIR-Sheet zeigt zusätzlich kompakten Timer. Sheet-Dismiss → großer Timer bleibt sichtbar. Keine Race, kein Logik-Eingriff.

### Detail-Steps

**CompactRestTimerView:** Ring ~130pt (62% von 210), Zeit-Text 44pt monospace, kleine ±15s-Buttons. Kein `.glassCard()` (Sheet selbst ist Glas).

**RIRInputSheet:**
```swift
struct RIRInputSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var restTimerManager: RestTimerManager
    let targetSeconds: Int
    let onAdjustRest: (Int) -> Void
    let onSelectRIR: (Int) -> Void   // 0..4, 4 = "4+"
    let onSkip: () -> Void
    // CompactRestTimerView + "Wie viele Reps wären noch drin gewesen?" + 5 gleich breite Buttons + "Überspringen"
    // .presentationDetents([.fraction(0.45)]) + .presentationDragIndicator(.visible)
}
```

Button-Row: `HStack(spacing: 8)`, jeder Button `frame(maxWidth: .infinity, minHeight: 48)`.

Tap-Mapping: `rir in 0..3` → `rpe = 10 - rir`. `rir == 4` → `rpe = 6`.

**ActiveWorkoutView-Hooks:**
```swift
// Vor PR-Check in completeSet(_:):
if isLastWorkSet(of: set) {
    set.isLastSetOfExercise = true
}

// Am Ende completeSet(_:), nur Nicht-Superset:
if set.supersetGroupId == nil && set.isLastSetOfExercise {
    rirSheetSet = set
}
```

### Edge-Cases (Produktfragen offen)

| Fall | Vorschlag |
|---|---|
| Add-Set nach RIR | Alter Satz behält `rpe` + Flag → false; neuer Satz bekommt Flag `true` beim Abschluss (Cleanup-Helper) |
| Delete-Set | Vorheriger completed Work-Set bekommt Flag `true`, wenn alle noch completed |
| Swipe-Dismiss | wie Skip: `rpe` bleibt 0 |
| Superset | Kein RIR-Sheet in Phase 1 (`supersetGroupId == nil`-Gate) |

### Manuelle Tests

1. 3-Sätze-Übung: Satz 1/2 normaler Timer. Satz 3 → Sheet öffnet mit Timer oben + 5 Buttons.
2. Tap 0 → `rpe=10`. Tap 3 → `rpe=7`. Tap 4+ → `rpe=6`. Skip → `rpe=0`.
3. Swipe-Dismiss → wie Skip.
4. iPhone SE + iPhone 15: 5 Buttons einzeilig, Sheet ≈45%.
5. Nach Sheet-Dismiss → weitere Übung startbar, `ExerciseRatingCard` zeitlich getrennt funktional.
6. Superset-Übung letzter Satz → **kein** Sheet.
7. Warmup-Satz als letzter → nicht als "letzter Work-Set" gezählt.
8. Add-Set nach RIR → Flag-Hygiene stimmt.

### Build-Check

- [ ] iOS Build grün
- [ ] watchOS Build grün
- [ ] Keine neuen Warnings
- [ ] Preview RIRInputSheet rendert
- [ ] 3-Sätze-Training: Sheet triggert korrekt

### Risks

1. **File-Size ActiveWorkoutView (2161 Zeilen):** weit über 800-Hartlimit. 1.18 fügt ~50 Zeilen hinzu. Split spätestens vor 1.19 zwingend — **separater Refactor-Schritt** empfohlen.
2. **Timer-Doppelanzeige:** großer Timer hinter Sheet + Compact im Sheet. Mit Backdrop-Blur harmlos, testen.
3. **Skip-Semantik:** `rpe = 0` hat `calculatedRIR = 10` (fälschlich "10 Reps übrig"). `ProgressionCalcEngine.hasRIRData` (seit 1.14) behandelt `rpe == 0` bereits als "unbekannt" → kompatibel.
4. **Cleanup-Helper:** Ohne Implementierung bleibt Flag stale bei Add/Delete-Set — UX-relevant für spätere Aggregationen.

### Offene Produktfragen

1. **Cleanup-Helper für Add-Set/Delete-Set in 1.18 mitnehmen?** (~20 Zeilen + 2 Call-Sites). → Vorschlag: **ja**, Flag-Hygiene stimmt.
2. **Split ActiveWorkoutView vor 1.19 oder später?** → Vorschlag: **separater Refactor-Schritt** (z.B. 1.18.5) nach 1.18.
3. **Skip-Semantik `rpe = 0`:** bleibt. ProgressionCalcEngine handhabt bereits korrekt. → Bestätigen?

🛑 **STOPP 1.18** — Warte auf Entscheidungen zu den 3 Produktfragen + Freigabe.

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
- **2026-04-18** — Schritt 1.14 committed (c99b6d4). Schritt 1.15 implementiert.
- **2026-04-18** — Schritt 1.15 committed (d322ad2). Plan 1.16 erstellt.
- **2026-04-18** — Schritt 1.16 committed (548eb0f). Schritt 1.17 committed (e0abe61). Plan 1.18 erstellt.
- **2026-04-18** — Schritt 1.16 implementiert. Resolver + SmartFillViewModel + ExerciseSet.isEngineSuggestion + ActiveWorkoutView-Hooks + ActiveSetCard-Badge/Reasoning-Label.
- **2026-04-18** — Schritt 1.16 Scope-Korrektur: Produktfragen 2A + 3A (Reasoning-Label entfernt, ExerciseSet.isEngineSuggestion entfernt, Tracking zurück auf In-Memory Dictionary im ViewModel).
- **2026-04-18** — Schritt 1.17 implementiert (FineTuneChipsView + SetEditSheet-Einbau).
- **2026-04-18** — Schritt 1.18 implementiert. RIRInputSheet + CompactRestTimerView + ActiveWorkoutView-Hooks + Cleanup-Helper.
