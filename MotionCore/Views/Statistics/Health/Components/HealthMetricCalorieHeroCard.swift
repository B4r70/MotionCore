//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsmetriken                                              /
// Datei . . . . : HealthMetricCalorieHeroCard.swift                                /
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
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kalorienbilanz")
                                .font(AppFont.headline)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        Spacer()

                        // Expand/Collapse Icon
                        Image(systemName: "chevron.down.circle.fill")
                            .font(AppFont.title)
                            .foregroundStyle(Theme.accent)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }

                    // Hauptanzeige: Bilanz
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(calorieBalance.isDeficit ? "+" : "-")
                                .font(.system(size: 35, weight: .semibold))
                                .foregroundStyle(calorieBalance.isDeficit ? Theme.success : Theme.danger)

                            Text("\(abs(calorieBalance.balance))")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(calorieBalance.isDeficit ? Theme.success : Theme.danger)

                            Text("kcal")
                                .font(AppFont.title)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.leading, 4)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: calorieBalance.isDeficit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(AppFont.callout)
                                .foregroundStyle(calorieBalance.isDeficit ? Theme.success : Theme.danger)

                            Text(calorieBalance.isDeficit ? "Kaloriendefizit" : "Kalorienüberschuss")
                                .font(AppFont.body.weight(.medium))
                                .foregroundStyle(calorieBalance.isDeficit ? Theme.success : Theme.danger)
                        }
                    }
                }
                .padding(20)

            // MARK: - Erweiterte Ansicht (nur wenn ausgeklappt)
            if isExpanded {
                VStack(spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(Theme.line)
                        .frame(height: 1)
                        .padding(.horizontal, 20)

                    VStack(spacing: 16) {
                        // Eingenommene Kalorien
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .foregroundStyle(Theme.success)

                                Text("Aufnahme")
                                    .font(AppFont.body)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(calorieBalance.consumedCalories) kcal")
                                .font(AppFont.body.weight(.semibold))
                        }
                        // Grundumsatz
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.circle.fill")
                                    .foregroundStyle(Theme.warning)

                                Text("Grundumsatz")
                                    .font(AppFont.body)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(calorieBalance.basalEnergy) kcal")
                                .font(AppFont.body.weight(.semibold))
                        }
                        // Aktive Kalorien
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.run.circle.fill")
                                    .foregroundStyle(Theme.series[0])

                                Text("Aktivität")
                                    .font(AppFont.body)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("\(calorieBalance.activeEnergy) kcal")
                                .font(AppFont.body.weight(.semibold))
                        }
                        // Trennlinie
                        Rectangle()
                            .fill(Theme.line)
                            .frame(height: 0.5)

                        // Gesamtverbrauch
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "sum")
                                    .foregroundStyle(Theme.series[2])
                                Text("Gesamtverbrauch")
                                    .font(AppFont.body.weight(.medium))
                            }
                            Spacer()
                            Text("\(calorieBalance.totalBurned) kcal")
                                .font(AppFont.body.weight(.bold))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Visueller Fortschrittsbalken
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Hintergrund (Gesamtverbrauch)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.warning.opacity(0.15))

                                // Verbrauchte Kalorien
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(calorieBalance.consumedPercentage > 1.0 ? Theme.danger : Theme.success)
                                    .frame(width: geometry.size.width * min(calorieBalance.consumedPercentage, 1.0))
                            }
                        }
                        .frame(height: 16)

                        // Legende unter dem Balken
                        HStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.success)
                                    .frame(width: 8, height: 8)

                                Text("Aufnahme")
                                    .font(AppFont.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()

                            Text("\(Int(calorieBalance.consumedPercentage * 100))%")
                                .font(AppFont.caption.weight(.semibold))
                                .foregroundStyle(calorieBalance.consumedPercentage > 1.0 ? Theme.danger : Theme.success)
                            Spacer()

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.warning)
                                    .frame(width: 8, height: 8)

                                Text("Verbrauch")
                                    .font(AppFont.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .card()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - CalorieBalance UI-Erweiterung
// Farb-Eigenschaft in SwiftUI-Schicht, da Color ein SwiftUI-Typ ist

extension CalorieBalance {
    // Farbe für die Bilanz-Anzeige
    var statusColor: Color {
        isDeficit ? Theme.success : Theme.danger
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

    VStack(spacing: 20) {
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
