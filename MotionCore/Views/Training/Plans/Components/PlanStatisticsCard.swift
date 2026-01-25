//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanStatisticsCard.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Statistik-Card mit Übungen, Sätzen und Volumen                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PlanStatisticsCard: View {
    let plan: TrainingPlan
    
    // Berechnete Statistiken
    private var totalExercises: Int {
        plan.groupedTemplateSets.count
    }
    
    private var totalSets: Int {
        plan.safeTemplateSets.count
    }
    
    private var workingSets: Int {
        plan.safeTemplateSets.filter { !$0.isWarmup }.count
    }
    
    private var warmupSets: Int {
        plan.safeTemplateSets.filter { $0.isWarmup }.count
    }
    
    private var totalVolume: Double {
        plan.safeTemplateSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var totalReps: Int {
        plan.safeTemplateSets.reduce(0) { $0 + $1.reps }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Übungen
            statisticItem(
                value: "\(totalExercises)",
                label: "Übungen",
                icon: "dumbbell.fill",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            // Sätze
            statisticItem(
                value: "\(totalSets)",
                label: "Sätze",
                icon: "number.circle.fill",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            // Volumen
            statisticItem(
                value: formatVolume(totalVolume),
                label: "Volumen",
                icon: "scalemass.fill",
                color: .green
            )
        }
        .glassCard()
    }
    
    // MARK: - Subviews
    
    private func statisticItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Hilfsfunktionen
    
    private func formatVolume(_ volume: Double) -> String {
        if volume <= 0 {
            return "–"
        } else if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - Erweiterte Statistik-Card (optional für DetailView)

struct PlanStatisticsDetailCard: View {
    let plan: TrainingPlan
    
    private var totalExercises: Int {
        plan.groupedTemplateSets.count
    }
    
    private var totalSets: Int {
        plan.safeTemplateSets.count
    }
    
    private var workingSets: Int {
        plan.safeTemplateSets.filter { !$0.isWarmup }.count
    }
    
    private var warmupSets: Int {
        plan.safeTemplateSets.filter { $0.isWarmup }.count
    }
    
    private var totalVolume: Double {
        plan.safeTemplateSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var totalReps: Int {
        plan.safeTemplateSets.reduce(0) { $0 + $1.reps }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistik")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                detailStatItem(value: "\(totalExercises)", label: "Übungen", icon: "dumbbell.fill", color: .blue)
                detailStatItem(value: "\(totalSets)", label: "Sätze gesamt", icon: "number.circle.fill", color: .orange)
                detailStatItem(value: "\(workingSets)", label: "Arbeitssätze", icon: "flame.fill", color: .red)
                detailStatItem(value: "\(warmupSets)", label: "Aufwärmsätze", icon: "sun.max.fill", color: .yellow)
                detailStatItem(value: "\(totalReps)", label: "Wiederholungen", icon: "repeat.circle.fill", color: .purple)
                detailStatItem(value: formatVolume(totalVolume), label: "Volumen (kg)", icon: "scalemass.fill", color: .green)
            }
        }
        .glassCard()
    }
    
    private func detailStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume <= 0 {
            return "–"
        } else if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        } else {
            return String(format: "%.0f", volume)
        }
    }
}

// MARK: - Preview

#Preview("Plan Statistics Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        VStack(spacing: 20) {
            PlanStatisticsCard(plan: TrainingPlan(title: "Push Day"))
            
            PlanStatisticsDetailCard(plan: TrainingPlan(title: "Push Day"))
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
