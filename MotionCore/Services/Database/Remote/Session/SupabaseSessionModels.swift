// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseSessionModels.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.03.2026                                                       /
// Beschreibung  : Encodable DTOs für den Supabase Session-Sync                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Nur Encodable – kein Lesen zurück aus Supabase                  /
//                SupabaseClient.makeEncoder() wandelt camelCase → snake_case       /
//                Enum-Rohwerte (Raw) werden direkt übertragen                     /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - TrainingPlan DTO

struct SupabaseTrainingPlanDTO: Encodable {
    let id: UUID                        // sessionUUID aus @Model
    let title: String
    let planDescription: String
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let planTypeRaw: String             // "cardio", "strength", "outdoor", "mixed"
    let createdAt: Date
}

// MARK: - StrengthSession DTO

struct SupabaseStrengthSessionDTO: Encodable {
    let id: UUID                        // sessionUUID aus @Model
    let date: Date
    let duration: Int
    let calories: Int
    let bodyWeight: Double
    let heartRate: Int
    let maxHeartRate: Int
    let notes: String
    let workoutTypeRaw: String          // "fullBody", "upperBody", etc.
    let intensityRaw: Int               // 0–5
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthKitWorkoutUUID: UUID?
    let sourceTrainingPlanId: UUID?     // UUID des verknüpften TrainingPlans
}

// MARK: - ExerciseSet DTO

struct SupabaseExerciseSetDTO: Encodable {
    let id: UUID                        // eigene UUID für stabiles Upsert
    let sessionId: UUID                 // sessionUUID der zugehörigen StrengthSession
    let trainingPlanId: UUID?           // gesetzt wenn Template-Set
    let exerciseName: String
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
    let setKindRaw: String              // "work", "warmup", "drop", "amrap"
    let isCompleted: Bool
    let rpe: Int
    let notes: String
}

// MARK: - CardioSession DTO

struct SupabaseCardioSessionDTO: Encodable {
    let id: UUID                        // sessionUUID aus @Model
    let date: Date
    let duration: Int
    let distance: Double
    let calories: Int
    let difficulty: Int
    let heartRate: Int
    let maxHeartRate: Int
    let bodyWeight: Double
    let notes: String
    let cardioDeviceRaw: Int            // 0=none, 1=Crosstrainer, 2=Ergometer…
    let intensityRaw: Int               // 0–5
    let trainingProgramRaw: String      // "random", etc.
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthKitWorkoutUUID: UUID?
}

// MARK: - OutdoorSession DTO

struct SupabaseOutdoorSessionDTO: Encodable {
    let id: UUID                        // sessionUUID aus @Model
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
    let notes: String
    let temperature: Double?
    let weatherConditionRaw: String     // "unknown", "sunny", etc.
    let outdoorActivityRaw: String      // "cycling", "running", "hiking"
    let intensityRaw: Int               // 0–5
    let perceivedExertion: Int?
    let energyLevelBefore: Int?
    let isCompleted: Bool
    let isLiveSession: Bool
    let startedAt: Date?
    let completedAt: Date?
    let deviceSource: String
    let healthKitWorkoutUUID: UUID?
}
