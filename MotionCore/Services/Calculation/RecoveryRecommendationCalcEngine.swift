//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : RecoveryRecommendationCalcEngine.swift                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Ableitung von Trainings-Empfehlungen aus MuscleRecoveryAnalysis  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - RecoveryRecommendation

/// Empfehlung welche Muskelgruppen heute trainiert oder gemieden werden sollten
struct RecoveryRecommendation {
    let recommendedGroups: [MuscleGroup]
    let avoidGroups: [MuscleGroup]
    let recommendedTitle: String
    let avoidTitle: String
    let avoidReason: String

    /// Leerer Zustand wenn keine Trainingsdaten vorhanden
    static let empty = RecoveryRecommendation(
        recommendedGroups: [],
        avoidGroups: [],
        recommendedTitle: "Noch keine Trainingsdaten",
        avoidTitle: "Heute keine Einschränkungen",
        avoidReason: ""
    )
}

// MARK: - RecoveryRecommendationCalcEngine

/// Pure Namespace-Enum zur Ableitung von Trainings-Empfehlungen
enum RecoveryRecommendationCalcEngine {

    // MARK: - Schwellenwerte

    /// Mindest-Erholung (%) damit eine Gruppe als "empfohlen" gilt
    private static let recommendThreshold: Double = 85.0

    /// Maximal-Erholung (%) unterhalb derer eine Gruppe gemieden werden sollte
    private static let avoidThreshold: Double = 60.0

    // MARK: - Haupt-Funktion

    /// Leitet Trainings-Empfehlung aus einer MuscleRecoveryAnalysis ab
    static func recommend(from analysis: MuscleRecoveryAnalysis) -> RecoveryRecommendation {
        guard !analysis.muscleGroupScores.isEmpty else { return .empty }

        // Nur Gruppen berücksichtigen die im Zeitfenster trainiert wurden
        let trained = analysis.muscleGroupScores.filter { $0.wasTrainedInTimeframe }
        guard !trained.isEmpty else { return .empty }

        // Empfohlene Gruppen: >= 85% Erholung, absteigend sortiert, max. 3
        let recommended = trained
            .filter { $0.recoveryPercent >= recommendThreshold }
            .sorted { $0.recoveryPercent > $1.recoveryPercent }
            .prefix(3)
            .map { $0.muscleGroup }

        // Meidungs-Gruppen: < 60% Erholung, aufsteigend sortiert, max. 3
        let avoid = trained
            .filter { $0.recoveryPercent < avoidThreshold }
            .sorted { $0.recoveryPercent < $1.recoveryPercent }
            .prefix(3)
            .map { $0.muscleGroup }

        let recommendedTitle = buildRecommendedTitle(for: recommended)
        let avoidTitle = buildAvoidTitle(for: avoid)
        let avoidReason = buildAvoidReason(from: trained, avoid: avoid)

        return RecoveryRecommendation(
            recommendedGroups: recommended,
            avoidGroups: avoid,
            recommendedTitle: recommendedTitle,
            avoidTitle: avoidTitle,
            avoidReason: avoidReason
        )
    }

    // MARK: - Titel-Hilfsfunktionen

    private static func buildRecommendedTitle(for groups: [MuscleGroup]) -> String {
        guard !groups.isEmpty else { return "Keine Gruppe vollständig erholt" }

        let names = groups.map { displayName(for: $0) }.joined(separator: " · ")

        if let prefix = groupPrefix(for: groups) {
            return "\(prefix) \(names)"
        }
        return names
    }

    private static func buildAvoidTitle(for groups: [MuscleGroup]) -> String {
        guard !groups.isEmpty else { return "Heute keine Einschränkungen" }
        return groups.map { displayName(for: $0) }.joined(separator: " · ")
    }

    private static func buildAvoidReason(from trained: [MuscleGroupRecovery], avoid: [MuscleGroup]) -> String {
        guard !avoid.isEmpty else { return "" }
        let lowestScore = trained
            .filter { avoid.contains($0.muscleGroup) }
            .map { $0.recoveryPercent }
            .min() ?? 0.0
        return "Bei \(Int(lowestScore))% Erholung steigt das Verletzungsrisiko."
    }

    // MARK: - Präfix-Erkennung

    /// Erkennt Trainings-Muster (Push / Pull / Beine) aus einer Menge von Muskelgruppen
    private static func groupPrefix(for groups: [MuscleGroup]) -> String? {
        let groupSet = Set(groups)

        // Push: Brust + Schultern + Arme (enthält Trizeps)
        if groupSet.contains(.chest) && groupSet.contains(.shoulders) && groupSet.contains(.arms) {
            return "Push:"
        }
        // Pull: Rücken + Arme (enthält Bizeps)
        if groupSet.contains(.back) && groupSet.contains(.arms) {
            return "Pull:"
        }
        // Beine + Gesäß
        if groupSet.contains(.legs) && groupSet.contains(.glutes) {
            return "Beine:"
        }
        return nil
    }

    // MARK: - Display-Name

    /// Lokalisierter Anzeigename einer Muskelgruppe
    private static func displayName(for group: MuscleGroup) -> String {
        switch group {
        case .chest:    return "Brust"
        case .back:     return "Rücken"
        case .shoulders: return "Schultern"
        case .arms:     return "Arme"
        case .legs:     return "Beine"
        case .glutes:   return "Gesäß"
        case .core:     return "Core"
        case .fullBody: return "Ganzkörper"
        case .other:    return "Sonstige"
        }
    }
}
