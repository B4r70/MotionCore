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
- [x] **1.16** Smart-Fill im ActiveWorkoutView *(implementiert 2026-04-18)*
- [x] **1.17** Feintuning-Chips für Zwischengewichte *(implementiert 2026-04-18)*
- [ ] 1.18 RIR-Sheet am letzten Satz *(geplant nach Freigabe)*
- [ ] 1.18 RIR-Sheet am letzten Satz *(geplant nach Freigabe)*
- [ ] 1.19 Quick-Config aus ActiveWorkout *(geplant nach Freigabe)*
- [ ] 1.20 Rollback-Insight-Karte + manueller Rollback *(geplant nach Freigabe)*
- [ ] 1.21 `SessionQualityCalcEngine` + Integration *(geplant nach Freigabe)*
- [ ] 1.22 Supabase-Schema-Erweiterung *(geplant nach Freigabe)*

---

## Aktueller Schritt: 1.16 — Smart-Fill im ActiveWorkoutView

### Ziel

Beim Öffnen einer Übung im aktiven Training werden die noch offenen Work-Sets mit Engine-Empfehlungen (Gewicht + Reps) vorbefüllt. Lazy-Erstellung von `ExerciseProgressionState` beim ersten abgeschlossenen Work-Set einer Übung. Erster UI-Konsument von `ProgressionCalcEngine` + `EquipmentWeightRounding`.

### Kritische Erkenntnis

`ActiveSetCard` zeigt Gewicht/Reps als **read-only Text**, nicht als TextField. Editing läuft über `SetEditSheet`. "Placeholder" bedeutet hier: Prefill **schreibt** direkt auf `set.weight`/`set.reps` der uncompleted Work-Sets — solange noch nicht vom User überschrieben (Heuristik).

### Files

**NEU (2):**
- `MotionCore/Services/Calculation/ExerciseProgressionStateResolver.swift` — `fetch` + `createIfMissing` für `ExerciseProgressionState` per `exerciseGroupKey`
- `MotionCore/Views/Workouts/Active/ViewModel/ActiveWorkoutSmartFillViewModel.swift` — `@Observable`, Engine-Aufruf, Cache, Prefill, Lazy-State-Trigger

**ÄNDERN (1):**
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — minimalinvasiv ~30 Zeilen:
  - `@Query var studioEquipments: [StudioEquipment]`
  - `@State var smartFill: ActiveWorkoutSmartFillViewModel?`
  - Hook in `setupSession()` (ViewModel init + erster Prefill)
  - Hook in `.onChange(of: selectedExerciseKey)` (Prefill bei Übungswechsel)
  - Hook in `completeSet(_:)` (recordSetCompletion + Re-Prefill)
  - Hook in `.onChange(of: selectedSetForEdit)` (markUserConfirmed)

### Architektur-Entscheidungen

1. **ViewModel statt View:** Engine-Aufruf + FetchDescriptor gehören NICHT in View (CLAUDE.md). Neue `@Observable` ViewModel-Klasse.
2. **Kein Split von ActiveWorkoutView in 1.16:** Datei ist bei ~1806 Zeilen, 1.16 fügt ~30 Zeilen hinzu, verschlimmert nichts. Split zwangsläufig in 1.18/1.19 — dort ganzheitlich.
3. **Cache:** `[exerciseGroupKey: Output]` im ViewModel. Invalidierung bei `completeSet` → nächster Prefill aktiviert "folge-vorherigem-Satz"-Pfad der Engine.
4. **Lazy-State-Creation:** Triggerpunkt `completeSet`, NICHT `openExercise` (Concept 3.4: "lazy beim ersten Set-Abschluss, `workingWeight = aktuelles Set-Gewicht`").
5. **Rollback-Placeholder in 1.16:** Engine liefert bereits `previousWorkingWeight` bei `.rollbackSuggested`. Prefill schreibt transparent — keine UI-Karte (kommt 1.20).

### Detail-Steps

#### 1.16.1 — `ExerciseProgressionStateResolver.swift`

