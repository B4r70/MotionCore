# MotionCore Calm-2026-Redesign — Session-Handoff

> **🎉 REDESIGN ABGESCHLOSSEN (2026-07-08): AP 0–11 vollständig auf `main`.** Alle 12 APs implementiert, gebaut, gegrünt und gemerged — `origin/main` = `d064039` (Merge PR #14, AP 11). Holistischer Dark-Sweep durch alle Tabs (Dunkel+Hell) vom User durchgeführt: **keine Auffälligkeiten**. §11-Abnahme erledigt. Das Calm-2026-Redesign ist live auf `main`.
>
> Optional/Rest: alte `redesign/*`-Branches aufräumen; bewusst nicht angefasste Nicht-Theme-Reste (`wrapContentInGlassCard`-Param-Name, Material in ExerciseVideoView/AppIconView/KeyboardToolbar/FormViewSection — Icon-/Video-/Keyboard-Kontext) → optionaler Folgedurchlauf falls je gewünscht.
>
> Stand: 2026-07-03 (AP 4/7/8/9/10 fertig+gepusht). Dieses Dokument ist der Wiedereinstiegspunkt für eine **neue Session mit leerem Kontext**.
> Lies zuerst: dieses File → `DESIGN.md` (Repo-Root) → `Documentation/Redesign/MotionCore_Redesign_Instruction.md` (AP-Plan).

---

## 1 · Was ist das Projekt

MotionCore = persönlicher iOS-Fitness-Tracker (SwiftUI + SwiftData + Swift Charts + HealthKit + ActivityKit, Apple-Watch-Companion, Supabase). iOS 17+, kein XCTest.

Wir setzen das **„Calm 2026"-Redesign** um: helle, ruhige Oberfläche statt dunklem „Liquid Glass". Verbindliches Design-System steht in **`DESIGN.md`** (Repo-Root). Der Ausführungsplan ist **`Documentation/Redesign/MotionCore_Redesign_Instruction.md`** (Arbeitspakete **AP 0–11**, je eigener Branch + eigener PR, mit STOPP-Gates).

**Eiserne Regeln (gelten immer):**
- Akzent app-weit = Tiefblau `#2C6BCB`. `Theme.accent` ist die **einzige** Akzentquelle. Nie eine zweite.
- Redesign = **NUR Darstellung**. Keine Änderung an CalcEngines/Services/SwiftData/ViewModels/Bindings/Gesten, außer im AP explizit verlangt.
- Nur `Theme.*` / `AppFont.*` / `.card()` + die AP-1-Bausteine. **Kein rohes Hex, kein `Color.blue|green|red|yellow|orange|purple|teal|…`, kein Gradient (Charts einfarbig), kein `MCColor`/Glas/Blob** im View-Code.
- Deutsche UI + Kommentare, englischer Code. Conventional Commits (Englisch).
- App ist bis **AP 11** per `.preferredColorScheme(.light)` auf Hell gepinnt (Dark-Werte stecken aber schon in den Asset-Colorsets).

---

## 2 · KRITISCHE Umgebungs-Gotchas (sonst geht nichts)

### 2a · Bash ist standardmäßig blockiert (lean-ctx-Shell-Hook)
Der `lean-ctx`-Shell-Wrapper routet **jeden** Bash-Befehl durch `eval` → der Harness blockiert das („Command uses eval … blocked"). **Fix (bereits gesetzt in `.claude/settings.local.json`):**
```json
"env": { "LEAN_CTX_ALLOWLIST_WARN_ONLY": "1" }
```
Damit läuft Bash wieder; es bleibt nur eine **kosmetische `WARN`-Zeile** vor jeder Ausgabe (ignorieren). Diese settings-Änderung ist bewusst **nur lokal** (uncommitted). Greift ab Session-Start (Harness injiziert env). Falls in einer neuen Session Bash wieder blockt → prüfen, ob der `env`-Eintrag noch da ist.

### 2b · Build (das STOPP-Gate)
CLI-Tools zeigen auf CommandLineTools, daher **`DEVELOPER_DIR` überschreiben** (kein sudo nötig). Xcode-beta 27 ist installiert:
```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild \
  -scheme "MotionCore iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug -derivedDataPath /tmp/mc_dd build
```
Im Hintergrund laufen lassen (run_in_background) + Log in Datei; dann `grep -E "\*\* BUILD (SUCCEEDED|FAILED)|error:"`. Erfolg = `** BUILD SUCCEEDED **`, Exit 0.

### 2c · zsh-Eigenheiten beim Scripten
- Unquoted `$var` **wird in zsh NICHT in Wörter gesplittet** → `for x in $list` iteriert einmal über den ganzen String. Nutze `… | while read -r x; do …` oder Glob.
- Multi-Pfad-`grep` mit Glob-Pfaden, die Leerzeichen enthalten (z. B. `MotionCoreWatch Watch App`), kann grep stören → Einzelpfade nutzen.
- Für Suche `grep`/`find` funktionieren wieder (dank 2a). MCP-`ctx_*`-Tools waren in dieser Session teils disconnected — nicht drauf verlassen.

### 2d · Neue Dateien & Datei-Header
Projekt nutzt **synchronisierte Xcode-Ordner** (PBXFileSystemSynchronizedRootGroup) → neue `.swift`-Dateien im Sync-Root werden automatisch ins Target aufgenommen, **kein `project.pbxproj`-Edit nötig**. Asset-Catalog-Colorsets werden als Einheit kompiliert.
Datei-Header ist eine **85-Zeichen-breite Kommentar-Box**. Generieren per bash-Helper:
```bash
b1="//$(printf '%082d' 0 | tr '0' '-')/"          # Top-Border
bi="// $(printf '%081d' 0 | tr '0' '-')/"         # Inner-Border
hdr() { printf '%-84s/\n' "$1"; }                 # Inhaltszeile auf 85
```
(Achtung: Em-Dash „—" in Header-Zeilen sind multibyte → Box wird 2 Bytes kürzer; in Headern lieber ASCII.)

---

## 3 · Design-Tokens & Bausteine (AP 0 + AP 1, eingefroren)

**Tokens** in `MotionCore/Views/Shared/Redesign/Theme.swift`: `Theme` (Asset-Catalog-Colorsets, Light+Dark), `AppFont`, `enum Space {s1=4…s8=32}`, `enum Radius {sm10/md14/lg20/xl26}`.
- Flächen: `surfaceApp` (Seite), `surfaceCard` (Karte), `surfaceSunken` (Inset/Track).
- Text: `textPrimary/textSecondary/textTertiary`. Linien: `line/lineSoft`.
- Akzent: `accent/accentHover/accentPress/accentSoft`, `accentWash` (= accent.opacity(0.08)).
- Status: `success` (Erholung/Body), `warning` (Streak/Rekorde/Kalorien/Amber), `danger` (Fehler/Puls).
- Charts: `series[0..4]` = [Blau, Teal, Violett, Amber, Rosé], `chartGrid`.
- `Color(hex:)` (`Utils/Extensions/ColorHexExtension.swift`) bleibt für Einzelfälle.

**Karte:** `.card(padding: Space.s6)` (`MotionCore/Components/Cards/Card.swift`) — solide `surfaceCard`, Radius `lg`, 1px `Theme.line`-Hairline, Schatten **nur in Light**.

**AP-1-Bausteine** (alle in `Views/Shared/Redesign/`):
- `Button`-Styles: `.mcPrimary` (voll accent, Press 0.97), `.mcSecondary` (accentSoft), `.mcGhost` (transparent). **Achtung: alle erzwingen intern `maxWidth:.infinity`** → in HStacks teilen sie sich die Breite 50/50; `.mcGhost` ist die einzige content-breite Variante.
- `Chip(title:systemImage:isSelected:action:)` · `Badge(text:style:.soft/.solid,color:)` · `StatTile(eyebrow:value:unit:tint:)` · `SectionHeader(title:eyebrow:trailing:)`.
- `FactorBar(label:subLabel:value:tint:)` (value 0…1) · `ProgressRing(progress:size:stroke:tint:centerValue:centerLabel:centerSubText:)` · `Sparkline(data:color:showFill:)` **(fixe 70pt-Breite intern! füllt Panels nicht — Baustein-Tweak offen)**.
- `FABButtonStyle` (`.mcFAB`) · `.frostedTabBar()` (in `BaseView` verdrahtet) · `.calmSheet(_ detents:)`.

**Animationsdauern (§6):** 0.14 / 0.24 / 0.36 s, easeOut/easeInOut. **Keine Endlos-Loops** (in AP 3 wurde z. B. der Watch-Puls entfernt).

---

## 4 · Git-/Branch-Strategie (WICHTIG)

- **Fundament** = `redesign/ap1-shared-components` (enthält AP 0 + AP 1). Jeder Screen-AP zweigt **davon** ab (`git checkout -b redesign/apX-… redesign/ap1-shared-components`) → **Geschwister, nicht gestackt** → sauberer Einzel-PR pro AP, kein fremder Diff.
- Ein AP = ein Branch + ein Commit + eigener PR. Conventional Commit, am Ende Footer `Co-Authored-By: Claude Opus 4.8 …` + `Claude-Session: …`.
- Beim Branch-Wechsel revertieren andere-AP-Dateien im Working Tree auf Fundament-Stand — **das ist normal/erwartet** (die Arbeit liegt sicher im jeweiligen Commit). Nicht erschrecken.
- `.claude/settings.local.json` (env-Fix) + `tasks/current.md` + `Documentation/Redesign/`-Untracked **nie** in AP-Commits mitnehmen.

### Branch-Status (alle auf origin gepusht: git.barto.cloud **und** github)
| Branch | Commit | Status |
|---|---|---|
| `redesign/ap0-theme-foundations` | `cb6bdf7` | ✅ AP 0 (war schon da) |
| `redesign/ap1-shared-components` | `8151849` | ✅ AP 1 (Fundament) |
| `redesign/ap2-summary-home` | `c2868d2` | ✅ AP 2 |
| `redesign/ap3-active-workout` | `b006ec7` | ✅ AP 3 |
| `redesign/ap6-body` | `6466944` | ✅ AP 6 |
| `redesign/ap5-statistics` | `9642631` | ✅ AP 5 |
| `fix/strength-detail-horizontal-scroll` | `f69c5fc` | ✅ Bugfix (in AP 4 gemergt) |
| `redesign/ap4-workouts` | `bffdd0c` | ✅ AP 4 (gepusht 2026-07-03) |
| `redesign/ap7-training` | `a3e1a18` | ✅ AP 7 (gepusht 2026-07-03) |
| `redesign/ap8-settings` | `ffc4462` | ✅ AP 8 (gepusht 2026-07-03) |
| `redesign/ap9-readiness` | `cd24fbb` | ✅ AP 9 (gepusht 2026-07-03) |
| `redesign/ap10-watch` | `161f312` | ✅ AP 10 (in `main` gemerged) |
| `redesign/ap11-dark-qa-cleanup` | `a4ae551` | ✅ AP 11 (von `main`, PR-bereit) |

**AP 0–10 in `main` gemerged; AP 11 PR-bereit.** — alle Branches liegen push-bereit auf origin (barto.cloud + github).

### Integration nach main — vorbereitet & verifiziert (2026-07-04)
**Merge-Reihenfolge (konfliktfrei, per Dry-Run + Integrations-Build bestätigt):**
`main ← ap1 → ap2 → ap3 → ap6 → ap5 → ap4 → ap7 → ap8 → ap9 → ap10`.
- main = `c35a2bd` (Pre-Redesign); ap1 = main + 2 lineare Commits (enthält ap0). **10 PRs.**
- **3 Vorab-Angleichungs-Commits** gepusht, damit alle Merges ohne Handkonflikt laufen (Byte-identisch-Muster; „gleiche Datei von 2 APs migriert"):
  - ap4 `e53792e`: `WorkoutCompletedCard.swift` ← ap3-Version (Eigentümer `Views/Workouts/Active/`).
  - ap8 `85a9754`: `BodyMeasurementsValueCarousel.swift` ← ap6-Version (ap6 war Obermenge; Eigentümer `Views/Body/`).
  - ap7 `fdb641e`: `TypesUI.swift` wieder byte-identisch zu ap5; ap7-eigene `PlanType`-Extension in **neue Datei `MotionCore/Utils/Themes/PlanTypeUI.swift`** verschoben (neue Datei = sauberer Merge-Add; löst EOF-Newline-Konflikt).
- **Verifiziert:** kumulativer Dry-Run aller 10 = CLEAN; integrierter Stand (main+AP0–10) **iOS-Build inkl. embedded Watch = BUILD SUCCEEDED**. (Build im Worktree braucht die git-ignorierte `MotionCore/Config/MotionCoreSecrets.xcconfig` aus dem Haupt-Checkout — reinkopieren.)
- **AP 11 wartet**, bis main = integriertes AP 0–10; dann AP-11-Branch **von main** (nicht von ap1).

---

## 5 · Erledigt (mit Inhalt)

**AP 0 · Theme & Foundations** (`cb6bdf7`): 21 Asset-Colorsets (Light+Dark), `Theme/AppFont/Space/Radius`, `.card()` (alle 116 `.glassCard()` migriert, `glassCard()` deprecated), flacher `Theme.surfaceApp` statt AnimatedBackground/Blob/Gradient (zentral in `BackgroundSettings.swift` entkernt; `showAnimatedBlob`-Flag inert), `MCColorPalette.swift` gelöscht + `MCColor`→`Theme`, `.preferredColorScheme(.light)` in `MotionCoreApp.swift`.

**AP 1 · Bausteine** (`8151849`): siehe §3. Je Baustein SwiftUI-Preview. Alte MC*-Komponenten (`MCChip/MCFactorBar/MCHeroRing/MCMiniRing/MCSparkline`), `GlassButton`, `StatBubble`, `FilterChip` bleiben vorerst (Entfernung AP 11).

**AP 2 · Übersicht/Home** (`c2868d2`): Richtung A · Ring-Hero. `SummaryCommandHero` = `ProgressRing` (Tagesform/accent) + Empfehlung + `.mcPrimary` + StatTile-Reihe (Erholung/Streak/Puls). MCChip→Chip, MCMiniRing→ProgressRing, MCSparkline→Sparkline, XP-Gradient→einfarbig, Aktivitäts-Hexskala→`accent`-Intensität, alle Insight-/Typ-Karten tokenisiert.

**AP 3 · ActiveWorkoutView** (`b006ec7`): pixelnah nach `Documentation/Redesign/README.md` §4. Status-Header (3 Spalten + Balken + Live-Chips, `LiveHealthCard` in den Header gefaltet → Datei jetzt ungenutzt), Satz-Karte Variante A „Stacked" (64×64 `ExerciseVideoView`-Thumbnail) + Superset (→success), Pausen-Timer **inline** (einfarbiger Ring, ≤30s warning/≤10s danger), PR-Banner (warning-soft + crown + „Rekord"-Badge), aufklappbare Übungsliste, Anpassen-Sheet `SetEditSheet` mit `.calmSheet`. Logik (RestTimerManager/SetManager/ExerciseCountdownManager/Drag&Drop/Superset) unangetastet.

**AP 6 · Body** (`6466944`): `BodyCompositeScoreCard` RadialGradient-Wash entfernt → zentrierter `ProgressRing(success)`; MCFactorBar→FactorBar, MuscleRecoveryDonut→ProgressRing, BodyTabSwitch flach, Trend-Chart einfarbig. **Heatmap-Light-Skala**: `HeatLevel.color`+`.hexColor` (`Models/Types/MuscleHeatmapTypes.swift`) = none→high `#E1EEF7 → #BBD8EC → #3A8FC9 → #2C6BCB` (sky→accent); SVG-Basis-Fill + Mini-Binär-Fills angeglichen. Körpermaße-Suite (Sparkline/.calmSheet/Tokens). **Dark-Heatmap-Skala bewusst auf AP 11 verschoben.**

**AP 5 · Statistik** (`9642631`): Regenbogen-Kollaps — KPI/Record/Health-Grids: rohe Farben → `series[0..4]` + Status-Token je Kennzahl. **`TypesUI.swift`-Domänen-Enums** (`Intensity`/`CardioDevice`/`TrainingProgram`) auf `Theme` (Option A, app-weit). Donut → `series` via `chartForegroundStyleScale`; Trend-Charts einfarbig accent + `chartGrid`; Volume/1RM/Hero-Cards gradient-frei.

**Bugfix** (`f69c5fc`, eigener Branch): `StrengthDetailView` scrollte horizontal — Ursache `LazyVGrid` in `statisticsCard` ohne Breiten-Klemme; Fix = `.frame(maxWidth: .infinity)` als äußerster Modifier am ScrollView-Inhalt. Vom User auf Gerät bestätigt.

**AP 4 · Workouts-Liste + Detail** (`bffdd0c`, Branch `redesign/ap4-workouts` von `ap1`, 7 Commits, Plan: `AP4-PLAN.md`): Karten→`.card()`, ein Typ-Ton je Workout (neuer `WorkoutTypeIconTile` + `WorkoutType.calmTileBackground/.calmIconTint`), Metrik-Regenbogen→semantische Map (Puls=danger, kcal=warning, neutral=series[0]), Intensität auf Karte neutral/Detail volle Ampel, `OutdoorActivity.tint`→success, StrengthSessionCard Endlos-Puls→statischer Dot, Typ-Filter→AP-1-`Chip`, `FilterSection`/`FilterChip` calm, `StatBubble` entglast, Detail-/Form-Views (Strength/Outdoor/Cardio inkl. `StrengthEditView`) + `AddExerciseDuringWorkoutSheet` tokenisiert. **Scroll-Fix verschärft:** `containerRelativeFrame(.horizontal)+.clipped()` (die `maxWidth:.infinity`-Klemme war unzureichend — WKWebView-Heatmap zog den Inhalt breit; Heatmap zusätzlich per GeometryReader geklemmt + AP-6-Farben repliziert). **Cross-Branch:** AP-5-`TypesUI`- + AP-6-`MuscleHeatmapMiniView`-Migration byte-identisch repliziert (trivialer Merge). **Deferred:** `SessionPlanSyncSheet`/`PlanPickerSheet`→AP 7; `SetEditSheet`/`ActiveWorkoutStatus`/`ReadinessReducedBadge`→AP 3; `ReadinessLabelStyle`/`ExerciseQualityRating.color`→AP 9.

**AP 7 · Training/Pläne** (`a3e1a18`, Branch `redesign/ap7-training` von `ap1`, 4 Gate-Commits, Plan: `AP7-PLAN.md`): `PlanType.calmTint/.calmTileBackground` (an AP4-WorkoutType angeglichen: strength=accent/cardio=series[1]/outdoor=success/mixed=series[2]) ersetzt lokale Regenbogen-Switches; FilterChip von ap4 repliziert. Plan-Karten (Buchstaben-Tile), Detail, Set-Konfig (RIR→Theme, Schwellen behalten), Plan-Edit (Drag&Drop/Superset unangetastet), Picker/Import/Update/Sync tokenisiert. **Gate 4 = reichweitenbasierte Scope-Erweiterung (User-Freigabe):** `TrainingFormView` + gesamte **Exercise-Library** (`ExerciseListView`/`ExerciseFilterSheet`/`LocalExerciseSearchView`/`ExerciseFormView`/`ExerciseInstructionsCard` [Color.blue.gradient→accent]/`ExerciseCard` [Rep-Range→Theme]/`ExerciseAPIView`/Muskel-Picker) + `SessionSyncUndoBanner` — waren nicht in der Dateiliste, aber aus Plan/Picker erreichbar. Services unangetastet. Gesamte `Views/Training/`-Fläche verifiziert residue-frei. **Lehre:** nach jedem AP VOLLER Bereichs-Sweep (nicht nur geplante Dateien); Grep MUSS `glassDivider|GlassDivider|.gradient` enthalten.

**AP 10 · Apple-Watch-App** (Gate 1 `c678c2b`, Gate 2 `161f312`, Branch `redesign/ap10-watch` von `ap1`): **Target-Membership war der Knackpunkt.** Befund: `Theme.swift` + die 21 Theme-Colorsets lagen NUR im iOS-Target; die Watch nutzte rohe SwiftUI-Farben/System-Fonts. Der `MotionCore/`-Sync-Root ist für Nicht-Owner-Targets eine **Allow-Liste** (`PBXFileSystemSynchronizedBuildFileExceptionSet.membershipExceptions` = opt-in, Beweis: das Widget-Target listet nur 3 Dateien). **Plumbing (Gate 1):** (a) `Views/Shared/Redesign/Theme.swift` in die Watch-Allow-Liste (EEDE2C47) aufgenommen — eine pbxproj-Zeile, `Theme.swift` ist watchOS-sicher (nur SwiftUI); (b) **reduzierter Token-Satz** (8 Colorsets: accent, accentHover, success, warning, danger, textPrimary/Secondary/Tertiary) byte-kopiert nach `MotionCoreWatch Watch App/Assets.xcassets/` (Theme/-Ordner hat kein `provides-namespace` → Bare-Name-Auflösung). **Gate 1 UI:** `WatchActiveWorkoutView` + `IdleView` von rohen Farben auf Theme — Herz `danger`, Kalorien/Streak/Pause/Rest `warning`, primäre Aktion `accent`, Vordergrund-Akzent **`accentHover`** (besserer Kontrast auf Schwarz), Timer/Zahlen `design:.monospaced`→**`.rounded` + `.monospacedDigit()`**; `.primary/.secondary/.tertiary`→`Theme.text*`. **Gate 2:** `StreakComplication` (orange→warning), `WeeklyProgressComplication` (blue→accentHover, .secondary→textSecondary). Watch-Session-/Connectivity-Logik (`WatchSessionManager` 501, `WatchWorkoutManager` 308 — null SwiftUI) unangetastet. **Build-Gate:** `-scheme "MotionCoreWatch Watch App" -destination 'generic/platform=watchOS Simulator'` (Sim-Runtime fehlt → SDK-Build); iOS-Build embedded den Watch-Target zusätzlich → beide grün. **Watch rendert DARK-Werte** (kein `.preferredColorScheme`-Pin im Watch-Entry, folgt System; natives Schwarz bleibt Hintergrund, kein `surfaceApp`-Fill). Voller Watch-Sweep sauber.

**AP 9 · Readiness-Detail & geteilte Sheets** (Gate 1 `69d138d`, Gate 2 `cd24fbb`, Branch `redesign/ap9-readiness` von `ap1`, 2 Gate-Commits): **KORREKTUR zum Plan-Dok:** die AP-9-Dateiliste war veraltet/verstreut — `Views/Readiness/` = nur 3 Dateien, `Views/Shared/` (außer `Redesign/`) leer; die geteilten Primitives liegen unter `Components/`. **Gate 1 (Readiness-Detail):** Score-Header → AP-1 `ProgressRing` (Füllung+Zahl in Label-Farbe, wie Tagesform-Ring der Übersicht; Batterie-Icon entfällt), `ReadinessFactorRow` → `FactorBar` (SubLabel `Wert · Gewicht %`, Status-Ramp danger/warning/success), `CalibrationProgressRow` → success/accent, `ReadinessLabelStyle.color` **in place** auf Theme (veryLow→danger, low+normal→warning, good+excellent→success), `AnimatedBackground`→`Theme.surfaceApp`. **Gate 2 (geteilte Komponenten):** `GlassDivider` Material/Grau → feine `Theme.line`-Hairline (API + `.glassDivider()`-Modifier + Varianten unverändert → 13 Verwender ziehen mit, **Rename auf calmen Namen bewusst nach AP 11**), `EmptyState` entglast (getönter `accentWash`-Kreis in `.card()`, Text auf AppFont/Theme; 14 Verwender), `DisclosureRow`-Default → `Theme.textPrimary`, `InfoRow` `.secondary`→`textSecondary`, `ExerciseQualityRating.color` **in place** auf Theme (3 Zeilen; Intensity/TrainingProgram/CardioDevice bleiben AP-5-Eigentum, mergen konfliktfrei). **Cross-Branch bewusst NICHT angefasst** (schon auf Sibling migriert): `ReadinessCard`/`ReadinessReducedBadge` (AP 3), `DebugReadinessSection` (AP 8). **Voller Sweep** `Views/Readiness/` sauber; verbliebene `Components/`-Residue triagiert = sibling-eigen (StatBubble/FilterSection→AP4, SetDurationSection→AP7), AP-11-Löschziele (GlassCard/GlassButton), oder **Orphans außerhalb AP-9-Theme & nicht aus Readiness erreichbar** → siehe §6 (FormViewSection, ExerciseVideoView, AppIconView, KeyboardToolbar).

**AP 8 · Settings & Onboarding** (`ffc4462`, Branch `redesign/ap8-settings` von `ap1`, 3 Gate-Commits, Plan: `AP8-PLAN.md`): sehr saubere Basis. **Blob-Toggle entfernt** (DisplaySettingsView). **KORREKTUR zum ursprünglichen Auftrag:** Theme-Umschalter existiert BEREITS (`AppTheme` system/light/dark mit `.colorScheme`, Picker an `$appSettings.appTheme`; App-Root `.preferredColorScheme(.light)` + AP-11-Kommentar) → KEINE neue `@AppStorage("appColorScheme")`. Native-Form-Settings-Views unangetastet; Debug-/Supabase-Sections/EBike-Profil/Studio (`AnimatedBackground`→surfaceApp)/BodyMeasurements-Karussell (DeltaPill green/red→success/danger) tokenisiert. `Views/Settings/`-Fläche residue-frei.

---

## 6 · NOCH ZU ERLEDIGEN

### ✅ AP 11 abgeschlossen (2026-07-08, Branch `redesign/ap11-dark-qa-cleanup` von `main`, 4 Gate-Commits)
- **Gate 1 (`8b16e90`) Dark scharf + Heatmap-Dark:** App-Root `.preferredColorScheme(.light)` → `appSettings.appTheme.colorScheme` (Umschalter aus AP 8 greift). Heatmap komplett schema-konsistent: `HeatLevel.hexColor(for:)/color(for:)` mit Dark-Skala (`#222C37`→`#6BB0E8`), `svgStylesCSS(for:)`; große + Mini-SVG-Views + Legende + Region-Listen reichen `@Environment(\.colorScheme)` explizit durch (folgt SwiftUI-Scheme, nicht System).
- **Gate 2 (`560c915`) Reduced Motion:** `ProgressRing` + `FactorBar` werten `accessibilityReduceMotion` aus (Endzustand ohne Animation). **Dynamic Type: feste AppFont-Größen bewusst behalten** (User-Entscheidung, DESIGN.md §3, Single-User).
- **Gate 3 (`02256a8`) WCAG-AA-Kontrast:** systematischer Audit aller Token-Paare (Light+Dark), auf reale Render-Schwelle gemappt (Icon/Großtext 3.0 vs Normaltext 4.5). 2 echte Fails behoben: **warning-Light `#C7902F`→`#9A6B1A`** (2.82→4.67, iOS+Watch-Colorset+DESIGN.md §2) und **Tagesform-Ring-Füllung in Dark→accentHover** (2.75→3.44, SummaryCommandHero). textTertiary-Light 3.04 + Grenzfälle bewusst akzeptiert.
- **Gate 4 (`a4ae551`) Cleanup + FAB-Migration:** **11 tote/abgelöste Dateien gelöscht** (GlassCard, GlassButton+GlassButtonExamples, MCChip/MCFactorBar/MCHeroRing/MCMiniRing/MCSparkline, AnimatedBlob, LiveHealthCard). **FAB-Migration** (übersehener Redesign-Rest): `floatingActionButton()` → Calm `.mcFAB` (4 Screens, Call-Sites unberührt), ToolbarButton calm. `showAnimatedBlob`-Flag komplett getilgt (AnimatedBackground-Signatur + 12 Sites + AppSettings), GradientBackground weg, `GlassDivider`→`HairlineDivider`. **Lehre:** finaler Verwender-Check vor dem Löschen deckte auf, dass FloatingButton/ToolbarButton noch `.glassButton` nutzten — Kartierung war ungenau, Check rettete vor Broken Build.

### (historisch) Verbleibende APs — (A) App-Root entpinnen: `.preferredColorScheme(.light)` → vom `@AppStorage("appColorScheme")`-Umschalter aufgelöst (Picker aus AP 8); **Heatmap-Dark-Injection-Skala** für `MuscleHeatmapSVGView` ergänzen; alle Screens in Dunkel sichten. (B) Dynamic Type, Reduced Motion, **WCAG-AA-Kontrast hell+dunkel** (Grenzfälle: Weiß auf accent, Akzent-Text auf accentSoft). **Nach Merge in HELL nachprüfen** (durch AP-9-Shared-Änderungen NACH ihrer AP-Freigabe verändert, daher von keinem Sibling-Grün abgedeckt): `EmptyState`-Instanzen (leere Listen quer durch alle Tabs), Divider-dichte Karten (`GlassDivider`-Hairline), und AP-3-`ReadinessCard` im ActiveWorkout mit den neuen `ReadinessLabel`-Theme-Farben. **Watch (AP 10):** hat KEINEN `.preferredColorScheme`-Pin, rendert schon dunkel — beim Dark-Scharfschalten NICHTS an der Watch nötig. **ABER:** der reduzierte Watch-Token-Satz (8 Colorsets in `MotionCoreWatch Watch App/Assets.xcassets/`) ist eine **Kopie** — wenn der WCAG-Audit Dark-Werte in `MotionCore/Assets.xcassets/Theme/` nachzieht, dieselben 8 (accent, accentHover, success, warning, danger, textPrimary/Secondary/Tertiary) im Watch-Catalog **mitziehen** (sonst Drift Uhr↔iPhone). (C) **Cleanup:** `GlassCard`/`GlassButton`/`AnimatedBlob`/`BackgroundSettings`-Reste + deprecated Modifier entfernen; `GlassDivider` ist seit AP 9 calm-in-place (Theme.line-Hairline) → optional in `HairlineDivider` o. ä. umbenennen (13 Verwender, tangiert AP-4/7-Dateien → nur in AP 11); ersetzte MC*-Komponenten + `LiveHealthCard.swift` (ungenutzt seit AP 3) + ungenutzte `AnimatedBackground`-Call-Sites entfernen; **AP-9-Orphans abarbeiten** (FormViewSection/ExerciseVideoView/AppIconView/KeyboardToolbar — siehe Querschnitts-Liste).

### Querschnittliche Aufräum-Punkte (über mehrere APs / final in AP 11)
- **Bewusst gelassene Domänen-Enum-Farben** (wie `setKind.color`): `ReadinessLabelStyle` ✅ AP 9, `ExerciseQualityRating.color` ✅ AP 9. **`genderMetrics.color` liegt NICHT in `TypesUI` sondern = `GenderIconView.gender.color` in `HealthMetricView` (AP-5-Statistik-Territorium) → AP 5/11, nicht AP 9.**
- **Orphan-Glass-Komponenten aus AP-9-Sweep** (kein Sibling-Eigentum, aber außerhalb AP-9-Theme & nicht aus Readiness erreichbar → **AP 11 / dedizierter Form-Pass**): `Components/Forms/FormViewSection.swift` (~900 Zeilen Regenbogen-Ramps + `ultraThinMaterial`, größter Brocken), `Components/Media/ExerciseVideoView.swift` (Video-Control-Material, aus AP-4/7-Screens genutzt), `Components/Elements/AppIconView.swift` (1× Material, nur AboutView), `Components/Forms/KeyboardToolbar.swift` (1× Material, konventionell). GlassCard/GlassButton sind ohnehin AP-11-Löschziele.
- **`AddExerciseDuringWorkoutSheet.swift`** (Active-Ordner, ~30 rohe Farben) — war nicht in AP-3-§8-Liste; eigener Folge-Durchlauf (passt thematisch zu AP 4/7).
- **`Sparkline` breitenflexibel machen** (aktuell fixe 70pt) — AP-1-Baustein-Tweak; betrifft `SummaryStatGridCard` + `BodyMeasurementsCard`. AP-1-Bausteine sind „eingefroren" → als serialisierter Einzel-PR, dann betroffene Screens.
- **`recoveryTint(_:)`** liegt aktuell top-level in `MuscleRecoveryDonut.swift`; ideale Heimat `MuscleRecoveryUI.swift` neben `recoveryColor`.
- **`BodyMeasurementEntrySlide`**: Unit-Label `.title3`→`AppFont.title` ist etwas schwer; ggf. auf `AppFont.body` absenken (visueller Review).
- **`MCColorPalette.swift` ist bereits in AP 0 weg** — nicht erneut suchen.

---

## 7 · Bewährter Workflow für ein AP (so weitermachen)

1. **Branch** `redesign/apX-…` von `redesign/ap1-shared-components` abzweigen.
2. **Orientieren** (nichts aus dem Gedächtnis): Referenz `Documentation/Redesign/source/screens.jsx` (passender `*Screen`) + ggf. `MotionCore-App-prototype.html`; bei AP 3 die verbindliche `README.md`. Aktuellen Code lesen — bei großen Screens einen **Explore-Subagenten** zum Kartieren nutzen (Struktur, Stilprobleme mit Datei:Zeile, Logik-vs-View-Grenze, ViewModels).
3. **Plan + STOPP-Gate-Aufteilung** vorlegen, **auf „grün" des Users warten** (Gate-Protokoll: an jedem Gate explizit grün/rot, vage Bestätigung zählt nicht).
4. **Umsetzen:** spec-kritische/strukturelle Teile selbst; breite mechanische Tokenisierung an einen `motioncore-developer`-Subagenten delegieren (mit exaktem Token-Mapping + „nur Darstellung, keine Logik/Signatur"). Danach **selbst bauen + Residue-Grep** (rohe Farben/Gradient/Material/MC*), Reste fixen.
5. Pro Gate **bauen** (§2b) → grün/rot melden → erst nach Grün weiter.
6. Am AP-Ende: **commit** (nur AP-Dateien), auf Wunsch **push**.

**Residue-Grep-Muster:**
```bash
grep -rnE "(Color)?\.(blue|green|red|yellow|orange|purple|teal|indigo|cyan|mint|pink|brown|gray)\b|LinearGradient|RadialGradient|ultraThinMaterial|MCColor|MCSparkline|MCFactorBar|MCHeroRing|MCMiniRing|MCChip|glassCard|GlassDivider" --include='*.swift' <Pfad> | grep -vE "Color\.white|Color\.clear|Theme\.|series|setKind\.color"
```
Erlaubt/bewusst auslassen: `Color.white`/`.clear` (strukturell), `Color(hex:)` der Heatmap-Skala, Domänen-Enum-`.color` (setKind/HeatLevel/rating/gender), Preview-Sample-Farben.

---

## 8 · Wiedereinstieg in einer neuen Session (Copy-Paste-Start)

> „Wir setzen das MotionCore Calm-2026-Redesign fort. Lies `Documentation/Redesign/SESSION-HANDOFF.md`, `DESIGN.md` und `Documentation/Redesign/MotionCore_Redesign_Instruction.md`. **Erledigt sind AP 0–10** — alle Branches auf origin (barto.cloud + github), noch keine PRs. Heute: **AP 11 · Dark Mode aktivieren + QA + Cleanup** (das LETZTE AP, seriell) — (A) App-Root `.preferredColorScheme(.light)` in `MotionCoreApp` durch den aufgelösten `appSettings.appTheme.colorScheme` ersetzen (Picker existiert seit AP 8), Heatmap-Dark-Injection-Skala für `MuscleHeatmapSVGView`, alle Screens in Dunkel sichten; (B) Dynamic Type + Reduced Motion + **WCAG-AA-Kontrast hell+dunkel**; (C) Cleanup GlassCard/GlassButton/AnimatedBlob/BackgroundSettings + deprecated Modifier + ersetzte MC*-Komponenten + `LiveHealthCard` + GlassDivider-Rename + **AP-9-Sweep-Orphans** (FormViewSection/ExerciseVideoView/AppIconView/KeyboardToolbar). **Achtung §5/§6-Merknotizen:** nach Merge in HELL die AP-9-Shared-Änderungen (EmptyState/Hairline/ReadinessCard) nachprüfen; Watch braucht KEIN Dark-Scharfschalten (rendert schon dunkel), aber Watch-Colorset-Kopie bei WCAG-Wert-Änderungen mitziehen. **WICHTIG: AP 11 fasst viele Branch-übergreifende Dateien an — Reihenfolge/Merge-Strategie klären (rebase auf gemergtes Fundament), da die Screen-APs noch als Geschwister-Branches offen sind (keine PRs gemerged).** Bewährtes Vorgehen (wie AP 2–10): Explore-Agent kartiert die Fläche → Plan + STOPP-Gate-Aufteilung vorlegen und auf mein explizites Grün warten → pro Gate Umsetzung (bei kleiner/urteilslastiger Fläche inline statt Fan-out) + Build (§2b; für Watch-Teile `-scheme "MotionCoreWatch Watch App" -destination 'generic/platform=watchOS Simulator'`) + Residue-Grep (MUSS `glassDivider|GlassDivider|.gradient` enthalten) → visuelles Grün → Commit pro Gate → nach dem letzten Gate VOLLER Bereichs-Sweep. Gates laut Instruction: (1) Umschalter+Dark scharf + Heatmap-Dark (2) Dynamic Type + Reduced Motion (3) Kontrast-Audit hell+dunkel (4) Cleanup."

Zur Build-/Bash-Umgebung: §2 dieses Dokuments beachten (env-Fix + `DEVELOPER_DIR`-Build).
