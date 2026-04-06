//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Muskel-Heatmap                                                   /
// Datei . . . . : MuscleHeatmapView.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.03.2026                                                       /
// Beschreibung  : Interaktive Muskel-Heatmap mit Zeitraum-Filter und Detail-Sheet  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct MuscleHeatmapView: View {

    // MARK: - Queries

    @Query(filter: #Predicate<StrengthSession> { $0.isCompleted },
           sort: \StrengthSession.date, order: .reverse)
    private var sessions: [StrengthSession]

    // MARK: - Environment & State

    @EnvironmentObject private var appSettings: AppSettings
    @State private var timeframe: SummaryTimeframe = .month
    @State private var viewModel = MuscleHeatmapViewModel()
    @State private var selectedRegion: MuscleHeatData?

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    TimeframePicker(selection: $timeframe)

                    // SVG-Heatmap Card
                    heatmapCard

                    // Legende
                    MuscleHeatmapLegend()

                    // Vernachlässigte Muskeln
                    if let analysis = viewModel.analysis, !analysis.neglectedRegions.isEmpty {
                        neglectedMusclesCard(regions: analysis.neglectedRegions)
                    }

                    // Top trainierte Muskeln
                    if let analysis = viewModel.analysis, !analysis.topRegions.isEmpty {
                        topMusclesCard(regions: analysis.topRegions)
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if viewModel.analysis == nil {
                EmptyState()
            }
        }
        .task { viewModel.recalculate(sessions: sessions, timeframe: timeframe) }
        .onChange(of: sessions) { _, new in viewModel.recalculate(sessions: new, timeframe: timeframe) }
        .onChange(of: timeframe) { _, new in viewModel.recalculate(sessions: sessions, timeframe: new) }
        .sheet(item: $selectedRegion) { data in
            MuscleDetailSheet(data: data, sessions: viewModel.faultedSessions, timeframe: timeframe)
        }
    }

    // MARK: - Heatmap Card

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.orange)
                Text("Muskelaktivität")
                    .font(.headline)
                Spacer()
                if let analysis = viewModel.analysis {
                    Text("\(analysis.totalSets) Sets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let analysis = viewModel.analysis {
                MuscleHeatmapSVGView(analysis: analysis) { regionId in
                    selectedRegion = viewModel.analysis?.data(for: regionId)
                }
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .frame(height: 400)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Vernachlässigte Muskeln

    private func neglectedMusclesCard(regions: [MuscleHeatData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.orange)
                Text("Vernachlässigte Muskeln")
                    .font(.headline)
                Spacer()
                Text("\(regions.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.orange)
            }

            VStack(spacing: 8) {
                ForEach(regions.prefix(5)) { region in
                    HStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(region.heatLevel.color)
                            .frame(width: 10, height: 10)
                        Text(region.displayName)
                            .font(.subheadline)
                        Spacer()
                        if let days = region.daysSinceLastTrained {
                            Text("vor \(days) Tagen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Nie trainiert")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }

    // MARK: - Top Muskeln

    private func topMusclesCard(regions: [MuscleHeatData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.red)
                Text("Meist trainiert")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(regions) { region in
                    HStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(region.heatLevel.color)
                            .frame(width: 10, height: 10)
                        Text(region.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(region.totalSets) Sets · \(region.frequencyFormatted)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .glassCard()
    }
}

// MARK: - Detail Sheet

private struct MuscleDetailSheet: View {

    @Environment(\.dismiss) private var dismiss
    let data: MuscleHeatData
    let sessions: [StrengthSession]
    let timeframe: SummaryTimeframe

    @State private var history: [MuscleTrainingHistorySession] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Volumen", value: data.volumeFormatted)
                    LabeledContent("Sets", value: "\(data.totalSets)")
                    LabeledContent("Frequenz", value: data.frequencyFormatted)
                    LabeledContent("Intensität", value: data.heatLevel.displayName)
                    if let days = data.daysSinceLastTrained {
                        LabeledContent("Zuletzt trainiert", value: "vor \(days) Tagen")
                    }
                }

                if !data.contributingMuscles.isEmpty {
                    Section("Muskeln") {
                        ForEach(data.contributingMuscles) { muscle in
                            Text(muscle.displayName)
                                .font(.subheadline)
                        }
                    }
                }

                if !history.isEmpty {
                    Section("Trainingshistorie") {
                        ForEach(history) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                // Session-Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.sessionDate, style: .date)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        if let plan = entry.planName {
                                            Text(plan)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(entry.sessionDate, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                // Übungen
                                ForEach(entry.exercises) { exercise in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.exerciseName)
                                                .font(.caption)
                                                .foregroundStyle(exercise.isPrimary ? .primary : .secondary)
                                            Text(exerciseSummary(exercise))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(volumeFormatted(exercise.totalVolume))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(data.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "checkmark").foregroundStyle(Color.blue) }
                }
            }
            .task(id: data.svgRegionId) {
                let engine = MuscleHeatmapCalcEngine()
                history = engine.trainingHistory(for: data.svgRegionId, sessions: sessions, timeframe: timeframe)
            }
        }
    }

    private func exerciseSummary(_ exercise: MuscleTrainingHistoryExercise) -> String {
        let avgReps = exercise.setCount > 0 ? exercise.totalReps / exercise.setCount : 0
        let weightStr = exercise.maxWeight > 0 ? " · \(Int(exercise.maxWeight)) kg" : ""
        return "\(exercise.setCount)×\(avgReps)\(weightStr)"
    }

    private func volumeFormatted(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        }
        return String(format: "%.0f kg", volume)
    }
}

// MARK: - Preview

#Preview("Muskel-Heatmap") {
    MuscleHeatmapView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
