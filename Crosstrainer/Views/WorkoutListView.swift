//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
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
    @State private var exportURL: URL? = nil                // 🆕 Datei-URL für ShareLink

    // Local draft for Add flow; will be reset when sheet opens
    @State private var draft = WorkoutSession(
        date: .now,
        duration: 0,
        distance: 0.0,
        calories: 0,
        difficulty: 1,
        heartRate: 0,
        bodyWeight: 0,
        intensity: .none,
        trainingProgram: .manual
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
            .navigationTitle("Crosstrainer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddView = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let url = exportURL {
                        ShareLink(item: url) {                      // 🆕 natives Sharing einer Datei
                            Image(systemName: "square.and.arrow.up")
                        }
                        .onAppear { exportURL = makeExportFile() }  // 🆕 Datei frisch erzeugen
                        .disabled(workouts.isEmpty)
                    } else {
                        Button {
                            exportURL = makeExportFile()            // 🆕 erst Datei bauen, dann zeigt ShareLink
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(workouts.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showingAddView) { /* … unverändert … */ }

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

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(workouts[index]) }
        try? modelContext.save()
    }

    // MARK: - JSON bauen und temporäre Datei erzeugen  // 🆕
    private func makeExportFile() -> URL? {
        guard !workouts.isEmpty else { return nil }

        let pkg = WorkoutExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: workouts.map { $0.exportItem }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // hübsch & diff-freundlich
        do {
            let data = try encoder.encode(pkg)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("CrossStats-Export-\(Int(Date().timeIntervalSince1970))).json")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Export-Fehler:", error)
            return nil
        }
    }
}
