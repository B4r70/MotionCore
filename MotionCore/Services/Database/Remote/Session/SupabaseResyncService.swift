// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services                                                         /
// Datei . . . . : SupabaseResyncService.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 08.03.2026                                                       /
// Beschreibung  : Synct Sessions die nach erstem Upload lokal geändert wurden    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Läuft bei App-Start und Foreground-Rückkehr.                  /
//                needsSupabaseResync wird nach Erfolg auf false gesetzt.        /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftData

/// Lädt Sessions hoch, die nach erstem Supabase-Upload lokal verändert wurden.
/// Wird bei App-Start und Foreground-Rückkehr aufgerufen.
@MainActor
final class SupabaseResyncService {

    static let shared = SupabaseResyncService()
    private init() {}

    // MARK: - Resync

    /// Sucht alle Sessions mit `needsSupabaseResync == true` und lädt sie hoch.
    /// Nach erfolgreichem Upload: `needsSupabaseResync = false`.
    func syncPendingChanges(in context: ModelContext) async {
        var didChange = false

        // MARK: StrengthSessions
        let strengthSessions = (try? context.fetch(
            FetchDescriptor<StrengthSession>(
                predicate: #Predicate { $0.needsSupabaseResync }
            )
        )) ?? []

        for session in strengthSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.needsSupabaseResync = false
                didChange = true
                print("🔄 StrengthSession re-synced: \(session.sessionUUID)")
            } else {
                print("⚠️ StrengthSession re-sync fehlgeschlagen: \(session.sessionUUID)")
            }
        }

        // MARK: CardioSessions
        let cardioSessions = (try? context.fetch(
            FetchDescriptor<CardioSession>(
                predicate: #Predicate { $0.needsSupabaseResync }
            )
        )) ?? []

        for session in cardioSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.needsSupabaseResync = false
                didChange = true
                print("🔄 CardioSession re-synced: \(session.sessionUUID)")
            } else {
                print("⚠️ CardioSession re-sync fehlgeschlagen: \(session.sessionUUID)")
            }
        }

        // MARK: OutdoorSessions
        let outdoorSessions = (try? context.fetch(
            FetchDescriptor<OutdoorSession>(
                predicate: #Predicate { $0.needsSupabaseResync }
            )
        )) ?? []

        for session in outdoorSessions {
            let success = await SupabaseSessionService.shared.upload(session)
            if success {
                session.needsSupabaseResync = false
                didChange = true
                print("🔄 OutdoorSession re-synced: \(session.sessionUUID)")
            } else {
                print("⚠️ OutdoorSession re-sync fehlgeschlagen: \(session.sessionUUID)")
            }
        }

        // Flags persistieren
        if didChange {
            try? context.save()
        }
    }
}
