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

- [ ] **1.1** Datenmodell: Studio & StudioEquipment *(aktuell in Planung — siehe Detail-Plan unten)*
- [ ] 1.2 Datenmodell: `ExerciseProgressionState` + `ProgressionMode` *(geplant nach Freigabe)*
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

## Aktueller Schritt: 1.1 — Datenmodell: Studio & StudioEquipment

### Ziel

Zwei neue SwiftData-Modelle (`Studio`, `StudioEquipment`) plus ein Enum (`StudioEquipmentType`) anlegen und im `ModelContainer`-Schema registrieren. Additiv, ohne UI, ohne Seeder, ohne Services.

### Files (erwartet)

- **NEU:** `MotionCore/Models/Core/Studio.swift`
- **NEU:** `MotionCore/Models/Core/StudioEquipment.swift`
- **NEU:** `MotionCore/Models/Core/StudioEquipmentType.swift`
- **ÄNDERN:** `MotionCore/App/MotionCoreApp.swift` (Schema-Array erweitern)

> Verzeichnis: Die bestehenden Models liegen unter `MotionCore/Models/Core/`, nicht direkt unter `MotionCore/Models/`. Abweichung vom Instruction-Text ist bewusst (konsistent zur existierenden Struktur). Xcode 16 `PBXFileSystemSynchronizedRootGroup` nimmt neue Files automatisch ins Target `MotionCore` — keine manuelle Target-Zuordnung nötig.

### Cross-References (für Löschungen)

Keine — additiver Schritt. Grep auf `Studio`, `StudioEquipment`, `StudioEquipmentType` ergab keine Treffer in `MotionCore/` (außer in Concept/Instruction-Docs). Naming-Konflikt mit `ExerciseEquipment` (in `MotionCore/Models/Types/ExerciseTypes.swift:53`) wird durch bewusste Namenswahl `StudioEquipmentType` vermieden.

### Detail-Steps

#### 1. `StudioEquipmentType.swift`

- Datei-Header gemäß Projekt-Standard (vgl. `ExerciseRating.swift`), Abschnitt "Daten-Modell", Beschreibung: "Gerätetyp-Enum für StudioEquipment".
- `import Foundation` (kein SwiftData nötig).
- `enum StudioEquipmentType: String, Codable, CaseIterable { case machine, cable, dumbbell, barbell, bodyweight, other }` — Reihenfolge und Fälle exakt aus Concept 3.1.2.
- Bewusst **separate Datei** statt in eine der Model-Dateien, konsistent zum Concept-Layout und leicht auffindbar.

#### 2. `Studio.swift`

- Datei-Header analog (Erstellt am: 18.04.2026, Beschreibung: "Studio-Definition (Equipment-Profil-Container)").
- `import Foundation`, `import SwiftData`.
- `@Model final class Studio` mit stored Properties:
  - `var id: UUID = UUID()`
  - `var name: String = ""`
  - `var isPrimary: Bool = false`
  - `var createdAt: Date = Date()`
- Relationship:
  - `@Relationship(deleteRule: .cascade, inverse: \StudioEquipment.studio) var equipment: [StudioEquipment]? = []`
- Safe Accessor am Dateiende in separatem `extension`-Block:
  - `var safeEquipment: [StudioEquipment] { equipment ?? [] }`
- Init exakt wie im Concept:
  - `init(name: String = "", isPrimary: Bool = false)` — setzt `name` und `isPrimary`, alles andere über Defaults.
- Deutsche Kommentare für nicht-offensichtliche Felder (`isPrimary` → "Aktuell genutztes Studio (Multi-Studio-vorbereitet, UI zeigt nur eins)").

#### 3. `StudioEquipment.swift`

- Datei-Header analog (Beschreibung: "Konkretes Studio-Gerät mit Gewichtsprofil und Sprüngen").
- `import Foundation`, `import SwiftData`.
- `@Model final class StudioEquipment` mit stored Properties exakt nach Concept 3.1.2:
  - `var id: UUID = UUID()`
  - `var name: String = ""`
  - `var equipmentTypeRaw: String = "machine"`
  - `var startWeight: Double = 0.0`
  - `var increment: Double = 2.5`
  - `var minWeight: Double = 0.0`
  - `var maxWeight: Double? = nil`
  - `var intermediateIncrements: [Double] = []`
  - `var notes: String = ""`
  - `var createdAt: Date = Date()`
- Rückbeziehung (Kind-Seite, ohne `inverse`):
  - `var studio: Studio?`
