# Claude-Code-Instruction — In-Session-Supersets v1

> **Konzept-Referenz:** `tasks/InSessionSuperset_Concept_v1.md`
>
> **Reihenfolge:** Steps werden strikt nacheinander abgearbeitet. Nach
> jedem Step folgt ein **STOPP-Gate**, an dem der User die Implementierung
> verifiziert, bevor der nächste Step beginnt.
>
> **File-Limits:** Warnung bei 600 Zeilen, harter Stopp bei 800.
>
> **Code-Conventions:** Deutsche UI-Texte und deutsche Kommentare,
> englische Variablen-/Methoden-Namen.

---

## Step 1 — Session-API: `createSuperset` + `removeFromSuperset`

**Datei:** `StrengthSession.swift`

**Was:** Analog zur bestehenden Implementation in `TrainingPlan.swift`,
aber auf `safeExerciseSets` und `groupedSets` statt `safeTemplateSets`
und `groupedTemplateSets`.

**Methoden:**

```swift
extension StrengthSession {

    /// Erstellt ein neues Superset aus den übergebenen Gruppen-Indizes
    /// (0-basiert, bezogen auf groupedSets).
    /// Voraussetzungen:
    ///   - Mindestens 2, maximal 5 Indizes
    ///   - Alle Indizes lückenlos aufeinanderfolgend
    ///   - Keine der gewählten Übungen hat completed Sets
    /// Passt restSeconds an: alle Sätze außer dem letzten Satz der letzten
    /// Übung pro Runde werden auf 0 gesetzt.
    func createSuperset(fromGroupIndices indices: [Int]) {
        let groups = groupedSets
        let sorted = indices.sorted()

        // Vorbedingungen prüfen
        guard sorted.count >= 2, sorted.count <= 5 else { return }
        guard sorted.allSatisfy({ $0 >= 0 && $0 < groups.count }) else { return }

        // Lückenlosigkeit
        let isContiguous = zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }
        guard isContiguous else { return }

        // Eligibility: keine completed Sets in den gewählten Gruppen
        let allEligible = sorted.allSatisfy { idx in
            groups[idx].allSatisfy { !$0.isCompleted }
        }
        guard allEligible else { return }

        let newGroupId = UUID().uuidString

        // supersetGroupId setzen
        for idx in sorted {
            groups[idx].forEach { $0.supersetGroupId = newGroupId }
        }

        // Pausenzeiten anpassen
        // Pro Runde: alle Übungen außer der letzten bekommen restSeconds = 0
        // Innerhalb der letzten Übung pro Runde bleibt die Original-Pausenzeit erhalten
        let lastGroupIndex = sorted.last!
        for idx in sorted where idx != lastGroupIndex {
            groups[idx].forEach { $0.restSeconds = 0 }
        }
    }

    /// Entfernt eine einzelne Übung (Gruppe an Gruppen-Index) aus ihrem
    /// Superset. Falls danach nur noch eine Übung in der Gruppe verbleibt,
    /// wird das gesamte Superset aufgelöst.
    /// restSeconds bleiben unverändert — der User kann sie über das
    /// Satz-Edit-Sheet anpassen.
    func removeFromSuperset(groupAt index: Int) {
        let groups = groupedSets
        guard index >= 0, index < groups.count else { return }
        let targetGroup = groups[index]

        guard let groupId = targetGroup.first?.supersetGroupId else { return }

        targetGroup.forEach { $0.supersetGroupId = nil }

        let remaining = safeExerciseSets.filter { $0.supersetGroupId == groupId }
        let remainingExerciseCount = Set(remaining.map { $0.groupKey }).count

        if remainingExerciseCount < 2 {
            remaining.forEach { $0.supersetGroupId = nil }
        }
    }
}
```

**Wichtig:**
- Keine `context.save()` in diesen Methoden — wird vom Aufrufer
  übernommen (analog zur Plan-API).
- Keine Veränderung von `sortOrder` — die Übungen sind in der Session
  bereits aufeinanderfolgend (Lückenlosigkeit ist Vorbedingung).

**Wo platzieren:** In der bestehenden Extension `extension StrengthSession`
am Ende der Datei, vor dem letzten `}`. Wenn die Datei dadurch die
600-Zeilen-Grenze überschreitet, eigene Datei
`StrengthSession+Superset.swift` anlegen.

