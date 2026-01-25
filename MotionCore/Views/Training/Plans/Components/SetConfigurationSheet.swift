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
import SwiftUI

struct SetConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    // Quelle 1: aus Library
    private let exercise: Exercise?

    // Quelle 2: Snapshot (Edit ohne Exercise-Relationship)
    private let snapshotName: String
    private let snapshotMediaAssetName: String
    private let snapshotIsUnilateral: Bool

    let onSave: ([ExerciseSet]) -> Void
    let initialSets: [ExerciseSet]?

    // Display (computed)
    private var displayName: String { exercise?.name ?? snapshotName }
    private var displayMedia: String { exercise?.mediaAssetName ?? snapshotMediaAssetName }
    private var displayIsUnilateral: Bool { exercise?.isUnilateral ?? snapshotIsUnilateral }

    // MARK: - Init A: Normal mit Exercise
    init(
        exercise: Exercise,
        initialSets: [ExerciseSet]? = nil,
        onSave: @escaping ([ExerciseSet]) -> Void
    ) {
        self.exercise = exercise

        // NEU: Snapshot-Fallbacks IMMER initialisieren (stored props müssen gesetzt sein)
        self.snapshotName = exercise.name
        self.snapshotMediaAssetName = exercise.mediaAssetName
        self.snapshotIsUnilateral = exercise.isUnilateral

        self.initialSets = initialSets
        self.onSave = onSave

        // NEU: gemeinsame Initialisierung der @State Werte
        Self.bootstrapState(
            initialSets: initialSets,
            isUnilateral: exercise.isUnilateral,
            numberOfSets: &_numberOfSets,
            targetReps: &_targetReps,
            targetWeight: &_targetWeight,
            restSeconds: &_restSeconds,
            targetRIR: &_targetRIR,
            workSetKind: &_workSetKind,
            includeWarmup: &_includeWarmup,
            warmupSets: &_warmupSets
        )
    }

    // MARK: - Init B: Snapshot (ohne Exercise)
    init(
        exerciseName: String,
        mediaAssetName: String,
        isUnilateral: Bool = false,
        initialSets: [ExerciseSet]? = nil,
        onSave: @escaping ([ExerciseSet]) -> Void
    ) {
        self.exercise = nil

        self.snapshotName = exerciseName
        self.snapshotMediaAssetName = mediaAssetName
        self.snapshotIsUnilateral = isUnilateral

        self.initialSets = initialSets
        self.onSave = onSave

        // NEU: gemeinsame Initialisierung der @State Werte
        Self.bootstrapState(
            initialSets: initialSets,
            isUnilateral: isUnilateral,
            numberOfSets: &_numberOfSets,
            targetReps: &_targetReps,
            targetWeight: &_targetWeight,
            restSeconds: &_restSeconds,
            targetRIR: &_targetRIR,
            workSetKind: &_workSetKind,
            includeWarmup: &_includeWarmup,
            warmupSets: &_warmupSets
        )
    }

    // MARK: - State
    @State private var numberOfSets: Int = 3
    @State private var targetReps: Int = 10
    @State private var targetWeight: Double = 0
    @State private var includeWarmup: Bool = false
    @State private var warmupSets: Int = 1

    @State private var restSeconds: Int = 90
    @State private var targetRIR: Int = 2
    @State private var workSetKind: SetKind = .work

    @State private var incrementTimer: Timer?

    enum FocusedField { case sets, reps, weight }

    // MARK: - NEU: Bootstrap Helper (initialSets -> @State)
    private static func bootstrapState(
        initialSets: [ExerciseSet]?,
        isUnilateral: Bool,
        numberOfSets: inout State<Int>,
        targetReps: inout State<Int>,
        targetWeight: inout State<Double>,
        restSeconds: inout State<Int>,
        targetRIR: inout State<Int>,
        workSetKind: inout State<SetKind>,
        includeWarmup: inout State<Bool>,
        warmupSets: inout State<Int>
    ) {
        guard let sets = initialSets, !sets.isEmpty else {
            targetWeight = State(initialValue: 0)
            numberOfSets = State(initialValue: 3)
            targetReps = State(initialValue: 10)
            restSeconds = State(initialValue: 90)
            targetRIR = State(initialValue: 2)
            workSetKind = State(initialValue: .work)
            includeWarmup = State(initialValue: false)
            warmupSets = State(initialValue: 1)
            return
        }

        let workSets = sets.filter { $0.setKind == .work }
        let warmupCount = sets.filter { $0.setKind == .warmup }.count

        numberOfSets = State(initialValue: max(workSets.count, 1))
        targetReps = State(initialValue: workSets.first?.reps ?? 10)

        let firstWork = workSets.first
        // Hinweis: weightPerSide ist bei dir Double (nicht optional)
        if isUnilateral, (firstWork?.weightPerSide ?? 0) > 0 {
            targetWeight = State(initialValue: firstWork?.weightPerSide ?? 0)
        } else {
            targetWeight = State(initialValue: firstWork?.weight ?? 0)
        }

        restSeconds = State(initialValue: firstWork?.restSeconds ?? 90)
        targetRIR = State(initialValue: firstWork?.targetRIR ?? 2)
        workSetKind = State(initialValue: firstWork?.setKind ?? .work)

        includeWarmup = State(initialValue: warmupCount > 0)
        warmupSets = State(initialValue: max(warmupCount, 1))
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                ScrollView {
                    VStack(spacing: 20) {
                        exerciseInfoCard
                        setsConfigurationCard
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
                    Button("Abbrechen") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button { saveSets() } label: {
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
            ExerciseVideoView(
                assetName: displayMedia,
                size: 80
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(displayName)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                if let ex = exercise {
                    Label(ex.equipment.description, systemImage: ex.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !ex.primaryMuscles.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(ex.primaryMuscles.prefix(2), id: \.self) { muscle in
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

            // Arbeitssätze
            VStack(alignment: .leading, spacing: 8) {
                Text("Arbeitssätze")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Button { decreaseSets(by: 1) } label: {
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

                    Text("\(numberOfSets)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(width: 100)
                        .contentTransition(.numericText())

                    Button { increaseSets(by: 1) } label: {
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

            // Reps
            VStack(alignment: .leading, spacing: 8) {
                Text("Wiederholungen pro Satz")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Button { decreaseReps(by: 1) } label: {
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

                    Text("\(targetReps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(width: 100)
                        .contentTransition(.numericText())

                    Button { increaseReps(by: 1) } label: {
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

            // Gewicht
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(displayIsUnilateral ? "Gewicht pro Seite (kg)" : "Zielgewicht (kg)")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if displayIsUnilateral {
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
                    Button { decreaseWeight(by: 0.25) } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startAutoRepeatWeight(increment: false) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})

                    if displayIsUnilateral && targetWeight > 0 {
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

                    Button { increaseWeight(by: 0.25) } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .onLongPressGesture(minimumDuration: 0.35, pressing: { pressing in
                        if pressing { startAutoRepeatWeight(increment: true) }
                        else { stopContinuousAdjustment() }
                    }, perform: {})
                }
                .frame(maxWidth: .infinity)

                if displayIsUnilateral {
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

            SetRestTimeSection(restSeconds: $restSeconds)

            GlassDivider.compact

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
                if includeWarmup {
                    ForEach(1...warmupSets, id: \.self) { setNum in
                        SetPreviewRow(
                            setNumber: setNum,
                            reps: targetReps,
                            weight: calculateWarmupWeight(setNum),
                            setKind: .warmup,
                            restSeconds: 60,
                            targetRIR: 4,
                            isUnilateral: displayIsUnilateral
                        )
                    }
                }

                ForEach(1...numberOfSets, id: \.self) { setNum in
                    SetPreviewRow(
                        setNumber: (includeWarmup ? warmupSets : 0) + setNum,
                        reps: targetReps,
                        weight: targetWeight,
                        setKind: workSetKind,
                        restSeconds: restSeconds,
                        targetRIR: targetRIR,
                        isUnilateral: displayIsUnilateral
                    )
                }
            }

            VStack(spacing: 8) {
                HStack {
                    Label("\(totalSetsCount) Sätze", systemImage: "number.circle.fill")
                    Spacer()
                    Label("\(totalSetsCount * targetReps) Wdh. gesamt", systemImage: "repeat.circle.fill")
                }

                HStack {
                    Label(formatRestTime(restSeconds), systemImage: "timer")
                    Spacer()
                    Label("RIR \(targetRIR)", systemImage: "flame.fill")
                }

                if displayIsUnilateral && targetWeight > 0 {
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

    private var totalSetsCount: Int {
        numberOfSets + (includeWarmup ? warmupSets : 0)
    }

    private func calculateWarmupWeight(_ setNum: Int) -> Double {
        guard targetWeight > 0 else { return 0 }
        let percentages = [0.5, 0.7, 0.85]
        let index = min(setNum - 1, percentages.count - 1)
        return (targetWeight * percentages[index]).rounded(toNearest: 2.5)
    }

    // MARK: - Speichern
    private func makeSet(setNumber: Int, weight: Double, reps: Int) -> ExerciseSet {
        if let ex = exercise {
            let set = ExerciseSet(from: ex, setNumber: setNumber, weight: weight, reps: reps)

            // NEU: Unilateral-Snapshot setzen (auch wenn Relationship da ist)
            set.isUnilateralSnapshot = ex.isUnilateral

            return set
        } else {
            let set = ExerciseSet(
                exerciseName: snapshotName,
                exerciseNameSnapshot: snapshotName,
                exerciseUUIDSnapshot: "",
                exerciseMediaAssetName: snapshotMediaAssetName,
                setNumber: setNumber,
                weight: weight,
                reps: reps
            )

            // NEU: Snapshot-Fall
            set.isUnilateralSnapshot = snapshotIsUnilateral

            return set
        }
    }

    private func saveSets() {
        var sets: [ExerciseSet] = []
        var setNumber = 1

        if includeWarmup {
            for i in 1...warmupSets {
                let warmupWeight = calculateWarmupWeight(i)

                let set = makeSet(
                    setNumber: setNumber,
                    weight: displayIsUnilateral ? warmupWeight * 2 : warmupWeight,
                    reps: targetReps
                )

                if displayIsUnilateral { set.weightPerSide = warmupWeight }

                set.setKind = .warmup
                set.restSeconds = 60
                set.targetRIR = 4

                sets.append(set)
                setNumber += 1
            }
        }

        for _ in 1...numberOfSets {
            let set = makeSet(
                setNumber: setNumber,
                weight: displayIsUnilateral ? targetWeight * 2 : targetWeight,
                reps: targetReps
            )

            if displayIsUnilateral { set.weightPerSide = targetWeight }

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
    private func increaseSets(by amount: Int) {
        if numberOfSets < 10 { numberOfSets += amount; hapticFeedback() }
    }

    private func decreaseSets(by amount: Int) {
        if numberOfSets > 1 { numberOfSets -= amount; hapticFeedback() }
    }

    private func increaseReps(by amount: Int) {
        if targetReps < 50 { targetReps += amount; hapticFeedback() }
    }

    private func decreaseReps(by amount: Int) {
        if targetReps > 1 { targetReps -= amount; hapticFeedback() }
    }

    private func increaseWeight(by amount: Double) {
        targetWeight += amount
        targetWeight = (targetWeight * 4).rounded() / 4
        hapticFeedback()
    }

    private func decreaseWeight(by amount: Double) {
        if targetWeight >= amount {
            targetWeight -= amount
            targetWeight = (targetWeight * 4).rounded() / 4
            hapticFeedback()
        }
    }

    private func startContinuousAdjustment(field: FocusedField, increment: Bool) {
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
                    let step = counter > 20 ? 0.5 : 0.25
                    if increment { self.increaseWeight(by: step) } else { self.decreaseWeight(by: step) }
                }
            }

            if let t = self.incrementTimer { RunLoop.current.add(t, forMode: .common) }
        }
    }

    private func startAutoRepeatWeight(increment: Bool) {
        stopContinuousAdjustment()

        var counter = 0
        incrementTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            counter += 1
            let step: Double = counter > 20 ? 0.5 : 0.25
            if increment { increaseWeight(by: step) } else { decreaseWeight(by: step) }
        }

        if let t = incrementTimer { RunLoop.current.add(t, forMode: .common) }
    }

    private func stopContinuousAdjustment() {
        incrementTimer?.invalidate()
        incrementTimer = nil
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Set Preview Row (unverändert)
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

private extension Double {
    func rounded(toNearest value: Double) -> Double {
        (self / value).rounded() * value
    }
}

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
