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
    @ObservedObject private var settings = AppSettings.shared

    @State private var showBodyHeightWheel = false

    var body: some View {
        List {
                // MARK: Benutzerangaben
            Section {
                // Userdefault: Körpergröße des Benutzers
                HStack {
                    DisclosureRow(
                        title: "Größe",
                        value: "\(settings.userBodyHeight) cm",
                        isExpanded: $showBodyHeightWheel
                    ){
                        Picker("Körpergröße", selection: $settings.userBodyHeight) {
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
                    Text("(\(settings.userAge) Jahre)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $settings.userBirthdayDate,
                        displayedComponents: .date
                    )
                    .environment(\.locale, Locale(identifier: "de_DE"))
                    .datePickerStyle(.automatic)
                    .labelsHidden()
                }

                // Geschlecht (Wichtig für die Berechnung von Fitness-Werten)
                HStack {
                    Text("Geschlecht")
                    Spacer()

                    Picker("", selection: $settings.userGender) {
                        ForEach(Gender.allCases,id: \.self) { gender in
                            Text(gender.description)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .pickerStyle(.automatic) // Zeigt den ausgewählten Wert als Menüpunkt
                .labelsHidden()
            }
            header: {
                Text("Persönliche Daten")
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
