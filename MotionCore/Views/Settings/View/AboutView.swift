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
                AppIconView(size: 120)

                Text("MotionCore")
                    .font(.largeTitle.bold())

                Text("Deine persönliche Workout-Tracking-App")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    // Automatische Version aus Xcode Target
                    InfoRow(title: "Version", value: Bundle.main.fullVersion)
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
