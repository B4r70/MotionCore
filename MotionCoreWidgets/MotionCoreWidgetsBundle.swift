//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Widget Extension                                                 /
// Datei . . . . : MotionCoreWidgetsBundle.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Widget-Bundle — registriert alle Widgets und die Live Activity   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

@main
struct MotionCoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // MARK: - Home Screen Widgets
        StreakWidget()
        WeeklyGoalWidget()
        LastWorkoutWidget()
        TrainingOverviewWidget()

        // MARK: - Lock Screen Widgets
        CircularStatusWidget()
        InlineStatusWidget()

        // MARK: - Control Widget (bestehend)
        MotionCoreWidgetsControl()

        // MARK: - Live Activity (bestehend)
        MotionCoreWidgetsLiveActivity()
    }
}
