# Design: Supabase Session Sync

**Datum:** 2026-03-04
**Status:** Freigegeben
**Scope:** StrengthSession, CardioSession, OutdoorSession, TrainingPlan + ExerciseSets

---

## Kontext

MotionCore nutzt aktuell Supabase nur read-only für den Exercise-Import. CloudKit bleibt weiterhin als primäre lokale Persistenz bestehen. Ziel ist es, alle Trainings-Sessions zusätzlich in Supabase zu spiegeln – als Grundlage für zukünftige Features (Multi-Device-Sync, Web-Dashboard, Coach-Features, API-Zugriff).

---

## Architektur-Entscheidungen

| Frage | Entscheidung |
|---|---|
| Sync-Zeitpunkt | Sofort nach Session-Abschluss |
| Richtung | iOS → Supabase (one-way, vorerst) |
| Auth | Bestehende Supabase Auth-Session |
| Felder | Alle Felder 1:1 aus den @Model-Klassen |
| ExerciseSets | Separate Tabelle mit Foreign Key |
| Fehlerbehandlung | Silent Fail (Supabase = sekundäre Ebene) |
| Konfliktlösung | Upsert (ON CONFLICT DO UPDATE) |

---

## Supabase Tabellen-Struktur

### `strength_sessions`
```sql
CREATE TABLE strength_sessions (
  id                    UUID PRIMARY KEY,
  user_id               UUID NOT NULL REFERENCES auth.users(id),
  date                  TIMESTAMPTZ NOT NULL,
  duration              INTEGER DEFAULT 0,
  calories              INTEGER DEFAULT 0,
  body_weight           DOUBLE PRECISION DEFAULT 0,
  heart_rate            INTEGER DEFAULT 0,
  max_heart_rate        INTEGER DEFAULT 0,
  notes                 TEXT DEFAULT '',
  workout_type          TEXT DEFAULT 'fullBody',
  intensity             INTEGER DEFAULT 0,
  perceived_exertion    INTEGER,
  energy_level_before   INTEGER,
  is_completed          BOOLEAN DEFAULT FALSE,
  is_live_session       BOOLEAN DEFAULT FALSE,
  started_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  device_source         TEXT DEFAULT 'manual',
  healthkit_workout_uuid UUID,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE strength_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own sessions" ON strength_sessions
  FOR ALL USING (auth.uid() = user_id);
```

### `exercise_sets`
```sql
CREATE TABLE exercise_sets (
  id                    UUID PRIMARY KEY,
  session_id            UUID REFERENCES strength_sessions(id) ON DELETE CASCADE,
  training_plan_id      UUID REFERENCES training_plans(id) ON DELETE SET NULL,
  exercise_name         TEXT DEFAULT '',
  exercise_uuid         TEXT DEFAULT '',
  exercise_media_asset  TEXT DEFAULT '',
  is_unilateral         BOOLEAN DEFAULT FALSE,
  set_number            INTEGER DEFAULT 1,
  weight                DOUBLE PRECISION DEFAULT 0,
  weight_per_side       DOUBLE PRECISION DEFAULT 0,
  reps                  INTEGER DEFAULT 0,
  duration              INTEGER DEFAULT 0,
  distance              DOUBLE PRECISION DEFAULT 0,
  rest_seconds          INTEGER DEFAULT 90,
  target_reps_min       INTEGER DEFAULT 0,
  target_reps_max       INTEGER DEFAULT 0,
  target_rir            INTEGER DEFAULT 2,
  group_id              TEXT DEFAULT '',
  superset_group_id     TEXT,
  sort_order            INTEGER DEFAULT 0,
  set_kind              TEXT DEFAULT 'work',
  is_completed          BOOLEAN DEFAULT TRUE,
  rpe                   INTEGER DEFAULT 0,
  notes                 TEXT DEFAULT '',
  created_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE exercise_sets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own sets" ON exercise_sets
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM strength_sessions s
      WHERE s.id = session_id AND s.user_id = auth.uid()
    )
  );
```

### `cardio_sessions`
```sql
CREATE TABLE cardio_sessions (
  id                    UUID PRIMARY KEY,
  user_id               UUID NOT NULL REFERENCES auth.users(id),
  date                  TIMESTAMPTZ NOT NULL,
  duration              INTEGER DEFAULT 0,
  distance              DOUBLE PRECISION DEFAULT 0,
  calories              INTEGER DEFAULT 0,
  difficulty            INTEGER DEFAULT 1,
  heart_rate            INTEGER DEFAULT 0,
  max_heart_rate        INTEGER DEFAULT 0,
  body_weight           DOUBLE PRECISION DEFAULT 0,
  notes                 TEXT DEFAULT '',
  cardio_device         INTEGER DEFAULT 0,
  intensity             INTEGER DEFAULT 0,
  training_program      TEXT DEFAULT 'random',
  perceived_exertion    INTEGER,
  energy_level_before   INTEGER,
  is_completed          BOOLEAN DEFAULT FALSE,
  is_live_session       BOOLEAN DEFAULT FALSE,
  started_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  device_source         TEXT DEFAULT 'manual',
  healthkit_workout_uuid UUID,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE cardio_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own cardio sessions" ON cardio_sessions
  FOR ALL USING (auth.uid() = user_id);
```

