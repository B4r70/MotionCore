# MotionCore — Refactoring: Statistiken, Rekorde & Progression-Analyse

## Kontext

MotionCore ist eine persönliche iOS-Fitness-App (SwiftUI, SwiftData, HealthKit).
Die App unterstützt drei Workout-Typen: **Cardio** (`CardioSession`), **Kraft** (`StrengthSession`), **Outdoor** (`OutdoorSession`).
Alle drei implementieren das `CoreSession`-Protokoll. Generische Berechnungen laufen über `CoreSessionCalcEngine<T: CoreSession>`.

### Architektur-Regeln (NICHT verhandelbar)

- **Keine Business-Logik in Views.** Alle Berechnungen gehören in dedizierte `CalcEngine`-Structs.
- **Code-Kommentare auf Deutsch**, Variablen/Methoden auf Englisch.
- **Production Code only** — kein Test-Code generieren.
- **Glassmorphism-Design** mit blauen Gradienttönen (`#F0F7FF`, `#C9E6FF`, `#9BD2FF`).
- Bestehende Komponenten wiederverwenden: `StatisticGridCard`, `StatisticCard`, `RecordCard`, `RecordGridCard`, `GlassCard`, `TimeframePicker`, `StatisticTrendChart`, `StatisticDonutChart`, `ShowStarRating`, `EmptyState`, `AnimatedBackground`.

---

## Teil 1: Neue StatsAndRecordsView-Struktur

### Aktuell

```
StatsAndRecordsView → Segmented Control: Statistiken | Rekorde | Kraft
```

### Neu

```
StatsAndRecordsView → Segmented Control: Statistiken | Rekorde  (2 Segmente)
```

- Das **Kraft-Segment entfällt** — die `StrengthStatisticView` wird komplett in die neue `StatisticView` integriert.
- Die **HealthMetricView wird entfernt** — ersetzt durch eine neue **ProgressionAnalyseView** als eigener Tab in der App.
- `StatsSegment`-Enum anpassen: `.strength` Case entfernen.

---

## Teil 2: Neue StatisticView (vereint alle Trainingstypen, Kraft-dominant)

### Datenquellen

Die View benötigt `@Query` für alle drei Session-Typen:

- `[CardioSession]`
- `[StrengthSession]`
- `[OutdoorSession]`

### TimeframePicker

Oben in der View: `TimeframePicker(selection: $selectedTimeframe)` mit **Woche | Monat | Jahr | Alle**.
Der bestehende `SummaryTimeframe`-Enum und `TimeframePicker` können 1:1 wiederverwendet werden.
Alle KPIs und Charts müssen den gewählten Zeitraum berücksichtigen.

### KPI-Grid (LazyVGrid, 2 Spalten)

Reihenfolge der Grid-Cards:

| # | KPI | Datenquelle | Icon | Farbe |
|---|-----|-------------|------|-------|
| 1 | Gesamt Workouts | Alle Session-Typen (Cardio + Strength + Outdoor) | `figure.run` | `.blue` |
| 2 | Gesamt Kalorien | Alle Session-Typen | `flame.fill` | `.orange` |
| 3 | Gesamt Volumen | Nur `StrengthSession` (`totalVolume`) | `scalemass.fill` | `.purple` |
| 4 | ⌀ Herzfrequenz | Alle Session-Typen (über `CoreSession.heartRate`) | `heart.fill` | `.red` |
| 5 | Gesamt Sets | Nur `StrengthSession` (`totalSets`) | `list.number` | `.teal` |
| 6 | ⌀ Volumen/Session | Nur `StrengthSession` | `chart.bar.fill` | `.indigo` |
| 7 | ⌀ Dauer | Alle Session-Typen (über `CoreSession.duration`) | `clock.fill` | `.cyan` |
| 8 | ⌀ METs | Nur `CardioSession` (Cardio-spezifisch) | `bolt.fill` | `.yellow` |
| 9 | Gesamt Strecke | `CardioSession.distance` + `OutdoorSession.distance` | `arrow.left.and.right` | `.green` |

### Kraft-spezifische Charts (Kurzfassung)

Unterhalb des KPI-Grids:

