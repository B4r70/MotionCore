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

@Observable
final class BodyViewModel {

    // MARK: - Öffentliche Properties

    private(set) var recoveryAnalysis: MuscleRecoveryAnalysis?
    private(set) var readinessFactors: [ReadinessFactor] = []

    // MARK: - Internes Readiness-ViewModel (Logik-Wiederverwendung)

    private let readinessVM = ReadinessViewModel()

    // MARK: - Berechnungen

    /// Berechnet die Muskel-Erholungsanalyse aus den letzten abgeschlossenen Sessions
    func recalculate(sessions: [StrengthSession]) {
        recoveryAnalysis = MuscleRecoveryCalcEngine.analyze(sessions: sessions)
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
    }
}
