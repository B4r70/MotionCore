//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Shared / Redesign                                        /
// Datei . . . . : MCSparkline.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               //
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Minimalistische Sparkline für Trendvisualisierungen              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - MCSparkline

struct MCSparkline: View {

    // MARK: Properties

    let data: [Double]
    let color: Color
    var showFill: Bool = true

    // MARK: Body

    var body: some View {
        if data.count < 2 {
            Color.clear
        } else {
            Canvas { ctx, size in
                guard let minVal = data.min(), let maxVal = data.max() else { return }
                let range  = maxVal - minVal

                // Punkte normalisieren; bei flachen Daten alle auf 0.5
                let points: [CGPoint] = data.enumerated().map { i, val in
                    let x = size.width * Double(i) / Double(data.count - 1)
                    let y: Double
                    if range == 0 {
                        y = size.height * 0.5
                    } else {
                        y = size.height * (1 - (val - minVal) / range)
                    }
                    return CGPoint(x: x, y: y)
                }

                // Linienpfad
                var linePath = Path()
                linePath.move(to: points[0])
                for pt in points.dropFirst() {
                    linePath.addLine(to: pt)
                }

                // Linie zeichnen
                ctx.stroke(
                    linePath,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )

                // Fill-Bereich
                if showFill {
                    var fillPath = linePath
                    fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
                    fillPath.addLine(to: CGPoint(x: 0, y: size.height))
                    fillPath.closeSubpath()
                    ctx.fill(fillPath, with: .color(color.opacity(0.18)))
                }
            }
            .frame(width: 70, height: 24)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Aufsteigend
        MCSparkline(
            data: [10, 20, 35, 42, 55, 70, 85],
            color: MCColor.mcBody
        )
        .frame(width: 120, height: 36)

        // Zufällig / volatil
        MCSparkline(
            data: [60, 30, 75, 20, 90, 45, 65],
            color: MCColor.mcEnergy
        )
        .frame(width: 120, height: 36)

        // Absturz
        MCSparkline(
            data: [80, 75, 70, 40, 20, 10, 5],
            color: MCColor.mcStreak,
            showFill: false
        )
        .frame(width: 120, height: 36)
    }
    .padding()
}
