# watchOS: Self-Healing Start + Live-Timer + Info-Display

**Complexity:** Medium

## Root Cause Summary

1. **WCSession-Startrace**: `sendStartHealthTracking()` in `onAppear` wird verworfen wenn `isReachable == false`. Kein Retry → Watch startet nie HKWorkoutSession → HR/Kalorien immer "–".
2. **Kein Live-Timer auf Watch**: `sendWatchState()` nur event-driven (Set-Abschluss, Übungswechsel) → Watch-Timer eingefroren.
3. **Fehlende Kalorien-Anzeige**: WatchActiveWorkoutView zeigt keine Kalorien.

## Scope

### Fix 1: Self-Healing in WatchSessionManager
Wenn die Watch ein aktives Workout-State (`!= .idle`) empfängt aber `workoutManager == nil` ist, startet sie die HKWorkoutSession und den Heartbeat-Timer automatisch — unabhängig davon ob `startHealthTracking` ankam.

### Fix 2: Lokaler Live-Timer in WatchSessionManager
- Neues `@Published var liveElapsedSeconds: TimeInterval = 0`
- Lokaler `Timer.scheduledTimer` (1s) läuft wenn `workoutState == .active`
- Wenn iPhone `elapsedTime` sendet: `liveElapsedSeconds` als Basis setzen, dann weiter zählen
- Bei Pause: Timer stoppen. Bei Fortsetzen: Timer neu starten.

### Fix 3: WatchActiveWorkoutView Redesign
Ziel: Trainings-Info im Vordergrund.

Layout (von oben):
1. **Timer** (groß, live-zählend) + Pause-Button
2. **Übungsname** + Set X/Y
3. **HR** (immer sichtbar, auch "–") + **Kalorien** (neu)
4. Satz-abschließen-Button (kompakter, bleibt erhalten)

## Affected Files

| Datei | Änderung |
|---|---|
| `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` | Self-healing (Fix 1) + `liveElapsedSeconds` Property + lokaler Timer (Fix 2) |
| `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift` | Neues Layout mit Kalorien + `liveElapsedSeconds` (Fix 3) |

## Implementation Steps

- [x] **1. WatchSessionManager: `liveElapsedSeconds` + lokaler Timer**
  - `@Published var liveElapsedSeconds: TimeInterval = 0` hinzufügen
  - `private var localTimer: Timer?` hinzufügen
  - Methode `startLocalTimer()`: `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)` → `liveElapsedSeconds += 1`
  - Methode `stopLocalTimer()`: `localTimer?.invalidate(); localTimer = nil`
  - Wenn `workoutState` auf `.active` → `startLocalTimer()`; auf `.paused`/`.idle` → `stopLocalTimer()`

- [x] **2. WatchSessionManager: `elapsedTime` aus iPhone-Nachricht als Basis setzen**
  - In `session(_:didReceiveMessage:)`: wenn `WatchStateKey.elapsedTime` im Message → `liveElapsedSeconds = receivedTime`

- [x] **3. WatchSessionManager: Self-Healing beim State-Empfang**
  - In `session(_:didReceiveMessage:)`: nach Verarbeitung des State-Updates
  - Wenn `workoutState != .idle && workoutManager == nil`: auto-start (gleicher Code wie `startHealthTracking`-Handler)
  - Guard: nicht doppelt starten wenn `workoutManager != nil`

- [x] **4. WatchActiveWorkoutView: Neues Layout**
  - Timer-Zeile: `liveElapsedSeconds` statt `elapsedTime`, Pause-Button bleibt
  - Set-Info: Übungsname (headline) + "Satz X/Y | Übung X/Y" (caption)
  - Metric-Zeile: HR links (❤️ currentHR oder "–") + Kalorien rechts (🔥 activeCalories oder "–")
  - Satz-abschließen-Button: kompakter (`.bordered` statt `.borderedProminent`, kleinere Schrift)

## Manual Verification

- [ ] Build (`Cmd+B`) — beide Targets fehlerfrei
- [ ] Watch-App starten, dann iPhone-Training starten → Watch zeigt Workout-View mit live zählendem Timer
- [ ] Nach ~5 Sekunden: HR und Kalorien erscheinen (Watch hat self-healing HKWorkoutSession gestartet)
- [ ] Pause auf iPhone → Watch zeigt Pause-Zustand (orange, Timer pausiert)
- [ ] Resume → Timer zählt weiter
- [ ] Training beenden → HR/Kalorien in gespeicherter Session > 0

---

## Implementierungsfortschritt

**Datum:** 2026-04-03

**Abgeschlossene Schritte:** 1, 2, 3, 4

**Geänderte Dateien:**
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — `liveElapsedSeconds` + `localTimer` Properties, `startLocalTimer()` + `stopLocalTimer()` Methoden, elapsedTime-Basis-Synchronisation, Timer-Start/-Stop je nach workoutState, Self-Healing-Block nach `handleHealthLifecycle`
- `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift` — Neues Layout (Timer + Pause-Button, Übungsname + Satz-Info, HR + Kalorien immer sichtbar, kompakter Satz-Button), `formattedTime` auf `liveElapsedSeconds` umgestellt

**Verbleibend:** Manuelle Verifikation via `Cmd+B` + Simulator
