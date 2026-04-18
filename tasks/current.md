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
- [ ] **1.11** Exercise-Felder entfernen + SetConfigSheet-UI + ProgressionTypes.swift löschen *(implementiert, warte auf Build-Check)*
- [ ] 1.12 Studio-Setup + Default-Seeder *(geplant nach Freigabe)*
- [ ] 1.13 Medikamenten-Schalter in Settings *(geplant nach Freigabe)*
- [ ] 1.14 Neue `ProgressionCalcEngine` *(geplant nach Freigabe)*
- [ ] 1.15 `RollbackDetectionCalcEngine` *(geplant nach Freigabe)*
- [ ] 1.16 Smart-Fill im ActiveWorkoutView *(geplant nach Freigabe)*
- [ ] 1.17 Feintuning-Button für Zwischengewichte *(geplant nach Freigabe)*
- [ ] 1.18 RIR-Sheet am letzten Satz *(geplant nach Freigabe)*
- [ ] 1.19 Quick-Config aus ActiveWorkout *(geplant nach Freigabe)*
- [ ] 1.20 Rollback-Insight-Karte + manueller Rollback *(geplant nach Freigabe)*
- [ ] 1.21 `SessionQualityCalcEngine` + Integration *(geplant nach Freigabe)*
- [ ] 1.22 Supabase-Schema-Erweiterung *(geplant nach Freigabe)*

---

## Aktueller Schritt: 1.11 — Exercise-Felder entfernen + SetConfigSheet + ProgressionTypes.swift löschen

### Ziel

Letzter Legacy-Entfernungs-Schritt: 4 Stored Properties + 4 Computed Properties aus `Exercise.swift` entfernen, zugehörige UI-Section `ExerciseProgressionSection` aus `FormViewSection.swift` löschen, alle Bindings/States in `SetConfigurationSheet.swift` und `ExerciseFormView.swift` bereinigen, abschließend `ProgressionTypes.swift` löschen. Damit ist das gesamte Legacy-Progression-System entfernt.

### Files

**ÄNDERN (4):**
- `MotionCore/Models/Core/Exercise.swift` — 4 Stored + 4 Computed Properties + Init-Params raus
- `MotionCore/Views/Training/Plans/Components/SetConfigurationSheet.swift` — 9 Stellen bereinigen
- `MotionCore/Components/Forms/FormViewSection.swift` — `ExerciseProgressionSection` komplett löschen (Zeilen 1248–1503)
- `MotionCore/Views/Training/Exercises/View/ExerciseFormView.swift` — 11-Zeilen-Block (Zeilen 114–124) löschen

**LÖSCHEN (1):**
- `MotionCore/Models/Types/ProgressionTypes.swift`

**NICHT anfassen:**
- `BundledExerciseSeeder.swift:327` — Kommentar nennt nur behaltene Felder. Keine Änderung nötig.
- `Export.swift` + `SupabaseFullBackupService.swift` — 0 Treffer, keine Änderung.
- `MotionCoreApp.swift` — klassisches `Schema([...])`, kein `VersionedSchema`, kein Migrations-Code nötig.

### Abweichungen vom 1.7-Report (bestätigt)

- `ExerciseFormView` ist nach 1.9/1.10 deutlich schlanker. Report-Zeilen `38–42, 147–149, 196, 216, 221` wurden bereits bereinigt. Jetzt nur noch ein 11-Zeilen-Block (114–124).
- `BundledExerciseSeeder`: Report-Annahme "Kommentar aktualisieren" trifft nicht zu — Kommentar nennt nur behaltene Felder.
- `Export.swift` + `SupabaseFullBackupService.swift`: Report-Annahme bestätigt, keine Änderung.

### Detail-Steps (Empfohlene Reihenfolge: D → C → B → A → E)

#### 1.11.D — `ExerciseFormView.swift`

Zeilen 114–124 (11 Zeilen) entfernen:
```swift
// MARK: Progression
if exercise.category != .bodyweight {
    ExerciseProgressionSection(
        strategy: $exercise.progressionStrategy,
        targetRIR: $exercise.targetRIR,
        sessionsRequired: $exercise.progressionSessionsRequired,
        minDaysBetween: $exercise.minDaysBetweenProgressions,
        customStep: $exercise.customProgressionStep,
        baseStep: exercise.baseProgressionStep
    )
}
```

Hinweis: `$exercise.targetRIR` verschwindet aus Form-View. Wert bleibt via Default `2` für neue Exercises; Setzen pro Set weiterhin in `SetConfigurationSheet`.

#### 1.11.C — `SetConfigurationSheet.swift` (9 Stellen)

