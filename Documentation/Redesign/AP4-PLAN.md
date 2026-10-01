# AP 4 · Workouts-Liste + Detail — Geschärfter Plan (Grilling-Ergebnis)

> Stand: 2026-06-26. Ergebnis einer Grilling-Session über den AP-4-Auftrag.
> Grundlagen: `SESSION-HANDOFF.md` §6, `MotionCore_Redesign_Instruction.md` (AP 4),
> `DESIGN.md`, Prototyp `source/screens.jsx` (`WorkoutsScreen`).
> **Eiserne Regel bleibt: NUR Darstellung, keine Logik/Datenmodell/Bindings/Gesten.**

---

## Scope-Korrektur (am Code verifiziert)

- **`TrainingListView` ist NICHT der Host** der Session-Karten — das sind die Trainings­**pläne** (→ AP 7). **OUT.**
- **Echter List-Host = `Views/Workouts/View/ListView.swift` + `Views/Workouts/Components/ListViewWrapper.swift`.** Diese ersetzen `TrainingListView` in der AP-4-Dateiliste.
- `ListView` hat einen **eigenen inline `workoutTypeSelector`** (Alle/Cardio/Kraft/Outdoor, Icon-Segmented-Control mit rohem `Color.blue.opacity`, `.ultraThinMaterial`, `Color.white.opacity`) **und** `AnimatedBackground(showAnimatedBlob:)`.
- `FilterChip`/`FilterSection` werden in **`BaseView`** (Geräte-/Zeitfilter der Workout-Liste) **und in `ExercisePickerView` (AP 7)** genutzt → Migration vererbt sich auf AP 7 (gewollt).
- `StatBubble` (`Components/Elements/StatBubble.swift`) wird von WorkoutCard, OutdoorSessionCard, StrengthSessionCard, OutdoorDetailView genutzt — **AP-4-lokal**, kein Fremd-Screen-Risiko.
- **`TypeBreakdownCard` ist NICHT AP 4** — liegt in `Views/Summary/`, genutzt von `SummaryView` (AP 2, fertig), bereits Theme-konform (0 rohe Farben). **OUT.**

---

## Entscheidungen (Grilling)

1. **Card-Struktur: Restyle-in-place.** Struktur/Inhalt/Logik der Karten bleiben (Übungs-Vorschau, Intensitäts-Stars, Progress, Performance-Grids). Nur **Farbdichte** kollabiert auf Prototyp-Niveau: ein Typ-Ton pro Karte, Metriken werden neutraler Text. Prototyp = visuelle Wahrheit für Ästhetik/Farbdichte, NICHT für Informations-Architektur.

2. **Metrik-Farben → semantische Map** (wie AP 5 + DESIGN.md §101–102): Puls→`danger`, Kalorien→`warning`, neutrale Daten (Dauer/Distanz/Speed/Volumen/METS)→`series[0]` bzw. neutraler `textSecondary`-Text. App-weit identisch.

3. **Typ-Ton (Icon-Tile, ein Ton/Karte)** — Instruction-Default:
   - Kraft → `accentWash`-Fläche + `accent`-Icon
   - Outdoor → `success.opacity`-Fläche + `success`-Icon
   - Cardio → `series[1].opacity`-Fläche + `series[1]`-Icon

4. **Effort-Skalen:**
   - `Intensity.color` (TypesUI.swift) **UNVERÄNDERT** (Domänen-Enum, liegt schon auf Theme — wie `setKind.color` bewusst gelassen).
   - **Intensität-Darstellung kontextabhängig:** auf der **Liste-Karte** neutral (`textSecondary`-Stars/Text, kein Ampel-Tint → ein Ton pro Karte). Im **Detail-View** bleibt `Intensity.color` als volle Ampel-Skala. (`Intensity.color` selbst bleibt unverändert; nur die Karte ruft es nicht mehr für den Tint auf.)
   - `rpeColor()` (StrengthDetailView): rohe Farben → Theme-Tokens, gleiche Effort-Skala: `.green`→`success`, `.yellow`→`series[3]`/`warning`, `.orange`→`warning`, `.red`→`danger`.

5. **`OutdoorActivity.tint`** (OutdoorTypes.swift, rohe Per-Aktivitäts-Farben) → **auf `Theme.success` kollabieren.** Aktivität wird nur noch über das SF-Symbol unterschieden (bike/running/hiking), nicht über Farbe.

