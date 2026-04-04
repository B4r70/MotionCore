//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryXPCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
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

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Rang + Level Kopfzeile
            headerSection

            // Fortschrittsbalken
            progressBarSection

            // Letzte XP-Gewinne
            if !recentGains.isEmpty {
                Divider().opacity(0.4)
                recentGainsSection
            }
        }
        .glassCard()
        .task {
            withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
                progressVisible = true
            }
        }
    }

    // MARK: - Kopfzeile

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Rang-Badge groß
            ZStack {
                Circle()
                    .fill(Color(hex: xpLevel.rank.colorHex).opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: xpLevel.rank.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(Color(hex: xpLevel.rank.colorHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(xpLevel.rank.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: xpLevel.rank.colorHex))

                Text("Level \(xpLevel.level)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(xpLevel.totalXP) XP gesamt")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Nächstes Level
            if !xpLevel.isMaxLevel {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("→ Level \(xpLevel.level + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(xpLevel.xpRequiredForNextLevel - (xpLevel.totalXP - xpLevel.xpForCurrentLevel)) XP")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Fortschrittsbalken

    private var progressBarSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Fortschritt zum nächsten Level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", xpLevel.progressToNextLevel * 100))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: xpLevel.rank.colorHex))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#C9E6FF"),
                                    Color(hex: xpLevel.rank.colorHex)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Letzte XP-Gewinne")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(recentGains) { gain in
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.yellow)
                        .frame(width: 14)

                    Text(gain.description)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("+\(gain.xpAmount) XP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: xpLevel.rank.colorHex))

                    Text(gain.date.formatted(.dateTime.day().month()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("SummaryXPCard") {
    let level = XPLevel(
        level: 8,
        totalXP: 4200,
        xpForCurrentLevel: 3600,
        xpRequiredForNextLevel: 2250,
        rank: .athlet,
        progressToNextLevel: 0.27
    )

    let gains: [XPGain] = [
        XPGain(description: "Krafttraining", xpAmount: 165, date: Date().addingTimeInterval(-86400)),
        XPGain(description: "Laufen", xpAmount: 145, date: Date().addingTimeInterval(-2 * 86400)),
        XPGain(description: "Krafttraining", xpAmount: 172, date: Date().addingTimeInterval(-4 * 86400)),
        XPGain(description: "E-Bike Tour", xpAmount: 195, date: Date().addingTimeInterval(-6 * 86400))
    ]

    SummaryXPCard(xpLevel: level, recentGains: gains)
        .padding()
        .environmentObject(AppSettings.shared)
}
