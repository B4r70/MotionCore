# Watch-App automatisch starten beim Krafttraining-Start (startWatchApp)

**Datum:** 2026-10-04
**Status:** Geplant, noch nicht umgesetzt
**Umsetzung:** zwei Phasen (1: Watch, 2: iPhone), jede Phase einzeln baubar

## Komplexität

**Large.** Begründung:
- 6 Dateien in 2 Targets plus Build-Setting (pbxproj).
- Mehrere Startpfade laufen parallel: `handle(_:)`, die Start-Message, Self-Healing und Reconcile. Sie dürfen nachweisbar nur eine `HKWorkoutSession` erzeugen.
- Neue HealthKit-Berechtigung auf dem iPhone.
- Nur auf echten Geräten testbar.
- Keine Schema-, CloudKit- oder Supabase-Änderung, keine UI-Änderung (darum keine UX-Platzierung).

## Analyse der betroffenen Architektur

**iPhone (Ist)**
- `PhoneSessionManager.sendStartHealthTracking` (`PhoneSessionManager.swift:150-158`):
  - setzt den applicationContext `.active` mit sessionUUID/planName (`:153`),
  - sendet die Lifecycle-Message (`:154`); die wird bei `!isReachable` verworfen (`:319-323`),
  - setzt `isWatchTrackingActive = true`, auch wenn nichts angekommen ist (`:155-157`).
- `updateDesiredHealthState` schreibt nichts, wenn WCSession nicht aktiviert ist (`:307`).
- Stop und Discard schreiben `.finished`/`.discarded` **ohne** sessionUUID in den Context (`:162`, `:171`). Dieser terminale Context bleibt bis zum nächsten Start stehen.
- Aufrufer: `ActiveWorkoutView.swift:229` (onAppear) und `:197` (onWatchBecameReachable, nur wenn `!isWatchTrackingActive`, `:196`).
  - Der Reachability-Callback sendet sonst nur den State (`:200`).
  - Nach einem verworfenen Start wird `sendHeartbeatEnabled(true)` (`:230`) nicht erneut gesendet.
- Nur Krafttraining:
  - `ActiveWorkoutView.swift:681` startet die Session mit `workoutType: .strength`.
  - Die Watch kennt nur `.traditionalStrengthTraining/.indoor` (`WatchWorkoutManager.swift:101-103`).
  - Ob Cardio/Outdoor `PhoneSessionManager` aufrufen, ist **nicht verifiziert** (siehe Schritt 0).
- Bisher gibt es auf dem iPhone weder `startWatchApp` noch eine HealthKit-Write-Berechtigung:
  - `HealthKitManager.requestAuthorization` fordert `toShare: []` an (`HealthKitManager.swift:78`).
  - `healthStore` ist private (`:28`).

**Watch (Ist)**
- Es gibt keinen `WKApplicationDelegate`: `MotionCoreWatchApp.swift:15-35` hat nur `WindowGroup` und `scenePhase`.
- `lastDesiredHealthState` startet mit `.active` (`WatchSessionManager.swift:81`). Den echten Context übernimmt erst `activationDidCompleteWith` in drei Main-Queue-Blöcken (`:147-154`).
- `reconcileHealthStateIfNeeded` (`:482-530`):
  - Bei vorhandenem Manager: `.finished` führt zu `endWorkout()` (`:495-501`), `.discarded` zu `discardWorkout`, `.active` trägt Metadata nach (`:503-509`).
  - Ohne Manager: nur Recovery bei `.discarded` (`:519-529`).
- Startpfade heute:
  - **Self-Healing** (`:221-249`): nur mit State-Message, `workoutManager == nil` und Desired `.active`. Startet den Heartbeat-Timer selbst (`:238`).
  - **Start-Message** (`:335-375`): verwendet eine laufende Session wieder (`:342`). Einen Manager ohne Live-Session verwirft sie und startet neu (`:353-374`).
- **Lücke im Startfenster (betrifft schon den heutigen Code):**
  - `workoutManager` wird synchron gesetzt (`:224`, `:359`).
  - Die `HKWorkoutSession` existiert erst nach `await requestAuthorization`, `hasLiveSession` ist bis zum Zustand running `false` (`WatchWorkoutManager.swift:34-37`, `:112-113`).
  - Kommt in diesem Fenster ein Discard (`:353-357`, `:390-400`), Stop (`:381`) oder terminaler Reconcile, ist `discardWorkout`/`endWorkout` wirkungslos (`WatchWorkoutManager.swift:158`, `:187`). Der ursprüngliche Task startet trotzdem eine **verwaiste Session**.
