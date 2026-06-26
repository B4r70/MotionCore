//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : WorkoutCompletedCard.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Anzeige eines abgeschlossenen Trainings                          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct WorkoutCompletedCard: View {
    let onFinishWorkout: () -> Void
    let onAddExercise: (() -> Void)?  // ✅ NEU: Optional callback

    var body: some View {
        VStack(spacing: 20) {
            // Trophy: Theme.warning (Amber) für Erfolgs-Akzent
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.warning)

            Text("Alle Sätze abgeschlossen!")
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("Großartige Arbeit! Du kannst das Training jetzt beenden oder weitere Übungen hinzufügen.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            // Sekundäre Aktion: Übung hinzufügen
            if let onAddExercise {
                Button {
                    onAddExercise()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Weitere Übung")
                    }
                }
                .buttonStyle(.mcSecondary)
            }

            // Primäre Aktion: Training beenden
            Button {
                onFinishWorkout()
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Training beenden")
                }
            }
            .buttonStyle(.mcPrimary)
        }
        .card()
    }
}
