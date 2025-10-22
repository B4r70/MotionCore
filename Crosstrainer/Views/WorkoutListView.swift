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
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]

    @State private var showingAddView = false
    @State private var showingExport = false
    @State private var exportText = ""

    // Local draft for Add flow; will be reset when sheet opens
    @State private var draft = WorkoutEntry(date: .now, duration: 0, distance: 0.0, calories: 0, intensity: 0)

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        // EDIT → use the shared form in edit mode
                        WorkoutFormView(mode: .edit, workout: workout)
                    } label: {
                        WorkoutRowView(workout: workout)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationTitle("Crosstrainer Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddView = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { exportToNotes() } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(workouts.isEmpty)
                }
            }
            // ADD → shared form in add mode with fresh draft
            .sheet(isPresented: $showingAddView) {
                NavigationStack {
                    WorkoutFormView(mode: .add, workout: draft)
                }
                .onAppear {
                    // reset draft each time the sheet is shown
                    draft = WorkoutEntry(date: .now, duration: 0, distance: 0.0, calories: 0, intensity: 0)
                }
            }
            .sheet(isPresented: $showingExport) {
                ShareSheet(items: [exportText])
            }
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

    private func exportToNotes() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        var text = "Crosstrainer Training\n"
        text += "===================\n\n"
        for workout in workouts {
            text += "📅 \(dateFormatter.string(from: workout.date))\n"
            text += "⏱️ \(workout.duration) Min\n"
            text += "📏 \(String(format: "%.2f", workout.distance)) km\n"
            text += "🔥 \(workout.calories) kcal\n"
            text += "💪 Belastung: \(workout.intensity)/5\n"
            text += "-------------------\n"
        }
        exportText = text
        showingExport = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
 }
