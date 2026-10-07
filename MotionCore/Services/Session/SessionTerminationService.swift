//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Session-Management                                               /
// Datei . . . . : SessionTerminationService.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.10.2026                                                       /
// Beschreibung  : Zentraler Abräum-Pfad für Löschen/Verwerfen einer Session.       /
//                 Räumt SwiftData, ActiveSessionManager-State und Live Activity    /
//                 gemeinsam ab — kein Pfad kann eins der drei mehr vergessen.      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import ActivityKit
import Foundation
import SwiftData

// MARK: - SessionTerminationService

@MainActor
enum SessionTerminationService {

    // MARK: - Löschen (SwiftData + State + Live Activity)

    /// Löscht die Session aus SwiftData und räumt State + Live Activity ab.
    static func delete(_ session: StrengthSession, context: ModelContext) {
        let sessionID = session.sessionUUID.uuidString
        context.delete(session)
        try? context.save()
        discardRuntimeState(sessionID: sessionID)
    }

    // MARK: - Verwerfen ohne SwiftData-Löschung (Resume-Alert, verwaiste Restore-Info)

    /// Räumt ActiveSessionManager-State und Live Activity ab. Der SwiftData-Datensatz bleibt.
    /// State wird nur verworfen, wenn er zur übergebenen Session gehört.
    static func discardRuntimeState(sessionID: String, manager: ActiveSessionManager = .shared) {
        if manager.getActiveSessionID() == sessionID {
            manager.discardSession()
        }
        Task { await LiveActivityCtrl.endActivity(forSessionID: sessionID) }
    }

    // MARK: - App-Start-Cleanup

    /// Beendet Live Activities, deren Session in SwiftData nicht mehr existiert.
    static func endOrphanedLiveActivities(context: ModelContext) async {
        guard let sessions = try? context.fetch(FetchDescriptor<StrengthSession>()) else { return }
        let existingIDs = Set(sessions.map { $0.sessionUUID.uuidString })
        for activity in Activity<WorkoutActivityAttributes>.activities
        where !existingIDs.contains(activity.attributes.sessionID) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
