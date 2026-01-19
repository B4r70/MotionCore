//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanActionsSection.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Aktions-Buttons für Trainingsplan                                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct PlanActionsSection: View {
    let plan: TrainingPlan
    let onStartWorkout: () -> Void
    let onDelete: () -> Void
    
    private var accentColor: Color {
        switch plan.planType {
        case .cardio: return .blue
        case .strength: return .orange
        case .outdoor: return .green
        case .mixed: return .purple
        }
    }
    
    private var canStartWorkout: Bool {
        !plan.safeTemplateSets.isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            // Training starten (nur wenn Übungen vorhanden)
            if canStartWorkout {
                startWorkoutButton
            }
            
            // Plan bearbeiten
            editPlanButton
            
            // Plan löschen
            deletePlanButton
        }
    }
    
    // MARK: - Subviews
    
    private var startWorkoutButton: some View {
        Button {
            onStartWorkout()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Training starten")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Color.green.opacity(0.15))
            .foregroundStyle(.green)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private var editPlanButton: some View {
        NavigationLink {
            TrainingFormView(mode: .edit, plan: plan)
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Plan bearbeiten")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(accentColor.opacity(0.15))
            .foregroundStyle(accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
    
    private var deletePlanButton: some View {
        Button(role: .destructive) {
            onDelete()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Plan löschen")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Color.red.opacity(0.12))
            .foregroundStyle(.red)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Einzelne Action Row (wiederverwendbar)

struct PlanActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let showChevron: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        color: Color,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Preview

#Preview("Plan Actions Section") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        VStack(spacing: 20) {
            // Mit Übungen
            PlanActionsSection(
                plan: TrainingPlan(title: "Push Day", planType: .strength),
                onStartWorkout: { print("Start") },
                onDelete: { print("Delete") }
            )
            .padding(.horizontal)
            
            Divider()

            // Einzelne Action Rows
            VStack(spacing: 12) {
                PlanActionRow(
                    title: "Duplizieren",
                    icon: "doc.on.doc",
                    color: .blue
                ) { print("Duplicate") }
                
                PlanActionRow(
                    title: "Teilen",
                    icon: "square.and.arrow.up",
                    color: .purple,
                    showChevron: false
                ) { print("Share") }
            }
            .padding(.horizontal)
        }
    }
    .environmentObject(AppSettings.shared)
}
