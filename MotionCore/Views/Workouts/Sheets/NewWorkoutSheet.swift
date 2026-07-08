//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Sheets                                                           /
// Datei . . . . : WorkoutPickerSheet.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.12.2025                                                       /
// Beschreibung  : Auswahl-Sheet für den Workout-Typ beim Erstellen                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct NewWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Callbacks für die Auswahl
    var onCardioSelected: () -> Void
    var onStrengthSelected: () -> Void
    var onOutdoorSelected: () -> Void
    
    var body: some View {
        ZStack {
            // Flache Seitenfläche (Calm 2026 — kein AnimatedBackground)
            Theme.surfaceApp.ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Neues Training")
                        .font(AppFont.title)

                    Text("Wähle den Trainingstyp")
                        .font(AppFont.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 32)

                // Workout-Typ Buttons
                VStack(spacing: 12) {
                    WorkoutTypeButton(
                        icon: "figure.strengthtraining.traditional",
                        title: "Krafttraining",
                        subtitle: "Trainingsplan auswählen",
                        color: WorkoutType.strength.calmIconTint
                    ) {
                        onStrengthSelected()
                    }

                    WorkoutTypeButton(
                        icon: "figure.elliptical",
                        title: "Cardio",
                        subtitle: "Ausdauertraining erfassen",
                        color: WorkoutType.cardio.calmIconTint
                    ) {
                        onCardioSelected()
                    }

                    WorkoutTypeButton(
                        icon: "figure.outdoor.cycle",
                        title: "E-Bike Tour",
                        subtitle: "E-Bike Tour erfassen",
                        color: WorkoutType.outdoor.calmIconTint
                    ) {
                        onOutdoorSelected()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Workout Type Button

private struct WorkoutTypeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(isDisabled ? Theme.textSecondary : color)
                    .frame(width: 50)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(AppFont.headline)
                            .foregroundStyle(isDisabled ? Theme.textSecondary : Theme.textPrimary)

                        if isDisabled {
                            Text("Bald")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.textTertiary, in: Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            .card(padding: Space.s4)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

// MARK: - Preview

#Preview {
    NewWorkoutSheet(
        onCardioSelected: { print("Cardio") },
        onStrengthSelected: { print("Strength") },
        onOutdoorSelected: { print("Outdoor") }
    )
}
