//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch App                                                        /
// Datei . . . . : MotionCoreWatchApp.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Watch App Entry Point                                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

@main
struct MotionCoreWatchApp: App {

    // WatchSessionManager beim App-Start initialisieren
    @StateObject private var watchSession = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchBaseView()
                .environmentObject(watchSession)
        }
    }
}
