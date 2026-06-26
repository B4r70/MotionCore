//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TrainingPlanCard.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 19.12.2025                                                       /
// Beschreibung  : Card um einzelne Trainingsprogramme darzustellen                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct TrainingPlanCard: View {
    let plan: TrainingPlan

    // TODO: Sobald du echte Plan-Inhalte hast (z.B. Trainings/Einheiten),
    // kannst du hier Fortschritt berechnen.
    private var progress: Double { 0.0 }

    // Status-Icon je Fortschritt
    private var statusIcon: String {
        progress >= 1.0 ? "checkmark.circle.fill" : "clock.fill"
    }

    // Status-Farbe: Erfolg → success, ausstehend → warning
    private var statusColor: Color {
        progress >= 1.0 ? Theme.success : Theme.warning
    }

    // Anzahl der einzigartigen Übungen im Plan
    private var exerciseCount: Int {
        return plan.groupedTemplateSets.count
    }

    // Gesamtanzahl der Sätze im Plan
    private var totalSets: Int {
        return plan.safeTemplateSets.count
    }

    // Gesamtvolumen des Plans (Gewicht × Wiederholungen)
    private var totalVolume: Double {
        return plan.safeTemplateSets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                // Buchstaben-Tile: Initial des Plans auf weicher Typ-Tönung
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(plan.planType.calmTileBackground)
                        .frame(width: 46, height: 46)

                    Text(String(plan.title.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(plan.planType.calmTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(AppFont.headline)
                        .foregroundStyle(Theme.textPrimary)

                    if !plan.planDescription.isEmpty {
                        Text(plan.planDescription)
                            .font(AppFont.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    } else {
                        Text(plan.planType.description)
                            .font(AppFont.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }

            Divider()
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Statistiken (Übungen, Sätze & Volumen) — neutrale Metrik-Farbe series[0]
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                // Übungen
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.series[0])

                        Text("\(exerciseCount)")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.series[0])
                    }

                    Text("Übungen")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

                // Sätze
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "number.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.series[0])

                        Text("\(totalSets)")
                            .font(.title3.bold())
                            .foregroundStyle(Theme.series[0])
                    }

                    Text("Sätze")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

                // Volumen
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.series[0])

                        Text(formatVolume(totalVolume))
                            .font(.title3.bold())
                            .foregroundStyle(Theme.series[0])
                    }

                    Text("Volumen")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            }

            Divider()
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Start")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(plan.startDate.formatted(AppFormatters.dateGermanLong))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                if let end = plan.endDate {
                    HStack {
                        Text("Ende")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(end.formatted(AppFormatters.dateGermanLong))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }

                HStack {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: plan.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                            .foregroundStyle(plan.isActive ? Theme.success : Theme.textTertiary)
                        Text(plan.isActive ? "Aktiv" : "Inaktiv")
                            .foregroundStyle(Theme.textPrimary)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            Divider()
                .padding(.top, 12)
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                Button {
                    print("Plan starten/fortsetzen: \(plan.title)")
                } label: {
                    HStack {
                        Image(systemName: progress > 0 ? "play.circle.fill" : "play.fill")
                        Text(progress > 0 ? "Fortsetzen" : "Starten")
                    }
                }
                .buttonStyle(.mcSecondary)

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.accentSoft, in: Circle())
            }
        }
        .card()
    }

    // Formatiert das Volumen (kg)
    private func formatVolume(_ volume: Double) -> String {
        if volume <= 0 {
            return "–"
        } else if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - Preview

#Preview("Plan-Karte") {
    ZStack {
        Theme.surfaceApp.ignoresSafeArea()

        ScrollView {
            VStack(spacing: Space.s4) {
                TrainingPlanCard(plan: TrainingPlan(title: "Push Day", planType: .strength))
                TrainingPlanCard(plan: TrainingPlan(title: "Laufen", planType: .cardio))
                TrainingPlanCard(plan: TrainingPlan(title: "Wanderung", planType: .outdoor))
                TrainingPlanCard(plan: TrainingPlan(title: "Mixed Training", planType: .mixed))
            }
            .padding(Space.s4)
        }
    }
}
