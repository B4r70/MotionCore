# Letzte Trainingswerte als dezente Referenz im ActiveSetCard

**Status:** Bereit zur Implementierung · **Komplexität:** Medium

---

## Summary

`ActiveSetCard` zeigt unauffällig die Reps/Gewicht-Werte des letzten Trainings für genau diesen Satz an — aber nur, wenn das letzte Training in **mindestens zwei** Sätzen der Übung sichtbar vom aktuellen Trainingsplan abwich (Gewicht und/oder Reps). Einmalige Ausreißer werden ignoriert.

---

## Scope

**Included:**
- Vergleich letzte Session-Sätze ↔ Plan-Template-Sätze pro Übung
- Per-Satz-Anzeige der historischen Werte (Reps × Gewicht) im aktiven `ActiveSetCard`
- Dezente UI (Caption, secondary) — kein Badge, keine Card, kein Icon-Hervorheben
- Nur Work-Sets

**Excluded:**
- Keine neue Datenmodell-Änderung
- Keine Anpassung von `SmartFill`/`ProgressionCalcEngine`
- Kein Diff-Banner / kein „+X kg"-Hinweis
- Keine Anzeige im `RestTimerCard` / `ExerciseCompletedCard`
- Keine Anzeige wenn `session.sourceTrainingPlan == nil` (Ad-hoc-Workouts)

---

## Affected Files

| Datei | Änderung |
|-------|----------|
| `Services/Calculation/LastSessionReferenceCalcEngine.swift` | **neu** — pure struct, ermittelt Reference pro setNumber mit Gating (≥ 2 abweichende Work-Sets) |
| `Views/Workouts/Active/Components/ActiveSetCard.swift` | neuer optionaler Parameter `lastSessionReference`; dezente Caption-Zeile |
| `Views/Workouts/Active/View/ActiveWorkoutView.swift` | neuer Cache `cachedLastSessionReferences`, Helper `refreshLastSessionReference()`, Verdrahtung |

---

## Risks

- **Plan fehlt:** `session.sourceTrainingPlan` kann `nil` sein → Engine wird nicht aufgerufen, `Reference? = nil`.
- **groupKey-Drift:** Bei alten Sessions ohne `exerciseUUIDSnapshot` — durch L1-008-Fixes weitgehend entschärft; Engine liefert `nil` bei fehlendem Match.
- **Set-Number-Mismatch:** Letzte Session und Plan können unterschiedliche Satzanzahl haben → strenge `setNumber`-Zuordnung, fehlende → keine Referenz.
- **Cache-Invalidierung:** Cache muss bei `selectedExerciseKey`-Wechsel UND `exerciseListRefreshID` aufgefrischt werden.
- **Gleitkomma-Vergleich:** `abs(delta) >= 0.01` für `weight`, direkte Int-Gleichheit für `reps`.

---

## Implementation Steps

### Schritt 1 — CalcEngine anlegen

Neue Datei `MotionCore/Services/Calculation/LastSessionReferenceCalcEngine.swift`:

```swift
struct LastSessionReferenceCalcEngine {
    struct Reference {
        let reps: Int
        let weight: Double
    }

    struct Input {
        let activeSetNumber: Int
        let lastSessionSets: [ExerciseSet]
        let planTemplateSets: [ExerciseSet]
    }

    static func resolve(input: Input) -> Reference? {
        // 1. Nur Work-Sets
        let lastWork = input.lastSessionSets.filter { $0.setKind == .work }
        let planWork = input.planTemplateSets.filter { $0.setKind == .work }

        // 2. Paare per setNumber
        var pairs: [Int: (last: ExerciseSet, plan: ExerciseSet)] = [:]
        for planSet in planWork {
            if let lastSet = lastWork.first(where: { $0.setNumber == planSet.setNumber }) {
                pairs[planSet.setNumber] = (last: lastSet, plan: planSet)
            }
        }

        // 3. Abweichungen zählen
        let deviationCount = pairs.values.filter {
            abs($0.last.weight - $0.plan.weight) >= 0.01 || $0.last.reps != $0.plan.reps
        }.count

        // 4. Gating: mindestens 2 abweichende Sätze
        guard deviationCount >= 2 else { return nil }

        // 5. Referenz für aktiven Satz
        guard let pair = pairs[input.activeSetNumber] else { return nil }
        return Reference(reps: pair.last.reps, weight: pair.last.weight)
    }
}
```

---

### Schritt 2 — Cache + Helper in `ActiveWorkoutView`

Neuer State:
```swift
@State private var cachedLastSessionReferences: [String: [Int: LastSessionReferenceCalcEngine.Reference]] = [:]
```

