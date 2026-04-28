# Plan: Erweiterte TrainingPlan-Verwaltung

**Komplexität:** Large
**Implementierungsmodus:** Phased (Schritt 0 Audit + 11 Schritte mit STOPP-Gates)
**Status:** Planung abgeschlossen — alle Open Questions geklärt, bereit für Implementierung
**Konzept-Quelle:** `Documentation/Concepts/MotionCore_TrainingPlan-Management_Concept.md` (mit 3 ergänzten Sektionen 3.6, 4.4, 6.1 zur Integration des externen Imports von `motioncore.barto.cloud`)
**Erstellt:** 2026-04-28

## Summary

Zwei neue Plan-Verwaltungs-Features plus Schließung einer bestehenden Lücke beim externen Plan-Import:

1. **Option A — Plan aus Session aktualisieren:** User-getriebener 1:1-Diff zwischen abgeschlossener `StrengthSession` und ihrem `sourceTrainingPlan`, mit Sheet, Checkboxen, Snapshot-basiertem 72h-Undo.
2. **Option B Enhancement — Smart-Trend:** ≥2/3-Schwelle für `.exerciseAdded`, plus Hinweis-Text im bestehenden `PlanUpdateSheet`.
3. **Plan duplizieren:** Direkter Klon mit `(Kopie)`-Suffix, geteilter `ExerciseProgressionState` über `exerciseGroupKey`.
4. **Externe Import-Lücke schließen:** `ProgressionStateEnsurer` greift nach `PlanImportManager.acceptImport()` — initialisiert `workingWeight` aus Template-Sets.

Beide Pfade (A + B) enden im selben `PlanUpdateApplicator` und im neuen `ProgressionStateEnsurer`. Snapshot-Undo lebt nur lokal auf dem `TrainingPlan`-Record.

## Scope

### Included

- 5 neue Dateien (CalcEngine, Sheet, 2 Services, Banner)
- 9 geänderte Dateien (TrainingPlan-Schema, PlanUpdateApplicator, PlanUpdateCalcEngine, PlanUpdateSheet, PlanActionsSection, TrainingDetailView, StrengthDetailView, PlanImportManager, ggf. Supabase-Backup-DTO)
- Schema-Erweiterung TrainingPlan: `lastSyncSnapshotJSON: String?`, `lastSessionSyncDate: Date?`, `lastSessionSyncSourceUUID: String?`
- `reindexSortOrders()` von `private` auf `internal`
- Neuer Enum-Case `PlanUpdateChangeType.exerciseRemoved`

### Explicitly Excluded

- Rückspielung lokaler Änderungen nach `motioncore.barto.cloud` (One-Way-Import bleibt one-way, siehe Konzept Sektion 6.1)
- Migration alter Pläne (kein Backfill — Undo-Felder bleiben für Bestandspläne `nil`)
- Änderungen am `AutoProgressionApplier` / `AutoProgressionCalcEngine` / `ExerciseProgressionState`-Schema
- Multi-Session-Diff (Option A bleibt 1:1 zur einzelnen Session)
- Änderungen am externen `pending_plan_imports`-Status-Flow

## UX Placement

### Option A — "Plan aus Session aktualisieren"

- **Standort:** `StrengthDetailView` → `actionsSection`
- **Entry-Point:** Button, sichtbar nur wenn `session.sourceTrainingPlan != nil && session.isCompleted`
- **Sheet:** `SessionPlanSyncSheet` (eigenes Sheet, nicht `PlanUpdateSheet`-Reuse — Kontext zu unterschiedlich, gemäß Konzept 6)
- **Pattern:** `.sheet(item: $syncContext)` mit `Identifiable`-Wrapper-Struct, **niemals** `.sheet(isPresented:)` (siehe `tasks/lessons.md`)

### Option A — Undo-Banner

- **Standort:** `TrainingDetailView`, direkt unter dem bestehenden `PlanUpdateBanner`-Slot (zwei Banner-Slots untereinander)
- **Entry-Point:** automatisch sichtbar wenn `SessionSyncUndoService.isUndoAvailable(for: plan)` true (Snapshot vorhanden + `lastSessionSyncDate` < 72h)
- **Aktionen:** "Rückgängig" / "Verwerfen"

### Plan duplizieren

- **Standort:** `PlanActionsSection` in `TrainingDetailView`, neuer Button neben den bestehenden Aktionen
- **Verhalten:** sofortige Aktion ohne Bestätigungs-Dialog, Toast/Banner-Feedback
- **Open Decision:** Navigation nach Duplizieren — siehe Open Questions

