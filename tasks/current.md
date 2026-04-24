# Phase 2 — Readiness

**Complexity:** Medium-Large
**Status:** In Arbeit — strikt phased, 8 Schritte mit STOPP-Gates
**Voraussetzung:** Phase 1 ✓ + Phase 1.5 ✓ (rpeRecorded, Modus-Gewicht, AutoProgression abgeschlossen)

## Summary

Phase 2 aktiviert den `readinessModifier` in `ProgressionCalcEngine` (bisher hardcoded 1.0). Dazu wird HealthKit um HRV, Schlaf, Ruhepuls und Aktivität erweitert, rollende Baselines (28 Tage, 42 Tage bei Kardio-Medikation) werden täglich auf Foreground-Wechsel aktualisiert, und pro Session wird ein `SessionReadiness`-Snapshot (Score 0–100 + Label) erzeugt. UI: kompakte Readiness-Card auf dem Workout-Start-Screen mit Detail-Sheet (Breakdown + optionale Energie/Stress-Abfrage) und eigener Kalibrierungs-Darstellung während der ersten ~14 Tage. Die Progression reagiert bei Modifier < 0.9 mit Entlastung (bereits vorhanden), Auto-Progression (Phase 1.5) wird bei reduzierter Readiness unterdrückt.

## Scope

Included:
- HealthKit-Service-Erweiterung (HRV SDNN, Schlaf, RestingHR, ActiveEnergy), on-demand Permission-Request
- `HealthBaselineUpdateService` mit daily-Trigger auf `scenePhase == .active`
- `ReadinessCalcEngine` + `ReadinessTypes` (pure Struct, gewichtetes z-Score-Modell)
- `SessionReadiness`-Snapshot bei Workout-Start (einmalig, nicht kontinuierlich)
- `ReadinessCard` + `ReadinessDetailView` + `ReadinessViewModel`
- Verdrahtung `readinessModifier` in `ProgressionCalcEngine`-Aufrufen in ActiveWorkoutView
- Auto-Progression (Phase 1.5) bei `readinessModifier < 1.0` unterdrücken
- Kalibrierungs-UI (Progress-Bars + Text)
- Debug-Helper hinter `#if DEBUG` für Baseline-Mock + Score-Override
- Medikamenten-Toggle (AppSettings, beeinflusst Fenster-Länge + Gewichtung)

Explicitly excluded:
- Supabase-Sync der neuen `SessionReadiness`/`HealthBaseline`-Tabellen (Folge-Phase)
- Kontinuierliche Readiness-Neuberechnung während laufender Session
- Rollback-Logik-Erweiterung um Readiness
- Phase 3

## UX Placement

- **Readiness-Card:** auf dem Workout-Start-Screen direkt unter dem Plan-Header, vor der Übungsliste
- **Entry Point:** Tap auf Card → `ReadinessDetailView` als Sheet (`.sheet(item:)`-Pattern gemäß Lessons)
- **Medikamenten-Toggle:** in Settings unter neuer Sektion „Gesundheit" (`takesCardioMedication: Bool` in AppSettings, Default `false`)
- **Kalibrierungs-Zustand:** gleicher Kartenplatz, andere Darstellung + gelbes Icon
- **Debug-Tools:** SettingsView unter `#if DEBUG` (Baseline mocken, Score überschreiben)

## Affected Files

### Schritt 2.1 — HealthKit-Service erweitern
- NEU oder ÄNDERN: `MotionCore/Services/HealthKit/HealthKitService.swift` — 4 neue API-Methoden (hrvSamples, sleepDuration, restingHRSamples, activeEnergy)
- NEU: `MotionCore/Services/HealthKit/HealthKitServiceError.swift` — enum `.notAuthorized`, `.noData`, `.queryFailed(Error)`
- PRÜFEN: `MotionCore/Info.plist` / Build Settings — `NSHealthShareUsageDescription` vorhanden?

### Schritt 2.2 — HealthBaseline-Update-Service
- NEU: `MotionCore/Services/HealthBaselineUpdateService.swift` — `@MainActor final class`, `updateIfNeeded()` + `forceUpdate()`
- ÄNDERN: `MotionCore/App/MotionCoreApp.swift` — `.onChange(of: scenePhase)` Hook

### Schritt 2.3 — ReadinessCalcEngine
- NEU: `MotionCore/Services/Calculation/ReadinessCalcEngine.swift` — pure Struct mit `Input`/`Output` + `calculate(input:)`
- NEU: `MotionCore/Services/Calculation/ReadinessTypes.swift` — `ReadinessLabel`, `ReadinessFactor`, Modifier-Mapping

### Schritt 2.4 — SessionReadiness-Speicherung
- NEU: `MotionCore/Services/SessionReadinessService.swift` — `captureReadiness(forSession:context:)` async
- ÄNDERN: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — in `setupSession()` neuer `Task { @MainActor in ... }` Branch