### 🛑 STOPP-Gate 1

**Verifikation durch User:**
- [ ] Datei kompiliert ohne Warnings.
- [ ] Keine bestehenden Tests/Previews kaputt.
- [ ] Methoden-Signaturen passen zur Plan-API (Naming, Parameter).
- [ ] Wenn neue Datei: Header-Block korrekt, in Xcode-Projekt eingebunden.

---

## Step 2 — `ExercisesOverviewCard`: Multi-Select-State + Bolt-Button

**Datei:** `ExercisesOverviewCard.swift`

**Was:**

**2a.** Neue `@State`-Properties am Anfang der View:
```swift
// Multi-Select-Modus für Superset-Erstellung
@State private var isSupersetSelectionMode: Bool = false
@State private var selectedGroupIndicesForSuperset: Set<Int> = []
```

**2b.** Neuer Callback in der Property-Liste:
```swift
var onCreateSuperset: ((Set<Int>) -> Void)? = nil
var onRemoveFromSuperset: ((Int) -> Void)? = nil
```

**2c.** Hilfsmethoden (analog `PlanExercisesSection`):
```swift
/// Eine Übung ist eligible für Superset, wenn keiner ihrer Sätze
/// abgeschlossen ist.
private func isEligibleForSuperset(at index: Int) -> Bool {
    guard let group = groupedSets[safe: index] else { return false }
    return group.allSatisfy { !$0.isCompleted }
}

/// Anzahl der Übungen, die theoretisch in ein Superset überführt
/// werden könnten (für Bolt-Button-Enable-State).
private var eligibleExerciseCount: Int {
    (0..<groupedSets.count).filter { isEligibleForSuperset(at: $0) }.count
}

/// Prüft, ob die aktuell ausgewählten Indizes lückenlos sind.
private var hasContiguousSelection: Bool {
    guard selectedGroupIndicesForSuperset.count >= 2 else { return false }
    let sorted = selectedGroupIndicesForSuperset.sorted()
    return zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }
}

/// Prüft, ob eine Übung bereits Teil eines anderen Supersets ist.
private func isInOtherSuperset(at index: Int) -> Bool {
    guard let id = groupedSets[safe: index]?.first?.supersetGroupId,
          !id.isEmpty else { return false }
    return true
}
```

**2d.** Bolt-Button im Header der Card. Position: rechts neben dem
bestehenden Sort/Add-Button. Sichtbar nur wenn `!isSortMode`:
```swift
Button {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        isSupersetSelectionMode = true
        selectedGroupIndicesForSuperset = []
    }
} label: {
    Image(systemName: "bolt")
        .font(.title3)
        .foregroundStyle(Color.blue)
}
.opacity(eligibleExerciseCount >= 2 ? 1.0 : 0.4)
.disabled(eligibleExerciseCount < 2 || isSortMode)
```

**2e.** Reaktive State-Bereinigung:
```swift
.onChange(of: isSortMode) { _, newValue in
    if newValue { isSupersetSelectionMode = false }
}
.onChange(of: isSupersetSelectionMode) { _, newValue in
    if newValue { isSortMode = false }
    if !newValue { selectedGroupIndicesForSuperset = [] }
}
```

**Wichtig:**
- Noch kein UI für die Selektion auf den Cards — kommt in Step 3.
- Noch keine Action Bar — kommt in Step 4.
- Callbacks bleiben in der Property-Liste optional (`= nil`), damit
  bestehende Call-Sites nicht brechen.

### 🛑 STOPP-Gate 2

**Verifikation durch User:**
- [ ] Bolt-Button erscheint im Header von `ExercisesOverviewCard`.
- [ ] Button ist disabled (halbtransparent), wenn keine 2 eligible
      Übungen vorhanden sind.
- [ ] Tap auf Bolt-Button schaltet in den Selection-Modus
      (`isSupersetSelectionMode = true`) — noch nichts sichtbar.
- [ ] Aktivieren von Sort-Modus beendet Selection-Modus und umgekehrt.
- [ ] Datei bleibt unter 700 Zeilen. Falls darüber: `// MARK: - Superset`
      vorbereiten als Kandidat für Extraktion in Step 5.

---

## Step 3 — `ExerciseOverviewRow`: Selection-Visuals (Border, Checkmark, Schloss)

