# Supabase Full-Backup Service

**Complexity:** Large

## Summary

Implementierung eines `SupabaseFullBackupService`, der alle lokalen SwiftData-Daten vollständig nach Supabase hochlädt: alle Sessions (Strength, Cardio, Outdoor), alle TrainingPlans und alle ExerciseSets (Session-Sets UND Template-Sets). Idempotent durch UPSERT, manuell aufrufbar über einen Button in den Einstellungen.

## Scope

- **Enthalten**: Supabase-Schema-Änderung (SQL), DTO-Anpassung (`sessionId` optional), neuer Service (`SupabaseFullBackupService`), neue UI-Section (`SupabaseFullBackupSection`), Einbindung in `MainSettingsView`
- **Nicht enthalten**: Automatischer Backup-Trigger, Restore/Download von Supabase, Änderungen an `SupabaseMigrationService` oder `SupabaseResyncService`

## UX Placement

- **Ort**: `MainSettingsView`, als eigene Section unterhalb der bestehenden `SupabaseSyncSection`
- **Einstiegspunkt**: Button "Vollständiges Backup starten" mit Fortschrittsanzeige
- **Begründung**: Trennung von "historische Migration" (bestehend) und "Full Backup" (neu) — unterschiedliche Verantwortlichkeiten, klar getrennt für den Benutzer

## Affected Files

- **Supabase Dashboard** (manuell) — `ALTER TABLE exercise_sets ALTER COLUMN session_id DROP NOT NULL`
- `MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift` — `sessionId: UUID` → `UUID?` in `SupabaseExerciseSetDTO`
- `MotionCore/Services/Database/Remote/Session/SupabaseFullBackupService.swift` — **NEU**: kompletter Backup-Service mit Progress-Tracking
- `MotionCore/Views/Settings/Components/SupabaseFullBackupSection.swift` — **NEU**: UI-Section für den Backup-Button + Fortschritt
- `MotionCore/Views/Settings/View/MainSettingsView.swift` — Einbindung von `SupabaseFullBackupSection` unterhalb `SupabaseSyncSection`

## Risks

- **Schema-Änderung muss ZUERST erfolgen**: Ohne `session_id DROP NOT NULL` schlagen Template-Set-Uploads fehl (Supabase gibt 400/409)
- **Batch-Größe**: Chunking in 50er-Batches verhindert Payload-Limit-Überschreitung
- **DTO-Änderung rückwärtskompatibel**: `sessionId: UUID?` — bestehender `SupabaseSessionService` übergibt immer non-nil UUID
- **Kein Datenverlust**: Service führt nur INSERT/UPDATE aus, nie DELETE

## Implementation Steps

### Vorbereitung: Supabase Schema-Änderung (manuell)

- [ ] **0.1** Im Supabase Dashboard SQL ausführen:
  ```sql
  ALTER TABLE public.exercise_sets ALTER COLUMN session_id DROP NOT NULL;
  ```
  Verifizieren: `SELECT is_nullable FROM information_schema.columns WHERE table_name = 'exercise_sets' AND column_name = 'session_id';` → muss `YES` zurückgeben.

### Phase 1: DTO-Anpassung

- [x] **1.1** In `SupabaseSessionModels.swift`: `let sessionId: UUID` → `let sessionId: UUID?` in `SupabaseExerciseSetDTO`. Keine weiteren Änderungen nötig.

### Phase 2: SupabaseFullBackupService erstellen

- [x] **2.1** Neue Datei `MotionCore/Services/Database/Remote/Session/SupabaseFullBackupService.swift` erstellen.

- [x] **2.2** Klasse: `@MainActor final class SupabaseFullBackupService: ObservableObject` mit `static let shared`, `private let client = SupabaseClient.shared`.

- [x] **2.3** Progress-Tracking:
  - `@Published var isRunning: Bool = false`
  - `@Published var progress: BackupProgress = .idle`
  - `BackupProgress` Enum: `.idle`, `.running(step: String, current: Int, total: Int)`, `.completed(stats: BackupStats)`, `.failed(error: String)` (Equatable)
  - `BackupStats` Struct: `strengthSessions`, `cardioSessions`, `outdoorSessions`, `trainingPlans`, `exerciseSets`, `templateSets` (alle Int, Equatable)

