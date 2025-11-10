//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : RecordsView.swift                                                /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout List View                                                /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct RecordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var workouts: [WorkoutSession]

    @State private var showingAddView = false
    @State private var exportURL: URL? = nil   // Datei-URL für ShareLink

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        FormView(mode: .edit, workout: workout)
                    } label: {
                        RowView(workout: workout)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Center title between the buttons
                ToolbarItem(placement: .principal) {
                    HeaderView()
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

        let pkg = ExportPackage(
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
