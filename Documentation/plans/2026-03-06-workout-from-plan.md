# Workout aus Trainingsplan starten — Implementierungsplan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Den bestehenden "Training starten"-Button in `TrainingDetailView` vollständig verdrahten — Navigation zur `ActiveWorkoutView` via `fullScreenCover`, Plan-Name-Badge im Header und Hinweistext wenn der Plan leer ist.

**Architecture:** Die Core-Logik (`TrainingPlan.createSession()`) ist bereits fertig. Es sind 3 minimale Änderungen nötig: Navigation in `TrainingDetailView`, neuer optionaler Parameter in `ActiveWorkoutStatus`, und ein Leer-Hinweis in `PlanActionsSection`.

**Tech Stack:** SwiftUI, SwiftData. Kein XCTest — Verifikation via Previews + Simulator.

---

### Task 1: TrainingDetailView — Navigation verdrahten

**Files:**
- Modify: `MotionCore/Views/Training/Plans/Detail/TrainingDetailView.swift`

**Kontext:**
`startWorkout()` erstellt die Session bereits korrekt, aber die Navigation fehlt (steht als `// TODO`).

**Step 1: State-Property ergänzen**

In `TrainingDetailView`, direkt nach `@State private var showDeleteAlert = false` einfügen:

```swift
@State private var startedSession: StrengthSession?
```

**Step 2: `startWorkout()` aktualisieren**

Den bestehenden Inhalt von `startWorkout()` ersetzen:

```swift
private func startWorkout() {
    let session = plan.createSession()
    context.insert(session)
    try? context.save()
    startedSession = session
}
```

**Step 3: fullScreenCover am Body anhängen**

Am Ende des `body`, direkt nach dem bestehenden `.alert("Plan löschen?", ...)` Block, anfügen:

```swift
.fullScreenCover(item: $startedSession) { session in
    NavigationStack {
        ActiveWorkoutView(session: session)
    }
}
```

**Step 4: Verifikation via Preview/Simulator**

Im Simulator: `TrainingDetailView` mit einem Plan mit Übungen öffnen → "Training starten" tippen → `ActiveWorkoutView` öffnet sich als Vollbild-Sheet. Tippen auf "Abbrechen/Beenden" schließt das Sheet.

**Step 5: Commit**

```bash
git add MotionCore/Views/Training/Plans/Detail/TrainingDetailView.swift
git commit -m "feat: navigate to ActiveWorkoutView from TrainingDetailView via fullScreenCover"
```

---

### Task 2: Plan-Badge in ActiveWorkoutStatus

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/Components/ActiveWorkoutStatus.swift`
- Modify: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` (Aufruf-Stelle)

**Kontext:**
`ActiveWorkoutStatus` zeigt Timer, Volumen und Sätze. Ein optionaler `planTitle`-Parameter wird unter dem Timer als Caption angezeigt — nur wenn das Workout aus einem Plan stammt.

**Step 1: Parameter in `ActiveWorkoutStatus` hinzufügen**

Die `let sessionVolume: Double` Zeile nach unten und direkt darunter ergänzen:

```swift
let sessionVolume: Double
let planTitle: String?          // Optional: Plan-Name als Badge
```

**Step 2: Plan-Badge unter dem Timer anzeigen**

Im `body`, innerhalb des Timer-VStack (links in der HStack), nach dem `if isPaused { Text("Pausiert") }` Block einfügen:

```swift
if let title = planTitle {
    Text(title)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
}
```

Der gesamte Timer-VStack sieht dann so aus:

```swift
VStack(spacing: 2) {
    HStack(spacing: 6) {
        Image(systemName: isPaused ? "pause.circle.fill" : "clock.fill")
            .foregroundStyle(isPaused ? .orange : .blue)
        Text(formattedElapsedTime)
            .font(.title3.bold().monospacedDigit())
            .foregroundStyle(.primary)
    }
    if isPaused {
        Text("Pausiert")
            .font(.caption2)
            .foregroundStyle(.orange)
    }
    if let title = planTitle {
        Text(title)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
.frame(maxWidth: .infinity, alignment: .leading)
```

**Step 3: Aufruf in `ActiveWorkoutView` aktualisieren**

In `ActiveWorkoutView.swift` (Zeile ~154) den `ActiveWorkoutStatus(...)`-Aufruf suchen und `planTitle:` ergänzen:

```swift
ActiveWorkoutStatus(
    isPaused: sessionManager.isPaused,
    formattedElapsedTime: sessionManager.formattedElapsedTime,
    completedSets: session.completedSets,
    totalSets: session.totalSets,
    progress: session.progress,
    sessionVolume: sessionVolume,
    planTitle: session.sourceTrainingPlan?.title
)
```

**Step 4: Verifikation via Preview**

Im `ActiveWorkoutStatus`-Preview `planTitle: "Push Day A"` übergeben → Badge erscheint unter dem Timer. Mit `planTitle: nil` → kein Badge.

**Step 5: Commit**

```bash
git add MotionCore/Views/Workouts/Active/Components/ActiveWorkoutStatus.swift
git add MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat: show training plan name badge in ActiveWorkoutStatus"
```

---

### Task 3: PlanActionsSection — Hinweis bei leerem Plan

**Files:**
- Modify: `MotionCore/Views/Training/Plans/Components/PlanActionsSection.swift`

**Kontext:**
`PlanActionsSection` versteckt den "Training starten"-Button bereits komplett wenn `canStartWorkout == false`. Stattdessen soll ein erklärender Hinweistext erscheinen.

**Step 1: `else`-Branch zum `if canStartWorkout` Block ergänzen**

Den bestehenden Block:

```swift
if canStartWorkout {
    startWorkoutButton
}
```

Ersetzen durch:

```swift
if canStartWorkout {
    startWorkoutButton
} else {
    HStack(spacing: 8) {
        Image(systemName: "info.circle")
        Text("Füge zuerst Übungen zum Plan hinzu.")
            .font(.subheadline)
    }
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 14)
    .padding(.horizontal, 14)
    .background(Color.secondary.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 14))
}
```

**Step 2: Verifikation via Preview**

Im bestehenden `#Preview("Plan Actions Section")` sieht man bereits einen Plan ohne Übungen — dort sollte jetzt der Hinweistext erscheinen.
Um den Plan mit Übungen zu testen: im Preview `plan.templateSets` bleibt leer → Hinweis sichtbar.

**Step 3: Commit**

```bash
git add MotionCore/Views/Training/Plans/Components/PlanActionsSection.swift
git commit -m "feat: show hint text in PlanActionsSection when plan has no exercises"
```
