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

    // Zusätzliche Felder
    var isUnilateral: Bool = false          // Unilateral (einseitig) oder bilateral?
    var repRangeMin: Int = 8                // Minimale Wiederholungen (z.B. 1 für Maximalkraft)
    var repRangeMax: Int = 12               // Maximale Wiederholungen (z.B. 12 für Hypertrophie)
    var sortIndex: Int = 0                  // Sortierungsindex (für automatische Reihenfolge)
    var cautionNote: String = ""            // Besondere Sicherheitshinweise
    var isArchived: Bool = false            // Archiviert statt gelöscht

    // MARK: - Persistente ENUM-Rohwerte

    var categoryRaw: String = "compound"
    var equipmentRaw: String = "barbell"
    var difficultyRaw: String = "intermediate"

    // Weitere Enum-Rohwerte
    var movementPatternRaw: String = "push"
    var bodyPositionRaw: String = "standing"

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

    // Typisierte Properties für neue Enums
    var movementPattern: MovementPattern {
        get { MovementPattern(rawValue: movementPatternRaw) ?? .push }
        set { movementPatternRaw = newValue.rawValue }
    }

    var bodyPosition: BodyPosition {
        get { BodyPosition(rawValue: bodyPositionRaw) ?? .standing }
        set { bodyPositionRaw = newValue.rawValue }
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

    // Alle trainierten Muskelgruppen (primär + sekundär)
    var allMuscles: [MuscleGroup] {
        Array(Set(primaryMuscles + secondaryMuscles))
    }

    // Ist eine Ganzkörperübung?
    var isFullBody: Bool {
        allMuscles.contains(.fullBody)
    }

    // Hat ein GIF?
    var hasGif: Bool {
        !gifAssetName.isEmpty
    }

    // Berechnete Werte für Rep-Range
    // Rep-Range als formatierter String
    var repRangeFormatted: String {
        "\(repRangeMin)-\(repRangeMax) Wdh."
    }

    // Trainingstyp basierend auf Rep-Range
    var trainingType: String {
        switch repRangeMax {
        case 1...3: return "Maximalkraft"
        case 4...6: return "Kraft"
        case 7...12: return "Hypertrophie"
        case 13...20: return "Kraftausdauer"
        default: return "Ausdauer"
        }
    }

    // MARK: - Initialisierung

    init(
        name: String = "",
        exerciseDescription: String = "",
        gifAssetName: String = "",
        category: ExerciseCategory = .compound,
        equipment: ExerciseEquipment = .barbell,
        difficulty: ExerciseDifficulty = .intermediate,
        movementPattern: MovementPattern = .push,
        bodyPosition: BodyPosition = .standing,
        primaryMuscles: [MuscleGroup] = [],
        secondaryMuscles: [MuscleGroup] = [],
        isCustom: Bool = false,
        isFavorite: Bool = false,
        isUnilateral: Bool = false,
        repRangeMin: Int = 8,
        repRangeMax: Int = 12,
        sortIndex: Int = 0,
        cautionNote: String = "",
        isArchived: Bool = false
    ) {
        self.name = name
        self.exerciseDescription = exerciseDescription
        self.gifAssetName = gifAssetName
        self.categoryRaw = category.rawValue
        self.equipmentRaw = equipment.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.movementPatternRaw = movementPattern.rawValue
        self.bodyPositionRaw = bodyPosition.rawValue
        self.primaryMusclesRaw = primaryMuscles.map { $0.rawValue }
        self.secondaryMusclesRaw = secondaryMuscles.map { $0.rawValue }
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.isUnilateral = isUnilateral
        self.repRangeMin = repRangeMin
        self.repRangeMax = repRangeMax
        self.sortIndex = sortIndex
        self.cautionNote = cautionNote
        self.isArchived = isArchived
        self.createdAt = Date()
    }
}
