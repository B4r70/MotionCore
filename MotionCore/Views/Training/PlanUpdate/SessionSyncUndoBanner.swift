//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / Plan-Update                                           /
// Datei . . . . : SessionSyncUndoBanner.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 28.04.2026                                                       /
// Beschreibung  : Kompakter Undo-Banner für Session-Plan-Sync (Option A)           /
//                 Erscheint wenn Snapshot vorhanden und < 72h alt                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

// MARK: - Session-Sync Undo Banner

struct SessionSyncUndoBanner: View {

    @Environment(\.modelContext) private var context

    let plan: TrainingPlan
    let onUndo: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundStyle(Color.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Plan-Sync rückgängig machen?")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                // Rückgängig-Button
                Button {
                    SessionSyncUndoService.undo(plan: plan, context: context)
                    onUndo()
                } label: {
                    Text("Rückgängig")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                }

                // Verwerfen-Button
                Button {
                    SessionSyncUndoService.discard(plan: plan, context: context)
                    onDiscard()
                } label: {
                    Text("Verwerfen")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Hilfseigenschaften

    private var subtitleText: String {
        guard let syncDate = plan.lastSessionSyncDate else {
            return "Änderungen aus Session-Sync"
        }
        let hours = Int(Date().timeIntervalSince(syncDate) / 3600)
        if hours < 1 {
            return "Sync vor wenigen Minuten"
        } else if hours == 1 {
            return "Sync vor 1 Stunde"
        } else {
            return "Sync vor \(hours) Stunden"
        }
    }
}

// MARK: - Preview

#Preview("Session Sync Undo Banner") {
    let plan = TrainingPlan(title: "Push Day A", planType: .strength)
    plan.lastSessionSyncDate = Date().addingTimeInterval(-3600) // 1h zurück

    return VStack {
        SessionSyncUndoBanner(
            plan: plan,
            onUndo: { print("Rückgängig") },
            onDiscard: { print("Verworfen") }
        )
        .padding()
    }
}
