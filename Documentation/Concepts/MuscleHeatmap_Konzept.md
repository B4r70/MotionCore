# 🔥 MotionCore: Muskelgruppen-Heatmap

Vollständiges Konzept für die visuelle Darstellung der Trainingsverteilung basierend auf der `Muscles-simplified.svg`.

---

## 1. Übersicht

### Was es macht
Eine interaktive Körper-Visualisierung, die zeigt welche Muskelgruppen du in einem bestimmten Zeitraum trainiert hast – und welche vernachlässigt werden.

### Warum es wertvoll ist
- **Auf einen Blick** sehen, ob Push/Pull balanciert ist
- **Vernachlässigte Muskeln** erkennen (z.B. hintere Schulter, unterer Rücken)
- **Motivation** durch visuelle Fortschrittskontrolle

---

## 2. Die SVG-Struktur

Die `Muscles-simplified.svg` enthält **27 separate Muskelgruppen** als `<g>`-Elemente:

### 2.1 Verfügbare Gruppen

```
OBERKÖRPER FRONT          OBERKÖRPER BACK           BEINE
─────────────────         ─────────────────         ─────────────────
upper_pecs                rear_delts                quads
middle_pecs               rhomboids                 hamstrings
lower_pecs                lats                      glutes
front_delts               lower_back                hip_adductor
side_delts                upper_traps               hip_abductor
biceps                    lower_traps               calves
triceps
forearms                  CORE
upper_abs                 ─────────────────
lower_abs                 obliques
                          neck
```

### 2.2 SVG-Aufbau

```xml
<svg viewBox="0 0 3528.37 3203.47">
  <!-- Styles -->
  <style>
    .st4{fill:#FF0000;stroke:#FF0000;...}  <!-- Muskeln -->
    .st6{fill:#FFFFFF;stroke:#000000;...}  <!-- Gesicht -->
  </style>
  
  <!-- Körperumrisse -->
  <g id="front_borders">...</g>
  <g id="rear_borders">...</g>
  
  <!-- Muskelgruppen (dynamisch einfärbbar) -->
  <g id="upper_pecs">
    <path class="st4" d="..."/>
  </g>
  <g id="quads">
    <path class="st4" d="..."/>
    <path class="st4" d="..."/>
  </g>
  <!-- ... weitere Gruppen -->
</svg>
```

### 2.3 Wichtige Erkenntnisse

1. **Alle Muskeln haben `class="st4"`** → einheitliches Styling möglich
2. **Gruppen enthalten mehrere `<path>`-Elemente** (links/rechts, Segmente)
3. **ViewBox ist groß (3528×3203)** → skaliert gut
4. **Front und Back sind nebeneinander** → kein Toggle nötig, beide sichtbar

---

## 3. Mapping: SVG → MuscleGroup Enum

### 3.1 Mapping-Tabelle

```swift
enum MuscleHeatmapRegion: String, CaseIterable {
    // Brust
    case upperPecs = "upper_pecs"
    case middlePecs = "middle_pecs"
    case lowerPecs = "lower_pecs"
    
    // Core
    case upperAbs = "upper_abs"
    case lowerAbs = "lower_abs"
    case obliques = "obliques"
    
    // Schultern
    case frontDelts = "front_delts"
    case sideDelts = "side_delts"
    case rearDelts = "rear_delts"
    
    // Arme
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    
    // Rücken
    case lats = "lats"
    case rhomboids = "rhomboids"
    case lowerBack = "lower_back"
    case upperTraps = "upper_traps"
    case lowerTraps = "lower_traps"
    
    // Beine
    case quads = "quads"
    case hamstrings = "hamstrings"
    case glutes = "glutes"
    case calves = "calves"
    case hipAdductor = "hip_adductor"
    case hipAbductor = "hip_abductor"
    
    // Sonstige
    case neck = "neck"
    
    /// SVG Element-ID
    var svgId: String { rawValue }
    
    /// Deutsche Bezeichnung
    var displayName: String {
        switch self {
        case .upperPecs: return "Obere Brust"
        case .middlePecs: return "Mittlere Brust"
        case .lowerPecs: return "Untere Brust"
        case .upperAbs: return "Obere Bauchmuskeln"
        case .lowerAbs: return "Untere Bauchmuskeln"
        case .obliques: return "Schräge Bauchmuskeln"
        case .frontDelts: return "Vordere Schulter"
        case .sideDelts: return "Seitliche Schulter"
        case .rearDelts: return "Hintere Schulter"
        case .biceps: return "Bizeps"
        case .triceps: return "Trizeps"
        case .forearms: return "Unterarme"
        case .lats: return "Latissimus"
        case .rhomboids: return "Rhomboideus"
        case .lowerBack: return "Unterer Rücken"
        case .upperTraps: return "Oberer Trapez"
        case .lowerTraps: return "Unterer Trapez"
        case .quads: return "Quadrizeps"
        case .hamstrings: return "Beinbeuger"
        case .glutes: return "Gesäß"
        case .calves: return "Waden"
        case .hipAdductor: return "Adduktoren"
        case .hipAbductor: return "Abduktoren"
        case .neck: return "Nacken"
        }
    }
}
```

