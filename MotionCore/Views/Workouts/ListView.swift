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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // Glassmorphic Export Button
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
                EmptyState()
            }
        }
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

    // MARK: Statistic Preview
#Preview("Statistiken") {
    ListView()
        .modelContainer(PreviewData.sharedContainer)
}