### `outdoor_sessions`
```sql
CREATE TABLE outdoor_sessions (
  id                    UUID PRIMARY KEY,
  user_id               UUID NOT NULL REFERENCES auth.users(id),
  date                  TIMESTAMPTZ NOT NULL,
  duration              INTEGER DEFAULT 0,
  distance              DOUBLE PRECISION DEFAULT 0,
  calories              INTEGER DEFAULT 0,
  elevation_gain        DOUBLE PRECISION DEFAULT 0,
  average_speed         DOUBLE PRECISION DEFAULT 0,
  max_speed             DOUBLE PRECISION DEFAULT 0,
  route_name            TEXT DEFAULT '',
  start_location        TEXT DEFAULT '',
  end_location          TEXT DEFAULT '',
  notes                 TEXT DEFAULT '',
  temperature           DOUBLE PRECISION,
  weather_condition     TEXT DEFAULT 'unknown',
  outdoor_activity      TEXT DEFAULT 'running',
  intensity             INTEGER DEFAULT 0,
  perceived_exertion    INTEGER,
  energy_level_before   INTEGER,
  is_completed          BOOLEAN DEFAULT FALSE,
  is_live_session       BOOLEAN DEFAULT FALSE,
  started_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  device_source         TEXT DEFAULT 'manual',
  healthkit_workout_uuid UUID,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE outdoor_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own outdoor sessions" ON outdoor_sessions
  FOR ALL USING (auth.uid() = user_id);
```

### `training_plans`
```sql
CREATE TABLE training_plans (
  id                    UUID PRIMARY KEY,
  user_id               UUID NOT NULL REFERENCES auth.users(id),
  title                 TEXT DEFAULT '',
  plan_description      TEXT DEFAULT '',
  start_date            TIMESTAMPTZ NOT NULL,
  end_date              TIMESTAMPTZ,
  is_active             BOOLEAN DEFAULT TRUE,
  plan_type             TEXT DEFAULT 'strength',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE training_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own plans" ON training_plans
  FOR ALL USING (auth.uid() = user_id);
```

---

## iOS-seitige Architektur

### Neue Dateien

```
Services/Database/Remote/
└── Session/
    ├── SupabaseSessionService.swift     # Upload-Logik
    └── SupabaseSessionModels.swift      # Encodable DTOs
```

### `SupabaseSessionService`

```swift
final class SupabaseSessionService {
    static let shared = SupabaseSessionService()

    func upload(_ session: StrengthSession) async
    func upload(_ session: CardioSession) async
    func upload(_ session: OutdoorSession) async
    func upload(_ plan: TrainingPlan) async
}
```

- Alle Methoden sind `async` (kein `throws` – Silent Fail mit Log)
- Upsert-Strategie: `POST /rest/v1/tablename?on_conflict=id`
- ExerciseSets: erst Session upserten, dann alle alten Sets löschen, neue Sets batch-inserieren

### DTOs (`SupabaseSessionModels.swift`)

Reine `Encodable`-Structs ohne SwiftData-Abhängigkeit:

```swift
struct SupabaseStrengthSessionDTO: Encodable {
    let id: UUID
    let userId: UUID
    let date: Date
    // ... alle Felder aus StrengthSession
}

struct SupabaseExerciseSetDTO: Encodable {
    let id: UUID
    let sessionId: UUID
    // ... alle Felder aus ExerciseSet
}
```

### Integration in ActiveSessionManager

```swift
// Nach Session-Abschluss:
func completeSession(_ session: StrengthSession) {
    session.complete()       // SwiftData + CloudKit
    Task {
        await SupabaseSessionService.shared.upload(session)
    }
}
```

---

## Upload-Ablauf (StrengthSession)

```
1. StrengthSession → SupabaseStrengthSessionDTO
2. POST /rest/v1/strength_sessions (Upsert via Prefer: resolution=merge-duplicates)
3. DELETE /rest/v1/exercise_sets?session_id=eq.{id}
4. POST /rest/v1/exercise_sets (Batch-Insert aller Sets)
```

---

## Was nicht in Scope ist (vorerst)

- Bidirektionaler Sync (Supabase → iOS)
- Retry-Queue bei Netzwerkfehlern
- Realtime-Updates
- Web-Dashboard
- Historische Session-Migration (nur neue Sessions werden gesynct)

---

## Erfolgskriterien

- [ ] Alle 5 Tabellen in Supabase angelegt mit RLS
- [ ] Nach Session-Abschluss erscheint die Session in Supabase
- [ ] ExerciseSets korrekt verknüpft
- [ ] Bestehender CloudKit-Sync unverändert
- [ ] Kein UI-Impact bei Fehlern
