# MotionCore — Redesign: SummaryView (Dashboard) & BodyView

**Variante: B (Command Center) für beide Tabs**
**Vorgehen: Clean Slate — Views komplett neu, Cards überarbeiten/ersetzen wo nötig**
**Workflow: Standard — `motioncore-planner` → STOPP → `motioncore-developer` mit STOPP-Gates nach jedem Step**

---

## 1. Hintergrund & Designreferenz

Das Redesign basiert auf dem in Claude Design ausgearbeiteten "Command Center"-Look:

- **Liquid-Glass-Ästhetik beibehalten** (`.glassCard()` weiter nutzen)
- **Daten-dicht, kompakt, scrollbar**
- **Farb-Codes nach Bereich**:
  - Tagesform / Readiness → Amber `#F5B400`
  - Erholung / Recovery → Grün `#5CC63F`
  - Statistik → Blau `#2E6DF0`
  - Streak → Coral `#FF6B4A`
- **`tabular-nums`** für alle Zahlenwerte (Score, kg, kcal, %)
- Sparklines (klein, mit Farbflächen-Fill) als wiederkehrendes Motiv

> **Wichtig**: Das Design ist die Vorlage für **Layout, Hierarchie und Farbe** — nicht für 1:1-Pixelmaße. Deine bestehenden iOS-Standards (`.glassCard()`, `EmptyState()`, `scrollViewContentPadding()`) gehen vor.

---

## 2. Scope & Out-of-Scope

### In Scope

- `SummaryView.swift` — komplette Neustrukturierung (Clean Slate)
- `BodyView.swift` — komplette Neustrukturierung (Clean Slate)
- Neue wiederverwendbare Komponenten (siehe Phase 1)
- Heuristik für "Heute trainieren / Heute meiden" (nutzt bestehende `MuscleRecoveryAnalysis`)

### Out of Scope

- Body-Map-SVG (es kommt **keine** SVG-Body-Map ins Dashboard — Variante B nutzt MiniRing-Grid)
- Neue CalcEngines bauen (nur die kleine Empfehlungs-Heuristik)
- Andere Tabs (Statistik, Records, Training etc.)
- `MuscleHeatmapView` als Standalone (bleibt unverändert in `StatsAndRecordsView`)
- Watch-App, Widgets, Live Activity

### Nicht anfassen (harte Constraints)

- `ExerciseRating` System — gruppKey-basiert, bleibt unangetastet
- `PlanUpdateCalcEngine`
- `MuscleRecoveryCalcEngine`, `RecoveryCalcEngine`, `MuscleHeatmapCalcEngine`, `XPCalcEngine`, `StreakCalcEngine`, `WeeklyGoalCalcEngine`, `TrendCalcEngine`, `RatingInsightCalcEngine`
- Alle SwiftData-Models
- `SupabaseFullBackupService`, CloudKit-Sync

---

## 3. Phasenplan

Insgesamt **6 Phasen**. Jede Phase ist ein eigener Build-Step mit STOPP-Gate. Erst nach Build-Bestätigung durch Barto geht's weiter.

### Phase 1 — Wiederverwendbare Building-Blocks

Neue Komponenten unter `MotionCore/Views/Shared/Redesign/`:

1. **`MCFactorBar.swift`**
   - Horizontaler Bar mit Label oben, Sub-Label rechts klein, prominenter Bar darunter
   - Props: `label: String`, `subLabel: String?`, `value: Double` (0…1), `color: Color`
   - Verwendet von: Dashboard-Hero (Tagesform-Faktoren), BodyView Tagesform-Tab

2. **`MCChip.swift`**
   - Horizontaler Glass-Chip mit Icon, Wert (groß), Label (klein darunter)
   - Props: `icon: Image`, `value: String`, `label: String`, `tint: Color = .primary`
   - Verwendet von: Dashboard Chip-Strip

3. **`MCSparkline.swift`**
   - Mini-Liniendiagramm mit Area-Fill (~70×24 default, größer für Trend-Tab)
   - Props: `data: [Double]`, `color: Color`, `showFill: Bool = true`
   - Pure SwiftUI mit `Path` — keine Charts-Lib
   - Auto-Skalierung auf min/max der Daten
   - Verwendet von: Hero-Mini-Sparklines, Spark-Cards 2×2, Insight-Stream, Trend-Tab

