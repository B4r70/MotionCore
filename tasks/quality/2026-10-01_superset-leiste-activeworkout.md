# Quality Gate — Superset-Leiste im aktiven Workout (Teil B)

**Datum:** 2026-10-01 · **Datei:** `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` · **Plan:** `tasks/current.md`

## Status
- Review: ✅ Approved (kein Blocker)
- Verification: Build grün (Developer-Lauf); UI-Verhalten nicht im Simulator geprüft
- Einschränkung des Reviewers: `git diff`/Grep nicht verfügbar; `ActiveWorkoutSupersetActionBar`, `ExercisesOverviewCard`, `DESIGN.md` nicht gelesen

## Findings
1. [Info] Root Cause korrekt: Overlay-VStack → `.safeAreaInset(edge: .bottom, spacing: 0)`, Magic Number `100` → `Space.s4`.
2. [Low] Animation/Scroll-Sprung: Inset-Höhe ändert sich beim Auswahlmodus (~74pt) → Inhalt reflowt; ggf. `withAnimation` am Aufrufer. Im Simulator prüfen.
3. [Low] Tastatur: ScrollView schrumpft jetzt um Leistenhöhe + Tastatur; auf kleinem Gerät prüfen, falls im Flow ein `TextField` liegt.
4. [Low] Superset-Leiste ohne eigenen Hintergrund (Material nur an `bottomActionBar`); Inhalt scheint in der 8pt-Lücke/neben der Leiste durch. Optik prüfen.
5. [Info] `.ultraThinMaterial` vs. „kein Glas" (DESIGN.md) — Altbestand, nicht Teil dieses Fixes.
6. [Info] Keine toten Reste durch die Änderung; `ZStack` bleibt wegen `AnimatedBackground`.
7. [Info] Teil A (Plan-Editor: `PlanExercisesSection`/`TrainingFormView`) hat denselben Bug, bewusst nicht in Scope.

## Manuelle Tests
- [ ] 8+ Übungen, Auswahlmodus an, ganz nach unten: letzte Zeile voll sichtbar + antippbar
- [ ] Ohne Auswahlmodus: keine unerwartete Lücke, letzte Zeile erreichbar
- [ ] Ein/Aus des Auswahlmodus (auch ganz unten gescrollt): keine Sprünge; Abbrechen, Superset anlegen, Sortiermodus-Ende
- [ ] Inhalt scrollt hinter der Material-Leiste durch; Light + Dark; Home Indicator
- [ ] Tastatur (kleines Gerät), falls TextField im Flow
- [ ] Regression: RestTimer-Karte, PR-Banner, Alerts, Sheets (Set-Edit, RIR, Pace), Pause/Beenden
