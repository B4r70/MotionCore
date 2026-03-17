# MotionCore — Superset-Gruppierung: Konzept & Implementierungsplan

> **Ziel:** Übungen im Trainingsplan zu echten Superset-Gruppen zusammenfassen (2–5 Übungen).  
> Während des Workouts rotiert die App automatisch durch die Gruppe — **ohne Pause zwischen den Übungen**, erst nach einer vollständigen Runde startet der Rest-Timer.

---

## 1. Ausgangslage (Ist-Zustand)

### Datenmodell

- `ExerciseSet` hat bereits `supersetGroupId: String?` — Sets mit gleichem Wert gehören zusammen
- `TrainingPlan.toggleSuperset(forGroupAt:)` verknüpft aktuell **immer nur paarweise** (Übung A ↔ nächste Übung B)
- Auflösen entfernt die **gesamte Gruppe** statt einzelne Übungen

### Workout-Steuerung (`ActiveWorkoutView.completeSet`)

- Nach `isCompleted = true` wird geprüft, ob die **aktuelle Übung** noch offene Sätze hat
- Falls ja → `restTimerManager.start(seconds:)` — **immer**, auch bei Supersets
- Kein Wechsel zur nächsten Superset-Übung
- `supersetNextExercise(for:)` existiert zwar, zeigt aber nur einen Text-Hinweis in `ActiveSetCard`

### UI im Trainingsplan

- `TemplateSetCard` zeigt ein Link-Icon bei Supersets
- Kontextmenü bietet "Superset mit nächster" / "Superset auflösen" (binärer Toggle)
- `ExercisesOverviewCard` zeichnet vertikale Linien zwischen Superset-Partnern

---

## 2. Datenmodell-Änderungen

### Keine Migration nötig

Die bestehende `supersetGroupId: String?` reicht aus. Alle Übungen mit identischer `supersetGroupId` bilden eine Gruppe. Die Reihenfolge innerhalb der Gruppe ergibt sich aus `sortOrder`.

### Keine neuen Properties

Die `sortOrder`-Sortierung innerhalb gleicher `supersetGroupId` definiert die Rotationsreihenfolge implizit. Kein neues Feld nötig.

---

## 3. Plan-Konfiguration: Multi-Select-Gruppierung

### 3.1 Neuer UI-Flow in `PlanExercisesSection` / `ReorderableExerciseList`

**Grundidee:** Ein dedizierter "Superset-Modus" in dem der User 2–5 Übungen per Tap auswählt und zu einer Gruppe zusammenfasst.

#### Aktivierung

- Neuer Button im Header der Übungsliste: **"Superset"** (SF Symbol: `rectangle.stack.badge.plus`)
- Alternativ: Im bestehenden Edit-Modus als zusätzliche Option
- Tapping aktiviert den **Superset-Auswahl-Modus**

#### Auswahl-Modus

- Übungskarten bekommen einen **Selektions-Indikator** (Checkbox oder farbigen Rahmen)
- Tap auf eine Karte togglet die Selektion
- Oben oder unten erscheint eine **Floating Action Bar** mit:
  - Anzeige: "X Übungen ausgewählt"
  - Button: **"Superset erstellen"** (aktiv ab 2 Übungen)
  - Button: **"Abbrechen"**
- Maximum: 5 Übungen pro Superset (sinnvolle Obergrenze, per Konstante konfigurierbar)
- Übungen die **bereits in einem Superset** sind, werden ausgegraut oder mit Hinweis versehen

#### Bestätigung

- Alle ausgewählten Sets bekommen die gleiche `supersetGroupId` (neue `UUID().uuidString`)
- Die `sortOrder`-Werte werden so angepasst, dass die Superset-Übungen **aufeinanderfolgend** im Plan stehen
- Danach wird der Auswahl-Modus beendet

### 3.2 Anpassung `toggleSuperset` → `removeSupersetMembership`

Die bestehende `toggleSuperset(forGroupAt:)` Methode wird ersetzt durch:

