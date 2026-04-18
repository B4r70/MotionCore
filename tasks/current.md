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
- [x] **1.18** RIR-Sheet am letzten Satz — committed (0564bd4)
- [x] **1.19** Quick-Config aus ActiveWorkout — committed (17076be)
- [x] **1.20** Rollback-Insight-Karte + manueller Rollback
- [x] **1.21** `SessionQualityCalcEngine` + Integration
- [ ] 1.22 Supabase-Schema-Erweiterung *(geplant nach Freigabe)*

---

## Aktueller Schritt: 1.20 — Rollback-Insight-Karte + manueller Rollback

### Ziel

SummaryView zeigt eine aggregierende Rollback-Insight-Karte (max 3 Übungen), wenn `RollbackDetectionCalcEngine.detect(...)` `shouldSuggestRollback == true` liefert. Pro Übungszeile: 3 Aktionen (Zurück auf X kg / Weiter versuchen / Ich trage selbst ein). Manueller Rollback-Button in `StrengthDetailView` pro Exercise-Block mit Bestätigungsdialog. Writes über neuen `ProgressionRollbackService` (pure static struct).

### Files

**NEU (2):**
- `MotionCore/Services/ProgressionRollbackService.swift` (~90 Z)
- `MotionCore/Views/Summary/Components/RollbackInsightCard.swift` (~180 Z)

**ÄNDERN (3):**
- `MotionCore/Services/ViewModels/SummaryViewModel.swift` — neuer DTO `RollbackSuggestion`, `rollbackSuggestions`-State, `recalculateRollbackSuggestions(states:strengthSessions:)`
- `MotionCore/Views/Summary/View/SummaryView.swift` — `@Query ExerciseProgressionState`, Karte zwischen `SummaryTrendCard` und `TimeframePicker`
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — Manual-Button im Exercise-Block-Header + ConfirmationDialog

### Service-API

```swift
struct ProgressionRollbackService {
    static func applyRollback(state:in:)      // workingWeight = previousWorkingWeight,
                                              // lastRollbackDate = now,
                                              // consecutiveFailCount = 0,
                                              // lastProgressionDate = nil
    static func dismissSuggestion(state:in:)  // consecutiveFailCount = 0,
                                              // lastRollbackDate = now (Cooldown)
    static func switchToAdvanced(state:in:)   // progressionMode = .advanced
    static func manualRollback(state:in:)     // Guard previousWorkingWeight != nil,
                                              // identisch zu applyRollback
}
```

Alle setzen `updatedAt = now` + `try? context.save()`.

### UI-Layout RollbackInsightCard

```
⚠ Rollback vorgeschlagen
Zwei schwache Sessions nach letzter Progression.
──────────────────────────
Bankdrücken            80 → 75 kg
[Zurück auf 75 kg]
[Weiter versuchen]  [Ich trage selbst ein]
──────────────────────────
Beinpresse           120 → 113 kg
...
```

- `.glassCard()` mit Warnung-Header (orange)
- Pro Zeile: Name + Weight-Preview + 3 Buttons (primary borderedProminent, secondary bordered)
- Max 3 Zeilen, bei >3: "+N weitere Vorschläge…"
- Wenn `previousWeight == nil`: "Zurück"-Button disabled

### SummaryViewModel-Erweiterung

```swift
struct RollbackSuggestion: Identifiable {
    let id: PersistentIdentifier
    let state: ExerciseProgressionState
    let exerciseName: String
    let currentWeight: Double
    let previousWeight: Double?
    let reasoning: String
}

private(set) var rollbackSuggestions: [RollbackSuggestion] = []
```

Neue Methode `recalculateRollbackSuggestions(states:strengthSessions:)`:
- Für jeden aktiven State: die 2 neuesten Sessions mit Sets dieses `groupKey` holen
- Cooldown: wenn `lastRollbackDate` gesetzt, nur zeigen wenn neueste Session-Date > lastRollbackDate
- `RollbackDetectionCalcEngine.detect(...)` aufrufen
- Bei `shouldSuggestRollback`: Suggestion anfügen
- Array auf max 3 Einträge truncaten

Aufruf in `recalculate(...)` nach `ratingInsights`.

### StrengthDetailView Manual-Button

Im Exercise-Block-Header (neben Edit-Icon):
```swift
if let groupKey = sets.first?.groupKey,
   let state = progressionState(for: groupKey),
   state.previousWorkingWeight != nil {
    Button { rollbackCandidate = state } label: {
        Image(systemName: "arrow.uturn.backward.circle")
            .font(.title3)
            .foregroundStyle(.orange)
    }
}
```

ConfirmationDialog:
- Message: "Aktuell: X kg → Rollback auf Y kg"
- Destructive: "Zurück auf Y kg"
- Cancel: "Abbrechen"

