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
    @EnvironmentObject private var appSettings: AppSettings

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
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

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
                    Button("Abbrechen") {
                        dismiss()
                    }
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
                .foregroundStyle(.secondary)

            Text("Keine Trainingspläne")
                .font(.headline)

            Text("Erstelle zuerst einen Trainingsplan\nim Training-Tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private var planColor: Color {
        switch plan.planType {
        case .strength: return .orange
        case .cardio: return .green
        case .outdoor: return .blue
        case .mixed: return .purple
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(planColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: plan.planType.icon)
                        .font(.title2)
                        .foregroundStyle(planColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        let exerciseCount = Set(plan.templateSets.map { $0.exerciseName }).count
                        Label("\(exerciseCount) Übungen", systemImage: "dumbbell")
                        Label("\(plan.templateSets.count) Sets", systemImage: "list.number")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selected: TrainingPlan? = nil

    PlanPickerSheet(selectedPlan: $selected)
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
