//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Liste                                                    /
// Datei . . . . : WorkoutCard.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung von Cards für Workouts in ListView                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import SwiftUI

// Workout Card
struct WorkoutCard: View {
    let allWorkouts: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Device Badge
            HStack {
                // Device Icon mit Glas-Effekt
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    Image(systemName: allWorkouts.workoutDevice.symbol)
                        .font(.title3)
                        .foregroundStyle(allWorkouts.workoutDevice.tint)
                }
                // Anzeige Datum und Uhrzeit
                VStack(alignment: .leading, spacing: 2) {
                        // Datum
                    Text(allWorkouts.date.formatted(AppFormatters.dateGermanLong))
                        .font(.headline)
                        .foregroundStyle(.primary)

                        // Uhrzeit
                    Text(allWorkouts.date.formatted(AppFormatters.timeGermanLong))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                // Training Program Icon
                Image(systemName: allWorkouts.trainingProgram.symbol)
                    .font(.title3)
                    .foregroundStyle(allWorkouts.trainingProgram.tint)
            }
            .glassDivider(paddingTop: 5, paddingBottom: 2)

            // Stats Grid mit Icons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                // Workout-Dauer
                StatBubble(
                    icon: .system("clock.fill"),
                    value: allWorkouts.durationFormatted,
                    color: .blue
                )
                // Workout-Distanz
                StatBubble(
                    icon: .system("arrow.left.and.right"),
                    value: allWorkouts.distanceFormatted,
                    color: .green
                )
                // Workout-Geschwindigkeit
                StatBubble(
                    icon: .system("gauge.with.dots.needle.67percent"),
                    value: allWorkouts.averageSpeedFormatted,
                    color: .orange
                )
                // Workout-Herzfrequenz (Durchschnitt)
                StatBubble(
                    icon: .system("heart.fill"),
                    value: allWorkouts.heartRateFormatted,
                    color: .red
                )
                // Workout-Kalorien
                StatBubble(
                    icon: .system("flame.fill"),
                    value: allWorkouts.caloriesFormatted,
                    color: .orange
                )
                // Workout-METS
                StatBubble(
                    icon: .system("bolt.fill"),
                    value: allWorkouts.metsFormatted,
                    color: .yellow
                )
            }
            .glassDivider(paddingTop: 15, paddingBottom: 2)

            // Intensity Stars
            HStack(spacing: 4) {
                Text("Belastung:")
                    .font(.caption2)
                    .foregroundStyle(.primary)

                ForEach(0 ..< 5) { index in
                    Image(systemName: index < allWorkouts.intensity.rawValue ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < allWorkouts.intensity.rawValue ? allWorkouts.intensity.color : .gray.opacity(0.3))
                }

                Spacer()
            }
        }
        .glassCard()
    }
}
