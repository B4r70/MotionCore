//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : OutdoorFormSections.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Wiederverwendbare Form-Sections für OutdoorFormView              /
//                 (Route, Adresse, Wetter, Dauer)                                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Focus-Enum für Outdoor-Formulare

enum OutdoorFocusedField: Hashable {
    case routeName
    case startStreet, startPostalCode, startCity
    case endStreet, endPostalCode, endCity
    case distance, elevationGain
    case averageSpeed, maxSpeed
    case calories, heartRate, maxHeartRate
    case bodyWeight, temperature
}

// MARK: - Routenname & Datum

struct OutdoorRouteNameSection: View {
    @Binding var routeName: String
    @Binding var date: Date
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        VStack(spacing: 12) {
            // Routenname
            HStack {
                Text("Routenname")
                Spacer()
                TextField("z.B. Rheinufer-Tour", text: $routeName)
                    .multilineTextAlignment(.trailing)
                    .focused(focusedField, equals: .routeName)
            }

            Divider()

            // Datum mit Uhrzeit
            DatePicker(
                "Datum",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .environment(\.locale, Locale(identifier: "de_DE"))
            .tint(.primary)
        }
    }
}

// MARK: - Adressfelder (Start & Ziel)

struct OutdoorAddressSection: View {
    @Binding var startStreet: String
    @Binding var startPostalCode: String
    @Binding var startCity: String
    @Binding var endStreet: String
    @Binding var endPostalCode: String
    @Binding var endCity: String
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Startadresse
            Text("Startpunkt")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("Straße")
                Spacer()
                TextField("Straße & Nr.", text: $startStreet)
                    .multilineTextAlignment(.trailing)
                    .focused(focusedField, equals: .startStreet)
            }

            Divider()

            HStack {
                Text("PLZ")
                Spacer()
                TextField("PLZ", text: $startPostalCode)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .startPostalCode)
            }

            Divider()

            HStack {
                Text("Stadt")
                Spacer()
                TextField("Stadt", text: $startCity)
                    .multilineTextAlignment(.trailing)
                    .focused(focusedField, equals: .startCity)
            }

            Divider()

            // Zieladresse
            Text("Zielpunkt")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("Straße")
                Spacer()
                TextField("Straße & Nr.", text: $endStreet)
                    .multilineTextAlignment(.trailing)
                    .focused(focusedField, equals: .endStreet)
            }

            Divider()

            HStack {
                Text("PLZ")
                Spacer()
                TextField("PLZ", text: $endPostalCode)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .endPostalCode)
            }

            Divider()

            HStack {
                Text("Stadt")
                Spacer()
                TextField("Stadt", text: $endCity)
                    .multilineTextAlignment(.trailing)
                    .focused(focusedField, equals: .endCity)
            }
        }
    }
}

// MARK: - Wetter

struct OutdoorWeatherSection: View {
    @Binding var weatherCondition: WeatherCondition
    @Binding var temperature: Double?
    var focusedField: FocusState<OutdoorFocusedField?>.Binding

    var body: some View {
        VStack(spacing: 12) {
            // Wetter-Picker
            HStack {
                Text("Wetter")
                Spacer()
                Menu {
                    Picker("", selection: $weatherCondition) {
                        ForEach(WeatherCondition.allCases) { condition in
                            Label(condition.description, systemImage: condition.icon)
                                .tag(condition)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: weatherCondition.icon)
                            .foregroundStyle(.primary)
                        Text(weatherCondition.description)
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Temperatur — Double?-Wrapper: nil wird als 0 behandelt, 0 wird wieder nil
            // Bekannte Einschränkung (Phase 1): 0 °C ist nicht erfassbar (→ nil);
            // negative Temperaturen sind über .decimalPad strukturell nicht möglich.
            HStack {
                Text("Temperatur")
                Spacer()
                DecimalTextField(
                    value: Binding(
                        get: { temperature ?? 0 },
                        set: { temperature = $0 == 0 ? nil : $0 }
                    ),
                    placeholder: "z.B. 18",
                    decimalPlaces: 1
                )
                .focused(focusedField, equals: .temperature)

                Text("°C")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Dauer (Wheel)

struct OutdoorDurationSection: View {
    @Binding var duration: Int
    @Binding var showWheel: Bool

    var body: some View {
        DisclosureRow(
            title: "Dauer",
            value: duration > 0 ? "\(duration) min" : "–",
            isExpanded: $showWheel,
            valueColor: .primary
        ) {
            Picker("Dauer", selection: $duration) {
                ForEach(0 ... 600, id: \.self) { min in
                    Text("\(min) min").tag(min)
                }
            }
            .pickerStyle(.wheel)
            .tint(.primary)
            .frame(height: 140)
            .clipped()
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            OutdoorRouteNamePreviewWrapper()
        }
        .padding()
    }
}

// Hilfs-Wrapper für Preview
private struct OutdoorRouteNamePreviewWrapper: View {
    @State private var routeName = ""
    @State private var date = Date()
    @FocusState private var focus: OutdoorFocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route").font(.title3.bold())
            OutdoorRouteNameSection(routeName: $routeName, date: $date, focusedField: $focus)
        }
        .card()
    }
}
