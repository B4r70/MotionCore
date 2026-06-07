// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseSessionModels.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.03.2026                                                       /
// Beschreibung  : Encodable DTOs für den Supabase Session Sync                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Nur Encodable – kein Lesen zurück aus Supabase                    /
//                CodingKeys müssen vollständig sein – bei vorhandenem CodingKeys   /
//                Enum ignoriert Swift den convertToSnakeCase-Encoder komplett.     /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - TrainingPlan DTO

struct SupabaseTrainingPlanDTO: Encodable {
    let id: UUID
    let title: String
    let planDescription: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let planTypeRaw: String
    // Session-Sync Undo Felder (Option A) — nil wenn kein Sync stattgefunden hat
    let lastSyncSnapshotJSON: String?
    let lastSessionSyncDate: Date?
    let lastSessionSyncSourceUUID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case planDescription            = "plan_description"
        case startDate                  = "start_date"
        case endDate                    = "end_date"
        case isActive                   = "is_active"
        case planTypeRaw                = "plan_type"
        case lastSyncSnapshotJSON       = "last_sync_snapshot_json"
        case lastSessionSyncDate        = "last_session_sync_date"
        case lastSessionSyncSourceUUID  = "last_session_sync_source_uuid"
    }
}

// MARK: - StrengthSession DTO

struct SupabaseStrengthSessionDTO: Encodable {
    let id: UUID
    let date: Date
    let duration: Int
    let calories: Int
    let bodyWeight: Double
    let heartRate: Int
    let maxHeartRate: Int
    let notes: String
    let workoutTypeRaw: String
    let intensityRaw: Int
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthKitWorkoutUUID: UUID?
    let sourceTrainingPlanId: UUID?
    let sessionQualityScore: Int?
    let sessionReadinessId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case duration
        case calories
        case bodyWeight             = "body_weight"
        case heartRate              = "heart_rate"
        case maxHeartRate           = "max_heart_rate"
        case notes
        case workoutTypeRaw         = "workout_type"
        case intensityRaw           = "intensity"
        case perceivedExertion      = "perceived_exertion"
        case energyLevelBefore      = "energy_level_before"
        case isCompleted            = "is_completed"
        case isLiveSession          = "is_live_session"
        case startedAt              = "started_at"
        case completedAt            = "completed_at"
        case deviceSource           = "device_source"
        case healthKitWorkoutUUID   = "healthkit_workout_uuid"
        case sourceTrainingPlanId   = "source_training_plan_id"
        case sessionQualityScore    = "session_quality_score"
        case sessionReadinessId     = "session_readiness_id"
    }
}

// MARK: - ExerciseSet DTO

struct SupabaseExerciseSetDTO: Encodable {
    let id: UUID
    let sessionId: UUID?
    let trainingPlanId: UUID?
    let exerciseNameSnapshot: String
    let exerciseUUIDSnapshot: String
    let exerciseMediaAssetName: String
    let isUnilateralSnapshot: Bool
    let setNumber: Int
    let weight: Double
    let weightPerSide: Double
    let reps: Int
    let duration: Int
    let distance: Double
    let restSeconds: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let targetRIR: Int
    let groupId: String
    let supersetGroupId: String?
    let sortOrder: Int
    let setKindRaw: String
    let isCompleted: Bool
    let rpe: Int
    let notes: String
    let isLastSetOfExercise: Bool
    let rpeRecorded: Bool
    /// Tracking-Modus des Satzes ("weight" oder "time") — immer gesetzt, UPSERT-idempotent
    let trackingMode: String

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId              = "session_id"
        case trainingPlanId         = "training_plan_id"
        case exerciseNameSnapshot   = "exercise_name"
        case exerciseUUIDSnapshot   = "exercise_uuid"
        case exerciseMediaAssetName = "exercise_media_asset"
        case isUnilateralSnapshot   = "is_unilateral"
        case setNumber              = "set_number"
        case weight
        case weightPerSide          = "weight_per_side"
        case reps
        case duration
        case distance
        case restSeconds            = "rest_seconds"
        case targetRepsMin          = "target_reps_min"
        case targetRepsMax          = "target_reps_max"
        case targetRIR              = "target_rir"
        case groupId                = "group_id"
        case supersetGroupId        = "superset_group_id"
        case sortOrder              = "sort_order"
        case setKindRaw             = "set_kind"
        case isCompleted            = "is_completed"
        case rpe
        case notes
        case isLastSetOfExercise    = "is_last_set_of_exercise"
        case rpeRecorded            = "rpe_recorded"
        case trackingMode           = "tracking_mode"
    }
}

