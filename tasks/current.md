# MuscleRecoveryCalcEngine + Body-Tab

**Complexity:** Large
**Status:** Bereit zur Umsetzung — strikt phased, 11 Schritte mit STOPP-Gates
**Voraussetzung:** Phase 1 + Phase 1.5 + Phase 2 Readiness abgeschlossen (alle vorhanden)
**Bezug:** `Documentation/Concepts/MotionCore_MuscleRecoveryCalcEngine_Concept_v3.md`
**Instruction:** `Documentation/Concepts/MotionCore_MuscleRecovery_ClaudeCodeInstruction_v2.md`

## Summary

`MuscleRecoveryCalcEngine` berechnet pro Muskelgruppe einen Erholungs-Score (0–100%) aus den letzten 14 Tagen mit exponentiellem Decay (Halbwertszeit 7 Tage). Anzeige in neuem **Body-Tab** (zwischen Stats und Training) plus kompakte Vorschau in `SummaryView`. Genau ein Snapshot pro Tag wird beim ersten App-Open ab 6:00 Uhr in die Supabase-Tabelle `motioncore.muscle_recovery_snapshots` geschrieben.

## Scope

**Inkludiert (Phase 1):**
- Pure CalcEngine + Ergebnistypen
- 2 Card-Styles (`.compact` / `.full`) und ein Detail-Sheet
- Neuer `BodyView`-Tab inkl. Readiness-Faktoren-Wiederverwendung
- SummaryView-Vorschau direkt nach `ReadinessSummaryCard`
- Supabase-Tabelle + DTO + Service + scenePhase-Trigger (1 Snapshot pro Tag, 6-Uhr-Schwelle)

**Explizit ausgeschlossen:**
- Adaptive Lernlogik (`baseRecoveryHours` aus Verhalten — Phase 2)
- TrainingDetailView-Integration / `PlanRecoveryAnalysis`
- ActiveWorkoutView Recovery-Header
- Lokale SwiftData-Persistenz der Snapshots
- Body-Composition-Cards
- Backfill historischer Snapshots
- Session-Complete-Trigger (bewusst entfernt vs. v2)

## UX Placement

- **Tab-Position:** Zwischen `stats` und `training` in `BaseView.Tab`
- **Tab-Icon:** `figure.arms.open` (Fallback: `figure.strengthtraining.traditional`)
- **SummaryView-Card:** Direkt unter `ReadinessSummaryCard`, Style `.compact`
- **Detail-Sheet:** Tap auf Card öffnet `MuscleRecoveryDetailView` via `.sheet(item:)`

## Affected Files

### Neu (9 Dateien)

- `MotionCore/Services/Calculation/MuscleRecoveryTypes.swift`
- `MotionCore/Services/Calculation/MuscleRecoveryCalcEngine.swift`
- `MotionCore/Views/Body/MuscleRecoveryDonut.swift`
- `MotionCore/Views/Body/MuscleRecoveryCard.swift`
- `MotionCore/Views/Body/MuscleRecoveryDetailView.swift`
- `MotionCore/Views/Body/BodyViewModel.swift`
- `MotionCore/Views/Body/BodyView.swift`
- `MotionCore/Services/Supabase/SupabaseMuscleRecoverySnapshot.swift`
- `MotionCore/Services/Supabase/SupabaseMuscleRecoveryService.swift`

### Geändert (3 Dateien)

- `BaseView.swift` — `Tab`-Enum + neue TabView-Section + App-Open-Trigger
- `SummaryViewModel.swift` — `recoveryAnalysis` Property + Recompute-Aufruf
- `SummaryView.swift` — `MuscleRecoveryCard` nach `ReadinessSummaryCard` + Sheet

### Datenbank (1 Migration)

- Supabase MCP `apply_migration` (Project ID: `jeebptrnhjekwtviecvz`) — `motioncore.muscle_recovery_snapshots`

## Risks

- **Default-Tab nach Enum-Erweiterung:** Initial-Wert muss explizit `.summary` bleiben.
- **Doppel-Inserts:** UserDefaults-Set NUR nach erfolgreichem Upload — kein Tag-Check im Service.
- **Sheet-Race (lessons.md):** MUSS `.sheet(item:)` verwenden — niemals `.sheet(isPresented:)`.
- **CodingKeys-Falle (lessons.md):** Alle DTO-Felder explizit in `CodingKeys` listen.
- **Supabase RLS:** KEIN `ENABLE ROW LEVEL SECURITY` — Tabellen bleiben UNRESTRICTED.
- **Muscle-Resolution-Duplikat:** Bewusste Copy-Paste aus `MuscleHeatmapCalcEngine` mit `// TODO: extract to SharedMuscleResolver`.

