// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : MotionCoreApp.swift                                              /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Main Application File                                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

@main
struct MotionCoreApp: App {
    @StateObject private var settings = AppSettings.shared
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
                .preferredColorScheme(settings.appTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
