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
                .foregroundStyle(Color.green)

            if let exerciseName {
                Text("Übung \"\(exerciseName)\" abgeschlossen!")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }

            Text("Wähle die nächste Übung aus der Liste unten.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                        .font(.headline)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }
}