```swift
// TrainingPlan.swift

/// Entfernt eine einzelne Übung aus ihrer Superset-Gruppe.
/// Falls nur noch eine Übung in der Gruppe verbleibt, wird die Gruppe aufgelöst.
func removeFromSuperset(groupAt index: Int) {
    let groups = groupedTemplateSets
    guard index < groups.count else { return }
    let targetGroup = groups[index]

    guard let groupId = targetGroup.first?.supersetGroupId else { return }

    // Diese Übung aus dem Superset entfernen
    targetGroup.forEach { $0.supersetGroupId = nil }

    // Prüfen ob die verbleibende Gruppe noch ≥ 2 Übungen hat
    let remaining = safeTemplateSets.filter { $0.supersetGroupId == groupId }
    let remainingExerciseKeys = Set(remaining.map { $0.groupKey })

    if remainingExerciseKeys.count < 2 {
        // Nur noch eine Übung → Gruppe komplett auflösen
        remaining.forEach { $0.supersetGroupId = nil }
    }
}

/// Erstellt ein neues Superset aus den übergebenen Gruppen-Indizes.
/// Passt sortOrder an, sodass die Übungen aufeinanderfolgend stehen.
func createSuperset(fromGroupIndices indices: [Int]) {
    let groups = groupedTemplateSets
    let validIndices = indices.filter { $0 < groups.count }.sorted()
    guard validIndices.count >= 2 else { return }

    let newGroupId = UUID().uuidString

    // supersetGroupId setzen
    for index in validIndices {
        groups[index].forEach { $0.supersetGroupId = newGroupId }
    }

    // Übungen zusammenrücken (sortOrder anpassen)
    // Die erste ausgewählte Übung bleibt an ihrer Position,
    // die anderen rücken direkt dahinter
    let anchorOrder = groups[validIndices[0]].first?.sortOrder ?? 1
    for (offset, index) in validIndices.enumerated() {
        groups[index].forEach { $0.sortOrder = anchorOrder + offset }
    }

    // Alle anderen Übungen neu nummerieren um Lücken zu vermeiden
    reindexSortOrders()
}

/// Nummeriert alle sortOrder-Werte lückenlos neu (1-basiert)
private func reindexSortOrders() {
    let allGroups = groupedTemplateSets // bereits nach sortOrder sortiert
    for (index, group) in allGroups.enumerated() {
        group.forEach { $0.sortOrder = index + 1 }
    }
}
```

### 3.3 Kontextmenü-Anpassung in `TemplateSetCard`

Das bestehende Kontextmenü-Item wird angepasst:

| Zustand | Menü-Option | Aktion |
|---------|-------------|--------|
| Nicht im Superset | *(kein Menü-Item — Superset wird über den Auswahl-Modus erstellt)* | — |
| Im Superset | "Aus Superset entfernen" | `removeFromSuperset(groupAt:)` |

Der alte "Superset mit nächster" Eintrag wird **entfernt**. Die Gruppierung läuft ausschließlich über den Multi-Select-Modus.

### 3.4 Visuelle Darstellung im Plan

- Übungen im gleichen Superset werden mit einem **durchgehenden farbigen Seitenstreifen** (blau, 3pt, links) visuell gruppiert — analog zur bestehenden Linie in `ExercisesOverviewCard`
- Über der Gruppe: kleines Label **"Superset (3 Übungen)"** in blau
- Zwischen Superset-Übungen: **reduzierter Abstand** (4pt statt 12pt) um die Zusammengehörigkeit zu betonen

---

## 4. Workout-Steuerung: Superset-Rotation

### 4.1 Kernlogik in `completeSet`

Die bestehende `completeSet(_:)` Methode in `ActiveWorkoutView` wird um eine Superset-Rotation erweitert:

```swift
// ActiveWorkoutView.swift — completeSet(_:) Erweiterung

private func completeSet(_ set: ExerciseSet) {
    withAnimation(.easeInOut) {
        set.isCompleted = true
    }
    try? context.save()

    // ... bestehende PR-Prüfung bleibt ...

    // ... bestehende selectedExerciseKey-Logik bleibt ...

    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()

    // ============================================================
    // NEU: Superset-Rotation
    // ============================================================
    if let groupId = set.supersetGroupId {
        handleSupersetRotation(completedSet: set, supersetGroupId: groupId)
        return   // ← frühzeitiger Return, kein normaler Rest-Timer
    }

    // ============================================================
    // Bestehende Logik (kein Superset)
    // ============================================================
    let remainingSetsForExercise = session.safeExerciseSets.filter {
        $0.groupKey == set.groupKey && !$0.isCompleted
    }
    if !remainingSetsForExercise.isEmpty {
        restTimerManager.start(seconds: set.restSeconds)
    }
}
```

### 4.2 Neue Methode: `handleSupersetRotation`

