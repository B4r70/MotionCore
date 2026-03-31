//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : ProgressionTypes.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-16                                                       /
// Beschreibung  : Typen für das intelligente Progressionssystem                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Progressions-Strategie

enum ProgressionStrategy: String, CaseIterable, Codable {
    case micro      = "micro"       // +1.25 kg, sehr konservativ
    case standard   = "standard"    // +2.5 kg nach N Sessions
    case aggressive = "aggressive"  // +5 kg, für Anfänger
    case double     = "double"      // Double Progression (erst Reps, dann Gewicht)
    case manual     = "manual"      // Keine automatischen Empfehlungen

    var displayName: String {
        switch self {
        case .micro:      return "Mikro-Progression"
        case .standard:   return "Standard"
        case .aggressive: return "Aggressiv"
        case .double:     return "Double Progression"
        case .manual:     return "Manuell"
        }
    }

    var description: String {
        switch self {
        case .micro:      return "Kleine Schritte (+1.25 kg). Ideal für Isolation und Plateaus."
        case .standard:   return "Klassische lineare Progression (+2.5 kg)."
        case .aggressive: return "Schnelle Steigerung (+5 kg). Für Anfänger oder nach Pausen."
        case .double:     return "Erst Reps steigern, dann Gewicht. Optimal für Rep-Ranges."
        case .manual:     return "Keine automatischen Empfehlungen."
        }
    }

    var icon: String {
        switch self {
        case .micro:      return "tortoise.fill"
        case .standard:   return "arrow.up.right"
        case .aggressive: return "hare.fill"
        case .double:     return "arrow.up.arrow.down"
        case .manual:     return "hand.raised.fill"
        }
    }
}

// MARK: - Konfidenz-Level

enum ProgressionConfidence: String, CaseIterable {
    case insufficient = "insufficient"  // < 0.3: Nicht genug Daten
    case low          = "low"           // 0.3–0.5: Könnte bereit sein
    case medium       = "medium"        // 0.5–0.75: Wahrscheinlich bereit
    case high         = "high"          // > 0.75: Definitiv bereit

    var displayName: String {
        switch self {
        case .insufficient: return "Unzureichend"
        case .low:          return "Niedrig"
        case .medium:       return "Mittel"
        case .high:         return "Hoch"
        }
    }

    var color: String {
        switch self {
        case .insufficient: return "gray"
        case .low:          return "orange"
        case .medium:       return "yellow"
        case .high:         return "green"
        }
    }

    var icon: String {
        switch self {
        case .insufficient: return "questionmark.circle"
        case .low:          return "circle.bottomhalf.filled"
        case .medium:       return "circle.inset.filled"
        case .high:         return "checkmark.circle.fill"
        }
    }

    init(value: Double) {
        switch value {
        case ..<0.3:      self = .insufficient
        case 0.3..<0.5:   self = .low
        case 0.5..<0.75:  self = .medium
        default:          self = .high
        }
    }
}

// MARK: - Trainings-Level (Auto-Detect)

enum TrainingLevel: String, CaseIterable {
    case beginner     = "beginner"      // < 10 Sessions
    case intermediate = "intermediate"  // 10–50 Sessions
    case advanced     = "advanced"      // > 50 Sessions
    case returning    = "returning"     // Nach längerer Pause

    var displayName: String {
        switch self {
        case .beginner:     return "Anfänger"
        case .intermediate: return "Fortgeschritten"
        case .advanced:     return "Erfahren"
        case .returning:    return "Wiedereinsteiger"
        }
    }

    var suggestedStrategy: ProgressionStrategy {
        switch self {
        case .beginner:     return .aggressive
        case .intermediate: return .standard
        case .advanced:     return .double
        case .returning:    return .standard
        }
    }

    var suggestedSessionsRequired: Int {
        switch self {
        case .beginner:     return 1
        case .intermediate: return 2
        case .advanced:     return 3
        case .returning:    return 2
        }
    }
}

