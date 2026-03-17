//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticCalcEngine.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Zentrale Berechnungen für die Statistikanzeige                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Gemeinsame Berechnungen werden an CoreSessionCalcEngine           /
//                delegiert. Cardio-spezifische Berechnungen (distance, cardioDevice,/
//                mets, trainingProgram) bleiben hier. Typübergreifende KPIs         /
//                (totalWorkoutsAll, totalCaloriesAll, etc.) berechnen über alle    /
//                drei Session-Typen.                                               /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData
import SwiftUI

// MARK: - Helper Types

// Zusammenfassung einer Belastungsintensität.
struct IntensitySummary {
    let intensity: Intensity
    let count: Int
    let total: Int
}

// Generischer Trend-Punkt für Charts (Datum/Wert-Paar).
// Definition bleibt hier — wird auch von CoreSessionCalcEngine genutzt.
struct TrendPoint: Identifiable {
    let id = UUID()
    let trendDate: Date
    let trendValue: Double
}

// Generische Datenstruktur für Donut/Pie Charts.
struct DonutChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

// Zusammenfassung eines Trainingsprogramms (intern für Berechnung).
struct ProgramSummary: Identifiable {
    let id = UUID()
    let program: TrainingProgram
    let count: Int
}

// MARK: - Statistic Calculation Engine

struct StatisticCalcEngine {

    // MARK: - Input (alle drei Session-Typen)

    let allCardioSessions: [CardioSession]
    let allStrengthSessions: [StrengthSession]
    let allOutdoorSessions: [OutdoorSession]

    // MARK: - Initializer

    init(
        cardioSessions: [CardioSession],
        strengthSessions: [StrengthSession],
        outdoorSessions: [OutdoorSession]
    ) {
        self.allCardioSessions = cardioSessions
        self.allStrengthSessions = strengthSessions
        self.allOutdoorSessions = outdoorSessions
    }

    // MARK: - Timeframe-Filter

    /// Gibt eine neue Engine zurück, deren Sessions auf den gewählten Zeitraum gefiltert sind.
    func filtered(by timeframe: SummaryTimeframe) -> StatisticCalcEngine {
        let now = Date()
        let calendar = Calendar.current

        // Startdatum für den Zeitraum — nil bedeutet "Alle" (kein Filter)
        let startDate: Date?
        switch timeframe {
        case .week:  startDate = calendar.date(byAdding: .day,   value: -7,  to: now)
        case .month: startDate = calendar.date(byAdding: .month, value: -1,  to: now)
        case .year:  startDate = calendar.date(byAdding: .year,  value: -1,  to: now)
        case .all:   startDate = nil
        }

        guard let start = startDate else { return self }

        return StatisticCalcEngine(
            cardioSessions:   allCardioSessions.filter   { $0.date >= start },
            strengthSessions: allStrengthSessions.filter { $0.date >= start },
            outdoorSessions:  allOutdoorSessions.filter  { $0.date >= start }
        )
    }

    // MARK: - Interne Delegate-Engines

    private var coreCalc: CoreSessionCalcEngine<CardioSession> {
        CoreSessionCalcEngine(sessions: allCardioSessions)
    }

    private var strengthCalc: StrengthStatisticCalcEngine {
        StrengthStatisticCalcEngine(sessions: allStrengthSessions)
    }

    // MARK: - Typübergreifende KPIs

    /// Gesamtanzahl aller Workouts (Cardio + Kraft + Outdoor).
    var totalWorkoutsAll: Int {
        allCardioSessions.count + allStrengthSessions.count + allOutdoorSessions.count
    }

    /// Gesamtkalorien über alle Workout-Typen.
    var totalCaloriesAll: Int {
        allCardioSessions.reduce(0) { $0 + $1.calories }
        + allStrengthSessions.reduce(0) { $0 + $1.calories }
        + allOutdoorSessions.reduce(0) { $0 + $1.calories }
    }

    /// Gewichteter Durchschnitt der Herzfrequenz über alle Typen (nur Sessions mit HR > 0).
    var averageHeartRateAll: Int {
        let cardioWithHR = allCardioSessions.filter { $0.heartRate > 0 }
        let strengthWithHR = allStrengthSessions.filter { $0.heartRate > 0 }
        let outdoorWithHR = allOutdoorSessions.filter { $0.heartRate > 0 }
        let count = cardioWithHR.count + strengthWithHR.count + outdoorWithHR.count
        guard count > 0 else { return 0 }
        let total = cardioWithHR.reduce(0) { $0 + $1.heartRate }
                  + strengthWithHR.reduce(0) { $0 + $1.heartRate }
                  + outdoorWithHR.reduce(0) { $0 + $1.heartRate }
        return total / count
    }

