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
        // MARK: - Input

        // All workouts used as data source for the statistics.
    let allWorkouts: [WorkoutSession]

        // MARK: - Initializer

    init(workouts: [WorkoutSession]) {
        self.allWorkouts = workouts
    }

        // MARK: - Basic totals

        // Total number of workouts.
    var totalWorkouts: Int {
        allWorkouts.count
    }

        // Total burned calories across all workouts.
    var totalCalories: Int {
        allWorkouts.reduce(0) { $0 + $1.calories }
    }

        /// Total distance across all workouts.
    var totalDistance: Double {
        allWorkouts.reduce(0.0) { $0 + $1.distance }
    }

        // Average heart rate across all workouts.
    var averageHeartRate: Int {
        let valid = allWorkouts.filter { $0.heartRate > 0 }
        guard !valid.isEmpty else { return 0 }

        let total = valid.reduce(0) { $0 + $1.heartRate }
        return total / valid.count
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

        // Distance trend over time (date vs. distance in km).
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
