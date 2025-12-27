//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TrainingDetailView.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.12.2025                                                       /
// Beschreibung  : Detailansicht für Trainingspläne                                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct TrainingDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    @Bindable var plan: TrainingPlan

    @State private var showDeleteAlert = false

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Plan-Info
                    PlanInfoCard(plan: plan)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Statistik (nur wenn Übungen vorhanden)
                    if !plan.templateSets.isEmpty {
                        PlanStatisticsCard(plan: plan)
                            .padding(.horizontal)
                    }

                    // Übungen
                    PlanExercisesSection(plan: plan, mode: .detail)

                    // Aktionen
                    PlanActionsSection(
                        plan: plan,
                        onStartWorkout: { startWorkout() },
                        onDelete: { showDeleteAlert = true }
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Plan löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) { deletePlan() }
        } message: {
            Text("Dieser Trainingsplan wird unwiderruflich gelöscht.")
        }
    }

    // MARK: - Aktionen

    private func deletePlan() {
        context.delete(plan)
        try? context.save()
        dismiss()
    }

    private func startWorkout() {
        let session = plan.createSession()
        context.insert(session)
        try? context.save()

        // TODO: Navigation zur aktiven Workout-Ansicht
        // Hier später NavigationPath oder Sheet für Live-Tracking
    }
}

// MARK: - Preview

#Preview("Training Detail View") {
    NavigationStack {
        TrainingDetailView(plan: TrainingPlan(
            title: "Push Day A",
            planDescription: "Brust, Schultern und Trizeps",
            planType: .strength
        ))
        .environmentObject(AppSettings.shared)
    }
}

#Preview("Training Detail View - Empty") {
    NavigationStack {
        TrainingDetailView(plan: TrainingPlan(
            title: "Neuer Plan",
            planType: .mixed
        ))
        .environmentObject(AppSettings.shared)
    }
}
