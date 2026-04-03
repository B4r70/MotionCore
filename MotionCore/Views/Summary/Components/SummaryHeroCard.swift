//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryHeroCard.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Hero-Card mit Begrüßung, Rang-Badge und XP-Fortschrittsbalken    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Hero Card

struct SummaryHeroCard: View {

    let motivationalContext: MotivationalContext
    let xpLevel: XPLevel

    // MARK: - Animation State

    @State private var progressVisible: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Begrüßung + Rang-Badge
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(motivationalContext.greeting)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(motivationalContext.motivationalText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer()

                // Rang-Badge
                rankBadge
            }

            // XP-Fortschrittsbalken
            xpProgressBar
        }
        .glassCard()
        // Gradient-Akzentlinie oben (nach glassCard, damit sie den Rand berührt)
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [Color(hex: "#C9E6FF"), Color(hex: "#9BD2FF")],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .clipShape(RoundedRectangle(cornerRadius: 1))
        }
        .task {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                progressVisible = true
            }
        }
    }

    // MARK: - Rang-Badge

    private var rankBadge: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: xpLevel.rank.colorHex).opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: xpLevel.rank.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: xpLevel.rank.colorHex))
            }

            Text(xpLevel.rank.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: xpLevel.rank.colorHex))
        }
    }

    // MARK: - XP-Fortschrittsbalken

    private var xpProgressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Level \(xpLevel.level)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                if !xpLevel.isMaxLevel {
                    Text("\(xpLevel.xpForCurrentLevel) / \(xpLevel.xpForCurrentLevel + xpLevel.xpRequiredForNextLevel) XP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Max Level!")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: xpLevel.rank.colorHex))
                }
            }

            // Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Hintergrund
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    // Füllstand
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#C9E6FF"), Color(hex: xpLevel.rank.colorHex)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: progressVisible
                                ? geo.size.width * CGFloat(xpLevel.progressToNextLevel)
                                : 0,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

#Preview("SummaryHeroCard") {
    let context = MotivationalContext(
        greeting: "Guten Morgen",
        motivationalText: "30 Tage Streak! Unglaublich!"
    )
    let level = XPLevel(
        level: 12,
        totalXP: 6500,
        xpForCurrentLevel: 4500,
        xpRequiredForNextLevel: 3500,
        rank: .warrior,
        progressToNextLevel: 0.57
    )

    SummaryHeroCard(motivationalContext: context, xpLevel: level)
        .padding()
        .environmentObject(AppSettings.shared)
}