### Schritt 2.5 — Readiness-Karte (kompakt)
- NEU: `MotionCore/Views/Readiness/ReadinessCard.swift`
- NEU: `MotionCore/ViewModels/ReadinessViewModel.swift` — `@Observable`
- NEU: `MotionCore/Views/Readiness/ReadinessLabelStyle.swift` — Color/Icon-Resolver
- ÄNDERN: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — Card einbinden

### Schritt 2.6 — Readiness-Expanded-View + optionale Fragen
- NEU: `MotionCore/Views/Readiness/ReadinessDetailView.swift`
- NEU: `MotionCore/Views/Readiness/ReadinessFactorRow.swift`
- ÄNDERN: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `.sheet(item: $selectedReadiness)`

### Schritt 2.7 — Verdrahtung mit ProgressionCalcEngine
- ÄNDERN: `ActiveWorkoutSmartFillViewModel` (oder wo ProgressionCalcEngine-Input gebaut wird) — `readinessModifier: Double` dynamisch statt 1.0
- ÄNDERN: `MotionCore/Services/AutoProgressionApplier.swift` — Guard: bei `readinessModifier < 1.0` kein Auto-Progression
- NEU: `MotionCore/Views/Workouts/Active/Components/ReadinessReducedBadge.swift` — Badge im Set-Input wenn `reasoning == .readinessReduced`

### Schritt 2.8 — Kalibrierungs-Hinweis-UI-Feinschliff
- ÄNDERN: `MotionCore/Views/Readiness/ReadinessCard.swift` — Kalibrierungs-Variante
- ÄNDERN: `MotionCore/Views/Readiness/ReadinessDetailView.swift` — Progress-Bars
- NEU: `MotionCore/Views/Readiness/CalibrationProgressRow.swift`
- ÄNDERN: `AppSettings` + Settings-View — neuer Toggle `takesCardioMedication`
- `#if DEBUG` Helper: Baseline mocken + Score überschreiben

## Risks

- **ActiveWorkoutView ~2230 Zeilen:** neue Logik strikt in Services/ViewModels, View nur Card-Binding + ein neuer `@State currentReadinessModifier`
- **HealthKit-Permission on-demand:** Dialog darf nicht beim App-Start erscheinen, sondern erst beim ersten `updateIfNeeded()`-Aufruf mit fehlender Auth
- **Info.plist Usage-String:** via `INFOPLIST_KEY_*` Build Settings (Lesson), NICHT als eigene Info.plist-Datei
- **stdDev == 0 → NaN/Infinity:** Guard bei `stdDev < 0.01` → neutrale Metrik
- **Timezone / Tagesgrenzen:** `Calendar.isDateInToday()` statt Raw-Date-Differenz
- **`.sheet(item:)` Pflicht:** Detail-Sheet immer via `selectedReadiness: SessionReadiness?` (Lesson 2026-04-06)
- **Auto-Progression-Guard:** muss in `AutoProgressionApplier`, nicht in der View — sonst wirkungslos
- **CloudKit-Dedupe:** prüfen ob `HealthBaseline.id` + `SessionReadiness.id` bereits in `deduplicateAllSyncUUIDs()` stehen

## Implementation Steps

- [x] **Schritt 2.1** — HealthKit-Service: 4 neue Methoden + Error-Enum + Info.plist-Strings
- [x] **Schritt 2.2** — `HealthBaselineUpdateService` + App-Foreground-Hook
- [x] **Schritt 2.3** — `ReadinessCalcEngine` + `ReadinessTypes`
- [x] **Schritt 2.4** — `SessionReadinessService` + Einbindung in `setupSession()`
- [x] **Schritt 2.5** — `ReadinessCard` + `ReadinessViewModel` + Einbindung in Workout-Start-Scroll
- [x] **Schritt 2.6** — `ReadinessDetailView` + optionale Energie/Stress-Inputs + Neu-Berechnung
- [x] **Schritt 2.7** — `readinessModifier` durchreichen + Auto-Progression-Guard + `ReadinessReducedBadge`
- [x] **Schritt 2.8** — Kalibrierungs-UI-Feinschliff + Settings-Toggle + Debug-Helper

---

---

## Progress

**2026-04-24 15:30 — Schritt 2.6 abgeschlossen**

Completed steps: 2.6

Modified files:
- NEU: `MotionCore/Views/Readiness/ReadinessFactorRow.swift` — kompakte Zeile pro ReadinessFactor mit ProgressView-Balken und farbigem Tint
- NEU: `MotionCore/Views/Readiness/ReadinessDetailView.swift` — Detail-Sheet mit Score-Header, Faktoren-Liste, Energie/Stress-Segmented-Picker, Kalibrierungs-Platzhalter
- GEÄNDERT: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `showReadinessDetail: Bool` → `selectedReadinessForDetail: SessionReadiness?`, `.sheet(item: $selectedReadinessForDetail)` ergänzt

