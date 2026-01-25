//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TrainingListView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 19.12.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Trainingspläne                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct TrainingListView: View {

    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TrainingPlan.startDate, order: .reverse)
    private var plans: [TrainingPlan]

    @State private var draftPlan: TrainingPlan? = nil

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(plans) { plan in
                        NavigationLink {
                            TrainingDetailView(plan: plan)
                        } label: {
                            TrainingPlanCard(plan: plan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            if plans.isEmpty {
                EmptyState()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ExerciseListView()
                } label: {
                    ToolbarButton(icon: .system("figure.strengthtraining.traditional.circle"))
                }
            }
        }
        .floatingActionButton(
            icon: .system("plus.circle.fill"),
            color: .primary
        ) {
            // Draft erzeugen
            draftPlan = TrainingPlan()
        }
        // sheet(item:) statt sheet(isPresented:)
        .sheet(item: $draftPlan) { plan in
            NavigationStack {
                TrainingFormView(mode: .add, plan: plan)
            }
        }
    }
}

// MARK: - Preview

#Preview("Workout Plans") {
    NavigationStack {
        TrainingListView()
            .environmentObject(AppSettings.shared)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HeaderView(
                        title: "MotionCore",
                        subtitle: "Trainingspläne"
                    )
                }
            }
    }
}