### 3.2 Mapping von bestehender MuscleGroup

Deine App hat bereits ein `MuscleGroup`-Enum. Hier das Mapping:

```swift
extension MuscleGroup {
    /// Mapping zu SVG-Regionen (kann mehrere sein, z.B. "Brust" → alle 3 Pec-Regionen)
    var heatmapRegions: [MuscleHeatmapRegion] {
        switch self {
        case .chest:
            return [.upperPecs, .middlePecs, .lowerPecs]
        case .back:
            return [.lats, .rhomboids, .lowerBack, .upperTraps, .lowerTraps]
        case .shoulders:
            return [.frontDelts, .sideDelts, .rearDelts]
        case .biceps:
            return [.biceps]
        case .triceps:
            return [.triceps]
        case .forearms:
            return [.forearms]
        case .abs, .core:
            return [.upperAbs, .lowerAbs, .obliques]
        case .quadriceps:
            return [.quads]
        case .hamstrings:
            return [.hamstrings]
        case .glutes:
            return [.glutes]
        case .calves:
            return [.calves]
        case .adductors:
            return [.hipAdductor]
        case .abductors:
            return [.hipAbductor]
        case .traps:
            return [.upperTraps, .lowerTraps]
        case .lats:
            return [.lats]
        case .lowerBack:
            return [.lowerBack]
        case .neck:
            return [.neck]
        default:
            return []
        }
    }
}
```

---

## 4. Architektur

### 4.1 Komponenten-Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│                     MuscleHeatmapView                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  TimeframePicker (Woche/Monat/Quartal/Jahr)           │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                                                       │  │
│  │              MuscleHeatmapSVGView                     │  │
│  │         (WKWebView mit dynamischem SVG)               │  │
│  │                                                       │  │
│  │    ┌─────────┐              ┌─────────┐              │  │
│  │    │  FRONT  │              │  BACK   │              │  │
│  │    │         │              │         │              │  │
│  │    │ 🔴 Brust │              │ 🟡 Lats │              │  │
│  │    │ 🟡 Bizeps│              │ 🔵 Trap │              │  │
│  │    │ 🔵 Quads │              │ ⚪ Glut │              │  │
│  │    │         │              │         │              │  │
│  │    └─────────┘              └─────────┘              │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Legende + Vernachlässigte Muskeln                    │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Detail-Sheet (bei Tap auf Muskel)                    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  MuscleHeatmapCalcEngine                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Input: [StrengthSession], SummaryTimeframe           │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  1. Sessions filtern nach Zeitraum                    │  │
│  │  2. Sets aggregieren nach Muskelgruppe                │  │
│  │  3. Volumen berechnen (Gewicht × Reps)                │  │
│  │  4. Relative Intensität normalisieren                 │  │
│  │  5. HeatLevel zuweisen                                │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  Output: [MuscleHeatmapRegion: MuscleHeatData]        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Dateien

