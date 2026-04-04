# MotionCore — Supabase Schema `motioncore` — Tabellenübersicht

> Referenz für Claude Code. Alle Tabellen im Schema `motioncore` auf Supabase-Projekt `jeebptrnhjekwtviecvz`.

---

## Übersicht

| # | Tabelle | Rows | Beschreibung |
|---|---------|------|-------------|
| 1 | `exercises` | 1.324 | Stammdaten aller Übungen |
| 2 | `exercise_translations` | 2.648 | Übersetzungen (de/en) pro Exercise |
| 3 | `exercise_muscles` | 5.690 | Join: Exercise ↔ MuscleGroup (primary/secondary) |
| 4 | `exercise_equipment` | 1.306 | Join: Exercise ↔ Equipment |
| 5 | `exercise_relationships` | 0 | Exercise-Beziehungen (Varianten, Alternativen) — leer |
| 6 | `equipment` | 28 | Geräte-Katalog |
| 7 | `equipment_translations` | 56 | Übersetzungen pro Equipment |
| 8 | `muscle_groups` | 47 | Muskelgruppen (hierarchisch, Level 1 + 2) |
| 9 | `muscle_group_translations` | 94 | Übersetzungen pro MuscleGroup |
| 10 | `muscle_aliases` | 0 | Alternative Bezeichnungen — leer |
| 11 | `taxonomy_types` | 5 | Taxonomie-Kategorien (category, force_type, etc.) |
| 12 | `taxonomy_values` | 17 | Taxonomie-Werte pro Typ |
| 13 | `taxonomy_value_translations` | 0 | Übersetzungen — leer |
| 14 | `training_split_types` | 4 | Split-Typen (PPL, Upper/Lower, etc.) |
| 15 | `training_split_translations` | 8 | Übersetzungen pro Split-Typ |
| 16 | `split_days` | 11 | Trainingstage pro Split |
| 17 | `split_day_translations` | 22 | Übersetzungen pro Split-Tag |
| 18 | `split_day_muscle_groups` | 27 | Join: SplitDay ↔ MuscleGroup |

**Views (kein eigener Storage):**
- `exercises_de` — Exercise + deutsche Übersetzung (flach)
- `exercises_en` — Exercise + englische Übersetzung (flach)
- `exercises_full` — Exercise + Übersetzung + Muscles + Equipment (aggregiert)

---

## Tabellen im Detail

### 1. `exercises` (1.324 Rows)

Zentrale Übungstabelle. Jede Übung hat eine UUID, die in der iOS-App als `apiID` auf dem SwiftData `Exercise`-Modell gespeichert wird.

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `exercise_db_id` | text | YES | — | Externe ID (ExerciseDB-Quelle) |
| `category` | text | NO | — | z.B. "strength", "stretching" |
| `force_type` | text | YES | — | "push", "pull", "static" |
| `mechanic_type` | text | YES | — | "compound", "isolation" |
| `difficulty` | text | NO | — | "beginner", "intermediate", "expert" |
| `video_path` | text | YES | — | Pfad in Supabase Storage (Bucket `exercise-videos`) |
| `poster_path` | text | YES | — | Pfad in Supabase Storage (Bucket `exercise-posters`) |
| `source` | text | YES | `'exercisedb'` | Datenquelle |
| `is_verified` | boolean | YES | `false` | Manuell geprüft? |
| `is_archived` | boolean | YES | `false` | Archiviert/versteckt? |
| `created_at` | timestamptz | YES | `now()` | Erstellungsdatum |
| `updated_at` | timestamptz | YES | `now()` | Letzte Änderung |

**Constraints:**
- **PK:** `exercises_pkey` → `id`
- **UNIQUE:** `exercises_exercise_db_id_key` → `exercise_db_id`

---

### 2. `exercise_translations` (2.648 Rows)

Übersetzungen pro Exercise und Sprache. Aktuell de + en = 2 × 1.324.

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `exercise_id` | uuid | NO | — | **FK** → `exercises.id` |
| `language_code` | text | NO | — | "de", "en" |
| `name` | text | NO | — | Übersetzter Name |
| `instructions` | text | YES | — | Ausführungsanleitung |
| `tips` | text | YES | — | Trainingstipps |
| `common_mistakes` | text | YES | — | Häufige Fehler |
| `created_at` | timestamptz | YES | `now()` | — |
| `updated_at` | timestamptz | YES | `now()` | — |
| `translation_source` | text | YES | — | z.B. "claude-haiku" |
| `translation_quality` | text | YES | `'raw'` | "raw", "reviewed" |
| `translated_at` | timestamptz | YES | — | Übersetzungsdatum |