6. **Filter:** `workoutTypeSelector` → AP-1-`Chip`-Reihe (Text, wie Prototyp). `FilterChip`/`FilterSection` → AP-1-`Chip`/Theme. **ExercisePicker (AP 7) erbt den neuen Chip** — gewollte Design-System-Migration, AP 7 muss sie nicht erneut anfassen.

7. **`AddExerciseDuringWorkoutSheet`: in AP 4** (eigenes Gate 4). Schließt die einzige un-redesignte Fläche im fertigen AP-3-Active-Flow. Nur Control-Tints → Theme; **Timer-/LongPress-/`context.insert()`-Logik UNANGETASTET.**

8. **Live-Indikator (StrengthSessionCard aktive Session):** Endlos-Puls (`pauseIconScale`/`runningCircleScale`) **entfernen** → ruhiger statischer Indikator (gefüllter Dot + Label). Konsistent mit Endlos-Loop-Regel + AP-3-Präzedenz (Watch-Puls). Logik (`getActiveSessionID()`/`isPaused`) bleibt.

9. **Flächen:** `.ultraThinMaterial` der Session-Karten → `.card()`. `NewWorkoutSheet` (Sheet) darf Material behalten. `ListView`-`AnimatedBackground` → `Theme.surfaceApp`.

---

## STOPP-Gates (je grün/rot, Build nach jedem)

> **Branch-Basis:** `redesign/ap4-workouts` von `redesign/ap1-shared-components` abzweigen,
> dann **`fix/strength-detail-horizontal-scroll` (f69c5fc) hineinmergen**, sodass
> StrengthDetailView vom gefixten Stand aus startet.

- **G1 · Liste + Karten** — `ListView`, `ListViewWrapper`, `workoutTypeSelector`→Chip, `AnimatedBackground`→`surfaceApp`, `WorkoutCard`, `StrengthSessionCard` (inkl. statischer Live-Indikator), `OutdoorSessionCard`, `StatBubble`, `WorkoutCompletedCard`, `NewWorkoutSheet`.
- **G2 · Filter** — `FilterChip`, `FilterSection`, `FilterTypes`, Aufrufstellen in `BaseView`. (ExercisePicker AP 7 erbt mit.)
- **G3 · Detail + Forms** — `StrengthDetailView` (Stats-Grid→semantische Map, `rpeColor`→Theme, Buttons→`accentSoft`/`accentWash`; **Breiten-Klemme aus Scroll-Fix MUSS erhalten bleiben** — `.frame(maxWidth:.infinity)` als äußerster Modifier am ScrollView-Inhalt, beim Material→`.card()`-Tausch nicht entfernen), `OutdoorDetailView` (Performance-Grid→Map, `OutdoorActivity.tint`→success), **`FormView` (Cardio Detail/Edit)** + **`OutdoorFormView` (Outdoor Create/Edit)** — Control-Tints→Theme, Form-Logik (Speichern/Validierung/SwiftData) unangetastet.
- **G4 · AddExerciseSheet** — `AddExerciseDuringWorkoutSheet` Control-Tints → Theme.

**Done-Kriterien je Gate (VORGEHEN §3/§5):** Build grün · `#Preview` im neuen Stil für jede geänderte View · Simulator-Screenshot vs. Prototyp · Residue-Grep sauber · grün/rot melden.

---

## Unangetastet (Logik-Grenze)

- `ActiveSessionManager` (`getActiveSessionID`/`isPaused`), Swipe-Delete, `@Bindable session`, Navigation/Sheet-Callbacks (`syncContext`, `repeatWorkout`, `exerciseToEdit`).
- `ProgressionRollbackService.manualRollback()`, `deleteSession()`-Pfade.
- `AddExerciseDuringWorkoutSheet`: `incrementTimer`, `startContinuousAdjustment`/`stop`, `addExerciseToSession()`/`context.insert()`.
- `FormView`/`OutdoorFormView`: Speichern/Validierung/SwiftData-Persistenz, `FormMode`.
- `Intensity.color` (Definition), `FilterTypes.dateRange()`, `MixedWorkoutItem`-Sortierung.

## Residue-Grep nach jedem Gate

```
grep -rnE "(Color)?\.(blue|green|red|yellow|orange|purple|teal|indigo|cyan|mint|pink|brown|gray)\b|LinearGradient|RadialGradient|ultraThinMaterial|MCColor|glassCard|glassButton" --include='*.swift' <Pfad> | grep -vE "Color\.white|Color\.clear|Theme\.|series|setKind\.color|Intensity"
```
Bewusst auslassen: `Color.white`/`.clear` (strukturell), `NewWorkoutSheet`-Material (Sheet), `Intensity.color` (Domänen-Enum).
