//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Progressions-Analyse                                            /
// Datei . . . . : WorkoutAnalyseView.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-03-18                                                       /
// Beschreibung  : Aggregierte Progressions-Analyse für ein einzelnes Workout.    /
//                 Zeigt Übersicht + kompakte Karten aller trainierten Übungen.    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct WorkoutAnalyseView: View {

    // MARK: - Input

    /// Die analysierte Session (aktuelles oder abgeschlossenes Workout)
    let session: StrengthSession

    // MARK: - Queries (historische Daten, ohne aktuelle Session)

    @Query(filter: #Predicate<StrengthSession> { $0.isCompleted }, sort: \StrengthSession.date, order: .reverse)
    private var allCompletedSessions: [StrengthSession]

    @Query(sort: \Exercise.name)
    private var allExercises: [Exercise]

    // MARK: - Environment & State

    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var selectedExercise: SelectedExerciseData? = nil
    @State private var viewModel = ProgressionViewModel()
    @State private var cachedSessionAnalyses: [ProgressionAnalysis] = []

    // MARK: - Computed

    /// Historische Sessions ohne die aktuelle Session
    private var historicalSessions: [StrengthSession] {
        allCompletedSessions.filter { $0.persistentModelID != session.persistentModelID }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                ScrollView {
                    VStack(spacing: 16) {

                        // Übersicht: nur Counts der Session-Übungen
                        ProgressionOverviewCard(
                            improvingCount: cachedSessionAnalyses.filter { $0.trend == .improving }.count,
                            stableCount: cachedSessionAnalyses.filter { $0.trend == .stable || $0.trend == .volatile }.count,
                            decliningCount: cachedSessionAnalyses.filter { $0.trend == .declining }.count,
                            needsDeload: viewModel.needsDeload
                        )

                        // Übungs-Liste
                        if cachedSessionAnalyses.isEmpty {
                            EmptyState()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(cachedSessionAnalyses, id: \.exerciseName) { analysis in
                                    ProgressionExerciseCard(analysis: analysis)
                                        .onTapGesture {
                                            openExerciseDetail(for: analysis)
                                        }
                                }
                            }
                        }
                    }
                    .scrollViewContentPadding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Workout-Analyse")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "checkmark").foregroundStyle(.blue) }
                }
            }
            .sheet(item: $selectedExercise) { data in
                ExerciseProgressionView(
                    analysis: data.analysis,
                    lastSnapshot: data.lastSnapshot,
                    oneRMData: data.oneRMData,
                    volumeData: data.volumeData,
                    currentWeight: data.currentWeight,
                    currentReps: data.currentReps,
                    currentVolume: data.currentVolume
                )
                .environmentObject(appSettings)
            }
        }
        .task {
            let historical = historicalSessions
            viewModel.recalculate(sessions: historical, exercises: allExercises)
            let engine = ProgressionAnalyseCalcEngine(sessions: historical, exercises: allExercises)
            cachedSessionAnalyses = engine.analysesForSession(session)
        }
        .onChange(of: allCompletedSessions) { _, _ in
            let historical = historicalSessions
            viewModel.recalculate(sessions: historical, exercises: allExercises)
            let engine = ProgressionAnalyseCalcEngine(sessions: historical, exercises: allExercises)
            cachedSessionAnalyses = engine.analysesForSession(session)
        }
    }

    // MARK: - Übungsdetail öffnen

    private func openExerciseDetail(for analysis: ProgressionAnalysis) {
        let engine = ProgressionAnalyseCalcEngine(sessions: historicalSessions, exercises: allExercises)

        // Letzter Snapshot: nur wenn Übung in der Bibliothek vorhanden
        guard let matchedExercise = allExercises.first(where: { $0.name == analysis.exerciseName }) else { return }
        let snapshots = engine.snapshots(for: matchedExercise)

        // Aktueller Stand aus der Session berechnen
        let sessionSets = session.safeExerciseSets.filter {
            ($0.exerciseNameSnapshot.isEmpty ? $0.exerciseName : $0.exerciseNameSnapshot) == analysis.exerciseName
                && $0.setKind == .work
                && $0.isCompleted
        }

        let currentWeight = sessionSets.compactMap { $0.weight > 0 ? $0.weight : nil }.max() ?? 0
        let currentReps = sessionSets.map { $0.reps }.min() ?? 0
        let currentVolume = sessionSets.map { Double($0.reps) * $0.weight }.reduce(0, +)

        // oneRM und Volumen aus ViewModel (vorberechnet)
        let oneRMData = viewModel.oneRMTrendMap[matchedExercise.persistentModelID] ?? []
        let volumeData = viewModel.volumeTrendMap[matchedExercise.persistentModelID] ?? []

        selectedExercise = SelectedExerciseData(
            analysis: analysis,
            lastSnapshot: snapshots.first,
            oneRMData: oneRMData,
            volumeData: volumeData,
            currentWeight: currentWeight,
            currentReps: currentReps,
            currentVolume: currentVolume
        )
    }
}

// MARK: - Hilfstyp für Sheet-Übergabe

private struct SelectedExerciseData: Identifiable {
    let id = UUID()
    let analysis: ProgressionAnalysis
    let lastSnapshot: SessionSnapshot?
    let oneRMData: [TrendPoint]
    let volumeData: [TrendPoint]
    let currentWeight: Double
    let currentReps: Int
    let currentVolume: Double
}

// MARK: - Preview

#Preview("WorkoutAnalyseView") {
    let session: StrengthSession = {
        let s = StrengthSession(
            date: Date(),
            duration: 55,
            calories: 340,
            notes: "",
            workoutType: .push,
            intensity: .medium
        )
        s.isCompleted = true

        let set1 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 82.5, reps: 9, setKind: .work)
        set1.isCompleted = true
        let set2 = ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 82.5, reps: 8, setKind: .work)
        set2.isCompleted = true
        s.exerciseSets = [set1, set2]
        return s
    }()

    WorkoutAnalyseView(session: session)
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
