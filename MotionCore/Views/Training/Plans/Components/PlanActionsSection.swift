//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanActionsSection.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Aktions-Buttons für Trainingsplan                                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PlanActionsSection: View {
    let plan: TrainingPlan
    let onStartWorkout: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    private var canStartWorkout: Bool {
        !plan.safeTemplateSets.isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            // Training starten oder Hinweis bei leerem Plan
            if canStartWorkout {
                startWorkoutButton
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                    Text("Füge zuerst Übungen zum Plan hinzu.")
                        .font(.subheadline)
                }
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .background(Theme.surfaceSunken)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }

            // Plan bearbeiten
            editPlanButton

            // Plan duplizieren
            duplicatePlanButton

            // Plan löschen
            deletePlanButton
        }
    }

    // MARK: - Subviews

    private var startWorkoutButton: some View {
        Button {
            onStartWorkout()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Training starten")
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        .buttonStyle(.mcPrimary)
    }

    private var editPlanButton: some View {
        NavigationLink {
            TrainingFormView(mode: .edit, plan: plan)
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Plan bearbeiten")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            // Akzentton des Plan-Typs als weiche Fläche
            .background(plan.planType.calmTileBackground)
            .foregroundStyle(plan.planType.calmTint)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var duplicatePlanButton: some View {
        Button {
            onDuplicate()
        } label: {
            HStack {
                Image(systemName: "doc.on.doc")
                Text("Plan duplizieren")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Theme.accentSoft)
            .foregroundStyle(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
    }

    private var deletePlanButton: some View {
        Button(role: .destructive) {
            onDelete()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Plan löschen")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Theme.danger.opacity(0.12))
            .foregroundStyle(Theme.danger)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
    }
}

// MARK: - Einzelne Action Row (wiederverwendbar)

struct PlanActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let showChevron: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String,
        color: Color,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.showChevron = showChevron
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
    }
}

// MARK: - Preview

#Preview("Plan Actions Section") {
    ZStack {
        Theme.surfaceApp.ignoresSafeArea()

        VStack(spacing: 20) {
            // Mit Übungen
            PlanActionsSection(
                plan: TrainingPlan(title: "Push Day", planType: .strength),
                onStartWorkout: { print("Start") },
                onDuplicate: { print("Duplicate") },
                onDelete: { print("Delete") }
            )
            .padding(.horizontal)

            Divider()

            // Einzelne Action Rows
            VStack(spacing: 12) {
                PlanActionRow(
                    title: "Duplizieren",
                    icon: "doc.on.doc",
                    color: Theme.accent
                ) { print("Duplicate") }

                PlanActionRow(
                    title: "Teilen",
                    icon: "square.and.arrow.up",
                    color: Theme.series[2],
                    showChevron: false
                ) { print("Share") }
            }
            .padding(.horizontal)
        }
    }
}
