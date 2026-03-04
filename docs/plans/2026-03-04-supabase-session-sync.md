# Supabase Session Sync – Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Alle abgeschlossenen Sessions (StrengthSession, CardioSession, OutdoorSession, TrainingPlan + ExerciseSets) werden sofort nach Abschluss per Upsert zu Supabase hochgeladen.

**Architecture:** Neuer `SupabaseSessionService` (Singleton analog zu `SupabaseExerciseService`) mit `Encodable` DTOs. Upload wird aus dem `ActiveSessionManager` nach `session.complete()` getriggert. CloudKit bleibt unverändert. Kein UI-Impact bei Fehlern (Silent Fail + Log).

**Tech Stack:** SwiftUI, SwiftData, URLSession (custom `SupabaseClient`), Supabase REST API v1

**Auth-Hinweis:** Aktuell keine User-Auth implementiert. `user_id` in den Tabellen ist nullable – wird befüllt wenn Apple Sign-In + Supabase Auth ergänzt wird.

---

## Task 1: Supabase Tabellen anlegen

**Files:**
- Create: `supabase/migrations/20260304_session_sync.sql`

### Schritt 1: SQL-Migrationsdatei schreiben

Erstelle `/Users/bartosz/Developments/MotionCore/supabase/migrations/20260304_session_sync.sql`:

