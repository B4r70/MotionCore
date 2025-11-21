//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : AboutView.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.11.2025                                                       /
// Beschreibung  : Informationsdisplay für die App-Einstellungen                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(.appIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .padding(.top, 40)

                Text("MotionCore")
                    .font(.largeTitle.bold())

                Text("Deine persönliche Workout-Tracking-App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(title: "Version", value: "1.0.0")
                    InfoRow(title: "Entwickler", value: "Bartosz Stryjewski")
                    InfoRow(title: "Erstellt", value: "2025")
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Über MotionCore")
        .navigationBarTitleDisplayMode(.inline)
    }
}
