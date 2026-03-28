# Quality Gate — Übungs-Reihenfolge in ActiveWorkoutView

**Datum:** 2026-03-28

## Review Status: Genehmigt (alle Findings behoben)
## Verification Status: Statisch plausibel

---

## Findings (alle behoben)

**1. [Mittel → BEHOBEN] LongPress beendet Edit-Modus nicht**
- `ExercisesOverviewCard.swift`, Zeile 76
- `isEditMode = true` → `isEditMode.toggle()`

**2. [Niedrig → BEHOBEN] Kein `context.save()` nach Reorder**
- `ActiveWorkoutView.swift`, Ende von `reorderExercise()`
- `Task { @MainActor in try? context.save() }` ergänzt — konsistent mit `completeSet` und anderen Schreibpfaden

**3. [Niedrig → BEHOBEN] Inline `UIImpactFeedbackGenerator` ohne `prepare()`**
- `ActiveWorkoutView.swift`, Zeile 664
- `UIImpactFeedbackGenerator(style: .light).impactOccurred()` → `hapticGenerator.impactOccurred()`

**4. [Info] `isPressed: false` hardcoded in `ExerciseOverviewRow` — vorbestehend**
- Kein Handlungsbedarf für diesen Task.

---

## Positives

- Superset-Block-Algorithmus korrekt: Indices absteigend entfernt, Insert bei `newBlockStart + offset`
- Out-of-bounds-Guards vollständig in beiden Pfaden (Einzelübung + Block)
- `sortOrder`-Vergabe via `enumerated()` nach Swap korrekt
- Cache-Refresh via `session.groupedSets` konsistent mit dem restlichen Pattern
- `guard !isEditMode else { return }` schützt `onSelectExercise` zuverlässig
- ↑/↓ kombiniert `.disabled(true)` + `.opacity(0)` — korrekt und barrierefreiheitskonform
- Alter LongPress-Direktlösch-Flow vollständig ersetzt

---

## Manual Verification Required

- [ ] Xcode Build (`Cmd+B`)
- [ ] LongPress → Edit-Modus aktiviert; erneuter LongPress → Edit-Modus deaktiviert
- [ ] "Fertig"-Button → Edit-Modus deaktiviert
- [ ] Up/Down-Pfeile verschieben Übung korrekt
- [ ] Erster/letzter Eintrag: Pfeil in Richtung Ende unsichtbar + disabled
- [ ] Tap im Edit-Modus → kein `onSelectExercise`
- [ ] X-Button → Delete-Alert wie bisher
- [ ] Superset-Block: beide Übungen springen gemeinsam
- [ ] Nach Session-Neustart: neue Reihenfolge erhalten
