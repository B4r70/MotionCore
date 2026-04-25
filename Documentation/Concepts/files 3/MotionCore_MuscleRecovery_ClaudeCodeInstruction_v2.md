# Claude Code Instruction — MuscleRecoveryCalcEngine + Body-Tab (v2)

> **Auftraggeber:** Bartosz
> **Komplexität:** Medium-High (neue Engine + neuer Tab + Supabase-Schema)
> **Bezug:** `MotionCore_MuscleRecoveryCalcEngine_Concept_v3.md`
> **Voraussetzung:** Phase 2 Readiness und Phase 1.5 Bugfixes sind abgeschlossen.

---

## Agent-Workflow

```
motioncore-planner    → erstellt feinen Plan pro Step
motioncore-developer  → implementiert
motioncore-quality-gate → reviewed nach jedem STOPP-Gate
```

**STOPP-Gates** sind verpflichtend. Jeder Step endet mit Build + manueller Bestätigung von Bartosz, bevor der nächste Step beginnt.

---

## Globale Regeln

1. **Datei-Header:** Identisches Format wie alle bestehenden Dateien (siehe z.B. `ReadinessCalcEngine.swift`).
2. **Sprache:** UI-Texte deutsch, Code englisch, Code-Kommentare deutsch.
3. **CalcEngine-Pattern:** `MuscleRecoveryCalcEngine` ist eine **pure struct** ohne State, ohne Side-Effects.
4. **Datei-Größe:** Ziel 400 Zeilen, Hard Stop 800. Bei Annäherung an 600 sofort splitten.
5. **`ExerciseRating` und `PlanUpdateCalcEngine`** dürfen nicht angefasst werden.
6. **`rpeRecorded`-Feld** existiert seit Phase 1.5 — für Intensitäts-Berechnung nutzen.
7. **Muskel-Auflösung:** Identische Fallback-Kette wie `MuscleHeatmapCalcEngine.resolveDetailedMuscles()` — Copy-Paste mit `// TODO: extract to SharedMuscleResolver`.

---

## Step 1 — MuscleRecoveryTypes.swift

### Aufgabe
Lege die Datei `MuscleRecoveryTypes.swift` an mit allen Ergebnistypen.

### Inhalt
Siehe Konzept Abschnitt 4. Konkret:

- `DetailedMuscleRecovery` (Identifiable struct)
- `MuscleGroupRecovery` (Identifiable struct, mit `wasTrainedInTimeframe`)
- `MuscleRecoveryAnalysis` (struct mit `muscleGroupScores`, `detailedScores`, `leastRecoveredGroups`, `overallRecoveryPercent`)

### Validierung
- Datei kompiliert isoliert
- Alle Properties haben sinnvolle Typen
- Computed Properties (`displayName`, `muscleGroup`, `isFullyRecovered`) sind vorhanden

### STOPP-Gate
Build im Xcode prüfen. Erst nach OK weiter.

---

## Step 2 — MuscleRecoveryCalcEngine.swift

### Aufgabe
Implementiere die pure struct `MuscleRecoveryCalcEngine` mit der Methode `analyze(sessions:) -> MuscleRecoveryAnalysis`.

### Vorgaben
- **Konstanten:** Genau wie in Konzept 5.1.
- **Algorithmus:** Genau wie in Konzept 5.2 (14 Tage + exponential decay + Hybrid-Score).
- **Hilfsfunktionen:** `intensityFromRIR`, `normalizedVolume`, `fatigueMultiplier` — siehe Konzept 5.3.
- **`resolveDetailedMuscles`:** Copy-Paste der Fallback-Kette aus `MuscleHeatmapCalcEngine.swift` mit TODO-Kommentar.
- **Sekundäre Muskeln:** 30% des Volumens, NICHT als zusätzlicher Set zählen.
- **Decay:** `decayFactor = pow(0.5, ageInDays / 7.0)` — Halbwertszeit 7 Tage.
- **Untrainiert:** Muskelgruppen ohne Daten erhalten `recoveryPercent = 100, wasTrainedInTimeframe = false`.

