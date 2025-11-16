// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : WorkoutSettingsView.swift                                        /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 15.11.2025                                                       /
// Function . . : Workout Settings View                                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct WorkoutSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    // Local state for duration wheel
    @State private var showDurationWheel = false
    @State private var showDifficultyWheel = false

    var body: some View {
        List {
            // MARK: - Defaults for new workouts

            Section("Defaultwerte für neue Workouts") {
                // Default Gerätetyp
                Picker("Gerätetyp", selection: $settings.defaultDevice) {
                    ForEach(WorkoutDevice.allCases, id: \.self) { device in
                        Label(device.description, systemImage: device.symbol)
                            .tag(device)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)

                // Default Trainingsprogramm
                Picker("Trainingsprogramm", selection: $settings.defaultProgram) {
                    ForEach(TrainingProgram.allCases, id: \.self) { program in
                        Label(program.description, systemImage: program.symbol)
                            .tag(program)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)

                // Default duration (wheel in DisclosureGroup)
                DisclosureGroup(
                    isExpanded: $showDurationWheel,
                    content: {
                        Picker("Trainingsdauer", selection: $settings.defaultDuration) {
                            ForEach(0 ... 300, id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .clipped()
                        .transition(.opacity)
                    },
                    label: {
                        HStack {
                            Text("Trainingsdauer")
                            Spacer()
                            Text("\(settings.defaultDuration) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                )

                // Default Schwierigkeitsgrad (wheel in DisclosureGroup)
                DisclosureGroup(
                    isExpanded: $showDifficultyWheel,
                    content: {
                        Picker("Difficulty", selection: $settings.defaultDifficulty) {
                            ForEach(1 ... 25, id: \.self) { v in
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
                            Text("\(settings.defaultDifficulty)")
                                .foregroundStyle(.secondary)
                        }
                    }
                )
            }
            Section("Sonstige Einstellungen") {
                // Show empty fields option – gehört inhaltlich auch zu den Defaults
                Toggle("Leere Felder anzeigen", isOn: $settings.showEmptyFields)
            }
        }
        .navigationTitle("Defaultwerte für Workouts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WorkoutSettingsView()
    }
}
