//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ExerciseFormView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.12.2025                                                       /
// Beschreibung  : Formular zum Erstellen/Bearbeiten von Übungen                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

enum ExerciseFormMode { case add, edit }

struct ExerciseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: ExerciseFormMode

    @Bindable var exercise: Exercise
    @EnvironmentObject private var appSettings: AppSettings

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                .hideKeyboardOnTap()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Titel
                        Text("Übungsdaten")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        // MARK: Name
                        ExerciseNameSection(name: $exercise.name)

                        // MARK: Beschreibung
                        ExerciseDescriptionSection(description: $exercise.exerciseDescription)

                        // MARK: Kategorie
                        ExerciseCategorySection(category: $exercise.category)

                        // MARK: Equipment
                        ExerciseEquipmentSection(equipment: $exercise.equipment)

                        // MARK: Schwierigkeit
                        ExerciseDifficultySection(difficulty: $exercise.difficulty)

                        // MARK: Bewegungsmuster
                        ExerciseMovementPatternSection(movementPattern: $exercise.movementPattern)

                        // MARK: Körperposition
                        ExerciseBodyPositionSection(bodyPosition: $exercise.bodyPosition)

                        // MARK: Primäre Muskelgruppen
                        ExercisePrimaryMuscleGroupsSection(selectedMuscles: $exercise.primaryMuscles)

                        // MARK: Sekundäre Muskelgruppen
                        ExerciseSecondaryMuscleGroupsSection(selectedMuscles: $exercise.secondaryMuscles)

                        // MARK: GIF Asset Name
                        ExerciseGifAssetSection(gifAssetName: $exercise.gifAssetName)

                        // MARK: Unilateral Toggle
                        ExerciseUnilateralToggle(isUnilateral: $exercise.isUnilateral)

                        // MARK: Wiederholungsbereich
                        ExerciseRepRangeSection(
                            repRangeMin: $exercise.repRangeMin,
                            repRangeMax: $exercise.repRangeMax
                        )

                        // MARK: Sicherheitshinweis
                        ExerciseCautionNoteSection(cautionNote: $exercise.cautionNote)

                        // MARK: Favorit
                        ExerciseFavoriteToggle(isFavorite: $exercise.isFavorite)
                    }
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(mode == .add ? "Neue Übung" : "Bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Speichern
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismissKeyboard()
                    if mode == .add {
                        exercise.isCustom = true
                        context.insert(exercise)
                    }
                    try? context.save()
                    dismiss()
                } label: {
                    IconType(icon: .system("checkmark"), color: .blue, size: 16)
                        .glassButton(size: 36, accentColor: .blue)
                }
                .disabled(exercise.name.isEmpty)
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
        .alert("Übung löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deleteExercise()
            }
        } message: {
            Text("Diese Übung wird unwiderruflich gelöscht.")
        }
    }

    // MARK: - Hilfsfunktionen

    private func deleteExercise() {
        context.delete(exercise)
        try? context.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Exercise Form - Add") {
    NavigationStack {
        ExerciseFormView(mode: .add, exercise: Exercise())
            .environmentObject(AppSettings.shared)
    }
}