### Rejected Alternatives

- **Reuse `PlanUpdateSheet` für Option A** verworfen: Single-Session-Diff hat andere Semantik als Trend-Aggregat (entfernte Übungen, vorselektierte Felder anders)
- **Confirm-Dialog vor Duplizieren** verworfen: Aktion ist reversibel (Plan löschbar)
- **Aktiv-Wechsel auf Kopie nach Duplizieren** verworfen: Kopie ist `isActive: true`, Original bleibt unangetastet — User entscheidet selbst über Wechsel

## Affected Files

### Neue Dateien

- `MotionCore/Services/Calculation/SessionPlanSyncCalcEngine.swift` — Pure CalcEngine, Vergleich `StrengthSession` ↔ `TrainingPlan`, liefert `PlanUpdateProposal`
- `MotionCore/Services/Plan/ProgressionStateEnsurer.swift` — Stellt `ExerciseProgressionState` für jede Übung im Plan sicher (statisch, idempotent)
- `MotionCore/Services/Plan/SessionSyncUndoService.swift` — Snapshot-Capture, JSON-(De)Serialisierung, Undo-Restore, 72h-Check
- `MotionCore/Views/Strength/Detail/SessionPlanSyncSheet.swift` — Diff-Sheet mit Checkboxen, gruppiert nach Kategorie
- `MotionCore/Views/Training/Detail/SessionSyncUndoBanner.swift` — Kompakter Banner mit "Rückgängig"/"Verwerfen"

### Geänderte Dateien

- `MotionCore/Models/Core/TrainingPlan.swift`
  - 3 neue Felder mit `nil`-Defaults (siehe CloudKit-Hinweis unten)
  - `reindexSortOrders()` von `private` → `internal`
  - neue `duplicate(context:) -> TrainingPlan`-Extension
- `MotionCore/Services/Calculation/PlanUpdateApplicator.swift` — neuer `case .exerciseRemoved` im Switch, Aufruf von `plan.reindexSortOrders()` nach Lösch-Loop, Aufruf von `ProgressionStateEnsurer.ensureStates(...)` am Ende
- `MotionCore/Services/Calculation/PlanUpdateCalcEngine.swift` — `detectNewExercises()`: Schwelle auf `ceil(sessions.count * 2/3)` (konsistent mit anderen Trend-Methoden)
- `MotionCore/Views/Training/PlanUpdateSheet.swift` — Bei `.exerciseAdded` Hinweistext "in X von Y Sessions trainiert"
- `MotionCore/Models/Core/PlanUpdateTypes.swift` — neuer Case `.exerciseRemoved`, ggf. `PlanUpdateChange.metadata: PlanUpdateChangeMetadata?`
- `MotionCore/Views/Strength/Detail/StrengthDetailView.swift` — Button + `@State var syncContext: SessionPlanSyncContext?` + `.sheet(item:)`
- `MotionCore/Views/Training/Detail/PlanActionsSection.swift` — neuer "Duplizieren"-Button mit `onDuplicate: () -> Void` Callback
- `MotionCore/Views/Training/Detail/TrainingDetailView.swift` — Duplikat-Callback, Undo-Banner einhängen, Toast nach Duplizieren
- `MotionCore/Services/.../PlanImportManager.swift` — am Ende von `acceptImport()` Aufruf `ProgressionStateEnsurer.ensureStates(forPlan: newPlan, sessionSets: nil, context: context)`
- **Optional, falls vorhanden:** Supabase-DTO/CodingKeys für `TrainingPlan` (Backup) — 3 neue Felder explizit listen (siehe Risiken)

## Risks

### CloudKit / Schema

- **CloudKit UUID Default Bug NICHT relevant hier:** Die 3 neuen Felder sind `String?`/`Date?`/`String?` — keine `UUID`-Defaults, keine Schema-Migration-Falle. Trotzdem vor Merge prüfen, dass alle drei mit `= nil` initialisiert werden (CloudKit verlangt Defaults oder Optionals).
- **Kein `deduplicateAllSyncUUIDs()` nötig**, da kein neues UUID-Feld eingeführt wird (`planUUID` bleibt unangetastet).
- **Schema-Migration-Risiko gering:** Nur Optionale hinzugefügt, keine bestehenden Felder geändert. Bestehende CloudKit-Records blieben unverändert.

### Supabase CodingKeys-Trap

