//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body / BodyMeasurements                                  /
// Datei . . . . : BodyMeasurementsRadarCard.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Radar-Chart-Card für 6 Körpermaß-Achsen mit Timeframe-Picker    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - BodyMeasurementsRadarCard

struct BodyMeasurementsRadarCard: View {
    let measurements: [BodyMeasurement]

    @State private var timeframe: SummaryTimeframe = .month
    private let engine = BodyMeasurementRadarCalcEngine()

    private var data: BodyMeasurementRadarData {
        engine.computeRadar(measurements: measurements, timeframe: timeframe)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Körpermaße im Vergleich")
                .font(.headline)

            TimeframePicker(selection: $timeframe)

            RadarCanvas(data: data)
                .aspectRatio(1, contentMode: .fit)

            if data.previousPolygon == nil {
                Text("Mehr Daten für Vergleich nötig")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }
}

// MARK: - RadarCanvas

private struct RadarCanvas: View {
    let data: BodyMeasurementRadarData

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.70
            let count = data.axes.count

            func angle(for i: Int) -> Double {
                -.pi / 2 + (2 * .pi / Double(count)) * Double(i)
            }

            func unitVector(for i: Int) -> CGPoint {
                CGPoint(x: cos(angle(for: i)), y: sin(angle(for: i)))
            }

            func point(value: Double, axis i: Int) -> CGPoint {
                let uv = unitVector(for: i)
                return CGPoint(
                    x: center.x + uv.x * radius * value,
                    y: center.y + uv.y * radius * value
                )
            }

            // 1. Hilfslinien: 4 konzentrische Ringe
            for ring in [0.25, 0.5, 0.75, 1.0] {
                var ringPath = Path()
                for i in 0..<count {
                    let p = point(value: ring, axis: i)
                    if i == 0 { ringPath.move(to: p) } else { ringPath.addLine(to: p) }
                }
                ringPath.closeSubpath()
                ctx.stroke(ringPath, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
            }

            // 2. Achsen-Speichen
            for i in 0..<count {
                var spokePath = Path()
                spokePath.move(to: center)
                spokePath.addLine(to: point(value: 1.0, axis: i))
                ctx.stroke(spokePath, with: .color(.secondary.opacity(0.15)), lineWidth: 0.5)
            }

            // 3. Vergleichs-Polygon (untere Schicht)
            if let prev = data.previousPolygon {
                var prevPath = Path()
                for i in 0..<count {
                    let p = point(value: prev[i], axis: i)
                    if i == 0 { prevPath.move(to: p) } else { prevPath.addLine(to: p) }
                }
                prevPath.closeSubpath()
                ctx.fill(prevPath, with: .color(MCColor.mcBody.opacity(0.15)))
                ctx.stroke(prevPath, with: .color(MCColor.mcBody.opacity(0.50)), style: StrokeStyle(lineWidth: 1.5))
            }

            // 4. Aktuelles Polygon (obere Schicht)
            var currPath = Path()
            for i in 0..<count {
                let p = point(value: data.currentPolygon[i], axis: i)
                if i == 0 { currPath.move(to: p) } else { currPath.addLine(to: p) }
            }
            currPath.closeSubpath()
            ctx.fill(currPath, with: .color(MCColor.mcBody.opacity(0.30)))
            ctx.stroke(currPath, with: .color(MCColor.mcBody.opacity(0.70)), style: StrokeStyle(lineWidth: 2))
        }
        .overlay(alignment: .center) {
            // Achsen-Labels als SwiftUI-Text-Overlays über dem Canvas
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) / 2 * 0.70
                let labelRadius = radius * 1.20
                let count = data.axes.count

                ForEach(0..<count, id: \.self) { i in
                    let angle = -.pi / 2 + (2 * .pi / Double(count)) * Double(i)
                    let x = center.x + cos(angle) * labelRadius
                    let y = center.y + sin(angle) * labelRadius

                    Text(data.axes[i].label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BodyMeasurementsRadarCard(measurements: [])
        .padding()
}
