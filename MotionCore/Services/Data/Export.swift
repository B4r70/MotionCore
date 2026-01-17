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

// ==================================================================================
// MARK: - CardioSession (Workouts)
// ==================================================================================

// MARK: Paket
struct WorkoutExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [WorkoutExportItem]
}

// MARK: Struktur
struct WorkoutExportItem: Codable {
    // Grunddaten
    let date: String? // ISO8601
    let duration: Int?
    let distance: Double?
    let calories: Int?
    let difficulty: Int?
    let heartRate: Int?
    let maxHeartRate: Int? 
    let bodyWeight: Double?
    let notes: String? 
    let intensity: Int? // Enum als rawValue (0...5)
    let trainingProgram: String? // Enum als rawValue ("manual", ...)
    let cardioDevice: Int?

    // Session-Status (NEU)
    let isCompleted: Bool?
    let isLiveSession: Bool?
    let startedAt: String? // ISO8601
    let completedAt: String? // ISO8601

    // Subjektive Bewertung für ML (NEU)
    let perceivedExertion: Int? // RPE 1-10
    let energyLevelBefore: Int? // 1-5

    // HealthKit-Integration (NEU)
    let healthKitWorkoutUUID: String? // UUID als String
    let deviceSource: String?
}

// MARK: Mapper
extension CardioSession {
    // → DTO (Export)
    var exportItem: WorkoutExportItem {
        let iso = ISO8601DateFormatter()

        return WorkoutExportItem(
            date: iso.string(from: date),
            duration: duration > 0 ? duration : nil,
            distance: distance > 0 ? distance : nil,
            calories: calories > 0 ? calories : nil,
            difficulty: difficulty > 1 ? difficulty : nil,
            heartRate: heartRate > 0 ? heartRate : nil,
            maxHeartRate: maxHeartRate > 0 ? maxHeartRate : nil,
            bodyWeight: bodyWeight > 0.0 ? bodyWeight : nil,
            notes: notes.isEmpty ? nil : notes,
            intensity: intensity != .none ? intensity.rawValue : nil,
            trainingProgram: trainingProgram != .manual ? trainingProgram.rawValue : nil,
            cardioDevice: cardioDevice != .none ? cardioDevice.rawValue : nil,
            isCompleted: isCompleted ? true : nil,
            isLiveSession: isLiveSession ? true : nil,
            startedAt: startedAt.map { iso.string(from: $0) },
            completedAt: completedAt.map { iso.string(from: $0) },
            perceivedExertion: perceivedExertion,
            energyLevelBefore: energyLevelBefore,
            healthKitWorkoutUUID: healthKitWorkoutUUID?.uuidString,
            deviceSource: deviceSource != "manual" ? deviceSource : nil
        )
    }

    // ← DTO (Import)
    static func fromExportItem(_ e: WorkoutExportItem) -> CardioSession {
        let iso = ISO8601DateFormatter()

        let session = CardioSession(
            date: e.date.flatMap { iso.date(from: $0) } ?? .now,
            duration: e.duration ?? 0,
            distance: e.distance ?? 0.0,
            calories: e.calories ?? 0,
            difficulty: e.difficulty ?? 1,
            heartRate: e.heartRate ?? 0,
            maxHeartRate: e.maxHeartRate ?? 0,
            bodyWeight: e.bodyWeight ?? 0.0,
            notes: e.notes ?? "",
            isCompleted: e.isCompleted ?? false,
            isLiveSession: e.isLiveSession ?? false,
            startedAt: e.startedAt.flatMap { iso.date(from: $0) },
            completedAt: e.completedAt.flatMap { iso.date(from: $0) },
            perceivedExertion: e.perceivedExertion,
            energyLevelBefore: e.energyLevelBefore,
            healthKitWorkoutUUID: e.healthKitWorkoutUUID.flatMap { UUID(uuidString: $0) },
            deviceSource: e.deviceSource ?? "manual",
            intensity: e.intensity.flatMap { Intensity(rawValue: $0) } ?? .none,
            trainingProgram: e.trainingProgram.flatMap { TrainingProgram(rawValue: $0) } ?? .manual,
            cardioDevice: e.cardioDevice.flatMap { CardioDevice(rawValue: $0) } ?? .none
        )

        return session
    }
}