4. **`MCMiniRing.swift`**
   - Kreis-Progress-Ring mit Wert in Mitte und Label darunter (ggf. außen)
   - Props: `value: Int` (0…100), `label: String`, `size: CGFloat = 62`, `stroke: CGFloat = 6`, `tint: Color` (optional, default abgeleitet von Wert)
   - Mit `withAnimation` einblenden
   - Verwendet von: Dashboard "Trainierte Muskeln" 4×2-Grid

5. **`MCHeroRing.swift`**
   - Großer Kreis-Ring mit zentraler Zahl + Sub-Label
   - Props: `value: Int` (0…100), `label: String?`, `subText: String?`, `size: CGFloat = 170`, `stroke: CGFloat = 13`, `tint: Color`
   - Animierte Ring-Draw-Animation beim ersten Erscheinen
   - Verwendet von: BodyView Composite-Score-Card

6. **`MCRecoveryHeatmapGrid.swift`** *(klein, Dashboard)*
   - 7×4 Grid (Wochen × Wochentage), Quadrate gefärbt nach Trainings-Intensität
   - Props: `days: [HeatmapDay]` (eigener kleiner Struct: `date: Date, intensity: Double`)
   - Quelle: `viewModel.activityGrid` o. ä. — falls nicht da, vorerst `EmptyView()`
   - **Falls nicht zeitnah datentechnisch lieferbar: in dieser Phase weglassen, als Phase-7-Stub markieren**

7. **`MCColorPalette.swift`**
   - Zentrale Farben-Konstanten für die Variante-B-Palette:
     - `mcEnergy = Color(hex: "#F5B400")`, `mcEnergySoft`, `mcEnergyInk`
     - `mcBody = Color(hex: "#5CC63F")`, `mcBodySoft`, `mcBodyInk`
     - `mcStat = Color(hex: "#2E6DF0")`, `mcStatSoft`, `mcStatInk`
     - `mcStreak = Color(hex: "#FF6B4A")`, `mcStreakSoft`, `mcStreakInk`
   - Als `Color`-Extension oder `enum MCColor { static let ... }`
   - Bestehende `Color(hex:)` aus `ColorHexExtension.swift` nutzen
   - **Vor Anlage prüfen, ob es im Projekt schon ein Farb-Theme gibt** — falls ja, dort ergänzen

**Standards je Komponente:**
- Eigene Datei (Standards: max 400 Zeilen)
- File-Header analog bestehendem Code
- `// MARK: -` Sections, Properties → Body → Subviews → Helpers
- `tabular-nums` via `.monospacedDigit()`
- Pure UI, keine Logik
- `#Preview` mit mehreren Zuständen (low/mid/high) am Ende

**STOPP nach Phase 1.**

---

### Phase 2 — Recommendation-Heuristik

Neue Datei: `MotionCore/CalcEngines/RecoveryRecommendationCalcEngine.swift`

Pure Struct, keine SwiftData-Abhängigkeit. Input: `MuscleRecoveryAnalysis`. Output:

```swift
struct RecoveryRecommendation {
    let recommendedGroups: [MuscleGroup]   // 1–3 am besten erholt
    let avoidGroups: [MuscleGroup]         // 1–3 am wenigsten erholt
    let recommendedTitle: String           // z.B. "Push: Brust · Trizeps · Schultern"
    let avoidTitle: String                 // z.B. "Beine · Rücken"
    let avoidReason: String                // z.B. "Bei 28% Erholung steigt das Verletzungsrisiko."
}
```

**Logik:**
- Aus `analysis.muscleGroupScores` die mit höchstem Recovery-Score (≥85%) → empfohlen
- Aus den mit niedrigstem Score (<60%) → meiden
- Wenn keine Gruppe <60% → `avoidGroups = []`, `avoidTitle` "Heute keine Einschränkungen"
- Empfehlung als deutscher String: erste 3 displayNames mit " · " verbunden, Präfix "Push:" / "Pull:" / "Beine:" wenn klar erkennbar (siehe Mapping unten), sonst nur Namen
  - Brust + Trizeps + Schultern → "Push:"
  - Rücken + Bizeps → "Pull:"
  - Beine + Gesäß → "Beine:"
  - Rest → kein Präfix
