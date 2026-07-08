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

struct ExerciseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: FormMode

    @Bindable var exercise: Exercise
    @EnvironmentObject private var appSettings: AppSettings
    var showDeleteButton: Bool = true

    // Lösch-Bestätigung
    @State private var showDeleteAlert = false

    // Doppelter Name
    @State private var showDuplicateNameAlert = false

    // Instruktionen zur Übung
    @State private var isEditingInstructions = false

    // Alle Übungen für Namens-Duplikatprüfung
    @Query(sort: \Exercise.name)
    private var allExercises: [Exercise]

    private var isDuplicateName: Bool {
        let trimmed = exercise.name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        return allExercises.contains {
            $0.name.lowercased() == trimmed &&
            $0.persistentModelID != exercise.persistentModelID
        }
    }

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

                        // MARK: Übungsanleitung Inline
                        // 2 verschiedene Modi: presentation: .inline / .sheet
                        ExerciseInstructionSection(
                            exercise: exercise,
                            isEditingInstructions: $isEditingInstructions,
                            presentation: .inline
                        )

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

                        // MARK: Primäre Muskeln (detailliert)
                        ExerciseDetailedPrimaryMusclesSection(selectedMuscles: $exercise.detailedPrimaryMuscles)

                        // MARK: Sekundäre Muskeln (detailliert)
                        ExerciseDetailedSecondaryMusclesSection(selectedMuscles: $exercise.detailedSecondaryMuscles)

                        // MARK: Media Asset Name
                        ExerciseMediaAssetSection(mediaAssetName: $exercise.mediaAssetName)

                        // MARK: Unilateral Toggle
                        ExerciseUnilateralToggle(isUnilateral: $exercise.isUnilateral)

                        // MARK: Wiederholungsbereich
                        ExerciseRepRangeSection(
                            repRangeMin: $exercise.repRangeMin,
                            repRangeMax: $exercise.repRangeMax
                        )

                        // MARK: - Smart Progression (v1.1)

                        Text("Smart Progression")
                            .font(.headline)
                            .padding(.top, 8)

                        ExerciseStudioEquipmentSection(studioEquipmentID: $exercise.studioEquipmentID)

                        ExerciseCustomTargetRepsSection(customTargetReps: $exercise.customTargetReps)

                        ExerciseProgressionModeSection(mode: Binding(
                            get: { exercise.progressionMode },
                            set: { exercise.progressionMode = $0 }
                        ))

                        ExerciseConfigNotesSection(configNotes: $exercise.configNotes)

                        // MARK: Sicherheitshinweis
                        ExerciseCautionNoteSection(cautionNote: $exercise.cautionNote)

                        // MARK: Favorit
                        ExerciseFavoriteToggle(isFavorite: $exercise.isFavorite)

                        // MARK: API-Informationen (nur bei importierten Übungen)
                        if exercise.isSystemExercise {
                            ExerciseAPIView(exercise: exercise)
                        }
                    }
                    .card()
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
                    guard !isDuplicateName else {
                        showDuplicateNameAlert = true
                        return
                    }
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
                .disabled(exercise.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Löschen im Edit-Modus (nur wenn erlaubt)
            if mode == .edit && showDeleteButton {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        dismissKeyboard()
                        showDeleteAlert = true
                    } label: {
                        IconType(icon: .system("trash"), color: Color.red, size: 16)
                            .glassButton(size: 36, accentColor: Color.red)
                    }
                }
            }
        }
        .alert("Name bereits vergeben", isPresented: $showDuplicateNameAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Eine Übung mit dem Namen \"\(exercise.name)\" existiert bereits. Bitte wähle einen anderen Namen.")
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
