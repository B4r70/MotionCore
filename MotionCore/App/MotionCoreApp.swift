// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Hauptprogramm                                                    /
// Datei . . . . : MotionCoreApp.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Einstiegspunkt und Startkonfiguration für den Ablauf der App     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

@main
struct MotionCoreApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var activeSessionManager = ActiveSessionManager.shared

    // State für Session-Wiederherstellungs-Alert
    @State private var showSessionRestoreAlert = false
    @State private var pendingRestoreInfo: (sessionID: String, workoutType: WorkoutType)?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CardioSession.self,
            StrengthSession.self,
            OutdoorSession.self,
            ExerciseSet.self,
            Exercise.self,
            TrainingPlan.self,
            TrainingEntry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            BaseView()
                .environmentObject(appSettings)
                .environmentObject(activeSessionManager)
                .preferredColorScheme(appSettings.appTheme.colorScheme)
                .handleSessionLifecycle()
                .onAppear {
                    repairSnapshotsOnLaunch()
                    checkForActiveSession()
                }
                .alert("Aktive Session gefunden", isPresented: $showSessionRestoreAlert) {
                    Button("Fortsetzen") {
                        restoreSession()
                    }
                    Button("Verwerfen", role: .cancel) {
                        activeSessionManager.discardSession()
                        pendingRestoreInfo = nil
                    }
                } message: {
                    if let info = pendingRestoreInfo {
                        let formattedTime = activeSessionManager.formattedElapsedTime
                        Text("Du hast eine pausierte \(info.workoutType.description)-Session (\(formattedTime)). Möchtest du fortfahren?")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Session Wiederherstellung

    // Prüft beim App-Start ob eine aktive Session wiederhergestellt werden muss
    private func checkForActiveSession() {
        if let restoreInfo = activeSessionManager.getRestorationInfo() {
            pendingRestoreInfo = restoreInfo

            // Kurze Verzögerung damit die UI vollständig geladen ist
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showSessionRestoreAlert = true
            }
        }
    }

    // Stellt die Session wieder her und navigiert zur entsprechenden View
    private func restoreSession() {
        guard let info = pendingRestoreInfo else { return }

        // Notification an BaseView senden
        NotificationCenter.default.post(
            name: .restoreActiveSession,
            object: nil,
            userInfo: [
                "sessionID": info.sessionID,
                "workoutType": info.workoutType
            ]
        )

        pendingRestoreInfo = nil
    }

    private func repairSnapshotsOnLaunch() {
        let context = ModelContext(sharedModelContainer)

        do {
            let descriptor = FetchDescriptor<ExerciseSet>()
            let sets = try context.fetch(descriptor)

            var changed = 0
            for s in sets {
                let uuid = s.exerciseUUIDSnapshot
                if !uuid.isEmpty && UUID(uuidString: uuid) == nil {
                    // kaputter Snapshot -> leeren, damit UI nicht falsche URLs baut
                    s.exerciseUUIDSnapshot = ""
                    changed += 1
                }
            }

            if changed > 0 {
                try context.save()
                print("🧹 Repair: cleaned \(changed) invalid exerciseUUIDSnapshot values")
            }
        } catch {
            print("⚠️ Repair failed:", error)
        }
    }
}
