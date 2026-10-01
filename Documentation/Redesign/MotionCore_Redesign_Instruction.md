# MotionCore — Redesign Instruction-Set (Calm 2026) · AP 0–11

> **Version 1.2** · Stand: 19.06.2026
> Für die Claude-Code-Agent-Pipeline (`motioncore-planner` → `motioncore-developer` → `motioncore-quality-gate`).
> Jedes Arbeitspaket (AP) ist **eigener Branch + eigener PR** und einzeln übergebbar.

**Festgelegte Entscheidungen:** Akzent = **Tiefblau `#2C6BCB`** (definitiv) · **Dark Mode** ja, in Settings umschaltbar (System/Hell/Dunkel) · Theme als **Asset-Catalog-Colorsets** mit **Light + Dark** (Werte stehen in `DESIGN.md` §2 und `colors.css`) · `Color(hex: String)` bleibt · `MCColor`/`MCColorPalette.swift` wird **in AP 0 hart auf `Theme` migriert und entfernt**.

**Neu in v1.2:** Dark-Palette freigegeben und in AP 0 eingebaut (Color Sets bekommen sofort Light **und** Dark). `DESIGN.md` und `colors.css` liegen fertig bei (Setup). Konkreter Orchestrierungs-Abschnitt für parallele Subagenten am Ende.

---

## Wie dieses Dokument zu benutzen ist

Pro AP gibt es **Ziel · Abhängigkeit · Dateien · Soll/Entscheidungen · Akzeptanz · STOPP-Gates · Prompt**. Der Prompt-Block ist copy-paste-fertig (Deutsch) und enthält die festgelegten Entscheidungen + die Gate-Anweisung.

**Verbindliches Regelwerk (gilt für jedes AP):** `DESIGN.md` (Tokens §2–§5, Dark §11, Migration §10) · `README.md` aus `Documentation/Redesign/` (Screen-Spec für **AP 3**, pixelgenau) · Skill `swift-standards` · die HTML-Prototypen bzw. `source/*.jsx` als visuelle Wahrheit.

**Quellen-Hierarchie:** `DESIGN.md` **>** `README.md` **>** `source/*.jsx` **>** `tokens/colors.css`.

---

## Setup (vor AP 0) — Dateien ablegen & CLAUDE.md verdrahten

**Repo-Root:** `/Users/bartosz/Developments/MotionCore/`
**Handoff-Paket:** `/Users/bartosz/Developments/MotionCore/Documentation/Redesign/` (README, Prototypen, `source/`, `tokens/`, `assets/`).

Es liegen zwei fertige, aktualisierte Dateien bei:
- **`DESIGN.md`** → ins **Repo-Root** legen (`/Users/bartosz/Developments/MotionCore/DESIGN.md`). Das ist ab jetzt das verbindliche, dauerhafte Design-System (Tiefblau final, Light+Dark-Tabelle, Asset-Catalog, Dark-Mode-Abschnitt). Ersetzt das alte `Documentation/Redesign/DESIGN-SwiftUI.md` (das kann ins Archiv oder weg).
- **`colors.css`** → ersetzt `Documentation/Redesign/tokens/colors.css` (Tiefblau + Dark-Block; das alte Teal-File ist veraltet).

**`CLAUDE.md` ergänzen:** Verweis aufnehmen, z. B.:
> „UI/Design: siehe **`DESIGN.md`** (verbindliches Design-System, Calm 2026). Jede UI-Änderung hält sich strikt daran: nur `Theme.*`/`AppFont.*`/`.card()` + die Bausteine aus AP 1, Akzent ist `Theme.accent` (Tiefblau `#2C6BCB`), kein Glas/Blobs, eine Leitfarbe pro Kennzahl, Dark Mode über die Asset-Catalog-Colorsets."

Rest des Pakets bleibt unter `Documentation/Redesign/` als Archiv.

---

## 0 · Globale Regeln (Kontext-Block — vor jedes AP prependen)

```
KONTEXT (gilt für dieses AP):
- Regelwerk: DESIGN.md (Tokens §2–§5, Dark §11, Migration §10) + Skill swift-standards.
- AKZENT app-weit = Tiefblau #2C6BCB (DEFINITIV). Theme.accent ist die EINZIGE Stelle.
  NIE eine zweite Akzentfarbe einführen.
- THEME = Asset-Catalog-Colorsets mit Light UND Dark (Werte in DESIGN.md §2). Color(hex: String)
  bleibt für Einzelfälle. Bis AP 11 ist die App per .preferredColorScheme(.light) auf Hell gepinnt
  (vorhersehbarer Übergang); der System/Hell/Dunkel-Umschalter kommt in AP 11.
- Redesign = NUR Darstellung. Keine Änderung an Geschäftslogik, Datenflüssen, CalcEngines,
  Services oder SwiftData-Modellen, außer im AP explizit verlangt.
- Swift: CalcEngines bleiben pure structs (kein SwiftUI-Import, keine Side-Effects). Keine Logik
  in Views/body. Dateien Ziel ≤400 Zeilen (hart >600 splitten). Keine "+" in Dateinamen.
  Datei-Header-Block aus einer bestehenden Datei kopieren. Debug-print() entfernen.
- Sprache: deutsche UI-Texte, englischer Code, deutsche Inline-Kommentare.
- Commits: Conventional Commits, Englisch. Ein Branch + ein PR pro AP.
- project_knowledge_search ist die Quelle für aktuellen Swift-Code, NICHT ls /mnt/project.

STOPP-GATE-PROTOKOLL:
- Halte an JEDEM markierten Gate an und gib explizit "grün" (Build erfolgreich) oder "rot" +
  Fehlermeldung zurück. Vage Bestätigungen zählen NICHT. Fahre erst nach explizitem Grün fort.
  Bei Rot: Ursache finden und beheben, kein temporärer Workaround.
```

