# Design: Supabase OnUpdate-Sync (Dirty-Flag + ResyncService)

**Datum:** 2026-03-08
**Status:** Approved

---

## Problem

Notizen und andere Felder werden oft erst nach dem Training über `StrengthEditView` oder `FormView` hinzugefügt. Der Supabase-Upload passiert aber direkt beim Training-Abschluss — danach setzt `syncedToSupabase = true`, und es wird nie wieder hochgeladen.

---

## Lösung: Dirty-Flag + ResyncService

### 1. Neues Modell-Feld: `needsSupabaseResync: Bool = false`

In allen drei Session-Modellen:

- `StrengthSession.swift`
- `CardioSession.swift`
- `OutdoorSession.swift`

SwiftData ergänzt neue Felder mit Default-Wert automatisch — keine Migration nötig.

Bedeutung:
- `false` (default): kein ausstehender Resync
- `true`: Session wurde nach erstem Upload geändert → ResyncService soll sie hochladen

---

### 2. Trigger: Wo wird `needsSupabaseResync = true` gesetzt?

**StrengthEditView** (`Views/Workouts/Components/StrengthEditView.swift`):
- "Fertig"-Button: `session.needsSupabaseResync = true` vor `dismiss()`
- Nur wenn `session.syncedToSupabase == true` (nie gesyncte Sessions fallen unter MigrationService)

**FormView** (`Views/Workouts/View/FormView.swift`) — Cardio-Edit:
- Bei Upload-Fehler: `workout.needsSupabaseResync = true` setzen
- FormView macht bereits einen synchronen Upload beim Speichern — falls der fehlschlägt, picked ResyncService die Session auf

**OutdoorSession** (falls ein OutdoorEditView existiert): gleiche Pattern.

---

### 3. Neue Datei: `SupabaseResyncService`

**Pfad:** `Services/Database/Remote/Session/SupabaseResyncService.swift`

```swift
@MainActor
final class SupabaseResyncService {
    static let shared = SupabaseResyncService()

    func syncPendingChanges(in context: ModelContext) async {
        // 1) StrengthSessions mit needsSupabaseResync == true
        // 2) CardioSessions mit needsSupabaseResync == true
        // 3) OutdoorSessions mit needsSupabaseResync == true
        // Für jede: upload() → bei Erfolg needsSupabaseResync = false
        // context.save() am Ende
    }
}
```

Pattern analog zu `SupabaseMigrationService`:
- Sequenzieller Upload (schützt vor Rate-Limit)
- Fehler werden geloggt, nicht weitergereicht
- Kein `@Published`-State nötig (kein UI-Feedback erforderlich)

---

### 4. Aufruf: Wann läuft ResyncService?

**`MotionCoreApp.swift`** — `BaseView().onAppear`:
```swift
Task { await SupabaseResyncService.shared.syncPendingChanges(in: context) }
```

**`BaseView` oder Root-View** — `scenePhase == .active`:
```swift
.onChange(of: scenePhase) { _, phase in
    if phase == .active {
        Task { await SupabaseResyncService.shared.syncPendingChanges(in: context) }
    }
}
```

---

## Betroffene Dateien

| Datei | Aktion |
|-------|--------|
| `Models/Core/StrengthSession.swift` | `needsSupabaseResync: Bool = false` hinzufügen |
| `Models/Core/CardioSession.swift` | `needsSupabaseResync: Bool = false` hinzufügen |
| `Models/Core/OutdoorSession.swift` | `needsSupabaseResync: Bool = false` hinzufügen |
| `Views/Workouts/Components/StrengthEditView.swift` | "Fertig"-Button setzt Flag |
| `Views/Workouts/View/FormView.swift` | Upload-Fehler setzt Flag |
| `Services/Database/Remote/Session/SupabaseResyncService.swift` | Neue Datei |
| `App/MotionCoreApp.swift` | ResyncService bei onAppear + scenePhase |

---

## Nicht im Scope

- UI-Feedback während Resync (kein Spinner/Progress nötig — läuft im Hintergrund)
- Retry-Logik (ein Versuch pro App-Start/Foreground ist ausreichend)
- TrainingPlan-Resync (kein Edit-Flow vorhanden)
