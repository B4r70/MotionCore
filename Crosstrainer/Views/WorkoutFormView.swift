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

enum WorkoutFormMode { case add, edit }

struct WorkoutFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: WorkoutFormMode
    @Bindable var workout: WorkoutSession
        // 🆕 Lokaler Zustand für aufklappbare Wheels
    @State private var showDurationWheel = false
    @State private var showHrWheel = false
    @State private var showLevelWheel = false
    @State private var showWeightWheel = false
    @State private var showCaloriesWheel = false

    var body: some View {
        Form {
            // MARK: - Workout-Daten
            Section("Workout-Daten") {

                DatePicker("Datum", selection: $workout.date)

                    // MARK: Dauer mit Wheel
                DisclosureGroup(
                    isExpanded: $showDurationWheel,
                    content: {
                        Picker("Dauer", selection: $workout.duration) {
                            ForEach(0...300, id: \.self) { min in
                                Text("\(min) min.").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .clipped()
                        .transition(.opacity)
                    },
                    label: {
                        HStack {
                            Text("Dauer")
                            Spacer()
                            Text("\(workout.duration)")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
                    // MARK: Schwierigkeitsgrad mit Wheel
                DisclosureGroup(
                    isExpanded: $showLevelWheel,
                    content: {
                        Picker("Level", selection: $workout.difficulty) {
                            ForEach(1...25, id: \.self) { v in
                                Text("Stufe \(v)").tag(v)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .clipped()
                        .transition(.opacity)
                    },
                    label: {
                        HStack {
                            Text("Schwierigkeitsgrad")
                            Spacer()
                            Text("\(workout.difficulty)")
                                .foregroundStyle(.secondary)
                        }
                    }
                )

                    // Distanz (Double) mit Komma/ Punkt toleranz
                HStack {
                    Text("Distanz")
                    Spacer()
                    TextField("0,00",
                              text: Binding(
                                get: { String(format: "%.2f", workout.distance) },
                                set: { raw in
                                    let normalized = raw.replacingOccurrences(of: ",", with: ".")
                                    if let val = Double(normalized) { workout.distance = val }
                                })
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    Text("km").foregroundStyle(.secondary)
                }

                    // MARK: Gewicht mit Wheel
                DisclosureGroup(
                    isExpanded: $showWeightWheel,
                    content: {
                        Picker("Gewicht", selection: $workout.bodyWeight) {
                            ForEach(0...300, id: \.self) { kg in
                                Text("\(kg) kg").tag(kg)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .clipped()
                        .transition(.opacity)
                    },
                    label: {
                        HStack {
                            Text("Gewicht")
                            Spacer()
                            Text("\(workout.bodyWeight) kg")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
                    // MARK: Kalorien mit Wheel
                DisclosureGroup(
                    isExpanded: $showCaloriesWheel,
                    content: {
                        Picker("Kalorien", selection: $workout.calories) {
                            ForEach(0...2000, id: \.self) { kcal in
                                Text("\(kcal) kcal").tag(kcal)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .clipped()
                        .transition(.opacity)
                    },
                    label: {
                        HStack {
                            Text("Kalorien")
                            Spacer()
                            Text("\(workout.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
                    // MARK: Herzfrequenz: EIN Feld, NumPad – keine 3 Zeilen mehr
                DisclosureGroup(
                    isExpanded: $showHrWheel,
                    content: {
                        Picker("Herzfrequenz", selection: $workout.heartRate) {
                            ForEach(60...200, id: \.self) { bpm in
                                Text("\(bpm) bpm").tag(bpm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .clipped()
                        .transition(.opacity)
                    },
                    label: {
                        HStack {
                            Text("Herzfrequenz")
                            Spacer()
                            Text("\(workout.heartRate) bpm")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
            }

            // Belastungsintensität
            Section("Belastungsintensität") {
                WorkoutStarRatingView(rating: $workout.intensity)
            }
        } // <- Form korrekt geschlossen  // 🆕

        // Eindeutige Toolbar-Platzierung, damit nichts doppelt erscheint  // 🆕
        .navigationTitle(mode == .add ? "Neues Workout" : "Bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    if mode == .add { context.insert(workout) }
                    try? context.save()
                    dismiss()
                }
                .tint(.orange)
            }
        }
    }
}