// ==================================================================================
// MARK: - Exercise (Übungsbibliothek)
// ==================================================================================

// MARK: Paket
struct ExerciseExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [ExerciseExportItem]
}

// MARK: Struktur
struct ExerciseExportItem: Codable {
    let name: String
    let exerciseDescription: String?
    let mediaAssetName: String?
    let category: String // Enum rawValue
    let equipment: String // Enum rawValue
    let difficulty: String // Enum rawValue
    let primaryMuscles: [String] // Array of rawValues
    let secondaryMuscles: [String] // Array of rawValues
    let isFavorite: Bool
    let isCustom: Bool
    // Erweiterte Felder
    let movementPattern: String?
    let bodyPosition: String?
    let isUnilateral: Bool?
    let repRangeMin: Int?
    let repRangeMax: Int?
    let sortIndex: Int?
    let cautionNote: String?
    let isArchived: Bool?

    // ExerciseDB API Felder
    let apiID: String?
    let isSystemExercise: Bool?
    let videoPath: String?
    let posterPath: String?
    let instructions: String?
    let apiBodyPart: String?
    let apiTarget: String?
    let apiEquipment: String?
    let apiSecondaryMuscles: [String]?
}

// MARK: Mapper

extension Exercise {
    // → DTO (Export)
    var exportItem: ExerciseExportItem {
        ExerciseExportItem(
            name: name,
            exerciseDescription: exerciseDescription.isEmpty ? nil : exerciseDescription,
            mediaAssetName: mediaAssetName.isEmpty ? nil : mediaAssetName,
            category: category.rawValue,
            equipment: equipment.rawValue,
            difficulty: difficulty.rawValue,
            primaryMuscles: primaryMuscles.map { $0.rawValue },
            secondaryMuscles: secondaryMuscles.map { $0.rawValue },
            isFavorite: isFavorite,
            isCustom: isCustom,
            movementPattern: movementPatternRaw,
            bodyPosition: bodyPositionRaw,
            isUnilateral: isUnilateral,
            repRangeMin: repRangeMin != 8 ? repRangeMin : nil,
            repRangeMax: repRangeMax != 12 ? repRangeMax : nil,
            sortIndex: sortIndex != 0 ? sortIndex : nil,
            cautionNote: cautionNote.isEmpty ? nil : cautionNote,
            isArchived: isArchived ? true : nil,

            // NEU: API-Felder
            apiID: apiID?.uuidString,
            isSystemExercise: isSystemExercise ? true : nil,
            videoPath: videoPath,
            posterPath: posterPath,
            instructions: instructions,
            apiBodyPart: apiBodyPart,
            apiTarget: apiTarget,
            apiEquipment: apiEquipment,
            apiSecondaryMuscles: apiSecondaryMuscles
        )
    }

    // ← DTO (Import)
    static func fromExportItem(_ e: ExerciseExportItem) -> Exercise {
        Exercise(
            name: e.name,
            exerciseDescription: e.exerciseDescription ?? "",
            mediaAssetName: e.mediaAssetName ?? "",
            category: ExerciseCategory(rawValue: e.category) ?? .compound,
            equipment: ExerciseEquipment(rawValue: e.equipment) ?? .barbell,
            difficulty: ExerciseDifficulty(rawValue: e.difficulty) ?? .intermediate,
            movementPattern: e.movementPattern.flatMap { MovementPattern(rawValue: $0) } ?? .push,
            bodyPosition: e.bodyPosition.flatMap { BodyPosition(rawValue: $0) } ?? .standing,
            primaryMuscles: e.primaryMuscles.compactMap { MuscleGroup(rawValue: $0) },
            secondaryMuscles: e.secondaryMuscles.compactMap { MuscleGroup(rawValue: $0) },
            isCustom: e.isCustom,
            isFavorite: e.isFavorite,
            isUnilateral: e.isUnilateral ?? false,
            repRangeMin: e.repRangeMin ?? 8,
            repRangeMax: e.repRangeMax ?? 12,
            sortIndex: e.sortIndex ?? 0,
            cautionNote: e.cautionNote ?? "",
            isArchived: e.isArchived ?? false,

            // NEU: API-Felder
            apiID: e.apiID.flatMap { UUID(uuidString: $0) },
            isSystemExercise: e.isSystemExercise ?? false,
            videoPath: e.videoPath,
            posterPath: e.posterPath,
            instructions: e.instructions,
            localVideoFileName: nil, // Wird nicht exportiert (nur temporär gecacht)
            apiBodyPart: e.apiBodyPart,
            apiTarget: e.apiTarget,
            apiEquipment: e.apiEquipment,
            apiSecondaryMuscles: e.apiSecondaryMuscles
        )
    }
}

