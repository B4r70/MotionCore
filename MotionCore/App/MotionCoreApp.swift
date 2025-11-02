//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : MotionCoreApp.swift                                              /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Main Application File                                            /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

@main
struct MotionCoreApp: App {
    var body: some Scene {
        WindowGroup {
            BaseView()
        }
        .modelContainer(for: WorkoutSession.self)
    }
}