```sql
-- ============================================================
-- MotionCore: Session Sync Tabellen
-- ============================================================

-- 1. training_plans
CREATE TABLE IF NOT EXISTS training_plans (
  id                UUID PRIMARY KEY,
  user_id           UUID,                         -- nullable bis Auth implementiert
  title             TEXT NOT NULL DEFAULT '',
  plan_description  TEXT NOT NULL DEFAULT '',
  start_date        TIMESTAMPTZ NOT NULL,
  end_date          TIMESTAMPTZ,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  plan_type         TEXT NOT NULL DEFAULT 'strength',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. strength_sessions
CREATE TABLE IF NOT EXISTS strength_sessions (
  id                      UUID PRIMARY KEY,
  user_id                 UUID,
  date                    TIMESTAMPTZ NOT NULL,
  duration                INTEGER NOT NULL DEFAULT 0,
  calories                INTEGER NOT NULL DEFAULT 0,
  body_weight             DOUBLE PRECISION NOT NULL DEFAULT 0,
  heart_rate              INTEGER NOT NULL DEFAULT 0,
  max_heart_rate          INTEGER NOT NULL DEFAULT 0,
  notes                   TEXT NOT NULL DEFAULT '',
  workout_type            TEXT NOT NULL DEFAULT 'fullBody',
  intensity               INTEGER NOT NULL DEFAULT 0,
  perceived_exertion      INTEGER,
  energy_level_before     INTEGER,
  is_completed            BOOLEAN NOT NULL DEFAULT FALSE,
  is_live_session         BOOLEAN NOT NULL DEFAULT FALSE,
  started_at              TIMESTAMPTZ,
  completed_at            TIMESTAMPTZ,
  device_source           TEXT NOT NULL DEFAULT 'manual',
  healthkit_workout_uuid  UUID,
  source_training_plan_id UUID REFERENCES training_plans(id) ON DELETE SET NULL,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. exercise_sets
CREATE TABLE IF NOT EXISTS exercise_sets (
  id                    UUID PRIMARY KEY,
  session_id            UUID NOT NULL REFERENCES strength_sessions(id) ON DELETE CASCADE,
  training_plan_id      UUID REFERENCES training_plans(id) ON DELETE SET NULL,
  exercise_name         TEXT NOT NULL DEFAULT '',
  exercise_uuid         TEXT NOT NULL DEFAULT '',
  exercise_media_asset  TEXT NOT NULL DEFAULT '',
  is_unilateral         BOOLEAN NOT NULL DEFAULT FALSE,
  set_number            INTEGER NOT NULL DEFAULT 1,
  weight                DOUBLE PRECISION NOT NULL DEFAULT 0,
  weight_per_side       DOUBLE PRECISION NOT NULL DEFAULT 0,
  reps                  INTEGER NOT NULL DEFAULT 0,
  duration              INTEGER NOT NULL DEFAULT 0,
  distance              DOUBLE PRECISION NOT NULL DEFAULT 0,
  rest_seconds          INTEGER NOT NULL DEFAULT 90,
  target_reps_min       INTEGER NOT NULL DEFAULT 0,
  target_reps_max       INTEGER NOT NULL DEFAULT 0,
  target_rir            INTEGER NOT NULL DEFAULT 2,
  group_id              TEXT NOT NULL DEFAULT '',
  superset_group_id     TEXT,
  sort_order            INTEGER NOT NULL DEFAULT 0,
  set_kind              TEXT NOT NULL DEFAULT 'work',
  is_completed          BOOLEAN NOT NULL DEFAULT TRUE,
  rpe                   INTEGER NOT NULL DEFAULT 0,
  notes                 TEXT NOT NULL DEFAULT '',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. cardio_sessions
CREATE TABLE IF NOT EXISTS cardio_sessions (
  id                      UUID PRIMARY KEY,
  user_id                 UUID,
  date                    TIMESTAMPTZ NOT NULL,
  duration                INTEGER NOT NULL DEFAULT 0,
  distance                DOUBLE PRECISION NOT NULL DEFAULT 0,
  calories                INTEGER NOT NULL DEFAULT 0,
  difficulty              INTEGER NOT NULL DEFAULT 1,
  heart_rate              INTEGER NOT NULL DEFAULT 0,
  max_heart_rate          INTEGER NOT NULL DEFAULT 0,
  body_weight             DOUBLE PRECISION NOT NULL DEFAULT 0,
  notes                   TEXT NOT NULL DEFAULT '',
  cardio_device           INTEGER NOT NULL DEFAULT 0,
  intensity               INTEGER NOT NULL DEFAULT 0,
  training_program        TEXT NOT NULL DEFAULT 'random',
  perceived_exertion      INTEGER,
  energy_level_before     INTEGER,
  is_completed            BOOLEAN NOT NULL DEFAULT FALSE,
  is_live_session         BOOLEAN NOT NULL DEFAULT FALSE,
  started_at              TIMESTAMPTZ,
  completed_at            TIMESTAMPTZ,
  device_source           TEXT NOT NULL DEFAULT 'manual',
  healthkit_workout_uuid  UUID,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. outdoor_sessions
CREATE TABLE IF NOT EXISTS outdoor_sessions (
  id                      UUID PRIMARY KEY,
  user_id                 UUID,
  date                    TIMESTAMPTZ NOT NULL,
  duration                INTEGER NOT NULL DEFAULT 0,
  distance                DOUBLE PRECISION NOT NULL DEFAULT 0,
  calories                INTEGER NOT NULL DEFAULT 0,
  elevation_gain          DOUBLE PRECISION NOT NULL DEFAULT 0,
  average_speed           DOUBLE PRECISION NOT NULL DEFAULT 0,
  max_speed               DOUBLE PRECISION NOT NULL DEFAULT 0,
  route_name              TEXT NOT NULL DEFAULT '',
  start_location          TEXT NOT NULL DEFAULT '',
  end_location            TEXT NOT NULL DEFAULT '',
  notes                   TEXT NOT NULL DEFAULT '',
  temperature             DOUBLE PRECISION,
  weather_condition       TEXT NOT NULL DEFAULT 'unknown',
  outdoor_activity        TEXT NOT NULL DEFAULT 'running',
  intensity               INTEGER NOT NULL DEFAULT 0,
  perceived_exertion      INTEGER,
  energy_level_before     INTEGER,
  is_completed            BOOLEAN NOT NULL DEFAULT FALSE,
  is_live_session         BOOLEAN NOT NULL DEFAULT FALSE,
  started_at              TIMESTAMPTZ,
  completed_at            TIMESTAMPTZ,
  device_source           TEXT NOT NULL DEFAULT 'manual',
  healthkit_workout_uuid  UUID,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indizes für häufige Queries
CREATE INDEX IF NOT EXISTS idx_strength_sessions_user_id ON strength_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_strength_sessions_date ON strength_sessions(date DESC);
CREATE INDEX IF NOT EXISTS idx_exercise_sets_session_id ON exercise_sets(session_id);
CREATE INDEX IF NOT EXISTS idx_cardio_sessions_user_id ON cardio_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_outdoor_sessions_user_id ON outdoor_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_training_plans_user_id ON training_plans(user_id);
```

### Schritt 2: SQL im Supabase Dashboard ausführen

