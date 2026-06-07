# Claude Code Instruction: Zeitbasierte Übungen (Set-Reps-Time)

**Version:** 1.1
**Basiert auf:** Concept_Zeitbasierte_Uebungen.md v1.1
**Agent-Pipeline:** `motioncore-planner` → `motioncore-developer` → `motioncore-quality-gate`

---

## Globale Regeln für diese Instruction

- **Swift 6, SwiftUI, async/await.** Standards aus `swift-standards` Skill einhalten (max. 400 Zeilen/Datei, CalcEngine = pure struct, keine Business-Logik in Views, `Date`-Anker statt `Timer.scheduledTimer` für hintergrundrelevante Zeit).
- **Additiv arbeiten:** Weight-Pfad bleibt unverändert. Time-Pfad zweigt an definierten Stellen ab.
- **Kommentare auf Deutsch, Code/Identifier auf Englisch, Commits Conventional Commits (Englisch).**
- **Dateinamen ohne `+`.**
- **STOPP-Gates:** Nach jeder Phase Build-Bestätigung abwarten. Nur explizites „green"/„red" zählt — kein „passt", „ok", „weiter".
- Bei vermuteten Falsch-Findings / Konflikten mit Bestand: melden statt raten (False-Finding-Protokoll).

---

## Phase A — Datenmodell & Types

**Ziel:** `SetTrackingMode` einführen, `ExerciseSet` erweitern, Propagation an allen Kopierpfaden.

### Schritt A.1 — Enum `SetTrackingMode`
- In `StrengthTypes.swift` den Enum `SetTrackingMode` (`weight`/`time`, `Codable`, `CaseIterable`, `Identifiable`, `description`) anlegen. Prüfen, ob ein passender Types-File-Platz existiert; keinen Duplikat-Enum erzeugen.

### Schritt A.2 — `ExerciseSet` erweitern
- `var trackingModeRaw: String = "weight"` + computed `trackingMode` (get/set) + `var isTimeBased: Bool`.
- `init(...)` um Parameter `trackingMode: SetTrackingMode = .weight` ergänzen und im Body setzen.

### Schritt A.3 — `cloneForSession()`
- `trackingMode` (bzw. `trackingModeRaw`) in den Clone übernehmen. `duration` wird bereits kopiert — verifizieren.

### Schritt A.4 — Export/Import
- In `Export.swift`: `ExerciseSetExportItem` um `trackingMode: String?` erweitern, `exportItem` befüllen (nil wenn `.weight`, für kompakte Exporte), `fromExportItem` rückwärtskompatibel mappen (fehlt → `.weight`).

### Schritt A.5 — Supabase-Backup
- In `SupabaseFullBackupService.swift` (und zugehörigem DTO, z. B. `SupabaseSessionModels.swift`) `trackingMode` in den Set-Payload aufnehmen. Spalten-/Key-Namen an bestehende Snake-Case-Konvention angleichen (`tracking_mode`). UPSERT-Idempotenz wahren.

> **🛑 STOPP-Gate A:** Build iOS-Target. Erwartung: kompiliert, bestehende Sets laden als `.weight` (lightweight migration). Bestätigung „green"/„red" abwarten.

---

## Phase B — Config-Sheet (Plan-Erstellung)

**Ziel:** Segmented Control + bedingte UI + `saveSets()` für Time-Mode.

### Schritt B.1 — `SetDurationSection`
- Neue Section-View (in `FormViewSection.swift` einreihen oder eigene Datei `SetDurationSection.swift`, je nach Dateigröße). Aufbau analog `SetRestTimeSection`: Preset-Buttons (30/60/120/180/300 s), ±15 s Feineinstellung, `mm:ss`-Anzeige. Binding `@Binding var durationSeconds: Int`.

### Schritt B.2 — Segmented Control in `SetConfigurationSheet`
- `@State private var trackingMode: SetTrackingMode` + Bootstrap aus `initialSets` (erster Work-Set bestimmt Modus; fehlt → `.weight`).
- `Picker(selection:)` mit `.pickerStyle(.segmented)` ganz oben im Sheet.
- Zusätzlicher State `@State private var durationSeconds: Int` (Default 300) und `@State private var paceNote: String`.

