# Supabase Historical Session Migration – Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Alle historischen Sessions (StrengthSession, CardioSession, OutdoorSession, TrainingPlan) können per Button in den Einstellungen einmalig nach Supabase hochgeladen werden – mit Progress Bar und Zähler.

**Architecture:** Ein `syncedToSupabase: Bool = false` Flag in jedem Session-Modell trackt den Sync-Status. `upload()` Methoden geben jetzt `Bool` zurück (true = Erfolg). `SupabaseMigrationService` iteriert sequenziell über alle ungemigrierten Sessions und setzt das Flag nach Erfolg. Ein neuer `SupabaseSyncSection` View in `MainSettingsView` zeigt Progress und Ergebnis.

**Tech Stack:** SwiftUI, SwiftData, `SupabaseSessionService` (bereits vorhanden), `SupabaseMigrationService` (neu)

---

## Task 1: syncedToSupabase Flag zu allen Session-Modellen hinzufügen

**Files:**
- Modify: `MotionCore/Models/Core/StrengthSession.swift`
- Modify: `MotionCore/Models/Core/CardioSession.swift`
- Modify: `MotionCore/Models/Core/OutdoorSession.swift`
- Modify: `MotionCore/Models/Core/TrainingPlan.swift`

### Schritt 1: Jede Datei lesen

Lies alle vier Dateien um den richtigen Einfügepunkt zu finden (nach den letzten bestehenden Properties, vor Computed Properties / Relationships).

### Schritt 2: Property hinzufügen

In **jeder** der vier `@Model`-Klassen, füge direkt nach dem Block der anderen Bool-Properties ein:

```swift
/// Wurde diese Session bereits zu Supabase hochgeladen?
var syncedToSupabase: Bool = false
```

Kein `@Attribute` nötig – ein einfacher SwiftData-Property mit Default-Value erfordert keine Migration.

### Schritt 3: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Models/Core/StrengthSession.swift
git add MotionCore/Models/Core/CardioSession.swift
git add MotionCore/Models/Core/OutdoorSession.swift
git add MotionCore/Models/Core/TrainingPlan.swift
git commit -m "feat: add syncedToSupabase flag to all session models"
```

**Verifikation:** Überprüfe nach dem Commit dass alle 4 Dateien die Property enthalten und keine existierende Property verdrängt wurde.

---

## Task 2: upload() Methoden zu Bool Return-Type umbauen

**Files:**
- Modify: `MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift`

Die bestehenden `upload()` Methoden geben `Void` zurück. Wir brauchen `Bool` um im Aufrufer zu wissen ob der Upload erfolgreich war.

### Schritt 1: Datei lesen

Lies `/Users/bartosz/Developments/MotionCore/MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift`

### Schritt 2: Alle vier upload()-Signaturen anpassen

Jede Methode von `func upload(...) async` zu `func upload(...) async -> Bool` ändern.

**Muster für StrengthSession (die anderen analog):**

```swift
// ALT:
func upload(_ session: StrengthSession) async {
    do {
        // ... upload logic ...
        print("✅ StrengthSession \(session.sessionUUID) hochgeladen (\(setDTOs.count) Sets)")
    } catch {
        print("⚠️ Supabase Upload fehlgeschlagen (StrengthSession): \(error.localizedDescription)")
    }
}

// NEU:
@discardableResult
func upload(_ session: StrengthSession) async -> Bool {
    do {
        // ... upload logic (unverändert) ...
        print("✅ StrengthSession \(session.sessionUUID) hochgeladen (\(setDTOs.count) Sets)")
        return true
    } catch {
        print("⚠️ Supabase Upload fehlgeschlagen (StrengthSession): \(error.localizedDescription)")
        return false
    }
}
```

`@discardableResult` → bestehende Aufrufer (ActiveWorkoutView etc.) kompilieren weiterhin ohne Änderung.

Alle vier Methoden anpassen:
- `upload(_ session: StrengthSession) async -> Bool`
- `upload(_ session: CardioSession) async -> Bool`
- `upload(_ session: OutdoorSession) async -> Bool`
- `upload(_ plan: TrainingPlan) async -> Bool`

### Schritt 3: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift
git commit -m "feat: upload() returns Bool for success tracking"
```

---

## Task 3: syncedToSupabase = true in bestehenden Upload-Aufrufen setzen

