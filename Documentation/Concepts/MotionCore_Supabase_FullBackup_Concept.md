# MotionCore: Supabase Full-Backup Service

## Ziel

Erstelle einen `SupabaseFullBackupService`, der **alle** lokalen SwiftData-Daten vollständig nach Supabase hochlädt. Das betrifft:

1. **Alle Sessions** (StrengthSession, CardioSession, OutdoorSession)
2. **Alle TrainingPlans** inkl. ihrer Template-Sets
3. **Alle ExerciseSets** (sowohl Session-Sets als auch Template-Sets)

Der Service soll:
- Einmalig manuell aufrufbar sein (z.B. über einen Button in den Einstellungen)
- Idempotent sein (kann mehrfach laufen ohne Duplikate – nutzt UPSERT)
- Fortschritt anzeigen (Anzahl hochgeladener Records)
- `syncedToSupabase = true` setzen nach erfolgreichem Upload

---

## Aktueller Stand

### Bereits vorhanden:
- `SupabaseSessionService.swift` – lädt einzelne Sessions hoch
- `SupabaseSessionModels.swift` – enthält DTOs
- `SupabaseClient.swift` – HTTP-Client mit `upsert()` Methode

### Problem:
- Template-Sets (ExerciseSets mit `trainingPlan != nil` und `session == nil`) werden NICHT hochgeladen
- Aktuell: `exercise_sets.session_id` ist NOT NULL in Supabase → Template-Sets können nicht gespeichert werden

---

## Schritt 1: Supabase Schema-Änderung

Die Spalte `session_id` in `exercise_sets` muss NULLABLE werden, damit Template-Sets gespeichert werden können.

```sql
-- Migration: allow_template_sets_in_exercise_sets
ALTER TABLE public.exercise_sets 
ALTER COLUMN session_id DROP NOT NULL;
```

Nach dieser Änderung:
- Session-Sets haben `session_id` gesetzt, `training_plan_id` optional
- Template-Sets haben `training_plan_id` gesetzt, `session_id = NULL`

---

## Schritt 2: Neue Datei `SupabaseFullBackupService.swift`

Erstelle die Datei unter `/Services/` oder im Hauptverzeichnis.

### Struktur:

