# Supabase OnUpdate-Sync — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Nachträgliche Änderungen an Sessions (z.B. Notizen nach Training) automatisch nach Supabase syncen — via Dirty-Flag (`needsSupabaseResync`) und einem ResyncService, der bei App-Start und Foreground-Rückkehr läuft.

**Architecture:** Neues `needsSupabaseResync: Bool = false` Feld in allen drei Session-Modellen (SwiftData, kein Migration-Script nötig). Edit-Views setzen das Flag beim Speichern. `SupabaseResyncService` (analog zu `SupabaseMigrationService`) läuft beim App-Start und Foreground-Rückkehr, liest alle Sessions mit `needsSupabaseResync == true`, lädt sie hoch und setzt das Flag zurück.

**Tech Stack:** SwiftUI, SwiftData, `SupabaseSessionService` (bereits vorhanden), `ModelContext`, `scenePhase`

---

## Hinweise für alle Tasks

- Projektpfad: `/Users/bartosz/Developments/MotionCore/`
- Kein CLI-Build. Verifikation: `Cmd+B` in Xcode + SwiftUI Preview prüfen
- Standard-Header jeder neuen Datei von bestehender Datei kopieren (z.B. `SupabaseMigrationService.swift`)
- Commit-Präfix: `feat()`, `fix()`
- `SupabaseSessionService.shared.upload()` existiert bereits für alle drei Session-Typen
- `SupabaseMigrationService.swift` als Referenz-Implementierung für Fetch-Pattern nutzen

---

## Task 1: `needsSupabaseResync`-Feld in Session-Modellen

**Dateien:**
- Modify: `MotionCore/Models/Core/StrengthSession.swift`
- Modify: `MotionCore/Models/Core/CardioSession.swift`
- Modify: `MotionCore/Models/Core/OutdoorSession.swift`

### Schritt 1: StrengthSession — Feld einfügen

Öffne `MotionCore/Models/Core/StrengthSession.swift`. Nach der Zeile `var syncedToSupabase: Bool = false` einfügen:

```swift
/// Wurde die Session nach erstem Supabase-Upload lokal geändert?
/// true → ResyncService soll beim nächsten App-Start/Foreground hochladen.
var needsSupabaseResync: Bool = false
```

### Schritt 2: CardioSession — Feld einfügen

Öffne `MotionCore/Models/Core/CardioSession.swift`. Nach `var syncedToSupabase: Bool = false` einfügen:

```swift
/// Wurde die Session nach erstem Supabase-Upload lokal geändert?
var needsSupabaseResync: Bool = false
```

### Schritt 3: OutdoorSession — Feld einfügen

Öffne `MotionCore/Models/Core/OutdoorSession.swift`. Nach `var syncedToSupabase: Bool = false` einfügen:

```swift
/// Wurde die Session nach erstem Supabase-Upload lokal geändert?
var needsSupabaseResync: Bool = false
```

### Schritt 4: Build prüfen

`Cmd+B` in Xcode. SwiftData ergänzt neue Felder mit Default-Wert automatisch — kein Migration-Script nötig. Build muss fehlerfrei sein.

### Schritt 5: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Models/Core/StrengthSession.swift \
        MotionCore/Models/Core/CardioSession.swift \
        MotionCore/Models/Core/OutdoorSession.swift
git commit -m "feat(model): needsSupabaseResync-Feld zu allen Session-Modellen hinzufügen"
```

---

## Task 2: `SupabaseResyncService` erstellen

**Dateien:**
- Create: `MotionCore/Services/Database/Remote/Session/SupabaseResyncService.swift`

### Schritt 1: Datei anlegen

Kopiere den Header aus `SupabaseMigrationService.swift`. Vollständiger Inhalt:

```swift
// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseResyncService.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-08                                                       /
// Beschreibung  : Synct Sessions die nach erstem Upload lokal geändert wurden    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Läuft bei App-Start und Foreground-Rückkehr.                  /
//                needsSupabaseResync wird nach Erfolg auf false gesetzt.        /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

/// Lädt Sessions hoch, die nach erstem Supabase-Upload lokal verändert wurden.
/// Wird bei App-Start und Foreground-Rückkehr aufgerufen.
@MainActor
final class SupabaseResyncService {

    static let shared = SupabaseResyncService()
    private init() {}

    // MARK: - Resync

