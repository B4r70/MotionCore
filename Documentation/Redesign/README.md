# Handoff: ActiveWorkoutView — Calm Redesign (MotionCore)

> **Für Claude Code.** Dieses Paket beschreibt das Redesign des aktiven
> Krafttrainings-Screens (`ActiveWorkoutView`) der MotionCore iOS-App, sodass die
> Umsetzung **pixelgenau** dem HTML-Designvorschlag entspricht.

---

## 1 · Überblick

`ActiveWorkoutView` ist der wichtigste und komplexeste Screen der App: das
Live-Logging eines Krafttrainings (Satz für Satz, mit Pausen-Timer, Live-Puls,
Supersätzen und PR-Erkennung). Das Redesign behält **Funktion und Information
1:1**, ändert aber die visuelle Sprache auf die ruhige 2026-Richtung: helles
Grauweiß statt dunklem „Liquid Glass", **ein** moderater Akzent (Tiefblau), flache
Karten mit Hairline-Kontur, Hanken Grotesk, minimalistische Daten.

**Zielumgebung:** Die App ist **SwiftUI + SwiftData** (iOS). Die Dateien in diesem
Paket sind **Design-Referenzen in HTML** — Prototypen, die Aussehen und Verhalten
zeigen, **kein** Produktionscode zum Kopieren. Die Aufgabe ist, diese Designs in
der **bestehenden SwiftUI-Umgebung** mit deren etablierten Mustern nachzubauen
(siehe die konkreten Datei-Verweise in §8).

**Fidelity: High-Fidelity (hifi).** Finale Farben, Typografie, Abstände und
Interaktionen. Pixelgenau nachbauen.

---

## 2 · Design-System-Fundament (gilt app-weit)

Das Redesign basiert auf einem Token-System. Diese Werte sind verbindlich; lege
sie als zentrale SwiftUI-Konstanten an (siehe **fertiges `Theme.swift` in
`DESIGN-SwiftUI.md`**, das diesem Paket beiliegt) und ersetze die alten
Glass-/Blau-Werte.

### Farben (exakt)
| Rolle | Hex | SwiftUI |
|---|---|---|
| Seiten-Hintergrund | `#F4F6F8` | `Color(hex: 0xF4F6F8)` |
| Karte / Fläche | `#FFFFFF` | `.white` |
| Inset / Track / sekundär | `#E9EDF1` | `Color(hex: 0xE9EDF1)` |
| Text primär | `#16202B` | `Color(hex: 0x16202B)` |
| Text sekundär | `#5A6877` | `Color(hex: 0x5A6877)` |
| Text tertiär | `#8A95A2` | `Color(hex: 0x8A95A2)` |
| Hairline-Border | `#D9E0E7` | `Color(hex: 0xD9E0E7)` |
| Border soft | `#E9EDF1` | `Color(hex: 0xE9EDF1)` |
| **Akzent (Tiefblau)** | `#2C6BCB` | `Color.accent` |
| Akzent hover/hell | `#3A7CDC` | — |
| Akzent pressed | `#21539E` | — |
| Akzent soft (Wash) | `rgba(44,107,203,0.08)` | `Color.accent.opacity(0.08)` |
| Akzent soft (Fläche) | `#D7E4F8` | `Color(hex: 0xD7E4F8)` |
| Erfolg / Erholung | `#1F9E6E` | `Color(hex: 0x1F9E6E)` |
| **Warnung / Streak / PR** | `#C7902F` | `Color(hex: 0xC7902F)` |
| Fehler | `#CF5656` | `Color(hex: 0xCF5656)` |
| Puls (Herz) | `#CF5656` | rot |
| Kalorien (Flamme) | `#C7902F` | amber |

> **Akzent-Hinweis:** Der DS-Standard ist Teal `#0F9488`; der Nutzer hat sich für
> diesen Screen für **Tiefblau `#2C6BCB`** entschieden. Halte den Akzent als
> **eine** zentrale Konstante, damit ein Wechsel trivial ist.

### Typografie
- **Schrift:** Die App nutzt nativ **SF Pro** — das ist die Apple-Entsprechung
  von Hanken Grotesk (humanistische Grotesk). **SF Pro beibehalten.** Große Zahlen
  in **SF Pro Rounded** (`.system(size:, weight: .bold, design: .rounded)`).
