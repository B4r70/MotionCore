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

struct WorkoutExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [WorkoutExportItem]
}

// MARK: - Export-Paket für Trainingsübungen
struct ExerciseExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [ExerciseExportItem]
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
    let cardioDevice: Int?
}

// MARK: Trainingsübungen (persistenzneutral)
struct ExerciseExportItem: Codable {
    let name: String
    let exerciseDescription: String?
    let gifAssetName: String?
    let category: String // Enum rawValue
    let equipment: String // Enum rawValue
    let difficulty: String // Enum rawValue
    let primaryMuscles: [String] // Array of rawValues
    let secondaryMuscles: [String] // Array of rawValues
    let isFavorite: Bool
    let isCustom: Bool
}

// MARK: - Mapper zwischen Model und DTO
// CardioSession
extension CardioSession {
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
            cardioDevice: cardioDevice != .none ? cardioDevice.rawValue : nil
        )
    }
    
    // ← DTO
    static func fromExportItem(_ e: WorkoutExportItem) -> CardioSession {
        let iso = ISO8601DateFormatter()

        return CardioSession(
            date: e.date.flatMap { iso.date(from: $0) } ?? .now,
            duration: e.duration ?? 0,
            distance: e.distance ?? 0.0,
            calories: e.calories ?? 0,
            difficulty: e.difficulty ?? 1,
            heartRate: e.heartRate ?? 0,
            bodyWeight: e.bodyWeight ?? 0.0,
            intensity: e.intensity.flatMap { Intensity(rawValue: $0) } ?? .none,
            trainingProgram: e.trainingProgram.flatMap { TrainingProgram(rawValue: $0) } ?? .manual,
            cardioDevice: e.cardioDevice.flatMap { CardioDevice(rawValue: $0) } ?? .none
        )
    }
}

// Trainingsübungen
extension Exercise {
    // DTO (Export)
    var exportItem: ExerciseExportItem {
        ExerciseExportItem(
            name: name,
            exerciseDescription: exerciseDescription.isEmpty ? nil : exerciseDescription,
            gifAssetName: gifAssetName.isEmpty ? nil : gifAssetName,
            category: category.rawValue,
            equipment: equipment.rawValue,
            difficulty: difficulty.rawValue,
            primaryMuscles: primaryMuscles.map { $0.rawValue },
            secondaryMuscles: secondaryMuscles.map { $0.rawValue },
            isFavorite: isFavorite,
            isCustom: isCustom
        )
    }

    // DTO (Import)
    static func fromExportItem(_ e: ExerciseExportItem) -> Exercise {
        Exercise(
            name: e.name,
            exerciseDescription: e.exerciseDescription ?? "",
            gifAssetName: e.gifAssetName ?? "",
            category: ExerciseCategory(rawValue: e.category) ?? .compound,
            equipment: ExerciseEquipment(rawValue: e.equipment) ?? .barbell,
            difficulty: ExerciseDifficulty(rawValue: e.difficulty) ?? .intermediate,
            primaryMuscles: e.primaryMuscles.compactMap { MuscleGroup(rawValue: $0) },
            secondaryMuscles: e.secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) },
            isCustom: e.isCustom,
            isFavorite: e.isFavorite
        )
    }
}






