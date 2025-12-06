//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsdaten                                                 /
// Datei . . . . : HealthMetricHeroCard.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Darstellung einer mehrzeiligen Card für die Kalorienbilanz       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct HealthMetricHeroCard: View {
    let date: Date
    let calorieBalance: CalorieBalance

    @State private var isExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Kompakte Ansicht (immer sichtbar)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aktuelle Kalorienbilanz")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        // Expand/Collapse Icon
                        Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }

                    // Hauptanzeige: Bilanz
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(calorieBalance.isDeficit ? "+" : "-")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(calorieBalance.isDeficit ? .green : .red)

                            Text("\(abs(calorieBalance.balance))")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(calorieBalance.isDeficit ? .green : .red)

                            Text("kcal")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: calorieBalance.isDeficit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.caption)
                                .foregroundStyle(calorieBalance.isDeficit ? .green : .red)

                            Text(calorieBalance.isDeficit ? "Kaloriendefizit" : "Kalorienüberschuss")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(calorieBalance.isDeficit ? .green : .red)
                        }
                    }
                }
                .padding(20)
            }
            .buttonStyle(.plain)

            // MARK: - Erweiterte Ansicht (nur wenn ausgeklappt)
            if isExpanded {
                VStack(spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(colorScheme == .light ? 0.2 : 0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    VStack(spacing: 16) {
                        // Eingenommene Kalorien
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundStyle(.green)

                                Text("Aufnahme")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(calorieBalance.consumedCalories) kcal")
                                .font(.subheadline.weight(.semibold))
                        }

                        // Grundumsatz
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.circle.fill")
                                    .foregroundStyle(.orange)

                                Text("Grundumsatz")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(calorieBalance.basalEnergy) kcal")
                                .font(.subheadline.weight(.semibold))
                        }

                        // Aktive Kalorien
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.run.circle.fill")
                                    .foregroundStyle(.blue)

                                Text("Aktivität")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(calorieBalance.activeEnergy) kcal")
                                .font(.subheadline.weight(.semibold))
                        }

                        // Trennlinie
                        Rectangle()
                            .fill(Color.gray.opacity(colorScheme == .light ? 0.15 : 0.25))
                            .frame(height: 0.5)

                        // Gesamtverbrauch
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "sum")
                                    .foregroundStyle(.purple)

                                Text("Gesamtverbrauch")
                                    .font(.subheadline.weight(.medium))
                            }

                            Spacer()

                            Text("\(calorieBalance.totalBurned) kcal")
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Visueller Fortschrittsbalken
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Hintergrund (Gesamtverbrauch)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.orange.opacity(0.3),
                                                Color.purple.opacity(0.3)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                // Verbrauchte Kalorien
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: calorieBalance.consumedPercentage > 1.0
                                                ? [Color.red.opacity(0.7), Color.red]
                                                : [Color.green.opacity(0.7), Color.green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * min(calorieBalance.consumedPercentage, 1.0))
                            }
                        }
                        .frame(height: 16)

                        // Legende unter dem Balken
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)

                                Text("Aufnahme")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(Int(calorieBalance.consumedPercentage * 100))%")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(calorieBalance.consumedPercentage > 1.0 ? .red : .green)

                            Spacer()

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)

                                Text("Verbrauch")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .glassCard()
    }
}

// MARK: - Preview

#Preview("Hero Card - Interaktiv") {
    let balance1 = CalorieBalance(
        consumedCalories: 1800,
        basalEnergy: 1650,
        activeEnergy: 450,
        totalBurned: 2100,
        balance: 300,
        isDeficit: true,
        consumedPercentage: 0.857
    )

    let balance2 = CalorieBalance(
        consumedCalories: 2500,
        basalEnergy: 1650,
        activeEnergy: 450,
        totalBurned: 2100,
        balance: -400,
        isDeficit: false,
        consumedPercentage: 1.19
    )

    return VStack(spacing: 20) {
        HealthMetricHeroCard(
            date: Date(),
            calorieBalance: balance1
        )

        HealthMetricHeroCard(
            date: Date(),
            calorieBalance: balance2
        )
    }
    .padding()
}
