//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : DetailedMusclePicker.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.03.2026                                                       /
// Beschreibung  : Multi-Select Picker für feingranulare Muskeln, gruppiert nach    /
//                 MuscleGroup (parentGroup)                                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Detailed Muscle Picker

struct DetailedMusclePicker: View {
    @Binding var selectedMuscles: [DetailedMuscle]
    let title: String
    @Environment(\.dismiss) private var dismiss

    // Einmalig vorberechnet — ändert sich nicht zur Laufzeit
    private static let musclesByGroup: [(group: MuscleGroup, muscles: [DetailedMuscle])] = {
        var seen: [MuscleGroup: [DetailedMuscle]] = [:]
        var order: [MuscleGroup] = []
        for muscle in DetailedMuscle.allCases {
            let group = muscle.parentGroup
            if seen[group] == nil { order.append(group) }
            seen[group, default: []].append(muscle)
        }
        return order.map { group in (group, seen[group] ?? []) }
    }()

    var body: some View {
        List {
            ForEach(Self.musclesByGroup, id: \.group) { entry in
                Section(entry.group.description) {
                    ForEach(entry.muscles) { muscle in
                        Button {
                            if selectedMuscles.contains(muscle) {
                                selectedMuscles.removeAll { $0 == muscle }
                            } else {
                                selectedMuscles.append(muscle)
                            }
                        } label: {
                            HStack {
                                Text(muscle.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedMuscles.contains(muscle) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.blue)
                }
            }
        }
    }
}
