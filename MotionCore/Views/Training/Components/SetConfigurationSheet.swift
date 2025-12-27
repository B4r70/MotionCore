//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : SetConfigurationSheet.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Sheet zum Konfigurieren der Sätze für eine Übung im Plan         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct SetConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    
    let exercise: Exercise
    let onSave: ([ExerciseSet]) -> Void
    
    // Konfiguration
    @State private var numberOfSets: Int = 3
    @State private var targetReps: Int = 10
    @State private var targetWeight: Double = 0
    @State private var includeWarmup: Bool = false
    @State private var warmupSets: Int = 1
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Übungs-Info Card
                        exerciseInfoCard
                        
                        // Satz-Konfiguration
                        setsConfigurationCard
                        
                        // Vorschau
                        previewCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Sätze konfigurieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveSets()
                    } label: {
                        IconType(icon: .system("checkmark"), color: .blue, size: 16)
                            .glassButton(size: 36, accentColor: .blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var exerciseInfoCard: some View {
        HStack(spacing: 16) {
            ExerciseGifView(assetName: exercise.gifAssetName, size: 80)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Label(exercise.equipment.description, systemImage: exercise.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !exercise.primaryMuscles.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(exercise.primaryMuscles.prefix(2), id: \.self) { muscle in
                            Text(muscle.description)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Spacer()
        }
        .glassCard()
    }
    
    private var setsConfigurationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Konfiguration")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            // Anzahl Arbeitssätze
            VStack(alignment: .leading, spacing: 8) {
                Text("Arbeitssätze")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Button {
                        if numberOfSets > 1 { numberOfSets -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    
                    Text("\(numberOfSets)")
                        .font(.title.bold())
                        .frame(width: 60)
                    
                    Button {
                        if numberOfSets < 10 { numberOfSets += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            .glassDivider()

            // Wiederholungen
            VStack(alignment: .leading, spacing: 8) {
                Text("Wiederholungen pro Satz")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Button {
                        if targetReps > 1 { targetReps -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    
                    Text("\(targetReps)")
                        .font(.title.bold())
                        .frame(width: 60)
                    
                    Button {
                        if targetReps < 50 { targetReps += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            .glassDivider()
            
            // Gewicht
            VStack(alignment: .leading, spacing: 8) {
                Text("Zielgewicht (kg)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack {
                    Button {
                        if targetWeight >= 2.5 { targetWeight -= 2.5 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    
                    Text(targetWeight > 0 ? String(format: "%.1f", targetWeight) : "–")
                        .font(.title.bold())
                        .frame(width: 80)
                    
                    Button {
                        targetWeight += 2.5
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text("0 = Körpergewicht oder später festlegen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            .glassDivider()

            // Aufwärmsätze
            Toggle(isOn: $includeWarmup) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aufwärmsätze hinzufügen")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Leichtere Sätze vor den Arbeitssätzen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.blue)
            
            if includeWarmup {
                HStack {
                    Text("Anzahl Aufwärmsätze")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Picker("", selection: $warmupSets) {
                        ForEach(1...3, id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
        }
        .glassCard()
    }
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vorschau")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                // Aufwärmsätze
                if includeWarmup {
                    ForEach(1...warmupSets, id: \.self) { setNum in
                        SetPreviewRow(
                            setNumber: setNum,
                            reps: targetReps,
                            weight: calculateWarmupWeight(setNum),
                            isWarmup: true
                        )
                    }
                }
                
                // Arbeitssätze
                ForEach(1...numberOfSets, id: \.self) { setNum in
                    SetPreviewRow(
                        setNumber: (includeWarmup ? warmupSets : 0) + setNum,
                        reps: targetReps,
                        weight: targetWeight,
                        isWarmup: false
                    )
                }
            }
            
            // Zusammenfassung
            HStack {
                Label("\(totalSetsCount) Sätze", systemImage: "number.circle.fill")
                Spacer()
                Label("\(totalSetsCount * targetReps) Wdh. gesamt", systemImage: "repeat.circle.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .glassCard()
    }
    
    // MARK: - Berechnungen
    
    private var totalSetsCount: Int {
        numberOfSets + (includeWarmup ? warmupSets : 0)
    }
    
    private func calculateWarmupWeight(_ setNum: Int) -> Double {
        guard targetWeight > 0 else { return 0 }
        // Aufwärmsätze: 50%, 70%, 85% des Zielgewichts
        let percentages = [0.5, 0.7, 0.85]
        let index = min(setNum - 1, percentages.count - 1)
        return (targetWeight * percentages[index]).rounded(toNearest: 2.5)
    }
    
    // MARK: - Speichern
    
    private func saveSets() {
        var sets: [ExerciseSet] = []
        var setNumber = 1
        
        // Aufwärmsätze
        if includeWarmup {
            for i in 1...warmupSets {
                let set = ExerciseSet(
                    from: exercise,
                    setNumber: setNumber,
                    weight: calculateWarmupWeight(i),
                    reps: targetReps
                )
                set.isWarmup = true
                sets.append(set)
                setNumber += 1
            }
        }
        
        // Arbeitssätze
        for _ in 1...numberOfSets {
            let set = ExerciseSet(
                from: exercise,
                setNumber: setNumber,
                weight: targetWeight,
                reps: targetReps
            )
            sets.append(set)
            setNumber += 1
        }
        
        onSave(sets)
        dismiss()
    }
}

// MARK: - Set Preview Row

private struct SetPreviewRow: View {
    let setNumber: Int
    let reps: Int
    let weight: Double
    let isWarmup: Bool
    
    var body: some View {
        HStack {
            // Satz-Nummer
            Text("Satz \(setNumber)")
                .font(.subheadline)
                .foregroundStyle(isWarmup ? .orange : .primary)
            
            if isWarmup {
                Text("(Aufwärmen)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            // Reps × Gewicht
            HStack(spacing: 4) {
                Text("\(reps)")
                    .font(.subheadline.bold())
                
                Text("×")
                    .foregroundStyle(.secondary)
                
                Text(weight > 0 ? String(format: "%.1f kg", weight) : "–")
                    .font(.subheadline.bold())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isWarmup ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
        )
    }
}

// MARK: - Double Extension

private extension Double {
    func rounded(toNearest value: Double) -> Double {
        (self / value).rounded() * value
    }
}

// MARK: - Preview

#Preview("Set Configuration Sheet") {
    SetConfigurationSheet(
        exercise: Exercise(
            name: "Bankdrücken",
            category: .compound,
            equipment: .barbell,
            primaryMuscles: [.chest]
        )
    ) { sets in
        print("Created \(sets.count) sets")
    }
    .environmentObject(AppSettings.shared)
}