1. Öffne https://app.supabase.com → MotionCore Projekt
2. Navigiere zu **SQL Editor**
3. Kopiere den SQL-Inhalt aus der Migrationsdatei
4. Klicke **Run**

### Schritt 3: Tabellen verifizieren

In Supabase Dashboard → **Table Editor** prüfen, ob alle 5 Tabellen sichtbar sind:
- `training_plans`
- `strength_sessions`
- `exercise_sets`
- `cardio_sessions`
- `outdoor_sessions`

### Schritt 4: Commit

```bash
git add supabase/migrations/20260304_session_sync.sql
git commit -m "feat: add Supabase migration for session sync tables"
```

---

## Task 2: SupabaseClient um Upsert + Delete erweitern

**Files:**
- Modify: `MotionCore/Services/Database/Remote/Core/SupabaseClient.swift`

Der bestehende `SupabaseClient` hat kein Upsert (benötigt `Prefer: resolution=merge-duplicates`) und kein DELETE. Beides wird ergänzt.

### Schritt 1: `upsert`-Methode hinzufügen

In `SupabaseClient.swift`, nach der bestehenden `post`-Methode mit generischem Body einfügen:

```swift
// MARK: - Upsert (INSERT OR UPDATE via POST mit resolution=merge-duplicates)

/// Fügt einen Datensatz ein oder aktualisiert ihn, wenn die id bereits existiert.
func upsert<Body: Encodable>(
    endpoint: String,
    body: Body
) async throws {
    let url = baseURL
        .appendingPathComponent("rest")
        .appendingPathComponent("v1")
        .appendingPathComponent(endpoint)

    print("🔄 UPSERT \(url.absoluteString)")
    var request = makeRequest(url: url, method: "POST")
    request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

    let encoder = Self.makeEncoder()
    request.httpBody = try encoder.encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)
    try validate(response, data: data)
}

/// Batch-Upsert für Arrays
func upsert<Body: Encodable>(
    endpoint: String,
    body: [Body]
) async throws {
    guard !body.isEmpty else { return }

    let url = baseURL
        .appendingPathComponent("rest")
        .appendingPathComponent("v1")
        .appendingPathComponent(endpoint)

    print("🔄 BATCH UPSERT \(url.absoluteString) (\(body.count) Einträge)")
    var request = makeRequest(url: url, method: "POST")
    request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

    let encoder = Self.makeEncoder()
    request.httpBody = try encoder.encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)
    try validate(response, data: data)
}
```

### Schritt 2: `delete`-Methode hinzufügen

```swift
// MARK: - DELETE

/// Löscht Datensätze anhand von Query-Parametern.
/// Beispiel: deleteWhere(endpoint: "exercise_sets", filter: "session_id=eq.\(uuid)")
func deleteWhere(
    endpoint: String,
    filter: String
) async throws {
    guard !filter.isEmpty else {
        print("⚠️ DELETE ohne Filter abgelehnt (endpoint: \(endpoint))")
        return
    }

    var components = URLComponents()
    components.scheme = baseURL.scheme
    components.host = baseURL.host
    components.path = "/rest/v1/\(endpoint)"
    components.query = filter

    guard let url = components.url else {
        throw SupabaseError.invalidURL
    }

    print("🗑️ DELETE \(url.absoluteString)")
    let request = makeRequest(url: url, method: "DELETE")

    let (data, response) = try await URLSession.shared.data(for: request)
    try validate(response, data: data)
}
```

### Schritt 3: Commit

```bash
git add MotionCore/Services/Database/Remote/Core/SupabaseClient.swift
git commit -m "feat: add upsert and delete methods to SupabaseClient"
```

---

## Task 3: SupabaseSessionModels.swift – Encodable DTOs

**Files:**
- Create: `MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift`

Diese Datei enthält reine `Encodable` Structs – keine SwiftData-Abhängigkeit.

### Schritt 1: Datei erstellen

