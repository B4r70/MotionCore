# Watch-Discard wird trotzdem in Apple Health gespeichert

**Komplexität:** Large · **Steps:** 9 · **Modus:** Phasen (STOPP-Gates nach Phase A, B, C) · **Sprache:** Plan DE, Code EN

> Erstellt 2026-05-29 via motioncore-planner. Ungeprüft durch Reviewer (advisor war überlastet), aber vollständig auf gelesenen Code gestützt. Open Questions 1+2 vor Umsetzung klären.

## Summary

Ein verworfenes Krafttraining landet trotzdem in Apple Health/Fitness. Ursache: zwei sich verstärkende Defekte: (1) Discard/Stop werden als fire-and-forget `sendMessage` gesendet und beim nicht-erreichbaren Watch-Ziel stumm verworfen; (2) die verwaiste, weiterlaufende `HKWorkoutSession` wird ~20 min später beim App-Kill durch den watchOS-HealthKit-Daemon automatisch gespeichert. Fix: garantierte Zustellung (`sendMessage` für Speed + `transferUserInfo` als garantierter Fallback) plus `updateApplicationContext`-„Desired-State" für Reconcile-on-Wake. Auto-Save-Fenster wird minimiert, client-seitig nicht zu 100 % schließbar.

## Scope

**Included**
- Garantierte Discard/Stop-Zustellung: `sendMessage` (sofort, falls reachable) + `transferUserInfo` (garantiert, FIFO, Background)
- `updateApplicationContext` als „Desired-Health-State"-Kanal (idle/active/discarded) für Reconciliation
- Watch-seitiger `didReceiveUserInfo` + `didReceiveApplicationContext`-Handler, beide idempotent
- Reconcile-on-Watch-Launch/Foreground: verwaiste `HKWorkoutSession` erkennen und verwerfen
- `HKWorkoutSession` Recovery-Handling (`recoverActiveWorkoutSession`) — Entscheidung Open Question 1
- Inverser Bug: `sendStopHealthTracking`-Drop bei Unreachable (legitimer Finish geht sonst verloren)
- Orphan-Pfad `handlePausedExit()`: Cleanup beim X-Schließen im pausierten Zustand
- `onDisappear`-Reconnect-Lücke (`onWatchBecameReachable = nil`)
- `isTearingDown`-Reset bei `workoutState == .idle`
- Idempotenz-Guards in `handleHealthLifecycle`
- Neue Message-Keys (Synchronized-File-Group-Membership beachten)

