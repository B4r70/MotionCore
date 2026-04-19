//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryMuscleHeatmapCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Kompakte Muskel-Heatmap-Card mit Top-Muskelgruppen-Tags           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Muscle Heatmap Card

/// Zeigt die Muskel-Heatmap nur wenn mindestens 1 Set in der Analyse vorhanden ist.
struct SummaryMuscleHeatmapCard: View {

    let analysis: MuscleHeatmapAnalysis

    // MARK: - Body

    var body: some View {
        if analysis.totalSets > 0 {
            cardContent
        }
    }

    // MARK: - Card-Inhalt

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Überschrift
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.orange)
                Text("Trainierte Muskeln")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // SVG Heatmap mit vollem CSS-Heatmap-Farbspektrum
            MuscleHeatmapMiniSVGView(svgStylesCSS: analysis.svgStylesCSS)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Top-Muskelgruppen-Tags (max. 3)
            let topRegions = Array(analysis.topRegions.prefix(3))
            if !topRegions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topRegions) { region in
                            MuscleTag(region: region)
                        }
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Muskel-Tag

private struct MuscleTag: View {
    let region: MuscleHeatData

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(region.heatLevel.color)
                .frame(width: 8, height: 8)

            Text(region.displayName)
                .font(.caption2)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("SummaryMuscleHeatmapCard") {
    let emptyAnalysis = MuscleHeatmapAnalysis(
        timeframe: .week,
        analysisDate: Date(),
        regionData: [:],
        totalVolume: 0,
        totalSets: 0,
        totalFrequency: 0
    )

    let mockData: [String: MuscleHeatData] = [
        "quads": MuscleHeatData(
            id: "quads",
            svgRegionId: "quads",
            displayName: "Quadrizeps",
            totalVolume: 5000,
            totalSets: 12,
            totalFrequency: 4,
            relativeIntensity: 1.0,
            heatLevel: .high,
            lastTrainedDate: Date(),
            contributingMuscles: []
        ),
        "lats": MuscleHeatData(
            id: "lats",
            svgRegionId: "lats",
            displayName: "Latissimus",
            totalVolume: 3200,
            totalSets: 8,
            totalFrequency: 3,
            relativeIntensity: 0.64,
            heatLevel: .high,
            lastTrainedDate: Date(),
            contributingMuscles: []
        )
    ]

    let mockAnalysis = MuscleHeatmapAnalysis(
        timeframe: .week,
        analysisDate: Date(),
        regionData: mockData,
        totalVolume: 8200,
        totalSets: 20,
        totalFrequency: 4
    )

    VStack(spacing: 16) {
        // Leere Analyse — soll nichts rendern
        SummaryMuscleHeatmapCard(analysis: emptyAnalysis)
            .padding(.horizontal)

        // Analyse mit Daten
        SummaryMuscleHeatmapCard(analysis: mockAnalysis)
            .padding(.horizontal)
    }
    .padding(.vertical)
    .environmentObject(AppSettings.shared)
}
