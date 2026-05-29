# Code Review — Layer L1: Watch-Target & iPhone-Bridge

**Datum:** 2026-05-15
**Reviewer:** motioncore-reviewer (Opus)
**Scope:** Komplettes Watch-Target (`MotionCoreWatch Watch App/`) inklusive Complications, plus die iPhone-seitige Kommunikations-Brücke (`PhoneSessionManager`, `WatchComplicationService`, Watch-Integration in `ActiveWorkoutView`). Shared-Files (`WatchHealthDataTypes`, `WatchMessageKeys`) als konsolidierte Multi-Target-Datei akzeptiert.
**Codebase-Stand:** branch `main` @ c641daf (Watch/Widget-Klone konsolidiert)
**Gelesene Dateien:** 11
**Gefundene Issues:** 11

---

## Executive Summary

### Severity-Verteilung
- 🔴 Critical: 0
- 🟠 High: 2
- 🟡 Medium: 5
- 🔵 Low: 3
- ⚪ Info: 1

### Top-3-Themen (was zieht sich durch?)
1. **Nested-ObservableObject-Falle** — die Watch-UI liest Live-Werte aus einem in `WatchSessionManager` verschachtelten `WatchWorkoutManager`. SwiftUI propagiert die inneren `@Published`-Events nicht; die UI rendert nur dank des sekündlichen Live-Timers zufällig neu. Betrifft 1 Finding, hat aber UI-weite Wirkung.
2. **State-Pollution via Lifecycle-Messages** — `didReceiveMessage` auf der Watch wertet `WatchStateKey`-Felder auch in reinen Lifecycle-Nachrichten aus. Das setzt `restEndDate` ungewollt auf nil bei jedem Start/Stop/Pause/Heartbeat-Toggle. Betrifft 2 Findings.
3. **App-Group-Identifier verstreut** — `"group.com.barto.motioncore"` ist als String-Literal in `IdleView`, `WatchComplicationService`, `StreakProvider` und `WeeklyProgressProvider` dupliziert. Tippfehler-Bug-Falle, betrifft 3 Stellen.

### Top-3-Wins (was ist gut gemacht?)
1. **Watch ist alleiniger HealthKit-Workout-Writer** — `HKWorkoutSession`, `HKLiveWorkoutBuilder`, `requestAuthorization` mit `.workoutType()` existieren ausschließlich in `WatchWorkoutManager.swift`. iPhone-seitig kein `HKWorkoutSession` oder Workout-Save (Grep-verifiziert). Die "Watch is sole HealthKit writer"-Regel wird konsequent eingehalten.
2. **`discardWorkout` korrekt async** — `WatchWorkoutManager.discardWorkout()` (Zeile 137–152) wartet `endCollection(at:)` ab, bevor `builder.discardWorkout()` aufgerufen wird. Genau das, was die "Watch Discard Workflow"-Gotcha in CLAUDE.md fordert. `WatchSessionManager` ruft es konsequent über `await` auf (Zeile 254–255).
3. **Rest-Timer-Countdown via Date-Anchor** — `WatchActiveWorkoutView.restView` (Zeile 118) verwendet `Text(timerInterval: Date()...endDate, countsDown: true)` statt `Text(date, style: .timer)`. Genau das in CLAUDE.md geforderte Pattern — kein Aufwärtszählen nach Ablauf, kein sekündlicher Sync nötig.

### Empfehlung
Zwei High-Findings sollten als Erstes adressiert werden: `[L1-Watch-001]` (Nested ObservableObject) ist eine echte UI-Daten-Falle, derzeit nur durch den 1-Hz-Live-Timer kaschiert; `[L1-Watch-002]` (restEndDate-Reset durch Lifecycle-Messages) ist ein latenter Bug mit unangenehmem Timing-Risiko bei `sendRequestSnapshot()` direkt vor `restTimerManager.start(...)`. Beide hängen architektonisch mit der Frage zusammen: "Wer ist eigentlich die SSoT für Live-Werte auf der Watch?" — sinnvoll im Cluster zu fixen. Danach die App-Group-Konstante zentralisieren (`[L1-Watch-005]`), das beseitigt drei Duplikate auf einmal.

---

## Findings

### [L1-Watch-001] Nested ObservableObject: HR/Kalorien auf Watch werden nur durch Glück aktualisiert

**Status:** ✅ Implementiert am 2026-05-29 (Build grün). Umgesetzt als **objectWillChange-Forwarding** in einem `didSet` auf `workoutManager` (`WatchSessionManager.swift:39–47`, neue Cancellable Z. 66) — bewusste Abweichung vom „Konkreten Fix": das dort vorgeschlagene Mirroring in `sendHeartbeatUpdate()` hätte HR an den 5-s-Heartbeat-Timer gekoppelt und die Refresh-Rate von ~1 Hz auf 5 s regressiert. Forwarding erhält die HK-native Rate, behebt das Pause-Einfrieren und braucht keine View-Änderung. Das `didSet` ist nötig, weil `workoutManager` mehrfach neu zugewiesen wird (Start/Self-Healing/Discard).

**Severity:** 🟠 High
**Kategorie:** SwiftUI-State
**Datei:** MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift:65–91
**Verwandte Findings:** —

**Fundstelle:**
```swift
HStack(spacing: 4) {
    Image(systemName: "heart.fill")
        .foregroundStyle(Color.red)
        .font(.caption2)
    let hr = watchSession.workoutManager?.currentHeartRate ?? 0
    Text(hr > 0 ? "\(Int(hr))" : "–")
        .font(.system(.caption, design: .monospaced).bold())
    Text("bpm")
        .font(.caption2)
        .foregroundStyle(.secondary)
}
```

