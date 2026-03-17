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
import SwiftData
import SwiftUI

// MARK: - Modus fuer die Uebungsanzeige

enum PlanExercisesMode {
    case form      // Bearbeitbar mit Edit/Delete
    case detail    // Nur Anzeige
}

// MARK: - Superset-Label

/// Gibt den passenden Superset-Typ-Namen zurück
private func supersetLabel(for count: Int) -> String {
    switch count {
    case 2: return "Double Set"
    case 3: return "Tri Set"
    default: return "Giant Set"  // 4–5
    }
}

// MARK: - Uebungs-Section

struct PlanExercisesSection: View {
    let plan: TrainingPlan
    let mode: PlanExercisesMode
    @Environment(\.modelContext) private var modelContext

    // Callbacks fuer Form-Modus
    var onAddExercise: (() -> Void)? = nil
    var onEditExercise: ((ExerciseSet) -> Void)? = nil
    var onDeleteExercise: ((ExerciseSet) -> Void)? = nil
    var onMoveExercise: ((IndexSet, Int) -> Void)? = nil

    @State private var isEditing = false

    // Multi-Select-Modus fuer Superset-Erstellung
    @State private var isSupersetSelectionMode: Bool = false
    @State private var selectedGroupIndicesForSuperset: Set<Int> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                exerciseHeaderView