- **Volumen-Trend-Chart** (aus `StrengthStatisticCalcEngine.volumeTrend`) — kompakt als `StatisticTrendChart`.
- **1RM-Chart** (aus `StrengthStatisticCalcEngine.estimatedOneRM`) — Kurzfassung. Die Detail-Version kommt in die ProgressionAnalyseView.

### Typübergreifende Trend-Charts

- **Herzfrequenz-Trend** — bleibt (`StatisticTrendChart` mit `coreCalc.heartRateTrend` über alle Typen).
- **Kalorien-Trend** — bleibt (`StatisticTrendChart` mit `coreCalc.caloriesTrend` über alle Typen).
- Gerätespezifische Distanz-Charts (Crosstrainer, Ergometer) → **entfernt**.

### Cardio/Outdoor-Section (klein, unten)

Unterhalb der Kraft-dominanten Inhalte, als eigener Bereich mit einer kleinen Überschrift:

- ⌀ Belastungsintensität (Stern-Rating, `StatisticCard`)
- ⌀ Kaloriendichte (`StatisticCard`, Cardio-spezifisch)
- Geräte-Verteilung (`StatisticDeviceCard`)
- Intensitäts-Verteilung (`StatisticIntensityCard`)
- Donut-Chart Programme (`StatisticDonutChart`)

### HealthKit-Section (ausklappbar, standardmäßig eingeklappt)

Am Ende der View eine `DisclosureGroup` mit:

- Aktuelle Herzfrequenz (aus `HealthKitManager.latestHeartRate`)
- Schlafzusammenfassung (aus `HealthKitManager.todaySleepSummary`)

Diese Daten stammen aus der entfernten `HealthMetricView`. Die Schlaf-Daten werden für einen zukünftigen Fitness-Score benötigt.

### CalcEngine-Anpassung

Der bestehende `StatisticCalcEngine` muss erweitert werden:

- Zusätzliche Inputs: `[StrengthSession]`, `[OutdoorSession]`
- Neue Properties für typübergreifende Summen:
  - `totalWorkoutsAll` (Cardio + Strength + Outdoor count)
  - `totalCaloriesAll` (über CoreSessionCalcEngine für jeden Typ, dann summieren)
  - `averageHeartRateAll` (gewichteter Durchschnitt über alle Typen mit HR > 0)
  - `averageDurationAll`
- Kraft-spezifische Properties delegieren an `StrengthStatisticCalcEngine`
- TimeFrame-Filter über `SummaryTimeframe` implementieren (ähnlich wie `StrengthStatisticCalcEngine.filtered(by:)`)

### Dateien die entfallen

- `StrengthStatisticView.swift` → Logik wandert in die neue `StatisticView`
- `HealthMetricView.swift` → ersetzt durch ProgressionAnalyseView (eigener Tab)
- `HealthMetricCalcEngine.swift` → ggf. einzelne Properties (BMI etc.) in `StatisticCalcEngine` übernehmen, falls benötigt

---

## Teil 3: Neue RecordView (Kraft-dominant)

### Kraft-Rekorde (prominent, oben)

Neuer `StrengthRecordCalcEngine` (separate Datei: `StrengthRecordCalcEngine.swift`).

Input: `[StrengthSession]`

Benötigte Rekorde:

| Rekord | Berechnung | Icon | Farbe |
|--------|-----------|------|-------|
| Höchstes Gewichtsvolumen | `sessions.max(by: { $0.totalVolume })` | `scalemass.fill` | `.purple` |
| Meiste Sätze | `sessions.max(by: { $0.totalSets })` | `list.number` | `.teal` |
| Meiste Reps gesamt | `sessions.max(by: { sum of all reps })` | `repeat` | `.blue` |
| Schwerster Einzelsatz | Max `ExerciseSet.weight` über alle Sessions/Sets | `dumbbell.fill` | `.orange` |
| Längstes Kraft-Training | `sessions.max(by: { $0.duration })` | `clock.fill` | `.indigo` |
| Meiste Übungen | `sessions.max(by: { $0.exercisesPerformed })` | `figure.strengthtraining.traditional` | `.green` |
| Höchstes geschätztes 1RM | Max `set.weight * (1 + reps/30)` über alle Sessions | `trophy.fill` | `.yellow` |