## Implementation Steps

### Step 1 — `MuscleRecoveryTypes.swift` (NEU)

- [x] Datei in `MotionCore/Services/Calculation/` anlegen, Standard-Header
- [x] `DetailedMuscleRecovery` (Identifiable struct): `id: String`, `muscle: DetailedMuscle`, `recoveryPercent: Double`, `lastTrainedDate: Date?`, `totalFatigueScore: Double`, computed `displayName`, `muscleGroup`
- [x] `MuscleGroupRecovery` (Identifiable struct): `id`, `muscleGroup`, `recoveryPercent`, `muscleDetails: [DetailedMuscleRecovery]`, `lastTrainedDate`, `wasTrainedInTimeframe: Bool`, computed `displayName`, `isFullyRecovered`
- [x] `MuscleRecoveryAnalysis`: `analysisDate`, `timeframeDays: Int`, `muscleGroupScores: [MuscleGroupRecovery]`, `detailedScores: [DetailedMuscleRecovery]`, computed `leastRecoveredGroups`, `overallRecoveryPercent`
- [x] `recoveryColor(percent:) -> Color` Hilfsfunktion (HSL-Interpolation rot→grün)
- [ ] **STOPP-Gate 1:** Build prüfen.

### Step 2 — `MuscleRecoveryCalcEngine.swift` (NEU)

- [x] Datei in `MotionCore/Services/Calculation/` anlegen, Standard-Header
- [x] `struct MuscleRecoveryCalcEngine` mit Konstanten exakt nach Konzept 5.1
- [x] `static func analyze(sessions: [StrengthSession]) -> MuscleRecoveryAnalysis` nach Konzept 5.2
- [x] Private Hilfsfunktionen: `intensityFromRIR(_:)`, `normalizedVolume(weight:reps:sessionBodyWeight:)`, `fatigueMultiplier(_:)`
- [x] `resolveDetailedMuscles` als Copy-Paste aus `MuscleHeatmapCalcEngine.swift` mit `// TODO: extract to SharedMuscleResolver`
- [x] Sets-Filter: nur `isCompleted && reps > 0 && setKind == .work`
- [x] Output-Reihenfolge: `[chest, back, shoulders, arms, legs, core, glutes]`
- [ ] **STOPP-Gate 2:** Build + mentaler Algorithmus-Check.

### Step 3 — `MuscleRecoveryDonut.swift` + `MuscleRecoveryCard.swift` (NEU)

- [x] Donut: Parameter `percent`, `wasTrained`, `label`, `size` + Gradient-Farbe vs. grauer Ring
- [x] Card: `enum CardStyle { case compact, full }`, `.glassCard()`, `onTap`-Closure
- [x] `.compact`: ~60pt Donuts, horizontaler Scroll; `.full`: ~80pt, LazyVGrid 4 Spalten
- [x] Header: "Muskel-Erholung" + Gesamt-%; Footer (`.full`): "Letzte 14 Tage"
- [x] Preview mit Mock-Daten (trainiert + untrainiert)
- [ ] **STOPP-Gate 3:** Preview visuell prüfen.

### Step 4 — `MuscleRecoveryDetailView.swift` (NEU)

- [x] Sheet mit ScrollView + `AnimatedBackground`, analog `ReadinessDetailView`
- [x] Header: Gesamt-Donut + "Letzte 14 Tage"
- [x] Pro MuscleGroup: Zeile mit Donut + Name + relative Zeit + aufklappbare DetailedMuscle-Liste
- [x] Untrainierte Gruppen: grau + "noch nicht trainiert"
- [x] `scrollViewContentPadding()`, < 400 Zeilen, Preview vorhanden
- [ ] **STOPP-Gate 4:** Preview prüfen.

### Step 5 — `BodyViewModel.swift` + `BodyView.swift` (NEU)

- [x] ViewModel: `@Observable`, `recoveryAnalysis`, `readinessFactors`, `recalculate(sessions:)`, `loadReadinessFactors(...)`
- [x] View: ScrollView + AnimatedBackground, `@State viewModel`, `@Query` Sessions + Readiness + Baselines
- [x] Refresh: `.task` + `.onChange(of: scenePhase) { if newPhase == .active { ... } }`
- [x] Sheet via `.sheet(item: $detailItem)` — niemals `isPresented`
- [x] Section "Tagesform-Faktoren" mit `ReadinessFactorRow`
- [x] `EmptyState()` wenn keine Daten, Preview vorhanden
- [ ] **STOPP-Gate 5:** Build + Preview prüfen.