Neue Methode `refreshLastSessionReference(for groupKey: String)`:
- Plan-Sets: `session.sourceTrainingPlan?.safeTemplateSets.filter { $0.groupKey == groupKey } ?? []`
- Last-Sets: `lastCompletedSession(for: groupKey)?.safeExerciseSets.filter { $0.groupKey == groupKey } ?? []`
- Wenn Plan-Sets leer → `cachedLastSessionReferences[groupKey] = [:]`, return
- Sonst: alle Work-Set-Nummern ermitteln, Engine pro `setNumber` aufrufen, Sub-Dictionary füllen

Aufrufstellen:
- `setupSession()` — einmalig für alle groupKeys in `cachedGroupedSets`
- `.onChange(of: selectedExerciseKey)` — für den neuen Key
- `.onChange(of: exerciseListRefreshID)` — für alle Keys (nach Add-Exercise)

Lookup-Helper:
```swift
func lastSessionReference(for set: ExerciseSet) -> LastSessionReferenceCalcEngine.Reference? {
    cachedLastSessionReferences[set.groupKey]?[set.setNumber]
}
```

---

### Schritt 3 — `ActiveSetCard` erweitern

Neuer optionaler Parameter:
```swift
var lastSessionReference: LastSessionReferenceCalcEngine.Reference? = nil
```

Neue Caption-Zeile (nur wenn `lastSessionReference != nil`), unter dem Weight/Reps-HStack:
```swift
if let ref = lastSessionReference {
    Text("Letztes Mal: \(ref.reps) Wdh. × \(formattedLastWeight(ref))")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

Hilfsfunktion im Card (oder als Extension):
```swift
private func formattedLastWeight(_ ref: LastSessionReferenceCalcEngine.Reference) -> String {
    guard ref.weight > 0 else { return "Körpergewicht" }
    if exercise.isUnilateral {
        return "2× \(formatWeight(ref.weight / 2)) kg"
    }
    return "\(formatWeight(ref.weight)) kg"
}
```

- `exercise.isUnilateral` — boolean bereits auf `Exercise`-Modell prüfen (ggf. `trackingMode == .unilateral`)
- `formatWeight(_:)` — bestehende Gewichtsformatierungs-Helper verwenden

Kein Hintergrund, kein Icon — reiner Caption-Text.

---

### Schritt 4 — Verdrahtung in `ActiveWorkoutView`

In der `ActiveSetCard(…)`-Erzeugung:
```swift
lastSessionReference: lastSessionReference(for: activeSet)
```

---

### Schritt 5 — Edge-Cases absichern

- Ad-hoc-Workout (`sourceTrainingPlan == nil`): Plan-Sets leer → Engine nicht aufgerufen → `nil`
- Plan und letzte Session identisch: `deviationCount == 0` → `nil`
- Nur 1 Satz weicht ab: `deviationCount == 1` → `nil` (Gating greift)
- `setNumber` fehlt in letzter Session: Pair fehlt → `nil` für diesen Satz

---

## Manual Verification

- [ ] Xcode-Build (`Cmd+B`) erfolgreich, keine Warnings
- [ ] Aktives Workout aus Plan, letzte Session plan-konform → keine Caption sichtbar
- [ ] Aktives Workout aus Plan, letzte Session nur 1 Satz abweichend → keine Caption sichtbar
- [ ] Aktives Workout aus Plan, letzte Session ≥ 2 Sätze abweichend → Caption „Letztes Mal: X Wdh. × Y kg" pro Satz sichtbar, korrekt nach `setNumber`
- [ ] Unilaterale Übung → Caption zeigt „2× X kg" (halbes Gewicht pro Seite)
- [ ] Übungswechsel → Referenz aktualisiert sich korrekt
- [ ] Übung während Training hinzufügen → neue Übung ohne Plan-Sets zeigt keine Referenz
- [ ] Ad-hoc-Workout ohne `sourceTrainingPlan` → keine Caption
- [ ] Visuell dezent: Caption, secondary, kein Banner/Badge/Icon

---

## Progress

**2026-05-16**

Completed steps: 1, 2, 3, 4, 5 (alle Schritte implementiert)

Modified files:
- `MotionCore/Services/Calculation/LastSessionReferenceCalcEngine.swift` — neu angelegt
- `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift` — `lastSessionReference`-Parameter + Caption-Zeile + `formattedLastWeight`/`formatWeight`-Helpers
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `cachedLastSessionReferences` State, `refreshLastSessionReference(for:)`, `lastSessionReference(for:)`, Aufrufstellen in `onAppear`, `.onChange(of: selectedExerciseKey)`, `.onChange(of: exerciseListRefreshID)`, Verdrahtung in `heroCard`

Remaining: Manual Verification (Xcode-Build + Laufzeit-Test)

---

## Entschiedene Design-Fragen

1. **setNumber-Matching:** Strikt — kein Match für eine Satznummer → keine Caption für diesen Satz.
2. **Unilateral-Darstellung:** `2× X kg` (halbes Gewicht pro Seite), z. B. „Letztes Mal: 8 Wdh. × 2× 15 kg".