### Schritt B.3 — Bedingte UI
- Sätze-Anzahl + Pausenzeit: immer sichtbar.
- Reps, Gewicht, Aufwärmsätze, Ziel-RIR: nur `if trackingMode == .weight`.
- `SetDurationSection` + Pace-Notizfeld: nur `if trackingMode == .time`.

### Schritt B.4 — `saveSets()`
- Bei `.time`: N Work-Sets (`numberOfSets`) mit `duration = durationSeconds`, `weight = 0`, `reps = 0`, `restSeconds = restSeconds`, `setKind = .work`, `trackingMode = .time`, `notes = paceNote`. Keine Warmups, kein `targetRIR`.
- Bei `.weight`: bestehender Pfad unverändert.

> **🛑 STOPP-Gate B:** Build + manueller Test: Plan anlegen mit einer Time-Übung (5 Min, 3 Sätze) und einer Weight-Übung. Sets korrekt persistiert? Edit lädt Modus korrekt? „green"/„red".

---

## Phase C — Active Workout (Countdown-Manager + Card)

**Ziel:** Countdown-Logik, Card-Darstellung, Abschluss-Gate.

### Schritt C.1 — `ExerciseCountdownManager.swift` (NEU)
- Klasse analog `RestTimerManager` (Concept §5.1). `Date`-Anker, `RunLoop.main`/`.common`, `[weak self]`, Timer-Identitätscheck.
- API: `start(seconds:)`, `pause()`, `resume()`, `reset(to:)`, `handleForegroundReturn()`, `cleanup()`.
- Published: `remainingSeconds`, `isRunning`, `isPaused`, `isFinished`, `endDate`; `targetSeconds`.
- `var elapsedSeconds: Int { max(0, targetSeconds - remainingSeconds) }` — für Zeit-Rückschreiben (R3).
- `snapshot()` / `restore(from:)` für Persistenz (R6, siehe Phase G-pre). Snapshot-Struct `ExerciseCountdownSnapshot` (Codable: targetSeconds, endDate, isPaused, remainingSeconds, setUUID).
- `onFinished` Callback (**nur Haptik**, kein Sound). Bei `remaining <= 0`: `isFinished = true`, `isRunning = false`, `onFinished?()`.

### Schritt C.2 — `ExerciseCountdownTimerView.swift` (NEU)
- Ring + große Mono-Ziffern wie `RestTimerCard`-Ring. Label **„Übung läuft"** (klar abgegrenzt von „Pause").
- Farblogik: `> 60s` grün, `10–60s` gelb, `≤ 10s` rot.
- Inputs: `remainingSeconds`, `targetSeconds`, plus Button-Callbacks (oder Buttons in der Card halten — Entscheidung des Developers, aber Buttons sollen eingebettet und kompakt sein, keine 3 breiten Buttons untereinander).

### Schritt C.3 — `ActiveSetCard` Time-Zweig
- `if set.isTimeBased { timeBasedContent } else { /* Bestand unverändert */ }`.
- `timeBasedContent`: Header (wie gehabt), Countdown-View, Button-Zeile:
  - Primär-Toggle: „Start" → „Pause" → „Fortsetzen" (Capsule, Icon+Label).
  - Sekundär: „Satz abschließen", **disabled** solange `isRunning && !isPaused`.
- **Beim „Satz abschließen" (R3):** `set.duration = countdown.elapsedSeconds` setzen, *bevor* `onComplete(set)` aufgerufen wird (voller Ablauf → bleibt = Soll; Abbruch → Ist-Zeit).
- Pace-Chip aus `set.notes`, falls nicht leer.
- `ActiveSetCard` erhält Zugriff auf den Countdown-Manager (per Injection / `@ObservedObject` bzw. Binding), analog zum bestehenden Muster.

> **🛑 STOPP-Gate C:** Build. Card rendert für Time-Set korrekt, „Satz abschließen" nur bei pausiert/abgelaufen aktiv, Countdown-Farben stimmen. „green"/„red".

---

## Phase D — Verdrahtung in ActiveWorkoutView & SetManager

**Ziel:** Manager-Lifecycle, Reset bei Übungswechsel, Abschluss-Flow-Guards.

