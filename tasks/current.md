# HealthKit Live-Workout-Session (Apple Watch HR + Kalorien)

**Complexity:** Large
**Status:** In Implementierung

## Summary

MotionCore startet eine eigene `HKWorkoutSession` auf der Apple Watch, sodass Herzfrequenz und Kalorienverbrauch automatisch gemessen werden. Die Werte erscheinen live auf dem iPhone in der `ActiveWorkoutView`. Nach Beenden steht ein vollständiges `HKWorkout` in Apple Health. Das Feature ist optional — ohne Watch läuft das Workout wie bisher.

## Scope

**Enthalten:**
- `HKWorkoutSession` + `HKLiveWorkoutBuilder` auf der Watch
- HealthKit Write-Berechtigungen auf der Watch (Read bleibt wie bisher)
- Watch→iPhone Kommunikation für HR/Kalorien (Event-basiert + optionaler 60-Sek-Heartbeat)
- Neues `ExerciseMetrics` SwiftData Model für pro-Übung Health-Daten
- `LiveHealthCard` UI in der `ActiveWorkoutView`
- Watch-Connection-Indikator in `ActiveWorkoutStatus`
- HR-Anzeige auf der Watch
- Cancel-Alert mit Health-Entscheidung (behalten/verwerfen)
- Setting für Heartbeat-Timer
- Nur Krafttraining (`StrengthSession`)

**Explizit ausgeschlossen:**
- Cardio/Outdoor Sessions (separates Feature)
- Historische Backfills
- HR-basierte Pausenempfehlungen
- Eigenständiges Watch-Workout-Starten
- iPhone-seitiges HealthKit-Write
- Supabase-Schema für ExerciseMetrics (spätere Session)
- StrengthDetailView-Anzeige von HR pro Übung (spätere Session)

## Getroffene Entscheidungen

| # | Frage | Entscheidung |
|---|---|---|
| F1 | HealthKit-Auth Zeitpunkt | Automatisch beim ersten Workout-Start (kein Button in Settings) |
| F2 | ExerciseMetrics bei Exercise-Transition | Ja — bei jedem Übungswechsel für die vorherige Übung speichern |
| F3 | WatchConnectionState-Logik | Einfach: `isWatchTrackingActive ? .activeTracking : .hidden` |

---

## Affected Files

### Neue Dateien (6 Stück inkl. Duplikat)

| Datei | Target | Beschreibung |
|---|---|---|
| `MotionCore/Services/Watch/WatchHealthDataTypes.swift` | iPhone | Shared Keys: WatchHealthKey, WatchExerciseSnapshotKey, WatchWorkoutLifecycleKey, WatchHeartbeatKey |
| `MotionCoreWatch Watch App/Services/WatchHealthDataTypes.swift` | Watch | Identische Kopie (wie WatchMessageKeys.swift) |
| `MotionCoreWatch Watch App/Services/WatchWorkoutManager.swift` | Watch | HKWorkoutSession + HKLiveWorkoutBuilder, Delegates, Snapshots |
| `MotionCore/Models/Core/ExerciseMetrics.swift` | iPhone | SwiftData @Model für pro-Übung Health-Metriken |
| `MotionCore/Views/Workouts/Active/Components/LiveHealthCard.swift` | iPhone | GlassCard: aktuelle HR, Ø HR, max HR, Kalorien |
| `MotionCore/Services/Calculation/HealthDataCalcEngine.swift` | iPhone | Pure Struct: aggregiert ExerciseMetrics |

### Geänderte Dateien (10 Stück)

| Datei | Änderung |
|---|---|
| `MotionCore/App/MotionCoreApp.swift` | ExerciseMetrics.self zum appSchema hinzufügen |
| `MotionCore/Models/Core/StrengthSession.swift` | Inverse Relationship + safeExerciseMetrics |
| `MotionCore/Models/Core/AppSettings.swift` | enableLiveHeartbeatTimer: Bool |
| `MotionCore/Services/Watch/PhoneSessionManager.swift` | @Published Health-Properties, Lifecycle-Methoden, Message-Empfang |
| `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` | workoutManager Property, Lifecycle-Handling, Heartbeat-Timer |
| `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` | LiveHealthCard, Transitions, finishWorkout, cancelWorkout |
| `MotionCore/Views/Workouts/Active/Components/ActiveWorkoutStatus.swift` | watchConnectionState Parameter + ⌚ Icon |
| `MotionCore/Views/Settings/View/WorkoutSettingsView.swift` | Toggle für Heartbeat-Timer |
| `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift` | HR-Anzeige unter Timer |
| `MotionCoreWatch Watch App/WatchBaseView.swift` | HealthKit-Auth Button |

