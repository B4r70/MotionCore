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
- [ ] **1.2** Datenmodell: `ExerciseProgressionState` + `ProgressionMode` *(aktuell in Planung — siehe Detail-Plan unten)*
- [ ] 1.3 Exercise-Erweiterung (nur HINZUFÜGEN) *(geplant nach Freigabe)*
- [ ] 1.4 ExerciseSet-Erweiterung (`isLastSetOfExercise`) *(geplant nach Freigabe)*
- [ ] 1.5 Neue Datenmodelle: `SessionReadiness` & `HealthBaseline` *(geplant nach Freigabe)*
- [ ] 1.6 StrengthSession-Erweiterung *(geplant nach Freigabe)*
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

## Aktueller Schritt: 1.2 — Datenmodell: ExerciseProgressionState + ProgressionMode

### Ziel

Ein neues SwiftData-Modell `ExerciseProgressionState` sowie ein separates Enum `ProgressionMode` anlegen und im `ModelContainer`-Schema registrieren. Additiv, ohne UI, ohne Seeder, ohne Services. Keine Relationship zu `Exercise` — Matching erfolgt per `exerciseGroupKey` analog zu `ExerciseRating`.

### Files (erwartet)

- **NEU:** `MotionCore/Models/Core/ProgressionMode.swift`
- **NEU:** `MotionCore/Models/Core/ExerciseProgressionState.swift`
- **ÄNDERN:** `MotionCore/App/MotionCoreApp.swift` (Schema-Array erweitern um `ExerciseProgressionState.self`)

> Verzeichnis: `MotionCore/Models/Core/` (reale Struktur), konsistent mit Studio/StudioEquipment aus 1.1.

### Cross-References (für Löschungen)

Keine — rein additiver Schritt. Vorab-Checks:
- `ProgressionMode` in `MotionCore/`: null Treffer. Auch bestehendes `ProgressionCalcEngine.swift` definiert kein `ProgressionMode` — kein Konflikt.
- `ExerciseProgressionState` in `MotionCore/`: null Treffer.
- `exerciseGroupKey` als Match-Pattern validiert in `MotionCore/Models/Core/ExerciseRating.swift` (einfacher String-Match, keine Relationship zu Exercise).

### Detail-Steps

#### 1. `ProgressionMode.swift`

- Datei-Header gemäß Projekt-Standard (Template `ExerciseRating.swift`), Abschnitt "Daten-Modell", Beschreibung: "Progressions-Modus für ExerciseProgressionState".
- Nur `import Foundation`.
- Enum exakt nach Concept 3.1.3:
  ```swift
  enum ProgressionMode: String, Codable, CaseIterable {
      case smart
      case advanced
      case off
  }
  ```
- Fälle einzeln auf separaten Zeilen (Pattern konsistent mit `StudioEquipmentType.swift`).
- Separate Datei analog zum 1.1-Vorgehen bei `StudioEquipmentType`.

#### 2. `ExerciseProgressionState.swift`

- Datei-Header analog (Erstellt am: 18.04.2026, Beschreibung: "Progressions-State pro Übungsgruppe — Arbeitsgewicht, Ziel-Reps, Rollback-Historie").
- Header-Hinweis: "Match via exerciseGroupKey (wie ExerciseRating) — keine @Relationship zu Exercise, um Many-to-One-Zwang zu vermeiden".
- `import Foundation`, `import SwiftData`.
- `@Model final class ExerciseProgressionState` mit stored Properties exakt nach Concept 3.1.3 (Reihenfolge wie im Concept):
  - `var id: UUID = UUID()`
  - `var exerciseGroupKey: String = ""` — Kommentar: "Stabiler Schlüssel der Übungsgruppe (entspricht ExerciseSet.groupKey)"
  - `var workingWeight: Double = 0.0` — Kommentar: "Aktuelles Arbeitsgewicht, wird bei jeder Progression aktualisiert"
  - `var targetReps: Int = 10`
  - `var minTargetReps: Int = 8`
  - `var maxTargetReps: Int = 12`
  - `var progressionModeRaw: String = "smart"` — Kommentar: "Rohwert für CloudKit-Kompatibilität (String statt Enum)"
  - `var lastProgressionDate: Date?`
  - `var lastRollbackDate: Date?`
  - `var previousWorkingWeight: Double?` — Kommentar: "Für Rollback-Wiederherstellung gespeichertes vorheriges Arbeitsgewicht"
  - `var consecutiveSuccessCount: Int = 0`
  - `var consecutiveFailCount: Int = 0`
  - `var isActive: Bool = true`
  - `var createdAt: Date = Date()`
  - `var updatedAt: Date = Date()`
