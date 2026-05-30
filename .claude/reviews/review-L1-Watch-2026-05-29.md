# Code Review — Layer L1-Watch: Watch-Target & iPhone-Bridge

**Date:** 2026-05-29
**Reviewer:** motioncore-reviewer (Opus)
**Scope:** Komplettes Watch-Target (`MotionCoreWatch Watch App/` — App-Entry, `WatchBaseView`, `WatchActiveWorkoutView`, `IdleView`, `WatchSessionManager`, `WatchWorkoutManager`, alle Complications) plus die iPhone-seitige Brücke (`PhoneSessionManager`, `WatchComplicationService`, `WatchMessageKeys` und das neu extrahierte `WatchBridge`-Observable). Die WCSession-Verdrahtung in `ActiveWorkoutView` wurde gelesen, aber als L2-View-Thema nur unter „Observations for other layers" notiert. Shared-File `WatchMessageKeys.swift` als konsolidierte Multi-Target-Datei akzeptiert.
**Codebase State:** branch `main` @ 3ecabad (working tree; ActiveWorkoutView in fokussierte Observables aufgeteilt, `WatchBridge` neu)
**Files Read:** 14
**Issues Found:** 11

---

## Executive Summary

### Severity Distribution
- 🔴 Critical: 0
- 🟠 High: 3
- 🟡 Medium: 4
- 🔵 Low: 3
- ⚪ Info: 1

### Top Themes (was zieht sich durch?)
1. **Lifecycle/State-Trennung in `didReceiveMessage` fragil** — die Watch wertet Rest-Timer-State auch in reinen Lifecycle-Messages aus (löscht `restEndDate`), und das Self-Healing kann nach einem Discard ein Geister-HKWorkout in Apple Health schreiben. Betrifft 2 Findings, beide am selben Delegate.
2. **Nested-ObservableObject-Falle bei Live-Werten** — HR/Kalorien werden aus dem in `WatchSessionManager` verschachtelten `WatchWorkoutManager` gelesen; SwiftUI propagiert die inneren `@Published`-Events nicht. Die UI rendert nur dank des sekündlichen Live-Timers. Betrifft 1 Finding mit UI-weiter Wirkung. (Unverändert seit 2026-05-15 — das ActiveWorkoutView-Refactoring hat die Watch-Seite nicht berührt.)
3. **App-Group-Identifier `"group.com.barto.motioncore"` 4× als String-Literal** — in `IdleView`, `StreakComplication`, `WeeklyProgressComplication` und `WatchComplicationService` dupliziert (alle 4 Stellen 1:1 verifiziert). Tippfehler-Bug-Falle. Betrifft 1 Finding, hängt mit dem `IdleView`-Re-Render-Finding zusammen.
4. **WatchBridge-Extraktion ohne Konventions-Mitnahme** — die neue Datei nutzt `.exerciseName` statt `.exerciseNameSnapshot`. Betrifft 1 Finding.

### Top 3 Wins (was ist gut gemacht?)
1. **Watch ist alleiniger HealthKit-Workout-Writer, kein Fremd-Persistenz-Zugriff** — `HKWorkoutSession`, `HKLiveWorkoutBuilder` und `requestAuthorization(toShare: [..., HKObjectType.workoutType()])` existieren ausschließlich in `WatchWorkoutManager.swift`. Kein CloudKit-, Supabase- oder SwiftData-`@Model`-Write im gesamten Watch-Target (alle 9 Dateien gelesen). Die Architektur-Regel „Watch is sole HealthKit writer, no direct persistence" wird konsequent eingehalten.
2. **`discardWorkout()` korrekt async** — `WatchWorkoutManager.discardWorkout()` (Zeilen 137–152) wartet `try await builder.endCollection(at:)` ab, bevor `builder.discardWorkout()` aufgerufen wird. Exakt das, was die „Watch Discard Workflow"-Gotcha in CLAUDE.md fordert; `WatchSessionManager.handleHealthLifecycle` ruft es über `await manager?.discardWorkout()` auf (Zeile 254–262).
3. **Rest-Timer-Countdown via Date-Anchor** — `WatchActiveWorkoutView.restView` (Zeile 118) verwendet `Text(timerInterval: Date()...endDate, countsDown: true)` statt `Text(date, style: .timer)`. Genau das in CLAUDE.md geforderte Pattern — kein Aufwärtszählen nach Ablauf, kein sekündlicher Sync nötig. Unverändert sauber.

