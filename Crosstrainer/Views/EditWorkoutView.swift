//
//  EditWorkoutView.swift
//  Crosstrainer
//
//  Created by Barto on 21.10.25.
//
import SwiftUI
import SwiftData

struct EditWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var workout: WorkoutEntry
    
    @State private var distanceText: String = ""
    @State private var caloriesText: String = ""
    
    var body: some View {
        Form {
            Section("Training") {
                DatePicker("Datum & Uhrzeit", selection: $workout.date, displayedComponents: [.date, .hourAndMinute])
                
                Picker("Dauer (Minuten)", selection: $workout.duration) {
                    ForEach(5...120, id: \.self) { minute in
                        Text("\(minute) Min").tag(minute)
                    }
                }
                
                TextField("Strecke (km)", text: $distanceText)
                    .keyboardType(.decimalPad)
                    .onChange(of: distanceText) { _, newValue in
                        if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                            workout.distance = value
                        }
                    }
                
                TextField("Kalorien (kcal)", text: $caloriesText)
                    .keyboardType(.numberPad)
                    .onChange(of: caloriesText) { _, newValue in
                        if let value = Int(newValue) {
                            workout.calories = value
                        }
                    }
            }
            
            Section("Belastung") {
                Picker("Intensität", selection: $workout.intensity) {
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
        .navigationTitle("Training bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            distanceText = String(format: "%.2f", workout.distance)
            caloriesText = String(workout.calories)
        }
    }
}
