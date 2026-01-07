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
//                mets, trainingProgram) bleiben hier.                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData
import SwiftUI

// MARK: - Helper Types

// Summary for a given workout intensity.
struct IntensitySummary {
    let intensity: Intensity
    let count: Int
    let total: Int
}

// Generic trend point for charts (date/value pair).
// NEU: Wird jetzt auch von CoreSessionCalcEngine genutzt - Definition bleibt hier
// oder kann in eine separate Datei (z.B. ChartTypes.swift) verschoben werden
struct TrendPoint: Identifiable {
    let id = UUID()
    let trendDate: Date
    let trendValue: Double
}

// Generische Datenstruktur für Donut/Pie Charts
struct DonutChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

// Summary for training programs (Intern für Berechnung)
struct ProgramSummary: Identifiable {
    let id = UUID()
    let program: TrainingProgram
    let count: Int
}

// MARK: - Statistic Calculation Engine

struct StatisticCalcEngine {

    // Abruf aus Einstellungen der Körpergröße, Geschlecht und Alter
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Input

    // All workouts used as data source for the statistics.
    let allWorkouts: [CardioSession]

    // MARK: - NEU: CoreSessionCalcEngine für gemeinsame Berechnungen

    /// Delegiert gemeinsame Berechnungen an die generische CoreSessionCalcEngine.
    /// Nutzt lazy initialization für Performance.
    private var coreCalc: CoreSessionCalcEngine<CardioSession> {
        CoreSessionCalcEngine(sessions: allWorkouts)
    }

    // MARK: - Initializer

    init(workouts: [CardioSession]) {
        self.allWorkouts = workouts
    }

    // MARK: - Basic totals (NEU: Delegiert an CoreSessionCalcEngine)

    /// Summe aller Workouts
    /// NEU: Delegiert an coreCalc.totalSessions
    var totalWorkouts: Int {
        coreCalc.totalSessions
    }

    /// Summe aller verbrannter Kalorien
    /// NEU: Delegiert an coreCalc.totalCalories
    var totalCalories: Int {
        coreCalc.totalCalories
    }

    /// Gesamt-Distanz aller Workouts
    /// BLEIBT: Cardio-spezifisch (distance ist nicht in CoreSession)
    var totalDistance: Double {
        allWorkouts.reduce(0.0) { $0 + $1.distance }
    }

    /// Durchschnittliche Herzfrequenz
    /// NEU: Delegiert an coreCalc.averageHeartRate
    var averageHeartRate: Int {
        coreCalc.averageHeartRate
    }

    /// Durchschnittliche Workout-Zeit
    /// NEU: Delegiert an coreCalc.averageDuration
    var averageDuration: Int {
        coreCalc.averageDuration
    }

    /// Durchschnittliche metabolisches Äquivalent
    /// BLEIBT: Cardio-spezifisch (mets ist nicht in CoreSession)
    var averageMETS: Double {
        let relevantWorkouts = allWorkouts.filter { $0.mets > 0.0 }
        guard !relevantWorkouts.isEmpty else {
            return 0.0
        }
        let totalMETSValue = relevantWorkouts.reduce(0.0) { sum, workout in
            sum + workout.mets
        }
        return totalMETSValue / Double(relevantWorkouts.count)
    }

    /// Relative Kaloriendichte
    /// BLEIBT: Cardio-spezifisch (relativeCaloricDensity ist nicht in CoreSession)
    var averageCaloricDensity: Double {
        guard !allWorkouts.isEmpty else { return 0.0 }

        let totalDensity = allWorkouts.reduce(0.0) { sum, session in
            sum + session.relativeCaloricDensity
        }

        return totalDensity / Double(allWorkouts.count)
    }

    // MARK: - Device based calculations (Cardio-spezifisch)

    /// Number of workouts for a specific device.
    /// BLEIBT: Cardio-spezifisch (cardioDevice ist nicht in CoreSession)
    func workoutCountDevice(for device: CardioDevice) -> Int {
        allWorkouts.filter { $0.cardioDevice == device }.count
    }

