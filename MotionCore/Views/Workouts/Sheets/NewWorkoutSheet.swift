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
    @EnvironmentObject private var appSettings: AppSettings
    
    // Callbacks für die Auswahl
    var onCardioSelected: () -> Void
    var onStrengthSelected: () -> Void
    var onOutdoorSelected: () -> Void
    
    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Neues Training")
                        .font(.title2.bold())
                    
                    Text("Wähle den Trainingstyp")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                // Workout-Typ Buttons
                VStack(spacing: 12) {
                    WorkoutTypeButton(
                        icon: "figure.strengthtraining.traditional",
                        title: "Krafttraining",
                        subtitle: "Trainingsplan auswählen",
                        color: .orange
                    ) {
                        onStrengthSelected()
                    }
                    
                    WorkoutTypeButton(
                        icon: "figure.elliptical",
                        title: "Cardio",
                        subtitle: "Ausdauertraining erfassen",
                        color: .green
                    ) {
                        onCardioSelected()
                    }
                    
                    WorkoutTypeButton(
                        icon: "figure.outdoor.cycle",
                        title: "Outdoor",
                        subtitle: "Aktivität im Freien",
                        color: .blue,
                        isDisabled: true
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
                    .foregroundStyle(isDisabled ? .secondary : color)
                    .frame(width: 50)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(isDisabled ? .secondary : .primary)
                        
                        if isDisabled {
                            Text("Bald")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.5), in: Capsule())
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
    .environmentObject(AppSettings.shared)
}
