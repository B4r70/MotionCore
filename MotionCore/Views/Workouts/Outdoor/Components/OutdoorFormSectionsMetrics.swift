//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : OutdoorFormSectionsMetrics.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Wiederverwendbare Form-Sections für OutdoorFormView              /
//                 (Distanz, Höhe, Speed, Kalorien, HR, Gewicht, RPE, Energie,      /
//                  Intensität)                                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Distanz

struct OutdoorDistanceSection: View {
    @Binding var distance: Double
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        HStack {
            Text("Distanz")
            Spacer()
            DecimalTextField(value: $distance, placeholder: "0", decimalPlaces: 2)
                .focused(focusedField, equals: .distance)
            Text("km")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Höhenmeter

struct OutdoorElevationSection: View {
    @Binding var elevationGain: Double
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        HStack {
            Text("Höhenmeter")
            Spacer()
            DecimalTextField(value: $elevationGain, placeholder: "0", decimalPlaces: 0)
                .focused(focusedField, equals: .elevationGain)
            Text("m")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Geschwindigkeit (Durchschnitt & Max)

struct OutdoorSpeedSection: View {
    @Binding var averageSpeed: Double
    @Binding var maxSpeed: Double
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        VStack(spacing: 12) {
            // Durchschnittsgeschwindigkeit
            HStack {
                Text("Ø Geschwindigkeit")
                Spacer()
                DecimalTextField(value: $averageSpeed, placeholder: "0", decimalPlaces: 1)
                    .focused(focusedField, equals: .averageSpeed)
                Text("km/h")
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Höchstgeschwindigkeit
            HStack {
                Text("Max. Geschwindigkeit")
                Spacer()
                DecimalTextField(value: $maxSpeed, placeholder: "0", decimalPlaces: 1)
                    .focused(focusedField, equals: .maxSpeed)
                Text("km/h")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Kalorien

struct OutdoorCaloriesSection: View {
    @Binding var calories: Int
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        HStack {
            Text("Kalorien")
            Spacer()
            TextField(
                "0",
                text: Binding(
                    get: { calories > 0 ? "\(calories)" : "" },
                    set: { raw in
                        if let val = Int(raw) { calories = val }
                    }
                )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused(focusedField, equals: .calories)

            Text("kcal")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Herzfrequenz (Durchschnitt & Max)

struct OutdoorHeartRateSection: View {
    @Binding var heartRate: Int
    @Binding var maxHeartRate: Int
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        VStack(spacing: 12) {
            // Durchschnittliche Herzfrequenz
            HStack {
                Text("Ø Herzfrequenz")
                Spacer()
                TextField(
                    "0",
                    text: Binding(
                        get: { heartRate > 0 ? "\(heartRate)" : "" },
                        set: { raw in
                            if let val = Int(raw) { heartRate = val }
                        }
                    )
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused(focusedField, equals: .heartRate)

                Text("bpm")
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Maximale Herzfrequenz
            HStack {
                Text("Max. Herzfrequenz")
                Spacer()
                TextField(
                    "0",
                    text: Binding(
                        get: { maxHeartRate > 0 ? "\(maxHeartRate)" : "" },
                        set: { raw in
                            if let val = Int(raw) { maxHeartRate = val }
                        }
                    )
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused(focusedField, equals: .maxHeartRate)

                Text("bpm")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Körpergewicht

struct OutdoorBodyWeightSection: View {
    @Binding var bodyWeight: Double
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        HStack {
            Text("Gewicht")
            Spacer()
            DecimalTextField(value: $bodyWeight, placeholder: "0", decimalPlaces: 1)
                .focused(focusedField, equals: .bodyWeight)
            Text("kg")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - RPE (Rate of Perceived Exertion, 1–10)

struct OutdoorRPESection: View {
    @Binding var perceivedExertion: Int?

    var body: some View {
        HStack {
            Text("Anstrengung (RPE)")
            Spacer()
            Menu {
                // "Keine Angabe" Option
                Button("Keine Angabe") { perceivedExertion = nil }
                Divider()
                Picker("", selection: Binding(
                    get: { perceivedExertion ?? 0 },
                    set: { perceivedExertion = $0 == 0 ? nil : $0 }
                )) {
                    ForEach(1 ... 10, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(perceivedExertion.map { "\($0) / 10" } ?? "Keine")
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Energielevel vor Training (1–5)

struct OutdoorEnergySection: View {
    @Binding var energyLevelBefore: Int?

    private let labels = ["Erschöpft", "Müde", "Normal", "Gut", "Top-Fit"]

    var body: some View {
        HStack {
            Text("Energielevel")
            Spacer()
            Menu {
                Button("Keine Angabe") { energyLevelBefore = nil }
                Divider()
                Picker("", selection: Binding(
                    get: { energyLevelBefore ?? 0 },
                    set: { energyLevelBefore = $0 == 0 ? nil : $0 }
                )) {
                    ForEach(1 ... 5, id: \.self) { level in
                        Text("\(labels[level - 1]) (\(level))").tag(level)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let level = energyLevelBefore {
                        Text("\(labels[level - 1]) (\(level))")
                            .foregroundStyle(.primary)
                    } else {
                        Text("Keine")
                            .foregroundStyle(.primary)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Intensität (Sterne)

struct OutdoorIntensitySection: View {
    @Binding var intensity: Intensity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Belastungsintensität")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack {
                InputStarRating(rating: $intensity)
            }
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            OutdoorMetricsPreviewWrapper()
        }
        .padding()
    }
}

// Hilfs-Wrapper für Preview
private struct OutdoorMetricsPreviewWrapper: View {
    @State private var distance = 0.0
    @State private var elevation = 0.0
    @State private var avgSpeed = 0.0
    @State private var maxSpeed = 0.0
    @State private var calories = 0
    @State private var hr = 0
    @State private var maxHr = 0
    @State private var weight = 0.0
    @State private var rpe: Int? = nil
    @State private var energy: Int? = nil
    @State private var intensity: Intensity = .none
    @FocusState private var focus: OutdoorFocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Leistungsdaten").font(.title3.bold())
            OutdoorDistanceSection(distance: $distance, focusedField: $focus)
            Divider()
            OutdoorElevationSection(elevationGain: $elevation, focusedField: $focus)
            Divider()
            OutdoorSpeedSection(averageSpeed: $avgSpeed, maxSpeed: $maxSpeed, focusedField: $focus)
            Divider()
            OutdoorCaloriesSection(calories: $calories, focusedField: $focus)
            Divider()
            OutdoorHeartRateSection(heartRate: $hr, maxHeartRate: $maxHr, focusedField: $focus)
            Divider()
            OutdoorBodyWeightSection(bodyWeight: $weight, focusedField: $focus)
        }
        .glassCard()
    }
}
