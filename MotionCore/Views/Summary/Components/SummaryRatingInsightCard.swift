//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryRatingInsightCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.04.2026                                                       /
// Beschreibung  : Zeigt auffällige Bewertungsmuster in der Summary-View an         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Karte in der SummaryView die auffällige Bewertungsmuster anzeigt.
/// Maximal 3 Insights werden dargestellt (CalcEngine liefert bereits priorisiert).
struct SummaryRatingInsightCard: View {
    let insights: [RatingInsightCalcEngine.ExerciseInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.headline)
                    .foregroundStyle(Color.purple)

                Text("Übungs-Insights")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            // Maximal 3 Insights anzeigen
            ForEach(insights.prefix(3)) { insight in
                insightRow(insight)
            }
        }
        .glassCard()
    }

    // MARK: - Insight-Zeile

    private func insightRow(_ insight: RatingInsightCalcEngine.ExerciseInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon je nach Insight-Typ
            ZStack {
                Circle()
                    .fill(insightColor(insight.insightType).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: insightIcon(insight.insightType))
                    .font(.subheadline)
                    .foregroundStyle(insightColor(insight.insightType))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                Text(insight.suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Hilfsmethoden

    private func insightColor(_ type: RatingInsightCalcEngine.InsightType) -> Color {
        switch type {
        case .struggling: return Color.red
        case .thriving:   return Color.green
        }
    }

    private func insightIcon(_ type: RatingInsightCalcEngine.InsightType) -> String {
        switch type {
        case .struggling: return "exclamationmark.triangle.fill"
        case .thriving:   return "star.fill"
        }
    }
}

#Preview {
    SummaryRatingInsightCard(insights: [
        RatingInsightCalcEngine.ExerciseInsight(
            exerciseName: "Bankdrücken",
            exerciseGroupKey: "bench_press",
            insightType: .struggling,
            consecutiveCount: 3,
            suggestion: "Bankdrücken war 3× hintereinander schlecht. Überprüfe Technik, Gewicht oder Erholung."
        ),
        RatingInsightCalcEngine.ExerciseInsight(
            exerciseName: "Klimmzüge",
            exerciseGroupKey: "pullups",
            insightType: .thriving,
            consecutiveCount: 3,
            suggestion: "Klimmzüge lief 3× hintereinander gut. Bereit für eine Steigerung?"
        )
    ])
    .padding()
}
