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

    private var statusIcon: String {
        progress >= 1.0 ? "checkmark.circle.fill" : "clock.fill"
    }

    private var statusColor: Color {
        progress >= 1.0 ? .green : .orange
    }

    private var planAccent: Color {
        switch plan.planType {
            case .cardio: return .green
            case .strength: return .red
            default: return .primary
        }
    }

    // Anzahl der einzigartigen Übungen im Plan
    private var exerciseCount: Int {
        return plan.groupedTemplateSets.count
    }

    // Gesamtanzahl der Sätze im Plan
    private var totalSets: Int {
        return plan.templateSets.count
    }

    // Gesamtvolumen des Plans (Gewicht × Wiederholungen)
    private var totalVolume: Double {
        return plan.templateSets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)

                    IconType(
                        icon: .system(plan.planType.icon),
                        color: planAccent,
                        size: 24
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if !plan.planDescription.isEmpty {
                        Text(plan.planDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(plan.planType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }

            .glassDivider(paddingTop: 12, paddingBottom: 8)

            // Statistiken (Übungen, Sätze & Volumen)
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
                            .foregroundStyle(planAccent)

                        Text("\(exerciseCount)")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }

                    Text("Übungen")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    // Sätze
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "number.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(planAccent)

                        Text("\(totalSets)")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }

                    Text("Sätze")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    // Volumen
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption2)
                            .foregroundStyle(planAccent)

                        Text(formatVolume(totalVolume))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }

                    Text("Volumen")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            .glassDivider(paddingTop: 12, paddingBottom: 8)


            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Start")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(plan.startDate.formatted(AppFormatters.dateGermanLong))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                if let end = plan.endDate {
                    HStack {
                        Text("Ende")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(end.formatted(AppFormatters.dateGermanLong))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }

                HStack {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: plan.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                            .foregroundStyle(plan.isActive ? .green : .secondary)
                        Text(plan.isActive ? "Aktiv" : "Inaktiv")
                            .foregroundStyle(.primary)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }

            .glassDivider(paddingTop: 12, paddingBottom: 8)

            HStack(spacing: 12) {
                Button {
                    print("Plan starten/fortsetzen: \(plan.title)")
                } label: {
                    HStack {
                        Image(systemName: progress > 0 ? "play.circle.fill" : "play.fill")
                        Text(progress > 0 ? "Fortsetzen" : "Starten")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(planAccent.opacity(0.15))
                    .foregroundStyle(planAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(planAccent)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .glassCard()
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
