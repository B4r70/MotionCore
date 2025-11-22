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

struct UserSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        List {
                // MARK: Benutzerangaben
            Section {
                HStack {
                    Text("Körpergröße")
                    Spacer()

                    TextField(
                        "0",
                        value: $settings.userBodyHeight, // <-- Bindet direkt an den Int-Wert
                        format: .number // Stellt sicher, dass die Eingabe als Zahl behandelt wird
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    Text("cm") // <-- Einheit von "km" auf "cm" korrigiert
                        .foregroundStyle(.secondary)
                }
                    // 2. Alter
                HStack {
                    Text("Alter")
                    Spacer()
                    TextField("0", value: $settings.userAge, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("Jahre")
                        .foregroundStyle(.secondary)
                }

                    // 3. Geschlecht (Als Picker oder Segmented Control)
                Picker("Geschlecht", selection: $settings.userGender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.description)
                    }
                }
            }
            header: {
                Text("Benutzerangaben")
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
