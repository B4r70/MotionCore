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

    @State private var isEditing = false

    // Multi-Select-Modus fuer Superset-Erstellung
    @State private var isSupersetSelectionMode: Bool = false
    @State private var selectedGroupIndicesForSuperset: Set<Int> = []

    // Drag & Drop State
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardHeights: [Int: CGFloat] = [:]
    @State private var lastTargetIndex: Int? = nil

    private var averageCardHeight: CGFloat {
        guard !cardHeights.isEmpty else { return 72 }
        return cardHeights.values.reduce(0, +) / CGFloat(cardHeights.count)
    }

    private let cardSpacing: CGFloat = 12
    private let supersetSpacing: CGFloat = 4

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
        .onChange(of: isEditing) { _, newValue in
            if newValue { isSupersetSelectionMode = false }
            if !newValue {
                draggingIndex = nil
                dragOffset = .zero
                lastTargetIndex = nil
            }
        }
        .onChange(of: isSupersetSelectionMode) { _, newValue in
            if newValue { isEditing = false }
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
                    // Superset-Auswahl-Button (nur wenn nicht im Sortier-Modus)
                    if !plan.safeTemplateSets.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSupersetSelectionMode = true
                                selectedGroupIndicesForSuperset = []
                            }
                        } label: {
                            Image(systemName: "bolt")
                                .font(.title2)
                                .foregroundStyle(Color.blue)
                        }
                        .opacity(isEditing ? 0 : 1)
                        .scaleEffect(isEditing ? 0.5 : 1)
                    }

                    // Hinzufügen-Button (nur wenn nicht im Sortier-Modus)
                    if let onAdd = onAddExercise {
                        Button { onAdd() } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.blue)
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
                            .foregroundStyle(isEditing ? Color.green : .blue)
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
                            .foregroundStyle(Color.blue)
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
                        .foregroundStyle(Color.white)
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
                        .foregroundStyle(Color.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .card()
        .padding(.horizontal)
    }

    // MARK: - Uebungsliste

    @ViewBuilder
    private var exercisesList: some View {
        switch mode {
        case .form:
            formExercisesList
                .padding(.horizontal)

        case .detail:
            VStack(spacing: 12) {
                ForEach(
                    Array(plan.groupedTemplateSets.enumerated()),
                    id: \.element.first?.persistentModelID
                ) { index, setsGroup in
                    if let firstSet = setsGroup.first {
                        ExerciseDetailRow(
                            exerciseName: firstSet.exerciseNameSnapshot,
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

    // MARK: - Form-Modus Drag & Drop Liste

    private var formExercisesList: some View {
        ZStack(alignment: .top) {
            // Hintergrund-Cards (verschieben sich beim Drag)
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
                                        .foregroundStyle(Color.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.12), in: Capsule())
                                    Spacer()
                                }
                                .padding(.bottom, 4)
                                .padding(.top, index == 0 ? 0 : 4)
                            }

                            // Die eigentliche Card mit allen Overlays
                            exerciseCard(
                                setsGroup: setsGroup,
                                firstSet: firstSet,
                                index: index,
                                isInSuperset: isInSuperset,
                                isLastInGroup: isLastInGroup
                            )
                        }
                        .padding(.bottom, spacingAfter(index: index, in: groups))
                    }
                }
            }

            // Schwebende Card während Drag
            if let dragIndex = draggingIndex,
               let setsGroup = plan.groupedTemplateSets[safe: dragIndex],
               let firstSet = setsGroup.first {

                let yPosition = calculateFloatingCardPosition(for: dragIndex)

                TemplateSetCard(
                    exerciseName: firstSet.exerciseNameSnapshot,
                    mediaAssetName: firstSet.exerciseMediaAssetName,
                    sets: setsGroup,
                    onDelete: {},
                    onEdit: {},
                    showsEditMenu: false
                ) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                }
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
                .scaleEffect(1.02)
                .offset(y: yPosition + dragOffset.height)
                .zIndex(1000)
            }
        }
    }

    // MARK: - Einzelne Card mit Superset-Overlays und Drag-Handle

    @ViewBuilder
    private func exerciseCard(
        setsGroup: [ExerciseSet],
        firstSet: ExerciseSet,
        index: Int,
        isInSuperset: Bool,
        isLastInGroup: Bool
    ) -> some View {
        let isSelected = selectedGroupIndicesForSuperset.contains(index)
        let alreadyInSuperset = isInSuperset && isSupersetSelectionMode
        let isFollower = isSupersetFollower(at: index)

        ZStack(alignment: .leading) {
            TemplateSetCard(
                exerciseName: firstSet.exerciseNameSnapshot,
                mediaAssetName: firstSet.exerciseMediaAssetName,
                sets: setsGroup,
                onDelete: { onDeleteExercise?(firstSet) },
                onEdit: { onEditExercise?(firstSet) },
                showsEditMenu: !isEditing,
                onSupersetToggle: isInSuperset ? {
                    plan.removeFromSuperset(groupAt: index)
                    try? modelContext.save()
                } : nil
            ) {
                if isEditing {
                    if isFollower {
                        // Superset-Folgemitglied: kein Drag (werden als Block verschoben)
                        Image(systemName: "link")
                            .font(.title3)
                            .foregroundStyle(.blue.opacity(0.5))
                            .frame(width: 36, height: 36)
                    } else {
                        dragHandleView(index: index)
                    }
                } else {
                    EmptyView()
                }
            }
            // Höhe messen für Drag-Berechnung
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { cardHeights[index] = geo.size.height }
                        .onChange(of: geo.size.height) { _, newHeight in
                            cardHeights[index] = newHeight
                        }
                }
            )
            // Ziehende Card ausblenden
            .opacity(draggingIndex == index ? 0 : 1)
            .animation(nil, value: draggingIndex)
            // Verschiebe-Animation
            .modifier(RowOffsetModifier(offset: offsetForIndex(index)))

            // Pastellgrüner Superset-Tint (nur im Normalmodus)
            .overlay(
                Group {
                    if isInSuperset && !isSupersetSelectionMode {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.08))
                            .allowsHitTesting(false)
                    }
                }
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
                    if selectedGroupIndicesForSuperset.contains(index) {
                        selectedGroupIndicesForSuperset.remove(index)
                    } else {
                        selectedGroupIndicesForSuperset.insert(index)
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    // MARK: - Drag Handle

    @ViewBuilder
    private func dragHandleView(index: Int) -> some View {
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
                            if draggingIndex == nil {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    draggingIndex = index
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            if let drag {
                                dragOffset = drag.translation
                                let target = calculateTargetIndex(from: index)
                                if target != lastTargetIndex && target != index {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                            plan.reorderExercise(from: index, to: toIndex)
                            try? modelContext.save()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }
            )
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
                    .foregroundStyle(Color.white)
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

    // MARK: - Superset-Hilfsmethoden

    /// Gibt die Anzahl der Übungen in einem Superset zurück
    private func supersetSize(for groupId: String) -> Int {
        plan.groupedTemplateSets.filter { $0.first?.supersetGroupId == groupId }.count
    }

    /// Prüft ob die Gruppe an diesem Index die erste ihrer Superset-Gruppe ist
    private func isFirstSupersetMember(at index: Int, in groups: [[ExerciseSet]]) -> Bool {
        guard let groupId = groups[index].first?.supersetGroupId else { return false }
        return !groups[0..<index].contains { $0.first?.supersetGroupId == groupId }
    }

    /// Prüft ob die Gruppe an diesem Index die letzte ihrer Superset-Gruppe ist
    private func isLastSupersetMember(at index: Int, in groups: [[ExerciseSet]]) -> Bool {
        guard let groupId = groups[index].first?.supersetGroupId else { return false }
        return !groups[(index + 1)...].contains { $0.first?.supersetGroupId == groupId }
    }

    /// Prüft ob eine Gruppe ein nachfolgendes Superset-Mitglied ist (nicht das erste)
    private func isSupersetFollower(at index: Int) -> Bool {
        guard index > 0,
              let thisID = plan.groupedTemplateSets[safe: index]?.first?.supersetGroupId,
              !thisID.isEmpty,
              let prevID = plan.groupedTemplateSets[safe: index - 1]?.first?.supersetGroupId
        else { return false }
        return thisID == prevID
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

    // MARK: - Positions-Berechnung (Drag & Drop)

    private func yStart(for index: Int) -> CGFloat {
        var y: CGFloat = 0
        let groups = plan.groupedTemplateSets
        for i in 0..<index {
            y += (cardHeights[i] ?? averageCardHeight) + spacingAfter(index: i, in: groups)
        }
        return y
    }

    private func calculateFloatingCardPosition(for index: Int) -> CGFloat {
        yStart(for: index)
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

    private func offsetForIndex(_ index: Int) -> CGFloat {
        guard let dragIndex = draggingIndex else { return 0 }
        if index == dragIndex { return 0 }

        let target = calculateTargetIndex(from: dragIndex)
        let groups = plan.groupedTemplateSets
        let draggedHeight = (cardHeights[dragIndex] ?? averageCardHeight) + spacingAfter(index: dragIndex, in: groups)

        if dragIndex < target {
            if (dragIndex + 1)...target ~= index { return -draggedHeight }
        } else if target < dragIndex {
            if target..<dragIndex ~= index { return draggedHeight }
        }

        return 0
    }
}

// MARK: - Row Offset Modifier

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
                .foregroundStyle(Color.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            if isInSuperset {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundStyle(Color.blue)
            }
            // Anzeige MP4 Übungsdurchführung — bevorzugt die verknüpfte Exercise (Remote Poster/Video)
            if let exercise = sets.first?.exercise {
                ExerciseVideoView.forExercise(exercise, size: 50)
            } else {
                ExerciseVideoView(assetName: mediaAssetName, size: 50)
            }

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
                            .foregroundStyle(Color.orange)
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