### Recommendation
Die drei High-Findings clustern alle am `didReceiveMessage`-Design bzw. der Live-Daten-SSoT und sollten zusammen betrachtet werden. Beginne mit `[L1-Watch-002]` (restEndDate-Reset — mechanischer 10-Min-Fix) und `[L1-Watch-003]` (Self-Healing-Race → Geister-Workout in Apple Health — die ernsteste Konsequenz, da fehlerhafte Daten persistiert werden). Danach `[L1-Watch-001]` (Nested ObservableObject): die jüngste Refactoring-Welle hat die Watch-Seite ausgelassen, daher besteht die alte Falle weiter. Die App-Group-Konstante (`[L1-Watch-005]`) zentralisiert vier Duplikate auf einmal und ist Voraussetzung für `[L1-Watch-007]`.

---

## Findings

### [L1-Watch-001] Nested ObservableObject: HR/Kalorien auf der Watch werden nur durch den 1-Hz-Timer aktualisiert

**Severity:** 🟠 High
**Category:** SwiftUI-State
**File:** MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift:64–91
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
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
.frame(maxWidth: .infinity, alignment: .leading)
// ... Kalorien analog via watchSession.workoutManager?.activeCalories (Zeile 83)
```

**Problem:**
`workoutManager` ist `@Published` auf `WatchSessionManager` (Zeile 39), aber `currentHeartRate` / `activeCalories` sind `@Published` auf der **inneren** `WatchWorkoutManager`-Instanz (verifiziert in `WatchWorkoutManager.swift:27–30`). SwiftUI observiert verschachtelte `ObservableObject`s nicht automatisch — nur ein Swap der `workoutManager`-Referenz triggert ein Re-Render. HR-/Kalorien-Updates auf demselben Manager-Objekt erreichen die View nicht direkt. Es funktioniert aktuell nur, weil `liveElapsedSeconds` als `@Published` auf `WatchSessionManager` sekündlich tickt (`startLocalTimer()`, Zeile 318–323) und einen 1-Hz-Re-Render erzwingt, der nebenbei den HR-Wert neu liest.

**Impact:**
- Fällt der lokale Timer aus (z.B. wenn `workoutState != .active`, dann läuft `stopLocalTimer()` — Zeile 133–138), friert die HR-Anzeige ein, obwohl `HKLiveWorkoutBuilder` weiter Werte in `didCollectDataOf` liefert.
- Updates erscheinen bis zu 1 s verzögert; die UI wirkt gegenüber der Apple-Workout-App träge.
- Architektonisch fragil: wer den 1-Hz-Timer künftig optimiert, bricht die HR-Anzeige unbemerkt. Das jüngste ActiveWorkoutView-Refactoring zeigt, dass solche Eingriffe passieren.

**Recommended Correction:**
HR/Kalorien als eigene `@Published`-Properties direkt auf `WatchSessionManager` spiegeln und in `sendHeartbeatUpdate()` (Zeile 332–337) und im `didCollectDataOf`-Pfad aktualisieren. Damit ist die UI-SSoT klar `WatchSessionManager`, und `WatchWorkoutManager` bleibt ein interner Datenproduzent.

**Concrete Fix:**
```swift
// In WatchSessionManager: HR/Kalorien als eigene @Published spiegeln
@Published private(set) var liveCurrentHR: Double = 0
@Published private(set) var liveActiveCalories: Double = 0

private func sendHeartbeatUpdate() {
    guard let manager = workoutManager else { return }
    self.liveCurrentHR = manager.currentHeartRate        // UI-Mirror
    self.liveActiveCalories = manager.activeCalories
    var snapshot = manager.currentSnapshot()
    snapshot[WatchHealthKey.healthUpdate] = true
    sendSnapshotToPhone(snapshot)
}