**Problem:**
`workoutManager` ist `@Published` auf `WatchSessionManager`, aber `currentHeartRate` / `activeCalories` sind `@Published` auf der **inneren** `WatchWorkoutManager`-Instanz. SwiftUI observiert verschachtelte `ObservableObject`s nicht automatisch — nur ein Swap der `workoutManager`-Referenz triggert ein Re-Render des `EnvironmentObject`. Updates der HR auf demselben Manager-Objekt erreichen die View nicht direkt. Funktioniert in der Praxis aktuell **nur deshalb**, weil `liveElapsedSeconds` als `@Published` auf `WatchSessionManager` sekündlich tickt und einen 1-Hz-Re-Render erzwingt, der nebenbei den HR-Wert neu liest.

**Auswirkung:**
- Wenn der Live-Timer ausfällt (z.B. wenn die View während `.paused` gerendert wird — `stopLocalTimer()` wird auf jedem Phone-Push aufgerufen), friert die HR-Anzeige ein, obwohl `HKLiveWorkoutBuilder` weiter Werte liefert.
- HR-Updates erscheinen visuell verzögert (maximal 1 s Lag), was bei 5-s-Heartbeat-Intervallen nicht problematisch wirkt, aber die UI fühlt sich gegenüber der Apple-Workout-App träge an.
- Architektonisch fragil: wer auch immer den 1-Hz-Timer in Zukunft optimiert, bricht die HR-Anzeige unbemerkt.

**Empfohlene Korrektur:**
HR/Kalorien als eigene `@Published`-Properties direkt auf `WatchSessionManager` spiegeln und in `sendHeartbeatUpdate()` bzw. `currentSnapshot()`-Aufruf aktualisieren. Damit ist die SSoT für die UI klar `WatchSessionManager`, und der HealthKit-Manager bleibt ein interner Datenproduzent. Alternativ `WatchWorkoutManager` als `@StateObject` separat in der View beobachten — aber dann müsste die View Kenntnis der Manager-Existenz haben, was die aktuelle Kapselung bricht.

**Konkreter Fix:**
```swift
// In WatchSessionManager: HR/Kalorien als eigene @Published mirroren
@Published private(set) var liveCurrentHR: Double = 0
@Published private(set) var liveActiveCalories: Double = 0

private func sendHeartbeatUpdate() {
    guard let manager = workoutManager else { return }
    let snapshot = manager.currentSnapshot()
    // UI-State mirroren — triggert View-Update
    self.liveCurrentHR = manager.currentHeartRate
    self.liveActiveCalories = manager.activeCalories
    var payload = snapshot
    payload[WatchHealthKey.healthUpdate] = true
    sendSnapshotToPhone(payload)
}

// In WatchActiveWorkoutView: direkt aus WatchSessionManager lesen
let hr = watchSession.liveCurrentHR
let cal = watchSession.liveActiveCalories
```

**Aufwand:** ~30 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Ja
**Begründung Diskussion:** Alternative Architektur: `WatchWorkoutManager` direkt als zweiten `@EnvironmentObject` einsetzen und mit `WatchSessionManager` koppeln. Charmant aber bricht das Singleton-Pattern und macht Preview komplizierter. Mirroring (oben) hat geringeren Footprint, aber doppelte State-Haltung. Bartosz' Entscheidung, welche Variante zur Watch-Konvention passen soll.

---

### [L1-Watch-002] `restEndDate` wird durch jede Lifecycle-Message auf nil zurückgesetzt

**Status:** ✅ Bereits implementiert (verifiziert 2026-05-29). Der `isStateMessage`-Guard aus dem „Konkreten Fix" steckt 1:1 im Live-File (`WatchSessionManager.swift:122–135`); restEndDate/isResting werden nur noch bei State-Messages mit `workoutState`-Key angefasst. Fix wurde nach Review-Stand `c641daf` eingespielt (laut `tasks/current.md` am 29.05.2026).

**Severity:** 🟠 High
**Kategorie:** WCSession-Kommunikation
**Datei:** MotionCoreWatch Watch App/Services/WatchSessionManager.swift:122–131
**Verwandte Findings:** [L1-Watch-003]

**Fundstelle:**
```swift
// Rest-Timer-State aus iPhone-Nachricht auslesen
if let resting = message[WatchStateKey.isResting] as? Bool {
    self.isResting = resting
}
if let endInterval = message[WatchStateKey.restEndDate] as? TimeInterval {
    self.restEndDate = Date(timeIntervalSinceReferenceDate: endInterval)
} else if !(message[WatchStateKey.isResting] as? Bool ?? false) {
    // isResting = false ohne restEndDate → Timer abgelaufen oder nicht aktiv
    self.restEndDate = nil
}
```

**Problem:**
Lifecycle-Messages vom iPhone (`sendStartHealthTracking`, `sendStopHealthTracking`, `sendPauseHealthTracking`, `sendResumeHealthTracking`, `sendExerciseTransition`, `sendRequestSnapshot`, `sendHeartbeatEnabled`) enthalten **keine** `WatchStateKey.isResting`- oder `restEndDate`-Felder. Der `else if`-Branch wertet aber `message[...isResting] as? Bool ?? false` aus — fehlende Keys → `false` → `!false == true` → `self.restEndDate = nil`. Jede Lifecycle-Nachricht löscht damit den laufenden Rest-Countdown, obwohl iPhone-seitig der Timer weiterläuft.

