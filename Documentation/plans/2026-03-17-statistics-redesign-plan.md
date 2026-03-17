# Implementierungsplan: Statistics, Records & Tab-Redesign

**Datum**: 2026-03-17
**Scope**: Teil 1–5 (ProgressionAnalyseView kommt später als separate Session)

---

## Zusammenfassung der Entscheidungen

| Punkt | Entscheidung |
|-------|-------------|
| Scope | Teil 1–5: CalcEngines + StatisticView + RecordView + Tab-Struktur |
| OutdoorSession | Existiert vollständig — wird in typübergreifenden KPIs berücksichtigt |
| Neuer Tab (später) | „Analyse" / `brain.head.profile` für ProgressionAnalyseView |
| RecordGridCard | Existiert, aber CardioSession-gebunden → neue `StrengthRecordGridCard` nötig |
| CalcEngine-Filter | `filtered(by: SummaryTimeframe) → new StatisticCalcEngine` |
| HealthKit-Section | Nur **aktive Kalorien** + **Schlaf** (`HealthKitManager.shared`) in StatisticView |
| Donut-Chart | Entfernen (zu cardio-spezifisch) |
| Erfolgs-Indikatoren | Nicht in diesem Scope |

---

## Schritt 1: StrengthRecordCalcEngine erstellen

**Neue Datei**: `Services/Calculation/StrengthRecordCalcEngine.swift`

### StrengthRecord-Struct (in gleicher Datei)

```swift
struct StrengthRecord {
    let session: StrengthSession
    let exerciseName: String?   // Optional — nur bei Set-Level-Rekorden
    let value: Double
    let formattedValue: String
}
```

### Zu berechnende Rekorde (Input: `[StrengthSession]`)

| Property | Berechnung | Rückgabe |
|----------|-----------|---------|
| `highestVolumeSession` | `sessions.max(by: { $0.totalVolume < $1.totalVolume })` | `StrengthRecord?` |
| `mostSetsSession` | `sessions.max(by: { $0.safeExerciseSets.count < $1.safeExerciseSets.count })` | `StrengthRecord?` |
| `mostRepsSession` | max sum of all set.reps | `StrengthRecord?` |
| `heaviestSingleSet` | max `ExerciseSet.weight` über alle Sessions/Sets | `StrengthRecord?` (mit exerciseName) |
| `longestStrengthSession` | `sessions.max(by: { $0.duration < $1.duration })` | `StrengthRecord?` |
| `mostExercisesSession` | max unique exercises per session | `StrengthRecord?` |
| `highestEstimated1RM` | max `weight * (1 + reps/30)` über alle Sets | `StrengthRecord?` (mit exerciseName) |

---

## Schritt 2: StatisticCalcEngine erweitern

**Geänderte Datei**: `Services/Calculation/StatisticCalcEngine.swift`

### Neue Signatur

```swift
struct StatisticCalcEngine {
    let allCardioSessions: [CardioSession]
    let allStrengthSessions: [StrengthSession]
    let allOutdoorSessions: [OutdoorSession]

    func filtered(by timeframe: SummaryTimeframe) -> StatisticCalcEngine
}
```

**Migration**: bisheriger `allWorkouts` → `allCardioSessions` (alle Callsites anpassen).

### Neue typübergreifende Properties

```swift
var totalWorkoutsAll: Int          // Cardio + Strength + Outdoor
var totalCaloriesAll: Int          // Summe aller calories via CoreSessionCalcEngine
var averageHeartRateAll: Int       // Gewichteter Ø über alle Typen mit HR > 0
var averageDurationAll: Int        // Ø Dauer aller Typen
```

### Kraft-Properties (delegieren an StrengthStatisticCalcEngine)

```swift
private var strengthCalc: StrengthStatisticCalcEngine { ... }
var totalVolume: Double            // → strengthCalc.totalVolume
var averageVolume: Double          // → strengthCalc.averageVolume
var totalSets: Int                 // → strengthCalc.totalSets
var averageSets: Double            // → strengthCalc.averageSets
var volumeTrend: [TrendPoint]      // → strengthCalc.volumeTrend
var estimated1RMData: [TrendPoint] // → strengthCalc.estimatedOneRM (o.ä.)
```

### `filtered(by:)` Implementierung

Filtert alle drei Arrays auf Basis von `SummaryTimeframe` (analog zu `StrengthStatisticCalcEngine.filtered(by:)`).

---

## Schritt 3: StatisticView neu bauen

**Geänderte Datei**: `Views/Statistics/Workouts/View/StatisticView.swift`

### Queries

```swift
@Query(sort: \CardioSession.date, order: .reverse)
private var cardioSessions: [CardioSession]

@Query(sort: \StrengthSession.date, order: .reverse)
private var strengthSessions: [StrengthSession]

@Query(sort: \OutdoorSession.date, order: .reverse)
private var outdoorSessions: [OutdoorSession]

@State private var selectedTimeframe: SummaryTimeframe = .month
@ObservedObject private var healthKitManager = HealthKitManager.shared
```

### Layout-Aufbau

