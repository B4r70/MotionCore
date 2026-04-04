//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExercisesOverviewCard.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Übungsübersicht eines Workouts mit Drag & Drop Sortierung        /
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
    let onReorderExercise: (Int, Int) -> Void

    // Sortiermodus-State
    @State private var isSortMode: Bool = false

    // Drag & Drop State
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardHeights: [Int: CGFloat] = [:]
    @State private var lastTargetIndex: Int? = nil

    private var averageCardHeight: CGFloat {
        guard !cardHeights.isEmpty else { return 60 }
        return cardHeights.values.reduce(0, +) / CGFloat(cardHeights.count)
    }

    private let cardSpacing: CGFloat = 12

    private func isSupersetMember(at index: Int) -> Bool {
        guard let id = groupedSets[safe: index]?.first?.supersetGroupId else { return false }
        return !id.isEmpty
    }

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

            ZStack(alignment: .top) {
                // Hintergrund-Rows (verschieben sich beim Drag)
                VStack(spacing: 0) {
                    ForEach(Array(groupedSets.enumerated()), id: \.element.first?.groupKey) { index, sets in
                        if let firstSet = sets.first {
                            ExerciseOverviewRow(
                                index: index + 1,
                                name: firstSet.exerciseNameSnapshot,
                                sets: sets,
                                isCurrentExercise: index == currentExerciseIndex,
                                isPressed: false,
                                hasSupersetAbove: isSupersetConnectedAbove(at: index),
                                hasSupersetBelow: isSupersetConnectedBelow(at: index),
                                hasPR: hasPR(in: sets),
                                isSortMode: isSortMode,
                                isSupersetMember: isSupersetMember(at: index)
                            )
                            // Höhe messen für Drag-Berechnung
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear { cardHeights[index] = geo.size.height }
                                        .onChange(of: geo.size.height) { _, h in cardHeights[index] = h }
                                }
                            )
                            .opacity(draggingIndex == index ? 0 : 1)
                            .animation(nil, value: draggingIndex)
                            .modifier(RowOffsetModifier(offset: offsetForIndex(index)))
                            // Drag-Handle Gesture (nur im Sortiermodus, nur wenn kein Superset-Mitglied)
                            .overlay(alignment: .trailing) {
                                if isSortMode {
                                    if isSupersetMember(at: index) {
                                        Image(systemName: "link")
                                            .font(.system(size: 15))
                                            .foregroundStyle(.blue.opacity(0.5))
                                            .frame(width: 36, height: 36)
                                            .padding(.trailing, 4)
                                    } else {
                                        dragHandleView(index: index)
                                    }
                                }
                            }
                            // Tap zum Navigieren (nur außerhalb des Sortiermodus)
                            .onTapGesture {
                                guard !isSortMode else { return }
                                onSelectExercise(firstSet.groupKey)
                            }
                            // LongPress zum Löschen (nur außerhalb des Sortiermodus)
                            .onLongPressGesture(minimumDuration: 0.5) {
                                guard !isSortMode else { return }
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                onDeleteExercise(firstSet.groupKey)
                            }
                            .padding(.bottom, index < groupedSets.count - 1 ? cardSpacing : 0)
                        }
                    }
                }

                // Schwebende Card während Drag
                if let dragIndex = draggingIndex,
                   let sets = groupedSets[safe: dragIndex],
                   let firstSet = sets.first {

                    let yPos = calculateFloatingCardPosition(for: dragIndex)

                    ExerciseOverviewRow(
                        index: dragIndex + 1,
                        name: firstSet.exerciseNameSnapshot,
                        sets: sets,
                        isCurrentExercise: dragIndex == currentExerciseIndex,
                        isPressed: false,
                        hasSupersetAbove: false,
                        hasSupersetBelow: false,
                        hasPR: hasPR(in: sets),
                        isSortMode: true,
                        isSupersetMember: false
                    )
                    .overlay(alignment: .trailing) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .padding(.trailing, 4)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                    .scaleEffect(1.03)
                    .offset(y: yPos + dragOffset.height)
                    .zIndex(1000)
                }
            }
        }
        .glassCard()
        .onChange(of: isSortMode) { _, newValue in
            if !newValue {
                draggingIndex = nil
                dragOffset = .zero
                lastTargetIndex = nil
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Übersicht")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 12) {
                // "(+) Übung"-Button: nur im Nicht-Sortiermodus
                if !isSortMode {
                    Button {
                        onAddExercise()
                    } label: {
                        Label("Übung", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.blue)
                    }
                }

                // Sortier- / Fertig-Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSortMode.toggle()
                    }
                } label: {
                    Image(
                        systemName: isSortMode
                            ? "checkmark.circle.fill"
                            : "arrow.up.arrow.down.circle.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(isSortMode ? .green : .blue)
                    .contentTransition(.symbolEffect(.replace))
                }
            }
        }
    }

    // MARK: - Drag Handle

    @ViewBuilder
    private func dragHandleView(index: Int) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .frame(width: 36, height: 36)
            .padding(.trailing, 4)
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .sequenced(before: DragGesture())
                    .onChanged { value in
                        if case .second(true, let drag) = value {
                            if draggingIndex == nil {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    draggingIndex = index
                                }
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                            if let drag {
                                dragOffset = drag.translation
                                let target = calculateTargetIndex(from: index)
                                if target != lastTargetIndex && target != index {
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                    lastTargetIndex = target
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        let toIndex = calculateTargetIndex(from: index)
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                            draggingIndex = nil
                            dragOffset = .zero
                            lastTargetIndex = nil
                        }
                        if toIndex != index {
                            onReorderExercise(index, toIndex)
                            let gen = UIImpactFeedbackGenerator(style: .medium)
                            gen.impactOccurred()
                        }
                    }
            )
    }

    // MARK: - Positions-Berechnung

    private func yStart(for index: Int) -> CGFloat {
        var y: CGFloat = 0
        for i in 0..<index {
            y += (cardHeights[i] ?? averageCardHeight) + cardSpacing
        }
        return y
    }

    private func calculateFloatingCardPosition(for index: Int) -> CGFloat {
        yStart(for: index)
    }

    private func calculateTargetIndex(from dragIndex: Int) -> Int {
        let count = groupedSets.count
        guard count > 1 else { return dragIndex }

        let draggedHeight = cardHeights[dragIndex] ?? averageCardHeight
        let draggedMidY = yStart(for: dragIndex) + dragOffset.height + draggedHeight / 2

        var bestIndex = dragIndex
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for i in 0..<count {
            let h = cardHeights[i] ?? averageCardHeight
            let mid = yStart(for: i) + h / 2
            let d = abs(mid - draggedMidY)
            if d < bestDistance {
                bestDistance = d
                bestIndex = i
            }
        }

        return bestIndex
    }

    private func offsetForIndex(_ index: Int) -> CGFloat {
        guard let dragIndex = draggingIndex else { return 0 }
        if index == dragIndex { return 0 }

        let target = calculateTargetIndex(from: dragIndex)
        let draggedHeight = (cardHeights[dragIndex] ?? averageCardHeight) + cardSpacing

        if dragIndex < target {
            if (dragIndex + 1)...target ~= index { return -draggedHeight }
        } else if target < dragIndex {
            if target..<dragIndex ~= index { return draggedHeight }
        }

        return 0
    }
}

// MARK: - Row Offset Modifier (verhindert doppelte offsetForIndex-Berechnung)

private struct RowOffsetModifier: ViewModifier {
    let offset: CGFloat
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: offset)
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Exercise Overview Row

private struct ExerciseOverviewRow: View {
    let index: Int
    let name: String
    let sets: [ExerciseSet]
    let isCurrentExercise: Bool
    let isPressed: Bool
    let hasSupersetAbove: Bool
    let hasSupersetBelow: Bool
    let hasPR: Bool
    let isSortMode: Bool
    let isSupersetMember: Bool

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
                        .foregroundStyle(Color.blue)
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
            // Rechts Platz für Drag-Handle lassen im Sortiermodus
            .padding(.trailing, isSortMode ? 32 : 0)
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
                        .foregroundStyle(Color.yellow)
                }
                if isAllCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
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