- **Zahlen immer tabular:** `.monospacedDigit()`.
- Skala (pt): Hero 48 · Metrik 36/32 · Titel 22 · Headline 17 · Body/Subhead 15 ·
  Caption 13/12 · **Eyebrow 10 UPPERCASE, letter-spacing +0.6**.
- Titel: `-0.5` tracking, Bold. Eyebrows: uppercase, tertiär-Farbe.

### Abstände, Radien, Schatten
- **8pt-Raster.** Stapel-Abstand 14–16, Karten-Polster 24 (`.padding(20–24)`).
- **Radien:** Kachel `14`, Karte `20`, Sheet/Hero `26`, Pille voll rund.
- **Schatten (Karte):** sehr leise — `color: rgba(22,32,43,0.04), radius 2, y 1`
  **plus 1px Hairline** (`.overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex:0xD9E0E7), lineWidth: 1))`).
  Karte führt mit der Hairline, **nicht** mit Schatten. Kein dunkler Glow mehr.
- **Motion:** `easeOut`/`easeInOut`, 140 / 240 / 360 ms. Ringe & Balken animieren
  ihre Füllung. Keine Bounces, keine Endlos-Loops.

---

## 3 · Screen-Aufbau (oben → unten)

Einspaltig, Scrollview, im 390pt-Phone. Fester Nav-Header oben
(Zurück · „Aktives Training" · „Beenden"-Pille), darunter scrollender Inhalt:

1. **Status-Header**
2. **Pausen-Timer** (nur während der Pause — 3 Stile, siehe §4.2)
3. **PR-Banner** (nur nach einem Rekord)
4. **Aktive Satz-Karte** (Kernstück)
5. **Übungen** (aufklappbare Liste)

---

## 4 · Komponenten im Detail

### 4.1 Status-Header  (ersetzt `ActiveWorkoutStatus` + `LiveHealthCard`)
- **Layout:** `HStack` mit drei Spalten (links/mitte/rechts), darunter ein
  Fortschrittsbalken, darunter eine Chip-Zeile. Padding `4 20 14`.
- **Links — Timer:** Icon (`clock.fill`, Akzent; bei Pause `pause.circle.fill`,
  amber) + Zeit `24:18` in **SF Pro Rounded Bold 22, monospaced**. Darunter
  Eyebrow = Plan-Name `PUSH DAY A` (bei Pause: `PAUSIERT`, amber).
- **Mitte — Volumen:** Zahl `4,3 t` (Rounded Bold 22), Eyebrow `VOLUMEN`. Format:
  `≥1000 kg → "x,x t"`, sonst `"x kg"`.
- **Rechts — Sätze:** `6/14` (Rounded Bold 22), Eyebrow `SÄTZE`.
- **Fortschrittsbalken:** Höhe 6, voll rund, Track `#E9EDF1`, Füllung **Akzent
  (einfarbig, kein Gradient)**, Breite = `done/total`, Animation `easeOut 360ms`.
- **Chip-Zeile (Live-Health):** zwei Pillen (Höhe 30, weiß, 1px Hairline):
  - `♥ 138 bpm` — Herz `heart.fill` rot, Wert primär monospaced, Einheit tertiär.
  - `🔥 214 kcal` — Flamme `flame.fill` amber.
  - Rechts außen: grüne Soft-Pille `⌚ LIVE` (`applewatch`, Erfolg-Farbe), nur wenn
    Watch aktiv trackt. Bei „connected" blau, „disconnected" grau, sonst ausblenden.
  - **Nur anzeigen, wenn mindestens ein Wert > 0** (wie im Original).

### 4.2 Pausen-Timer  (ersetzt `RestTimerCard` / `CompactRestTimerView`)
Erscheint **nach** „Satz abschließen". Drei Stile — der **Standard ist `inline`** (vom Nutzer bestimmt); `kompakt`/`vollbild`
sind optionale Alternativen (im Prototyp per Tweak):
- **`inline` (Standard):** volle Karte im Flow **anstelle** der Satz-Karte. Großer
  Ring (Ø 210, Strich 13, voll rund), Zahl in der Mitte **Rounded Bold 60,
  monospaced** (`60s`/`1:12`). Ring-Track `#E9EDF1`, Füllung **Akzent**, sobald
  ≤30s **amber**, ≤10s **rot**. Darunter `−15s` / `+15s` Pillen, dann
  „Nächster: <Übung · Satz n>", dann Primärbutton **„Pause überspringen"** (`forward.fill`).