**Datei:** `ExercisesOverviewCard.swift` (bzw. wo `ExerciseOverviewRow`
definiert ist — bitte im File suchen und beibehalten, nicht
extrahieren).

**Was:**

**3a.** Neue Parameter an `ExerciseOverviewRow`:
```swift
let isSupersetSelectionMode: Bool
let isSelectedForSuperset: Bool
let isEligibleForSuperset: Bool
let isInOtherSuperset: Bool
```

**3b.** Visuelle Behandlung in `ExerciseOverviewRow.body`:

- **Border:** Wenn `isSupersetSelectionMode && isSelectedForSuperset` →
  blauer Border (2pt, `Color.blue`).
- **Checkmark-Badge:** Wenn `isSupersetSelectionMode && isSelectedForSuperset` →
  `checkmark.circle.fill` (weiß auf blau) als Overlay topTrailing.
- **Schloss-Icon:** Wenn `isSupersetSelectionMode && !isEligibleForSuperset && !isInOtherSuperset` →
  `lock.fill` (grau) als Overlay topTrailing, Card-Inhalt
  halbtransparent (`opacity 0.5`).
- **Link-Icon:** Wenn `isSupersetSelectionMode && isInOtherSuperset && !isSelectedForSuperset` →
  `link.circle.fill` (weiß auf blau, halbtransparent) als Overlay
  topTrailing.

**3c.** Tap-Handler in der Row erweitern:
```swift
.contentShape(Rectangle())
.onTapGesture {
    if isSupersetSelectionMode {
        // Im Selection-Modus: Auswahl toggle, nur wenn eligible und
        // nicht bereits in anderem Superset
        guard isEligibleForSuperset, !isInOtherSuperset else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        onToggleSupersetSelection()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    } else {
        // Normaler Tap → bestehende Auswahl-Logik
        onSelect()
    }
}
```

**3d.** Neuer Callback `onToggleSupersetSelection: () -> Void` in der
Row-Signatur.

**3e.** In `ExercisesOverviewCard.body` beim Aufruf von
`ExerciseOverviewRow` die neuen Parameter und den Callback füllen:
```swift
ExerciseOverviewRow(
    // ... bestehende Parameter ...
    isSupersetSelectionMode: isSupersetSelectionMode,
    isSelectedForSuperset: selectedGroupIndicesForSuperset.contains(index),
    isEligibleForSuperset: isEligibleForSuperset(at: index),
    isInOtherSuperset: isInOtherSuperset(at: index),
    onToggleSupersetSelection: {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if selectedGroupIndicesForSuperset.contains(index) {
                selectedGroupIndicesForSuperset.remove(index)
            } else {
                selectedGroupIndicesForSuperset.insert(index)
            }
        }
    }
)
```

### 🛑 STOPP-Gate 3

**Verifikation durch User:**
- [ ] Im Selection-Modus erscheinen die Visuals korrekt:
      - Eligible + nicht ausgewählt: normale Card
      - Eligible + ausgewählt: blauer Border + Checkmark
      - Nicht-eligible (completed Set): Schloss-Icon, halbtransparent,
        Tap blockiert mit Haptic
      - Bereits in Superset: Link-Icon, Tap blockiert mit Haptic
- [ ] Tap im Normalmodus funktioniert wie vorher (Auswahl der Übung).
- [ ] Auswahl persistiert solange der Modus aktiv ist.

---

## Step 4 — Floating Action Bar im Sichtfeld

**Datei:** `ExercisesOverviewCard.swift`

**Was:** Action Bar als Overlay mit `safeAreaInset` auf der ScrollView
würde im Falle dieser Card nicht funktionieren, da `ExercisesOverviewCard`
selbst Teil der ScrollView ist. Stattdessen: Action Bar wird über die
**`ActiveWorkoutView`** gerendert (siehe Step 5). Aber das Triggering
und der State leben in `ExercisesOverviewCard`.

**4a.** Diesen Step in `ExercisesOverviewCard` vorbereiten: State und
Methoden public-zugänglich machen via `@Binding` nach außen.

Property-Liste erweitern:
```swift
@Binding var isSupersetSelectionMode: Bool
@Binding var selectedGroupIndicesForSuperset: Set<Int>
```