// MARK: - ExerciseRating DTO

struct SupabaseExerciseRatingDTO: Encodable {
    let id: UUID
    let sessionId: UUID
    let exerciseGroupKey: String
    let exerciseNameSnapshot: String
    let rating: String
    let ratedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId              = "session_id"
        case exerciseGroupKey       = "exercise_group_key"
        case exerciseNameSnapshot   = "exercise_name_snapshot"
        case rating
        case ratedAt                = "rated_at"
    }
}

// MARK: - CardioSession DTO

struct SupabaseCardioSessionDTO: Encodable {
    let id: UUID
    let date: Date
    let duration: Int
    let distance: Double
    let calories: Int
    let difficulty: Int
    let heartRate: Int
    let maxHeartRate: Int
    let bodyWeight: Double
    let notes: String
    let cardioDeviceRaw: Int
    let intensityRaw: Int
    let trainingProgramRaw: String
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthKitWorkoutUUID: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case duration
        case distance
        case calories
        case difficulty
        case heartRate              = "heart_rate"
        case maxHeartRate           = "max_heart_rate"
        case bodyWeight             = "body_weight"
        case notes
        case cardioDeviceRaw        = "cardio_device"
        case intensityRaw           = "intensity"
        case trainingProgramRaw     = "training_program"
        case perceivedExertion      = "perceived_exertion"
        case energyLevelBefore      = "energy_level_before"
        case isCompleted            = "is_completed"
        case isLiveSession          = "is_live_session"
        case startedAt              = "started_at"
        case completedAt            = "completed_at"
        case deviceSource           = "device_source"
        case healthKitWorkoutUUID   = "healthkit_workout_uuid"
    }
}

// MARK: - Smart-Progression Phase 1 DTOs

struct SupabaseStudioDTO: Encodable {
    let id: UUID
    let name: String
    let isPrimary: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isPrimary  = "is_primary"
        case createdAt  = "created_at"
        case updatedAt  = "updated_at"
    }
}

struct SupabaseStudioEquipmentDTO: Encodable {
    let id: UUID
    let studioId: UUID?
    let name: String
    let equipmentType: String
    let startWeight: Double
    let increment: Double
    let minWeight: Double
    let maxWeight: Double?
    let intermediateIncrements: [Double]
    let notes: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case studioId               = "studio_id"
        case name
        case equipmentType          = "equipment_type"
        case startWeight            = "start_weight"
        case increment
        case minWeight              = "min_weight"
        case maxWeight              = "max_weight"
        case intermediateIncrements = "intermediate_increments"
        case notes
        case createdAt              = "created_at"
        case updatedAt              = "updated_at"
    }
}

struct SupabaseExerciseProgressionStateDTO: Encodable {
    let id: UUID
    let exerciseGroupKey: String
    let workingWeight: Double
    let previousWorkingWeight: Double?
    let targetReps: Int
    let minTargetReps: Int
    let maxTargetReps: Int
    let progressionMode: String
    let lastProgressionDate: Date?
    let lastRollbackDate: Date?
    let consecutiveSuccessCount: Int
    let consecutiveFailCount: Int
    let isActive: Bool
    let lastAutoProgressionDate: Date?
    let lastAutoProgressionAmount: Double?
    let autoProgressionUndoable: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseGroupKey           = "exercise_group_key"
        case workingWeight              = "working_weight"
        case previousWorkingWeight      = "previous_working_weight"
        case targetReps                 = "target_reps"
        case minTargetReps              = "min_target_reps"
        case maxTargetReps              = "max_target_reps"
        case progressionMode            = "progression_mode"
        case lastProgressionDate        = "last_progression_date"
        case lastRollbackDate           = "last_rollback_date"
        case consecutiveSuccessCount    = "consecutive_success_count"
        case consecutiveFailCount       = "consecutive_fail_count"
        case isActive                   = "is_active"
        case lastAutoProgressionDate    = "last_auto_progression_date"
        case lastAutoProgressionAmount  = "last_auto_progression_amount"
        case autoProgressionUndoable    = "auto_progression_undoable"
        case createdAt                  = "created_at"
        case updatedAt                  = "updated_at"
    }
}

