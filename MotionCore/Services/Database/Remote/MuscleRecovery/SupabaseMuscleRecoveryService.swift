// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseMuscleRecoveryService.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Lädt den täglichen Muskel-Erholungs-Snapshot nach Supabase      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Fire-and-forget – kein Crash, kein Rethrow bei Fehlern           /
//                Dedup-Logik liegt im Aufrufer (UserDefaults-Key in BaseView)      /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - MuscleRecovery Supabase Service

@MainActor
final class SupabaseMuscleRecoveryService {

    static let shared = SupabaseMuscleRecoveryService()
    private let client = SupabaseClient.shared

    private init() {}

    // MARK: - Upload

    /// Lädt einen Muskel-Erholungs-Snapshot nach Supabase hoch.
    /// Gibt `true` zurück wenn der Upload erfolgreich war, sonst `false`.
    /// Fehler werden nur im Debug-Log ausgegeben, nie weitergeworfen.
    @discardableResult
    func uploadSnapshot(analysis: MuscleRecoveryAnalysis, triggerSource: String) async -> Bool {
        let dto = buildDTO(analysis: analysis, triggerSource: triggerSource)

        do {
            try await client.upsert(endpoint: "muscle_recovery_snapshots", body: dto)
            return true
        } catch {
            #if DEBUG
            print("⚠️ MuscleRecovery Snapshot upload failed:", error)
            #endif
            // Kein Crash, kein Rethrow — Aufrufer wertet Bool aus
            return false
        }
    }

    // MARK: - DTO Aufbau

    private func buildDTO(
        analysis: MuscleRecoveryAnalysis,
        triggerSource: String
    ) -> SupabaseMuscleRecoverySnapshotDTO {

        // Hilfsfunktion: recovery + trained für eine Muskelgruppe aus den Scores holen
        func score(for group: MuscleGroup) -> (recovery: Double, trained: Bool) {
            if let g = analysis.muscleGroupScores.first(where: { $0.muscleGroup == group }) {
                return (g.recoveryPercent, g.wasTrainedInTimeframe)
            }
            // Gruppe nicht trainiert → vollständig erholt
            return (100.0, false)
        }

        return SupabaseMuscleRecoverySnapshotDTO(
            id: UUID(),
            capturedAt: Date(),
            snapshotDate: Calendar.current.startOfDay(for: Date()),
            triggerSource: triggerSource,
            chestRecovery:      score(for: .chest).recovery,
            backRecovery:       score(for: .back).recovery,
            shouldersRecovery:  score(for: .shoulders).recovery,
            armsRecovery:       score(for: .arms).recovery,
            legsRecovery:       score(for: .legs).recovery,
            coreRecovery:       score(for: .core).recovery,
            glutesRecovery:     score(for: .glutes).recovery,
            chestTrained:       score(for: .chest).trained,
            backTrained:        score(for: .back).trained,
            shouldersTrained:   score(for: .shoulders).trained,
            armsTrained:        score(for: .arms).trained,
            legsTrained:        score(for: .legs).trained,
            coreTrained:        score(for: .core).trained,
            glutesTrained:      score(for: .glutes).trained,
            overallRecovery:    analysis.overallRecoveryPercent,
            timeframeDays:      analysis.timeframeDays
        )
    }
}
