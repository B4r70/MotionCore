//
//  WorkoutListView.swift
//  Crosstrainer
//
//  Created by Barto on 21.10.25.
//

import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutEntry.date, order: .reverse) private var workouts: [WorkoutEntry]
    @State private var showingAddView = false
    @State private var showingExport = false
    @State private var exportText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink {
                        EditWorkoutView(workout: workout)
                    } label: {
                        WorkoutRowView(workout: workout)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationTitle("Crosstrainer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        exportToNotes()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(workouts.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddWorkoutView()
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
        for index in offsets {
            modelContext.delete(workouts[index])
        }
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

struct WorkoutRowView: View {
    let workout: WorkoutEntry
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: workout.date))
                .font(.headline)
            
            HStack(spacing: 12) {
                Label("\(workout.duration) Min", systemImage: "clock")
                Label(String(format: "%.2f km", workout.distance), systemImage: "map")
                Label("\(workout.calories) kcal", systemImage: "flame")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            HStack {
                Text("Belastung:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<5) { index in
                    Image(systemName: index < workout.intensity ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < workout.intensity ? .orange : .gray)
                }
            }
        }
        .padding(.vertical, 4)
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
