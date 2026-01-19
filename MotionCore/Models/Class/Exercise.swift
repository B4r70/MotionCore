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
    var name: String = ""
    var exerciseDescription: String = ""
    var mediaAssetName: String = ""
    var isCustom: Bool = false
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var isUnilateral: Bool = false
    var repRangeMin: Int = 0
    var repRangeMax: Int = 0
    var sortIndex: Int = 0
    var cautionNote: String = ""
    var isArchived: Bool = false

    var apiID: UUID?
    var isSystemExercise: Bool = false

    var videoPath: String?
    var posterPath: String?
    var instructions: String?
    var localVideoFileName: String?

    var apiBodyPart: String?
    var apiTarget: String?
    var apiEquipment: String?
    var apiSecondaryMuscles: [String]?

    var apiOverview: String?
    var apiExerciseTips: [String]?
    var apiVariations: [String]?
    var apiImageURL: String?
    var apiProvider: String?

    var categoryRaw: String = ""
    var equipmentRaw: String = ""
    var difficultyRaw: String = ""
    var movementPatternRaw: String = ""
    var bodyPositionRaw: String = ""
    var primaryMusclesRaw: [String] = []
    var secondaryMusclesRaw: [String] = []

    @Relationship(deleteRule: .nullify, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet]? = []

    init(
        name: String = "",
        exerciseDescription: String = "",
        mediaAssetName: String = "",
        isCustom: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        isUnilateral: Bool = false,
        repRangeMin: Int = 8,
        repRangeMax: Int = 12,
        sortIndex: Int = 0,
        cautionNote: String = "",
        isArchived: Bool = false,
        apiID: UUID? = nil,
        isSystemExercise: Bool = false,
        videoPath: String? = nil,
        posterPath: String? = nil,
        instructions: String? = nil,
        localVideoFileName: String? = nil,
        apiBodyPart: String? = nil,
        apiTarget: String? = nil,
        apiEquipment: String? = nil,
        apiSecondaryMuscles: [String]? = nil,
        apiProvider: String? = nil,
        apiOverview: String? = nil,
        apiExerciseTips: [String]? = nil,
        apiVariations: [String]? = nil,
        apiImageURL: String? = nil,
        categoryRaw: String = "",
        equipmentRaw: String = "",
        difficultyRaw: String = "",
        movementPatternRaw: String = "",
        bodyPositionRaw: String = "",
        primaryMusclesRaw: [String] = [],
        secondaryMusclesRaw: [String] = []
    ) {
        self.name = name
        self.exerciseDescription = exerciseDescription
        self.mediaAssetName = mediaAssetName
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.isUnilateral = isUnilateral
        self.repRangeMin = repRangeMin
        self.repRangeMax = repRangeMax
        self.sortIndex = sortIndex
        self.cautionNote = cautionNote
        self.isArchived = isArchived

        self.apiID = apiID
        self.isSystemExercise = isSystemExercise

        self.videoPath = videoPath
        self.posterPath = posterPath
        self.instructions = instructions
        self.localVideoFileName = localVideoFileName

        self.apiBodyPart = apiBodyPart
        self.apiTarget = apiTarget
        self.apiEquipment = apiEquipment
        self.apiSecondaryMuscles = apiSecondaryMuscles

        self.apiProvider = apiProvider
        self.apiOverview = apiOverview
        self.apiExerciseTips = apiExerciseTips
        self.apiVariations = apiVariations
        self.apiImageURL = apiImageURL

        self.categoryRaw = categoryRaw
        self.equipmentRaw = equipmentRaw
        self.difficultyRaw = difficultyRaw
        self.movementPatternRaw = movementPatternRaw
        self.bodyPositionRaw = bodyPositionRaw
        self.primaryMusclesRaw = primaryMusclesRaw
        self.secondaryMusclesRaw = secondaryMusclesRaw
    }
}

// MARK: - Computed Properties

extension Exercise {
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

