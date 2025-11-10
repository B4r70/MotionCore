//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : ListView.swift                                                   /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout List View with Glassmorphic Design                       /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    @State private var exportURL: URL?
    @State private var selectedFilter: WorkoutDevice = .none // Neu

    // Neu: Gefilterte Workouts basierend auf Auswahl
    var filteredWorkouts: [WorkoutSession] {
        if selectedFilter == .none {
            return allWorkouts
        }
        return allWorkouts.filter { $0.workoutDevice == selectedFilter }
    }

    var body: some View {
        ZStack { // Neu
            // Neu: Gradient Background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.cyan.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Neu: Animated Blob (optional für mehr Liquid-Effekt)
           // AnimatedBlob()

            // Neu: ScrollView statt List
            ScrollView {
                LazyVStack(spacing: 16) { // Neu
                    // Neu: Filter Chips (Glassmorphic)
                    FilterSection(selectedFilter: $selectedFilter, allWorkouts: allWorkouts)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Neu: Workout Cards mit ForEach
                    ForEach(filteredWorkouts) { workout in // Geändert: filteredWorkouts statt allWorkouts
                        NavigationLink {
                            FormView(mode: .edit, workout: workout)
                        } label: {
                            WorkoutCard(workout: workout) // Neu: Custom Card statt RowView
                        }
                        .buttonStyle(.plain) // Neu
                    }
                    .onDelete(perform: deleteWorkouts)
                }
                .padding(.horizontal) // Neu
                .padding(.bottom, 100) // Neu
            }
            .scrollIndicators(.hidden) // Neu
        } // Neu: Ende ZStack
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Neu: Glassmorphic Export Button
                if let url = exportURL {
                    ShareLink(item: url) {
                        ToolbarButton(icon: "square.and.arrow.up") // Neu: Custom Button
                    }
                    .disabled(allWorkouts.isEmpty)
                } else {
                    Button {
                        exportURL = makeExportFile()
                    } label: {
                        ToolbarButton(icon: "square.and.arrow.up") // Neu: Custom Button
                    }
                    .disabled(allWorkouts.isEmpty)
                }
            }
        }
        .overlay {
            if filteredWorkouts.isEmpty { // Geändert: filteredWorkouts statt allWorkouts
                EmptyState() // Neu: Custom Empty State
            }
        }
    }

    // MARK: - Aktionen
    private func deleteWorkouts(at offsets: IndexSet) {
        let workoutsToDelete = offsets.map { filteredWorkouts[$0] } // Neu: filteredWorkouts
        for workout in workoutsToDelete { // Geändert
            modelContext.delete(workout) // Geändert
        }
        try? modelContext.save()
    }

    // MARK: - JSON-Export
    private func makeExportFile() -> URL? {
        guard !allWorkouts.isEmpty else { return nil }

        let pkg = ExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allWorkouts.map { $0.exportItem }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(pkg)
            let filename = "MotionCore-Export-\(Int(Date().timeIntervalSince1970)).json" // Geändert: "MotionCores" → "MotionCore"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Export-Fehler:", error)
            return nil
        }
    }
}


