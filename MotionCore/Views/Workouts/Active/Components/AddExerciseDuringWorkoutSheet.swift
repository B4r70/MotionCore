//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts / Components                                     /
// Datei . . . . : AddExerciseDuringWorkoutSheet.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.05.2026                                                       /
// Beschreibung  : Sheet zum Hinzufügen einer Übung während eines laufenden         /
//                 Trainings. Schritt 1: Übung wählen, Schritt 2: Konfigurieren.   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct AddExerciseDuringWorkoutSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: StrengthSession
    let onComplete: () -> Void

        // Schritt 1: Übung wählen, Schritt 2: Sets konfigurieren
    @State private var selectedExercise: Exercise?
    @State private var numberOfSets: Int = 3
    @State private var defaultWeight: Double = 0.0
    @State private var defaultReps: Int = 10
    @State private var restSeconds: Int = 90

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.surfaceApp.ignoresSafeArea()

                if let exercise = selectedExercise {
                        // Schritt 2: Sets konfigurieren
                    configureExerciseView(exercise)
                } else {
                        // Schritt 1: Übung wählen
                    exerciseSelectionView
                }
            }
            .navigationTitle(selectedExercise == nil ? "Übung hinzufügen" : "Konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if selectedExercise != nil {
                                // Zurück zur Auswahl
                            withAnimation {
                                selectedExercise = nil
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        if selectedExercise != nil {
                            Label("Zurück", systemImage: "chevron.left")
                        } else {
                            Text("Abbrechen")
                        }
                    }
                }
            }
            .onDisappear {
                    // Timer aufräumen beim Schließen
                stopContinuousAdjustment()
            }
        }
    }

        // MARK: - Schritt 1: Übung wählen (delegiert an ExercisePickerView)

    private var exerciseSelectionView: some View {
        ExercisePickerView { exercise in
            withAnimation {
                selectedExercise = exercise
                defaultReps = exercise.repRangeMax > 0 ? exercise.repRangeMax : 10
            }
        }
    }

        // MARK: - Schritt 2: Sets konfigurieren

    private func configureExerciseView(_ exercise: Exercise) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                    // Übungsinfo
                exerciseInfoCard(exercise)

                    // Set-Konfiguration
                setConfigurationCard

                    // Hinzufügen-Button
                addButton(exercise)
            }
            .padding()
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private func exerciseInfoCard(_ exercise: Exercise) -> some View {
        HStack(spacing: 16) {
                // Anzeige Exercise Video View
            ExerciseVideoView.forExercise(
                exercise,
                size: 80
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 8) {
                    Label(exercise.equipment.description, systemImage: exercise.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)

                    if let primaryMuscle = exercise.primaryMuscles.first {
                        Text(primaryMuscle.description)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentSoft)
                            .foregroundStyle(Theme.accent)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .card()
    }

    private var setConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set-Konfiguration")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

                Divider()

                // Anzahl Sets
            HStack {
                Text("Anzahl Sets")
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    Button { decreaseSets() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(numberOfSets > 1 ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(numberOfSets <= 1)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .sets, increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    Text("\(numberOfSets)")
                        .font(.title2.bold().monospacedDigit())
                        .frame(minWidth: 40)
                        .contentTransition(.numericText())

                    Button { increaseSets() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(numberOfSets < 10 ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(numberOfSets >= 10)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .sets, increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }
            }

            Divider()

                // Gewicht mit +/- Buttons und LongPress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(isSelectedExerciseUnilateral ? "Gewicht pro Seite (kg)" : "Gewicht (kg)")
                        .foregroundStyle(Theme.textPrimary)

                    if isSelectedExerciseUnilateral {
                        Text("2×")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.warning.opacity(0.2))
                            .foregroundStyle(Theme.warning)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Button { decreaseWeight() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(defaultWeight > 0 ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(defaultWeight <= 0)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .weight, increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    Spacer()

                    if isSelectedExerciseUnilateral && defaultWeight > 0 {
                        HStack(spacing: 4) {
                            Text("2×")
                                .font(.title3)
                                .foregroundStyle(Theme.warning)
                            Text(String(format: "%.2f", defaultWeight))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                        .contentTransition(.numericText())
                    } else {
                        Text(defaultWeight > 0 ? String(format: "%.2f", defaultWeight) : "–")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    Button { increaseWeight() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.accent)
                    }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .weight, increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }

                if isSelectedExerciseUnilateral {
                    if defaultWeight > 0 {
                        Text("Gesamt: \(String(format: "%.2f", defaultWeight * 2)) kg")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("Gewicht einer Seite eingeben")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    Text("0 = Körpergewicht")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Divider()

                // Wiederholungen
            HStack {
                Text("Wiederholungen")
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    Button { decreaseReps() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(defaultReps > 1 ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(defaultReps <= 1)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .reps, increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    Text("\(defaultReps)")
                        .font(.title2.bold().monospacedDigit())
                        .frame(minWidth: 40)
                        .contentTransition(.numericText())

                    Button { increaseReps() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(defaultReps < 50 ? Theme.accent : Theme.textTertiary)
                    }
                    .disabled(defaultReps >= 50)
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startContinuousAdjustment(field: .reps, increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }
            }

            Divider()

                // Pausenzeit
            HStack {
                Text("Pause (Sek.)")
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Picker("", selection: $restSeconds) {
                    ForEach([30, 45, 60, 90, 120, 150, 180], id: \.self) { seconds in
                        Text("\(seconds)s").tag(seconds)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .card()
    }

        // MARK: - Hilfsvariable für unilateral

    private var isSelectedExerciseUnilateral: Bool {
        selectedExercise?.isUnilateral ?? false
    }

        // MARK: - Adjustment Timer für LongPress

    @State private var incrementTimer: Timer?

    private enum AdjustmentField { case sets, reps, weight }

    private func increaseSets() {
        guard numberOfSets < 10 else { return }
        withAnimation { numberOfSets += 1 }
        hapticFeedback()
    }

    private func decreaseSets() {
        guard numberOfSets > 1 else { return }
        withAnimation { numberOfSets -= 1 }
        hapticFeedback()
    }

    private func increaseReps() {
        guard defaultReps < 50 else { return }
        withAnimation { defaultReps += 1 }
        hapticFeedback()
    }

    private func decreaseReps() {
        guard defaultReps > 1 else { return }
        withAnimation { defaultReps -= 1 }
        hapticFeedback()
    }

    private func increaseWeight() {
        withAnimation {
            defaultWeight += 0.25
            defaultWeight = (defaultWeight * 4).rounded() / 4
        }
        hapticFeedback()
    }

    private func decreaseWeight() {
        guard defaultWeight >= 0.25 else { return }
        withAnimation {
            defaultWeight -= 0.25
            defaultWeight = (defaultWeight * 4).rounded() / 4
        }
        hapticFeedback()
    }

    private func startContinuousAdjustment(field: AdjustmentField, increment: Bool) {
        stopContinuousAdjustment()

        var counter = 0
        incrementTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            counter += 1
            switch field {
                case .sets:
                    if increment { increaseSets() } else { decreaseSets() }
                case .reps:
                    if increment { increaseReps() } else { decreaseReps() }
                case .weight:
                        // Nach 20 Iterationen schneller (0.5 statt 0.25)
                    let step: Double = counter > 20 ? 0.5 : 0.25
                    if increment {
                        withAnimation {
                            defaultWeight += step
                            defaultWeight = (defaultWeight * 4).rounded() / 4
                        }
                    } else if defaultWeight >= step {
                        withAnimation {
                            defaultWeight -= step
                            defaultWeight = (defaultWeight * 4).rounded() / 4
                        }
                    }
                    hapticFeedback()
            }
        }

        if let t = incrementTimer {
            RunLoop.current.add(t, forMode: .common)
        }
    }

    private func stopContinuousAdjustment() {
        incrementTimer?.invalidate()
        incrementTimer = nil
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func addButton(_ exercise: Exercise) -> some View {
        Button {
            addExerciseToSession(exercise)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("\(numberOfSets) \(numberOfSets == 1 ? "Set" : "Sets") hinzufügen")
                    .font(.headline)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Radius.lg))
        }
    }

        // MARK: - Logik zum Hinzufügen

    private func addExerciseToSession(_ exercise: Exercise) {
            // Höchsten sortOrder in der Session finden
        let maxSortOrder = session.safeExerciseSets.map { $0.sortOrder }.max() ?? -1
        let newSortOrder = maxSortOrder + 1

            // Gewicht berechnen (bei unilateral: Gesamtgewicht = 2 × Eingabe)
        let isUnilateral = exercise.isUnilateral
        let finalWeight = isUnilateral ? defaultWeight * 2 : defaultWeight

            // Sets erstellen
        for setNumber in 1...numberOfSets {
            let newSet = ExerciseSet(
                exerciseName: exercise.name,
                exerciseNameSnapshot: exercise.name,
                exerciseUUIDSnapshot: exercise.apiID?.uuidString.lowercased() ?? "",
                exerciseMediaAssetName: exercise.mediaAssetName,
                isUnilateralSnapshot: exercise.isUnilateral,
                setNumber: setNumber,
                weight: finalWeight,
                weightPerSide: isUnilateral ? defaultWeight : 0,
                reps: defaultReps,
                restSeconds: restSeconds,
                setKind: .work,
                isCompleted: false, // Nicht abgeschlossen, da während des Trainings
                targetRepsMin: exercise.repRangeMin,
                targetRepsMax: exercise.repRangeMax,
                sortOrder: newSortOrder
            )

            newSet.exercise = exercise
            session.addSet(newSet)      // setzt session + hängt an optional array korrekt an
            context.insert(newSet)
        }

        try? context.save()

            // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

            // Callback ausführen (Live Activity updaten etc.)
        onComplete()
    }
}