```
MotionCore/
├── CalcEngines/
│   └── MuscleHeatmapCalcEngine.swift      # Volumen-Berechnung
├── Types/
│   └── MuscleHeatmapTypes.swift           # Enums, Structs
├── Views/
│   └── Stats/
│       ├── MuscleHeatmapView.swift        # Haupt-View
│       ├── MuscleHeatmapSVGView.swift     # WebView mit SVG
│       └── MuscleHeatmapLegend.swift      # Legende + Warnungen
└── Resources/
    └── Muscles-simplified.svg              # Die SVG-Datei
```

---

## 5. Datenmodell

### 5.1 Types

```swift
// MuscleHeatmapTypes.swift

import SwiftUI

// MARK: - Heat Level

enum HeatLevel: Int, CaseIterable, Comparable {
    case none = 0        // Nicht trainiert
    case veryLow = 1     // < 10% vom Maximum
    case low = 2         // 10-25%
    case medium = 3      // 25-50%
    case high = 4        // 50-75%
    case veryHigh = 5    // > 75%
    
    static func < (lhs: HeatLevel, rhs: HeatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// Farbe für die Heatmap (Blau → Rot Gradient)
    var color: Color {
        switch self {
        case .none:     return Color.gray.opacity(0.3)
        case .veryLow:  return Color(hex: "#3B82F6")  // Blau
        case .low:      return Color(hex: "#22D3EE")  // Cyan
        case .medium:   return Color(hex: "#22C55E")  // Grün
        case .high:     return Color(hex: "#F59E0B")  // Orange
        case .veryHigh: return Color(hex: "#EF4444")  // Rot
        }
    }
    
    /// Hex-Farbe für SVG-Injection
    var hexColor: String {
        switch self {
        case .none:     return "#9CA3AF"  // Grau
        case .veryLow:  return "#3B82F6"  // Blau
        case .low:      return "#22D3EE"  // Cyan
        case .medium:   return "#22C55E"  // Grün
        case .high:     return "#F59E0B"  // Orange
        case .veryHigh: return "#EF4444"  // Rot
        }
    }
    
    var displayName: String {
        switch self {
        case .none:     return "Nicht trainiert"
        case .veryLow:  return "Sehr wenig"
        case .low:      return "Wenig"
        case .medium:   return "Moderat"
        case .high:     return "Viel"
        case .veryHigh: return "Sehr viel"
        }
    }
    
    /// Erstellt HeatLevel aus relativem Wert (0.0 - 1.0)
    init(relativeValue: Double) {
        switch relativeValue {
        case ..<0.01:   self = .none
        case ..<0.10:   self = .veryLow
        case ..<0.25:   self = .low
        case ..<0.50:   self = .medium
        case ..<0.75:   self = .high
        default:        self = .veryHigh
        }
    }
}

// MARK: - Muscle Heat Data

struct MuscleHeatData: Identifiable {
    let id = UUID()
    let region: MuscleHeatmapRegion
    let totalVolume: Double           // kg × reps
    let totalSets: Int
    let relativeIntensity: Double     // 0.0 - 1.0 (relativ zum Maximum)
    let heatLevel: HeatLevel
    let lastTrainedDate: Date?
    
    var isNeglected: Bool {
        heatLevel <= .veryLow
    }
    
    var daysSinceLastTrained: Int? {
        guard let date = lastTrainedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
    
    var volumeFormatted: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk kg", totalVolume / 1000)
        }
        return String(format: "%.0f kg", totalVolume)
    }
}

// MARK: - Heatmap Analysis Result

struct MuscleHeatmapAnalysis {
    let timeframe: SummaryTimeframe
    let analysisDate: Date
    let regionData: [MuscleHeatmapRegion: MuscleHeatData]
    
    // Aggregierte Statistiken
    let totalVolume: Double
    let totalSets: Int
    let mostTrainedRegion: MuscleHeatmapRegion?
    let leastTrainedRegion: MuscleHeatmapRegion?
    
    /// Alle vernachlässigten Regionen
    var neglectedRegions: [MuscleHeatData] {
        regionData.values
            .filter { $0.isNeglected }
            .sorted { $0.totalVolume < $1.totalVolume }
    }
    
    /// Top 5 meisttrainierte
    var topRegions: [MuscleHeatData] {
        Array(regionData.values
            .sorted { $0.totalVolume > $1.totalVolume }
            .prefix(5))
    }
    
    /// Gibt HeatData für eine Region zurück
    func data(for region: MuscleHeatmapRegion) -> MuscleHeatData {
        regionData[region] ?? MuscleHeatData(
            region: region,
            totalVolume: 0,
            totalSets: 0,
            relativeIntensity: 0,
            heatLevel: .none,
            lastTrainedDate: nil
        )
    }
    
    /// Generiert CSS-Styles für alle Regionen
    var svgStylesCSS: String {
        regionData.map { region, data in
            "#\(region.svgId) path { fill: \(data.heatLevel.hexColor) !important; }"
        }.joined(separator: "\n")
    }
}
```

