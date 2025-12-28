///----------------------------------------------------------------------------------/
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
        case .cardio: return .blue
        case .strength: return .orange
        default: return .primary
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

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Start")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(plan.startDate, style: .date)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                if let end = plan.endDate {
                    HStack {
                        Text("Ende")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(end, style: .date)
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
}
