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

    // Globaler Zugriff auf AppSettings
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.modelContext) private var modelContext

    // Echte Daten aus SwiftData
    @Query(sort: \TrainingPlan.startDate, order: .reverse)
    private var plans: [TrainingPlan]

    // UI State
    @State private var showingAddPlanSheet = false

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(plans) { plan in
                        TrainingPlanCard(plan: plan)
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)

            // Empty State (wenn keine Pläne vorhanden)
            if plans.isEmpty {
                EmptyState()
            }
        }
        // Toolbar mit Exercise Library Button
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    ToolbarButton(icon: .system("figure.strengthtraining.traditional.circle"))
                }
            }
        }
        // Floating Action Button zum Erstellen neuer Pläne
        .floatingActionButton(
            icon: .system("plus.circle.fill"),
            color: .primary
        ) {
            showingAddPlanSheet = true
        }
        .sheet(isPresented: $showingAddPlanSheet) {
            NavigationStack {
                TrainingPlanFormView(mode: .add, plan: TrainingPlan())
                    .environmentObject(AppSettings.shared)
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
