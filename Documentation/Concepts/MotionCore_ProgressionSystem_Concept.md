# 🎯 MotionCore: Intelligentes Progressionssystem

## Übersicht

Ein mehrstufiges System, das dir mitteilt, wann du bereit bist, Gewichte zu steigern – basierend auf deinen tatsächlichen Trainingsleistungen.

---

## 1. Kernprinzipien

### 1.1 Double Progression

Da du mit Rep-Ranges (z.B. 8-12) trainierst, ist Double Progression der optimale Ansatz:

```
Phase 1: Reps steigern (bei gleichem Gewicht)
──────────────────────────────────────────────
Woche 1: 80kg × 8, 8, 8    ← Start am unteren Rep-Limit
Woche 2: 80kg × 9, 9, 8    
Woche 3: 80kg × 10, 10, 10
Woche 4: 80kg × 11, 11, 11
Woche 5: 80kg × 12, 12, 12 ← Oberes Rep-Limit erreicht!

Phase 2: Gewicht steigern (Reps zurücksetzen)
──────────────────────────────────────────────
Woche 6: 82.5kg × 8, 8, 8  ← Neuer Zyklus beginnt
```

**Trigger für Gewichtssteigerung:**
- Alle Arbeitssätze erreichen das obere Rep-Limit (z.B. 12)
- RIR ist über dem Zielwert (= noch Reserve vorhanden)
- Konsistent über N Sessions (konfigurierbar, Default: 2)

### 1.2 Konfidenz-System

Nicht jede Empfehlung ist gleich sicher. Das System berechnet eine Konfidenz:

| Level | Konfidenz | Bedeutung | UI-Darstellung |
|-------|-----------|-----------|----------------|
| 🔴 Niedrig | 0.3 - 0.5 | Könnte bereit sein | Dezenter Hinweis |
| 🟡 Mittel | 0.5 - 0.75 | Wahrscheinlich bereit | Empfehlung |
| 🟢 Hoch | 0.75 - 1.0 | Definitiv bereit | Starke Empfehlung |

**Faktoren für Konfidenz-Berechnung:**
- Anzahl konsistenter Sessions (mehr = höher)
- Abstand zum Ziel-RIR (größer = höher)
- Trend der letzten Wochen (steigend = höher)
- Varianz in den Daten (niedriger = höher)

### 1.3 Auto-Detect: Anfänger vs. Fortgeschritten

Das System erkennt automatisch deinen Trainingsstand pro Übung:

| Status | Erkennung | Progressions-Empfehlung |
|--------|-----------|-------------------------|
| **Anfänger** | < 10 Sessions mit Übung | Aggressiver (+5kg bei Compounds) |
| **Intermediate** | 10-50 Sessions | Standard (+2.5kg) |
| **Fortgeschritten** | > 50 Sessions, Plateaus | Micro (+1.25kg), Double Progression |
| **Nach Pause** | > 3 Wochen ohne Übung | Vorsichtiger Wiedereinstieg |

### 1.4 Trend-Analyse

Analysiert deine Performance über die letzten 4-8 Wochen:

```
Trend-Typen:
────────────
↗️ Aufsteigend   : Reps/Gewicht steigen → Progression empfohlen
→  Stabil        : Keine Veränderung → Weiter beobachten
↘️ Absteigend    : Performance sinkt → Deload/Pause prüfen
〰️ Volatil       : Stark schwankend → Mehr Daten sammeln
```

---

## 2. Datenmodell-Erweiterungen

### 2.1 Exercise.swift (Erweiterungen)

```swift
// MARK: - Progressions-Konfiguration

/// Wie viele erfolgreiche Sessions bis zur Empfehlung? (Default: 2)
var progressionSessionsRequired: Int = 2

/// Ziel-RIR — darunter gilt als "zu schwer"
var targetRIR: Int = 2

/// Progressions-Strategie (Raw-Value für SwiftData)
var progressionStrategyRaw: String = "double"

/// Progressions-Schrittweite überschreiben? (nil = Auto basierend auf Übungstyp)
var customProgressionStep: Double? = nil

/// Minimale Tage zwischen Gewichtssteigerungen (verhindert zu schnelle Progression)
var minDaysBetweenProgressions: Int = 7

/// Datum der letzten Gewichtssteigerung (für Cooldown)
var lastProgressionDate: Date? = nil

// MARK: - Computed Properties

var progressionStrategy: ProgressionStrategy {
    get { ProgressionStrategy(rawValue: progressionStrategyRaw) ?? .double }
    set { progressionStrategyRaw = newValue.rawValue }
}

/// Automatisch berechneter Progressionsschritt basierend auf Übungstyp
var effectiveProgressionStep: Double {
    if let custom = customProgressionStep { return custom }
    
    switch category {
    case .compound:
        return equipment == .barbell ? 2.5 : 2.0
    case .isolation:
        return 1.25
    case .bodyweight:
        return 0 // Reps-basierte Progression
    default:
        return 2.5
    }
}

/// Kann gerade eine Progression empfohlen werden? (Cooldown-Check)
var canRecommendProgression: Bool {
    guard let lastDate = lastProgressionDate else { return true }
    let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    return daysSince >= minDaysBetweenProgressions
}
```

