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
    @Query(sort: \CardioSession.date, order: .reverse)
    private var allWorkouts: [CardioSession]

    @State private var exportURL: URL?

    // Filter-States
    @Binding var selectedDeviceFilter: CardioDevice
    @Binding var selectedTimeFilter: TimeFilter

    // Abruf aus Einstellungen
    @EnvironmentObject private var appSettings: AppSettings

    // Kombinierte Filterlogik (beide Filter)
    var filteredWorkouts: [CardioSession] {
        var workouts = allWorkouts

            // Gerätefilter anwenden
        if selectedDeviceFilter != .none {
            workouts = workouts.filter { $0.cardioDevice == selectedDeviceFilter }
        }

            // Zeitfilter anwenden
        if let dateRange = selectedTimeFilter.dateRange() {
            workouts = workouts.filter {
                $0.date >= dateRange.start && $0.date <= dateRange.end
            }
        }

        return workouts
    }


    // Ansicht "Workouts"
    var body: some View {
        ZStack {
            // Hintergrund aufrufen
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            ScrollView {
                LazyVStack(spacing: 16) {
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
                .scrollViewContentPadding() // Einheitlicher Abstand
            }
            .scrollIndicators(.hidden)
        }
        .overlay {
            if filteredWorkouts.isEmpty {
                EmptyState()
            }
        }
    }
}
