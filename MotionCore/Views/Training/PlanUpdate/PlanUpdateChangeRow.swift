//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Training / Plan-Update                                           /
// Datei . . . . : PlanUpdateChangeRow.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 21.03.2026                                                       /
// Beschreibung  : Einzelne Zeile für eine Plan-Update-Änderung                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Plan-Update Change Row

struct PlanUpdateChangeRow: View {

    @Binding var change: PlanUpdateChange

    private var isSkipped: Bool {
        if case .exerciseSkipped = change.changeType { return true }
        return false
    }

    var body: some View {
        Toggle(isOn: $change.isSelected) {
            VStack(alignment: .leading, spacing: 4) {
                Text(change.exerciseName)
                    .font(.headline)

                Text(changeDetailText)
                    .font(.subheadline)
                    .foregroundStyle(changeDetailColor)
            }
        }
        .toggleStyle(.switch)
        // Übersprungene Übungen sind reine Info — kein Toggle nötig
        .disabled(isSkipped)
        .padding()
        .glassCard()
    }

    // MARK: - Hilfseigenschaften

    private var changeDetailText: String {
        switch change.changeType {
        case .weightUpdate(let from, let to):
            let direction = to > from ? "erhöhen" : "reduzieren"
            return "Gewicht \(direction): \(String(format: "%.1f kg", from)) → \(String(format: "%.1f kg", to))"

        case .setCountUpdate(let from, let to):
            let direction = to > from ? "erhöhen" : "reduzieren"
            return "Satzanzahl \(direction): \(from) → \(to) Sätze"

        case .exerciseAdded(let sets):
            let setCount = sets.count
            return "Neue Übung hinzufügen (\(setCount) \(setCount == 1 ? "Satz" : "Sätze"))"

        case .exerciseSkipped(let timesSkipped, let outOf):
            return "Übersprungen in \(timesSkipped) von \(outOf) Sessions"
        }
    }

    private var changeDetailColor: Color {
        switch change.changeType {
        case .weightUpdate(let from, let to):
            return to > from ? Color.green : .secondary
        case .setCountUpdate(let from, let to):
            return to > from ? Color.green : .secondary
        case .exerciseAdded:
            return .blue
        case .exerciseSkipped:
            return Color.orange
        }
    }
}

// MARK: - Preview

#Preview("Plan Update Change Row") {
    @Previewable @State var weightChange = PlanUpdateChange(
        exerciseGroupKey: "bench_press",
        exerciseName: "Bankdrücken",
        changeType: .weightUpdate(from: 80.0, to: 85.0),
        isSelected: true
    )
    @Previewable @State var setCountChange = PlanUpdateChange(
        exerciseGroupKey: "squat",
        exerciseName: "Kniebeuge",
        changeType: .setCountUpdate(from: 3, to: 4),
        isSelected: true
    )
    @Previewable @State var newExercise = PlanUpdateChange(
        exerciseGroupKey: "lateral_raise",
        exerciseName: "Seitheben",
        changeType: .exerciseAdded(sets: []),
        isSelected: false
    )
    @Previewable @State var skipped = PlanUpdateChange(
        exerciseGroupKey: "cable_fly",
        exerciseName: "Kabelzug Flys",
        changeType: .exerciseSkipped(timesSkipped: 2, outOf: 3),
        isSelected: false
    )

    VStack(spacing: 12) {
        PlanUpdateChangeRow(change: $weightChange)
        PlanUpdateChangeRow(change: $setCountChange)
        PlanUpdateChangeRow(change: $newExercise)
        PlanUpdateChangeRow(change: $skipped)
    }
    .padding()
}
