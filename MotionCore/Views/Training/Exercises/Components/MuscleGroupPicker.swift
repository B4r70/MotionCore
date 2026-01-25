//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : MuscleGroupPicker.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.12.2025                                                       /
// Beschreibung  : Formular zum Erstellen/Bearbeiten von Übungen                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Muscle Group Picker

struct MuscleGroupPicker: View {
    @Binding var selectedMuscles: [MuscleGroup]
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(MuscleGroup.allCases) { muscle in
                Button {
                    if selectedMuscles.contains(muscle) {
                        selectedMuscles.removeAll { $0 == muscle }
                    } else {
                        selectedMuscles.append(muscle)
                    }
                } label: {
                    HStack {
                        Text(muscle.description)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if selectedMuscles.contains(muscle) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fertig") {
                    dismiss()
                }
            }
        }
    }
}
