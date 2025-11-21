//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Basis-Darstellungen                                              /
// Datei . . . . : EmptyState.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 10.11.2025                                                       /
// Beschreibung  : Display ohne Workout                                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Neu: Glassmorphic Empty State
struct EmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Image(systemName: "figure.run")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
            .shadow(color: .black.opacity(0.1), radius: 20)

            VStack(spacing: 8) {
                Text("Keine Einträge")
                    .font(.title2.bold())

                Text("Füge dein erstes Training hinzu")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }
}
