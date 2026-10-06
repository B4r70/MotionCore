# Superset-Auswahlleiste verdeckt letzte Übung

**Complexity:** Medium

## Summary

Im Superset-Auswahlmodus legt sich die Leiste über den Inhalt, ohne dass unten Platz reserviert wird → die letzte Übung ist nicht antippbar. Fix: Leiste per `.safeAreaInset(edge: .bottom)` am Bildschirmrand verankern, damit der Scroll-Inhalt automatisch um ihre Höhe nach oben rückt. Kein Workaround (keine Magic-Number-Paddings).

## Root Cause

- **A: Plan-Editor** — `PlanExercisesSection.swift:66–84`: Leiste liegt in `ZStack(alignment: .bottom)` *innerhalb* der ScrollView von `TrainingFormView.swift:48–67` → scrollt mit der letzten Karte mit; `.padding(.bottom, 80)` (`TrainingFormView:66`) liegt außerhalb des ZStack und hilft nicht.
- **B: Aktives Workout** — `ActiveWorkoutView.swift:154–164`: Superset-Leiste (~74pt) steht zusätzlich über `bottomActionBar` (~88pt), Inhalt hat aber pauschal nur 100pt Abstand (`:940`) → ~60pt der letzten Zeile verdeckt.

## Scope

- Drin: Leiste in A und B festpinnen; in A Auswahl-State eine Ebene höher (`TrainingFormView`).
- Nicht drin: Leisten-Redesign, gemeinsame Komponente, Aufteilen von `PlanExercisesSection`, `.padding(.bottom, 80)` ändern.

## Dateien

- `MotionCore/Views/Training/Plans/Components/PlanExercisesSection.swift` (`:47–49`, `:66–84`, `:479–535`, Previews `:737`, `:754`)
- `MotionCore/Views/Training/Plans/View/TrainingFormView.swift` (State + `.safeAreaInset` nach `:68`)
- `MotionCore/Views/Training/Plans/Detail/TrainingDetailView.swift` (Aufruf `:76`)
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` (`:148–164`, `:940`) — Teil B

## Schritte

**A: Plan-Editor — NICHT in Scope (User-Entscheidung)**
- [ ] `TrainingFormView`: `@State isSupersetSelectionMode`, `@State selectedGroupIndicesForSuperset: Set<Int>`
- [ ] `PlanExercisesSection:48–49`: `@State` → `@Binding` (Muster wie `ExercisesOverviewCard.swift:29–31`); `onChange`-Logik (`:86–96`) unverändert
- [ ] `TrainingFormView:54–64`: Bindings übergeben
- [ ] `supersetActionBar` (`:479–535`) unverändert nach `TrainingFormView` verschieben (`modelContext` → `context`)
- [ ] `PlanExercisesSection.body`: `ZStack` samt Leisten-Zweig entfernen, innere `VStack` bleibt Wurzel
- [ ] `TrainingFormView`: `.safeAreaInset(edge: .bottom)` mit Leiste (`.transition(.move(edge: .bottom).combined(with: .opacity))`) + `.animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSupersetSelectionMode)`
- [ ] `TrainingDetailView:76` + 2 Previews: `.constant(false)` / `.constant([])`
- [ ] Vor Build: Grep nach `PlanExercisesSection(` auf weitere Aufrufer

**B: Aktives Workout (separat streichbar)**
- [x] Overlay-`VStack` (`:154–164`) entfernen; Superset-Leiste + `bottomActionBar` als `.safeAreaInset(edge: .bottom, spacing: 0)` an die ScrollView (`:148–151`) hängen, `.animation` mitnehmen
- [x] `.padding(.bottom, 100)` (`:940`) → `Space.s4`

## Risiken

- Animation beim Ein-/Ausblenden (Sortiermodus beendet Auswahl ohne `withAnimation`) → `.animation` an Inset-Inhalt
- Tastatur-Verhalten in B (Satz-Eingabe) prüfen
- `.ultraThinMaterial`-Leiste in B: Inhalt muss dahinter durchscrollen
- Weitere Aufrufer nur per Datei-Inspektion gefunden (Compiler fängt den Rest)
- Keine Daten-/CloudKit-Berührung

## Manuelle Tests

- [ ] Build (`Cmd+B`) + Previews (Plan Exercises Section Form/Detail, Training Form Edit, Training Detail)
- [ ] Plan-Editor, 8+ Übungen: Superset aus den **letzten beiden** ohne Umsortieren anlegen
- [ ] Leiste bleibt beim Scrollen sichtbar, letzte Karte vollständig über die Leiste scrollbar; Abbrechen/Superset/Sortiermodus blenden animiert aus
- [ ] Detailansicht des Plans unverändert
- [ ] Aktives Workout: letzte Zeile in `ExercisesOverviewCard` im Auswahlmodus antippbar, ohne Auswahlmodus keine Extra-Lücke; Tastatur wie vorher
- [ ] Light + Dark Mode

## Entscheidung (User, 2026-10-01)

Fehler trat im aktiven Workout auf (Liste in `ActiveWorkoutView`) → **nur Teil B umsetzen**. Teil A (Plan-Editor) bleibt unangetastet (gleicher Bug im Code, nicht beauftragt).