**Constraints:**
- **PK:** `exercise_translations_pkey` → `id`
- **FK:** `exercise_translations_exercise_id_fkey` → `exercises.id`
- **UNIQUE:** `unique_exercise_language` → (`exercise_id`, `language_code`)
- **UNIQUE:** `exercise_translations_exercise_lang_unique` → (`exercise_id`, `language_code`)

---

### 3. `exercise_muscles` (5.690 Rows)

Join-Tabelle: Welche Muskeln trainiert eine Übung? `involvement_type` unterscheidet primary/secondary.

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `exercise_id` | uuid | NO | — | **FK** → `exercises.id` |
| `muscle_group_id` | uuid | NO | — | **FK** → `muscle_groups.id` |
| `involvement_type` | text | NO | — | `"primary"` oder `"secondary"` |
| `intensity_percentage` | integer | YES | — | Intensitätsanteil (optional) |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `exercise_muscles_pkey` → `id`
- **FK:** `exercise_muscles_exercise_id_fkey` → `exercises.id`
- **FK:** `exercise_muscles_muscle_group_id_fkey` → `muscle_groups.id`
- **UNIQUE:** `unique_exercise_muscle` → (`exercise_id`, `muscle_group_id`)

**iOS-Mapping:** Die RPC-Funktionen liefern `muscle_groups.identifier` (Level 2, z.B. `"chest_upper"`) als Strings. In der App werden diese direkt zu `DetailedMuscle(rawValue:)` gemappt.

---

### 4. `exercise_equipment` (1.306 Rows)

Join-Tabelle: Welches Equipment braucht eine Übung?

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `exercise_id` | uuid | NO | — | **FK** → `exercises.id` |
| `equipment_id` | uuid | NO | — | **FK** → `equipment.id` |
| `is_required` | boolean | YES | `true` | Pflicht-Equipment? |
| `is_primary` | boolean | YES | `true` | Haupt-Equipment? |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `exercise_equipment_pkey` → `id`
- **FK:** `exercise_equipment_exercise_id_fkey` → `exercises.id`
- **FK:** `exercise_equipment_equipment_id_fkey` → `equipment.id`
- **UNIQUE:** `unique_exercise_equipment` → (`exercise_id`, `equipment_id`)

---

### 5. `exercise_relationships` (0 Rows — leer)

Beziehungen zwischen Exercises (Varianten, Alternativen, Progressionen).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `exercise_id` | uuid | NO | — | **FK** → `exercises.id` |
| `related_exercise_id` | uuid | NO | — | **FK** → `exercises.id` |
| `relationship_type` | text | NO | — | z.B. "variation", "alternative", "progression" |
| `notes` | text | YES | — | — |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `exercise_relationships_pkey` → `id`
- **FK:** `exercise_relationships_exercise_id_fkey` → `exercises.id`
- **FK:** `exercise_relationships_related_exercise_id_fkey` → `exercises.id`
- **UNIQUE:** `unique_exercise_relationship` → (`exercise_id`, `related_exercise_id`, `relationship_type`)

---

### 6. `equipment` (28 Rows)

Geräte-Katalog.

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `identifier` | text | NO | — | Maschinenlesbar, z.B. "barbell", "dumbbell" |
| `category` | text | YES | — | z.B. "free_weights", "machines" |
| `display_order` | integer | YES | `0` | Sortierung |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `equipment_pkey` → `id`
- **UNIQUE:** `equipment_identifier_key` → `identifier`

---

### 7. `equipment_translations` (56 Rows)

Übersetzungen pro Equipment (28 × 2 Sprachen).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `equipment_id` | uuid | NO | — | **FK** → `equipment.id` |
| `language_code` | text | NO | — | "de", "en" |
| `name` | text | NO | — | Übersetzter Name |
| `description` | text | YES | — | Beschreibung |

**Constraints:**
- **PK:** `equipment_translations_pkey` → `id`
- **FK:** `equipment_translations_equipment_id_fkey` → `equipment.id`
- **UNIQUE:** `unique_equipment_language` → (`equipment_id`, `language_code`)

---

### 8. `muscle_groups` (47 Rows)

Hierarchische Muskelgruppen. Level 1 = Hauptgruppen (z.B. "chest"), Level 2 = Untergruppen (z.B. "chest_upper"). Self-referencing via `parent_id`.

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `identifier` | text | NO | — | z.B. "chest", "chest_upper" — entspricht `DetailedMuscle.rawValue` |
| `parent_id` | uuid | YES | — | **FK (self)** → `muscle_groups.id` (null bei Level 1) |
| `hierarchy_level` | integer | YES | `0` | 1 = Hauptgruppe, 2 = Untergruppe |
| `display_order` | integer | YES | `0` | Sortierung |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `muscle_groups_pkey` → `id`
- **FK:** `muscle_groups_parent_id_fkey` → `muscle_groups.id` (self-ref)
- **UNIQUE:** `muscle_groups_identifier_key` → `identifier`

