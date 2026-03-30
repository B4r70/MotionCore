// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseFullBackupService.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Lädt alle lokalen SwiftData-Daten vollständig nach Supabase      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Rein additiv – kein DELETE. UPSERT ist idempotent.                /
//                Reihenfolge: TrainingPlans → StrengthSessions → Cardio →          /
//                             Outdoor → Template-Sets (wegen Foreign Keys)         /
//                Chunking in 50er-Batches verhindert Payload-Limit-Überschreitung. /
// ---------------------------------------------------------------------------------/
//
import Combine
import Foundation
import SwiftData

// MARK: - BackupProgress

/// Fortschrittszustand des Full-Backup-Prozesses.
enum BackupProgress: Equatable {
    case idle
    case running(step: String, current: Int, total: Int)
    case completed(stats: BackupStats)
    case failed(error: String)
}

// MARK: - BackupStats

/// Zusammenfassung der hochgeladenen Datensätze nach erfolgreichem Backup.
struct BackupStats: Equatable {
    let strengthSessions: Int
    let cardioSessions: Int
    let outdoorSessions: Int
    let trainingPlans: Int
    let exerciseSets: Int
    let templateSets: Int
}

// MARK: - SupabaseFullBackupService

/// Führt einen vollständigen idempotenten Backup aller lokalen SwiftData-Daten nach Supabase durch.
/// Wird manuell vom Benutzer in den Einstellungen gestartet.
@MainActor
final class SupabaseFullBackupService: ObservableObject {

    static let shared = SupabaseFullBackupService()

    private let client = SupabaseClient.shared

    // MARK: - Published State

    @Published var isRunning: Bool = false
    @Published var progress: BackupProgress = .idle

    private init() {}

    // MARK: - Haupt-Backup