- Bei leerer Analyse → beide Listen leer, Titel `"Noch keine Trainingsdaten"`

**`SummaryViewModel`-Erweiterung:**
- `private(set) var recommendation: RecoveryRecommendation = .empty` (Default-Wert oder Optional)
- In `recalculate()` nach dem MuscleRecovery-Block befüllen
- `recalculateFiltered()` braucht das nicht (hängt nicht am Timeframe)

**STOPP nach Phase 2.**

---

### Phase 3 — Dashboard-Hero & Chip-Row

Neue Datei: `MotionCore/Views/Summary/SummaryCommandHero.swift`

3-Spalten-Card mit Sub-Cards für **Tagesform**, **Erholung**, **Streak**:

- **Tagesform** (Amber-Tint-Background):
  - Großer Score (z.B. `66`), Label-Text ("Normale Form" / "Sehr gut" / "Niedrig")
  - Mini-Sparkline der letzten 7 Tage (falls Verlaufsdaten verfügbar — sonst weglassen oder Stub)
  - Datenquelle: `latestSessionReadiness?.overallScore`
  - Wenn `isCalibrating` oder kein Score → "Kalibrierung läuft" / Platzhalter "—"

- **Erholung** (Grün-Tint-Background):
  - Großer Wert in % (`87%`), Label ("Sehr gut" / "Mittel" / "Niedrig")
  - Mini-Sparkline (Stub: leer oder gleichmäßig — echter 14-Tage-Trend-Verlauf existiert noch nicht und ist out-of-scope)
  - Datenquelle: `viewModel.recoveryAnalysis?.overallRecoveryPercent`

- **Streak** (Coral-Tint-Background):
  - Großer Wert (`3 d`), Sub-Label ("X Tage bis Wochen-Streak" oder Milestone-Hinweis)
  - Statt Sparkline: Linearer Progress-Bar zum nächsten Milestone
  - Datenquelle: `viewModel.currentStreak`, `viewModel.nextStreakMilestone`

Darunter — **inline "Heute trainieren"-Empfehlung** als kleinerer Sub-Block:
- Blue-Tint-Background, Icon (Hantel) links
- Titel-Zeile (z.B. "Push: Brust · Trizeps · Schultern" — aus `viewModel.recommendation.recommendedTitle`)
- Sub-Text optional (z.B. "X Gruppen erholt")
- Button rechts: "Start" → öffnet `NewWorkoutSheet` oder navigiert zum Training-Tab (vorerst nur einen `onTap`-Hook freilegen, Logik in der SummaryView)
- Wenn `recommendation.recommendedGroups.isEmpty` → Card weglassen oder Platzhalter

**Chip-Row darunter** (horizontal scrollbar): `MCChip`s mit:
- Level + Progress (`Lvl X · Y% bis Lvl Z`) — aus `viewModel.xpLevel`
- Volumen-Trend (`+258%` / Volumen vs. Vorw.) — aus `viewModel.volumeTrend`
- Ø Herzfrequenz (`104 bpm`) — aus `filteredAverageHeartRate` (sofern verfügbar)
- Schlaf (`6h 12`) — aus `latestSessionReadiness?.sleepDuration` falls vorhanden, sonst weglassen

**Bestehende `ReadinessSummaryCard.swift` löschen** — Hero übernimmt das (Bestätigung Barto).

**STOPP nach Phase 3.**

---

### Phase 4 — Dashboard restliche Karten

Reihenfolge in `SummaryView` (Top → Bottom):

1. `SummaryCommandHero` (Phase 3) — inkl. inline Recommendation
2. Chip-Row (Phase 3)
3. **"Trainierte Muskeln" 4×2-Grid** — neue Card `SummaryMuscleRingsCard.swift`
   - Header: "Trainierte Muskeln" links, Ø-Erholung rechts ("Ø 87% bereit")
   - 4-Spalten-Grid mit `MCMiniRing` für jede `MuscleGroup` aus `recoveryAnalysis.muscleGroupScores`
   - Tap auf Ring → öffnet `MuscleRecoveryDetailView` (bestehender Sheet-Mechanismus)