Known remaining: Schritt 2.7 (readinessModifier durchreichen + Auto-Progression-Guard + ReadinessReducedBadge), Schritt 2.8 (Kalibrierungs-UI-Feinschliff + Settings-Toggle + Debug-Helper)

---

**2026-04-24 15:30 — Schritt 2.7 abgeschlossen**

Completed steps: 2.7

Modified files:
- GEÄNDERT: `MotionCore/Views/Workouts/Active/ViewModel/ActiveWorkoutSmartFillViewModel.swift` — `prefillSuggestion` erhält neuen Parameter `readinessModifier: Double = 1.0`; wird an `ProgressionCalcEngine.Input` weitergegeben (bisher hardcoded `1.0`); neue Hilfsmethode `isReadinessReduced(for:)` für Badge-Abfrage
- GEÄNDERT: `MotionCore/Services/AutoProgressionApplier.swift` — `apply(...)` erhält neuen Parameter `readinessModifier: Double = 1.0`; Guard am Anfang: `guard readinessModifier >= 1.0 else { return [] }`
- GEÄNDERT: `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `prefillSmartSuggestionsIfNeeded()` übergibt `readinessModifier: currentReadinessModifier`; `AutoProgressionApplier.apply(...)` übergibt `readinessModifier: currentReadinessModifier`; `ActiveSetCard`-Aufruf übergibt `isReadinessReduced: smartFill?.isReadinessReduced(for: activeSet) ?? false`
- NEU: `MotionCore/Views/Workouts/Active/Components/ReadinessReducedBadge.swift` — gelbes Moon-Badge als Inline-Chip; in `ActiveSetCard` eingebunden via `isReadinessReduced: Bool = false` Parameter
- GEÄNDERT: `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift` — neuer Parameter `isReadinessReduced: Bool = false`; `ReadinessReducedBadge` im Header-HStack nach "Vorschlag"-Badge

Known remaining: —

---

**2026-04-24 15:35 — Schritt 2.8 abgeschlossen — Phase 2 vollständig**

Completed steps: 2.8

Modified files:
- NEU: `MotionCore/Views/Readiness/CalibrationProgressRow.swift` — Progress-Bar-Zeile pro Metrik (Name, X/14 Tage, gelber ProgressView, grün wenn bereit)
- GEÄNDERT: `MotionCore/Views/Readiness/ReadinessDetailView.swift` — `calibratingSection` zeigt jetzt 4 echte `CalibrationProgressRow`-Zeilen mit `sampleCount` aus `HealthBaseline`-Proxy; neue Hilfsmethode `baselineSampleCount(for:)`; beide `viewModel.load`-Aufrufe erhalten `debugScoreOverride`-Parameter
- GEÄNDERT: `MotionCore/Models/Core/AppSettings.swift` — `debugReadinessScoreOverride: Int` ergänzt (Default -1 = kein Override), mit UserDefaults-Persistenz
- NEU: `MotionCore/Views/Settings/View/DebugReadinessSection.swift` — `#if DEBUG`-Sektion mit Baseline-Reset-Button, Score-Override-Slider+Toggle, letztes-Update-Label
- GEÄNDERT: `MotionCore/Views/Settings/View/MainSettingsView.swift` — `@Query allBaselines` ergänzt; `#if DEBUG DebugReadinessSection(baselines: allBaselines)` vor App-Sektion eingebunden
- GEÄNDERT: `MotionCore/Services/ViewModels/ReadinessViewModel.swift` — `debugScoreOverride: Int = -1` Property + Parameter in `load()`; `score` gibt Override zurück wenn `>= 0` (nur in `#if DEBUG`)
- GEÄNDERT: `MotionCore/Views/Workouts/Active/Components/ReadinessCard.swift` — `@EnvironmentObject appSettings` ergänzt; `score` berücksichtigt `debugReadinessScoreOverride` unter `#if DEBUG`; Previews mit `.environmentObject(AppSettings.shared)`

Notes:
- `takesCardioMedication` war bereits in AppSettings + UserSettingsView vorhanden — keine Änderung nötig
- `CalibrationProgressRow` nutzt `HealthBaseline.sampleCount` als Proxy statt eigener SessionReadiness-Felder (TODO für Schritt 2.9 kommentiert)
- Phase 2 alle 8 Schritte abgeschlossen

---

## Open Questions

1. Readiness bei pausiertem Workout, das am Folgetag fortgesetzt wird → **Empfehlung: ursprünglicher Snapshot behalten** (ein Start = ein Snapshot)
2. Kalibrierungs-Granularität: binär (calibrating ja/nein bei ≥14 Samples) oder 3-stufig → **Empfehlung: binär**
3. Card-Anzeige bei Superset-Plänen → **Empfehlung: immer zeigen**