---

## 6. CalcEngine

```swift
// MuscleHeatmapCalcEngine.swift

import Foundation

struct MuscleHeatmapCalcEngine {
    
    // MARK: - Haupt-Analyse
    
    func analyze(
        sessions: [StrengthSession],
        timeframe: SummaryTimeframe
    ) -> MuscleHeatmapAnalysis {
        
        // 1. Sessions im Zeitraum filtern
        let filteredSessions = filterSessions(sessions, for: timeframe)
        
        // 2. Volumen pro Region aggregieren
        var volumeByRegion: [MuscleHeatmapRegion: Double] = [:]
        var setsByRegion: [MuscleHeatmapRegion: Int] = [:]
        var lastTrainedByRegion: [MuscleHeatmapRegion: Date] = [:]
        
        for session in filteredSessions {
            for set in session.safeExerciseSets where set.isCompleted {
                let volume = set.weight * Double(set.reps)
                
                // Primäre Muskeln → volle Gewichtung
                let primaryRegions = set.primaryMuscles.flatMap { $0.heatmapRegions }
                for region in primaryRegions {
                    volumeByRegion[region, default: 0] += volume
                    setsByRegion[region, default: 0] += 1
                    
                    if let existing = lastTrainedByRegion[region] {
                        if session.date > existing {
                            lastTrainedByRegion[region] = session.date
                        }
                    } else {
                        lastTrainedByRegion[region] = session.date
                    }
                }
                
                // Sekundäre Muskeln → halbe Gewichtung
                let secondaryRegions = set.secondaryMuscles.flatMap { $0.heatmapRegions }
                for region in secondaryRegions {
                    volumeByRegion[region, default: 0] += volume * 0.5
                    // Sets nicht zählen für sekundäre
                    
                    if let existing = lastTrainedByRegion[region] {
                        if session.date > existing {
                            lastTrainedByRegion[region] = session.date
                        }
                    } else {
                        lastTrainedByRegion[region] = session.date
                    }
                }
            }
        }
        
        // 3. Relative Intensität berechnen
        let maxVolume = volumeByRegion.values.max() ?? 1.0
        
        var regionData: [MuscleHeatmapRegion: MuscleHeatData] = [:]
        
        for region in MuscleHeatmapRegion.allCases {
            let volume = volumeByRegion[region] ?? 0
            let sets = setsByRegion[region] ?? 0
            let relativeIntensity = maxVolume > 0 ? volume / maxVolume : 0
            
            regionData[region] = MuscleHeatData(
                region: region,
                totalVolume: volume,
                totalSets: sets,
                relativeIntensity: relativeIntensity,
                heatLevel: HeatLevel(relativeValue: relativeIntensity),
                lastTrainedDate: lastTrainedByRegion[region]
            )
        }
        
        // 4. Aggregierte Stats
        let totalVolume = volumeByRegion.values.reduce(0, +)
        let totalSets = setsByRegion.values.reduce(0, +)
        
        let mostTrained = regionData.max { $0.value.totalVolume < $1.value.totalVolume }?.key
        let leastTrained = regionData
            .filter { $0.value.totalVolume > 0 }
            .min { $0.value.totalVolume < $1.value.totalVolume }?.key
        
        return MuscleHeatmapAnalysis(
            timeframe: timeframe,
            analysisDate: Date(),
            regionData: regionData,
            totalVolume: totalVolume,
            totalSets: totalSets,
            mostTrainedRegion: mostTrained,
            leastTrainedRegion: leastTrained
        )
    }
    
    // MARK: - Hilfsmethoden
    
    private func filterSessions(
        _ sessions: [StrengthSession],
        for timeframe: SummaryTimeframe
    ) -> [StrengthSession] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .allTime:
            return sessions
        }
        
        return sessions.filter { $0.date >= startDate }
    }
}
```

