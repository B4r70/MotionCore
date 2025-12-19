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
import SwiftData
import SwiftUI

struct WorkoutPlanView: View {
    // Globaler Zugriff auf AppSettings
    @EnvironmentObject private var appSettings: AppSettings
    
    // State für Beispieldaten (später durch @Query ersetzt)
    @State private var samplePlans: [WorkoutPlanSample] = [
        WorkoutPlanSample(
            title: "Anfänger Cardio Plan",
            description: "3x pro Woche, 15 Minuten",
            workoutCount: 12,
            completedCount: 5,
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Beispiel-Plan Card
                    ForEach(samplePlans) { plan in
                        WorkoutPlanCard(plan: plan)
                    }
                }
                .scrollViewContentPadding()
            }
            .scrollIndicators(.hidden)
            
            // Empty State (wenn keine Pläne vorhanden)
            if samplePlans.isEmpty {
                EmptyState()
            }
        }
        // NEU: Floating Action Button zum Erstellen neuer Pläne
        .floatingActionButton(
            icon: .system("plus"),
            color: .blue
        ) {
            // TODO: Sheet für neuen Plan öffnen
            print("Neuen Trainingsplan erstellen")
        }
    }
}

// MARK: - Workout Plan Card

struct WorkoutPlanCard: View {
    let plan: WorkoutPlanSample
    
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

// MARK: - Sample Data Model (Temporär)

struct WorkoutPlanSample: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let workoutCount: Int
    let completedCount: Int
    let color: Color
}

// MARK: - Preview

#Preview("Workout Plans") {
    NavigationStack {
        WorkoutPlanView()
            .environmentObject(AppSettings.shared)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HeaderView(
                        title: "MotionCore",
                        subtitle: "Trainingspläne"
                    )
                }
            }
    }
}