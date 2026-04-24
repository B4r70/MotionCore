//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Berechnung                                                       /
// Datei . . . . : ReadinessCalcEngine.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Berechnet den täglichen Readiness-Score (Phase 2)                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct ReadinessCalcEngine {

    // MARK: - Input

    struct Input {
        let takesCardioMedication: Bool

        // Heutige Messwerte (nil = nicht verfügbar)
        let hrvToday: Double?           // ms SDNN
        let sleepToday: Double?         // Stunden letzte Nacht
        let restingHRToday: Double?     // bpm
        let activityYesterday: Double?  // kcal

        // Baselines aus SwiftData
        let hrvBaseline: HealthBaseline?
        let sleepBaseline: HealthBaseline?
        let restingHRBaseline: HealthBaseline?
        let activityBaseline: HealthBaseline?

        // Optionaler User-Input
        let userEnergy: Int?            // 1–5
        let userStressRaw: String?      // "low" | "medium" | "high"
    }

    // MARK: - Output

    struct Output {
        let score: Int                  // 0–100
        let label: ReadinessLabel
        let modifier: Double            // 0.85 / 0.92 / 1.00 / 1.05
        let breakdown: [ReadinessFactor]
        let isCalibrating: Bool

        // Per-Metrik-Scores für SessionReadiness-Persistenz (0.0–1.0)
        let hrvScore: Double?
        let sleepScore: Double?
        let restingHRScore: Double?
        let activityScore: Double?
    }

    // MARK: - Berechnung

    static func calculate(input: Input) -> Output {

        // 1. Kalibrierungs-Check
        let allBaselines: [HealthBaseline?] = [
            input.hrvBaseline, input.sleepBaseline,
            input.restingHRBaseline, input.activityBaseline
        ]
        let hasEnoughData = allBaselines.allSatisfy { ($0?.sampleCount ?? 0) >= 14 }

        guard hasEnoughData else {
            return Output(
                score: 50, label: .normal, modifier: 1.0,
                breakdown: [], isCalibrating: true,
                hrvScore: nil, sleepScore: nil, restingHRScore: nil, activityScore: nil
            )
        }

        // 2. Gewichtung je nach Medikation
        let w: (hrv: Double, sleep: Double, restingHR: Double, activity: Double) =
            input.takesCardioMedication
            ? (0.25, 0.40, 0.15, 0.15)
            : (0.40, 0.30, 0.20, 0.10)

        let wPct: (hrv: Int, sleep: Int, restingHR: Int, activity: Int) =
            input.takesCardioMedication
            ? (25, 40, 15, 15)
            : (40, 30, 20, 10)

        // 3. Per-Metrik-Scores berechnen
        let hrvNorm    = normalizedScore(value: input.hrvToday,        baseline: input.hrvBaseline,      higherIsBetter: true)
        let sleepNorm  = normalizedScore(value: input.sleepToday,      baseline: input.sleepBaseline,    higherIsBetter: true)
        let hrNorm     = normalizedScore(value: input.restingHRToday,  baseline: input.restingHRBaseline, higherIsBetter: false)
        let actNorm    = normalizedScore(value: input.activityYesterday, baseline: input.activityBaseline, higherIsBetter: true)

        // Nur verfügbare Metriken in gewichteten Score einrechnen
        var weightedSum = 0.0
        var totalWeight = 0.0
        if let s = hrvNorm    { weightedSum += s * w.hrv;      totalWeight += w.hrv }
        if let s = sleepNorm  { weightedSum += s * w.sleep;    totalWeight += w.sleep }
        if let s = hrNorm     { weightedSum += s * w.restingHR; totalWeight += w.restingHR }
        if let s = actNorm    { weightedSum += s * w.activity; totalWeight += w.activity }

        let baseNormalized: Double = totalWeight > 0 ? weightedSum / totalWeight : 0.5
        var finalScore = baseNormalized * 100.0

        // 4. User-Input-Anpassung
        if let energy = input.userEnergy {
            finalScore += (Double(energy) - 3.0) * 2.5  // -5 bis +5
        }
        if let stressRaw = input.userStressRaw {
            switch ReadinessStressInput(rawValue: stressRaw) {
            case .low:    finalScore += 3
            case .high:   finalScore -= 5
            default:      break
            }
        }
        let clampedScore = Int(min(max(finalScore, 0), 100).rounded())

        // 5. Modifier
        let modifier: Double
        switch clampedScore {
        case 0..<30:   modifier = 0.85
        case 30..<50:  modifier = 0.92
        case 85...100: modifier = 1.05
        default:       modifier = 1.00
        }

        // 6. Breakdown für UI
        var breakdown: [ReadinessFactor] = []
        if let s = hrvNorm {
            breakdown.append(ReadinessFactor(
                metricType: .hrv,
                name: "HRV",
                valueDescription: valueDescription(for: s, higherIsBetter: true),
                normalizedScore: s,
                weightPercent: wPct.hrv
            ))
        }
        if let s = sleepNorm {
            let desc = input.sleepToday.map { sleepDurationDescription($0) } ?? valueDescription(for: s, higherIsBetter: true)
            breakdown.append(ReadinessFactor(
                metricType: .sleep,
                name: "Schlaf",
                valueDescription: desc,
                normalizedScore: s,
                weightPercent: wPct.sleep
            ))
        }
        if let s = hrNorm {
            breakdown.append(ReadinessFactor(
                metricType: .restingHR,
                name: "Ruhepuls",
                valueDescription: valueDescription(for: s, higherIsBetter: false),
                normalizedScore: s,
                weightPercent: wPct.restingHR
            ))
        }
        if let s = actNorm {
            breakdown.append(ReadinessFactor(
                metricType: .activity,
                name: "Aktivität (gestern)",
                valueDescription: valueDescription(for: s, higherIsBetter: true),
                normalizedScore: s,
                weightPercent: wPct.activity
            ))
        }

        return Output(
            score: clampedScore,
            label: ReadinessLabel.from(score: clampedScore),
            modifier: modifier,
            breakdown: breakdown,
            isCalibrating: false,
            hrvScore: hrvNorm,
            sleepScore: sleepNorm,
            restingHRScore: hrNorm,
            activityScore: actNorm
        )
    }

    // MARK: - Hilfsmethoden

    // Normalisiert einen Messwert relativ zur Baseline (0.0–1.0, nil wenn keine Daten)
    private static func normalizedScore(
        value: Double?,
        baseline: HealthBaseline?,
        higherIsBetter: Bool
    ) -> Double? {
        guard let v = value, let b = baseline, b.sampleCount >= 14 else { return nil }
        guard b.rollingStdDev > 0.01 else { return 0.5 } // stdDev ≈ 0 → neutral
        let z = (v - b.rollingMean) / b.rollingStdDev
        let raw = higherIsBetter ? (z + 2.0) / 4.0 : (-z + 2.0) / 4.0
        return min(max(raw, 0.0), 1.0)
    }

    private static func valueDescription(for normalized: Double, higherIsBetter: Bool) -> String {
        // Konvertierung zurück in z-Score-Raum für Beschreibung
        let z = higherIsBetter ? (normalized * 4.0 - 2.0) : (2.0 - normalized * 4.0)
        switch z {
        case let z where z > 1.5:  return "deutlich über Baseline"
        case let z where z > 0.5:  return "leicht über Baseline"
        case let z where z > -0.5: return "normal"
        case let z where z > -1.5: return "leicht unter Baseline"
        default:                   return "deutlich unter Baseline"
        }
    }

    private static func sleepDurationDescription(_ hours: Double) -> String {
        switch hours {
        case let h where h < 5:  return "sehr wenig"
        case let h where h < 6:  return "wenig"
        case let h where h < 7:  return "okay"
        case let h where h < 8:  return "gut"
        default:                 return "sehr gut"
        }
    }
}
