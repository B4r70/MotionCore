//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch Complications                                              /
// Datei . . . . : MotionCoreWatchComplications.swift                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : WidgetBundle für alle Watch Face Complications                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

// Dieser Bundle registriert alle Complications für das Watch-Target.
// KEIN @main hier — der @main Entry Point ist MotionCoreWatchApp.
struct MotionCoreWatchComplications: WidgetBundle {
    var body: some Widget {
        StreakComplication()
        WeeklyProgressComplication()
    }
}
