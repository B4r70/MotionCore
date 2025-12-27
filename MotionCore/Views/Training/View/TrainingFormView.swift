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
                selectedExerciseForConfig = exercise
            }
            .environmentObject(appSettings)
        }
        .sheet(item: $selectedExerciseForConfig) { exercise in
            SetConfigurationSheet(exercise: exercise) { sets in
                addSets(sets)
            }
            .environmentObject(appSettings)
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

    private func addSets(_ sets: [ExerciseSet]) {
        for set in sets {
            set.trainingPlan = plan
            plan.templateSets.append(set)
        }
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
            deleteExercise(exerciseName)
            selectedExerciseForConfig = exercise
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
