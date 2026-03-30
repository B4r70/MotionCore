//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch App                                                        /
// Datei . . . . : ContentView.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Watch App Root View — routet zwischen Idle und Active Workout    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct WatchBaseView: View {
    @EnvironmentObject private var watchSession: WatchSessionManager

    var body: some View {
        Group {
            if watchSession.workoutState == .idle {
                IdleView()
            } else {
                WatchActiveWorkoutView()
            }
        }
        .animation(.easeInOut, value: watchSession.workoutState)
    }
}
