//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyRecoveryTrendCard.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Platzhalter-Card für den 14-Tage-Erholungs-Trend                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyRecoveryTrendCard

struct BodyRecoveryTrendCard: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Erholungs-Trend · 14 Tage")
                .font(.headline)

            EmptyState()
        }
        .frame(minHeight: 140)
        .glassCard()
    }
}

// MARK: - Preview

#Preview {
    BodyRecoveryTrendCard()
        .padding()
}
