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
- [ ] **1.3** Additive Model-Erweiterungen (Exercise + ExerciseSet + Readiness-Models + StrengthSession) *(aktuell in Planung — bündelt Instruction-Schritte 1.3+1.4+1.5+1.6; siehe Detail-Plan unten)*
- [ ] 1.7 Cross-Reference-Check vor Legacy-Entfernung *(geplant nach Freigabe)*
- [ ] 1.8 TrendPoint-Extraktion (bedingt) *(geplant nach Freigabe)*
- [ ] 1.9 Legacy-UI-Entfernung (Views) *(geplant nach Freigabe)*
- [ ] 1.10 Legacy-CalcEngines + ViewModel entfernen *(geplant nach Freigabe)*
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

## Aktueller Schritt: 1.3 — Additive Model-Erweiterungen (gebündelt 1.3+1.4+1.5+1.6)

### Ziel

Alle additiven Model-Änderungen aus den Instruction-Schritten 1.3 + 1.4 + 1.5 + 1.6 in einem einzigen Commit: neue Felder auf `Exercise`, `ExerciseSet`, `StrengthSession`, zwei neue SwiftData-Models (`SessionReadiness`, `HealthBaseline`) + Enum `HealthMetricType`, Schema-Registrierung. Keine UI, keine CalcEngine, keine Seeder. Rein additiv — alte Legacy-Felder auf Exercise bleiben bis Schritt 1.11 unverändert.

### Files (erwartet)

- **NEU:** `MotionCore/Models/Core/HealthMetricType.swift`
- **NEU:** `MotionCore/Models/Core/HealthBaseline.swift`
- **NEU:** `MotionCore/Models/Core/SessionReadiness.swift`
- **ÄNDERN:** `MotionCore/Models/Core/Exercise.swift` — 4 neue stored Properties + 1 computed + Init-Erweiterung
- **ÄNDERN:** `MotionCore/Models/Core/ExerciseSet.swift` — 1 neues stored Property + Init + Clone-Anpassung
- **ÄNDERN:** `MotionCore/Models/Core/StrengthSession.swift` — 2 neue stored Properties + Init-Erweiterung
- **ÄNDERN:** `MotionCore/App/MotionCoreApp.swift` — `SessionReadiness.self`, `HealthBaseline.self` ins Schema

### Cross-References (Vorab-Checks durchgeführt)

**Naming-Konflikte — alle frei:**
- `SessionReadiness`, `HealthBaseline`, `HealthMetricType`, `isLastSetOfExercise`: 0 Treffer in `MotionCore/`
- `Exercise.progressionMode` (neu): kein Typ-Konflikt — `progressionMode` existiert bereits als computed auf `ExerciseProgressionState`, unterschiedlicher Receiver, kein Shadowing. Namespace `ProgressionMode` (Enum aus 1.2) identisch — gewollt.
- Bestehende `HealthMetric*`-Files (`HealthMetricView`, `HealthMetricCalcEngine`, `HealthMetricCard` etc.) deklarieren kein `HealthMetricType` oder `HealthMetric`-Enum — keine Kollision.

**Init-Call-Site-Analyse:**
- `Exercise(...)` in 22 Files: neue Parameter mit Defaults → keine Call-Site bricht. Convenience-Inits delegieren an Primary-Init.
- `ExerciseSet(...)` in 11 Files inkl. `cloneForSession` / `cloneForPlanEditing`: neuer Param mit Default `false` → alle Call-Sites grün. Clone-Methoden werden angepasst, Flag wird **nicht** kopiert.
- `StrengthSession(...)` in 7 Files: neue Params optional mit `nil`-Default.

### Detail-Steps

#### 1.3a — Exercise-Erweiterung (`Exercise.swift`)

1. Nach bestehendem Progressions-Konfig-MARK-Block neue MARK-Sektion `// MARK: - Smart-Progression (v1.1)` mit folgenden stored Properties:
   - `var studioEquipmentID: UUID? = nil` — "Soft-Link auf StudioEquipment.id (keine @Relationship)"
   - `var customTargetReps: Int? = nil` — "Überschreibt repRangeMin/Max als expliziter Ziel-Wert"
   - `var progressionModeRaw: String = "smart"` — "Rohwert für CloudKit-Kompatibilität"
   - `var configNotes: String = ""` — "Freitext-Notiz, z.B. Geräte-spezifische Einstellung"
2. Im Primary-`init` neue Parameter mit Defaults ergänzen (nach `lastProgressionDate`, vor `sortIndex`):
   - `studioEquipmentID: UUID? = nil`, `customTargetReps: Int? = nil`, `progressionModeRaw: String = "smart"`, `configNotes: String = ""`
   - Entsprechende Zuweisungen im Init-Body.
