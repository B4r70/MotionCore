# PR-Erkennung & Supersets — Implementierungsplan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Supersets (2+ Übungen visuell verbunden, ohne Auto-Jump) und Live-PR-Erkennung beim Satz-Abschluss mit Banner + Kronen-Icon.

**Architecture:** Neues optionales Feld `supersetGroupId: String?` in `ExerciseSet` verbindet Übungen — gleicher Wert = gleiche Gruppe. `PRDetectionService` (pure struct) berechnet Epley-1RM und vergleicht mit historischem Bestwert. PR-State wird in `ActiveWorkoutView` als `Set<PersistentModelID>` gehalten (kein Modell-Change).

**Tech Stack:** SwiftUI, SwiftData (iOS 17+). Kein XCTest — Verifikation via Previews + Simulator.

---

## Kontext für den Implementierer

### Wichtige Dateien
- `MotionCore/Models/Core/ExerciseSet.swift` — SwiftData-Modell, hat `cloneForSession()` und `cloneForPlanEditing()`
- `MotionCore/Models/Core/TrainingPlan.swift` — Hat `groupedTemplateSets: [[ExerciseSet]]`, `safeTemplateSets`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — ~880 Zeilen, `completeSet()` bei Zeile ~457
- `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift` — Zeigt aktuellen Satz, hat `onComplete: (ExerciseSet) -> Void`
- `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift` — Zeigt alle Übungen als Zeilen mit Dots
- `MotionCore/Views/Training/Plans/Components/TemplateSetCard.swift` — Generische Card mit `<Trailing: View>` und Menu
- `MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift` — Enthält `ReorderableExerciseList` → `ReorderableCard` → `TemplateSetCard`
- `MotionCore/Views/Training/Plans/View/TrainingFormView.swift` — Ruft `PlanExercisesSection` auf mit Callbacks
- `MotionCore/Services/Calculation/StrengthStatisticCalcEngine.swift` — Hat Epley-Formel als Referenz

### Datei-Header (für neue Dateien kopieren)
```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : [Abschnitt]                                                      /
// Datei . . . . : [Dateiname].swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : [Beschreibung]                                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
```

### Code-Konventionen
- Cards: `.glassCard()` Modifier
- Hintergrund: `AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)`
- Empty State: `EmptyState()` Komponente
- Commit-Präfix: `feat()`

---

## Task 1: ExerciseSet — `supersetGroupId` Feld

**Files:**
- Modify: `MotionCore/Models/Core/ExerciseSet.swift`

**Ziel:** Neues optionales Feld `supersetGroupId: String?` hinzufügen. Alle bestehenden Stellen, die `ExerciseSet` kopieren, müssen das Feld weitergeben.

**Step 1: `supersetGroupId` Feld und computed helper hinzufügen**

In `ExerciseSet`, nach dem `groupId`-Feld (Zeile ~48) einfügen:

```swift
var supersetGroupId: String? = nil       // nil = normaler Satz, gleicher Wert = Superset-Gruppe
```

Computed property (nach `isTemplate`, Zeile ~83):
```swift
var isInSuperset: Bool {
    supersetGroupId != nil
}
```

**Step 2: `init()` erweitern**

Parameter hinzufügen (nach `sortOrder: Int = 0`):
```swift
supersetGroupId: String? = nil
```

Im Body:
```swift
self.supersetGroupId = supersetGroupId
```

**Step 3: `cloneForPlanEditing()` aktualisieren**

In der `ExerciseSet.cloneForPlanEditing()` extension (Zeile ~201), nach `copy.isUnilateralSnapshot = isUnilateralSnapshot`:
```swift
copy.supersetGroupId = supersetGroupId
```

**Step 4: `cloneForSession()` aktualisieren**

In der `ExerciseSet.cloneForSession()` extension (Zeile ~251), nach `copy.exercise = self.exercise`:
```swift
copy.supersetGroupId = supersetGroupId
```

