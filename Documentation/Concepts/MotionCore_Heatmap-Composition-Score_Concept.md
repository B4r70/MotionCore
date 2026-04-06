# Konzept: Heatmap Composite Score

**Ziel:** Die Muskel-Heatmap soll nicht mehr nur nach Gesamtvolumen (Gewicht × Reps) färben, sondern einen gewichteten Composite Score aus Volumen, Satzzahl und Trainingsfrequenz verwenden. Damit bildet die Heatmap realistischer ab, welche Muskeln tatsächlich am meisten beansprucht werden.

**Komplexität:** Small (1 Datei ändern, 1 Datei erweitern, 1 View minimal anpassen)

---

## Problem

Aktuell bestimmt `relativeIntensity` in `MuscleHeatmapCalcEngine` die Heatmap-Farbe ausschließlich über `totalVolume` (= `weight × reps`, aufsummiert). Das führt dazu, dass schwere Compound-Übungen (z.B. Kniebeugen, Beinpresse) dominieren, obwohl sie nur in 1–2 Übungen eines Plans vorkommen. Muskeln wie Brust und Trizeps, die über viele Übungen und Sessions hinweg häufig trainiert werden, erscheinen im Vergleich unterrepräsentiert.

---

## Lösung: Composite Score

Drei normalisierte Faktoren werden gewichtet kombiniert:

```
compositeScore = (normVolume × 0.40) + (normSets × 0.35) + (normFrequency × 0.25)
```

| Faktor | Beschreibung | Gewicht |
|---|---|---|
| **Volumen** | Gewicht × Reps (wie bisher) | 40% |
| **Satzzahl** | Anzahl abgeschlossener Sets (wird bereits getrackt, aber nicht genutzt) | 35% |
| **Frequenz** | Anzahl *verschiedener Sessions*, in denen der Muskel vorkam | 25% |

### Warum diese Gewichtung?

- **Volumen (40%)** bleibt der stärkste Faktor, weil mechanische Spannung der Haupttreiber für Muskelwachstum ist.
- **Satzzahl (35%)** fängt ab, dass viele leichte Sets (z.B. Isolationsübungen für Trizeps) auch substantielles Training darstellen.
- **Frequenz (25%)** belohnt Muskeln, die über mehrere Trainingstage hinweg angesprochen werden — ein anerkannter Faktor für Hypertrophie.

### Normalisierung

Jeder Faktor wird relativ zum Maximum über alle Regionen normalisiert (0.0–1.0):

```swift
let normVolume = maxVolume > 0 ? volume / maxVolume : 0
let normSets = maxSets > 0 ? Double(sets) / Double(maxSets) : 0
let normFrequency = maxFrequency > 0 ? Double(frequency) / Double(maxFrequency) : 0
```

### Sekundäre Muskeln

Die bestehende 30%-Gewichtung für sekundäre Muskeln wird auf alle drei Faktoren angewendet:

- **Volumen:** `+= volume * 0.3` (bereits so)
- **Satzzahl:** `+= 1` zählt nur bei primär, sekundär wird **nicht** als separater Set gezählt (sonst Inflation)
- **Frequenz:** Session-ID wird auch für sekundäre Muskeln ins Set aufgenommen (ein Muskel, der in jeder Push-Session sekundär arbeitet, verdient Frequenz-Credit)

---

## Betroffene Dateien

### 1. `MuscleHeatmapCalcEngine.swift` — Hauptänderung

**Neues Dictionary hinzufügen:**

```swift
var frequencyByRegion: [String: Set<UUID>] = [:]  // Session-UUIDs pro Region
```

**Im Primär-Block (Zeile 43–49) ergänzen:**

```swift
frequencyByRegion[regionId, default: []].insert(session.sessionUUID)
```

**Im Sekundär-Block (Zeile 52–57) ergänzen:**

```swift
frequencyByRegion[regionId, default: []].insert(session.sessionUUID)
```

