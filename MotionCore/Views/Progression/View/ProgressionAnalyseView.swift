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
    @State private var selectedSegment: AnalyseSegment = .progression

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Picker("Ansicht", selection: $selectedSegment) {
                ForEach(AnalyseSegment.allCases) { segment in
                    Text(segment.label).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)

            switch selectedSegment {
            case .progression:
                progressionContent
            case .heatmap:
                MuscleHeatmapView()
            }
        }
    }

    // MARK: - Progressions-Inhalt

    private var progressionContent: some View {
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

// MARK: - AnalyseSegment

enum AnalyseSegment: String, CaseIterable, Identifiable {
    case progression = "progression"
    case heatmap = "heatmap"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .progression: return "Progression"
        case .heatmap: return "Heatmap"
        }
    }
}

// MARK: - Preview

#Preview("Progressions-Analyse") {
    ProgressionAnalyseView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
