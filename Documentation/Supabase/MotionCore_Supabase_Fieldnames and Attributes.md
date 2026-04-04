| table_name                | column_name          | data_type                | is_nullable | column_default     | ordinal_position |
| ------------------------- | -------------------- | ------------------------ | ----------- | ------------------ | ---------------- |
| equipment                 | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| equipment                 | identifier           | text                     | NO          | null               | 2                |
| equipment                 | category             | text                     | YES         | null               | 3                |
| equipment                 | display_order        | integer                  | YES         | 0                  | 4                |
| equipment                 | created_at           | timestamp with time zone | YES         | now()              | 5                |
| equipment_translations    | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| equipment_translations    | equipment_id         | uuid                     | NO          | null               | 2                |
| equipment_translations    | language_code        | text                     | NO          | null               | 3                |
| equipment_translations    | name                 | text                     | NO          | null               | 4                |
| equipment_translations    | description          | text                     | YES         | null               | 5                |
| exercise_equipment        | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| exercise_equipment        | exercise_id          | uuid                     | NO          | null               | 2                |
| exercise_equipment        | equipment_id         | uuid                     | NO          | null               | 3                |
| exercise_equipment        | is_required          | boolean                  | YES         | true               | 4                |
| exercise_equipment        | is_primary           | boolean                  | YES         | true               | 5                |
| exercise_equipment        | created_at           | timestamp with time zone | YES         | now()              | 6                |
| exercise_muscles          | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| exercise_muscles          | exercise_id          | uuid                     | NO          | null               | 2                |
| exercise_muscles          | muscle_group_id      | uuid                     | NO          | null               | 3                |
| exercise_muscles          | involvement_type     | text                     | NO          | null               | 4                |
| exercise_muscles          | intensity_percentage | integer                  | YES         | null               | 5                |
| exercise_muscles          | created_at           | timestamp with time zone | YES         | now()              | 6                |
| exercise_relationships    | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| exercise_relationships    | exercise_id          | uuid                     | NO          | null               | 2                |
| exercise_relationships    | related_exercise_id  | uuid                     | NO          | null               | 3                |
| exercise_relationships    | relationship_type    | text                     | NO          | null               | 4                |
| exercise_relationships    | notes                | text                     | YES         | null               | 5                |
| exercise_relationships    | created_at           | timestamp with time zone | YES         | now()              | 6                |
| exercise_translations     | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| exercise_translations     | exercise_id          | uuid                     | NO          | null               | 2                |
| exercise_translations     | language_code        | text                     | NO          | null               | 3                |
| exercise_translations     | name                 | text                     | NO          | null               | 4                |
| exercise_translations     | instructions         | text                     | YES         | null               | 5                |
| exercise_translations     | tips                 | text                     | YES         | null               | 6                |
| exercise_translations     | common_mistakes      | text                     | YES         | null               | 7                |
| exercise_translations     | created_at           | timestamp with time zone | YES         | now()              | 8                |
| exercise_translations     | updated_at           | timestamp with time zone | YES         | now()              | 9                |
| exercise_translations     | translation_source   | text                     | YES         | null               | 10               |
| exercise_translations     | translation_quality  | text                     | YES         | 'raw'::text        | 11               |
| exercise_translations     | translated_at        | timestamp with time zone | YES         | null               | 12               |
| exercises                 | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| exercises                 | exercise_db_id       | text                     | YES         | null               | 2                |
| exercises                 | category             | text                     | NO          | null               | 3                |
| exercises                 | force_type           | text                     | YES         | null               | 4                |
| exercises                 | mechanic_type        | text                     | YES         | null               | 5                |
| exercises                 | difficulty           | text                     | NO          | null               | 6                |
| exercises                 | poster_path          | text                     | YES         | null               | 7                |
| exercises                 | video_path           | text                     | YES         | null               | 8                |
| exercises                 | source               | text                     | YES         | 'exercisedb'::text | 10               |
| exercises                 | is_verified          | boolean                  | YES         | false              | 11               |
| exercises                 | is_archived          | boolean                  | YES         | false              | 12               |
| exercises                 | created_at           | timestamp with time zone | YES         | now()              | 13               |
| exercises                 | updated_at           | timestamp with time zone | YES         | now()              | 14               |
| exercises_de              | id                   | uuid                     | YES         | null               | 1                |
| exercises_de              | exercise_db_id       | text                     | YES         | null               | 2                |
| exercises_de              | category             | text                     | YES         | null               | 3                |
| exercises_de              | force_type           | text                     | YES         | null               | 4                |
| exercises_de              | mechanic_type        | text                     | YES         | null               | 5                |
| exercises_de              | difficulty           | text                     | YES         | null               | 6                |
| exercises_de              | gif_filename         | text                     | YES         | null               | 7                |
| exercises_de              | name                 | text                     | YES         | null               | 8                |
| exercises_de              | instructions         | text                     | YES         | null               | 9                |
| exercises_de              | tips                 | text                     | YES         | null               | 10               |
| exercises_de              | common_mistakes      | text                     | YES         | null               | 11               |
| exercises_de              | is_archived          | boolean                  | YES         | null               | 12               |
| exercises_de              | created_at           | timestamp with time zone | YES         | null               | 13               |
| exercises_de              | updated_at           | timestamp with time zone | YES         | null               | 14               |
| exercises_en              | id                   | uuid                     | YES         | null               | 1                |
| exercises_en              | exercise_db_id       | text                     | YES         | null               | 2                |
| exercises_en              | category             | text                     | YES         | null               | 3                |
| exercises_en              | force_type           | text                     | YES         | null               | 4                |
| exercises_en              | mechanic_type        | text                     | YES         | null               | 5                |
| exercises_en              | difficulty           | text                     | YES         | null               | 6                |
| exercises_en              | gif_filename         | text                     | YES         | null               | 7                |
| exercises_en              | name                 | text                     | YES         | null               | 8                |
| exercises_en              | instructions         | text                     | YES         | null               | 9                |
| exercises_en              | tips                 | text                     | YES         | null               | 10               |
| exercises_en              | common_mistakes      | text                     | YES         | null               | 11               |
| exercises_en              | is_archived          | boolean                  | YES         | null               | 12               |
| exercises_en              | created_at           | timestamp with time zone | YES         | null               | 13               |
| exercises_en              | updated_at           | timestamp with time zone | YES         | null               | 14               |
| exercises_full            | id                   | uuid                     | YES         | null               | 1                |
| exercises_full            | exercise_db_id       | text                     | YES         | null               | 2                |
| exercises_full            | category             | text                     | YES         | null               | 3                |
| exercises_full            | difficulty           | text                     | YES         | null               | 4                |
| exercises_full            | name                 | text                     | YES         | null               | 5                |
| exercises_full            | language_code        | text                     | YES         | null               | 6                |
| exercises_full            | primary_muscles      | ARRAY                    | YES         | null               | 7                |
| exercises_full            | secondary_muscles    | ARRAY                    | YES         | null               | 8                |
| exercises_full            | equipment            | ARRAY                    | YES         | null               | 9                |
| muscle_aliases            | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| muscle_aliases            | muscle_group_id      | uuid                     | NO          | null               | 2                |
| muscle_aliases            | language_code        | text                     | NO          | null               | 3                |
| muscle_aliases            | alias_type           | text                     | NO          | null               | 4                |
| muscle_aliases            | alias                | text                     | NO          | null               | 5                |
| muscle_aliases            | is_preferred         | boolean                  | YES         | false              | 6                |
| muscle_aliases            | display_order        | integer                  | YES         | 0                  | 7                |
| muscle_aliases            | created_at           | timestamp with time zone | YES         | now()              | 8                |
| muscle_group_translations | id                   | uuid                     | NO          | gen_random_uuid()  | 1                |
| muscle_group_translations | muscle_group_id      | uuid                     | NO          | null               | 2                |