- **Keine `@Relationship`** — `exerciseGroupKey`-basiertes Matching.
- Typisiertes Enum-Accessor:
  ```swift
  var progressionMode: ProgressionMode {
      get { ProgressionMode(rawValue: progressionModeRaw) ?? .smart }
      set { progressionModeRaw = newValue.rawValue }
  }
  ```
- Init exakt nach Concept:
  ```swift
  init(exerciseGroupKey: String = "", workingWeight: Double = 0.0) {
      self.exerciseGroupKey = exerciseGroupKey
      self.workingWeight = workingWeight
  }
  ```
- MARK-Struktur analog `ExerciseRating.swift`:
  - `// MARK: - Identifikation`
  - `// MARK: - Übungs-Referenz`
  - `// MARK: - Arbeitsgewicht`
  - `// MARK: - Ziel-Reps`
  - `// MARK: - Progressions-Modus`
  - `// MARK: - Historie`
  - `// MARK: - Metadaten`
  - `// MARK: - Typisierter Modus (computed)`
  - `// MARK: - Initialisierung`

#### 3. `MotionCoreApp.swift` — Schema-Registrierung

- In `private static let appSchema = Schema([...])` `ExerciseProgressionState.self` ergänzen.
- Position: unmittelbar nach `StudioEquipment.self`:
  ```swift
  Studio.self,
  StudioEquipment.self,
  ExerciseProgressionState.self
  ```
- Enum `ProgressionMode` wird **nicht** ins Schema aufgenommen.
- Kein Seeder, keine Default-Daten. `PreviewModelContainer.swift` unverändert.

#### 4. Build-Validierung

- Xcode `Cmd+B` iOS-Target.
- watchOS-Build kontroll-grün halten (nicht betroffen).
- Launch im Simulator: Bestehende Daten intakt. Neue Tabelle leer.

### Manuelle Tests

1. App starten — kein Migrations-Crash, Home-Screen öffnet normal.
2. Bestehende Übung öffnen → `ExerciseFormView` ohne Fehler.
3. Bestehende Session öffnen → `StrengthDetailView` ohne Fehler.
4. Aktives Training starten + 1 Satz eintragen → speichert wie gehabt.
5. Console: keine SwiftData-Warnung zu fehlenden Inversen oder unknown types. Speziell: KEIN "Missing inverse" für `ExerciseProgressionState` (keine Relationship deklariert).
6. (Optional, dev-safe, nicht committen) Debug-Insert:
   ```swift
   let state = ExerciseProgressionState(exerciseGroupKey: "bench-press", workingWeight: 60.0)
   state.progressionMode = .smart
   context.insert(state); try? context.save()
   ```

### Build-Check

- [ ] iOS build green
- [ ] watchOS build green (nicht betroffen, nur Kontrolle)
- [ ] No new warnings
- [ ] App launches
- [ ] Bestehende Daten intakt (Sessions, Exercises, Pläne, Studios aus 1.1)
- [ ] Affected views load without crash

### Risks / Open Questions

- **CloudKit-Dedup-Bug:** `var id: UUID = UUID()`-Default wird einmalig ausgewertet — für 1.2 akzeptabel, da noch keine Records. `deduplicateAllSyncUUIDs()` ggf. in 1.22 erweitern.
- **Verzeichnis-Pfad:** Instruction-Doc nennt `MotionCore/Models/`; Realität `MotionCore/Models/Core/` — Plan folgt der Realität.
- **Keine Relationship zu Exercise — bewusst:** Matching via `exerciseGroupKey` analog `ExerciseRating`. Vorteile: kein CloudKit-Inverse-Zwang, Exercise-Umbenennung ohne State-Verlust, Spontan-Übungen ohne persistiertes `Exercise` möglich (Concept §3.4: lazy init beim ersten Set-Abschluss).
- **Keine Naming-Konflikte:** Grep-Validation bestätigt.

🛑 **STOPP 1.2** — Nach erfolgreichem Build-Check und Barto-Sichtung warten auf Freigabe für Schritt 1.3.

---

## Fortschritt

- **2026-04-18** — Plan 1.1 erstellt.
- **2026-04-18** — Schritt 1.1 implementiert. Dateien: `StudioEquipmentType.swift` (neu), `Studio.swift` (neu), `StudioEquipment.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
- **2026-04-18** — Schritt 1.1 committed (5744842). Plan 1.2 erstellt.
- **2026-04-18** — Schritt 1.2 implementiert. Dateien: `ProgressionMode.swift` (neu), `ExerciseProgressionState.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