**Auswirkung:**
- Konkretes Szenario: User schließt Satz ab → iPhone ruft `sendRequestSnapshot()` (ActiveWorkoutView Zeile 890) → Watch löscht `restEndDate` → erst durch das danach folgende `onChange(of: session.completedSets)` → `sendWatchState(...)` mit `restEndDate` wird der Countdown wiederhergestellt. Zwischen den beiden Messages flackert die UI in der Hop-Animation `if watchSession.isResting, let endDate = watchSession.restEndDate` zurück auf `workoutView`, bevor sie wieder zur `restView` springt.
- Bei Pause während eines laufenden Rest-Timers (theoretisch möglich) verliert die Watch den Countdown dauerhaft, bis das nächste State-Update kommt.
- Latente Race-Condition: WCSession-Messages sind zwar pro Counterpart geordnet, aber bei vielen schnell aufeinanderfolgenden Sends (Set abschließen löst Snapshot + State-Push aus) kann jede Reihenfolge zu temporären Geisterzuständen führen.

**Empfohlene Korrektur:**
Lifecycle-State und View-State strikt trennen: `restEndDate`/`isResting` nur dann zurücksetzen, wenn die Message **tatsächlich** ein State-Update ist (erkennbar an `workoutState`-Key) oder explizit `isResting=false` enthält. Heuristik: ist `WatchStateKey.workoutState` in der Message vorhanden, ist es eine State-Message — sonst Lifecycle.

**Konkreter Fix:**
```swift
// Rest-Timer-State NUR aus State-Messages auslesen
let isStateMessage = message[WatchStateKey.workoutState] != nil
if isStateMessage {
    self.isResting = message[WatchStateKey.isResting] as? Bool ?? false
    if let endInterval = message[WatchStateKey.restEndDate] as? TimeInterval {
        self.restEndDate = Date(timeIntervalSinceReferenceDate: endInterval)
    } else {
        // State-Message ohne restEndDate → Timer beendet
        self.restEndDate = nil
    }
}
// Lifecycle-Messages (ohne workoutState-Key) verändern restEndDate/isResting NICHT
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein

---

### [L1-Watch-003] Self-Healing kann nach Discard ein neues HKWorkout starten, bevor `idle` ankommt

**Status:** ✅ Implementiert am 2026-05-29 (Build grün). Umgesetzt als **negatives `isTearingDown`-Flag** (`WatchSessionManager.swift`: Z. 67, Guard Z. 162, gesetzt Z. 263/274, gelöscht Z. 234) — bewusste Abweichung von BEIDEN Vorschlägen des Findings. Grund: die echte Discard-Kette wurde verfolgt — `discardSession()` → `endSession()` setzt `isPaused = true` → `onChange(of: isPaused)` (ActiveWorkoutView:287) feuert einen **deferred** `sendState()`-`paused`-Push, der NACH der synchron gesendeten Idle-Message ankommt. Dieser Trailing-Push hebelt sowohl die *kombinierte Discard+Idle-Message* als auch das *bei `.idle` gelöschte Flag* aus (idle löscht das Flag, bevor der paused-Push eintrifft). Korrekt: Flag bei stop/discard setzen, **nur bei `startHealthTracking` löschen** (nicht bei idle). Die `workoutState != .idle`-Inferenz bleibt erhalten — sie ist load-bearing für den Watch-Relaunch-Resume-Fall (nach Relaunch gibt es kein erneutes `startHealthTracking`). `isTearingDown = true` steht bei stop bewusst VOR dem `guard let manager` (double-stop / stop-after-discard).

**Severity:** 🟡 Medium
**Kategorie:** Lifecycle-Management
**Datei:** MotionCoreWatch Watch App/Services/WatchSessionManager.swift:143–175
**Verwandte Findings:** [L1-Watch-002]

**Fundstelle:**
```swift
// Self-Healing: Workout aktiv aber kein Health-Tracking läuft → auto-starten
// Guard: nicht bei Stop/Discard auslösen (workoutManager ist dort gerade nil gesetzt worden,
// aber workoutState noch nicht .idle — Idle kommt als separate Nachricht vom iPhone)
let isStoppingNow = message[WatchWorkoutLifecycleKey.stopHealthTracking] != nil
                 || message[WatchWorkoutLifecycleKey.discardHealthTracking] != nil
if self.workoutState != .idle && self.workoutManager == nil && !isStoppingNow {
    let manager = WatchWorkoutManager()
    self.workoutManager = manager
    Task {
        let authorized = await manager.requestAuthorization()
        // ... startet neuen HKWorkoutSession
    }
}
```

**Problem:**
Der `isStoppingNow`-Guard greift **nur in der gleichen Message**. Sobald die Stop/Discard-Nachricht verarbeitet ist, ist `workoutManager == nil` und `workoutState` ist noch `.active` oder `.paused` (Idle-State kommt vom iPhone als separater `sendIdleState`-Aufruf). Wenn **zwischen** Stop/Discard und Idle eine weitere Message ankommt — z.B. ein verspätet zugestellter State-Push oder ein onChange-getriggerter `sendWatchState` — ist `isStoppingNow=false`, alle Guards sind erfüllt, Self-Healing startet eine **brandneue HKWorkoutSession** unmittelbar nach dem Discard.

**Auswirkung:**
- In `ActiveWorkoutView.cancelWorkout()` (Zeile 1114–1131) folgen `sendDiscardHealthTracking()` und `sendIdleState()` zwar synchron aufeinander, aber zwischen ihnen können `onChange(of: sessionManager.isPaused)`-getriggerte State-Pushes liegen (z.B. wenn `discardSession()` einen Pause-State zurücksetzt).
- WCSession ordnet zwar pro Counterpart, aber bei besonders schneller Folge kann ein State-Update on-the-fly anders priorisiert werden.
- Effekt: User verwirft Training mit Health-Daten — Watch startet 1 Sekunde später unsichtbar ein neues HKWorkout, das in Apple Health erscheint.

**Empfohlene Korrektur:**
Self-Healing nicht nur per `isStoppingNow` in der **aktuellen** Message blockieren, sondern durch ein persistentes Flag, das nach Stop/Discard für eine kurze Karenzzeit (oder bis `.idle` ankommt) aktiv bleibt. Alternativ: iPhone schickt Discard und Idle in einer einzigen Message (kombinierter Payload), sodass `workoutState == .idle` direkt zusammen mit dem Stop-Signal ankommt — saubere Lösung, beseitigt das Race-Window komplett.

**Konkreter Fix:**
```swift
// Privates Flag, das Self-Healing nach Stop/Discard blockt bis Idle ankommt
private var isTearingDown: Bool = false

