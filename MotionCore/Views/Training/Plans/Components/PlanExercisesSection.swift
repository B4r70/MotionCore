//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanExercisesSection.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Übungsliste mit Empty State für Trainingsplan                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
import SwiftUI

// MARK: - Modus fuer die Uebungsanzeige

enum PlanExercisesMode {
    case form      // Bearbeitbar mit Edit/Delete
    case detail    // Nur Anzeige
}

// MARK: - Uebungs-Section

struct PlanExercisesSection: View {
    let plan: TrainingPlan
    let mode: PlanExercisesMode

    // Callbacks fuer Form-Modus
    var onAddExercise: (() -> Void)? = nil
    var onEditExercise: ((ExerciseSet) -> Void)? = nil
    var onDeleteExercise: ((ExerciseSet) -> Void)? = nil
    var onMoveExercise: ((IndexSet, Int) -> Void)? = nil

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            exerciseHeaderView

            if plan.safeTemplateSets.isEmpty {
                emptyStateView
            } else {
                exercisesList
            }
        }
    }

    // MARK: - Header

    private var exerciseHeaderView: some View {
        HStack {
            Text("Übungen")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()

            switch mode {
            case .form:
                HStack(spacing: 12) {
                    // Hinzufügen Button (nur wenn nicht im Sortier-Modus)
                    if let onAdd = onAddExercise {
                        Button { onAdd() } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .opacity(isEditing ? 0 : 1)
                        .scaleEffect(isEditing ? 0.5 : 1)
                    }

                    // Sortieren/Fertig Button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isEditing.toggle()
                        }
                    } label: {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isEditing ? .green : .blue)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                case .detail:
                    if !plan.safeTemplateSets.isEmpty {
                        NavigationLink {
                            TrainingFormView(mode: .edit, plan: plan)
                        } label: {
                            Text("Bearbeiten")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Noch keine Übungen")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Füge Übungen hinzu, um deinen\nTrainingsplan zu erstellen")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if mode == .form, let onAdd = onAddExercise {
                Button { onAdd() } label: {
                    Label("Übung hinzufügen", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                }
            } else if mode == .detail {
                NavigationLink {
                    TrainingFormView(mode: .edit, plan: plan)
                } label: {
                    Text("Übungen hinzufügen")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassCard()
        .padding(.horizontal)
    }

    // MARK: - Uebungsliste

    @ViewBuilder
    private var exercisesList: some View {
        switch mode {
        case .form:
            ReorderableExerciseList(
                isEditing: $isEditing,
                plan: plan,
                onEdit: { set in onEditExercise?(set) },
                onDelete: { set in onDeleteExercise?(set) },
                onReorder: { from, to in
                    // Optionaler Callback falls du im Parent mitziehen willst
                    onMoveExercise?(IndexSet(integer: from), to)

                    // Deine Plan-Methode (präzise)
                    plan.reorderExercise(from: from, to: to)
                }
            )
            .padding(.horizontal)

        case .detail:
            VStack(spacing: 12) {
                ForEach(
                    Array(plan.groupedTemplateSets.enumerated()),
                    id: \.element.first?.persistentModelID
                ) { index, setsGroup in
                    if let firstSet = setsGroup.first {
                        ExerciseDetailRow(
                            exerciseName: firstSet.exerciseName,
                            mediaAssetName: firstSet.exerciseMediaAssetName,
                            sets: setsGroup,
                            index: index + 1
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Reorderable Exercise List mit Custom Drag & Drop

struct ReorderableExerciseList: View {
    @Binding var isEditing: Bool
    let plan: TrainingPlan
    let onEdit: (ExerciseSet) -> Void
    let onDelete: (ExerciseSet) -> Void
    let onReorder: (Int, Int) -> Void

    // Drag State
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardHeights: [Int: CGFloat] = [:]
    @State private var lastTargetIndex: Int? = nil

    private var averageCardHeight: CGFloat {
        guard !cardHeights.isEmpty else { return 120 }
        return cardHeights.values.reduce(0, +) / CGFloat(cardHeights.count)
    }

    private let cardSpacing: CGFloat = 12

    var body: some View {
        ZStack(alignment: .top) {
            // Hintergrund-Cards (die sich verschieben)
            VStack(spacing: cardSpacing) {
                ForEach(Array(plan.groupedTemplateSets.enumerated()), id: \.element.first?.persistentModelID) { index, setsGroup in
                    if let firstSet = setsGroup.first {
                        ReorderableCard(
                            exerciseName: firstSet.exerciseName,
                            mediaAssetName: firstSet.exerciseMediaAssetName,
                            sets: setsGroup,
                            index: index,
                            isDragging: draggingIndex == index,
                            isEditing: isEditing,
                            offset: offsetForIndex(index),
                            onEdit: { onEdit(firstSet) },
                            onDelete: { onDelete(firstSet) }, // ✅ richtig: ExerciseSet
                            onDragStarted: { startDragging(index: index) },
                            onDragChanged: { translation in updateDrag(translation: translation, fromIndex: index) },
                            onDragEnded: { endDragging(fromIndex: index) },
                            onHeightMeasured: { height in cardHeights[index] = height }
                        )
                    }
                }
            }

            // Schwebende Card (die mit dem Finger bewegt wird)
            if let dragIndex = draggingIndex,
               let setsGroup = plan.groupedTemplateSets[safe: dragIndex],
               let firstSet = setsGroup.first {

                let yPosition = calculateFloatingCardPosition(for: dragIndex)

                FloatingDragCard(
                    exerciseName: firstSet.exerciseName,
                    mediaAssetName: firstSet.exerciseMediaAssetName,
                    sets: setsGroup
                )
                .offset(y: yPosition + dragOffset.height)
                .zIndex(1000)
            }
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                draggingIndex = nil
                dragOffset = .zero
                lastTargetIndex = nil
            }
        }
    }

    // MARK: - Drag Handlers

    private func startDragging(index: Int) {
        guard isEditing else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            draggingIndex = index
        }
        hapticFeedback(.medium)
    }

    private func updateDrag(translation: CGSize, fromIndex: Int) {
        dragOffset = translation

        let targetIndex = calculateTargetIndex(from: fromIndex)
        if targetIndex != lastTargetIndex && targetIndex != fromIndex {
            hapticFeedback(.light)
            lastTargetIndex = targetIndex
        }
    }

    private func endDragging(fromIndex: Int) {
        let toIndex = calculateTargetIndex(from: fromIndex)

        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = .zero
            draggingIndex = nil
            lastTargetIndex = nil
        }

        if toIndex != fromIndex {
            onReorder(fromIndex, toIndex)
            hapticFeedback(.medium)
        }
    }

    // MARK: - Position Calculations

    private func calculateFloatingCardPosition(for index: Int) -> CGFloat {
        var position: CGFloat = 0
        for i in 0..<index {
            position += (cardHeights[i] ?? averageCardHeight) + cardSpacing
        }
        return position
    }

    private func offsetForIndex(_ index: Int) -> CGFloat {
        guard let dragIndex = draggingIndex else { return 0 }
        if index == dragIndex { return 0 }

        let target = calculateTargetIndex(from: dragIndex)
        let draggedHeight = cardHeights[dragIndex] ?? averageCardHeight
        let shift = draggedHeight + cardSpacing

        if dragIndex < target {
            if (dragIndex + 1)...target ~= index { return -shift }
        } else if target < dragIndex {
            if target..<(dragIndex) ~= index { return shift }
        }

        return 0
    }

    private func yStart(for index: Int) -> CGFloat {
        var y: CGFloat = 0
        for i in 0..<index {
            y += (cardHeights[i] ?? averageCardHeight) + cardSpacing
        }
        return y
    }

    private func calculateTargetIndex(from dragIndex: Int) -> Int {
        let count = plan.groupedTemplateSets.count
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

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Reorderable Card mit Drag Handle

private struct ReorderableCard: View {
    let exerciseName: String
    let mediaAssetName: String
    let sets: [ExerciseSet]
    let index: Int
    let isDragging: Bool
    let isEditing: Bool
    let offset: CGFloat
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDragStarted: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onHeightMeasured: (CGFloat) -> Void

    @State private var hasStartedDrag = false

    var body: some View {
        TemplateSetCard(
            exerciseName: exerciseName,
            mediaAssetName: mediaAssetName,
            sets: sets,
            onDelete: onDelete,
            onEdit: onEdit,
            showsEditMenu: !isEditing
        ) {
            if isEditing {
                dragHandle
            } else {
                EmptyView()
            }
        }
        .opacity(isDragging ? 0 : 1)
        .animation(nil, value: isDragging)
        .offset(y: offset)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: offset)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { onHeightMeasured(geo.size.height) }
                    .onChange(of: geo.size.height) { _, newHeight in
                        onHeightMeasured(newHeight)
                    }
            }
        )
    }

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 36, height: 36)
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .sequenced(before: DragGesture())
                    .onChanged { value in
                        if case .second(true, let drag) = value {
                            if !hasStartedDrag {
                                hasStartedDrag = true
                                onDragStarted()
                            }
                            if let drag { onDragChanged(drag.translation) }
                        }
                    }
                    .onEnded { _ in
                        if hasStartedDrag {
                            hasStartedDrag = false
                            onDragEnded()
                        }
                    }
            )
    }
}

// MARK: - Floating Drag Card

private struct FloatingDragCard: View {
    let exerciseName: String
    let mediaAssetName: String
    let sets: [ExerciseSet]

    var body: some View {
        TemplateSetCard(
            exerciseName: exerciseName,
            mediaAssetName: mediaAssetName,
            sets: sets,
            onDelete: {},
            onEdit: {}
        ) {
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
        }
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
        .scaleEffect(1.02)
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Exercise Detail Row (für Detail-Ansicht)

struct ExerciseDetailRow: View {
    let exerciseName: String
    let mediaAssetName: String
    let sets: [ExerciseSet]
    let index: Int

    private var workingSets: [ExerciseSet] {
        sets.filter { !$0.isWarmup }
    }

    private var warmupSets: [ExerciseSet] {
        sets.filter { $0.isWarmup }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
            // Anzeige MP4 Übungsdurchführung
            ExerciseVideoView(
                assetName: mediaAssetName,
                size: 50
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    if let firstWorkingSet = workingSets.first {
                        Text("\(workingSets.count) x \(firstWorkingSet.reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if firstWorkingSet.weight > 0 {
                            Text("@ \(String(format: "%.1f", firstWorkingSet.weight)) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !warmupSets.isEmpty {
                        Text("+\(warmupSets.count) Aufwärm.")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
}

// MARK: - Preview

#Preview("Plan Exercises Section - Form Mode") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)

        ScrollView {
            PlanExercisesSection(
                plan: TrainingPlan(title: "Push Day"),
                mode: .form,
                onAddExercise: { print("Add") },
                onEditExercise: { set in print("Edit: \(set.exerciseName)") },
                onDeleteExercise: { set in print("Delete: \(set.exerciseName)") }
            )
        }
    }
    .environmentObject(AppSettings.shared)
}

#Preview("Plan Exercises Section - Detail Mode") {
    NavigationStack {
        ZStack {
            AnimatedBackground(showAnimatedBlob: true)

            ScrollView {
                PlanExercisesSection(
                    plan: TrainingPlan(title: "Push Day"),
                    mode: .detail
                )
            }
        }
    }
    .environmentObject(AppSettings.shared)
}
