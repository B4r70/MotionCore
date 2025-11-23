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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutSession.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
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
                .preferredColorScheme(appSettings.appTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