// In handleHealthLifecycle bei stopHealthTracking / discardHealthTracking:
self.isTearingDown = true

// In session(_:didReceiveMessage:) — Self-Healing-Guard erweitern:
if self.workoutState != .idle
   && self.workoutManager == nil
   && !isStoppingNow
   && !self.isTearingDown {  // ← neu
    // ... Self-Healing wie bisher
}

// Bei Eintritt in .idle Flag zurücksetzen:
if self.workoutState == .idle {
    self.isTearingDown = false
    self.liveElapsedSeconds = 0
}
```

**Aufwand:** ~15 Min
**Risiko:** Mittel
**Diskussion erwünscht:** Ja
**Begründung Diskussion:** Race-Window ist in der Praxis schmal und mir ist kein User-Report bekannt. Trade-off: Patch oben fügt State hinzu, alternative iPhone-Kombi-Message (Discard+Idle in einer sendMessage) wäre eleganter, ändert aber Phone-Protokoll und damit beide Targets. Bartosz' Entscheidung welche Strategie zur Watch-Konvention passen soll.

---

### [L1-Watch-004] Nicht-Snapshot-Pfad in `didReceiveMessage(replyHandler:)` verarbeitet keine Lifecycle-Logik

**Status:** ✅ Bereits implementiert (verifiziert 2026-05-29, Build grün). Die Reply-Variante macht bei `requestSnapshot` ein `return` und delegiert alle anderen Nachrichten an die No-Reply-Variante (`self.session(session, didReceiveMessage:)`) + quittiert mit `replyHandler([:])` — 1:1 der „Konkrete Fix". Fundstelle `WatchSessionManager.swift:199–222`. Wurde nach Review-Stand `c641daf` eingespielt.

**Severity:** 🟡 Medium
**Kategorie:** WCSession-Kommunikation
**Datei:** MotionCoreWatch Watch App/Services/WatchSessionManager.swift:184–205
**Verwandte Findings:** —

**Fundstelle:**
```swift
func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    // Snapshot-Anforderung mit sofortiger Antwort via replyHandler
    if message[WatchWorkoutLifecycleKey.requestSnapshot] != nil {
        DispatchQueue.main.async { [weak self] in
            guard let self, let manager = self.workoutManager else {
                replyHandler([:])
                return
            }
            var combined = manager.currentSnapshot()
            // ... reply
        }
    } else {
        // Alle anderen Nachrichten mit leerem Reply quittieren
        replyHandler([:])
    }
}
```

**Problem:**
Die Reply-Variante von `didReceiveMessage` behandelt ausschließlich `requestSnapshot`. Wenn iPhone-Code jemals ein anderes `sendMessage(..., replyHandler: ...)` (z.B. Pause-Toggle mit ACK) verwenden würde, würde die Nachricht zwar mit leerem Reply quittiert, aber inhaltlich verworfen — kein State-Update, keine Lifecycle-Verarbeitung. Aktuell wird `replyHandler` außerhalb von `requestFinalSnapshot` nicht genutzt, also funktional korrekt — aber als Architekturfalle gefährlich, weil das Verhalten still ist (kein Crash, kein Log).

**Auswirkung:**
- Erweiterungen (z.B. ein zukünftiges "iPhone wartet auf Watch-ACK vor Set-Speicherung") würden stumm scheitern.
- Symmetrie-Bruch: die No-Reply-Variante verarbeitet `requestSnapshot` **ebenfalls** (Zeile 275–284), aber via fire-and-forget. Doppelte Pfade für denselben Key sind eine Wartungsfalle — wer pflegt welchen Pfad, wenn sich die Snapshot-Logik ändert?

**Empfohlene Korrektur:**
Reply-Variante einfach an die No-Reply-Variante delegieren und am Ende `replyHandler([:])` aufrufen (außer bei `requestSnapshot`, das eine echte Antwort braucht). Damit ist nur ein Lifecycle-Pfad existent.

**Konkreter Fix:**
```swift
func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    // requestSnapshot: synchrone Antwort über replyHandler
    if message[WatchWorkoutLifecycleKey.requestSnapshot] != nil {
        DispatchQueue.main.async { [weak self] in
            guard let self, let manager = self.workoutManager else {
                replyHandler([:])
                return
            }
            var combined = manager.currentSnapshot()
            let exerciseSnap = manager.exerciseSnapshot()
            for (key, value) in exerciseSnap { combined[key] = value }
            combined[WatchExerciseSnapshotKey.exerciseSnapshot] = true
            replyHandler(combined)
        }
        return
    }

    // Alle anderen Nachrichten: an die No-Reply-Variante delegieren
    self.session(session, didReceiveMessage: message)
    replyHandler([:])
}
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein

---

### [L1-Watch-005] App-Group-Identifier `"group.com.barto.motioncore"` ist 4× als String-Literal verstreut

**Severity:** 🟡 Medium
**Kategorie:** Wartbarkeit
**Datei:** mehrere Stellen (Liste unten)
**Verwandte Findings:** —

**Fundstelle:**
```swift
// MotionCoreWatch Watch App/Views/IdleView.swift:19
UserDefaults(suiteName: "group.com.barto.motioncore")

// MotionCoreWatch Watch App/Complications/StreakComplication.swift:28
UserDefaults(suiteName: "group.com.barto.motioncore")

// MotionCoreWatch Watch App/Complications/WeeklyProgressComplication.swift:29
UserDefaults(suiteName: "group.com.barto.motioncore")

// MotionCore/Services/Watch/WatchComplicationService.swift:23
private static let appGroup = "group.com.barto.motioncore"
```