// In WatchActiveWorkoutView: direkt aus WatchSessionManager lesen
let hr = watchSession.liveCurrentHR
let cal = watchSession.liveActiveCalories
```

**Effort:** ~30 min
**Risk:** Low
**Discussion Wanted:** Yes
**Discussion Reason:** Mirroring im 5-s-Heartbeat reicht nicht für flüssige HR-Anzeige — der Mirror muss zusätzlich ins `didCollectDataOf`-Delegate (das pro HR-Sample feuert). Alternative: `WatchWorkoutManager` direkt als zweiten `@EnvironmentObject` in die View hängen — charmant, bricht aber die aktuelle Kapselung (View kennt die Manager-Existenz nicht). Bartosz entscheidet, welche Variante zur Watch-SSoT-Konvention passt.

---

### [L1-Watch-002] `restEndDate` wird durch jede Lifecycle-Message auf nil zurückgesetzt

**Severity:** 🟠 High
**Category:** WCSession-Kommunikation
**File:** MotionCoreWatch Watch App/Services/WatchSessionManager.swift:122–131
**Related Findings:** [L1-Watch-004]
**Touches Locked Area:** No

**Location:**
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
Lifecycle-Messages vom iPhone (`sendStartHealthTracking`, `sendStopHealthTracking`, `sendPauseHealthTracking`, `sendResumeHealthTracking`, `sendExerciseTransition`, `sendRequestSnapshot`, `sendHeartbeatEnabled`) enthalten weder `WatchStateKey.isResting` noch `restEndDate` (verifiziert in `PhoneSessionManager.sendLifecycleMessage`, Zeile 251–261 — die Payloads tragen nur den jeweiligen Lifecycle-Key). Der `else if`-Branch wertet aber `message[...isResting] as? Bool ?? false` aus: fehlender Key → `false` → `!false == true` → `self.restEndDate = nil`. Jede Lifecycle-Nachricht löscht damit den laufenden Rest-Countdown, obwohl iPhone-seitig der Timer weiterläuft.

**Impact:**
- Konkretes Szenario: User schließt einen Satz ab → `ActiveWorkoutView` ruft `PhoneSessionManager.shared.sendRequestSnapshot()` (verifiziert: `.onReceive(setManager.setCompleted)`, Zeile 221) → diese Lifecycle-Message löscht auf der Watch `restEndDate`. Wird der Countdown erst durch das nachfolgende `watchBridge.sendState()` (`.onChange(of: session.completedSets)`, Zeile 254–259) wiederhergestellt, springt die Watch-UI dazwischen in `if watchSession.isResting, let endDate = watchSession.restEndDate` (View Zeile 36) zurück auf `workoutView` und wieder zur `restView` → sichtbares Flackern. (Die relative Reihenfolge von `setCompleted` und `completedSets` ist SwiftUI-seitig nicht garantiert; der Reset-Bug besteht unabhängig davon.)
- Bei Pause während eines laufenden Rest-Timers verliert die Watch den Countdown bis zum nächsten State-Update.
- WCSession ist pro Counterpart zwar geordnet, aber `sendRequestSnapshot` und `sendState` sind zwei separate Sends — jede Reihenfolge erzeugt ein temporäres Geisterbild.

**Recommended Correction:**
Lifecycle-State und View-State strikt trennen: `restEndDate`/`isResting` nur dann anfassen, wenn die Message tatsächlich ein State-Update ist. Heuristik: ist `WatchStateKey.workoutState` in der Message vorhanden, ist es eine State-Message — sonst Lifecycle (State-Messages tragen diesen Key immer, Lifecycle-Messages nie).

**Concrete Fix:**
```swift
// Rest-Timer-State NUR aus State-Messages auslesen
let isStateMessage = message[WatchStateKey.workoutState] != nil
if isStateMessage {
    self.isResting = message[WatchStateKey.isResting] as? Bool ?? false
    if let endInterval = message[WatchStateKey.restEndDate] as? TimeInterval {
        self.restEndDate = Date(timeIntervalSinceReferenceDate: endInterval)
    } else {
        // State-Message ohne restEndDate → Timer beendet/nicht aktiv
        self.restEndDate = nil
    }
}
// Lifecycle-Messages (ohne workoutState-Key) verändern restEndDate/isResting NICHT
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** No

---

### [L1-Watch-003] Self-Healing kann nach Discard ein Geister-HKWorkout in Apple Health schreiben

**Severity:** 🟠 High
**Category:** Lifecycle-Management
**File:** MotionCoreWatch Watch App/Services/WatchSessionManager.swift:143–175
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
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
        // ... startet neue HKWorkoutSession
    }
}
```

**Problem:**
Der `isStoppingNow`-Guard greift nur in derselben Message. Sobald die Stop/Discard-Nachricht verarbeitet ist, ist `workoutManager == nil`, während `workoutState` noch `.active`/`.paused` ist (der Idle-State kommt vom iPhone als separater `sendIdleState()`-Aufruf — verifiziert: `ActiveWorkoutView.onDisappear`, Zeile 321). Trifft zwischen Stop/Discard und Idle eine weitere Message ein (z.B. ein verspäteter State-Push oder ein onChange-getriggertes `watchBridge.sendState()`), ist `isStoppingNow == false`, alle Guards sind erfüllt, und Self-Healing startet eine brandneue HKWorkoutSession unmittelbar nach dem Discard.

**Impact:**
- Persistierte Fehl-Daten: User verwirft ein Training bewusst → Watch startet ~1 s später unsichtbar ein neues HKWorkout. Wird es nicht erneut verworfen (kein weiteres Discard kommt, da das iPhone den Discard schon abgeschlossen hat), landet es als Geister-Workout in Apple Health. Das ist eine fehlerhafte Persistenz, kein reiner UI-Glitch — daher High.
- In `ActiveWorkoutView.onDisappear` folgt `sendIdleState()` (Zeile 321) zwar; aber `discardHealthTracking` wird im Cancel-Flow gesendet, und onChange-getriggerte `watchBridge.sendState()`-Pushes (Zeile 252/259/273/289) können dazwischen liegen.
- Das Race-Window ist schmal, da WCSession pro Counterpart ordnet — aber bei schneller Send-Folge nicht ausgeschlossen.

**Recommended Correction:**
Self-Healing nicht nur per `isStoppingNow` in der aktuellen Message blockieren, sondern durch ein persistentes `isTearingDown`-Flag, das nach Stop/Discard aktiv bleibt, bis `.idle` ankommt. Alternativ: iPhone sendet Discard und Idle in einer kombinierten Message, sodass `workoutState == .idle` direkt mit dem Stop-Signal eintrifft — beseitigt das Race-Window vollständig, ändert aber das Protokoll.

**Concrete Fix:**
```swift
// Privates Flag, das Self-Healing nach Stop/Discard blockt bis Idle ankommt
private var isTearingDown = false