### 2.2 ProgressionTypes.swift (Neu)

```swift
import Foundation

// MARK: - Progressions-Strategie

enum ProgressionStrategy: String, CaseIterable, Codable {
    case micro = "micro"           // +1.25kg, sehr konservativ
    case standard = "standard"     // +2.5kg nach N Sessions
    case aggressive = "aggressive" // +5kg, für Anfänger
    case double = "double"         // Double Progression (erst Reps, dann Gewicht)
    case manual = "manual"         // Keine automatischen Empfehlungen
    
    var displayName: String {
        switch self {
        case .micro: return "Mikro-Progression"
        case .standard: return "Standard"
        case .aggressive: return "Aggressiv"
        case .double: return "Double Progression"
        case .manual: return "Manuell"
        }
    }
    
    var description: String {
        switch self {
        case .micro: 
            return "Kleine Schritte (+1.25kg). Ideal für Isolation und Plateaus."
        case .standard: 
            return "Klassische lineare Progression (+2.5kg)."
        case .aggressive: 
            return "Schnelle Steigerung (+5kg). Für Anfänger oder nach Pausen."
        case .double: 
            return "Erst Reps steigern, dann Gewicht. Optimal für Rep-Ranges."
        case .manual: 
            return "Keine automatischen Empfehlungen."
        }
    }
    
    var icon: String {
        switch self {
        case .micro: return "tortoise.fill"
        case .standard: return "arrow.up.right"
        case .aggressive: return "hare.fill"
        case .double: return "arrow.up.arrow.down"
        case .manual: return "hand.raised.fill"
        }
    }
}

// MARK: - Konfidenz-Level

enum ProgressionConfidence: String, CaseIterable {
    case insufficient = "insufficient"  // < 0.3: Nicht genug Daten
    case low = "low"                     // 0.3 - 0.5: Könnte bereit sein
    case medium = "medium"               // 0.5 - 0.75: Wahrscheinlich bereit
    case high = "high"                   // > 0.75: Definitiv bereit
    
    var displayName: String {
        switch self {
        case .insufficient: return "Unzureichend"
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }
    
    var color: String {
        switch self {
        case .insufficient: return "gray"
        case .low: return "orange"
        case .medium: return "yellow"
        case .high: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .insufficient: return "questionmark.circle"
        case .low: return "circle.bottomhalf.filled"
        case .medium: return "circle.inset.filled"
        case .high: return "checkmark.circle.fill"
        }
    }
    
    init(value: Double) {
        switch value {
        case ..<0.3: self = .insufficient
        case 0.3..<0.5: self = .low
        case 0.5..<0.75: self = .medium
        default: self = .high
        }
    }
}

// MARK: - Trainings-Level (Auto-Detect)

enum TrainingLevel: String, CaseIterable {
    case beginner = "beginner"           // < 10 Sessions
    case intermediate = "intermediate"   // 10-50 Sessions
    case advanced = "advanced"           // > 50 Sessions
    case returning = "returning"         // Nach längerer Pause
    
    var displayName: String {
        switch self {
        case .beginner: return "Anfänger"
        case .intermediate: return "Fortgeschritten"
        case .advanced: return "Erfahren"
        case .returning: return "Wiedereinsteiger"
        }
    }
    
    var suggestedStrategy: ProgressionStrategy {
        switch self {
        case .beginner: return .aggressive
        case .intermediate: return .standard
        case .advanced: return .double
        case .returning: return .standard
        }
    }
    
    var suggestedSessionsRequired: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .returning: return 2
        }
    }
}

// MARK: - Trend-Richtung

enum PerformanceTrend: String {
    case improving = "improving"     // ↗️ Aufwärtstrend
    case stable = "stable"           // →  Stabil
    case declining = "declining"     // ↘️ Abwärtstrend
    case volatile = "volatile"       // 〰️ Stark schwankend
    case insufficient = "insufficient" // Nicht genug Daten
    
    var displayName: String {
        switch self {
        case .improving: return "Aufwärtstrend"
        case .stable: return "Stabil"
        case .declining: return "Abwärtstrend"
        case .volatile: return "Schwankend"
        case .insufficient: return "Zu wenig Daten"
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        case .volatile: return "waveform.path"
        case .insufficient: return "questionmark"
        }
    }
    
    var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .declining: return "orange"
        case .volatile: return "yellow"
        case .insufficient: return "gray"
        }
    }
}

// MARK: - Empfohlene Aktion

enum ProgressionAction: Equatable {
    case maintain                        // Weiter so, noch nicht bereit
    case increaseReps                    // Reps steigern (Double Progression Phase 1)
    case increaseWeight(kg: Double)      // Gewicht steigern
    case considerDeload                  // Leistung sinkt, Deload prüfen
    case needMoreData                    // Zu wenig Daten für Empfehlung
    
    var displayName: String {
        switch self {
        case .maintain: 
            return "Gewicht halten"
        case .increaseReps: 
            return "Reps steigern"
        case .increaseWeight(let kg): 
            return "Gewicht erhöhen (+\(kg.formatted())kg)"
        case .considerDeload: 
            return "Deload erwägen"
        case .needMoreData: 
            return "Mehr Daten sammeln"
        }
    }
    
    var icon: String {
        switch self {
        case .maintain: return "equal.circle"
        case .increaseReps: return "repeat"
        case .increaseWeight: return "arrow.up.circle.fill"
        case .considerDeload: return "bed.double.fill"
        case .needMoreData: return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - Haupt-Analyse-Ergebnis

struct ProgressionAnalysis {
    // Identifikation
    let exerciseName: String
    let exerciseUUID: UUID?
    let analysisDate: Date
    
    // Aktueller Stand
    let currentWeight: Double
    let currentRepsRange: ClosedRange<Int>  // z.B. 8...10 (Min-Max der letzten Session)
    let targetRepsRange: ClosedRange<Int>   // z.B. 8...12 (Ziel-Range)
    
    // Analyse-Ergebnisse
    let trainingLevel: TrainingLevel
    let trend: PerformanceTrend
    let confidence: Double              // 0.0 - 1.0
    let confidenceLevel: ProgressionConfidence
    
    // Empfehlung
    let recommendedAction: ProgressionAction
    let suggestedWeight: Double?        // Nur bei .increaseWeight
    
    // Begründung (für UI)
    let reasoningPoints: [String]
    
    // Statistiken
    let sessionsAnalyzed: Int
    let daysSinceLastSession: Int
    let estimatedOneRepMax: Double?
    let oneRepMaxTrend: PerformanceTrend?
    
    // Double Progression spezifisch
    let repsProgress: Double?           // 0.0 - 1.0 (wie weit im Rep-Range?)
    let isReadyForWeightIncrease: Bool
    
    // Computed
    var hasRecommendation: Bool {
        switch recommendedAction {
        case .increaseReps, .increaseWeight:
            return true
        default:
            return false
        }
    }
    
    var summaryText: String {
        switch recommendedAction {
        case .maintain:
            return "Weiter mit \(currentWeight.formatted())kg trainieren"
        case .increaseReps:
            return "Versuche mehr Reps bei \(currentWeight.formatted())kg"
        case .increaseWeight(let kg):
            return "Bereit für \((currentWeight + kg).formatted())kg"
        case .considerDeload:
            return "Erholungswoche empfohlen"
        case .needMoreData:
            return "Noch \(max(0, 3 - sessionsAnalyzed)) Sessions für Analyse"
        }
    }
}

// MARK: - Session-Snapshot (für Analyse)

/// Vereinfachte Darstellung einer Session für die Progressions-Analyse
struct SessionSnapshot {
    let date: Date
    let weight: Double
    let reps: [Int]           // Reps pro Arbeitssatz
    let rpeValues: [Int]      // RPE pro Arbeitssatz (0 = nicht erfasst)
    let totalVolume: Double   // Gewicht × Reps summiert
    let estimatedOneRM: Double?
    
    var averageReps: Double {
        guard !reps.isEmpty else { return 0 }
        return Double(reps.reduce(0, +)) / Double(reps.count)
    }
    
    var minReps: Int { reps.min() ?? 0 }
    var maxReps: Int { reps.max() ?? 0 }
    
    var averageRIR: Double? {
        let validRPE = rpeValues.filter { $0 > 0 }
        guard !validRPE.isEmpty else { return nil }
        let avgRPE = Double(validRPE.reduce(0, +)) / Double(validRPE.count)
        return 10.0 - avgRPE
    }
}
```

