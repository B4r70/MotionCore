//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : SetConfigurationSheet.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Sheet zum Konfigurieren der Sätze für eine Übung im Plan         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct SetConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    let exercise: Exercise
    let onSave: ([ExerciseSet]) -> Void

    // Nur noch initialSets (kein initialWeight mehr)
    let initialSets: [ExerciseSet]?

    init(
        exercise: Exercise,
        initialSets: [ExerciseSet]? = nil,
        onSave: @escaping ([ExerciseSet]) -> Void
    ) {
        self.exercise = exercise
        self.initialSets = initialSets
        self.onSave = onSave

        // Werte aus initialSets laden, falls vorhanden
        if let sets = initialSets, !sets.isEmpty {
            let workSets = sets.filter { $0.setKind == .work }
            let warmupSetsCount = sets.filter { $0.setKind == .warmup }.count

            // Anzahl Arbeitssätze
            _numberOfSets = State(initialValue: workSets.count)

            // Wiederholungen (aus erstem Arbeitssatz)
            _targetReps = State(initialValue: workSets.first?.reps ?? 10)

            // Gewicht (weightPerSide falls unilateral, sonst weight)
            let firstWorkSet = workSets.first
            if exercise.isUnilateral, let weightPerSide = firstWorkSet?.weightPerSide {
                _targetWeight = State(initialValue: weightPerSide)
            } else {
                _targetWeight = State(initialValue: firstWorkSet?.weight ?? 0)
            }

            // Pausenzeit
            _restSeconds = State(initialValue: firstWorkSet?.restSeconds ?? 90)

            // RIR
            _targetRIR = State(initialValue: firstWorkSet?.targetRIR ?? 2)

            // Set-Art
            _workSetKind = State(initialValue: firstWorkSet?.setKind ?? .work)

            // Aufwärmsätze
            _includeWarmup = State(initialValue: warmupSetsCount > 0)
            _warmupSets = State(initialValue: max(warmupSetsCount, 1))
        } else {
            // Default-Werte wenn keine initialSets vorhanden
            _targetWeight = State(initialValue: 0)
            _numberOfSets = State(initialValue: 3)
            _targetReps = State(initialValue: 10)
            _restSeconds = State(initialValue: 90)
            _targetRIR = State(initialValue: 2)
            _workSetKind = State(initialValue: .work)
            _includeWarmup = State(initialValue: false)
            _warmupSets = State(initialValue: 1)
        }
    }

    // Konfiguration
    @State private var numberOfSets: Int = 3
    @State private var targetReps: Int = 10
    @State private var targetWeight: Double = 0
    @State private var includeWarmup: Bool = false
    @State private var warmupSets: Int = 1

    // Erweiterte Konfiguration
    @State private var restSeconds: Int = 90
    @State private var targetRIR: Int = 2
    @State private var workSetKind: SetKind = .work

    // Für Long Press bei Sets, Reps und Weight
    @State private var incrementTimer: Timer?

    // Enumeration für fokussierte Felder
    enum FocusedField {
        case sets, reps, weight
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                ScrollView {
                    VStack(spacing: 20) {
                        // Übungs-Info Card
                        exerciseInfoCard

                        // Satz-Konfiguration
                        setsConfigurationCard

                        // Vorschau
                        previewCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Sätze konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveSets()
                    } label: {
                        IconType(icon: .system("checkmark"), color: .blue, size: 16)
                            .glassButton(size: 36, accentColor: .blue)
                    }
                }
            }
            .onDisappear {
                incrementTimer?.invalidate()
                incrementTimer = nil
            }
        }
    }

    // MARK: - Subviews

    private var exerciseInfoCard: some View {
        HStack(spacing: 16) {
            ExerciseGifView(assetName: exercise.gifAssetName, size: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Label(exercise.equipment.description, systemImage: exercise.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !exercise.primaryMuscles.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(exercise.primaryMuscles.prefix(2), id: \.self) { muscle in
                            Text(muscle.description)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()
        }
        .glassCard()
    }

    private var setsConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Konfiguration")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            // Anzahl Arbeitssätze
            VStack(alignment: .leading, spacing: 8) {
                Text("Arbeitssätze")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    // Minus Button
                    Button {
                        decreaseSets(by: 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in startContinuousAdjustment(field: .sets, increment: false) }
                    )
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if !pressing { stopContinuousAdjustment() }
                    }, perform: {})

                    // Große Zahl
                    Text("\(numberOfSets)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(width: 100)
                        .contentTransition(.numericText())

                    // Plus Button
                    Button {
                        increaseSets(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in startContinuousAdjustment(field: .sets, increment: true) }
                    )
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if !pressing { stopContinuousAdjustment() }
                    }, perform: {})
                }
                .frame(maxWidth: .infinity)
            }

            GlassDivider.compact

            // Wiederholungen
            VStack(alignment: .leading, spacing: 8) {
                Text("Wiederholungen pro Satz")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    // Minus Button
                    Button {
                        decreaseReps(by: 1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in startContinuousAdjustment(field: .reps, increment: false) }
                    )
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if !pressing { stopContinuousAdjustment() }
                    }, perform: {})

                    // Große Zahl
                    Text("\(targetReps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(width: 100)
                        .contentTransition(.numericText())

                    // Plus Button
                    Button {
                        increaseReps(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.35)
                            .onEnded { _ in startContinuousAdjustment(field: .reps, increment: true) }
                    )
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if !pressing { stopContinuousAdjustment() }
                    }, perform: {})
                }
                .frame(maxWidth: .infinity)
            }

            GlassDivider.compact

            // Gewicht - Unterscheidung unilateral/bilateral
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.isUnilateral ? "Gewicht pro Seite (kg)" : "Zielgewicht (kg)")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    // Unilateral-Badge
                    if exercise.isUnilateral {
                        Text("2×")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    // Minus Button (Tap = 0.25, LongPress = Auto-Repeat)
                    Button {
                        decreaseWeight(by: 0.25)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing {
                            startAutoRepeatWeight(increment: false)
                        } else {
                            stopContinuousAdjustment()
                        }
                    }, perform: {})

                    // Große Zahl mit unilateral Anzeige
                    if exercise.isUnilateral && targetWeight > 0 {
                        HStack(spacing: 6) {
                            Text("2 ×")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.2f", targetWeight))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                        }
                        .frame(width: 150)
                        .contentTransition(.numericText())
                    } else {
                        Text(targetWeight > 0 ? String(format: "%.2f", targetWeight) : "–")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(width: 150)
                            .contentTransition(.numericText())
                    }

                    // Plus Button (Tap = 0.25, LongPress = Auto-Repeat)
                    Button {
                        increaseWeight(by: 0.25)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing {
                            startAutoRepeatWeight(increment: true)
                        } else {
                            stopContinuousAdjustment()
                        }
                    }, perform: {})
                }
                .frame(maxWidth: .infinity)

                // Hilfstext je nach Übungstyp
                if exercise.isUnilateral {
                    if targetWeight > 0 {
                        Text("Gesamt: \(String(format: "%.2f", targetWeight * 2)) kg (beide Seiten)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Gewicht einer Kurzhantel/Seite eingeben")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("0 = Körpergewicht oder später festlegen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GlassDivider.compact

            // Aufwärmsätze
            Toggle(isOn: $includeWarmup) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aufwärmsätze hinzufügen")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Leichtere Sätze vor den Arbeitssätzen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.blue)

            if includeWarmup {
                HStack {
                    Text("Anzahl Aufwärmsätze")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Picker("", selection: $warmupSets) {
                        ForEach(1...3, id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }

            GlassDivider.compact

            // Pausenzeit
            SetRestTimeSection(restSeconds: $restSeconds)

            GlassDivider.compact

            // Ziel-RIR
            SetTargetRIRSection(targetRIR: $targetRIR)
        }
        .glassCard()
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vorschau")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                // Aufwärmsätze
                if includeWarmup {
                    ForEach(1...warmupSets, id: \.self) { setNum in
                        SetPreviewRow(
                            setNumber: setNum,
                            reps: targetReps,
                            weight: calculateWarmupWeight(setNum),
                            setKind: .warmup,
                            restSeconds: 60,
                            targetRIR: 4,
                            isUnilateral: exercise.isUnilateral
                        )
                    }
                }

                // Arbeitssätze
                ForEach(1...numberOfSets, id: \.self) { setNum in
                    SetPreviewRow(
                        setNumber: (includeWarmup ? warmupSets : 0) + setNum,
                        reps: targetReps,
                        weight: targetWeight,
                        setKind: workSetKind,
                        restSeconds: restSeconds,
                        targetRIR: targetRIR,
                        isUnilateral: exercise.isUnilateral
                    )
                }
            }

            // Zusammenfassung
            VStack(spacing: 8) {
                HStack {
                    Label("\(totalSetsCount) Sätze", systemImage: "number.circle.fill")
                    Spacer()
                    Label("\(totalSetsCount * targetReps) Wdh. gesamt", systemImage: "repeat.circle.fill")
                }

                // Pause und RIR Info
                HStack {
                    Label(formatRestTime(restSeconds), systemImage: "timer")
                    Spacer()
                    Label("RIR \(targetRIR)", systemImage: "flame.fill")
                }

                // Gesamtvolumen bei unilateral
                if exercise.isUnilateral && targetWeight > 0 {
                    HStack {
                        Label("Gesamtgewicht: \(String(format: "%.1f", targetWeight * 2)) kg", systemImage: "scalemass.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .glassCard()
    }

    // Helper für Zeitformatierung
    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 {
            return "\(mins):\(String(format: "%02d", secs)) Pause"
        } else if mins > 0 {
            return "\(mins) Min Pause"
        } else {
            return "\(secs) Sek Pause"
        }
    }

    // MARK: - Berechnungen

    private var totalSetsCount: Int {
        numberOfSets + (includeWarmup ? warmupSets : 0)
    }

    private func calculateWarmupWeight(_ setNum: Int) -> Double {
        guard targetWeight > 0 else { return 0 }
        // Aufwärmsätze: 50%, 70%, 85% des Zielgewichts
        let percentages = [0.5, 0.7, 0.85]
        let index = min(setNum - 1, percentages.count - 1)
        return (targetWeight * percentages[index]).rounded(toNearest: 2.5)
    }

    // MARK: - Speichern

    private func saveSets() {
        var sets: [ExerciseSet] = []
        var setNumber = 1

        // Aufwärmsätze
        if includeWarmup {
            for i in 1...warmupSets {
                let warmupWeight = calculateWarmupWeight(i)
                let set = ExerciseSet(
                    from: exercise,
                    setNumber: setNumber,
                    weight: exercise.isUnilateral ? warmupWeight * 2 : warmupWeight,
                    reps: targetReps
                )
                // Bei unilateral das Gewicht pro Seite speichern
                if exercise.isUnilateral {
                    set.weightPerSide = warmupWeight
                }
                set.setKind = .warmup
                set.restSeconds = 60  // Kürzere Pause beim Aufwärmen
                set.targetRIR = 4     // Aufwärmen sollte leichter sein
                sets.append(set)
                setNumber += 1
            }
        }

        // Arbeitssätze
        for _ in 1...numberOfSets {
            let set = ExerciseSet(
                from: exercise,
                setNumber: setNumber,
                weight: exercise.isUnilateral ? targetWeight * 2 : targetWeight,
                reps: targetReps
            )
            // Bei unilateral das Gewicht pro Seite speichern
            if exercise.isUnilateral {
                set.weightPerSide = targetWeight
            }
            // Erweiterte Werte setzen
            set.setKind = workSetKind
            set.restSeconds = restSeconds
            set.targetRIR = targetRIR
            sets.append(set)
            setNumber += 1
        }

        onSave(sets)
        dismiss()
    }

    // MARK: - Adjustment Helpers

    // Sets erhöhen
    private func increaseSets(by amount: Int) {
        if numberOfSets < 10 {
            numberOfSets += amount
            hapticFeedback()
        }
    }

    // Sets vermindern
    private func decreaseSets(by amount: Int) {
        if numberOfSets > 1 {
            numberOfSets -= amount
            hapticFeedback()
        }
    }

    // Reps erhöhen
    private func increaseReps(by amount: Int) {
        if targetReps < 50 {
            targetReps += amount
            hapticFeedback()
        }
    }

    // Reps vermindern
    private func decreaseReps(by amount: Int) {
        if targetReps > 1 {
            targetReps -= amount
            hapticFeedback()
        }
    }

    // Gewicht erhöhen (0,25 kg Schritte)
    private func increaseWeight(by amount: Double) {
        targetWeight += amount
        targetWeight = (targetWeight * 4).rounded() / 4  // Auf 0,25 runden
        hapticFeedback()
    }

    // Gewicht vermindern (0,25 kg Schritte)
    private func decreaseWeight(by amount: Double) {
        if targetWeight >= amount {
            targetWeight -= amount
            targetWeight = (targetWeight * 4).rounded() / 4  // Auf 0,25 runden
            hapticFeedback()
        }
    }

    // Continuous Adjustment (Long Press mit Delay) - Sets/Reps (dein bestehendes Verhalten)
    private func startContinuousAdjustment(field: FocusedField, increment: Bool) {
        // Warte kurz (0.8s) bevor kontinuierliches Anpassen startet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.incrementTimer == nil else { return }

            var counter = 0

            self.incrementTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                counter += 1

                switch field {
                case .sets:
                    if increment { self.increaseSets(by: 1) } else { self.decreaseSets(by: 1) }

                case .reps:
                    if increment { self.increaseReps(by: 1) } else { self.decreaseReps(by: 1) }

                case .weight:
                    // wird hier nicht mehr genutzt (Weight hat eigenes Auto-Repeat)
                    let step = counter > 20 ? 0.5 : 0.25
                    if increment { self.increaseWeight(by: step) } else { self.decreaseWeight(by: step) }
                }
            }

            if let t = self.incrementTimer {
                RunLoop.current.add(t, forMode: .common)
            }
        }
    }

    // ✅ Auto-Repeat für Weight (Tap bleibt Tap, LongPress startet direkt Repeat)
    private func startAutoRepeatWeight(increment: Bool) {
        stopContinuousAdjustment()

        var counter = 0
        incrementTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            counter += 1
            let step: Double = counter > 20 ? 0.5 : 0.25
            if increment { increaseWeight(by: step) } else { decreaseWeight(by: step) }
        }

        if let t = incrementTimer {
            RunLoop.current.add(t, forMode: .common)
        }
    }

    // Timer stoppen
    private func stopContinuousAdjustment() {
        incrementTimer?.invalidate()
        incrementTimer = nil
    }

    // Haptic Feedback
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Set Preview Row

private struct SetPreviewRow: View {
    let setNumber: Int
    let reps: Int
    let weight: Double
    let setKind: SetKind
    let restSeconds: Int
    let targetRIR: Int
    let isUnilateral: Bool

    var body: some View {
        HStack {
            // Satz-Nummer mit Typ-Badge
            HStack(spacing: 6) {
                Text(setKind.shortName)
                    .font(.caption.bold())
                    .frame(width: 20, height: 20)
                    .background(setKind.color.opacity(0.2))
                    .foregroundStyle(setKind.color)
                    .clipShape(Circle())

                Text("Satz \(setNumber)")
                    .font(.subheadline)
                    .foregroundStyle(setKind == .warmup ? .orange : .primary)
            }

            Spacer()

            // Reps × Gewicht - "2 × X kg" bei unilateral
            HStack(spacing: 4) {
                Text("\(reps)")
                    .font(.subheadline.bold())

                Text("×")
                    .foregroundStyle(.secondary)

                if isUnilateral && weight > 0 {
                    HStack(spacing: 2) {
                        Text("2×")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f kg", weight))
                            .font(.subheadline.bold())
                    }
                } else {
                    Text(weight > 0 ? String(format: "%.1f kg", weight) : "–")
                        .font(.subheadline.bold())
                }
            }

            // RIR Badge
            Text("RIR \(targetRIR)")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(rirColor.opacity(0.2))
                .foregroundStyle(rirColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(setKind.color.opacity(0.1))
        )
    }

    private var rirColor: Color {
        switch targetRIR {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .blue
        }
    }
}

// MARK: - Double Extension

private extension Double {
    func rounded(toNearest value: Double) -> Double {
        (self / value).rounded() * value
    }
}

// MARK: - Preview

#Preview("Set Configuration Sheet") {
    SetConfigurationSheet(
        exercise: Exercise(
            name: "Bankdrücken",
            category: .compound,
            equipment: .barbell,
            primaryMuscles: [.chest]
        )
    ) { sets in
        print("Created \(sets.count) sets")
    }
    .environmentObject(AppSettings.shared)
}