> Hinweis: `setsByRegion` bleibt unverändert — sekundäre Muskeln zählen dort wie bisher **nicht** als Set.

**Composite Score berechnen (ersetzt Zeile 62–71):**

```swift
// 3. Maxima für Normalisierung
let maxVolume = volumeByRegion.values.max() ?? 1.0
let maxSets = setsByRegion.values.max() ?? 1
let maxFrequency = frequencyByRegion.values.map(\.count).max() ?? 1

// 4. MuscleHeatData für alle SVG-Regionen erstellen
let allSvgRegionIds = Set(DetailedMuscle.allCases.compactMap { $0.svgRegionId })
var regionData: [String: MuscleHeatData] = [:]

// Gewichtung
let weightVolume = 0.40
let weightSets = 0.35
let weightFrequency = 0.25

for regionId in allSvgRegionIds {
    let volume = volumeByRegion[regionId] ?? 0
    let sets = setsByRegion[regionId] ?? 0
    let frequency = frequencyByRegion[regionId]?.count ?? 0

    // Normalisierte Faktoren (0.0–1.0)
    let normVolume = maxVolume > 0 ? volume / maxVolume : 0
    let normSets = Double(maxSets) > 0 ? Double(sets) / Double(maxSets) : 0
    let normFrequency = Double(maxFrequency) > 0 ? Double(frequency) / Double(maxFrequency) : 0

    // Composite Score
    let compositeScore = (normVolume * weightVolume)
                       + (normSets * weightSets)
                       + (normFrequency * weightFrequency)

    let contributing = Array(musclesByRegion[regionId] ?? [])

    regionData[regionId] = MuscleHeatData(
        id: regionId,
        svgRegionId: regionId,
        displayName: regionDisplayName(for: regionId),
        totalVolume: volume,
        totalSets: sets,
        totalFrequency: frequency,               // NEU
        relativeIntensity: compositeScore,        // Jetzt Composite statt nur Volumen
        heatLevel: HeatLevel(relativeValue: compositeScore),
        lastTrainedDate: lastTrainedByRegion[regionId],
        contributingMuscles: contributing
    )
}
```

---

### 2. `MuscleHeatmapTypes.swift` — Neues Property

**`MuscleHeatData` erweitern:**

```swift
struct MuscleHeatData: Identifiable {
    let id: String
    let svgRegionId: String
    let displayName: String
    let totalVolume: Double
    let totalSets: Int
    let totalFrequency: Int              // NEU — Anzahl verschiedener Sessions
    let relativeIntensity: Double
    let heatLevel: HeatLevel
    let lastTrainedDate: Date?
    let contributingMuscles: [DetailedMuscle]
    
    // ... bestehende computed properties bleiben ...
    
    /// Formatierte Frequenz-Anzeige
    var frequencyFormatted: String {     // NEU
        totalFrequency == 1 ? "1 Session" : "\(totalFrequency) Sessions"
    }
}
```

**`MuscleHeatmapAnalysis.topRegions` anpassen:**

```swift
/// Top 5 meisttrainierte Regionen — jetzt nach Composite Score (= relativeIntensity)
var topRegions: [MuscleHeatData] {
    Array(regionData.values
        .sorted { $0.relativeIntensity > $1.relativeIntensity }  // War: totalVolume
        .prefix(5))
}
```

**`MuscleHeatmapAnalysis` — neues totalFrequency Property:**

```swift
struct MuscleHeatmapAnalysis {
    let timeframe: SummaryTimeframe
    let analysisDate: Date
    let regionData: [String: MuscleHeatData]
    let totalVolume: Double
    let totalSets: Int
    let totalFrequency: Int              // NEU — max Frequenz über alle Regionen
    // ... Rest bleibt ...
}
```

Im `analyze()`-Return ergänzen:

```swift
return MuscleHeatmapAnalysis(
    timeframe: timeframe,
    analysisDate: Date(),
    regionData: regionData,
    totalVolume: volumeByRegion.values.reduce(0, +),
    totalSets: setsByRegion.values.reduce(0, +),
    totalFrequency: maxFrequency       // NEU
)
```