// ==================================================================================
// MARK: - ExerciseSet (Übungssätze)
// ==================================================================================

// MARK: Paket
struct ExerciseSetExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [ExerciseSetExportItem]
}

// MARK: Struktur
struct ExerciseSetExportItem: Codable {
    let exerciseName: String
    let exerciseNameSnapshot: String?
    let exerciseUUIDSnapshot: String?
    let exerciseMediaAssetName: String?
    let isUnilateralSnapshot: Bool?
    let setNumber: Int
    let weight: Double?
    let weightPerSide: Double?
    let reps: Int?
    let duration: Int?
    let distance: Double?
    let restSeconds: Int?
    let setKind: String? // work/warmup/drop/amrap (optional für Rückwärtskompatibilität)
    let isCompleted: Bool
    let rpe: Int?
    let notes: String?
    // Zielwerte
    let targetRepsMin: Int?
    let targetRepsMax: Int?
    let targetRIR: Int?
    let groupId: String?
    // Rückwärtskompatibilität für alte Exporte
    let exerciseId: String? // Alt: wird zu exerciseUUIDSnapshot gemappt
    let isWarmup: Bool? // Alt: wird zu setKind gemappt
}

// MARK: Mapper
extension ExerciseSet {
    // → DTO (Export)
    var exportItem: ExerciseSetExportItem {
        ExerciseSetExportItem(
            exerciseName: exerciseName,
            exerciseNameSnapshot: exerciseNameSnapshot.isEmpty ? nil : exerciseNameSnapshot,
            exerciseUUIDSnapshot: exerciseUUIDSnapshot.isEmpty ? nil : exerciseUUIDSnapshot,
            exerciseMediaAssetName: exerciseMediaAssetName.isEmpty ? nil : exerciseMediaAssetName,
            isUnilateralSnapshot: isUnilateralSnapshot ? true : nil,
            setNumber: setNumber,
            weight: weight > 0 ? weight : nil,
            weightPerSide: weightPerSide > 0 ? weightPerSide : nil,
            reps: reps > 0 ? reps : nil,
            duration: duration > 0 ? duration : nil,
            distance: distance > 0 ? distance : nil,
            restSeconds: restSeconds != 90 ? restSeconds : nil,
            setKind: setKindRaw,
            isCompleted: isCompleted,
            rpe: rpe > 0 ? rpe : nil,
            notes: notes.isEmpty ? nil : notes,
            targetRepsMin: targetRepsMin > 0 ? targetRepsMin : nil,
            targetRepsMax: targetRepsMax > 0 ? targetRepsMax : nil,
            targetRIR: targetRIR != 2 ? targetRIR : nil,
            groupId: groupId.isEmpty ? nil : groupId,
            // Rückwärtskompatibilität: Nicht mehr verwendet beim Export
            exerciseId: nil,
            isWarmup: nil
        )
    }

