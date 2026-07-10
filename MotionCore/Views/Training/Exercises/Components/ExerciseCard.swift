//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ExerciseCard.swift                                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.12.2025                                                       /
// Beschreibung  : Formular zum Erstellen/Bearbeiten von Übungen                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Exercise Card Component

struct ExerciseCard: View {
    let exercise: Exercise
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // MP4 Thumbnail oder Placeholder
                ExerciseVideoView.forExercise(exercise, size: 80)

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        if exercise.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.success)
                        }

                        // Unilateral Badge
                        if exercise.isUnilateral {
                            Image(systemName: "hand.raised.fingers.spread.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                            // Video verfügbar Badge
                        if exercise.videoPath != nil {
                            Image(systemName: "play.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    // Kategorie & Equipment
                    HStack(spacing: 8) {
                        Label {
                            Text(exercise.category.description)
                                .font(.caption)
                        } icon: {
                            Image(systemName: exercise.category.icon)
                                .font(.caption2)
                        }
                        .foregroundStyle(Theme.textSecondary)

                        Label {
                            Text(exercise.equipment.description)
                                .font(.caption)
                        } icon: {
                            Image(systemName: exercise.equipment.icon)
                                .font(.caption2)
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }

                    // Bewegungsmuster & Position
                    HStack(spacing: 8) {
                        Label {
                            Text(exercise.movementPattern.description)
                                .font(.caption)
                        } icon: {
                            Image(systemName: exercise.movementPattern.icon)
                                .font(.caption2)
                        }
                        .foregroundStyle(Theme.textSecondary)

                        Label {
                            Text(exercise.bodyPosition.description)
                                .font(.caption)
                        } icon: {
                            Image(systemName: exercise.bodyPosition.icon)
                                .font(.caption2)
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }

                    // Muskelgruppen
                    if !exercise.primaryMuscles.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                                    Text(muscle.description)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.accentSoft)
                                        .foregroundStyle(Theme.accent)
                                        .clipShape(Capsule())
                                }

                                // Rep-Range Badge
                                Text(exercise.repRangeFormatted)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(repRangeColor(exercise.repRangeMax).opacity(0.2))
                                    .foregroundStyle(repRangeColor(exercise.repRangeMax))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Spacer()

                // Schwierigkeit
                VStack(spacing: 4) {
                    ForEach(0..<exercise.difficulty.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(difficultyColor)
                    }
                }
            }

            // Sicherheitshinweis anzeigen falls vorhanden
            if !exercise.cautionNote.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.warning)

                    Text(exercise.cautionNote)
                        .font(.caption)
                        .foregroundStyle(Theme.warning)
                        .lineLimit(2)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.warning.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .card()
        .overlay(alignment: .topTrailing) {
            if !exercise.isSystemExercise {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Theme.success, in: Circle())
                    .padding(8)
            }
        }
    }


    // Schwierigkeitsgrad → Theme-Farbe (Schwellen behalten)
    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .beginner:     return Theme.success    // leicht
        case .intermediate: return Theme.warning    // mittel
        case .advanced:     return Theme.series[3]  // hart (Amber)
        case .expert:       return Theme.danger     // sehr hart
        }
    }
}
