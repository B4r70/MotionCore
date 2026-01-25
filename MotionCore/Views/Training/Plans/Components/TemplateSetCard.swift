//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : TemplateSetCard.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Card-Komponente für eine Übung mit Sätzen im Template            /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct TemplateSetCard<Trailing: View>: View {
    let exerciseName: String
    let mediaAssetName: String
    let sets: [ExerciseSet]
    let onDelete: () -> Void
    let onEdit: () -> Void
    let showsEditMenu: Bool
    let trailing: () -> Trailing

    @State private var showDeleteConfirm = false

    init(
        exerciseName: String,
        mediaAssetName: String,
        sets: [ExerciseSet],
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        showsEditMenu: Bool = true,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.exerciseName = exerciseName
        self.mediaAssetName = mediaAssetName
        self.sets = sets
        self.onDelete = onDelete
        self.onEdit = onEdit
        self.showsEditMenu = showsEditMenu
        self.trailing = trailing
    }

    // MARK: - Calculated Values

    private var workingSets: [ExerciseSet] {
        sets.filter { $0.setKind == .work }
    }

    private var warmupSets: [ExerciseSet] {
        sets.filter { $0.setKind == .warmup }
    }

    private var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header mit Übungsinfo
            HStack(spacing: 12) {
                if let firstSet = sets.first {
                    ExerciseVideoView.forSet(firstSet, size: 56)
                } else {
                    ExerciseVideoView.forAsset(mediaAssetName, size: 56)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label("\(sets.count) Sätze", systemImage: "number.circle")

                        if totalVolume > 0 {
                            Label(String(format: "%.0f kg", totalVolume), systemImage: "scalemass")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Menu nur im Normalmodus (wenn kein Trailing geliefert wird)
                if showsEditMenu {
                    Menu {
                        Button { onEdit() } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Entfernen", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                // Trailing Slot (z.B. Drag Handle im Edit-Mode)
                trailing()
            }

            // Satz-Details
            VStack(spacing: 6) {

                // Aufwärmsätze
                if !warmupSets.isEmpty {
                    HStack {
                        Text("Aufwärmen")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)

                        Spacer()

                        Text(warmupSummary)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                // Arbeitssätze
                HStack {
                    Text("Arbeitssätze")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)

                    Spacer()

                    Text(workingSummary)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                // Pause und RIR Info
                if let firstWork = workingSets.first {
                    HStack(spacing: 16) {
                        Label(formatRestTime(firstWork.restSeconds), systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Text("RIR")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(firstWork.targetRIR)")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(rirColor(for: firstWork.targetRIR).opacity(0.2))
                                .foregroundStyle(rirColor(for: firstWork.targetRIR))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .glassCard()
        .alert("Übung entfernen?", isPresented: $showDeleteConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("\(exerciseName) wird aus dem Trainingsplan entfernt.")
        }
    }

    // MARK: - Summaries

    private var warmupSummary: String {
        guard let first = warmupSets.first else { return "" }
        let reps = first.reps

        if first.weightPerSide > 0 {
            let weightsPerSide = warmupSets.map { $0.weightPerSide }
            if Set(weightsPerSide).count == 1, let weight = weightsPerSide.first {
                return "\(warmupSets.count) × \(reps) @ 2×\(formatWeight(weight))"
            } else {
                return "\(warmupSets.count) × \(reps) (variabel)"
            }
        } else {
            let weights = warmupSets.map { $0.weight }
            if Set(weights).count == 1, let weight = weights.first {
                return "\(warmupSets.count) × \(reps) @ \(formatWeight(weight))"
            } else {
                return "\(warmupSets.count) × \(reps) (variabel)"
            }
        }
    }

    private var workingSummary: String {
        guard let first = workingSets.first else { return "" }
        let reps = first.reps

        if first.weightPerSide > 0 {
            return "\(workingSets.count) × \(reps) @ 2×\(formatWeight(first.weightPerSide))"
        } else {
            return "\(workingSets.count) × \(reps) @ \(formatWeight(first.weight))"
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        weight > 0 ? String(format: "%.1f kg", weight) : "KG"
    }

    private func formatRestTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 {
            return "\(mins):\(String(format: "%02d", secs)) Pause"
        } else if mins > 0 {
            return "\(mins) Min Pause"
        } else {
            return "\(secs) Sek Pause"
        }
    }

    private func rirColor(for rir: Int) -> Color {
        switch rir {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .blue
        }
    }
}

// Convenience init für normalen Gebrauch ohne trailing
extension TemplateSetCard where Trailing == EmptyView {
    init(
        exerciseName: String,
        mediaAssetName: String,
        sets: [ExerciseSet],
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        showsEditMenu: Bool = true
    ) {
        self.init(
            exerciseName: exerciseName,
            mediaAssetName: mediaAssetName,
            sets: sets,
            onDelete: onDelete,
            onEdit: onEdit,
            showsEditMenu: showsEditMenu
        ) {
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("Template Set Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)

        VStack(spacing: 16) {
            TemplateSetCard(
                exerciseName: "Bankdrücken",
                mediaAssetName: "",
                sets: [
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 40, reps: 10, setKind: .warmup),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 60, reps: 10, setKind: .warmup),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 3, weight: 80, reps: 10, setKind: .work),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 4, weight: 80, reps: 10, setKind: .work),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 5, weight: 80, reps: 10, setKind: .work)
                ],
                onDelete: {},
                onEdit: {}
            )

            TemplateSetCard(
                exerciseName: "Kniebeugen",
                mediaAssetName: "",
                sets: [
                    ExerciseSet(exerciseName: "Kniebeugen", setNumber: 1, weight: 100, reps: 8, setKind: .work),
                    ExerciseSet(exerciseName: "Kniebeugen", setNumber: 2, weight: 100, reps: 8, setKind: .work),
                    ExerciseSet(exerciseName: "Kniebeugen", setNumber: 3, weight: 100, reps: 8, setKind: .work)
                ],
                onDelete: {},
                onEdit: {}
            )
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