```swift
import Foundation
import SwiftData

/// Einmaliger Full-Backup aller lokalen Daten nach Supabase.
/// Idempotent durch UPSERT – kann mehrfach ausgeführt werden.
@MainActor
final class SupabaseFullBackupService: ObservableObject {
    
    static let shared = SupabaseFullBackupService()
    private let client = SupabaseClient.shared
    
    // MARK: - Progress Tracking
    @Published var isRunning = false
    @Published var progress: BackupProgress = .idle
    
    enum BackupProgress: Equatable {
        case idle
        case running(step: String, current: Int, total: Int)
        case completed(stats: BackupStats)
        case failed(error: String)
    }
    
    struct BackupStats: Equatable {
        let strengthSessions: Int
        let cardioSessions: Int
        let outdoorSessions: Int
        let trainingPlans: Int
        let exerciseSets: Int
        let templateSets: Int
    }
    
    private init() {}
    
    // MARK: - Main Backup Function
    
    func runFullBackup(context: ModelContext) async {
        guard !isRunning else { return }
        isRunning = true
        progress = .running(step: "Starte Backup...", current: 0, total: 6)
        
        var stats = BackupStats(
            strengthSessions: 0,
            cardioSessions: 0,
            outdoorSessions: 0,
            trainingPlans: 0,
            exerciseSets: 0,
            templateSets: 0
        )
        
        do {
            // 1. TrainingPlans (müssen zuerst, wegen Foreign Key)
            progress = .running(step: "TrainingPlans...", current: 1, total: 6)
            stats = BackupStats(
                strengthSessions: stats.strengthSessions,
                cardioSessions: stats.cardioSessions,
                outdoorSessions: stats.outdoorSessions,
                trainingPlans: try await uploadAllTrainingPlans(context: context),
                exerciseSets: stats.exerciseSets,
                templateSets: stats.templateSets
            )
            
            // 2. StrengthSessions
            progress = .running(step: "StrengthSessions...", current: 2, total: 6)
            stats = BackupStats(
                strengthSessions: try await uploadAllStrengthSessions(context: context),
                cardioSessions: stats.cardioSessions,
                outdoorSessions: stats.outdoorSessions,
                trainingPlans: stats.trainingPlans,
                exerciseSets: stats.exerciseSets,
                templateSets: stats.templateSets
            )
            
            // 3. CardioSessions
            progress = .running(step: "CardioSessions...", current: 3, total: 6)
            stats = BackupStats(
                strengthSessions: stats.strengthSessions,
                cardioSessions: try await uploadAllCardioSessions(context: context),
                outdoorSessions: stats.outdoorSessions,
                trainingPlans: stats.trainingPlans,
                exerciseSets: stats.exerciseSets,
                templateSets: stats.templateSets
            )
            
            // 4. OutdoorSessions
            progress = .running(step: "OutdoorSessions...", current: 4, total: 6)
            stats = BackupStats(
                strengthSessions: stats.strengthSessions,
                cardioSessions: stats.cardioSessions,
                outdoorSessions: try await uploadAllOutdoorSessions(context: context),
                trainingPlans: stats.trainingPlans,
                exerciseSets: stats.exerciseSets,
                templateSets: stats.templateSets
            )
            
            // 5. Session ExerciseSets (bereits in uploadAllStrengthSessions enthalten)
            // Hier nur für Stats-Zählung
            
            // 6. Template-Sets (Sets ohne Session)
            progress = .running(step: "Template-Sets...", current: 5, total: 6)
            stats = BackupStats(
                strengthSessions: stats.strengthSessions,
                cardioSessions: stats.cardioSessions,
                outdoorSessions: stats.outdoorSessions,
                trainingPlans: stats.trainingPlans,
                exerciseSets: stats.exerciseSets,
                templateSets: try await uploadAllTemplateSets(context: context)
            )
            
            // Fertig
            progress = .completed(stats: stats)
            try? context.save()
            
        } catch {
            progress = .failed(error: error.localizedDescription)
        }
        
        isRunning = false
    }
    
    // MARK: - Upload Functions
    
    private func uploadAllTrainingPlans(context: ModelContext) async throws -> Int {
        let plans = try context.fetch(FetchDescriptor<TrainingPlan>())
        
        for plan in plans {
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
        }
        
        return plans.count
    }
    
    private func uploadAllStrengthSessions(context: ModelContext) async throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<StrengthSession>())
        
        for session in sessions {
            // Session selbst
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
            
            // ExerciseSets dieser Session
            let setDTOs = session.safeExerciseSets.map { set in
                SupabaseExerciseSetDTO(
                    id: set.setUUID,
                    sessionId: session.sessionUUID,
                    trainingPlanId: nil, // Session-Set, nicht Template
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
            
            session.syncedToSupabase = true
            session.needsSupabaseResync = false
        }
        
        return sessions.count
    }
    
    private func uploadAllCardioSessions(context: ModelContext) async throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<CardioSession>())
        
        for session in sessions {
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
            
            session.syncedToSupabase = true
            session.needsSupabaseResync = false
        }
        
        return sessions.count
    }
    
    private func uploadAllOutdoorSessions(context: ModelContext) async throws -> Int {
        let sessions = try context.fetch(FetchDescriptor<OutdoorSession>())
        
        for session in sessions {
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
            
            session.syncedToSupabase = true
            session.needsSupabaseResync = false
        }
        
        return sessions.count
    }
    
    private func uploadAllTemplateSets(context: ModelContext) async throws -> Int {
        // Template-Sets: Haben TrainingPlan aber KEINE Session
        let allSets = try context.fetch(FetchDescriptor<ExerciseSet>())
        let templateSets = allSets.filter { $0.trainingPlan != nil && $0.session == nil }
        
        let dtos = templateSets.compactMap { set -> SupabaseExerciseSetDTO? in
            guard let planUUID = set.trainingPlan?.planUUID else { return nil }
            
            return SupabaseExerciseSetDTO(
                id: set.setUUID,
                sessionId: nil, // Template-Set hat keine Session
                trainingPlanId: planUUID,
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
        
        if !dtos.isEmpty {
            try await client.upsert(endpoint: "exercise_sets", body: dtos)
        }
        
        return dtos.count
    }
}
```

---

## Schritt 3: DTO-Anpassung in `SupabaseSessionModels.swift`

