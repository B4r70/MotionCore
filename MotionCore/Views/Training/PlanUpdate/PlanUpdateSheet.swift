//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / Plan-Update                                           /
// Datei . . . . : PlanUpdateSheet.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.03.2026                                                       /
// Beschreibung  : Sheet zur Übernahme von Plan-Update-Vorschlägen                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

// MARK: - Plan-Update Sheet

struct PlanUpdateSheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let proposal: PlanUpdateProposal
    let onApply: () -> Void

    @State private var changes: [PlanUpdateChange]

    init(proposal: PlanUpdateProposal, onApply: @escaping () -> Void) {
        self.proposal = proposal
        self.onApply = onApply
        _changes = State(initialValue: proposal.changes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Space.s4) {
                    // Header-Card
                    headerCard

                    // Strukturelle Änderungen (Gewicht, Satzanzahl) — Akzentfarbe (Info/geändert)
                    let structuralChanges = structuralIndices
                    if !structuralChanges.isEmpty {
                        sectionView(
                            title: "Strukturelle Änderungen",
                            icon: "arrow.up.arrow.down",
                            color: Theme.accent,
                            indices: structuralChanges
                        )
                    }

                    // Neue Übungen — Erfolg/hinzugefügt
                    let newExerciseChanges = newExerciseIndices
                    if !newExerciseChanges.isEmpty {
                        sectionView(
                            title: "Neue Übungen",
                            icon: "plus.circle",
                            color: Theme.success,
                            indices: newExerciseChanges
                        )
                    }

                    // Übersprungene Übungen (nur Info) — Warnung
                    let skippedChanges = skippedIndices
                    if !skippedChanges.isEmpty {
                        sectionView(
                            title: "Übersprungene Übungen",
                            icon: "eye.slash",
                            color: Theme.warning,
                            indices: skippedChanges
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Space.s4)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Plan-Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button { applyChanges() } label: { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
                    .disabled(selectedCount == 0)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header-Card

    private var headerCard: some View {
        HStack(spacing: Space.s3) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Theme.accent)

            VStack(alignment: .leading, spacing: Space.s1) {
                Text("Vorschlag basierend auf \(proposal.analyzedSessionCount) Sessions")
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)

                Text("\(selectedCount) von \(changes.count) Änderungen ausgewählt")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()
        }
        .padding()
        .card()
    }

    // MARK: - Sektion

    private func sectionView(title: String, icon: String, color: Color, indices: [Int]) -> some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Label(title, systemImage: icon)
                .font(AppFont.callout)
                .foregroundStyle(color)
                .padding(.horizontal, Space.s1)

            ForEach(indices, id: \.self) { idx in
                PlanUpdateChangeRow(change: $changes[idx])
            }
        }
    }

    // MARK: - Index-Filter (für index-basiertes Binding)

    private var structuralIndices: [Int] {
        changes.indices.filter { idx in
            switch changes[idx].changeType {
            case .weightUpdate, .setCountUpdate: return true
            default: return false
            }
        }
    }

    private var newExerciseIndices: [Int] {
        changes.indices.filter { idx in
            if case .exerciseAdded = changes[idx].changeType { return true }
            return false
        }
    }

    private var skippedIndices: [Int] {
        changes.indices.filter { idx in
            if case .exerciseSkipped = changes[idx].changeType { return true }
            return false
        }
    }

    private var selectedCount: Int {
        changes.filter { $0.isSelected }.count
    }

    // MARK: - Anwenden

    private func applyChanges() {
        let selected = changes.filter { $0.isSelected }
        PlanUpdateApplicator.apply(
            changes: selected,
            to: proposal.plan,
            context: context,
            sourceSessionUUID: proposal.sourceSessionUUID
        )
        try? context.save()
        onApply()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Plan Update Sheet") {
    let plan = TrainingPlan(title: "Push Day A", planType: .strength)
    let proposal = PlanUpdateProposal(
        plan: plan,
        changes: [
            PlanUpdateChange(
                exerciseGroupKey: "bench",
                exerciseName: "Bankdrücken",
                changeType: .weightUpdate(from: 80, to: 85),
                isSelected: true
            ),
            PlanUpdateChange(
                exerciseGroupKey: "ohp",
                exerciseName: "Schulterdrücken",
                changeType: .setCountUpdate(from: 3, to: 4),
                isSelected: true
            ),
            PlanUpdateChange(
                exerciseGroupKey: "lateral",
                exerciseName: "Seitheben",
                changeType: .exerciseAdded(sets: []),
                isSelected: false
            ),
            PlanUpdateChange(
                exerciseGroupKey: "fly",
                exerciseName: "Kabelzug Flys",
                changeType: .exerciseSkipped(timesSkipped: 2, outOf: 3),
                isSelected: false
            )
        ],
        analyzedSessionCount: 3,
        analyzedSessionDates: []
    )

    PlanUpdateSheet(proposal: proposal, onApply: {})
        .environmentObject(AppSettings.shared)
}