### Xcode-Konfiguration (manuell in Xcode)

- Watch-Target: HealthKit Capability aktivieren
- Watch-Target: Background Modes → "Workout processing" aktivieren
- Watch-Target Info.plist: NSHealthShareUsageDescription + NSHealthUpdateUsageDescription
- `MotionCoreWatch Watch App.entitlements`: com.apple.developer.healthkit = true

---

## Risks

### Kritisch
- **SwiftData-Schema-Änderung:** `ExerciseMetrics` als neues @Model + inverse Relationship in `StrengthSession`. Alle Felder haben Default-Werte → CloudKit-kompatibel. Vor Merge auf echtem Gerät mit bestehenden Daten testen.
- **ActiveWorkoutView Komplexität:** ~2000 Zeilen. Änderungen chirurgisch präzise — nur existierende Funktionen erweitern, keine Umstrukturierung.

### Mittel
- **WatchConnectivity-Zuverlässigkeit:** `sendMessage()` nur wenn Watch reachable. Fallback: Workout ohne HR-Daten, kein Fehler.
- **Nur auf echter Hardware testbar:** HKWorkoutSession liefert im Simulator keine Daten.
- **Dual-Target Dateisync:** `WatchHealthDataTypes.swift` muss in beiden Targets identisch sein.

---

## Implementation Steps

### Phase 1: Foundation Watch-seitig (Schritte 1–6)

- [x] **1. Watch-Target Capabilities konfigurieren (Xcode manuell)**
  - HealthKit Capability im Watch-Target aktivieren (MANUELL in Xcode)
  - Background Modes: "Workout processing" aktivieren (MANUELL in Xcode)
  - Info.plist: `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` ✅ erstellt
  - Entitlements: `com.apple.developer.healthkit = true` ✅ hinzugefügt

- [x] **2. WatchHealthDataTypes.swift erstellen (BEIDE Targets)**
  - iPhone-Datei: `MotionCore/Services/Watch/WatchHealthDataTypes.swift` ✅
  - Watch-Kopie: `MotionCoreWatch Watch App/Services/WatchHealthDataTypes.swift` ✅
  - Enums: `WatchHealthKey`, `WatchExerciseSnapshotKey`, `WatchWorkoutLifecycleKey`, `WatchHeartbeatKey` ✅
  - **Target Membership: beide Dateien manuell in Xcode dem richtigen Target zuweisen**

- [x] **3. WatchWorkoutManager.swift erstellen (Watch-Target)**
  - `final class WatchWorkoutManager: NSObject, ObservableObject` ✅
  - @Published: `currentHeartRate`, `averageHeartRate`, `maxHeartRate`, `activeCalories`, `isActive` ✅
  - Methoden: `requestAuthorization()`, `startWorkout()`, `pauseWorkout()`, `resumeWorkout()`, `endWorkout()`, `discardWorkout()`, `markExerciseTransition()`, `currentSnapshot()`, `exerciseSnapshot()` ✅
  - Delegates: `HKWorkoutSessionDelegate`, `HKLiveWorkoutBuilderDelegate` ✅
  - Config: `.traditionalStrengthTraining`, `.indoor` ✅
  - **Target Membership: manuell in Xcode dem Watch-Target zuweisen**

- [x] **4. WatchSessionManager.swift — requestAuthorization beim Workout-Start**
  - Kein Auth-Button in Settings (F1: automatisch) ✅
  - `startWorkout()`-Handling: Zuerst `workoutManager.requestAuthorization()`, dann `startWorkout()` ✅
  - Wenn Auth verweigert: Workout läuft ohne HR-Tracking (Fallback), kein Fehler ✅

- [x] **5. WatchSessionManager.swift erweitern — workoutManager + Lifecycle (inkl. Auto-Auth)**
  - Neue Property: `@Published private(set) var workoutManager: WatchWorkoutManager?` ✅
  - Heartbeat-Timer Properties + Methoden ✅
  - In `didReceiveMessage`: Lifecycle-Keys verarbeiten (start/stop/pause/resume/transition/snapshot/discard/heartbeat) ✅