Die internen `@State`-Declarations aus Step 2a **entfernen** und durch
Bindings ersetzen. Grund: Die Action Bar muss in der `ActiveWorkoutView`
über der `bottomActionBar` gerendert werden, dort wird derselbe State
gebraucht.

**4b.** Bolt-Button-Action und alle internen Referenzen auf die
Bindings umstellen.

**4c.** Hilfsmethoden `hasContiguousSelection`,
`isEligibleForSuperset(at:)`, `eligibleExerciseCount`,
`isInOtherSuperset(at:)` bleiben in `ExercisesOverviewCard` — werden in
Step 5 aber zusätzlich in der `ActiveWorkoutView` für die Action Bar
gebraucht. Lösung: kleine `SupersetSelectionHelper` Struct, die diese
Logik bündelt und beide Stellen nutzen können.

Eigene Datei `SupersetSelectionHelper.swift`:
```swift
//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / Components                                     /
// Datei . . . . : SupersetSelectionHelper.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.05.2026                                                       /
// Beschreibung  : Reine Berechnungs-Helper für In-Session-Superset-Auswahl.        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct SupersetSelectionHelper {
    let groupedSets: [[ExerciseSet]]

    func isEligible(at index: Int) -> Bool {
        guard index >= 0, index < groupedSets.count else { return false }
        return groupedSets[index].allSatisfy { !$0.isCompleted }
    }

    func isInOtherSuperset(at index: Int) -> Bool {
        guard index >= 0, index < groupedSets.count,
              let id = groupedSets[index].first?.supersetGroupId,
              !id.isEmpty else { return false }
        return true
    }

    var eligibleCount: Int {
        (0..<groupedSets.count).filter { isEligible(at: $0) }.count
    }

    func isContiguous(_ indices: Set<Int>) -> Bool {
        guard indices.count >= 2 else { return false }
        let sorted = indices.sorted()
        return zip(sorted, sorted.dropFirst()).allSatisfy { $1 - $0 == 1 }
    }

    /// Gibt true zurück, wenn ein Superset aus der aktuellen Auswahl
    /// erstellt werden darf.
    func canCreateSuperset(from indices: Set<Int>) -> Bool {
        guard indices.count >= 2, indices.count <= 5 else { return false }
        guard isContiguous(indices) else { return false }
        return indices.allSatisfy { isEligible(at: $0) }
    }
}
```

### 🛑 STOPP-Gate 4

**Verifikation durch User:**
- [ ] `SupersetSelectionHelper.swift` als eigene Datei erstellt und in
      Xcode-Projekt eingebunden.
- [ ] `ExercisesOverviewCard` nutzt Bindings statt internem State.
- [ ] Bolt-Button und Auswahl funktionieren immer noch wie nach Step 3.
- [ ] Es gibt **noch keine Action Bar** — der User sieht zwar die
      Auswahl-Visuals, kann aber noch nichts auslösen außer Tappen.

---

## Step 5 — `ActiveWorkoutView`: Action Bar + Verdrahtung mit Session-API

**Datei:** `ActiveWorkoutView.swift`

**Was:**

**5a.** Neue `@State`-Properties:
```swift
@State private var isSupersetSelectionMode: Bool = false
@State private var selectedGroupIndicesForSuperset: Set<Int> = []
```

**5b.** Bindings an `ExercisesOverviewCard` in `exercisesOverview`
durchreichen plus neuer Callback `onCreateSuperset`:

```swift
private var exercisesOverview: some View {
    ExercisesOverviewCard(
        groupedSets: setManager.cachedGroupedSets,
        currentExerciseIndex: setManager.cachedCurrentExerciseIndex,
        selectedExerciseKey: exerciseNav.selectedExerciseKey,
        prSetIDs: prSetIDs,
        isSupersetSelectionMode: $isSupersetSelectionMode,
        selectedGroupIndicesForSuperset: $selectedGroupIndicesForSuperset,
        onAddExercise: { showAddExerciseSheet = true },
        onSelectExercise: { key in
            exerciseNav.selectExercise(key: key)
            hapticGenerator.impactOccurred()
        },
        onDeleteExercise: { key in deleteExercise(groupKey: key) },
        onReorderExercise: { from, to in
            exerciseNav.reorderExercise(from: from, to: to, in: setManager.cachedGroupedSets)
            setManager.rebuildGroupedCaches()
            setManager.refreshSetCaches()
            Task { @MainActor in try? context.save() }
            hapticGenerator.impactOccurred()
        },
        onRemoveFromSuperset: { index in
            removeFromSupersetAtIndex(index)
        },
        onRetroRIR: { set in rirRetroSet = set }
    )
}
```