- Die UI zeigt `IdleView`, bis eine State-Message vom iPhone kommt (`WatchBaseView.swift:20-24`).

**Kernproblem des neuen Pfads: veralteter terminaler Context**
- Beim Launch über `startWatchApp` liegt auf der Watch oft noch `.finished`/`.discarded` vom letzten Workout. Ob das neue `.active` vor oder nach dem Launch ankommt, ist nicht festgelegt.
- Startet `handle(_:)` sofort, beendet Reconcile die frische Session als `.finished`. Das ergibt ein Mini-Workout in Health oder (im Startfenster) eine verwaiste Session.
- **Entscheidung:** `handle(_:)` merkt sich nur die Start-Absicht. Gestartet wird ausschließlich über den Desired-State (wie heute die Autorität laut `:79-81`, `:217-218`) und erst, nachdem der Activation-Context übernommen wurde. Ein später oder doppelt zugestellter Launch bleibt dann wirkungslos, weil der Desired-State bereits terminal ist.

**HealthKit / Plist / Entitlements (Ist)**
- iPhone:
  - HealthKit-Entitlement vorhanden (`MotionCore/MotionCore.entitlements:7-8`).
  - **Nur** `NSHealthShareUsageDescription` (`project.pbxproj:518`, `:565`), **kein** `NSHealthUpdateUsageDescription`.
  - `MotionCore/Info.plist` enthält keine HealthKit-Keys.
- Watch:
  - Entitlement vorhanden (`MotionCoreWatch Watch App.entitlements:5-6`).
  - Share- und Update-Description vorhanden (`project.pbxproj:610-611`, `:650-651`).
  - `WKBackgroundModes` = `workout-processing` (`MotionCoreWatch-Watch-App-Info.plist:7-10`).
  - `WKCompanionAppBundleIdentifier` gesetzt (`:613`).
- Die Watch fordert selbst Share-Rechte für workoutType, HR und Kalorien an (`WatchWorkoutManager.swift:71-84`).
- **Nicht verifiziert:** ob `startWatchApp` eine eigene Workout-Share-Freigabe der iPhone-App braucht oder ob die Freigabe der Watch-App reicht.
- **Sicher:** Jede `toShare`-Anfrage auf dem iPhone ohne `NSHealthUpdateUsageDescription` lässt die App abstürzen.
- Beide Targets nutzen `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (`project.pbxproj:539`, `:626`). Deshalb async-APIs statt Completion-Closures, die außerhalb des Main Threads laufen.

**Abgrenzung**
- Drin: Launch über `HKHealthStore.startWatchApp`, `handle(_:)` auf der Watch, eine gemeinsame Startroutine mit Schutz für das Startfenster, Write-Berechtigung auf dem iPhone.
- Nicht drin:
  - Cardio/Outdoor.
  - `handleActiveWorkoutRecovery()` (Recovery nach Watch-Crash).
  - Die Semantik von `isWatchTrackingActive`: bleibt nach einem gescheiterten Launch `true`, betrifft das Badge `ActiveWorkoutView.swift:139` und den Cancel-Alert `:779-782`.
  - Neue `WatchMessageKeys`.
  - Jede UI-Änderung.
  - Die Auswertung der übergebenen `HKWorkoutConfiguration`: einziger Absender ist die eigene App, und `WatchWorkoutManager` baut eine identische Konfiguration.

## Betroffene Dateien

- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift`: gemeinsame Startroutine, Flags, Launch-Absicht, Reconcile-Start
- `MotionCoreWatch Watch App/WatchAppDelegate.swift` (**neu**): `WKApplicationDelegate.handle(_:)`
- `MotionCoreWatch Watch App/MotionCoreWatchApp.swift`: `@WKApplicationDelegateAdaptor`
- `MotionCore.xcodeproj/project.pbxproj`: `INFOPLIST_KEY_NSHealthUpdateUsageDescription` für das Target MotionCore (Debug + Release)
- `MotionCore/Services/Health/HealthKitManager.swift`: `startWatchWorkoutApp()` mit Write-Berechtigung bei Bedarf und `startWatchApp`
- `MotionCore/Services/Watch/PhoneSessionManager.swift`: Launch-Aufruf in `sendStartHealthTracking`
- Unverändert: `ActiveWorkoutView.swift`, `WatchWorkoutManager.swift`, `WatchMessageKeys.swift`