4. **2×2 Spark-Cards** — neue Card `SummaryStatGridCard.swift` (oder direkt im View)
   - Workouts (Lila/Blau) — `filteredTotalWorkouts`
   - Kalorien (Coral) — `filteredTotalCalories`
   - Trainingszeit (Lila) — `filteredFormattedDuration`
   - Ø Herzfrequenz (Coral) — `filteredAverageHeartRate`
   - Jeweils Icon-Badge oben links, Trend-Delta oben rechts (aus den `*Trend`-Werten), großer Wert mittig, Sub-Einheit + Label, Sparkline unten
   - **Sparkline-Datenquelle**: Falls keine fertigen 7-Tage-Series-Daten existieren → vorerst leerer Sparkline-Slot oder Stub mit `[0,0,...,wert]`. Nicht erfinden.
5. `TimeframePicker` (bleibt wie er ist, vor den Karten 6+)
6. `SummaryRatingInsightCard` (bleibt — refactor optional auf neuen Sparkline-Look "Insight-Stream", aber nicht zwingend in dieser Phase)
7. `StreakCard` (bleibt unverändert)
8. `SummaryXPCard` (bleibt unverändert)
9. `TypeBreakdownCard` + `StatisticDonutChart` (bleibt unverändert)
10. `SummaryRecordsCard` (bleibt unverändert)
11. `SummaryActivityCalendar` (bleibt — Toggle über `SummaryWeekStrip`)
12. `SummaryMuscleHeatmapCard` (bleibt — wird durch das neue MiniRing-Grid ergänzt, nicht ersetzt; falls Barto später entscheidet einen rauszuwerfen → separater Schritt)

**`SummaryView.swift` neu strukturieren:**
- Bestehende Order verwerfen
- Neue Reihenfolge oben
- `recoveryDetailItem`-Sheet bleibt
- `showAutoProgressionDetails`-Sheet bleibt
- `RollbackInsightCard` und `AutoProgressionInsightCard` bleiben — Position: zwischen Spark-Cards (4) und TimeframePicker (5), conditionally
- `SummaryWeekStrip` + `SummaryActivityCalendar` rutschen weiter nach unten (Punkt 11)
- `SummaryHeroCard` + `SummaryWeeklyGoalRing` + `SummaryTrendCard` werden **ersetzt** durch Hero (3) + Chip-Row (3) + Spark-Cards (4)
- Heißt konkret: `SummaryHeroCard.swift`, `SummaryWeeklyGoalRing.swift`, `SummaryTrendCard.swift` werden **nicht gelöscht**, sondern aus `SummaryView` rausgenommen und im Projekt belassen (für eventuelle spätere Wiederverwendung). **Vor Löschen Cross-Reference-Check** — falls eine andere View sie nutzt, dranlassen; falls nicht → in Phase 6 (Cleanup) löschen.

**STOPP nach Phase 4.**

---

### Phase 5 — BodyView Redesign

`BodyView.swift` komplett neu strukturieren — Variante B Stack:

1. **Composite-Ready-Score-Card** — neue Card `BodyCompositeScoreCard.swift`
   - Großer `MCHeroRing` (170pt) mit `recoveryAnalysis.overallRecoveryPercent`
   - Rechts daneben: "Bereit für" Label + `recommendation.recommendedTitle` + Sub-Text + "Heute trainieren →"-Button
   - Subtiler Glow-Background-Akzent (radialer Grün-Gradient hinter dem Ring) mit `RadialGradient`
   - Wenn Empfehlung leer → Button ausblenden, Text "Noch keine Empfehlung verfügbar"

2. **Tab-Switch** — `BodyTabSwitch.swift` (oder als private View in BodyView)
   - Drei Tabs: **Erholung**, **Tagesform**, **Trend**
   - Glass-Pill-Style: ausgewählter Tab weiß-Background mit subtiler Shadow, andere transparent
   - State `@State private var selectedTab: BodyTab = .recovery`
   - Enum `BodyTab: String, CaseIterable { case recovery = "Erholung", form = "Tagesform", trend = "Trend" }`