```swift
enum ExerciseProgressionStateResolver {
    static func fetch(in context: ModelContext, exerciseGroupKey: String) -> ExerciseProgressionState?
    static func createIfMissing(in context: ModelContext, exerciseGroupKey: String, workingWeight: Double, exercise: Exercise) -> ExerciseProgressionState
}
```
- `fetch`: `FetchDescriptor<ExerciseProgressionState>` mit `#Predicate { $0.exerciseGroupKey == key }`, `fetchLimit: 1`
- `createIfMissing`: Falls nil → neuer State mit `workingWeight`, `targetReps = exercise.customTargetReps ?? max(1, (repRangeMin + repRangeMax) / 2)` (Fallback 10 wenn beide 0), `minTargetReps = repRangeMin > 0 ? repRangeMin : 8`, `maxTargetReps = repRangeMax > 0 ? repRangeMax : 12`, `progressionModeRaw = exercise.progressionModeRaw`. `context.insert + save()`.

#### 1.16.2 — `ActiveWorkoutSmartFillViewModel.swift`

```swift
@MainActor @Observable
final class ActiveWorkoutSmartFillViewModel {
    private(set) var cachedOutputs: [String: ProgressionCalcEngine.Output] = [:]
    private(set) var isSuggestionActive: [String: Bool] = [:]  // Key: setUUID.uuidString
    private let context: ModelContext

    init(context: ModelContext)

    func prefillSuggestion(exerciseGroupKey: String, exercise: Exercise?, session: StrengthSession,
                          lastCompletedSession: StrengthSession?, equipmentByID: [UUID: StudioEquipment])

    func recordSetCompletion(completedSet: ExerciseSet, exercise: Exercise?)

    func isSuggestion(for set: ExerciseSet) -> Bool

    func markUserConfirmed(set: ExerciseSet)
}
```

**`prefillSuggestion`:** idempotent (guard auf cache), resolve progressionState via Resolver.fetch → falls nil: keine Suggestion (Edge Case "neue Übung"). Engine.Input aufbauen mit `readinessModifier = 1.0`, `exerciseFallbackStep = exercise.progressionStep`, `currentSessionPreviousSets` gefiltert auf groupKey. Engine call. Output cachen. Prefill-Durchlauf: uncompleted Work-Sets mit `set.weight == 0 && set.reps <= 1` oder `isSuggestionActive[setUUID] == true` → `set.weight = output.suggestedWeight`, `set.reps = output.suggestedReps`, Flag true setzen.

**`recordSetCompletion`:** Cache-Entry für groupKey löschen, `isSuggestionActive[setUUID] = false`, Lazy-State-Creation via `Resolver.createIfMissing(workingWeight: completedSet.weight, exercise: exercise)`.

**`markUserConfirmed`:** Flag `isSuggestionActive[setUUID] = false`.

#### 1.16.3 — `ActiveWorkoutView.swift` — Änderungen

- `@Query var studioEquipments: [StudioEquipment]` (bei bestehenden Query-Deklarationen ~Zeile 27)
- `@State var smartFill: ActiveWorkoutSmartFillViewModel?` (bei anderen `@State` ~Zeile 76)
- Helper: `equipmentByID`, `lastCompletedSession(for:)`, `resolveExercise(for:)`, `prefillSmartSuggestionsIfNeeded()`
- In `setupSession()`: `if smartFill == nil { smartFill = ActiveWorkoutSmartFillViewModel(context: context) }` + `prefillSmartSuggestionsIfNeeded()`
- `.onChange(of: selectedExerciseKey)` → `prefillSmartSuggestionsIfNeeded()`
- In `completeSet(_:)` (vor PR-Check): `smartFill?.recordSetCompletion(completedSet: set, exercise: resolveExercise(for: set.groupKey))` + `prefillSmartSuggestionsIfNeeded()`
- `.onChange(of: selectedSetForEdit)` → `if let newSet { smartFill?.markUserConfirmed(set: newSet) }`

### Lazy-State-Creation-Pattern

| Zeitpunkt | Aktion |
|---|---|
| Öffnen (neue Übung) | `fetch` → nil → kein State, keine Suggestion |
| Satz 1 completed | `createIfMissing` → State mit `workingWeight = set1.weight` |
| Öffnen Satz 2 (gleiche Session) | Engine Pfad 1 (`currentSessionSetIndex > 0`) → Prefill mit `set1.weight` |
| Nächste Session | Engine normaler Entscheidungsbaum mit `lastSessionSets` |

