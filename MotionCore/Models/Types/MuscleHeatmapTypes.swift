//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : MuscleHeatmapTypes.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : Typen für die Muskel-Heatmap                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - HeatLevel

enum HeatLevel: Int, CaseIterable, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: HeatLevel, rhs: HeatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // Heatmap Farbe (SwiftUI) — schema-abhängig, teilt die Skala mit hexColor.
    var color: Color { color(for: .light) }

    func color(for scheme: ColorScheme) -> Color {
        Color(hex: hexColor(for: scheme))
    }

    var hexColor: String { hexColor(for: .light) }

    /// Hex-String für die SVG-CSS-Injection, schema-abhängig.
    /// Light = sky → accent (heller Grund); Dark = gedämpft → heller Akzent (dunkler Grund).
    func hexColor(for scheme: ColorScheme) -> String {
        switch scheme {
        case .dark:
            switch self {
            case .none:   return "#222C37"   // surfaceSunken-dark: nicht trainiert, unauffällig
            case .low:    return "#2E4E70"
            case .medium: return "#3A7CDC"   // accentHover
            case .high:   return "#6BB0E8"   // heller Akzent-Ton für „viel"
            }
        default:
            switch self {
            case .none:   return "#E1EEF7"   // Calm 2026 Light-Skala (sky → accent)
            case .low:    return "#BBD8EC"
            case .medium: return "#3A8FC9"
            case .high:   return "#2C6BCB"
            }
        }
    }

    /// Deutscher Anzeigename
    var displayName: String {
        switch self {
        case .none:     return "Nicht trainiert"
        case .low:      return "Wenig"
        case .medium:   return "Moderat"
        case .high:     return "Viel"
        }
    }

    /// Erstellt HeatLevel aus relativem Wert (0.0–1.0)
    init(relativeValue: Double) {
        switch relativeValue {
        case ..<0.05:   self = .none
        case ..<0.33:   self = .low
        case ..<0.66:   self = .medium
        default:        self = .high
        }
    }
}

// MARK: - MuscleHeatData

struct MuscleHeatData: Identifiable {
    let id: String          // = svgRegionId
    let svgRegionId: String
    let displayName: String
    let totalVolume: Double
    let totalSets: Int
    let totalFrequency: Int         // Anzahl verschiedener Sessions
    let relativeIntensity: Double   // 0.0–1.0 (Composite Score)
    let heatLevel: HeatLevel
    let lastTrainedDate: Date?
    let contributingMuscles: [DetailedMuscle]

    var isNeglected: Bool { heatLevel <= .low }

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

    var frequencyFormatted: String {
        totalFrequency == 1 ? "1 Session" : "\(totalFrequency) Sessions"
    }
}

// MARK: - MuscleTrainingHistory

struct MuscleTrainingHistoryExercise: Identifiable {
    let id = UUID()
    let exerciseName: String
    let setCount: Int
    let totalReps: Int
    let maxWeight: Double
    let totalVolume: Double
    let isPrimary: Bool
}

struct MuscleTrainingHistorySession: Identifiable {
    let id: UUID                        // = session.sessionUUID
    let sessionDate: Date
    let planName: String?
    let exercises: [MuscleTrainingHistoryExercise]
}

// MARK: - MuscleHeatmapAnalysis

struct MuscleHeatmapAnalysis {
    let timeframe: SummaryTimeframe
    let analysisDate: Date
    let regionData: [String: MuscleHeatData]    // Key = svgRegionId
    let totalVolume: Double
    let totalSets: Int
    let totalFrequency: Int         // Maximale Frequenz über alle Regionen

    /// Vernachlässigte Regionen (sortiert: am wenigsten trainierte zuerst)
    var neglectedRegions: [MuscleHeatData] {
        regionData.values
            .filter { $0.isNeglected }
            .sorted { $0.relativeIntensity < $1.relativeIntensity }
    }

    /// Top 5 meisttrainierte Regionen (sortiert nach Composite Score)
    var topRegions: [MuscleHeatData] {
        Array(regionData.values
            .sorted { $0.relativeIntensity > $1.relativeIntensity }
            .prefix(5))
    }

    /// Gibt HeatData für eine SVG-Region zurück
    func data(for svgRegionId: String) -> MuscleHeatData? {
        regionData[svgRegionId]
    }

    /// CSS für SVG-Injection (dynamische Einfärbung der Muskelgruppen), schema-abhängig.
    func svgStylesCSS(for scheme: ColorScheme) -> String {
        regionData.map { svgId, data in
            "#\(svgId) path { fill: \(data.heatLevel.hexColor(for: scheme)) !important; }"
        }.joined(separator: "\n")
    }
}
