//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Body-Tab — Muskel-Erholung, Tagesform und Trend                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct BodyView: View {

    // MARK: - Eingaben

    let onStartWorkoutTap: () -> Void

    // MARK: - ViewModel

    @State private var viewModel = BodyViewModel()

    // MARK: - Lokaler State

    @State private var detailItem: MuscleRecoveryAnalysis? = nil
    @State private var selectedTab: BodyTab = .recovery

    // MARK: - Queries

    @Query(
        filter: #Predicate<StrengthSession> { $0.isCompleted },
        sort: \StrengthSession.date,
        order: .reverse
    )
    private var strengthSessions: [StrengthSession]

    @Query(sort: \SessionReadiness.capturedAt, order: .reverse)
    private var allReadiness: [SessionReadiness]

    @Query
    private var baselines: [HealthBaseline]

    // MARK: - Umgebung

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Body

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 16) {
                    compositeSection
                    BodyTabSwitch(selectedTab: $selectedTab)
                    tabContentSection
                    avoidSection
                    emptySection
                }
                .scrollViewContentPadding()
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .task {
            refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refresh()
        }
        .onChange(of: strengthSessions) { _, _ in
            refresh()
        }
        .sheet(item: $detailItem) { analysis in
            MuscleRecoveryDetailView(analysis: analysis)
                .environmentObject(appSettings)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var compositeSection: some View {
        if let analysis = viewModel.recoveryAnalysis {
            BodyCompositeScoreCard(
                recoveryPercent: Int(analysis.overallRecoveryPercent),
                recommendation: viewModel.recommendation,
                onStartWorkoutTap: onStartWorkoutTap
            )
        }
    }

    @ViewBuilder
    private var tabContentSection: some View {
        switch selectedTab {
        case .recovery:
            if let analysis = viewModel.recoveryAnalysis {
                BodyRecoveryListCard(analysis: analysis) { _ in
                    detailItem = analysis
                }
            } else {
                EmptyState()
            }
        case .form:
            BodyReadinessFactorsCard(
                factors: viewModel.readinessFactors,
                score: viewModel.readinessScore
            )
        case .trend:
            BodyRecoveryTrendCard()
        }
    }

    @ViewBuilder
    private var avoidSection: some View {
        if !viewModel.recommendation.avoidGroups.isEmpty {
            BodyAvoidCard(recommendation: viewModel.recommendation)
        }
    }

    @ViewBuilder
    private var emptySection: some View {
        if viewModel.recoveryAnalysis == nil && viewModel.readinessFactors.isEmpty {
            EmptyState()
        }
    }

    // MARK: - Refresh

    private func refresh() {
        viewModel.recalculate(sessions: strengthSessions)
        viewModel.loadReadinessFactors(
            latestReadiness: allReadiness.first,
            baselines: baselines,
            takesCardioMedication: appSettings.takesCardioMedication
        )
    }
}

// MARK: - Preview

#Preview("BodyView") {
    NavigationStack {
        BodyView(onStartWorkoutTap: {})
            .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(PreviewData.sharedContainer)
    .environmentObject(AppSettings.shared)
}