**Files:**
- Modify: `MotionCore/Views/Workouts/Strength/Active/ActiveWorkoutView.swift` (ca. Zeile 547)
- Modify: `MotionCore/Views/Workouts/Cardio/FormView.swift` (ca. Zeile 139)
- Modify: `MotionCore/Views/Workouts/Training/TrainingFormView.swift` (ca. Zeile 157)

Nach einem erfolgreichen Upload soll das Flag gesetzt werden. Aber: Die Aufrufe laufen in einem `Task { }` Block – wir müssen den `ModelContext` zugänglich machen oder direkt am Session-Objekt setzen.

### Schritt 1: Alle drei Dateien lesen

Lies die drei Dateien und finde die `Task { await SupabaseSessionService.shared.upload(...) }` Blöcke.

### Schritt 2: Flag nach erfolgreichem Upload setzen

**Pattern (für alle drei Stellen):**

```swift
// ALT:
Task {
    await SupabaseSessionService.shared.upload(session)
}

// NEU:
Task {
    let success = await SupabaseSessionService.shared.upload(session)
    if success {
        await MainActor.run {
            session.syncedToSupabase = true
            try? context.save()
        }
    }
}
```

**Hinweis:** SwiftData-Objekte müssen auf dem MainActor modifiziert werden. Prüfe ob `context` (ModelContext) an der jeweiligen Stelle bereits als `@Environment(\.modelContext)` verfügbar ist. Falls nicht, ist es in `@Environment(\.modelContext) private var context` zu finden.

### Schritt 3: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Views/Workouts/Strength/Active/ActiveWorkoutView.swift
git add MotionCore/Views/Workouts/Cardio/FormView.swift
git add MotionCore/Views/Workouts/Training/TrainingFormView.swift
git commit -m "feat: set syncedToSupabase=true after successful upload"
```

---

## Task 4: SupabaseMigrationService erstellen

**Files:**
- Create: `MotionCore/Services/Database/Remote/Session/SupabaseMigrationService.swift`

### Schritt 1: Header aus bestehender Datei kopieren

Lies `/Users/bartosz/Developments/MotionCore/MotionCore/Services/Database/Remote/Session/SupabaseSessionService.swift` für den korrekten Datei-Header-Stil.

### Schritt 2: Datei erstellen

```swift
//  SupabaseMigrationService.swift
//  MotionCore
//
//  Lädt alle historischen Sessions einmalig nach Supabase hoch.

import Foundation
import SwiftData

/// Migriert alle lokalen Sessions, die noch nicht in Supabase sind.
@MainActor
final class SupabaseMigrationService: ObservableObject {

    static let shared = SupabaseMigrationService()

    // MARK: - Published State

    @Published var isRunning: Bool = false
    @Published var uploadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var failedCount: Int = 0