## Risiken

1. **Veralteter terminaler Context beim Launch.** Folge: Mini-Workout in Health oder verwaiste Session (siehe Analyse).
   Gegenmaßnahme: `handle(_:)` setzt nur `launchStartPending`. Gestartet wird nur aus dem Reconcile-Zweig ohne Manager, und nur wenn der Activation-Context übernommen wurde und Desired `.active` ist (Schritte 4-7). Das frische `.active` erreicht Reconcile über `didReceiveApplicationContext` (`WatchSessionManager.swift:298-309`), ganz ohne Timer.
2. **Doppelte oder verwaiste HKWorkoutSession durch parallele Pfade und das Startfenster.**
   Gegenmaßnahme:
   - eine einzige Startroutine für Message, Self-Healing und Launch,
   - Flag `isStartingWorkout` in der Wiederverwendungsprüfung (`:342`),
   - nach `startWorkout` die Prüfung `self.workoutManager === manager`, sonst eigene Session verwerfen (Schritte 2-3),
   - alle Pfade laufen auf dem Main Thread, prüfen und setzen `workoutManager` also atomar.
   - Auf dem iPhone schließen sich Message und Launch gegenseitig aus: Launch nur bei `!isReachable` (Schritt 12).
3. **Titel/ExternalUUID-Race.**
   Gegenmaßnahme:
   - Auf dem iPhone kommt der Launch strikt nach `updateDesiredHealthState` (`PhoneSessionManager.swift:153`) und nur bei `activationState == .activated`. Sonst wurde der Context nicht geschrieben (`:307`).
   - Auf der Watch wird nach dem Start `desiredSessionUUID` gegen `manager.sessionUUID` geprüft und bei Abweichung `applyMetadata` aufgerufen.
   - Der bestehende Reconcile-Zweig `.active` (`:503-509`, Fix `f0afc8e`) bleibt als zusätzliche Absicherung.
4. **HealthKit-Write-Berechtigung.**
   - Sicher: Ohne `NSHealthUpdateUsageDescription` stürzt `requestAuthorization(toShare:)` ab. Deshalb kommt Schritt 10 vor Schritt 11.
   - Nicht verifiziert: ob die Freigabe auf dem iPhone überhaupt nötig ist.
   - Gegenmaßnahme: nur anfragen, wenn `authorizationStatus(for: .workoutType()) == .notDetermined` (der Status ist für Share-Typen aussagekräftig), und nur bei gepaarter Watch mit installierter App. `startWatchApp` wird auch bei `.sharingDenied` versucht, falls die Freigabe der Watch genügt.
5. **Apple-Verhalten, nicht verifiziert:**
   - Launch bei gesperrter oder abgelegter Watch und außer Reichweite: wird er verworfen oder später nachgeliefert?
   - Startet die App im Vordergrund oder im Hintergrund?
   - Gibt es eine Zeitgrenze, bis `handle(_:)` eine Session starten muss? Falls watchOS eine im Hintergrund gestartete App ohne Session suspendiert, kann das Warten auf das frische `.active` scheitern.
   - Gegenmaßnahme: Fallback wie heute (manuelles Öffnen, dann Self-Healing) und Geräte-Checkliste B/E/F. Ein spät nachgelieferter Launch ist durch Risiko 1 abgesichert.
6. **Watch zeigt nach dem Launch `IdleView`**, bis eine State-Message kommt (`WatchBaseView.swift:20`). Das setzt voraus, dass `sessionReachabilityDidChange` auf dem iPhone auch für eine vom System gestartete Watch-App feuert (`PhoneSessionManager.swift:351-356`). **Nicht verifiziert.**
   Gegenmaßnahme: Gerätetest A. Notfalls schickt das iPhone beim nächsten Ereignis ohnehin den State (`ActiveWorkoutView.swift:272`, `:282`, `:296`).
