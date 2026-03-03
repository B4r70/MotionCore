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
import SwiftData
import SwiftUI

struct ExercisesOverviewCard: View {
    let groupedSets: [[ExerciseSet]]
    let currentExerciseIndex: Int
    let refreshID: UUID
    let prSetIDs: Set<PersistentModelID>

    let onAddExercise: () -> Void
    let onSelectExercise: (String) -> Void
    let onDeleteExercise: (String) -> Void

    @State private var pressedGroupKey: String? = nil

    private func isSupersetConnectedBelow(at index: Int) -> Bool {
        guard index + 1 < groupedSets.count else { return false }
        guard let thisID = groupedSets[index].first?.supersetGroupId,
              !thisID.isEmpty,
              let nextID = groupedSets[index + 1].first?.supersetGroupId else { return false }
        return thisID == nextID
    }

    private func isSupersetConnectedAbove(at index: Int) -> Bool {
        guard index > 0 else { return false }
        guard let thisID = groupedSets[index].first?.supersetGroupId,
              !thisID.isEmpty,
              let prevID = groupedSets[index - 1].first?.supersetGroupId else { return false }
        return thisID == prevID
    }

    private func hasPR(in sets: [ExerciseSet]) -> Bool {
        sets.contains { prSetIDs.contains($0.persistentModelID) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ForEach(Array(groupedSets.enumerated()), id: \.offset) { index, sets in
                if let firstSet = sets.first {
                    ExerciseOverviewRow(
                        index: index + 1,
                        name: firstSet.exerciseName,
                        sets: sets,
                        isCurrentExercise: index == currentExerciseIndex,
                        isPressed: pressedGroupKey == firstSet.groupKey,
                        hasSupersetAbove: isSupersetConnectedAbove(at: index),
                        hasSupersetBelow: isSupersetConnectedBelow(at: index),
                        hasPR: hasPR(in: sets)
                    )
                    .onTapGesture {
                        onSelectExercise(firstSet.groupKey)
                    }
                    .onLongPressGesture(
                        minimumDuration: 0.5,
                        perform: {
                            onDeleteExercise(firstSet.groupKey)
                            pressedGroupKey = nil
                        },
                        onPressingChanged: { isPressing in
                            if isPressing {
                                pressedGroupKey = firstSet.groupKey
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    pressedGroupKey = nil
                                }
                            }
                        }
                    )
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
    let isPressed: Bool
    let hasSupersetAbove: Bool
    let hasSupersetBelow: Bool
    let hasPR: Bool

    private var completedCount: Int { sets.filter { $0.isCompleted }.count }
    private var isAllCompleted: Bool { completedCount == sets.count }

    var body: some View {
        HStack(spacing: 0) {
            // Vertikale Superset-Linie links
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .opacity(hasSupersetAbove ? 1 : 0)

                if hasSupersetAbove || hasSupersetBelow {
                    Image(systemName: "link")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.blue)
                        .padding(.vertical, 2)
                }

                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .opacity(hasSupersetBelow ? 1 : 0)
            }
            .frame(width: 12)

            // Inhalt
            VStack(spacing: 8) {
                topLine
                dotsLine
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }

    private var topLine: some View {
        HStack {
            Text("\(index). \(name)")
                .font(.subheadline.bold())
                .foregroundStyle(isCurrentExercise ? .blue : .primary)

            Spacer()

            HStack(spacing: 4) {
                if hasPR {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
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

    private var backgroundColor: Color {
        if isPressed {
            return Color.red.opacity(0.15)
        } else if isCurrentExercise {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}
