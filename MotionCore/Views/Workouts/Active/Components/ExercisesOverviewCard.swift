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
    let selectedExerciseKey: String?
    let prSetIDs: Set<PersistentIdentifier>

    let onAddExercise: () -> Void
    let onSelectExercise: (String) -> Void
    let onDeleteExercise: (String) -> Void
    let onReorderExercise: (Int, Int) -> Void
    var onRetroRIR: ((ExerciseSet) -> Void)? = nil
    var onRemoveFromSuperset: ((Int) -> Void)? = nil

    // Superset-Selection-State als Bindings (State liegt in ActiveWorkoutView)
    @Binding var isSupersetSelectionMode: Bool
    @Binding var selectedGroupIndicesForSuperset: Set<Int>

        // Sortiermodus-State
    @State private var isSortMode: Bool = false

        // Expand-State für Accordion-Verhalten
    @State private var expandedExerciseKey: String? = nil

        // Drag & Drop State
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardHeights: [Int: CGFloat] = [:]
    @State private var lastTargetIndex: Int? = nil

    private var averageCardHeight: CGFloat {
        guard !cardHeights.isEmpty else { return 60 }
        return cardHeights.values.reduce(0, +) / CGFloat(cardHeights.count)
    }

    private var completedGroupCount: Int {
        groupedSets.filter { sets in sets.allSatisfy { $0.isCompleted } }.count
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

    // MARK: - Superset-Selection-Helpers

    private var supersetHelper: SupersetSelectionHelper {
        SupersetSelectionHelper(groupedSets: groupedSets)
    }

    private func isEligibleForSuperset(at index: Int) -> Bool {
        supersetHelper.isEligible(at: index)
    }

    private func isInOtherSuperset(at index: Int) -> Bool {
        supersetHelper.isInOtherSuperset(at: index)
    }

    private var eligibleExerciseCount: Int {
        supersetHelper.eligibleCount
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
                                isSupersetMember: isSupersetMember(at: index),
                                isExpanded: expandedExerciseKey == sets.first?.groupKey,
                                isSupersetSelectionMode: isSupersetSelectionMode,
                                isSelectedForSuperset: selectedGroupIndicesForSuperset.contains(index),
                                isEligibleForSuperset: isEligibleForSuperset(at: index),
                                isInOtherSuperset: isInOtherSuperset(at: index),
                                onToggleExpand: {
                                    guard let key = sets.first?.groupKey else { return }
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        expandedExerciseKey = (expandedExerciseKey == key) ? nil : key
                                    }
                                },
                                onSelectAsActive: {
                                    guard let key = sets.first?.groupKey else { return }
                                    onSelectExercise(key)
                                },
                                onToggleSupersetSelection: {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                        if selectedGroupIndicesForSuperset.contains(index) {
                                            selectedGroupIndicesForSuperset.remove(index)
                                        } else {
                                            selectedGroupIndicesForSuperset.insert(index)
                                        }
                                    }
                                },
                                onRemoveFromSuperset: {
                                    onRemoveFromSuperset?(index)
                                },
                                onRetroRIR: onRetroRIR
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
                                            .foregroundStyle(Theme.success.opacity(0.5))
                                            .frame(width: 36, height: 36)
                                            .padding(.trailing, 4)
                                    } else {
                                        dragHandleView(index: index)
                                    }
                                }
                            }
                                // LongPress zum Löschen (nur außerhalb des Sortier- und Selection-Modus)
                            .onLongPressGesture(minimumDuration: 0.5) {
                                guard !isSortMode, !isSupersetSelectionMode else { return }
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
                        isSupersetMember: false,
                        isExpanded: false,
                        isSupersetSelectionMode: false,
                        isSelectedForSuperset: false,
                        isEligibleForSuperset: false,
                        isInOtherSuperset: false,
                        onToggleExpand: {},
                        onSelectAsActive: {},
                        onToggleSupersetSelection: {},
                        onRemoveFromSuperset: {}
                    )
                    .overlay(alignment: .trailing) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
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
        .card()
        .onAppear {
            if expandedExerciseKey == nil {
                expandedExerciseKey = selectedExerciseKey ?? groupedSets.first?.first?.groupKey
            }
        }
        // groupedSets kommt nach onAppear — Expand nachholen wenn Cache spät ankommt
        .onChange(of: groupedSets.first?.first?.groupKey) { _, newKey in
            if expandedExerciseKey == nil {
                expandedExerciseKey = selectedExerciseKey ?? newKey
            }
        }
        .onChange(of: selectedExerciseKey) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedExerciseKey = newValue
            }
        }
        .onChange(of: isSortMode) { _, newValue in
            if !newValue {
                draggingIndex = nil
                dragOffset = .zero
                lastTargetIndex = nil
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedExerciseKey = nil
                }
                // Sort-Modus beendet Selection-Modus (Mutex)
                isSupersetSelectionMode = false
            }
        }
        .onChange(of: isSupersetSelectionMode) { _, newValue in
            if newValue {
                // Selection-Modus beendet Sort-Modus (Mutex)
                isSortMode = false
            } else {
                selectedGroupIndicesForSuperset = []
            }
        }
    }

        // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Übungen")
                    .font(AppFont.title)
                    .tracking(-0.5)
                    .foregroundStyle(Theme.textPrimary)

                Text("\(completedGroupCount) von \(groupedSets.count) erledigt")
                    .font(AppFont.eyebrow)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            HStack(spacing: 12) {
                    // "(+) Übung"-Button: nur im Nicht-Sortier- und Nicht-Selection-Modus
                if !isSortMode && !isSupersetSelectionMode {
                    Button {
                        onAddExercise()
                    } label: {
                        Label("Übung", systemImage: "plus.circle.fill")
                            .font(AppFont.body.weight(.medium))
                            .foregroundStyle(Theme.accent)
                    }
                }

                    // Bolt-Button: Superset-Selection-Modus ein-/ausschalten
                if !isSortMode {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isSupersetSelectionMode.toggle()
                        }
                    } label: {
                        Image(systemName: "bolt")
                            .font(AppFont.headline)
                            .foregroundStyle(Theme.accent)
                    }
                    .opacity(eligibleExerciseCount >= 2 ? 1.0 : 0.4)
                    .disabled(eligibleExerciseCount < 2)
                }

                    // Sortier- / Fertig-Button: nicht im Selection-Modus
                if !isSupersetSelectionMode {
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
                        .font(AppFont.title)
                        .foregroundStyle(isSortMode ? Theme.success : Theme.accent)
                        .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
        }
    }

        // MARK: - Drag Handle

    @ViewBuilder
    private func dragHandleView(index: Int) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 15))
            .foregroundStyle(Theme.textSecondary)
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

    // MARK: - Exercise Overview Expanded Detail

