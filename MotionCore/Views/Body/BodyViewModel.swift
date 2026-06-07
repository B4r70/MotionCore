//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyViewModel.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : ViewModel für BodyView — koordiniert Recovery-Analyse und        /
//                 Readiness-Faktoren                                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Observable
final class BodyViewModel {

    // MARK: - Öffentliche Properties

    private(set) var recoveryAnalysis: MuscleRecoveryAnalysis?
    private(set) var recoveryTrend: [TrendPoint] = []
    private(set) var readinessFactors: [ReadinessFactor] = []
    private(set) var recommendation: RecoveryRecommendation = .empty
    private(set) var readinessScore: Int? = nil

    // MARK: - Internes Readiness-ViewModel (Logik-Wiederverwendung)

    private let readinessVM = ReadinessViewModel()

    // MARK: - Race-Guard

    private var refreshTask: Task<Void, Never>?

    // MARK: - Berechnungen

    /// Berechnet die Muskel-Erholungsanalyse aus den letzten abgeschlossenen Sessions
    func recalculate(sessions: [StrengthSession]) {
        recoveryAnalysis = MuscleRecoveryCalcEngine.analyze(sessions: sessions)
        if let analysis = recoveryAnalysis {
            recommendation = RecoveryRecommendationCalcEngine.recommend(from: analysis)
        } else {
            recommendation = .empty
        }
        recoveryTrend = RecoveryTrendCalcEngine.trend(sessions: sessions)
    }

    /// Lädt die Readiness-Faktoren analog zur ReadinessDetailView-Logik
    func loadReadinessFactors(
        latestReadiness: SessionReadiness?,
        baselines: [HealthBaseline],
        takesCardioMedication: Bool
    ) {
        readinessVM.load(
            readiness: latestReadiness,
            baselines: baselines,
            takesCardioMedication: takesCardioMedication
        )
        readinessFactors = readinessVM.breakdown
        // Score als gewichteter Durchschnitt der normalisierten Faktoren berechnen
        let breakdown = readinessVM.breakdown
        if breakdown.isEmpty {
            readinessScore = nil
        } else {
            let weighted = breakdown.reduce(0.0) { $0 + $1.normalizedScore * Double($1.weightPercent) }
            let totalWeight = breakdown.reduce(0) { $0 + $1.weightPercent }
            readinessScore = totalWeight > 0 ? Int((weighted / Double(totalWeight)) * 100) : nil
        }
    }

    /// Berechnet Readiness live aus HealthKit und aktualisiert den UI-State.
    /// Ein laufender Refresh wird abgebrochen bevor ein neuer startet (Race-Guard).
    @MainActor
    func loadLiveReadiness(context: ModelContext, takesCardioMedication: Bool) async {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            let output = await SessionReadinessService.computeLive(
                context: context,
                takesCardioMedication: takesCardioMedication
            )
            guard !Task.isCancelled else { return }
            readinessFactors = output.breakdown
            readinessScore = output.isCalibrating ? nil : output.score
        }
        await refreshTask?.value
    }
}