struct SupabaseSessionReadinessDTO: Encodable {
    let id: UUID
    let sessionUuid: String?
    let capturedAt: Date
    let hrvScore: Double?
    let sleepScore: Double?
    let restingHRScore: Double?
    let activityScore: Double?
    let userEnergyLevel: Int?
    let userStressLevel: String?
    let overallScore: Int
    let isCalibrating: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionUuid        = "session_uuid"
        case capturedAt         = "captured_at"
        case hrvScore           = "hrv_score"
        case sleepScore         = "sleep_score"
        case restingHRScore     = "resting_hr_score"
        case activityScore      = "activity_score"
        case userEnergyLevel    = "user_energy_level"
        case userStressLevel    = "user_stress_level"
        case overallScore       = "overall_score"
        case isCalibrating      = "is_calibrating"
    }
}

struct SupabaseHealthBaselineDTO: Encodable {
    let id: UUID
    let metricType: String
    let rollingMean: Double
    let rollingStdDev: Double
    let sampleCount: Int
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case metricType     = "metric_type"
        case rollingMean    = "rolling_mean"
        case rollingStdDev  = "rolling_std_dev"
        case sampleCount    = "sample_count"
        case lastUpdated    = "last_updated"
    }
}

// MARK: - OutdoorSession DTO

struct SupabaseOutdoorSessionDTO: Encodable {
    let id: UUID
    let date: Date
    let duration: Int
    let distance: Double
    let calories: Int
    let elevationGain: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let heartRate: Int
    let maxHeartRate: Int
    let bodyWeight: Double
    let routeName: String
    let startLocation: String
    let endLocation: String
    // GPS-Koordinaten (Phase 3: automatisch via LocationHelper)
    let startLatitude: Double?
    let startLongitude: Double?
    let endLatitude: Double?
    let endLongitude: Double?
    // Strukturierte Adressfelder
    let startStreet: String
    let startPostalCode: String
    let startCity: String
    let endStreet: String
    let endPostalCode: String
    let endCity: String
    let notes: String
    let temperature: Double?
    let weatherConditionRaw: String
    let outdoorActivityRaw: String
    let intensityRaw: Int
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthKitWorkoutUUID: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case duration
        case distance
        case calories
        case elevationGain          = "elevation_gain"
        case averageSpeed           = "average_speed"
        case maxSpeed               = "max_speed"
        case heartRate              = "heart_rate"
        case maxHeartRate           = "max_heart_rate"
        case bodyWeight             = "body_weight"
        case routeName              = "route_name"
        case startLocation          = "start_location"
        case endLocation            = "end_location"
        case startLatitude          = "start_latitude"
        case startLongitude         = "start_longitude"
        case endLatitude            = "end_latitude"
        case endLongitude           = "end_longitude"
        case startStreet            = "start_street"
        case startPostalCode        = "start_postal_code"
        case startCity              = "start_city"
        case endStreet              = "end_street"
        case endPostalCode          = "end_postal_code"
        case endCity                = "end_city"
        case notes
        case temperature
        case weatherConditionRaw    = "weather_condition"
        case outdoorActivityRaw     = "outdoor_activity"
        case intensityRaw           = "intensity"
        case perceivedExertion      = "perceived_exertion"
        case energyLevelBefore      = "energy_level_before"
        case isCompleted            = "is_completed"
        case isLiveSession          = "is_live_session"
        case startedAt              = "started_at"
        case completedAt            = "completed_at"
        case deviceSource           = "device_source"
        case healthKitWorkoutUUID   = "healthkit_workout_uuid"
    }
}