7. **`recoverAndDiscard()` bei veraltetem `.discarded`** (`WatchSessionManager.swift:521-528`) läuft beim Activation-Reconcile. **Nicht verifiziert:** ob `recoverActiveWorkoutSession()` eine gerade im Prozess gestartete Session zurückgibt. Wahrscheinlichkeit gering, weil Recovery bei der Aktivierung läuft und der Start erst mit dem frischen Context.
   Gegenmaßnahme: Gerätetest C.
8. **Verhaltensänderung im Message-Pfad durch die gemeinsame Startroutine:**
   - Die Watch startet den Heartbeat-Timer selbst. Das ist idempotent (`:442-447`); das iPhone sendet `enableHeartbeat(true)` ohnehin.
   - Bei Auth-Fehler wird abgebrochen statt „ohne HR“ weitergemacht. Praktisch gleich, weil `requestAuthorization` nur bei fehlendem HealthKit oder Exception `false` liefert (`WatchWorkoutManager.swift:68-89`).
   - Bei Fehlschlag `stopLocalTimer`. Die nächste State-Message startet ihn neu (`:205-206`).
9. **Rest-Risiko: hängengebliebene Launch-Absicht.** Ohne Stop/Discard bleibt `launchStartPending` bis zum Prozessende gesetzt. Gestartet wird trotzdem nur bei Desired `.active`. Akzeptiert.
10. **Ungeprüfte Aufrufer** von `sendStartHealthTracking`: Schritt 0.
11. Keine Risiken für Datenmodell, CloudKit oder Supabase.

## Konkrete Umsetzungsschritte

**Schritt 0: Vorprüfung (kein Code)**
- [ ] 0. Suche nach `sendStartHealthTracking(`. Erwartung: nur `ActiveWorkoutView.swift:197`, `:229`. Gibt es Treffer in Cardio/Outdoor, vor der Umsetzung klären.
- [ ] 0b. Suche nach `requestAuthorization(` im iPhone-Target. Damit ist bekannt, wann die bestehende Read-Anfrage läuft; relevant für Offene Frage 1.

**Phase 1: Watch** (ohne Absender wirkungslos, aber Regressionstest des manuellen Ablaufs)
- [ ] 1. `WatchSessionManager.swift`, Abschnitt Desired-State (`:77-106`): drei private Properties anlegen, alle nur auf dem Main Thread benutzt:
  - `isStartingWorkout` (Start läuft),
  - `launchStartPending` (`handle(_:)` empfangen),
  - `isActivationContextApplied` (Activation-Context übernommen).
- [ ] 2. `WatchSessionManager.swift`: Block `:223-248` als `private func startWorkoutSession()` extrahieren. Self-Healing (`:221-222`) ruft nur noch diese Funktion auf. Ablauf:
  - Guard: `workoutManager == nil && !isStartingWorkout`.
  - Manager anlegen und zuweisen, `isStartingWorkout = true`, `launchStartPending = false`.
  - Task: Authorization anfordern. Bei `false`: auf Main `isStartingWorkout = false`, und `workoutManager = nil` nur, wenn `=== manager`.
  - `try await manager.startWorkout(sessionUUID: desiredSessionUUID, planName: desiredPlanName)`.
  - Auf Main: `isStartingWorkout = false`. Ist `workoutManager !== manager`: `await manager.discardWorkout()` und return (der Manager wurde inzwischen ersetzt oder geleert).
  - Weicht `desiredSessionUUID` von `manager.sessionUUID` ab: `applyMetadata` aufrufen.
  - 2 s warten, erneut `=== manager` prüfen, dann `startHeartbeatTimer()` und `sendHeartbeatUpdate()`.
  - Im catch: `isStartingWorkout = false`; bei `=== manager` dann `workoutManager = nil` und `stopLocalTimer()`.
  - Danach bauen.
- [ ] 3. `WatchSessionManager.handleHealthLifecycle`, Start-Zweig (`:335-375`):
  - Bedingung `:342` wird zu `existing.hasLiveSession || isStartingWorkout`. Metadata-Nachtrag und Heartbeat bleiben; `applyMetadata` ist ohne Builder wirkungslos (`WatchWorkoutManager.swift:135`), den Nachtrag übernimmt Schritt 2.
  - Verwerfen eines alten Managers (`:353-357`) bleibt unverändert.
  - `:358-374` durch `startWorkoutSession()` ersetzen.
  - Danach bauen.