// In handleHealthLifecycle bei stop/discardHealthTracking:
self.isTearingDown = true

// Self-Healing-Guard erweitern:
if self.workoutState != .idle
   && self.workoutManager == nil
   && !isStoppingNow
   && !self.isTearingDown {        // ← neu
    // ... Self-Healing wie bisher
}

// Bei Eintritt in .idle Flag zurücksetzen (bestehender if-Block Zeile 178):
if self.workoutState == .idle {
    self.isTearingDown = false
    self.liveElapsedSeconds = 0
}
```

**Effort:** ~15 min
**Risk:** Medium
**Discussion Wanted:** Yes
**Discussion Reason:** Race-Window ist in der Praxis schmal, kein User-Report bekannt — die Severity-Einstufung als High beruht auf der Konsequenz (persistiertes Health-Workout), nicht auf der Häufigkeit. Trade-off: Flag fügt State hinzu; die alternative iPhone-Kombi-Message (Discard+Idle in einem Send) wäre eleganter, ändert aber das Protokoll auf beiden Targets. Bartosz' Entscheidung, welche Strategie zur Watch-Konvention passt.

---

### [L1-Watch-004] Reply-Variante von `didReceiveMessage` verarbeitet ausschließlich `requestSnapshot`

**Severity:** 🟡 Medium
**Category:** WCSession-Kommunikation
**File:** MotionCoreWatch Watch App/Services/WatchSessionManager.swift:184–205
**Related Findings:** [L1-Watch-002]
**Touches Locked Area:** No

**Location:**
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
Die Reply-Variante behandelt nur `requestSnapshot`. Jede andere `sendMessage(..., replyHandler:)`-Nachricht (z.B. ein künftiges „iPhone wartet auf Watch-ACK") wird mit leerem Reply quittiert, aber inhaltlich verworfen — keine State- oder Lifecycle-Verarbeitung. Aktuell sendet das iPhone Lifecycle/State über die No-Reply-Variante (`PhoneSessionManager` nutzt durchgängig `replyHandler: nil`), also funktional korrekt. Es ist aber eine stille Architekturfalle: kein Crash, kein Log.

**Impact:**
- Erweiterungen mit ACK-Semantik scheitern lautlos.
- Symmetrie-Bruch: die No-Reply-Variante verarbeitet `requestSnapshot` ebenfalls (Zeile 280–289, fire-and-forget). Doppelte Pfade für denselben Key sind eine Wartungsfalle — wer pflegt welchen, wenn sich die Snapshot-Logik ändert?

**Recommended Correction:**
Reply-Variante an die No-Reply-Variante delegieren und am Ende `replyHandler([:])` aufrufen — außer bei `requestSnapshot`, das eine echte Antwort braucht. Damit existiert nur ein Lifecycle-Pfad.

**Concrete Fix:**
```swift
func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    if message[WatchWorkoutLifecycleKey.requestSnapshot] != nil {
        DispatchQueue.main.async { [weak self] in
            guard let self, let manager = self.workoutManager else { replyHandler([:]); return }
            var combined = manager.currentSnapshot()
            let exerciseSnap = manager.exerciseSnapshot()
            for (key, value) in exerciseSnap { combined[key] = value }
            combined[WatchExerciseSnapshotKey.exerciseSnapshot] = true
            replyHandler(combined)
        }
        return
    }
    // Alle anderen Messages über den bestehenden No-Reply-Pfad verarbeiten
    self.session(session, didReceiveMessage: message)
    replyHandler([:])
}
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** No

---

### [L1-Watch-005] App-Group-Identifier `"group.com.barto.motioncore"` 4× als String-Literal verstreut

**Severity:** 🟡 Medium
**Category:** Wartbarkeit
**File:** mehrere Stellen (Liste unten)
**Related Findings:** [L1-Watch-007]
**Touches Locked Area:** No

