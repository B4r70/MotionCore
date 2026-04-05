//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExerciseRatingBadge.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.04.2026                                                       /
// Beschreibung  : Kleines Inline-Badge für eine ExerciseQualityRating-Bewertung   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

/// Kleines Inline-Icon-Badge für eine Übungsbewertung.
/// Wird in Listen und Detail-Views als kompakter Indikator verwendet.
struct ExerciseRatingBadge: View {
    let rating: ExerciseQualityRating

    var body: some View {
        Image(systemName: rating.icon)
            .font(.caption)
            .foregroundStyle(rating.color)
    }
}

#Preview {
    HStack(spacing: 16) {
        ExerciseRatingBadge(rating: .poor)
        ExerciseRatingBadge(rating: .neutral)
        ExerciseRatingBadge(rating: .good)
    }
    .padding()
}
