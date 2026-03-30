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

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case planDescription    = "plan_description"
        case startDate          = "start_date"
        case endDate            = "end_date"
        case isActive           = "is_active"
        case planTypeRaw        = "plan_type"
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