**Problem:**
Der App-Group-Identifier ist an mindestens vier Stellen als String-Literal dupliziert. Ein Tippfehler in einem einzigen Vorkommen führt zu `UserDefaults(suiteName:)` mit nil-Rückgabe — die Reads/Writes verschieben sich stumm in den Standard-Container, ohne Compiler-Warnung. Der Bug wäre extrem schwer zu finden.

**Auswirkung:**
- Tippfehler-Bug-Falle bei jeder Identifier-Änderung (z.B. Multi-Build-Konfigurationen für TestFlight/Beta).
- Komplikationen lesen leere Daten, IdleView zeigt 0/0 — ohne ersichtlichen Fehler.
- Multi-Target-Konsistenz wird durch Kommentare ("identisch in beiden Targets") in den Shared-Files dokumentiert, aber bei App-Group fehlt diese Disziplin komplett.

**Empfohlene Korrektur:**
Eine Konstante in `WatchMessageKeys.swift` (Shared-File, in beiden Targets verfügbar) definieren und an allen vier Stellen referenzieren. Optional plus eine Helper-Funktion `WatchAppGroup.defaults` für `UserDefaults(suiteName:)`.

**Konkreter Fix:**
```swift
// In WatchMessageKeys.swift, neue Sektion ergänzen:

// MARK: - App Group

/// Gemeinsamer App-Group-Identifier für Watch ↔ iPhone Datenfreigabe.
/// Muss exakt mit dem Entitlement-Eintrag in beiden Targets übereinstimmen.
enum WatchAppGroup {
    static let identifier = "group.com.barto.motioncore"

    /// Convenience-Accessor für die App-Group-UserDefaults.
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }
}

// Dann an allen 4 Stellen ersetzen:
// IdleView.swift:19, StreakComplication.swift:28, WeeklyProgressComplication.swift:29:
private var sharedDefaults: UserDefaults? { WatchAppGroup.defaults }

// WatchComplicationService.swift:23:
private static let appGroup = WatchAppGroup.identifier
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein

---

### [L1-Watch-006] Watch-State nutzt `exerciseName` statt `exerciseNameSnapshot`

**Severity:** 🟡 Medium
**Kategorie:** Projekt-Konvention
**Datei:** MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift:1149–1158
**Verwandte Findings:** —

**Fundstelle:**
```swift
private func sendWatchState() {
    let state: WatchWorkoutState = sessionManager.isPaused ? .paused : .active
    let grouped = cachedGroupedSets
    let currentKey = selectedExerciseKey ?? session.nextUncompletedSet?.groupKey ?? ""
    let exIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? 0
    let currentExName = grouped[safe: exIdx]?.first?.exerciseName ?? ""
    let completedInGroup = grouped[safe: exIdx]?.filter { $0.isCompleted }.count ?? 0
    let totalInGroup = grouped[safe: exIdx]?.count ?? 0

    PhoneSessionManager.shared.sendWorkoutState(
        state: state,
        exerciseName: currentExName,
        // ...
    )
}
```

**Problem:**
CLAUDE.md fordert explizit: *"Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`"*. Genau dieser Aufrufer benutzt aber `.exerciseName`. Andere Stellen in derselben Datei verwenden den korrekten Fallback-Pattern (z.B. Zeile 181, 542, 679: `$0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot`).

**Auswirkung:**
- Wenn die referenzierte `Exercise` umbenannt oder gelöscht wird (z.B. nach Plan-Update), zeigt die Watch den neuen Namen statt des historischen Snapshots — inkonsistent zum Rest der App, der den Snapshot bevorzugt.
- Bei migriertem Datenbestand mit lookup-basierter `exerciseName`-Resolution kann es zu leeren Strings kommen, die im Watch-UI als "–" erscheinen.

**Empfohlene Korrektur:**
Denselben Fallback-Pattern wie in den anderen Aufrufern verwenden — Snapshot bevorzugen, `exerciseName` nur als Fallback.

**Konkreter Fix:**
```swift
private func sendWatchState() {
    // ... unverändert oben
    let firstSet = grouped[safe: exIdx]?.first
    let currentExName = firstSet?.exerciseNameSnapshot.isEmpty == false
        ? firstSet!.exerciseNameSnapshot
        : (firstSet?.exerciseName ?? "")
    // ... Rest unverändert
}
```

**Aufwand:** <5 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein

---

### [L1-Watch-007] `setIndex` kann transient `totalSets` überschreiten → Watch zeigt "Satz 4/3"

**Status:** ✅ Implementiert am 2026-05-29 (Build grün). **Variante A (iPhone-Seite)** gewählt: `WatchBridge.sendState()` sendet `setIndex` jetzt als Index des nächsten offenen Satzes (`nextOpenIdx ?? max(0, totalInGroup - 1)`) statt als `completedInGroup`-Count (`WatchBridge.swift:74–86`, `completedInGroup` entfernt). Behebt die Count-vs-Index-Verwechslung an der Quelle — deckt sowohl die „Satz X/Y"-Zeile als auch das Button-Label ab und korrigiert zusätzlich den Out-of-order-Fall. Variante B (Watch-seitiges Clampen) verworfen, weil sie nur das Symptom maskiert und je Anzeige-Stelle dupliziert werden müsste. Hinweis: Stelle lag laut Review noch in `ActiveWorkoutView`, ist beim Refactoring nach `WatchBridge` gewandert.

**Severity:** 🟡 Medium
**Kategorie:** UI / Watch-Bridge
**Datei:** MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift:1153–1166 + MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift:59,99
**Verwandte Findings:** —

