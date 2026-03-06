# Design: Workout aus Trainingsplan starten

**Datum:** 2026-03-06
**Status:** Freigegeben

---

## Ziel

Einen Trainingsplan direkt als aktives Workout starten — Übungen und Sets werden aus dem Template vorausgefüllt, der User landet sofort in der `ActiveWorkoutView`.

---

## Kontext

Die Core-Logik ist bereits vollständig implementiert:
- `TrainingPlan.createSession()` — kopiert alle Template-Sets in eine neue `StrengthSession`
- `TrainingDetailView.startWorkout()` — erstellt die Session, hat aber `// TODO: Navigation`
- `PlanActionsSection` mit `onStartWorkout` Callback — Button existiert bereits
- `StrengthSession.sourceTrainingPlan` Relationship — Verknüpfung im Datenmodell vorhanden

Es fehlt ausschließlich die Navigation und ein kleines UI-Detail.

---

## Design-Entscheidungen

### Navigation: fullScreenCover
`ActiveWorkoutView` öffnet sich als modales Vollbild aus `TrainingDetailView`. Konsistent mit anderen Live-Screens, klar getrennt vom Trainingsplan-NavigationStack.

### Plan-Badge in ActiveWorkoutView
Wenn `session.sourceTrainingPlan != nil` → Plan-Name als kleiner Badge/Text unter dem Timer sichtbar. Gibt dem User Kontext, dass das Workout aus einem Plan stammt.

### Button-Guard
Wenn der Plan keine Template-Sets hat (`safeTemplateSets.isEmpty`) → "Training starten" Button deaktiviert mit erklärendem Hinweis.

---

## Änderungen (3 Dateien)

### 1. `TrainingDetailView.swift`
```swift
@State private var startedSession: StrengthSession?

private func startWorkout() {
    let session = plan.createSession()
    context.insert(session)
    try? context.save()
    startedSession = session  // Navigation auslösen
}

// Body:
.fullScreenCover(item: $startedSession) { session in
    NavigationStack {
        ActiveWorkoutView(session: session)
    }
}
```

### 2. `ActiveWorkoutView.swift`
Plan-Name Badge im bestehenden Header-Bereich, wenn `session.sourceTrainingPlan != nil`:
```swift
if let planTitle = session.sourceTrainingPlan?.title {
    Text(planTitle)
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

### 3. `PlanActionsSection.swift`
```swift
Button("Training starten") { ... }
    .disabled(plan.safeTemplateSets.isEmpty)

if plan.safeTemplateSets.isEmpty {
    Text("Füge zuerst Übungen zum Plan hinzu.")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

---

## Nicht im Scope

- Änderungen an `createSession()` — funktioniert bereits korrekt
- Neue SwiftData-Properties — keine nötig
- Apple Watch / HealthKit Integration — unverändert
