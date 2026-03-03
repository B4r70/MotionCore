# Design: Workout-Erweiterung — RestTimer, ActiveWorkout & Kraft-Statistiken

**Datum:** 2026-03-03
**Branch:** `refactor/code-refactor`
**Ansatz:** B — Ausgewogenes Feature-Set

---

## Übersicht

Drei Bereiche der MotionCore-App werden erweitert:

1. **RestTimerCard** — Kreisförmiger Ring-Timer mit Zeitanpassung und Haptic-Feedback
2. **ActiveWorkoutStatus** — Session-Volumen-Anzeige im Workout-Header
3. **Kraft-Statistiken** — Neue `StrengthStatisticView` mit Volumen-Trend und 1RM-Progression

---

## Architektur

### Neue Dateien

```
MotionCore/
├── Services/
│   └── Calculation/
│       └── StrengthStatisticCalcEngine.swift
├── Views/
│   ├── Statistics/
│   │   └── Strength/
│   │       ├── View/
│   │       │   └── StrengthStatisticView.swift
│   │       └── Components/
│   │           ├── StrengthVolumeChart.swift
│   │           └── StrengthOneRMChart.swift
```

### Geänderte Dateien

| Datei | Was ändert sich |
|---|---|
| `RestTimerCard.swift` | Kreis-Timer, `+/-15s` Buttons, Haptic |
| `ActiveWorkoutStatus.swift` | Session-Volumen-Anzeige |
| `StatsAndRecordsView.swift` | Neues Segment `StatsSegment.strength` |
| `ExercisesOverviewCard.swift` | Fortschrittspunkte je Übung |

### Kein Eingriff in

- `ActiveSessionManager` — keine Logik-Änderungen
- `CoreSessionCalcEngine` — bleibt unverändert
- Alle bestehenden Modelle

---

## 1. RestTimerCard

### Visuell: Kreisförmiger Ring-Timer

- `ZStack` mit `Circle`-Stroke als Hintergrund und animiertem `trim`-Arc als Fortschritt
- Große Zahl in der Mitte (96pt, `.rounded`, `.monospacedDigit`)
- Farbwechsel am Ring: blau (>30s) → grün → orange (>10s) → rot (≤10s)
- Kein separater Fortschrittsbalken mehr

### Zeitanpassung

```
[ − 15s ]   02:30   [ + 15s ]
```

- Zwei Buttons links/rechts der Zeitanzeige
- Minimum: 5 Sekunden, Maximum: 5 Minuten
- Neuer Callback: `onAdjust(delta: Int)` — Aufrufer (`ActiveWorkoutView`) verwaltet den Wert

### Haptic-Feedback

- Bei `remainingSeconds == 0`: `UINotificationFeedbackGenerator(.success)`
- Ausgelöst in `ActiveWorkoutView.onChange(of: restTimerSeconds)`

### Unverändert

- `nextExerciseName`, `nextSetNumber`, `totalSetsForExercise`
- Skip-Button

---

## 2. ActiveWorkoutStatus

### Neue Volumen-Anzeige

Dritte Kennzahl zwischen Timer und Satz-Zähler:

```
[ 00:45:12 ]    [ 4.250 kg ]    [ 6/12 Sätze ]
─────────────────────────────────────────────
████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
```

- **Volumen** = Summe aller abgeschlossenen Sätze: `weight × reps`
- Formatierung: Tausender-Punkt, ohne Dezimalstellen wenn ganzzahlig
- Label: `"Volumen"` in `.caption` / `.secondary`
- Live-Update nach jedem abgeschlossenen Satz
- Neuer Parameter: `sessionVolume: Double`

### Berechnung (in `ActiveWorkoutView`)

```swift
private var sessionVolume: Double {
    session.safeExerciseSets
        .filter { $0.isCompleted }
        .reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
}
```

### Unverändert

- Timer-Logik, Fortschrittsbalken, `ActiveSessionManager`

---

## 3. Kraft-Statistiken

### StatsAndRecordsView — Neues Segment

```
[ Statistiken ]  [ Rekorde ]  [ Kraft ]
```

### StrengthStatisticView — Aufbau (ScrollView)

**1. Timeframe-Picker** (vorhandene `TimeframePicker`-Komponente)
```
[ Woche ]  [ Monat ]  [ Jahr ]  [ Alles ]
```
Filtert alle Charts und Kennzahlen gleichzeitig.

**2. Kennzahlen-Grid** (2 Spalten, `StatisticGridCard`)
- Gesamt Sessions
- Gesamt Volumen (kg)
- ⌀ Volumen/Session
- ⌀ Sätze/Session

**3. StrengthVolumeChart** — Volumen-Trend
- `BarMark` — Gesamtvolumen pro Session
- X-Achse: Datum, Y-Achse: kg
- Nutzt Swift Charts (analog zu `StatisticTrendChart`)

**4. StrengthOneRMChart** — 1RM-Progression
- Picker: Liste aller trainierten Übungen
- Chart: `LineMark` mit geschätztem 1RM pro Session
- **Formel (Epley):** `weight × (1 + reps / 30)`
- X-Achse: Datum, Y-Achse: kg (est. 1RM)

### StrengthStatisticCalcEngine

Neue Engine analog zu `StatisticCalcEngine`, Input: `[StrengthSession]`

```swift
struct StrengthStatisticCalcEngine {
    let sessions: [StrengthSession]

    var totalSessions: Int
    var totalVolume: Double              // Summe weight × reps aller completed Sets
    var averageVolumePerSession: Double
    var averageSetsPerSession: Double
    var volumeTrend: [TrendPoint]        // Volumen pro Session, chronologisch
    var allTrainedExerciseNames: [String] // Alle Übungsnamen aus allen Sets

    func estimatedOneRM(for exerciseName: String) -> [TrendPoint]
    // Epley: weight × (1 + reps / 30), max je Session
}
```

---

## Nicht in diesem Scope

- Sound-Feedback beim RestTimer
- Swipe-Gesten in ActiveWorkoutView
- Export der Kraft-Statistiken
- Vergleich zwischen Zeiträumen (z.B. diese Woche vs. letzte Woche)