**Location:**
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
Der App-Group-Identifier ist an vier Stellen als String-Literal dupliziert (alle vier 1:1 aus den Dateien verifiziert). Ein Tippfehler in einem Vorkommen führt zu `UserDefaults(suiteName:)` mit `nil`-Rückgabe — Reads/Writes verschieben sich stumm in den Standard-Container, ohne Compiler-Warnung. Auffällig: für `WatchComplicationKey` existiert bereits eine zentrale Enum in `WatchMessageKeys.swift` (Shared-File), aber der App-Group-String wurde dort nicht aufgenommen.

**Impact:**
- Tippfehler-Bug-Falle bei jeder Identifier-Änderung (Multi-Build-Configs für TestFlight/Beta).
- Complications lesen leere Daten, `IdleView` zeigt 0/0 — ohne ersichtlichen Fehler.
- Inkonsistenz zur bereits etablierten zentralen Key-Disziplin in `WatchMessageKeys.swift`.

**Recommended Correction:**
Eine `WatchAppGroup`-Enum in `WatchMessageKeys.swift` (in beiden Targets verfügbar) ergänzen und an allen vier Stellen referenzieren, plus optional einen `defaults`-Convenience-Accessor.

**Concrete Fix:**
```swift
// In WatchMessageKeys.swift ergänzen:
enum WatchAppGroup {
    static let identifier = "group.com.barto.motioncore"
    static var defaults: UserDefaults? { UserDefaults(suiteName: identifier) }
}

// IdleView.swift / StreakComplication.swift / WeeklyProgressComplication.swift:
private var sharedDefaults: UserDefaults? { WatchAppGroup.defaults }

// WatchComplicationService.swift:
private static let appGroup = WatchAppGroup.identifier
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** No

---

### [L1-Watch-006] `WatchBridge` nutzt `.exerciseName` statt `.exerciseNameSnapshot`

**Severity:** 🟡 Medium
**Category:** Projekt-Konvention
**File:** Views/Workouts/Active/ViewModel/WatchBridge.swift:73
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
```swift
let exIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? 0
let currentExName = grouped[safe: exIdx]?.first?.exerciseName ?? ""
let completedInGroup = grouped[safe: exIdx]?.filter { $0.isCompleted }.count ?? 0
let totalInGroup = grouped[safe: exIdx]?.count ?? 0
```

**Problem:**
CLAUDE.md fordert explizit: *„Prefer `ExerciseSet.exerciseNameSnapshot` over `.exerciseName`"*. `WatchBridge.sendState()` liest `.exerciseName` ohne Snapshot-Fallback. Der kanonische Fallback-Pattern existiert im Modell selbst (z.B. `ExerciseSet.primaryMuscleGroup`, Zeile 159: `exerciseNameSnapshot.isEmpty ? exerciseName : exerciseNameSnapshot`), wurde beim Extrahieren aus dem ActiveWorkoutView-Monolithen aber nicht mitgenommen.

**Impact:**
- Wird die referenzierte `Exercise` umbenannt/gelöscht (z.B. nach Plan-Update), zeigt die Watch den neuen Namen statt des historischen Snapshots — inkonsistent zum Rest der App.
- Bei lookup-basierter `exerciseName`-Resolution kann ein leerer String entstehen, der im Watch-UI als „–" erscheint (`WatchActiveWorkoutView:53`).

**Recommended Correction:**
Snapshot bevorzugen, `exerciseName` nur als Fallback — denselben Pattern wie im Modell.

**Concrete Fix:**
```swift
let exIdx = grouped.firstIndex(where: { $0.first?.groupKey == currentKey }) ?? 0
let firstSet = grouped[safe: exIdx]?.first
let currentExName = firstSet.map { $0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot } ?? ""
let completedInGroup = grouped[safe: exIdx]?.filter { $0.isCompleted }.count ?? 0
let totalInGroup = grouped[safe: exIdx]?.count ?? 0
```

**Effort:** <5 min
**Risk:** Low
**Discussion Wanted:** No

---

### [L1-Watch-007] `IdleView` re-rendert nicht, wenn Complications-UserDefaults extern aktualisiert werden

**Severity:** 🟡 Medium
**Category:** SwiftUI-State
**File:** MotionCoreWatch Watch App/Views/IdleView.swift:17–33
**Related Findings:** [L1-Watch-005]
**Touches Locked Area:** No

**Location:**
```swift
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
```

**Problem:**
`IdleView` liest die Werte über computed properties direkt aus `UserDefaults(suiteName:)`. Wenn iPhone-Code (`WatchComplicationService.updateComplications`) die Defaults aktualisiert, während die Watch-App läuft, gibt es keinen `objectWillChange`-Trigger. Ein Re-Render passiert nur, wenn die View neu erscheint oder ein anderer State-Wechsel sie ohnehin neu rendert (z.B. `WatchBaseView` wechselt von `WatchActiveWorkoutView` zurück zu `IdleView`).

**Impact:**
- User schließt iPhone-Workout ab, schaut auf die Watch — Streak zeigt den alten Wert, bis die Watch-App in den Hintergrund und zurück geht.
- Schwer reproduzierbar, weil typische Watch-Nutzung das App-Lifecycle ohnehin aktiviert (Activation = neuer Render). Daher Medium, nicht High.

**Recommended Correction:**
`@AppStorage` mit App-Group-Suite — bindet UserDefaults an SwiftUI-State und triggert View-Updates bei externen Änderungen. Setzt die zentrale `WatchAppGroup.defaults`-Konstante aus `[L1-Watch-005]` voraus.

**Concrete Fix:**
```swift
@AppStorage(WatchComplicationKey.streakCount, store: WatchAppGroup.defaults)
private var streakCount: Int = 0