**Step 5: In `TrainingPlan.createSession()` aktualisieren**

In `TrainingPlan.createSession()` (Zeile ~72), beim `ExerciseSet(...)` init-Aufruf, nach `sortOrder:` Parameter hinzufügen:
```swift
supersetGroupId: templateSet.supersetGroupId,
```

**Step 6: Superset-Toggle-Methode zu `TrainingPlan` hinzufügen**

Am Ende der `TrainingPlan` Klasse (nach `sortExercises`, vor `init`):
```swift
/// Verbindet Übung an `index` mit der nächsten Übung als Superset.
/// Falls die Übung bereits in einem Superset ist, wird das gesamte Superset aufgelöst.
func toggleSuperset(forGroupAt index: Int) {
    let groups = groupedTemplateSets
    guard index < groups.count else { return }
    let currentGroup = groups[index]

    if let existingGroupId = currentGroup.first?.supersetGroupId {
        // Superset auflösen: alle Sets dieser Gruppe
        safeTemplateSets
            .filter { $0.supersetGroupId == existingGroupId }
            .forEach { $0.supersetGroupId = nil }
    } else {
        // Mit nächster Übung verbinden
        guard index + 1 < groups.count else { return }
        let nextGroup = groups[index + 1]
        let newGroupId = UUID().uuidString
        currentGroup.forEach { $0.supersetGroupId = newGroupId }
        nextGroup.forEach { $0.supersetGroupId = newGroupId }
    }
}
```

**Step 7: Verify via Preview**

Öffne `TrainingFormView` Preview — bestehende Pläne sollten unverändert erscheinen.

**Step 8: Commit**

```bash
git add MotionCore/Models/Core/ExerciseSet.swift MotionCore/Models/Core/TrainingPlan.swift
git commit -m "feat(ExerciseSet): supersetGroupId Feld + TrainingPlan toggleSuperset Methode"
```

---

## Task 2: PRDetectionService

**Files:**
- Create: `MotionCore/Services/Detection/PRDetectionService.swift`

**Ziel:** Pure struct der bestimmt ob ein abgeschlossener Satz ein neuer persönlicher Rekord (1RM via Epley) ist.

**Step 1: Verzeichnis prüfen**

```bash
ls MotionCore/Services/
```

Falls `Detection/` nicht existiert: normal, Swift-Verzeichnisse existieren nur im Filesystem, nicht zwingend als Xcode-Gruppe. Datei einfach erstellen.

