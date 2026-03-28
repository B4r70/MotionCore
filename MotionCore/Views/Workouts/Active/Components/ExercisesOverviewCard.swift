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
    let prSetIDs: Set<PersistentIdentifier>

    let onAddExercise: () -> Void
    let onSelectExercise: (String) -> Void
    let onDeleteExercise: (String) -> Void
    let onMoveExercise: (String, Int) -> Void

    @State private var isEditMode: Bool = false

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

            // groupKey als stabile ID: SwiftUI kann Rows bei Reihenfolge-Änderungen
            // animieren statt sie komplett neu zu erstellen.
            ForEach(Array(groupedSets.enumerated()), id: \.element.first?.groupKey) { index, sets in
                if let firstSet = sets.first {
                    VStack(spacing: 0) {
                        // ↑ oberhalb der Row (nur im Edit-Modus)
                        if isEditMode {
                            Button {
                                onMoveExercise(firstSet.groupKey, -1)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity, minHeight: 28)
                            }
                            .opacity(index == 0 ? 0 : 1)
                            .disabled(index == 0)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Row mit ✕-Overlay rechts mittig
                        ExerciseOverviewRow(
                            index: index + 1,
                            name: firstSet.exerciseName,
                            sets: sets,
                            isCurrentExercise: index == currentExerciseIndex,
                            isPressed: false,
                            hasSupersetAbove: isSupersetConnectedAbove(at: index),
                            hasSupersetBelow: isSupersetConnectedBelow(at: index),
                            hasPR: hasPR(in: sets)
                        )
                        .frame(maxWidth: .infinity)
                        .overlay {
                            if isEditMode {
                                HStack {
                                    Spacer()
                                    Button {
                                        onDeleteExercise(firstSet.groupKey)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.red)
                                            .frame(minWidth: 44, minHeight: 44)
                                    }
                                    .padding(.trailing, 4)
                                }
                                .transition(.opacity)
                            }
                        }
                        .onTapGesture {
                            guard !isEditMode else { return }
                            onSelectExercise(firstSet.groupKey)
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isEditMode.toggle()
                            }
                        }

                        // ↓ unterhalb der Row (nur im Edit-Modus)
                        if isEditMode {
                            Button {
                                onMoveExercise(firstSet.groupKey, 1)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity, minHeight: 28)
                            }
                            .opacity(index == groupedSets.count - 1 ? 0 : 1)
                            .disabled(index == groupedSets.count - 1)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private var header: some View {
        HStack {
            Text("Übersicht")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()

            // Fertig-Button im Edit-Modus
            if isEditMode {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditMode = false
                    }
                } label: {
                    Text("Fertig")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                }
            } else {
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
