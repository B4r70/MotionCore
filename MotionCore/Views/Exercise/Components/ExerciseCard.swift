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
        .glassCard()
    }
}