---

## 1 · Migrations-Landkarte (Ist → Soll)

| Ist (gefunden in) | Soll |
|---|---|
| `.glassCard()` — `GlassCard.swift` (Radius 22, Material, weiße Tönung/Stroke, Schatten r12/y6) | `.card()` (Hairline `Theme.line`, flüsterleiser Schatten nur in Light) — DESIGN.md §5 |
| `.glassButton()` / `GlassButton.swift` (Material + Glow, Default `.blue`) · `FloatingButton.swift` | Neue Button-Stile aus **AP 1** + FAB-Stil (Press 0.92) |
| `AnimatedBackground`/`AnimatedBlob`/`GradientBackground` — `BackgroundSettings.swift`; Flag `showAnimatedBlob` | Flacher `Theme.surfaceApp`-Hintergrund. Blob/Gradient + Toggle stilllegen |
| `Color.blue` als De-facto-Akzent (`FilterChip`, Toolbars, `FloatingButton`/`GlassButton`-Defaults) | `Theme.accent` |
| Regenbogen-Grid `.blue/.orange/.purple/.red/.teal/.indigo/.cyan/.yellow` — `StatisticView.swift` | Ruhige Palette: eine Farbe je Kennzahl bzw. `Theme.series` in Reihenfolge (→ AP 5) |
| **`MCColor.*` — `MCColorPalette.swift`** | **In AP 0 hart auf `Theme.*` migrieren** (Mapping in AP 0), Datei danach **entfernen** |
| `HeatLevel.color`/`.hexColor` — `MuscleHeatmapTypes.swift` (Blau-Skala, **Hex-Strings** für SVG-Injection) | Theme-konforme Hex (sky/accent) — Hex-Strings, keine SwiftUI-Colors (→ AP 6); Dark-Skala → AP 11 |
| `.thinMaterial`/`.ultraThinMaterial` als Inline-Füllung | `surfaceSunken`/`.card()`. Material nur für gefrostete TabBar + Sheets über Inhalt |
| `Color(hex: String)` — `ColorHexExtension.swift` | **bleibt** für Einzelfälle; `Theme` kommt aus Asset-Catalog-Colorsets |

---

# PHASE 0 — Fundament (Blocker)

> Phase 0 zuerst und in **einem** PR mergen, sonst kollidieren parallele Screen-PRs an den Tokens.

## ☐ AP 0 · Theme & Foundations (Asset Catalog Light+Dark, MCColor-Migration)

**Ziel:** Token-Fundament als **Asset-Catalog-Colorsets mit Light + Dark**; alter Glass-/Blau-/Blob-Look raus; `MCColor` vollständig auf `Theme` migriert und entfernt. Alles kompiliert auf den neuen Tokens (Layout darf vorerst alt sein); App per `.preferredColorScheme(.light)` auf Hell gepinnt.

**Abhängigkeit:** keine. Muss vor allem anderen gemerged sein. **Größeres AP** (MCColor-Sofortmigration + Light+Dark-Werte — bewusst so).

**Quelle:** `DESIGN.md` §2 (Tokens-Tabelle Light+Dark), §3, §4, §5, §11; `colors.css`.

**Schritte & Gates:**

1. **Theme als Asset-Catalog-Colorsets, Light + Dark.** Pro Token aus §2 ein Color Set (camelCase: `surfaceApp`, `surfaceCard`, `surfaceSunken`, `textPrimary/Secondary/Tertiary`, `line`, `lineSoft`, `accent`, `accentHover`, `accentPress`, `accentSoft`, `success`, `warning`, `danger`, `series1`–`series5`, `chartGrid`) — **jeweils Light- UND Dark-Appearance** mit den Werten aus der §2-Tabelle.
   - Dünnes `Theme`-Enum als Zugriff (`static let surfaceApp = Color("surfaceApp")` …), `accentWash` als computed `accent.opacity(0.08)`.
   - `Color(hex: String)` (`ColorHexExtension.swift`) **bleibt** unangetastet.
   - `AppFont`, `Space`, `Radius` Enums (§3/§4).
   - App-Root (`MotionCoreApp`/`BaseView`): `.preferredColorScheme(.light)` setzen (bis AP 11).
   - → **STOPP-Gate 1:** baut? grün/rot.
