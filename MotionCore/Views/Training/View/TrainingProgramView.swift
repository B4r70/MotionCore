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

struct TrainingProgramView: View {
    // Globaler Zugriff auf AppSettings
    @EnvironmentObject private var appSettings: AppSettings

    // State für Beispieldaten (später durch @Query ersetzt)
    @State private var samplePlans: [TrainingProgramSample] = [
        TrainingProgramSample(
            title: "Cardio Plan",
            description: "3× pro Woche · 15 Min · Crosstrainer",
            workoutCount: 12,
            completedCount: 5,
            color: .blue
        ),
        TrainingProgramSample(
            title: "Kraft Basics – Ganzkörper",
            description: "3× pro Woche · Geräte · 45–60 Min",
            workoutCount: 18,
            completedCount: 2,
            color: .orange
        ),
        TrainingProgramSample(
            title: "Intervall-Training",
            description: "2× pro Woche · HIIT · Ergometer",
            workoutCount: 8,
            completedCount: 8,
            color: .green
        ),
        TrainingProgramSample(
            title: "Aufbau – 4 Wochen Progression",
            description: "4× pro Woche · Split · Steigerung",
            workoutCount: 16,
            completedCount: 11,
            color: .purple
        )
    ]

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Beispiel-Plan Card
                    ForEach(samplePlans) { plan in
                        TrainingProgramCard(plan: plan)
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)
            
            // Empty State (wenn keine Pläne vorhanden)
            if samplePlans.isEmpty {
                EmptyState()
            }
        }
        // NEU: Floating Action Button zum Erstellen neuer Pläne
        .floatingActionButton(
            icon: .system("plus.circle.fill"),
            color: .primary
        ) {
            // TODO: Sheet für neuen Plan öffnen
            print("Neuen Trainingsplan erstellen")
        }
    }
}

// MARK: - Sample Data Model (Temporär)

struct TrainingProgramSample: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let workoutCount: Int
    let completedCount: Int
    let color: Color
}

// MARK: - Preview

#Preview("Workout Plans") {
    NavigationStack {
        TrainingProgramView()
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