```swift
// MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift

import Foundation

// MARK: - TrainingPlan DTO

struct SupabaseTrainingPlanDTO: Encodable {
    let id: UUID
    let title: String
    let planDescription: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let planType: String
    let updatedAt: Date
}

// MARK: - StrengthSession DTO

struct SupabaseStrengthSessionDTO: Encodable {
    let id: UUID
    let date: Date
    let duration: Int
    let calories: Int
    let bodyWeight: Double
    let heartRate: Int
    let maxHeartRate: Int
    let notes: String
    let workoutType: String
    let intensity: Int
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthkitWorkoutUuid: UUID?
    let sourceTrainingPlanId: UUID?
    let updatedAt: Date
}

// MARK: - ExerciseSet DTO

struct SupabaseExerciseSetDTO: Encodable {
    let id: UUID
    let sessionId: UUID
    let trainingPlanId: UUID?
    let exerciseName: String
    let exerciseUuid: String
    let exerciseMediaAsset: String
    let isUnilateral: Bool
    let setNumber: Int
    let weight: Double
    let weightPerSide: Double
    let reps: Int
    let duration: Int
    let distance: Double
    let restSeconds: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let targetRir: Int
    let groupId: String
    let supersetGroupId: String?
    let sortOrder: Int
    let setKind: String
    let isCompleted: Bool
    let rpe: Int
    let notes: String
}

// MARK: - CardioSession DTO

struct SupabaseCardioSessionDTO: Encodable {
    let id: UUID
    let date: Date
    let duration: Int
    let distance: Double
    let calories: Int
    let difficulty: Int
    let heartRate: Int
    let maxHeartRate: Int
    let bodyWeight: Double
    let notes: String
    let cardioDevice: Int
    let intensity: Int
    let trainingProgram: String
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthkitWorkoutUuid: UUID?
    let updatedAt: Date
}

// MARK: - OutdoorSession DTO

struct SupabaseOutdoorSessionDTO: Encodable {
    let id: UUID
    let date: Date
    let duration: Int
    let distance: Double
    let calories: Int
    let elevationGain: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let routeName: String
    let startLocation: String
    let endLocation: String
    let notes: String
    let temperature: Double?
    let weatherCondition: String
    let outdoorActivity: String
    let intensity: Int
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthkitWorkoutUuid: UUID?
    let updatedAt: Date
}
```

**Hinweis:** Der `SupabaseClient.makeEncoder()` verwendet `.convertToSnakeCase` – Swift-Properties in `camelCase` werden automatisch als `snake_case` zu Supabase gesendet. Kein manuelles Mapping nötig.

### Schritt 2: Commit

```bash
git add MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift
git commit -m "feat: add Encodable DTOs for session sync"
```

---

## Task 4: SupabaseSessionService.swift erstellen

**Files:**
- Create: `MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift`

### Schritt 1: Service erstellen

