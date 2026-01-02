//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Live Activity                                                    /
// Datei . . . . : MotionCoreWidgetsBundle.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.01.2026                                                       /
// Beschreibung  : Live Activity UI für Dynamic Island und Sperrbildschirm          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import WidgetKit
import SwiftUI

@main
struct MotionCoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MotionCoreWidgets()
        MotionCoreWidgetsControl()
        MotionCoreWidgetsLiveActivity()
    }
}