private struct ExerciseOverviewExpandedDetail: View {
    let sets: [ExerciseSet]
    var onRetroRIR: ((ExerciseSet) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.lineSoft)
                .padding(.bottom, 8)

            if sets.isEmpty {
                Text("Keine Sätze konfiguriert")
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(sets, id: \.persistentModelID) { set in
                        setDetailRow(set: set)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func setDetailRow(set: ExerciseSet) -> some View {
        HStack {
            Text("Satz \(set.setNumber)")
                .font(AppFont.callout)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text(formatSetValue(set))
                .font(AppFont.callout)
                .foregroundStyle(set.isCompleted ? Theme.textPrimary : Theme.textSecondary)

            if set.isLastSetOfExercise && !set.rpeRecorded, let callback = onRetroRIR {
                Button {
                    callback(set)
                } label: {
                    Image(systemName: "pencil.and.outline")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }

            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle.dashed")
                .font(AppFont.callout)
                .foregroundStyle(set.isCompleted ? Theme.success : Theme.textTertiary)
                .padding(.leading, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatSetValue(_ set: ExerciseSet) -> String {
        // Zeitbasierte Sätze: Dauer in mm:ss statt Gewicht × Wiederholungen
        if set.isTimeBased {
            return formatDuration(set.duration)
        }
        let weightStr: String
        if set.weight == set.weight.rounded() {
            weightStr = String(format: "%.0f", set.weight)
        } else {
            weightStr = String(format: "%.1f", set.weight)
        }
        return "\(weightStr) kg × \(set.reps) Wdh."
    }

    /// Formatiert Sekunden als „m:ss Min" (z. B. 300 → „5:00 Min", 75 → „1:15 Min")
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m):00 Min" : String(format: "%d:%02d Min", m, s)
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
    let isExpanded: Bool
    // Superset-Selection-Parameter
    let isSupersetSelectionMode: Bool
    let isSelectedForSuperset: Bool
    let isEligibleForSuperset: Bool
    let isInOtherSuperset: Bool
    let onToggleExpand: () -> Void
    let onSelectAsActive: () -> Void
    let onToggleSupersetSelection: () -> Void
    let onRemoveFromSuperset: () -> Void
    var onRetroRIR: ((ExerciseSet) -> Void)? = nil

    private var completedCount: Int { sets.filter { $0.isCompleted }.count }
    private var isAllCompleted: Bool { completedCount == sets.count }

    var body: some View {
        HStack(spacing: 0) {
                // Vertikale Superset-Linie links
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.success.opacity(0.6))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .opacity(hasSupersetAbove ? 1 : 0)

                if hasSupersetAbove || hasSupersetBelow {
                    Image(systemName: "link")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.success)
                        .padding(.vertical, 2)
                }

                Rectangle()
                    .fill(Theme.success.opacity(0.6))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .opacity(hasSupersetBelow ? 1 : 0)
            }
            .frame(width: 12)

                // Inhalt
            VStack(spacing: 8) {
                topLine
                dotsLine
                if isExpanded && !isSupersetSelectionMode {
                    ExerciseOverviewExpandedDetail(sets: sets, onRetroRIR: onRetroRIR)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
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
        // Akzent-Border wenn im Selection-Modus ausgewählt
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSupersetSelectionMode && isSelectedForSuperset ? Theme.accent : Color.clear,
                    lineWidth: 2
                )
        )
        // Overlays: Checkmark / Schloss / Link-Icon
        .overlay(alignment: .topTrailing) {
            if isSupersetSelectionMode {
                if isSelectedForSuperset {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white)
                        .background(Theme.accent, in: Circle())
                        .padding(6)
                } else if isInOtherSuperset {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.white)
                        .background(Theme.success.opacity(0.6), in: Circle())
                        .padding(6)
                } else if !isEligibleForSuperset {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(8)
                }
            }
        }
        // Transparenz für nicht-eligble Übungen im Selection-Modus
        .opacity(isSupersetSelectionMode && !isEligibleForSuperset && !isInOtherSuperset ? 0.5 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSupersetSelectionMode {
                // Im Selection-Modus: Auswahl toggle, nur wenn eligible und nicht in anderem Superset
                guard isEligibleForSuperset, !isInOtherSuperset else {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    return
                }
                onToggleSupersetSelection()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                guard !isSortMode else { return }
                onToggleExpand()
            }
        }
        // Kontextmenü unconditional — Inhalt conditional (verhindert HStack-Kollaps)
        .contextMenu {
            if isSupersetMember && !isSupersetSelectionMode {
                Button("Aus Superset entfernen", systemImage: "link.badge.minus") {
                    onRemoveFromSuperset()
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }

    private var topLine: some View {
        HStack {
            Text("\(index). \(name)")
                .font(AppFont.body.bold())
                .foregroundStyle(isCurrentExercise ? Theme.accent : Theme.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                if hasPR {
                    Image(systemName: "crown.fill")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.warning)
                }
                if isAllCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                } else {
                    Text("\(completedCount)/\(sets.count)")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textPrimary)
                }

                if !isCurrentExercise && !isSortMode && !isSupersetSelectionMode {
                    Button {
                        onSelectAsActive()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(AppFont.headline)
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                }

                Image(systemName: "chevron.down")
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .opacity(isSortMode ? 0 : 1)
                    .padding(.leading, 4)
            }
        }
    }

    private var dotsLine: some View {
        HStack(spacing: 6) {
            ForEach(sets, id: \.persistentModelID) { set in
                Circle()
                    .fill(set.isCompleted ? Theme.success : Theme.surfaceSunken)
                    .frame(width: 12, height: 12)
                    .overlay {
                        if set.setKind == .warmup {
                            Circle()
                                .stroke(Theme.warning, lineWidth: 2) // Warmup-Indikator (amber)
                        }
                    }
            }
            Spacer()
        }
    }

    private var backgroundColor: Color {
        if isPressed {
            return Theme.danger.opacity(0.15)
        } else if isCurrentExercise {
            return Theme.accentSoft
        } else {
            return Color.clear
        }
    }
}