---

## 3. ProgressionCalcEngine (Erweitert)

### 3.1 Haupt-Analyse-Methode

```swift
struct ProgressionCalcEngine {
    
    // MARK: - Haupt-Analyse
    
    /// Analysiert eine Übung und gibt eine Progressions-Empfehlung zurück
    func analyze(
        exercise: Exercise,
        sessions: [StrengthSession]
    ) -> ProgressionAnalysis {
        
        // 1. Sessions für diese Übung extrahieren
        let snapshots = extractSnapshots(for: exercise, from: sessions)
        
        // 2. Trainings-Level bestimmen
        let level = detectTrainingLevel(
            sessionCount: snapshots.count,
            daysSinceLastSession: daysSince(snapshots.first?.date)
        )
        
        // 3. Trend analysieren
        let trend = analyzeTrend(snapshots: snapshots)
        
        // 4. Double Progression Status prüfen
        let dpStatus = analyzeDoubleProgression(
            snapshots: snapshots,
            targetRange: exercise.repRangeMin...exercise.repRangeMax
        )
        
        // 5. Konfidenz berechnen
        let confidence = calculateConfidence(
            snapshots: snapshots,
            trend: trend,
            exercise: exercise
        )
        
        // 6. Empfehlung ableiten
        let action = determineAction(
            exercise: exercise,
            dpStatus: dpStatus,
            trend: trend,
            confidence: confidence,
            level: level
        )
        
        // 7. Ergebnis zusammenstellen
        return ProgressionAnalysis(
            exerciseName: exercise.name,
            exerciseUUID: exercise.apiID,
            analysisDate: Date(),
            currentWeight: snapshots.first?.weight ?? 0,
            currentRepsRange: (snapshots.first?.minReps ?? 0)...(snapshots.first?.maxReps ?? 0),
            targetRepsRange: exercise.repRangeMin...exercise.repRangeMax,
            trainingLevel: level,
            trend: trend,
            confidence: confidence,
            confidenceLevel: ProgressionConfidence(value: confidence),
            recommendedAction: action,
            suggestedWeight: suggestedWeight(for: action),
            reasoningPoints: buildReasoning(/* ... */),
            sessionsAnalyzed: snapshots.count,
            daysSinceLastSession: daysSince(snapshots.first?.date),
            estimatedOneRepMax: snapshots.first?.estimatedOneRM,
            oneRepMaxTrend: analyzeOneRMTrend(snapshots: snapshots),
            repsProgress: dpStatus.progress,
            isReadyForWeightIncrease: dpStatus.readyForIncrease
        )
    }
    
    // MARK: - Double Progression Analyse
    
    private struct DoubleProgressionStatus {
        let progress: Double           // 0.0 - 1.0
        let readyForIncrease: Bool
        let consecutiveSessionsAtTop: Int
    }
    
    private func analyzeDoubleProgression(
        snapshots: [SessionSnapshot],
        targetRange: ClosedRange<Int>
    ) -> DoubleProgressionStatus {
        
        guard !snapshots.isEmpty else {
            return DoubleProgressionStatus(
                progress: 0, 
                readyForIncrease: false, 
                consecutiveSessionsAtTop: 0
            )
        }
        
        let topReps = targetRange.upperBound
        let rangeSize = Double(targetRange.upperBound - targetRange.lowerBound)
        
        // Fortschritt im Rep-Range berechnen (basierend auf Min-Reps der Session)
        let latestMinReps = snapshots.first?.minReps ?? targetRange.lowerBound
        let progress = Double(latestMinReps - targetRange.lowerBound) / rangeSize
        
        // Zähle aufeinanderfolgende Sessions am oberen Limit
        var consecutiveAtTop = 0
        for snapshot in snapshots {
            // Alle Sätze müssen am oberen Limit sein
            if snapshot.minReps >= topReps {
                consecutiveAtTop += 1
            } else {
                break
            }
        }
        
        return DoubleProgressionStatus(
            progress: min(1.0, max(0.0, progress)),
            readyForIncrease: consecutiveAtTop >= 2,  // Mind. 2 Sessions am Top
            consecutiveSessionsAtTop: consecutiveAtTop
        )
    }
    
    // MARK: - Trend-Analyse
    
    private func analyzeTrend(snapshots: [SessionSnapshot]) -> PerformanceTrend {
        guard snapshots.count >= 3 else { return .insufficient }
        
        // Nimm die letzten 8 Sessions (oder weniger)
        let relevant = Array(snapshots.prefix(8))
        
        // Berechne lineare Regression auf estimated 1RM oder Volume
        let values = relevant.compactMap { $0.estimatedOneRM ?? $0.totalVolume }
        guard values.count >= 3 else { return .insufficient }
        
        let slope = linearRegressionSlope(values.reversed()) // Älteste zuerst
        let variance = calculateVariance(values)
        
        // Hohe Varianz = volatil
        let coefficientOfVariation = sqrt(variance) / (values.reduce(0, +) / Double(values.count))
        if coefficientOfVariation > 0.15 {
            return .volatile
        }
        
        // Slope interpretieren
        let avgValue = values.reduce(0, +) / Double(values.count)
        let normalizedSlope = slope / avgValue  // Prozentuale Änderung
        
        switch normalizedSlope {
        case let s where s > 0.02: return .improving   // > 2% Steigerung
        case let s where s < -0.02: return .declining  // > 2% Rückgang
        default: return .stable
        }
    }
    
    // MARK: - Konfidenz-Berechnung
    
    private func calculateConfidence(
        snapshots: [SessionSnapshot],
        trend: PerformanceTrend,
        exercise: Exercise
    ) -> Double {
        
        var confidence = 0.0
        
        // Faktor 1: Anzahl Sessions (max 0.3)
        let sessionFactor = min(0.3, Double(snapshots.count) * 0.05)
        confidence += sessionFactor
        
        // Faktor 2: Trend (max 0.25)
        switch trend {
        case .improving: confidence += 0.25
        case .stable: confidence += 0.15
        case .volatile: confidence += 0.05
        case .declining, .insufficient: confidence += 0.0
        }
        
        // Faktor 3: Konsistenz der letzten Sessions (max 0.25)
        if let consistencyScore = calculateConsistency(snapshots: snapshots) {
            confidence += consistencyScore * 0.25
        }
        
        // Faktor 4: RIR über Ziel (max 0.2)
        if let avgRIR = snapshots.first?.averageRIR {
            let rirBuffer = avgRIR - Double(exercise.targetRIR)
            if rirBuffer > 0 {
                confidence += min(0.2, rirBuffer * 0.1)
            }
        }
        
        return min(1.0, confidence)
    }
    
    // MARK: - Hilfsmethoden
    
    private func linearRegressionSlope(_ values: [Double]) -> Double {
        let n = Double(values.count)
        guard n > 1 else { return 0 }
        
        let indices = values.indices.map { Double($0) }
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map(*).reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }
        
        return (n * sumXY - sumX * sumY) / denominator
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count - 1)
    }
}
```

