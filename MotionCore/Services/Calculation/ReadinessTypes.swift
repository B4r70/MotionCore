//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : ReadinessTypes.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Typen für ReadinessCalcEngine (Phase 2)                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Readiness-Label

enum ReadinessLabel: String {
    case veryLow    = "veryLow"
    case low        = "low"
    case normal     = "normal"
    case good       = "good"
    case excellent  = "excellent"

    static func from(score: Int) -> ReadinessLabel {
        switch score {
        case 0..<25:    return .veryLow
        case 25..<42:   return .low
        case 42..<65:   return .normal
        case 65..<82:   return .good
        default:        return .excellent
        }
    }

    var localizedTitle: String {
        switch self {
        case .veryLow:   return "Heute besser schonen"
        case .low:       return "Etwas müde heute"
        case .normal:    return "Normale Tagesform"
        case .good:      return "Heute gut drauf"
        case .excellent: return "Top-Tag heute"
        }
    }
}

// MARK: - Stress-Input

enum ReadinessStressInput: String {
    case low    = "low"
    case medium = "medium"
    case high   = "high"
}

// MARK: - Breakdown-Faktor

struct ReadinessFactor {
    let metricType: HealthMetricType
    let name: String
    let valueDescription: String
    let normalizedScore: Double  // 0.0 – 1.0
    let weightPercent: Int       // Gewichtung als ganze Prozentzahl
}
