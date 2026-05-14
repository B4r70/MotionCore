//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : MuscleRecoveryTypes.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Typen für MuscleRecoveryCalcEngine                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - DetailedMuscleRecovery

/// Erholungsstatus eines einzelnen feingranularen Muskels
struct DetailedMuscleRecovery: Identifiable {
    let id: String
    let muscle: DetailedMuscle
    let recoveryPercent: Double
    let lastTrainedDate: Date?
    let totalFatigueScore: Double

    var displayName: String { muscle.displayName }
    var muscleGroup: MuscleGroup { muscle.parentGroup }
}

// MARK: - MuscleGroupRecovery

/// Aggregierter Erholungsstatus einer Muskelgruppe
struct MuscleGroupRecovery: Identifiable {
    let id: String
    let muscleGroup: MuscleGroup
    let recoveryPercent: Double
    let muscleDetails: [DetailedMuscleRecovery]
    let lastTrainedDate: Date?
    let wasTrainedInTimeframe: Bool

    var displayName: String { muscleGroup.description }
    var isFullyRecovered: Bool { recoveryPercent >= 95.0 }
}

// MARK: - MuscleRecoveryAnalysis

/// Vollständige Erholungsanalyse für alle Muskelgruppen
struct MuscleRecoveryAnalysis {
    let analysisDate: Date
    let timeframeDays: Int
    let muscleGroupScores: [MuscleGroupRecovery]
    let detailedScores: [DetailedMuscleRecovery]

    /// Nur trainierte Gruppen, aufsteigend nach Erholung sortiert
    var leastRecoveredGroups: [MuscleGroupRecovery] {
        muscleGroupScores
            .filter { $0.wasTrainedInTimeframe }
            .sorted { $0.recoveryPercent < $1.recoveryPercent }
    }

    /// Durchschnitt der trainierten Gruppen; 100.0 wenn keine Gruppe trainiert
    var overallRecoveryPercent: Double {
        let trained = muscleGroupScores.filter { $0.wasTrainedInTimeframe }
        guard !trained.isEmpty else { return 100.0 }
        let sum = trained.reduce(0.0) { $0 + $1.recoveryPercent }
        return sum / Double(trained.count)
    }
}

// MARK: - MuscleRecoveryAnalysis + Identifiable

/// Identifiable-Konformität damit `.sheet(item:)` funktioniert
extension MuscleRecoveryAnalysis: Identifiable {
    var id: Date { analysisDate }
}
