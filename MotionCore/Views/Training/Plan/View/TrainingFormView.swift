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
    @State private var initialSetsForConfig: [ExerciseSet]? = nil  // NEU
    @State private var sheetDidSave = false  // NEU: Track ob gespeichert wurde

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

                    // Übungen
                    PlanExercisesSection(
                        plan: plan,
                        mode: .form,
                        onAddExercise: { showExercisePicker = true },
                        onEditExercise: { exerciseName in editExercise(exerciseName) },
                        onDeleteExercise: { exerciseName in deleteExercise(exerciseName) }
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
                initialSetsForConfig = nil  // NEU: Bei neuer Übung keine initialSets
                selectedExerciseForConfig = exercise
            }
            .environmentObject(appSettings)
        }
        .sheet(item: $selectedExerciseForConfig) { exercise in
            SetConfigurationSheet(
                exercise: exercise,
                initialSets: initialSetsForConfig  // NEU: Verwende gespeicherte State
            ) { sets in
                addSets(sets)
            }
            .environmentObject(appSettings)
        }
        .onChange(of: selectedExerciseForConfig) { oldValue, newValue in
            // Wenn das Sheet geschlossen wird (newValue == nil) und nicht gespeichert wurde
            if oldValue != nil && newValue == nil {
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

    // Trainingsplan sichern
    private func save() {
        dismissKeyboard()
        if mode == .add {
            context.insert(plan)
        }
        try? context.save()
        dismiss()
    }

    // Trainingsplan löschen
    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }

    // Neues Set hinzufügen
    private func addSets(_ sets: [ExerciseSet]) {
        sheetDidSave = true

        // Wenn wir im Edit-Modus sind, alte Sets endgültig löschen
        if isEditingExercise {
            for oldSet in backupSetsForEdit {
                context.delete(oldSet)
            }
            backupSetsForEdit = []
            isEditingExercise = false
            initialSetsForConfig = nil
        }

        // Neue Sets hinzufügen
        for set in sets {
            set.trainingPlan = plan
            plan.templateSets.append(set)
        }
    }

    // Übung aus dem Trainingsplan löschen
    private func deleteExercise(_ exerciseName: String) {
        let setsToRemove = plan.templateSets.filter { $0.exerciseName == exerciseName }
        for set in setsToRemove {
            plan.templateSets.removeAll { $0.id == set.id }
            context.delete(set)
        }
    }

    // Übung anpassen
    private func editExercise(_ exerciseName: String) {
        // Reset sheetDidSave für neue Session
        sheetDidSave = false

        if let existingSet = plan.templateSets.first(where: { $0.exerciseName == exerciseName }),
           let exercise = existingSet.exercise {

            // Zuerst die Sets sammeln
            let existingSets = plan.templateSets.filter { $0.exerciseName == exerciseName }

            // Backup der bestehenden Sets erstellen
            backupSetsForEdit = existingSets
            initialSetsForConfig = existingSets
            isEditingExercise = true

            // Sets temporär entfernen (aber nicht aus SwiftData löschen!)
            plan.templateSets.removeAll { $0.exerciseName == exerciseName }

            // Jetzt erst das Sheet öffnen
            selectedExerciseForConfig = exercise
        }
    }

    // Stellt das Backup wieder her, wenn der Benutzer abbricht
    private func restoreBackupIfCancelled() {
        // Nur wiederherstellen wenn wir im Edit-Modus sind UND NICHT gespeichert wurde
        if isEditingExercise && !sheetDidSave {
            // Sets aus Backup wiederherstellen
            for set in backupSetsForEdit {
                plan.templateSets.append(set)
            }

            // Cleanup
            backupSetsForEdit = []
            isEditingExercise = false
            initialSetsForConfig = nil
        } else {
            // Cleanup trotzdem
            backupSetsForEdit = []
            isEditingExercise = false
            initialSetsForConfig = nil
            sheetDidSave = false  // Reset für nächstes Mal
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
