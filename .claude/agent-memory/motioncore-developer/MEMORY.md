# MotionCore Developer Agent Memory

## Kritische Supabase-Encoding-Regel
Sobald ein `CodingKeys`-Enum im Encodable-Struct vorhanden ist, wird `.convertToSnakeCase` IGNORIERT.
→ Alle Properties müssen dann explizit mit Supabase-Spaltennamen gemappt werden.
→ Besonders aufpassen bei: Raw-Suffix, UUID-Abkürzungen, Snapshot-Suffix.

## Bekannte Einschränkungen (Supabase Sync)
- `exerciseUUIDSnapshot: String` ist KEIN UUID-Typ (Int-Hash-String) → Supabase-Spalte `exercise_uuid` muss TEXT sein
- Supabase: nur Anon-Key – kein User-Auth. `user_id` nullable, RLS deaktiviert
- OutdoorSession hat keinen Live-Abschluss-Flow → kein Upload-Trigger
- Kein Retry bei Offline-Nutzung (Fire-and-forget)

## Performance-Falle: ActiveWorkoutView
- `ActiveSessionManager.elapsedSeconds` ist `@Published` → triggert jede Sekunde vollen body-Render
- Computed properties im body-Aufrufpfad MÜSSEN gecacht sein wenn sie SwiftData scannen
- Caching-Pattern: `@State private var cachedX` + `private func refreshX()` + Aufruf in onChange/onAppear

## Preview-Pattern
- Previews die `@Binding` brauchen: immer als Wrapper-Struct implementieren (nicht `@State var` direkt in `#Preview`)
