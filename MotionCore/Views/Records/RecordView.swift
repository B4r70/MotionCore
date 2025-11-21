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

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Beste Leistung nach Distanz auf dem Crosstrainer
                    if let best = calcRecords.bestCrosstrainerWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Längste Distanz auf dem Crosstrainer",
                            icon: best.workoutDevice.symbol,
                            color: best.workoutDevice.tint,
                            allWorkouts: best
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    // Beste Leistung nach Distanz auf dem Ergometer
                    if let best = calcRecords.bestErgometerWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Längste Distanz auf dem Ergometer",
                            icon: best.workoutDevice.symbol,
                            color: best.workoutDevice.tint,
                            allWorkouts: best
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    // Hier kannst du später weitere Rekord-Cards hinzufügen
                }
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

// MARK: - Preview

    // MARK: Statistic Preview
#Preview("Statistiken") {
    RecordView()
        .modelContainer(PreviewData.sharedContainer)
}
