// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : DisplaySettingsView.swift                                        /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Anzeigeeinstellungen                                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct DisplaySettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        List {
            // MARK: Erscheinungsbild
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Thema", selection: $settings.appTheme) {
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
            }
            header: {
                Text("Erscheinungsbild")
            }

            // MARK: Animierter Hintergrund
            Section {
                Toggle(isOn: $settings.showAnimatedBlob) {
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
        }
        .navigationTitle("Anzeigeeinstellungen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DisplaySettingsView()
    }
}
