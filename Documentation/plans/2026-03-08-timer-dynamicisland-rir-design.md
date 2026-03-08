# Design: Timer-Sync Fix · Dynamic Island Redesign · RIR Auto-Progression

**Datum:** 2026-03-08
**Status:** Approved

---

## 1. Timer-Sync Bug Fix (Background → Foreground)

### Problem
`Timer.scheduledTimer` pausiert wenn die App in den Hintergrund wechselt.
- Dynamic Island: korrekt (nutzt `restEndDate: Date`, systemseitig)
- In-App `restTimerSeconds: Int`: bleibt stehen, da timer-getrieben

### Lösung
`@Environment(\.scenePhase)` in `ActiveWorkoutView` beobachten.
Beim Wechsel nach `.active` (Foreground-Rückkehr):
1. Prüfen ob `isResting && restEndDate > Date()`
2. `restTimerSeconds` aus `restEndDate` neu berechnen
3. `restartLocalRestTimerFromResume()` aufrufen (Methode existiert bereits)

```swift
.onChange(of: scenePhase) { _, newPhase in
    guard newPhase == .active, isResting,
          let end = restEndDate, end > Date() else { return }
    restTimerSeconds = max(0, Int(end.timeIntervalSinceNow.rounded()))
    restartLocalRestTimerFromResume()
}
```

**Betroffene Datei:** `ActiveWorkoutView.swift`
**Scope:** Nur Foreground-Handling, kein Model-Change, keine neue Klasse.

---

## 2. Dynamic Island Redesign

### Constraints
- Compact-Modus: kein `.ultraThinMaterial` möglich (Widget-Context)
- Glassmorphism nur in Lock Screen / Expanded View anwendbar

### Compact View
- **Aktiv-Modus:** Icon + Set-Fortschritt (unverändert, funktioniert gut)
- **Pausen-Modus links:** `pause.circle.fill` in blau statt bisherigem Farbverlauf
- **Pausen-Modus rechts:** Countdown in blauen Gradient-Tönen (`blue → cyan`)

### Expanded View
- **Trailing (Rest-Timer):** Größerer, bolder Timer mit blauem Gradient
  (`LinearGradient([.blue, .cyan])` auf Text via `.foregroundStyle(gradient)`)
- **Bottom:** Fortschrittsbalken bleibt, aber `blue → indigo` Gradient

### Lock Screen
Komplettes Layout-Redesign mit Glassmorphism:
- Hintergrundkarte: `ZStack` + `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))`
- Header: blauer Gradient-Text für Plan/Übungsname
- Timer-Anzeige: zentrierter Countdown-Block mit blauen Akzenten
- Fortschrittsring statt Balken (für Rest-Timer): `Circle().trim()` mit `blue → cyan` Gradient
- Farbkodierung Rest-Timer bleibt: grün → orange → rot (über >30s, 10-30s, <10s)

**Betroffene Datei:** `MotionCoreWidgetsLiveActivity.swift`
**Scope:** Nur UI, keine Daten-Änderungen, keine neuen Model-Felder.

---

## 3. RIR-basierte Auto-Progression

### Model-Änderung: Exercise
Neues Feld in `Exercise.swift`:
```swift
var progressionStep: Double = 2.5  // Gewichtsschritt in kg
```

### Neue Datei: ProgressionCalcEngine
**Pfad:** `Services/Calculation/ProgressionCalcEngine.swift`

```swift
struct ProgressionRecommendation {
    let exerciseName: String
    let currentWeight: Double
    let suggestedWeight: Double
    let progressionStep: Double
    let reason: String   // z.B. "Ø RIR 4.0 > Ziel 2 in den letzten 3 Sessions"
}

struct ProgressionCalcEngine {
    /// sessions: abgeschlossene Sessions, chronologisch sortiert (neueste zuerst)
    func recommendation(
        for exerciseName: String,
        targetRIR: Int,
        progressionStep: Double,
        sessions: [StrengthSession],
        sessionCount: Int = 3
    ) -> ProgressionRecommendation?
}
```

**Logik:**
1. Letzte `sessionCount` Sessions filtern, die `exerciseName` enthalten
2. Work-Sets (kein Warmup) pro Session sammeln
3. Durchschnittlichen `calculatedRIR` (= `10 - rpe`) pro Session berechnen
4. Wenn **alle** N Sessions: Durchschnitts-RIR > targetRIR → Empfehlung
5. `suggestedWeight = letztes Gewicht + progressionStep`

### UI: Progression-Banner in ActiveWorkoutView
**Position:** Über der Übungsliste, pro Übungs-Gruppe (nur wenn Empfehlung vorliegt)
**Design:** "Liquid Glass" Badge

```
╭─────────────────────────────────────╮
│ ↑  Gewicht erhöhen · +2,5 kg        │  ← blaues Gradient-Icon
│    Ø RIR 4.0 > Ziel 2 (3 Sessions)  │  ← caption, secondary
╰─────────────────────────────────────╯
```

- Hintergrund: `.ultraThinMaterial` + blauer Gradient-Border (`blue.opacity(0.3)`)
- Icon: `arrow.up.circle.fill` in `LinearGradient([.blue, .cyan])`
- Tippen: Sheet oder Alert mit Erklärung + "Übernehmen" (setzt Gewicht direkt)
- Verschwindet nach "Übernehmen" oder explizitem Dismiss

**Betroffene Dateien:**
- `Models/Core/Exercise.swift` — neues Feld `progressionStep`
- `Services/Calculation/ProgressionCalcEngine.swift` — neu anlegen
- `Views/Workouts/Active/View/ActiveWorkoutView.swift` — Banner integrieren
- ggf. `Views/Workouts/Active/Components/ProgressionBadge.swift` — separates Component

---

## Offene Entscheidungen (für Implementierungsplan)

- ProgressionBadge als eigenes Component oder inline in ActiveWorkoutView?
  → Empfehlung: separates Component (Datei: `ProgressionBadge.swift`)
- Wo in der Exercise-Detail-UI soll `progressionStep` editierbar sein?
  → ExerciseDetailView / EditExerciseSheet (kein Scope für dieses Feature)
