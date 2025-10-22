//
//  CrosstrainerApp.swift
//  Crosstrainer
//
//  Created by Barto on 21.10.25.
//

import SwiftUI
import SwiftData

@main
struct CrosstrainerApp: App {
    var body: some Scene {
        WindowGroup {
            WorkoutListView()
        }
        .modelContainer(for: WorkoutEntry.self)
    }
}
