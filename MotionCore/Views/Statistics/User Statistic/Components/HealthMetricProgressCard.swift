//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsdaten                                                 /
// Datei . . . . : HealthMetricProgressCard.swift                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.11.2025                                                       /
// Beschreibung  : HealthMetricCard mit Fortschrittsbalken                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct HealthMetricProgressCard: View {
    let icon: IconTypes
    let title: String
    let currentValue: Double
    let targetValue: Double
    let unit: String  // z.B. "kcal", "km", "min", "Schritte"
    let color: Color
    let showPercentage: Bool  // Optional: Prozentwert anzeigen

        // Initializer mit Defaults
    init(
        icon: IconTypes,
        title: String,
        currentValue: Double,
        targetValue: Double,
        unit: String,
        color: Color,
        showPercentage: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.unit = unit
        self.color = color
        self.showPercentage = showPercentage
    }

    private var percentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    private var isOverTarget: Bool {
        currentValue > targetValue
    }

    var body: some View {
        VStack(spacing: 16) {
            // Icon
            IconType(icon: icon, color: color, size: 40)

                // Werte
            VStack(spacing: 4) {
                Text(formatValue(currentValue))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(isOverTarget ? .green : .primary)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

                // Fortschrittsbalken
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                            // Hintergrund
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)

                            // Fortschritt
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isOverTarget
                                    ? [.green, .mint]
                                    : [color.opacity(0.7), color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * percentage, height: 12)
                            .animation(.spring(response: 0.6), value: percentage)
                    }
                }
                .frame(height: 12)

                    // Label unter dem Balken
                HStack {
                    Text("0")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("Ziel: \(formatValue(targetValue))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // Prozentwert (optional)
            if showPercentage {
                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.caption.bold())
                    .foregroundStyle(isOverTarget ? .green : color)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // Formatierung der Werte mit Einheit
    private func formatValue(_ value: Double) -> String {
            // Ganzzahlen ohne Dezimalstellen
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value)) \(unit)"
        }
            // Sonst mit einer Dezimalstelle
        return String(format: "%.1f \(unit)", value)
    }
}

    // MARK: - Preview

#Preview("Verschiedene Metriken") {
    ScrollView {
        VStack(spacing: 20) {
                // Kalorien
            HealthMetricProgressCard(
                icon: .system("flame.fill"),
                title: "Aktive Kalorien / Grundumsatz",
                currentValue: 240,
                targetValue: 2000,
                unit: "kcal",
                color: .orange
            )

                // Schritte
            HealthMetricProgressCard(
                icon: .system("figure.walk"),
                title: "Schritte / Tagesziel",
                currentValue: 8450,
                targetValue: 10000,
                unit: "Schritte",
                color: .blue
            )

                // Distanz
            HealthMetricProgressCard(
                icon: .system("arrow.left.and.right"),
                title: "Gelaufene Distanz / Wochenziel",
                currentValue: 12.5,
                targetValue: 25.0,
                unit: "km",
                color: .green
            )

                // Trainingszeit
            HealthMetricProgressCard(
                icon: .system("clock.fill"),
                title: "Trainingszeit / Wochenziel",
                currentValue: 180,
                targetValue: 300,
                unit: "min",
                color: .purple,
                showPercentage: false
            )

                // Ziel überschritten
            HealthMetricProgressCard(
                icon: .system("flame.fill"),
                title: "Aktive Kalorien",
                currentValue: 2150,
                targetValue: 2000,
                unit: "kcal",
                color: .orange
            )
        }
        .padding()
    }
}
