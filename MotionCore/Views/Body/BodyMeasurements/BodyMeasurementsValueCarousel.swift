//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body / BodyMeasurements                                  /
// Datei . . . . : BodyMeasurementsValueCarousel.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : 7-Card-Karussell für Körpermaß-Übersicht mit Hero-Wert           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Charts
import SwiftData
import SwiftUI

// MARK: - MeasureType

/// Die 7 dargestellten Maß-Typen im Karussell
private enum MeasureType: CaseIterable {
    case weight
    case chest
    case waist
    case abdomen
    case hip
    case armAvg
    case thighAvg

    var title: String {
        switch self {
        case .weight:   return "Körpergewicht"
        case .chest:    return "Brustumfang"
        case .waist:    return "Taillenumfang"
        case .abdomen:  return "Bauchmaß"
        case .hip:      return "Hüftumfang"
        case .armAvg:   return "Armumfang (Ø)"
        case .thighAvg: return "Oberschenkel (Ø)"
        }
    }

    var unit: String {
        switch self {
        case .weight: return "kg"
        default:      return "cm"
        }
    }

    var keyPath: KeyPath<BodyMeasurement, Double?> {
        switch self {
        case .weight:   return \.bodyWeight
        case .chest:    return \.chestCircumference
        case .waist:    return \.waistCircumference
        case .abdomen:  return \.abdomenCircumference
        case .hip:      return \.hipCircumference
        case .armAvg:   return \.armCircumferenceAverage
        case .thighAvg: return \.thighCircumferenceAverage
        }
    }
}

// MARK: - MeasurementDetailContext

private struct MeasurementDetailContext: Identifiable {
    let id = UUID()
    let title: String
    let unit: String
    let keyPath: KeyPath<BodyMeasurement, Double?>
}

// MARK: - BodyMeasurementsValueCarousel

struct BodyMeasurementsValueCarousel: View {
    let measurements: [BodyMeasurement]
    private let engine = BodyMeasurementTrendCalcEngine()

    @State private var detailContext: MeasurementDetailContext?

    var body: some View {
        TabView {
            ForEach(MeasureType.allCases, id: \.self) { type in
                let trend = engine.trend(for: measurements, keyPath: type.keyPath)
                let sparkline = engine.sparklineData(for: measurements, keyPath: type.keyPath)
                BodyMeasurementHeroCard(type: type, trend: trend, sparkline: sparkline)
                    .onTapGesture {
                        detailContext = MeasurementDetailContext(
                            title: type.title,
                            unit: type.unit,
                            keyPath: type.keyPath
                        )
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 280)
        .sheet(item: $detailContext) { context in
            BodyMeasurementHistorySheet(
                title: context.title,
                unit: context.unit,
                keyPath: context.keyPath,
                measurements: measurements
            )
            .environmentObject(AppSettings.shared)
        }
    }
}

// MARK: - BodyMeasurementHeroCard

private struct BodyMeasurementHeroCard: View {
    let type: MeasureType
    let trend: BodyMeasurementTrend
    let sparkline: [(Date, Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header
            HStack(alignment: .top) {
                Text(type.title)
                    .font(.headline)
                Spacer()
                DeltaPill(trend: trend, unit: type.unit)
            }

            // Großer Wert
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 56, weight: .light, design: .rounded))
                Text(type.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Sparkline
            if sparkline.count >= 2 {
                Chart(sparkline, id: \.0) { item in
                    LineMark(
                        x: .value("Datum", item.0),
                        y: .value(type.unit, item.1)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 50)
            } else {
                Text("Mehr Daten nötig")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(height: 50)
            }

            // Footer
            Text(footerText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Hilfsfunktionen

    private var formattedValue: String {
        guard let v = trend.currentValue else { return "–" }
        return String(format: "%.1f", v)
    }

    private var footerText: String {
        guard let d = trend.currentDate else { return "Noch keine Messung" }
        return "Letzte Messung: \(d.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE"))))"
    }
}

// MARK: - DeltaPill

private struct DeltaPill: View {
    let trend: BodyMeasurementTrend
    let unit: String

    var body: some View {
        if let delta = trend.absoluteDelta {
            let sign = delta >= 0 ? "+" : ""
            Text("\(sign)\(String(format: "%.1f", delta)) \(unit)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(pillColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var pillColor: Color {
        switch trend.direction {
        case .up:              return .green
        case .down:            return .red
        case .stable, .unknown: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    BodyMeasurementsValueCarousel(measurements: [])
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