- **`kompakt`:** schlanke Karten-Pille **oben** (Mini-Ring Ø 38 + „PAUSE 1:12" +
  „Nächster: …" + `+15s` + Skip-Icon-Button). Die Satz-Karte bleibt darunter
  sichtbar und rückt bereits auf den **nächsten** Satz vor (Loggen nicht blockiert).
- **`vollbild`:** dieselbe große Rest-Karte als zentriertes Overlay über einem
  Scrim (`rgba(20,35,59,0.40)` + Blur 3).

### 4.3 PR-Banner  (ersetzt `PRBannerView`)
- Erscheint, wenn der abgeschlossene Satz einen neuen Rekord ergab.
- **Layout:** `HStack`: runder Icon-Chip (Ø 38, amber-soft) mit `crown.fill`
  (amber) → Texte „**Neuer PR!**" (Subhead Bold) + „<Übung> · 104,2 kg 1RM"
  (Caption sekundär) → rechts Solid-Badge „REKORD" (amber).
- **Fläche:** amber-soft (`rgba(199,144,47,0.10)`), 1px amber-Kontur
  (`rgba(199,144,47,0.35)`), Radius 20. **Stilvoll, ruhig — kein Konfetti.**

### 4.4 Aktive Satz-Karte  (ersetzt `ActiveSetCard`, Weight-Zweig)
Weiße Karte (Radius 20, Hairline). Aufbau:
- **Header:** `HStack`: Thumbnail (64×64, Radius 14, akzent-soft Fläche mit
  Übungs-Icon — im Original ein Video-Standbild via `ExerciseVideoView`) →
  Texte: optionaler Set-Kind-Eyebrow (z. B. `AUFWÄRMEN`, amber, nur wenn
  `setKind != .work`), Übungsname (Headline Bold), „Satz 3 von 4" (Caption
  sekundär) + optional Badge „Vorschlag" (neutral) / `ReadinessReducedBadge` →
  rechts ein runder Icon-Button (`figure.run.square.stack` / „Anleitung", Ø 36,
  sunken). Quick-Config-Gear optional wie im Original.
- **Superset-Tracker** (nur bei Superset, siehe §4.5).
- **Hairline-Divider** (1px `#E9EDF1`, vertikaler Abstand 18).
- **Werte — Variante A „Stacked" (ENTSCHIEDEN — umsetzen, = Original):** zwei Spalten zentriert,
  `82,5` + Einheit „kg" | 1px-Trenner | `8` + „Wdh.", Zahlen **Rounded Bold 36,
  tabular**. Bei Körpergewicht: Wert `0` → Label „Körpergewicht".
- **Referenz-Zeile** (wenn aktiviert): zentriert, Caption tertiär
  „Letztes Mal: 8 Wdh. × 80 kg". (Toggle-bar — der Nutzer lässt sie **an**.)
- **Variante B „Target-led"** (verworfen — nur Referenz in `setcard-variations.html`):
  zwei Spalten „**JETZT** 82,5 kg × 8" vs. „**LETZTES MAL** 80 kg × 8". **Nicht
  umsetzen** — Variante A ist gewählt.
- **Aktionen:** `HStack`: Sekundär-Button „Anpassen" (`slider.horizontal.3`,
  akzent-soft) + Primär-Button „Satz abschließen" (`checkmark`, voll Akzent,
  füllt restliche Breite). Im Original ist „abschließen" grün — **hier Akzent**.

### 4.5 Superset-Tracker  (Teil von `ActiveSetCard`)
- Nur wenn der aktuelle Satz Teil eines Supersatzes ist.
- Fläche: erfolg-soft, Radius 14. Kopf: `bolt.fill` (Erfolg) + „SUPERSET · Runde 1/3".
- Übungs-Dots: aktive Übung = gefüllter Punkt (Erfolg), erledigt = `checkmark`,
  ausstehend = leerer Ring; Name aktiv = primär/600, sonst sekundär; `chevron.right`
  als Trenner.

