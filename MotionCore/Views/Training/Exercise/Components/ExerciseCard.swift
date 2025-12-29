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
                // GIF Thumbnail oder Placeholder
                ExerciseGifView(assetName: exercise.gifAssetName, size: 80)

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if exercise.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }

                        // Unilateral Badge
                        if exercise.isUnilateral {
                            Image(systemName: "hand.raised.fingers.spread.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
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
                        .foregroundStyle(.secondary)

                        Label {
                            Text(exercise.equipment.description)
                                .font(.caption)
                        } icon: {
                            Image(systemName: exercise.equipment.icon)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)

                        Label {
                            Text(exercise.bodyPosition.description)
                                .font(.caption)
                        } icon: {
                            Image(systemName: exercise.bodyPosition.icon)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
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
                                        .background(.blue.opacity(0.2))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }

                                // Rep-Range Badge
                                Text(exercise.repRangeFormatted)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(trainingTypeColor.opacity(0.2))
                                    .foregroundStyle(trainingTypeColor)
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
                            .foregroundStyle(Color(exercise.difficulty.color))
                    }
                }
            }

            // Sicherheitshinweis anzeigen falls vorhanden
            if !exercise.cautionNote.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Text(exercise.cautionNote)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .glassCard()
    }

    // Trainingstyp-Farbe basierend auf Rep-Range
    private var trainingTypeColor: Color {
        switch exercise.repRangeMax {
        case 1...3: return .red
        case 4...6: return .orange
        case 7...12: return .blue
        case 13...20: return .green
        default: return .teal
        }
    }
}
