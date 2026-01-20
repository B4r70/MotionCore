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
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text("Alle Sätze abgeschlossen!")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("Großartige Arbeit! Du kannst das Training jetzt beenden oder weitere Übungen hinzufügen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // ✅ NEU: Weitere Übung Button
            if let onAddExercise {
                Button {
                    onAddExercise()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Weitere Übung")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                }
            }

            Button {
                onFinishWorkout()
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("Training beenden")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.green, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }
}