**Step 2: `PRDetectionService.swift` erstellen**

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Erkennung                                                        /
// Datei . . . . : PRDetectionService.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Erkennt persönliche Bestleistungen via Epley-1RM-Formel          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct PRDetectionService {

    // MARK: - Input

    let historicalSessions: [StrengthSession]

    // MARK: - Öffentliche API

    /// Gibt true zurück, wenn `set` einen neuen 1RM-PR darstellt.
    /// Nur work-Sätze mit weight > 0 und reps > 0 werden berücksichtigt.
    func isNewPR(set: ExerciseSet) -> Bool {
        guard set.setKind == .work, set.weight > 0, set.reps > 0 else { return false }
        let current = epley(weight: set.weight, reps: set.reps)
        return current > bestOneRM(for: set.exerciseName)
    }

    /// Bisheriger Bestwert (1RM) für eine Übung aus historischen Sessions.
    func bestOneRM(for exerciseName: String) -> Double {
        historicalSessions
            .flatMap { $0.safeExerciseSets }
            .filter {
                $0.exerciseName == exerciseName
                    && $0.setKind == .work
                    && $0.weight > 0
                    && $0.reps > 0
                    && $0.isCompleted
            }
            .map { epley(weight: $0.weight, reps: $0.reps) }
            .max() ?? 0
    }

    // MARK: - Privat

    private func epley(weight: Double, reps: Int) -> Double {
        weight * (1.0 + Double(reps) / 30.0)
    }
}
```

**Step 3: Verify — kein Compiler-Fehler**

Sicherstellen dass der Code fehlerfrei kompiliert (Xcode Build: `Cmd+B`).

**Step 4: Commit**

```bash
git add MotionCore/Services/Detection/PRDetectionService.swift
git commit -m "feat(PRDetectionService): Epley-1RM-Vergleich für PR-Erkennung"
```

---

## Task 3: Superset-Indikator in `TemplateSetCard`

**Files:**
- Modify: `MotionCore/Views/Training/Plans/Components/TemplateSetCard.swift`

**Ziel:** Superset-Badge im Header und „Superset"-Menüeintrag hinzufügen.

**Step 1: `onSupersetToggle` Parameter hinzufügen**

In der `TemplateSetCard<Trailing: View>` struct, nach `let showsEditMenu: Bool`:
```swift
let onSupersetToggle: (() -> Void)?
```

Im `init`:
```swift
onSupersetToggle: (() -> Void)? = nil,
```

Body zuweisen:
```swift
self.onSupersetToggle = onSupersetToggle
```

**Step 2: `isInSuperset` computed property**

Direkt nach `var totalVolume`:
```swift
private var isInSuperset: Bool {
    sets.first?.supersetGroupId != nil
}
```

**Step 3: Superset-Badge im Header**

Im `body`, im HStack-Header nach dem Video-Block und dem VStack (Übungsname + Labels), vor `Spacer()`:

```swift
if isInSuperset {
    Image(systemName: "link")
        .font(.caption.bold())
        .foregroundStyle(.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.blue.opacity(0.15), in: Capsule())
}
```

**Step 4: Menüeintrag für Superset**

Im `Menu`-Block, nach dem "Bearbeiten"-Button, vor dem "Entfernen"-Button:

```swift
if let toggle = onSupersetToggle {
    Button {
        toggle()
    } label: {
        if isInSuperset {
            Label("Superset auflösen", systemImage: "link.badge.minus")
        } else {
            Label("Superset mit nächster", systemImage: "link.badge.plus")
        }
    }

    Divider()
}
```

**Step 5: `EmptyView`-Convenience-Init anpassen**

Der bestehende `extension TemplateSetCard where Trailing == EmptyView` hat einen separaten `init`. Dort `onSupersetToggle: nil` als default belassen (kein Parameter nötig — der neue init-Parameter hat bereits `= nil`). Sicherstellen dass der Convenience-Init unverändert funktioniert.

**Step 6: Verify via Preview**

Preview „Template Set Card" öffnen — Badge und Menüeintrag sollten nicht erscheinen (supersetGroupId ist nil). Manuell einen `ExerciseSet` mit `supersetGroupId = "test"` in der Preview erstellen und prüfen dass Badge erscheint.

**Step 7: Commit**

```bash
git add MotionCore/Views/Training/Plans/Components/TemplateSetCard.swift
git commit -m "feat(TemplateSetCard): Superset-Badge und Menüeintrag"
```

---

## Task 4: Superset-Verwaltung in `PlanExercisesSection` + `TrainingFormView`

**Files:**
- Modify: `MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift`
- Modify: `MotionCore/Views/Training/Plans/View/TrainingFormView.swift`

**Ziel:** Superset-Toggle von `TemplateSetCard` bis `TrainingFormView` durchverdrahten.

**Step 1: `onSupersetToggle` zu `ReorderableExerciseList` hinzufügen**

In `struct ReorderableExerciseList: View`, nach `let onReorder: (Int, Int) -> Void`:
```swift
let onSupersetToggle: (Int) -> Void
```

**Step 2: `onSupersetToggle` zu `ReorderableCard` hinzufügen**

In `private struct ReorderableCard: View`, nach `let onDragEnded: () -> Void`:
```swift
let onSupersetToggle: (() -> Void)?
```

**Step 3: `ReorderableExerciseList` — `ReorderableCard` Aufruf aktualisieren**

Im `body` von `ReorderableExerciseList`, beim `ReorderableCard(...)` Aufruf, nach `onHeightMeasured`:

```swift
onSupersetToggle: index < plan.groupedTemplateSets.count - 1
    ? { onSupersetToggle(index) }
    : nil