- Typisiertes Enum-Accessor:
  - `var equipmentType: StudioEquipmentType { get { StudioEquipmentType(rawValue: equipmentTypeRaw) ?? .machine } set { equipmentTypeRaw = newValue.rawValue } }`
- Init exakt wie im Concept:
  - `init(name: String = "", equipmentType: StudioEquipmentType = .machine, startWeight: Double = 0.0, increment: Double = 2.5, intermediateIncrements: [Double] = [])` — setzt diese Felder; `minWeight = startWeight`.
- Hinweis-Kommentar über `intermediateIncrements`: "Zwischengewichte via Feintuning-Chips; standardmäßig leer".
- **Keine `@Attribute(.transformable)` notwendig**: `[Double] = []` wird — analog zu `Exercise.primaryMusclesRaw: [String] = []` — von SwiftData/CloudKit inline gespeichert.

#### 4. `MotionCoreApp.swift` — Schema-Registrierung

- In `private static let appSchema = Schema([...])` (Zeilen 39–48) die beiden neuen Models ergänzen:
  - `Studio.self`
  - `StudioEquipment.self`
- Enum `StudioEquipmentType` wird **nicht** ins Schema aufgenommen (SwiftData-Schemata nehmen nur `@Model`-Typen).
- Keine weiteren Änderungen im Container-Setup, kein Seeder-Call in dieser Stufe.
- `PreviewModelContainer.swift` bleibt unverändert (registriert nur `CardioSession.self`; neue Models sind in Previews irrelevant, solange keine Preview sie nutzt).

#### 5. Build-Validierung

- Xcode `Cmd+B` auf iOS-Target.
- Watch-Target-Build nicht betroffen (keine Änderungen an Watch-Dateien).
- Launch im Simulator: Bestehende Daten (Sessions, Exercises, Pläne) müssen vollständig erhalten bleiben. Neue Tabellen im lokalen Store sind leer — erwartetes Verhalten.

### Manuelle Tests

1. App starten (Simulator) — kein Migrations-Crash, Home-Screen öffnet normal.
2. Bestehende Übung öffnen → `ExerciseFormView` lädt ohne Fehler.
3. Bestehende Session öffnen → `StrengthDetailView` lädt ohne Fehler.
4. Aktives Training starten + 1 Satz eintragen → speichert wie gehabt.
5. Xcode-Console: keine SwiftData-Warnung zu fehlenden Inversen oder unknown types.
6. (Optional, dev-safe) Debug-Insert via temporärer Test-View: `Studio(name: "Mein Studio", isPrimary: true)` + `StudioEquipment(name: "Kabelzug", equipmentType: .cable, startWeight: 1.25, increment: 2.5, intermediateIncrements: [0.625, 1.25])` — sollte fehlerfrei persistieren. Diese Testaktion **nicht committen**.

### Build-Check

- [ ] iOS build green
- [ ] watchOS build green (nicht betroffen, nur Kontrolle)
- [ ] No new warnings
- [ ] App launches
- [ ] Bestehende Daten intakt (Sessions, Exercises, Pläne)
- [ ] Affected views load without crash (Summary, ActiveWorkout, StrengthDetail, ExerciseList)

### Risks / Open Questions

- **Risiko CloudKit-Dedup-Bug:** `var id: UUID = UUID()` wird bei Schema-Migration nur einmal ausgewertet. Für `Studio`/`StudioEquipment` in 1.1 akzeptabel, da noch keine Records existieren; `deduplicateAllSyncUUIDs()` wird im Sync-Schritt 1.22 ggf. erweitert.
- **Verzeichnis-Pfad:** Instruction-Doc nennt `MotionCore/Models/`; tatsächliche Struktur ist `MotionCore/Models/Core/`. Dieser Plan folgt der realen Struktur (konsistent mit `Exercise.swift`, `ExerciseRating.swift`, `TrainingPlan.swift`).
- **Offene Frage — keine.** `[Double]` ist laut bestehender `[String]`-Nutzung in `Exercise` unbedenklich mit SwiftData+CloudKit. Falls der Dev-Build wider Erwarten einen Fehler wirft, Fallback: `@Attribute(.externalStorage)` prüfen — aber erst bei tatsächlichem Symptom, nicht präventiv.

🛑 **STOPP 1.1** — Nach erfolgreichem Build-Check und Barto-Sichtung warten auf Freigabe für Schritt 1.2.

---

## Fortschritt

- **2026-04-18** — Plan 1.1 erstellt.
- **2026-04-18** — Schritt 1.1 implementiert. Dateien: `StudioEquipmentType.swift` (neu), `Studio.swift` (neu), `StudioEquipment.swift` (neu), `MotionCoreApp.swift` (Schema erweitert).
