# PlanExercisesSection Drag & Drop Redesign

**Complexity:** Medium
**Status:** Warte auf Genehmigung

## Summary

Die komplexe dreiteilige Drag-Architektur (`ReorderableExerciseList` + `ReorderableCard` + `FloatingDragCard`) in `PlanExercisesSection.swift` wird durch das schlankere, bewährte Pattern aus `ExercisesOverviewCard.swift` ersetzt. Drag-State und -Logik werden direkt in `PlanExercisesSection` integriert, Drag-Handle als Overlay auf `TemplateSetCard`, Floating Card als ZStack-Overlay. Der Superset-Selection-Modus bleibt vollständig erhalten. Ein Doppel-Sortierungs-Bug (Zeile 197-199) wird dabei bereinigt.

## Scope

- **Enthalten**: Entfernung von `ReorderableExerciseList`, `ReorderableCard`, `FloatingDragCard`; Integration der Drag-Logik direkt in `PlanExercisesSection`; `RowOffsetModifier` als private struct; Bereinigung des Doppel-Sortierungs-Bugs; Anpassung `TrainingFormView` (Entfernung des jetzt unnötigen `onMoveExercise`-Callbacks)
- **Nicht enthalten**: Änderungen an `TemplateSetCard`, `ExerciseDetailRow`, dem `.detail`-Modus, dem Superset-Selection-Modus (inhaltlich), `TrainingDetailView`

## Affected Files

- `MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift` — Entfernung von `ReorderableExerciseList`, `ReorderableCard`, `FloatingDragCard`; Drag-State + Drag-Logik + ZStack-Pattern direkt in `PlanExercisesSection` integrieren
- `MotionCore/Views/Training/Plans/View/TrainingFormView.swift` — `onMoveExercise`-Callback entfernen

## Risks

- Superset-Selection-Modus und Sort-Modus müssen gegenseitig exklusiv bleiben
- `TemplateSetCard` hat eigenen `.glassCard()`-Modifier — Offset/Opacity-Modifikation muss außerhalb erfolgen
- Doppel-Sortierungs-Bug: aktuell wird bei jedem Reorder sowohl der Parent-Callback als auch direkt `plan.reorderExercise` aufgerufen — im neuen Pattern nur noch einmal direkt

## Implementation Steps

### Phase 1: PlanExercisesSection umbauen

- [x] **1.1 Drag-State in PlanExercisesSection integrieren**: Die vier States (`draggingIndex: Int?`, `dragOffset: CGSize`, `cardHeights: [Int: CGFloat]`, `lastTargetIndex: Int?`) direkt als `@State` in `PlanExercisesSection` hinzufügen. `averageCardHeight` und `cardSpacing` (12) übernehmen.

- [x] **1.2 `onMoveExercise`-Callback entfernen**: Die Property `var onMoveExercise: ((IndexSet, Int) -> Void)? = nil` aus `PlanExercisesSection` entfernen. Reordering geschieht direkt via `plan.reorderExercise(from:to:)` + `try? modelContext.save()`.

- [x] **1.3 `exercisesList` für `.form`-Modus neu schreiben**: Statt `ReorderableExerciseList` direkt ein `ZStack(alignment: .top)` mit Hintergrund-VStack (ForEach über `plan.groupedTemplateSets.enumerated()`) + Floating Card Overlay. Superset-Labels und -Spacing bleiben.

- [x] **1.4 Drag-Handle als Overlay**: Im Sort-Modus auf jeder `TemplateSetCard` ein `.overlay(alignment: .trailing)` mit Drag-Handle (`line.3.horizontal`) + `LongPressGesture(0.2s).sequenced(before: DragGesture())`. Superset-Mitglieder: `link`-Icon ohne Gesture.

- [x] **1.5 Superset-Overlays beibehalten**: Die Superset-Selection-Overlays (grüner Tint, Auswahl-Stroke, Checkmark-Badge, Tap-Gesture) direkt auf `TemplateSetCard` anwenden.

- [x] **1.6 Drag-Logik-Methoden integrieren**: `yStart(for:)`, `calculateFloatingCardPosition(for:)`, `calculateTargetIndex(from:)`, `offsetForIndex(_:)` analog zum `ExercisesOverviewCard`-Pattern in `PlanExercisesSection` integrieren.

- [x] **1.7 `RowOffsetModifier` als private struct**: 6-zeiligen `RowOffsetModifier` am Ende der Datei als `private struct` hinzufügen.

- [x] **1.8 Gegenseitige Exklusivität**: Beim Aktivieren von `isSupersetSelectionMode` → `isEditing = false`. Beim Aktivieren von `isEditing` → `isSupersetSelectionMode = false`. Drag-State beim Verlassen des Sort-Modus zurücksetzen.

- [x] **1.9 `ReorderableExerciseList`, `ReorderableCard`, `FloatingDragCard` entfernen**: Die drei Structs komplett löschen.

### Phase 2: TrainingFormView anpassen

- [x] **2.1 `onMoveExercise`-Parameter entfernen**: In `TrainingFormView` den `onMoveExercise:`-Parameter aus dem `PlanExercisesSection`-Aufruf entfernen. Methode `moveExercise(from:to:)` ebenfalls entfernen.

## Manual Verification

- [ ] Xcode Build (`Cmd+B`)
- [ ] Sortier-Button im Header sichtbar
- [ ] Sort-Button aktiviert Sortiermodus: Drag-Handles erscheinen, Plus/Bolt-Buttons verschwinden
- [ ] Drag auf Handle verschiebt Übung mit Floating Card + Haptic
- [ ] Reihenfolge persistiert nach Dismiss und Rückkehr
- [ ] Superset-Selection-Modus funktioniert wie bisher
- [ ] Superset-Mitglieder zeigen Link-Icon statt Drag-Handle
- [ ] Kontextmenü (Edit/Delete) funktioniert außerhalb des Sort-Modus
- [ ] `.detail`-Modus (`TrainingDetailView`) unverändert

---

## Fortschritt

**Datum:** 2026-03-29

**Abgeschlossene Schritte:** 1.1–1.9, 2.1

**Geänderte Dateien:**
- `MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift` — `ReorderableExerciseList`, `ReorderableCard`, `FloatingDragCard` entfernt; Drag-State + Drag-Logik + ZStack-Pattern direkt in `PlanExercisesSection` integriert; `onMoveExercise`-Property entfernt; gegenseitige Exklusivität via `.onChange` gesichert; `RowOffsetModifier` als private struct; `isSupersetFollower(at:)` als neue Hilfsmethode; `spacingAfter` in `offsetForIndex` und `yStart` eingebaut für korrekte Superset-Abstände
- `MotionCore/Views/Training/Plans/View/TrainingFormView.swift` — `onMoveExercise:`-Parameter aus `PlanExercisesSection`-Aufruf entfernt; `moveExercise(from:to:)`-Methode entfernt

**Verbleibend:** Manuelle Verifikation via Xcode Build + Simulator