```

**Step 4: `ReorderableCard` — `TemplateSetCard` Aufruf aktualisieren**

In `ReorderableCard.body`, beim `TemplateSetCard(...)` Aufruf, nach `showsEditMenu`:
```swift
onSupersetToggle: onSupersetToggle,
```

**Step 5: `FloatingDragCard` — `TemplateSetCard` Aufruf unverändert lassen**

`FloatingDragCard` nutzt `TemplateSetCard` ohne Menu (wird beim Drag angezeigt). Der `onSupersetToggle`-Parameter hat `= nil` als Default, also kein Anpassungsbedarf.

**Step 6: `ReorderableExerciseList` in `PlanExercisesSection` verdrahten**

In `PlanExercisesSection`:
1. `@Environment(\.modelContext) private var modelContext` hinzufügen (am Anfang der struct)
2. Im `exercisesList` switch case `.form`, beim `ReorderableExerciseList(...)` Aufruf nach `onReorder`:

```swift
onSupersetToggle: { index in
    plan.toggleSuperset(forGroupAt: index)
    try? modelContext.save()
}
```

**Step 7: `ExerciseDetailRow` — Superset-Badge für Detail-Modus**

In `struct ExerciseDetailRow: View`, nach dem `index`-Parameter:
```swift
var isInSuperset: Bool = false
```

Im `body`, im HStack, nach dem blauen Kreis-Index-Badge:
```swift
if isInSuperset {
    Image(systemName: "link")
        .font(.caption2)
        .foregroundStyle(.blue)
}
```

Im `PlanExercisesSection.exercisesList` case `.detail`, beim `ExerciseDetailRow(...)`:
```swift
isInSuperset: (setsGroup.first?.supersetGroupId != nil)
```

**Step 8: Verify via Simulator**

1. Plan öffnen → Übung bearbeiten (edit-Modus)
2. ⋯ Menu öffnen → „Superset mit nächster" antippen
3. Prüfen: Badge `link` erscheint bei beiden Übungen
4. ⋯ Menu erneut → „Superset auflösen" → Badge verschwindet

**Step 9: Commit**

```bash
git add MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift \
        MotionCore/Views/Training/Plans/View/TrainingFormView.swift
git commit -m "feat(PlanExercisesSection): Superset-Verwaltung über Toggle-Callback"
```

---

## Task 5: Superset-Indikator in `ExercisesOverviewCard`

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift`

**Ziel:** Im aktiven Workout werden Superset-Gruppen mit einer vertikalen blauen Linie und `link`-Icon verbunden. Außerdem: PR-Kronen-Icon für Übungen mit PR.

**Step 1: Parameter hinzufügen**

In `struct ExercisesOverviewCard: View`, nach `let refreshID: UUID`:
```swift
let prSetIDs: Set<PersistentModelID>
```

**Step 2: Superset-Helper computed properties**

Direkt nach dem `@State private var pressedGroupKey`:
```swift
private func isSupersetConnectedBelow(at index: Int) -> Bool {
    guard index + 1 < groupedSets.count else { return false }
    guard let thisID = groupedSets[index].first?.supersetGroupId,
          let nextID = groupedSets[index + 1].first?.supersetGroupId else { return false }
    return thisID == nextID
}

private func isSupersetConnectedAbove(at index: Int) -> Bool {
    guard index > 0 else { return false }
    guard let thisID = groupedSets[index].first?.supersetGroupId,
          let prevID = groupedSets[index - 1].first?.supersetGroupId else { return false }
    return thisID == prevID
}

private func hasPR(in sets: [ExerciseSet]) -> Bool {
    sets.contains { prSetIDs.contains($0.persistentModelID) }
}
```

