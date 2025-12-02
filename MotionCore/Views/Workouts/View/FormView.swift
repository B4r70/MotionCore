//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Basisdarstellung                                                 /
// Datei . . . . : FormView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Anzeige-/Erfassungs-/Änderungsdisplay für Workouts               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

enum WorkoutFormMode { case add, edit }

struct FormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: WorkoutFormMode

    @Bindable var workout: WorkoutSession
    @EnvironmentObject private var appSettings: AppSettings

    // Lokaler Zustand für aufklappbare Wheels
    @State private var showDurationWheel = false
    @State private var showHrWheel = false
    @State private var showDifficultyWheel = false
    @State private var showCaloriesWheel = false

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: – Eine gemeinsame GlassCard für alle Eingaben

                    VStack(alignment: .leading, spacing: 24) {
                        // Titel
                        Text("Workout-Daten")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        // MARK: Datum

                        DatePicker(
                            "Datum",
                            selection: $workout.date,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .environment(\.locale, Locale(identifier: "de_DE"))
                        .tint(.primary) // keine blaue Schrift mehr

                        // MARK: Gerätetyp

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gerätetyp")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack(spacing: 12) {
                                // Auswahl "Ergometer" als Button
                                DeviceButton(
                                    device: .crosstrainer,
                                    isSelected: workout.workoutDevice == .crosstrainer
                                ) {
                                    workout.workoutDevice = .crosstrainer
                                }
                                // Auswahl "Ergometer" als Button
                                DeviceButton(
                                    device: .ergometer,
                                    isSelected: workout.workoutDevice == .ergometer
                                ) {
                                    workout.workoutDevice = .ergometer
                                }
                            }
                        }

                        // MARK: Trainingsprogramm

                        HStack {
                            Text("Trainingsprogramm")
                                .foregroundStyle(.primary)

                            Spacer()

                            Menu {
                                Picker(
                                    "",
                                    selection: Binding<TrainingProgram>(
                                        get: { workout.trainingProgram },
                                        set: { workout.trainingProgram = $0 }
                                    )
                                ) {
                                    ForEach(TrainingProgram.allCases, id: \.self) { p in
                                        Label(p.description, systemImage: p.symbol)
                                            .tag(p)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(workout.trainingProgram.description)
                                        .foregroundStyle(.primary)
                                        .tint(.primary)

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                        .tint(.primary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)

                        // MARK: Dauer

                        DisclosureRow(
                            title: "Dauer",
                            value: "\(workout.duration) min",
                            isExpanded: $showDurationWheel,
                            valueColor: .primary
                        ) {
                            Picker("Dauer", selection: $workout.duration) {
                                ForEach(0 ... 300, id: \.self) { min in
                                    Text("\(min) min").tag(min)
                                }
                            }
                            .pickerStyle(.wheel)
                            .tint(.primary)
                            .frame(height: 140)
                            .clipped()
                        }

                        // MARK: Schwierigkeitsgrad

                        DisclosureRow(
                            title: "Schwierigkeitsgrad",
                            value: "\(workout.difficulty)",
                            isExpanded: $showDifficultyWheel,
                            valueColor: .primary
                        ) {
                            Picker("Schwierigkeitsgrad", selection: $workout.difficulty) {
                                ForEach(1 ... 25, id: \.self) { v in
                                    Text("Stufe \(v)").tag(v)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 140)
                            .clipped()
                        }

                        // MARK: Distanz (Double mit Komma-Punkt-Toleranz)

                        HStack {
                            Text("Distanz")
                            Spacer()
                            TextField(
                                "0,00",
                                text: Binding(
                                    get: { String(format: "%.2f", workout.distance) },
                                    set: { raw in
                                        let normalized = raw.replacingOccurrences(of: ",", with: ".")
                                        if let val = Double(normalized) {
                                            workout.distance = val
                                        }
                                    }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)

                            Text("km")
                                .foregroundStyle(.secondary)
                        }

                        // MARK: Körpergewicht
                        HStack {
                            Text("Gewicht")
                            Spacer()
                            TextField("0.0", value: $workout.bodyWeight, format: .number) // Bindet direkt an Double
                                .keyboardType(.decimalPad) // Wichtig: Ziffernblock mit Dezimalpunkt/Komma
                                .multilineTextAlignment(.trailing)
                            Text("kg")
                        }

                        // MARK: Kalorien

                        DisclosureRow(
                            title: "Kalorien",
                            value: "\(workout.calories) kcal",
                            isExpanded: $showCaloriesWheel,
                            valueColor: .primary
                        ) {
                            Picker("Kalorien", selection: $workout.calories) {
                                ForEach(0 ... 2000, id: \.self) { kcal in
                                    Text("\(kcal) kcal").tag(kcal)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 140)
                            .clipped()
                        }

                        // MARK: Herzfrequenz

                        DisclosureRow(
                            title: "Herzfrequenz",
                            value: "\(workout.heartRate) bpm",
                            isExpanded: $showHrWheel,
                            valueColor: .primary
                        ) {
                            Picker("Herzfrequenz", selection: $workout.heartRate) {
                                ForEach(60 ... 200, id: \.self) { bpm in
                                    Text("\(bpm) bpm").tag(bpm)
                                }
                            }
                            .pickerStyle(.wheel)
                            .tint(.primary)
                            .frame(height: 140)
                            .clipped()
                        }

                        // MARK: Belastungsintensität

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Belastungsintensität")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack {
                                InputStarRating(rating: $workout.intensity)
                                    .scaleEffect(1.0)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            if mode == .add {
                applyDefaultsIfNeeded()
            }
        }
        .navigationTitle(mode == .add ? "Neues Workout" : "Bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Speichern
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if mode == .add { context.insert(workout) }
                    try? context.save()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(.blue) // Icon darf ruhig blau bleiben
            }

            // Löschen im Edit-Modus
            if mode == .edit {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .alert("Workout löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Dieses Workout wird unwiderruflich gelöscht.")
        }
    }

    // MARK: - Hilfsfunktionen

    // Löschen-Funktion
    private func deleteWorkout() {
        context.delete(workout)
        try? context.save()
        dismiss()
    }

    // Defaulteinstellungen für neue Workouts
    private func applyDefaultsIfNeeded() {
        if workout.workoutDevice == .none {
            workout.workoutDevice = appSettings.defaultDevice
        }
        if workout.trainingProgram == .manual {
            workout.trainingProgram = appSettings.defaultProgram
        }
        if workout.duration == 0 {
            workout.duration = appSettings.defaultDuration
        }
        if workout.difficulty == 1 {
            workout.difficulty = appSettings.defaultDifficulty
        }
    }
}