```swift
// MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift

import Foundation

/// Lädt abgeschlossene Sessions nach Supabase hoch.
/// CloudKit bleibt primäre Persistenz – Supabase ist additiv.
final class SupabaseSessionService {

    static let shared = SupabaseSessionService()
    private let client = SupabaseClient.shared

    private init() {}

    // MARK: - StrengthSession

    /// Lädt eine StrengthSession inkl. aller ExerciseSets zu Supabase hoch.
    func upload(_ session: StrengthSession) async {
        do {
            let dto = SupabaseStrengthSessionDTO(
                id: session.sessionUUID,
                date: session.date,
                duration: session.duration,
                calories: session.calories,
                bodyWeight: session.bodyWeight,
                heartRate: session.heartRate,
                maxHeartRate: session.maxHeartRate,
                notes: session.notes,
                workoutType: session.workoutTypeRaw,
                intensity: session.intensityRaw,
                perceivedExertion: session.perceivedExertion,
                energyLevelBefore: session.energyLevelBefore,
                isCompleted: session.isCompleted,
                isLiveSession: session.isLiveSession,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                deviceSource: session.deviceSource,
                healthkitWorkoutUuid: session.healthKitWorkoutUUID,
                sourceTrainingPlanId: session.sourceTrainingPlan?.persistentModelID.hashValue
                    .description
                    .isEmpty == false ? nil : nil, // wird in Task 4 verfeinert
                updatedAt: Date()
            )

            // Session upserten
            try await client.upsert(endpoint: "strength_sessions", body: dto)

            // Alte Sets löschen und neue einfügen
            try await client.deleteWhere(
                endpoint: "exercise_sets",
                filter: "session_id=eq.\(session.sessionUUID.uuidString)"
            )

            let setDTOs = session.safeExerciseSets.map { set in
                SupabaseExerciseSetDTO(
                    id: set.persistentModelID.hashValue > 0
                        ? UUID() : UUID(), // Fallback – siehe Hinweis unten
                    sessionId: session.sessionUUID,
                    trainingPlanId: nil,
                    exerciseName: set.exerciseNameSnapshot.isEmpty
                        ? set.exerciseName : set.exerciseNameSnapshot,
                    exerciseUuid: set.exerciseUUIDSnapshot,
                    exerciseMediaAsset: set.exerciseMediaAssetName,
                    isUnilateral: set.isUnilateralSnapshot,
                    setNumber: set.setNumber,
                    weight: set.weight,
                    weightPerSide: set.weightPerSide,
                    reps: set.reps,
                    duration: set.duration,
                    distance: set.distance,
                    restSeconds: set.restSeconds,
                    targetRepsMin: set.targetRepsMin,
                    targetRepsMax: set.targetRepsMax,
                    targetRir: set.targetRIR,
                    groupId: set.groupId,
                    supersetGroupId: set.supersetGroupId,
                    sortOrder: set.sortOrder,
                    setKind: set.setKindRaw,
                    isCompleted: set.isCompleted,
                    rpe: set.rpe,
                    notes: set.notes
                )
            }

            if !setDTOs.isEmpty {
                try await client.upsert(endpoint: "exercise_sets", body: setDTOs)
            }

            print("✅ StrengthSession \(session.sessionUUID) zu Supabase hochgeladen (\(setDTOs.count) Sets)")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (StrengthSession): \(error.localizedDescription)")
        }
    }

    // MARK: - CardioSession

    func upload(_ session: CardioSession) async {
        do {
            let dto = SupabaseCardioSessionDTO(
                id: session.sessionUUID,
                date: session.date,
                duration: session.duration,
                distance: session.distance,
                calories: session.calories,
                difficulty: session.difficulty,
                heartRate: session.heartRate,
                maxHeartRate: session.maxHeartRate,
                bodyWeight: session.bodyWeight,
                notes: session.notes,
                cardioDevice: session.cardioDeviceRaw,
                intensity: session.intensityRaw,
                trainingProgram: session.trainingProgramRaw,
                perceivedExertion: session.perceivedExertion,
                energyLevelBefore: session.energyLevelBefore,
                isCompleted: session.isCompleted,
                isLiveSession: session.isLiveSession,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                deviceSource: session.deviceSource,
                healthkitWorkoutUuid: session.healthKitWorkoutUUID,
                updatedAt: Date()
            )

            try await client.upsert(endpoint: "cardio_sessions", body: dto)
            print("✅ CardioSession \(session.sessionUUID) zu Supabase hochgeladen")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (CardioSession): \(error.localizedDescription)")
        }
    }

    // MARK: - OutdoorSession

    func upload(_ session: OutdoorSession) async {
        do {
            let dto = SupabaseOutdoorSessionDTO(
                id: session.sessionUUID,
                date: session.date,
                duration: session.duration,
                distance: session.distance,
                calories: session.calories,
                elevationGain: session.elevationGain,
                averageSpeed: session.averageSpeed,
                maxSpeed: session.maxSpeed,
                routeName: session.routeName,
                startLocation: session.startLocation,
                endLocation: session.endLocation,
                notes: session.notes,
                temperature: session.temperature,
                weatherCondition: session.weatherConditionRaw,
                outdoorActivity: session.outdoorActivityRaw,
                intensity: session.intensityRaw,
                perceivedExertion: session.perceivedExertion,
                energyLevelBefore: session.energyLevelBefore,
                isCompleted: session.isCompleted,
                isLiveSession: session.isLiveSession,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                deviceSource: session.deviceSource,
                healthkitWorkoutUuid: session.healthKitWorkoutUUID,
                updatedAt: Date()
            )

            try await client.upsert(endpoint: "outdoor_sessions", body: dto)
            print("✅ OutdoorSession \(session.sessionUUID) zu Supabase hochgeladen")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (OutdoorSession): \(error.localizedDescription)")
        }
    }

    // MARK: - TrainingPlan

    func upload(_ plan: TrainingPlan) async {
        do {
            let dto = SupabaseTrainingPlanDTO(
                id: plan.planUUID,          // prüfen ob planUUID existiert – sonst anpassen
                title: plan.title,
                planDescription: plan.planDescription,
                startDate: plan.startDate,
                endDate: plan.endDate,
                isActive: plan.isActive,
                planType: plan.planTypeRaw,
                updatedAt: Date()
            )

            try await client.upsert(endpoint: "training_plans", body: dto)
            print("✅ TrainingPlan zu Supabase hochgeladen")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (TrainingPlan): \(error.localizedDescription)")
        }
    }
}
```

