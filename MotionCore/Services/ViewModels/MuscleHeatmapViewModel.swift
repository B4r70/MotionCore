//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : ViewModels                                                       /
// Datei . . . . : MuscleHeatmapViewModel.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : Gecachte Heatmap-Analyse — einmal berechnen, O(1) lesen.         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import Observation

@Observable
final class MuscleHeatmapViewModel {

    // MARK: - Gecachte Ergebnisse

    private(set) var analysis: MuscleHeatmapAnalysis?
    private(set) var faultedSessions: [StrengthSession] = []
    private(set) var isCalculating = false

    // MARK: - Cache-Keys

    private var cachedTimeframe: SummaryTimeframe?
    private var cachedSessionCount: Int = 0

    private let calcEngine = MuscleHeatmapCalcEngine()

    // MARK: - Neuberechnung

    /// Berechnet die Heatmap-Analyse und cached das Ergebnis.
    /// Nur bei echten Änderungen neu berechnen (via .task / .onChange).
    func recalculate(sessions: [StrengthSession], timeframe: SummaryTimeframe) {
        guard timeframe != cachedTimeframe || sessions.count != cachedSessionCount else { return }

        isCalculating = true
        analysis = calcEngine.analyze(sessions: sessions, timeframe: timeframe)
        faultedSessions = sessions          // exerciseSets-Relationships sind jetzt gefaultet
        cachedTimeframe = timeframe
        cachedSessionCount = sessions.count
        isCalculating = false
    }
}