@AppStorage(WatchComplicationKey.weeklyWorkoutCount, store: WatchAppGroup.defaults)
private var weeklyCount: Int = 0

@AppStorage(WatchComplicationKey.weeklyWorkoutGoal, store: WatchAppGroup.defaults)
private var weeklyGoalRaw: Int = 0

private var weeklyGoal: Int { weeklyGoalRaw > 0 ? weeklyGoalRaw : 5 }
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** No

---

### [L1-Watch-008] Watch-Buttons (`completeSet`, `pauseResume`) ohne Doppelklick-Sicherung

**Severity:** 🔵 Low
**Category:** UI-Robustheit
**File:** MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift:26–34, 96–106
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
```swift
Button {
    watchSession.sendAction(.pauseResume)
} label: {
    Image(systemName: watchSession.workoutState == .paused ? "play.fill" : "pause.fill")
        .font(.caption)
}
.buttonStyle(.plain)
.foregroundStyle(watchSession.workoutState == .paused ? Color.orange : .secondary)
// ... completeSet-Button (Zeile 96–106) analog fire-and-forget
```

**Problem:**
`sendAction(...)` ist fire-and-forget (`replyHandler: nil`, `WatchSessionManager.swift:82`). Der Round-Trip Watch → iPhone → onChange → Watch dauert typischerweise 200–400 ms. In dieser Zeit kann der User erneut tippen. Zwei `pauseResume`-Actions togglen zweimal (User landet im Ausgangszustand). Zwei `completeSet`-Actions sind zwar iPhone-seitig defensiv abgefangen (`WatchBridge.handleAction(.completeSet)` sucht `first { !$0.isCompleted }`, Zeile 109–115 — schließt nichts ab wenn kein offener Satz übrig ist), aber der `pauseResume`-Doppel-Toggle bleibt sichtbar.

**Impact:**
- Nicht-deterministisches Pause-Verhalten bei nervösen Tappern — der Pausen-State auf dem iPhone passt bis zum nächsten onChange nicht zum Watch-State.
- Auf der Watch besonders unschön, weil der User den State-Sync nicht sieht und glaubt, der erste Tap sei nicht angekommen.

**Recommended Correction:**
Kurzes Debouncing per `@State`-Boolean — Buttons für ~500 ms nach Tap deaktivieren.

