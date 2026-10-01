# MotionCore — Redesign-Plan (Calm 2026)

Arbeitspakete (AP) für das vollständige App-Redesign. Jedes AP ist einzeln an
Claude Code übergebbar. **Regelwerk für alle:** `DESIGN-SwiftUI.md`.
**Visuelle Wahrheit:** die HTML-Prototypen im Design-System bzw. die exportierten
Standalone-Dateien (`MotionCore App.html`, `MotionCore ActiveWorkout.html`).

**Reihenfolge = Abhängigkeit.** Phase 0 zuerst und in *einem* PR mergen, sonst
kollidieren parallele Screen-PRs an den Tokens.

> **App-Akzent festgelegt:** **Tiefblau `#2C6BCB`** (app-weit, gilt für jeden Screen).
> In `Theme.accent` gesetzt — nie eine zweite Akzentfarbe einführen.

---

## Phase 0 — Fundament (Blocker)

### ☐ AP 0 · Theme & Foundations
- [ ] `Theme.swift` anlegen (Color(hex:)-Extension + alle semantischen Farben aus §2)
- [ ] `AppFont`, `Space`, `Radius` Enums (§3, §4)
- [ ] `.card()`-Modifier (§5), ersetzt `.glassCard()`
- [ ] `AnimatedBackground`/Blobs entfernen → flacher `Theme.surfaceApp`
- [ ] Verstreute Hex-/`Color.blue/green/red`-Werte auf `Theme.*` migrieren (Checkliste §10)
- **Fertig wenn:** alles kompiliert auf neuen Tokens (Layout darf noch alt sein), kein Hex mehr im View-Code.

### ☐ AP 1 · Geteilte Bausteine
- [ ] Button (primär/sekundär/ghost), Chip, Badge, StatTile, SectionHeader
- [ ] FactorBar, ProgressRing, Sparkline/Charts (einfarbig, kein Gradient)
- [ ] TabBar (gefrostet) + Bottom-Sheet-Stil
- **Fertig wenn:** je Komponente eine SwiftUI-Preview im neuen Stil.

---

## Phase 1 — Kern-Screens (nach AP 0/1 parallelisierbar)

### ☐ AP 2 · Übersicht / Home  — Richtung **A · Ring Hero**
`Views/Summary/**` · Referenz: `MotionCore App.html` (Tab Übersicht)

### ☐ AP 3 · ActiveWorkoutView  ✅ bereits spezifiziert
`Views/Workouts/Active/**` · Referenz: `design_handoff_active_workout/README.md`
+ `MotionCore ActiveWorkout.html`. Entschieden: Satz-Karte **A „Stacked"**, Timer **inline**, Übungsliste **aufklappbar**.

### ☐ AP 4 · Workouts-Liste + Detail
`Views/Workouts/**`, `WorkoutCard`, `StrengthDetailView` · Karten, Filter, Outdoor/Strength.

### ☐ AP 5 · Statistik
`Views/Statistics/**` · Volumen, PRs, Verteilungen — minimalistische Charts (`Theme.series`).

### ☐ AP 6 · Body
`Views/Body/**`, `Views/Heatmap/**` · Erholungs-Ring, Körpermaße, Gruppen-Balken, Muskel-Heatmap.

### ☐ AP 7 · Training / Pläne
`Views/Training/**` · Plan-Karten, Set-Konfiguration, Übungs-Picker, Import.

---

## Phase 2 — Rand & Politur

### ☐ AP 8 · Settings & Onboarding
`Views/Settings/**` · viele Zeilen/Sheets, eher mechanisch.

### ☐ AP 9 · Readiness-Detail & geteilte Sheets
`Views/Readiness/**`, `Views/Shared/**`.

### ☐ AP 10 · Apple-Watch-App
Eigene Zielplattform, reduzierter Token-Satz (Akzent, Text, Surface, eine Kennzahl).

### ☐ AP 11 · QA & Politur
Dark-Mode-Strategie, Dynamic Type, Reduced-Motion, Kontrast (WCAG AA), Konsistenz-Durchlauf.

---

## Empfohlene Wertreihenfolge
**0 → 1 → 2** (Home, erster Eindruck) **→ 3** (ActiveWorkout, Kern-Use-Case) **→ 6**
(Body) **→ 5** (Statistik) **→ 4 → 7 →** Phase 2.

---

# Anhang — Auftragstexte für Claude Code

> Pro AP: eigener Branch + eigener PR. Kopiere den Block in Claude Code.

### AP 0
```
Lies DESIGN-SwiftUI.md vollständig. Lege das Farb-/Typo-/Spacing-Fundament an:
Theme.swift (Color(hex:)-Extension + alle Theme.*-Farben aus §2), AppFont (§3),
Space/Radius (§4), den .card()-Modifier (§5). Ersetze .glassCard() überall durch
.card(). Entferne AnimatedBackground/Blobs und setze Theme.surfaceApp als
App-Hintergrund. Migriere verstreute Hex- und Color.blue/green/red-Werte auf
Theme.* nach der Checkliste §10. Ziel: alles kompiliert auf den neuen Tokens,
kein rohes Hex mehr im View-Code. Layout darf vorerst unverändert bleiben.
```

### AP 1
```
Aufbauend auf Theme/AppFont/.card(): Baue die geteilten UI-Bausteine gemäß
DESIGN-SwiftUI.md §9 — Button (primär/sekundär/ghost), Chip, Badge, StatTile,
SectionHeader, FactorBar, ProgressRing, Sparkline/Charts, gefrostete TabBar,
Bottom-Sheet-Stil. Charts einfarbig (Theme.accent / Theme.series), kein Gradient.
Lege für jede Komponente eine SwiftUI-Preview im neuen Stil an. Nutze nur Theme.*
und AppFont.*, keine rohen Hexwerte.
```

### AP 2 (Home) — Muster für AP 4–9
```
Redesigne <SCREEN> in <Views/PFAD/**> nach DESIGN-SwiftUI.md, mit den Bausteinen
aus AP 1. Visuelle Referenz: <REFERENZ-DATEI>. Übernimm Layout, Hierarchie und
Abstände aus der Referenz; ändere keine Geschäftslogik/Datenflüsse. Nur Theme.*,
AppFont.*, .card(). Eine Leitfarbe, kein Glas, keine Blobs, keine
Farbverlauf-Fortschritte. Liefere SwiftUI-Previews der Hauptzustände.
```
*(Für AP 2: SCREEN = Übersicht/Home, PFAD = Summary, Referenz = „MotionCore App.html", Richtung A · Ring Hero.)*

### AP 3 (ActiveWorkoutView)
```
Setze design_handoff_active_workout/README.md 1:1 um in Views/Workouts/Active/**.
Entschieden: Satz-Karte Variante A „Stacked", Pausen-Timer inline, Übungsliste
aufklappbar (DisclosureGroup-Verhalten). Referenz: MotionCore ActiveWorkout.html.
Regelwerk: DESIGN-SwiftUI.md. Keine Logikänderung am Workout-Tracking.
```
