// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseMuscleRecoverySnapshot.swift                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Encodable DTO für den täglichen Muskel-Erholungs-Snapshot        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Nur Encodable – kein Lesen zurück aus Supabase                   /
//                CodingKeys müssen vollständig sein – bei vorhandenem CodingKeys   /
//                Enum ignoriert Swift den convertToSnakeCase-Encoder komplett.     /
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - MuscleRecovery Snapshot DTO

struct SupabaseMuscleRecoverySnapshotDTO: Encodable {
    let id: UUID
    let capturedAt: Date
    let snapshotDate: Date
    let triggerSource: String
    let chestRecovery: Double
    let backRecovery: Double
    let shouldersRecovery: Double
    let armsRecovery: Double
    let legsRecovery: Double
    let coreRecovery: Double
    let glutesRecovery: Double
    let chestTrained: Bool
    let backTrained: Bool
    let shouldersTrained: Bool
    let armsTrained: Bool
    let legsTrained: Bool
    let coreTrained: Bool
    let glutesTrained: Bool
    let overallRecovery: Double
    let timeframeDays: Int

    // Alle Felder müssen explizit gelistet sein – bei CodingKeys wird convertToSnakeCase ignoriert
    enum CodingKeys: String, CodingKey {
        case id
        case capturedAt         = "captured_at"
        case snapshotDate       = "snapshot_date"
        case triggerSource      = "trigger_source"
        case chestRecovery      = "chest_recovery"
        case backRecovery       = "back_recovery"
        case shouldersRecovery  = "shoulders_recovery"
        case armsRecovery       = "arms_recovery"
        case legsRecovery       = "legs_recovery"
        case coreRecovery       = "core_recovery"
        case glutesRecovery     = "glutes_recovery"
        case chestTrained       = "chest_trained"
        case backTrained        = "back_trained"
        case shouldersTrained   = "shoulders_trained"
        case armsTrained        = "arms_trained"
        case legsTrained        = "legs_trained"
        case coreTrained        = "core_trained"
        case glutesTrained      = "glutes_trained"
        case overallRecovery    = "overall_recovery"
        case timeframeDays      = "timeframe_days"
    }
}
