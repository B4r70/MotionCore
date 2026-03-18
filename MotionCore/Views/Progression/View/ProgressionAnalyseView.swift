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
    @State private var viewModel = ProgressionViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 16) {

                    // Hero-Card: Aggregierte Übersicht
                    if !viewModel.trainedExercises.isEmpty {
                        ProgressionOverviewCard(
                            improvingCount: viewModel.improvingCount,
                            stableCount: viewModel.stableCount,
                            decliningCount: viewModel.decliningCount,
                            needsDeload: viewModel.needsDeload
                        )
                    }

                    // Übungsliste
                    VStack(spacing: 10) {
                        ForEach(viewModel.trainedExercises) { exercise in
                            if let analysis = viewModel.analysis(for: exercise) {
                                ProgressionExerciseCard(analysis: analysis)
                                    .onTapGesture {
                                        selectedExercise = exercise
                                    }
                            }
                        }
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if viewModel.trainedExercises.isEmpty {
                EmptyState()
            }
        }
        .sheet(item: $selectedExercise) { exercise in
            // Analyse ist im Cache — bei korrektem onChange immer vorhanden
            if let analysis = viewModel.analysis(for: exercise) {
                ProgressionDetailView(
                    analysis: analysis,
                    oneRMData: viewModel.oneRMTrendMap[exercise.persistentModelID] ?? [],
                    volumeData: viewModel.volumeTrendMap[exercise.persistentModelID] ?? []
                )
            }
        }
        .task {
            viewModel.recalculate(sessions: allSessions, exercises: allExercises)
        }
        .onChange(of: allSessions) { _, new in
            viewModel.recalculate(sessions: new, exercises: allExercises)
        }
        .onChange(of: allExercises) { _, new in
            viewModel.recalculate(sessions: allSessions, exercises: new)
        }
    }
}

// MARK: - Preview

#Preview("Progressions-Analyse") {
    ProgressionAnalyseView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