---

## 4. UI-Komponenten

### 4.1 Übungsdetail-Ansicht: ProgressionInsightCard

```swift
struct ProgressionInsightCard: View {
    let analysis: ProgressionAnalysis
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progressions-Analyse")
                        .font(.headline)
                    Spacer()
                    ConfidenceBadge(level: analysis.confidenceLevel)
                }
                
                Divider()
                
                // Haupt-Empfehlung
                RecommendationRow(action: analysis.recommendedAction)
                
                // Double Progression Fortschritt
                if let progress = analysis.repsProgress {
                    ProgressBar(
                        value: progress,
                        label: "Rep-Fortschritt",
                        detail: "\(analysis.currentRepsRange.lowerBound)-\(analysis.currentRepsRange.upperBound) / \(analysis.targetRepsRange.upperBound)"
                    )
                }
                
                // Trend
                TrendIndicator(trend: analysis.trend)
                
                // Begründung (aufklappbar)
                DisclosureGroup("Details") {
                    ForEach(analysis.reasoningPoints, id: \.self) { point in
                        Label(point, systemImage: "info.circle")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}
```

### 4.2 Dashboard: ProgressionSummaryCard

```swift
struct ProgressionSummaryCard: View {
    let analyses: [ProgressionAnalysis]
    
    var readyForProgression: [ProgressionAnalysis] {
        analyses.filter { $0.hasRecommendation && $0.confidenceLevel != .low }
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                    Text("Progressions-Empfehlungen")
                        .font(.headline)
                    Spacer()
                    if !readyForProgression.isEmpty {
                        Badge("\(readyForProgression.count)")
                    }
                }
                
                if readyForProgression.isEmpty {
                    Text("Aktuell keine Übungen bereit für Progression")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(readyForProgression.prefix(3), id: \.exerciseName) { analysis in
                        ProgressionRow(analysis: analysis)
                    }
                    
                    if readyForProgression.count > 3 {
                        NavigationLink("Alle anzeigen (\(readyForProgression.count))") {
                            ProgressionListView(analyses: readyForProgression)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
```

