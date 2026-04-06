//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Berechnung                                            /
// Datei . . . . : MuscleHeatmapCalcEngine.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : Berechnet Muskel-Heatmap-Daten aus StrengthSessions              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

struct MuscleHeatmapCalcEngine {

    // MARK: - Haupt-Analyse

    func analyze(
        sessions: [StrengthSession],
        timeframe: SummaryTimeframe
    ) -> MuscleHeatmapAnalysis {

        // 1. Sessions im Zeitraum filtern
        let filteredSessions = filterSessions(sessions, for: timeframe)

        // 2. Volumen pro SVG-Region aggregieren
        var volumeByRegion: [String: Double] = [:]
        var setsByRegion: [String: Int] = [:]
        var frequencyByRegion: [String: Set<UUID>] = [:]
        var lastTrainedByRegion: [String: Date] = [:]
        var musclesByRegion: [String: Set<DetailedMuscle>] = [:]

        for session in filteredSessions {
            for set in session.safeExerciseSets where set.isCompleted {
                let volume = set.weight * Double(set.reps)
                guard volume > 0 else { continue }

                // Primäre Muskeln ermitteln (Fallback-Kette)
                let primaryDetailed = resolveDetailedMuscles(for: set, type: .primary)
                let secondaryDetailed = resolveDetailedMuscles(for: set, type: .secondary)

                // Primäre Muskeln → volle Gewichtung
                for muscle in primaryDetailed {
                    guard let regionId = muscle.svgRegionId else { continue }
                    volumeByRegion[regionId, default: 0] += volume
                    setsByRegion[regionId, default: 0] += 1
                    frequencyByRegion[regionId, default: []].insert(session.sessionUUID)
                    musclesByRegion[regionId, default: []].insert(muscle)
                    updateLastTrained(&lastTrainedByRegion, regionId: regionId, date: session.date)
                }

                // Sekundäre Muskeln → reduzierte Gewichtung (30%); Sets werden bewusst nicht gezählt (vermeidet Inflation)
                for muscle in secondaryDetailed {
                    guard let regionId = muscle.svgRegionId else { continue }
                    volumeByRegion[regionId, default: 0] += volume * 0.3
                    frequencyByRegion[regionId, default: []].insert(session.sessionUUID)
                    musclesByRegion[regionId, default: []].insert(muscle)
                    updateLastTrained(&lastTrainedByRegion, regionId: regionId, date: session.date)
                }
            }
        }

        // 3. Maxima für Normalisierung
        let maxVolume = volumeByRegion.values.max() ?? 1.0
        let maxSets = setsByRegion.values.max() ?? 1
        let maxFrequency = frequencyByRegion.values.map(\.count).max() ?? 1

        // 4. MuscleHeatData für alle SVG-Regionen erstellen
        let allSvgRegionIds = Set(DetailedMuscle.allCases.compactMap { $0.svgRegionId })
        var regionData: [String: MuscleHeatData] = [:]

        // Gewichtungskonstanten
        let weightVolume = 0.40
        let weightSets = 0.35
        let weightFrequency = 0.25

        for regionId in allSvgRegionIds {
            let volume = volumeByRegion[regionId] ?? 0
            let sets = setsByRegion[regionId] ?? 0
            let frequency = frequencyByRegion[regionId]?.count ?? 0

            // Normalisierte Faktoren (0.0–1.0)
            let normVolume = maxVolume > 0 ? volume / maxVolume : 0
            let normSets = Double(maxSets) > 0 ? Double(sets) / Double(maxSets) : 0
            let normFrequency = Double(maxFrequency) > 0 ? Double(frequency) / Double(maxFrequency) : 0

            // Composite Score (gewichtete Summe)
            let compositeScore = (normVolume * weightVolume)
                               + (normSets * weightSets)
                               + (normFrequency * weightFrequency)

            let contributing = Array(musclesByRegion[regionId] ?? [])

            regionData[regionId] = MuscleHeatData(
                id: regionId,
                svgRegionId: regionId,
                displayName: regionDisplayName(for: regionId),
                totalVolume: volume,
                totalSets: sets,
                totalFrequency: frequency,
                relativeIntensity: compositeScore,
                heatLevel: HeatLevel(relativeValue: compositeScore),
                lastTrainedDate: lastTrainedByRegion[regionId],
                contributingMuscles: contributing
            )
        }

        return MuscleHeatmapAnalysis(
            timeframe: timeframe,
            analysisDate: Date(),
            regionData: regionData,
            totalVolume: volumeByRegion.values.reduce(0, +),
            totalSets: setsByRegion.values.reduce(0, +),
            totalFrequency: maxFrequency
        )
    }