2. **`.card()`-Modifier** (dark-ready `CardStyle` aus §5: `@Environment(\.colorScheme)`, Schatten nur in Light). `.glassCard()` app-weit auf `.card()` umstellen (alle Call-Sites via `project_knowledge_search`). `GlassCardModifier` darf vorerst `@available(*, deprecated)` bleiben.
   - → **STOPP-Gate 2:** baut? grün/rot.
3. **Hintergrund flach:** `AnimatedBackground`/`AnimatedBlob`/`GradientBackground` (`BackgroundSettings.swift`) aus dem Produktiv-Pfad entfernen → `Theme.surfaceApp`. Flag `appSettings.showAnimatedBlob` stilllegen (UI-Bereinigung in AP 8). Previews mit `AnimatedBackground` umstellen.
   - → **STOPP-Gate 3:** baut? grün/rot.
4. **MCColor → Theme (hart) + Datei entfernen.** Alle `MCColor.*`-Referenzen (Call-Sites **und** Previews) auf `Theme.*`, dann `MCColorPalette.swift` löschen. Mapping:

   | MCColor | → Theme | Soft / Ink |
   |---|---|---|
   | `mcEnergy` (Readiness) | `accent` | `accentWash` / `accentPress` |
   | `mcBody` (Erholung) | `success` | `success.opacity(0.09)` / dunkler |
   | `mcStat` (Volumen) | `series[0]` (`#3A8FC9`) | `series[0].opacity(0.10)` / dunkler |
   | `mcStreak` (Streak) | `warning` | `warning.opacity(0.10)` / dunkler |

   Soft-Tönungen folgen §2 (7–13 %). Betroffen: `MCFactorBar`, `MCChip`, `MCHeroRing`, `MCMiniRing`, `MCSparkline` + Verwender (z. B. `BodyReadinessFactorsCard`).
   - → **STOPP-Gate 4:** baut? grün/rot.
5. **Restliche Hex-/Farb-Migration (§10):** `Color.blue`/`#0038BD`→`accent`; `Color.green`(Erfolg)→`success`; `Color.red`/`.yellow`→`warning`; reines Schwarz/Weiß→Text-Tokens; Gradient-Fortschritte→einfarbig `accent`; Großzahlen→`.rounded`+`.monospacedDigit()`.
   - → **STOPP-Gate 5:** baut? grün/rot.

**Akzeptanz:** Projekt kompiliert komplett auf `Theme`/`AppFont`/`.card()`; **kein** rohes Hex / `Color.blue|green|red|yellow|orange` / `MCColor` im View-Code; `MCColorPalette.swift` entfernt; keine Blobs; Theme **dark-ready mit Light+Dark-Werten**; App auf Hell gepinnt. Layout darf unverändert sein.

**Prompt (kopieren):**
```
Lies DESIGN.md vollständig (§2–§5, §10, §11). Lege das Token-Fundament an, mit STOPP-Gate nach
jedem Schritt:
(1) Theme als Asset-Catalog-Colorsets, je Token aus §2 mit Light UND Dark Appearance (Werte aus der
§2-Tabelle). Dünnes Theme-Enum (Theme.surfaceApp = Color("surfaceApp") …), accentWash computed.
Color(hex: String) bleibt unangetastet. Plus AppFont (§3), Space/Radius (§4). Am App-Root
.preferredColorScheme(.light) setzen (bis AP 11). → STOPP-Gate 1.
(2) Dark-ready .card()-Modifier aus §5 (Schatten nur in Light); .glassCard() app-weit ersetzen.
→ STOPP-Gate 2.
(3) AnimatedBackground/AnimatedBlob/GradientBackground entfernen → Theme.surfaceApp; showAnimatedBlob
stilllegen; Previews umstellen. → STOPP-Gate 3.
(4) Alle MCColor.*-Referenzen (Call-Sites + Previews) auf Theme.* (mcEnergy→accent, mcBody→success,
mcStat→series[0], mcStreak→warning; Soft 7–13%), dann MCColorPalette.swift löschen. → STOPP-Gate 4.
(5) Restliche Hex-/Color.blue|green|red|yellow-Werte auf Theme.* (Checkliste §10). → STOPP-Gate 5.
Ziel: alles kompiliert; kein rohes Hex/kein MCColor im View-Code; Theme dark-ready (Light+Dark).
```

---

## ☐ AP 1 · Geteilte Bausteine

**Ziel:** wiederverwendbare UI-Primitives im neuen Stil (DESIGN.md §9).
**Abhängigkeit:** AP 0.
**Bausteine:** Button (primär/sekundär/ghost, Press 0.97), Chip, Badge (soft/solid), StatTile, SectionHeader, FactorBar (einfarbig), ProgressRing (Track `surfaceSunken`, Füllung `accent`, **kein Gradient**), Sparkline/Charts (`accent`/`Theme.series`, `chartGrid`), gefrostete TabBar (`.ultraThinMaterial`), Bottom-Sheet-Stil (Grabber, Radius `xl`, `.presentationDetents`), FAB (Press 0.92).
**Bestehende abzulösen** (neu anlegen, alte schrittweise ersetzen, finale Entfernung AP 11): `MCChip`→Chip, `MCFactorBar`→FactorBar, `MCHeroRing`/`MCMiniRing`→ProgressRing, `MCSparkline`→Sparkline, `StatBubble`→StatTile, `FilterChip`→Chip-Variante, `GlassButton`→Button-Stile. (Beziehen ihre Farbe nach AP 0 bereits aus `Theme`, also automatisch dark-ready.)
**Akzeptanz:** je Baustein SwiftUI-Preview im neuen Stil; nur `Theme.*`/`AppFont.*`; Charts einfarbig.
**STOPP-Gates:** (1) Buttons/Chips/Badges; (2) FactorBar/ProgressRing/Sparkline/Charts; (3) TabBar/Sheet/FAB — je grün/rot.