---

## 7. SVG-Integration

### 7.1 Ansatz: WKWebView mit dynamischem CSS

Da SwiftUI keine native SVG-Manipulation unterstützt, nutzen wir `WKWebView` mit JavaScript für dynamische Einfärbung.

```swift
// MuscleHeatmapSVGView.swift

import SwiftUI
import WebKit

struct MuscleHeatmapSVGView: UIViewRepresentable {
    let analysis: MuscleHeatmapAnalysis
    var onRegionTap: ((MuscleHeatmapRegion) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "regionTapped")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRegionTap: onRegionTap)
    }
    
    // MARK: - HTML Generation
    
    private func generateHTML() -> String {
        // SVG aus Bundle laden
        guard let svgURL = Bundle.main.url(forResource: "Muscles-simplified", withExtension: "svg"),
              let svgContent = try? String(contentsOf: svgURL) else {
            return "<html><body>SVG nicht gefunden</body></html>"
        }
        
        // Dynamische Styles generieren
        let dynamicStyles = analysis.svgStylesCSS
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { 
                    width: 100%; 
                    height: 100%; 
                    background: transparent;
                    overflow: hidden;
                }
                svg { 
                    width: 100%; 
                    height: 100%; 
                    display: block;
                }
                
                /* Basis-Styles überschreiben */
                #front_borders path,
                #rear_borders path {
                    fill: none !important;
                    stroke: #374151 !important;
                    stroke-width: 3 !important;
                }
                
                #face path {
                    fill: #F3F4F6 !important;
                    stroke: #374151 !important;
                }
                
                /* Dynamische Muskel-Farben */
                \(dynamicStyles)
                
                /* Hover-Effekt für Interaktion */
                g[id]:not(#front_borders):not(#rear_borders):not(#face):not(#front):not(#rear) path {
                    cursor: pointer;
                    transition: opacity 0.2s ease;
                }
                g[id]:not(#front_borders):not(#rear_borders):not(#face):not(#front):not(#rear):hover path {
                    opacity: 0.8;
                }
            </style>
        </head>
        <body>
            \(svgContent)
            <script>
                // Click-Handler für Muskelgruppen
                document.querySelectorAll('g[id]').forEach(group => {
                    const id = group.id;
                    // Nur echte Muskelgruppen, keine Borders/Face
                    const excluded = ['front_borders', 'rear_borders', 'face', 'front', 'rear'];
                    if (!excluded.includes(id)) {
                        group.addEventListener('click', () => {
                            window.webkit.messageHandlers.regionTapped.postMessage(id);
                        });
                    }
                });
            </script>
        </body>
        </html>
        """
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var onRegionTap: ((MuscleHeatmapRegion) -> Void)?
        
        init(onRegionTap: ((MuscleHeatmapRegion) -> Void)?) {
            self.onRegionTap = onRegionTap
        }
        
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let regionId = message.body as? String,
                  let region = MuscleHeatmapRegion(rawValue: regionId) else { return }
            
            DispatchQueue.main.async {
                self.onRegionTap?(region)
            }
        }
    }
}
```

### 7.2 Alternative: Native SwiftUI mit SVGKit

Falls du lieber keine WebView nutzen möchtest, gibt es SVGKit als Package:

```swift
// Package.swift oder Xcode SPM
.package(url: "https://github.com/SVGKit/SVGKit.git", from: "3.0.0")
```

