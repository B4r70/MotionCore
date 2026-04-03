# Quality Gate — watchOS HR/Kalorien-Fix

**Datum:** 2026-04-03  
**Status:** Korrekturen erforderlich

---

## Findings

### 1. [KRITISCH] — `resumed`-Flag nicht thread-sicher (Data Race)
- **Datei:** `PhoneSessionManager.swift` — `requestFinalSnapshot()`
- `var resumed = false` wird von zwei konkurrierenden Kontexten geschrieben: WCSession-Queue (replyHandler/errorHandler) und Swift-Task-Thread (timeoutTask). Ohne Synchronisation ist das ein Data Race.
- **Fix:** Beide Handler via `DispatchQueue.main.async` serialisieren, bevor `resumed` geprüft/gesetzt wird.

### 2. [HOCH] — Kein explizites Heartbeat-Stop vom iPhone bei Workout-Ende
- **Datei:** `ActiveWorkoutView.swift` — `finishWorkout()` / `cancelWorkout()`
- `sendHeartbeatEnabled(false)` wird nie vom iPhone aufgerufen. Wenn die Watch `sendStopHealthTracking()` nicht empfängt (z.B. Watch außer Reichweite), läuft der 5s-Timer weiter und überschreibt nach `resetHealthData()` erneut die Properties.
- **Fix:** `sendHeartbeatEnabled(false)` vor `sendStopHealthTracking()` aufrufen.

### 3. [MITTEL] — Veraltete Kommentare in beiden `WatchHealthDataTypes.swift`
- **Datei:** `MotionCore/.../WatchHealthDataTypes.swift` + `MotionCoreWatch Watch App/.../WatchHealthDataTypes.swift`
- Kommentare nennen noch "60-Sekunden-Heartbeat-Timer" — beide Targets müssen synchron aktualisiert werden.

### 4. [NIEDRIG] — Toggle `enableLiveHeartbeatTimer` ist wirkungslos (toter UI-State)
- **Datei:** `ActiveWorkoutView.swift` `onAppear` (Bedingung entfernt)
- Der Toggle in WorkoutSettings kann deaktiviert werden, hat aber keinen Effekt mehr.
- **Produkt-Entscheidung:** Toggle entfernen oder Logik wiederherstellen (replyHandler-Snapshot ist davon unabhängig).

---

## Positives

- WCSession-Delegate-Koexistenz (`didReceiveMessage` vs. `didReceiveMessage:replyHandler:`) korrekt — WCSession routiert eindeutig.
- `finishWorkout()` liest Health-Daten nachweislich NACH `await requestFinalSnapshot()` — Reihenfolge korrekt.
- `sendStopHealthTracking()` korrekt NACH dem Snapshot-Read aufgerufen.
- Initialer 2s-Snapshot nach Workout-Start pragmatisch und korrekt.
- `AppSettings`-Default-Änderung korrekt (`as? Bool ?? true`).
- Chirurgische Änderungen — ActiveWorkoutView.swift minimal modifiziert.

---

## Ergebnis

Zwei Fixes erforderlich (1 + 2 + 3), dann freigabefähig.