**Hinweis ExerciseSet UUID:** `ExerciseSet` hat möglicherweise keine stabile UUID. Prüfe, ob `ExerciseSet` eine `id: UUID` Property hat. Falls nicht → in Task 5 ergänzen.

### Schritt 2: Kompilieren prüfen

In Xcode: **⌘ + B** – sicherstellen, dass keine Compile-Errors entstehen.

Häufige Probleme:
- Property-Namen stimmen nicht mit den @Model-Properties überein → korrigieren
- `OutdoorSession` hat eventuell `outdoorActivityRaw` unter einem anderen Namen → prüfen

### Schritt 3: Commit

```bash
git add MotionCore/Services/Database/Remote/Session/
git commit -m "feat: add SupabaseSessionService with upload for all session types"
```

---

## Task 5: ExerciseSet UUID prüfen und ggf. ergänzen

**Files:**
- Modify: `MotionCore/Models/Core/ExerciseSet.swift` (nur falls nötig)

### Schritt 1: ExerciseSet auf UUID prüfen

Öffne `MotionCore/Models/Core/ExerciseSet.swift` und prüfe:

```swift
// Gibt es bereits eine stabile UUID-Property?
var setUUID: UUID  // oder ähnlich
```

### Schritt 2a: Falls UUID vorhanden → SupabaseSessionService korrigieren

Im `SupabaseSessionService.swift` beim ExerciseSet-Mapping ersetzen:
```swift
// Alt (Placeholder):
id: UUID()

// Neu (mit tatsächlicher UUID-Property):
id: set.setUUID
```

### Schritt 2b: Falls KEINE UUID vorhanden → zu ExerciseSet hinzufügen

```swift
// In ExerciseSet @Model:
var setUUID: UUID = UUID()
```

**Achtung:** Neue SwiftData-Property erfordert keine Migration wenn sie einen Default-Wert hat.

Dann im `SupabaseSessionService.swift` korrigieren:
```swift
id: set.setUUID
```

### Schritt 3: TrainingPlan UUID analog prüfen

Prüfe ob `TrainingPlan` eine `planUUID: UUID` Property hat. Falls nicht → ergänzen:
```swift
var planUUID: UUID = UUID()
```

Im `SupabaseSessionService.swift` `upload(_ plan:)` entsprechend korrigieren.

### Schritt 4: Commit

```bash
git add MotionCore/Models/Core/ExerciseSet.swift
git add MotionCore/Models/Core/TrainingPlan.swift
git add MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift
git commit -m "feat: add stable UUIDs to ExerciseSet and TrainingPlan for Supabase sync"
```

---

## Task 6: Integration – StrengthSession Upload nach Abschluss

**Files:**
- Modify: `MotionCore/Services/Session/ActiveSessionManager.swift`

### Schritt 1: ActiveSessionManager finden und lesen

Öffne `MotionCore/Services/Session/ActiveSessionManager.swift`. Finde die Methode, die eine StrengthSession abschließt. Suche nach:
- `func completeSession`
- `session.complete()`
- `isCompleted = true`
- `completedAt = Date()`

### Schritt 2: Supabase Upload Task ergänzen

Direkt nach dem Setzen von `session.isCompleted = true` / `session.complete()`, den Supabase Upload triggern:

```swift
// Supabase Upload (non-blocking, CloudKit bleibt primär)
Task {
    await SupabaseSessionService.shared.upload(session)
}
```

**Wichtig:** Den Upload in einem separaten `Task {}` aufrufen, damit er den Haupt-Thread und CloudKit-Sync nicht blockiert.

### Schritt 3: Compile + manueller Test

1. **⌘ + B** – compiliert ohne Fehler
2. App im Simulator starten
3. Eine StrengthSession abschließen
4. Supabase Dashboard → Table Editor → `strength_sessions` prüfen

Erwartetes Ergebnis: Neue Zeile in `strength_sessions` + Zeilen in `exercise_sets`.

