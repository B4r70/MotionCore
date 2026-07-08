//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanInfoCard.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Header-Card mit Plan-Info für Detailansicht                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PlanInfoCard: View {
    let plan: TrainingPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header mit Icon und Status
            headerSection

            // Beschreibung (falls vorhanden)
            if !plan.planDescription.isEmpty {
                Text(plan.planDescription)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.subheadline)
            }

            Divider()

            // Datum-Informationen
            dateSection
        }
        .card()
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            // Icon-Tile: Hintergrund und Akzentfarbe aus PlanType
            ZStack {
                Circle()
                    .fill(plan.planType.calmTileBackground)
                    .frame(width: 50, height: 50)

                IconType(
                    icon: .system(plan.planType.icon),
                    color: plan.planType.calmTint,
                    size: 24
                )
            }

            // Titel und Typ
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text(plan.planType.description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            // Status-Badge
            statusBadge
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: plan.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                .foregroundStyle(plan.isActive ? Theme.success : Theme.textSecondary)
            Text(plan.isActive ? "Aktiv" : "Inaktiv")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Startdatum")
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(plan.startDate.formatted(AppFormatters.dateGermanLong))
                    .foregroundStyle(Theme.textPrimary)
                    .fontWeight(.semibold)
            }

            if let end = plan.endDate {
                HStack {
                    Text("Enddatum")
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(end.formatted(AppFormatters.dateGermanLong))
                        .foregroundStyle(Theme.textPrimary)
                        .fontWeight(.semibold)
                }

                // Verbleibende Tage
                if let daysRemaining = daysUntilEnd(end) {
                    HStack {
                        Text("Verbleibend")
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(daysRemaining > 0 ? "\(daysRemaining) Tage" : "Abgelaufen")
                            .foregroundStyle(daysRemaining > 0 ? Theme.textPrimary : Theme.danger)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Hilfsfunktionen

    private func daysUntilEnd(_ endDate: Date) -> Int? {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day
    }
}

// MARK: - Preview

#Preview("Plan Info Card") {
    ZStack {
        Theme.surfaceApp.ignoresSafeArea()

        VStack(spacing: 16) {
            PlanInfoCard(plan: TrainingPlan(
                title: "Push Day A",
                planDescription: "Brust, Schultern und Trizeps Training",
                endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                planType: .strength
            ))

            PlanInfoCard(plan: TrainingPlan(
                title: "Cardio Woche",
                planType: .cardio,
                isActive: false
            ))
        }
        .padding()
    }
}
