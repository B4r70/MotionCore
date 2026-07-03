//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Sheets                                                           /
// Datei . . . . : PlanPickerSheet.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.12.2025                                                       /
// Beschreibung  : Auswahl-Sheet für Trainingspläne beim Starten einer Session      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct PlanPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TrainingPlan.title) private var trainingPlans: [TrainingPlan]

    // Binding für den ausgewählten Plan
    @Binding var selectedPlan: TrainingPlan?

    // Nur Krafttraining-Pläne anzeigen
    private var strengthPlans: [TrainingPlan] {
        trainingPlans.filter { $0.planType == .strength || $0.planType == .mixed }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Calm-2026: einheitliche App-Hintergrundfläche
                Theme.surfaceApp.ignoresSafeArea()

                VStack(spacing: 0) {
                    if strengthPlans.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(strengthPlans) { plan in
                                    PlanRow(plan: plan) {
                                        selectedPlan = plan
                                        dismiss()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Trainingsplan wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(Theme.textSecondary)

            Text("Keine Trainingspläne")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Text("Erstelle zuerst einen Trainingsplan\nim Training-Tab.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Plan Row

private struct PlanRow: View {
    let plan: TrainingPlan
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon-Tile: Typ-spezifische Calm-2026-Farben
                ZStack {
                    Circle()
                        .fill(plan.planType.calmTileBackground)
                        .frame(width: 50, height: 50)

                    Image(systemName: plan.planType.icon)
                        .font(.title2)
                        .foregroundStyle(plan.planType.calmTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        let sets = plan.safeTemplateSets
                        let exerciseCount = Set(sets.map { $0.exerciseName }).count

                        Label("\(exerciseCount) Übungen", systemImage: "dumbbell")
                        Label("\(sets.count) Sets", systemImage: "list.number")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Play-Icon: Erfolgsfarbe (semantisch: Starten = positiv)
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(Theme.success)
            }
        }
        .buttonStyle(.plain)
        .card()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected: TrainingPlan? = nil

    ZStack {
        Theme.surfaceApp.ignoresSafeArea()

        PlanPickerSheet(selectedPlan: $selected)
            .modelContainer(PreviewData.sharedContainer)
    }
}