**Für den schwersten Einzelsatz und das höchste 1RM** muss die CalcEngine auch den Übungsnamen und das Datum zurückgeben. Empfehlung: Ein eigenes `StrengthRecord`-Struct:

```swift
struct StrengthRecord {
    let session: StrengthSession
    let exerciseName: String?  // Optional, nur bei set-level Rekorden
    let value: Double
    let formattedValue: String
}
```

### Darstellung

- Kraft-Rekorde als `RecordGridCard` im 2er-Grid (wie aktuell Cardio-Rekorde).
- Für den „Schwersten Einzelsatz" und „Höchstes 1RM" den Übungsnamen als Subtitle anzeigen.

### Cardio-Rekorde (reduziert)

Nur noch **2 Cardio-Rekorde** beibehalten, unterhalb der Kraft-Rekorde:

1. **Längste Distanz** (`RecordCalcEngine.longestDistanceWorkout`)
2. **Effektivstes Workout** / Höchster Kalorienverbrauch (`RecordCalcEngine.highestBurnedCaloriesWorkout`)

Alle anderen Cardio-Rekorde (Crosstrainer-best, Ergometer-best, Speed-Rekorde, Körpergewicht-Rekorde) → **entfernt**.

### Erfolgs-Indikatoren (in RecordView oder StatisticView)

Diese Features müssen nicht alle sofort implementiert werden, aber die Architektur sollte sie ermöglichen:

1. **Persönliche Records (PRs) mit Datum** — z.B. „Bestes 1RM Bankdrücken: 80 kg am 12.03.2026". Kann aus `StrengthRecordCalcEngine` oder `ProgressionCalcEngine` kommen.
2. **Streak-Anzeige** — z.B. „4 Wochen in Folge mindestens 3× trainiert". Logik gehört in einen `StreakCalcEngine` (existiert teilweise schon in `StreakCard`).
3. **Volumen-Meilensteine** — z.B. „10 Tonnen Gesamtvolumen erreicht!". Berechnung in `StrengthStatisticCalcEngine`.
4. **Muskelgruppen-Balance** — Donut-Chart welche Muskelgruppen wie oft trainiert werden. Daten aus `StrengthSession.trainedMuscleGroups`.
5. **Trainingsfrequenz-Heatmap** (GitHub-Style) — welche Tage im Jahr trainiert wurde. Daten aus allen Session-Typen über `CoreSession.date`.

---

## Teil 4: Neue ProgressionAnalyseView (eigener Tab)

### Navigation

Die ProgressionAnalyseView wird als **eigener Tab** in der TabView der App hinzugefügt (nicht als Segment in StatsAndRecordsView).

### Datenquellen

- `@Query [StrengthSession]` (sortiert nach Datum, descending)
- `@Query [Exercise]` (für Progression-Konfiguration pro Übung)
- `ProgressionCalcEngine` für die Analyse pro Übung

### Gesamtübersicht (Hero-Section oben)

Eine zusammenfassende Card die zeigt:

- **Wie viele Übungen verbessern sich** (Trend = `.improving`) → grün
- **Wie viele stagnieren** (Trend = `.stable`) → blau
- **Wie viele sinken** (Trend = `.declining`) → orange/rot
- **Deload-Warnung**: Wenn ≥ 3 Übungen `.declining` sind, eine prominente Warnung anzeigen.

Berechnung: Für jede trainierte Übung `ProgressionCalcEngine.analyze()` aufrufen und die Trends aggregieren. → Gehört in einen neuen `ProgressionAnalyseCalcEngine`.

### Übungsliste (Hybrid-Layout)

**Alle trainierten Übungen** anzeigen (nicht nur Favoriten).

Layout: **Kompakte Cards** in einem vertikalen ScrollView. Jede Card zeigt:

- Übungsname
- Aktuelles Gewicht
- Trend-Icon + Farbe (aus `PerformanceTrend`)
- Konfidenz-Level-Icon (aus `ProgressionConfidence`)
- Empfohlene Aktion als kurzer Text (aus `ProgressionAction.displayName`)

**Antippbar** → expandiert zu einer Detailansicht (Sheet oder NavigationLink) mit:

