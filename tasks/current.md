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
- [x] **1.12** Studio-Setup + Default-Seeder *(implementiert 2026-04-18)*
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

## Aktueller Schritt: 1.12 — Studio-Setup + Default-Seeder

### Ziel

Studio-Konfigurations-UI im Settings-Bereich + idempotenter Default-Seeder für "Mein Studio" beim ersten App-Start. User kann StudioEquipment-Profile anlegen, editieren, löschen. Datenmodell existiert seit 1.1.

### Files

**NEU (4):**
- `MotionCore/Services/DefaultStudioSeeder.swift`
- `MotionCore/Views/Settings/View/StudioSetupView.swift`
- `MotionCore/Views/Settings/Components/StudioEquipmentEditSheet.swift`
- `MotionCore/Views/Settings/Components/StudioEquipmentRow.swift`

**ÄNDERN (2):**
- `MotionCore/Views/Settings/View/MainSettingsView.swift` — NavigationLink "Studio einrichten" in Section "Allgemeine Einstellungen"
- `MotionCore/App/MotionCoreApp.swift` — Seeder-Call im existierenden `.task`-Block (nach `ExerciseSeeder.seedMissing`)

### Patterns (Vorlagen)

- Seeder-Hook: `MotionCoreApp.swift:122–128` (bestehende `.task`-Sequenz)
- Settings-View-Struktur: `EBikeProfileView.swift` (`List { Section { ... } }`)
- Decimal-Input: `DecimalTextField.swift` (DE/US-Locale-kompatibel)
- Sheet-Pattern: immer `.sheet(item:)` (Lessons)
- Idempotenz: Query-basiert auf `Studio.isPrimary == true` (robuster als UserDefaults bei CloudKit-Restore)

### Detail-Steps

#### 1.12.1 — `DefaultStudioSeeder.swift`

- `struct DefaultStudioSeeder` mit `static func seedIfNeeded(context: ModelContext)`
- Idempotenz-Check: `FetchDescriptor<Studio>` mit `#Predicate { $0.isPrimary == true }` → early return bei ≥1 Treffer
- Bei 0 Treffern: `Studio(name: "Mein Studio", isPrimary: true)` + 5 `StudioEquipment` mit `equipment.studio = studio` (Inverse setzen)
- `try? context.save()`
- Default-Geräte gemäß Concept 3.1.2:
  - Kabelzug — cable, start 1.25, incr 2.5, intermediate [0.625, 1.25]
  - Kurzhanteln — dumbbell, start 2.0, incr 2.0, intermediate [], max 24.0
  - Beinpresse — machine, start 0.0, incr 7.0, intermediate [3.5]
  - Brustpresse — machine, start 0.0, incr 7.0, intermediate [3.5]
  - Latzugmaschine — machine, start 0.0, incr 7.0, intermediate [3.5]

#### 1.12.2 — `StudioEquipmentRow.swift`

- Props: `let equipment: StudioEquipment`
- `HStack`: Type-Icon (SF-Symbol) + `VStack { name, weightRange }` + Badge "Feintuning" bei vorhandenen Intermediates
- Icon-Mapping (`StudioEquipmentType`-Extension):
  - `.machine` → "gear", `.cable` → "arrow.up.and.down", `.dumbbell` → "dumbbell.fill", `.barbell` → "figure.strengthtraining.traditional", `.bodyweight` → "figure.stand", `.other` → "questionmark.circle"
- displayName-Extension: "Maschine" / "Kabelzug" / "Kurzhantel" / "Langhantel" / "Körpergewicht" / "Sonstiges"

#### 1.12.3 — `StudioEquipmentEditSheet.swift`

- Props: `let studio: Studio`, `let existing: StudioEquipment?` (nil = Add), `@Environment(\.modelContext)`, `@Environment(\.dismiss)`
- Lokale `@State`-Kopien aller Felder (Cancel-Safe)
- `maxWeight: Double?` via `hasMaxWeight: Bool` + `maxWeightValue: Double`
- Layout `NavigationStack { Form { ... } }`:
  - Section "Basis": Name (TextField), Typ (Picker)
  - Section "Gewicht": start/increment/min (DecimalTextField), Toggle+Field für max
  - Section "Zwischengewichte": dynamische Liste via `ForEach(..enumerated())` mit Swipe-Delete, Footer-Button "hinzufügen" (default 0.625)
  - Section "Notiz": TextEditor
- Toolbar: Cancel + Speichern
- Validierung: Name nicht leer, Increment > 0, StartWeight ≥ 0, MaxWeight > StartWeight (wenn gesetzt). Fehler via Alert-State
- Save: existing=nil → Insert + `equipment.studio = studio`; sonst Felder überschreiben; `try? context.save()`

