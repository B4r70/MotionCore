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
- [x] **1.10** Legacy-CalcEngines + ViewModel entfernen *(implementiert 2026-04-18)*
- [ ] 1.11 Exercise-Felder entfernen + SetConfigurationSheet-UI bereinigen *(geplant nach Freigabe)*
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

## Aktueller Schritt: 1.10 — Legacy-CalcEngines + ViewModel entfernen

### Ziel

3 veraltete Progression-Files löschen und `SummaryViewModel` bereinigen. Mit diesem Schritt ist das komplette Legacy-ViewModel/Engine-System entfernt. `ProgressionTypes.swift` bleibt bewusst bestehen — `ProgressionStrategy` wird in Exercise/SetConfigurationSheet/FormViewSection/ExerciseFormView noch aktiv genutzt und fällt erst in 1.11.

### Files

**Löschen (3):**
- `MotionCore/Services/Calculation/ProgressionCalcEngine.swift`
- `MotionCore/Services/Calculation/ProgressionAnalyseCalcEngine.swift`
- `MotionCore/Services/ViewModels/ProgressionViewModel.swift`

**Bereinigen (1):**
- `MotionCore/Services/ViewModels/SummaryViewModel.swift`

**NICHT anfassen:**
- `MotionCore/Models/Types/ProgressionTypes.swift` (erst 1.11)

### Cross-Reference-Grep (Vorab-Check)

- `ProgressionCalcEngine` extern: nur `SummaryViewModel.swift:98, 267`
- `ProgressionAnalyseCalcEngine` extern: 0
- `ProgressionViewModel` extern: 0
- `ProgressionAnalysis` extern: nur `SummaryViewModel.swift:29, 57` + Definition in `ProgressionTypes.swift:213`
- `ProgressionRecommendation` extern: 0 (wurde bereits in 1.9 aus ActiveWorkoutView entfernt)
- `progressionAnalyses`, `bestExerciseAnalysis`, `bestExerciseTrendPoints`, `recalculateBestExercise`: nur in `SummaryViewModel.swift` — 0 externe Leser
- `SessionSnapshot`, `ProgressionConfidence`, `TrainingLevel`, `PerformanceTrend`, `ProgressionAction`: nach 1.10 nur noch in `ProgressionTypes.swift` (dead code bis 1.11)

**Abweichung vom 1.7-Report:** keine.

### Detail-Steps

#### 1.10a — `SummaryViewModel.swift` bereinigen

- Zeile 29 löschen: `private(set) var progressionAnalyses: [ProgressionAnalysis] = []`
- Zeile 57 löschen: `private(set) var bestExerciseAnalysis: ProgressionAnalysis? = nil`
- Zeile 58 löschen: `private(set) var bestExerciseTrendPoints: [TrendPoint] = []`
- Zeilen 97–117 komplett entfernen (Progressions-Zweig in `recalculate(...)` inkl. `ProgressionCalcEngine()`-Instanziierung und Filter `progressionStrategy != .manual`)
- Zeile 155 löschen: Aufruf `recalculateBestExercise(strength:progressionEngine:)`
- Zeilen 260–293 komplett entfernen (`private func recalculateBestExercise(...)`)
- Post-Cleanup-Grep: `Progression` sollte 0 Treffer in der Datei haben. `TrendPoint` ebenfalls 0 (Typ bleibt im Projekt, nur Usage hier weg).

#### 1.10b — Legacy-Files löschen

```bash
git rm MotionCore/Services/Calculation/ProgressionCalcEngine.swift
git rm MotionCore/Services/Calculation/ProgressionAnalyseCalcEngine.swift
git rm MotionCore/Services/ViewModels/ProgressionViewModel.swift
```

Xcode 16 PBXFileSystemSynchronizedRootGroup — keine `project.pbxproj`-Anpassung nötig.

#### 1.10c — Post-Delete-Verifikation

Greps erwarten 0 Treffer (außer Type-Definitionen in `ProgressionTypes.swift`):
- `ProgressionCalcEngine`, `ProgressionAnalyseCalcEngine`, `ProgressionViewModel`: 0
- `ProgressionRecommendation`: 0
- `progressionAnalyses`, `bestExerciseAnalysis`, `bestExerciseTrendPoints`, `recalculateBestExercise`: 0
- `ProgressionAnalysis`: 1 Treffer (Definition in `ProgressionTypes.swift`)

### Manuelle Tests

1. App starten — kein Crash, kein Migrations-Fehler (reine Code-Löschung, kein Schema-Touch).
2. Summary-Tab öffnen — alle Karten rendern, keine Lücke durch fehlendes `bestExerciseAnalysis`.
3. Timeframe-Wechsel (Woche/Monat/Jahr/All) — `recalculateFiltered` unverändert.
4. StatsAndRecords: Statistiken + Rekorde + Heatmap funktional.
5. Active-Workout: Satz eintragen + speichern.
6. StrengthDetailView: lädt, keine Banner-Referenz.
7. ExerciseFormView: `ExerciseProgressionSection` noch sichtbar (bleibt bis 1.11).

### Build-Check

- [ ] iOS build green
- [ ] watchOS build green (Kontrolle)
- [ ] Keine neuen Warnings
- [ ] App launcht

### Risks

- **Build-Grün-Risiko niedrig.** Einzige externe Konsumenten (`SummaryViewModel`-Zweig) werden in 1.10a proaktiv bereinigt. Alle UI-Konsumenten wurden in 1.9 entfernt.
- **`ProgressionTypes.swift` wird dead code** — gewollt, Löschung in 1.11.
- **CloudKit / SwiftData:** keine Schema-Änderung.
- **Watch-Target:** unberührt.

🛑 **STOPP 1.10** — Warte auf Freigabe für Developer-Start.

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
- **2026-04-18** — Schritt 1.10 implementiert. 3 Legacy-Files gelöscht, SummaryViewModel bereinigt.
