//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / Plan-Update                                           /
// Datei . . . . : PlanUpdateBanner.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.03.2026                                                       /
// Beschreibung  : Banner in TrainingDetailView für ausstehende Plan-Updates        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Plan-Update Banner

struct PlanUpdateBanner: View {

    let proposal: PlanUpdateProposal
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.blue)

                // Texte
                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Plan-Update")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // X-Button zum Verwerfen
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding()
            .card()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hilfseigenschaften

    private var subtitleText: String {
        let count = proposal.changes.count
        let sessionCount = proposal.analyzedSessionCount
        if count == 1 {
            return "1 Änderung vorgeschlagen (aus \(sessionCount) Sessions)"
        } else {
            return "\(count) Änderungen vorgeschlagen (aus \(sessionCount) Sessions)"
        }
    }
}

// MARK: - Preview

#Preview("Plan Update Banner") {
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
            )
        ],
        analyzedSessionCount: 3,
        analyzedSessionDates: []
    )

    VStack {
        PlanUpdateBanner(
            proposal: proposal,
            onTap: { print("Banner getippt") },
            onDismiss: { print("Banner verworfen") }
        )
        .padding()
    }
}