#### 1.12.4 — `StudioSetupView.swift`

- `@Environment(\.modelContext)`, `@EnvironmentObject private var appSettings: AppSettings`
- `@Query(filter: #Predicate<Studio> { $0.isPrimary == true })`
- `@State private var editingEquipment: StudioEquipment?` (Sheet-Item)
- `@State private var addSheetStudio: Studio?` (Sheet-Item für Add)
- `@State private var equipmentPendingDelete: StudioEquipment?` (Alert-Item)
- `ZStack`: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)` + `List`
- Pro Equipment: `Button { editingEquipment = eq } label: { StudioEquipmentRow(equipment: eq) }.glassCard()`
- `.onDelete` am ForEach → `equipmentPendingDelete = eq`
- `.alert(item: $equipmentPendingDelete)` für Delete-Confirm
- Toolbar Trailing: "+" → `addSheetStudio = primaryStudio`
- Fallback EmptyState wenn keine Equipment
- `.sheet(item: $editingEquipment)` + `.sheet(item: $addSheetStudio)` — item-basiert, kein isPresented-Pattern
- `.navigationTitle("Studio einrichten")`, `.navigationBarTitleDisplayMode(.inline)`

#### 1.12.5 — `MainSettingsView.swift`

In Section "Allgemeine Einstellungen" nach dem E-Bike-Profil-Link:
```swift
NavigationLink { StudioSetupView() } label: {
    Label("Studio einrichten", systemImage: "dumbbell.fill")
}
```

#### 1.12.6 — `MotionCoreApp.swift`

Im bestehenden `.task` nach `ExerciseSeeder.seedMissing(context: context)` anhängen:
```swift
DefaultStudioSeeder.seedIfNeeded(context: context)
```

### Manuelle Tests

**Seeder-Idempotenz:**
- Frische Installation → 5 Geräte in "Mein Studio"
- App-Restart → keine Duplikate
- Alle Geräte löschen → App-Restart → Seeder läuft nicht erneut (Studio noch da)

**Setup-Flow:** Add-Sheet → Validierung → Row erscheint. Zwischengewichte add/delete.

**Edit-Flow:** Tap → Sheet mit vorbefüllten Werten → Speichern aktualisiert Row.

**Delete-Flow:** Swipe → Confirm → Löschen.

**Decimal-Input:** `,` und `.` beide akzeptiert.

### Build-Check

- [ ] iOS Build grün
- [ ] watchOS Build grün (Kontrolle)
- [ ] Keine neuen Warnings
- [ ] App startet ohne Migrations-Fehler
- [ ] Previews für StudioSetupView + EditSheet funktionieren

### Risks

- **CloudKit-Sync + Seeder:** Paralleler First-Launch auf 2 Devices → 2 Primary-Studios möglich. Akzeptiert (manueller Cleanup in UI möglich, keine Watch-Sync-Pflicht).
- **Dynamic-List Focus-Reset bei Mitte-Insert:** durch Append-Only-Pattern mitigiert.
- **Decimal-Input:** `DecimalTextField` bewährt (EBikeProfileView).

### Offene Fragen

Keine — Concept v1 schreibt Single-Studio-UI explizit vor.

🛑 **STOPP 1.12** — Warte auf Freigabe für Developer-Start.

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
- **2026-04-18** — Schritt 1.10 implementiert. 3 Legacy-Files gelöscht, SummaryViewModel bereinigt.
- **2026-04-18** — Schritt 1.11 implementiert. 4 Stored Properties (progressionSessionsRequired, progressionStrategyRaw, customProgressionStep, minDaysBetweenProgressions) + 4 Computed Properties (progressionStrategy, baseProgressionStep, effectiveProgressionStep, canRecommendProgression) aus Exercise.swift entfernt. ExerciseProgressionSection (256 Zeilen) aus FormViewSection.swift gelöscht. 9 Stellen in SetConfigurationSheet.swift bereinigt (4 State-Inits, 4 @State-Declarations, If-Else-Block vereinfacht, 4 Save-Zuweisungen entfernt). 11-Zeilen-Block aus ExerciseFormView.swift entfernt. ProgressionTypes.swift per git rm gelöscht. Finale Grepping: alle Legacy-Typen 0 Treffer.
- **2026-04-18** — Schritt 1.12 implementiert. DefaultStudioSeeder + StudioSetupView + StudioEquipmentEditSheet + StudioEquipmentRow + MainSettings-Link + Seeder-Hook.
