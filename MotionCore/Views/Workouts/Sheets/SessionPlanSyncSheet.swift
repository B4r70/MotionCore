//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout / Sheets                                                 /
// Datei . . . . : SessionPlanSyncSheet.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 28.04.2026                                                       /
// Beschreibung  : Sheet für Option A — Plan aus Session aktualisieren              /
//                 Zeigt Diff zwischen Session und Plan, Checkboxen pro Änderung   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Snapshot VOR Apply (captureSnapshot), dann apply, dann save.     /
//                SessionPlanSyncContext ist Identifiable → Sheet(item:) Pattern.  /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

// MARK: - Identifiable Wrapper (für .sheet(item:) — nie .sheet(isPresented:))

struct SessionPlanSyncContext: Identifiable {
    let id: UUID = UUID()
    let session: StrengthSession
    let plan: TrainingPlan
}

// MARK: - Session-Plan Sync Sheet

struct SessionPlanSyncSheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: StrengthSession
    let plan: TrainingPlan

    @State private var changes: [PlanUpdateChange] = []
    @State private var isLoaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerCard

                    // Neue Übungen (aus Session, nicht im Plan) — vorselektiert
                    let addedIndices = addedExerciseIndices
                    if !addedIndices.isEmpty {
                        sectionView(
                            title: "Neue Übungen",
                            icon: "plus.circle.fill",
                            color: Theme.success,
                            indices: addedIndices
                        )
                    }

                    // Strukturelle Änderungen (Gewicht / Satzanzahl)
                    let structuralIndices = changedIndices
                    if !structuralIndices.isEmpty {
                        sectionView(
                            title: "Geänderte Werte",
                            icon: "arrow.up.arrow.down.circle.fill",
                            color: Theme.accent,
                            indices: structuralIndices
                        )
                    }

                    // Nicht trainierte Plan-Übungen (exerciseRemoved — nicht vorselektiert)
                    let removedIndices = removedExerciseIndices
                    if !removedIndices.isEmpty {
                        sectionView(
                            title: "Nicht trainiert",
                            icon: "minus.circle.fill",
                            color: Theme.textSecondary,
                            indices: removedIndices
                        )
                    }

                    // Leerzustand
                    if changes.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Plan aktualisieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button { applySelected() } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(selectedCount == 0 ? Theme.textTertiary : Theme.accent)
                    }
                    .disabled(selectedCount == 0)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            guard !isLoaded else { return }
            isLoaded = true
            let engine = SessionPlanSyncCalcEngine()
            let proposal = engine.analyze(session: session, plan: plan)
            changes = proposal.changes
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title2)
                .foregroundStyle(Theme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Direkter Session-Vergleich")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Text("\(selectedCount) von \(changes.count) Änderungen ausgewählt")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()
        }
        .padding()
        .card()
    }

    // MARK: - Sektion

    private func sectionView(title: String, icon: String, color: Color, indices: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .padding(.horizontal, 4)

            ForEach(indices, id: \.self) { idx in
                PlanUpdateChangeRow(change: $changes[idx])
            }
        }
    }

    // MARK: - Leerzustand

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.success)
            Text("Plan und Session stimmen überein")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("Es gibt keine Unterschiede zwischen dieser Session und deinem Plan.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Index-Filter

    private var addedExerciseIndices: [Int] {
        changes.indices.filter { idx in
            if case .exerciseAdded = changes[idx].changeType { return true }
            return false
        }
    }

    private var changedIndices: [Int] {
        changes.indices.filter { idx in
            switch changes[idx].changeType {
            case .weightUpdate, .setCountUpdate: return true
            default: return false
            }
        }
    }

    private var removedExerciseIndices: [Int] {
        changes.indices.filter { idx in
            if case .exerciseRemoved = changes[idx].changeType { return true }
            return false
        }
    }

    private var selectedCount: Int {
        changes.filter { $0.isSelected }.count
    }

    // MARK: - Anwenden

    private func applySelected() {
        let selected = changes.filter { $0.isSelected }
        guard !selected.isEmpty else { dismiss(); return }

        // 1. Snapshot VOR Apply (für 72h-Undo)
        SessionSyncUndoService.captureSnapshot(for: plan)

        // 2. Änderungen anwenden
        PlanUpdateApplicator.apply(
            changes: selected,
            to: plan,
            context: context,
            sourceSessionUUID: session.sessionUUID.uuidString
        )

        // 3. Session-Sync Felder setzen
        plan.lastSessionSyncDate = Date()
        plan.lastSessionSyncSourceUUID = session.sessionUUID.uuidString

        // 4. Speichern
        try? context.save()

        dismiss()
    }
}

// MARK: - Preview

#Preview("Session Plan Sync Sheet") {
    let plan = TrainingPlan(title: "Push Day A", planType: .strength)
    let session = StrengthSession(date: Date(), workoutType: .push)
    return SessionPlanSyncSheet(session: session, plan: plan)
        .environmentObject(AppSettings.shared)
}