    /// Durchschnittliche Trainingsdauer über alle Workout-Typen in Minuten.
    var averageDurationAll: Int {
        let count = totalWorkoutsAll
        guard count > 0 else { return 0 }
        let total = allCardioSessions.reduce(0) { $0 + $1.duration }
                  + allStrengthSessions.reduce(0) { $0 + $1.duration }
                  + allOutdoorSessions.reduce(0) { $0 + $1.duration }
        return total / count
    }

    /// Gesamtdistanz über Cardio- und Outdoor-Sessions in Kilometern.
    var totalDistanceAll: Double {
        allCardioSessions.reduce(0.0) { $0 + $1.distance }
        + allOutdoorSessions.reduce(0.0) { $0 + $1.distance }
    }

    // MARK: - Kraft-spezifische KPIs (delegiert an StrengthStatisticCalcEngine)

    /// Gesamtvolumen aller Kraft-Sessions.
    var totalStrengthVolume: Double { strengthCalc.totalVolume }

    /// Durchschnittliches Volumen pro Kraft-Session.
    var averageStrengthVolumePerSession: Double { strengthCalc.averageVolumePerSession }

    /// Gesamtanzahl der Sätze über alle Kraft-Sessions.
    var totalStrengthSets: Int {
        allStrengthSessions.reduce(0) { $0 + $1.totalSets }
    }

    /// Durchschnittliche Sätze pro Kraft-Session.
    var averageStrengthSetsPerSession: Double { strengthCalc.averageSetsPerSession }

    /// Volumen-Trend für Charts.
    var strengthVolumeTrend: [TrendPoint] { strengthCalc.volumeTrend }

    /// Alle trainierten Übungsnamen (unique, sortiert) für den 1RM-Chart.
    var allTrainedExerciseNames: [String] { strengthCalc.allTrainedExerciseNames }

    // MARK: - Cardio-spezifische KPIs (delegiert an CoreSessionCalcEngine)

    /// Gesamtanzahl aller Cardio-Workouts.
    var totalWorkouts: Int { coreCalc.totalSessions }

    /// Gesamtkalorien aller Cardio-Workouts.
    var totalCalories: Int { coreCalc.totalCalories }

    /// Durchschnittliche Herzfrequenz aller Cardio-Workouts.
    var averageHeartRate: Int { coreCalc.averageHeartRate }

    /// Durchschnittliche Dauer aller Cardio-Workouts.
    var averageDuration: Int { coreCalc.averageDuration }

    /// Durchschnittliche Belastungsintensität (Cardio).
    var averageIntensity: Double { coreCalc.averageIntensity }

    /// Gesamtdistanz aller Cardio-Workouts.
    var totalDistance: Double {
        allCardioSessions.reduce(0.0) { $0 + $1.distance }
    }

    /// Durchschnittliches metabolisches Äquivalent (Cardio-spezifisch).
    var averageMETS: Double {
        let relevant = allCardioSessions.filter { $0.mets > 0.0 }
        guard !relevant.isEmpty else { return 0.0 }
        return relevant.reduce(0.0) { $0 + $1.mets } / Double(relevant.count)
    }

    /// Relative Kaloriendichte zum Körpergewicht (Cardio-spezifisch).
    var averageCaloricDensity: Double {
        guard !allCardioSessions.isEmpty else { return 0.0 }
        return allCardioSessions.reduce(0.0) { $0 + $1.relativeCaloricDensity }
            / Double(allCardioSessions.count)
    }

    // MARK: - Gerätebasierte Berechnungen (Cardio-spezifisch)

    /// Anzahl Workouts für ein bestimmtes Cardio-Gerät.
    func workoutCountDevice(for device: CardioDevice) -> Int {
        allCardioSessions.filter { $0.cardioDevice == device }.count
    }

    // MARK: - Intensitätsbasierte Berechnungen

    /// Anzahl Workouts für eine bestimmte Intensität (Cardio).
    func intensityCount(_ intensity: Intensity) -> Int {
        coreCalc.sessionCount(for: intensity)
    }

    /// Zusammenfassung (Anzahl + Gesamt) für eine Intensitätsstufe (Cardio).
    func intensitySummary(for intensity: Intensity) -> IntensitySummary {
        IntensitySummary(
            intensity: intensity,
            count: coreCalc.sessionCount(for: intensity),
            total: coreCalc.totalSessions
        )
    }

    // MARK: - Trend-Daten für Charts

    /// Herzfrequenz-Trend über Zeit (Cardio).
    var trendHeartRate: [TrendPoint] { coreCalc.heartRateTrend }

    /// Kalorien-Trend über Zeit (Cardio).
    var trendCalories: [TrendPoint] { coreCalc.caloriesTrend }

    /// Distanz-Trend für ein bestimmtes Cardio-Gerät.
    func trendDistanceDevice(for device: CardioDevice) -> [TrendPoint] {
        allCardioSessions
            .filter { $0.cardioDevice == device && $0.distance > 0 }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(trendDate: $0.date, trendValue: $0.distance) }
    }
}