    var allMuscles: [MuscleGroup] {
        Array(Set(primaryMuscles + secondaryMuscles))
    }

    var isFullBody: Bool {
        allMuscles.contains(.fullBody)
    }

    var hasMedia: Bool {
        !mediaAssetName.isEmpty || videoPath != nil
    }

    var hasRemoteVideo: Bool {
        guard let p = videoPath else { return false }
        return !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasLocalVideo: Bool {
        localVideoFileName != nil
    }

    var bestVideoSource: String? {
        if let localFile = localVideoFileName {
            return localFile
        }
        return videoPath
    }

    var repRangeFormatted: String {
        "\(repRangeMin)-\(repRangeMax) Wdh."
    }

    var trainingType: String {
        switch repRangeMax {
        case 1...3: return "Maximalkraft"
        case 4...6: return "Kraft"
        case 7...12: return "Hypertrophie"
        case 13...20: return "Kraftausdauer"
        default: return "Ausdauer"
        }
    }

    var sourceLabel: String {
        if let provider = apiProvider {
            switch provider {
            case "supabase": return "Supabase"
            case "rapidapi", "exercisedb_v2": return "ExerciseDB"
            default: return "API"
            }
        } else if isSystemExercise {
            return "System"
        } else if isCustom {
            return "Eigene Übung"
        } else {
            return "Standard"
        }
    }

    var fullDescription: String {
        var parts: [String] = []

        if !exerciseDescription.isEmpty {
            parts.append(exerciseDescription)
        }

        if let apiInstructions = instructions, !apiInstructions.isEmpty {
            parts.append(apiInstructions)
        }

        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Convenience Initializer (Enum-basiert)

extension Exercise {
    convenience init(
        name: String = "",
        exerciseDescription: String = "",
        mediaAssetName: String = "",
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
        isArchived: Bool = false,
        apiID: UUID? = nil,
        isSystemExercise: Bool = false,
        videoPath: String? = nil,
        posterPath: String? = nil,
        instructions: String? = nil,
        localVideoFileName: String? = nil,
        apiBodyPart: String? = nil,
        apiTarget: String? = nil,
        apiEquipment: String? = nil,
        apiSecondaryMuscles: [String]? = nil,
        apiProvider: String? = nil,
        apiOverview: String? = nil,
        apiExerciseTips: [String]? = nil,
        apiVariations: [String]? = nil,
        apiImageURL: String? = nil
    ) {
        self.init(
            name: name,
            exerciseDescription: exerciseDescription,
            mediaAssetName: mediaAssetName,
            isCustom: isCustom,
            isFavorite: isFavorite,
            createdAt: Date(),
            isUnilateral: isUnilateral,
            repRangeMin: repRangeMin,
            repRangeMax: repRangeMax,
            sortIndex: sortIndex,
            cautionNote: cautionNote,
            isArchived: isArchived,
            apiID: apiID,
            isSystemExercise: isSystemExercise,
            videoPath: videoPath,
            posterPath: posterPath,
            instructions: instructions,
            localVideoFileName: localVideoFileName,
            apiBodyPart: apiBodyPart,
            apiTarget: apiTarget,
            apiEquipment: apiEquipment,
            apiSecondaryMuscles: apiSecondaryMuscles,
            apiProvider: apiProvider,
            apiOverview: apiOverview,
            apiExerciseTips: apiExerciseTips,
            apiVariations: apiVariations,
            apiImageURL: apiImageURL,
            categoryRaw: category.rawValue,
            equipmentRaw: equipment.rawValue,
            difficultyRaw: difficulty.rawValue,
            movementPatternRaw: movementPattern.rawValue,
            bodyPositionRaw: bodyPosition.rawValue,
            primaryMusclesRaw: primaryMuscles.map { $0.rawValue },
            secondaryMusclesRaw: secondaryMuscles.map { $0.rawValue }
        )
    }
}

// MARK: - Supabase Import

extension Exercise {
    convenience init(from supabase: SupabaseExercise) {
        let displayName = supabase.name
        let instructionsText = supabase.instructions ?? ""
        let tipsText = supabase.tips ?? ""

        let primaryMusclesList = supabase.primaryMuscles.compactMap {
            MuscleGroupMapper.map(supabaseValue: $0)
        }
        let secondaryMusclesList = supabase.secondaryMuscles.compactMap {
            MuscleGroupMapper.map(supabaseValue: $0)
        }

        let primaryMusclesRaw = primaryMusclesList.map { $0.rawValue }
        let secondaryMusclesRaw = secondaryMusclesList.map { $0.rawValue }

        let equipmentEnum = ExerciseEquipment.fromSupabase(supabase.equipment.first)
        let equipmentRaw = equipmentEnum.rawValue

        let difficultyEnum = ExerciseDifficulty.fromSupabase(supabase.difficulty ?? "intermediate")
        let difficultyRaw = difficultyEnum.rawValue

        let categoryEnum = ExerciseCategory.fromSupabase(
            mechanic: supabase.mechanicType,
            force: supabase.forceType
        )
        let categoryRaw = categoryEnum.rawValue

        let videoPath: String? = supabase.videoPath
        let posterPath: String? = supabase.posterPath

        self.init(
            name: displayName,
            exerciseDescription: tipsText,
            mediaAssetName: "",
            isCustom: false,
            isFavorite: false,
            createdAt: Date(),
            isUnilateral: false,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: 0,
            cautionNote: "",
            isArchived: false,
            apiID: supabase.id,
            isSystemExercise: true,
            videoPath: videoPath,
            posterPath: posterPath,
            instructions: instructionsText,
            localVideoFileName: nil,
            apiBodyPart: nil,
            apiTarget: nil,
            apiEquipment: nil,
            apiSecondaryMuscles: nil,
            apiProvider: "supabase",
            apiOverview: tipsText,
            apiExerciseTips: nil,
            apiVariations: nil,
            apiImageURL: nil,
            categoryRaw: categoryRaw,
            equipmentRaw: equipmentRaw,
            difficultyRaw: difficultyRaw,
            movementPatternRaw: "push",
            bodyPositionRaw: "standing",
            primaryMusclesRaw: primaryMusclesRaw,
            secondaryMusclesRaw: secondaryMusclesRaw
        )
    }
}

// MARK: - Methods

extension Exercise {
    func markVideoAsCached(fileName: String) {
        self.localVideoFileName = fileName
    }

    func clearLocalVideo() {
        self.localVideoFileName = nil
    }

    func matchesSearch(_ searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }

        let lowercasedSearch = searchText.lowercased()

        if name.lowercased().contains(lowercasedSearch) {
            return true
        }

        if exerciseDescription.lowercased().contains(lowercasedSearch) {
            return true
        }

        if primaryMusclesRaw.contains(where: { $0.lowercased().contains(lowercasedSearch) }) {
            return true
        }

        if secondaryMusclesRaw.contains(where: { $0.lowercased().contains(lowercasedSearch) }) {
            return true
        }

        return false
    }

    func trainsMuscle(_ muscle: MuscleGroup) -> Bool {
        return primaryMuscles.contains(muscle) || secondaryMuscles.contains(muscle)
    }

    func usesEquipment(_ eq: ExerciseEquipment) -> Bool {
        return equipment == eq
    }
}

extension Exercise {
    var remoteVideoPublicURL: URL? {
        guard let path = videoPath, !path.isEmpty else { return nil }
        return SupabaseStorageURLBuilder.publicURL(bucket: .exerciseVideos, path: path)
    }

    var posterPublicURL: URL? {
        guard let path = posterPath, !path.isEmpty else { return nil }
        return SupabaseStorageURLBuilder.publicURL(bucket: .exercisePosters, path: path)
    }
}
extension Exercise {
    var safeSets: [ExerciseSet] {
        sets ?? []
    }
}
