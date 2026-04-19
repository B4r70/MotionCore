//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Muskel-Heatmap                                                   /
// Datei . . . . : MuscleHeatmapLegend.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : Kompakte Farbskala-Legende für die Muskel-Heatmap                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct MuscleHeatmapLegend: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.orange)
                Text("Trainingsintensität")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Trainingsintensitätsskala in blau
            HStack(spacing: 8) {
                Text("Wenig")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 3) {
                    ForEach(HeatLevel.allCases.filter { $0 != .none }, id: \.rawValue) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(level.color)
                            .frame(height: 14)
                    }
                }

                Text("Viel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
