# Concept: Zeitbasierte Übungen (Set-Reps-Time)

**Version:** 1.1
**Datum:** 2026-06-06
**Autor:** Bartosz Stryjewski
**Status:** Approved (Q&A + Review-Runde abgeschlossen)
**Area:** MotionCore / Active Workout
**Priority:** High

> **Changelog v1.1:** RIR komplett raus, stattdessen bestehende `ExerciseQualityRating`-Bewertung (Daumen hoch/horizontal/runter) nach Time-Übungen sicherstellen (§5.3.1). Time-Sätze zählen ins Satz-Total, aber nicht ins Volumen (§5.5/§5.6). Tatsächlich gelaufene Zeit wird beim Abschließen zurückgeschrieben (§5.3.2). Session-Pause hält den Übungs-Countdown an (§5.1/§5.4). Countdown-State wird in `SessionResumeStore` mitpersistiert (§5.7). Nur Haptik, kein Sound (§5.2).

---

## 1. Ziel & Motivation

Der neue Trainingsplan enthält Übungen, die nicht über Gewicht × Wiederholungen
definiert sind, sondern über **Zeit** — z. B. Ruderergometer (5 Min, Pace 2:50/500m),
Cross-Trainer (5 Min, 8 km/h), Seilspringen (5 Min). MotionCore kennt bislang nur
das Modell **Set-Reps-Weight**. Es soll ein zweiter Modus **Set-Reps-Time** ergänzt
werden, ohne die bestehende Weight-Logik zu verändern.

Leitprinzip: **additiv, nicht invasiv.** Weight-Übungen verhalten sich exakt wie
heute. Time-Übungen sind ein zusätzlicher Pfad, der an klar definierten Stellen
abzweigt. Kein Big-Bang-Umbau von `ActiveWorkoutView` oder `completeSet`.

---

## 2. Entscheidungen aus dem Q&A

| # | Frage | Entscheidung |
|---|-------|--------------|
| 1 | Wo lebt der Modus-Marker? | **Neues Feld auf `ExerciseSet`** — pro Übung, gemischte Pläne möglich. |
| 2/5 | Reps bei Time-Übungen? | **Reps entfällt.** Time-Mode = N Sätze (= N `ExerciseSet`-Objekte), jeder mit eigener `duration`. `reps` bleibt `0` und wird nirgends angezeigt. |
| 3 | Pace/Geschwindigkeit? | **Freitext im Notizfeld** (`notes`). Kein strukturiertes Feld. |
| 4 | Hintergrund-Countdown? | **Ja, `Date`-Anker** wie `RestTimerManager`. |
| 6 | Buttons in der Card? | **Ein Toggle-Button Start → Pause/Fortsetzen** + separater Button **„Satz abschließen"**. |
| 7 | Watch-Verhalten? | **Watch zeigt Countdown nur an.** Abschließen ausschließlich am iPhone. |
| 8 | Pause nach Time-Satz? | **Ja, normaler Rest-Timer** läuft wie bei Weight-Sätzen. |
| 9 | Umschaltung im Config-Sheet? | **Segmented Control oben im Sheet**, schaltet die darunterliegende UI um. |
| 10 | Countdown erreicht 0? | **Stoppt bei 0 + Haptik** (kein Sound), „Satz abschließen" wird aktiv. |
| 11 | Optik? | **Wie Pausentimer**: Ring + große Mono-Ziffern, Farbverlauf grün → gelb → rot. |

### Review-Runde (v1.1)

