# Design: Apple Watch Integration

**Datum:** 2026-03-06
**Status:** Freigegeben

---

## Ziel

Native WatchOS App für MotionCore mit zwei Kernfunktionen:
1. **Watch Face Complications** — Streak und Weekly Progress passiv anzeigen
2. **Remote Control** — Aktives Workout von der Watch aus steuern (Pause/Resume, Satz abschließen, Übung wechseln)

---

## Kontext

- Kein WatchOS-Target existiert bisher
- HealthKit und App Group `group.com.barto.motioncore` sind bereits konfiguriert
- Live Activities (Dynamic Island) sind bereits implementiert — bleiben unverändert
- Alle Session-Models haben `healthKitWorkoutUUID` und `deviceSource` Felder bereits
- Watch-Steuerung ist **Remote Control only** — Watch ist Controller für iPhone, kein eigenständiges Tracking

---

## Architektur

### Targets

```
Projekt
├── MotionCore (iPhone) ← bestehend
│   └── Services/Watch/PhoneSessionManager.swift  ← neu
├── MotionCoreWatch (Watch) ← neu (watchOS 10+, SwiftUI)
│   ├── MotionCoreWatchApp.swift
│   ├── Views/
│   │   ├── IdleView.swift
│   │   └── ActiveWorkoutView.swift
│   ├── Services/
│   │   └── WatchSessionManager.swift
│   └── Complications/
│       ├── StreakComplication.swift
│       └── WeeklyProgressComplication.swift
└── MotionCoreWidgetsExtension (iOS Widgets) ← unverändert
```

### Kommunikation

| Kanal | Verwendung |
|-------|-----------|
| `WatchConnectivity` (WCSession) | Live Remote Control — bidirektional, niedrige Latenz |
| App Group UserDefaults | Complications-Daten (Streak, Weekly Progress) — iPhone schreibt, Watch liest |

---

## Watch UI

### Idle Screen (kein aktives Workout)

```
┌─────────────────┐
│  🔥 12          │
│  Streak         │
│                 │
│  ████░░  3/5    │
│  Diese Woche    │
│                 │
│  Kein Workout   │
│  aktiv          │
└─────────────────┘
```

### Active Workout Screen (Remote Control)

```
┌─────────────────┐
│  12:34  ⏸       │
│                 │
│  Bench Press    │
│  Übung 2/6      │
│                 │
│  ┌───────────┐  │
│  │  ✓ Satz   │  │
│  │   2 / 4   │  │
│  └───────────┘  │
│                 │
│  ◀◀        ▶▶  │
└─────────────────┘
```

- **Hauptaktion:** Großer "Satz ✓" Button
- **Pause/Resume:** Tap auf Timer-Bereich oben links
- **Übung wechseln:** ◀◀ / ▶▶ unten

---

## WatchConnectivity Message-Flow

### iPhone → Watch (State Updates)

Gesendet bei jedem relevanten Event (Satz-Abschluss, Pause, Übungswechsel, Workout-Ende):

```swift
[
    "workoutState": "idle" | "active" | "paused",
    "exerciseName": String,
    "setIndex": Int,        // 0-basiert
    "totalSets": Int,
    "exerciseIndex": Int,   // 0-basiert
    "totalExercises": Int,
    "elapsedTime": TimeInterval
]
```

### Watch → iPhone (Actions)

```swift
["action": "pauseResume" | "completeSet" | "nextExercise" | "previousExercise"]
```

iPhone verarbeitet die Action und schickt sofort den neuen State zurück.

---

## Watch Face Complications

### Streak Complication

| WidgetFamily | Aussehen |
|-------------|---------|
| `.accessoryCorner` | `🔥 12` |
| `.accessoryCircular` | Flammen-Symbol + Zahl |

### Weekly Progress Complication

| WidgetFamily | Aussehen |
|-------------|---------|
| `.accessoryCircular` | Bogen-Gauge, Zahl in der Mitte |
| `.accessoryRectangular` | Fortschrittsbalken + "3 / 5 Workouts" |

### Daten-Update-Strategie

- iPhone schreibt nach `UserDefaults(suiteName: "group.com.barto.motioncore")` nach jedem Workout-Abschluss:
  - `watch_streak_count: Int`
  - `watch_weekly_workout_count: Int`
  - `watch_weekly_workout_goal: Int` (Default: 5)
- `WidgetCenter.shared.reloadTimelines(ofKind:)` triggert Complication-Update
- Kein Background-Refresh nötig — Update nur nach echtem Workout-Abschluss

---

## Nicht im Scope

- Standalone Watch Workout (ohne iPhone)
- WorkoutKit / HKWorkoutSession auf der Watch
- Herzfrequenz-Anzeige im aktiven Workout
- Watch-seitige SwiftData / CloudKit Sync
- Änderungen an Live Activities / Dynamic Island

---

## Implementierungs-Reihenfolge (empfohlen)

1. **WatchOS Target anlegen** (Xcode, manuell durch Barto)
2. **WatchConnectivity** — PhoneSessionManager (iPhone) + WatchSessionManager (Watch)
3. **Watch UI** — IdleView + ActiveWorkoutView
4. **Complications** — StreakComplication + WeeklyProgressComplication
5. **Integration** — iPhone-seitige Daten-Updates nach Workout-Abschluss
