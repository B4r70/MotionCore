//---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : RecordsView.swift                                                /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 11.11.2025                                                       /
// Function . . : Persönliche Rekorde                                              /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct RecordsView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var workouts: [WorkoutSession]

    @ObservedObject private var settings = AppSettings.shared

    // Berechnung: Workout mit der längsten Distanz
    private var bestWorkout: WorkoutSession? {
        workouts.max(by: { $0.distance < $1.distance })
    }

    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: settings.showAnimatedBlob)

            ScrollView {
                VStack(spacing: 20) {
                    // Beste Leistung Card
                    if let best = bestWorkout {
                        RecordCard(
                            title: "Beste Leistung",
                            subtitle: "Meiste Kalorien",
                            icon: "trophy.fill",
                            color: .orange,
                            workout: best
                        )
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }

                    // Hier kannst du später weitere Rekord-Cards hinzufügen
                }
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)

            // Empty State
            if workouts.isEmpty {
                EmptyState()
            }
        }
    }
}
// MARK: - Preview
#Preview {
    NavigationStack {
        RecordsView()
    }
}
