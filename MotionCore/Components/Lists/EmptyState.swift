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

    // Calm 2026 Empty State — getoenter Icon-Kreis in einer Karte
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
        VStack(spacing: Space.s5) {
            ZStack {
                Circle()
                    .fill(Theme.accentWash)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Space.s2) {
                Text(title)
                    .font(AppFont.title)
                    .foregroundStyle(Theme.textPrimary)

                Text(message)
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .card(padding: Space.s8)
    }
}
