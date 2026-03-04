// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseSessionService.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.03.2026                                                       /
// Beschreibung  : Lädt abgeschlossene Sessions additiv nach Supabase hoch         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : CloudKit bleibt primäre Persistenz – Supabase ist sekundär      /
//                Fehler beim Upload werden geloggt, aber nicht weitergereicht.   /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Lädt abgeschlossene Sessions additiv nach Supabase hoch.
/// CloudKit bleibt primäre Persistenz – Supabase ist sekundär.
final class SupabaseSessionService {

    static let shared = SupabaseSessionService()
    private let client = SupabaseClient.shared

    private init() {}

    // MARK: - StrengthSession

    /// Lädt eine StrengthSession inkl. aller ExerciseSets nach Supabase hoch.
    func upload(_ session: StrengthSession) async {
        do {
            let dto = SupabaseStrengthSessionDTO(
                id: session.sessionUUID,
                date: session.date,
                duration: session.duration,
                calories: session.calories,
                bodyWeight: session.bodyWeight,
                heartRate: session.heartRate,
                maxHeartRate: session.maxHeartRate,
                notes: session.notes,
                workoutTypeRaw: session.workoutTypeRaw,
                intensityRaw: session.intensityRaw,
                perceivedExertion: session.perceivedExertion,
                energyLevelBefore: session.energyLevelBefore,
                isCompleted: session.isCompleted,
                isLiveSession: session.isLiveSession,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                deviceSource: session.deviceSource,
                healthKitWorkoutUUID: session.healthKitWorkoutUUID,
                sourceTrainingPlanId: session.sourceTrainingPlan?.planUUID
            )

            try await client.upsert(endpoint: "strength_sessions", body: dto)

            // Alte Sets löschen, dann neue einfügen.
            // Bewusst: Zwischen DELETE und INSERT existiert ein kurzes Inkonsistenzfenster.
            // Da Supabase sekundäre Persistenz ist (CloudKit ist primär), ist das akzeptabel –
            // ein erneuter Upload beim nächsten Session-Abschluss würde es korrigieren.
            try await client.deleteWhere(
                endpoint: "exercise_sets",
                filter: "session_id=eq.\(session.sessionUUID.uuidString)"
            )

            let setDTOs = session.safeExerciseSets.map { set in
                SupabaseExerciseSetDTO(
                    id: set.setUUID,
                    sessionId: session.sessionUUID,
                    trainingPlanId: set.trainingPlan?.planUUID,
                    exerciseNameSnapshot: set.exerciseNameSnapshot.isEmpty ? set.exerciseName : set.exerciseNameSnapshot,
                    exerciseUUIDSnapshot: set.exerciseUUIDSnapshot,
                    exerciseMediaAssetName: set.exerciseMediaAssetName,
                    isUnilateralSnapshot: set.isUnilateralSnapshot,
                    setNumber: set.setNumber,
                    weight: set.weight,
                    weightPerSide: set.weightPerSide,
                    reps: set.reps,
                    duration: set.duration,
                    distance: set.distance,
                    restSeconds: set.restSeconds,
                    targetRepsMin: set.targetRepsMin,
                    targetRepsMax: set.targetRepsMax,
                    targetRIR: set.targetRIR,
                    groupId: set.groupId,
                    supersetGroupId: set.supersetGroupId,
                    sortOrder: set.sortOrder,
                    setKindRaw: set.setKindRaw,
                    isCompleted: set.isCompleted,
                    rpe: set.rpe,
                    notes: set.notes
                )
            }

            if !setDTOs.isEmpty {
                try await client.upsert(endpoint: "exercise_sets", body: setDTOs)
            }

            print("✅ StrengthSession \(session.sessionUUID) hochgeladen (\(setDTOs.count) Sets)")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (StrengthSession): \(error.localizedDescription)")
        }
    }

    // MARK: - CardioSession

    /// Lädt eine CardioSession nach Supabase hoch.
    func upload(_ session: CardioSession) async {
        do {
            let dto = SupabaseCardioSessionDTO(
                id: session.sessionUUID,
                date: session.date,
                duration: session.duration,
                distance: session.distance,
                calories: session.calories,
                difficulty: session.difficulty,
                heartRate: session.heartRate,
                maxHeartRate: session.maxHeartRate,
                bodyWeight: session.bodyWeight,
                notes: session.notes,
                cardioDeviceRaw: session.cardioDeviceRaw,
                intensityRaw: session.intensityRaw,
                trainingProgramRaw: session.trainingProgramRaw,
                perceivedExertion: session.perceivedExertion,
                energyLevelBefore: session.energyLevelBefore,
                isCompleted: session.isCompleted,
                isLiveSession: session.isLiveSession,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                deviceSource: session.deviceSource,
                healthKitWorkoutUUID: session.healthKitWorkoutUUID
            )

            try await client.upsert(endpoint: "cardio_sessions", body: dto)
            print("✅ CardioSession \(session.sessionUUID) hochgeladen")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (CardioSession): \(error.localizedDescription)")
        }
    }

    // MARK: - OutdoorSession

    /// Lädt eine OutdoorSession nach Supabase hoch.
    func upload(_ session: OutdoorSession) async {
        do {
            let dto = SupabaseOutdoorSessionDTO(
                id: session.sessionUUID,
                date: session.date,
                duration: session.duration,
                distance: session.distance,
                calories: session.calories,
                elevationGain: session.elevationGain,
                averageSpeed: session.averageSpeed,
                maxSpeed: session.maxSpeed,
                routeName: session.routeName,
                startLocation: session.startLocation,
                endLocation: session.endLocation,
                notes: session.notes,
                temperature: session.temperature,
                weatherConditionRaw: session.weatherConditionRaw,
                outdoorActivityRaw: session.outdoorActivityRaw,
                intensityRaw: session.intensityRaw,
                perceivedExertion: session.perceivedExertion,
                energyLevelBefore: session.energyLevelBefore,
                isCompleted: session.isCompleted,
                isLiveSession: session.isLiveSession,
                startedAt: session.startedAt,
                completedAt: session.completedAt,
                deviceSource: session.deviceSource,
                healthKitWorkoutUUID: session.healthKitWorkoutUUID
            )

            try await client.upsert(endpoint: "outdoor_sessions", body: dto)
            print("✅ OutdoorSession \(session.sessionUUID) hochgeladen")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (OutdoorSession): \(error.localizedDescription)")
        }
    }

    // MARK: - TrainingPlan

    /// Lädt einen TrainingPlan nach Supabase hoch.
    func upload(_ plan: TrainingPlan) async {
        do {
            let dto = SupabaseTrainingPlanDTO(
                id: plan.planUUID,
                title: plan.title,
                planDescription: plan.planDescription,
                startDate: plan.startDate,
                endDate: plan.endDate,
                isActive: plan.isActive,
                planTypeRaw: plan.planTypeRaw
            )

            try await client.upsert(endpoint: "training_plans", body: dto)
            print("✅ TrainingPlan \(plan.planUUID) hochgeladen")
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (TrainingPlan): \(error.localizedDescription)")
        }
    }
}