### Schritt D.1 — `ActiveWorkoutView`
- Countdown-Manager als State halten; in `ActiveSetCard` injizieren.
- `.onChange(of: setManager.cachedCurrentSet)` (bzw. vorhandener Key-Change-Handler): bei neuem Time-Set `countdown.reset(to: set.duration)`; bei Weight-Set Countdown idle.
- `onFinished` → Haptik (`UINotificationFeedbackGenerator`, **kein Sound**).
- `onDisappear` → `cleanup()`; Vordergrund-Return → `handleForegroundReturn()`.
- **Session-Pause-Kopplung (R4):** im bestehenden `.onChange(of: sessionManager.isPaused)`-Handler: beim Pausieren `wasRunningBeforeSessionPause = countdown.isRunning && !countdown.isPaused`, dann `countdown.pause()`; beim Resume nur `countdown.resume()`, wenn der Merker `true` war.

### Schritt D.2 — `SetManager` Guards
- **RIR-Flag (R1):** `isLastWorkSet` und `cleanupLastSetFlag` müssen Time-Sätze ausschließen — `isLastSetOfExercise` für Time-Sätze **gar nicht erst setzen**. Damit erscheint kein Retro-RIR-Stift in `ExercisesOverviewCard`. (Sheet-Unterdrückung allein reicht nicht.)
- **Übungsbewertung (R1):** Die `ExerciseQualityRating`-Karte (`ExerciseCompletedCard` → `ExerciseRatingCard`) läuft für Time-Übungen automatisch. **Nur verifizieren**, dass der Completed-Pfad (`isSelectedExerciseComplete`) bei reinen Time-Übungen sauber greift und nicht am fehlenden RIR-Flag oder an `isTimeBased` hängenbleibt. Kein neues UI.
- **Volumen (R2):** `recomputeSessionVolume` Time-Sätze überspringen (`!set.isTimeBased`). Satz-Zählung (`completedSets`/`totalSets`) bleibt unverändert — Time-Sätze zählen mit.
- Rest-Timer-Start bleibt (Entscheidung 8). Superset-Rotation unverändert.

### Schritt D.2b — `StrengthSession.totalVolume`
- Time-Sätze aus `totalVolume` ausschließen (`!isTimeBased`), analog zu D.2.

### Schritt D.3 — `ExercisesOverviewCard`
- `formatSetValue`: bei `isTimeBased` Zeit (`mm:ss Min`) statt „kg × Wdh.". `ExerciseDetailRow` analog.

> **🛑 STOPP-Gate D:** Build + Voll-Test einer Time-Übung im aktiven Training (Start/Pause/Fortsetzen/Abschließen → Pause → nächster Satz). Übungsliste zeigt Zeit. Kein RIR-Sheet, **kein Retro-RIR-Stift**. Nach Übungsende erscheint die Bewertungskarte (Daumen hoch/horizontal/runter). Abbruch nach Teilzeit schreibt Ist-Zeit in `duration`. Session-Pause hält den Countdown an. „green"/„red".

---

## Phase E — StrengthDetailView & Volumen-Anzeige

### Schritt E.1 — StrengthDetailView
- Satz-Detailzeile: Time-Sätze zeigen Zeit (Ist-`duration`) statt „kg × Wdh.".
- Volumen-/„kg"-Block der Übung ausblenden, wenn alle Sätze Time-basiert sind (kein „0 kg"). `exerciseVolume` ignoriert Time-Sätze (folgt aus D.2b).

### Schritt E.2 — Weitere Volumen-/kg-Anzeigen (R2)
- `WorkoutCompletedCard` und ggf. Summary-Karten: kg-/Volumen-Zeile bei Time-Sätzen unterdrücken. Satz-Anzahl bleibt korrekt (Time zählt mit).

> **🛑 STOPP-Gate E:** Build + abgeschlossene Session mit Time-Übung in Detail-View + Completed-Card ansehen. Sätze gezählt, kein „0 kg", Ist-Zeit sichtbar. „green"/„red".

---

## Phase E2 — Persistenz / Resume (R6)

**Ziel:** Übungs-Countdown übersteht App-Kill / Wiederaufnahme.

### Schritt E2.1 — `SessionResumeState`
- Optionalen Sub-Snapshot `ExerciseCountdownSnapshot?` aufnehmen (Codable). Enthält `setUUID` zur Zuordnung.

### Schritt E2.2 — `SessionResumeStore`
- Beim Speichern des Resume-State den Countdown-Snapshot via `countdown.snapshot()` mitschreiben (nil wenn idle).