**Fundstelle:**
```swift
// iPhone (ActiveWorkoutView):
let completedInGroup = grouped[safe: exIdx]?.filter { $0.isCompleted }.count ?? 0
let totalInGroup = grouped[safe: exIdx]?.count ?? 0
PhoneSessionManager.shared.sendWorkoutState(
    // ...
    setIndex: completedInGroup,
    totalSets: totalInGroup,
    // ...
)

// Watch (WatchActiveWorkoutView):
Text("Satz \(watchSession.setIndex + 1)/\(watchSession.totalSets)  ·  Übung \(watchSession.exerciseIndex + 1)/\(watchSession.totalExercises)")
// und Zeile 99:
Label("Satz \(watchSession.setIndex + 1)", systemImage: "checkmark.circle.fill")
```

**Problem:**
`setIndex = completedInGroup` (z.B. 3 bei 3 abgeschlossenen Sätzen). Die Watch zeigt dann `Satz 4/3`. Tritt auf zwischen dem Abschließen des letzten Satzes einer Übung und dem `onChange(of: selectedExerciseKey)`-Trigger, der zur nächsten Übung navigiert. Auch im Superset-Flow für den Moment, in dem alle Sätze einer Position abgeschlossen sind, aber `handleSupersetRotation` noch nicht zur nächsten Position rotiert hat.

**Auswirkung:**
- Sichtbarer UI-Glitch ("Satz 4/3") auf der Watch — kurzfristig, aber für User irritierend.
- Auf dem "Satz X"-Button wird `Satz 4` angezeigt, obwohl `disabled(watchSession.workoutState == .paused)` nicht greift — ein Klick darauf triggert `completeSet`, was im `handleWatchAction(.completeSet)` durch `selectedExerciseSets.first(where: { !$0.isCompleted })` korrekt abgefangen wird (kein Set mehr offen → kein Effekt). Verhalten ist also defensiv, aber die UI-Indikation ist irreführend.

**Empfohlene Korrektur:**
Auf der iPhone-Seite den Index auf den **nächsten offenen Satz** statt auf "Anzahl abgeschlossener" abbilden. Das deckt den Übergangsmoment sauber ab und macht den Naming-Konflikt zwischen "Index" und "Count" konzeptionell sauber.

**Konkreter Fix:**
```swift
// In sendWatchState:
let groupSets = grouped[safe: exIdx] ?? []
let nextOpenIdx = groupSets.firstIndex(where: { !$0.isCompleted })
let totalInGroup = groupSets.count
// setIndex zeigt den Index des aktuellen/nächsten Satzes (0-basiert)
// — wenn alle abgeschlossen: clampen auf totalInGroup - 1 (Watch zeigt dann "Satz N/N")
let displaySetIndex = nextOpenIdx ?? max(0, totalInGroup - 1)

PhoneSessionManager.shared.sendWorkoutState(
    // ...
    setIndex: displaySetIndex,
    totalSets: totalInGroup,
    // ...
)
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Ja
**Begründung Diskussion:** Alternative: Watch-seitig clampen mit `min(setIndex + 1, totalSets)`. Schnellerer Patch, aber doppelte Semantik (Phone und Watch interpretieren `setIndex` unterschiedlich). Bartosz entscheidet, wo die Korrektur sitzen soll.

---

### [L1-Watch-008] `IdleView` re-rendert nicht, wenn Complications-UserDefaults von außen aktualisiert werden

**Severity:** 🔵 Low
**Kategorie:** SwiftUI-State
**Datei:** MotionCoreWatch Watch App/Views/IdleView.swift:15–33
**Verwandte Findings:** —

**Fundstelle:**
```swift
struct IdleView: View {

    // Complications-Daten aus App Group UserDefaults lesen
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.barto.motioncore")
    }

    private var streakCount: Int {
        sharedDefaults?.integer(forKey: WatchComplicationKey.streakCount) ?? 0
    }

    private var weeklyCount: Int {
        sharedDefaults?.integer(forKey: WatchComplicationKey.weeklyWorkoutCount) ?? 0
    }
    // ...
}
```

**Problem:**
`IdleView` liest Werte über computed properties aus `UserDefaults(suiteName:)`. Wenn iPhone-Code (`WatchComplicationService.updateComplications`) die Defaults während die Watch-App läuft aktualisiert, gibt es keinen `objectWillChange`-Trigger für die View. Re-Render passiert nur, wenn die View neu erscheint (Navigation, App-Activation) oder wenn ein anderer State-Wechsel sie sowieso neu rendert.

**Auswirkung:**
- User schließt iPhone-Workout ab, schaut auf seine Watch — Streak zeigt noch alten Wert, bis die Watch-App in den Hintergrund und zurück geht.
- Schwer reproduzierbar, weil die typische Watch-Nutzung sowieso das App-Lifecycle aktiviert (Activation = neuer Render).

**Empfohlene Korrektur:**
`@AppStorage` mit App-Group-Suite verwenden — bindet UserDefaults direkt an SwiftUI-State und triggert View-Updates bei externen Änderungen. Funktioniert sauber für `Int`-Werte.

**Konkreter Fix:**
```swift
struct IdleView: View {

    @AppStorage(WatchComplicationKey.streakCount,
                store: WatchAppGroup.defaults)  // siehe [L1-Watch-005]
    private var streakCount: Int = 0

    @AppStorage(WatchComplicationKey.weeklyWorkoutCount,
                store: WatchAppGroup.defaults)
    private var weeklyCount: Int = 0

    @AppStorage(WatchComplicationKey.weeklyWorkoutGoal,
                store: WatchAppGroup.defaults)
    private var weeklyGoalRaw: Int = 0

    private var weeklyGoal: Int { weeklyGoalRaw > 0 ? weeklyGoalRaw : 5 }