- [ ] 4. `WatchSessionManager.activationDidCompleteWith`: im letzten Dispatch-Block (`:154`) vor `reconcileHealthStateIfNeeded()` den Wert `isActivationContextApplied = true` setzen. Durch die FIFO-Reihenfolge der Main-Queue ist `lastDesiredHealthState` dann schon echt.
- [ ] 5. `WatchSessionManager.reconcileHealthStateIfNeeded`, Zweig ohne Manager (`:519-529`): am Ende `if launchStartPending && isActivationContextApplied && lastDesiredHealthState == .active { startWorkoutSession() }`. Kommentar: Launch-Start folgt dem Desired-State, ein veralteter terminaler Context startet nichts.
- [ ] 6. `WatchSessionManager.clearWorkoutMetadata` (`:98-101`): `launchStartPending = false` ergänzen. Wirkt bei Stop, Discard und terminalem Reconcile.
- [ ] 7. `WatchSessionManager`, Extension Health Tracking Lifecycle: neue interne Funktion `handleWorkoutLaunch()`. Sie setzt `launchStartPending = true`, und falls `isActivationContextApplied`, ruft sie `reconcileHealthStateIfNeeded()` auf. Sonst übernimmt das die Aktivierung aus Schritt 4.
- [ ] 8. Neue Datei `MotionCoreWatch Watch App/WatchAppDelegate.swift`:
  - Header aus einer bestehenden Datei kopieren, Imports `WatchKit` und `HealthKit`.
  - `final class WatchAppDelegate: NSObject, WKApplicationDelegate` mit `func handle(_ workoutConfiguration: HKWorkoutConfiguration)`, die nur `WatchSessionManager.shared.handleWorkoutLaunch()` aufruft.
  - Keine Typprüfung (einziger Absender ist die eigene App).
- [ ] 9. `MotionCoreWatchApp.swift`: `import WatchKit` und `@WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate` ergänzen. Watch-Target bauen. Regressionstest: Workout auf dem iPhone starten, Watch-App manuell öffnen, Self-Healing funktioniert wie bisher.

**Phase 2: iPhone**
- [ ] 10. Target MotionCore, Info (oder `project.pbxproj:518` und `:565`): `INFOPLIST_KEY_NSHealthUpdateUsageDescription` für Debug **und** Release. Textvorschlag: „MotionCore startet dein Krafttraining auf der Apple Watch und speichert es als Workout in Apple Health.“ Bauen.
- [ ] 11. `HealthKitManager.swift`: neuer Abschnitt `// MARK: - Watch-Start` mit `func startWatchWorkoutApp() async`:
  - Ist `authorizationStatus(for: HKObjectType.workoutType()) == .notDetermined`: `try await healthStore.requestAuthorization(toShare: [workoutType], read: [])`.
  - `HKWorkoutConfiguration` mit `.traditionalStrengthTraining` und `.indoor`.
  - Die async-Variante von `startWatchApp(with:)` aufrufen (Swift-Namen im SDK prüfen).
  - Fehler nur per `print` loggen (Fallback wie heute).
  - `requestAuthorization()` (`:70-88`) bleibt unverändert.
- [ ] 12. `PhoneSessionManager.sendStartHealthTracking` (`:150-158`): direkt nach `:153` ergänzen:
  - Bedingung: `WCSession.default.activationState == .activated && !isReachable && isPaired && isWatchAppInstalled`, dann `Task { await HealthKitManager.shared.startWatchWorkoutApp() }`.
  - Kommentar: Launch nur, wenn keine Message ankommen kann; der Context ist zu diesem Zeitpunkt bereits geschrieben.
  - `sendLifecycleMessage` und `isWatchTrackingActive` bleiben unverändert.
  - Beide Targets bauen (`Cmd+B`).

## Manuelle Verifikation

- [ ] Xcode-Build (`Cmd+B`) für die Schemes MotionCore und MotionCoreWatch Watch App
- [ ] Alle folgenden Punkte auf echtem iPhone und echter Watch (Simulator nicht aussagekräftig). Die Konsole beider Geräte offen halten; das Log in `WatchWorkoutManager.startWorkout` zeigt jeden Session-Start mit sessionUUID und planName.

