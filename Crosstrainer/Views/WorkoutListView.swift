//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutListView.swift                                            /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout List View                                                /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workouts: [WorkoutSession]

    @State private var showingAddView = false
    @State private var exportURL: URL? = nil   // Datei-URL für ShareLink

    // Lokaler Draft für "Add"
    @State private var draft = WorkoutSession(
        date: .now,
        duration: 0,
        distance: 0.0,
        calories: 0,
        difficulty: 1,
        heartRate: 0,
        bodyWeight: 0,
        intensity: .none,
        trainingProgram: .manual,
        workoutDevice: .none
    )

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        WorkoutFormView(mode: .edit, workout: workout)
                    } label: {
                        WorkoutRowView(workout: workout)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Center title between the buttons
                ToolbarItem(placement: .principal) {
                    Text("MotionCore")
                        .font(.title)          // inline-Bar: headline ist die visuelle Norm
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)
                }

                // Trailing: Add
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddView = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Neues Workout")
                }

                // Leading: Export / Share
                ToolbarItem(placement: .topBarLeading) {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(workouts.isEmpty)
                    } else {
                        Button { exportURL = makeExportFile() } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(workouts.isEmpty)
                    }
                }
            }
            // Add-Sheet
            .sheet(isPresented: $showingAddView) {
                NavigationStack {
                    WorkoutFormView(mode: .add, workout: draft)
                        .navigationTitle("Neues Workout")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .onAppear {
                    // Draft sauber zurücksetzen, bevor der Nutzer editiert
                    draft = WorkoutSession(
                        date: .now,
                        duration: 0,
                        distance: 0.0,
                        calories: 0,
                        difficulty: 1,
                        heartRate: 0,
                        bodyWeight: 0,
                        intensity: .none,
                        trainingProgram: .manual,
                        workoutDevice: .none
                    )
                }
            }
            // Empty-State
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "Keine Einträge",
                        systemImage: "figure.run",
                        description: Text("Füge dein erstes Training hinzu")
                    )
                }
            }
        }
    }

    // MARK: - Aktionen
    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(workouts[index]) }
        try? modelContext.save()
    }

    // MARK: - JSON-Export-Datei erzeugen
    private func makeExportFile() -> URL? {
        guard !workouts.isEmpty else { return nil }

        let pkg = WorkoutExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: workouts.map { $0.exportItem }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(pkg)
            let filename = "MotionCores-Export-\(Int(Date().timeIntervalSince1970)).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Export-Fehler:", error)
            return nil
        }
    }
}