```swift
/// Steuert die Rotation innerhalb eines Supersets.
///
/// Ablauf einer Runde:
///   Crunches (Satz 1) → Beinheben (Satz 1) → Russian Twist (Satz 1) → PAUSE
///   Crunches (Satz 2) → Beinheben (Satz 2) → Russian Twist (Satz 2) → PAUSE
///   ...
///
/// Regeln:
/// - Zwischen Superset-Übungen: KEIN Rest-Timer
/// - Nach einer vollständigen Runde: Rest-Timer starten
/// - Nächste Runde beginnt bei der ersten Übung der Gruppe mit offenen Sätzen
private func handleSupersetRotation(completedSet: ExerciseSet, supersetGroupId: String) {

    // 1. Alle Übungs-Keys in dieser Superset-Gruppe (sortiert nach sortOrder)
    let supersetKeys: [String] = session.groupedSets
        .filter { $0.first?.supersetGroupId == supersetGroupId }
        .sorted { ($0.first?.sortOrder ?? 0) < ($1.first?.sortOrder ?? 0) }
        .compactMap { $0.first?.groupKey }

    guard !supersetKeys.isEmpty else { return }

    // 2. Position der gerade abgeschlossenen Übung in der Rotation
    let currentIndex = supersetKeys.firstIndex(of: completedSet.groupKey) ?? 0

    // 3. Suche die NÄCHSTE Übung in der Rotation (nur nach der aktuellen, kein wrap-around)
    let nextInRound = supersetKeys
        .suffix(from: currentIndex + 1)  // alles NACH der aktuellen Übung
        .first { key in
            session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
        }

    if let nextKey = nextInRound {
        // → Noch nicht alle Übungen dieser Runde durch
        // → Direkt zur nächsten Übung wechseln, KEIN Timer
        withAnimation(.easeInOut) {
            selectedExerciseKey = nextKey
        }
    } else {
        // → Diese Runde ist komplett
        // → Prüfen ob es noch weitere Runden gibt
        let anyOpenInGroup = supersetKeys.contains { key in
            session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
        }

        if anyOpenInGroup {
            // Noch Runden übrig → Rest-Timer starten
            restTimerManager.start(seconds: completedSet.restSeconds)

            // Nach der Pause: zur ersten offenen Übung der Gruppe springen
            let firstOpenKey = supersetKeys.first { key in
                session.safeExerciseSets.contains { $0.groupKey == key && !$0.isCompleted }
            }
            if let key = firstOpenKey {
                withAnimation(.easeInOut) {
                    selectedExerciseKey = key
                }
            }
        }
        // Falls keine offenen Sätze mehr → normales Verhalten
        // (ExerciseCompletedCard / WorkoutCompletedCard greift automatisch)
    }
}
```

### 4.3 Sonderfall: Ungleiche Satzanzahlen

Wenn Crunches 4 Sätze hat, Beinheben nur 3, und Russian Twist 3:

- Runde 4: Nur noch Crunches hat einen offenen Satz
- `nextInRound` findet nichts nach Crunches → Runde gilt als komplett
- `anyOpenInGroup` ist `false` (Crunches war die letzte) → kein Timer
- Funktioniert korrekt ohne Sonderbehandlung

---

## 5. UI-Anpassungen im aktiven Workout

### 5.1 `ActiveSetCard` — Superset-Indikator erweitern

Der bestehende Hinweis "Superset — weiter mit: Beinheben" wird zu einem **Rotations-Tracker**:

```
┌─────────────────────────────────────────┐
│  🔗  Superset – Runde 1/3              │
│  ● Crunches  ○ Beinheben  ○ R. Twist   │
└─────────────────────────────────────────┘
```

- Ausgefüllter Punkt (●) = aktuell aktiv
- Leerer Punkt (○) = kommt als nächstes in dieser Runde
- Häkchen (✓) = in dieser Runde bereits abgeschlossen

Benötigte Daten für die `ActiveSetCard`:
- `supersetExerciseNames: [String]` — alle Übungen in der Gruppe
- `currentSupersetIndex: Int` — welche Übung gerade aktiv ist
- `supersetRoundNumber: Int` — aktuelle Runde
- `supersetTotalRounds: Int` — Gesamtanzahl Runden

### 5.2 `ExercisesOverviewCard` — Gruppierung beibehalten

Die bestehende vertikale Linie (`isSupersetConnectedAbove/Below`) funktioniert bereits korrekt für Gruppen mit mehr als 2 Übungen, da sie auf `supersetGroupId`-Gleichheit prüft. **Keine Änderung nötig.**

### 5.3 `RestTimerCard` — "Nächste Runde" Hinweis