**iOS-Mapping:** Level-2 `identifier` = `DetailedMuscle.rawValue`. Level-1 `identifier` ≈ `MuscleGroup.rawValue` (mit einigen Abweichungen, siehe `MuscleGroupMapper`).

---

### 9. `muscle_group_translations` (94 Rows)

Übersetzungen pro MuscleGroup (47 × 2 Sprachen).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `muscle_group_id` | uuid | NO | — | **FK** → `muscle_groups.id` |
| `language_code` | text | NO | — | "de", "en" |
| `name` | text | NO | — | z.B. "Obere Brust" |
| `description` | text | YES | — | — |

**Constraints:**
- **PK:** `muscle_group_translations_pkey` → `id`
- **FK:** `muscle_group_translations_muscle_group_id_fkey` → `muscle_groups.id`
- **UNIQUE:** `unique_muscle_group_language` → (`muscle_group_id`, `language_code`)

---

### 10. `muscle_aliases` (0 Rows — leer)

Alternative Bezeichnungen für Muskelgruppen (z.B. "Lats" → back_lats).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `muscle_group_id` | uuid | NO | — | **FK** → `muscle_groups.id` |
| `language_code` | text | NO | — | — |
| `alias_type` | text | NO | — | z.B. "common", "scientific" |
| `alias` | text | NO | — | Der alternative Name |
| `is_preferred` | boolean | YES | `false` | Bevorzugte Bezeichnung? |
| `display_order` | integer | YES | `0` | — |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `muscle_aliases_pkey` → `id`
- **FK:** `muscle_aliases_muscle_group_id_fkey` → `muscle_groups.id`
- **UNIQUE:** `unique_alias` → (`muscle_group_id`, `language_code`, `alias_type`, `alias`)

---

### 11. `taxonomy_types` (5 Rows)

Kategorisierungssystem für Exercise-Metadaten.

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `key` | text | NO | — | z.B. "category", "force_type", "mechanic_type", "difficulty" |
| `description` | text | YES | — | — |
| `created_at` | timestamptz | NO | `now()` | — |

**Constraints:**
- **PK:** `taxonomy_types_pkey` → `id`
- **UNIQUE:** `taxonomy_types_key_key` → `key`

---

### 12. `taxonomy_values` (17 Rows)

Werte pro Taxonomie-Typ (z.B. "push" für force_type, "compound" für mechanic_type).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `taxonomy_type_id` | uuid | NO | — | **FK** → `taxonomy_types.id` |
| `identifier` | text | NO | — | z.B. "push", "pull", "compound" |
| `display_order` | integer | YES | — | Sortierung |
| `is_active` | boolean | NO | `true` | — |
| `created_at` | timestamptz | NO | `now()` | — |

**Constraints:**
- **PK:** `taxonomy_values_pkey` → `id`
- **FK:** `taxonomy_values_taxonomy_type_id_fkey` → `taxonomy_types.id`
- **UNIQUE:** `taxonomy_values_taxonomy_type_id_identifier_key` → (`taxonomy_type_id`, `identifier`)

---

### 13. `taxonomy_value_translations` (0 Rows — leer)

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `taxonomy_value_id` | uuid | NO | — | **FK** → `taxonomy_values.id` |
| `language_code` | text | NO | — | — |
| `name` | text | NO | — | — |
| `description` | text | YES | — | — |
| `created_at` | timestamptz | NO | `now()` | — |

**Constraints:**
- **PK:** `taxonomy_value_translations_pkey` → `id`
- **FK:** `taxonomy_value_translations_taxonomy_value_id_fkey` → `taxonomy_values.id`
- **UNIQUE:** (`taxonomy_value_id`, `language_code`)

---

### 14. `training_split_types` (4 Rows)

Trainings-Split-Typen (z.B. Push/Pull/Legs, Upper/Lower).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `identifier` | text | NO | — | z.B. "ppl", "upper_lower" |
| `days_per_week` | integer | YES | — | Empfohlene Trainingstage |
| `recommended_level` | text | YES | — | "beginner", "intermediate", etc. |
| `display_order` | integer | YES | `0` | — |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `training_split_types_pkey` → `id`
- **UNIQUE:** `training_split_types_identifier_key` → `identifier`

---

### 15. `training_split_translations` (8 Rows)

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `split_type_id` | uuid | NO | — | **FK** → `training_split_types.id` |
| `language_code` | text | NO | — | — |
| `name` | text | NO | — | — |
| `description` | text | YES | — | — |

**Constraints:**
- **PK:** `training_split_translations_pkey` → `id`
- **FK:** `training_split_translations_split_type_id_fkey` → `training_split_types.id`
- **UNIQUE:** `unique_split_translation` → (`split_type_id`, `language_code`)

---

### 16. `split_days` (11 Rows)

