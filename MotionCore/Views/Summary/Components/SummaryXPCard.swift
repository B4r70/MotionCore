//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryXPCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.04.2026                                                       /
// Beschreibung  : XP- und Rang-Card mit animiertem Fortschrittsbalken              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary XP Card

struct SummaryXPCard: View {

    let xpLevel: XPLevel
    let recentGains: [XPGain]

    @State private var progressVisible: Bool = false

    // Rang-Farbe ist data-driven (Gamification-Palette), bleibt Color(hex:) — Einzelfall.
    private var rankColor: Color { Color(hex: xpLevel.rank.colorHex) }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            headerSection
            progressBarSection
            if !recentGains.isEmpty {
                Divider().opacity(0.4)
                recentGainsSection
            }
        }
        .card()
        .task {
            withAnimation(.easeOut(duration: 0.36).delay(0.2)) {
                progressVisible = true
            }
        }
    }

    // MARK: - Kopfzeile

    private var headerSection: some View {
        HStack(spacing: Space.s4) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: xpLevel.rank.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(rankColor)
            }

            VStack(alignment: .leading, spacing: Space.s1) {
                Text(xpLevel.rank.displayName)
                    .font(AppFont.headline)
                    .foregroundStyle(rankColor)
                Text("Level \(xpLevel.level)")
                    .font(AppFont.body)
                    .foregroundStyle(Theme.textSecondary)
                Text("\(xpLevel.totalXP) XP gesamt")
                    .font(AppFont.callout)
                    .monospacedDigit()
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if !xpLevel.isMaxLevel {
                VStack(alignment: .trailing, spacing: Space.s1) {
                    Text("→ Level \(xpLevel.level + 1)")
                        .font(AppFont.callout)
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(xpLevel.xpRequiredForNextLevel - (xpLevel.totalXP - xpLevel.xpForCurrentLevel)) XP")
                        .font(AppFont.caption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    // MARK: - Fortschrittsbalken (einfarbig, kein Gradient)

    private var progressBarSection: some View {
        VStack(spacing: Space.s2) {
            HStack {
                Text("Fortschritt zum nächsten Level")
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", xpLevel.progressToNextLevel * 100))
                    .font(AppFont.callout)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(rankColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Theme.surfaceSunken)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(rankColor)
                        .frame(
                            width: progressVisible
                                ? geo.size.width * CGFloat(xpLevel.progressToNextLevel)
                                : 0,
                            height: 10
                        )
                }
            }
            .frame(height: 10)
        }
    }

    // MARK: - Letzte XP-Gewinne

    private var recentGainsSection: some View {
        VStack(alignment: .leading, spacing: Space.s2) {
            Text("Letzte XP-Gewinne")
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)

            ForEach(recentGains) { gain in
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.warning)
                        .frame(width: 14)

                    Text(gain.description)
                        .font(AppFont.callout)
                        .lineLimit(1)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text("+\(gain.xpAmount) XP")
                        .font(AppFont.callout)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(rankColor)

                    Text(gain.date.formatted(.dateTime.day().month()))
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("SummaryXPCard") {
    let level = XPLevel(
        level: 8, totalXP: 4200, xpForCurrentLevel: 3600,
        xpRequiredForNextLevel: 2250, rank: .athlet, progressToNextLevel: 0.27
    )
    let gains: [XPGain] = [
        XPGain(description: "Krafttraining", xpAmount: 165, date: Date().addingTimeInterval(-86400)),
        XPGain(description: "Laufen", xpAmount: 145, date: Date().addingTimeInterval(-2 * 86400)),
        XPGain(description: "Krafttraining", xpAmount: 172, date: Date().addingTimeInterval(-4 * 86400)),
        XPGain(description: "E-Bike Tour", xpAmount: 195, date: Date().addingTimeInterval(-6 * 86400))
    ]
    return SummaryXPCard(xpLevel: level, recentGains: gains)
        .padding()
        .background(Theme.surfaceApp)
        .environmentObject(AppSettings.shared)
}
