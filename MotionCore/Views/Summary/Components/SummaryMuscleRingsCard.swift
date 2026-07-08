//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Summary / Components                                     /
// Datei . . . . : SummaryMuscleRingsCard.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Grid mit ProgressRings je Muskelgruppe (RecoveryAnalysis)        /
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
        VStack(alignment: .leading, spacing: Space.s3) {
            header
            if analysis.muscleGroupScores.isEmpty {
                EmptyState()
                    .frame(maxWidth: .infinity)
            } else {
                ringGrid
            }
        }
        .card()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Trainierte Muskeln")
                .font(AppFont.headline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text("Ø \(Int(analysis.overallRecoveryPercent))% bereit")
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
        }
    }

    // MARK: - Ring-Grid

    private var ringGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 4),
            spacing: Space.s3
        ) {
            ForEach(analysis.muscleGroupScores, id: \.muscleGroup) { group in
                ProgressRing(
                    progress: group.recoveryPercent / 100.0,
                    size: 62,
                    stroke: 6,
                    tint: recoveryTint(group.recoveryPercent),
                    centerValue: "\(Int(group.recoveryPercent))",
                    centerLabel: group.displayName
                )
                .onTapGesture {
                    onMuscleTap()
                }
            }
        }
    }

    // MARK: - Erholungs-Farbe (eine Leitfarbe je Erholungsstufe)

    private func recoveryTint(_ percent: Double) -> Color {
        switch percent {
        case 85...:   return Theme.success
        case 50..<85: return Theme.warning
        default:      return Theme.danger
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
