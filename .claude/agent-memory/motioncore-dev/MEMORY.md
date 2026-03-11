# MotionCore Agent Memory

## Session UUIDs (stabile Primärschlüssel)
- `StrengthSession.sessionUUID: UUID` — bereits vorhanden
- `CardioSession.sessionUUID: UUID` — bereits vorhanden
- `OutdoorSession.sessionUUID: UUID` — bereits vorhanden
- `ExerciseSet.setUUID: UUID` — hinzugefügt 04.03.2026
- `TrainingPlan.planUUID: UUID` — hinzugefügt 04.03.2026

## Supabase Session Sync
- `SupabaseSessionService` → `Services/Database/Remote/Session/SupabaseSessionService.swift`
- DTOs → `Services/Database/Remote/Session/SupabaseSessionModels.swift`
- Client-Methoden: `upsert(endpoint:body:)`, `deleteWhere(endpoint:filter:)`, `get`, `post`, `rpc`
- Delete-Filter-Format: `"session_id=eq.UUID-STRING"` (als URL query string)
- Upload-Strategie für Sets: erst DELETE wo session_id=eq.X, dann BATCH UPSERT
- Upload-Trigger-Stellen (Tasks 6-8, abgeschlossen 04.03.2026):
  - StrengthSession: `ActiveWorkoutView.finishWorkout()` → nach `session.complete()`
  - CardioSession: `FormView.swift` Toolbar-Button → nur bei `mode == .add`
  - TrainingPlan: `TrainingFormView.save()` → nur bei `mode == .add`
  - OutdoorSession: kein manueller Abschluss-Flow vorhanden (BaseView TODO)
- Upload-Muster: immer `Task { await SupabaseSessionService.shared.upload(x) }` (non-blocking)

## SwiftData Models (Core)
- `StrengthSession` — `Models/Core/StrengthSession.swift` (Dateiname: StrengthWorkoutSession.swift)
- `CardioSession` — `Models/Core/CardioSession.swift`
- `OutdoorSession` — `Models/Core/OutdoorSession.swift` (Dateiname: OutdoorWorkoutSession.swift)
- `ExerciseSet` — `Models/Core/ExerciseSet.swift`
- `TrainingPlan` — `Models/Core/TrainingPlan.swift`
- `StrengthSession.safeExerciseSets` → computed, gibt `exerciseSets ?? []` zurück
- `TrainingPlan.safeTemplateSets` → computed, gibt `templateSets ?? []` zurück

## Architektur-Muster
- CalcEngines: pure structs in `Services/Calculation/`
- Keine Unit-Tests — Verifikation via Previews + Simulator
- Neue SwiftData-Properties mit Default-Value brauchen keine Migration
- SupabaseClient ist Singleton: `SupabaseClient.shared`
- SupabaseSessionService ist Singleton: `SupabaseSessionService.shared`

## Datei-Konventionen
- Header-Stil: Kommentar-Block mit //----- Linie, Metadaten, Copyright
- Code-Kommentare auf Deutsch, Variable/Function Names auf Englisch
- Keine "NEU:"-Kommentare außer explizit verlangt

## Kritische Supabase-Encoding-Regel (WICHTIG)
Sobald ein `CodingKeys`-Enum im Encodable-Struct vorhanden ist, wird `.convertToSnakeCase` IGNORIERT.
→ Alle Properties müssen dann explizit mit Supabase-Spaltennamen gemappt werden.
→ Besonders aufpassen bei: `Raw`-Suffix, UUID-Abkürzungen, Snapshot-Suffix:
  ```swift
  case workoutTypeRaw = "workout_type"         // Raw → ohne Suffix
  case healthKitWorkoutUUID = "healthkit_workout_uuid"  // UUID → lowercase
  case exerciseUUIDSnapshot = "exercise_uuid"  // Snapshot → ohne Suffix
  case targetRIR = "target_rir"               // Abkürzungen → explizit
  ```

## WatchOS Integration (abgeschlossen 06.03.2026)
- App Group ID: `group.com.barto.motioncore`
- `WatchMessageKeys` → `Services/Watch/WatchMessageKeys.swift` (geteilte Konstanten)
- `PhoneSessionManager` → `Services/Watch/PhoneSessionManager.swift` (Singleton, WCSession auf iPhone)
- `WatchComplicationService` → `Services/Watch/WatchComplicationService.swift` (pure struct)
  - Schreibt Streak + WeeklyCount in App Group UserDefaults via `WatchComplicationKey`
  - Ruft `WidgetCenter.shared.reloadTimelines` für "StreakComplication" + "WeeklyProgressComplication"
  - Aufruf in `ActiveWorkoutView.finishWorkout()` nach `context.save()`, vor Supabase-Upload
- Watch-Complication-Keys: `WatchComplicationKey.streakCount`, `.weeklyWorkoutCount`, `.weeklyWorkoutGoal`

## Bekannte Einschränkungen (Supabase Sync)
- `exerciseUUIDSnapshot: String` ist KEIN UUID-Typ (Int-Hash-String) → Supabase-Spalte `exercise_uuid` muss TEXT sein
- Supabase: nur Anon-Key – kein User-Auth. `user_id` nullable, RLS deaktiviert
- OutdoorSession hat keinen Live-Abschluss-Flow → kein Upload-Trigger
- Kein Retry bei Offline-Nutzung (Fire-and-forget)