Das `SupabaseExerciseSetDTO` muss `sessionId` als Optional haben:

```swift
struct SupabaseExerciseSetDTO: Codable {
    let id: UUID
    let sessionId: UUID?  // ← War vorher non-optional, jetzt Optional für Template-Sets
    let trainingPlanId: UUID?
    // ... rest bleibt gleich
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case trainingPlanId = "training_plan_id"
        // ...
    }
}
```

---

## Schritt 4: UI-Integration in `DataSettingsView.swift`

Füge einen Button zum manuellen Auslösen des Backups hinzu:

```swift
@StateObject private var backupService = SupabaseFullBackupService.shared

// Im Body:
Section("Supabase Backup") {
    Button {
        Task {
            await backupService.runFullBackup(context: modelContext)
        }
    } label: {
        HStack {
            Text("Vollständiges Backup starten")
            Spacer()
            if backupService.isRunning {
                ProgressView()
            }
        }
    }
    .disabled(backupService.isRunning)
    
    // Fortschrittsanzeige
    switch backupService.progress {
    case .idle:
        EmptyView()
    case .running(let step, let current, let total):
        Text("\(step) (\(current)/\(total))")
            .font(.caption)
            .foregroundStyle(.secondary)
    case .completed(let stats):
        VStack(alignment: .leading, spacing: 4) {
            Text("✅ Backup abgeschlossen")
                .foregroundStyle(.green)
            Text("\(stats.strengthSessions) Kraft, \(stats.cardioSessions) Cardio, \(stats.outdoorSessions) Outdoor")
                .font(.caption)
            Text("\(stats.trainingPlans) Pläne, \(stats.templateSets) Template-Sets")
                .font(.caption)
        }
    case .failed(let error):
        Text("❌ Fehler: \(error)")
            .foregroundStyle(.red)
            .font(.caption)
    }
}
```

---

## Schritt 5: Verifizierung

Nach dem Backup sollte folgendes in Supabase zu sehen sein:

```sql
-- Prüf-Query für vollständiges Backup
SELECT 
    'strength_sessions' as table_name, COUNT(*) as count FROM public.strength_sessions
UNION ALL SELECT 'cardio_sessions', COUNT(*) FROM public.cardio_sessions
UNION ALL SELECT 'outdoor_sessions', COUNT(*) FROM public.outdoor_sessions
UNION ALL SELECT 'training_plans', COUNT(*) FROM public.training_plans
UNION ALL SELECT 'exercise_sets (session)', COUNT(*) FROM public.exercise_sets WHERE session_id IS NOT NULL
UNION ALL SELECT 'exercise_sets (template)', COUNT(*) FROM public.exercise_sets WHERE session_id IS NULL;
```

---

## Zusammenfassung der Änderungen

| Datei | Änderung |
|-------|----------|
| **Supabase Schema** | `session_id` in `exercise_sets` → NULLABLE |
| **SupabaseSessionModels.swift** | `sessionId` in DTO → `UUID?` |
| **SupabaseFullBackupService.swift** | **NEU** – Kompletter Backup-Service |
| **DataSettingsView.swift** | Button + Fortschrittsanzeige hinzufügen |

---

## Wichtige Hinweise

1. **Reihenfolge beachten**: TrainingPlans müssen VOR den Template-Sets hochgeladen werden (Foreign Key)
2. **Idempotent**: Service nutzt UPSERT, kann beliebig oft laufen
3. **Offline-Safe**: Bei Fehlern wird der Fortschritt angezeigt, nichts geht verloren
4. **Kein Löschen**: Service löscht nie Daten in Supabase, nur INSERT/UPDATE

---

## Felder-Abgleich: SwiftData ↔ Supabase

### StrengthSession ✅ Vollständig
Alle Felder werden bereits korrekt gemappt.

### CardioSession ✅ Vollständig
Alle Felder werden bereits korrekt gemappt.

### OutdoorSession ✅ Vollständig
Alle Felder werden bereits korrekt gemappt.

### TrainingPlan ✅ Vollständig
Alle Felder werden bereits korrekt gemappt.

### ExerciseSet ✅ Vollständig
Alle Felder werden bereits korrekt gemappt. Einzige Änderung: `sessionId` wird Optional.
