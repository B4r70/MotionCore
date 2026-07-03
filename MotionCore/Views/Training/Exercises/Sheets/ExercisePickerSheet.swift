//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : ExercisePickerSheet.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Sheet zum Auswählen einer Übung aus der Bibliothek.              /
//                 Dünner Wrapper um ExercisePickerView (NavigationStack + Toolbar)./
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ExercisePickerView { exercise in
                onSelect(exercise)
                dismiss()
            }
            .background(Theme.surfaceApp.ignoresSafeArea())
            .navigationTitle("Übung wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Exercise Picker Sheet") {
    ExercisePickerSheet { exercise in
        print("Selected: \(exercise.name)")
    }
}