**Prompt (kopieren):**
```
Aufbauend auf Theme/AppFont/.card(): Baue die geteilten UI-Bausteine gemäß DESIGN.md §9 — Button
(primär/sekundär/ghost), Chip, Badge, StatTile, SectionHeader, FactorBar, ProgressRing, Sparkline/
Charts, gefrostete TabBar, Bottom-Sheet-Stil, FAB (Press 0.92). Charts einfarbig, kein Gradient. Je
Baustein eine SwiftUI-Preview. Plane die Ablösung von MCChip/MCFactorBar/MCHeroRing/MCMiniRing/
MCSparkline/StatBubble/FilterChip/GlassButton (noch nicht hart löschen). Nur Theme.*/AppFont.*.
STOPP-Gates: (1) Buttons/Chips/Badges (2) FactorBar/Ring/Sparkline (3) TabBar/Sheet/FAB — je grün/rot.
```

---

# PHASE 1 — Kern-Screens (nach AP 0/1 parallelisierbar)

## ☐ AP 2 · Übersicht / Home — Richtung **A · Ring Hero**

**Abhängigkeit:** AP 0 + 1. **Referenz:** `MotionCore-App-prototype.html` (Übersicht) + `source/screens.jsx` (`SummaryScreen`).
**Dateien:** `SummaryView`, `SummaryCommandHero`, `SummaryChipRow`, `SummaryWeekStrip`, `SummaryActivityCalendar`, `SummaryMuscleRingsCard`, `SummaryMuscleHeatmapCard`, `SummaryRecordsCard`/`SummaryRecordRow`, `SummaryStatGridCard`, `SummaryXPCard`, `ReadinessCard`, `StreakCard`.
**Unangetastet:** `SummaryViewModel`, `SummaryCalcEngine`, `GreetingCalcEngine`, `XPCalcEngine`, `StreakCalcEngine`, `ActivityGridCalcEngine`, `WeeklyGoalCalcEngine`.
**Soll:** Ring-Hero (Tagesform = `accent`), eine Farbe je Kennzahl, alle Flächen `.card()`, Wochen-Strip, Heatmap-Mini; kein Glas/Blobs/Gradient-Progress.
**STOPP-Gates:** (1) Hero + Header; (2) Karten-Grid; (3) ganzer Screen — je grün/rot.

**Prompt (kopieren):**
```
Redesigne die Übersicht/Home in Views/Summary/** nach DESIGN.md, mit den Bausteinen aus AP 1,
Richtung A · Ring Hero. Referenz: MotionCore-App-prototype.html (Übersicht) + source/screens.jsx
(SummaryScreen). Tagesform = accent, eine Farbe je Kennzahl, alle Flächen .card(), kein Glas/Blobs/
Gradient. KEINE Logikänderung. Previews: leer + mit Daten. STOPP-Gates: (1) Hero+Header (2) Karten-
Grid (3) ganzer Screen — je grün/rot.
```

---

## ☐ AP 3 · ActiveWorkoutView ✅ vollständig spezifiziert

**Abhängigkeit:** AP 0 + 1. **Verbindliche Spec:** `Documentation/Redesign/README.md` (§2–§9, pixelgenau). **Visuell:** `ActiveWorkoutView-prototype.html` + `source/active-workout.jsx`.
**Dateien:** README §8 (`ActiveWorkoutView`, `ActiveWorkoutStatus`, `LiveHealthCard`, `ActiveSetCard`, `RestTimerCard` + `CompactRestTimerView`, `PRBannerView`, `ExercisesOverviewCard`).
**Festgelegt (README §10):** (1) Satz-Karte **Variante A „Stacked"**; (2) Pausen-Timer **`inline`**; (3) Übungsliste **aufklappbar**; (4) echtes `ExerciseVideoView`-Standbild im 64×64-Thumbnail.
**Unangetastet:** Workout-Tracking (`RestTimerManager`, `ActiveSessionManager`, `SetManager`, Live-Health, PR-Erkennung).
**STOPP-Gates:** (1) Status-Header + Live-Chips (§4.1); (2) Satz-Karte + Superset (§4.4/§4.5); (3) Pausen-Timer inline + PR-Banner (§4.2/§4.3); (4) Übungsliste aufklappbar + Anpassen-Sheet (§4.6/§4.7) — je grün/rot.