    /// Gesamtfortschritt 0.0–1.0
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(uploadedCount + failedCount) / Double(totalCount)
    }

    /// true wenn Migration abgeschlossen (nicht laufend, aber mindestens eine Session verarbeitet)
    var isDone: Bool { !isRunning && totalCount > 0 }

    /// Noch ungemigrigte Sessions vorhanden?
    var hasPendingSessions: Bool { !isRunning && !isDone }

    private init() {}

    // MARK: - Migration

    /// Startet die einmalige Migration aller lokalen Sessions nach Supabase.
    func migrate(context: ModelContext) async {
        guard !isRunning else { return }

        isRunning = true
        uploadedCount = 0
        failedCount = 0

        // Alle ungemigrierten Sessions laden
        let strengthSessions = (try? context.fetch(
            FetchDescriptor<StrengthSession>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        let cardioSessions = (try? context.fetch(
            FetchDescriptor<CardioSession>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        let outdoorSessions = (try? context.fetch(
            FetchDescriptor<OutdoorSession>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        let trainingPlans = (try? context.fetch(
            FetchDescriptor<TrainingPlan>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        totalCount = strengthSessions.count + cardioSessions.count
                   + outdoorSessions.count + trainingPlans.count

        guard totalCount > 0 else {
            isRunning = false
            return
        }

        // Sequenzieller Upload (Anon-Key Rate-Limit)
        for session in strengthSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        for session in cardioSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        for session in outdoorSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        for plan in trainingPlans {
            let success = await SupabaseSessionService.shared.upload(plan)
            if success {
                plan.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        // Alle gesetzten Flags speichern
        try? context.save()

        isRunning = false
        print("✅ Migration abgeschlossen: \(uploadedCount) hochgeladen, \(failedCount) fehlgeschlagen")
    }
}
```

### Schritt 3: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Services/Database/Remote/Session/SupabaseMigrationService.swift
git commit -m "feat: add SupabaseMigrationService for historical session upload"
```

---

## Task 5: SupabaseSyncSection View + MainSettingsView Integration

**Files:**
- Create: `MotionCore/Views/Settings/Components/SupabaseSyncSection.swift`
- Modify: `MotionCore/Views/Settings/View/MainSettingsView.swift`

### Schritt 1: Bestehende Dateien lesen

Lies:
- `MotionCore/Views/Settings/View/MainSettingsView.swift` – um den Aufbau zu verstehen und den richtigen Einfügepunkt zu finden (in der "Daten-Management"-Section)
- Eine andere Settings-Component aus `MotionCore/Views/Settings/Components/` für den Datei-Header-Stil

### Schritt 2: SupabaseSyncSection.swift erstellen

```swift
//  SupabaseSyncSection.swift
//  MotionCore

import SwiftUI
import SwiftData

/// Zeigt den Supabase-Sync-Status und ermöglicht die einmalige historische Migration.
struct SupabaseSyncSection: View {

    @Environment(\.modelContext) private var context
    @StateObject private var service = SupabaseMigrationService.shared

    var body: some View {
        Section("Supabase Sync") {
            if service.isRunning {
                // Laufende Migration
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: service.progress)
                    Text("\(service.uploadedCount) / \(service.totalCount) hochgeladen…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

            } else if service.isDone {
                // Abgeschlossen
                Label(
                    "\(service.uploadedCount) Sessions hochgeladen",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)

                if service.failedCount > 0 {
                    Text("\(service.failedCount) fehlgeschlagen – beim nächsten Sync wiederholt")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

            } else {
                // Idle – Button anzeigen
                Button("Historische Sessions synchronisieren") {
                    Task {
                        await service.migrate(context: context)
                    }
                }
            }
        }
    }
}
```

### Schritt 3: SupabaseSyncSection in MainSettingsView einbinden

In `MainSettingsView.swift`, finde die "Daten-Management"-Section. Füge `SupabaseSyncSection()` **am Ende dieser Section** oder als eigene Section darunter ein.

```swift
// In der bestehenden List/Form in MainSettingsView:
SupabaseSyncSection()
```

### Schritt 4: Build-Test

In Xcode: **⌘ + B** – sicherstellen dass keine Compile-Errors entstehen.

Häufige Probleme:
- `SupabaseMigrationService` ist `@MainActor` aber wird aus nicht-MainActor-Kontext aufgerufen → `Task { @MainActor in ... }`
- `@StateObject` vs `@ObservedObject` – `@StateObject` ist korrekt für die `Section`-View, da sie den Service ownt

### Schritt 5: Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add MotionCore/Views/Settings/Components/SupabaseSyncSection.swift
git add MotionCore/Views/Settings/View/MainSettingsView.swift
git commit -m "feat: add SupabaseSyncSection to Settings for historical migration UI"
```

---

## Task 6: Manueller End-to-End Test

### Schritt 1: App im Simulator starten

In Xcode: **⌘ + R** mit einem Simulator-Gerät.

### Schritt 2: Settings navigieren

Öffne die App → Settings → "Daten-Management" (oder die neue Supabase-Section) → Button "Historische Sessions synchronisieren" sollte sichtbar sein.

### Schritt 3: Migration starten

Button drücken. Erwartetes Verhalten:
- ProgressView erscheint sofort
- Zähler inkrementiert live
- Nach Abschluss: "✅ X Sessions hochgeladen"

### Schritt 4: Supabase Dashboard verifizieren

Öffne https://app.supabase.com → MotionCore → Table Editor → `strength_sessions`, `cardio_sessions`, `outdoor_sessions`, `training_plans` prüfen.

Erwartetes Ergebnis: Alle historischen Sessions erscheinen in den Tabellen.

### Schritt 5: Idempotenz prüfen

Button erneut drücken. Da alle Sessions `syncedToSupabase = true` haben, sollte die Migration sofort enden (kein Upload, kein Progress).

### Schritt 6: Abschluss-Commit

```bash
cd /Users/bartosz/Developments/MotionCore
git add -A
git commit -m "feat: complete historical Supabase session migration

syncedToSupabase Flag in allen Session-Modellen.
SupabaseMigrationService mit sequenziellem Upload und Progress.
SupabaseSyncSection im Settings-Screen.
"
```