    // ← DTO (Import) - mit Rückwärtskompatibilität
    static func fromExportItem(_ e: ExerciseSetExportItem) -> ExerciseSet {
        // SetKind bestimmen: Neu oder aus altem isWarmup-Feld
        let resolvedSetKind: SetKind
        if let setKindStr = e.setKind, let kind = SetKind(rawValue: setKindStr) {
            resolvedSetKind = kind
        } else if e.isWarmup == true {
            resolvedSetKind = .warmup
        } else {
            resolvedSetKind = .work
        }

        // UUID-Snapshot: Neu oder aus altem exerciseId-Feld
        let resolvedUUID = e.exerciseUUIDSnapshot ?? e.exerciseId ?? ""

        return ExerciseSet(
            exerciseName: e.exerciseName,
            exerciseNameSnapshot: e.exerciseNameSnapshot ?? e.exerciseName,
            exerciseUUIDSnapshot: resolvedUUID,
            exerciseMediaAssetName: e.exerciseMediaAssetName ?? "",
            isUnilateralSnapshot: e.isUnilateralSnapshot ?? false,
            setNumber: e.setNumber,
            weight: e.weight ?? 0.0,
            weightPerSide: e.weightPerSide ?? 0.0,
            reps: e.reps ?? 0,
            duration: e.duration ?? 0,
            distance: e.distance ?? 0.0,
            restSeconds: e.restSeconds ?? 90,
            setKind: resolvedSetKind,
            isCompleted: e.isCompleted,
            rpe: e.rpe ?? 0,
            notes: e.notes ?? "",
            targetRepsMin: e.targetRepsMin ?? 0,
            targetRepsMax: e.targetRepsMax ?? 0,
            targetRIR: e.targetRIR ?? 2,
            groupId: e.groupId ?? ""
        )
    }
}

// ==================================================================================
// MARK: - TrainingPlan (Trainingspläne)
// ==================================================================================

// MARK: Paket
struct TrainingPlanExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [TrainingPlanExportItem]
}

// MARK: Struktur
struct TrainingPlanExportItem: Codable {
    let title: String
    let planDescription: String?
    let startDate: String // ISO8601
    let endDate: String? // ISO8601
    let isActive: Bool
    let createdAt: String // ISO8601
    let planType: String // Enum rawValue
    let templateSets: [ExerciseSetExportItem] // Eingebettete Sets
}

// MARK: Mapper
extension TrainingPlan {
    // → DTO (Export)
    var exportItem: TrainingPlanExportItem {
        let iso = ISO8601DateFormatter()

        return TrainingPlanExportItem(
            title: title,
            planDescription: planDescription.isEmpty ? nil : planDescription,
            startDate: iso.string(from: startDate),
            endDate: endDate.map { iso.string(from: $0) },
            isActive: isActive,
            createdAt: iso.string(from: createdAt),
            planType: planTypeRaw,
            templateSets: templateSets.map { $0.exportItem }
        )
    }

    // ← DTO (Import)
    static func fromExportItem(_ e: TrainingPlanExportItem) -> TrainingPlan {
        let iso = ISO8601DateFormatter()

        let plan = TrainingPlan(
            title: e.title,
            planDescription: e.planDescription ?? "",
            startDate: iso.date(from: e.startDate) ?? Date(),
            endDate: e.endDate.flatMap { iso.date(from: $0) },
            planType: PlanType(rawValue: e.planType) ?? .mixed,
            isActive: e.isActive
        )

        // CreatedAt überschreiben (wird im Init auf Date() gesetzt)
        if let created = iso.date(from: e.createdAt) {
            plan.createdAt = created
        }

        // Template-Sets importieren und verknüpfen
        for setItem in e.templateSets {
            let exerciseSet = ExerciseSet.fromExportItem(setItem)
            exerciseSet.trainingPlan = plan
            plan.templateSets.append(exerciseSet)
        }

        return plan
    }
}

// ==================================================================================
// MARK: - StrengthSession (Krafttraining)
// ==================================================================================

// MARK: Paket
struct StrengthSessionExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [StrengthSessionExportItem]
}

// MARK: Struktur
struct StrengthSessionExportItem: Codable {
    // Grunddaten
    let date: String // ISO8601
    let duration: Int?
    let calories: Int?
    let notes: String?
    let bodyWeight: Double?
    let heartRate: Int?
    let maxHeartRate: Int? 
    let workoutType: String // Enum rawValue
    let intensity: Int? // Enum rawValue

    // Session-Status
    let isCompleted: Bool
    let isLiveSession: Bool? 
    let startedAt: String? // ISO8601
    let completedAt: String? // ISO8601

    // Subjektive Bewertung für ML (NEU)
    let perceivedExertion: Int? // RPE 1-10
    let energyLevelBefore: Int? // 1-5