### Schritt E2.3 — `ActiveWorkoutView` Restore
- Beim Wiederaufnehmen: `countdown.restore(from:)` nur, wenn der persistierte `setUUID` zum aktuellen Time-Set passt (sonst verwerfen, Risiko §9.8). `endDate` in der Vergangenheit → `isFinished`-Zustand.

> **🛑 STOPP-Gate E2:** Test: Time-Countdown starten, App killen, neu starten → Session wird wiederaufgenommen, Countdown zeigt korrekte Restzeit (oder „abgelaufen"). „green"/„red".

---

## Phase F — Live Activity & Watch

**Ziel:** Countdown read-only in LiveActivity und auf der Watch.

### Schritt F.1 — `WorkoutActivityAttributes.ContentState`
- Neue Felder: `isExerciseCountdown: Bool`, `countdownStartDate: Date?`, `countdownEndDate: Date?`. Initializer + `Codable` erweitern. **Alle bestehenden Call-Sites** des Initializers anpassen (Defaults).

### Schritt F.2 — `LiveActivityCtrl.makeLiveContentState`
- Countdown-Felder aus dem `ExerciseCountdownManager` befüllen.

### Schritt F.3 — `MotionCoreWidgetsLiveActivity`
- Countdown-Branch rendern (system-`timerInterval` via `countdownStartDate`/`countdownEndDate`), Farblogik grün/gelb/rot, Label „Übung" statt „Pause".

### Schritt F.4 — Watch-Keys (beide Target-Kopien!)
- `WatchMessageKeys.swift` in MotionCore **und** MotionCoreWatch: `isCountdown`, `countdownEndDate` ergänzen. **Synchron halten.**

### Schritt F.5 — `PhoneSessionManager` + `WatchBridge`
- `sendWorkoutState` um `isCountdown`/`countdownEndDate` erweitern; `WatchBridge.sendState` befüllt sie.
- `WatchBridge.handleAction`: `.completeSet` ignorieren, wenn aktueller Set `isTimeBased`.

### Schritt F.6 — `WatchSessionManager` + `WatchActiveWorkoutView`
- Keys auslesen (nur aus State-Messages, analog `restEndDate`). Watch-UI zeigt Countdown read-only (Ring/Zahl), **kein** Abschließen-Button bei Time-Sätzen.

> **🛑 STOPP-Gate F:** Build beider Targets. Test: Time-Übung am iPhone starten → LiveActivity zeigt Countdown mit Farbe; Watch zeigt Countdown read-only, kein Abschließen-Button. Watch-`completeSet` während Countdown wird ignoriert. „green"/„red".

---

## Phase G — Abschluss & Verifikation

### Schritt G.1 — Edge-Case-Tests
- Gemischtes Superset (Weight + Time): Rotation + Countdown-Reset sauber.
- App in Hintergrund während Countdown → korrekte Anzeige nach Rückkehr.
- App-Kill während Countdown → Resume stellt Countdown wieder her (E2).
- Mehrere Time-Sätze hintereinander mit Pause dazwischen (kein State-Leak zwischen Countdown und Rest-Timer).
- Session-Pause während laufendem Countdown → Countdown hält an, Resume setzt nur fort wenn er vorher lief (R4).
- Teilzeit-Abbruch → korrekte Ist-Zeit in `duration`, kein Volumen, aber Satz gezählt, Bewertungskarte erscheint (R1/R2/R3).

### Schritt G.2 — Cleanup
- Debug-`print` entfernt, Dateigrößen geprüft (Split falls > 600 Zeilen), keine Force-Unwraps ohne Doku.

### Schritt G.3 — Commits
- Conventional Commits, logisch pro Phase (z. B. `feat: add SetTrackingMode for time-based exercises`, `feat: exercise countdown manager and card`, `feat: time-based exercises on watch and live activity`).

> **🛑 STOPP-Gate G:** Final-Build beide Targets, alle Edge-Cases grün. „green"/„red".

---

## Anhang — Reihenfolge-Abhängigkeiten

```
A (Modell) ──> B (Config) ──> C (Manager+Card) ──> D (Verdrahtung) ──> E (Detail/Volumen)
                                                          ├──────────> E2 (Persistenz/Resume)
                                                          └──────────> F (LA+Watch) ──> G (Final)
```
A ist Voraussetzung für alles. C/D/E/E2/F bauen auf dem Manager auf. E, E2 und F sind untereinander unabhängig und können in beliebiger Reihenfolge (oder gestaffelt) umgesetzt werden. G zuletzt.