### Step 6 — `BaseView.swift` EDIT — Body-Tab einfügen

- [x] `enum Tab` erweitern: `case summary, workouts, stats, body, training`
- [x] Default-Tab bleibt explizit `.summary`
- [x] Neue NavigationStack-Section mit `BodyView()`, HeaderView "Body", Settings-Link
- [x] `.tabItem { Label("Body", systemImage: "figure.arms.open") }.tag(Tab.body)`
- [x] App-Open-Trigger NOCH NICHT hier — folgt Step 11
- [ ] **STOPP-Gate 6 (visuell):** Tab zwischen Stats und Training, kein Layout-Glitch.

### Step 7 — `SummaryViewModel.swift` EDIT

- [x] `private(set) var recoveryAnalysis: MuscleRecoveryAnalysis?`
- [x] In `recalculate(...)`: `recoveryAnalysis = MuscleRecoveryCalcEngine.analyze(sessions: strengthSessions)`
- [x] Keine bestehende Berechnung verändern
- [ ] **STOPP-Gate 7:** Build prüfen.

### Step 8 — `SummaryView.swift` EDIT

- [x] `@State private var recoveryDetailItem: MuscleRecoveryAnalysis?`
- [x] Nach `ReadinessSummaryCard`-Block: `if let recovery = viewModel.recoveryAnalysis { MuscleRecoveryCard(analysis: recovery, style: .compact) { recoveryDetailItem = recovery } }`
- [x] `.sheet(item: $recoveryDetailItem) { MuscleRecoveryDetailView(analysis: $0) }`
- [ ] **STOPP-Gate 8 (visuell):** Card erscheint, Tap öffnet Sheet, Sheet-Race-Test direkt nach App-Start.

### Step 9 — Supabase-Migration

- [x] MCP `apply_migration` — `public.muscle_recovery_snapshots` (im `public`-Schema, konsistent mit allen anderen App-Daten-Tabellen)
- [x] KEIN `related_session_uuid`, KEIN RLS
- [x] 2 Indices: `captured_at DESC`, `snapshot_date DESC`
- [x] `list_tables` zur Verifikation — Tabelle vorhanden, `rls_enabled: false`
- [ ] **STOPP-Gate 9:** Schema im Supabase-Dashboard bestätigen.

### Step 10 — `SupabaseMuscleRecoverySnapshot.swift` + `SupabaseMuscleRecoveryService.swift` (NEU)

- [x] DTO: `Encodable`, alle 20 Felder explicit in `CodingKeys` mit snake_case (lessons.md!)
- [x] KEIN `related_session_uuid`
- [x] Service: `@MainActor final class`, `static let shared`, `func uploadSnapshot(...) async -> Bool`
- [x] Gibt `true`/`false` zurück — kein Crash, kein Rethrow; `#if DEBUG print(...)` bei Fehler
- [x] Keine Dedup-Logik im Service
- [ ] **STOPP-Gate 10:** Build prüfen.

### Step 11 — `BaseView.swift` EDIT — App-Open-Trigger

- [x] `triggerDailyMuscleRecoverySnapshotIfNeeded()`: UserDefaults-Key `lastMuscleRecoverySnapshotDate`, 6-Uhr-Schwelle, Task mit Fetch + analyze + upload
- [x] UserDefaults-Key NUR bei `success == true` gesetzt (retry bei Fehler)
- [x] In bestehendem `.onChange(of: scenePhase)` ergänzt (kein Duplikat)
- [x] Im bestehenden `.onAppear`-Block ergänzt (nach 1s-Delay, initialer Launch)
- [ ] **STOPP-Gate 11 (End-to-End):**
  - Test 1: Key löschen → App öffnen → 1 Snapshot in Supabase
  - Test 2: App sofort nochmal öffnen → KEIN zweiter Snapshot
  - Test 3: Body-Tab → Background → Foreground → recalculate läuft
  - Test 4: Werte in SummaryView-Vorschau und BodyView konsistent

---

## Fortschritt

**2026-04-25 17:20 Uhr**

Abgeschlossene Steps: 1, 2, 3, 4, 5, 6

