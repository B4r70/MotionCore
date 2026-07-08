//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : PRBannerView.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 03.03.2026                                                       /
// Beschreibung  : Banner-Overlay für neuen persönlichen Rekord (§4.3)              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PRBannerView: View {
    let exerciseName: String
    let oneRM: Double

    var body: some View {
        HStack(spacing: Space.s3) {
            // Runder Icon-Chip (Ø 38, amber-soft)
            Image(systemName: "crown.fill")
                .font(AppFont.headline)
                .foregroundStyle(Theme.warning)
                .frame(width: 38, height: 38)
                .background(Theme.warning.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: Space.s1) {
                Text("Neuer PR!")
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(exerciseName) · \(String(format: "%.1f", oneRM)) kg 1RM")
                    .font(AppFont.callout)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Badge(text: "Rekord", style: .solid, color: Theme.warning)
        }
        .padding(Space.s4)
        .background(
            Theme.warning.opacity(0.10),
            in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(Theme.warning.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal, Space.s4)
        .padding(.top, Space.s2)
    }
}

// MARK: - Preview

#Preview("PR Banner") {
    ZStack {
        Theme.surfaceApp.ignoresSafeArea()
        VStack {
            PRBannerView(exerciseName: "Bankdrücken", oneRM: 102.5)
            Spacer()
        }
    }
}
