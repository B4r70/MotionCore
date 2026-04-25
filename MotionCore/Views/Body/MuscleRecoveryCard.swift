//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : MuscleRecoveryCard.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 25.04.2026                                                       /
// Beschreibung  : Card-Darstellung der Muskelgruppen-Erholung in zwei Styles       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - MuscleRecoveryCardStyle

/// Anzeige-Modus der MuscleRecoveryCard
enum MuscleRecoveryCardStyle {
    /// Kompakt für SummaryView: ~60pt Donuts, horizontaler Scroll
    case compact
    /// Vollansicht für BodyView: ~80pt Donuts, LazyVGrid 4 Spalten
    case full
}

// MARK: - MuscleRecoveryCard

/// Übersichts-Card mit Donut-Ring pro Muskelgruppe.
/// Unterstützt `.compact` (SummaryView) und `.full` (BodyView).
struct MuscleRecoveryCard: View {

    let analysis: MuscleRecoveryAnalysis
    let style: MuscleRecoveryCardStyle
    let onTap: () -> Void

    // Donut-Größe je nach Style
    private var donutSize: CGFloat { style == .compact ? 60 : 80 }

    // Gesamt-Erholungsfarbe
    private var overallColor: Color {
        recoveryColor(percent: analysis.overallRecoveryPercent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if analysis.muscleGroupScores.isEmpty {
                emptyState
            } else {
                donutContent
            }

            if style == .full {
                footer
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .onTapGesture { onTap() }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Muskel-Erholung")
                .font(.headline)

            Spacer()

            Text("\(Int(analysis.overallRecoveryPercent.rounded()))%")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(overallColor)
        }
    }

    // MARK: - Leer-Zustand

    private var emptyState: some View {
        Text("Noch keine Trainingsdaten")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    // MARK: - Donut-Inhalt je Style

    @ViewBuilder
    private var donutContent: some View {
        switch style {
        case .compact:
            compactScrollRow
        case .full:
            fullGrid
        }
    }

    // Horizontaler Scroll für compact
    private var compactScrollRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(analysis.muscleGroupScores) { group in
                    MuscleRecoveryDonut(
                        percent: group.recoveryPercent,
                        wasTrained: group.wasTrainedInTimeframe,
                        label: group.displayName,
                        size: donutSize
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // 4-spaltiges Grid für full
    private var fullGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 4),
            spacing: 12
        ) {
            ForEach(analysis.muscleGroupScores) { group in
                MuscleRecoveryDonut(
                    percent: group.recoveryPercent,
                    wasTrained: group.wasTrainedInTimeframe,
                    label: group.displayName,
                    size: donutSize
                )
            }
        }
    }

    // MARK: - Footer (nur .full)

    private var footer: some View {
        Text("Letzte 14 Tage")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview Mock-Daten

#if DEBUG
extension MuscleRecoveryAnalysis {
    static var preview: MuscleRecoveryAnalysis {
        let now = Date()

        // Trainierte Gruppen mit verschiedenen Erholungs-Werten
        let chestDetails: [DetailedMuscleRecovery] = [
            DetailedMuscleRecovery(
                id: "chest_upper",
                muscle: .chestUpper,
                recoveryPercent: 55,
                lastTrainedDate: now.addingTimeInterval(-86400 * 2),
                totalFatigueScore: 12.0
            ),
            DetailedMuscleRecovery(
                id: "chest_middle",
                muscle: .chestMiddle,
                recoveryPercent: 60,
                lastTrainedDate: now.addingTimeInterval(-86400 * 2),
                totalFatigueScore: 10.0
            )
        ]
        let chest = MuscleGroupRecovery(
            id: "chest",
            muscleGroup: .chest,
            recoveryPercent: 57,
            muscleDetails: chestDetails,
            lastTrainedDate: now.addingTimeInterval(-86400 * 2),
            wasTrainedInTimeframe: true
        )

        let backDetails: [DetailedMuscleRecovery] = [
            DetailedMuscleRecovery(
                id: "back_lats",
                muscle: .backLats,
                recoveryPercent: 80,
                lastTrainedDate: now.addingTimeInterval(-86400 * 4),
                totalFatigueScore: 6.0
            )
        ]
        let back = MuscleGroupRecovery(
            id: "back",
            muscleGroup: .back,
            recoveryPercent: 80,
            muscleDetails: backDetails,
            lastTrainedDate: now.addingTimeInterval(-86400 * 4),
            wasTrainedInTimeframe: true
        )

        let legsDetails: [DetailedMuscleRecovery] = [
            DetailedMuscleRecovery(
                id: "quads_vastus_lateralis",
                muscle: .quadsVastusLateralis,
                recoveryPercent: 28,
                lastTrainedDate: now.addingTimeInterval(-86400 * 1),
                totalFatigueScore: 20.0
            )
        ]
        let legs = MuscleGroupRecovery(
            id: "legs",
            muscleGroup: .legs,
            recoveryPercent: 28,
            muscleDetails: legsDetails,
            lastTrainedDate: now.addingTimeInterval(-86400 * 1),
            wasTrainedInTimeframe: true
        )

        // Untrainierte Gruppen
        let shoulders = MuscleGroupRecovery(
            id: "shoulders",
            muscleGroup: .shoulders,
            recoveryPercent: 100,
            muscleDetails: [],
            lastTrainedDate: nil,
            wasTrainedInTimeframe: false
        )
        let arms = MuscleGroupRecovery(
            id: "arms",
            muscleGroup: .arms,
            recoveryPercent: 100,
            muscleDetails: [],
            lastTrainedDate: nil,
            wasTrainedInTimeframe: false
        )
        let core = MuscleGroupRecovery(
            id: "core",
            muscleGroup: .core,
            recoveryPercent: 100,
            muscleDetails: [],
            lastTrainedDate: nil,
            wasTrainedInTimeframe: false
        )
        let glutes = MuscleGroupRecovery(
            id: "glutes",
            muscleGroup: .glutes,
            recoveryPercent: 100,
            muscleDetails: [],
            lastTrainedDate: nil,
            wasTrainedInTimeframe: false
        )

        return MuscleRecoveryAnalysis(
            analysisDate: now,
            timeframeDays: 14,
            muscleGroupScores: [chest, back, shoulders, arms, legs, core, glutes],
            detailedScores: chestDetails + backDetails + legsDetails
        )
    }
}
#endif

// MARK: - Preview

#Preview("MuscleRecoveryCard Compact") {
    MuscleRecoveryCard(
        analysis: .preview,
        style: .compact,
        onTap: {}
    )
    .padding()
    .environmentObject(AppSettings.shared)
}

#Preview("MuscleRecoveryCard Full") {
    MuscleRecoveryCard(
        analysis: .preview,
        style: .full,
        onTap: {}
    )
    .padding()
    .environmentObject(AppSettings.shared)
}

#Preview("MuscleRecoveryCard Leer") {
    MuscleRecoveryCard(
        analysis: MuscleRecoveryAnalysis(
            analysisDate: Date(),
            timeframeDays: 14,
            muscleGroupScores: [],
            detailedScores: []
        ),
        style: .compact,
        onTap: {}
    )
    .padding()
    .environmentObject(AppSettings.shared)
}
