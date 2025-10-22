//
//  AddWorkoutView.swift
//  Crosstrainer
//
//  Created by Barto on 21.10.25.
//
import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var duration: Int = 30
    @State private var distance: String = ""
    @State private var calories: String = ""
    @State private var intensity: Int = 2
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Training") {
                    DatePicker("Datum & Uhrzeit", selection: .constant(Date()), displayedComponents: [.date, .hourAndMinute])
                        .disabled(true)
                    
                    Picker("Dauer (Minuten)", selection: $duration) {
                        ForEach(5...120, id: \.self) { minute in
                            Text("\(minute) Min").tag(minute)
                        }
                    }
                    
                    TextField("Strecke (km)", text: $distance)
                        .keyboardType(.decimalPad)
                    
                    TextField("Kalorien (kcal)", text: $calories)
                        .keyboardType(.numberPad)
                }
                
                Section("Belastung") {
                    Picker("Intensität", selection: $intensity) {
                        Text("0 - Sehr leicht").tag(0)
                        Text("1 - Leicht").tag(1)
                        Text("2 - Moderat").tag(2)
                        Text("3 - Anstrengend").tag(3)
                        Text("4 - Sehr anstrengend").tag(4)
                        Text("5 - Maximal").tag(5)
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Neues Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveWorkout()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard let distanceValue = Double(distance.replacingOccurrences(of: ",", with: ".")),
              let caloriesValue = Int(calories),
              distanceValue > 0,
              caloriesValue > 0 else {
            return false
        }
        return true
    }
    
    private func saveWorkout() {
        guard let distanceValue = Double(distance.replacingOccurrences(of: ",", with: ".")),
              let caloriesValue = Int(calories) else {
            return
        }
        
        let workout = WorkoutEntry(
            date: Date(),
            duration: duration,
            distance: distanceValue,
            calories: caloriesValue,
            intensity: intensity
        )
        
        modelContext.insert(workout)
        dismiss()
    }
}
