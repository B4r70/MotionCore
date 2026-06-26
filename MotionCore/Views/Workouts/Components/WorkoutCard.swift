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
    let allWorkouts: CardioSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Device Badge
            HStack {
                // Cardio-Icon-Tile — einheitliches Tile je Workout-Typ
                WorkoutTypeIconTile(type: .cardio, systemImage: allWorkouts.cardioDevice.symbol)
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
                    .foregroundStyle(Theme.textSecondary)
            }
            Divider().padding(.top, 5).padding(.bottom, 2)

            // Stats Grid mit Icons
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                // Workout-Dauer — neutrale Zeitmetrik
                StatBubble(
                    icon: .system("clock.fill"),
                    value: allWorkouts.durationFormatted,
                    color: Theme.series[0]
                )
                // Workout-Distanz — neutrale Streckenmetrik
                StatBubble(
                    icon: .system("arrow.left.and.right"),
                    value: allWorkouts.distanceFormatted,
                    color: Theme.series[0]
                )
                // Workout-Geschwindigkeit — neutrale Tempoemetrik
                StatBubble(
                    icon: .system("gauge.with.dots.needle.67percent"),
                    value: allWorkouts.averageSpeedFormatted,
                    color: Theme.series[0]
                )
                // Workout-Herzfrequenz (Durchschnitt) — Puls → danger
                StatBubble(
                    icon: .system("heart.fill"),
                    value: allWorkouts.heartRateFormatted,
                    color: Theme.danger
                )
                // Workout-Kalorien — Energie → warning
                StatBubble(
                    icon: .system("flame.fill"),
                    value: allWorkouts.caloriesFormatted,
                    color: Theme.warning
                )
                // Workout-METS — neutrale Aktivitätsmetrik
                StatBubble(
                    icon: .system("bolt.fill"),
                    value: allWorkouts.metsFormatted,
                    color: Theme.series[0]
                )
            }
            Divider().padding(.top, 15).padding(.bottom, 2)

            // Intensity Stars — neutral, kein Ampel-Ton
            HStack(spacing: 4) {
                Text("Belastung:")
                    .font(.caption2)
                    .foregroundStyle(.primary)

                ForEach(0 ..< 5) { index in
                    Image(systemName: index < allWorkouts.intensity.rawValue ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(index < allWorkouts.intensity.rawValue ? Theme.textSecondary : Theme.line)
                }

                Spacer()
            }
        }
        .card()
    }
}
