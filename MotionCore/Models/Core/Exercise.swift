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
    var progressionStep: Double = 2.5    // Progressionsschritt in kg (z.B. 2.5 oder 5.0)

    // MARK: - Progressions-Konfiguration
    var targetRIR: Int = 2                              // Ziel-RIR für Progressions-Analyse
    var progressionSessionsRequired: Int = 2            // Konsistente Sessions bis zur Empfehlung
    var progressionStrategyRaw: String = "double"       // ProgressionStrategy Raw-Value
    var customProgressionStep: Double? = nil            // Überschreibt automatischen Step (nil = Auto)
    var minDaysBetweenProgressions: Int = 7             // Cooldown zwischen Steigerungen
    var lastProgressionDate: Date? = nil                // Datum der letzten Gewichtssteigerung

    // MARK: - Smart-Progression (v1.1)

    /// Soft-Link auf StudioEquipment.id (keine @Relationship, um CloudKit-Inverse-Zwang zu vermeiden)
    var studioEquipmentID: UUID? = nil

    /// Überschreibt repRangeMin/Max als expliziter Ziel-Wert (optional)
    var customTargetReps: Int? = nil

    /// Rohwert für CloudKit-Kompatibilität (String statt Enum)
    var progressionModeRaw: String = "smart"

    /// Freitext-Notiz, z.B. Geräte-spezifische Einstellung
    var configNotes: String = ""

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

    // Feingranulare Muskeldaten (DetailedMuscle rawValues = Supabase-Identifier)
    // Diese Felder werden bei zukünftigen Imports und durch In-Place Enrichment befüllt.
    // Bestehende Exercises haben hier [] — der Fallback auf primaryMusclesRaw greift dann.
    var detailedPrimaryMusclesRaw: [String] = []
    var detailedSecondaryMusclesRaw: [String] = []

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
        progressionStep: Double = 2.5,
        targetRIR: Int = 2,
        progressionSessionsRequired: Int = 2,
        progressionStrategyRaw: String = "double",
        customProgressionStep: Double? = nil,
        minDaysBetweenProgressions: Int = 7,
        lastProgressionDate: Date? = nil,
        studioEquipmentID: UUID? = nil,
        customTargetReps: Int? = nil,
        progressionModeRaw: String = "smart",
        configNotes: String = "",
        sortIndex: Int = 0,
        cautionNote: String = "",
        isArchived: Bool = false,
        apiID: UUID? = nil,
        isSystemExercise: Bool = false,
        videoPath: String? = nil,
        posterPath: String? = nil,
        instructions: String? = nil,
        localVideoFileName: String? = nil,
        categoryRaw: String = "",
        equipmentRaw: String = "",
        difficultyRaw: String = "",
        movementPatternRaw: String = "",
        bodyPositionRaw: String = "",
        primaryMusclesRaw: [String] = [],
        secondaryMusclesRaw: [String] = [],
        detailedPrimaryMusclesRaw: [String] = [],
        detailedSecondaryMusclesRaw: [String] = []
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
        self.progressionStep = progressionStep
        self.targetRIR = targetRIR
        self.progressionSessionsRequired = progressionSessionsRequired
        self.progressionStrategyRaw = progressionStrategyRaw
        self.customProgressionStep = customProgressionStep
        self.minDaysBetweenProgressions = minDaysBetweenProgressions
        self.lastProgressionDate = lastProgressionDate
        self.studioEquipmentID = studioEquipmentID
        self.customTargetReps = customTargetReps
        self.progressionModeRaw = progressionModeRaw
        self.configNotes = configNotes
        self.sortIndex = sortIndex
        self.cautionNote = cautionNote
        self.isArchived = isArchived

        self.apiID = apiID
        self.isSystemExercise = isSystemExercise

        self.videoPath = videoPath
        self.posterPath = posterPath
        self.instructions = instructions
        self.localVideoFileName = localVideoFileName

        self.categoryRaw = categoryRaw
        self.equipmentRaw = equipmentRaw
        self.difficultyRaw = difficultyRaw
        self.movementPatternRaw = movementPatternRaw
        self.bodyPositionRaw = bodyPositionRaw
        self.primaryMusclesRaw = primaryMusclesRaw
        self.secondaryMusclesRaw = secondaryMusclesRaw
        self.detailedPrimaryMusclesRaw = detailedPrimaryMusclesRaw
        self.detailedSecondaryMusclesRaw = detailedSecondaryMusclesRaw
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
        get {
            // Bevorzugt: Aus DetailedMuscle ableiten (feingranular → grob)
            if !detailedPrimaryMusclesRaw.isEmpty {
                return Array(Set(detailedPrimaryMuscles.map { $0.parentGroup })).sorted { $0.rawValue < $1.rawValue }
            }
            // Fallback: Alte Daten direkt lesen (bestehende Exercises)
            return primaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            primaryMusclesRaw = newValue.map { $0.rawValue }
            // Detaillierte Daten leeren, damit der Getter nicht veraltete Werte bevorzugt
            detailedPrimaryMusclesRaw = []
        }
    }

    var secondaryMuscles: [MuscleGroup] {
        get {
            if !detailedSecondaryMusclesRaw.isEmpty {
                return Array(Set(detailedSecondaryMuscles.map { $0.parentGroup })).sorted { $0.rawValue < $1.rawValue }
            }
            return secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            secondaryMusclesRaw = newValue.map { $0.rawValue }
            // Detaillierte Daten leeren, damit der Getter nicht veraltete Werte bevorzugt
            detailedSecondaryMusclesRaw = []
        }
    }

    var detailedPrimaryMuscles: [DetailedMuscle] {
        get { detailedPrimaryMusclesRaw.compactMap { DetailedMuscle(rawValue: $0) } }
        set {
            detailedPrimaryMusclesRaw = newValue.map { $0.rawValue }
            // Grobe Gruppen aus den feingranularen Muskeln ableiten (Compat)
            primaryMusclesRaw = Array(Set(newValue.map { $0.parentGroup.rawValue })).sorted()
        }
    }

    var detailedSecondaryMuscles: [DetailedMuscle] {
        get { detailedSecondaryMusclesRaw.compactMap { DetailedMuscle(rawValue: $0) } }
        set {
            detailedSecondaryMusclesRaw = newValue.map { $0.rawValue }
            // Grobe Gruppen aus den feingranularen Muskeln ableiten (Compat)
            secondaryMusclesRaw = Array(Set(newValue.map { $0.parentGroup.rawValue })).sorted()
        }
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

    // MARK: - Progressions-Computed Properties

    var progressionStrategy: ProgressionStrategy {
        get { ProgressionStrategy(rawValue: progressionStrategyRaw) ?? .double }
        set { progressionStrategyRaw = newValue.rawValue }
    }

    // MARK: - Smart-Progression (v1.1)

    /// Typisierter Zugriff auf den Progressions-Modus (Smart/Advanced/Off)
    var progressionMode: ProgressionMode {
        get { ProgressionMode(rawValue: progressionModeRaw) ?? .smart }
        set { progressionModeRaw = newValue.rawValue }
    }

    /// Automatischer Schritt basierend auf Kategorie/Equipment (ohne Custom-Override)
    var baseProgressionStep: Double {
        switch category {
        case .compound:   return equipment == .barbell ? 2.5 : 2.0
        case .isolation:  return 1.25
        case .bodyweight: return 0
        default:          return 2.5
        }
    }

    /// Effektiver Progressionsschritt: customProgressionStep oder baseProgressionStep
    var effectiveProgressionStep: Double {
        customProgressionStep ?? baseProgressionStep
    }

    /// Kann gerade eine Progression empfohlen werden? (Cooldown-Check)
    var canRecommendProgression: Bool {
        guard let lastDate = lastProgressionDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return days >= minDaysBetweenProgressions
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
        if isSystemExercise { return "System-Übung" }
        if isCustom { return "Eigene Übung" }
        return "Standard"
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
        localVideoFileName: String? = nil
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

        // Feingranulare Muskeln: Supabase-Identifier direkt als DetailedMuscle speichern
        let detailedPrimaryList = supabase.primaryMuscles.compactMap {
            MuscleGroupMapper.mapDetailed(supabaseValue: $0)
        }
        let detailedSecondaryList = supabase.secondaryMuscles.compactMap {
            MuscleGroupMapper.mapDetailed(supabaseValue: $0)
        }

        // DetailedMuscle rawValues speichern (verlustfrei)
        let detailedPrimaryMusclesRaw = detailedPrimaryList.map { $0.rawValue }
        let detailedSecondaryMusclesRaw = detailedSecondaryList.map { $0.rawValue }

        // Grobe MuscleGroup für Compat ableiten (bestehende Views nutzen das weiterhin)
        let primaryMusclesRaw = Array(Set(detailedPrimaryList.map { $0.parentGroup.rawValue }))
        let secondaryMusclesRaw = Array(Set(detailedSecondaryList.map { $0.parentGroup.rawValue }))

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
            categoryRaw: categoryRaw,
            equipmentRaw: equipmentRaw,
            difficultyRaw: difficultyRaw,
            movementPatternRaw: "push",
            bodyPositionRaw: "standing",
            primaryMusclesRaw: primaryMusclesRaw,
            secondaryMusclesRaw: secondaryMusclesRaw,
            detailedPrimaryMusclesRaw: detailedPrimaryMusclesRaw,
            detailedSecondaryMusclesRaw: detailedSecondaryMusclesRaw
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
