//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExercisesOverviewCard.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Übungsübersicht eines Workouts                                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ExercisesOverviewCard: View {
    let groupedSets: [[ExerciseSet]]
    let currentExerciseIndex: Int
    let refreshID: UUID

    let onAddExercise: () -> Void
    let onSelectExercise: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ForEach(Array(groupedSets.enumerated()), id: \.offset) { index, sets in
                if let firstSet = sets.first {
                    ExerciseOverviewRow(
                        index: index + 1,
                        name: firstSet.exerciseName,
                        sets: sets,
                        isCurrentExercise: index == currentExerciseIndex
                    )
                    .onTapGesture {
                        onSelectExercise(firstSet.groupKey)
                    }
                }
            }
        }
        .glassCard()
        .id(refreshID)
    }

    private var header: some View {
        HStack {
            Text("Übersicht")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()

            Button {
                onAddExercise()
            } label: {
                Label("Übung", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
            }
        }
    }
}

private struct ExerciseOverviewRow: View {
    let index: Int
    let name: String
    let sets: [ExerciseSet]
    let isCurrentExercise: Bool

    private var completedCount: Int { sets.filter { $0.isCompleted }.count }
    private var isAllCompleted: Bool { completedCount == sets.count }

    var body: some View {
        VStack(spacing: 8) {
            topLine
            dotsLine
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentExercise ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private var topLine: some View {
        HStack {
            Text("\(index). \(name)")
                .font(.subheadline.bold())
                .foregroundStyle(isCurrentExercise ? .blue : .primary)

            Spacer()

            if isAllCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("\(completedCount)/\(sets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dotsLine: some View {
        HStack(spacing: 6) {
            ForEach(sets, id: \.persistentModelID) { set in
                Circle()
                    .fill(set.isCompleted ? Color.green : Color.primary.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .overlay {
                        if set.setKind == .warmup {
                            Circle()
                                .stroke(Color.orange, lineWidth: 2)
                        }
                    }
            }
            Spacer()
        }
    }
}