- [ ] **6. BUILD + DEVICE TEST Phase 1**
  - HealthKit-Auth genehmigen, HR-Samples in Console prüfen

### Phase 2: Kommunikation Watch → iPhone (Schritte 7–9)

- [x] **7. PhoneSessionManager.swift erweitern**
  - @Published: `liveCurrentHR`, `liveAverageHR`, `liveMaxHR`, `liveActiveCalories`, `isWatchTrackingActive`, `lastExerciseSnapshot` ✅
  - Struct `ExerciseSnapshotData` (avgHR, minHR, maxHR, calories, durationSeconds) ✅
  - Lifecycle-Methoden: alle 9 Methoden implementiert ✅
  - `didReceiveMessage` erweitern: WatchHealthKey + WatchExerciseSnapshotKey verarbeitet ✅
  - `PhoneSessionManager` jetzt `ObservableObject` (war vorher kein ObservableObject) ✅

- [x] **8. WatchSessionManager Snapshot-Senden prüfen**
  - Combined-Snapshot (currentSnapshot + exerciseSnapshot) korrekt zusammengebaut ✅
  - `exerciseSnapshot`-Marker-Key für iPhone-seitige Erkennung gesetzt ✅

- [ ] **9. BUILD + DEVICE TEST Phase 2**
  - Set abschließen → Snapshot in Console auf iPhone

### Phase 3: iPhone Model + UI (Schritte 10–15)

- [ ] **10. ExerciseMetrics.swift erstellen (iPhone-Target)**
  - `@Model final class ExerciseMetrics`
  - Properties mit Default-Werten: exerciseGroupKey, exerciseNameSnapshot, avgHeartRate, minHeartRate, maxHeartRate, activeCalories, durationSeconds
  - `@Relationship(deleteRule: .nullify) var session: StrengthSession?`

- [ ] **11. StrengthSession.swift erweitern — Inverse Relationship**
  - `@Relationship(deleteRule: .cascade, inverse: \ExerciseMetrics.session) var exerciseMetrics: [ExerciseMetrics]? = []`
  - `var safeExerciseMetrics: [ExerciseMetrics] { exerciseMetrics ?? [] }`

- [ ] **12. MotionCoreApp.swift — ExerciseMetrics zum Schema**
  - `ExerciseMetrics.self` zum appSchema Array hinzufügen

- [ ] **13. HealthDataCalcEngine.swift erstellen (iPhone-Target)**
  - `struct HealthDataCalcEngine` mit `sessionSummary(from:) -> SessionHealthSummary`
  - `struct SessionHealthSummary` (avgHR, maxHR, totalCalories, totalDuration)

- [ ] **14. LiveHealthCard.swift erstellen (iPhone-Target)**
  - GlassCard mit `currentHR`, `averageHR`, `maxHR`, `activeCalories`
  - Herz-Icon rot, Flamme-Icon für Kalorien
  - Nur anzeigen wenn mindestens ein Wert > 0
  - Preview mit Beispieldaten

- [ ] **15. ActiveWorkoutStatus.swift erweitern — Watch-Indikator**
  - Enum `WatchConnectionState: hidden, connected, activeTracking, disconnected`
  - Parameter `watchConnectionState: WatchConnectionState = .hidden`
  - ⌚ Icon links neben Timer: grün (activeTracking), blau (connected), grau (disconnected), kein Icon (hidden)
  - Bestehende Previews dürfen nicht brechen

### Phase 4: Integration + Settings (Schritte 16–19)

- [ ] **16. AppSettings.swift erweitern**
  - `@Published var enableLiveHeartbeatTimer: Bool`
  - UserDefaults-Key: `"workout.enableLiveHeartbeatTimer"`, Default: `false`

- [ ] **17. WorkoutSettingsView.swift erweitern**
  - Neue Section "Apple Watch Health-Tracking"
  - Toggle mit Footer-Erklärung

