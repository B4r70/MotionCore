//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : HealthDataCalcEngine.swift                                       /
// Erstellt am . : 31.03.2026                                                       /
// Beschreibung  : Aggregiert ExerciseMetrics zu einer Session-Zusammenfassung      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct SessionHealthSummary {
    let avgHR: Double
    let maxHR: Double
    let totalCalories: Double
    let totalDuration: Int  // Sekunden
}

struct HealthDataCalcEngine {
    func sessionSummary(from metrics: [ExerciseMetrics]) -> SessionHealthSummary {
        guard !metrics.isEmpty else {
            return SessionHealthSummary(avgHR: 0, maxHR: 0, totalCalories: 0, totalDuration: 0)
        }
        let allAvgHR = metrics.map { $0.avgHeartRate }.filter { $0 > 0 }
        let avgHR = allAvgHR.isEmpty ? 0 : allAvgHR.reduce(0, +) / Double(allAvgHR.count)
        let maxHR = metrics.map { $0.maxHeartRate }.max() ?? 0
        let totalCalories = metrics.map { $0.activeCalories }.reduce(0, +)
        let totalDuration = metrics.reduce(0) { $0 + $1.durationSeconds }
        return SessionHealthSummary(avgHR: avgHR, maxHR: maxHR, totalCalories: totalCalories, totalDuration: totalDuration)
    }
}