- Falls TrainingPlan-Backup-DTO ein `CodingKeys`-Enum nutzt: **alle 3 neuen Felder explizit listen**, sonst silent missing im Voll-Backup. Zu prüfen in Schritt 0 bzw. Schritt 5.

### Reindex-Sichtbarkeit

- `reindexSortOrders()` von `private` → `internal` erlaubt Aufruf aus `PlanUpdateApplicator`. Konzept-Vorgabe. Niedriges Risiko.

### Snapshot-JSON-Codable-Kompatibilität

- `ExerciseSetSnapshot` muss `Codable` sein. **Verifizieren in Schritt 0:** Datei lesen, falls nicht — Conformance hinzufügen.
- **JSON-Größe:** typischer Plan mit 30 Sets → ~6–10 KB JSON-String. Akzeptabel für CloudKit-String-Felder.
- **JSON-Versionierung:** Snapshot-Format bekommt einen `version: Int = 1` als Top-Level-Feld in einem Wrapper-Struct, damit zukünftige `ExerciseSetSnapshot`-Erweiterungen Decode-Failures zu lokalem Verwerfen führen (Undo "abgelaufen"-Fallback) statt Crashes.

### PlanUpdateApplicator-Aufrufpattern

- **Audit-Befund (Planner):** `PlanUpdateApplicator` ist `struct` mit `static func apply(...)`. Existierender Aufrufer: `PlanUpdateSheet`. Neuer Aufrufer: `SessionPlanSyncSheet` mit identischer Signatur.
- **Tracking-Felder:** `lastUpdatedFromSession` und `lastUpdateSourceSessionUUID` werden bereits im Applicator gesetzt — Option A nutzt diese **zusätzlich** zu den drei neuen Undo-Feldern. Doppelte Quelle für Sync-Datum: bewusst (`lastUpdatedFromSession` für Option-B-Trend-Filter, `lastSessionSyncDate` für Undo-Ablauf).

### Hinweistext "X von Y Sessions"

- Heute trägt `PlanUpdateChange` keinen `sessionOccurrenceCount`. **Empfehlung:** `PlanUpdateChange` um optionales `metadata: PlanUpdateChangeMetadata?` erweitern (Default `nil`, additiv, bricht keine Aufrufer).

### Regression-Risiken

- `PlanUpdateBanner` (Option B) zeigt nach Aktivierung der ≥2/3-Schwelle ggf. weniger Vorschläge als heute. **Bestätigen:** ist gewollt.
- `AutoProgressionApplier` darf nicht durch neuen `ProgressionStateEnsurer`-Aufruf doppelt initialisieren — Ensurer muss idempotent sein (nur fehlende States anlegen, vorhandene unverändert lassen).
- Externer Import: heute kein `ExerciseProgressionState` für importierte Pläne. Nach diesem Feature werden Bestands-Pläne erst beim nächsten Import-Trigger initialisiert. **Backfill-Empfehlung:** App-Start einmaliger Pass über alle `TrainingPlan` ohne States — siehe Open Questions.

## Implementation Steps

### Schritt 0: Audit (vorbereitend, kein Code-Change)

- [x] `PlanUpdateApplicator.apply(...)`-Signatur und Call-Sites geprüft (struct + static, ein Aufrufer in `PlanUpdateSheet`)
- [x] `ExerciseSetSnapshot.swift` lesen — war NICHT `Codable`; Conformance in Schritt 5 hinzugefügt
- [x] `PlanUpdateChange` lesen — Erweiterung um optionales `metadata` problemlos möglich (Default-Parameter)
- [x] Supabase-DTO `SupabaseTrainingPlanDTO` hat explizites `CodingKeys`-Enum — alle 3 neuen Felder in Schritt 5 ergänzt
- [x] `PlanImportManager.acceptImport()` gelesen — Ensurer-Aufruf nach erstem `try context.save()` in Schritt 4 eingefügt
- **Audit-Notizen:** `detectNewExercises()` hatte alte Schwelle `sessions.count == 1 ? 1 : 2` (statt 2/3); `reindexSortOrders()` war `private`

### Schritt 1: PlanUpdateTypes erweitern

- [x] `PlanUpdateChangeType`-Enum: neuer Case `case exerciseRemoved`
- [x] `PlanUpdateChange` um `metadata: PlanUpdateChangeMetadata? = nil` erweitert
- [x] `PlanUpdateChangeRow.swift` Switch-Cases um `.exerciseRemoved` ergänzt
- **Build grün**

### Schritt 2: PlanUpdateApplicator erweitern + reindex internal

