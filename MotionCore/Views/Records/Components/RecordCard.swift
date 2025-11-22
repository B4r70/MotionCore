//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : RecordCard.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.11.2025                                                       /
// Beschreibung  : Darstellung von Cards für den Bereich Rekorde                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Record Card Component

struct RecordCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let allWorkouts: WorkoutSession

    var body: some View {
        VStack(spacing: 20) {
            // Header mit Icon
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(color)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            .glassDivider(paddingTop: 15, paddingBottom: 2, paddingHorizontal: 0)

            // Workout Details
            VStack(alignment: .leading, spacing: 12) {
                // Trainingsgerät mit Icon, Beschreibung und entsprechender Farbe
                RecordDetailRow(
                    icon: allWorkouts.workoutDevice.symbol,
                    label: "Gerät",
                    value: allWorkouts.workoutDevice.description,
                    color: allWorkouts.workoutDevice.tint
                )
                // Kalorien
                RecordDetailRow(
                    icon: "flame.fill",
                    label: "Kalorien",
                    value: "\(allWorkouts.calories) kcal",
                    color: .orange
                )
                // Dauer des Workouts
                RecordDetailRow(
                    icon: "clock.fill",
                    label: "Dauer",
                    value: "\(allWorkouts.duration) min",
                    color: .blue
                )
                // Zurückgelegte Distanz
                RecordDetailRow(
                    icon: "arrow.left.and.right",
                    label: "Distanz",
                    value: String(format: "%.2f km", allWorkouts.distance),
                    color: .green
                )
                // Datum des Workouts
                RecordDetailRow(
                    icon: "calendar",
                    label: "Datum",
                    value: allWorkouts.date.formatted(AppFormatters.dateGermanShort),
                    color: .purple
                )
            }
        }
        .glassCard()
    }
}

struct RecordGridCard: View {
    let metricTitle: String
    let recordValue: String
    let bestWorkout: WorkoutSession
    let metricIcon: String
    let metricColor: Color

    var body: some View {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 5) {
                    Image(systemName: metricIcon)
                        .font(.system(size: 30)) // Etwas größer für mehr Fokus
                        .foregroundStyle(metricColor)
                        .padding(.top, 10)

                    // Wert (Record Value) in groß
                    Text(recordValue)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    // Titel der Metrik
                    Text(metricTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Datum des Rekords (kompakt)
                    Text(bestWorkout.date.formatted(AppFormatters.dateGermanShort))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                // Stellt sicher, dass dieser VStack das Zentrum der Kachel einnimmt
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 2. ECKEN-ELEMENT (DeviceBadge)
                // Wird durch alignment: .topLeading in die obere linke Ecke platziert
                DeviceBadge(
                    device: bestWorkout.workoutDevice,
                    compact: true
                )
                .padding([.top, .leading], 1) // Abstand vom Rand der Card
            }
            // Einheitliche Größe und Card-Style
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
            .glassCard()
        }
    }