---

### 3. `MuscleHeatmapView.swift` — Minimale UI-Anpassung

**`topMusclesCard`: Anzeige von Composite-Wert statt nur Volumen**

Aktuelle Zeile 175:
```swift
Text(region.volumeFormatted)
```

Ersetzen durch:
```swift
Text("\(region.totalSets) Sets · \(region.frequencyFormatted)")
```

> Begründung: Da der Composite Score jetzt die Rangfolge bestimmt, ist die reine kg-Anzeige nicht mehr aussagekräftig als alleinige Metrik. Sets + Frequenz kommunizieren besser, *warum* ein Muskel hoch rankt.

**`MuscleDetailSheet`: Frequenz ergänzen (optional, nice-to-have)**

Nach Zeile 200 (`LabeledContent("Sets", ...)`) einfügen:
```swift
LabeledContent("Frequenz", value: data.frequencyFormatted)
```

---

## Nicht betroffen

| Datei | Grund |
|---|---|
| `MuscleHeatmapViewModel.swift` | Cache-Logik bleibt identisch |
| `MuscleHeatmapSVGView.swift` | Nutzt `svgStylesCSS` → bleibt via `heatLevel` |
| `MuscleHeatmapLegend.swift` | Farb-Skala ändert sich nicht |
| `MuscleHeatmapMiniView.swift` | Nutzt gleiche `analysis`-Struktur |
| `SummaryMuscleHeatmapCard.swift` | Konsumiert `MuscleHeatmapAnalysis` |

---

## Implementierungs-Schritte

### Schritt 1: `MuscleHeatmapTypes.swift` erweitern
- `totalFrequency: Int` zu `MuscleHeatData` hinzufügen
- `frequencyFormatted` Computed Property hinzufügen
- `totalFrequency: Int` zu `MuscleHeatmapAnalysis` hinzufügen
- `topRegions` Sortierung auf `relativeIntensity` ändern

**STOPP → Build + Test**

### Schritt 2: `MuscleHeatmapCalcEngine.swift` umbauen
- `frequencyByRegion: [String: Set<UUID>]` Dictionary anlegen
- Im Primär-Block: `session.sessionUUID` in `frequencyByRegion` einfügen
- Im Sekundär-Block: `session.sessionUUID` in `frequencyByRegion` einfügen
- Composite Score Berechnung einbauen (ersetzt alte `relativeIntensity`)
- `MuscleHeatData` Initialisierung um `totalFrequency` erweitern
- `MuscleHeatmapAnalysis` Return um `totalFrequency` erweitern

**STOPP → Build + Test**

### Schritt 3: `MuscleHeatmapView.swift` UI anpassen
- `topMusclesCard`: Anzeige auf Sets + Frequenz ändern
- `MuscleDetailSheet`: Frequenz-Zeile ergänzen

**STOPP → Build + Test → Visuell prüfen**

---

## Erwartetes Ergebnis

Mit deinem Trainingsmuster (Push/Pull/Lower) sollte das Ergebnis nach dem Umbau etwa so aussehen:

| Muskel | Vorher (nur Volumen) | Nachher (Composite) |
|---|---|---|
| Quadrizeps | 🔴 Sehr viel (hohes Gewicht) | 🟠 Viel (hohes Volumen, aber niedrige Frequenz) |
| Trizeps | 🟠 Viel | 🔴 Sehr viel (hohe Sets + Frequenz durch sekundäre Beteiligung) |
| Mittlere Brust | 🟠 Viel | 🔴 Sehr viel (viele Übungen, hohe Frequenz) |
| Beinbeuger | 🔴 Sehr viel | 🟠 Viel (ähnlich wie Quads — wenige Übungen) |

---

## Offene Entscheidung: Keine

Alle Design-Entscheidungen sind im Dokument getroffen. Direkt umsetzbar.