**Step 3: `ExerciseOverviewRow` Parameter erweitern**

In `private struct ExerciseOverviewRow: View`, nach `let isPressed: Bool`:
```swift
let hasSupersetAbove: Bool
let hasSupersetBelow: Bool
let hasPR: Bool
```

**Step 4: Superset-Verbindung und PR-Crown im `ExerciseOverviewRow.body`**

Ersetze das aktuelle `VStack(spacing: 8) { topLine; dotsLine }` durch:

```swift
HStack(spacing: 0) {
    // Vertikale Superset-Linie links
    VStack(spacing: 0) {
        // Obere Linie
        Rectangle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .opacity(hasSupersetAbove ? 1 : 0)

        // Superset-Icon in der Mitte
        if hasSupersetAbove || hasSupersetBelow {
            Image(systemName: "link")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.blue)
                .padding(.vertical, 2)
        }

        // Untere Linie
        Rectangle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .opacity(hasSupersetBelow ? 1 : 0)
    }
    .frame(width: 12)

    // Inhalt
    VStack(spacing: 8) {
        topLine
        dotsLine
    }
    .padding(12)
}
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(backgroundColor)
)
.contentShape(Rectangle())
.animation(.easeInOut(duration: 0.15), value: isPressed)
```

**Step 5: PR-Crown im `topLine`**

In `topLine`, nach dem `if isAllCompleted` Block, einen PR-Crown hinzufügen:

```swift
if hasPR {
    Image(systemName: "crown.fill")
        .font(.caption)
        .foregroundStyle(.yellow)
}
```

Der komplette `topLine` HStack rechte Seite:
```swift
HStack(spacing: 4) {
    if hasPR {
        Image(systemName: "crown.fill")
            .font(.caption)
            .foregroundStyle(.yellow)
    }
    if isAllCompleted {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
    } else {
        Text("\(completedCount)/\(sets.count)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

**Step 6: `ForEach` in `ExercisesOverviewCard.body` aktualisieren**

```swift
ForEach(Array(groupedSets.enumerated()), id: \.offset) { index, sets in
    if let firstSet = sets.first {
        ExerciseOverviewRow(
            index: index + 1,
            name: firstSet.exerciseName,
            sets: sets,
            isCurrentExercise: index == currentExerciseIndex,
            isPressed: pressedGroupKey == firstSet.groupKey,
            hasSupersetAbove: isSupersetConnectedAbove(at: index),
            hasSupersetBelow: isSupersetConnectedBelow(at: index),
            hasPR: hasPR(in: sets)
        )
        // ... onTapGesture, onLongPressGesture unverändert
    }
}
```

**Step 7: `ActiveWorkoutView` — `ExercisesOverviewCard` Aufruf aktualisieren**

In `ActiveWorkoutView.exercisesOverview`, beim `ExercisesOverviewCard(...)` Aufruf nach `refreshID:`:
```swift
prSetIDs: prSetIDs,
```

(Hinweis: `prSetIDs` wird in Task 7 als `@State` hinzugefügt. Zunächst als leeres `Set<PersistentModelID>()` vorübergehend hardcoden oder Task 7 vorziehen.)

Einfachste Lösung: Feld direkt als Default-Wert hinzufügen:
```swift
let prSetIDs: Set<PersistentModelID> = []
```

Dann in Task 7 entfernen und durch echte State-Weitergabe ersetzen.

**Step 8: Verify via Preview**

Öffne `ExercisesOverviewCard` — wenn kein Superset, sieht alles wie vorher aus.

**Step 9: Commit**

```bash
git add MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift \
        MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat(ExercisesOverviewCard): Superset-Verbindungslinie und PR-Crown"
```

---

## Task 6: Superset-Hinweis in `ActiveSetCard`

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift`

**Ziel:** Wenn die aktuelle Übung Teil eines Supersets ist, zeige einen Hinweis „Superset — weiter mit: [Name]".