Trainingstage innerhalb eines Splits (z.B. Push-Tag, Pull-Tag, Leg-Tag).

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `split_type_id` | uuid | NO | — | **FK** → `training_split_types.id` |
| `identifier` | text | NO | — | z.B. "push", "pull", "legs" |
| `day_order` | integer | NO | — | Reihenfolge im Split |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `split_days_pkey` → `id`
- **FK:** `split_days_split_type_id_fkey` → `training_split_types.id`
- **UNIQUE:** `unique_split_day` → (`split_type_id`, `identifier`)

---

### 17. `split_day_translations` (22 Rows)

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `split_day_id` | uuid | NO | — | **FK** → `split_days.id` |
| `language_code` | text | NO | — | — |
| `name` | text | NO | — | — |
| `description` | text | YES | — | — |

**Constraints:**
- **PK:** `split_day_translations_pkey` → `id`
- **FK:** `split_day_translations_split_day_id_fkey` → `split_days.id`
- **UNIQUE:** `unique_split_day_translation` → (`split_day_id`, `language_code`)

---

### 18. `split_day_muscle_groups` (27 Rows)

Join: Welche Muskelgruppen werden an welchem Split-Tag trainiert?

| Spalte | Typ | Nullable | Default | Beschreibung |
|--------|-----|----------|---------|-------------|
| `id` | uuid | NO | `gen_random_uuid()` | **PK** |
| `split_day_id` | uuid | NO | — | **FK** → `split_days.id` |
| `muscle_group_id` | uuid | NO | — | **FK** → `muscle_groups.id` |
| `priority` | integer | YES | `1` | Priorität der Muskelgruppe am Tag |
| `created_at` | timestamptz | YES | `now()` | — |

**Constraints:**
- **PK:** `split_day_muscle_groups_pkey` → `id`
- **FK:** `split_day_muscle_groups_split_day_id_fkey` → `split_days.id`
- **FK:** `split_day_muscle_groups_muscle_group_id_fkey` → `muscle_groups.id`
- **UNIQUE:** `unique_split_day_muscle` → (`split_day_id`, `muscle_group_id`)

---

## ER-Diagramm (Beziehungen)

```
exercises (1.324)
  ├──< exercise_translations (2.648)      [exercise_id → exercises.id]
  ├──< exercise_muscles (5.690)           [exercise_id → exercises.id]
  │       └──> muscle_groups (47)         [muscle_group_id → muscle_groups.id]
  ├──< exercise_equipment (1.306)         [exercise_id → exercises.id]
  │       └──> equipment (28)             [equipment_id → equipment.id]
  └──< exercise_relationships (0)         [exercise_id, related_exercise_id → exercises.id]

muscle_groups (47)
  ├──> muscle_groups (self-ref)           [parent_id → muscle_groups.id]
  ├──< muscle_group_translations (94)     [muscle_group_id → muscle_groups.id]
  ├──< muscle_aliases (0)                 [muscle_group_id → muscle_groups.id]
  └──< split_day_muscle_groups (27)       [muscle_group_id → muscle_groups.id]

equipment (28)
  └──< equipment_translations (56)        [equipment_id → equipment.id]

taxonomy_types (5)
  └──< taxonomy_values (17)               [taxonomy_type_id → taxonomy_types.id]
        └──< taxonomy_value_translations (0) [taxonomy_value_id → taxonomy_values.id]

training_split_types (4)
  ├──< training_split_translations (8)    [split_type_id → training_split_types.id]
  └──< split_days (11)                    [split_type_id → training_split_types.id]
        ├──< split_day_translations (22)  [split_day_id → split_days.id]
        └──< split_day_muscle_groups (27) [split_day_id → split_days.id]
```

---

## iOS-App Mapping (Key Facts)

| Supabase | iOS SwiftData | Hinweis |
|----------|--------------|---------|
| `exercises.id` | `Exercise.apiID` | UUID-Verknüpfung für Duplikat-Check |
| `exercise_translations.name` (de) | `Exercise.name` | Deutscher Name |
| `exercise_translations.instructions` (de) | `Exercise.instructions` | — |
| `exercise_translations.tips` (de) | `Exercise.exerciseDescription` | — |
| `muscle_groups.identifier` (Level 2) | `DetailedMuscle.rawValue` | 1:1 Mapping |
| `muscle_groups.identifier` (Level 1) | `MuscleGroup.rawValue` | Über `MuscleGroupMapper` |
| `equipment.identifier` | `ExerciseEquipment.rawValue` | Über `ExerciseEquipment.fromSupabase()` |
| `exercises.video_path` | `Exercise.videoPath` | Pfad in Storage Bucket `exercise-videos` |
| `exercises.poster_path` | `Exercise.posterPath` | Pfad in Storage Bucket `exercise-posters` |