1. Init A Body (Zeilen 64–68): 4 `_exercise...`-State-Init + Kommentar entfernen
2. State-Declarations (Zeilen 118–122): 4 `@State`-Variablen + Kommentar entfernen
3. Section-Aufruf (Zeilen 466–479): If-Else-Block vereinfachen auf nur `SetTargetRIRSection(targetRIR: $targetRIR)` für alle Übungen
4. Save-Zuweisungen (Zeilen 639–643): 4 Zuweisungen entfernen, **`ex.targetRIR = targetRIR` BLEIBT**

#### 1.11.B — `FormViewSection.swift`

Zeilen 1248–1503 komplett löschen: `// MARK: - Exercise Progression Section` + `struct ExerciseProgressionSection: View { ... }` + private Helpers (`formatStep`, `rirLabel`, `rirColor`, `rirColorFor`).

#### 1.11.A — `Exercise.swift`

**Stored Properties raus** (Zeilen 31–34):
- `progressionSessionsRequired`, `progressionStrategyRaw`, `customProgressionStep`, `minDaysBetweenProgressions`

**Primary-Init Params raus** (Zeilen 103–106) + Init-Body-Zuweisungen (Zeilen 142–145)

**Computed Properties raus** (in `extension Exercise`):
- `progressionStrategy` (Zeilen 283–288 inkl. MARK)
- `baseProgressionStep` (Zeilen 298–306)
- `effectiveProgressionStep` (Zeilen 308–311)
- `canRecommendProgression` (Zeilen 313–318)

**BEHALTEN:** `progressionStep`, `targetRIR`, `lastProgressionDate`, `repRangeMin/Max`, Smart-Progression-Felder aus 1.3.

Convenience-Inits (Zeilen 354 + 413) bleiben — delegieren an Primary-Init, Defaults greifen automatisch.

#### 1.11.E — `ProgressionTypes.swift` löschen

```bash
git rm MotionCore/Models/Types/ProgressionTypes.swift
```

Nach A–D sind alle darin definierten Typen (`ProgressionStrategy`, `ProgressionConfidence`, `TrainingLevel`, `PerformanceTrend`, `ProgressionAction`, `ProgressionAnalysis`, `SessionSnapshot`) nicht mehr referenziert.

### Manuelle Tests

1. App starten — kein Migrations-Fehler. Bestehende Exercises öffnen.
2. ExerciseFormView (Add + Edit) — Progression-Sektion fehlt, andere Sektionen vollständig. Speichern funktioniert.
3. SetConfigurationSheet (Plan → Übung) — nur RIR-Picker sichtbar. Speichern, Sätze werden erzeugt, `targetRIR` auf Sets + `ex.targetRIR` geschrieben.
4. Bestehendes Training starten — läuft normal.
5. Summary / StrengthDetails / Heatmap — rendern unverändert.

### Build-Check

- [ ] iOS build green
- [ ] watchOS build green (Kontrolle)
- [ ] Keine neuen Warnings
- [ ] App launcht, kein Migrations-Crash
- [ ] Bestehende Exercises/Sessions öffnen ohne Crash

### Risks

- **Lightweight Migration:** 4 Feld-Entfernungen auf aktivem CloudKit-Schema. SwiftData/CloudKit ignoriert entfernte Properties — bestehende Daten bleiben (die 4 Werte gehen verloren, unkritisch).
- **UX-Schrumpfung:** SetConfigSheet verliert 4 Einstellungs-Felder. Gewollt (Concept 3.2) — Ersatz kommt in 1.19 (Quick-Config).
- **ExerciseFormView verliert `targetRIR`-Binding.** Wert bleibt per Default 2; wird pro Set gesetzt.
- **`ProgressionStrategy`-Strings in CloudKit:** Werden beim nächsten Sync ignoriert. Kein Risiko.

🛑 **STOPP 1.11** — Warte auf Freigabe für Developer-Start.

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
- **2026-04-18** — Schritt 1.10 implementiert. 3 Legacy-Files gelöscht, SummaryViewModel bereinigt.
- **2026-04-18** — Schritt 1.11 implementiert. 4 Stored Properties (progressionSessionsRequired, progressionStrategyRaw, customProgressionStep, minDaysBetweenProgressions) + 4 Computed Properties (progressionStrategy, baseProgressionStep, effectiveProgressionStep, canRecommendProgression) aus Exercise.swift entfernt. ExerciseProgressionSection (256 Zeilen) aus FormViewSection.swift gelöscht. 9 Stellen in SetConfigurationSheet.swift bereinigt (4 State-Inits, 4 @State-Declarations, If-Else-Block vereinfacht, 4 Save-Zuweisungen entfernt). 11-Zeilen-Block aus ExerciseFormView.swift entfernt. ProgressionTypes.swift per git rm gelöscht. Finale Grepping: alle Legacy-Typen 0 Treffer.
