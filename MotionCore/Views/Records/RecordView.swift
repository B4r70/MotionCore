//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : RecordView.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Rekorde                             /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct RecordView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    @ObservedObject private var settings = AppSettings.shared

    private var calcRecords: RecordCalcEngine {
        RecordCalcEngine(workouts: allWorkouts)
    }

        // Anzahl der Cards je Zeile im Grid
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
                // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                        // Beste Leistung nach Distanz auf dem Crosstrainer
                    if let bestCrosstrainer = calcRecords.bestCrosstrainerWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Längste Distanz auf dem Crosstrainer",
                            icon: bestCrosstrainer.workoutDevice.symbol,
                            color: bestCrosstrainer.workoutDevice.tint,
                            allWorkouts: bestCrosstrainer
                        )
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                        // Beste Leistung nach Distanz auf dem Ergometer
                    if let bestErgometer = calcRecords.bestErgometerWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Längste Distanz auf dem Ergometer",
                            icon: bestErgometer.workoutDevice.symbol,
                            color: bestErgometer.workoutDevice.tint,
                            allWorkouts: bestErgometer
                        )
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    // Doppeltes Grid-Layout für andere Rekorde
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                            // Absoluter Distanz-Rekord
                        if let longestDistance = calcRecords.longestDistanceWorkout {
                            RecordGridCard(
                                metricTitle: "Längste Distanz",
                                recordValue: String(format: "%.2f km", longestDistance.distance),
                                bestWorkout: longestDistance,
                                metricIcon: "arrow.left.and.right",
                                metricColor: .green
                            )
                        }

                            // Absoluter Kalorien-Rekord
                        if let effectiveWorkout = calcRecords.highestBurnedCaloriesWorkout {
                            RecordGridCard(
                                metricTitle: "Effektivstes Workout",
                                recordValue: "\(effectiveWorkout.calories) kcal",
                                bestWorkout: effectiveWorkout,
                                metricIcon: "flame.fill",
                                metricColor: .red
                            )
                        }
                            // Absoluter Kalorien-Rekord
                        if let fastestCrosstrainer = calcRecords.fastestWorkoutDevice(for: .crosstrainer) {
                            RecordGridCard(
                                metricTitle: "Schnellste Crosstrainer",
                                recordValue: String(format: "%.0f m/min", fastestCrosstrainer.averageSpeed),
                                bestWorkout: fastestCrosstrainer,
                                metricIcon: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
                                metricColor: .indigo
                            )
                        }
                            // Absoluter Kalorien-Rekord
                        if let fastestErgometer = calcRecords.fastestWorkoutDevice(for: .ergometer) {
                            RecordGridCard(
                                metricTitle: "Schnellstes Ergometer",
                                recordValue: String(format: "%.0f m/min", fastestErgometer.averageSpeed),
                                bestWorkout: fastestErgometer,
                                metricIcon: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
                                metricColor: .orange
                            )
                        }
                            // Niedrigstes Körpergewicht
                        if let lowestBodyWeight = calcRecords.lowestBodyWeight {
                            RecordGridCard(
                                metricTitle: "Niedrigstes Gewicht",
                                recordValue: "\(lowestBodyWeight.bodyWeight) kg",
                                bestWorkout: lowestBodyWeight,
                                metricIcon: "arrow.down.circle.fill",
                                metricColor: .green
                            )
                        }
                            // Höchstes Körpergewicht
                        if let highestBodyWeight = calcRecords.highestBodyWeight {
                            RecordGridCard(
                                metricTitle: "Höchstes Gewicht",
                                recordValue: "\(highestBodyWeight.bodyWeight) kg",
                                bestWorkout: highestBodyWeight,
                                metricIcon: "arrow.up.circle.fill",
                                metricColor: .red
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)

                    // Empty State
                if allWorkouts.isEmpty {
                    EmptyState()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Rekorde") {
    RecordView()
        .modelContainer(PreviewData.sharedContainer)
}