**5c.** Floating Action Bar als Overlay im `body` der View. Position:
über der `bottomActionBar`, also im selben `VStack` wo
`bottomActionBar` sitzt, **direkt davor**:

```swift
VStack {
    Spacer()
    if isSupersetSelectionMode {
        supersetActionBar
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    bottomActionBar
}
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSupersetSelectionMode)
```

**5d.** `supersetActionBar` als private var (analog zu Plan-Edit, mit
deutscher Beschriftung):

```swift
private var supersetActionBar: some View {
    let helper = SupersetSelectionHelper(groupedSets: setManager.cachedGroupedSets)
    let canCreate = helper.canCreateSuperset(from: selectedGroupIndicesForSuperset)
    let hasGap = selectedGroupIndicesForSuperset.count >= 2
        && !helper.isContiguous(selectedGroupIndicesForSuperset)

    return HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(selectedGroupIndicesForSuperset.count) Übungen ausgewählt")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            if hasGap {
                Text("Nur aufeinanderfolgende Übungen")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Mindestens 2 für ein Superset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Spacer()

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isSupersetSelectionMode = false
                selectedGroupIndicesForSuperset = []
            }
        } label: {
            Text("Abbrechen")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        Button {
            createSupersetFromSelection()
        } label: {
            Text("Superset")
                .font(.subheadline.bold())
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    canCreate ? Color.blue : Color.blue.opacity(0.3),
                    in: Capsule()
                )
        }
        .disabled(!canCreate)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
    )
    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
}
```

**5e.** Action-Methoden:

```swift
private func createSupersetFromSelection() {
    let indices = Array(selectedGroupIndicesForSuperset)
    session.createSuperset(fromGroupIndices: indices)

    Task { @MainActor in
        try? context.save()
    }

    // Cache-Refresh — sonst zeigt ExercisesOverviewCard alte Daten
    setManager.rebuildGroupedCaches()
    setManager.refreshSetCaches()

    // Selection-Modus beenden
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isSupersetSelectionMode = false
        selectedGroupIndicesForSuperset = []
    }

    completionHapticMedium.impactOccurred()
}

private func removeFromSupersetAtIndex(_ index: Int) {
    session.removeFromSuperset(groupAt: index)

    Task { @MainActor in
        try? context.save()
    }

    setManager.rebuildGroupedCaches()
    setManager.refreshSetCaches()

    hapticGenerator.impactOccurred()
}
```

**5f.** Im Kontextmenü von `ExerciseOverviewRow` (vermutlich existiert
ein Menu pro Row für Delete) den neuen Eintrag "Aus Superset entfernen"
ergänzen, der den `onRemoveFromSuperset(index)`-Callback auslöst.
Sichtbar nur wenn `groupedSets[index].first?.supersetGroupId != nil`.

### 🛑 STOPP-Gate 5

**Verifikation durch User (End-to-End-Test):**

**5-Test A — Standard-Fall (Bartos Use Case):**
- [ ] Workout mit 5 Übungen starten, keine Sätze abschließen.
- [ ] Bolt-Button tippen → Selection-Modus aktiv, Action Bar erscheint
      im Sichtfeld über der Pause/Beenden-Bar.
- [ ] 5 Übungen antippen → alle blau markiert, Action Bar zeigt "5
      Übungen ausgewählt".
- [ ] "Superset" tippen → Action Bar verschwindet, Übungen sind
      visuell verbunden (Link-Visuals wie Plan-Edit).
- [ ] In `ExercisesOverviewCard` sind die Übungen jetzt mit Superset-
      Verbindungen sichtbar.
- [ ] `RestTimerCard` zeigt nach erstem Satz "Nächste Runde" mit den
      Folge-Übungen.

**5-Test B — Eligibility:**
- [ ] Workout mit 3 Übungen, 1 Satz von Übung 1 abschließen.
- [ ] Bolt-Button tippen → Übung 1 zeigt Schloss-Icon, Tap blockiert
      mit Haptic.
- [ ] Übung 2 + 3 wählbar, Superset erstellbar.

