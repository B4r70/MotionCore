//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutFormView.swift                                            /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout List View                                                /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

// MARK: - Shared form (recap)
// Assumes you already have this:
enum WorkoutFormMode { case add, edit }

struct WorkoutFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: WorkoutFormMode
    @Bindable var workout: WorkoutEntry

    var body: some View {
        Form {
            Section("Workout-Daten") {
                // Datum/Uhrzeit
                DatePicker("Datum", selection: $workout.date)
                // Workout-Dauer
                Stepper("Dauer: \(workout.duration) Min", value: $workout.duration, in: 0...500)
                // Distanz
                TextField("Distanz:", text: Binding(
                    get: { String(format: "%.2f", workout.distance) },
                    set: { newValue in
                        let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                        if let val = Double(normalized) { workout.distance = val }
                    }
                ))
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                //.textFieldStyle(.roundedBorder)
                // Kalorien
                Stepper("Kalorien: \(workout.calories) kcal", value: $workout.calories, in: 0...2000, step: 10)
            }
            Section("Belastungsintensität") {
                StarRatingView(rating: $workout.intensity)
            }
        }
        .navigationTitle(mode == .add ? "Neues Workout" : "Workout bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Speichern") {
                if mode == .add { context.insert(workout) }
                try? context.save()
                dismiss()
            }
        }
    }
}