### Output-Reihenfolge
`muscleGroupScores` immer in fester Reihenfolge:
`[chest, back, shoulders, arms, legs, core, glutes]`
(Andere `MuscleGroup` cases wie `.other` und `.fullBody` werden NICHT in der UI gezeigt — aber die Berechnung läuft über sie wenn sie via `parentGroup` angesprochen werden.)

### Validierung
- Engine ist `static`-Methode-basiert (analog `ReadinessCalcEngine.calculate(input:)`)
- Keine Side-Effects, keine `print`-Statements
- Alle Konstanten sind `static let`

### STOPP-Gate
Build prüfen. Bartosz geht den Algorithmus mental mit Beispieldaten durch (z.B. eine Session vor 2 Tagen, eine vor 8 Tagen). Erst nach Bestätigung weiter.

---

## Step 3 — MuscleRecoveryDonut.swift + MuscleRecoveryCard.swift

### Aufgabe
Lege beide Dateien an. Donut als wiederverwendbare Subkomponente.

### MuscleRecoveryDonut.swift
- Donut-Ring mit Prozent-Zahl in der Mitte (analog Mockup)
- Parameter: `percent: Double`, `wasTrained: Bool`, `label: String`, `size: CGFloat`
- Untrainiert (`wasTrained == false`): grauer voller Ring + Prozent-Zahl in `.secondary`
- Trainiert: Gradient-Farbe via `recoveryColor(percent:)` (HSL-Interpolation rot → grün)
- `recoveryColor` als interne Hilfsfunktion oder in `MuscleRecoveryTypes.swift`

### MuscleRecoveryCard.swift
- Style-Parameter: `enum CardStyle { case compact, full }`
- `.compact` (für SummaryView): kleinere Donuts (~60pt), horizontal scrollbar oder LazyHGrid
- `.full` (für BodyView): größere Donuts (~80pt), LazyVGrid mit 4 Spalten
- Header: "Muskel-Erholung" + Gesamt-Durchschnitt rechts
- Card-Stil: `.glassCard()`
- Tap-Geste auf gesamter Card → `onTap`-Closure
- Footer (nur in `.full`): "Letzte 14 Tage" als kleiner Hinweis

### Validierung
- Beide Dateien haben Preview mit Mock-Daten (trainierte + untrainierte Gruppen mischen)
- Tap-Geste funktioniert auf gesamter Card
- Donut-Größe passt sich an `size`-Parameter an

### STOPP-Gate
Preview in Xcode visuell prüfen.

---

## Step 4 — MuscleRecoveryDetailView.swift

### Aufgabe
Lege die Detail-View an, die bei Tap auf die Card geöffnet wird (Sheet via `.sheet(isPresented:)`).

### Inhalt
- Header: Großer Donut mit Gesamt-Recovery + "letzte 14 Tage"
- Pro `MuscleGroup` (in fester Reihenfolge): kompakte Zeile mit Donut + Name + relative Zeit-Anzeige (`vor 2 Tagen`)
- Bei Tap auf eine Gruppe: Aufklappbar mit DetailedMuscle-Aufschlüsselung
- Untrainierte Gruppen: grau dargestellt mit "noch nicht trainiert" als Subtitle
- AnimatedBackground konsistent mit anderen Detail-Views (siehe `ReadinessDetailView.swift`)

### Validierung
- Datei unter 400 Zeilen
- Preview vorhanden

### STOPP-Gate
Preview prüfen, mit Mock-Daten validieren.

---

## Step 5 — BodyViewModel.swift + BodyView.swift

### Aufgabe
Neuer Top-Level-Tab-Inhalt. ViewModel hält Recovery-Analyse und triggert Recompute bei View-Aktivierung.