- [ ] **18. ActiveWorkoutView.swift erweitern — volle Integration**
  - **ACHTUNG: Minimale, chirurgische Änderungen — 8 Einfügepunkte:**
    1. `onAppear`: Health-Tracking starten + ggf. Heartbeat aktivieren
    2. `onChange(of: selectedExerciseKey)`: ExerciseMetrics vorherige Übung speichern + Transition senden
    3. `scrollContent`: LiveHealthCard vor heroCard (wenn isWatchTrackingActive)
    4. `ActiveWorkoutStatus`-Aufruf: watchConnectionState Parameter
    5. `completeSet()`: `sendRequestSnapshot()` nach PR-Check
    6. `finishWorkout()`: Health-Daten in Session + saveCurrentExerciseMetrics() + sendStopHealthTracking()
    7. `cancelWorkout()`: showCancelHealthAlert wenn isWatchTrackingActive
    8. `toggleTimer()`: Pause/Resume Health-Sync
  - Neuer @State: `showCancelHealthAlert: Bool = false`
  - Neuer Alert: 3 Buttons (behalten / verwerfen / abbrechen)
  - Neue Funktion: `saveCurrentExerciseMetrics()`

- [ ] **19. BUILD + DEVICE TEST Phase 4**
  - Kompletter Flow: Start → Sätze → Pause → Finish → Apple Health prüfen

### Phase 5: Polish (Schritte 20–22)

- [ ] **20. WatchActiveWorkoutView.swift — HR-Anzeige**
  - Herz-Icon (rot) + aktuelle BPM unter Timer (wenn > 0)

- [ ] **21. Cancel-Alert testen**
  - Beide Pfade auf echtem Gerät testen

- [ ] **22. Fallback testen**
  - Ohne Watch → kein Fehler, kein LiveHealthCard, kein ⌚ Icon

---

## Manual Verification

- [ ] Xcode Build (`Cmd+B`) — beide Targets kompilieren fehlerfrei
- [ ] Watch-App: HealthKit-Auth Button sichtbar, Auth-Dialog erscheint
- [ ] Watch-App: HR-Anzeige während Workout sichtbar
- [ ] iPhone: LiveHealthCard erscheint wenn Watch-Tracking aktiv
- [ ] iPhone: ⌚ grünes Icon in ActiveWorkoutStatus
- [ ] iPhone: completeSet → Snapshot empfangen → LiveHealthCard aktualisiert
- [ ] iPhone: Exercise-Wechsel → Transition gesendet + ExerciseMetrics gespeichert
- [ ] iPhone: Pause → Watch pausiert HR-Tracking
- [ ] iPhone: finishWorkout → HKWorkout in Apple Health, HR/Kalorien in StrengthSession
- [ ] iPhone: cancelWorkout → Alert mit 3 Optionen (wenn Watch aktiv)
- [ ] iPhone: Ohne Watch → Workout normal, kein Fehler
- [ ] WorkoutSettingsView: Toggle sichtbar und funktional
- [ ] Bestehende ActiveWorkoutStatus Previews brechen nicht
- [ ] ExerciseMetrics werden in SwiftData gespeichert

---

## Fortschritt

**Datum:** 31.03.2026

**Abgeschlossene Schritte:** 1–5 (Phase 1) + 7–8 (Phase 2)

**Geänderte Dateien:**
- `MotionCoreWatch Watch App/MotionCoreWatch Watch App.entitlements` — `com.apple.developer.healthkit` hinzugefügt
- `MotionCoreWatch Watch App/Info.plist` — NEU erstellt mit NSHealthShare/UpdateUsageDescription
- `MotionCore/Services/Watch/WatchHealthDataTypes.swift` — NEU (iPhone-Target)
- `MotionCoreWatch Watch App/Services/WatchHealthDataTypes.swift` — NEU (Watch-Target, identische Kopie)
- `MotionCoreWatch Watch App/Services/WatchWorkoutManager.swift` — NEU (Watch-Target)
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — erweitert: workoutManager, heartbeatTimer, handleHealthLifecycle
- `MotionCore/Services/Watch/PhoneSessionManager.swift` — erweitert: ObservableObject, @Published Health-Properties, ExerciseSnapshotData, Lifecycle-Methoden, didReceiveMessage

**Ausstehende manuelle Schritte (Xcode):**
1. Watch-Target → Signing & Capabilities → HealthKit Capability hinzufügen
2. Watch-Target → Signing & Capabilities → Background Modes → "Workout processing" aktivieren
3. `WatchHealthDataTypes.swift` (iPhone-Target): Target Membership auf MotionCore setzen
4. `WatchHealthDataTypes.swift` (Watch-Target): Target Membership auf MotionCoreWatch Watch App setzen
5. `WatchWorkoutManager.swift`: Target Membership auf MotionCoreWatch Watch App setzen

**Offene Schritte:** 6 (Build+Test Phase 1), 9 (Build+Test Phase 2), 10–22 (Phase 3–5)