**Prompt (kopieren):**
```
Setze Documentation/Redesign/README.md 1:1 um in Views/Workouts/Active/**. Verbindlich: das gesamte
README (§2 Tokens, §4 Komponenten, §7 SF-Symbols). Festgelegt: Satz-Karte Variante A „Stacked",
Pausen-Timer inline, Übungsliste aufklappbar, echtes ExerciseVideoView-Standbild im 64×64-Thumbnail.
Visuell: ActiveWorkoutView-prototype.html. Regelwerk: DESIGN.md. KEINE Logikänderung am Workout-
Tracking. STOPP-Gates: (1) Status-Header+Chips (2) Satz-Karte+Superset (3) Pausen-Timer inline +
PR-Banner (4) Übungsliste aufklappbar + Anpassen-Sheet — je grün/rot.
```

---

## ☐ AP 4 · Workouts-Liste + Detail

**Abhängigkeit:** AP 0 + 1. **Referenz:** `MotionCore-App-prototype.html` (Workouts) + `source/screens.jsx` (`WorkoutsScreen` — Tones `signal`/`sage`/`info` → `accentWash`/`success`-Wash/`series1`-Wash).
**Dateien:** `TrainingListView`, `WorkoutCard`, `StrengthSessionCard`, `OutdoorSessionCard`, `WorkoutCompletedCard`, `StrengthDetailView`, `OutdoorDetailView`, `NewWorkoutSheet`, `FilterChip`/`FilterSection`/`FilterTypes`, `TypeBreakdownCard`.
**Soll:** Karten via `.card()`, Filter-Chips neu, ein ruhiger Farbton je Workout-Typ.
**STOPP-Gates:** (1) Liste + Karten; (2) Filter; (3) Detail — je grün/rot.

**Prompt (kopieren):**
```
Redesigne Workouts-Liste + Detail in Views/Workouts/** nach DESIGN.md, mit den Bausteinen aus AP 1.
Referenz: MotionCore-App-prototype.html (Workouts) + source/screens.jsx (WorkoutsScreen). Karten auf
.card(); Filter-Chips auf den AP-1-Chip; ein ruhiger Farbton je Typ. Detail-Views angleichen. KEINE
Logikänderung. STOPP-Gates: (1) Liste+Karten (2) Filter (3) Detail — je grün/rot.
```

---

## ☐ AP 5 · Statistik

**Abhängigkeit:** AP 0 + 1. **Referenz:** `MotionCore-App-prototype.html` (Statistik) + `source/screens.jsx` (`StatsScreen`).
**Dateien:** `StatisticView`, `StatisticCard`, `StatisticGridCard`, `StatisticTrendChart`, `StatisticDonutChart`, `StatisticIntensityCard`/`Row`, `StatisticDeviceCard`/`Row`, `StrengthVolumeChart`, `StrengthOneRMChart`, `TypeBreakdownCard`.
**Unangetastet:** `StatisticsViewModel`, `StatisticCalcEngine`, `StrengthStatisticCalcEngine`.
**Soll (Schwerpunkt):** die **Regenbogen-Grid** in `StatisticView` auf die ruhige Palette kollabieren — eine Farbe je Kennzahl bzw. `Theme.series` in Reihenfolge. Charts einfarbig, kein Gradient, `chartGrid`.
**STOPP-Gates:** (1) Grid-Cards (Farb-Kollaps); (2) Trend-/Donut-Charts; (3) Detail-Charts — je grün/rot.

**Prompt (kopieren):**
```
Redesigne Statistik in Views/Statistics/** nach DESIGN.md, mit den Bausteinen aus AP 1. Referenz:
MotionCore-App-prototype.html (Statistik) + source/screens.jsx (StatsScreen). WICHTIG: Regenbogen-
Grid in StatisticView auf die ruhige Palette kollabieren (eine Farbe je Kennzahl bzw. Theme.series
in Reihenfolge). Alle Charts einfarbig, kein Gradient, chartGrid. KEINE Logikänderung. STOPP-Gates:
(1) Grid-Cards (2) Trend/Donut-Charts (3) Detail-Charts — je grün/rot.
```

---

## ☐ AP 6 · Body

**Abhängigkeit:** AP 0 + 1. **Referenz:** `MotionCore-App-prototype.html` (Body) + `source/screens.jsx` (`BodyScreen`).
**Dateien:** `BodyView`, `BodyTabSwitch`, `BodyCompositeScoreCard`, `BodyRecoveryListCard`, `BodyRecoveryTrendCard`, `BodyReadinessFactorsCard`, `BodyAvoidCard`, `MuscleRecoveryUI`, `MuscleRecoveryDonut`, `MuscleRecoveryDetailView`, `MuscleHeatmapView`/`ViewModel`/`SVGView`/`Legend`/`MiniView`, `BodyMeasurements*`-Suite.
**Unangetastet:** `BodyViewModel`, `MuscleRecoveryCalcEngine`, `RecoveryTrendCalcEngine`, `RecoveryRecommendationCalcEngine`, `MuscleHeatmapCalcEngine`, `BodyMeasurement*CalcEngine`.
**Soll:** Erholungs-Ring (`success`), Körpermaße-Karten, Gruppen-Balken (FactorBar). **Heatmap-Sonderfall:** `HeatLevel.color` **und** `.hexColor` (`MuscleHeatmapTypes.swift`) auf eine Theme-konforme **Light-Skala** umstellen — `.hexColor` sind Hex-Strings für die SVG-CSS-Injection (`MuscleHeatmapSVGView`/WKWebView), keine SwiftUI-Colors. *Vorschlag none→low→medium→high: `#E1EEF7` → `#BBD8EC`/`#3A8FC9` → `#2C6BCB` → `#21539E`, am Prototyp kalibrieren.* (Dark-Injection-Skala kommt in AP 11.)
**STOPP-Gates:** (1) Recovery-Ring + Faktoren; (2) Heatmap (Skala + SVG-Injection); (3) Körpermaße — je grün/rot.

