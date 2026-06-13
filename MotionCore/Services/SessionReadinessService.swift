//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SessionReadinessService.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Erzeugt einen Readiness-Snapshot beim Workout-Start (Phase 2)    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@MainActor
enum SessionReadinessService {

    /// Berechnet Readiness für eine Session und persistiert den Snapshot.
    /// Gibt den berechneten Modifier zurück (Fallback: 1.0 bei Fehler).
    @discardableResult
    static func captureReadiness(
        for session: StrengthSession,
        context: ModelContext,
        takesCardioMedication: Bool
    ) async -> Double {
        // Baselines sicherstellen
        let baselineService = HealthBaselineUpdateService(healthKit: .shared, context: context)
        await baselineService.updateIfNeeded(takesCardioMedication: takesCardioMedication)

        // Baselines laden
        let baselines = (try? context.fetch(FetchDescriptor<HealthBaseline>())) ?? []
        func baseline(_ type: HealthMetricType) -> HealthBaseline? {
            baselines.first { $0.metricType == type }
        }

        // Heutige HealthKit-Werte holen (Fehler = nil, kein Crash)
        // .max(by:) wählt deterministisch den aktuellsten Tag statt non-deterministisch .values.first
        let hrv      = try? await HealthKitManager.shared.hrvSamples(daysBack: 1).max(by: { $0.key < $1.key })?.value
        let sleep    = try? await HealthKitManager.shared.sleepDuration(forNightEnding: Date())
        let restHR   = try? await HealthKitManager.shared.restingHRSamples(daysBack: 1).max(by: { $0.key < $1.key })?.value
        let activity = try? await HealthKitManager.shared.activeEnergy(
            forDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )

        let input = ReadinessCalcEngine.Input(
            takesCardioMedication: takesCardioMedication,
            hrvToday: hrv,
            sleepToday: sleep,
            restingHRToday: restHR,
            activityYesterday: activity,
            hrvBaseline: baseline(.hrv),
            sleepBaseline: baseline(.sleep),
            restingHRBaseline: baseline(.restingHR),
            activityBaseline: baseline(.activity),
            userEnergy: nil,
            userStressRaw: nil
        )
        let output = ReadinessCalcEngine.calculate(input: input)

        // SessionReadiness persistieren
        let readiness = SessionReadiness()
        readiness.sessionUUID = session.sessionUUID.uuidString
        readiness.capturedAt = Date()
        readiness.hrvScore = output.hrvScore
        readiness.sleepScore = output.sleepScore
        readiness.restingHRScore = output.restingHRScore
        readiness.activityScore = output.activityScore
        readiness.overallScore = output.score
        readiness.isCalibrating = output.isCalibrating
        context.insert(readiness)

        // Session verlinken
        session.sessionReadinessID = readiness.id
        try? context.save()

        return output.modifier
    }

    /// Berechnet Readiness live aus HealthKit — persistiert nichts.
    static func computeLive(
        context: ModelContext,
        takesCardioMedication: Bool
    ) async -> ReadinessCalcEngine.Output {
        // Baselines sicherstellen
        let baselineService = HealthBaselineUpdateService(healthKit: .shared, context: context)
        await baselineService.updateIfNeeded(takesCardioMedication: takesCardioMedication)

        // Baselines laden
        let baselines = (try? context.fetch(FetchDescriptor<HealthBaseline>())) ?? []
        func baseline(_ type: HealthMetricType) -> HealthBaseline? {
            baselines.first { $0.metricType == type }
        }

        // Heutige HealthKit-Werte holen (Fehler = nil, kein Crash)
        // .max(by:) wählt deterministisch den aktuellsten Tag statt non-deterministisch .values.first
        let hrv      = try? await HealthKitManager.shared.hrvSamples(daysBack: 1).max(by: { $0.key < $1.key })?.value
        let sleep    = try? await HealthKitManager.shared.sleepDuration(forNightEnding: Date())
        let restHR   = try? await HealthKitManager.shared.restingHRSamples(daysBack: 1).max(by: { $0.key < $1.key })?.value
        let activity = try? await HealthKitManager.shared.activeEnergy(
            forDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )

        let input = ReadinessCalcEngine.Input(
            takesCardioMedication: takesCardioMedication,
            hrvToday: hrv,
            sleepToday: sleep,
            restingHRToday: restHR,
            activityYesterday: activity,
            hrvBaseline: baseline(.hrv),
            sleepBaseline: baseline(.sleep),
            restingHRBaseline: baseline(.restingHR),
            activityBaseline: baseline(.activity),
            userEnergy: nil,
            userStressRaw: nil
        )
        return ReadinessCalcEngine.calculate(input: input)
    }

    /// Aktualisiert den Score mit User-Input (Energie + Stress) und speichert neu.
    static func refineWithUserInput(
        readiness: SessionReadiness,
        energy: Int?,
        stress: String?,
        context: ModelContext,
        takesCardioMedication: Bool
    ) {
        readiness.userEnergyLevel = energy
        readiness.userStressLevelRaw = stress

        let baselines = (try? context.fetch(FetchDescriptor<HealthBaseline>())) ?? []
        func baseline(_ type: HealthMetricType) -> HealthBaseline? {
            baselines.first { $0.metricType == type }
        }

        let input = ReadinessCalcEngine.Input(
            takesCardioMedication: takesCardioMedication,
            hrvToday: scoreToApproximateValue(readiness.hrvScore, baseline: baseline(.hrv), higherIsBetter: true),
            sleepToday: scoreToApproximateValue(readiness.sleepScore, baseline: baseline(.sleep), higherIsBetter: true),
            restingHRToday: scoreToApproximateValue(readiness.restingHRScore, baseline: baseline(.restingHR), higherIsBetter: false),
            activityYesterday: scoreToApproximateValue(readiness.activityScore, baseline: baseline(.activity), higherIsBetter: true),
            hrvBaseline: baseline(.hrv),
            sleepBaseline: baseline(.sleep),
            restingHRBaseline: baseline(.restingHR),
            activityBaseline: baseline(.activity),
            userEnergy: energy,
            userStressRaw: stress
        )
        let output = ReadinessCalcEngine.calculate(input: input)
        readiness.overallScore = output.score
        try? context.save()
    }

    // Rekonstruiert den ungefähren Rohmesswert aus dem gespeicherten normierten Score
    private static func scoreToApproximateValue(_ normalized: Double?, baseline: HealthBaseline?, higherIsBetter: Bool) -> Double? {
        guard let n = normalized, let b = baseline else { return nil }
        // normalisiert = (z + 1.5) / 3  →  z = n * 3 - 1.5
        let z = higherIsBetter ? (n * 3.0 - 1.5) : (1.5 - n * 3.0)
        return b.rollingMean + z * b.rollingStdDev
    }
}