3. **Tab-Content** je nach Auswahl:

   - **Erholung-Tab** — `BodyRecoveryListCard.swift`
     - Header: "Muskelgruppen"
     - Liste aller `recoveryAnalysis.muscleGroupScores` sortiert nach Recovery-Score aufsteigend (am wenigsten erholte zuerst, das ist die wichtige Info)
     - Pro Zeile: großer Prozent-Wert links (in Recovery-Color), Name + Mini-Bar darunter, rechts "vor X Tagen" + Volumen
     - Tap auf Zeile → `MuscleRecoveryDetailView` öffnen (bestehender Mechanismus)
     - Empty-State falls keine Trainingsdaten

   - **Tagesform-Tab** — `BodyReadinessFactorsCard.swift`
     - Bestehende Logik aus aktueller `readinessFactorsSection` extrahieren
     - Header: "Tagesform-Faktoren" + "Score X/100" rechts
     - Liste der `viewModel.readinessFactors` mit `MCFactorBar` (statt aktuellem `ReadinessFactorRow`, der weniger prominent ist) — **alternativ** `ReadinessFactorRow` weiter nutzen, falls dessen Look schon dem Design nahekommt; **Entscheidung: nutze `MCFactorBar` für Konsistenz**
     - Empty-State falls keine Faktoren verfügbar

   - **Trend-Tab** — `BodyRecoveryTrendCard.swift`
     - Header: "Erholungs-Trend · 14 Tage"
     - Großer `MCSparkline` (volle Card-Breite, Höhe 90pt)
     - **Datenquelle**: aktuell **keine** historische Recovery-Trend-Daten vorhanden. Optionen:
       - (a) `EmptyState` mit Hinweis "Trend-Daten kommen in Kürze" → präferiert, da ehrlich
       - (b) Stub aus `recoveryAnalysis.muscleGroupScores` als heutiger Punkt + 13 leere Datenpunkte
     - **Standard: Option (a)**. Tab dennoch sichtbar, damit Layout vollständig ist.
     - Footer-Stats-Row: Ø 14 Tage / Trend-% / Heute — bei (a) ausblenden

4. **"Heute meiden"-Card** unter den Tabs (immer sichtbar, nicht tab-abhängig)
   - Neue Card `BodyAvoidCard.swift`
   - Coral-Tint-Akzent, Header "Heute meiden" (uppercase, klein)
   - Titel `recommendation.avoidTitle`
   - Body-Text `recommendation.avoidReason`
   - Wenn `recommendation.avoidGroups.isEmpty` → Card komplett ausblenden

5. **`BodyViewModel`-Erweiterungen**:
   - `private(set) var recommendation: RecoveryRecommendation = ...` (wie in `SummaryViewModel`)
   - `recalculate()` füllt das mit
   - **Doppellogik vermeiden**: `RecoveryRecommendationCalcEngine` wird in beiden ViewModels aufgerufen — das ist okay, weil es ein pures Struct ist.

6. **Bestehende Komponenten**:
   - `MuscleRecoveryCard` mit Style `.full` — wird **nicht mehr** in BodyView verwendet (Composite-Score-Card + Tab-Liste übernehmen). Datei behalten (wird noch von `compact`-Style in Summary genutzt? → **prüfen vor Löschen**).
   - `ReadinessFactorRow` — bleibt im Projekt, ggf. weiter genutzt von ReadinessDetailView.

**STOPP nach Phase 5.**

---

### Phase 6 — Cleanup & Verifikation

1. **Cross-Reference-Checks** vor Löschungen:
   - `ReadinessSummaryCard.swift` — wird in SummaryView **nicht mehr** verwendet. Suche im Projekt: kommt sie woanders vor? Wenn nein → löschen.
   - `SummaryHeroCard.swift`, `SummaryWeeklyGoalRing.swift`, `SummaryTrendCard.swift` — Suche im Projekt. Wenn nirgends mehr referenziert → löschen. Wenn noch in Tests/Previews → Barto fragen.
   - `MuscleRecoveryCard.swift` — wird `.compact`-Style noch in SummaryView gebraucht? **Im neuen Design: Nein** (das MiniRing-Grid in Phase 4 ersetzt es). → prüfen → löschen oder behalten je nach Cross-Reference.

2. **File-Size-Audit**:
   - `SummaryView.swift` und `BodyView.swift` neu — sollten je <300 Zeilen bleiben (View ruft Cards auf, ist Orchestrator)
   - Wenn doch zu groß → Sub-Sections in private Files extrahieren