```
ScrollView
├── TimeframePicker (Woche | Monat | Jahr | Alle)
│
├── KPI-Grid (LazyVGrid, 2 Spalten, 9 Cards)
│   ├── Gesamt Workouts    (figure.run, .blue)
│   ├── Gesamt Kalorien    (flame.fill, .orange)
│   ├── Gesamt Volumen     (scalemass.fill, .purple) [Strength only]
│   ├── Ø Herzfrequenz     (heart.fill, .red) [Alle Typen]
│   ├── Gesamt Sets        (list.number, .teal) [Strength only]
│   ├── Ø Volumen/Session  (chart.bar.fill, .indigo) [Strength only]
│   ├── Ø Dauer            (clock.fill, .cyan) [Alle Typen]
│   ├── Ø METs             (bolt.fill, .yellow) [Cardio only]
│   └── Gesamt Strecke     (arrow.left.and.right, .green) [Cardio + Outdoor]
│
├── Kraft-Charts
│   ├── StatisticTrendChart (Volumen-Trend, aus strengthCalc.volumeTrend)
│   └── StrengthOneRMChart (kurze Vorschau, aus strengthCalc.estimated1RMData)
│
├── Typübergreifende Trend-Charts
│   ├── StatisticTrendChart (Herzfrequenz-Trend)
│   └── StatisticTrendChart (Kalorien-Trend)
│
├── Cardio/Outdoor-Section (Überschrift: "Cardio & Outdoor")
│   ├── Ø Belastungsintensität (StatisticCard mit ShowStarRating)
│   ├── Ø Kaloriendichte (StatisticCard)
│   ├── StatisticDeviceCard
│   └── StatisticIntensityCard
│
└── HealthKit-Section (Überschrift: "Gesundheit", DisclosureGroup)
    ├── HealthMetricCalorieHeroCard (aktiveBurnedCalories)
    └── HealthMetricSleepHeroCard (todaySleepSummary)
```

### CalcEngine-Nutzung

```swift
private var calc: StatisticCalcEngine {
    StatisticCalcEngine(
        allCardioSessions: cardioSessions,
        allStrengthSessions: strengthSessions,
        allOutdoorSessions: outdoorSessions
    ).filtered(by: selectedTimeframe)
}
```

---

## Schritt 4: RecordView umbauen

**Geänderte Datei**: `Views/Statistics/Records/View/RecordView.swift`

### Neue Komponente: StrengthRecordGridCard

**Neue Datei**: `Views/Statistics/Records/Components/StrengthRecordGridCard.swift`

```swift
struct StrengthRecordGridCard: View {
    let metricTitle: String
    let recordValue: String
    let recordDate: Date
    let subtitle: String?      // Übungsname (für 1RM/Einzelsatz)
    let metricIcon: IconTypes
    let metricColor: Color
}
```

### Layout RecordView

```
ScrollView
├── Kraft-Rekorde (Überschrift: "Kraft-Rekorde")
│   LazyVGrid(2 Spalten) mit StrengthRecordGridCard:
│   ├── Höchstes Gewichtsvolumen   (scalemass.fill, .purple)
│   ├── Meiste Sätze               (list.number, .teal)
│   ├── Meiste Reps gesamt         (repeat, .blue)
│   ├── Schwerster Einzelsatz      (dumbbell.fill, .orange) + Übungsname
│   ├── Längstes Kraft-Training    (clock.fill, .indigo)
│   ├── Meiste Übungen             (figure.strengthtraining.traditional, .green)
│   └── Höchstes geschätztes 1RM   (trophy.fill, .yellow) + Übungsname
│
└── Cardio-Rekorde (Überschrift: "Cardio-Rekorde", reduziert auf 2)
    LazyVGrid(2 Spalten) mit RecordGridCard:
    ├── Längste Distanz            (arrow.left.and.right, .green)
    └── Höchster Kalorienverbrauch (flame.fill, .orange)
```

### Entfernte Cardio-Rekorde

- `bestCrosstrainerWorkout` → entfernt
- `bestErgometerWorkout` → entfernt
- `fastestCardioDevice` → entfernt
- `lowestBodyWeight` / `highestBodyWeight` → entfernt

---

## Schritt 5: StatsAndRecordsView anpassen

**Geänderte Datei**: `Views/Statistics/StatsAndRecordsView.swift`

- `StatsSegment.strength` Case entfernen
- Nur noch 2 Segmente: `.statistics` | `.records`
- `StrengthStatisticView()` aus dem Switch entfernen

---

## Dateien die entfallen (nach Fertigstellung löschen)

| Datei | Grund |
|-------|-------|
| `StrengthStatisticView.swift` | Logik in StatisticView integriert |
| `StrengthVolumeChart.swift` | Durch StatisticTrendChart ersetzt (prüfen ob noch referenziert) |
| `StrengthOneRMChart.swift` | Prüfen ob behalten oder ersetzen |

**Vorerst behalten** (bis Tab-Redesign in Session 2):
- `HealthMetricView.swift` + alle Health-Komponenten → Health-Tab bleibt bis ProgressionAnalyseView implementiert

---

## Implementierungsreihenfolge

1. `StrengthRecord`-Struct + `StrengthRecordCalcEngine` erstellen
2. `StatisticCalcEngine` erweitern (Signatur-Änderung + neue Properties)
3. Alle Callsites von `StatisticCalcEngine` prüfen und anpassen
4. `StrengthRecordGridCard` erstellen
5. `StatisticView` komplett neu bauen
6. `RecordView` umbauen
7. `StatsAndRecordsView` anpassen (2 Segmente)
8. `StrengthStatisticView` (+ ggf. Charts) löschen
9. Build-Check via Xcode

---

## Offene Fragen für spätere Session

- ProgressionAnalyseView (Teil 6–10) → eigener Tab „Analyse" (`brain.head.profile`)
- HealthMetricView entfernen sobald ProgressionAnalyseView fertig ist
- `HealthMetricCalcEngine` aufräumen (BMI-Properties ggf. in AppSettings behalten)
