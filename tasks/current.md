# Zeitbasierte Übungen (Set-Reps-Time)

**Komplexität:** Large · **Phasen:** A–G · **Modus:** Phasiert mit STOPP-Gate nach jeder Phase

> Spezifikation: `Documentation/Instructions/MotionCore_Timebased-Exercises_Instruction.md` (v1.1) + `Documentation/Concepts/MotionCore_Timebased-Exercises_Concept.md` (v1.1), beide approved. Bei Konflikt gewinnt die Instruction, ergänzt um die hier dokumentierten verifizierten Code-Befunde.

## Summary

Zweiter Tracking-Modus `time` neben dem bestehenden `weight`-Modus. Übungen werden über eine Zeit pro Satz (z. B. Rudern 5 Min) statt über Gewicht × Wiederholungen definiert. Ein Übungs-Countdown (Date-Anker, hintergrundsicher) treibt die Anzeige; tatsächlich gelaufene Zeit wird zurückgeschrieben. Leitprinzip: **additiv, nicht invasiv** — der Weight-Pfad bleibt byte-identisch, der Time-Pfad zweigt an klar definierten Stellen ab.

## Scope

**Included**
- Datenmodell: `SetTrackingMode`-Enum, `ExerciseSet.trackingModeRaw`/`trackingMode`/`isTimeBased`, Propagation über alle Clone-/Export-/Backup-Pfade
- Config-Sheet: Segmented Control + bedingte UI + Time-`saveSets()`
- Active Workout: `ExerciseCountdownManager` (NEU) + `ExerciseCountdownTimerView` (NEU) + Time-Zweig in `ActiveSetCard`
- Verdrahtung: Manager-Lifecycle in `ActiveWorkoutView`, RIR-Flag-Guard + Volumen-Filter im `SetManager`/`ExerciseSetFlagUpdater`, Anzeige-Anpassungen
- Detail-/Volumen-Anzeigen (kein „0 kg" bei Time-Sätzen, Satz-Zählung bleibt korrekt)
- Persistenz/Resume des Countdowns über `SessionResumeStore`
- Live Activity (read-only Countdown) + Watch (read-only Countdown, kein Abschließen)

**Explizit ausgeschlossen** (Concept §7)
- Smart Progression für Time-Übungen
- Statistik & Rekorde für Time-Übungen
- Strukturierte Pace-Erfassung (nur Freitext in `notes`)
- `distance`-Feld (kommt mit dem Statistik-Feature)
- Auto-Start des Countdowns
- Sound beim Timer-Ende (nur Haptik)

## Verifizierte Code-Befunde (Planner-Entscheidungen)

1. **`SetTrackingMode` → `StrengthTypes.swift`.** Foundation-only, passt zu `ExerciseQualityRating`-Muster.
2. **`duration` existiert bereits** auf `ExerciseSet`. NICHT neu anlegen. Clone-Pfade kopieren `duration` bereits — nur `trackingMode` fehlt.
3. **RIR-Flag wird an ZWEI Quellen gesetzt** — beide guarden: `SetManager.isLastWorkSet` + `ExerciseSetFlagUpdater.updateLastSetFlags`.
4. **Volumen wird an ZWEI Stellen berechnet** — beide filtern: `SetManager.recomputeSessionVolume` + `StrengthSession.totalVolume`.
5. **`WatchMessageKeys.swift` ist EINE Datei mit Multi-Target-Membership** — ein Edit genügt.
6. **`ExerciseCountdownManager` braucht echtes pause/resume.** `RestTimerManager` hat nur start/stop — `pause()` friert `remainingSeconds` ein, `resume()` berechnet neuen `endDate`.
7. **`WorkoutActivityAttributes.ContentState.init`** — neue Params mit Defaults → bestehende Call-Sites kompilieren unverändert.

## Affected Files

**Phase A — Modell/Types**
- `MotionCore/Models/Types/StrengthTypes.swift`
- `MotionCore/Models/Core/ExerciseSet.swift`
- `MotionCore/Services/Data/Export.swift`
- `MotionCore/Services/Database/Remote/Session/SupabaseFullBackupService.swift` + `SupabaseSessionModels.swift`
- `MotionCore/Models/Core/StrengthSession.swift`

**Phase B — Config**
- `MotionCore/Views/Training/Plans/Components/SetConfigurationSheet.swift`
- `MotionCore/Components/Forms/FormViewSection.swift`

**Phase C — Active Workout**
- `MotionCore/Views/Workouts/Active/Components/ExerciseCountdownManager.swift` — NEU
- `MotionCore/Views/Workouts/Active/Components/ExerciseCountdownTimerView.swift` — NEU
- `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift`

**Phase D — Verdrahtung**
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`
- `MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift`
- `MotionCore/Services/ExerciseSetFlagUpdater.swift`
- `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift`

**Phase E — Detail/Volumen**
- `MotionCore/Views/Workouts/Components/StrengthDetailView.swift`
- `MotionCore/Views/Workouts/Active/Components/WorkoutCompletedCard.swift`

**Phase E2 — Persistenz/Resume**
- `MotionCore/Models/Session/SessionResumeState.swift`
- `MotionCore/Services/Session/SessionResumeStore.swift`
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift`

**Phase F — Live Activity & Watch**
- `MotionCoreWidgets/WorkoutActivityAttributes.swift`
- `MotionCore/Views/Workouts/Active/ViewModel/LiveActivityCtrl.swift`
- `MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift`
- `MotionCore/Services/Watch/WatchMessageKeys.swift` (EIN Edit, Multi-Target)
- `MotionCore/Services/Watch/PhoneSessionManager.swift`
- `MotionCore/Views/Workouts/Active/ViewModel/WatchBridge.swift`
- `MotionCoreWatch Watch App/Services/WatchSessionManager.swift`
- `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift`

## Risks

- **SwiftData-Migration:** `trackingModeRaw: String = "weight"` mit Default → lightweight migration, kein Schema-Bruch.
- **Supabase CodingKeys-Trap:** Falls DTO ein `CodingKeys`-Enum hat, `tracking_mode` explizit listen. Vor Edit prüfen.
- **Export-Forward-Compat:** `trackingMode: String?` optional → alte Exporte → `.weight`.
- **Pause-Kollision:** Zwei getrennte Manager (Countdown + RestTimer) vermeiden State-Vermischung.
- **Session-Pause-Doppellogik (R4):** `wasRunningBeforeSessionPause`-Merker nötig.
- **Resume-Konsistenz (R6):** `setUUID`-Abgleich beim Restore.
- **Watch-Race:** `.completeSet`-Guard in `WatchBridge.handleAction`.
- **Regression Weight-Pfad:** Striktes `if isTimeBased / else Bestand`.

## Implementation Steps

### Phase A — Datenmodell & Types
- [x] **A.1** `StrengthTypes.swift`: `SetTrackingMode: String, Codable, CaseIterable, Identifiable` (`weight`/`time`, `id`, `description`)
- [x] **A.2** `ExerciseSet.swift`: `trackingModeRaw`/`trackingMode`/`isTimeBased`; `init`-Param `trackingMode: SetTrackingMode = .weight`
- [x] **A.3** `ExerciseSet.swift`: `cloneForSession()` + `cloneForPlanEditing()` — `trackingMode: trackingMode` ergänzen
- [x] **A.4** `Export.swift`: `ExerciseSetExportItem.trackingMode: String?`; `exportItem`/`fromExportItem` rückwärtskompatibel; CodingKeys prüfen
- [x] **A.5** `SupabaseFullBackupService.swift` + `SupabaseSessionModels.swift`: `tracking_mode` im Set-Payload; CodingKeys prüfen
- [x] **A.6** `StrengthSession.swift`: `totalVolume` Filter `!isTimeBased`

> **🛑 STOPP-Gate A:** Build iOS. Kompiliert; bestehende Sets `.weight`. „green"/„red".

---

**Fortschritt Phase A** — 2026-06-06
- Abgeschlossen: A.1–A.6
- Geänderte Dateien:
  - `MotionCore/Models/Types/StrengthTypes.swift` — `SetTrackingMode`-Enum ergänzt
  - `MotionCore/Models/Core/ExerciseSet.swift` — `trackingModeRaw`/`trackingMode`/`isTimeBased`; `init`-Param; Clone-Pfade
  - `MotionCore/Services/Data/Export.swift` — `ExerciseSetExportItem.trackingMode: String?`; Export/Import-Mapper
  - `MotionCore/Services/Database/Remote/Session/SupabaseSessionModels.swift` — `SupabaseExerciseSetDTO.trackingMode` + CodingKeys
  - `MotionCore/Services/Database/Remote/Session/SupabaseFullBackupService.swift` — beide DTO-Konstruktionsstellen erweitert
  - `MotionCore/Models/Core/StrengthSession.swift` — `totalVolume` filtert Time-Sätze
- Offen: STOPP-Gate A (Build) durch Bartosz; Supabase-Spalte `tracking_mode` in `exercise_sets`-Tabelle muss manuell hinzugefügt werden (Datenmodell-Entscheidung, nicht im Code)

### Phase B — Config-Sheet
- [x] **B.1** `FormViewSection.swift`: `SetDurationSection` (Presets 30/60/120/180/300 s, ±15 s, mm:ss)
- [x] **B.2** `SetConfigurationSheet.swift`: `@State trackingMode`/`durationSeconds = 300`/`paceNote`; Bootstrap aus `initialSets`; `Picker(.segmented)` oben
- [x] **B.3** Bedingte UI: Sätze+Pause immer; Reps/Gewicht/Warmup/Ziel-RIR nur Weight; `SetDurationSection`+Pace nur Time
- [x] **B.4** `saveSets()` Time-Zweig: N Work-Sets mit `duration`/`weight=0`/`reps=0`/`setKind=.work`/`trackingMode=.time`/`notes=paceNote`; keine Warmups/RIR

> **🛑 STOPP-Gate B:** Build + Plan-Test (Time 5 Min/3 Sätze + Weight). Persistenz + Edit korrekt. „green"/„red".

---

**Fortschritt Phase B** — 2026-06-06
- Abgeschlossen: B.1–B.4
- Geänderte/erstellte Dateien:
  - `MotionCore/Components/Forms/SetDurationSection.swift` — NEU (104 Zeilen); `SetDurationSection`-View mit Presets 30/60/120/180/300 s, ±15-s-Feineinstellung, mm:ss-Format
  - `MotionCore/Views/Training/Plans/Components/SetConfigurationSheet.swift` — `@State trackingMode/durationSeconds/paceNote`; `bootstrapState` um 3 neue Parameter erweitert; segmented Picker im `setsConfigurationCard`; bedingte Sektionen; `saveSets()` Zeit-Zweig; `TimeSetPreviewRow` NEU; `previewCard` modus-bewusst
- Abweichungen:
  - `SetDurationSection` in eigene Datei ausgelagert (FormViewSection.swift war bereits 1415 Zeilen — deutlich über 400)
  - `SetConfigurationSheet.swift` ist 972 Zeilen (war vorher 807) — pre-existing Überschreitung, kein Split da Datei etabliert ist
  - `previewCard` erhält Zeit-Branch mit `TimeSetPreviewRow` statt Weight-Garbage (außerhalb B.1–B.4, aber notwendig für saubere UX)
  - `paceNote` wird aus `initialSets` geladen (erstes zeitbasiertes Work-Set → `notes`), damit Edit korrekt round-trippt
- Offen: STOPP-Gate B (Build + Plan-Test) durch Bartosz

### Phase C — Active Workout (Manager + Card)
- [x] **C.1** `ExerciseCountdownManager.swift` (NEU): `@MainActor ObservableObject`; Published `remainingSeconds`/`isRunning`/`isPaused`/`isFinished`/`endDate`, `targetSeconds`; `start`/`pause`/`resume`/`reset(to:)`/`handleForegroundReturn`/`cleanup`; `elapsedSeconds`; `snapshot()`/`restore(from:)`; `ExerciseCountdownSnapshot: Codable`; `onFinished` (Haptik)
- [x] **C.2** `ExerciseCountdownTimerView.swift` (NEU): Ring + Mono-Ziffern, Label „Übung läuft", Farben grün/>60s / gelb/10–60s / rot/≤10s
- [x] **C.3** `ActiveSetCard.swift`: `@ObservedObject countdown`; Time-Zweig; Toggle Start/Pause/Fortsetzen + „Satz abschließen" disabled bei `isRunning && !isPaused`; `set.duration = countdown.elapsedSeconds` VOR `onComplete(set)`; Pace-Chip

> **🛑 STOPP-Gate C:** Build. Time-Card korrekt, Abschließen-Gate, Farben. „green"/„red".

---

**Fortschritt Phase C** — 2026-06-06
- Abgeschlossen: C.1–C.3
- Erstellte Dateien:
  - `MotionCore/Views/Workouts/Active/Components/ExerciseCountdownManager.swift` — NEU (261 Zeilen); `@MainActor` ObservableObject; `import Combine + Foundation`; Date-Anker-Loop mit `MainActor.assumeIsolated`; pause/resume/reset(to:setUUID:)/snapshot/restore; `ExerciseCountdownSnapshot: Codable`
  - `MotionCore/Views/Workouts/Active/Components/ExerciseCountdownTimerView.swift` — NEU (109 Zeilen); Ring + Mono-Ziffern mm:ss; Farblogik grün/gelb/rot; Label „Übung läuft"
  - `MotionCore/Views/Workouts/Active/Components/ActiveTimeSetContent.swift` — NEU (117 Zeilen); Time-Inhalt aus ActiveSetCard ausgelagert (Zeilenlimit)
- Geänderte Dateien:
  - `MotionCore/Views/Workouts/Active/Components/ActiveSetCard.swift` — 366 Zeilen; `@ObservedObject countdown: ExerciseCountdownManager`; `cardHeader`/`supersetTracker`/`withInstructionsSheet` als geteilte Properties; Weight-Zweig (`weightBasedContent`) und Time-Zweig (`timeBasedContent`) getrennt; kein Anpassen-Stift im Time-Zweig
  - `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `@StateObject private var exerciseCountdownManager`; `countdown: exerciseCountdownManager` an Call-Site übergeben (vollständige Verdrahtung in Phase D)
- Abweichungen:
  1. `start(seconds:setUUID:)` und `reset(to:setUUID:)` erhalten `setUUID`-Parameter: notwendig damit `snapshot()` die `setUUID` für Phase-E2-Abgleich kennt — plangemäße Erweiterung, vom Advisor empfohlen.
  2. `countdownToggleButton`: abgelaufener Zustand (`isFinished, !isRunning, !isPaused`) zeigt „Start"-Button (Neustart). „Satz abschließen" ist gleichzeitig aktiv — beides nutzbar.
  3. Time-Inhalt (Buttons + Timer) in `ActiveTimeSetContent.swift` ausgelagert, damit `ActiveSetCard` unter 400 Zeilen bleibt.
  4. Weight-Zweig: logisch identisch zum Original, gemeinsamer Header extrahiert — Renderverhalten unverändert.
- Offen: STOPP-Gate C (Build) durch Bartosz

### Phase D — Verdrahtung
- [x] **D.1** `ActiveWorkoutView.swift`: Manager-State + Injection; `.onChange(cachedCurrentSet)` reset bei Time-Set; `onFinished`→Haptik; `cleanup`/`handleForegroundReturn`; `wasRunningBeforeSessionPause` + Session-Pause-Kopplung
- [x] **D.2** `SetManager.swift`: `isLastWorkSet` Guard `!set.isTimeBased`; `recomputeSessionVolume` Filter `!isTimeBased`; Zählung unverändert
- [x] **D.2b** `ExerciseSetFlagUpdater.swift`: `updateLastSetFlags` Time-Sätze ausschließen
- [x] **D.2c** Verifikation: `isSelectedExerciseComplete` / ExerciseQualityRating-Pfad klappt für Time-Übungen
- [x] **D.3** `ExercisesOverviewCard.swift`: `formatSetValue`/`ExerciseDetailRow` Zeit bei `isTimeBased`

---

**Fortschritt Phase D** — 2026-06-06
- Abgeschlossen: D.1–D.3 (inkl. D.2c Verifikation ohne Code-Eingriff)
- Geänderte Dateien:
  - `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `@State wasRunningBeforeSessionPause`; `onFinished`-Haptik in `onAppear`; `.onChange(cachedCurrentSet.persistentModelID)` für Countdown-Reset; Session-Pause-Kopplung in `onChange(isPaused)`; `handleForegroundReturn()` + `cleanup()` ergänzt
  - `MotionCore/Views/Workouts/Active/ViewModel/SetManager.swift` — `isLastWorkSet` Guard `!set.isTimeBased`; `recomputeSessionVolume` filtert `!isTimeBased`
  - `MotionCore/Services/ExerciseSetFlagUpdater.swift` — `updateLastSetFlags` setzt Flag nur auf letzten Weight-WorkSet
  - `MotionCore/Views/Workouts/Active/Components/ExercisesOverviewCard.swift` — `formatSetValue` Time-Zweig + `formatDuration`-Hilfsfunktion
- Abweichungen:
  1. Kein bestehender `.onChange`-Handler für den aktuellen Satz gefunden — neuer Handler auf `setManager.cachedCurrentSet?.persistentModelID` angelegt (Plan: „suche den bestehenden Handler"). Planungsäquivalent, da `cachedCurrentSet` ein `@Observable`-Property ist.
  2. `ExerciseDetailRow` existiert nicht in `ExercisesOverviewCard.swift` — die einzige Wert-Formatierung liegt in `ExerciseOverviewExpandedDetail.formatSetValue`. Dort implementiert.
  3. D.2c: Kein Code-Eingriff nötig (Befund dokumentiert in History).
- Offen: STOPP-Gate D (Build + Voll-Test) durch Bartosz

> **🛑 STOPP-Gate D:** Build + Voll-Test; Zeit in Liste; kein RIR-Sheet/-Stift; Bewertungskarte; Teilzeit→Ist-`duration`; Session-Pause hält Countdown. „green"/„red".

### Phase E — Detail/Volumen
- [x] **E.1** `StrengthDetailView.swift`: Time-Sätze Zeit statt kg×Wdh.; Volumen-Block ausblenden wenn alle Time
- [x] **E.2** `WorkoutCompletedCard.swift` (+ Summary): kg/Volumen bei Time unterdrücken; Satz-Anzahl korrekt

> **🛑 STOPP-Gate E:** Build + Session-Detail + Completed-Card; kein „0 kg", Ist-Zeit. „green"/„red".

---

**Fortschritt Phase E2** — 2026-06-06
- Abgeschlossen: E2.1–E2.3
- Geänderte Dateien:
  - `MotionCore/Models/Session/SessionResumeState.swift` — `let exerciseCountdown: ExerciseCountdownSnapshot?` ergänzt (optional → rückwärtskompatibel)
  - `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — `saveResumeState()`: `exerciseCountdown: exerciseCountdownManager.snapshot()` als neuer Parameter; `setupSession()`: Countdown-Restore nach `setManager.configure()` + `validateSelectedKey()`
- Abweichungen:
  1. `saveResumeState()` bleibt vollständig `let`-basiert (struct, inline initializer) — kein `var state` nötig, `snapshot()` direkt als Argument übergeben.
  2. Countdown-Restore in `setupSession()` platziert (nicht in `restoreResumeStateIfPossible()`), da `cachedCurrentSet` erst nach `setManager.configure()` synchron befüllt ist. Ein zweiter `SessionResumeStore.load()`-Aufruf (UserDefaults, ~1 µs) ist bewusst akzeptiert, um die `setUUID`-Prüfung korrekt durchführen zu können.
- Offen: STOPP-Gate E2 (Kill+Resume-Test) durch Bartosz

---

**Fortschritt Phase E** — 2026-06-06
- Abgeschlossen: E.1, E.2
- Geänderte Dateien:
  - `MotionCore/Views/Workouts/Components/StrengthDetailView.swift` — Satz-Detailzeile: Time-Zweig mit `formatSetDuration`; Volumen-Badge ausgeblendet wenn `sets.allSatisfy(\.isTimeBased)`; `exerciseVolume` filtert `!isTimeBased`; `formatSetDuration(_ seconds:)` hinzugefügt (distinct von `formatDuration(_ minutes:)`)
- Keine Änderungen nötig:
  - `WorkoutCompletedCard.swift` — kein Volumen/kg-Block vorhanden; keine Änderung
  - `ActiveWorkoutStatus.swift` — `if sessionVolume > 0`-Guard bestehend; A.6-Filter liefert 0 bei All-Time-Session → Volumen-Block automatisch ausgeblendet
  - `StrengthSessionCard.swift` — `formatVolume(session.totalVolume)` im StatBubble; A.6 liefert 0 → `formatVolume` gibt „–" zurück (kein „0 kg")
  - `StrengthDetailView.statisticsCard` Volumen-Kachel — ebenfalls via `session.totalVolume` + `formatVolume` → „–"; Layout-Kachel bleibt sichtbar (konsistent mit Bodyweight-Sessions im Weight-Pfad)
- Hinweis für STOPP-Gate E: Bei reiner Time-Session zeigt `totalReps`-Kachel „0 Wdh. gesamt" — Time-Sätze haben reps=0; liegt außerhalb E-Scope, aber für Bartosz zur Entscheidung beim Gate markiert

### Phase E2 — Persistenz/Resume
- [x] **E2.1** `SessionResumeState.swift`: `let exerciseCountdown: ExerciseCountdownSnapshot?`
- [x] **E2.2** `ActiveWorkoutView.swift` / Store: `countdown.snapshot()` beim Speichern mitschreiben
- [x] **E2.3** `ActiveWorkoutView.swift` Restore: `restore(from:)` nur wenn `setUUID` passt; `endDate` Vergangenheit → `isFinished`

> **🛑 STOPP-Gate E2:** Countdown starten → Kill → Neustart → korrekte Restzeit oder „abgelaufen". „green"/„red".

### Phase F — Live Activity & Watch
- [x] **F.0** `WatchMessageKeys.swift` Target-Membership verifizieren (eine Datei, Multi-Target)
- [x] **F.1** `WorkoutActivityAttributes.swift`: ContentState + `isExerciseCountdown: Bool = false`, `countdownStartDate: Date? = nil`, `countdownEndDate: Date? = nil`
- [x] **F.2** `LiveActivityCtrl.swift`: `configure` um `countdown`; `makeLiveContentState` befüllt Felder
- [x] **F.3** `MotionCoreWidgetsLiveActivity.swift`: Countdown-Branch (`Text(timerInterval:countsDown:)`), Farben, Label „Übung"
- [x] **F.4** `WatchMessageKeys.swift`: `isCountdown`/`countdownEndDate` ergänzen (EIN Edit)
- [x] **F.5** `PhoneSessionManager.swift` + `WatchBridge.swift`: `sendWorkoutState` erweitern; `.completeSet` ignoriert Time-Sets
- [x] **F.6** `WatchSessionManager.swift` + `WatchActiveWorkoutView.swift`: Keys auslesen; read-only Countdown; kein Abschließen-Button

> **🛑 STOPP-Gate F:** Build beide Targets. LiveActivity farbig; Watch read-only ohne Button; Watch-`completeSet` ignoriert. „green"/„red".

---

**Fortschritt Phase F** — 2026-06-06
- Abgeschlossen: F.0–F.6
- Verifikation F.0: nur eine physische `WatchMessageKeys.swift` (Multi-Target-Membership per pbxproj — ein Edit genügt)
- Geänderte Dateien:
  - `MotionCoreWidgets/WorkoutActivityAttributes.swift` — 3 neue Felder + init-Params mit Defaults
  - `MotionCore/Services/Watch/WatchMessageKeys.swift` — `isCountdown` + `countdownEndDate` Keys
  - `MotionCore/Services/Watch/PhoneSessionManager.swift` — `sendWorkoutState` um `isCountdown`/`countdownEndDate` erweitert
  - `MotionCore/Views/Workouts/Active/ViewModel/LiveActivityCtrl.swift` — `countdown`-Property + configure-Param + `makeLiveContentState` Countdown-Block
  - `MotionCore/Views/Workouts/Active/ViewModel/WatchBridge.swift` — `countdown`-Property + configure-Param + `sendState` Countdown-Block + `.completeSet`-Guard
  - `MotionCoreWidgets/MotionCoreWidgetsLiveActivity.swift` — `countdownTimerColor` Helper; compactLeading/compactTrailing/expanded trailing/lockScreen Countdown-Zweige
  - `MotionCoreWatch Watch App/Services/WatchSessionManager.swift` — `isCountdown`/`countdownEndDate` Published properties + Parsing im didReceiveMessage
  - `MotionCoreWatch Watch App/Views/WatchActiveWorkoutView.swift` — `countdownView` Builder + Routing in body
  - `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` — configure()-Aufrufe mit `countdown:`; `.onChange(of: exerciseCountdownManager.isRunning)` Handler
- Abweichungen:
  1. `onChange(of: exerciseCountdownManager.isRunning)` feuert nur bei Start/Stop, NICHT bei Pause. Spec sagt `isRunning` only — implementiert exakt so. Lücke: Pause/Resume-Toggle im Countdown aktualisiert LiveActivity/Watch erst beim nächsten `isRunning`-Wechsel. Für Gate-F notiert.
  2. Advisor-Korrektur: `setManager?.cachedCurrentSet` → `setManager.cachedCurrentSet` (nicht-optional nach guard)
- Offen: STOPP-Gate F (Build beide Targets) durch Bartosz

### Phase G — Abschluss
- [ ] **G.1** Edge-Cases: gemischtes Superset (Weight+Time), Hintergrund, Kill+Resume, mehrere Time-Sätze (kein State-Leak), Session-Pause (R4), Teilzeit-Abbruch (R1/R2/R3)
- [ ] **G.2** Cleanup: `print` raus, Dateigrößen prüfen (Split >600 L), keine undokumentierten Force-Unwraps, keine `+`-Dateinamen
- [ ] **G.3** Commits (Conventional, pro Phase)

> **🛑 STOPP-Gate G:** Final-Build beide Targets, alle Edge-Cases grün. „green"/„red".

## Manual Verification Checklist
- [ ] Build `Cmd+B` iOS (Gates A–E2), beide Targets (F, G)
- [ ] Migration: bestehende Sets laden als `.weight`
- [ ] Config: Time + Weight anlegen; Edit lädt Modus korrekt
- [ ] Active-Flow: Start/Pause/Fortsetzen/Abschließen; Zeit in Übungsliste; kein RIR-Sheet/-Stift; Bewertungskarte erscheint; Teilzeit → `duration`; Session-Pause hält Countdown an
- [ ] Volumen: Satz-Total korrekt, kein „0 kg"
- [ ] Resume: Kill+Neustart → korrekte Restzeit oder „abgelaufen"
- [ ] Watch/LiveActivity: farbiger Countdown; Watch read-only; `completeSet` ignoriert bei Time-Set
- [ ] Edge-Cases: gemischtes Superset, mehrere Time-Sätze hintereinander
- [ ] Regression: reine Weight-Übung unverändert

## Open Questions
Keine. Spezifikation v1.1 approved und vollständig; alle Code-Konflikte als Planner-Entscheidungen aufgelöst.
