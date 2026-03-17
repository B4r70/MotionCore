//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                            /
// Datei . . . . : ProgressionAnalyseView.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-17                                                       /
// Beschreibung  : Tab-View für die Progressions-Analyse aller trainierten Übungen /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ProgressionAnalyseView: View {

    // MARK: - Queries

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allSessions: [StrengthSession]

    @Query(sort: \Exercise.name)
    private var allExercises: [Exercise]

    // MARK: - Environment & State

    @EnvironmentObject private var appSettings: AppSettings
    @State private var selectedExercise: Exercise?

    // MARK: - Computed

    private var progressionCalc: ProgressionAnalyseCalcEngine {
        ProgressionAnalyseCalcEngine(sessions: allSessions, exercises: allExercises)
    }

    private var trainedExercises: [Exercise] {
        progressionCalc.trainedExercises
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 16) {

                    // Hero-Card: Aggregierte Übersicht
                    if !trainedExercises.isEmpty {
                        ProgressionOverviewCard(
                            improvingCount: progressionCalc.improvingCount,
                            stableCount: progressionCalc.stableCount,
                            decliningCount: progressionCalc.decliningCount,
                            needsDeload: progressionCalc.needsDeload
                        )
                    }

                    // Übungsliste
                    VStack(spacing: 10) {
                        ForEach(trainedExercises) { exercise in
                            ProgressionExerciseCard(
                                analysis: progressionCalc.analysis(for: exercise)
                            )
                            .onTapGesture {
                                selectedExercise = exercise
                            }
                        }
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if trainedExercises.isEmpty {
                EmptyState()
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            ProgressionDetailView(
                analysis: progressionCalc.analysis(for: exercise),
                oneRMData: progressionCalc.oneRMTrend(for: exercise),
                volumeData: progressionCalc.volumeTrend(for: exercise)
            )
        }
    }
}

// MARK: - Preview

#Preview("Progressions-Analyse") {
    ProgressionAnalyseView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
