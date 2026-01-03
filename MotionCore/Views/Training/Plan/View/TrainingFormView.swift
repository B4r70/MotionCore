//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TrainingFormView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.12.2025                                                       /
// Beschreibung  : Formular zum Erstellen/Bearbeiten von Trainingsplänen            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

enum TrainingPlanFormMode { case add, edit }

struct TrainingFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mode: TrainingPlanFormMode
    @Bindable var plan: TrainingPlan

    @EnvironmentObject private var appSettings: AppSettings

    // Alerts
    @State private var showDeleteAlert = false

    // Sheet States
    @State private var showExercisePicker = false
    @State private var selectedExerciseForConfig: Exercise? = nil

    // Backup für Edit-Modus - falls Benutzer abbricht
    @State private var backupSetsForEdit: [ExerciseSet] = []
    @State private var isEditingExercise = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                .hideKeyboardOnTap()

            ScrollView {
                VStack(spacing: 20) {
                    // Grunddaten
                    PlanBasicDataCard(plan: plan)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Uebungen
                    PlanExercisesSection(
                        plan: plan,
                        mode: .form,
                        onAddExercise: { showExercisePicker = true },
                        onEditExercise: { exerciseName in editExercise(exerciseName) },
                        onDeleteExercise: { exerciseName in deleteExercise(exerciseName) },
                        onMoveExercise: { source, destination in moveExercise(from: source, to: destination) }  // Drag & Drop
                    )
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(mode == .add ? "Neuer Plan" : "Plan bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("Plan löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) { deletePlan() }
        } message: {
            Text("Dieser Trainingsplan wird unwiderruflich gelöscht.")
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet { exercise in
                selectedExerciseForConfig = exercise
            }
            .environmentObject(appSettings)
        }
        .sheet(item: $selectedExerciseForConfig) { exercise in
            SetConfigurationSheet(
                exercise: exercise,
                initialSets: backupSetsForEdit.isEmpty ? nil : backupSetsForEdit  // Bestehende Sets übergeben
            ) { sets in
                addSets(sets)
            }
            .environmentObject(appSettings)
            // Bei Abbruch (Sheet schliesst ohne Speichern) Backup wiederherstellen
            .onDisappear {
                restoreBackupIfCancelled()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                save()
            } label: {
                IconType(icon: .system("checkmark"), color: .blue, size: 16)
                    .glassButton(size: 36, accentColor: .blue)
            }
            .disabled(plan.title.isEmpty)
        }

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

    // MARK: - Aktionen

    private func save() {
        dismissKeyboard()
        if mode == .add {
            context.insert(plan)
        }
        try? context.save()
        dismiss()
    }

    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }

    // addSets mit sortOrder-Logik
    private func addSets(_ sets: [ExerciseSet]) {
        // Wenn wir im Edit-Modus sind, alte Sets endgueltig loeschen
        if isEditingExercise {
            // sortOrder vom ersten Backup-Set uebernehmen
            let existingSortOrder = backupSetsForEdit.first?.sortOrder ?? plan.nextSortOrder

            for oldSet in backupSetsForEdit {
                context.delete(oldSet)
            }
            backupSetsForEdit = []
            isEditingExercise = false

            // Neue Sets mit bestehender sortOrder hinzufuegen
            for set in sets {
                set.sortOrder = existingSortOrder
                set.trainingPlan = plan
                plan.templateSets.append(set)
            }
        } else {
            // Neue Uebung: nächste verfuegbare sortOrder verwenden
            let nextOrder = plan.nextSortOrder

            for set in sets {
                set.sortOrder = nextOrder
                set.trainingPlan = plan
                plan.templateSets.append(set)
            }
        }
    }

    // MARK: - Uebungs-Sortierung (Drag & Drop)

    // Drag & Drop Callback
    private func moveExercise(from source: IndexSet, to destination: Int) {
        plan.reorderExercises(fromOffsets: source, toOffset: destination)
    }

    private func deleteExercise(_ exerciseName: String) {
        let setsToRemove = plan.templateSets.filter { $0.exerciseName == exerciseName }
        for set in setsToRemove {
            plan.templateSets.removeAll { $0.id == set.id }
            context.delete(set)
        }
    }

    private func editExercise(_ exerciseName: String) {
        if let existingSet = plan.templateSets.first(where: { $0.exerciseName == exerciseName }),
           let exercise = existingSet.exercise {

            // Backup der bestehenden Sets erstellen
            backupSetsForEdit = plan.templateSets.filter { $0.exerciseName == exerciseName }
            isEditingExercise = true

            // Sets temporär entfernen (aber nicht aus SwiftData löschen!)
            plan.templateSets.removeAll { $0.exerciseName == exerciseName }

            selectedExerciseForConfig = exercise
        }
    }

    // Stellt das Backup wieder her, wenn der Benutzer abbricht
    private func restoreBackupIfCancelled() {
        // Nur wiederherstellen wenn wir im Edit-Modus sind
        // (isEditingExercise ist noch true = Benutzer hat nicht gespeichert)
        if isEditingExercise {
            // Sets aus Backup wiederherstellen
            for set in backupSetsForEdit {
                plan.templateSets.append(set)
            }

            // Cleanup
            backupSetsForEdit = []
            isEditingExercise = false
        }
    }
}

// MARK: - Preview

#Preview("Training Form - Add") {
    NavigationStack {
        TrainingFormView(mode: .add, plan: TrainingPlan())
            .environmentObject(AppSettings.shared)
    }
}

#Preview("Training Form - Edit") {
    NavigationStack {
        TrainingFormView(mode: .edit, plan: TrainingPlan(title: "Push Day A", planType: .strength))
            .environmentObject(AppSettings.shared)
    }
}
