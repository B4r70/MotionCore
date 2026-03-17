//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Rekorde                                                          /
// Datei . . . . : RecordView.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Rekorde                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct RecordView: View {

    // MARK: - Queries

    @Query(sort: \CardioSession.date, order: .reverse)
    private var allCardioSessions: [CardioSession]

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allStrengthSessions: [StrengthSession]

    // MARK: - Environment

    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Computed

    private var calcRecords: RecordCalcEngine {
        RecordCalcEngine(workouts: allCardioSessions)
    }

    private var calcStrengthRecords: StrengthRecordCalcEngine {
        StrengthRecordCalcEngine(sessions: allStrengthSessions)
    }

    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Kraft-Rekorde (prominent, oben)
                    if !allStrengthSessions.isEmpty {
                        strengthRecordsSection
                    }

                    // MARK: Cardio-Rekorde (reduziert, unten)
                    if !allCardioSessions.isEmpty {
                        cardioRecordsSection
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if allCardioSessions.isEmpty && allStrengthSessions.isEmpty {
                EmptyState()
            }
        }
    }

    // MARK: - Kraft-Rekorde Section

    @ViewBuilder
    private var strengthRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kraft-Rekorde")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: gridColumns, spacing: 16) {

                // Höchstes Gewichtsvolumen
                if let record = calcStrengthRecords.highestVolumeSession {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Höchstes Volumen",
                        metricIcon: .system("scalemass.fill"),
                        metricColor: .purple
                    )
                }

                // Meiste Sätze
                if let record = calcStrengthRecords.mostSetsSession {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Meiste Sätze",
                        metricIcon: .system("list.number"),
                        metricColor: .teal
                    )
                }

                // Meiste Reps gesamt
                if let record = calcStrengthRecords.mostRepsSession {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Meiste Reps",
                        metricIcon: .system("repeat"),
                        metricColor: .blue
                    )
                }

                // Schwerster Einzelsatz
                if let record = calcStrengthRecords.heaviestSingleSet {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Schwerster Satz",
                        metricIcon: .system("dumbbell.fill"),
                        metricColor: .orange
                    )
                }

                // Längstes Kraft-Training
                if let record = calcStrengthRecords.longestStrengthSession {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Längstes Training",
                        metricIcon: .system("clock.fill"),
                        metricColor: .indigo
                    )
                }

                // Meiste Übungen
                if let record = calcStrengthRecords.mostExercisesSession {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Meiste Übungen",
                        metricIcon: .system("figure.strengthtraining.traditional"),
                        metricColor: .green
                    )
                }

                // Höchstes geschätztes 1RM
                if let record = calcStrengthRecords.highestEstimated1RM {
                    StrengthRecordGridCard(
                        record: record,
                        metricTitle: "Höchstes 1RM",
                        metricIcon: .system("trophy.fill"),
                        metricColor: .yellow
                    )
                }
            }
        }
    }

    // MARK: - Cardio-Rekorde Section

    @ViewBuilder
    private var cardioRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cardio-Rekorde")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: gridColumns, spacing: 16) {

                // Längste Distanz
                if let longestDistance = calcRecords.longestDistanceWorkout {
                    RecordGridCard(
                        metricTitle: "Längste Distanz",
                        recordValue: String(format: "%.2f km", longestDistance.distance),
                        bestWorkout: longestDistance,
                        metricIcon: .system("arrow.left.and.right"),
                        metricColor: .green
                    )
                }

                // Höchster Kalorienverbrauch
                if let highestCalories = calcRecords.highestBurnedCaloriesWorkout {
                    RecordGridCard(
                        metricTitle: "Höchste Kalorien",
                        recordValue: "\(highestCalories.calories) kcal",
                        bestWorkout: highestCalories,
                        metricIcon: .system("flame.fill"),
                        metricColor: .red
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Rekorde") {
    RecordView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