### BodyViewModel.swift
- `@Observable final class BodyViewModel`
- Property: `recoveryAnalysis: MuscleRecoveryAnalysis?`
- Methode: `func recalculate(sessions: [StrengthSession])` — ruft `MuscleRecoveryCalcEngine.analyze(sessions:)` auf
- Methode: `func loadReadinessFactors(latestReadiness: SessionReadiness?, baselines: [HealthBaseline], takesCardioMedication: Bool)` — wiederverwendbar mit Logik analog `ReadinessViewModel.buildBreakdown()`
- Property: `readinessFactors: [ReadinessFactor]`

### BodyView.swift
- ScrollView mit `AnimatedBackground` (analog `SummaryView.swift`)
- `@State private var viewModel = BodyViewModel()` Pattern (analog `ReadinessDetailView`)
- `@Query` auf `StrengthSession` (isCompleted == true) und `SessionReadiness`
- `@Environment(\.scenePhase) private var scenePhase`
- Inhalt:
  - `MuscleRecoveryCard(analysis:, style: .full, onTap: ...)` — Tap navigiert zu `MuscleRecoveryDetailView` via Sheet
  - Section "Tagesform-Faktoren" mit `ReadinessFactorRow` für jeden Faktor (HRV, Schlaf, Ruhepuls, Aktivität)
  - `EmptyState` falls weder Recovery- noch Readiness-Daten vorhanden

### Refresh-Trigger (wichtig — Konzept 7.1)
```swift
.task {
    viewModel.recalculate(sessions: strengthSessions)
    viewModel.loadReadinessFactors(
        latestReadiness: latestReadiness,
        baselines: baselines,
        takesCardioMedication: appSettings.takesCardioMedication
    )
}
.onChange(of: scenePhase) { _, newPhase in
    guard newPhase == .active else { return }
    viewModel.recalculate(sessions: strengthSessions)
    viewModel.loadReadinessFactors(...)
}
```

### Validierung
- ViewModel ist `@Observable` (nicht `@MainActor` falls nicht zwingend nötig)
- Refresh feuert sowohl bei `.task` als auch bei scenePhase-Wechsel auf `.active`
- Preview vorhanden

### STOPP-Gate
Build, Preview prüfen.

---

## Step 6 — BaseView.swift erweitern (Body-Tab + App-Open-Trigger)

### Aufgabe A: Body-Tab in TabView einfügen — **zwischen Stats und Training**.

### Konkrete Änderungen
1. `Tab`-Enum erweitern:
```swift
enum Tab: Hashable {
    case summary, workouts, stats, body, training
}
```

2. Neue TabView-Section nach dem Stats-Tab und vor dem Training-Tab:
```swift
NavigationStack {
    BodyView()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HeaderView(title: "MotionCore", subtitle: "Body")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MainSettingsView()
                } label: {
                    ToolbarButton(icon: .system("gearshape"))
                }
            }
        }
}
.tabItem {
    Label("Body", systemImage: "figure.arms.open")
}
.tag(Tab.body)
```

### Aufgabe B: App-Open-Trigger für Supabase-Snapshot
Die Trigger-Logik kommt **noch nicht** in diesem Step — sie wird in Step 11 hinzugefügt, wenn der Service existiert. Hier nur den Tab einbauen.

### Validierung
- Tab erscheint zwischen Stats und Training
- Tab-Icon `figure.arms.open` (Apple SF Symbol — falls nicht verfügbar, alternative: `figure.strengthtraining.traditional`)
- Bestehende Tabs (Summary, Workouts, Stats, Training) bleiben unverändert
- Default-Tab bleibt `.summary`

### STOPP-Gate
**Wichtig:** Auf echtem Gerät oder Simulator testen — Tab-Switch funktioniert sauber, kein Layout-Glitch. Bartosz bestätigt.

---

## Step 7 — SummaryViewModel.swift erweitern

### Aufgabe
`recoveryAnalysis` Property + Recompute-Aufruf integrieren.

### Konkrete Änderungen
1. Neue Property:
```swift
private(set) var recoveryAnalysis: MuscleRecoveryAnalysis?
```