- **1RM-Entwicklung als Chart** (Line-Chart über Zeit, Daten aus `ProgressionCalcEngine.extractSnapshots` → `estimatedOneRM`)
- **Volumen-Trend als Chart** (Line-Chart, Daten aus Snapshots → `totalVolume`)
- **Double-Progression-Fortschritt** als ProgressBar (0.0–1.0, zeigt wie weit im Rep-Range)
- **Trainings-Level** (Anfänger/Fortgeschritten/Erfahren/Wiedereinsteiger)
- **Reasoning-Points** (aus `ProgressionAnalysis.reasoningPoints`) als Liste
- **Sessions analysiert**, **Tage seit letzter Session**

### CalcEngine

Neuer `ProgressionAnalyseCalcEngine`:

```swift
struct ProgressionAnalyseCalcEngine {
    let sessions: [StrengthSession]
    let exercises: [Exercise]
    private let progressionEngine = ProgressionCalcEngine()

    // Alle trainierten Übungsnamen (unique, aus ExerciseSet-Snapshots)
    var allTrainedExerciseNames: [String]

    // Analyse pro Übung
    func analysis(for exercise: Exercise) -> ProgressionAnalysis

    // Aggregierte Übersicht
    var improvingCount: Int
    var stableCount: Int
    var decliningCount: Int
    var needsDeload: Bool  // >= 3 declining
}
```

### Detailansicht

Neue `ProgressionDetailView`:

- Input: `ProgressionAnalysis` + `[SessionSnapshot]`
- Charts für 1RM und Volumen (können `StatisticTrendChart` wiederverwenden, mit angepasstem Titel/Label)
- ProgressBar für Double-Progression (neues Component, z.B. `ProgressionProgressBar`)

---

## Teil 5: Zusammenfassung der neuen/geänderten Dateien

### Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `StrengthRecordCalcEngine.swift` | Kraft-spezifische Rekord-Berechnungen |
| `ProgressionAnalyseCalcEngine.swift` | Aggregierte Progressions-Übersicht |
| `ProgressionAnalyseView.swift` | Tab-View für Progressions-Analyse |
| `ProgressionDetailView.swift` | Detail-Sheet pro Übung |
| `ProgressionOverviewCard.swift` | Hero-Card mit improving/stable/declining Counts |
| `ProgressionExerciseCard.swift` | Kompakte Card pro Übung in der Liste |
| `ProgressionProgressBar.swift` | Double-Progression Fortschrittsbalken |

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `StatisticView.swift` | Komplett neu: Alle Typen, Kraft-dominant, TimeframePicker, HealthKit-Section |
| `StatisticCalcEngine.swift` | Erweitert um Strength + Outdoor Inputs, typübergreifende KPIs |
| `RecordView.swift` | Kraft-Rekorde dominant, Cardio auf 2 Rekorde reduziert |
| `StatsAndRecordsView.swift` | Nur noch 2 Segmente (Statistiken, Rekorde), Kraft-Segment entfällt |
| `MotionCoreApp.swift` (o.ä. TabView) | Neuer Tab für ProgressionAnalyseView |

### Entfernte Dateien

| Datei | Grund |
|-------|-------|
| `StrengthStatisticView.swift` | In StatisticView integriert |
| `HealthMetricView.swift` | Ersetzt durch ProgressionAnalyseView |
| `HealthMetricCalcEngine.swift` | Relevante Teile in StatisticCalcEngine übernommen |

---

## Implementierungs-Reihenfolge (Empfehlung)

1. **StrengthRecordCalcEngine** erstellen (isoliert, keine UI-Abhängigkeiten)
2. **StatisticCalcEngine** erweitern (TimeFrame-Filter, Multi-Type-Support)
3. **StatisticView** neu bauen (Grid + Charts + Cardio-Section + HealthKit-Section)
4. **RecordView** umbauen (Kraft-Rekorde + reduzierte Cardio-Rekorde)
5. **StatsAndRecordsView** anpassen (2 Segmente)
6. **ProgressionAnalyseCalcEngine** erstellen
7. **ProgressionAnalyseView** + Components bauen
8. **ProgressionDetailView** bauen
9. **Tab-Integration** in der App
10. **Aufräumen**: Alte Dateien entfernen, Imports prüfen
