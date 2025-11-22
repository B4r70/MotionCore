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
    @ObservedObject private var settings = AppSettings.shared

    // Lokaler Zustand für aufklappbare Wheels
    @State private var showDurationWheel = false
    @State private var showHrWheel = false
    @State private var showDifficultyWheel = false
    @State private var showWeightWheel = false
    @State private var showCaloriesWheel = false

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

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

                        // MARK: Dauer

                        disclosureRow(
                            title: "Dauer",
                            value: "\(workout.duration) min",
                            isExpanded: $showDurationWheel
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

                        disclosureRow(
                            title: "Schwierigkeitsgrad",
                            value: "\(workout.difficulty)",
                            isExpanded: $showDifficultyWheel
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

                        // MARK: Gewicht

                        disclosureRow(
                            title: "Gewicht",
                            value: "\(workout.bodyWeight) kg",
                            isExpanded: $showWeightWheel
                        ) {
                            Picker("Gewicht", selection: $workout.bodyWeight) {
                                ForEach(0 ... 300, id: \.self) { kg in
                                    Text("\(kg) kg").tag(kg)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 140)
                            .clipped()
                        }

                        // MARK: Kalorien

                        disclosureRow(
                            title: "Kalorien",
                            value: "\(workout.calories) kcal",
                            isExpanded: $showCaloriesWheel
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

                        disclosureRow(
                            title: "Herzfrequenz",
                            value: "\(workout.heartRate) bpm",
                            isExpanded: $showHrWheel
                        ) {
                            Picker("Herzfrequenz", selection: $workout.heartRate) {
                                ForEach(60 ... 200, id: \.self) { bpm in
                                    Text("\(bpm) bpm").tag(bpm)
                                }
                            }
                            .pickerStyle(.wheel)
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

    /// Generische DisclosureGroup-Zeile mit Label rechts
    @ViewBuilder
    private func disclosureRow<Content: View>(
        title: String,
        value: String,
        isExpanded: Binding<Bool>,
        content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                    .tint(.primary)
                Spacer()
                Text(value)
                    .foregroundStyle(.primary)
                    .tint(.primary)
            }
        }
    }

    // Löschen-Funktion
    private func deleteWorkout() {
        context.delete(workout)
        try? context.save()
        dismiss()
    }

    // Defaulteinstellungen für neue Workouts
    private func applyDefaultsIfNeeded() {
        if workout.workoutDevice == .none {
            workout.workoutDevice = settings.defaultDevice
        }
        if workout.trainingProgram == .manual {
            workout.trainingProgram = settings.defaultProgram
        }
        if workout.duration == 0 {
            workout.duration = settings.defaultDuration
        }
        if workout.difficulty == 1 {
            workout.difficulty = settings.defaultDifficulty
        }
    }
}
