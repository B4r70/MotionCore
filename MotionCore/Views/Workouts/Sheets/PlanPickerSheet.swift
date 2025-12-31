//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Sheets                                                           /
// Datei . . . . : TrainingPlanPickerSheet.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 31.12.2025                                                       /
// Beschreibung  : Auswahl-Sheet für Trainingspläne beim Starten einer Session      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct PlanPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var appSettings: AppSettings
    
    @Query(sort: \TrainingPlan.title) private var trainingPlans: [TrainingPlan]
    
    // Callback wenn ein Plan ausgewählt wurde
    var onPlanSelected: (TrainingPlan) -> Void
    
    // Nur Krafttraining-Pläne anzeigen
    private var strengthPlans: [TrainingPlan] {
        trainingPlans.filter { $0.planType == .strength || $0.planType == .mixed }
    }
    
    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Trainingsplan wählen")
                        .font(.title2.bold())
                    
                    Text("Wähle einen Plan für dein Krafttraining")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                if strengthPlans.isEmpty {
                    // Leerer Zustand
                    emptyState
                } else {
                    // Liste der Trainingspläne
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(strengthPlans) { plan in
                                TrainingPlanRow(plan: plan) {
                                    onPlanSelected(plan)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("Keine Trainingspläne")
                .font(.headline)
            
            Text("Erstelle zuerst einen Trainingsplan\nim Training-Tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Schließen") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Training Plan Row

private struct TrainingPlanRow: View {
    let plan: TrainingPlan
    let action: () -> Void
    
    // Farbe basierend auf PlanType
    private var planColor: Color {
        switch plan.planType {
        case .strength: return .orange
        case .cardio: return .green
        case .outdoor: return .blue
        case .mixed: return .purple
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon mit PlanType Farbe
                ZStack {
                    Circle()
                        .fill(planColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: plan.planType.icon)
                        .font(.title2)
                        .foregroundStyle(planColor)
                }
                
                // Plan-Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        // Anzahl Übungen (Template-Sets gruppiert)
                        let exerciseCount = Set(plan.templateSets.map { $0.exerciseName }).count
                        Label("\(exerciseCount) Übungen", systemImage: "dumbbell")
                        
                        // Anzahl Sets
                        Label("\(plan.templateSets.count) Sets", systemImage: "list.number")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Start-Button
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    PlanPickerSheet { plan in
        print("Selected: \(plan.title)")
    }
    .modelContainer(PreviewData.sharedContainer)
    .environmentObject(AppSettings.shared)
}