    var body: some View {
        // ... unverändert
    }
}
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein

---

### [L1-Watch-009] Pause-Toggle-Button auf der Watch hat keine Disable-Sicherung gegen Doppelklick

**Status:** ✅ Implementiert am 2026-05-29 (Build grün). Debounce-Lock (Variante A) **nur auf dem Pause/Resume-Button** (`WatchActiveWorkoutView.swift:17,27–41`): `@State isPauseLocked`, 500 ms `Task.sleep`-Auto-Unlock, `.disabled(isPauseLocked)`. **Satz-Button bewusst NICHT gelockt** — der `handleAction(.completeSet)`-Guard (erster nicht-abgeschlossener Satz) verhindert den Doppel-Complete-Bug bereits, und ein Lock würde schnelle legitime Mehrfach-Logger ausbremsen. Optimistic-State (Variante B) als Over-Engineering für ein Low-Finding verworfen.

**Severity:** 🔵 Low
**Kategorie:** UI-Robustheit
**Datei:** MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift:26–34
**Verwandte Findings:** —

**Fundstelle:**
```swift
Button {
    watchSession.sendAction(.pauseResume)
} label: {
    Image(systemName: watchSession.workoutState == .paused ? "play.fill" : "pause.fill")
        .font(.caption)
}
.buttonStyle(.plain)
.foregroundStyle(watchSession.workoutState == .paused ? Color.orange : .secondary)
```

**Problem:**
`sendAction(.pauseResume)` ist fire-and-forget, kein Reply. Round-Trip von Watch → iPhone → onChange → Watch dauert typischerweise 200–400 ms. In dieser Zeit kann der User den Button erneut drücken — zwei `pauseResume`-Actions in Folge togglen zweimal, der User landet wieder im Ausgangszustand. Watch-spezifisch unschön, weil User den State-Sync nicht sieht und glaubt der erste Klick sei nicht angekommen.

**Auswirkung:**
- Nicht-deterministisches Verhalten bei nervösen Tappers — Pausen-State auf iPhone kann nicht zum Watch-State passen, bis das nächste onChange durchläuft.
- Gleiches Problem existiert für `completeSet` (Zeile 96–106), wo Doppelklick einen zweiten Set abschließen könnte, falls zwischen dem ersten Klick und dem `onChange(of: session.completedSets)` der nächste Set noch nicht selektiert wurde.

**Empfohlene Korrektur:**
Kurzes Debouncing per `@State` Boolean — Button für 400–500 ms nach Klick deaktivieren. Alternativ: optimistischer State-Update auf Watch-Seite (workoutState lokal togglen) und auf iPhone-Bestätigung warten. Letzteres ist invasiver, aber UX-konsistenter.

**Konkreter Fix:**
```swift
@State private var isActionLocked = false

Button {
    guard !isActionLocked else { return }
    isActionLocked = true
    watchSession.sendAction(.pauseResume)
    Task {
        try? await Task.sleep(for: .milliseconds(500))
        await MainActor.run { isActionLocked = false }
    }
} label: {
    Image(systemName: watchSession.workoutState == .paused ? "play.fill" : "pause.fill")
        .font(.caption)
}
.disabled(isActionLocked)
// ... Rest unverändert
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Ja
**Begründung Diskussion:** Doppelklicks sind in der Praxis selten; das Lock fügt eine kleine Komplexität hinzu. Bartosz' Entscheidung, ob die Robustheit den Code-Aufwand rechtfertigt.

---

### [L1-Watch-010] `HKLiveWorkoutBuilder`-Statistics werden in jeder `didCollectDataOf`-Iteration neu gelesen, auch für nicht-betroffene Typen

**Severity:** 🔵 Low
**Kategorie:** Performance
**Datei:** MotionCoreWatch Watch App/Services/WatchWorkoutManager.swift:246–285
**Verwandte Findings:** —

**Fundstelle:**
```swift
func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        // Herzfrequenz auslesen
        if collectedTypes.contains(HKQuantityType(.heartRate)) {
            let hrType = HKQuantityType(.heartRate)
            // ... statistics(for: hrType)
        }

        // Aktive Kalorien auslesen
        if collectedTypes.contains(HKQuantityType(.activeEnergyBurned)) {
            let calType = HKQuantityType(.activeEnergyBurned)
            // ...
        }
    }
}
```

**Problem:**
Beide `if collectedTypes.contains(...)`-Checks legen jedes Mal eine neue `HKQuantityType`-Instanz an, nur um auf Identität zu prüfen. Mikrooptimierung — `HKQuantityType` ist günstig, aber jede HR-Probe (theoretisch jede Sekunde) dispatcht auf MainActor und allokiert. Kein Hot-Path-Problem, aber bei einem 60-Min-Workout sind das 60.000 unnötige Allokationen. Eher Stil als Performance-Bug.

**Auswirkung:**
- Mikroskopischer Energieverbrauch auf der Watch, nicht messbar.
- Lesbarkeit: der Code wirkt "abgeschrieben" — typische Apple-Sample-Code-Struktur, aber das Caching von HK-Typen ist die etablierte Best Practice.

**Empfohlene Korrektur:**
HK-Quantity-Types als `private let` cachen — einmal initialisieren, mehrfach nutzen. Reine Stilverbesserung, kein Verhalten ändert sich.

**Konkreter Fix:**
```swift
// MARK: - Private Properties
private let healthStore = HKHealthStore()
// ... unverändert
private let hrType  = HKQuantityType(.heartRate)
private let calType = HKQuantityType(.activeEnergyBurned)
private let hrUnit  = HKUnit.count().unitDivided(by: .minute())

