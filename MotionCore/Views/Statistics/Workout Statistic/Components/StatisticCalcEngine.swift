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
    let allWorkouts: [WorkoutSession]

        // MARK: - Initializer

    init(workouts: [WorkoutSession]) {
        self.allWorkouts = workouts
    }

        // MARK: - Basic totals

    // Berechnung: Summe aller Workouts
    var totalWorkouts: Int {
        allWorkouts.count
    }

    // Berechnung: Summe aller verbrannter Kalorien
    var totalCalories: Int {
        allWorkouts.reduce(0) { $0 + $1.calories }
    }

    // Berechnung: Gesamt-Distanz aller Workouts
    var totalDistance: Double {
        allWorkouts.reduce(0.0) { $0 + $1.distance }
    }

    // Berechnung: Durchschnittliche Herzfrequenz
    var averageHeartRate: Int {
        let valid = allWorkouts.filter { $0.heartRate > 0 }
        guard !valid.isEmpty else { return 0 }

        let total = valid.reduce(0) { $0 + $1.heartRate }
        return total / valid.count
    }

    // Berechnung: Durchschnittliche Workout-Zeit
    var averageDuration: Int {
        let valid = allWorkouts.filter { $0.duration > 0 }
        guard !valid.isEmpty else { return 0 }

        let total = valid.reduce(0) { $0 + $1.duration }
        return total / valid.count
    }

    // Berechnung: Durchschnittliche metabolisches Äquivalent
    var averageMETS: Double {
            let relevantWorkouts = allWorkouts.filter { $0.mets > 0.0 }
            guard !relevantWorkouts.isEmpty else {
                return 0.0
            }
            let totalMETSValue = relevantWorkouts.reduce(0) { sum, workout in
                sum + workout.mets // Zugriff auf den numerischen Wert
            }
            return Double(totalMETSValue) / Double(relevantWorkouts.count)
        }

    // Berechnung: Relative Kaloriendichte
    var averageCaloricDensity: Double {
            guard !allWorkouts.isEmpty else { return 0.0 }

            // Summiere die relative Dichte aller Workouts
            let totalDensity = allWorkouts.reduce(0.0) { sum, session in
                sum + session.relativeCaloricDensity
            }

            // Teile durch die Anzahl der Workouts, um den Durchschnitt zu erhalten
            return totalDensity / Double(allWorkouts.count)
        }

        // MARK: - Device based calculations

        // Number of workouts for a specific device.
    func workoutCountDevice(for device: WorkoutDevice) -> Int {
        allWorkouts.filter { $0.workoutDevice == device }.count
    }

        // MARK: - Intensity based calculations

        // Number of workouts for a specific intensity.
    func intensityCount(_ intensity: Intensity) -> Int {
        allWorkouts.filter { $0.intensity == intensity }.count
    }

        // Summary (count + total) for a given intensity.
    func intensitySummary(for intensity: Intensity) -> IntensitySummary {
        let count = allWorkouts.filter { $0.intensity == intensity }.count
        let total = allWorkouts.count

        return IntensitySummary(
            intensity: intensity,
            count: count,
            total: total
        )
    }

    // Berechnung: Durchschnittliche Belastungsintensität in den Workouts
    var averageIntensity: Double {
        let relevantWorkouts = allWorkouts.filter { $0.intensity.rawValue > 0 }
        guard !relevantWorkouts.isEmpty else {
            return 0.0
        }
        let totalIntensityValue = relevantWorkouts.reduce(0) { sum, workout in
            sum + workout.intensity.rawValue // Zugriff auf den numerischen Wert
        }
        return Double(totalIntensityValue) / Double(relevantWorkouts.count)
    }

        // MARK: - Trend data for charts

        // Heart rate trend over time (date vs. average heart rate).
    var trendHeartRate: [TrendPoint] {
        allWorkouts
            .filter { $0.heartRate > 0 }
            .sorted { $0.date < $1.date }
            .map { workout in
                TrendPoint(
                    trendDate: workout.date,
                    trendValue: Double(workout.heartRate)
                )
            }
    }

        // Calories trend over time (date vs. calories).
    var trendCalories: [TrendPoint] {
        allWorkouts
            .filter { $0.calories > 0 }
            .sorted { $0.date < $1.date }
            .map { workout in
                TrendPoint(
                    trendDate: workout.date,
                    trendValue: Double(workout.calories)
                )
            }
    }

    // Berechnung: Distanz sortiert nach Datum
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

    // MARK: Trends gerätespezifisch

    func trendDistanceDevice(for device: WorkoutDevice) -> [TrendPoint] {
        allWorkouts
            .filter { $0.workoutDevice == device }
            .filter { $0.distance > 0 }
            .sorted { $0.date < $1.date }
            .map { workout in
                TrendPoint(
                    trendDate: workout.date,
                    trendValue: workout.distance
                )
            }
    }

    // Berechnung: Kaloriendichte für Chart
    var trendCaloricDensity: [(Date, Double)] {
        allWorkouts
            .sorted(by: { $0.date < $1.date })
            .map { ($0.date, $0.relativeCaloricDensity) }
    }

        // MARK: Donut-Chart

        // Berechnung für die verwendeten Programme je Workout
    var programDistribution: [ProgramSummary] {
        let grouped = Dictionary(grouping: allWorkouts, by: { $0.trainingProgram })
        return grouped.map { key, value in
            ProgramSummary(program: key, count: value.count)
        }.sorted { $0.count > $1.count } // Meistgenutzte zuerst
    }
    
        // Aufbereitung der Daten für Donut-Chart
    var programData: [DonutChartData] {
        programDistribution.map { summary in
            DonutChartData(
                label: summary.program.description,
                value: summary.count
            )
        }
    }
}