**Step 1: Parameter hinzufügen**

In `struct ActiveSetCard: View`, nach `let setsForCurrentExercise: Int`:
```swift
let supersetNextExercise: String?
```

**Step 2: Superset-Hinweis im Body**

Im `body`, direkt nach dem `HStack(spacing: 16)` Block (der Video + Name enthält), vor `.glassDivider()`:

```swift
if let nextExercise = supersetNextExercise {
    HStack(spacing: 6) {
        Image(systemName: "link")
            .font(.caption.bold())
        Text("Superset — weiter mit: \(nextExercise)")
            .font(.caption)
    }
    .foregroundStyle(.blue)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
}
```

**Step 3: `ActiveWorkoutView` — computed property für Superset-Next**

In `ActiveWorkoutView`, nach `var lastCompletedSet`:

```swift
private func supersetNextExercise(for set: ExerciseSet) -> String? {
    guard let groupId = set.supersetGroupId else { return nil }
    let groups = session.groupedSets
    guard let currentGroupIndex = groups.firstIndex(where: { group in
        group.contains { $0.groupKey == set.groupKey }
    }) else { return nil }

    // Finde die nächste Übung in derselben Superset-Gruppe
    let nextIndex = currentGroupIndex + 1
    guard nextIndex < groups.count,
          let nextSet = groups[nextIndex].first,
          nextSet.supersetGroupId == groupId else { return nil }
    return nextSet.exerciseName
}
```

**Step 4: `ActiveWorkoutView.heroCard` — `ActiveSetCard` Aufruf aktualisieren**

Beim `ActiveSetCard(...)` Aufruf in `heroCard`, nach `selectedSetForEdit: $selectedSetForEdit`:
```swift
supersetNextExercise: supersetNextExercise(for: activeSet),
```

**Step 5: Verify via Preview**

Öffne `ActiveSetCard` Preview und füge `supersetNextExercise: "Butterfly"` hinzu — der blaue Hinweis erscheint.

**Step 6: Commit**

```bash
git add MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift \
        MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat(ActiveSetCard): Superset-Hinweis für nächste Übung"
```

---

## Task 7: PR-Banner-View

**Files:**
- Create: `MotionCore/Views/Workouts/Active/Components/PRBannerView.swift`

**Ziel:** Kurzes, animiertes Banner das einen neuen PR anzeigt.

**Step 1: `PRBannerView.swift` erstellen**

```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : PRBannerView.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Banner-Overlay für neuen persönlichen Rekord                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PRBannerView: View {
    let exerciseName: String
    let oneRM: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Neuer PR!")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("\(exerciseName) — \(String(format: "%.1f", oneRM)) kg 1RM")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Color.yellow.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("PR Banner") {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()

        VStack {
            PRBannerView(exerciseName: "Bankdrücken", oneRM: 102.5)
            Spacer()
        }
    }
}
```

**Step 2: Verify via Preview**

Preview öffnen — Banner mit Kronen-Icon, Übungsname und 1RM erscheint.

**Step 3: Commit**

```bash
git add MotionCore/Views/Workouts/Active/Components/PRBannerView.swift
git commit -m "feat(PRBannerView): Gold-Banner für neue persönliche Bestleistung"
```

---

## Task 8: PR-Erkennung in `ActiveWorkoutView`

**Files:**
- Modify: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

**Ziel:** Beim Abschließen eines Satzes PR prüfen, Banner 3 Sekunden anzeigen, Kronen-IDs tracken. `ExercisesOverviewCard` bekommt echte `prSetIDs`.

**Step 1: `@Query` für historische Sessions hinzufügen**

In `ActiveWorkoutView`, nach `@Bindable var session: StrengthSession`:

```swift
@Query(sort: \StrengthSession.date, order: .reverse)
private var allSessions: [StrengthSession]
```

**Step 2: PR-State hinzufügen**

