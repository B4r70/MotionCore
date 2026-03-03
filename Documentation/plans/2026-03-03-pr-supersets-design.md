# PR-Erkennung & Supersets — Design

## Ziel

Zwei neue Features für das aktive Workout-Erlebnis:
1. **PR-Erkennung** — Live-Erkennung persönlicher Bestleistungen beim Satz-Abschluss
2. **Supersets** — Gruppierung von 2+ Übungen ohne automatischen Sprung, mit visueller Kennzeichnung

## Architektur

### Neues Feld in ExerciseSet

```swift
var supersetGroupId: String? = nil
// nil    = normaler Satz
// String = UUID-basierter Schlüssel, gleicher Wert = gleiche Superset-Gruppe
```

SwiftData Migration: non-destructive (optionales Feld, Default nil). Bestehende Daten unberührt.

### Neue Dateien

| Datei | Zweck |
|-------|-------|
| `MotionCore/Services/Detection/PRDetectionService.swift` | Pure struct — PR-Erkennung via Epley-Formel |

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `MotionCore/Models/Core/ExerciseSet.swift` | +`supersetGroupId: String?` |
| `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` | PR-Prüfung bei Set-Abschluss, Banner-State, PR-Set-IDs |
| `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift` | Kronen-Icon für PR-Sätze |
| `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift` | Superset-Klammer + Icon |
| `MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift` | Swipe-Action Superset erstellen/auflösen |
| `MotionCore/Views/Training/Plans/Components/TemplateSetCard.swift` | Superset-Icon im Plan-Editor |

---

## Feature 1: Supersets

### Datenmodell

`supersetGroupId: String?` in `ExerciseSet`. Alle Übungen mit gleichem Wert gehören zur selben Superset-Gruppe. Trisets und größere Gruppen werden durch denselben Mechanismus unterstützt.

### Plan-Editor (`PlanExercisesSection`)

- Swipe-Left auf eine Übung → Button „Superset mit nächster"
- Beide Übungen erhalten dieselbe `supersetGroupId` (UUID-String)
- Swipe-Left auf verbundene Übung → „Superset auflösen" (setzt `supersetGroupId = nil` für alle in der Gruppe)
- Für Trisets: dritte Übung per Swipe zur gleichen Gruppe hinzufügen

### Visueller Indikator

In `ExercisesOverviewCard` und `TemplateSetCard`:
- Vertikale blaue Linie links verbindet alle Übungen einer Superset-Gruppe
- `link`-SF-Symbol als kleines Badge an der Gruppe
- Kein Verhaltensänderung — Buttons bleiben wie heute

### Aktives Workout (`ActiveWorkoutView` / `ActiveSetCard`)

- Wenn aktuelle Übung Teil eines Supersets ist: kleiner Hinweis in `ActiveSetCard`
  - `⚡ Superset — weiter mit: [nächste Übung]`
- Kein Auto-Jump, Benutzer navigiert manuell

---

## Feature 2: PR-Erkennung

### PRDetectionService

```swift
struct PRDetectionService {
    let historicalSessions: [StrengthSession]

    func isNewPR(set: ExerciseSet) -> Bool
    func bestOneRM(for exerciseName: String) -> Double
}
```

- Formel: Epley — `weight × (1 + reps / 30)`
- Vergleich: aktueller 1RM > historischer Bestwert → PR
- Nur `work`-Sätze mit `weight > 0` und `reps > 0` (keine Warmups)
- Historische Sessions = alle abgeschlossenen Sessions **vor** der aktuellen

### State in ActiveWorkoutView

```swift
@State private var prSetIDs: Set<PersistentModelID> = []
@State private var prBannerExercise: String? = nil
@State private var prBannerOneRM: Double = 0
```

Beim Abschließen eines Satzes:
1. `PRDetectionService` prüft ob neuer PR
2. Ja → `prSetIDs.insert(set.persistentModelID)`
3. `prBannerExercise` setzen → Banner erscheint
4. Nach 3 Sekunden: `prBannerExercise = nil` (auto-dismiss)

### PR-Banner

- Overlay oben in der View, Slide-in/out Animation
- `.ultraThinMaterial` Hintergrund in Gold-Tönen
- Inhalt: „👑 Neuer PR! [Übungsname] — [1RM] kg"
- Verschwindet automatisch nach 3s

### Kronen-Icon in ActiveSetCard

- Abgeschlossene Sätze in `prSetIDs` → `crown.fill` SF-Symbol (gelb) neben Checkmark
- Sichtbar für den Rest des Workouts (State bleibt erhalten)
- Kein Modell-Change nötig — nur UI-State

---

## Tech Stack

- SwiftUI, SwiftData (iOS 17+)
- Epley-Formel: `weight × (1 + reps / 30)` — konsistent mit `StrengthStatisticCalcEngine`
- Keine Unit-Tests — Verifikation via Previews + Simulator
