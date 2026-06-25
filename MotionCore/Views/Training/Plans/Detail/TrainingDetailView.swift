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
    @EnvironmentObject private var sessionManager: ActiveSessionManager

    @Bindable var plan: TrainingPlan

    @State private var showDeleteAlert = false
    @State private var startedSession: StrengthSession?
    /// Lokale Kopie für das Sheet — getrennt von pendingPlanUpdateProposal
    /// damit Banner-Sichtbarkeit und Sheet-Öffnen unabhängig voneinander sind.
    @State private var planUpdateSheetProposal: PlanUpdateProposal?
    /// Steuert Sichtbarkeit des Undo-Banners (wird nach Undo/Verwerfen auf false gesetzt)
    @State private var showUndoBanner: Bool = true
    /// Toast-Nachricht nach Duplizieren (nil = kein Toast)
    @State private var duplicateToastMessage: String? = nil

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
                    if !plan.safeTemplateSets.isEmpty {
                        PlanStatisticsCard(plan: plan)
                            .padding(.horizontal)
                    }

                    // Plan-Update Banner (nach Workout-Ende, wenn Vorschlag vorhanden) — Option B
                    if let proposal = sessionManager.pendingPlanUpdateProposal,
                       proposal.hasChanges,
                       proposal.plan.planUUID == plan.planUUID {
                        PlanUpdateBanner(
                            proposal: proposal,
                            onTap: { planUpdateSheetProposal = proposal },
                            onDismiss: { sessionManager.pendingPlanUpdateProposal = nil }
                        )
                        .padding(.horizontal)
                    }

                    // Session-Sync Undo-Banner (Option A — 72h nach Plan-Sync sichtbar)
                    if showUndoBanner && SessionSyncUndoService.isUndoAvailable(for: plan) {
                        SessionSyncUndoBanner(
                            plan: plan,
                            onUndo: { showUndoBanner = false },
                            onDiscard: { showUndoBanner = false }
                        )
                        .padding(.horizontal)
                    }

                    // Übungen
                    PlanExercisesSection(plan: plan, mode: .detail)

                    // Toast-Banner nach Duplizieren
                    if let message = duplicateToastMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundStyle(Color.blue)
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button {
                                duplicateToastMessage = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .card()
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Aktionen
                    PlanActionsSection(
                        plan: plan,
                        onStartWorkout: { startWorkout() },
                        onDuplicate: { duplicatePlan() },
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
        .fullScreenCover(item: $startedSession) { session in
            NavigationStack {
                ActiveWorkoutView(session: session)
            }
            .environmentObject(appSettings)
            .environmentObject(ActiveSessionManager.shared)
        }
        .sheet(item: $planUpdateSheetProposal) { proposal in
            PlanUpdateSheet(proposal: proposal, onApply: {
                sessionManager.pendingPlanUpdateProposal = nil
                planUpdateSheetProposal = nil
            })
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
        startedSession = session
    }

    private func duplicatePlan() {
        let copy = plan.duplicate(context: context)
        try? context.save()
        withAnimation {
            duplicateToastMessage = "Plan \"\(copy.title)\" wurde erstellt."
        }
        // Toast nach 4 Sekunden automatisch ausblenden
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                duplicateToastMessage = nil
            }
        }
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
        .environmentObject(ActiveSessionManager.shared)
    }
}

#Preview("Training Detail View - Empty") {
    NavigationStack {
        TrainingDetailView(plan: TrainingPlan(
            title: "Neuer Plan",
            planType: .mixed
        ))
        .environmentObject(AppSettings.shared)
        .environmentObject(ActiveSessionManager.shared)
    }
}