---

## 5. Implementierungs-Reihenfolge

### Phase 1: Foundation (Woche 1)
- [ ] `ProgressionTypes.swift` erstellen
- [ ] `Exercise.swift` erweitern (neue Properties)
- [ ] SwiftData Migration vorbereiten
- [ ] Unit Tests für Berechnungen

### Phase 2: CalcEngine (Woche 1-2)
- [ ] `ProgressionCalcEngine` erweitern
- [ ] Double Progression Logik
- [ ] Trend-Analyse implementieren
- [ ] Konfidenz-Berechnung

### Phase 3: UI Integration (Woche 2)
- [ ] `ProgressionInsightCard` für Übungsdetails
- [ ] Progressions-Einstellungen in ExerciseFormView
- [ ] `ProgressionSummaryCard` für Dashboard

### Phase 4: Polish (Woche 2-3)
- [ ] Animationen und Glassmorphism
- [ ] Lokalisierung (Deutsch)
- [ ] Edge Cases testen
- [ ] Performance-Optimierung

---

## 6. Offene Fragen

1. **Sollen Progressions-Empfehlungen in Supabase gespeichert werden?**
   - Pro: Sync zwischen Geräten
   - Contra: Zusätzliche Komplexität
   
2. **Wie mit Übungen ohne Gewicht umgehen (Bodyweight)?**
   - Option A: Reps-basierte Progression
   - Option B: Zeit-basierte Progression
   - Option C: Von Analyse ausschließen

