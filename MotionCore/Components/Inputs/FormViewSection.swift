//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : FormViewSections.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.12.2025                                                       /
// Beschreibung  : Wiederverwendbare Form-Sections für FormView und ExerciseFormView/
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Gemeinsame Sections (für beide Forms)

// MARK: Date Input Section
struct DateInputSection: View {
    @Binding var date: Date

    var body: some View {
        DatePicker(
            "Datum",
            selection: $date,
            displayedComponents: [.date, .hourAndMinute]
        )
        .environment(\.locale, Locale(identifier: "de_DE"))
        .tint(.primary)
    }
}

// MARK: - Cardio-spezifische Sections

// MARK: Device Selection Section
struct DeviceSelectionSection: View {
    @Binding var selectedDevice: CardioDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gerätetyp")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                DeviceButton(
                    device: .crosstrainer,
                    isSelected: selectedDevice == .crosstrainer
                ) {
                    selectedDevice = .crosstrainer
                }

                DeviceButton(
                    device: .ergometer,
                    isSelected: selectedDevice == .ergometer
                ) {
                    selectedDevice = .ergometer
                }
            }
        }
    }
}

// MARK: Program Selection Section
struct ProgramSelectionSection: View {
    @Binding var selectedProgram: TrainingProgram

    var body: some View {
        HStack {
            Text("Trainingsprogramm")
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Picker("", selection: $selectedProgram) {
                    ForEach(TrainingProgram.allCases, id: \.self) { p in
                        Label(p.description, systemImage: p.symbol)
                            .tag(p)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedProgram.description)
                        .foregroundStyle(.primary)
                        .tint(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .tint(.primary)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: Duration Section
struct DurationSection: View {
    @Binding var duration: Int
    @Binding var showWheel: Bool
    var focusedField: FocusState<FocusedField?>.Binding?

    var body: some View {
        DisclosureRow(
            title: "Dauer",
            value: "\(duration) min",
            isExpanded: $showWheel,
            valueColor: .primary
        ) {
            Picker("Dauer", selection: $duration) {
                ForEach(0 ... 300, id: \.self) { min in
                    Text("\(min) min").tag(min)
                }
            }
            .pickerStyle(.wheel)
            .tint(.primary)
            .frame(height: 140)
            .clipped()
            .if(focusedField != nil) { view in
                view.focused(focusedField!, equals: .duration)
            }
        }
    }
}

// MARK: Difficulty Section
struct DifficultySection: View {
    @Binding var difficulty: Int
    @Binding var showWheel: Bool
    var focusedField: FocusState<FocusedField?>.Binding?

    var body: some View {
        DisclosureRow(
            title: "Schwierigkeitsgrad",
            value: "\(difficulty)",
            isExpanded: $showWheel,
            valueColor: .primary
        ) {
            Picker("Schwierigkeitsgrad", selection: $difficulty) {
                ForEach(1 ... 25, id: \.self) { v in
                    Text("Stufe \(v)").tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .clipped()
            .if(focusedField != nil) { view in
                view.focused(focusedField!, equals: .difficulty)
            }
        }
    }
}

// MARK: Distance Input Row
struct DistanceInputRow: View {
    @Binding var distance: Double
    var focusedField: FocusState<FocusedField?>.Binding?

    var body: some View {
        HStack {
            Text("Distanz")
            Spacer()
            TextField(
                "0,00",
                text: Binding(
                    get: { String(format: "%.2f", distance) },
                    set: { raw in
                        let normalized = raw.replacingOccurrences(of: ",", with: ".")
                        if let val = Double(normalized) {
                            distance = val
                        }
                    }
                )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .if(focusedField != nil) { view in
                view.focused(focusedField!, equals: .distance)
            }

            Text("km")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: Body Weight Input Row
struct BodyWeightInputRow: View {
    @Binding var bodyWeight: Double
    var focusedField: FocusState<FocusedField?>.Binding?

    var body: some View {
        HStack {
            Text("Gewicht")
            Spacer()
            TextField("0.0", value: $bodyWeight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .if(focusedField != nil) { view in
                    view.focused(focusedField!, equals: .bodyWeight)
                }

            Text("kg")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: Calories Section
struct CaloriesSection: View {
    @Binding var calories: Int
    @Binding var showWheel: Bool
    var focusedField: FocusState<FocusedField?>.Binding?

    var body: some View {
        DisclosureRow(
            title: "Kalorien",
            value: "\(calories) kcal",
            isExpanded: $showWheel,
            valueColor: .primary
        ) {
            Picker("Kalorien", selection: $calories) {
                ForEach(0 ... 2000, id: \.self) { kcal in
                    Text("\(kcal) kcal").tag(kcal)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 140)
            .clipped()
            .if(focusedField != nil) { view in
                view.focused(focusedField!, equals: .calories)
            }
        }
    }
}

// MARK: Heart Rate Section
struct HeartRateSection: View {
    @Binding var heartRate: Int
    @Binding var showWheel: Bool
    var focusedField: FocusState<FocusedField?>.Binding?

    var body: some View {
        DisclosureRow(
            title: "Herzfrequenz",
            value: "\(heartRate) bpm",
            isExpanded: $showWheel,
            valueColor: .primary
        ) {
            Picker("Herzfrequenz", selection: $heartRate) {
                ForEach(60 ... 200, id: \.self) { bpm in
                    Text("\(bpm) bpm").tag(bpm)
                }
            }
            .pickerStyle(.wheel)
            .tint(.primary)
            .frame(height: 140)
            .clipped()
            .if(focusedField != nil) { view in
                view.focused(focusedField!, equals: .heartRate)
            }
        }
    }
}

// MARK: Intensity Selection Section
struct IntensitySelectionSection: View {
    @Binding var intensity: Intensity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Belastungsintensität")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack {
                InputStarRating(rating: $intensity)
                    .scaleEffect(1.0)
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Exercise-spezifische Sections

// MARK: Exercise Name Section
struct ExerciseNameSection: View {
    @Binding var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.headline)
                .foregroundStyle(.primary)

            TextField("z.B. Bankdrücken", text: $name)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
        }
    }
}

// MARK: Exercise Description Section
struct ExerciseDescriptionSection: View {
    @Binding var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Beschreibung (optional)")
                .font(.headline)
                .foregroundStyle(.primary)

            TextField("Ausführung, Tipps...", text: $description, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
        }
    }
}

// MARK: Exercise Category Section
struct ExerciseCategorySection: View {
    @Binding var category: ExerciseCategory

    var body: some View {
        HStack {
            Text("Kategorie")
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Picker("", selection: $category) {
                    ForEach(ExerciseCategory.allCases) { category in
                        Label(category.description, systemImage: category.icon)
                            .tag(category)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(category.description)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

// MARK: Exercise Equipment Section
struct ExerciseEquipmentSection: View {
    @Binding var equipment: ExerciseEquipment

    var body: some View {
        HStack {
            Text("Gerät/Equipment")
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Picker("", selection: $equipment) {
                    ForEach(ExerciseEquipment.allCases) { equipment in
                        Label(equipment.description, systemImage: equipment.icon)
                            .tag(equipment)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(equipment.description)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

// MARK: Exercise Difficulty Section
struct ExerciseDifficultySection: View {
    @Binding var difficulty: ExerciseDifficulty

    var body: some View {
        HStack {
            Text("Schwierigkeit")
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Picker("", selection: $difficulty) {
                    ForEach(ExerciseDifficulty.allCases) { difficulty in
                        HStack {
                            Text(difficulty.description)
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(0..<difficulty.stars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                }
                            }
                        }
                        .tag(difficulty)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(difficulty.description)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

// MARK: Exercise Primary Muscle Groups Section
struct ExercisePrimaryMuscleGroupsSection: View {
    @Binding var selectedMuscles: [MuscleGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primäre Muskelgruppen")
                .font(.headline)
                .foregroundStyle(.primary)

            NavigationLink {
                MuscleGroupPicker(
                    selectedMuscles: $selectedMuscles,
                    title: "Primäre Muskelgruppen"
                )
            } label: {
                HStack {
                    if selectedMuscles.isEmpty {
                        Text("Keine ausgewählt")
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(selectedMuscles, id: \.self) { muscle in
                                    Text(muscle.description)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.2))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
            }
        }
    }
}

// MARK: Exercise Secondary Muscle Groups Section
struct ExerciseSecondaryMuscleGroupsSection: View {
    @Binding var selectedMuscles: [MuscleGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sekundäre Muskelgruppen (optional)")
                .font(.headline)
                .foregroundStyle(.primary)

            NavigationLink {
                MuscleGroupPicker(
                    selectedMuscles: $selectedMuscles,
                    title: "Sekundäre Muskelgruppen"
                )
            } label: {
                HStack {
                    if selectedMuscles.isEmpty {
                        Text("Keine ausgewählt")
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(selectedMuscles, id: \.self) { muscle in
                                    Text(muscle.description)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.purple.opacity(0.2))
                                        .foregroundStyle(.purple)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
            }
        }
    }
}

// MARK: Exercise GIF Asset Section
struct ExerciseGifAssetSection: View {
    @Binding var gifAssetName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GIF-Name (optional)")
                .font(.headline)
                .foregroundStyle(.primary)

            TextField("z.B. bench_press", text: $gifAssetName)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )
        }
    }
}

// MARK: Exercise Favorite Toggle
struct ExerciseFavoriteToggle: View {
    @Binding var isFavorite: Bool

    var body: some View {
        Toggle(isOn: $isFavorite) {
            HStack(spacing: 8) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)

                Text("Als Favorit markieren")
                    .foregroundStyle(.primary)
            }
        }
        .tint(.yellow)
    }
}

// MARK: - Exercise Movement Pattern Section
struct ExerciseMovementPatternSection: View {
    @Binding var movementPattern: MovementPattern

    var body: some View {
        HStack {
            Text("Bewegungsmuster")
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Picker("", selection: $movementPattern) {
                    ForEach(MovementPattern.allCases) { pattern in
                        Label(pattern.description, systemImage: pattern.icon)
                            .tag(pattern)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: movementPattern.icon)
                        .foregroundStyle(.blue)

                    Text(movementPattern.description)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Exercise Body Position Section
struct ExerciseBodyPositionSection: View {
    @Binding var bodyPosition: BodyPosition

    var body: some View {
        HStack {
            Text("Körperposition")
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                Picker("", selection: $bodyPosition) {
                    ForEach(BodyPosition.allCases) { position in
                        Label(position.description, systemImage: position.icon)
                            .tag(position)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: bodyPosition.icon)
                        .foregroundStyle(.blue)

                    Text(bodyPosition.description)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Exercise Unilateral Toggle
struct ExerciseUnilateralToggle: View {
    @Binding var isUnilateral: Bool

    var body: some View {
        Toggle(isOn: $isUnilateral) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: isUnilateral ? "hand.raised.fingers.spread.fill" : "hands.clap.fill")
                        .foregroundStyle(isUnilateral ? .orange : .secondary)

                    Text("Unilaterale Übung")
                        .foregroundStyle(.primary)
                }

                Text(isUnilateral ? "Einseitige Ausführung (z.B. einarmig)" : "Beidseitige Ausführung")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.orange)
    }
}

// MARK: - Exercise Rep Range Section
struct ExerciseRepRangeSection: View {
    @Binding var repRangeMin: Int
    @Binding var repRangeMax: Int

    // Berechneter Trainingstyp
    private var trainingType: String {
        switch repRangeMax {
        case 1...3: return "Maximalkraft"
        case 4...6: return "Kraft"
        case 7...12: return "Hypertrophie"
        case 13...20: return "Kraftausdauer"
        default: return "Ausdauer"
        }
    }

    private var trainingTypeColor: Color {
        switch repRangeMax {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...12: return .blue
        case 13...20: return .green
        default: return .teal
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wiederholungsbereich")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                // Trainingstyp-Badge
                Text(trainingType)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(trainingTypeColor.opacity(0.2))
                    .foregroundStyle(trainingTypeColor)
                    .clipShape(Capsule())
            }

            // Rep Range Anzeige
            HStack(spacing: 16) {
                // Minimum
                VStack(spacing: 4) {
                    Text("Min")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button {
                            if repRangeMin > 1 { repRangeMin -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.blue)
                        }

                        Text("\(repRangeMin)")
                            .font(.title2.bold())
                            .frame(width: 40)

                        Button {
                            if repRangeMin < repRangeMax - 1 { repRangeMin += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Text("–")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                // Maximum
                VStack(spacing: 4) {
                    Text("Max")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Button {
                            if repRangeMax > repRangeMin + 1 { repRangeMax -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.blue)
                        }

                        Text("\(repRangeMax)")
                            .font(.title2.bold())
                            .frame(width: 40)

                        Button {
                            if repRangeMax < 50 { repRangeMax += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Formatierte Anzeige
            Text("\(repRangeMin)–\(repRangeMax) Wiederholungen empfohlen")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Exercise Caution Note Section
struct ExerciseCautionNoteSection: View {
    @Binding var cautionNote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text("Sicherheitshinweis (optional)")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            TextField("z.B. Nicht bei Schulterproblemen", text: $cautionNote, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 0.8)
                )
        }
    }
}

// MARK: - Set Rest Time Section
struct SetRestTimeSection: View {
    @Binding var restSeconds: Int

    private let presets = [30, 60, 90, 120, 180, 240]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)

                Text("Pausenzeit")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(formatTime(restSeconds))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.blue)
            }

            // Preset-Buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(presets, id: \.self) { seconds in
                    Button {
                        restSeconds = seconds
                    } label: {
                        Text(formatTime(seconds))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(restSeconds == seconds ? Color.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(restSeconds == seconds ? Color.blue : Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .foregroundStyle(restSeconds == seconds ? .blue : .primary)
                }
            }

            // Feineinstellung
            HStack {
                Button {
                    if restSeconds >= 15 { restSeconds -= 15 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                Spacer()

                Text("±15 Sek.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if restSeconds < 600 { restSeconds += 15 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 {
            return "\(mins):\(String(format: "%02d", secs))"
        } else if mins > 0 {
            return "\(mins) Min"
        } else {
            return "\(secs) Sek"
        }
    }
}

// MARK: - Set Target RIR Section
struct SetTargetRIRSection: View {
    @Binding var targetRIR: Int

    private var rirDescription: String {
        switch targetRIR {
            case 0: return "Bis Muskelversagen"
            case 1: return "Fast am Limit"
            case 2: return "Moderate Intensität"
            case 3: return "Kontrolliert"
            case 4...5: return "Leicht bis Moderat"
            default: return "Sehr leicht"
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ziel-RIR")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(rirDescription)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(rirColor.opacity(0.2))
                    .foregroundStyle(rirColor)
                    .clipShape(Capsule())
            }

            Text("Reps In Reserve – Wie viele Wiederholungen könntest du noch schaffen?")
                .font(.caption)
                .foregroundStyle(.secondary)

            // RIR Auswahl
            HStack(spacing: 8) {
                ForEach(0...5, id: \.self) { rir in
                    Button {
                        targetRIR = rir
                    } label: {
                        Text("\(rir)")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(targetRIR == rir ? rirColorFor(rir).opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(targetRIR == rir ? rirColorFor(rir) : Color.white.opacity(0.2), lineWidth: 2)
                            )
                    }
                    .foregroundStyle(targetRIR == rir ? rirColorFor(rir) : .primary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func rirColorFor(_ rir: Int) -> Color {
        switch rir {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .blue
        }
    }
}

// MARK: - Set Kind Selection Section
struct SetKindSelectionSection: View {
    @Binding var setKind: SetKind

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Satz-Typ")
                .font(.headline)
                .foregroundStyle(.primary)

            // Set Kind Buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(SetKind.allCases) { kind in
                    Button {
                        setKind = kind
                    } label: {
                        VStack(spacing: 4) {
                            Text(kind.shortName)
                                .font(.title3.bold())

                            Text(kind.description)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(setKind == kind ? kind.color.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(setKind == kind ? kind.color : Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .foregroundStyle(setKind == kind ? kind.color : .primary)
                }
            }
        }
    }
}

// MARK: - Helper Extension für conditional modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
