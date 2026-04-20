# iOS Home Screen Widgets (System + Lock Screen)

**Complexity:** Large

## Summary

Die bestehende Emoji-Template-Datei `MotionCoreWidgets.swift` wird durch produktive MotionCore-Widgets ersetzt. Ziel ist ein Satz nützlicher Widgets für Home Screen (Small/Medium/Large) und Lock Screen (accessoryCircular/Rectangular/Inline), die Kern-Daten aus MotionCore anzeigen: Wochen-Fortschritt, Streak, nächstes Training, letzter Workout, Top-PRs und 4-Wochen-Volumen-Trend. Die bereits funktionierende Live Activity (`MotionCoreWidgetsLiveActivity.swift`) bleibt unverändert.

## Scope

Included:
- Widget-Bundle um Home-Screen- und Lock-Screen-Widgets erweitern
- AppGroup-basierte Datenbrücke (UserDefaults + JSON-Snapshot-File) nach bestehendem `WatchComplicationService`-Pattern
- Snapshot-Publisher-Service in der Main-App, der nach relevanten Events schreibt
- deep link per `widgetURL` in App-Views

Explicitly excluded:
- Direkter SwiftData/CloudKit-Zugriff aus der Widget-Extension (zu fragil, keine garantierte Store-Migration im Extension-Prozess)
- Supabase-Calls aus Widget (Network in Timeline-Provider verboten/begrenzt)
- Interaktive Widgets mit `AppIntent` (Phase 2)
- Neue Live Activities
- Konfigurierbare Widgets (`AppIntentConfiguration`) — Phase 2 falls gewünscht

## UX Placement

- **Small (Home)**: "Streak" (Flammen-Icon + Tage + Best-Streak-Subtitle)
- **Small (Home)**: "Wochenziel" (Ring-Progress Workouts/Woche, fix 5/Woche)
- **Medium (Home)**: "Letztes Workout" (Datum, Volumen, Dauer, Top-Übung, Satz-Count)
- **Large (Home)**: "Trainings-Überblick" (Wochenziel-Ring + Streak + 4-Wochen-Volumen-Bar-Chart via Swift Charts + Big-3-PRs)
- **Lock Screen accessoryCircular**: Streak-Ring (Fortschritt ggü. Wochenziel)
- **Lock Screen accessoryInline**: "MotionCore · 3/5 diese Woche · 🔥12"

Rationale: Widgets dienen Motivation (Streak, Wochenziel) und Kontext (letzte Session), nicht interaktiver Steuerung. Keine Duplikate von Apple-Health-Widgets.

## Affected Files

### Neue Dateien (Widget-Extension Target)

- `MotionCoreWidgets/Shared/WidgetSnapshot.swift` — Codable Snapshot-Struct mit Sub-Structs
- `MotionCoreWidgets/Shared/WidgetDataStore.swift` — AppGroup Reader/Writer
- `MotionCoreWidgets/Providers/MotionCoreEntry.swift` — TimelineEntry
- `MotionCoreWidgets/Providers/MotionCoreTimelineProvider.swift` — gemeinsamer Provider
- `MotionCoreWidgets/Widgets/StreakWidget.swift`
- `MotionCoreWidgets/Widgets/WeeklyGoalWidget.swift`
- `MotionCoreWidgets/Widgets/LastWorkoutWidget.swift`
- `MotionCoreWidgets/Widgets/TrainingOverviewWidget.swift`
- `MotionCoreWidgets/Widgets/InlineStatusWidget.swift`
- `MotionCoreWidgets/Views/` — SwiftUI-Komponenten (StreakRing, WeeklyGoalRing, VolumeMiniChart)

### Geänderte Dateien

- `MotionCoreWidgets/MotionCoreWidgets.swift` — Emoji-Template ersetzen
- `MotionCoreWidgets/MotionCoreWidgetsBundle.swift` — Neue Widgets registrieren
- `MotionCore/Services/Widget/WidgetSnapshotPublisher.swift` (neu) — Daten-Publisher
- `MotionCore/App/MotionCoreApp.swift` — Publisher triggern bei App-Start + Foreground

