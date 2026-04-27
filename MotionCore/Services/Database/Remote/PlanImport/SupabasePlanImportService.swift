// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Database / Remote / PlanImport                       /
// Datei . . . . : SupabasePlanImportService.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.04.2026                                                       /
// Beschreibung  : Supabase-Zugriff für pending_plan_imports                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation

/// Holt wartende Plan-Imports und markiert sie als akzeptiert / abgelehnt.
final class SupabasePlanImportService {

    static let shared = SupabasePlanImportService()
    private let client = SupabaseClient.shared

    private init() {}

    // MARK: - Fetch

    /// Lädt alle Einträge mit status=pending aus pending_plan_imports.
    func fetchPending() async throws -> [SupabasePendingPlanImportDTO] {
        let result: [SupabasePendingPlanImportDTO] = try await client.get(
            endpoint: "pending_plan_imports",
            queryItems: [URLQueryItem(name: "status", value: "eq.pending")]
        )
        print("📥 PlanImport: \(result.count) ausstehende Einträge geladen")
        return result
    }

    // MARK: - Mark Accepted

    /// Setzt den Status eines Imports auf 'accepted' und speichert die iOS-seitige planUUID.
    func markAccepted(id: UUID, planUUID: UUID) async throws {
        let body = MarkImportAcceptedBody(
            status: "accepted",
            acceptedAt: Date(),
            acceptedPlanId: planUUID,
            updatedAt: Date()
        )
        try await client.patchWhere(
            endpoint: "pending_plan_imports",
            filter: "id=eq.\(id.uuidString)",
            body: body
        )
        print("✅ PlanImport \(id.uuidString) als accepted markiert (planUUID: \(planUUID.uuidString))")
    }

    // MARK: - Mark Rejected

    /// Setzt den Status eines Imports auf 'rejected'.
    func markRejected(id: UUID) async throws {
        let body = MarkImportRejectedBody(
            status: "rejected",
            rejectedAt: Date(),
            updatedAt: Date()
        )
        try await client.patchWhere(
            endpoint: "pending_plan_imports",
            filter: "id=eq.\(id.uuidString)",
            body: body
        )
        print("✅ PlanImport \(id.uuidString) als rejected markiert")
    }
}
