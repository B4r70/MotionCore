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

    // Glassmorphic Empty State
struct EmptyState: View {
    /* *EDIT* Parameter hinzugefügt für Flexibilität */
    let icon: String
    let title: String
    let message: String

    /* *NEW* Default-Initializer für Abwärtskompatibilität */
    init(
        icon: String = "figure.run",
        title: String = "Keine Einträge",
        message: String = "Füge dein erstes Training hinzu"
    ) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Image(systemName: icon) /* *EDIT* Variable statt hardcoded */
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
            .shadow(color: .black.opacity(0.1), radius: 20)

            VStack(spacing: 8) {
                Text(title) /* *EDIT* Variable statt hardcoded */
                    .font(.title2.bold())

                Text(message) /* *EDIT* Variable statt hardcoded */
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center) /* *NEW* Für mehrzeilige Texte */
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
