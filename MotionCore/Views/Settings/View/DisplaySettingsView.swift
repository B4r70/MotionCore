//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : DisplaySettingsView.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Konfigurationsdisplay für die App-Anzeige                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct DisplaySettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        List {
            // MARK: Erscheinungsbild
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Thema", selection: $appSettings.appTheme) {
                        ForEach(AppTheme.allCases) { appTheme in
                            Text(appTheme.label).tag(appTheme)
                        }
                    }
                    Text("Überschreibt das systemweite Erscheinungsbild.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .pickerStyle(.segmented)
                .tint(.primary)
            } header: {
                Text("Erscheinungsbild")
            }

            // MARK: Animierter Hintergrund
            Section {
                Toggle(isOn: $appSettings.showAnimatedBlob) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Animierter Hintergrund")
                            .font(.body)
                        Text("Zeigt einen animierten Blob-Effekt im Hintergrund.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Specials")
            }

            // MARK: Übungsvideos
            Section {
                Toggle(isOn: $appSettings.showExerciseVideos) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Übungsvideos anzeigen")
                            .font(.body)
                        Text("Blendet Videos zu Übungen ein (z. B. in der Satz-Ansicht).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Übungen")
            }
        }
        .navigationTitle("Anzeigeeinstellungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DisplaySettingsView()
            .environmentObject(AppSettings.shared)
    }
}
