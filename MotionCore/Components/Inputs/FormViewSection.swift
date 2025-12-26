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