```swift
import SVGKit

struct NativeMuscleHeatmapView: View {
    let analysis: MuscleHeatmapAnalysis
    
    var body: some View {
        if let svgImage = loadAndColorSVG() {
            Image(uiImage: svgImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
    
    private func loadAndColorSVG() -> UIImage? {
        guard let svgURL = Bundle.main.url(forResource: "Muscles-simplified", withExtension: "svg"),
              let svg = SVGKImage(contentsOf: svgURL) else { return nil }
        
        // Gruppen durchgehen und Farben setzen
        for region in MuscleHeatmapRegion.allCases {
            if let layer = svg.layer(withIdentifier: region.svgId) {
                let data = analysis.data(for: region)
                layer.fillColor = UIColor(hex: data.heatLevel.hexColor)?.cgColor
            }
        }
        
        return svg.uiImage
    }
}
```

**Empfehlung:** WKWebView ist einfacher und braucht keine externe Dependency.

---

## 8. Views

### 8.1 Haupt-View

```swift
// MuscleHeatmapView.swift

import SwiftUI
import SwiftData

struct MuscleHeatmapView: View {
    @Query private var sessions: [StrengthSession]
    @State private var timeframe: SummaryTimeframe = .month
    @State private var selectedRegion: MuscleHeatmapRegion?
    @State private var showingDetail = false
    
    private var analysis: MuscleHeatmapAnalysis {
        MuscleHeatmapCalcEngine().analyze(sessions: sessions, timeframe: timeframe)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Zeitraum-Picker
                TimeframePicker(selection: $timeframe)
                    .padding(.horizontal)
                
                // SVG Heatmap
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                            Text("Muskelaktivität")
                                .font(.headline)
                            Spacer()
                            Text(analysis.totalSets.formatted() + " Sets")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        MuscleHeatmapSVGView(analysis: analysis) { region in
                            selectedRegion = region
                            showingDetail = true
                        }
                        .frame(height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }
                
                // Legende
                MuscleHeatmapLegend()
                
                // Vernachlässigte Muskeln
                if !analysis.neglectedRegions.isEmpty {
                    NeglectedMusclesCard(regions: analysis.neglectedRegions)
                }
                
                // Top trainierte Muskeln
                TopMusclesCard(regions: analysis.topRegions)
            }
            .padding()
        }
        .navigationTitle("Muskel-Heatmap")
        .sheet(isPresented: $showingDetail) {
            if let region = selectedRegion {
                MuscleDetailSheet(
                    data: analysis.data(for: region),
                    sessions: sessions
                )
            }
        }
    }
}
```

### 8.2 Legende

```swift
// MuscleHeatmapLegend.swift

struct MuscleHeatmapLegend: View {
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Legende")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(HeatLevel.allCases, id: \.self) { level in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(level.color)
                                .frame(height: 20)
                            
                            Text(level.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
```

### 8.3 Vernachlässigte Muskeln Card

```swift
struct NeglectedMusclesCard: View {
    let regions: [MuscleHeatData]
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Vernachlässigte Muskeln")
                        .font(.headline)
                }
                
                ForEach(regions.prefix(5)) { data in
                    HStack {
                        Circle()
                            .fill(data.heatLevel.color)
                            .frame(width: 12, height: 12)
                        
                        Text(data.region.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if let days = data.daysSinceLastTrained {
                            Text("vor \(days) Tagen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("nie trainiert")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
```

### 8.4 Detail-Sheet

```swift
struct MuscleDetailSheet: View {
    let data: MuscleHeatData
    let sessions: [StrengthSession]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Circle()
                            .fill(data.heatLevel.color)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        
                        Text(data.region.displayName)
                            .font(.title2.bold())
                        
                        Text(data.heatLevel.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    
                    // Stats
                    GlassCard {
                        VStack(spacing: 16) {
                            StatRow(label: "Volumen", value: data.volumeFormatted)
                            StatRow(label: "Sets", value: data.totalSets.formatted())
                            StatRow(label: "Relative Intensität", 
                                   value: String(format: "%.0f%%", data.relativeIntensity * 100))
                            
                            if let days = data.daysSinceLastTrained {
                                StatRow(label: "Zuletzt trainiert", value: "vor \(days) Tagen")
                            }
                        }
                        .padding()
                    }
                    
                    // Übungen die diesen Muskel trainieren
                    // TODO: Liste relevanter Übungen
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
```