| # | Punkt | Entscheidung |
|---|-------|--------------|
| R1 | RIR-Flag bei Time-Sätzen? | **Flag gar nicht erst setzen.** RIR ist für Time-Übungen nicht sinnvoll. Stattdessen die bestehende `ExerciseQualityRating`-Bewertung (gut/mittel/schlecht) nach der Übung nutzen — die läuft ohnehin über `ExerciseCompletedCard`. |
| R2 | Time-Sätze im Volumen? | **Sätze zählen ins Satz-Total**, aber **raus aus der Volumen-Berechnung** (kein „0 kg"). |
| R3 | Welche Zeit wird gespeichert? | **Tatsächlich gelaufene Zeit.** Abbruch nach 3 von 5 Min → `duration = 180` wird zurückgeschrieben. |
| R4 | Session-Pause ↔ Countdown? | **Globale Session-Pause hält auch den Übungs-Countdown an** (Konsistenz). |
| R5 | Timer-Ende-Signal? | **Nur Haptik.** Kein Sound (gibt es nirgends in der App). |
| R6 | Countdown nach App-Kill? | **Countdown-State mitpersistieren** über `SessionResumeStore`. |

---

## 3. Datenmodell

### 3.1 Neues Feld auf `ExerciseSet`

```swift
/// Tracking-Modus dieses Satzes. Default .weight für Rückwärtskompatibilität.
var trackingModeRaw: String = "weight"

var trackingMode: SetTrackingMode {
    get { SetTrackingMode(rawValue: trackingModeRaw) ?? .weight }
    set { trackingModeRaw = newValue.rawValue }
}

var isTimeBased: Bool { trackingMode == .time }
```

Neuer Enum in `StrengthTypes.swift` (oder `ExerciseTypes.swift`, beim SetKind):

```swift
enum SetTrackingMode: String, Codable, CaseIterable, Identifiable {
    case weight = "weight"   // Set-Reps-Weight (Bestand)
    case time   = "time"     // Set-Reps-Time (neu)

    var id: String { rawValue }
    var description: String {
        switch self {
        case .weight: return "Gewicht"
        case .time:   return "Zeit"
        }
    }
}
```

**Begründung Default `.weight`:** SwiftData-Migration. Alle bestehenden Sets (und alle
ohne explizit gesetzten Modus) bleiben Weight-Sätze. `duration` existiert bereits im
Modell (`var duration: Int = 0`, Sekunden) und wird im Time-Mode endlich aktiv genutzt.

### 3.2 Felder-Belegung im Time-Mode

| Feld | Weight-Mode | Time-Mode |
|------|-------------|-----------|
| `weight` / `weightPerSide` | aktiv | `0` (ungenutzt) |
| `reps` | aktiv | `0` (ungenutzt) |
| `duration` | `0` | **Sekunden pro Satz** (z. B. 300) |
| `restSeconds` | aktiv | aktiv (Pause zwischen Sätzen) |
| `targetRIR` | aktiv | ungenutzt |
| `notes` | optional | **Pace-/Geschwindigkeitsvorgabe als Freitext** |
| `setKind` | work/warmup/… | i. d. R. `.work` |

### 3.3 Propagation des neuen Feldes (kritisch)

`trackingModeRaw` MUSS an allen Set-Anlege-/Kopierpfaden mitgeführt werden, sonst geht
der Modus beim Trainingsstart oder Sync verloren:

1. **`ExerciseSet.init`** — neuer Parameter `trackingMode: SetTrackingMode = .weight`.
2. **`cloneForSession()`** — Modus + `duration` mitkopieren (duration wird heute schon kopiert, Modus fehlt).
3. **`Export.swift`** (`ExerciseSetExportItem` + `exportItem` + `fromExportItem`) — Feld ergänzen, rückwärtskompatibel (optional, Default `.weight`).
4. **`SupabaseFullBackupService`** / DTOs — Feld in den Backup-Payload aufnehmen.

---

## 4. Trainingsplan-Erstellung (Config-Sheet)

Betroffen: **`SetConfigurationSheet.swift`**

### 4.1 Segmented Control

Oben im Sheet ein `Picker(.segmented)` mit den zwei Modi. State: `@State private var trackingMode: SetTrackingMode`. Bootstrap aus `initialSets` (erster Work-Set bestimmt den Modus beim Editieren).

### 4.2 Bedingte UI

| Bereich | Weight-Mode | Time-Mode |
|---------|-------------|-----------|
| Sätze-Anzahl (`numberOfSets`) | ✓ | ✓ |
| Reps-Stepper | ✓ | ✗ |
| Gewicht-Stepper | ✓ | ✗ |
| **Zeit pro Satz** (neu, mm:ss) | ✗ | ✓ |
| Aufwärmsätze | ✓ | ✗ |
| Pausenzeit | ✓ | ✓ |
| Ziel-RIR | ✓ | ✗ |
| Notiz (Pace) | optional | ✓ (hervorgehoben) |

Der Zeit-pro-Satz-Picker analog zur bestehenden `SetRestTimeSection` (Preset-Buttons
30/60/120/180/300 s + ±15 s Feineinstellung), aber als eigenständige `SetDurationSection`.

### 4.3 `saveSets()`

Bei `trackingMode == .time`:
- N Work-Sets erzeugen (`numberOfSets`), jeweils `duration = gewählteSekunden`, `weight = 0`, `reps = 0`, `setKind = .work`, `restSeconds = restSeconds`, `trackingMode = .time`, `notes = paceNote`.
- Keine Warmup-Sets, kein `targetRIR`.

---

## 5. Active Workout

### 5.1 Neuer Manager: `ExerciseCountdownManager`

Eigene Klasse analog zu `RestTimerManager` (NICHT wiederverwenden — sonst Kollision
zwischen Übungs-Countdown und Satzpause bei mehreren Time-Sätzen).

```swift
@MainActor
final class ExerciseCountdownManager: ObservableObject {
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var endDate: Date?
    private(set) var targetSeconds: Int = 0

    var onFinished: (() -> Void)?   // nur Haptik (kein Sound)

    func start(seconds: Int)        // Date-Anker setzen, Loop starten
    func pause()                    // verbleibende Sekunden einfrieren
    func resume()                   // neuen endDate aus remaining berechnen
    func reset(to seconds: Int)     // für nächsten Satz
    func handleForegroundReturn()   // wie RestTimerManager
    func cleanup()

    /// Tatsächlich abgelaufene Zeit seit Start (für Rückschreiben in duration).
    var elapsedSeconds: Int { max(0, targetSeconds - remainingSeconds) }

    // Persistenz (R6): minimaler Snapshot für SessionResumeStore
    func snapshot() -> ExerciseCountdownSnapshot?   // nil wenn idle
    func restore(from: ExerciseCountdownSnapshot)
}
```

`Date`-Anker-Logik 1:1 von `RestTimerManager` übernehmen (Timer mit `RunLoop.main`,
`.common`-Mode, `[weak self]`, Identitätscheck `t === self.timer`). Bei `remaining <= 0`:
`isFinished = true`, `isRunning = false`, `onFinished?()`.

**Abschluss-Gate:** „Satz abschließen" ist nur betätigbar, wenn `isFinished || isPaused`
(d. h. NICHT während `isRunning && !isPaused`).

**Session-Pause-Kopplung (R4):** Wird die Session global pausiert (`sessionManager.isPaused`),
ruft `ActiveWorkoutView` `countdown.pause()` auf; bei Resume `countdown.resume()` — aber nur,
wenn der Countdown vor der Session-Pause lief. Sonst läuft die Übungszeit weiter, während die
Session „pausiert" ist (inkonsistent).

### 5.2 ActiveSetCard

`ActiveSetCard` bekommt einen bedingten Zweig: `if set.isTimeBased { … } else { /* Bestand */ }`.

Time-Zweig enthält:
- **Countdown-Ring** (neue `ExerciseCountdownTimerView`, optisch wie `RestTimerCard`-Ring, aber Label „Übung läuft" statt „Pause" → klare Abgrenzung; Farbe grün → gelb (letzte Minute) → rot (letzte 10 s)).
- **Button-Zeile** (eingebettet, nicht 3 breite Buttons untereinander):
  - Primär: Toggle **„Start" / „Pause" / „Fortsetzen"** (Icon + Label, Capsule).
  - Sekundär: **„Satz abschließen"** — disabled solange `isRunning && !isPaused`.
- Pace-Notiz (`set.notes`) als kleiner Hinweis-Chip, falls vorhanden.

Der Countdown wird vom `ExerciseCountdownManager` getrieben, der in `ActiveWorkoutView`
gehalten und in die Card injiziert wird (analog `restTimerManager`).

Farb-/Fortschrittslogik (analog Pausentimer, an deine Vorgabe angepasst):
```
remaining > 60s     → grün
10s < remaining ≤ 60 → gelb
remaining ≤ 10s     → rot
```

### 5.3 Abschluss-Flow (`SetManager.completeSet`)

`completeSet` bleibt im Kern unverändert. Time-spezifische Guards:
- **PR-Detection:** greift bereits nicht (`weight > 0 && reps > 0`). Kein Eingriff nötig.
- **RIR-Flag:** Bei Time-Sätzen wird `isLastSetOfExercise` **gar nicht erst gesetzt** (R1). `isLastWorkSet`/`cleanupLastSetFlag` müssen Time-Sätze ausschließen — sonst erscheint der Retro-RIR-Stift in der `ExercisesOverviewCard`. Guard direkt in der Flag-Setzung, nicht nur beim Sheet.
- **Rest-Timer:** läuft wie gehabt (`restShouldStart.send(set.restSeconds)`) — Entscheidung 8.
- **Superset-Rotation:** unverändert. Time-Sätze rotieren genauso über `handleSupersetRotation`.

#### 5.3.1 Übungsbewertung statt RIR (R1)

Die bestehende `ExerciseQualityRating`-Mechanik ist die richtige Entsprechung für deine
Anforderung „Daumen hoch / horizontal / runter":

| Rating | Icon | Label | Bedeutung Time-Übung |
|--------|------|-------|----------------------|
| `.good` | `hand.thumbsup.fill` (grün) | „Gut" | Übung lief gut |
| `.neutral` | `hand.point.right.fill` (orange) | „Mittel" | gerade so geschafft |
| `.poor` | `hand.thumbsdown.fill` (rot) | „Schlecht" | abbrechen müssen |

Diese Karte (`ExerciseRatingCard`) erscheint heute schon über `ExerciseCompletedCard`
nach **jeder** abgeschlossenen Übung — also auch nach Time-Übungen, ohne neuen Code.
**Zu tun:** nur sicherstellen, dass der Completed-/Rating-Pfad nicht versehentlich an
`isTimeBased` oder am fehlenden RIR-Flag scheitert. Kein neues UI-Element bauen.

#### 5.3.2 Tatsächlich gelaufene Zeit zurückschreiben (R3)

Beim „Satz abschließen" eines Time-Satzes wird `set.duration` auf die **tatsächlich
gelaufene** Zeit gesetzt: `set.duration = countdown.elapsedSeconds` (Soll minus Rest).
Voller Ablauf → `duration` bleibt = Soll. Abbruch nach 3 von 5 Min → `duration = 180`.
Das Rückschreiben passiert in der Card-Action *vor* dem Aufruf von `completeSet`, oder
in `completeSet` selbst, wenn der Manager dort erreichbar ist (Developer entscheidet die
saubere Stelle; das Konzept fordert nur: Ist-Zeit landet in `duration`).

### 5.4 ActiveWorkoutView-Verdrahtung

- `@StateObject` (bzw. `@State` bei `@Observable`) für `ExerciseCountdownManager`.
- Beim Wechsel auf einen Time-Set (neuer `cachedCurrentSet` mit `isTimeBased`): Countdown **resetten** via `reset(to: set.duration)` (kein Auto-Start — Entscheidung 6).
- `onFinished` → Haptik (`UINotificationFeedbackGenerator`, kein Sound).
- `cleanup()` bei `onDisappear`, `handleForegroundReturn()` beim Vordergrund-Return.
- **Session-Pause-Kopplung (R4):** im bestehenden `.onChange(of: sessionManager.isPaused)`-Handler zusätzlich den Countdown pausieren/fortsetzen — aber nur, wenn er vor der Session-Pause lief (`wasRunningBeforeSessionPause`-Merker, damit ein bereits manuell pausierter Countdown nicht versehentlich wieder anläuft).

### 5.5 ExercisesOverviewCard (Übungsliste)

`formatSetValue` erweitern: bei `set.isTimeBased` → `"\(formatDuration(set.duration))"`
(z. B. „5:00 Min") statt „X kg × Y Wdh.". `ExerciseDetailRow` analog.

### 5.6 Volumen & Satz-Zählung (R2)

**Klarstellung:** Time-Sätze zählen ganz normal ins **Satz-Total** (`completedSets`,
`totalSets`, „N Sätze"-Anzeige), aber **nicht ins Volumen**:
- `SetManager.recomputeSessionVolume`: Filter ergänzen, Time-Sätze überspringen (`!set.isTimeBased`).
- `StrengthSession.totalVolume`: ebenso Time-Sätze ausschließen.
- Session-/Übungs-Anzeigen mit „kg"/Volumen: bei Time-Sätzen die kg-/Volumen-Zeile ausblenden statt „0 kg" zu zeigen (WorkoutCompletedCard, Summary, StrengthDetailView).

### 5.6b StrengthDetailView

Satz-Detailzeile: bei Time-Sätzen Zeit (Ist-`duration`) statt „kg × Wdh." anzeigen.
Volumen-Block der Übung ausblenden, wenn alle Sätze Time-basiert sind (kein „0 kg").
`exerciseVolume` ignoriert Time-Sätze (folgt aus §5.6).

### 5.7 Persistenz / Resume (R6)

Der Countdown-State (Ziel, verbleibende Sekunden bzw. `endDate`, `isPaused`) wird in den
bestehenden `SessionResumeStore`/`SessionResumeState` als optionaler Sub-Snapshot
aufgenommen. Beim Wiederaufnehmen einer Session stellt `ActiveWorkoutView` den Countdown
via `countdown.restore(from:)` wieder her. `Date`-Anker macht das robust: Lief der Timer
beim Kill weiter, ist nach Neustart die korrekte Restzeit (oder „abgelaufen") sichtbar.
Bei `endDate` in der Vergangenheit → direkt `isFinished`-Zustand.

---

## 6. Live Activity & Watch

### 6.1 `WorkoutActivityAttributes.ContentState`

Neue Felder (analog zu `restStartDate`/`restEndDate`):
```swift
public var isExerciseCountdown: Bool          // läuft gerade ein Übungs-Countdown?
public var countdownStartDate: Date?
public var countdownEndDate: Date?
```
Damit kann das Widget den Countdown system-seitig via `timerInterval` rendern und die
Farblogik selbst anwenden. `LiveActivityCtrl.makeLiveContentState()` befüllt die Felder
aus dem `ExerciseCountdownManager`.

### 6.2 Watch (`WatchMessageKeys`, `PhoneSessionManager`, `WatchSessionManager`)

Neue State-Keys (in **beiden** Target-Kopien von `WatchMessageKeys.swift` pflegen!):
```swift
static let isCountdown        = "isCountdown"
static let countdownEndDate   = "countdownEndDate"
```
`PhoneSessionManager.sendWorkoutState` um diese Parameter erweitern; `WatchBridge.sendState`
befüllt sie. `WatchSessionManager` liest sie analog zu `restEndDate` (nur aus State-Messages).

**Watch-UI:** zeigt den Countdown read-only an (Ring/Zahl). **Kein** „Satz abschließen"-
Button für Time-Sätze auf der Watch (Entscheidung 7). Die bestehende `completeSet`-Action
der Watch darf bei einem aktiven Time-Set nicht greifen → in `WatchBridge.handleAction`
`.completeSet` ignorieren, wenn der aktuelle Set `isTimeBased` ist.

---

## 7. Explizit NICHT im Scope (später)

- Smart Progression für Time-Übungen (raus).
- Statistik & Rekorde für Time-Übungen (raus).
- Strukturierte Pace-Erfassung (nur Freitext im Notizfeld).
- **`distance`-Feld** (Ruder/Cross-Trainer thematisch passend) — bewusst auf später verschoben, kommt mit dem Statistik-Feature.
- Auto-Start des Countdowns.
- Sound beim Timer-Ende (nur Haptik).

---

## 8. Betroffene Dateien (Überblick)

**Modell/Types:**
`ExerciseSet.swift`, `StrengthTypes.swift` (oder `ExerciseTypes.swift`), `Export.swift`,
`SupabaseFullBackupService.swift` (+ ggf. `SupabaseSessionModels.swift`), `StrengthSession.swift` (totalVolume-Filter).

**Config:**
`SetConfigurationSheet.swift` (+ neue `SetDurationSection` in `FormViewSection.swift` oder eigener Datei).

**Active Workout:**
`ExerciseCountdownManager.swift` (NEU), `ExerciseCountdownTimerView.swift` (NEU),
`ActiveSetCard.swift`, `ActiveWorkoutView.swift`, `SetManager.swift` (RIR-Flag-Guard + Volumen-Filter),
`ExercisesOverviewCard.swift`.

**Persistenz/Resume (R6):**
`SessionResumeState.swift`, `SessionResumeStore.swift` (Countdown-Sub-Snapshot).

**Detail / Volumen-Anzeige (R2):**
`StrengthDetailView.swift`, `WorkoutCompletedCard.swift`, ggf. Summary-Karten mit kg-/Volumen-Anzeige.

**Live Activity / Watch:**
`WorkoutActivityAttributes.swift`, `LiveActivityCtrl.swift`,
`MotionCoreWidgetsLiveActivity.swift`, `WatchMessageKeys.swift` (×2 Targets),
`PhoneSessionManager.swift`, `WatchBridge.swift`, `WatchSessionManager.swift`,
`WatchActiveWorkoutView.swift`.

> **Hinweis:** Die `ExerciseQualityRating`-Bewertung (R1) erfordert **keine** neue Datei — `ExerciseRatingCard` / `ExerciseCompletedCard` / `rateExercise` existieren und greifen für Time-Übungen automatisch. Nur Nicht-Brechen sicherstellen.

---

## 9. Risiken & Edge Cases

1. **SwiftData-Migration:** Neues Feld mit Default → lightweight migration, kein Schema-Bruch. `duration` existiert bereits.
2. **Gemischte Supersets** (Weight + Time in einer Gruppe): Rotation läuft über `completeSet`; Countdown-Reset muss beim Rotations-Wechsel sauber feuern. Beim STOPP-Gate gezielt testen.
3. **Pause-Kollision:** Übungs-Countdown und Rest-Timer dürfen nie gleichzeitig sichtbar sein. Reihenfolge: Countdown abschließen → „Satz abschließen" → Rest-Timer. Zwei getrennte Manager verhindern State-Vermischung.
4. **Hintergrund-Rückkehr:** Beide Timer über `Date`-Anker; `handleForegroundReturn()` für Countdown ergänzen, sonst springt die Anzeige.
5. **Watch-Race:** verspätete `completeSet`-Action der Watch während laufendem Countdown → in `handleAction` guarden.
6. **RIR-Flag-Leak (R1):** `isLastSetOfExercise` darf bei Time-Sätzen nicht gesetzt werden — sonst Retro-RIR-Stift in der Übungsliste. Guard an der Flag-Quelle (`isLastWorkSet`/`cleanupLastSetFlag`), nicht nur am Sheet.
7. **Doppelte Session-Pause-Logik (R4):** Merker nötig, damit ein manuell pausierter Countdown bei Session-Resume nicht ungewollt weiterläuft.
8. **Resume-Konsistenz (R6):** Persistierter Countdown muss zum persistierten Set passen (gleiche `setUUID`). Beim Restore prüfen, dass der aktuelle Set noch der Time-Set ist, für den der Snapshot galt — sonst verwerfen.
