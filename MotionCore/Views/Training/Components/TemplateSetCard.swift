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

struct TemplateSetCard: View {
    let exerciseName: String
    let gifAssetName: String
    let sets: [ExerciseSet]
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var showDeleteConfirm = false
    
    // Berechnete Werte
    private var workingSets: [ExerciseSet] {
        sets.filter { !$0.isWarmup }
    }
    
    private var warmupSets: [ExerciseSet] {
        sets.filter { $0.isWarmup }
    }
    
    private var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header mit Übungsinfo
            HStack(spacing: 12) {
                ExerciseGifView(assetName: gifAssetName, size: 56)
                
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
                
                // Aktionen
                Menu {
                    Button {
                        onEdit()
                    } label: {
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
    
    // MARK: - Zusammenfassungen
    
    private var warmupSummary: String {
        guard let first = warmupSets.first else { return "" }
        let reps = first.reps
        let weights = warmupSets.map { $0.weight }
        
        if Set(weights).count == 1 {
            return "\(warmupSets.count) × \(reps) @ \(formatWeight(weights[0]))"
        } else {
            return "\(warmupSets.count) × \(reps) (variabel)"
        }
    }
    
    private var workingSummary: String {
        guard let first = workingSets.first else { return "" }
        let reps = first.reps
        let weight = first.weight
        
        return "\(workingSets.count) × \(reps) @ \(formatWeight(weight))"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        weight > 0 ? String(format: "%.1f kg", weight) : "KG"
    }
}

// MARK: - Preview

#Preview("Template Set Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        VStack(spacing: 16) {
            TemplateSetCard(
                exerciseName: "Bankdrücken",
                gifAssetName: "",
                sets: [
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 1, weight: 40, reps: 10, isWarmup: true),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 2, weight: 60, reps: 10, isWarmup: true),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 3, weight: 80, reps: 10),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 4, weight: 80, reps: 10),
                    ExerciseSet(exerciseName: "Bankdrücken", setNumber: 5, weight: 80, reps: 10)
                ],
                onDelete: {},
                onEdit: {}
            )
            
            TemplateSetCard(
                exerciseName: "Kniebeugen",
                gifAssetName: "",
                sets: [
                    ExerciseSet(exerciseName: "Kniebeugen", setNumber: 1, weight: 100, reps: 8),
                    ExerciseSet(exerciseName: "Kniebeugen", setNumber: 2, weight: 100, reps: 8),
                    ExerciseSet(exerciseName: "Kniebeugen", setNumber: 3, weight: 100, reps: 8)
                ],
                onDelete: {},
                onEdit: {}
            )
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