// MARK: - HKLiveWorkoutBuilderDelegate
func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        if collectedTypes.contains(self.hrType) {
            if let stats = workoutBuilder.statistics(for: self.hrType) {
                // ... self.hrUnit verwenden
            }
        }
        if collectedTypes.contains(self.calType) {
            // ...
        }
    }
}
```

**Aufwand:** ~10 Min
**Risiko:** Niedrig
**Diskussion erwünscht:** Nein

---

### [L1-Watch-011] Komplikationen aktualisieren nur einmal täglich — keine Refreshes bei iPhone-Workout-Abschluss

**Severity:** ⚪ Info
**Kategorie:** Komplikationen-Lifecycle
**Datei:** MotionCoreWatch Watch App/Complications/StreakComplication.swift:39–43 + MotionCoreWatch Watch App/Complications/WeeklyProgressComplication.swift:40–44
**Verwandte Findings:** —

**Fundstelle:**
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    // Täglich um Mitternacht neu laden
    let nextUpdate = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
    completion(Timeline(entries: [makeEntry()], policy: .after(nextUpdate)))
}
```

**Problem:**
Die Watch-Komplikations-Timelines werden nur einmal täglich um Mitternacht neu geladen. `WatchComplicationService.updateComplications` ruft zwar `WidgetCenter.shared.reloadTimelines(...)` auf — das funktioniert aber nur, wenn die Watch-App **läuft** oder iOS und watchOS die Reload-Anfrage über das Background-System weiterleiten (was bei App-Group-Apps zuverlässig, aber nicht garantiert ist).

**Auswirkung:**
- Wenn iPhone-Workout abgeschlossen wird, sieht der User die aktualisierte Streak ggf. erst beim nächsten Watch-App-Start.
- Standardverhalten ist akzeptabel — Apple empfiehlt explizit, nicht zu oft `reloadTimelines` aufzurufen, weil das das Budget verbraucht.
- Reine Beobachtung — kein Handlungsbedarf, sofern Bartosz mit dem aktuellen Lag-Verhalten einverstanden ist. Wenn nicht: zusätzlich `policy: .atEnd` und kürzere Timeline-Intervalle prüfen.

**Empfohlene Korrektur:**
Keine. Aktuelles Verhalten ist konsistent mit Apple-Best-Practices für Komplikationen.

**Konkreter Fix:**
N/A — Info-Finding.

**Aufwand:** —
**Risiko:** —
**Diskussion erwünscht:** Nein

---

## Beobachtungen für andere Layer

Aus dem Watch-Scope sind mir folgende Themen aufgefallen, die NICHT in L1-Watch gehören, aber zur Awareness in anderen Layern notiert werden sollten:

- **`ActiveWorkoutView.swift` Größe** — die Datei ist deutlich über 1.600 Zeilen (Methoden bis Zeile 1639+ in Grep-Treffern sichtbar). Liegt klar über dem Hard-Stop von 800 Zeilen, ist aber kein reines Watch-Thema. Sollte in einem L2-View-Review erfasst werden.
- **`requestFinalSnapshot` lebt in `PhoneSessionManager`, ist aber auch UI-relevant** — die View-Methode `finishWorkout` in ActiveWorkoutView wartet 3 s auf den Watch-Snapshot. Falls L2 die finishWorkout-Logik aufschnürt, sollte diese Kopplung mit bedacht werden.
- **HealthKit-Read-Auth-Status** — `HealthKitManager` und `HealthBaselineUpdateService` (iPhone-Seite) wurden nicht reviewed, könnten aber zur Watch-Authorization-Logik in `WatchWorkoutManager.requestAuthorization()` redundant sein. Gehört in L1-iPhone-Health.
- **Live-Activity-Sync** — `sendWatchState()` und `syncLiveActivityStates()` werden in fast allen onChange-Handlern parallel aufgerufen. Mögliche Redundanz, sollte in L2-Live-Activity-Review betrachtet werden.

---

## Statistik

- Gelesene Dateien: 11
- Untersuchte Zeilen (gesamt): ~2.100 (Watch-Target inkl. Bridge)
- Findings pro 1.000 Zeilen: 5.2
- Reviewer-Laufzeit: ~25 Min

## Nächste Schritte

Für `motioncore-developer`:
- **Empfohlene Fix-Reihenfolge:** L1-Watch-005 (App-Group-Konstante zentralisieren) → L1-Watch-002 (restEndDate-Reset) → L1-Watch-001 (Nested ObservableObject) → L1-Watch-006 (exerciseNameSnapshot) → L1-Watch-004 (Reply-Variante delegieren) → L1-Watch-007 (setIndex-Clamp) → L1-Watch-008 (AppStorage) → L1-Watch-003 (Self-Healing-Guard) → L1-Watch-009 (Doppelklick-Lock) → L1-Watch-010 (HK-Typ-Cache)
- **Cluster, die zusammen gefixt werden sollten:**
  - **Cluster A — Lifecycle/State-Trennung:** L1-Watch-002, L1-Watch-003, L1-Watch-004 (alle hängen am `didReceiveMessage`-Design)
  - **Cluster B — App-Group-Hygiene:** L1-Watch-005 + L1-Watch-008 (AppStorage braucht zentralisierten Suite-Namen)
  - **Cluster C — UI-State-SSoT:** L1-Watch-001 + L1-Watch-007 (klärt "Wer ist Owner der Live-Werte und wie clamp ich Übergänge")
- **Findings, die manuelles Testen brauchen:** L1-Watch-001 (HR-Anzeige bei Pause), L1-Watch-002 (Rest-Timer-Flicker), L1-Watch-003 (Discard direkt vor State-Push), L1-Watch-007 (Übergangs-Frame "Satz N+1/N")

Für Bartosz (Diskussion):
- **Issues mit "Diskussion erwünscht: Ja":** L1-Watch-001, L1-Watch-003, L1-Watch-007, L1-Watch-009
