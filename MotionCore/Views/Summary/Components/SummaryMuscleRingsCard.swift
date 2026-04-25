//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryMuscleRingsCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Grid mit MCMiniRings für jede Muskelgruppe aus der               /
//                 MuscleRecoveryAnalysis                                            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/

import SwiftUI

// MARK: - SummaryMuscleRingsCard

struct SummaryMuscleRingsCard: View {

    // MARK: Properties

    let analysis: MuscleRecoveryAnalysis
    let onMuscleTap: () -> Void

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if analysis.muscleGroupScores.isEmpty {
                EmptyState()
                    .frame(maxWidth: .infinity)
            } else {
                ringGrid
            }
        }
        .glassCard()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Trainierte Muskeln")
                .font(.headline)
            Spacer()
            Text("Ø \(Int(analysis.overallRecoveryPercent))% bereit")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    // MARK: - Ring-Grid

    private var ringGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 4),
            spacing: 12
        ) {
            ForEach(analysis.muscleGroupScores, id: \.muscleGroup) { group in
                MCMiniRing(
                    value: Int(group.recoveryPercent),
                    label: group.displayName
                )
                .onTapGesture {
                    onMuscleTap()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {

            // Szenario 1: Gemischte Erholung
            SummaryMuscleRingsCard(
                analysis: MuscleRecoveryAnalysis(
                    analysisDate: Date(),
                    timeframeDays: 14,
                    muscleGroupScores: [
                        MuscleGroupRecovery(
                            id: "chest", muscleGroup: .chest,
                            recoveryPercent: 92,
                            muscleDetails: [], lastTrainedDate: nil,
                            wasTrainedInTimeframe: true
                        ),
                        MuscleGroupRecovery(
                            id: "back", muscleGroup: .back,
                            recoveryPercent: 45,
                            muscleDetails: [], lastTrainedDate: nil,
                            wasTrainedInTimeframe: true
                        ),
                        MuscleGroupRecovery(
                            id: "legs", muscleGroup: .legs,
                            recoveryPercent: 70,
                            muscleDetails: [], lastTrainedDate: nil,
                            wasTrainedInTimeframe: true
                        ),
                        MuscleGroupRecovery(
                            id: "arms", muscleGroup: .arms,
                            recoveryPercent: 88,
                            muscleDetails: [], lastTrainedDate: nil,
                            wasTrainedInTimeframe: true
                        ),
                        MuscleGroupRecovery(
                            id: "shoulders", muscleGroup: .shoulders,
                            recoveryPercent: 55,
                            muscleDetails: [], lastTrainedDate: nil,
                            wasTrainedInTimeframe: true
                        ),
                        MuscleGroupRecovery(
                            id: "core", muscleGroup: .core,
                            recoveryPercent: 100,
                            muscleDetails: [], lastTrainedDate: nil,
                            wasTrainedInTimeframe: false
                        )
                    ],
                    detailedScores: []
                ),
                onMuscleTap: {}
            )

            // Szenario 2: Leer
            SummaryMuscleRingsCard(
                analysis: MuscleRecoveryAnalysis(
                    analysisDate: Date(),
                    timeframeDays: 14,
                    muscleGroupScores: [],
                    detailedScores: []
                ),
                onMuscleTap: {}
            )
        }
        .padding()
    }
}
