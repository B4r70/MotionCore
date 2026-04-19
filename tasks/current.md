# Ausklappbare Exercise Rows in ExercisesOverviewCard

**Complexity:** Medium

## Summary

Implementierung ausklappbarer Übungs-Rows in `ExercisesOverviewCard` laut Instruction-Dokument. Accordion-Verhalten mit Chevron, Satz-Detail-Sektion, Play-Icon zur Auswahl aktiver Übung und Reaktivität auf `selectedExerciseKey` + `isSortMode`. Umsetzung in 7 streng sequenziellen Schritten mit STOPP nach jedem Schritt.

## Scope

**Enthalten:**
- Neuer Parameter `selectedExerciseKey` in `ExercisesOverviewCard`
- `@State expandedExerciseKey` + Reaktivität (onAppear / onChange)
- Erweiterung `ExerciseOverviewRow` (isExpanded, onToggleExpand, onSelectAsActive, Tap-Handler)
- Chevron-Indikator in topLine
- Neue private Subview `ExerciseOverviewExpandedDetail`
- Play-Icon bei nicht-aktiven Übungen
- Edge-Case-Verifikation inkl. Superset-Linien und Sortiermodus

**Explizit ausgeschlossen:**
- Keine Änderungen an bestehender Drag-&-Drop-Logik
- Keine Änderungen an Superset-Verbindungslinien
- Keine Refactorings nebenbei
- Keine Auslagerung in eigene Datei (nur falls >600 Zeilen nach Schritt 7 — dann separat besprechen)

## Affected Files

- `Views/.../ExercisesOverviewCard.swift` — neuer Parameter, State, Subview-Erweiterung, neue `ExerciseOverviewExpandedDetail`-Subview (~448 → ~530 Zeilen)
- `Views/.../ActiveWorkoutView.swift` — eine Zeile: Parameter `selectedExerciseKey:` an Aufrufstelle von `ExercisesOverviewCard`

## Risks

- Datei-Größen-Risiko: Prognose ~530 Zeilen, Warnschwelle 600 Zeilen — falls Schritt 7 drüber → STOPP und Auslagerung besprechen
- Tap-Gesten-Konflikt: Play-Button darf Row-Tap nicht propagieren (`.buttonStyle(.plain)` sollte genügen; Fallback `simultaneousGesture` notiert)
- Drag-Floating-Row: neue Parameter müssen in beiden Row-Aufrufen (Background + Drag-Floating) gesetzt werden — leicht vergessen
- Animation-Race: gleichzeitiges `onChange(selectedExerciseKey)` + manuelles Toggle könnten sich überlagern — geminderte Risiken durch konsistente `withAnimation(.easeInOut(duration: 0.25))`
- Superset-Linien: dürfen bei ausgeklappter Row visuell nicht brechen — explizit im Edge-Case-Test

## Implementation Steps

- [x] **Schritt 1** — Parameter `selectedExerciseKey` durchreichen
- [x] **Schritt 2** — `expandedExerciseKey`-State + onChange-Handler
- [x] **Schritt 3** — `ExerciseOverviewRow` mit `isExpanded` + `onToggleExpand`
- [x] **Schritt 4** — Chevron-Indikator in topLine
- [x] **Schritt 5** — `ExerciseOverviewExpandedDetail` implementieren
- [x] **Schritt 6** — Play-Icon für Auswahl als aktive Übung
- [x] **Schritt 7** — Edge-Cases + Feinschliff

## Manual Verification Checklist

- [ ] Xcode build (`Cmd+B`) nach **jedem** der 7 Schritte
- [ ] Simulator: Aktive Übung ist beim Öffnen der `ActiveWorkoutView` automatisch aufgeklappt
- [ ] Simulator: Accordion (alte Row schließt, neue öffnet) funktioniert weich
- [ ] Simulator: Play-Icon wechselt aktive Übung korrekt, ohne Row-Toggle auszulösen
- [ ] Simulator: Sortiermodus schließt offene Row und blockiert Tap-Expand
- [ ] Simulator: Superset-Verbindungslinien bleiben bei aufgeklappter Row korrekt
- [ ] `ExercisesOverviewCard.swift` < 600 Zeilen
- [ ] Keine Compile-Warnungen aus geänderten Dateien

---

## Fortschritt

**2026-04-19 — Schritt 7 abgeschlossen**

**Abgeschlossene Schritte:** 1–7 (alle)

**Code-Bug behoben in Schritt 7:**
Äußerer `onTapGesture` in `ExercisesOverviewCard` (Zeile 128–132) rief `onSelectExercise` auf und blockierte den `onToggleExpand`-Aufruf in `ExerciseOverviewRow.background`. In SwiftUI gewinnt die äußere Geste — der Toggle wurde nie ausgelöst. Der fehlerhafte Tap-Handler wurde entfernt. Das Play-Icon übernimmt weiterhin die Übungsauswahl via `onSelectAsActive`.

**Geänderte Dateien:**
- `/Users/bartosz/Developments/MotionCore/MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift` — 4 Zeilen entfernt (äußerer onTapGesture)

**Datei-Größe:** 564 Zeilen (unter 600-Warnschwelle)

**Keine print-Statements / TODOs / FIXMEs vorhanden**

**Ausstehend:** Xcode `Cmd+B` Build-Check durch den User, Simulator-Tests der Checkliste

## Open Questions

Keine offenen Produkt-/UX-/Datenfragen — Konzept und Instruction sind vollständig spezifiziert. Einzige bedingte Entscheidung: Falls Datei nach Schritt 7 >600 Zeilen liegt, Auslagerung von `ExerciseOverviewExpandedDetail` in eigene Datei besprechen.

---

## Referenzen

- **Concept:** `/Users/bartosz/Developments/MotionCore/Documentation/Concepts/MotionCore_ActiveWorkout_ExpandableExerciseRow_Concept.md`
- **Instruction:** `/Users/bartosz/Developments/MotionCore/Documentation/Instructions/MotionCore_ActiveWorkout_ExpandableExerciseRow_Instruction.md`