    // MARK: - Muscle Resolution (Fallback-Kette)

    private enum MuscleType { case primary, secondary }

    /// Ermittelt DetailedMuscles für ein ExerciseSet.
    /// Fallback-Kette:
    /// 1. exercise?.detailedPrimaryMuscles (feingranular, nach Enrichment)
    /// 2. exercise?.primaryMuscles → alle DetailedMuscle mit passendem parentGroup (grob)
    /// 3. ExerciseSet.primaryMuscleGroup (Name-basiert, letzter Fallback)
    private func resolveDetailedMuscles(for set: ExerciseSet, type: MuscleType) -> [DetailedMuscle] {
        // 1. Feingranulare Daten vorhanden?
        if let exercise = set.exercise {
            let detailed = type == .primary ? exercise.detailedPrimaryMuscles : exercise.detailedSecondaryMuscles
            if !detailed.isEmpty { return detailed }
        }

        // 2. Grobe MuscleGroup → alle passenden DetailedMuscle
        let muscleGroups: [MuscleGroup]
        if let exercise = set.exercise {
            muscleGroups = type == .primary ? exercise.primaryMuscles : exercise.secondaryMuscles
        } else {
            // 3. Letzter Fallback: MuscleGroupMapper über ExerciseName
            if type == .primary {
                muscleGroups = [set.primaryMuscleGroup].compactMap { $0 }
            } else {
                muscleGroups = set.secondaryMuscleGroups
            }
        }

        // MuscleGroup → alle zugehörigen DetailedMuscle
        return muscleGroups.flatMap { group in
            DetailedMuscle.allCases.filter { $0.parentGroup == group }
        }
    }

    // MARK: - Hilfsmethoden

    private func filterSessions(
        _ sessions: [StrengthSession],
        for timeframe: SummaryTimeframe
    ) -> [StrengthSession] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return sessions
        }

        return sessions.filter { $0.date >= startDate }
    }

    private func updateLastTrained(
        _ dict: inout [String: Date],
        regionId: String,
        date: Date
    ) {
        if let existing = dict[regionId] {
            if date > existing { dict[regionId] = date }
        } else {
            dict[regionId] = date
        }
    }

    /// Deutscher Name für eine SVG-Region
    private func regionDisplayName(for svgRegionId: String) -> String {
        let mapping: [String: String] = [
            "upper_pecs": "Obere Brust",
            "middle_pecs": "Mittlere Brust",
            "lower_pecs": "Untere Brust",
            "lats": "Latissimus",
            "upper_traps": "Oberer Trapez",
            "lower_traps": "Unterer Trapez",
            "rhomboids": "Rhomboideus",
            "lower_back": "Unterer Rücken",
            "front_delts": "Vordere Schulter",
            "side_delts": "Seitliche Schulter",
            "rear_delts": "Hintere Schulter",
            "biceps": "Bizeps",
            "triceps": "Trizeps",
            "forearms": "Unterarme",
            "quads": "Quadrizeps",
            "hamstrings": "Beinbeuger",
            "glutes": "Gesäß",
            "calves": "Waden",
            "hip_adductor": "Adduktoren",
            "hip_abductor": "Abduktoren",
            "upper_abs": "Obere Bauchmuskeln",
            "lower_abs": "Untere Bauchmuskeln",
            "obliques": "Seitliche Bauchmuskeln",
            "neck": "Nacken"
        ]
        return mapping[svgRegionId] ?? svgRegionId
    }
}