    // HealthKit-Integration (NEU)
    let healthKitWorkoutUUID: String? // UUID als String
    let deviceSource: String?

    // Eingebettete Sets
    let exerciseSets: [ExerciseSetExportItem]
}

// MARK: Mapper
extension StrengthSession {
    // → DTO (Export)
    var exportItem: StrengthSessionExportItem {
        let iso = ISO8601DateFormatter()

        return StrengthSessionExportItem(
            date: iso.string(from: date),
            duration: duration > 0 ? duration : nil,
            calories: calories > 0 ? calories : nil,
            notes: notes.isEmpty ? nil : notes,
            bodyWeight: bodyWeight > 0 ? bodyWeight : nil,
            heartRate: heartRate > 0 ? heartRate : nil,
            maxHeartRate: maxHeartRate > 0 ? maxHeartRate : nil,
            workoutType: workoutTypeRaw,
            intensity: intensity != .none ? intensityRaw : nil,
            isCompleted: isCompleted,
            isLiveSession: isLiveSession ? true : nil,
            startedAt: startedAt.map { iso.string(from: $0) },
            completedAt: completedAt.map { iso.string(from: $0) },
            perceivedExertion: perceivedExertion,
            energyLevelBefore: energyLevelBefore,
            healthKitWorkoutUUID: healthKitWorkoutUUID?.uuidString,
            deviceSource: deviceSource != "manual" ? deviceSource : nil,
            exerciseSets: exerciseSets.map { $0.exportItem }
        )
    }

    // ← DTO (Import)
    static func fromExportItem(_ e: StrengthSessionExportItem) -> StrengthSession {
        let iso = ISO8601DateFormatter()

        let session = StrengthSession(
            date: iso.date(from: e.date) ?? Date(),
            duration: e.duration ?? 0,
            calories: e.calories ?? 0,
            notes: e.notes ?? "",
            bodyWeight: e.bodyWeight ?? 0.0,
            heartRate: e.heartRate ?? 0,
            maxHeartRate: e.maxHeartRate ?? 0,
            isCompleted: e.isCompleted,
            isLiveSession: e.isLiveSession ?? false,
            startedAt: e.startedAt.flatMap { iso.date(from: $0) },
            completedAt: e.completedAt.flatMap { iso.date(from: $0) },
            perceivedExertion: e.perceivedExertion,
            energyLevelBefore: e.energyLevelBefore,
            healthKitWorkoutUUID: e.healthKitWorkoutUUID.flatMap { UUID(uuidString: $0) },
            deviceSource: e.deviceSource ?? "manual",
            workoutType: StrengthWorkoutType(rawValue: e.workoutType) ?? .fullBody,
            intensity: e.intensity.flatMap { Intensity(rawValue: $0) } ?? .none
        )

        // ExerciseSets importieren und verknüpfen
        for setItem in e.exerciseSets {
            let exerciseSet = ExerciseSet.fromExportItem(setItem)
            exerciseSet.session = session
            session.exerciseSets.append(exerciseSet)
        }

        return session
    }
}

// ==================================================================================
// MARK: - OutdoorSession (Outdoor-Aktivitäten)
// ==================================================================================

// MARK: Paket
struct OutdoorSessionExportPackage: Codable {
    let version: Int
    let exportedAt: String // ISO8601
    let items: [OutdoorSessionExportItem]
}

// MARK: Struktur
struct OutdoorSessionExportItem: Codable {
    // Grunddaten
    let date: String // ISO8601
    let duration: Int?
    let distance: Double?
    let calories: Int?

    // Outdoor-spezifische Daten
    let elevationGain: Double?
    let averageSpeed: Double?
    let maxSpeed: Double?

    // Gesundheitsdaten
    let heartRate: Int?
    let maxHeartRate: Int?
    let bodyWeight: Double?

    // Route/Location
    let routeName: String?
    let startLocation: String?
    let endLocation: String?
    let notes: String?

    // Wetter
    let temperature: Double?
    let weatherCondition: String? // Enum rawValue

