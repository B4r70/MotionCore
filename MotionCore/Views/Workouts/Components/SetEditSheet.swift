//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : SetEditSheet.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 01.01.2026                                                       /
// Beschreibung  : Edit-Sheet für die Anpassung des Trainings innerhalb der View    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData
import UIKit

// MARK: - Set Edit Sheet

struct SetEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appSettings: AppSettings

    @Query private var studioEquipments: [StudioEquipment]

    @Bindable var set: ExerciseSet
    @Bindable var session: StrengthSession

    @State private var weight: Double
    @State private var reps: Int
    @State private var setCount: Int
    @State private var restSeconds: Int
    @State private var incrementTimer: Timer?

    init(set: ExerciseSet, session: StrengthSession) {
        self.set = set
        self.session = session
        _weight = State(initialValue: set.weight)
        _reps = State(initialValue: set.reps)
        _restSeconds = State(initialValue: set.restSeconds)
        let sameSets = session.safeExerciseSets.filter { $0.exerciseName == set.exerciseName }
        _setCount = State(initialValue: sameSets.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.surfaceApp.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        exerciseInfoCard
                        weightCard
                        repsCard
                        setCountCard
                        VStack(alignment: .leading, spacing: 0) {
                            SetRestTimeSection(restSeconds: $restSeconds)
                        }
                        .card()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Satz anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { saveChanges(); dismiss() } label: { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
                }
            }
            .onDisappear { stopTimer() }
            .calmSheet([.medium, .large])
        }
    }

    // MARK: - Subviews

    private var exerciseInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ExerciseVideoView.forSet(set, size: 60)
                VStack(alignment: .leading) {
                    Text(set.exerciseName).font(AppFont.headline).foregroundStyle(Theme.textPrimary)
                    Text("Satz \(set.setNumber)").font(AppFont.callout).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            // CautionNote aus verknüpfter Übung
            if let note = set.exercise?.cautionNote, !note.isEmpty {
                HStack(alignment: .top, spacing: Space.s2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.warning).font(AppFont.callout)
                    Text(note).font(AppFont.callout).foregroundStyle(Theme.warning)
                }
                .padding(.horizontal, Space.s3).padding(.vertical, Space.s2)
                .background(Theme.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
        .card()
    }

    private var weightCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(set.isUnilateralSnapshot ? "Gewicht pro Seite (kg)" : "Gewicht (kg)")
                    .font(AppFont.headline).foregroundStyle(Theme.textPrimary)
                if set.isUnilateralSnapshot {
                    Badge(text: "2×", style: .soft, color: Theme.warning)
                }
                Spacer()
            }
            HStack {
                makeStepButton(systemName: "minus.circle.fill") { adjustWeight(by: -0.25) }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { p in
                        if p { startAutoRepeat(interval: 0.12) { adjustWeight(by: -0.25) } } else { stopTimer() }
                    }, perform: {})

                // Bilateral-Anzeige bei unilateralen Übungen
                if set.isUnilateralSnapshot && weight > 0 {
                    HStack(spacing: Space.s1) {
                        Text("2 ×").font(AppFont.title).foregroundStyle(Theme.warning)
                        Text(String(format: "%.2f", weight / 2))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(width: 250).contentTransition(.numericText())
                } else {
                    Text(String(format: "%.2f", weight))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 250).contentTransition(.numericText())
                }

                makeStepButton(systemName: "plus.circle.fill") { adjustWeight(by: 0.25) }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { p in
                        if p { startAutoRepeat(interval: 0.12) { adjustWeight(by: 0.25) } } else { stopTimer() }
                    }, perform: {})
            }
            if set.isUnilateralSnapshot && weight > 0 {
                Text("Gesamt: \(String(format: "%.2f", weight)) kg (beide Seiten)")
                    .font(AppFont.callout).foregroundStyle(Theme.textSecondary)
            }

            // Feintuning-Chips: nur sichtbar wenn Equipment mit intermediateIncrements verknüpft
            if let equipment = studioEquipment, !equipment.intermediateIncrements.isEmpty {
                FineTuneChipsView(increments: equipment.intermediateIncrements) { delta in
                    adjustWeight(by: delta)
                }
                .padding(.top, 4)
            }
        }
        .card()
    }

    private var repsCard: some View {
        VStack(spacing: 12) {
            Text("Wiederholungen").font(AppFont.headline).foregroundStyle(Theme.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                makeStepButton(systemName: "minus.circle.fill", disabled: reps <= 1) {
                    if reps > 1 { reps -= 1; haptic() }
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.35)
                    .onEnded { _ in startAutoRepeat(interval: 0.15) { if reps > 1 { reps -= 1; haptic() } } })
                .onLongPressGesture(minimumDuration: 0.35, pressing: { p in if !p { stopTimer() } }, perform: {})

                Text("\(reps)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 250).contentTransition(.numericText())

                makeStepButton(systemName: "plus.circle.fill") { reps += 1; haptic() }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.35)
                        .onEnded { _ in startAutoRepeat(interval: 0.15) { reps += 1; haptic() } })
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { p in if !p { stopTimer() } }, perform: {})
            }
        }
        .card()
    }

    private var setCountCard: some View {
        VStack(spacing: 12) {
            Text("Anzahl Sätze").font(AppFont.headline).foregroundStyle(Theme.textPrimary).frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                // 0.3s Intervall schützt SwiftData vor zu schnellen Writes
                makeStepButton(systemName: "minus.circle.fill", disabled: setCount <= 1) {
                    if setCount > 1 { setCount -= 1; handleSetCountChange() }
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.35)
                    .onEnded { _ in startAutoRepeat(interval: 0.3) {
                        if setCount > 1 { setCount -= 1; handleSetCountChange() } } })
                .onLongPressGesture(minimumDuration: 0.35, pressing: { p in if !p { stopTimer() } }, perform: {})

                Text("\(setCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 250).contentTransition(.numericText())

                makeStepButton(systemName: "plus.circle.fill") { setCount += 1; handleSetCountChange() }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.35)
                        .onEnded { _ in startAutoRepeat(interval: 0.3) { setCount += 1; handleSetCountChange() } })
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { p in if !p { stopTimer() } }, perform: {})
            }
            Text("für \(set.exerciseName)").font(AppFont.callout).foregroundStyle(Theme.textSecondary)
        }
        .card()
    }

    // Gibt das verknüpfte StudioEquipment zurück, falls die Übung eines referenziert
    private var studioEquipment: StudioEquipment? {
        guard let id = set.exercise?.studioEquipmentID else { return nil }
        return studioEquipments.first { $0.id == id }
    }

    // Wiederverwendbarer Step-Button mit optionalem Disabled-State
    @ViewBuilder
    private func makeStepButton(
        systemName: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title)
                .foregroundStyle(disabled ? Theme.textTertiary : Theme.accent)
        }
        .disabled(disabled)
    }

    // MARK: - Speichern mit Übernahme für nachfolgende Sets

    private func saveChanges() {
        set.weight = weight
        set.reps = reps
        set.restSeconds = restSeconds

        // weightPerSide bei unilateralen Übungen mitschreiben
        if set.isUnilateralSnapshot && weight > 0 {
            set.weightPerSide = weight / 2
        }

        let sameSets = session.safeExerciseSets.filter { $0.exerciseName == set.exerciseName }
        for otherSet in sameSets where otherSet.setNumber > set.setNumber && !otherSet.isCompleted {
            otherSet.weight = weight
            otherSet.reps = reps
            otherSet.restSeconds = restSeconds
            if set.isUnilateralSnapshot && weight > 0 { otherSet.weightPerSide = weight / 2 }
        }

        try? context.save()
    }

    // MARK: - Set Management

    private func handleSetCountChange() {
        let currentCount = session.safeExerciseSets.filter { $0.exerciseName == set.exerciseName }.count
        let difference = setCount - currentCount
        if difference > 0 { for _ in 0..<difference { addSet() } }
        else if difference < 0 { for _ in 0..<abs(difference) { removeLastSet() } }
        renumberSetsForExercise()
        try? context.save()
        haptic()
    }

    private func addSet() {
        let sameSets = session.safeExerciseSets.filter { $0.exerciseName == set.exerciseName }
        let nextSetNumber = (sameSets.map { $0.setNumber }.max() ?? 0) + 1
        let newSet = ExerciseSet(
            exerciseName: set.exerciseName, exerciseNameSnapshot: set.exerciseNameSnapshot,
            exerciseUUIDSnapshot: set.exerciseUUIDSnapshot, exerciseMediaAssetName: set.exerciseMediaAssetName,
            isUnilateralSnapshot: set.isUnilateralSnapshot, setNumber: nextSetNumber,
            weight: set.weight, weightPerSide: set.weightPerSide, reps: set.reps,
            duration: set.duration, distance: set.distance, restSeconds: set.restSeconds,
            setKind: .work, trackingMode: set.trackingMode,
            isCompleted: false, rpe: 0, notes: "",
            targetRepsMin: set.targetRepsMin, targetRepsMax: set.targetRepsMax,
            targetRIR: set.targetRIR, groupId: set.groupId, sortOrder: set.sortOrder
        )
        newSet.exercise = set.exercise
        session.addSet(newSet)
        context.insert(newSet)
    }

    private func removeLastSet() {
        let sameSets = session.safeExerciseSets.filter { $0.exerciseName == set.exerciseName }
        guard sameSets.count > 1 else { return }
        let candidate = sameSets.filter { !$0.isCompleted }.sorted { $0.setNumber < $1.setNumber }.last
            ?? sameSets.sorted { $0.setNumber < $1.setNumber }.last
        guard let toDelete = candidate else { return }
        session.removeSet(toDelete)
        context.delete(toDelete)
    }

    private func renumberSetsForExercise() {
        let sets = session.safeExerciseSets
            .filter { $0.exerciseName == set.exerciseName }
            .sorted { $0.setNumber < $1.setNumber }
        for (idx, s) in sets.enumerated() { s.setNumber = idx + 1 }
    }

    // MARK: - Timer-Hilfsfunktionen

    private func adjustWeight(by delta: Double) {
        let newWeight = weight + delta
        guard newWeight >= 0 else { return }
        weight = (newWeight * 4).rounded() / 4
        haptic()
    }

    private func startAutoRepeat(interval: TimeInterval, action: @escaping () -> Void) {
        stopTimer()
        incrementTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in action() }
        if let t = incrementTimer { RunLoop.current.add(t, forMode: .common) }
    }

    private func stopTimer() {
        incrementTimer?.invalidate()
        incrementTimer = nil
    }

    private func haptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