### Logik: Wann zeigen / unterdrücken

**Zeigen:** `state.isActive` + ≥2 Sessions mit groupKey + Engine `shouldSuggestRollback` + (`lastRollbackDate == nil` ODER neueste Session-Date > `lastRollbackDate`)

**Unterdrücken:**
- "Zurück": `lastRollbackDate = now` → Cooldown
- "Weiter versuchen": `lastRollbackDate = now` (Dismiss-Cooldown, doppelt belegt)
- "Advanced": `progressionMode = .advanced` → Engine liefert `.noProgression`
- `consecutiveFailCount = 0` (in Phase 1 wird Counter nie > 0 gesetzt → reiner Anti-Spam via Cooldown)

### Manuelle Tests

1. Leerer State → keine Karte
2. Ein Kandidat → 1 Zeile mit 3 Buttons
3. "Zurück" Tap → workingWeight=previousWorkingWeight, lastRollbackDate=now, lastProgressionDate=nil, Karte weg
4. "Weiter versuchen" → Cooldown aktiv, Karte weg, kommt nach neuer schlechter Session zurück
5. "Ich trage selbst ein" → `progressionMode = .advanced`, Karte weg permanent
6. `previousWorkingWeight == nil` → "Zurück"-Button disabled
7. StrengthDetail Manual-Button: Tap → Dialog → Bestätigung → workingWeight aktualisiert
8. >3 Kandidaten → 3 + "+N weitere"
9. Preview iPhone 15 + SE: kein Button-Overflow

### Build-Check

- [ ] iOS Build grün
- [ ] watchOS Build grün
- [ ] Keine neuen Warnings
- [ ] Previews rendern

### Risks

1. **Performance Recalc:** bei großer Session-Historie O(N×M) — akzeptabel für <50 States, <500 Sessions
2. **`lastRollbackDate` doppelbelegt** (Rollback ausgeführt vs. Dismiss) — vertretbar im MVP
3. **`consecutiveFailCount`-Increment** fehlt in Phase 1 → Anti-Spam läuft über Cooldown, nicht über Counter

### Offene Produktfragen

1. **`lastRollbackDate` als Dismiss-Marker doppelbelegen?** → Vorschlag: **ja**, MVP einfacher
2. **Max-Anzeige: 3 + "+N weitere" vs. scrollbare Liste?** → Vorschlag: **3 + Hinweis**
3. **`previousWorkingWeight == nil` in Summary-Karte:** Button disabled oder Zeile verstecken? → Vorschlag: **verstecken** (konsistent zu StrengthDetail)
4. **`applyRollback` soll `lastProgressionDate` nullen?** → Vorschlag: **ja** (verhindert Re-Detection)

🛑 **STOPP 1.20** — Warte auf Entscheidungen zu den 4 Produktfragen + Freigabe.

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
- **2026-04-18** — Schritt 1.18 committed (0564bd4). Plan 1.19 erstellt.
- **2026-04-18** — Schritt 1.19 committed (17076be). Plan 1.20 erstellt.
- **2026-04-18** — Schritt 1.19 implementiert. ExerciseQuickConfigSheet (141 Zeilen, neu) + 4 neue FormSections in FormViewSection.swift (1414 Zeilen) + Smart-Progression-Sub-Block in ExerciseFormView.swift (218 Zeilen) + ⚙️-Button in ActiveSetCard.swift (276 Zeilen) + @State/Callback/Sheet-Hook in ActiveWorkoutView.swift (2236 Zeilen).
- **2026-04-18** — Schritt 1.16 implementiert. Resolver + SmartFillViewModel + ExerciseSet.isEngineSuggestion + ActiveWorkoutView-Hooks + ActiveSetCard-Badge/Reasoning-Label.
- **2026-04-18** — Schritt 1.16 Scope-Korrektur: Produktfragen 2A + 3A (Reasoning-Label entfernt, ExerciseSet.isEngineSuggestion entfernt, Tracking zurück auf In-Memory Dictionary im ViewModel).
- **2026-04-18** — Schritt 1.17 implementiert (FineTuneChipsView + SetEditSheet-Einbau).
- **2026-04-18** — Schritt 1.18 implementiert. RIRInputSheet + CompactRestTimerView + ActiveWorkoutView-Hooks + Cleanup-Helper.
- **2026-04-18** — Schritt 1.20 implementiert. ProgressionRollbackService + RollbackInsightCard + SummaryView/SummaryViewModel-Integration + StrengthDetailView Manual-Button.
- **2026-04-18** — Schritt 1.21 implementiert. SessionQualityCalcEngine.swift (neu, 108 Z), ActiveWorkoutView.swift (Engine-Aufruf nach session.complete()), StrengthDetailView.swift (Statline "Session-Qualität: X/100" in statisticsCard nach Bewertungs-Block).
