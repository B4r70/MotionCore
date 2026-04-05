//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                             /
// Datei . . . . : LastWorkoutCompareCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Vergleich aktueller Stand vs. letztes Workout pro Übung          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct LastWorkoutCompareCard: View {

    // Aktueller Stand (aus aktiver Session oder aktuell angezeigter Session)
    let currentWeight: Double
    let currentReps: Int
    let currentVolume: Double

    // Letztes Workout-Snapshot
    let lastSnapshot: SessionSnapshot?

    // Chart-Daten für 1RM-Sparkline (nur wenn kein Körpergewicht)
    let oneRMData: [TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(Color.blue)
                Text("Vergleich letztes Training")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 4)

            // Vergleichs-Zeile: Gewicht
            compareRow(
                icon: "scalemass.fill",
                iconColor: Color.orange,
                label: "Gewicht",
                current: weightDisplayText(weight: currentWeight),
                last: lastSnapshot.map { weightDisplayText(weight: $0.weight) },
                delta: weightDelta
            )

            GlassDivider()

            // Vergleichs-Zeile: Mindest-Wdh.
            compareRow(
                icon: "repeat.circle.fill",
                iconColor: .blue,
                label: "Mindest-Wdh.",
                current: "\(currentReps)",
                last: lastSnapshot.map { "\($0.minReps)" },
                delta: repsDelta
            )

            GlassDivider()

            // Vergleichs-Zeile: Volumen
            compareRow(
                icon: "chart.bar.fill",
                iconColor: Color.green,
                label: "Volumen",
                current: formatVolume(currentVolume),
                last: lastSnapshot.map { formatVolume($0.totalVolume) },
                delta: volumeDelta
            )

            // 1RM Sparkline (nur bei Gewichtsübungen mit genug Daten)
            if !isBodyweight && oneRMData.count >= 3 {
                GlassDivider()

                HStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.yellow)
                            .font(.caption)
                        Text("1RM-Trend")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    MiniSparkline(data: oneRMData, color: Color.yellow)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                }
                .padding(.horizontal, 4)
            }
        }
        .glassCard()
    }

    // MARK: - Berechnungen

    private var isBodyweight: Bool { currentWeight == 0 }

    private func weightDisplayText(weight: Double) -> String {
        weight == 0 ? "Körpergewicht" : String(format: "%.1f kg", weight)
    }

    private var weightDelta: DeltaInfo? {
        guard let last = lastSnapshot, !isBodyweight else { return nil }
        let diff = currentWeight - last.weight
        guard diff != 0 else { return nil }
        return DeltaInfo(value: diff, unit: "kg", positive: diff > 0)
    }

    private var repsDelta: DeltaInfo? {
        guard let last = lastSnapshot else { return nil }
        let diff = currentReps - last.minReps
        guard diff != 0 else { return nil }
        return DeltaInfo(value: Double(diff), unit: "", positive: diff > 0)
    }

    private var volumeDelta: DeltaInfo? {
        guard let last = lastSnapshot, currentVolume > 0, last.totalVolume > 0 else { return nil }
        let diff = currentVolume - last.totalVolume
        guard abs(diff) > 0.01 else { return nil }
        return DeltaInfo(value: diff, unit: "kg", positive: diff > 0)
    }

    private func formatVolume(_ v: Double) -> String {
        if v <= 0 { return "–" }
        if v >= 1000 { return String(format: "%.1fk", v / 1000) }
        return String(format: "%.0f kg", v)
    }

    // MARK: - Compare Row

    private func compareRow(
        icon: String,
        iconColor: Color,
        label: String,
        current: String,
        last: String?,
        delta: DeltaInfo?
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon + Label
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.caption)
                    .frame(width: 16)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 110, alignment: .leading)

            Spacer()

            // Letzter Wert
            if let last {
                Text(last)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("–")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Pfeil
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Aktueller Wert
            Text(current)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            // Delta-Badge (falls vorhanden)
            if let delta {
                deltaBadge(delta)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Delta Badge

    private struct DeltaInfo {
        let value: Double
        let unit: String
        let positive: Bool
    }

    @ViewBuilder
    private func deltaBadge(_ delta: DeltaInfo) -> some View {
        let sign = delta.positive ? "+" : ""
        let text = delta.unit.isEmpty
            ? "\(sign)\(Int(delta.value))"
            : String(format: "\(sign)%.1f \(delta.unit)", delta.value)

        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(delta.positive ? Color.green : Color.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                (delta.positive ? Color.green : Color.orange).opacity(0.15),
                in: Capsule()
            )
    }
}

// MARK: - Preview

#Preview("LastWorkoutCompareCard") {
    let mockSnapshot = SessionSnapshot(
        date: Date().addingTimeInterval(-7 * 86400),
        weight: 80,
        reps: [8, 8, 7],
        rpeValues: [8, 9, 9],
        totalVolume: 1880,
        estimatedOneRM: 100
    )

    let mockOneRM: [TrendPoint] = [
        TrendPoint(trendDate: Date().addingTimeInterval(-21 * 86400), trendValue: 95),
        TrendPoint(trendDate: Date().addingTimeInterval(-14 * 86400), trendValue: 97),
        TrendPoint(trendDate: Date().addingTimeInterval(-7 * 86400), trendValue: 100),
        TrendPoint(trendDate: Date().addingTimeInterval(-0 * 86400), trendValue: 103)
    ]

    VStack(spacing: 16) {
        // Normaler Fall: Gewicht vorhanden
        LastWorkoutCompareCard(
            currentWeight: 82.5,
            currentReps: 9,
            currentVolume: 2062.5,
            lastSnapshot: mockSnapshot,
            oneRMData: mockOneRM
        )

        // Körpergewicht-Fall
        LastWorkoutCompareCard(
            currentWeight: 0,
            currentReps: 8,
            currentVolume: 0,
            lastSnapshot: nil,
            oneRMData: []
        )
    }
    .padding()
}
