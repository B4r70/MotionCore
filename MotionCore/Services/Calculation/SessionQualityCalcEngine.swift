//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Calculation                                           /
// Datei . . . . : SessionQualityCalcEngine.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Berechnet Session-Qualitaetsscore (0-100) aus RIR-Ausbelastung,  /
//                 Ziel-Reps-Erreichung und Readiness-Modifier.                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Pure Struct ohne Side-Effects. Phase 1: readiness immer nil        /
//                → readinessFactor = 1.0 (neutral).                                /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct SessionQualityCalcEngine {

    // MARK: - I/O-Typen

    struct Input {
        let session: StrengthSession
        let allSets: [ExerciseSet]
        let readiness: SessionReadiness?
    }

    struct Output {
        let score: Int
        let factors: [QualityFactor]
    }

    enum QualityFactor {
        case rirUsage(Double)       // 0...1
        case repsTarget(Double)     // 0...1
        case readiness(Double)      // 0...1
    }

    // MARK: - Gewichtung (Concept 4.6)

    private static let rirWeight: Double = 0.40
    private static let repsWeight: Double = 0.35
    private static let readinessWeight: Double = 0.25

    // MARK: - Einstiegspunkt

    static func calculate(input: Input) -> Output {
        let workSets = input.allSets
            .filter { $0.isCompleted && $0.setKindRaw == "work" }

        let rirFactor = computeRIRFactor(workSets: workSets)
        let repsFactor = computeRepsFactor(workSets: workSets)
        let readinessFactor = computeReadinessFactor(readiness: input.readiness)

        let raw = rirFactor * rirWeight
                + repsFactor * repsWeight
                + readinessFactor * readinessWeight

        let clamped = max(0.0, min(1.0, raw))
        let score = Int((clamped * 100).rounded())

        return Output(
            score: score,
            factors: [
                .rirUsage(rirFactor),
                .repsTarget(repsFactor),
                .readiness(readinessFactor)
            ]
        )
    }

    // MARK: - Einzelfaktoren

    /// Anteil der Work-Sets mit calculatedRIR 0..2 (gute Ausbelastung).
    /// Sets ohne RIR-Daten (rpe == 0) werden als "neutral" ausgeklammert.
    private static func computeRIRFactor(workSets: [ExerciseSet]) -> Double {
        let withData = workSets.filter { $0.rpe > 0 }
        guard !withData.isEmpty else { return 1.0 }  // keine Daten → neutral
        let good = withData.filter { $0.calculatedRIR >= 0 && $0.calculatedRIR <= 2 }.count
        return Double(good) / Double(withData.count)
    }

    /// Anteil der Work-Sets mit reps >= targetRepsMin.
    /// Sets ohne targetRepsMin (== 0) werden als erreicht gezaehlt.
    private static func computeRepsFactor(workSets: [ExerciseSet]) -> Double {
        guard !workSets.isEmpty else { return 1.0 }
        let hit = workSets.filter { set in
            let target = set.targetRepsMin
            return target <= 0 ? true : set.reps >= target
        }.count
        return Double(hit) / Double(workSets.count)
    }

    /// Readiness-Faktor aus SessionReadiness-Modifier.
    /// Phase 1: readiness ist nil → 1.0 (neutral).
    /// Phase 2: readiness.overallScore via modifier-Mapping.
    private static func computeReadinessFactor(readiness: SessionReadiness?) -> Double {
        guard let readiness else { return 1.0 }
        // Phase-2-Stub: overallScore 0..100 → 0.85..1.05 via Linear-Mapping (Concept 4.2)
        let s = Double(readiness.overallScore)
        if s >= 85 { return 1.0 }         // keine Boni im Qualitaets-Score
        if s >= 70 { return 1.0 }
        if s >= 50 { return 1.0 }
        if s >= 30 { return 0.92 }
        return 0.85
    }
}

// MARK: - Testszenarien (Concept 4.6)
// 1. Alle Work-Sets rpe 8-10 (RIR 0-2) + reps >= target .... → score ~100
// 2. Alle Work-Sets rpe 5-7  (RIR 3-5) + reps >= target .... → score ~60 (0*0.4 + 1*0.35 + 1*0.25 = 0.60)
// 3. Alle rpe 8-10, reps < target ........................... → score ~65 (0.4 + 0 + 0.25)
// 4. Alle rpe == 0 (keine Daten), reps >= target ............ → score 100 (neutral RIR)
// 5. Leere Session (keine Work-Sets) ........................ → score 100 (Edge: alle Faktoren 1.0)
