//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyView.swift                                                   /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Body-Tab — Muskel-Erholung + Tagesform-Faktoren                 /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct BodyView: View {

    // MARK: - ViewModel

    @State private var viewModel = BodyViewModel()

    // Sheet-Item für MuscleRecoveryDetailView
    @State private var detailItem: MuscleRecoveryAnalysis?

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
                    recoverySection
                    readinessFactorsSection
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
        .sheet(item: $detailItem) { analysis in
            MuscleRecoveryDetailView(analysis: analysis)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var recoverySection: some View {
        if let analysis = viewModel.recoveryAnalysis {
            MuscleRecoveryCard(analysis: analysis, style: .full) {
                detailItem = analysis
            }
        }
    }

    @ViewBuilder
    private var readinessFactorsSection: some View {
        if !viewModel.readinessFactors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tagesform-Faktoren")
                    .font(.headline)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    ForEach(viewModel.readinessFactors.indices, id: \.self) { idx in
                        ReadinessFactorRow(factor: viewModel.readinessFactors[idx])
                            .padding(.horizontal, 4)
                        if idx < viewModel.readinessFactors.count - 1 {
                            Divider()
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .glassCard()
            }
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
        BodyView()
            .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(PreviewData.sharedContainer)
    .environmentObject(AppSettings.shared)
}
