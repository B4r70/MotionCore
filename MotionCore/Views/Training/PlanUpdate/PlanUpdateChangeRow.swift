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

    private var isInfoOnly: Bool {
        if case .exerciseSkipped = change.changeType { return true }
        return false
    }

    var body: some View {
        Toggle(isOn: $change.isSelected) {
            VStack(alignment: .leading, spacing: Space.s1) {
                Text(change.exerciseName)
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textPrimary)

                Text(changeDetailText)
                    .font(AppFont.callout)
                    .foregroundStyle(changeDetailColor)
            }
        }
        .toggleStyle(.switch)
        // Übersprungene Übungen sind rein informativ — Toggle nur für aktive Änderungen schaltbar
        .disabled(isInfoOnly)
        .padding()
        .card()
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
            let baseText = "Neue Übung hinzufügen (\(setCount) \(setCount == 1 ? "Satz" : "Sätze"))"
            if let meta = change.metadata {
                return "\(baseText) · In \(meta.sessionOccurrences) von \(meta.sessionsAnalyzed) Sessions trainiert"
            }
            return baseText

        case .exerciseSkipped(let timesSkipped, let outOf):
            return "Übersprungen in \(timesSkipped) von \(outOf) Sessions"

        case .exerciseRemoved:
            return "Übung aus Plan entfernen"
        }
    }

    private var changeDetailColor: Color {
        switch change.changeType {
        case .weightUpdate(let from, let to):
            // Erhöhung = positiv (Akzent), Reduzierung = neutral
            return to > from ? Theme.accent : Theme.textSecondary
        case .setCountUpdate(let from, let to):
            // Erhöhung = positiv (Akzent), Reduzierung = neutral
            return to > from ? Theme.accent : Theme.textSecondary
        case .exerciseAdded:
            // Hinzugefügt/neu → success
            return Theme.success
        case .exerciseSkipped:
            // Übersprungen → warning
            return Theme.warning
        case .exerciseRemoved:
            // Entfernt → danger
            return Theme.danger
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

    ScrollView {
        VStack(spacing: Space.s3) {
            PlanUpdateChangeRow(change: $weightChange)
            PlanUpdateChangeRow(change: $setCountChange)
            PlanUpdateChangeRow(change: $newExercise)
            PlanUpdateChangeRow(change: $skipped)
        }
        .padding(Space.s4)
    }
    .background(Theme.surfaceApp.ignoresSafeArea())
}