    /// Sucht alle Sessions mit `needsSupabaseResync == true` und lädt sie hoch.
    /// Nach erfolgreichem Upload: `needsSupabaseResync = false`.
    func syncPendingChanges(in context: ModelContext) async {
        var didChange = false

        // MARK: StrengthSessions
        let strengthSessions = (try? context.fetch(
            FetchDescriptor<StrengthSession>(
                predicate: #Predicate { $0.needsSupabaseResync }
            )
        )) ?? []

        for session in strengthSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.needsSupabaseResync = false
                didChange = true
                print("🔄 StrengthSession re-synced: \(session.sessionUUID)")
            } else {
                print("⚠️ StrengthSession re-sync fehlgeschlagen: \(session.sessionUUID)")
            }
        }

        // MARK: CardioSessions
        let cardioSessions = (try? context.fetch(
            FetchDescriptor<CardioSession>(
                predicate: #Predicate { $0.needsSupabaseResync }
            )
        )) ?? []

        for session in cardioSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.needsSupabaseResync = false
                didChange = true
                print("🔄 CardioSession re-synced: \(session.sessionUUID)")
            } else {
                print("⚠️ CardioSession re-sync fehlgeschlagen: \(session.sessionUUID)")
            }
        }

        // MARK: OutdoorSessions
        let outdoorSessions = (try? context.fetch(
            FetchDescriptor<OutdoorSession>(
                predicate: #Predicate { $0.needsSupabaseResync }
            )
        )) ?? []

        for session in outdoorSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.needsSupabaseResync = false
                didChange = true
                print("🔄 OutdoorSession re-synced: \(session.sessionUUID)")
            } else {
                print("⚠️ OutdoorSession re-sync fehlgeschlagen: \(session.sessionUUID)")
            }
        }

        // Flags persistieren
        if didChange {
            try? context.save()
        }
    }
}
```

### Schritt 2: Build prüfen

`Cmd+B`. `SupabaseResyncService` muss ohne Fehler kompilieren. `StrengthSession`, `CardioSession`, `OutdoorSession` haben jetzt das `needsSupabaseResync`-Feld (Task 1).

### Schritt 3: Commit

```bash
git add MotionCore/Services/Database/Remote/Session/SupabaseResyncService.swift
git commit -m "feat(service): SupabaseResyncService für nachträgliche Session-Updates"
```

---

## Task 3: Trigger in `StrengthEditView`

**Datei:** `MotionCore/Views/Workouts/Components/StrengthEditView.swift`

### Schritt 1: Datei lesen

Lies die Datei vollständig. Der relevante Bereich ist das Toolbar mit dem "Fertig"-Button (ca. Zeile 102-106):

```swift
ToolbarItem(placement: .confirmationAction) {
    Button("Fertig") {
        dismiss()
    }
    .fontWeight(.semibold)
}
```

### Schritt 2: "Fertig"-Button anpassen

Ersetze den Button-Inhalt durch:

```swift
ToolbarItem(placement: .confirmationAction) {
    Button("Fertig") {
        if session.syncedToSupabase {
            session.needsSupabaseResync = true
        }
        dismiss()
    }
    .fontWeight(.semibold)
}
```

**Warum `syncedToSupabase`-Check?** Sessions, die noch nie hochgeladen wurden (`syncedToSupabase == false`), werden vom bestehenden `SupabaseMigrationService` aufgegriffen. Wir setzen `needsSupabaseResync` nur für Sessions, die bereits in Supabase existieren.

### Schritt 3: Build prüfen

`Cmd+B`.

### Schritt 4: Commit

```bash
git add MotionCore/Views/Workouts/Components/StrengthEditView.swift
git commit -m "feat(edit): StrengthEditView setzt needsSupabaseResync beim Speichern"
```

---

## Task 4: Trigger in `FormView` (CardioSession Edit-Modus)

**Datei:** `MotionCore/Views/Workouts/View/FormView.swift`

### Schritt 1: Datei lesen

Lies die Datei. Der relevante Speichern-Button (ca. Zeile 131-155):

```swift
ToolbarItem(placement: .confirmationAction) {
    Button {
        dismissKeyboard()
        if mode == .add { context.insert(workout) }
        try? context.save()

        // Supabase-Upload nur bei neuen Sessions
        if mode == .add {
            Task {
                let success = await SupabaseSessionService.shared.upload(workout)
                if success {
                    await MainActor.run {
                        workout.syncedToSupabase = true
                        try? context.save()
                    }
                }
            }
        }

        dismiss()
    } label: { ... }
}
```

### Schritt 2: Edit-Modus Resync-Flag einfügen

Ersetze den gesamten Button-Action-Block durch:

```swift
Button {
    dismissKeyboard()
    if mode == .add { context.insert(workout) }
    try? context.save()

    if mode == .add {
        // Neue Session: direkt hochladen
        Task {
            let success = await SupabaseSessionService.shared.upload(workout)
            if success {
                await MainActor.run {
                    workout.syncedToSupabase = true
                    try? context.save()
                }
            }
        }
    } else if mode == .edit, workout.syncedToSupabase {
        // Bestehende Session: für Resync markieren
        workout.needsSupabaseResync = true
        try? context.save()
    }

    dismiss()
} label: { ... }
```

**Hinweis:** Das `label:` (IconType-Button) bleibt unverändert — nur der Action-Block ändert sich.

### Schritt 3: Build prüfen

`Cmd+B`.

### Schritt 4: Commit

```bash
git add MotionCore/Views/Workouts/View/FormView.swift
git commit -m "feat(edit): FormView setzt needsSupabaseResync bei Cardio-Session Edit"
```

---

## Task 5: ResyncService in `BaseView` integrieren

**Datei:** `MotionCore/Views/Root/View/BaseView.swift`

### Schritt 1: Datei lesen

Lies `BaseView.swift`. Relevante Stellen:
- `@Environment(\.modelContext) private var context` (ca. Zeile 22) — bereits vorhanden
- `.onAppear { ... }` Block (ca. Zeile 289-297) — dort läuft bereits `repairSnapshotsOnLaunch`
- Die View hat noch **kein** `@Environment(\.scenePhase)`

### Schritt 2: scenePhase-Property hinzufügen

Im `struct BaseView: View`, bei den anderen `@Environment`-Properties, hinzufügen:

```swift
@Environment(\.scenePhase) private var scenePhase
```

### Schritt 3: ResyncService in onAppear einbauen

Den bestehenden `.onAppear`-Block suchen:

```swift
.onAppear {
    guard !didRepair else { return }
    didRepair = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        repairSnapshotsOnLaunch(context: context)
    }
}
```

Ersetzen durch:

```swift
.onAppear {
    guard !didRepair else { return }
    didRepair = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        repairSnapshotsOnLaunch(context: context)
        // Ausstehende Supabase-Updates nach App-Start syncen
        Task {
            await SupabaseResyncService.shared.syncPendingChanges(in: context)
        }
    }
}
```

### Schritt 4: scenePhase-Handler hinzufügen

Nach dem `.onAppear`-Block (und vor dem letzten `.alert`/`.sheet`-Modifier) einfügen:

```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        Task {
            await SupabaseResyncService.shared.syncPendingChanges(in: context)
        }
    }
}
```

**Hinweis:** `newPhase == .active` feuert bei Foreground-Rückkehr und nicht beim ersten Start (dafür ist `.onAppear` zuständig). Doppelter Aufruf beim Start ist kein Problem — `syncPendingChanges` prüft selbst ob Sessions vorhanden sind.

### Schritt 5: Build prüfen

`Cmd+B`.

### Schritt 6: Manuell testen

1. Training in MotionCore abschließen — `syncedToSupabase = true` wird gesetzt
2. Training in der Liste öffnen → StrengthEditView → Notiz hinzufügen → "Fertig"
3. App in Hintergrund → zurückkehren (oder App neu starten)
4. Xcode Console: `🔄 StrengthSession re-synced: <UUID>` soll erscheinen
5. In Supabase Dashboard prüfen: `strength_sessions`-Tabelle → Notiz-Feld aktualisiert

### Schritt 7: Commit

```bash
git add MotionCore/Views/Root/View/BaseView.swift
git commit -m "feat(sync): SupabaseResyncService in BaseView bei App-Start und Foreground integrieren"
```

---

## Gesamt-Übersicht

| Task | Datei | Aktion |
|------|-------|--------|
| 1 | `Models/Core/StrengthSession.swift` | `needsSupabaseResync` Feld |
| 1 | `Models/Core/CardioSession.swift` | `needsSupabaseResync` Feld |
| 1 | `Models/Core/OutdoorSession.swift` | `needsSupabaseResync` Feld |
| 2 | `Services/.../SupabaseResyncService.swift` | Neue Datei |
| 3 | `Views/.../StrengthEditView.swift` | "Fertig" setzt Flag |
| 4 | `Views/.../FormView.swift` | Edit-Modus setzt Flag |
| 5 | `Views/Root/View/BaseView.swift` | ResyncService-Integration |

**5 Commits insgesamt.**

---

## Abschluss-Verifikation

```bash
git log --oneline -6
```

Erwartete Ausgabe (5 neue + 1 Design-Commit):
```
feat(sync): SupabaseResyncService in BaseView bei App-Start und Foreground integrieren
feat(edit): FormView setzt needsSupabaseResync bei Cardio-Session Edit
feat(edit): StrengthEditView setzt needsSupabaseResync beim Speichern
feat(service): SupabaseResyncService für nachträgliche Session-Updates
feat(model): needsSupabaseResync-Feld zu allen Session-Modellen hinzufügen
docs(): Design-Dokument Supabase OnUpdate-Sync (Dirty-Flag + ResyncService)
```
