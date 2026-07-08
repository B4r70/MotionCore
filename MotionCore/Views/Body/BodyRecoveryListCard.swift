//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyRecoveryListCard.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Liste aller Muskelgruppen mit Erholungsstatus, aufsteigend       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyRecoveryListCard

struct BodyRecoveryListCard: View {

    // MARK: - Eingaben

    let analysis: MuscleRecoveryAnalysis
    let onTapGroup: (MuscleGroupRecovery) -> Void

    // MARK: - Computed

    private var sortedGroups: [MuscleGroupRecovery] {
        analysis.muscleGroupScores.sorted { $0.recoveryPercent < $1.recoveryPercent }
    }

    // MARK: - Hilfsmethoden

    /// Relative Zeitangabe wann die Gruppe zuletzt trainiert wurde
    private func relativeTime(for group: MuscleGroupRecovery) -> String? {
        guard let date = group.lastTrainedDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muskelgruppen")
                .font(.headline)

            if sortedGroups.isEmpty {
                EmptyState()
            } else {
                ForEach(Array(sortedGroups.enumerated()), id: \.element.id) { index, group in
                    VStack(spacing: 0) {
                        groupRow(group)
                            .onTapGesture { onTapGroup(group) }

                        if index < sortedGroups.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Zeilenaufbau

    @ViewBuilder
    private func groupRow(_ group: MuscleGroupRecovery) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Prozentwert
            Text("\(Int(group.recoveryPercent))%")
                .font(.title3.bold())
                .monospacedDigit()
                .foregroundStyle(recoveryColor(percent: group.recoveryPercent))
                .frame(width: 52, alignment: .leading)

            // Name + Fortschrittsbalken
            VStack(alignment: .leading, spacing: 3) {
                Text(group.displayName)
                    .font(.subheadline)

                MCFactorBar(
                    label: "",
                    subLabel: nil,
                    value: group.recoveryPercent / 100.0,
                    color: recoveryColor(percent: group.recoveryPercent)
                )
                .frame(height: 6)
            }

            Spacer()

            // Relative Zeit (optional)
            if let time = relativeTime(for: group) {
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        BodyRecoveryListCard(
            analysis: MuscleRecoveryAnalysis(
                analysisDate: .now,
                timeframeDays: 7,
                muscleGroupScores: [
                    MuscleGroupRecovery(
                        id: "chest",
                        muscleGroup: .chest,
                        recoveryPercent: 92,
                        muscleDetails: [],
                        lastTrainedDate: Calendar.current.date(byAdding: .day, value: -3, to: .now),
                        wasTrainedInTimeframe: true
                    ),
                    MuscleGroupRecovery(
                        id: "legs",
                        muscleGroup: .legs,
                        recoveryPercent: 45,
                        muscleDetails: [],
                        lastTrainedDate: Calendar.current.date(byAdding: .hour, value: -18, to: .now),
                        wasTrainedInTimeframe: true
                    ),
                    MuscleGroupRecovery(
                        id: "back",
                        muscleGroup: .back,
                        recoveryPercent: 70,
                        muscleDetails: [],
                        lastTrainedDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
                        wasTrainedInTimeframe: true
                    )
                ],
                detailedScores: []
            ),
            onTapGroup: { _ in }
        )
        .padding()
    }
}
