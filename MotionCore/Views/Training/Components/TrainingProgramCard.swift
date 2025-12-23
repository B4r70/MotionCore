//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : WorkoutPlanView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 19.12.2025                                                       /
// Beschreibung  : Hauptdisplay für den Bereich Trainingspläne                      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct TrainingProgramCard: View {
    let plan: TrainingProgramSample
    
    // Fortschritt berechnen
    private var progress: Double {
        guard plan.workoutCount > 0 else { return 0 }
        return Double(plan.completedCount) / Double(plan.workoutCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header mit Icon
            HStack {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                    
                    IconType(
                        icon: .system("calendar.badge.checkmark"),
                        color: plan.color,
                        size: 24
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(plan.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status Icon
                Image(systemName: progress == 1.0 ? "checkmark.circle.fill" : "clock.fill")
                    .font(.title3)
                    .foregroundStyle(progress == 1.0 ? .green : .orange)
            }
            
            .glassDivider(paddingTop: 12, paddingBottom: 8)
            
            // Fortschrittsanzeige
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Fortschritt")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(plan.completedCount) / \(plan.workoutCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                // Fortschrittsbalken
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Hintergrund
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // Fortschritt
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [plan.color.opacity(0.7), plan.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.spring(response: 0.6), value: progress)
                    }
                }
                .frame(height: 8)
                
                // Prozentanzeige
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.caption.bold())
                    .foregroundStyle(plan.color)
            }
            
            .glassDivider(paddingTop: 12, paddingBottom: 8)
            
            // Aktionen
            HStack(spacing: 12) {
                // Starten/Fortsetzen Button
                Button {
                    // TODO: Plan starten/fortsetzen
                    print("Plan starten/fortsetzen")
                } label: {
                    HStack {
                        Image(systemName: progress > 0 ? "play.circle.fill" : "play.fill")
                        Text(progress > 0 ? "Fortsetzen" : "Starten")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(plan.color.opacity(0.15))
                    .foregroundStyle(plan.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Details Button
                Button {
                    // TODO: Plan-Details anzeigen
                    print("Plan-Details anzeigen")
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(plan.color)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .glassCard()
    }
}
