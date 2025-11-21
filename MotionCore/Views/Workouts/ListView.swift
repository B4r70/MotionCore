//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Liste                                                    /
// Datei . . . . : ListView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung aller erfassten Workouts                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    @State private var exportURL: URL?
    @State private var selectedFilter: WorkoutDevice = .none

    // Abruf aus Einstellungen
    @State private var settings = AppSettings.shared

    var filteredWorkouts: [WorkoutSession] {
        if selectedFilter == .none {
            return allWorkouts
        }
        return allWorkouts.filter { $0.workoutDevice == selectedFilter }
    }

    // Ansicht "Workouts"
    var body: some View {
        ZStack {
            // Hintergrund aufrufen
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Filter Chips (Glassmorphic)
                    FilterSection(selectedFilter: $selectedFilter, allWorkouts: allWorkouts)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Workout Cards mit ForEach
                    ForEach(filteredWorkouts) { workout in
                        NavigationLink {
                            FormView(mode: .edit, workout: workout)
                        } label: {
                            WorkoutCard(allWorkouts: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .overlay {
            if filteredWorkouts.isEmpty { // Geändert: filteredWorkouts statt allWorkouts
                EmptyState()
            }
        }
    }
}
    // MARK: Statistic Preview
#Preview("List View") {
    ListView()
        .modelContainer(PreviewData.sharedContainer)
}
