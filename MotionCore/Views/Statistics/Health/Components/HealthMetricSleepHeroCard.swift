//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsmetriken                                              /
// Datei . . . . : HealthMetricSleepHeroCard.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.11.2025                                                       /
// Beschreibung  : HealthMetricCard für Schlafphasen mit Fortschrittsbalken         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct HealthMetricSleepHeroCard: View {
    let sleepSummary: SleepStagesSummary

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    // Layout-Konstanten als enum
    private enum SleepProgressBar {
        static let iconColumnWidth: CGFloat = 22
        static let valueColumnWidth: CGFloat = 92
        static let rowSpacing: CGFloat = 8
        static let cardPadding: CGFloat = 20
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header + Hauptanzeige (immer sichtbar)
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schlafanalyse")
                            .font(AppFont.headline)
                            .foregroundStyle(Theme.textPrimary)

                        Text(formattedDate)
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()

                    // Expand/Collapse Icon
                    Image(systemName: "chevron.down.circle.fill")
                        .font(AppFont.title)
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                // Hauptanzeige: Gesamtschlaf
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .foregroundStyle(Theme.accent)
                            .font(AppFont.title)

                        Text(sleepSummary.formattedTotal)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.accent)

                        Text("Gesamtschlafzeit")
                            .font(AppFont.body.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(20)

            // MARK: - Erweiterte Ansicht (Phasen)
            if isExpanded {
                VStack(spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(Theme.line)
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    VStack(spacing: 14) {
                        // Zeit im Bett anzeigen, falls vorhanden
                        if let inBed = sleepSummary.inBedMinutes {
                            phaseRow(
                                icon: "bed.double.circle.fill",
                                color: Theme.series[0],
                                title: "Im Bett",
                                minutes: inBed,
                                percent: Double(sleepSummary.totalMinutes) > 0
                                ? Double(sleepSummary.totalMinutes) / Double(inBed)
                                : nil,
                                isEfficiencyRow: true
                            )
                        }

                        // Einzelne Schlafphasen (Anteile innerhalb der Schlafzeit)
                        ForEach(sleepSummary.phases) { phase in
                            let percentage = phase.percentage(of: sleepSummary.totalMinutes)
                            phaseRow(
                                icon: phase.systemIcon,
                                color: color(for: phase.name),
                                title: phase.name,
                                minutes: phase.minutes,
                                percent: percentage,
                                isEfficiencyRow: false
                            )
                        }
                    }
                    .padding(.horizontal, SleepProgressBar.cardPadding)

                    // Fortschrittsbalken über Phasen-Anteilen farblich im Verhältnis gekennzeichnet
                    if !sleepSummary.phases.isEmpty {
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                let totalWidth = geometry.size.width
                                let totalPhaseMinutes = sleepSummary.phases.reduce(0) { $0 + $1.minutes }                

                                ZStack(alignment: .leading) {
                                    // Background track (wie bei Calories)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.surfaceSunken)
                                        .frame(width: totalWidth)

                                    // Segmente füllen 100% (normalisiert)
                                    HStack(spacing: 0) {
                                        ForEach(sleepSummary.phases) { phase in
                                            let fraction = totalPhaseMinutes > 0
                                            ? Double(phase.minutes) / Double(totalPhaseMinutes)
                                            : 0

                                            Rectangle()
                                                .fill(color(for: phase.name).opacity(0.8))
                                                .frame(width: max(totalWidth * fraction, 0))
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .frame(height: 12)
                            .padding(.horizontal, SleepProgressBar.cardPadding)

                            // Legende
                            HStack(spacing: 12) {
                                ForEach(sleepSummary.phases) { phase in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(color(for: phase.name))
                                            .frame(width: 6, height: 6)
                                        Text(phase.name)
                                            .font(AppFont.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, SleepProgressBar.cardPadding)
                        }
                        .padding(.bottom, 16)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .card()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }


    // MARK: - Hilfsfunktionen

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: sleepSummary.date)
    }

    @ViewBuilder
    private func phaseRow(
        icon: String,
        color: Color,
        title: String,
        minutes: Int,
        percent: Double?,
        isEfficiencyRow: Bool
    ) -> some View {
        HStack(spacing: SleepProgressBar.rowSpacing) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: SleepProgressBar.iconColumnWidth, alignment: .leading)

            Text(title)
                .font(AppFont.body)
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedMinutes(minutes))
                    .font(AppFont.body.weight(.semibold))

                if let percent {
                    if isEfficiencyRow {
                            // z. B. 88% Schlaf-Effizienz
                        Text("\(Int(percent * 100))% Effizienz")
                            .font(AppFont.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("\(Int(percent * 100))%")
                            .font(AppFont.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .frame(width: SleepProgressBar.valueColumnWidth, alignment: .trailing)
        }
    }
    // Formatierung der Schlafphasen-Dauer (Stunden und Minuten)
    private func formattedMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return String(format: "%d h %02d min", h, m)
        } else {
            return String(format: "%d min", m)
        }
    }

    private func color(for sleepStageName: String) -> Color {
        switch sleepStageName.lowercased() {
            case "rem":
                return Theme.series[2]
            case "tiefschlaf", "deep":
                return Theme.series[0]
            case "kernschlaf", "core":
                return Theme.accent
            case "wach", "awake":
                return Theme.warning
            default:
                return Theme.textTertiary
        }
    }
}