**Wichtig:** `workingWeight` wird in 1.16 nur **erstellt**, nicht aktualisiert. Updates bei Progression → 1.20/1.21.

### Placeholder-Semantik

- Prefill überschreibt nur bei `set.weight == 0 && set.reps <= 1` ODER `isSuggestionActive[setUUID] == true` (zuvor eigene Suggestion)
- User-Overrides via SetEditSheet → `markUserConfirmed` → Flag false → nächster Prefill respektiert
- Keine sichtbare UI-Änderung in 1.16 an `ActiveSetCard` (nur Datenbefüllung)
- Flicker-Prävention: synchroner Prefill vor nächstem Render, keine async State-Changes

### Manuelle Tests

1. **Neue Übung ohne Historie:** 0kg-Template → keine Befüllung, User trägt ein. Satz abschließen → State angelegt.
2. **Übung mit Progression-Kandidat:** vorige Session alle Reps erreicht + rpe=9 → Prefill `+increment` Gewicht, Reasoning `.increaseWeight`.
3. **Satz 1 → Satz 2:** Satz 1 60kg completed → Cache invalidiert → Satz 2 zeigt 60kg (Pfad 1, `.holdWeight`).
4. **User-Override:** Vorschlag 60kg → Anpassen → 62.5kg → bleibt erhalten.
5. **Rollback-Szenario:** vorige Session reps<min, lastProgDate=5d → Prefill `previousWorkingWeight`.
6. **Kein Equipment:** `studioEquipmentID = nil` → Fallback auf `progressionStep`.
7. **Equipment (7kg Beinpresse):** 70kg + increase → 77kg.
8. **Übung-Wechsel:** A→B→A, Cache-Hit, keine Re-Writes.

### Build-Check

- [ ] iOS Build grün
- [ ] watchOS Build grün (Kontrolle)
- [ ] Keine neuen Warnings
- [ ] Training aus Plan starten, Übungen durchspielen

### Risks

- **File-Size ActiveWorkoutView (1806 Zeilen):** 1.16 fügt ~30 Zeilen hinzu, Split verschoben auf 1.18/1.19
- **Template-Default-Heuristik:** `weight == 0 && reps <= 1` — bei bewussten 0kg-Bodyweight-Templates harmlos (Engine liefert auch 0)
- **`isSuggestionActive`-Non-Persistence** nach App-Kill: nächster Prefill würde erneut befüllen, aber Heuristik schützt User-Werte
- **SwiftData `@Query<StudioEquipment>` in View:** muss mit leerem Studio-Context klarkommen (fresh install ohne Seed)
- **Race Prefill vs. save():** Prefill schreibt Model synchron, save() async — in RAM sofort sichtbar, kein Problem

### Offene Produktfragen

1. **Visuelles "Vorschlag"-Badge** auf ActiveSetCard (solange Suggestion aktiv)? → Vorschlag: **NEIN in 1.16** (nur Datenbefüllung), als Follow-up falls UX es fordert.
2. **Reasoning als secondary Label** (z.B. "Steigerung empfohlen", "Rollback empfohlen")? → Vorschlag: **NEIN in 1.16** — Rollback-Karte kommt prominent in 1.20.
3. **Prefill bei Session-Resume nach App-Kill:** Heuristik ausreichend oder `isSuggestionActive` persistieren? → Vorschlag: **Heuristik ausreichend** (User-Werte sind `weight>0 || reps>1` und werden nicht überschrieben).

🛑 **STOPP 1.16** — Warte auf Freigabe + Entscheidungen zu den 3 Produktfragen.

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
- **2026-04-18** — Schritt 1.16 implementiert. Resolver + SmartFillViewModel + ExerciseSet.isEngineSuggestion + ActiveWorkoutView-Hooks + ActiveSetCard-Badge/Reasoning-Label.
- **2026-04-18** — Schritt 1.16 Scope-Korrektur: Produktfragen 2A + 3A (Reasoning-Label entfernt, ExerciseSet.isEngineSuggestion entfernt, Tracking zurück auf In-Memory Dictionary im ViewModel).
- **2026-04-18** — Schritt 1.17 implementiert (FineTuneChipsView + SetEditSheet-Einbau).