- [ ] **A. Grundfall (Watch-App beendet):** Watch-App im App-Switcher beenden, Watch entsperrt am Handgelenk, Workout mit Plan auf dem iPhone starten.
  - Watch-App startet; Vordergrund oder Hintergrund notieren.
  - Genau ein `startWorkout`-Log, HR erscheint auf dem iPhone.
  - Watch wechselt aus `IdleView` in die aktive Ansicht.
- [ ] **B. Neues Workout direkt nach einem beendeten** (veralteter `.finished`-Context, der Normalfall):
  - Genau ein Workout in Fitness/Health, kein Mini-Workout unter 1 min.
  - Titel = Planname.
- [ ] **C. Neues Workout direkt nach „Alles verwerfen“** (veralteter `.discarded`): Die Session startet und wird nicht durch Recovery verworfen.
- [ ] **D. Watch-App bereits im Vordergrund:** Nur der Message-Pfad läuft, kein zweiter Start, ein Workout in Health.
- [ ] **E. Watch gesperrt bzw. nicht am Handgelenk:** Verhalten von `startWatchApp` dokumentieren (unverifiziert).
  - Kein Crash.
  - Nach Entsperren und manuellem Öffnen greift Self-Healing.
  - Kein doppeltes Workout.
- [ ] **F. Watch außer Reichweite oder Bluetooth aus:**
  - Fehler-Log auf dem iPhone, kein Crash.
  - Manuelles Öffnen später startet per Self-Healing.
  - Nach Workout-Ende wieder in Reichweite: ein spät zugestellter Launch startet **nichts**.
- [ ] **G. Watch-App-Kill während eines laufenden Workouts:** Verhalten wie vor der Änderung (dokumentieren).
- [ ] **H. iPhone-App-Kill während des Workouts, dann Resume:**
  - Kein zweites HKWorkout.
  - Bei unerreichbarer Watch läuft `handle(_:)` mit laufender Session ohne Wirkung.
  - Titel unverändert.
- [ ] **I. Doppelter Auslöser:** Workout starten und sofort die Watch-App manuell öffnen. Genau eine Session.
- [ ] **J. Stop („Beenden“):**
  - Workout in Health mit Titel = Planname.
  - Das iPhone setzt `healthKitWorkoutUUID` über `onWorkoutSaved` (`MotionCoreApp.swift:113-124`). Damit ist die ExternalUUID-Kette belegt; die Health-UI zeigt sie nicht an.
- [ ] **K. Discard („Alles verwerfen“):**
  - Normal: kein Health-Eintrag.
  - Innerhalb von 1-2 s nach dem Start: kein Workout-Indikator mehr auf der Watch, kein Health-Eintrag (Startfenster).
- [ ] **L. „Health-Daten behalten“:** Workout gespeichert.
- [ ] **M. Ad-hoc-Workout ohne Plan:** Apple-Standardtitel, `healthKitWorkoutUUID` gesetzt.
- [ ] **N. Berechtigung:**
  - Erster Start nach dem Update: Write-Prompt erscheint höchstens einmal, nur mit gepaarter Watch.
  - Prompt ablehnen: Fallback (manuelles Öffnen) funktioniert.
  - iPhone ohne gepaarte Watch: kein Prompt, kein Fehler.
  - Klären, ob die Freigabe der Watch genügt: Status war bereits `.sharingAuthorized`, also kein Prompt?
- [ ] **O. Pause/Resume** während des Workouts wie bisher.

## Offene Fragen

1. **Wann soll der HealthKit-Write-Prompt auf dem iPhone erscheinen?**
   Empfohlener Default: einmalig beim ersten Workout-Start nach dem Update. Nur bei gepaarter Watch mit installierter App und Status `.notDetermined`. Nutzer ohne Watch sehen ihn nie.
2. **Soll die Watch-App auch nach einem iPhone-App-Neustart (Resume) automatisch gestartet werden, wenn die Watch nicht erreichbar ist?**
   Empfohlener Default: ja. Es ist derselbe Codepfad, und er ist idempotent: Bei laufender Session bleibt `handle(_:)` ohne Wirkung.