// MARK: - Trend-Richtung

enum PerformanceTrend: String {
    case improving    = "improving"    // Aufwärtstrend
    case stable       = "stable"       // Stabil
    case declining    = "declining"    // Abwärtstrend
    case volatile     = "volatile"     // Stark schwankend
    case insufficient = "insufficient" // Nicht genug Daten

    var displayName: String {
        switch self {
        case .improving:    return "Aufwärtstrend"
        case .stable:       return "Stabil"
        case .declining:    return "Abwärtstrend"
        case .volatile:     return "Schwankend"
        case .insufficient: return "Zu wenig Daten"
        }
    }

    var icon: String {
        switch self {
        case .improving:    return "arrow.up.right"
        case .stable:       return "arrow.right"
        case .declining:    return "arrow.down.right"
        case .volatile:     return "waveform.path"
        case .insufficient: return "questionmark"
        }
    }

    var color: String {
        switch self {
        case .improving:    return "green"
        case .stable:       return "blue"
        case .declining:    return "orange"
        case .volatile:     return "yellow"
        case .insufficient: return "gray"
        }
    }
}

// MARK: - Empfohlene Aktion

enum ProgressionAction: Equatable {
    case maintain                   // Weiter so, noch nicht bereit
    case increaseReps               // Reps steigern (Double Progression Phase 1)
    case increaseWeight(kg: Double) // Gewicht steigern
    case considerDeload             // Leistung sinkt, Deload prüfen
    case needMoreData               // Zu wenig Daten für Empfehlung

    var displayName: String {
        switch self {
        case .maintain:
            return "Gewicht halten"
        case .increaseReps:
            return "Reps steigern"
        case .increaseWeight(let kg):
            return "Gewicht erhöhen (+\(kg.formatted()) kg)"
        case .considerDeload:
            return "Deload erwägen"
        case .needMoreData:
            return "Mehr Daten sammeln"
        }
    }

    var icon: String {
        switch self {
        case .maintain:        return "equal.circle"
        case .increaseReps:    return "repeat"
        case .increaseWeight:  return "arrow.up.circle.fill"
        case .considerDeload:  return "bed.double.fill"
        case .needMoreData:    return "chart.bar.doc.horizontal"
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
    let currentRepsRange: ClosedRange<Int>  // Min-Max der letzten Session
    let targetRepsRange: ClosedRange<Int>   // Ziel-Range der Übung

    // Analyse-Ergebnisse
    let trainingLevel: TrainingLevel
    let trend: PerformanceTrend
    let confidence: Double              // 0.0–1.0
    let confidenceLevel: ProgressionConfidence

    // Empfehlung
    let recommendedAction: ProgressionAction
    let suggestedWeight: Double?        // Nur bei .increaseWeight gesetzt

    // Begründung (für UI)
    let reasoningPoints: [String]

    // Statistiken
    let sessionsAnalyzed: Int
    let daysSinceLastSession: Int
    let estimatedOneRepMax: Double?
    let oneRepMaxTrend: PerformanceTrend?

    // Double Progression spezifisch
    let repsProgress: Double?       // 0.0–1.0 (wie weit im Rep-Range?)
    let isReadyForWeightIncrease: Bool

    // MARK: - Computed

    var hasRecommendation: Bool {
        switch recommendedAction {
        case .increaseReps, .increaseWeight: return true
        default: return false
        }
    }

    var summaryText: String {
        switch recommendedAction {
        case .maintain:
            return "Weiter mit \(currentWeight.formatted()) kg trainieren"
        case .increaseReps:
            return "Versuche mehr Reps bei \(currentWeight.formatted()) kg"
        case .increaseWeight(let kg):
            return "Bereit für \((currentWeight + kg).formatted()) kg"
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
    let reps: [Int]         // Reps pro Arbeitssatz
    let rpeValues: [Int]    // RPE pro Arbeitssatz (0 = nicht erfasst)
    let totalVolume: Double // Gewicht × Reps summiert
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
