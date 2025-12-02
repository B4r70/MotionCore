//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : UserSettingsView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.11.2025                                                       /
// Beschreibung  : Konfigurationsdisplay für die Benutzermaße                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct UserSettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings

    @State private var showBodyHeightWheel = false
    @State private var showUserActivityLevelWheel = false

    var body: some View {
        List {
                // MARK: Benutzerangaben
            Section {
                // Userdefault: Körpergröße des Benutzers
                HStack {
                    DisclosureRow(
                        title: "Größe",
                        value: "\(appSettings.userBodyHeight) cm",
                        isExpanded: $showBodyHeightWheel,
                        valueColor: .primary
                    ){
                        Picker("Körpergröße", selection: $appSettings.userBodyHeight) {
                            ForEach(0 ... 250,id: \.self) { cm in
                                Text("\(cm) cm").tag(cm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: 90, height: 100)
                        .clipped()
                    }
                }
                    // 2. Alter
                HStack {
                    Text("Geburtsdatum")
                    Spacer()
                    Text("(\(appSettings.userAge) Jahre)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $appSettings.userBirthdayDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "de_DE"))
                    .datePickerStyle(.automatic)
                    .labelsHidden()
                }

                // Userdefault: Geschlecht (Wichtig für die Berechnung von Fitness-Werten)
                HStack {
                    Text("Geschlecht")
                    Spacer()

                    Picker("", selection: $appSettings.userGender) {
                        ForEach(Gender.allCases,id: \.self) { gender in
                            Text(gender.description)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .pickerStyle(.automatic) // Zeigt den ausgewählten Wert als Menüpunkt
                .labelsHidden()

                // Userdefault: Tägliches Ziel an Aktivkalorien
                HStack {
                    Text("Tagesziel Kalorien")
                    Spacer()
                    TextField(
                        "500",
                        value: $appSettings.dailyActiveCalorieGoal,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)

                    Text("kcal")
                        .foregroundStyle(.secondary)
                }
                // Userdefault: Tägliches Ziel an Schritten
                HStack {
                    Text("Tagesziel Schritte")
                    Spacer()
                    TextField(
                        "5000",
                        value: $appSettings.dailyStepsGoal,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)

                    Text("Schritte")
                        .foregroundStyle(.secondary)
                }
                // Userdefault: Aktivitätslevel
                HStack {
                    DisclosureRow(
                        title: "Aktivitätslevel",
                        value: "\(appSettings.userActivityLevel.shortDescription)",
                        isExpanded: $showUserActivityLevelWheel,
                        valueColor: .primary
                    ){
                        Picker("Aktivitätslevel", selection: $appSettings.userActivityLevel) {
                            ForEach(UserActivityLevel.allCases, id: \.self) { level in
                                Text(level.shortDescription)
                                    .tag(level)
                                    .font(.caption)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 120)
                        .clipped()
                    }
                }
            }
            header: {
                Text("Persönliche Daten")
            }
            footer: {
                Text("Das Aktivitätslevel wird für die Berechnung deines täglichen Gesamtumsatzes (TDEE) verwendet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Benutzerspezifische Werte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserSettingsView()
    }
}