2. In der bestehenden `recalculate(...)`-Methode (oder dem entsprechenden Recompute-Pfad):
```swift
recoveryAnalysis = MuscleRecoveryCalcEngine.analyze(sessions: strengthSessions)
```

### Validierung
- Property ist `private(set)` und in der View lesbar
- Keine bestehenden Berechnungen brechen

### STOPP-Gate
Build prüfen. Noch keine UI-Änderung — nur Datenfluss.

---

## Step 8 — SummaryView.swift erweitern

### Aufgabe
`MuscleRecoveryCard` direkt nach `ReadinessSummaryCard` einfügen.

### Konkrete Änderungen
Nach diesem bestehenden Block in `SummaryView.swift`:
```swift
// 1b. Readiness-Card der letzten Session
if let readiness = latestSessionReadiness {
    ReadinessSummaryCard(readiness: readiness)
}
```

Direkt darunter einfügen:
```swift
// 1c. Muscle-Recovery Vorschau
if let recovery = viewModel.recoveryAnalysis {
    MuscleRecoveryCard(analysis: recovery, style: .compact) {
        showMuscleRecoveryDetail = true
    }
}
```

Plus passender `@State private var showMuscleRecoveryDetail = false` und `.sheet(isPresented: ...)` mit `MuscleRecoveryDetailView`.

### Validierung
- Card erscheint korrekt nach ReadinessSummaryCard
- Tap öffnet Detail-Sheet
- Layout in beiden Modi (mit/ohne Recovery-Daten) sauber

### STOPP-Gate
**Visuell auf echtem Gerät testen.** Bartosz prüft Layout und Tap-Verhalten. Erst nach OK weiter mit Supabase-Teil.

---

## Step 9 — Supabase-Migration

### Aufgabe
Tabelle `muscle_recovery_snapshots` im `motioncore`-Schema anlegen.

### Vorgehen
Verwende **Supabase MCP** (`apply_migration`). Project ID: `jeebptrnhjekwtviecvz`.

### Migration-SQL
```sql
CREATE TABLE motioncore.muscle_recovery_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    captured_at TIMESTAMPTZ NOT NULL,
    snapshot_date DATE NOT NULL,
    trigger_source TEXT NOT NULL,

    chest_recovery NUMERIC(5,2) NOT NULL,
    back_recovery NUMERIC(5,2) NOT NULL,
    shoulders_recovery NUMERIC(5,2) NOT NULL,
    arms_recovery NUMERIC(5,2) NOT NULL,
    legs_recovery NUMERIC(5,2) NOT NULL,
    core_recovery NUMERIC(5,2) NOT NULL,
    glutes_recovery NUMERIC(5,2) NOT NULL,

    chest_trained BOOLEAN NOT NULL DEFAULT FALSE,
    back_trained BOOLEAN NOT NULL DEFAULT FALSE,
    shoulders_trained BOOLEAN NOT NULL DEFAULT FALSE,
    arms_trained BOOLEAN NOT NULL DEFAULT FALSE,
    legs_trained BOOLEAN NOT NULL DEFAULT FALSE,
    core_trained BOOLEAN NOT NULL DEFAULT FALSE,
    glutes_trained BOOLEAN NOT NULL DEFAULT FALSE,

    overall_recovery NUMERIC(5,2) NOT NULL,
    timeframe_days INT NOT NULL DEFAULT 14,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_muscle_recovery_captured_at
    ON motioncore.muscle_recovery_snapshots(captured_at DESC);
CREATE INDEX idx_muscle_recovery_snapshot_date
    ON motioncore.muscle_recovery_snapshots(snapshot_date DESC);
```

> **Hinweis:** Die Spalte `related_session_uuid` aus früheren Versionen wird NICHT mehr benötigt.

### Validierung
- Migration läuft fehlerfrei durch
- Mit `list_tables` im `motioncore`-Schema verifizieren

### STOPP-Gate
Bartosz bestätigt Schema in Supabase-Dashboard.

---

## Step 10 — DTO + Service