3. **Soll die App warnen, wenn man die Empfehlung ignoriert?**
   - Dezenter Hinweis?
   - Gar nicht?

4. **Historische Analysen speichern?**
   - Für "Progression History" pro Übung
   - Könnte interessante Insights liefern

---

## 7. Beispiel-Flow

```
User öffnet Übungsdetail für "Bankdrücken"
    ↓
ProgressionCalcEngine.analyze() wird aufgerufen
    ↓
Letzte 8 Sessions mit Bankdrücken werden analysiert:
  - Session 1 (heute -3d): 80kg × 12, 12, 11 (RPE 7, 7, 8)
  - Session 2 (heute -7d): 80kg × 11, 11, 10 (RPE 7, 8, 8)
  - Session 3 (heute -10d): 80kg × 10, 10, 10 (RPE 8, 8, 8)
    ↓
Double Progression Status:
  - Ziel-Range: 8-12
  - Aktuelle Min-Reps: 11
  - Progress: 75% (11-8)/(12-8)
  - Noch nicht am oberen Limit (12)
    ↓
Empfehlung: "increaseReps"
Konfidenz: 0.65 (medium)
Trend: improving
    ↓
UI zeigt:
  ┌──────────────────────────────────────┐
  │ 📈 Progressions-Analyse    🟡 Mittel │
  ├──────────────────────────────────────┤
  │ 🔄 Empfehlung: Reps steigern         │
  │                                      │
  │ Rep-Fortschritt: [████████░░] 75%    │
  │ 11-12 / 12 Reps                      │
  │                                      │
  │ ↗️ Trend: Aufwärtstrend              │
  │                                      │
  │ ▶ Details                            │
  │   • 3 Sessions analysiert            │
  │   • Ø RIR: 2.3 (Ziel: 2)             │
  │   • Geschätztes 1RM: 98kg (+3%)      │
  └──────────────────────────────────────┘
```

---

*Dokument erstellt: März 2026*
*Für: MotionCore iOS App*
