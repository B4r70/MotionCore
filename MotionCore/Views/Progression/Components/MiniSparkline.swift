//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                             /
// Datei . . . . : MiniSparkline.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Kompakte Inline-Sparkline für TrendPoint-Arrays                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct MiniSparkline: View {

    let data: [TrendPoint]
    var color: Color = .blue
    var lineWidth: CGFloat = 2

    // Mindestens 3 Datenpunkte für eine sinnvolle Sparkline
    private var hasEnoughData: Bool { data.count >= 3 }

    var body: some View {
        if hasEnoughData {
            sparklineShape
        } else {
            // Platzhalter wenn zu wenig Daten
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.2))
        }
    }

    // MARK: - Sparkline-Form

    private var sparklineShape: some View {
        GeometryReader { geo in
            let values = data.map(\.trendValue)
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let range = maxVal - minVal

            let path = buildPath(
                values: values,
                minVal: minVal,
                range: range,
                size: geo.size
            )

            path
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - Pfad-Berechnung

    private func buildPath(values: [Double], minVal: Double, range: Double, size: CGSize) -> Path {
        guard values.count >= 2 else { return Path() }

        let effectiveRange = range > 0 ? range : 1.0
        let stepX = size.width / CGFloat(values.count - 1)

        return Path { path in
            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * stepX
                // Y-Achse umkehren: hohe Werte oben
                let normalizedY = (value - minVal) / effectiveRange
                let y = size.height - CGFloat(normalizedY) * size.height

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("MiniSparkline") {
    let mockData: [TrendPoint] = [
        TrendPoint(trendDate: Date().addingTimeInterval(-5 * 86400), trendValue: 80),
        TrendPoint(trendDate: Date().addingTimeInterval(-4 * 86400), trendValue: 82.5),
        TrendPoint(trendDate: Date().addingTimeInterval(-3 * 86400), trendValue: 82),
        TrendPoint(trendDate: Date().addingTimeInterval(-2 * 86400), trendValue: 85),
        TrendPoint(trendDate: Date().addingTimeInterval(-1 * 86400), trendValue: 87.5)
    ]

    VStack(spacing: 20) {
        MiniSparkline(data: mockData, color: .green)
            .frame(width: 80, height: 32)

        MiniSparkline(data: mockData, color: .blue)
            .frame(width: 120, height: 24)

        // Zu wenig Daten (< 3)
        MiniSparkline(data: Array(mockData.prefix(2)), color: .orange)
            .frame(width: 80, height: 32)
    }
    .padding()
}