                if plan.safeTemplateSets.isEmpty {
                    emptyStateView
                } else {
                    exercisesList
                }
            }

            // Floating Action Bar im Superset-Auswahl-Modus
            if isSupersetSelectionMode {
                supersetActionBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSupersetSelectionMode)
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
                    // Superset-Auswahl-Button (nur wenn nicht im Sortier-Modus)
                    if !plan.safeTemplateSets.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSupersetSelectionMode = true
                                selectedGroupIndicesForSuperset = []
                            }
                        } label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .opacity(isEditing ? 0 : 1)
                        .scaleEffect(isEditing ? 0.5 : 1)
                    }

                    // Hinzufügen-Button (nur wenn nicht im Sortier-Modus)
                    if let onAdd = onAddExercise {
                        Button { onAdd() } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .opacity(isEditing ? 0 : 1)
                        .scaleEffect(isEditing ? 0.5 : 1)
                    }

                    // Sortieren/Fertig-Button
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
                isSupersetSelectionMode: $isSupersetSelectionMode,
                selectedGroupIndices: $selectedGroupIndicesForSuperset,
                plan: plan,
                onEdit: { set in onEditExercise?(set) },
                onDelete: { set in onDeleteExercise?(set) },
                onReorder: { from, to in
                    onMoveExercise?(IndexSet(integer: from), to)
                    plan.reorderExercise(from: from, to: to)
                },
                onRemoveFromSuperset: { index in
                    plan.removeFromSuperset(groupAt: index)
                    try? modelContext.save()
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
                            index: index + 1,
                            isInSuperset: (setsGroup.first?.supersetGroupId != nil)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Floating Action Bar

    private var supersetActionBar: some View {
        HStack(spacing: 12) {
            // Anzahl ausgewählter Übungen
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedGroupIndicesForSuperset.count) Übungen ausgewählt")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text("Mindestens 2 für ein Superset")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Abbrechen
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSupersetSelectionMode = false
                    selectedGroupIndicesForSuperset = []
                }
            } label: {
                Text("Abbrechen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Superset erstellen
            Button {
                plan.createSuperset(fromGroupIndices: Array(selectedGroupIndicesForSuperset))
                try? modelContext.save()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSupersetSelectionMode = false
                    selectedGroupIndicesForSuperset = []
                }
            } label: {
                Text("Superset")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedGroupIndicesForSuperset.count >= 2
                            ? Color.blue
                            : Color.blue.opacity(0.3),
                        in: Capsule()
                    )
            }
            .disabled(selectedGroupIndicesForSuperset.count < 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Reorderable Exercise List mit Custom Drag & Drop

struct ReorderableExerciseList: View {
    @Binding var isEditing: Bool
    @Binding var isSupersetSelectionMode: Bool
    @Binding var selectedGroupIndices: Set<Int>
    let plan: TrainingPlan
    let onEdit: (ExerciseSet) -> Void
    let onDelete: (ExerciseSet) -> Void
    let onReorder: (Int, Int) -> Void
    let onRemoveFromSuperset: (Int) -> Void

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
    private let supersetSpacing: CGFloat = 4

    // Anzahl der Übungen in jedem Superset (nach supersetGroupId)
    private func supersetSize(for groupId: String) -> Int {
        let groups = plan.groupedTemplateSets
        return groups.filter { $0.first?.supersetGroupId == groupId }.count
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Hintergrund-Cards (die sich verschieben)
            VStack(spacing: 0) {
                let groups = plan.groupedTemplateSets
                ForEach(Array(groups.enumerated()), id: \.element.first?.persistentModelID) { index, setsGroup in
                    if let firstSet = setsGroup.first {
                        let isInSuperset = firstSet.supersetGroupId != nil
                        let groupId = firstSet.supersetGroupId
                        let isFirstInGroup = isFirstSupersetMember(at: index, in: groups)
                        let isLastInGroup = isLastSupersetMember(at: index, in: groups)

                        VStack(spacing: 0) {
                            // Superset-Label über der ersten Übung einer Gruppe
                            if isInSuperset, isFirstInGroup, let gId = groupId {
                                let size = supersetSize(for: gId)
                                HStack {
                                    Text(supersetLabel(for: size))
                                        .font(.caption.bold())
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.12), in: Capsule())
                                    Spacer()
                                }
                                .padding(.bottom, 4)
                                .padding(.top, index == 0 ? 0 : 4)
                            }

                            // Die eigentliche Card
                            supersetCardWrapper(
                                setsGroup: setsGroup,
                                firstSet: firstSet,
                                index: index,
                                isInSuperset: isInSuperset,
                                isLastInGroup: isLastInGroup
                            )
                        }
                        // Abstand: kleiner innerhalb eines Supersets, normal zwischen Gruppen
                        .padding(.bottom, spacingAfter(index: index, in: groups))
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
        .onChange(of: isSupersetSelectionMode) { _, newValue in
            if !newValue {
                selectedGroupIndices = []
            }
        }
    }

    // MARK: - Card mit optionalem Superset-Seitenstreifen

    @ViewBuilder
    private func supersetCardWrapper(
        setsGroup: [ExerciseSet],
        firstSet: ExerciseSet,
        index: Int,
        isInSuperset: Bool,
        isLastInGroup: Bool
    ) -> some View {
        let isSelected = selectedGroupIndices.contains(index)
        let alreadyInSuperset = isInSuperset && isSupersetSelectionMode

        ZStack(alignment: .leading) {
            // Linker blauer Seitenstreifen für Superset-Mitglieder
            if isInSuperset {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 3)
                    Spacer()
                }
                // Streifen läuft durch den Abstand zur nächsten Karte
                .frame(height: (cardHeights[index] ?? averageCardHeight) + (isLastInGroup ? 0 : supersetSpacing))
            }

            ReorderableCard(
                exerciseName: firstSet.exerciseName,
                mediaAssetName: firstSet.exerciseMediaAssetName,
                sets: setsGroup,
                index: index,
                isDragging: draggingIndex == index,
                isEditing: isEditing,
                offset: offsetForIndex(index),
                onEdit: { onEdit(firstSet) },
                onDelete: { onDelete(firstSet) },
                onDragStarted: { startDragging(index: index) },
                onDragChanged: { translation in updateDrag(translation: translation, fromIndex: index) },
                onDragEnded: { endDragging(fromIndex: index) },
                onHeightMeasured: { height in cardHeights[index] = height },
                onRemoveFromSuperset: isInSuperset ? { onRemoveFromSuperset(index) } : nil
            )
            // Auswahl-Overlay im Superset-Modus
            .overlay(
                Group {
                    if isSupersetSelectionMode {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.blue : Color.clear,
                                lineWidth: 2
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        alreadyInSuperset
                                            ? Color.black.opacity(0.25)
                                            : (isSelected ? Color.blue.opacity(0.08) : Color.clear)
                                    )
                            )
                    }
                }
            )
            // Checkmark-Badge bei Selektion
            .overlay(alignment: .topTrailing) {
                if isSupersetSelectionMode && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, .blue)
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            // Hinweis-Icon bei bereits im Superset
            .overlay(alignment: .topTrailing) {
                if isSupersetSelectionMode && alreadyInSuperset && !isSelected {
                    Image(systemName: "link.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, Color.blue.opacity(0.5))
                        .padding(8)
                }
            }
            // Tap-Overlay im Superset-Auswahl-Modus
            .contentShape(Rectangle())
            .onTapGesture {
                guard isSupersetSelectionMode else { return }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    if selectedGroupIndices.contains(index) {
                        selectedGroupIndices.remove(index)
                    } else {
                        selectedGroupIndices.insert(index)
                    }
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }

    // MARK: - Superset-Hilfsmethoden

    /// Prüft ob die Gruppe an diesem Index die erste ihrer Superset-Gruppe ist
    private func isFirstSupersetMember(at index: Int, in groups: [[ExerciseSet]]) -> Bool {
        guard let groupId = groups[index].first?.supersetGroupId else { return false }
        // Die erste Gruppe mit dieser ID vor diesem Index?
        return !groups[0..<index].contains { $0.first?.supersetGroupId == groupId }
    }

    /// Prüft ob die Gruppe an diesem Index die letzte ihrer Superset-Gruppe ist
    private func isLastSupersetMember(at index: Int, in groups: [[ExerciseSet]]) -> Bool {
        guard let groupId = groups[index].first?.supersetGroupId else { return false }
        return !groups[(index + 1)...].contains { $0.first?.supersetGroupId == groupId }
    }

    /// Gibt den Abstand nach einem bestimmten Index zurück
    private func spacingAfter(index: Int, in groups: [[ExerciseSet]]) -> CGFloat {
        guard index < groups.count - 1 else { return 0 }

        let currentGroupId = groups[index].first?.supersetGroupId
        let nextGroupId = groups[index + 1].first?.supersetGroupId

        // Kleiner Abstand innerhalb eines Supersets
        if let currentId = currentGroupId,
           let nextId = nextGroupId,
           currentId == nextId {
            return supersetSpacing
        }
        return cardSpacing
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
        let groups = plan.groupedTemplateSets
        for i in 0..<index {
            position += (cardHeights[i] ?? averageCardHeight) + spacingAfter(index: i, in: groups)
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
        let groups = plan.groupedTemplateSets
        for i in 0..<index {
            y += (cardHeights[i] ?? averageCardHeight) + spacingAfter(index: i, in: groups)
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
    let onRemoveFromSuperset: (() -> Void)?

    @State private var hasStartedDrag = false

    private var isInSuperset: Bool {
        sets.first?.supersetGroupId != nil
    }

    var body: some View {
        TemplateSetCard(
            exerciseName: exerciseName,
            mediaAssetName: mediaAssetName,
            sets: sets,
            onDelete: onDelete,
            onEdit: onEdit,
            showsEditMenu: !isEditing,
            onSupersetToggle: onRemoveFromSuperset
        ) {
            if isEditing {
                // Superset-Mitglieder: kein Drag-Handle (werden als Block dargestellt)
                if isInSuperset {
                    Image(systemName: "link")
                        .font(.title3)
                        .foregroundStyle(.blue.opacity(0.5))
                        .frame(width: 36, height: 36)
                } else {
                    dragHandle
                }
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
    var isInSuperset: Bool = false

    private var workingSets: [ExerciseSet] {
        sets.filter { $0.setKind == .work }
    }

    private var warmupSets: [ExerciseSet] {
        sets.filter { $0.setKind == .warmup }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
            if isInSuperset {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
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
