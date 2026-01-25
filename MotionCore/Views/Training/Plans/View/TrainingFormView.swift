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

    @State private var showDeleteAlert = false

    // Sheet States
    @State private var showExercisePicker = false
    @State private var editExerciseContext: EditExerciseContext? = nil

    @State private var pendingReplacement: (sortOrder: Int, newSets: [ExerciseSet])? = nil

    struct EditExerciseContext: Identifiable {
        let id = UUID()
        let exercise: Exercise?              // optional: Library-Exercise
        let exerciseName: String             // Snapshot-Fallback
        let mediaAssetName: String             // Snapshot-Fallback
        let isUnilateral: Bool               // Snapshot-Fallback
        let sets: [ExerciseSet]              // ORIGINALE Sets (nur zum Vorbefüllen)
        let sortOrder: Int                   // Gruppen-Key im Plan
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                .hideKeyboardOnTap()

            ScrollView {
                VStack(spacing: 20) {
                    PlanBasicDataCard(plan: plan)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    PlanExercisesSection(
                        plan: plan,
                        mode: .form,
                        onAddExercise: { showExercisePicker = true },
                        onEditExercise: { firstSet in
                            editExercise(firstSet)
                        },
                        onDeleteExercise: { set in
                            deleteExercise(set)
                        },
                        onMoveExercise: { source, destination in
                            moveExercise(from: source, to: destination)
                        }
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
        // Picker (Add)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet { exercise in
                // Für "Add" öffnen wir direkt über denselben Context-Mechanismus
                editExerciseContext = EditExerciseContext(
                    exercise: exercise,
                    exerciseName: exercise.name,
                    mediaAssetName: exercise.mediaAssetName,
                    isUnilateral: exercise.isUnilateral,
                    sets: [],
                    sortOrder: plan.nextSortOrder
                )
            }
            .environmentObject(appSettings)
        }
        // Konfiguration (Add + Edit über EIN Sheet)
        .sheet(item: $editExerciseContext, onDismiss: {
            commitPendingReplacementIfNeeded()
        }) { ctx in
            Group {
                if let ex = ctx.exercise {
                    SetConfigurationSheet(exercise: ex, initialSets: ctx.sets.isEmpty ? nil : ctx.sets) { newSets in
                        pendingReplacement = (ctx.sortOrder, newSets)
                        editExerciseContext = nil   // erst schließen
                    }
                } else {
                    SetConfigurationSheet(
                        exerciseName: ctx.exerciseName,
                        mediaAssetName: ctx.mediaAssetName,
                        isUnilateral: ctx.isUnilateral,
                        initialSets: ctx.sets.isEmpty ? nil : ctx.sets
                    ) { newSets in
                        pendingReplacement = (ctx.sortOrder, newSets)
                        editExerciseContext = nil   // erst schließen
                    }
                }
            }
            .environmentObject(appSettings)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button { save() } label: {
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
        if mode == .add { context.insert(plan) }
        try? context.save()
        dismiss()
    }

    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }

    private func commitPendingReplacementIfNeeded() {
        guard let pending = pendingReplacement else { return }
        pendingReplacement = nil

        addSets(pending.newSets, keepingSortOrder: pending.sortOrder)
    }

    // MARK: - Sortierung

    private func moveExercise(from source: IndexSet, to destination: Int) {
        plan.reorderExercises(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Delete

    private func deleteExercise(_ set: ExerciseSet) {
        let targetOrder = set.sortOrder

        let toRemove = plan.safeTemplateSets.filter { $0.sortOrder == targetOrder }

        plan.removeTemplateSets { $0.sortOrder == targetOrder }

        toRemove.forEach { context.delete($0) }

        try? context.save()
    }

    // MARK: - Edit

    private func editExercise(_ firstSet: ExerciseSet) {
        let targetOrder = firstSet.sortOrder
        let originalSets = plan.safeTemplateSets.filter { $0.sortOrder == targetOrder }

        // unilateral sauber bestimmen:
        // 1) wenn Relationship existiert -> von Exercise
        // 2) sonst -> aus Snapshot-Flag (neu) oder weightPerSide fallback
        let resolvedIsUnilateral: Bool =
            firstSet.exercise?.isUnilateral
            ?? originalSets.first?.isUnilateralSnapshot
            ?? originalSets.contains(where: { $0.weightPerSide > 0 })

        editExerciseContext = EditExerciseContext(
            exercise: firstSet.exercise,
            exerciseName: (firstSet.exerciseNameSnapshot.isEmpty ? firstSet.exerciseName : firstSet.exerciseNameSnapshot),
            mediaAssetName: firstSet.exerciseMediaAssetName,
            isUnilateral: resolvedIsUnilateral,
            sets: originalSets, // ORIGINALE Sets nur zum Vorbefüllen
            sortOrder: targetOrder
        )
    }

    // MARK: - Save Sets into Plan

    private func addSets(_ sets: [ExerciseSet], keepingSortOrder sortOrder: Int? = nil) {
        var targetOrder = sortOrder ?? plan.nextSortOrder
        if targetOrder <= 0 {
            let maxOrder = plan.safeTemplateSets.map(\.sortOrder).max() ?? 0
            targetOrder = max(maxOrder + 1, 1)
        }

        // 1) Alte Sets dieser Gruppe zuerst einsammeln
        let old = plan.safeTemplateSets.filter { $0.sortOrder == targetOrder }

        // 2) Relationship entfernen (einmal)
        plan.removeTemplateSets { $0.sortOrder == targetOrder }

        // 3) Alte Objekte aus dem Context löschen
        old.forEach { context.delete($0) }

        // 4) Neue Sets hinzufügen
        for set in sets {
            set.sortOrder = targetOrder
            plan.addTemplateSet(set)
            context.insert(set)          // optional, aber ich empfehle es hier explizit
        }

        try? context.save()
    }
}

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