**Excluded**
- HealthKit-Writer aufs iPhone verlagern (verstößt gegen „Watch ist alleiniger HealthKit-Writer")
- 100%-Garantie gegen watchOS-Auto-Save bei nie aufwachender Watch (client-seitig unmöglich)
- Schema-/CloudKit-Änderungen
- Refactor der Snapshot-/Heartbeat-Pfade über das Nötige hinaus

## Betroffene Dateien

| Datei | Aktion |
|-------|--------|
| `MotionCore/Services/Watch/PhoneSessionManager.swift` | `sendGuaranteedLifecycle()` (sendMessage + transferUserInfo); `updateApplicationContext` Desired-State |
| `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` | `didReceiveUserInfo` + `didReceiveApplicationContext`; `handleHealthLifecycle` idempotent; `isTearingDown`-Reset bei `.idle`; Reconcile; Desired-State cachen |
| `MotionCoreWatch Watch App/Services/WatchWorkoutManager.swift` | optional `recoverActiveWorkoutSession`; discard/end defensiv idempotent (nil-Guards bestehen) |
| `MotionCoreWatch Watch App/MotionCoreWatchApp.swift` | `scenePhase`-`onChange(.active)` → Reconcile |
| `MotionCore/Services/Watch/WatchMessageKeys.swift` | neue Keys: `WatchDesiredHealthState` enum **(idle/active/finished/discarded — `finished` ≠ `discarded`, Advisor-Korrektur)**. Synchronized-File-Group → automatisch in MotionCore + Watch + WidgetsExtension, KEINE Duplikat-Datei |
| `MotionCore/Services/Watch/WatchHealthDataTypes.swift` | `lifecycleCommandID`-Key (Lifecycle-Keys liegen hier, NICHT in WatchMessageKeys) |
| `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` | `handlePausedExit()` Cleanup; Discard-Alert-Reihenfolge absichern; onDisappear-Reconnect |

## Zustellstrategie

**Discard/Stop:** (1) `sendMessage` mit errorHandler (sofort falls reachable, kleinstes Auto-Save-Fenster). (2) **Immer zusätzlich** `transferUserInfo` mit `lifecycleCommandID` (garantiert, FIFO, Background). (3) `updateApplicationContext([desiredHealthState: …])` als Reconcile-Anker (immer neuester Wert beim Wake) — Discard setzt `.discarded`, **Finish setzt `.finished`** (NICHT `.idle`!).

**⚠️ Desired-State-Mapping (Advisor-Korrektur — load-bearing):** start → `.active`; Finish/Beenden → `.finished`; Discard/Verwerfen → `.discarded`; kein Workout → `.idle`. `finished` und `discarded` sind getrennte Werte, weil Reconcile sie GEGENSÄTZLICH behandelt (save vs. discard). Ein gedroppter Finish darf nicht als Discard fehlinterpretiert werden.

**Auto-Save-Fenster:** transferUserInfo/applicationContext werden „eventually" zugestellt — evtl. NACH dem watchOS-Auto-Save. Zweite Verteidigungslinie = **Reconcile-on-Launch/Foreground**: Watch wacht auf → „laufende Session bei Desired-State idle/discarded?" → `discardWorkout()`. Restlücke: wacht die Watch nie auf, speichert watchOS (unvermeidbar client-seitig).

**Nicht nur transferUserInfo:** garantiert Zustellung, nicht „vor Auto-Save". applicationContext ist besserer Reconcile-Anker. **Nicht App-Group:** geräte-lokal, kein Cross-Device-Kanal.

## Idempotenz
- Discard bei `workoutManager == nil` → no-op; `discardWorkout()` hat `guard let session, builder`.
- `lifecycleCommandID` (UUID) + bounded `processedCommandIDs`-Set → doppelt empfangener Discard nur 1× ausgeführt.
- Self-Healing-Guard (WatchSessionManager:162) erweitern um `&& lastDesiredHealthState == .active` → verspäteter active-Push reaktiviert verworfene Session nicht.
- `isTearingDown` auch bei `workoutState == .idle` zurücksetzen.

## Reconcile-on-Launch
`MotionCoreWatchApp` scenePhase `.active` → `reconcileHealthStateIfNeeded()`: liest Desired-State (receivedApplicationContext/Cache). **Verzweigt nach Desired-State (Advisor-Korrektur — KEINE gemeinsame Discard-Regel):**
- laufende Session + `.discarded` → `discardWorkout()` (verwerfen)
- laufende Session + `.finished` → `endWorkout()` (SPEICHERN — der Stop wurde gedroppt, der User wollte beenden; NICHT verwerfen!)
- laufende Session + `.active` → laufen lassen (alles korrekt)
- laufende Session + `.idle` (sollte nicht vorkommen) → konservativ: nicht verwerfen (kein stiller Datenverlust); Session in Ruhe lassen / regulären Flow abwarten

HKWorkoutSession-Recovery für App-Neustart-Fall (Step 7, gated hinter Phase-B-Delivery-Probe).

## Defekte: in-scope vs deferred
| Defekt | Entscheidung |
|--------|--------------|
| `sendStopHealthTracking`-Drop (invers) | **In-scope** (gleiche Wurzel) |
| `handlePausedExit()` ohne Cleanup | **Out-of-scope** (OQ2: Pause bleibt nicht-terminal, Kalorien dürfen laufen) |
| `onDisappear` nilt Reconnect-Callback | **In-scope (klein)** |
| `isTearingDown` nie bei `.idle` reset | **In-scope** |
| `sendHeartbeatEnabled(false)`/`sendIdleState()`-Drop | **Deferred** (nicht integritätskritisch) |

## Schritte (phasiert)

### Phase A — Garantierte Zustellung + Keys (iPhone) → STOPP-Gate A
- [x] Step 1 — Keys: `lifecycleCommandID` (WatchHealthDataTypes), `WatchDesiredHealthStateKey` + enum (WatchMessageKeys)
- [x] Step 2 — `sendGuaranteedLifecycle()` in PhoneSessionManager; sendStop/sendDiscard darauf umstellen
- [x] Step 3 — `updateDesiredHealthState(_:)` via updateApplicationContext. Mapping: Start→`.active`, **Finish→`.finished`**, Discard→`.discarded`, kein Workout→`.idle`. **→ Build Cmd+B**

### Phase B — Watch-Empfang + Idempotenz + Reconcile → STOPP-Gate B
- [x] Step 4 — `didReceiveUserInfo` + `didReceiveApplicationContext`; gemeinsame Verarbeitung; Desired-State cachen
- [x] Step 5 — `processedCommandIDs`-Dedup; isTearingDown-Reset bei .idle; Self-Healing-Guard um Desired-State
- [x] Step 6 — `reconcileHealthStateIfNeeded()` (verzweigt nach Desired-State: discarded→discard, finished→save) + scenePhase/activation-Aufruf
- [ ] **Step 6b — DELIVERY-PROBE (Gate, Advisor-Pflicht):** On-Device beweisen, dass `transferUserInfo` bei `isReachable==false` + laufender HKWorkoutSession den `didReceiveUserInfo` im Hintergrund auslöst, OHNE dass der User die Watch-App öffnet. Tragende Annahme: die laufende Session hält die Watch-App ~22 Min im Background am Leben → didReceiveUserInfo feuert. **Ergebnis bestimmt die Gewichtung:** feuert es → transferUserInfo ist Primärmechanismus, Reconcile = Backstop. Feuert es nur im Foreground → Reconcile-on-Wake wird Primär. **Erst nach dieser Probe Step 7 bauen.**
- [ ] Step 7 — HKWorkoutSession-Recovery (gated hinter Step 6b; least-testable, erfordert echten App-Kill mid-session → zuletzt). **→ Build beide Targets**

### Phase C — Orphan-Pfade iPhone → STOPP-Gate C (End-to-End)
- [ ] Step 8 — onDisappear/Discard-Dismiss: nach Verwerfen Desired-State auf `discarded`/`idle` setzen (kein stale `active`). **handlePausedExit NICHT anfassen** (Pause bleibt nicht-terminal, OQ2).
- [ ] Step 9 — Discard-Alert: synchrones `isWatchTrackingActive=false` muss vor `cancelWorkout()` greifen. **→ End-to-End Test-Matrix**

## Manuelle Verifikation
- [ ] Build MotionCore + MotionCoreWatch ohne neue Warnings
- [ ] Discard reachable → kein Fitness-Eintrag
- [ ] Discard unreachable → Watch wecken → Reconcile/transferUserInfo verwirft → kein Eintrag
- [ ] Discard unreachable + lange warten → Restlücke (watchOS Auto-Save) dokumentieren
- [ ] Finish reachable → Eintrag mit korrekten HR/Kalorien
- [ ] Finish unreachable (invers) → nach Wake garantiert gespeichert (kein Datenverlust)
- [ ] Doppelzustellung (sendMessage + transferUserInfo) → genau 1 Discard
- [ ] Self-Healing-Race → keine Reaktivierung
- [ ] Pause → View verlassen → Kalorien laufen weiter (nicht-terminal, kein Discard, kein Save erzwungen)
- [ ] isTearingDown-Deadlock → neues Workout nach Discard startet normal
- [ ] Regressions: Live-HR/Kalorien/Heartbeat/Rest-Timer/Snapshots unverändert

---

## Implementierungs-Fortschritt Phase B

**Datum:** 29.05.2026

**Abgeschlossene Steps:** 4, 5, 6

**Geänderte Dateien:**
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — Private Properties (Desired-State + Idempotenz) ergänzt; `activationDidCompleteWith` seedet `lastDesiredHealthState` aus receivedApplicationContext + ruft reconcile; neue WCSessionDelegate-Methoden `didReceiveUserInfo` + `didReceiveApplicationContext`; `handleHealthLifecycle` um Idempotenz-Guard (processedCommandIDs) ergänzt; Self-Healing-Guard erweitert um `&& lastDesiredHealthState == .active`; `isTearingDown`-Reset bei `.idle`; neue Methode `reconcileHealthStateIfNeeded()` (verzweigt nach discarded/finished/active/idle)
- `MotionCoreWatch Watch App/MotionCoreWatchApp.swift` — `@Environment(\.scenePhase)` + `.onChange(of: scenePhase)` → Reconcile bei `.active`

**Architektur-Entscheidungen:**
- `processedCommandIDs` als `[String]` (nicht Set) für O(n) FIFO-Eviction; gecappt auf 20 Einträge
- `lifecycleCommandID` kommt als `String` (UUID.uuidString) auf dem Draht — PhoneSessionManager:264 verifiziert
- `reconcileHealthStateIfNeeded()` ist `func` (nicht private) — App-Einstiegspunkt muss zugreifen
- `activationDidCompleteWith` dispatcht auf Main für beide State-Mutationen (Advisor-Punkt 2 adressiert)
- `isTearingDown = false` bei `.idle` ergänzt — L1-Watch-003-Schutz wandert auf Desired-State-Guard (Advisor-Punkt 4)

**STOPP-Gate B:** Bitte `Cmd+B` (Watch-Schema) ausführen vor Step 6b (Delivery-Probe).

---

## Implementierungs-Fortschritt Phase A

**Datum:** 29.05.2026

**Abgeschlossene Steps:** 1, 2, 3

**Geänderte Dateien:**
- `MotionCore/Services/Watch/WatchHealthDataTypes.swift` — Z. 43–52: `lifecycleCommandID`-Key in `WatchWorkoutLifecycleKey` ergänzt
- `MotionCore/Services/Watch/WatchMessageKeys.swift` — Z. 59–73: `WatchDesiredHealthStateKey` + `WatchDesiredHealthState` (idle/active/finished/discarded) vor bisherigem `MARK: - App Group UserDefaults Keys` eingefügt
- `MotionCore/Services/Watch/PhoneSessionManager.swift` — Z. 127–149 (sendStart/sendStop/sendDiscard): `updateDesiredHealthState`-Aufrufe ergänzt; sendStop/sendDiscard auf `sendGuaranteedLifecycle` umgestellt; neue Methoden `sendGuaranteedLifecycle` (Z. ~267) + `updateDesiredHealthState` (Z. ~289) hinzugefügt

**Architektur-Hinweis für Phase B:**
- `WatchHealthDataTypes.swift` ist via `membershipExceptions` in MotionCore + MotionCoreWatch eingebunden (ein physisches File, zwei Targets) — `lifecycleCommandID` wird in Phase B auf der Watch-Seite ohne weitere Projekt-Änderungen sichtbar sein
- `WatchDesiredHealthState`-Enum ist via `WatchMessageKeys.swift`-Membership in MotionCore + MotionCoreWatch + WidgetsExtension verfügbar

**STOPP-Gate A:** Bitte `Cmd+B` (iOS-Schema) ausführen vor Phase B.

---

## Open Questions — GEKLÄRT (2026-05-29)
1. **HKWorkoutSession-Recovery:** ✅ **In-scope** (Step 7) — deckt den App-Neustart-Fall ab (genau das beobachtete Szenario).
2. **`handlePausedExit` Discard-Semantik:** ✅ **Pause bleibt nicht-terminal.** Kein Auto-Discard und kein Auto-Save beim Pause-Exit — pausierte Kalorien/Puls sind reale Daten und dürfen weiterlaufen. Step 8 reduziert sich auf den **Discard-Dismiss-Pfad** (kein Cleanup-Eingriff in handlePausedExit). Mentales Modell bestätigt: nur **Beenden** speichert, nur **Verwerfen** verwirft, **Pause** ist nicht terminal.
3. **Restlücke kommunizieren?** ✅ **Nein** (Stille, keine Zusatz-UI).

## Bug-Befund bestätigt (2026-05-29)
- **Ein** fälschlicher Fitness-Eintrag: 18:59 → 19:21 (~22 Min), 164 kcal. Tatsächliches Training ~2–3 Min.
- ⇒ Original-Session lief ~22 Min weiter (Discard nie zugestellt), ~7,5 kcal/min im Workout-Modus = plausibel. **Nicht** die Kalorien-Rate ist kaputt, sondern die **Dauer**. Kein zweites Phantom ⇒ Self-Healing hier nicht beteiligt.

## Load-bearing Code-Verifikationen
- Discard-Drop: `PhoneSessionManager.swift:251-261` (`guard isReachable else return`)
- Save-only-Pfad: `WatchWorkoutManager.endWorkout()` → `finishWorkout()` (Z. 124-135); discard Z. 143-158
- Watch ohne UserInfo/AppContext-Handler: `WatchSessionManager.swift:100-223`; Self-Healing-Guard Z. 162; isTearingDown nur in startHealthTracking reset (Z. 234)
- Lifecycle-Keys in `WatchHealthDataTypes.swift` (nicht WatchMessageKeys)
- handlePausedExit nur `dismiss()`: `ActiveWorkoutView.swift:716-718`; Discard-Alert Z. 336-352; onDisappear nilt onWatchBecameReachable Z. 320
