//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : DisplaySettingsView.swift                                        /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Anzeigeeinstellungen                                             /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

struct DisplaySettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        List {
            // MARK: - Animationen
            Section {
                Toggle(isOn: $settings.showAnimatedBlob) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Animierter Hintergrund")
                            .font(.body)
                        Text("Zeigt einen animierten Blob-Effekt im Hintergrund")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Animationen")
            } footer: {
                Text("Kann die Batterieleistung beeinflussen")
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