### Aufgabe
Lege `SupabaseMuscleRecoverySnapshotDTO` und `SupabaseMuscleRecoveryService` an.

### SupabaseMuscleRecoverySnapshot.swift
- `Encodable` struct mit `CodingKeys` für snake_case Mapping (analog `SupabaseSessionReadinessDTO`)
- Felder 1:1 zur Tabelle
- KEIN `related_session_uuid` Feld

### SupabaseMuscleRecoveryService.swift
- Singleton `static let shared`
- `@MainActor final class`
- Methode: `func uploadSnapshot(analysis: MuscleRecoveryAnalysis, triggerSource: String) async`
- Logik:
  1. DTO aus `analysis` bauen (alle 7 MuscleGroup-Werte + `_trained` Flags)
  2. `try await client.insert(endpoint: "motioncore.muscle_recovery_snapshots", body: dto)`
  3. Bei Fehler: `#if DEBUG print(...)`, NICHT crashen, NICHT throwen
- **Keine** Dedup-Logik im Service — der Tag-Check passiert im Trigger-Pfad (Step 11).

### Validierung
- DTO kompiliert
- Service nutzt `SupabaseClient.shared` analog bestehender Services
- Service ist absolut "fire and forget" — kein UI-blockierendes Verhalten möglich

### STOPP-Gate
Build prüfen.

---

## Step 11 — App-Open-Trigger in BaseView.swift

### Aufgabe
Snapshot-Trigger so einbauen, dass beim ersten App-Open ab 6:00 morgens am Tag ein Snapshot nach Supabase geschickt wird.

### Konkrete Änderungen in BaseView.swift

**1. State für scenePhase nutzen (existiert bereits):**
```swift
@Environment(\.scenePhase) private var scenePhase
@Environment(\.modelContext) private var context
```

**2. Trigger-Methode hinzufügen:**
```swift
private func triggerDailyMuscleRecoverySnapshotIfNeeded() {
    let key = "lastMuscleRecoverySnapshotDate"
    let last = UserDefaults.standard.object(forKey: key) as? Date

    let calendar = Calendar.current
    guard let todaySixAM = calendar.date(
        bySettingHour: 6, minute: 0, second: 0, of: Date()
    ) else { return }

    // Nur wenn noch kein Snapshot seit heute 6:00 morgens existiert
    if let last, last >= todaySixAM { return }

    Task {
        let descriptor = FetchDescriptor<StrengthSession>(
            predicate: #Predicate { $0.isCompleted }
        )
        let sessions = (try? context.fetch(descriptor)) ?? []
        let analysis = MuscleRecoveryCalcEngine.analyze(sessions: sessions)

        await SupabaseMuscleRecoveryService.shared.uploadSnapshot(
            analysis: analysis,
            triggerSource: "app_open"
        )
        UserDefaults.standard.set(Date(), forKey: key)
    }
}
```

**3. Trigger an scenePhase-Wechsel binden:**
Im bestehenden `.onChange(of: scenePhase)`-Modifier oder neu anlegen:
```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        triggerDailyMuscleRecoverySnapshotIfNeeded()
    }
}
```

Falls bereits ein `.onChange(of: scenePhase)` existiert: den Aufruf darin ergänzen, nicht duplizieren.

**4. Auch beim ersten Start (App-Launch) triggern:**
Im `.onAppear` oder `.task` der `TabView` einmalig aufrufen, falls scenePhase-Trigger den initialen Launch nicht abdeckt. Falls `.onAppear` verwendet wird: einfach `triggerDailyMuscleRecoverySnapshotIfNeeded()` aufrufen.

### Validierung
- UserDefaults-Key wird korrekt gesetzt nach erfolgreichem Upload
- Bei Supabase-Fehler bleibt der Key auf altem Wert (nächster App-Open versucht erneut)
- Logik berücksichtigt 6:00-Uhr-Schwelle korrekt
- Keine Doppel-Inserts bei mehrfachem scenePhase-Wechsel innerhalb eines Tages

### STOPP-Gate (final)
**End-to-End-Test mit Bartosz:**

