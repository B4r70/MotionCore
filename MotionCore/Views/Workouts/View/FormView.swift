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

struct FormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: FormMode

    @Bindable var workout: CardioSession
    @EnvironmentObject private var appSettings: AppSettings

    // Lokaler Zustand für aufklappbare Wheels
    @State private var showDurationWheel = false
    @State private var showHrWheel = false
    @State private var showDifficultyWheel = false
    @State private var showCaloriesWheel = false

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    // Focus State für Keyboard-Navigation
    @FocusState private var focusedField: FocusedField?

    // Reihenfolge der Felder definieren
    private let fieldOrder: [FocusedField] = [
        .duration,
        .difficulty,
        .distance,
        .bodyWeight,
        .calories,
        .heartRate
    ]

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                .hideKeyboardOnTap()

            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Eine gemeinsame GlassCard für alle Eingaben
                    VStack(alignment: .leading, spacing: 24) {
                        // Titel
                        Text("Workout-Daten")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        // MARK: Datum
                        DateInputSection(date: $workout.date)

                        // MARK: Gerätetyp
                        DeviceSelectionSection(selectedDevice: $workout.cardioDevice)

                        // MARK: Trainingsprogramm
                        ProgramSelectionSection(selectedProgram: $workout.trainingProgram)

                        // MARK: Dauer
                        DurationSection(
                            duration: $workout.duration,
                            showWheel: $showDurationWheel,
                            focusedField: $focusedField
                        )

                        // MARK: Schwierigkeitsgrad
                        DifficultySection(
                            difficulty: $workout.difficulty,
                            showWheel: $showDifficultyWheel,
                            focusedField: $focusedField
                        )

                        // MARK: Distanz
                        DistanceInputRow(
                            distance: $workout.distance,
                            focusedField: $focusedField
                        )

                        // MARK: Körpergewicht
                        BodyWeightInputRow(
                            bodyWeight: $workout.bodyWeight,
                            focusedField: $focusedField
                        )

                        // MARK: Kalorien
                        CaloriesSection(
                            calories: $workout.calories,
                            showWheel: $showCaloriesWheel,
                            focusedField: $focusedField
                        )

                        // MARK: Herzfrequenz
                        HeartRateSection(
                            heartRate: $workout.heartRate,
                            showWheel: $showHrWheel,
                            focusedField: $focusedField
                        )

                        // MARK: Belastungsintensität
                        IntensitySelectionSection(intensity: $workout.intensity)
                    }
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
        }
        .keyboardToolbar(focusedField: $focusedField, fields: fieldOrder)
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
                    dismissKeyboard()
                    if mode == .add { context.insert(workout) }
                    try? context.save()
                    dismiss()
                } label: {
                    IconType(icon: .system("checkmark"), color: .blue, size: 16)
                        .glassButton(size: 36, accentColor: .blue)
                }
            }

            // Löschen im Edit-Modus
            if mode == .edit {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        dismissKeyboard() 
                        showDeleteAlert = true
                    } label: {
                        IconType(icon: .system("trash"), color: .red, size: 16)
                            .glassButton(size: 36, accentColor: .red)
                    }
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
        if workout.cardioDevice == .none {
            workout.cardioDevice = appSettings.defaultDevice
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
