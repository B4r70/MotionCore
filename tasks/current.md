# Watch-Integration: Sofortiger State-Push + Pause-Anzeige

**Complexity:** Medium

## Summary

Zwei Erweiterungen der Watch-Kommunikation:
1. Wenn die Watch-App während eines laufenden Workouts geöffnet wird, soll das iPhone sofort den aktuellen State pushen (statt auf das nächste onChange-Event zu warten).
2. Wenn auf dem iPhone ein Rest-Timer läuft, soll die Watch "Pause" mit Countdown anzeigen statt den nächsten Satz.

## Scope

- **Enthalten:** `sessionReachabilityDidChange`-Delegate, Callback-Pattern für State-Push, Rest-Timer-Keys in Messages, Watch-UI für Countdown, "Pause überspringen"-Action
- **Ausgeschlossen:** Neue `WatchWorkoutState`-Cases (Rest wird über separate Keys transportiert)

## Affected Files

- `MotionCore/Services/Watch/PhoneSessionManager.swift`
- `MotionCore/Services/Watch/WatchMessageKeys.swift` (oder wo WatchStateKey definiert ist) — BEIDE Targets
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift`
- `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift`

## Implementation Steps

### Feature 1: Sofortiger State-Push bei Watch-Aktivierung

- [x] **Schritt 1: `PhoneSessionManager` — `onWatchBecameReachable`-Callback + `sessionReachabilityDidChange`**
- [x] **Schritt 2: `ActiveWorkoutView` — Callback in `onAppear` setzen, in `onDisappear` aufräumen**

### Feature 2: Pause-Anzeige auf der Watch

- [x] **Schritt 3: `WatchStateKey` — `isResting` + `restEndDate` Keys (BEIDE Targets synchron)**
- [x] **Schritt 4: `PhoneSessionManager.sendWorkoutState()` — Rest-Parameter hinzufügen**
- [x] **Schritt 5: `ActiveWorkoutView.sendWatchState()` — Rest-Daten mitsenden**
- [x] **Schritt 6: `ActiveWorkoutView` — `onChange(of: restTimerManager.isResting)` → `sendWatchState()` ergänzen**
- [x] **Schritt 7: `WatchSessionManager` — `isResting` + `restEndDate` Properties + Parsing**
- [x] **Schritt 8: `WatchActiveWorkoutView` — Pause-Countdown-UI**
- [x] **Schritt 9: `WatchAction.skipRest` — "Pause überspringen"-Action (BEIDE Targets + Handler)**

## Manual Verification

- [ ] Xcode Build (`Cmd+B`) — beide Targets
- [ ] Watch öffnen während Workout läuft → State sofort angezeigt (Feature 1)
- [ ] Satz abschließen → Rest-Timer startet → Watch zeigt Countdown (Feature 2)
- [ ] Rest-Timer läuft ab → Watch zeigt wieder Satz-Ansicht
- [ ] "Pause überspringen" auf Watch → Rest-Timer endet auf iPhone
- [ ] Keine Regression bei `WatchWorkoutState.paused`

---

## Fortschritt

**Datum:** 2026-04-05
**Abgeschlossene Schritte:** 1–9 (alle)

**Geänderte Dateien:**
- `MotionCore/Services/Watch/PhoneSessionManager.swift` — `onWatchBecameReachable`-Callback, `sessionReachabilityDidChange`-Delegate, `sendWorkoutState()` um `isResting`/`restEndDate` erweitert
- `MotionCore/Services/Watch/WatchMessageKeys.swift` — `WatchStateKey.isResting`, `WatchStateKey.restEndDate`, `WatchAction.skipRest` hinzugefügt
- `MotionCoreWatch Watch App/Services/WatchMessageKeys.swift` — identisch synchronisiert
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `onWatchBecameReachable`-Callback in `onAppear`/`onDisappear`, `sendWatchState()` mit Rest-Daten, `onChange(of: restTimerManager.isResting)` + `sendWatchState()`, `handleWatchAction` um `.skipRest` erweitert
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — `isResting`/`restEndDate` Published Properties + Parsing in `didReceiveMessage`
- `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift` — Pause-Countdown-UI (`restView`), normale Workout-UI in `workoutView` extrahiert

**Offene Punkte:** Keine — Manuelle Verifikation via Xcode `Cmd+B` ausstehend
