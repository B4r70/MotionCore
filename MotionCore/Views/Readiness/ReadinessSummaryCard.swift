//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Readiness                                                        /
// Datei . . . . : ReadinessSummaryCard.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Kompakte Readiness-Info-Card in der SummaryView (Phase 2)        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ReadinessSummaryCard: View {

    let readiness: SessionReadiness

    private var score: Int { readiness.overallScore }
    private var isCalibrating: Bool { readiness.isCalibrating }
    private var label: ReadinessLabel { ReadinessLabel.from(score: score) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if isCalibrating {
                calibratingRow
            } else {
                scoreRow
                factorRows
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: isCalibrating ? "clock.badge.questionmark" : label.systemIcon)
                .foregroundStyle(isCalibrating ? .yellow : label.color)
                .font(.title3)
            Text("Tagesform")
                .font(.headline)
        }
    }

    // MARK: - Kalibrierungshinweis

    private var calibratingRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Kalibrierung läuft")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Noch zu wenig Daten — weiter trainieren, um den Score zu verfeinern.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Score-Zeile

    private var scoreRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(score)")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(label.color)
            Text("/ 100")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(label.localizedTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(label.color)
        }
    }

    // MARK: - Faktoren-Zeilen (HRV, Schlaf, Ruhepuls)

    @ViewBuilder
    private var factorRows: some View {
        let factors = availableFactors
        if !factors.isEmpty {
            Divider()
            VStack(spacing: 6) {
                ForEach(factors, id: \.name) { factor in
                    FactorMiniRow(factor: factor)
                }
            }
        }
    }

    private var availableFactors: [(name: String, icon: String, score: Double)] {
        var result: [(name: String, icon: String, score: Double)] = []
        if let hrv = readiness.hrvScore {
            result.append((name: "HRV", icon: "waveform.path.ecg", score: hrv))
        }
        if let sleep = readiness.sleepScore {
            result.append((name: "Schlaf", icon: "bed.double.fill", score: sleep))
        }
        if let rhr = readiness.restingHRScore {
            result.append((name: "Ruhepuls", icon: "heart.fill", score: rhr))
        }
        return result
    }
}

// MARK: - Hilfselement: kompakte Faktor-Zeile

private struct FactorMiniRow: View {

    let factor: (name: String, icon: String, score: Double)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: factor.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(factor.name)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            // Kleiner Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemFill))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * factor.score, height: 4)
                }
            }
            .frame(width: 60, height: 4)
        }
    }

    private var barColor: Color {
        switch factor.score {
        case 0..<0.35:  return .red
        case 0.35..<0.55: return .orange
        case 0.55..<0.75: return .yellow
        default:          return .green
        }
    }
}

// MARK: - Preview

#Preview("Good — mit Faktoren") {
    let r = SessionReadiness()
    r.overallScore = 78
    r.isCalibrating = false
    r.hrvScore = 0.82
    r.sleepScore = 0.65
    r.restingHRScore = 0.70
    return ReadinessSummaryCard(readiness: r)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Niedrig") {
    let r = SessionReadiness()
    r.overallScore = 28
    r.isCalibrating = false
    r.hrvScore = 0.20
    r.sleepScore = 0.30
    return ReadinessSummaryCard(readiness: r)
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Kalibrierung") {
    let r = SessionReadiness()
    r.isCalibrating = true
    return ReadinessSummaryCard(readiness: r)
        .padding()
        .background(Color(.systemGroupedBackground))
}