**Prompt (kopieren):**
```
Redesigne Body in Views/Body/** und Views/Heatmap/** nach DESIGN.md, mit den Bausteinen aus AP 1.
Referenz: MotionCore-App-prototype.html (Body) + source/screens.jsx (BodyScreen). Erholungs-Ring =
success, Gruppen-Balken über FactorBar, Karten via .card(). SONDERFALL Heatmap: HeatLevel.color UND
.hexColor in MuscleHeatmapTypes.swift auf eine Theme-konforme Light-Skala (Vorschlag #E1EEF7 →
#BBD8EC/#3A8FC9 → #2C6BCB → #21539E). hexColor = Hex-Strings für die SVG-Injection, keine SwiftUI-
Colors. Dark-Skala NICHT jetzt (kommt in AP 11). KEINE Logikänderung. STOPP-Gates: (1) Recovery-Ring+
Faktoren (2) Heatmap-Skala+SVG-Injection (3) Körpermaße — je grün/rot.
```

---

## ☐ AP 7 · Training / Pläne

**Abhängigkeit:** AP 0 + 1. **Referenz:** `MotionCore-App-prototype.html` (Training) + `source/screens.jsx` (`TrainingScreen`).
**Dateien:** `TrainingPlanCard`, `TrainingDetailView` (Plan), `PlanExercisesSection`, `PlanActionsSection`, `PlanBasicDataCard`, `PlanInfoCard`, `PlanStatisticsCard`, `TemplateSetCard`, `SetConfigurationSheet`, `SetDurationSection`, `ExercisePickerSheet`/`ExercisePickerView`, `PlanImportPreviewSheet`/`PlanImportListSheet`/`PlanImportSchemaMismatchBanner`, `PlanUpdateSheet`/`PlanUpdateBanner`/`PlanUpdateChangeRow`.
**Unangetastet:** `SessionPlanSyncCalcEngine`, `PlanUpdateCalcEngine`, `PlanImportApplyService`/`PlanImportManager`/`SupabasePlanImportService`, `SessionSyncUndoService`.
**STOPP-Gates:** (1) Plan-Karten + Detail; (2) Set-Konfiguration + Sheets; (3) Picker + Import-Flows — je grün/rot.

**Prompt (kopieren):**
```
Redesigne Training/Pläne in Views/Training/** nach DESIGN.md, mit den Bausteinen aus AP 1. Referenz:
MotionCore-App-prototype.html (Training) + source/screens.jsx (TrainingScreen). Plan-Karten/Detail,
Set-Konfiguration, Picker, Import-/Update-Sheets auf den neuen Stil. KEINE Logikänderung. STOPP-Gates:
(1) Plan-Karten+Detail (2) Set-Konfig+Sheets (3) Picker+Import — je grün/rot.
```

---

# PHASE 2 — Rand & Politur

## ☐ AP 8 · Settings & Onboarding

**Abhängigkeit:** AP 0 + 1.
**Dateien:** `MainSettingsView`, `UserSettingsView`, `DisplaySettingsView`, `DataSettingsView`, `WorkoutSettingsView`, `BodyMeasurementSettingsView`, `StudioSetupView`, `StudioEquipmentEditSheet`/`Row`, `AboutView`, Onboarding-Karussell (`BodyMeasurementsValueCarousel`/`BodyMeasurementEntrySlide`).
**Soll:** Zeilen/Sheets mechanisch auf neuen Stil. **`DisplaySettingsView`:** Blob-/Hintergrund-Toggle entfernen (Folge AP 0); **Theme-Umschalter (System/Hell/Dunkel) als Picker einbauen**, gebunden an `@AppStorage("appColorScheme")` — die *Wirkung* (`.preferredColorScheme` am Root) wird in AP 11 verdrahtet.
**STOPP-Gates:** (1) Settings-Listen; (2) Sheets + Studio; (3) Onboarding — je grün/rot.

**Prompt (kopieren):**
```
Redesigne Settings & Onboarding in Views/Settings/** nach DESIGN.md, mit den Bausteinen aus AP 1.
In DisplaySettingsView den Blob-/Hintergrund-Toggle entfernen (Folge AP 0) und einen Theme-Umschalter
(System/Hell/Dunkel) als Picker einbauen, gebunden an @AppStorage("appColorScheme"); die Verdrahtung
am Root kommt in AP 11. KEINE Logikänderung. STOPP-Gates: (1) Settings-Listen (2) Sheets+Studio
(3) Onboarding — je grün/rot.
```

