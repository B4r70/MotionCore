//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : MuscleRecoveryDetailView.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Detail-Sheet zur Muskelgruppen-Erholung — Score, Gruppen,        /
//                 aufklappbare Einzel-Muskeln mit relativer Zeit                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - MuscleRecoveryDetailView

struct MuscleRecoveryDetailView: View {

    // MARK: - Eingaben

    let analysis: MuscleRecoveryAnalysis

    // MARK: - Umgebung

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Lokaler State

    /// ID der aktuell aufgeklappten Muskelgruppe
    @State private var expandedGroupId: String? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        groupListSection
                    }
                    .scrollViewContentPadding()
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Muskel-Erholung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            MuscleRecoveryDonut(
                percent: analysis.overallRecoveryPercent,
                wasTrained: !analysis.leastRecoveredGroups.isEmpty,
                label: "Gesamt",
                size: 120
            )

            Text("Muskel-Erholung")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Letzte 14 Tage • \(Int(analysis.overallRecoveryPercent.rounded()))% erholt")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    // MARK: - Gruppen-Liste

    private var groupListSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Muskelgruppen")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(analysis.muscleGroupScores.indices, id: \.self) { idx in
                    let group = analysis.muscleGroupScores[idx]

                    MuscleGroupRow(
                        group: group,
                        isExpanded: expandedGroupId == group.id,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedGroupId == group.id {
                                    expandedGroupId = nil
                                } else {
                                    expandedGroupId = group.wasTrainedInTimeframe ? group.id : nil
                                }
                            }
                        }
                    )

                    if idx < analysis.muscleGroupScores.count - 1 {
                        Divider()
                            .padding(.horizontal, 4)
                    }
                }
            }
            .glassCard()
        }
    }

}

// MARK: - MuscleGroupRow

/// Zeile für eine Muskelgruppe mit optionaler aufklappbarer Detailliste
private struct MuscleGroupRow: View {

    let group: MuscleGroupRecovery
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Hauptzeile
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Donut
                    MuscleRecoveryDonut(
                        percent: group.recoveryPercent,
                        wasTrained: group.wasTrainedInTimeframe,
                        label: group.displayName,
                        size: 44
                    )

                    // Name + relative Zeit
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(group.wasTrainedInTimeframe ? .primary : .secondary)

                        Text(relativeTimeString(from: group.lastTrainedDate))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Erholungsprozent rechts
                    Text("\(Int(group.recoveryPercent.rounded()))%")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            group.wasTrainedInTimeframe
                                ? recoveryColor(percent: group.recoveryPercent)
                                : .secondary
                        )

                    // Aufklapp-Chevron (nur bei trainierten Gruppen mit Details)
                    if group.wasTrainedInTimeframe && !group.muscleDetails.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Aufgeklappte Detail-Liste
            if isExpanded && group.wasTrainedInTimeframe && !group.muscleDetails.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal, 4)

                    ForEach(group.muscleDetails) { detail in
                        DetailedMuscleRow(detail: detail)

                        if detail.id != group.muscleDetails.last?.id {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func relativeTimeString(from date: Date?) -> String {
        guard let date else { return "noch nicht trainiert" }
        let hours = Int(Date().timeIntervalSince(date) / 3600)
        if hours < 24 { return "vor \(hours)h" }
        let days = hours / 24
        return days == 1 ? "vor 1 Tag" : "vor \(days) Tagen"
    }
}

// MARK: - DetailedMuscleRow

/// Eingerückte Zeile für einen einzelnen Muskel innerhalb der aufgeklappten Gruppe
private struct DetailedMuscleRow: View {

    let detail: DetailedMuscleRecovery

    var body: some View {
        HStack {
            // Einrückung
            Spacer()
                .frame(width: 60)

            Text(detail.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(Int(detail.recoveryPercent.rounded()))%")
                .font(.caption.weight(.medium))
                .foregroundStyle(recoveryColor(percent: detail.recoveryPercent))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview("MuscleRecoveryDetailView") {
    MuscleRecoveryDetailView(analysis: MuscleRecoveryAnalysis(
        analysisDate: .now,
        timeframeDays: 7,
        muscleGroupScores: [
            MuscleGroupRecovery(id: "chest", muscleGroup: .chest, recoveryPercent: 87, muscleDetails: [], lastTrainedDate: Calendar.current.date(byAdding: .day, value: -2, to: .now), wasTrainedInTimeframe: true),
            MuscleGroupRecovery(id: "back",  muscleGroup: .back,  recoveryPercent: 45, muscleDetails: [], lastTrainedDate: Calendar.current.date(byAdding: .day, value: -1, to: .now), wasTrainedInTimeframe: true),
            MuscleGroupRecovery(id: "legs",  muscleGroup: .legs,  recoveryPercent: 62, muscleDetails: [], lastTrainedDate: Calendar.current.date(byAdding: .day, value: -3, to: .now), wasTrainedInTimeframe: true)
        ],
        detailedScores: []
    ))
    .environmentObject(AppSettings.shared)
}
