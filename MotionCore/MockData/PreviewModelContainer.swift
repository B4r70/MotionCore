//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Section  . . : Mock Data                                                        /
// Filename . . : PreviewModelContainer.swift                                      /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 17.11.2025                                                       /
// Function . . : Modelcontainer für die Aufbereitung der Preview                  /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftData
import Foundation

#if DEBUG
@MainActor
struct PreviewData {
    static let sharedContainer: ModelContainer = {
        // In-Memory-Konfiguration für die Preview
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: WorkoutSession.self,
                                            configurations: config)

        // Mock-Daten in den Kontext einfügen
        let context = container.mainContext
        WorkoutSession.previewMockData.forEach { context.insert($0) }

        return container
    }()
}
#endif