    // MARK: - Intensity based calculations (NEU: Teilweise delegiert)

    /// Number of workouts for a specific intensity.
    /// NEU: Delegiert an coreCalc.sessionCount(for:)
    func intensityCount(_ intensity: Intensity) -> Int {
        coreCalc.sessionCount(for: intensity)
    }

    /// Summary (count + total) for a given intensity.
    func intensitySummary(for intensity: Intensity) -> IntensitySummary {
        // NEU: Nutzt coreCalc für count
        let count = coreCalc.sessionCount(for: intensity)
        let total = coreCalc.totalSessions

        return IntensitySummary(
            intensity: intensity,
            count: count,
            total: total
        )
    }

    /// Durchschnittliche Belastungsintensität in den Workouts
    /// NEU: Delegiert an coreCalc.averageIntensity
    var averageIntensity: Double {
        coreCalc.averageIntensity
    }

    // MARK: - Trend data for charts (NEU: Gemeinsame Trends delegiert)

    /// Heart rate trend over time (date vs. average heart rate).
    /// NEU: Delegiert an coreCalc.heartRateTrend
    var trendHeartRate: [TrendPoint] {
        coreCalc.heartRateTrend
    }

    /// Calories trend over time (date vs. calories).
    /// NEU: Delegiert an coreCalc.caloriesTrend
    var trendCalories: [TrendPoint] {
        coreCalc.caloriesTrend
    }

    /// Distanz sortiert nach Datum
    /// BLEIBT: Cardio-spezifisch (distance ist nicht in CoreSession)
    var trendDistance: [TrendPoint] {
        allWorkouts
            .filter { $0.distance > 0 }
            .sorted { $0.date < $1.date }
            .map { workout in
                TrendPoint(
                    trendDate: workout.date,
                    trendValue: workout.distance
                )
            }
    }

    // MARK: - Trends gerätespezifisch (Cardio-spezifisch)

    /// Distanz-Trend für ein bestimmtes Gerät
    /// BLEIBT: Cardio-spezifisch (cardioDevice, distance sind nicht in CoreSession)
    func trendDistanceDevice(for device: CardioDevice) -> [TrendPoint] {
        allWorkouts
            .filter { $0.cardioDevice == device }
            .filter { $0.distance > 0 }
            .sorted { $0.date < $1.date }
            .map { workout in
                TrendPoint(
                    trendDate: workout.date,
                    trendValue: workout.distance
                )
            }
    }

    /// Kaloriendichte für Chart
    /// BLEIBT: Cardio-spezifisch (relativeCaloricDensity ist nicht in CoreSession)
    var trendCaloricDensity: [(Date, Double)] {
        allWorkouts
            .sorted(by: { $0.date < $1.date })
            .map { ($0.date, $0.relativeCaloricDensity) }
    }

    // MARK: - Donut-Chart (Cardio-spezifisch)

    /// Berechnung für die verwendeten Programme je Workout
    /// BLEIBT: Cardio-spezifisch (trainingProgram ist nicht in CoreSession)
    var programDistribution: [ProgramSummary] {
        let grouped = Dictionary(grouping: allWorkouts, by: { $0.trainingProgram })
        return grouped.map { key, value in
            ProgramSummary(program: key, count: value.count)
        }.sorted { $0.count > $1.count }
    }

    /// Aufbereitung der Daten für Donut-Chart
    var programData: [DonutChartData] {
        programDistribution.map { summary in
            DonutChartData(
                label: summary.program.description,
                value: summary.count
            )
        }
    }

    // MARK: - NEU: Convenience für zeitbasierte Analysen

    /// Statistiken für diese Woche
    var thisWeek: CoreSessionCalcEngine<CardioSession> {
        coreCalc.thisWeek
    }

    /// Statistiken für diesen Monat
    var thisMonth: CoreSessionCalcEngine<CardioSession> {
        coreCalc.thisMonth
    }

    /// Statistiken für die letzten N Tage
    func lastDays(_ days: Int) -> CoreSessionCalcEngine<CardioSession> {
        coreCalc.lastDays(days)
    }
}