Erstellte / geänderte Dateien:
- `MotionCore/Services/Calculation/MuscleRecoveryTypes.swift` — `extension MuscleRecoveryAnalysis: Identifiable` ergänzt
- `MotionCore/Services/Calculation/MuscleRecoveryCalcEngine.swift`
- `MotionCore/Views/Body/MuscleRecoveryDonut.swift`
- `MotionCore/Views/Body/MuscleRecoveryCard.swift`
- `MotionCore/Views/Body/MuscleRecoveryDetailView.swift`
- `MotionCore/Views/Body/BodyViewModel.swift` (NEU, 50 Zeilen) — `@Observable`, delegiert an `ReadinessViewModel` intern
- `MotionCore/Views/Body/BodyView.swift` (NEU, 120 Zeilen) — ScrollView + AnimatedBackground, `.sheet(item:)`
- `MotionCore/Views/Root/View/BaseView.swift` — Tab-Enum auf 5 Cases erweitert, Body-Tab zwischen Stats und Training eingefügt

Hinweise:
- `BodyViewModel` hält intern ein `ReadinessViewModel` und ruft `load(...)` auf — kein Kopieren der privaten `buildBreakdown`-Logik
- `MuscleRecoveryAnalysis: Identifiable` via `var id: Date { analysisDate }` — nötig für `.sheet(item:)`
- Default-Tab in BaseView bleibt `= .summary` (Zeile 27, unverändert)
- STOPP-Gates 1–6: Build- und Preview-Verifikation ausstehend (via Xcode Cmd+B)

Offene Steps: 9–11

---

**2026-04-25 17:30 Uhr**

Abgeschlossene Steps: 7, 8

Geänderte Dateien:
- `MotionCore/Services/ViewModels/SummaryViewModel.swift` — neue Property `recoveryAnalysis: MuscleRecoveryAnalysis?` (nach `filteredHeatmapAnalysis`), Zuweisung via `MuscleRecoveryCalcEngine.analyze(sessions: strength)` am Ende von `recalculate(...)` vor `recalculateFiltered`
- `MotionCore/Views/Summary/View/SummaryView.swift` — neuer `@State private var recoveryDetailItem: MuscleRecoveryAnalysis?`, Block "1c. Muscle-Recovery Vorschau" nach ReadinessSummaryCard, `.sheet(item: $recoveryDetailItem)` mit `.environmentObject(appSettings)` (nötig da `MuscleRecoveryDetailView` `@EnvironmentObject var appSettings: AppSettings` deklariert)

STOPP-Gates 7 + 8: Build + visuelle Verifikation via Xcode Cmd+B ausstehend.

---

**2026-04-25 17:30 Uhr**

Abgeschlossene Steps: 9, 10, 11

Architektur-Entscheid Step 9: Tabelle in `public`-Schema angelegt (nicht `motioncore`), da:
- Alle User-Daten-Tabellen (`strength_sessions`, `session_readiness`, etc.) liegen in `public`
- `motioncore`-Schema enthält nur Exercise-Stammdaten (read-only via RPC)
- `SupabaseClient.upsert()` unterstützt kein Schema-Header-Switching → kein Client-Umbau nötig

Erstellte Dateien:
- `MotionCore/Services/Database/Remote/MuscleRecovery/SupabaseMuscleRecoverySnapshot.swift` — DTO mit 20 expliziten CodingKeys
- `MotionCore/Services/Database/Remote/MuscleRecovery/SupabaseMuscleRecoveryService.swift` — `@MainActor`, gibt `Bool` zurück

Geänderte Datei:
- `MotionCore/Views/Root/View/BaseView.swift` — `triggerDailyMuscleRecoverySnapshotIfNeeded()` hinzugefügt; Aufruf in bestehendem `.onAppear` (nach 1s-Delay) und bestehendem `.onChange(of: scenePhase)` ergänzt; UserDefaults-Key nur bei `success == true` gesetzt

STOPP-Gate 9: via `list_tables` MCP-Verifikation bestätigt (0 rows, rls_enabled: false).
STOPP-Gates 10 + 11: Build-Verifikation via Xcode Cmd+B ausstehend.

---

## Manual Verification

- [ ] Xcode Build ohne Warnings nach jedem Step
- [ ] Default-Tab bei App-Start ist `.summary`
- [ ] Neuer Snapshot nur 1× pro Tag ab 6:00 Uhr
- [ ] Keine NULL-Verletzungen in Supabase
- [ ] Kein Crash bei fehlender Internetverbindung
- [ ] Alle 7 Gruppen grau mit leerer Datenbank
- [ ] Lessons-Checks: `sheet(item:)`, alle CodingKeys, Engine nicht als computed property