- [x] `TrainingPlan.reindexSortOrders()` von `private` auf `internal`
- [x] In `PlanUpdateApplicator.apply(...)`: neuer Case `.exerciseRemoved` mit Delete-Loop und `reindexSortOrders()`
- [x] `ProgressionStateEnsurer.ensureStates(...)` am Ende von `apply()` (gemeinsam mit Schritt 4 implementiert)
- **Build grün**

### Schritt 3: SessionPlanSyncCalcEngine

- [x] Neue Datei `Services/Calculation/SessionPlanSyncCalcEngine.swift`
- [x] `analyze(session:plan:)` → 3 Kategorien: exerciseAdded (vorselektiert), weightUpdate/setCountUpdate (Erhöhung vorselektiert), exerciseRemoved (nicht vorselektiert)
- [x] Modus-Gewicht der Session als Vergleichswert
- **Build grün**

### Schritt 4: ProgressionStateEnsurer + Integration

- [x] Neue Datei `Services/Plan/ProgressionStateEnsurer.swift`
- [x] `ensureStates(forPlan:sessionSets:context:)` — idempotent, Modus-Gewicht als initialWeight
- [x] In `PlanUpdateApplicator.apply(...)` am Ende: Ensurer aufgerufen
- [x] In `PlanImportManager.acceptImport(...)` nach erstem Save: Ensurer aufgerufen
- **Build grün**

### Schritt 4.5: App-Start-Backfill für Bestandspläne

- [x] In `MotionCoreApp.swift`: `backfillProgressionStates(context:)` im `.task`-Block nach Seedern
- [x] Fetcht alle `TrainingPlan`, ruft Ensurer für jeden auf (idempotent)
- **Build grün**

### Schritt 5: TrainingPlan-Schema + SessionSyncUndoService

- [x] `TrainingPlan.swift`: 3 neue Felder `lastSyncSnapshotJSON`, `lastSessionSyncDate`, `lastSessionSyncSourceUUID` (alle `= nil`)
- [x] `ExerciseSetSnapshot`: `Codable`-Conformance hinzugefügt (`SetKind` war bereits `Codable`)
- [x] `SupabaseTrainingPlanDTO`: 3 neue Felder + CodingKeys ergänzt; beide Aufrufer (SessionService + FullBackupService) aktualisiert
- [x] Neue Datei `Services/Plan/SessionSyncUndoService.swift` mit `captureSnapshot`, `undo`, `isUndoAvailable`, `discard`; versioned JSON-Wrapper
- **Build grün**

### Schritt 6: SessionPlanSyncSheet (UI)

- [x] Neue Datei `Views/Workouts/Sheets/SessionPlanSyncSheet.swift`
- [x] `SessionPlanSyncContext: Identifiable` Wrapper-Struct
- [x] Sheet mit 3 Sections (Neue Übungen / Geändert / Nicht trainiert), Leerzustand, Apply-Aktion
- [x] Snapshot VOR Apply, dann Apply, dann `lastSessionSyncDate` setzen, dann save, dann dismiss
- **Build grün**

### Schritt 7: StrengthDetailView Integration

- [x] `@State private var syncContext: SessionPlanSyncContext?` hinzugefügt
- [x] Button "Plan aus Session aktualisieren" in `actionsSection` (sichtbar wenn `sourceTrainingPlan != nil && isCompleted`)
- [x] `.sheet(item: $syncContext)` mit `SessionPlanSyncSheet`
- **Build grün — MANUELLER TEST ERFORDERLICH**

### Schritt 8: Undo-Banner

- [x] Neue Datei `Views/Training/PlanUpdate/SessionSyncUndoBanner.swift`
- [x] Banner mit "Rückgängig" (→ `undo`) und "Verwerfen" (→ `discard`) Buttons
- [x] In `TrainingDetailView`: unter `PlanUpdateBanner` einhängen, `@State private var showUndoBanner: Bool`
- **Build grün — MANUELLER TEST ERFORDERLICH**

### Schritt 9: Plan duplizieren

- [x] `TrainingPlan.duplicate(context:)` Extension: Kopie mit neuem UUID, `(Kopie)`-Suffix, alle Undo-Felder nil, Sets geklont
- [x] `PlanActionsSection.swift`: `onDuplicate: () -> Void` Callback + "Plan duplizieren"-Button
- [x] `TrainingDetailView.swift`: `duplicatePlan()` + Auto-schließender Toast nach 4s
- **Build grün — MANUELLER TEST ERFORDERLICH**

### Schritt 10: Option B Enhancement