---

## 9. Integration in die App

### 9.1 Navigation

```swift
// In StatsAndRecordsView.swift oder SummaryView.swift

NavigationLink {
    MuscleHeatmapView()
} label: {
    HStack {
        Image(systemName: "figure.strengthtraining.traditional")
            .foregroundStyle(.blue)
        Text("Muskel-Heatmap")
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundStyle(.secondary)
    }
    .padding()
}
```

### 9.2 Dashboard-Preview Card

```swift
struct MuscleHeatmapPreviewCard: View {
    let analysis: MuscleHeatmapAnalysis
    
    var body: some View {
        NavigationLink {
            MuscleHeatmapView()
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                        Text("Muskelaktivität")
                            .font(.headline)
                        Spacer()
                        Text("Diese Woche")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Mini-Balkendiagramm der Top 5
                    ForEach(analysis.topRegions.prefix(3)) { data in
                        HStack {
                            Text(data.region.displayName)
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(data.heatLevel.color)
                                    .frame(width: geo.size.width * data.relativeIntensity)
                            }
                            .frame(height: 12)
                        }
                    }
                    
                    if !analysis.neglectedRegions.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("\(analysis.neglectedRegions.count) vernachlässigt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
}
```

---

## 10. Implementierungs-Checklist

### Phase 1: Foundation (Tag 1)
- [ ] `MuscleHeatmapTypes.swift` erstellen
- [ ] `MuscleHeatmapRegion` Enum mit allen 24 Regionen
- [ ] `HeatLevel` Enum mit Farben
- [ ] Mapping `MuscleGroup` → `[MuscleHeatmapRegion]`

### Phase 2: CalcEngine (Tag 1-2)
- [ ] `MuscleHeatmapCalcEngine.swift`
- [ ] Volumen-Aggregation
- [ ] Relative Intensität
- [ ] Zeitraum-Filterung

### Phase 3: SVG-Integration (Tag 2-3)
- [ ] `Muscles-simplified.svg` in Bundle aufnehmen
- [ ] `MuscleHeatmapSVGView.swift` (WKWebView)
- [ ] Dynamische CSS-Generierung
- [ ] Click-Handler für Regionen

### Phase 4: Views (Tag 3-4)
- [ ] `MuscleHeatmapView.swift` (Haupt-View)
- [ ] `MuscleHeatmapLegend.swift`
- [ ] `NeglectedMusclesCard`
- [ ] `MuscleDetailSheet`
- [ ] `MuscleHeatmapPreviewCard` (für Dashboard)

### Phase 5: Polish (Tag 4)
- [ ] Glassmorphism-Styling
- [ ] Animationen
- [ ] Dark Mode testen
- [ ] Performance bei vielen Sessions

---

## 11. Bonus: Farbschemata

### 11.1 Standard (Blau → Rot)

```swift
case .none:     return "#9CA3AF"  // Grau
case .veryLow:  return "#3B82F6"  // Blau
case .low:      return "#22D3EE"  // Cyan
case .medium:   return "#22C55E"  // Grün
case .high:     return "#F59E0B"  // Orange
case .veryHigh: return "#EF4444"  // Rot
```

### 11.2 Alternative: Liquid Glass Theme

```swift
case .none:     return "#F0F7FF"  // Hellblau (dein Gradient-Start)
case .veryLow:  return "#C9E6FF"  // 
case .low:      return "#9BD2FF"  // (dein Gradient-Ende)
case .medium:   return "#60A5FA"  // 
case .high:     return "#3B82F6"  // 
case .veryHigh: return "#1D4ED8"  // Dunkelblau
```

### 11.3 Monochrom (für minimalistisches Design)

```swift
case .none:     return "#E5E7EB"
case .veryLow:  return "#9CA3AF"
case .low:      return "#6B7280"
case .medium:   return "#4B5563"
case .high:     return "#374151"
case .veryHigh: return "#1F2937"
```

---

*Dokument erstellt: März 2026*
*Für: MotionCore iOS App*
*SVG: Muscles-simplified.svg (27 Muskelgruppen)*