3. Im computed-Extension-Block (nach `progressionStrategy`) neue Sektion `// MARK: - Smart-Progression (v1.1)` + computed:
   ```swift
   var progressionMode: ProgressionMode {
       get { ProgressionMode(rawValue: progressionModeRaw) ?? .smart }
       set { progressionModeRaw = newValue.rawValue }
   }
   ```
4. **NICHT anfassen:** `progressionStrategyRaw`, `customProgressionStep`, `progressionSessionsRequired`, `minDaysBetweenProgressions`, `lastProgressionDate`, `effectiveProgressionStep`, `baseProgressionStep`, `canRecommendProgression`, Convenience-Inits.

#### 1.3b — ExerciseSet-Erweiterung (`ExerciseSet.swift`)

1. Nach `setKind`-Block (vor `// MARK: - Beziehungen`) neue Sektion `// MARK: - Smart-Progression (v1.1)` + Property:
   - `var isLastSetOfExercise: Bool = false` — "True = letzter Work-Set der Übung in dieser Session → triggert RIR-Sheet (Schritt 1.18)"
2. Im Primary-`init` neuer Param `isLastSetOfExercise: Bool = false` am Ende (nach `supersetGroupId`), Body entsprechend erweitern.
3. **`cloneForSession()`:** Param **NICHT** durchreichen — Default `false` greift. Kommentar: "`isLastSetOfExercise` wird nicht kopiert — neuer Session-Satz ist zunächst nie der letzte".
4. **`cloneForPlanEditing()`:** dito — Default `false`.
5. **`convenience init(from exercise:)`:** nicht anpassen — Default greift.
6. **NICHT anfassen:** `rpe`, `calculatedRIR`, `setKind`-Handling, Snapshots.

#### 1.3c — Neue Readiness-Modelle

**`HealthMetricType.swift`:**
- Header-Template analog `ProgressionMode.swift`, Beschreibung: "Metrik-Typen für HealthBaseline (HRV, Schlaf, Ruhepuls, Aktivität)"
- Nur `import Foundation`
- ```swift
  enum HealthMetricType: String, Codable, CaseIterable {
      case hrv
      case sleep
      case restingHR
      case activity
  }
  ```

**`HealthBaseline.swift`:**
- Header analog `ExerciseProgressionState.swift`, Beschreibung: "Rollende Baseline (Mean/StdDev) pro Health-Metrik — Phase 2 befüllt"
- `import Foundation`, `import SwiftData`
- `@Model final class HealthBaseline` gemäß Concept 3.1.5: `id`, `metricTypeRaw`, `rollingMean`, `rollingStdDev`, `sampleCount`, `lastUpdated` — alle defaulted
- Computed `metricType: HealthMetricType` (get/set, Fallback `.hrv`)
- Init: `init(metricType: HealthMetricType = .hrv) { self.metricTypeRaw = metricType.rawValue }`
- MARK: Identifikation / Metrik-Typ / Rolling-Statistik / Metadaten / Typisierter Accessor / Initialisierung
- **Keine `@Relationship`** — standalone

**`SessionReadiness.swift`:**
- Header analog, Beschreibung: "Readiness-Snapshot pro Session — Phase 2 befüllt, in Phase 1 ungenutzt"
- `@Model final class SessionReadiness` gemäß Concept 3.1.4: `id`, `sessionUUID: String?`, `capturedAt`, `hrvScore: Double?`, `sleepScore: Double?`, `restingHRScore: Double?`, `activityScore: Double?`, `userEnergyLevel: Int?`, `userStressLevelRaw: String?`, `overallScore: Int = 50`, `isCalibrating: Bool = false`
- Init: `init() {}` — Concept-konform leer
- MARK: Identifikation / Session-Referenz / Metrik-Scores / User-Input / Gesamt-Score / Initialisierung
- **Keine `@Relationship`** — Matching via `sessionUUID` String in Phase 2

#### 1.3d — StrengthSession-Erweiterung (`StrengthSession.swift`)

1. Nach Sektion "Subjektive Bewertung für ML" neue Sektion `// MARK: - Smart-Progression (v1.1)` + Properties:
   - `var sessionQualityScore: Int? = nil` — "0–100, berechnet durch SessionQualityCalcEngine (Schritt 1.21)"
   - `var sessionReadinessID: UUID? = nil` — "Soft-Link auf SessionReadiness.id (Phase 2)"
2. Im `init` neue Params am Ende vor `workoutType`: `sessionQualityScore: Int? = nil`, `sessionReadinessID: UUID? = nil`. Body erweitern.
3. **NICHT anfassen:** bestehende Relationships, `complete()`, `start()`, Helpers, Computed-Properties.