### Schritt 4: Commit

```bash
git add MotionCore/Services/Session/ActiveSessionManager.swift
git commit -m "feat: trigger Supabase upload after StrengthSession completion"
```

---

## Task 7: Integration – CardioSession + OutdoorSession

**Files:**
- Modify: `MotionCore/Services/Session/ActiveSessionManager.swift`
- Ggf. Modify: andere View-Dateien wo Cardio/Outdoor-Sessions abgeschlossen werden

### Schritt 1: Abschluss-Logik für CardioSession finden

Suche in der Codebase nach wo `CardioSession.isCompleted = true` gesetzt wird. Könnte in `ActiveSessionManager.swift` oder direkt in einer View sein.

### Schritt 2: Upload ergänzen

```swift
// Nach CardioSession-Abschluss:
Task {
    await SupabaseSessionService.shared.upload(cardioSession)
}
```

### Schritt 3: OutdoorSession analog

```swift
Task {
    await SupabaseSessionService.shared.upload(outdoorSession)
}
```

### Schritt 4: Manuell testen

1. CardioSession abschließen → `cardio_sessions` Tabelle prüfen
2. OutdoorSession abschließen → `outdoor_sessions` Tabelle prüfen

### Schritt 5: Commit

```bash
git add MotionCore/Services/Session/ActiveSessionManager.swift
git commit -m "feat: trigger Supabase upload after Cardio and Outdoor session completion"
```

---

## Task 8: Integration – TrainingPlan Upload

**Files:**
- Modify: Datei(en) wo TrainingPlan gespeichert/aktualisiert wird

### Schritt 1: TrainingPlan-Speichern-Logik finden

Suche nach wo `TrainingPlan` gespeichert wird (modelContext.insert / save). Wahrscheinlich in einer View oder einem Plan-Manager.

### Schritt 2: Upload ergänzen

```swift
// Nach TrainingPlan speichern:
Task {
    await SupabaseSessionService.shared.upload(plan)
}
```

### Schritt 3: Manuell testen

TrainingPlan erstellen/bearbeiten → `training_plans` Tabelle prüfen.

### Schritt 4: Commit

```bash
git add <betroffene Dateien>
git commit -m "feat: trigger Supabase upload when TrainingPlan is saved"
```

---

## Task 9: Abschlusskontrolle + Memory Update

### Schritt 1: Checkliste durchgehen

- [ ] Alle 5 Tabellen in Supabase angelegt
- [ ] `SupabaseClient` hat `upsert()` + `deleteWhere()` Methoden
- [ ] `SupabaseSessionModels.swift` enthält alle DTOs
- [ ] `SupabaseSessionService.swift` hat Upload-Methoden für alle 4 Typen
- [ ] StrengthSession-Abschluss triggert Upload
- [ ] CardioSession-Abschluss triggert Upload
- [ ] OutdoorSession-Abschluss triggert Upload
- [ ] TrainingPlan-Speichern triggert Upload
- [ ] CloudKit-Sync weiterhin unverändert
- [ ] Kein UI-Impact bei Fehlern (Silent Fail)

### Schritt 2: End-to-End Test

1. App im Simulator starten
2. Alle 3 Session-Typen einmal abschließen
3. Supabase Dashboard verifizieren
4. Einen TrainingPlan erstellen → `training_plans` prüfen
5. Console-Output prüfen: `✅` Meldungen erscheinen

### Schritt 3: Abschluss-Commit

```bash
git add -A
git commit -m "feat: complete Supabase session sync implementation

Alle Session-Typen (Strength, Cardio, Outdoor) und TrainingPläne
werden nach Abschluss automatisch zu Supabase hochgeladen (Upsert).
CloudKit-Sync bleibt unverändert als primäre Persistenz.
"
```

---

## Bekannte Einschränkungen (für spätere Iteration)

1. **Kein Retry bei Netzwerkfehlern** – Sessions die bei Offline-Nutzung nicht hochgeladen werden, fehlen in Supabase
2. **Keine User-Auth** – `user_id` in Tabellen ist nullable; RLS ist deaktiviert
3. **Keine bidirektionale Sync** – Nur iOS → Supabase, kein Read-Back
4. **Keine historischen Sessions** – Nur neue Sessions werden gesynct; alte bestehende nicht
