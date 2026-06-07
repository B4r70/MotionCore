// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseMigrationService.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.03.2026                                                       /
// Beschreibung  : Migriert alle lokalen Sessions nach Supabase (einmalig)          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Sequenzieller Upload schützt vor Rate-Limit beim Anon-Key.        /
//                syncedToSupabase-Flag wird nach erfolgreichem Upload gesetzt.     /
// ---------------------------------------------------------------------------------/
//

import Foundation
import Combine
import SwiftData

/// Migriert alle lokalen Sessions, die noch nicht in Supabase hochgeladen wurden.
/// Wird einmalig manuell vom User in den Einstellungen gestartet.
@MainActor
final class SupabaseMigrationService: ObservableObject {

    static let shared = SupabaseMigrationService()

    // MARK: - Published State

    @Published var isRunning: Bool = false
    @Published var uploadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var failedCount: Int = 0

    /// Gesamtfortschritt 0.0–1.0
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(uploadedCount + failedCount) / Double(totalCount)
    }

    /// true wenn Migration abgeschlossen (nicht laufend, mindestens eine Session verarbeitet)
    var isDone: Bool { !isRunning && totalCount > 0 }

    private init() {}

    // MARK: - Migration

    /// Lädt alle lokalen Sessions mit syncedToSupabase == false sequenziell nach Supabase hoch.
    func migrate(context: ModelContext) async {
        guard !isRunning else { return }

        isRunning = true
        uploadedCount = 0
        failedCount = 0
        totalCount = 0

        // Alle ungemigrierten Sessions laden
        let strengthSessions = (try? context.fetch(
            FetchDescriptor<StrengthSession>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        let cardioSessions = (try? context.fetch(
            FetchDescriptor<CardioSession>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        let outdoorSessions = (try? context.fetch(
            FetchDescriptor<OutdoorSession>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        let trainingPlans = (try? context.fetch(
            FetchDescriptor<TrainingPlan>(
                predicate: #Predicate { !$0.syncedToSupabase }
            )
        )) ?? []

        totalCount = strengthSessions.count + cardioSessions.count
                   + outdoorSessions.count + trainingPlans.count

        guard totalCount > 0 else {
            isRunning = false
            return
        }

        // Readiness-Snapshots vorladen für Strength-Session-Zuordnung
        let readinessIndex: [UUID: SessionReadiness] = strengthSessions.isEmpty ? [:] : Dictionary(
            uniqueKeysWithValues: ((try? context.fetch(FetchDescriptor<SessionReadiness>())) ?? []).map { ($0.id, $0) }
        )

        // Sequenzieller Upload (schützt vor Rate-Limit beim Anon-Key)
        for session in strengthSessions {
            let readiness = session.sessionReadinessID.flatMap { readinessIndex[$0] }
            let success = await SupabaseSessionService.shared.upload(session, readiness: readiness)
            if success {
                session.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        for session in cardioSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        for session in outdoorSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        for plan in trainingPlans {
            let success = await SupabaseSessionService.shared.upload(plan)
            if success {
                plan.syncedToSupabase = true
                uploadedCount += 1
            } else {
                failedCount += 1
            }
        }

        // Alle gesetzten Flags persistieren
        try? context.save()

        isRunning = false
        print("✅ Migration abgeschlossen: \(uploadedCount) hochgeladen, \(failedCount) fehlgeschlagen")
    }
}