3. **Visuelle Verifikation** (Barto in Xcode-Preview + Simulator):
   - Liquid-Glass-Look stimmt
   - Farben passen zur Variante-B-Palette
   - tabular-nums korrekt
   - Animationen smooth (Ring-Draw, Bar-Fill, fade-in)
   - Empty-States sauber
   - Sheets öffnen sich bei Tap auf Muskel-Ring / Recovery-Zeile

4. **Build-Check & Compile-Warnings auf 0** (Standards: keine Workarounds zurücklassen).

**STOPP nach Phase 6 (final).**

---

## 4. Datenfluss-Übersicht

| UI-Element | Datenquelle | Engine |
|---|---|---|
| Hero-Tagesform-Score | `latestSessionReadiness.overallScore` | bestehende `SessionReadinessService` / `ReadinessCalcEngine` |
| Hero-Erholung-% | `recoveryAnalysis.overallRecoveryPercent` | `MuscleRecoveryCalcEngine` |
| Hero-Streak | `viewModel.currentStreak` | `StreakCalcEngine` |
| Recommendation | `viewModel.recommendation` | **NEU**: `RecoveryRecommendationCalcEngine` |
| Chip: Level | `viewModel.xpLevel` | `XPCalcEngine` |
| Chip: Volumen-Delta | `viewModel.volumeTrend` | `TrendCalcEngine` |
| 4×2 MiniRings | `recoveryAnalysis.muscleGroupScores` | `MuscleRecoveryCalcEngine` |
| 2×2 Spark-Cards Werte | `viewModel.filtered*` | `StatisticCalcEngine` etc. |
| 2×2 Spark-Cards Sparklines | **noch keine 7-Tage-Series-Daten** | → vorerst leer / Stub |
| BodyView Composite-Ring | `recoveryAnalysis.overallRecoveryPercent` | `MuscleRecoveryCalcEngine` |
| BodyView Recovery-Liste | `recoveryAnalysis.muscleGroupScores` sortiert | `MuscleRecoveryCalcEngine` |
| BodyView Tagesform-Bars | `viewModel.readinessFactors` | bestehend |
| BodyView Trend-Tab | **keine Daten** → EmptyState | (zukünftig: neue Engine) |

---

## 5. Definition of Done

- ✅ SummaryView und BodyView entsprechen dem Design Variante B (Layout, Hierarchie, Farben)
- ✅ Alle neuen Komponenten unter `Shared/Redesign/` einzeln testbar via `#Preview`
- ✅ `RecoveryRecommendationCalcEngine` als pure Struct, ohne Side Effects
- ✅ Keine harten Constraints verletzt (`ExerciseRating`, `PlanUpdateCalcEngine` etc. unverändert)
- ✅ Keine Datei >400 Zeilen ohne Begründung
- ✅ Build green, keine neuen Warnings
- ✅ Empty-States für alle möglichen Null-Szenarien (keine Sessions, keine Readiness, keine Recovery-Daten)
- ✅ Deutsche UI-Texte, englische Variablen-/Methoden-Namen
- ✅ `tabular-nums` (`.monospacedDigit()`) für alle numerischen Werte
- ✅ `.glassCard()` auf jeder Card
- ✅ `EmptyState()` für leere Zustände (kein eigener Empty-Style)
- ✅ Drei Sheet-Mechanismen funktionieren: `MuscleRecoveryDetailView`, `AutoProgressionDetailsView`, ggf. neuer "Heute trainieren"-Action

---

## 6. Offene Punkte für Phase 7+ (nach diesem Redesign)

Diese sind **nicht** Teil dieses Tasks, aber zur Erinnerung:

- 7-Tage-Series-Daten für die Sparklines auf den 2×2 Spark-Cards (würde `TrendCalcEngine` erweitern)
- Historische Recovery-Trend-Engine (für BodyView Trend-Tab → echte Daten)
- "Trainings-Rhythmus"-Heatmap als eigene Card im Dashboard (Variante A hat das, B nicht — falls später erwünscht)
- Smarter Recommendation-Engine (Push/Pull/Legs-Split-aware, statt nur Top/Bottom-Score-Heuristik)
- "Muskelverteilung" Radar-Chart (steht eh schon auf der Roadmap)
