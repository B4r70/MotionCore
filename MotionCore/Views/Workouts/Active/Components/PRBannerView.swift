//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : PRBannerView.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-03                                                       /
// Beschreibung  : Banner-Overlay für neuen persönlichen Rekord                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PRBannerView: View {
    let exerciseName: String
    let oneRM: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Neuer PR!")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("\(exerciseName) — \(String(format: "%.1f", oneRM)) kg 1RM")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Color.yellow.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("PR Banner") {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()

        VStack {
            PRBannerView(exerciseName: "Bankdrücken", oneRM: 102.5)
            Spacer()
        }
    }
}
