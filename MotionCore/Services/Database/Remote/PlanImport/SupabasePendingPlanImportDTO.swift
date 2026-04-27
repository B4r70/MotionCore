// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Database / Remote / PlanImport                       /
// Datei . . . . : SupabasePendingPlanImportDTO.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Codable-DTOs für pending_plan_imports (Top + Payload + Nested)  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : CodingKeys sind vollständig gelistet (CodingKeys-Trap!).          /
//                Bei vorhandenem CodingKeys-Enum ignoriert Swift convertToSnakeCase./
// ---------------------------------------------------------------------------------/
//
import Foundation

// MARK: - Top-Level DTO (Datenbankzeile)

/// Repräsentiert eine Zeile aus der Tabelle `pending_plan_imports`.
struct SupabasePendingPlanImportDTO: Decodable, Identifiable {
    /// Aktuell unterstützte Import-Schema-Version. Einträge mit höherer Version werden übersprungen.
    static let supportedImportSchemaVersion: Int = 1

    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let schemaVersion: Int
    let source: String
    let title: String
    let planDescription: String
    let planType: String
    let exerciseCount: Int
    let setCount: Int
    let planData: PlanImportPayloadDTO
    let status: String
    let acceptedAt: Date?
    let rejectedAt: Date?
    let acceptedPlanId: UUID?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt          = "created_at"
        case updatedAt          = "updated_at"
        case schemaVersion      = "schema_version"
        case source
        case title
        case planDescription    = "plan_description"
        case planType           = "plan_type"
        case exerciseCount      = "exercise_count"
        case setCount           = "set_count"
        case planData           = "plan_data"
        case status
        case acceptedAt         = "accepted_at"
        case rejectedAt         = "rejected_at"
        case acceptedPlanId     = "accepted_plan_id"
        case expiresAt          = "expires_at"
    }
}

// MARK: - Payload-DTO (Inhalt von plan_data JSONB)

/// Inhalt des `plan_data`-JSONB-Felds.
struct PlanImportPayloadDTO: Decodable {
    let schemaVersion: Int
    let title: String
    let description: String
    let planType: String
    let startDate: String        // ISO-8601 Date-String ("2026-04-28")
    let endDate: String?         // optional
    let exercises: [PlanImportExerciseDTO]

    enum CodingKeys: String, CodingKey {
        case schemaVersion      = "schema_version"
        case title
        case description
        case planType           = "plan_type"
        case startDate          = "start_date"
        case endDate            = "end_date"
        case exercises
    }
}

// MARK: - Exercise-DTO (ein Eintrag in exercises[])

struct PlanImportExerciseDTO: Decodable {
    let sortOrder: Int
    let groupId: String?
    let supersetGroupId: String?
    let exerciseUuid: String
    let exerciseName: String
    let exerciseMediaAssetName: String
    let sets: [PlanImportSetDTO]

    enum CodingKeys: String, CodingKey {
        case sortOrder              = "sort_order"
        case groupId                = "group_id"
        case supersetGroupId        = "superset_group_id"
        case exerciseUuid           = "exercise_uuid"
        case exerciseName           = "exercise_name"
        case exerciseMediaAssetName = "exercise_media_asset_name"
        case sets
    }
}

// MARK: - Set-DTO (ein Eintrag in sets[])

struct PlanImportSetDTO: Decodable {
    let setNumber: Int
    let setKind: String
    let weight: Double
    let weightPerSide: Bool
    let reps: Int
    let duration: Int
    let distance: Double
    let restSeconds: Int
    let targetRepsMin: Int
    let targetRepsMax: Int
    let targetRir: Int
    let notes: String

    enum CodingKeys: String, CodingKey {
        case setNumber      = "set_number"
        case setKind        = "set_kind"
        case weight
        case weightPerSide  = "weight_per_side"
        case reps
        case duration
        case distance
        case restSeconds    = "rest_seconds"
        case targetRepsMin  = "target_reps_min"
        case targetRepsMax  = "target_reps_max"
        case targetRir      = "target_rir"
        case notes
    }
}

// MARK: - PATCH-Bodies für Statusänderungen

/// Body für PATCH pending_plan_imports → status = accepted
struct MarkImportAcceptedBody: Encodable {
    let status: String
    let acceptedAt: Date
    let acceptedPlanId: UUID
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case status
        case acceptedAt     = "accepted_at"
        case acceptedPlanId = "accepted_plan_id"
        case updatedAt      = "updated_at"
    }
}

/// Body für PATCH pending_plan_imports → status = rejected
struct MarkImportRejectedBody: Encodable {
    let status: String
    let rejectedAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case status
        case rejectedAt = "rejected_at"
        case updatedAt  = "updated_at"
    }
}
