//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : ViewModels                                                       /
// Datei . . . . : ReadinessViewModel.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Stellt Readiness-Daten für die ReadinessCard bereit (Phase 2)   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Observable
final class ReadinessViewModel {

    private(set) var readiness: SessionReadiness?
    private(set) var breakdown: [ReadinessFactor] = []

    // Debug-Override: -1 = kein Override, 0–100 = überschreibt echten Score
    private(set) var debugScoreOverride: Int = -1

    var score: Int {
        #if DEBUG
        if debugScoreOverride >= 0 { return debugScoreOverride }
        #endif
        return readiness?.overallScore ?? 50
    }
    var isCalibrating: Bool { readiness?.isCalibrating ?? true }
    var label: ReadinessLabel { ReadinessLabel.from(score: score) }
    var modifier: Double {
        switch score {
        case 0..<30:   return 0.85
        case 30..<50:  return 0.92
        case 85...100: return 1.05
        default:       return 1.00
        }
    }

    func load(readiness: SessionReadiness?, baselines: [HealthBaseline], takesCardioMedication: Bool, debugScoreOverride: Int = -1) {
        self.readiness = readiness
        self.debugScoreOverride = debugScoreOverride
        guard let r = readiness, !r.isCalibrating else {
            breakdown = []
            return
        }
        breakdown = buildBreakdown(r, baselines: baselines, takesCardioMedication: takesCardioMedication)
    }

    private func buildBreakdown(_ r: SessionReadiness, baselines: [HealthBaseline], takesCardioMedication: Bool) -> [ReadinessFactor] {
        func baseline(_ type: HealthMetricType) -> HealthBaseline? {
            baselines.first { $0.metricType == type }
        }
        let w: (hrv: Int, sleep: Int, restingHR: Int, activity: Int) =
            takesCardioMedication ? (25, 40, 15, 15) : (40, 30, 20, 10)

        var result: [ReadinessFactor] = []

        func desc(_ norm: Double, _ higherIsBetter: Bool) -> String {
            let z = higherIsBetter ? (norm * 4.0 - 2.0) : (2.0 - norm * 4.0)
            switch z {
            case let z where z > 1.5:  return "deutlich über Baseline"
            case let z where z > 0.5:  return "leicht über Baseline"
            case let z where z > -0.5: return "normal"
            case let z where z > -1.5: return "leicht unter Baseline"
            default:                   return "deutlich unter Baseline"
            }
        }

        if let s = r.hrvScore {
            result.append(ReadinessFactor(metricType: .hrv, name: "HRV",
                valueDescription: desc(s, true), normalizedScore: s, weightPercent: w.hrv))
        }
        if let s = r.sleepScore {
            // Schlaf-Beschreibung aus gespeichertem Score ableiten
            let sleepDesc = sleepDescription(normalized: s, baseline: baseline(.sleep))
            result.append(ReadinessFactor(metricType: .sleep, name: "Schlaf",
                valueDescription: sleepDesc, normalizedScore: s, weightPercent: w.sleep))
        }
        if let s = r.restingHRScore {
            result.append(ReadinessFactor(metricType: .restingHR, name: "Ruhepuls",
                valueDescription: desc(s, false), normalizedScore: s, weightPercent: w.restingHR))
        }
        if let s = r.activityScore {
            result.append(ReadinessFactor(metricType: .activity, name: "Aktivität (gestern)",
                valueDescription: desc(s, true), normalizedScore: s, weightPercent: w.activity))
        }
        return result
    }

    private func sleepDescription(normalized: Double, baseline: HealthBaseline?) -> String {
        guard let b = baseline else { return "normal" }
        let z = normalized * 4.0 - 2.0
        let approxHours = b.rollingMean + z * b.rollingStdDev
        switch approxHours {
        case let h where h < 5:  return "sehr wenig"
        case let h where h < 6:  return "wenig"
        case let h where h < 7:  return "okay"
        case let h where h < 8:  return "gut"
        default:                 return "sehr gut"
        }
    }
}
