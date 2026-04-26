# Live HealthKit Readiness in BodyView

**Komplexität:** Medium  
**Status:** Awaiting approval

## Problem
`BodyView` liest nur persistierte `SessionReadiness`-Records (nur bei Workout-Start geschrieben).
Schlaf-Faktor zeigt "sehr wenig" weil:
1. Kein Live-HealthKit-Query beim Tab-Öffnen
2. Baseline (`rollingMean`) aus Monaten falscher Queries systematisch zu niedrig

`HealthKitManager.sleepDuration(forNightEnding:)` wurde bereits gefixt — aber der Fix greift nicht,
weil die Funktion nie beim Öffnen des Body-Tabs aufgerufen wird.

## Scope — NICHT ändern
- `SessionReadiness` SwiftData-Schema — kein Migration-Risiko
- `SessionReadinessService.captureReadiness(...)` — bleibt einziger Persist-Pfad
- `ReadinessCalcEngine` — Mathe, Weights, Thresholds unverändert
- `ReadinessDetailView` — liest weiterhin persisted Snapshot (Workout-Kontext)
- `HealthKitManager.sleepDuration(forNightEnding:)` — bereits gefixt, nicht anfassen

## Affected Files
- `MotionCore/Services/SessionReadinessService.swift`
- `MotionCore/Views/Body/BodyViewModel.swift`
- `MotionCore/Views/Body/BodyView.swift`

## Steps

### Step 1 — `SessionReadinessService`: `computeLive` hinzufügen [x]
**File:** `MotionCore/Services/SessionReadinessService.swift`

Neue static Methode:
```swift
static func computeLive(context: ModelContext, takesCardioMedication: Bool) async -> ReadinessCalcEngine.Output
```
- Logik von `captureReadiness` (Baseline-Fetch + HK-Queries + Engine) übernehmen
- **Kein** `context.insert`, **kein** `context.save()`, **kein** `session.sessionReadinessID`
- Gibt raw `Output` zurück
- `captureReadiness` bleibt komplett unverändert

### Step 2 — `BodyViewModel`: `loadLiveReadiness` + Race-Guard [x]
**File:** `MotionCore/Views/Body/BodyViewModel.swift`

```swift
private var refreshTask: Task<Void, Never>?

@MainActor
func loadLiveReadiness(context: ModelContext, takesCardioMedication: Bool) async {
    refreshTask?.cancel()
    refreshTask = Task {
        let output = await SessionReadinessService.computeLive(
            context: context, takesCardioMedication: takesCardioMedication
        )
        guard !Task.isCancelled else { return }
        readinessFactors = output.breakdown
        readinessScore = output.isCalibrating ? nil : output.score
    }
    await refreshTask?.value
}
```
- `loadReadinessFactors(latestReadiness:...)` noch nicht löschen (erst nach Step 4 verifiziert)

### Step 3 — `BodyView`: Baseline-Force-Refresh (max 1× pro Tag) [x]
**File:** `MotionCore/Views/Body/BodyView.swift`

```swift
@AppStorage("lastBaselineForceRefreshDay") private var lastBaselineForceRefreshDay: String = ""
```

Helper `refreshBaselineIfNeeded() async`:
- Vergleicht heutiges `yyyy-MM-dd` mit gespeichertem Wert
- Bei Abweichung: `HealthBaselineUpdateService(healthKit: .shared, context: modelContext).forceUpdate(takesCardioMedication:)` aufrufen
- Key danach auf heute setzen

### Step 4 — `BodyView`: `refresh()` neu verdrahten [x]
**File:** `MotionCore/Views/Body/BodyView.swift`

- `recalculate(sessions:)` bleibt (Recovery-Analyse unverändert)
- Neuer `Task {}` in `refresh()`:
  1. `await refreshBaselineIfNeeded()`
  2. `await viewModel.loadLiveReadiness(context: modelContext, takesCardioMedication: appSettings.takesCardioMedication)`
- `loadReadinessFactors(latestReadiness: allReadiness.first, ...)` Aufruf entfernen
- `@Query allReadiness` + `@Query baselines` entfernen wenn keine weiteren Aufrufer

## Risks
- HealthKit Auth beim ersten BodyView-Öffnen vor Workout-Start → `HealthBaselineUpdateService.forceUpdate` ruft `requestAuthorization()` bereits auf → abgedeckt
- Race auf `scenePhase`/`@Query`-Churn → durch `refreshTask?.cancel()` in Step 2 abgesichert
- Baseline-Force-Refresh: 28-Tage-Batch → max 1× pro Tag-Guard in Step 3 verhindert Kosten
- Live ohne Watch-Daten → `output.breakdown = []` → bestehender `EmptyState`-Branch greift unverändert

## Manual Verification
- [ ] Build grün (`Cmd+B`)
- [ ] BodyView ohne Workout öffnen: "Schlaf" zeigt plausiblen Wert (kein "sehr wenig")
- [ ] BodyView 2× gleicher Tag öffnen: Baseline-Refresh nur 1× (kein zweiter `forceUpdate`)
- [ ] Workout starten: `ReadinessDetailView`-Sheet zeigt weiterhin persisted Snapshot
- [ ] Kein neuer `SessionReadiness`-Row nach mehrfachem BodyView-Öffnen
- [ ] Leerer State bei fehlendem Watch-Daten (kein Crash)
- [ ] Preview kompiliert ohne Crash

---

## Fortschritt

**2026-04-26 14:16 Uhr**

Alle 4 Steps implementiert.

Abgeschlossene Steps: 1, 2, 3, 4

Geänderte Dateien:
- `MotionCore/Services/SessionReadinessService.swift` — `computeLive` als neue static Methode hinzugefügt; `captureReadiness` unverändert
- `MotionCore/Views/Body/BodyViewModel.swift` — `import SwiftData`, `refreshTask: Task<Void, Never>?`, `loadLiveReadiness(context:takesCardioMedication:)` hinzugefügt; `loadReadinessFactors` bleibt vorerst erhalten
- `MotionCore/Views/Body/BodyView.swift` — `@Query allReadiness` + `@Query baselines` entfernt; `@Environment(\.modelContext)` + `@AppStorage("lastBaselineForceRefreshDay")` hinzugefügt; `refresh()` ruft jetzt `Task { await refreshBaselineIfNeeded(); await viewModel.loadLiveReadiness(...) }` auf; `refreshBaselineIfNeeded()` als privater async Helper implementiert

Offen: Manuelle Verifikation (Cmd+B, Laufzeitprüfung)