**Concrete Fix:**
```swift
@State private var isActionLocked = false

private func guardedAction(_ action: WatchAction) {
    guard !isActionLocked else { return }
    isActionLocked = true
    watchSession.sendAction(action)
    Task {
        try? await Task.sleep(for: .milliseconds(500))
        isActionLocked = false
    }
}
// Button-Aktionen: guardedAction(.pauseResume) / guardedAction(.completeSet)
// und .disabled(isActionLocked) an beiden Buttons
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** Yes
**Discussion Reason:** Doppelklicks sind in der Praxis selten; das Lock fügt minimale Komplexität hinzu. Bartosz' Entscheidung, ob die Robustheit den Aufwand rechtfertigt.

---

### [L1-Watch-009] `didCollectDataOf` legt bei jeder HR-Probe neue `HKQuantityType`-Instanzen an

**Severity:** 🔵 Low
**Category:** Performance
**File:** MotionCoreWatch Watch App/Services/WatchWorkoutManager.swift:246–283
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
```swift
func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        // Herzfrequenz auslesen
        if collectedTypes.contains(HKQuantityType(.heartRate)) {
            let hrType = HKQuantityType(.heartRate)
            let hrUnit = HKUnit.count().unitDivided(by: .minute())
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
Beide `contains(...)`-Checks legen pro Aufruf neue `HKQuantityType`-Instanzen an, nur um auf Identität zu prüfen, plus `hrUnit` wird jedes Mal neu konstruiert. Mikrooptimierung — `HKQuantityType` ist günstig, aber bei einer HR-Probe pro Sekunde sind das über ein 60-Min-Workout viele unnötige Allokationen auf dem MainActor.

**Impact:**
- Mikroskopischer Energieverbrauch auf der Watch, praktisch nicht messbar.
- Lesbarkeit: typische „Apple-Sample-Code"-Struktur; das Caching der HK-Typen ist die etablierte Best Practice.

**Recommended Correction:**
HK-Quantity-Types und die HR-Unit als `private let` cachen. Reine Stilverbesserung, kein Verhalten ändert sich.

**Concrete Fix:**
```swift
// MARK: - Private Properties (ergänzen)
private let hrType  = HKQuantityType(.heartRate)
private let calType = HKQuantityType(.activeEnergyBurned)
private let hrUnit  = HKUnit.count().unitDivided(by: .minute())

// didCollectDataOf: self.hrType / self.calType / self.hrUnit verwenden statt neu zu allozieren
```

**Effort:** ~10 min
**Risk:** Low
**Discussion Wanted:** No

---

### [L1-Watch-010] `WatchSessionManager.shared` als `@StateObject` am App-Entry

**Severity:** 🔵 Low
**Category:** SwiftUI-State / Lifecycle
**File:** MotionCoreWatch Watch App/MotionCoreWatchApp.swift:19
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
```swift
@main
struct MotionCoreWatchApp: App {

    // WatchSessionManager beim App-Start initialisieren
    @StateObject private var watchSession = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchBaseView()
                .environmentObject(watchSession)
        }
    }
}
```

**Problem:**
`WatchSessionManager.shared` ist ein Singleton, wird aber zusätzlich als `@StateObject` gehalten. `@StateObject` ist für view-eigene Objekte gedacht; ein Singleton lebt davon unabhängig. Auf der Watch ist der App-Lifecycle aggressiver als auf iOS, und `WatchSessionManager` hält aktive `Timer` (`heartbeatTimer`, `localTimer`) sowie über `workoutManager` eine HealthKit-Session. Ein expliziter Teardown beim Szenen-Suspend existiert nicht; das Singleton-Pattern verhindert hier aber Doppel-Init, sodass es funktional korrekt ist.

**Impact:**
- Kein akuter Bug — `@StateObject` mit Singleton ist gängig und stabil (Single-Init garantiert).
- Konzeptuelle Unschärfe: `@StateObject` suggeriert View-Ownership, die nicht existiert.
- Die Timer werden nie zentral invalidiert, wenn die App suspendet — für den aktuellen Single-Scene-Aufbau unkritisch, das System pausiert die Timer.

**Recommended Correction:**
Keine zwingende Änderung. Für ein App-Level-`App`-Struct ist `@StateObject` die sicherste Wahl (schützt vor Re-Init). Belassen, optional einen Kommentar zur Intention ergänzen.

**Concrete Fix:**
```swift
// Rein dokumentierend — Verhalten unverändert:
// @StateObject bewusst gewählt: garantiert Single-Init des Singletons am App-Entry.
// Timer-Teardown erfolgt über die Idle-Transition in didReceiveMessage.
@StateObject private var watchSession = WatchSessionManager.shared
```

**Effort:** <5 min
**Risk:** Low
**Discussion Wanted:** Yes
**Discussion Reason:** `@StateObject` vs. `@ObservedObject` für ein Watch-Singleton ist eine Konventionsfrage. Beide funktionieren. Falls eine projektweite Watch-Konvention festgelegt werden soll, hier entscheiden.

---

### [L1-Watch-011] Complications aktualisieren nur einmal täglich (Mitternacht)

**Severity:** ⚪ Info
**Category:** Complications-Lifecycle
**File:** MotionCoreWatch Watch App/Complications/StreakComplication.swift:39–43 + WeeklyProgressComplication.swift:40–44
**Related Findings:** —
**Touches Locked Area:** No

**Location:**
```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    // Täglich um Mitternacht neu laden
    let nextUpdate = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
    completion(Timeline(entries: [makeEntry()], policy: .after(nextUpdate)))
}
```

**Problem:**
Beide Complication-Timelines laden nur einmal täglich um Mitternacht neu. `WatchComplicationService.updateComplications` ruft zwar `WidgetCenter.shared.reloadTimelines(...)` auf (Zeile 42–43) — das wirkt aber nur, wenn das System die Reload-Anfrage an die Watch weiterleitet (App-Group-Reloads sind zuverlässig, aber nicht garantiert). Die Datenquelle ist App-Group-UserDefaults (nicht eine Live-Query), was dem Watch-Complication-Pattern entspricht und korrekt ist.

**Impact:**
- Nach iPhone-Workout sieht der User die aktualisierte Streak ggf. erst beim nächsten Reload.
- Apple empfiehlt, `reloadTimelines` sparsam aufzurufen (Budget). Aktuelles Verhalten ist konsistent mit Best Practices.
- Reine Beobachtung — kein Handlungsbedarf.

**Recommended Correction:**
Keine. Aktuelles Verhalten ist konventionskonform. Der bestehende `reloadTimelines`-Aufruf nach `updateComplications` deckt den Workout-Abschluss-Fall ab; eine kürzere `.after`-Policy nur erwägen, wenn der Lag real beanstandet wird.

**Concrete Fix:**
N/A — Info-Finding.

**Effort:** —
**Risk:** —
**Discussion Wanted:** No

---

## Observations for other layers

Aus dem Watch-Scope aufgefallen, gehört aber NICHT in L1-Watch:

- **`ActiveWorkoutView.swift` ist der Watch-Bridge-Treiber, aber L2-Scope** — die Datei verdrahtet `watchBridge.sendState()` in mehreren onChange-Handlern (Zeilen 252, 259, 273, 289) und steuert den Lifecycle (`sendStartHealthTracking`/`sendHeartbeatEnabled` Zeile 208–212, `sendRequestSnapshot` Zeile 221, `sendExerciseTransition` Zeile 277, `sendIdleState` Zeile 321). Diese Aufrufer-Logik wurde gelesen und zur Verifikation der Watch-Findings genutzt, aber strukturelle Bewertung der View gehört in ein L2-View-Review. Auffällig: `watchBridge.sendState()` wird bei jedem `completedSets`-Change zusätzlich zu `sendRequestSnapshot()` gefeuert — die Wechselwirkung mit `[L1-Watch-002]` (Lifecycle-Message löscht restEndDate) sollte beim L2-Review mitbedacht werden.
- **`requestFinalSnapshot` (3-s-Timeout) lebt in `PhoneSessionManager`, ist aber View-relevant** — falls L2 den `finishWorkout`-Flow aufschnürt, sollte diese Kopplung (Zeile 179–238) bedacht werden.
- **`Array[safe:]`-Subscript dupliziert** — `WatchBridge.swift:145–149` definiert ein eigenes `private extension Array { subscript(safe:) }`. Falls projektweit bereits ein `[safe:]`-Helper existiert (sehr wahrscheinlich), ist das eine Duplikat-Definition. Gehört in ein L2/Utils-Review.
- **HealthKit-Read-Auth-Redundanz** — `WatchWorkoutManager.requestAuthorization()` (Zeile 53–75) fordert `.heartRate`/`.activeEnergyBurned`/`workoutType` an; die iPhone-seitige `HealthKitManager`-Auth wurde nicht reviewed, könnte redundant sein. Gehört in L1-iPhone-Health.

---

## Statistics

- Files read: 14 (9 Watch-Target + 4 Bridge/Shared + ActiveWorkoutView-Auszüge + ExerciseSet zur Konventionsprüfung)
- Lines examined (total): ~1.250
- Findings per 1,000 lines: ~8.8
- Reviewer runtime: ~25 min

## Next Steps

For `motioncore-developer`:
- **Recommended fix order:** L1-Watch-002 (restEndDate-Reset) → L1-Watch-003 (Self-Healing-Guard, Geister-Workout) → L1-Watch-006 (exerciseNameSnapshot) → L1-Watch-005 (App-Group-Konstante) → L1-Watch-007 (AppStorage, braucht L1-Watch-005) → L1-Watch-004 (Reply-Delegate delegieren) → L1-Watch-001 (Live-Daten-SSoT) → L1-Watch-009 (HK-Typ-Cache) → L1-Watch-008 (Doppelklick-Lock) → L1-Watch-010 (StateObject-Doku)
- **Clusters to fix together:**
  - **Cluster A — App-Group-Hygiene:** L1-Watch-005 + L1-Watch-007 (AppStorage braucht zentralisierten Suite-Namen)
  - **Cluster B — Lifecycle/State-Robustheit:** L1-Watch-002 + L1-Watch-003 + L1-Watch-004 (alle am `didReceiveMessage`-Design)
- **Findings that need manual testing:** L1-Watch-001 (HR-Anzeige bei Pause/Timer-Ausfall), L1-Watch-002 (Rest-Timer-Flicker beim Satz-Abschluss), L1-Watch-003 (Discard direkt vor State-Push → Geister-Workout in Apple Health), L1-Watch-008 (schnelle Doppel-Taps)

For Bartosz (discussion):
- **Issues mit „Discussion Wanted: Yes":** L1-Watch-001, L1-Watch-003, L1-Watch-008, L1-Watch-010
