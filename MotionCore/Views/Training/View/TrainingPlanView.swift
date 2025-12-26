//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : WorkoutPlanView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 19.12.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Trainingspläne                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct TrainingPlanView: View {

    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TrainingPlan.startDate, order: .reverse)
    private var plans: [TrainingPlan]

    @State private var showingAddPlanSheet = false

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(plans) { plan in
                        NavigationLink {
                            TrainingPlanDetailView(plan: plan)
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
                    ExerciseLibraryView()
                } label: {
                    ToolbarButton(icon: .system("figure.strengthtraining.traditional.circle"))
                }
            }
        }
        .floatingActionButton(
            icon: .system("plus.circle.fill"),
            color: .primary
        ) {
            showingAddPlanSheet = true
        }
        .sheet(isPresented: $showingAddPlanSheet) {
            NavigationStack {
                TrainingPlanFormView(mode: .add, plan: TrainingPlan())
            }
        }
    }
}

// MARK: - Preview

#Preview("Workout Plans") {
    NavigationStack {
        TrainingPlanView()
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