In `ActiveWorkoutView`, nach dem bestehenden `@State private var showAddExerciseSheet`:

```swift
// PR-Erkennung
@State private var prSetIDs: Set<PersistentModelID> = []
@State private var prBannerExercise: String? = nil
@State private var prBannerOneRM: Double = 0
```

**Step 3: `historicalSessions` computed property**

Nach `var lastCompletedSet`:

```swift
private var historicalSessions: [StrengthSession] {
    allSessions.filter {
        $0.isCompleted && $0.persistentModelID != session.persistentModelID
    }
}
```

**Step 4: `completeSet()` — PR-Prüfung einbauen**

In `completeSet(_ set: ExerciseSet)`, direkt nach `try? context.save()` (erste Zeile der Funktion):

```swift
// PR-Prüfung
let prService = PRDetectionService(historicalSessions: historicalSessions)
if prService.isNewPR(set: set) {
    prSetIDs.insert(set.persistentModelID)
    prBannerExercise = set.exerciseName
    prBannerOneRM = set.weight * (1.0 + Double(set.reps) / 30.0)
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        withAnimation(.easeOut) {
            prBannerExercise = nil
        }
    }
}
```

**Step 5: PR-Banner im `body` hinzufügen**

Im `body`, im äußeren `ZStack`, nach `VStack(spacing: 0) { ... }` und vor `VStack { Spacer(); bottomActionBar }`:

```swift
// PR-Banner
if let exercise = prBannerExercise {
    VStack {
        PRBannerView(exerciseName: exercise, oneRM: prBannerOneRM)
        Spacer()
    }
    .transition(.move(edge: .top).combined(with: .opacity))
    .zIndex(100)
    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: prBannerExercise)
}
```

**Step 6: `ExercisesOverviewCard` Default-Wert entfernen**

In `ExercisesOverviewCard`, den Default-Wert `= []` vom `prSetIDs` Parameter entfernen (wurde in Task 5 temporär hinzugefügt).

In `ActiveWorkoutView.exercisesOverview`, `prSetIDs: prSetIDs` sicherstellen (wurde in Task 5 hinzugefügt, jetzt echte State-Variable).

**Step 7: `withAnimation` für Banner-Erscheinen im `body` sicherstellen**

Den PR-Banner-Block in ein `withAnimation` einwickeln oder die `onChange`-Reaktion nutzen. Einfachste Lösung: Der `if let exercise = prBannerExercise` Block in Kombination mit `.animation(.spring(...), value: prBannerExercise)` auf dem `VStack` reicht aus.

**Step 8: Verify via Simulator**

1. Workout starten (Plan mit bereits historischen Sessions)
2. Satz mit höherem Gewicht/Reps als bisher abschließen
3. PR-Banner erscheint oben für 3 Sekunden
4. Kronen-Icon in `ExercisesOverviewCard` für diese Übung erscheint

**Step 9: Commit**

```bash
git add MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift
git commit -m "feat(ActiveWorkoutView): PR-Erkennung, Banner und Crown-Tracking"
```

---

## Abschluss-Checkliste

- [ ] `ExerciseSet.supersetGroupId` vorhanden, beide clone-Methoden aktualisiert
- [ ] `TrainingPlan.toggleSuperset(forGroupAt:)` funktioniert (verbinden + auflösen)
- [ ] Plan-Editor: `link`-Badge und Menüeintrag in `TemplateSetCard`
- [ ] Plan-Editor: Superset-Toggle funktioniert via ⋯ Menu
- [ ] Aktives Workout: Superset-Verbindungslinie in `ExercisesOverviewCard`
- [ ] Aktives Workout: „Superset — weiter mit: X" Hinweis in `ActiveSetCard`
- [ ] PR-Banner erscheint nach Satz-Abschluss (3s, dann weg)
- [ ] Kronen-Icon in `ExercisesOverviewCard` für PR-Übungen
- [ ] Bestehende Workouts ohne Supersets: visuell unverändert
