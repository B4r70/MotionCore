//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExerciseCompletedCard.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Anzeige einer abgeschlossenen Übung                              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ExerciseCompletedCard: View {
    let exerciseName: String?
    let exerciseGroupKey: String?
    let existingRating: ExerciseQualityRating?
    let onRate: (ExerciseQualityRating) -> Void
    let onNextExercise: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.success)

            if let exerciseName {
                Text("Übung \"\(exerciseName)\" abgeschlossen!")
                    .font(AppFont.title)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            Text("Wähle die nächste Übung aus der Liste unten.")
                .font(AppFont.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            // Bewertungskarte — nur anzeigen wenn ein GroupKey vorhanden ist
            if let name = exerciseName, exerciseGroupKey != nil {
                ExerciseRatingCard(
                    exerciseName: name,
                    existingRating: existingRating,
                    onRate: onRate,
                    onSkip: {
                        // "Überspringen" → direkt zur nächsten Übung
                        withAnimation(.easeInOut) {
                            onNextExercise()
                        }
                    }
                )
            }

            Button {
                withAnimation(.easeInOut) {
                    onNextExercise()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Nächste Übung")
                }
            }
            .buttonStyle(.mcPrimary)
        }
        .card()
    }
}
