# Design: Historische Session-Migration nach Supabase

**Datum:** 2026-03-04
**Status:** Freigegeben
**Voraussetzung:** Supabase Session Sync (2026-03-04-supabase-session-sync-design.md) muss aktiv sein

---

## Kontext

Neue Sessions werden seit dem Supabase Session Sync automatisch nach Supabase hochgeladen. Alle vor diesem Feature erstellten Sessions existieren nur lokal in SwiftData/CloudKit. Ziel ist eine einmalige, vom User gestartete Migration aller historischen Sessions.

---

## Architektur-Entscheidungen

| Frage | Entscheidung |
|---|---|
| Trigger | Einstellungen-Screen (manueller Button) |
| Deduplizierung | `syncedToSupabase: Bool` Flag in SwiftData |
| UI | Progress Bar + Zähler (`X / Y hochgeladen`) |
| Upload-Strategie | Sequenziell (Anon-Key Rate-Limit Schutz) |
| Fehlerverhalten | Session überspringen, `failedCount` inkrementieren, beim nächsten Mal automatisch wiederholt |

---

## SwiftData-Änderungen

Vier Modelle bekommen eine neue Property:

```swift
// StrengthSession, CardioSession, OutdoorSession, TrainingPlan:
var syncedToSupabase: Bool = false
```

- Default `false` → keine SwiftData-Migration nötig
- Wird auf `true` gesetzt: nach erfolgreichem Upload (Migration + normaler Abschluss)
- Die bestehenden `upload()`-Aufrufe beim Session-Abschluss werden ebenfalls auf `true` setzen

---

## Neue Dateien

```
Services/Database/Remote/Session/
└── SupabaseMigrationService.swift    # Migration-Logik + ObservableObject
```

### `SupabaseMigrationService`

```swift
@MainActor
final class SupabaseMigrationService: ObservableObject {
    static let shared = SupabaseMigrationService()

    @Published var isRunning: Bool = false
    @Published var uploadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var failedCount: Int = 0

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(uploadedCount + failedCount) / Double(totalCount)
    }

    var isDone: Bool { !isRunning && totalCount > 0 }

    func migrate(context: ModelContext) async
}
```

**Migrations-Ablauf:**
1. Alle `StrengthSession`, `CardioSession`, `OutdoorSession`, `TrainingPlan` mit `syncedToSupabase == false` laden
2. `totalCount` setzen, `isRunning = true`
3. Sequenziell pro Session:
   - `await SupabaseSessionService.shared.upload(session)` aufrufen
   - Bei Erfolg: `session.syncedToSupabase = true`, `uploadedCount += 1`
   - Bei Fehler: `failedCount += 1` (Session bleibt `false`, wird beim nächsten Mal wiederholt)
4. Nach allen Sessions: `isRunning = false`, `context.save()`

---

## UI-Integration

### `SupabaseSyncSection` (neuer View)

Wird in den bestehenden `SettingsView` eingebettet.

**Zustände:**

```
[Idle – ungemigrigte Sessions vorhanden]
Section("Supabase Sync") {
    Button("Historische Sessions synchronisieren") { ... }
    Text("X Sessions noch nicht hochgeladen")
}

[Läuft]
Section("Supabase Sync") {
    ProgressView(value: service.progress)
    Text("\(service.uploadedCount) / \(service.totalCount) hochgeladen…")
}

[Fertig]
Section("Supabase Sync") {
    Label("147 Sessions hochgeladen", systemImage: "checkmark.circle.fill")
    if service.failedCount > 0 {
        Text("\(service.failedCount) fehlgeschlagen – beim nächsten Sync wiederholt")
    }
}
```

---

## Integration mit bestehendem Upload-Flow

Nach erfolgreichem Upload in `SupabaseSessionService.upload()` das Flag setzen:

```swift
// In ActiveWorkoutView.finishWorkout():
Task {
    await SupabaseSessionService.shared.upload(session)
    session.syncedToSupabase = true
}
```

Gleiches Muster für CardioSession und TrainingPlan.

---

## Erfolgskriterien

- [ ] `syncedToSupabase: Bool = false` in allen 4 Session-Modellen
- [ ] `SupabaseMigrationService` mit `@Published` Progress-Properties
- [ ] Button in `SettingsView` startet Migration
- [ ] ProgressView zeigt X/Y Zähler live
- [ ] Nach Abschluss: Erfolgs- und Fehler-Meldung sichtbar
- [ ] Flag wird auch bei regulärem Session-Abschluss gesetzt
- [ ] Keine Duplikate in Supabase
