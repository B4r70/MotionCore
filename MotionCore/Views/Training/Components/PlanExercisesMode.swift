//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : PlanExercisesSection.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Übungsliste mit Empty State für Trainingsplan                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Modus für die Übungsanzeige

enum PlanExercisesMode {
    case form      // Bearbeitbar mit Edit/Delete
    case detail    // Nur Anzeige
}

// MARK: - Übungs-Section

struct PlanExercisesSection: View {
    let plan: TrainingPlan
    let mode: PlanExercisesMode
    
    // Callbacks für Form-Modus
    var onAddExercise: (() -> Void)? = nil
    var onEditExercise: ((String) -> Void)? = nil
    var onDeleteExercise: ((String) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerView
            
            // Inhalt
            if plan.templateSets.isEmpty {
                emptyStateView
            } else {
                exercisesList
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Übungen")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            Spacer()
            
            switch mode {
            case .form:
                if let onAdd = onAddExercise {
                    Button {
                        onAdd()
                    } label: {
                        Label("Hinzufügen", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                }
                
            case .detail:
                if !plan.templateSets.isEmpty {
                    NavigationLink {
                        TrainingFormView(mode: .edit, plan: plan)
                    } label: {
                        Text("Bearbeiten")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Noch keine Übungen")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Füge Übungen hinzu, um deinen\nTrainingsplan zu erstellen")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if mode == .form, let onAdd = onAddExercise {
                Button {
                    onAdd()
                } label: {
                    Label("Übung hinzufügen", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.blue, in: Capsule())
                }
            } else if mode == .detail {
                NavigationLink {
                    TrainingFormView(mode: .edit, plan: plan)
                } label: {
                    Text("Übungen hinzufügen")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassCard()
        .padding(.horizontal)
    }
    
    // MARK: - Übungsliste
    
    @ViewBuilder
    private var exercisesList: some View {
        VStack(spacing: 12) {
            ForEach(Array(plan.groupedTemplateSets.enumerated()), id: \.offset) { index, setsGroup in
                if let firstSet = setsGroup.first {
                    switch mode {
                    case .form:
                        TemplateSetCard(
                            exerciseName: firstSet.exerciseName,
                            gifAssetName: firstSet.exerciseGifAssetName,
                            sets: setsGroup,
                            onDelete: {
                                onDeleteExercise?(firstSet.exerciseName)
                            },
                            onEdit: {
                                onEditExercise?(firstSet.exerciseName)
                            }
                        )
                        
                    case .detail:
                        ExerciseDetailRow(
                            exerciseName: firstSet.exerciseName,
                            gifAssetName: firstSet.exerciseGifAssetName,
                            sets: setsGroup,
                            index: index + 1
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Exercise Detail Row (für Detail-Ansicht)

struct ExerciseDetailRow: View {
    let exerciseName: String
    let gifAssetName: String
    let sets: [ExerciseSet]
    let index: Int
    
    private var workingSets: [ExerciseSet] {
        sets.filter { !$0.isWarmup }
    }
    
    private var warmupSets: [ExerciseSet] {
        sets.filter { $0.isWarmup }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Index-Nummer
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
            
            // GIF Thumbnail
            ExerciseGifView(assetName: gifAssetName, size: 50)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    // Arbeitssätze
                    if let firstWorkingSet = workingSets.first {
                        Text("\(workingSets.count) × \(firstWorkingSet.reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if firstWorkingSet.weight > 0 {
                            Text("@ \(String(format: "%.1f", firstWorkingSet.weight)) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Aufwärmsätze Indikator
                    if !warmupSets.isEmpty {
                        Text("+\(warmupSets.count) Aufwärm.")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
}

// MARK: - Preview

#Preview("Plan Exercises Section - Form Mode") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)
        
        ScrollView {
            PlanExercisesSection(
                plan: TrainingPlan(title: "Push Day"),
                mode: .form,
                onAddExercise: { print("Add") },
                onEditExercise: { name in print("Edit: \(name)") },
                onDeleteExercise: { name in print("Delete: \(name)") }
            )
        }
    }
    .environmentObject(AppSettings.shared)
}

#Preview("Plan Exercises Section - Detail Mode") {
    NavigationStack {
        ZStack {
            AnimatedBackground(showAnimatedBlob: true)
            
            ScrollView {
                PlanExercisesSection(
                    plan: TrainingPlan(title: "Push Day"),
                    mode: .detail
                )
            }
        }
    }
    .environmentObject(AppSettings.shared)
}
