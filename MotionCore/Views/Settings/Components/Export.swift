//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hilftools                                                        /
// Datei . . . . : Export.swift                                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 01.11.2025                                                       /
// Beschreibung  : Exportfunktion für die erfassten Workouts                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Paket (für Versionierung & Metadaten)

struct ExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [WorkoutExportItem]
}

// MARK: - Einzelnes Workout (persistenzneutral)

struct WorkoutExportItem: Codable {
    let date: String? // ISO8601
    let duration: Int?
    let distance: Double?
    let calories: Int?
    let difficulty: Int?
    let heartRate: Int?
    let bodyWeight: Double?
    let intensity: Int? // Enum als rawValue (0...5)
    let trainingProgram: String? // Enum als rawValue ("manual", ...)
    let workoutDevice: Int?
}

// MARK: - Mapper zwischen Model und DTO

extension WorkoutSession {
    // → DTO (Export)
    var exportItem: WorkoutExportItem {
        // Wir verwenden nil, wenn der Wert 0 oder der Standardwert ist,
        // um das Feld beim Export wegzulassen. Das hält die JSON-Datei schlank.
        WorkoutExportItem( // KORRIGIERT: Muss WorkoutExportItem zurückgeben, nicht ExportPackage
            date: ISO8601DateFormatter().string(from: date),
            duration: duration > 0 ? duration : nil,
            distance: distance > 0 ? distance : nil,
            calories: calories > 0 ? calories : nil,
            difficulty: difficulty > 1 ? difficulty : nil, // Annahme: 1 ist der Standard
            heartRate: heartRate > 0 ? heartRate : nil,
            bodyWeight: bodyWeight > 0.0 ? bodyWeight : nil,

            // Enum rawValues können oft 0 sein, daher prüfen wir auf .none/Standard
            intensity: intensity != .none ? intensity.rawValue : nil,
            trainingProgram: trainingProgram != .manual ? trainingProgram.rawValue : nil,
            workoutDevice: workoutDevice != .none ? workoutDevice.rawValue : nil
        )
    }
    
    // ← DTO
    static func fromExportItem(_ e: WorkoutExportItem) -> WorkoutSession {
        let iso = ISO8601DateFormatter()

        return WorkoutSession(
            date: e.date.flatMap { iso.date(from: $0) } ?? .now,
            duration: e.duration ?? 0,
            distance: e.distance ?? 0.0,
            calories: e.calories ?? 0,
            difficulty: e.difficulty ?? 1,
            heartRate: e.heartRate ?? 0,
            bodyWeight: e.bodyWeight ?? 0.0,
            intensity: e.intensity.flatMap { Intensity(rawValue: $0) } ?? .none,
            trainingProgram: e.trainingProgram.flatMap { TrainingProgram(rawValue: $0) } ?? .manual,
            workoutDevice: e.workoutDevice.flatMap { WorkoutDevice(rawValue: $0) } ?? .none
        )
    }
}