    // Aktivitätstyp und Intensität
    let outdoorActivity: String // Enum rawValue
    let intensity: Int? // Enum rawValue

    // Session-Status
    let isCompleted: Bool?
    let isLiveSession: Bool?
    let startedAt: String? // ISO8601
    let completedAt: String? // ISO8601

    // Subjektive Bewertung für ML
    let perceivedExertion: Int? // RPE 1-10
    let energyLevelBefore: Int? // 1-5

    // HealthKit-Integration
    let healthKitWorkoutUUID: String? // UUID als String
    let deviceSource: String?
}

// MARK: Mapper
extension OutdoorSession {
    // → DTO (Export)
    var exportItem: OutdoorSessionExportItem {
        let iso = ISO8601DateFormatter()

        return OutdoorSessionExportItem(
            date: iso.string(from: date),
            duration: duration > 0 ? duration : nil,
            distance: distance > 0 ? distance : nil,
            calories: calories > 0 ? calories : nil,
            elevationGain: elevationGain > 0 ? elevationGain : nil,
            averageSpeed: averageSpeed > 0 ? averageSpeed : nil,
            maxSpeed: maxSpeed > 0 ? maxSpeed : nil,
            heartRate: heartRate > 0 ? heartRate : nil,
            maxHeartRate: maxHeartRate > 0 ? maxHeartRate : nil,
            bodyWeight: bodyWeight > 0 ? bodyWeight : nil,
            routeName: routeName.isEmpty ? nil : routeName,
            startLocation: startLocation.isEmpty ? nil : startLocation,
            endLocation: endLocation.isEmpty ? nil : endLocation,
            notes: notes.isEmpty ? nil : notes,
            temperature: temperature,
            weatherCondition: weatherCondition != .unknown ? weatherConditionRaw : nil,
            outdoorActivity: outdoorActivityRaw,
            intensity: intensity != .none ? intensityRaw : nil,
            isCompleted: isCompleted ? true : nil,
            isLiveSession: isLiveSession ? true : nil,
            startedAt: startedAt.map { iso.string(from: $0) },
            completedAt: completedAt.map { iso.string(from: $0) },
            perceivedExertion: perceivedExertion,
            energyLevelBefore: energyLevelBefore,
            healthKitWorkoutUUID: healthKitWorkoutUUID?.uuidString,
            deviceSource: deviceSource != "manual" ? deviceSource : nil
        )
    }

    // ← DTO (Import)
    static func fromExportItem(_ e: OutdoorSessionExportItem) -> OutdoorSession {
        let iso = ISO8601DateFormatter()

        return OutdoorSession(
            date: iso.date(from: e.date) ?? Date(),
            duration: e.duration ?? 0,
            distance: e.distance ?? 0.0,
            calories: e.calories ?? 0,
            elevationGain: e.elevationGain ?? 0.0,
            averageSpeed: e.averageSpeed ?? 0.0,
            maxSpeed: e.maxSpeed ?? 0.0,
            heartRate: e.heartRate ?? 0,
            maxHeartRate: e.maxHeartRate ?? 0,
            bodyWeight: e.bodyWeight ?? 0.0,
            routeName: e.routeName ?? "",
            startLocation: e.startLocation ?? "",
            endLocation: e.endLocation ?? "",
            notes: e.notes ?? "",
            temperature: e.temperature,
            isCompleted: e.isCompleted ?? false,
            isLiveSession: e.isLiveSession ?? false,
            startedAt: e.startedAt.flatMap { iso.date(from: $0) },
            completedAt: e.completedAt.flatMap { iso.date(from: $0) },
            perceivedExertion: e.perceivedExertion,
            energyLevelBefore: e.energyLevelBefore,
            healthKitWorkoutUUID: e.healthKitWorkoutUUID.flatMap { UUID(uuidString: $0) },
            deviceSource: e.deviceSource ?? "manual",
            outdoorActivity: OutdoorActivity(rawValue: e.outdoorActivity) ?? .cycling,
            intensity: e.intensity.flatMap { Intensity(rawValue: $0) } ?? .none,
            weatherCondition: e.weatherCondition.flatMap { WeatherCondition(rawValue: $0) } ?? .unknown
        )
    }
}
