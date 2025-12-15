//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : AboutView.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 03.11.2025                                                       /
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
            VStack(spacing: 10) {
                Image(.appIcon)
                    .font(.system(size: 10))
                    .scaleEffect(0.5)
                    .foregroundStyle(.orange)
                    .padding(.top, 5)

                Text("MotionCore")
                    .font(.largeTitle.bold())

                Text("Deine persönliche Workout-Tracking-App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    Divider()

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
#Preview {
    NavigationStack {
        AboutView()
    }
}