---

## ☐ AP 9 · Readiness-Detail & geteilte Sheets

**Abhängigkeit:** AP 0 + 1.
**Dateien:** `ReadinessDetailView`, `ReadinessCard`, `ReadinessFactorRow`, `ReadinessLabelStyle`, `ReadinessReducedBadge`, `CalibrationProgressRow`, `DebugReadinessSection`; `Views/Shared/**` (`GlassDivider`, `EmptyState`, `DisclosureRow`, `InfoRow`, plus Reste der MC*-/Glass-Komponenten).
**Unangetastet:** `ReadinessViewModel`, `ReadinessCalcEngine`, `SessionReadinessService`.
**Soll:** Faktor-Balken (FactorBar), `ReadinessLabelStyle` auf `Theme`; geteilte Sheets/Components auf AP-1-Bausteine.
**STOPP-Gates:** (1) Readiness-Detail; (2) geteilte Sheets/Components — je grün/rot.

**Prompt (kopieren):**
```
Redesigne Readiness-Detail (Views/Readiness/**) und geteilte Sheets/Components (Views/Shared/**)
nach DESIGN.md, mit den Bausteinen aus AP 1. Faktor-Balken über FactorBar, ReadinessLabelStyle auf
Theme. Verbleibende MC*-/Glass-Komponenten auf AP-1-Bausteine ziehen. KEINE Logikänderung.
STOPP-Gates: (1) Readiness-Detail (2) geteilte Sheets/Components — je grün/rot.
```

---

## ☐ AP 10 · Apple-Watch-App

**Abhängigkeit:** AP 0 + 1.
**Dateien:** `WatchActiveWorkoutView`, `WatchBaseView`, `MotionCoreWatchApp`, `WatchWorkoutManager` (nur UI), Complications (`StreakComplication`, `WeeklyProgressComplication`, `MotionCoreWatchComplications`).
**Soll:** reduzierter Token-Satz (Akzent, Text, Surface, **eine** Kennzahl). **Target-Membership prüfen:** die Theme-Color-Sets (Asset Catalog) + `AppFont` müssen im watchOS-Target verfügbar sein, sonst zuerst herstellen.
**Unangetastet:** Watch-Session-/Connectivity-Logik (`WatchSessionManager`, `WatchBridge`, `WatchHealthDataTypes`).
**STOPP-Gates:** (1) Watch-Active-Workout; (2) Complications — je grün/rot.

**Prompt (kopieren):**
```
Redesigne die Apple-Watch-App nach DESIGN.md mit reduziertem Token-Satz. Prüfe zuerst, dass die
Theme-Color-Sets + AppFont dem watchOS-Target zugeordnet sind, sonst herstellen. WatchActiveWorkoutView
+ Complications auf den neuen Stil. KEINE Änderung an Watch-Session-/Connectivity-Logik. STOPP-Gates:
(1) Watch-Active-Workout (2) Complications — je grün/rot.
```

---

## ☐ AP 11 · Dark Mode aktivieren + QA & Politur + Cleanup

**Abhängigkeit:** alle vorherigen. (Die Dark-**Werte** stecken bereits seit AP 0 in den Color Sets — hier wird Dark *scharfgeschaltet* und geprüft.)

**A) Dark Mode aktivieren:**
- **App-Root entpinnen:** `.preferredColorScheme(.light)` aus AP 0 ersetzen durch den vom Umschalter aufgelösten Wert: `@AppStorage("appColorScheme")` (System/Hell/Dunkel) → `.preferredColorScheme(appScheme.resolved)` (siehe DESIGN.md §11). Picker dafür kommt aus AP 8.
- **Heatmap-Dark:** für `MuscleHeatmapSVGView` eine Dark-Injection-Skala ergänzen (die Light-sky/accent-Skala ist auf Hell ausgelegt).
- **Durchsehen:** alle migrierten Screens in Dunkel sichten (Karten-Elevation über Hairline, `accentSoft`-Flächen mit hellem Akzent-Text).

**B) QA & Politur:** Dynamic Type, Reduced Motion (`@Environment(\.accessibilityReduceMotion)` — Endzustände lesbar), **Kontrast WCAG AA hell UND dunkel** (Grenzfälle: Weiß auf `accent`, Akzent-Text auf `accentSoft`), Konsistenz-Durchlauf.

**C) Cleanup:** `GlassCard`/`GlassButton`/`AnimatedBlob`/`BackgroundSettings`-Reste + deprecated Modifier entfernen; durch AP-1-Bausteine ersetzte MC*-Komponenten entfernen. *(`MCColorPalette.swift` ist bereits in AP 0 weg.)*

**STOPP-Gates:** (1) Umschalter + Dark scharf, Heatmap-Dark; (2) Dynamic Type + Reduced Motion; (3) Kontrast-Audit hell+dunkel; (4) Cleanup — je grün/rot.