- [x] `PlanUpdateCalcEngine.detectNewExercises()`: Schwelle auf `max(1, Int(ceil(Double(sessions.count) * 2.0 / 3.0)))`
- [x] `PlanUpdateChangeMetadata` mit `sessionOccurrences` und `sessionsAnalyzed` in `detectNewExercises()` gesetzt
- [x] `PlanUpdateChangeRow.swift`: Hinweistext "In X von Y Sessions trainiert" bei `.exerciseAdded` mit Metadata
- **Build grün**

### Schritt 11: Regression-Check + Final Review

- [x] Finaler Build grün, keine Compiler-Errors oder Warnings
- [ ] Bestehende Option-B-Banner: manuell testen
- [ ] Option A E2E: manuell testen
- [ ] Undo E2E: manuell testen
- [ ] Plan duplizieren: manuell testen
- [ ] Externer Import: manuell testen
- [ ] Voll-Backup: manuell via SQL prüfen
- **MANUELLER TEST ERFORDERLICH**

## Manual Verification (Final)

- [ ] Xcode `Cmd+B` grün nach jedem Schritt
- [ ] `SessionPlanSyncSheet`-Preview mit `PreviewData.sharedContainer` rendert
- [ ] `SessionSyncUndoBanner`-Preview rendert
- [ ] `PlanUpdateSheet`-Preview rendert mit Hinweistext (Schritt 10)
- [ ] Sim-Flow: Plan → Session → Plan-Update via Sheet → Undo → Plan-Restore
- [ ] Sim-Flow: Plan duplizieren → beide aktiv → Progression in einem ändert sich auch im anderen (geteilter State)
- [ ] Sim-Flow: Externer Import von `motioncore.barto.cloud` → `ExerciseProgressionState` initialisiert
- [ ] CloudKit-Sync zwischen 2 Devices — Schema-Migration prüfen
- [ ] Voll-Backup-Sync: SQL-Query gegen Supabase, ob 3 neue Felder gespeichert sind

## Resolved Decisions

1. **Navigation nach Duplizieren** *(Schritt 9)*: ✅ **Bleiben + Toast.** Keine Navigation, nur kurzer Bestätigungs-Toast mit dem Namen der neuen Kopie.
2. **Undo-Banner-Sichtbarkeit** *(Schritt 8)*: ✅ **Beide Banner gleichzeitig sichtbar.** `PlanUpdateBanner` und `SessionSyncUndoBanner` rendern unabhängig voneinander.
3. **App-Start-Backfill** *(neu Schritt 4.5)*: ✅ **Eingeplant.** Einmaliger Pass über alle `TrainingPlan` beim App-Start, ruft `ProgressionStateEnsurer.ensureStates(...)` für jeden auf. Idempotent, kostet nichts wenn alle States schon existieren.
4. **Hinweistext-Variante** *(Schritt 10)*: ✅ **`PlanUpdateChange.metadata`-Struktur.** Optionales `metadata: PlanUpdateChangeMetadata?` mit `sessionOccurrences` und `sessionsAnalyzed`.
5. **`ProgressionStateEnsurer.sessionSets`-Logik** *(Schritt 4)*: ✅ **Modus.** Für nicht-leere `sessionSets` wird der Modus der Gewichte als initialer `workingWeight` verwendet.

## Progress Log

- 2026-04-28: Konzept-Dokument um Sektionen 3.6, 4.4, 6.1 (externer Import-Integration) erweitert.
- 2026-04-28: Plan vom motioncore-planner erstellt, in `tasks/current.md` abgelegt.
- 2026-04-28: Alle 5 Open Questions geklärt (Empfehlungen übernommen). Schritt 4.5 (App-Start-Backfill) ergänzt. Implementierung gestartet.
- 2026-04-28: Schritte 0–10 implementiert, Schritt 11 Build-Teil abgeschlossen. Alle 11 Schritte Code-Complete, Build grün. Manueller UI-Test durch User erforderlich (Schritte 7, 8, 9, 11).
- 2026-04-28: Quality-Gate-Blocker behoben. (1) `isInfoOnly` in `PlanUpdateChangeRow.swift` gibt nur noch `true` für `.exerciseSkipped` — `.exerciseRemoved`-Toggle ist jetzt schaltbar. (2) `SessionSyncUndoService.discard` hat Signatur `discard(plan:context:)` und ruft `try? context.save()` auf — analog zu `undo`; Call-Site in `SessionSyncUndoBanner.swift` angepasst. Build grün.
