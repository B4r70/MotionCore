//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutExportPackage.swift                                       /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout List View                                                /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//

import Foundation

// MARK: - Paket (für Versionierung & Metadaten)
struct WorkoutExportPackage: Codable {
    let version: Int
    let exportedAt: String   // ISO8601
    let items: [WorkoutExportItem]
}

// MARK: - Einzelnes Workout (persistenzneutral)
struct WorkoutExportItem: Codable {
    let date: String             // ISO8601
    let duration: Int
    let distance: Double
    let calories: Int
    let difficulty: Int
    let heartRate: Int
    let bodyWeight: Int
    let intensity: Int           // Enum als rawValue (0...5)
    let trainingProgram: String  // Enum als rawValue ("manual", ...)
}

// MARK: - Mapper zwischen Model und DTO
extension WorkoutSession {
    // → DTO
    var exportItem: WorkoutExportItem {
        WorkoutExportItem(
            date: ISO8601DateFormatter().string(from: date),
            duration: duration,
            distance: distance,
            calories: calories,
            difficulty: difficulty,
            heartRate: heartRate,
            bodyWeight: bodyWeight,
            intensity: intensity.rawValue,
            trainingProgram: trainingProgram.rawValue
        )
    }

    // ← DTO
    static func fromExportItem(_ e: WorkoutExportItem) -> WorkoutSession {
        let iso = ISO8601DateFormatter()
        return WorkoutSession(
            date: iso.date(from: e.date) ?? .now,
            duration: e.duration,
            distance: e.distance,
            calories: e.calories,
            difficulty: e.difficulty,
            heartRate: e.heartRate,
            bodyWeight: e.bodyWeight,
            intensity: Intensity(rawValue: e.intensity) ?? .none,
            trainingProgram: TrainingProgram(rawValue: e.trainingProgram) ?? .manual
        )
    }
}