### 4.6 Übungen — aufklappbare Liste  (ersetzt `ExercisesOverviewCard`)
- Karte mit `SectionHeader`: Titel „Übungen", Eyebrow „2 von 5 erledigt", rechts
  `chevron.down`. **Der ganze Header ist tippbar und klappt die Liste auf/zu.**
- **Aufklapp-Animation:** Chevron rotiert auf `-90°` (zu), Liste fährt per Höhe
  ein/aus (`easeOut 240ms`). **Standard: aufgeklappt.**
- **Zeilen:** Status-Kreis (Ø 24): erledigt = Akzent-Fläche + `checkmark` weiß;
  aktiv = akzent-soft + Nummer in Akzent; ausstehend = sunken + graue Nummer →
  Übungsname (aktiv 600/primär, ausstehend sekundär) → Badge „aktiv" (Akzent) →
  rechts Satz-Zähler `3/4` (Caption tertiär, tabular). Hairline-Trenner zwischen Zeilen.

### 4.7 Anpassen-Sheet  (ersetzt `SetEditSheet` / `ExerciseQuickConfigSheet`)
- Bottom-Sheet (Detents medium/large), Grabber, Titel „Satz anpassen",
  Untertitel „<Übung> · Satz n".
- Zwei **Stepper** (sunken, Radius 14): „GEWICHT" (±2,5 kg) und „WIEDERHOLUNGEN"
  (±1). Wert in Rounded Bold 26 + Einheit. Minus = sunken-Button, Plus = Akzent-Button.
- Primär-Button „Übernehmen" (voll Akzent) schreibt die Werte zurück in den Satz.

---

## 5 · Interaktionen & Verhalten

| Aktion | Ergebnis |
|---|---|
| **Satz abschließen** | Volumen += Gewicht×Wdh.; Sätze-Zähler +1; bei Rekord PR-Banner; Pausen-Timer startet; Satz rückt auf den nächsten vor |
| **Anpassen** | Stepper-Sheet öffnet; „Übernehmen" schreibt Gewicht/Wdh. zurück |
| **+15s / −15s** | Restzeit anpassen (min. 0) |
| **Pause überspringen / Skip** | Pause beenden → nächster Satz, logging-Modus |
| **Übungen-Header tippen** | Liste auf/zu (Chevron rotiert) |
| **Anleitung-Icon** | (Original) öffnet Übungsanleitung-Sheet |

**Timer:** Im echten App-Build tickt der Countdown sekündlich (im HTML-Prototyp
ist er bewusst statisch dargestellt). Nutze die bestehende `RestTimerManager`-Logik
der App; das Redesign betrifft nur die Darstellung.

---

## 6 · State (vorhanden in der App — Darstellung anpassen, nicht Logik)
- `mode`: logging | resting · `currentSetIndex` · `completedSets` / `totalSets`
- `sessionVolume` · `elapsedTime` · `isPaused`
- Live-Health: `currentHR` / `averageHR` / `maxHR` / `activeCalories` · `watchConnectionState`
- `restRemaining` / `restTarget` · `nextExerciseName` / `nextSetNumber`
- Superset: `supersetNames` / `round` / `totalRounds` / `currentIndex`
- PR: `prExerciseName` / `oneRM` · Liste auf/zu: lokaler `@State isExpanded`

---

## 7 · Icons (SF Symbols — nativ beibehalten)
Der HTML-Prototyp nutzt **Lucide** als Web-Ersatz. In der App die **SF Symbols**
behalten. Mapping:

| Prototyp (Lucide) | App (SF Symbol) |
|---|---|
| `clock` / `pause` | `clock.fill` / `pause.circle.fill` |
| `heart` | `heart.fill` |
| `flame` | `flame.fill` |
| `watch` | `applewatch` |
| `crown` | `crown.fill` |
| `check` | `checkmark` / `checkmark.circle.fill` |
| `forward` | `forward.fill` |
| `zap` (Superset) | `bolt.fill` |
| `sliders-horizontal` | `slider.horizontal.3` |
| `book-open` | `figure.run.square.stack` |
| `chevron-right/down/left` | `chevron.right/down/left` |
| `plus` / `minus` | `plus` / `minus` |
| `flag` | `flag.fill` |

**Keine Emoji.** Bedeutung tragen Icon + Farbe.

---