## Implementation Steps

- [x] Schritt 1: `Shared/WidgetSnapshot.swift` definieren
- [x] Schritt 2: `Shared/WidgetDataStore.swift` implementieren
- [x] Schritt 3: `Services/Widget/WidgetSnapshotPublisher.swift` implementieren (Big-3-PRs statt alle)
- [x] Schritt 4: Publisher in `BaseView` (onAppear + scenePhase.active) und `ActiveWorkoutView` triggern
- [x] Schritt 5: Template `MotionCoreWidgets.swift` ersetzen
- [x] Schritt 6: `MotionCoreTimelineProvider` + `MotionCoreEntry` anlegen
- [x] Schritt 7: `StreakWidget` implementieren
- [x] Schritt 8: `WeeklyGoalWidget` implementieren (fix 5)
- [x] Schritt 9: `LastWorkoutWidget` implementieren
- [x] Schritt 10: `TrainingOverviewWidget` implementieren (Big-3-PRs)
- [x] Schritt 11: `InlineStatusWidget` implementieren (accessoryCircular + accessoryInline)
- [x] Schritt 12: `MotionCoreWidgetsBundle` erweitern
- [x] Schritt 13: Entitlements geprüft — beide Targets haben `group.com.barto.motioncore`
- [ ] Schritt 14: Manuelles Verify + Lessons.md

## Produktentscheidungen (Geklärt)

1. ✅ **Wochenziel**: Fix 5/Woche
2. ✅ **"Nächstes Training" Widget**: Entfällt (nicht nötig)
3. ✅ **Top-PRs**: Big-3 (Bench/Squat/Deadlift)

## Status

- [x] Produktfragen geklärt
- [x] Implementation freigegeben
- [ ] Quality gate bestanden

---

## Fortschritt

**Datum:** 2026-04-20

**Abgeschlossene Schritte:** 1–13

**Geänderte / neue Dateien:**
- `MotionCoreWidgets/Shared/WidgetSnapshot.swift` (neu, Widget-Extension-Target)
- `MotionCoreWidgets/Shared/WidgetDataStore.swift` (neu, Widget-Extension-Target — Lesen + Placeholder)
- `MotionCoreWidgets/Providers/MotionCoreEntry.swift` (neu)
- `MotionCoreWidgets/Providers/MotionCoreTimelineProvider.swift` (neu)
- `MotionCoreWidgets/Widgets/StreakWidget.swift` (neu)
- `MotionCoreWidgets/Widgets/WeeklyGoalWidget.swift` (neu)
- `MotionCoreWidgets/Widgets/LastWorkoutWidget.swift` (neu)
- `MotionCoreWidgets/Widgets/TrainingOverviewWidget.swift` (neu)
- `MotionCoreWidgets/Widgets/InlineStatusWidget.swift` (neu — accessoryCircular + accessoryInline)
- `MotionCoreWidgets/MotionCoreWidgets.swift` (ersetzt — war Emoji-Template)
- `MotionCoreWidgets/MotionCoreWidgetsBundle.swift` (geändert — alle 6 Widgets + LiveActivity registriert)
- `MotionCore/Services/Widget/WidgetSnapshot.swift` (neu, App-Target — identische Structs)
- `MotionCore/Services/Widget/WidgetDataStore.swift` (neu, App-Target — nur Write)
- `MotionCore/Services/Widget/WidgetSnapshotPublisher.swift` (neu, App-Target)
- `MotionCore/Views/Root/View/BaseView.swift` (geändert — @Query + Publisher-Trigger)
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` (geändert — Publisher nach Session-Abschluss)

**Offene Punkte:**
- Schritt 14: Manuelles Verify via Xcode Cmd+B durch User erforderlich