    /// Startet den vollständigen Backup aller lokalen Daten nach Supabase.
    /// Idempotent: Bereits hochgeladene Datensätze werden per UPSERT überschrieben.
    func runFullBackup(context: ModelContext) async {
        guard !isRunning else { return }

        isRunning = true
        progress = .running(step: "Vorbereitung…", current: 0, total: 0)

        // Duplikate Sync-UUIDs reparieren (CloudKit-Migration-Bug: Default UUID() wird einmal evaluiert)
        deduplicateAllSyncUUIDs(context: context)

        do {
            // 1. TrainingPlans zuerst (Foreign Key training_plan_id in exercise_sets)
            progress = .running(step: "Trainingspläne", current: 0, total: 1)
            let plansCount = try await uploadAllTrainingPlans(context: context)

            // 2. StrengthSessions inkl. deren ExerciseSets
            progress = .running(step: "Krafttrainings", current: 0, total: 1)
            let (strengthCount, exerciseSetCount) = try await uploadAllStrengthSessions(context: context)

            // 3. CardioSessions
            progress = .running(step: "Cardio-Sessions", current: 0, total: 1)
            let cardioCount = try await uploadAllCardioSessions(context: context)

            // 4. OutdoorSessions
            progress = .running(step: "Outdoor-Sessions", current: 0, total: 1)
            let outdoorCount = try await uploadAllOutdoorSessions(context: context)

            // 5. Template-Sets (ExerciseSets ohne Session, mit TrainingPlan)
            progress = .running(step: "Template-Sets", current: 0, total: 1)
            let templateSetCount = try await uploadAllTemplateSets(context: context)

            // Flags persistieren
            try? context.save()

            let stats = BackupStats(
                strengthSessions: strengthCount,
                cardioSessions: cardioCount,
                outdoorSessions: outdoorCount,
                trainingPlans: plansCount,
                exerciseSets: exerciseSetCount,
                templateSets: templateSetCount
            )

            progress = .completed(stats: stats)
            isRunning = false

            print("✅ Full-Backup abgeschlossen: \(strengthCount) Kraft, \(cardioCount) Cardio, \(outdoorCount) Outdoor, \(plansCount) Pläne, \(exerciseSetCount) Sets, \(templateSetCount) Template-Sets")

        } catch {
            progress = .failed(error: error.localizedDescription)
            isRunning = false
            print("❌ Full-Backup fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Upload-Methoden

    /// Lädt alle TrainingPlans nach Supabase hoch.
    /// Einzeln statt als Batch – Swift kodiert nil-Optionals via encodeIfPresent (Key fehlt),
    /// was PostgREST PGRST102 auslösen würde wenn Pläne unterschiedliche optionale Felder haben.
    private func uploadAllTrainingPlans(context: ModelContext) async throws -> Int {
        let plans = (try? context.fetch(FetchDescriptor<TrainingPlan>())) ?? []
        guard !plans.isEmpty else { return 0 }

        progress = .running(step: "Trainingspläne", current: 0, total: plans.count)

        for (index, plan) in plans.enumerated() {
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
            plan.syncedToSupabase = true
            progress = .running(step: "Trainingspläne", current: index + 1, total: plans.count)
        }

        return plans.count
    }

    /// Lädt alle StrengthSessions inkl. ihrer ExerciseSets nach Supabase hoch.
    private func uploadAllStrengthSessions(context: ModelContext) async throws -> (sessions: Int, sets: Int) {
        let sessions = (try? context.fetch(FetchDescriptor<StrengthSession>())) ?? []
        guard !sessions.isEmpty else { return (0, 0) }

        progress = .running(step: "Krafttrainings", current: 0, total: sessions.count)

        var totalSetCount = 0

        for (index, session) in sessions.enumerated() {
            // Session hochladen
            let sessionDTO = SupabaseStrengthSessionDTO(
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

            try await client.upsert(endpoint: "strength_sessions", body: sessionDTO)

            // ExerciseSets in 50er-Batches hochladen
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

            try await uploadSetsIndividually(setDTOs)
            totalSetCount += setDTOs.count

            // Sync-Flags setzen
            session.syncedToSupabase = true
            session.needsSupabaseResync = false

            progress = .running(step: "Krafttrainings", current: index + 1, total: sessions.count)
        }

        return (sessions.count, totalSetCount)
    }

    /// Lädt alle CardioSessions nach Supabase hoch.
    private func uploadAllCardioSessions(context: ModelContext) async throws -> Int {
        let sessions = (try? context.fetch(FetchDescriptor<CardioSession>())) ?? []
        guard !sessions.isEmpty else { return 0 }

        progress = .running(step: "Cardio-Sessions", current: 0, total: sessions.count)

        let dtos = sessions.map { session in
            SupabaseCardioSessionDTO(
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
        }

        // Einzel-Upserts – Batch würde PGRST102 auslösen da nil-Optionals als fehlende Keys kodiert werden
        for (index, (session, dto)) in zip(sessions, dtos).enumerated() {
            try await client.upsert(endpoint: "cardio_sessions", body: dto)
            session.syncedToSupabase = true
            session.needsSupabaseResync = false
            progress = .running(step: "Cardio-Sessions", current: index + 1, total: sessions.count)
        }

        return sessions.count
    }

    /// Lädt alle OutdoorSessions nach Supabase hoch.
    private func uploadAllOutdoorSessions(context: ModelContext) async throws -> Int {
        let sessions = (try? context.fetch(FetchDescriptor<OutdoorSession>())) ?? []
        guard !sessions.isEmpty else { return 0 }

        progress = .running(step: "Outdoor-Sessions", current: 0, total: sessions.count)

        let dtos = sessions.map { session in
            SupabaseOutdoorSessionDTO(
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
        }

        // Einzel-Upserts – gleicher Grund wie bei Cardio (nil-Optionals → fehlende Keys → PGRST102)
        for (index, (session, dto)) in zip(sessions, dtos).enumerated() {
            try await client.upsert(endpoint: "outdoor_sessions", body: dto)
            session.syncedToSupabase = true
            session.needsSupabaseResync = false
            progress = .running(step: "Outdoor-Sessions", current: index + 1, total: sessions.count)
        }

        return sessions.count
    }

    /// Lädt alle Template-Sets (ExerciseSets ohne Session, mit TrainingPlan) nach Supabase hoch.
    private func uploadAllTemplateSets(context: ModelContext) async throws -> Int {
        // Template-Sets: haben trainingPlan, aber keine session
        let allSets = (try? context.fetch(FetchDescriptor<ExerciseSet>())) ?? []
        let templateSets = allSets.filter { $0.trainingPlan != nil && $0.session == nil }
        guard !templateSets.isEmpty else { return 0 }

        progress = .running(step: "Template-Sets", current: 0, total: templateSets.count)

        let dtos = templateSets.map { set in
            SupabaseExerciseSetDTO(
                id: set.setUUID,
                sessionId: nil,
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

        try await uploadSetsIndividually(dtos)

        progress = .running(step: "Template-Sets", current: templateSets.count, total: templateSets.count)
        return templateSets.count
    }

    // MARK: - Einzeln hochladen

    /// Lädt ExerciseSet-DTOs einzeln hoch.
    /// Batch-Upsert würde PGRST102 auslösen: Swift kodiert nil-Optionals via encodeIfPresent
    /// (Key fehlt im JSON), was PostgREST bei gemischten Batches ablehnt.
    private func uploadSetsIndividually(_ dtos: [SupabaseExerciseSetDTO]) async throws {
        for dto in dtos {
            try await client.upsert(endpoint: "exercise_sets", body: dto)
        }
    }

    // MARK: - UUID-Deduplizierung

    /// Repariert doppelte Sync-UUIDs, die durch CloudKit-Schema-Migration entstehen.
    /// Wenn ein neues Property `var xxxUUID: UUID = UUID()` zum Model hinzugefügt wird,
    /// evaluiert CloudKit den Default EINMAL und vergibt dieselbe UUID an alle bestehenden Datensätze.
    private func deduplicateAllSyncUUIDs(context: ModelContext) {
        var totalFixed = 0

        // TrainingPlan.planUUID
        let plans = (try? context.fetch(FetchDescriptor<TrainingPlan>())) ?? []
        totalFixed += deduplicateUUIDs(plans, label: "TrainingPlan") { $0.planUUID } fix: {
            $0.planUUID = UUID()
            $0.syncedToSupabase = false
        }

        // StrengthSession.sessionUUID
        let strength = (try? context.fetch(FetchDescriptor<StrengthSession>())) ?? []
        totalFixed += deduplicateUUIDs(strength, label: "StrengthSession") { $0.sessionUUID } fix: {
            $0.sessionUUID = UUID()
            $0.syncedToSupabase = false
        }

        // CardioSession.sessionUUID
        let cardio = (try? context.fetch(FetchDescriptor<CardioSession>())) ?? []
        totalFixed += deduplicateUUIDs(cardio, label: "CardioSession") { $0.sessionUUID } fix: {
            $0.sessionUUID = UUID()
            $0.syncedToSupabase = false
        }

        // OutdoorSession.sessionUUID
        let outdoor = (try? context.fetch(FetchDescriptor<OutdoorSession>())) ?? []
        totalFixed += deduplicateUUIDs(outdoor, label: "OutdoorSession") { $0.sessionUUID } fix: {
            $0.sessionUUID = UUID()
            $0.syncedToSupabase = false
        }

        // ExerciseSet.setUUID
        let sets = (try? context.fetch(FetchDescriptor<ExerciseSet>())) ?? []
        totalFixed += deduplicateUUIDs(sets, label: "ExerciseSet") { $0.setUUID } fix: {
            $0.setUUID = UUID()
        }

        if totalFixed > 0 {
            try? context.save()
            print("🔧 Gesamt \(totalFixed) doppelte Sync-UUID(s) korrigiert")
        }
    }

    /// Generische Deduplizierung: findet doppelte UUIDs und ruft `fix` für jedes Duplikat auf.
    /// Gibt die Anzahl reparierter Einträge zurück.
    private func deduplicateUUIDs<T>(
        _ items: [T],
        label: String,
        uuid: (T) -> UUID,
        fix: (T) -> Void
    ) -> Int {
        guard items.count > 1 else { return 0 }

        var seen = Set<UUID>()
        var fixedCount = 0

        for item in items {
            let id = uuid(item)
            if seen.contains(id) {
                fix(item)
                fixedCount += 1
                print("🔧 Doppelte \(label)-UUID repariert: \(id) → \(uuid(item))")
            } else {
                seen.insert(id)
            }
        }

        return fixedCount
    }
}