## 8 · Bezug zum bestehenden Code (welche Dateien anfassen)
Redesign der Darstellung in:
- `MotionCore/Views/Workouts/Active/View/ActiveWorkoutView.swift` (Komposition)
- `…/Active/Components/ActiveWorkoutStatus.swift` → Status-Header (§4.1)
- `…/Active/Components/LiveHealthCard.swift` → in den Header als Chips falten (§4.1)
- `…/Active/Components/ActiveSetCard.swift` → Satz-Karte (§4.4) + Superset (§4.5)
- `…/Active/Components/RestTimerCard.swift` + `CompactRestTimerView.swift` → §4.2
- `…/Active/Components/PRBannerView.swift` → §4.3
- `…/Active/Components/ExercisesOverviewCard.swift` → aufklappbare Liste (§4.6)
- zentrale Theme-/Token-Datei neu anlegen (§2) und `.glassCard()`-Stil auf den
  neuen flachen Hairline-Look umstellen.

### 8.1 · Einstieg in den Screen (Navigation)
Im Prototyp wird `ActiveWorkoutView` aus dem **„Workout starten"**-Sheet heraus
geöffnet (Option *Krafttraining*). In der App entspricht das dem bestehenden
Flow, der eine aktive `WorkoutSession` anlegt und `ActiveWorkoutView` als
Vollbild präsentiert (`.fullScreenCover` bzw. Navigation-Push). *Zurück* und
*Beenden* beenden/­schließen die Session. Siehe `MotionCore-App-prototype.html`
für den Kontext.

---

## 9 · Dateien in diesem Paket
- `README.md` — **diese Spezifikation** (verbindlich; Token-Tabellen in §2).
- `DESIGN-SwiftUI.md` — **app-weites Theme-Fundament**: fertiges `Theme.swift`
  (Color(hex:)-Extension + alle semantischen Farben), `AppFont`, `Space`/`Radius`,
  `.card()`-Modifier, SF-Symbols-Liste, Motion-Werte, **Migrations-Checkliste**
  vom alten Glass-/Blau-Theme. **Lies dies VOR der Umsetzung** und lege das
  Fundament damit an (entspricht §2).
- `ActiveWorkoutView-prototype.html` — **lauffähiger Offline-Prototyp** (Doppelklick;
  Tweaks-Panel über die Toolbar). Maßgebliche visuelle Referenz.
- `MotionCore-App-prototype.html` — **die komplette App als lauffähiger Prototyp**
  (5 Tabs). Hier ist die ActiveWorkoutView **im Kontext eingebunden**: Tab
  *Workouts* (oder *Übersicht → Training starten*) → Sheet *„Workout starten"* →
  **Krafttraining** öffnet den aktiven Trainings-Screen als Vollbild-Overlay;
  *Zurück/Beenden* schließt ihn wieder. Zeigt den realen Navigationskontext.
- `REDESIGN-PLAN.md` — Aufteilung des **gesamten** App-Redesigns in Arbeitspakete
  (AP 0–11) mit fertigen Auftragstexten für Claude Code.
- `source/index.html` — Quell-Markup des ActiveWorkout-Screens (Phone-Frame, Tweaks).
- `source/active-workout.jsx` — alle Screen-Komponenten **plus** die
  wiederverwendbare `ActiveWorkoutScreen`-Komponente (exakte Layouts/Styles).
- `source/app-index.html` · `source/screens.jsx` · `source/tweaks-panel.jsx` —
  Quellcode der **Gesamt-App** inkl. der Einbindung der ActiveWorkoutView (§8.1).
- `source/setcard-variations.html` — Satz-Karte A·Stacked vs. B·Target-led.
- `tokens/colors.css · typography.css · spacing.css · fonts.css` — die exakten
  Token-Werte (Quelle der Tabellen in §2).
- `assets/AppIcon.png` — MotionCore App-Icon.

---

## 10 · Entscheidungen (festgelegt)
1. **Satz-Karte: Variante A „Stacked"** — **entschieden** (B „Target-led" verworfen).
2. **Pausen-Timer-Standard:** `inline` — **entschieden** (vom Nutzer bestätigt). `kompakt`/`vollbild` bleiben optionale Alternativen.
3. **Übungsbilder:** Der Prototyp nutzt Icon-Kacheln. In der App das echte
   `ExerciseVideoView`-Standbild im 64×64-Thumbnail-Slot beibehalten.
