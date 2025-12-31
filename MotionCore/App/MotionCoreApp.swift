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
    // State für Userdefaults in den AppSettings
    @StateObject private var appSettings = AppSettings.shared

    // State für den ActiveSessionManager für Wiederherstellung von abgebrochenen Sitzungen
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
                .environmentObject(appSettings) // AppSettings sind Userdefaults und von überall zugreifbar
                .environmentObject(activeSessionManager) // SessionManager als Environment
                .preferredColorScheme(appSettings.appTheme.colorScheme)
                .handleSessionLifecycle() // Automatisches Background-/Foreground-Handling
                .onAppear {
                    checkForActiveSession()
                }
                .alert("Aktive Session gefunden", isPresented: $showSessionRestoreAlert) {
                    Button("Fortsetzen") {
                            // Navigation zur aktiven Session wird in BaseView gehandelt
                    }
                    Button("Verwerfen", role: .destructive) {
                        activeSessionManager.discardSession()
                    }
                } message: {
                    if let info = pendingRestoreInfo {
                        Text("Du hast eine pausierte \(info.workoutType.description)-Session. Möchtest du fortfahren?")
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
}