Wenn der Rest-Timer nach einer Superset-Runde läuft, kann optional angezeigt werden:

```
Pause – Nächste Runde: Crunches → Beinheben → Russian Twist
```

Statt des bisherigen "Nächste Übung: X".

---

## 6. Betroffene Dateien — Zusammenfassung

| Datei | Änderung | Aufwand |
|-------|----------|---------|
| **`TrainingPlan.swift`** | `createSuperset()`, `removeFromSuperset()`, `reindexSortOrders()` — alte `toggleSuperset` entfernen | Mittel |
| **`ActiveWorkoutView.swift`** | `handleSupersetRotation()` in `completeSet` integrieren, Helper-Properties für Runden-Info | Mittel |
| **`PlanExercisesSection.swift`** | Multi-Select-Modus mit `@State var supersetSelectionMode`, `@State var selectedForSuperset: Set<Int>`, Floating Action Bar | Hoch |
| **`ReorderableExerciseList`** | Selection-Overlay auf Cards im Superset-Modus, `onCreateSuperset`-Callback | Mittel |
| **`TemplateSetCard.swift`** | Kontextmenü: "Superset mit nächster" ersetzen durch "Aus Superset entfernen" | Klein |
| **`ActiveSetCard.swift`** | Superset-Rotations-Tracker (Punkte-Anzeige) statt einfachem Text-Hinweis | Mittel |
| **`RestTimerCard.swift`** | Optional: "Nächste Runde"-Anzeige mit Übungsnamen | Klein |
| **`ExercisesOverviewCard.swift`** | Keine Änderung nötig (funktioniert bereits für N Übungen) | — |

---

## 7. Implementierungsreihenfolge

### Phase 1: Datenlogik (kein UI)
1. `TrainingPlan.createSuperset(fromGroupIndices:)`
2. `TrainingPlan.removeFromSuperset(groupAt:)`
3. `TrainingPlan.reindexSortOrders()`
4. Alte `toggleSuperset(forGroupAt:)` entfernen

### Phase 2: Plan-UI
5. Multi-Select-Modus in `PlanExercisesSection`
6. Floating Action Bar mit "Superset erstellen" / "Abbrechen"
7. Selection-Overlay auf `ReorderableExerciseList`
8. Kontextmenü in `TemplateSetCard` anpassen
9. Visuelle Gruppierung (Seitenstreifen, Label, reduzierter Abstand)

### Phase 3: Workout-Rotation
10. `handleSupersetRotation()` in `ActiveWorkoutView`
11. Integration in `completeSet()`
12. Superset-Rotations-Tracker in `ActiveSetCard`

### Phase 4: Polish
13. "Nächste Runde"-Anzeige in `RestTimerCard`
14. Watch-Integration prüfen (`sendWatchState` muss Superset-Kontext mitgeben?)
15. Live Activity: Superset-Status im Dynamic Island anzeigen?

---

## 8. Architektur-Hinweise

- **Kein CalcEngine nötig:** Die Superset-Rotation ist reines UI-Steuerungsverhalten (welcher Key ist selektiert? Wird ein Timer gestartet?). Das gehört in die View-Logik, nicht in einen CalcEngine.
- **Kein neues Model:** Alles nutzt die bestehende `supersetGroupId` auf `ExerciseSet`.
- **Keine SwiftData-Migration:** Keine neuen Properties, keine Strukturänderungen.
- **Keine Supabase-Änderung:** `supersetGroupId` wird bereits im Session-Upload mitgesendet.
- **CloudKit:** Keine Anpassung, da `supersetGroupId` bereits Teil des Models ist.
- **Kommentare auf Deutsch**, Variablen/Methoden auf Englisch.
- **Kein Testcode** — nur Produktionscode.

---

## 9. Offene Entscheidungen

| Frage | Optionen |
|-------|----------|
| Max. Übungen pro Superset? | 3 / 4 / 5 (Empfehlung: **5**) |
| Können Supersets im aktiven Workout erstellt werden? | Erstmal **nein** — nur im Trainingsplan. Später als Feature denkbar. |
| Soll die Übungsreihenfolge innerhalb eines Supersets änderbar sein? | Ja, über das bestehende Drag & Drop. Constraint: Superset-Übungen müssen zusammenbleiben. |
| Rest-Timer: gleiche Pausenzeit für alle oder individuell pro Übung? | Aktuell: `restSeconds` kommt vom letzten Set. Empfehlung: **letzte Übung in der Runde bestimmt die Pausenzeit.** |
