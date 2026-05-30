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

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchBaseView()
                .environmentObject(watchSession)
                .onChange(of: scenePhase) { _, newPhase in
                    // Beim Aufwachen / Foreground: verwaiste Session mit Desired-State abgleichen
                    if newPhase == .active {
                        WatchSessionManager.shared.reconcileHealthStateIfNeeded()
                    }
                }
        }
    }
}
