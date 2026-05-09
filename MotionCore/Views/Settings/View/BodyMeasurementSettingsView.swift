//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : BodyMeasurementSettingsView.swift                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Einstellungen für die Erfassung von Körpermaßen                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct BodyMeasurementSettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        List {
            Section {
                Picker("Modus", selection: $appSettings.bodyMeasurementArmMode) {
                    ForEach(BodyMeasurementSideMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Armumfang")
            } footer: {
                Text("Pro Messung im Erfassungs-Sheet umschaltbar.")
            }

            Section {
                Picker("Modus", selection: $appSettings.bodyMeasurementThighMode) {
                    ForEach(BodyMeasurementSideMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Oberschenkelumfang")
            } footer: {
                Text("Pro Messung im Erfassungs-Sheet umschaltbar.")
            }
        }
        .navigationTitle("Körpermaße")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BodyMeasurementSettingsView()
    }
    .environmentObject(AppSettings.shared)
}
