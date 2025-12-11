//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsmetriken                                              /
// Datei . . . . : HealthMetricSleepHeroCard.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.11.2025                                                       /
// Beschreibung  : HealthMetricCard mit Fortschrittsbalken                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct HealthMetricSleepHeroCard: View {
    let summary: SleepSummary

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header + Hauptanzeige (immer sichtbar)
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schlaf")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    // Expand/Collapse Icon
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }

                // Hauptanzeige: Gesamtschlaf
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .foregroundStyle(.indigo)
                            .font(.title2)

                        Text(summary.formattedTotal)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.caption)
                            .foregroundStyle(.indigo)

                        Text("Gesamtschlafzeit")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)

            // MARK: - Erweiterte Ansicht (Phasen)
            if isExpanded {
                VStack(spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(colorScheme == .light ? 0.2 : 0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    VStack(spacing: 14) {
                            // Optional: Zeit im Bett anzeigen, falls vorhanden
                        if let inBed = summary.inBedMinutes {
                            phaseRow(
                                icon: "bed.double.circle.fill",
                                color: .blue,
                                title: "Im Bett",
                                minutes: inBed,
                                percent: Double(summary.totalMinutes) > 0
                                ? Double(summary.totalMinutes) / Double(inBed)
                                : nil,
                                isEfficiencyRow: true
                            )
                        }

                            // Einzelne Schlafphasen (Anteile innerhalb der Schlafzeit)
                        ForEach(summary.phases) { phase in
                            let percentage = phase.percentage(of: summary.totalMinutes)
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
                    .padding(.horizontal, 20)

                    // Optional: kleiner Fortschrittsbalken über Phasen-Anteilen
                    if !summary.phases.isEmpty {
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                let totalWidth = geometry.size.width
                                HStack(spacing: 0) {
                                    ForEach(summary.phases) { phase in
                                        let fraction = phase.percentage(of: summary.totalMinutes)
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(color(for: phase.name).opacity(0.8))
                                            .frame(width: max(totalWidth * fraction, 0))
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(height: 12)

                            HStack(spacing: 12) {
                                ForEach(summary.phases) { phase in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(color(for: phase.name))
                                            .frame(width: 6, height: 6)
                                        Text(phase.name)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .glassCard()
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
        return formatter.string(from: summary.date)
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
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedMinutes(minutes))
                    .font(.subheadline.weight(.semibold))

                if let percent {
                    if isEfficiencyRow {
                        // z. B. 88% Schlaf-Effizienz
                        Text("\(Int(percent * 100))% Effizienz")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(Int(percent * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return String(format: "%dh %02dmin", h, m)
        } else {
            return String(format: "%dmin", m)
        }
    }

    private func color(for phaseName: String) -> Color {
        switch phaseName.lowercased() {
        case "rem":
            return .purple
        case "tiefschlaf", "deep":
            return .blue
        case "kernschlaf", "core":
            return .indigo
        case "wach", "awake":
            return .orange
        default:
            return .gray
        }
    }
}