**Test 1 — Erster Launch des Tages:**
1. UserDefaults-Key löschen (Simulator-Reset oder via Code)
2. App öffnen
3. → Erwartung: 1 Snapshot in Supabase, `trigger_source = "app_open"`

**Test 2 — Wiederholtes Öffnen am gleichen Tag:**
1. App schließen
2. Sofort nochmal öffnen
3. → Erwartung: KEIN neuer Snapshot (Tag-Check greift)

**Test 3 — UI-Refresh:**
1. App offen lassen, Body-Tab öffnen
2. Score notieren
3. App in Background, 30 Sekunden warten, zurückwechseln
4. → Erwartung: Score wird neu berechnet (sichtbar bei Stoppen einer Console-Log-Ausgabe in `recalculate`, falls eine drin ist — ansonsten still und unsichtbar)

**Test 4 — UI-Konsistenz:**
1. SummaryView öffnen, Recovery-Vorschau-Card sichtbar
2. Tap auf Card → Detail-Sheet öffnet sich
3. Body-Tab öffnen → größere Card mit gleichen Werten
4. → Erwartung: Werte zwischen Vorschau und Body-Tab konsistent

---

## Schritt-Übersicht (Quick Reference)

| # | Datei(en) | Art | STOPP danach? |
|---|---|---|---|
| 1 | `MuscleRecoveryTypes.swift` | NEU | Ja |
| 2 | `MuscleRecoveryCalcEngine.swift` | NEU | Ja |
| 3 | `MuscleRecoveryDonut.swift`, `MuscleRecoveryCard.swift` | NEU | Ja |
| 4 | `MuscleRecoveryDetailView.swift` | NEU | Ja |
| 5 | `BodyViewModel.swift`, `BodyView.swift` | NEU | Ja |
| 6 | `BaseView.swift` (Tab einfügen) | EDIT | **Ja (visuell)** |
| 7 | `SummaryViewModel.swift` | EDIT | Ja |
| 8 | `SummaryView.swift` | EDIT | **Ja (visuell)** |
| 9 | Supabase-Migration | DB | Ja |
| 10 | `SupabaseMuscleRecoverySnapshot.swift`, `SupabaseMuscleRecoveryService.swift` | NEU | Ja |
| 11 | `BaseView.swift` (App-Open-Trigger) | EDIT | **End-to-End-Test** |

---

## Was NICHT Teil dieser Instruction ist

- TrainingDetailView-Integration (`PlanRecoveryAnalysis`)
- ActiveWorkoutView Recovery-Header
- Adaptive Lernlogik (Phase 2)
- SwiftData-lokale Persistenz
- Body-Composition-Cards
- Backfill historischer Snapshots in Supabase
- Session-Complete-Trigger (bewusst entfernt — siehe Konzept v3 Abschnitt 7.2)

Diese werden separat geplant, falls relevant.

---

## Review-Checkliste pro Step (für quality-gate)

- [ ] Datei-Header ist korrekt (Format, Datum, Beschreibung)
- [ ] Datei unter 400 Zeilen (oder begründet darüber)
- [ ] CalcEngine ist pure struct, keine Side-Effects
- [ ] Keine `print`-Statements im finalen Code (Ausnahme: `#if DEBUG`-Blöcke)
- [ ] Preview vorhanden bei View-Dateien
- [ ] German UI-Texte, English variable names, German comments
- [ ] `.glassCard()` für Cards, `EmptyState()` für leere Zustände
- [ ] Bestehende Patterns konsistent verwendet (`@Observable`, `.task`, etc.)
- [ ] Keine Veränderung an `ExerciseRating` oder `PlanUpdateCalcEngine`
- [ ] Refresh-Trigger in BodyView aktiv (`.task` + `.onChange(scenePhase)`)
- [ ] App-Open-Trigger berücksichtigt 6:00-Uhr-Schwelle
- [ ] Service "fire and forget" — kein Crash, kein UI-Block bei Supabase-Fehler
