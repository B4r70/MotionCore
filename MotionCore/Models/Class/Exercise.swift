//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Daten-Modell                                                     /
// Datei . . . . : Exercise.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.12.2025                                                       /
// Beschreibung  : Übungsdefinition für Krafttraining (Bibliothek)                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

@Model
final class Exercise {
    // MARK: - Grunddaten

    var name: String = ""                   // Name der Übung (z.B. "Bankdrücken")
    var exerciseDescription: String = ""    // Beschreibung/Ausführung
    var gifAssetName: String = ""           // Name des GIF-Assets
    var isCustom: Bool = false              // Vom Benutzer erstellt?
    var isFavorite: Bool = false            // Favorit markiert?
    var createdAt: Date = Date()            // Erstellungsdatum

    // MARK: - Persistente ENUM-Rohwerte

    var categoryRaw: String = "compound"
    var equipmentRaw: String = "barbell"
    var difficultyRaw: String = "intermediate"

    // MARK: - Muskelgruppen (als String-Arrays)

    var primaryMusclesRaw: [String] = []    // z.B. ["chest"]
    var secondaryMusclesRaw: [String] = []  // z.B. ["shoulders", "triceps"]

    // MARK: - Typisierte ENUM-Properties

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .compound }
        set { categoryRaw = newValue.rawValue }
    }

    var equipment: ExerciseEquipment {
        get { ExerciseEquipment(rawValue: equipmentRaw) ?? .barbell }
        set { equipmentRaw = newValue.rawValue }
    }

    var difficulty: ExerciseDifficulty {
        get { ExerciseDifficulty(rawValue: difficultyRaw) ?? .intermediate }
        set { difficultyRaw = newValue.rawValue }
    }

    var primaryMuscles: [MuscleGroup] {
        get { primaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { primaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    var secondaryMuscles: [MuscleGroup] {
        get { secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { secondaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    // MARK: - Berechnete Werte

    /// Alle trainierten Muskelgruppen (primär + sekundär)
    var allMuscles: [MuscleGroup] {
        Array(Set(primaryMuscles + secondaryMuscles))
    }

    /// Ist eine Ganzkörperübung?
    var isFullBody: Bool {
        allMuscles.contains(.fullBody)
    }

    /// Hat ein GIF?
    var hasGif: Bool {
        !gifAssetName.isEmpty
    }

    // MARK: - Initialisierung

    init(
        name: String = "",
        exerciseDescription: String = "",
        gifAssetName: String = "",
        category: ExerciseCategory = .compound,
        equipment: ExerciseEquipment = .barbell,
        difficulty: ExerciseDifficulty = .intermediate,
        primaryMuscles: [MuscleGroup] = [],
        secondaryMuscles: [MuscleGroup] = [],
        isCustom: Bool = false,
        isFavorite: Bool = false
    ) {
        self.name = name
        self.exerciseDescription = exerciseDescription
        self.gifAssetName = gifAssetName
        self.categoryRaw = category.rawValue
        self.equipmentRaw = equipment.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.primaryMusclesRaw = primaryMuscles.map { $0.rawValue }
        self.secondaryMusclesRaw = secondaryMuscles.map { $0.rawValue }
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }
}