#### Schema-Registrierung (`MotionCoreApp.swift`)

- Im `appSchema`-Array nach `ExerciseProgressionState.self`:
  ```swift
  Studio.self,
  StudioEquipment.self,
  ExerciseProgressionState.self,
  SessionReadiness.self,
  HealthBaseline.self
  ```
- `HealthMetricType` **nicht** ins Schema (Enum).

### Manuelle Tests

1. App starten — kein Migrations-Crash, Home-Screen öffnet.
2. Bestehende Trainingsplan-Ansicht → keine Fehler.
3. Bestehende Session im Detail öffnen (`StrengthDetailView`) → alle Felder, keine Crashes.
4. Aktives Training starten + Satz eintragen + speichern → ok.
5. Satz-Template aus Plan klonen (Session starten) → `isLastSetOfExercise == false` auf allen Clones.
6. Plan-Satz-Edit-Sheet → ändern → zurück → keine Fehler (`cloneForPlanEditing` intakt).
7. Console: keine "Missing inverse"-Warnung (weder `SessionReadiness`, `HealthBaseline`, noch `studioEquipmentID`).
8. Console: keine "unknown type"-Warnung.
9. `ExerciseRating`-Flow unverändert funktional.
10. `ProgressionAnalyseView` (Legacy, entfernt erst 1.9) öffnet weiterhin ohne Crash.

### Build-Check

- [ ] iOS build green
- [ ] watchOS build green (nicht direkt betroffen, Kontrolle)
- [ ] No new warnings
- [ ] App launches, kein Migrations-Crash
- [ ] Bestehende Sessions/Pläne/Übungen/Studios intakt
- [ ] ActiveWorkoutView, StrengthDetailView, TrainingFormView, ExerciseFormView laden
- [ ] ProgressionAnalyseView (Legacy) lädt weiterhin

### Risks / Open Questions

1. **Größerer Revert-Scope als 1.1/1.2:** 6 geänderte/neue Files in einem Commit, 3 bestehende Models gleichzeitig berührt. Bei Migrations-Fehler: `git revert` des einen Commits als Exit.
2. **CloudKit-Propagation:** 4 neue Felder auf `Exercise`, 1 auf `ExerciseSet`, 2 auf `StrengthSession` — alle additiv, lightweight. Erster Sync auf Device kann länger dauern.
3. **Clone-Methoden-Subtle-Bug:** `isLastSetOfExercise` darf nicht durchgereicht werden — explizit im Plan markiert.
4. **Bestehende Exercises:** `progressionModeRaw = "smart"` als Default heißt, alle alten Übungen verhalten sich ab 1.14 wie Smart-Mode. Concept-konform, gewollt.
5. **`customTargetReps: Int?`** noch nicht verdrahtet — Feld existiert, Nutzung erst in 1.14/1.16.
6. **Typ-Inkonsistenz `sessionReadinessID: UUID?` ↔ `SessionReadiness.sessionUUID: String?`** folgt dem Concept. Konvertierung in Phase 2 via `UUID.uuidString`. Nicht in 1.3 korrigieren.
7. **File-Size:** `Exercise.swift` ~535, `ExerciseSet.swift` ~315, `StrengthSession.swift` ~310 — alle unter 600-Warnschwelle.

**Offene Fragen:** keine. Alle Details aus Concept 3.1.4/3.1.5/3.2.1–3.2.3 eindeutig.

🛑 **STOPP 1.3** — Nach erfolgreichem Build-Check und Barto-Sichtung warten auf Freigabe für Schritt 1.7 (Cross-Reference-Check).

---

## Fortschritt

- **2026-04-18** — Plan 1.1 erstellt.
- **2026-04-18** — Schritt 1.1 implementiert. Dateien: `StudioEquipmentType.swift` (neu), `Studio.swift` (neu), `StudioEquipment.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
- **2026-04-18** — Schritt 1.1 committed (5744842). Plan 1.2 erstellt.
- **2026-04-18** — Schritt 1.2 implementiert. Dateien: `ProgressionMode.swift` (neu), `ExerciseProgressionState.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
- **2026-04-18** — Schritt 1.2 committed (28ea5b2). Schritte 1.3+1.4+1.5+1.6 zu neuem Schritt 1.3 gebündelt. Plan erstellt.
- **2026-04-18** — Schritt 1.3 implementiert. Dateien: HealthMetricType.swift (neu), HealthBaseline.swift (neu), SessionReadiness.swift (neu), Exercise.swift (+4 Felder), ExerciseSet.swift (+1 Feld), StrengthSession.swift (+2 Felder), MotionCoreApp.swift (Schema +2).