**5-Test C — Lücken-Erkennung:**
- [ ] Workout mit 4 Übungen, Übung 1 + 3 wählen → Action Bar zeigt
      "Nur aufeinanderfolgende Übungen" in Orange, "Superset"-Button
      disabled.

**5-Test D — Mehrere Supersets:**
- [ ] Workout mit 6 Übungen, Übungen 1+2 als Superset erstellen.
- [ ] Bolt-Button erneut tippen, Übungen 4+5 als zweites Superset.
- [ ] Beide Supersets unabhängig, jeweils eigene `supersetGroupId`.

**5-Test E — Auflösen:**
- [ ] Im Kontextmenü einer Superset-Übung "Aus Superset entfernen"
      tippen.
- [ ] Wenn dadurch nur noch eine Übung übrig: ganzes Superset
      aufgelöst.

**5-Test F — Plan bleibt unverändert:**
- [ ] Nach Workout-Ende: Plan-Detail aufrufen, prüfen dass keine
      Supersets im Plan eingetragen sind.
- [ ] Falls Smart Plan-Update aktiv ist: PlanUpdateSheet zeigt keinen
      Superset-Diff (nur Weight/Reps).

**Allgemein:**
- [ ] `ActiveWorkoutView.swift` bleibt unter 1000 Zeilen.
      Falls darüber: `supersetActionBar` in eigene Datei
      `ActiveWorkoutSupersetActionBar.swift` extrahieren.
- [ ] Kein `print()` zurückgeblieben.
- [ ] Live Activity + Watch-Sync funktioniert weiter unverändert.

---

## Step 6 — Cleanup + Edge-Case-Check

**Was:** Nach Bestätigung von Step 5 Schluss-Check der Implementation.

**6a.** Code-Review-Checkliste:
- [ ] Alle deutschen UI-Strings korrekt geschrieben (keine Tippfehler).
- [ ] Keine Force-Unwraps eingeführt außer dem dokumentierten in
      Step 1 (`sorted.last!` — durch `guard sorted.count >= 2` safe).
- [ ] `MARK` Sections konsistent.
- [ ] File-Header in neuen Dateien vorhanden mit korrektem Datum.

**6b.** Bekannte Edge Cases manuell durchspielen:
- [ ] Selection-Modus während aktiver Pause: Pause-Timer läuft weiter.
- [ ] Pull-to-refresh / Backgrounding während Selection-Modus: State
      bleibt erhalten oder wird sauber zurückgesetzt (egal welches,
      darf nicht crashen).
- [ ] Sort-Modus + Selection-Modus mutex (gegenseitig ausschließend).

**6c.** Conventional Commit als Vorschlag:
```
feat(active-workout): in-session superset creation

Adds multi-select mode in ExercisesOverviewCard with floating action
bar to create supersets from contiguous, not-yet-started exercises
during an active workout. Plan template stays unchanged.

- StrengthSession.createSuperset(fromGroupIndices:)
- StrengthSession.removeFromSuperset(groupAt:)
- SupersetSelectionHelper for eligibility + contiguity checks
- Rest seconds auto-adjusted: 0s for intra-round, original for last
  exercise per round
- Multiple supersets per session supported
```

### 🛑 STOPP-Gate 6 — Final

**Verifikation durch User:**
- [ ] Alle Tests aus Step 5 erfolgreich.
- [ ] Code committed mit obigem Conventional-Commit-Message.
- [ ] Feature-Wunsch "Konfigurierbare Pausenzeit im Superset" in den
      Projekt-Backlog aufgenommen.

---

## Hinweise für Claude Code

- **Reihenfolge strikt einhalten.** Step 5 funktioniert nicht ohne
  Step 1; Step 3 nicht ohne Step 2.
- **Bei jedem STOPP-Gate warten**, nicht weiterarbeiten ohne
  User-Bestätigung.
- **Keine Refactorings nebenbei.** Wenn dir andere Code-Smells
  auffallen, am Ende als Liste melden, nicht ungefragt anfassen.
- **Tools:** `project_knowledge_search` für aktuelle MotionCore-Files
  ist authoritative. Context7 für SwiftUI/SwiftData-Doku falls nötig.
- **File-Limits:** Bei >600 Zeilen warnen, bei >800 stoppen und
  Extraktion vorschlagen.
