// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseSessionService.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.03.2026                                                       /
// Beschreibung  : Lädt abgeschlossene Sessions additiv nach Supabase hoch          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : CloudKit bleibt primäre Persistenz – Supabase ist sekundär        /
//                Fehler beim Upload werden geloggt, aber nicht weitergereicht.     /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Lädt abgeschlossene Sessions additiv nach Supabase hoch.
/// CloudKit bleibt primäre Persistenz – Supabase ist sekundär.
///
/// Thread-Safety: `upload()` ist sicher aus `@MainActor`-Kontexten aufrufbar.
/// SwiftData-Properties werden synchron vor dem ersten `await` in ein DTO kopiert.
final class SupabaseSessionService {

    static let shared = SupabaseSessionService()
    private let client = SupabaseClient.shared

    private init() {}

    // MARK: - StrengthSession

    /// Lädt eine StrengthSession inkl. aller ExerciseSets und optional SessionReadiness nach Supabase hoch.
    @discardableResult
    func upload(_ session: StrengthSession, readiness: SessionReadiness? = nil) async -> Bool {
        // Alle @Model-Properties synchron vor dem ersten await in DTOs kopieren
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
            sourceTrainingPlanId: session.sourceTrainingPlan?.planUUID,
            sessionQualityScore: session.sessionQualityScore,
            sessionReadinessId: session.sessionReadinessID
        )

        let sessionUUIDString = session.sessionUUID.uuidString

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
                notes: set.notes,
                isLastSetOfExercise: set.isLastSetOfExercise,
                rpeRecorded: set.rpeRecorded,
                trackingMode: set.trackingModeRaw
            )
        }

        let ratingDTOs = session.safeExerciseRatings.map { r in
            SupabaseExerciseRatingDTO(
                id: r.ratingUUID,
                sessionId: session.sessionUUID,
                exerciseGroupKey: r.exerciseGroupKey,
                exerciseNameSnapshot: r.exerciseNameSnapshot,
                rating: r.ratingRaw,
                ratedAt: r.ratedAt
            )
        }

        let readinessDTO: SupabaseSessionReadinessDTO? = readiness.map { r in
            SupabaseSessionReadinessDTO(
                id: r.id,
                sessionUuid: r.sessionUUID,
                capturedAt: r.capturedAt,
                hrvScore: r.hrvScore,
                sleepScore: r.sleepScore,
                restingHRScore: r.restingHRScore,
                activityScore: r.activityScore,
                userEnergyLevel: r.userEnergyLevel,
                userStressLevel: r.userStressLevelRaw,
                overallScore: r.overallScore,
                isCalibrating: r.isCalibrating
            )
        }

        // Ab hier nur noch DTOs (Value-Types) — kein @Model-Zugriff nach await
        do {
            try await client.upsert(endpoint: "strength_sessions", body: dto)

            try await client.deleteWhere(
                endpoint: "exercise_sets",
                filter: "session_id=eq.\(sessionUUIDString)"
            )

            if !setDTOs.isEmpty {
                try await client.upsert(endpoint: "exercise_sets", body: setDTOs)
            }

            try await client.deleteWhere(
                endpoint: "exercise_ratings",
                filter: "session_id=eq.\(sessionUUIDString)"
            )

            if !ratingDTOs.isEmpty {
                try await client.upsert(endpoint: "exercise_ratings", body: ratingDTOs)
            }
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (StrengthSession): \(error.localizedDescription)")
            return false
        }

        // Readiness in eigenem try/catch — Fehler tankt nicht den Session-Upload
        if let readinessDTO {
            do {
                try await client.upsert(endpoint: "session_readiness", body: readinessDTO)
            } catch {
                print("⚠️ SessionReadiness Upload fehlgeschlagen (wird beim nächsten Resync nachgeholt): \(error.localizedDescription)")
            }
        }

        print("✅ StrengthSession \(dto.id) hochgeladen (\(setDTOs.count) Sets, \(ratingDTOs.count) Ratings\(readinessDTO != nil ? ", Readiness" : ""))")
        return true
    }

    // MARK: - CardioSession

    /// Lädt eine CardioSession nach Supabase hoch.
    @discardableResult
    func upload(_ session: CardioSession) async -> Bool {
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
            return true
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (CardioSession): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - OutdoorSession

    /// Lädt eine OutdoorSession nach Supabase hoch.
    @discardableResult
    func upload(_ session: OutdoorSession) async -> Bool {
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
                heartRate: session.heartRate,
                maxHeartRate: session.maxHeartRate,
                bodyWeight: session.bodyWeight,
                routeName: session.routeName,
                startLocation: session.startLocation,
                endLocation: session.endLocation,
                startLatitude: session.startLatitude,
                startLongitude: session.startLongitude,
                endLatitude: session.endLatitude,
                endLongitude: session.endLongitude,
                startStreet: session.startStreet,
                startPostalCode: session.startPostalCode,
                startCity: session.startCity,
                endStreet: session.endStreet,
                endPostalCode: session.endPostalCode,
                endCity: session.endCity,
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
            return true
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (OutdoorSession): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - TrainingPlan

    /// Lädt einen TrainingPlan nach Supabase hoch.
    @discardableResult
    func upload(_ plan: TrainingPlan) async -> Bool {
        do {
            let dto = SupabaseTrainingPlanDTO(
                id: plan.planUUID,
                title: plan.title,
                planDescription: plan.planDescription,
                startDate: plan.startDate,
                endDate: plan.endDate,
                isActive: plan.isActive,
                planTypeRaw: plan.planTypeRaw,
                lastSyncSnapshotJSON: plan.lastSyncSnapshotJSON,
                lastSessionSyncDate: plan.lastSessionSyncDate,
                lastSessionSyncSourceUUID: plan.lastSessionSyncSourceUUID
            )

            try await client.upsert(endpoint: "training_plans", body: dto)
            print("✅ TrainingPlan \(plan.planUUID) hochgeladen")
            return true
        } catch {
            print("⚠️ Supabase Upload fehlgeschlagen (TrainingPlan): \(error.localizedDescription)")
            return false
        }
    }
}
