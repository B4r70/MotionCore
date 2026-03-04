-- ============================================================
-- MotionCore: Session Sync Tabellen
-- 2026-03-04
-- ============================================================

-- 1. training_plans (muss vor strength_sessions existieren wegen FK)
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