**Prompt (kopieren):**
```
AP 11 — Dark Mode aktivieren + QA + Cleanup nach DESIGN.md §6/§11. Mit STOPP-Gate je Schritt:
(1) App-Root: .preferredColorScheme(.light) aus AP 0 durch den aufgelösten @AppStorage("appColorScheme")-
Wert ersetzen (System/Hell/Dunkel, siehe §11); Heatmap-Dark-Injection-Skala für MuscleHeatmapSVGView;
alle migrierten Screens in Dunkel sichten. (2) Dynamic Type + Reduced Motion. (3) Kontrast-Audit WCAG
AA hell+dunkel (Grenzfälle: Weiß auf accent, Akzent-Text auf accentSoft) + Konsistenz. (4) Cleanup:
GlassCard/GlassButton/AnimatedBlob/BackgroundSettings-Reste + deprecated Modifier + ersetzte MC*-
Komponenten entfernen. Je Schritt grün/rot.
```

---

## Orchestrierung — sequentiell oder mit parallelen Subagenten

Claude Code kann das Set sequentiell (ein Trio pro AP) **oder** mit parallelen Subagenten fahren. Parallelität lohnt **nur bei datei-disjunkten APs** — „großes Paket" allein ist kein Grund. Bei geteiltem State (gleiche Datei) entstehen Merge-Konflikte; außerdem ist Fan-out token-hungrig und kann Rate-Limits treffen.

**Topologie:**
1. **Phase 0 (AP 0 → AP 1) seriell, ein PR**, nach `main` mergen. Blocker, geteiltes Fundament (Asset Catalog). **Nicht** parallelisieren.
2. **Fan-out (Phase 1):** AP 2, 3, 4, 5, 6, 7 sind disjunkte `Views/`-Teilbäume → je AP ein **git worktree** + eigener Branch + eigener PR, mehrere parallel. Pro AP das Trio `planner → developer → quality-gate` + dein finales **grün/rot-Gate** (nicht wegautomatisieren).
3. **Freeze-Regel:** AP-1-Bausteine **und** der Asset Catalog sind während des Fan-outs eingefroren. Braucht ein Screen ein neues Token / einen geänderten Baustein → **pausieren, als einzelnen serialisierten PR** umsetzen, dann weiter.
4. **Phase 2 (AP 8, 9, 10)** nach den Screens; meist disjunkt, kann ebenfalls parallel — aber AP 9 fasst `Views/Shared/**` an (geteilt), daher AP 9 lieber allein laufen lassen oder zuletzt.
5. **AP 11 zuletzt, seriell** (schaltet Dark scharf, räumt app-weit auf, fasst viele Dateien an).

**Disjunktheit vor Fan-out verifizieren:** Faustregel „ein `Views/`-Teilbaum pro Agent". Geteilte Kollisionspunkte im Blick behalten: Asset Catalog, `Views/Shared/**`, `MotionCoreApp`/`BaseView`, `CLAUDE.md`. Das „prüfen-und-korrigieren" (adversarial verify) ist orthogonal zur Parallelität — es steckt im `quality-gate` und gilt seriell wie parallel.

---

## Reihenfolge & Merge-Strategie

**Wertreihenfolge:** `Setup → 0 → 1 → 2 → 3 → 6 → 5 → 4 → 7 → 8 → 9 → 10 → 11`.
Phase 0 zuerst (ein PR); Screen-PRs danach (parallel möglich, Bausteine eingefroren); jeder Screen-Branch rebased auf das gemergte Fundament; AP 11 zuletzt.

## Globale Definition of Done (pro AP)

- [ ] Kompiliert grün (an jedem Gate explizit bestätigt).
- [ ] Nur `Theme.*` / `AppFont.*` / `.card()` + AP-1-Bausteine; kein rohes Hex, kein `Color.blue|green|red|yellow|orange`, kein `MCColor` im View-Code.
- [ ] Keine Logikänderung (CalcEngines/Services/SwiftData unangetastet, außer im AP verlangt).
- [ ] SwiftUI-Previews der Hauptzustände im neuen Stil.
- [ ] Dateigrößen im Rahmen (Ziel ≤400, hart >600 splitten); keine „+" in Dateinamen; Datei-Header gesetzt.
- [ ] Ein Branch + ein PR, Conventional-Commits (Englisch).

---

## Noch offen (kein Blocker)

1. **Heatmap-Hues** (AP 6 Light / AP 11 Dark) — Vorschlag steht in den APs (sky→accent-Skala), final am Prototyp/Gerät kalibrieren.
2. **Theme-Mechanik** — dieses Set baut Theme als **Asset-Catalog-Colorsets** (passt zur Figma→camelCase→Asset-Catalog-Pipeline + Dark Mode). Falls doch ein statisches Hex-Enum gewünscht: nur AP-0-Schritt 1 + die Dark-Mechanik in AP 11 anpassen.
3. **Dark-Werte** sind ein begründeter Startpunkt — der WCAG-AA-Audit in AP 11 (hell+dunkel) ist der Gate; einzelne Werte dort ggf. nachziehen.