- [x] **2.4** `func runFullBackup(context: ModelContext) async` implementieren:
  - Guard `!isRunning`
  - Reihenfolge: (1) TrainingPlans, (2) StrengthSessions + deren Sets, (3) CardioSessions, (4) OutdoorSessions, (5) Template-Sets
  - TrainingPlans MÜSSEN zuerst (Foreign Key `training_plan_id` in `exercise_sets`)
  - Am Ende: `try? context.save()`, `progress = .completed(stats:)`
  - Bei Fehler: `progress = .failed(error:)`, `isRunning = false`

- [x] **2.5** Private Upload-Methoden:
  - `uploadAllTrainingPlans(context:) -> Int`: bestehenden `SupabaseTrainingPlanDTO` verwenden, `plan.syncedToSupabase = true`
  - `uploadAllStrengthSessions(context:) -> (sessions: Int, sets: Int)`: StrengthSession DTO + `safeExerciseSets` in 50er-Batches, `session.syncedToSupabase = true`, `needsSupabaseResync = false`
  - `uploadAllCardioSessions(context:) -> Int`: analog zu bestehendem Service
  - `uploadAllOutdoorSessions(context:) -> Int`: analog zu bestehendem Service
  - `uploadAllTemplateSets(context:) -> Int`: Filter `trainingPlan != nil && session == nil`, `sessionId: nil`, `trainingPlanId: plan.planUUID`, 50er-Batches

- [x] **2.6** Chunking-Hilfsmethode: `private func uploadInChunks(_ dtos: [SupabaseExerciseSetDTO], chunkSize: Int = 50) async throws`

### Phase 3: UI-Section erstellen

- [x] **3.1** Neue Datei `MotionCore/Views/Settings/Components/SupabaseFullBackupSection.swift`.

- [x] **3.2** `SupabaseFullBackupSection: View`:
  - `@Environment(\.modelContext)` + `@ObservedObject private var service = SupabaseFullBackupService.shared`
  - Section "Supabase Full-Backup":
    - **Idle**: Button "Vollständiges Backup starten" mit `icloud.and.arrow.up` Icon
    - **Running**: `ProgressView` + Step-Text + "(current/total)"
    - **Completed**: Grüner Haken + Zusammenfassung (Kraft/Cardio/Outdoor/Pläne/Template-Sets)
    - **Failed**: Rote Fehlermeldung
  - Button disabled wenn `service.isRunning`

### Phase 4: MainSettingsView-Integration

- [x] **4.1** In `MainSettingsView.swift` nach `SupabaseSyncSection()`: `SupabaseFullBackupSection()` einfügen.

### Phase 5: Xcode-Target

- [ ] **5.1** Beide neuen Dateien manuell zum Xcode-Target hinzufügen: `SupabaseFullBackupService.swift`, `SupabaseFullBackupSection.swift`

## Manual Verification

- [x] Xcode Build (`Cmd+B`) — keine Kompilierfehler
- [x] Supabase Dashboard: `session_id` in `exercise_sets` ist NULLABLE
- [x] "Supabase Full-Backup" Section erscheint in den Einstellungen unterhalb "Supabase Sync"
- [x] Fortschritt wird während des Backups angezeigt (Step-Name + Zähler)
- [x] Nach Abschluss: grüne Zusammenfassung mit Anzahlen
- [x] Supabase Dashboard: `exercise_sets` enthält Einträge mit `session_id IS NULL` (Template-Sets)
- [x] Bestehende `SupabaseSyncSection` funktioniert weiterhin (Regression-Check)
- [x] Erneutes Ausführen: idempotent, keine Duplikate
- [x] Xcode-Target: beide neuen Dateien manuell hinzugefügt

---

## Implementierungsfortschritt

**Status:** ✅ ABGESCHLOSSEN

**Backup-Ergebnis (zweiter Lauf, nach CloudKit-Sync):**
- 7 Trainingspläne, 32 Krafttrainings, 49 Cardio-Sessions, 992 Sets, 209 Template-Sets

**Erkenntnisse:**
- Erster Backup-Lauf zeigte nur 2/7 Pläne: CloudKit-Timing-Problem — die anderen 5 Pläne waren noch nicht im lokalen SwiftData-Store (noch von iCloud ausstehend).
- Nach vollständigem CloudKit-Sync: alle 7 Pläne + 209 Template-Sets korrekt gesichert.
- Diagnose-Logging in `uploadAllTrainingPlans` und `uploadAllTemplateSets` hinzugefügt (permanente Prints für zukünftige Nachvollziehbarkeit).
