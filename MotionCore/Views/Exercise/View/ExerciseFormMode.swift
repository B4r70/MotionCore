//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ExerciseFormView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.12.2025                                                       /
// Beschreibung  : Formular zum Erstellen/Bearbeiten von Übungen                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

enum ExerciseFormMode { case add, edit }

struct ExerciseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let mode: ExerciseFormMode
    
    @Bindable var exercise: Exercise
    @EnvironmentObject private var appSettings: AppSettings
    
    // Lösch-Bestätigung
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Titel
                        Text("Übungsdaten")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        
                        // MARK: Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            TextField("z.B. Bankdrücken", text: $exercise.name)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                        }
                        
                        // MARK: Beschreibung
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beschreibung (optional)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            TextField("Ausführung, Tipps...", text: $exercise.exerciseDescription, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                        }
                        
                        // MARK: Kategorie
                        HStack {
                            Text("Kategorie")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Menu {
                                Picker("", selection: $exercise.category) {
                                    ForEach(ExerciseCategory.allCases) { category in
                                        Label(category.description, systemImage: category.icon)
                                            .tag(category)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(exercise.category.description)
                                        .foregroundStyle(.primary)
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        // MARK: Equipment
                        HStack {
                            Text("Gerät/Equipment")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Menu {
                                Picker("", selection: $exercise.equipment) {
                                    ForEach(ExerciseEquipment.allCases) { equipment in
                                        Label(equipment.description, systemImage: equipment.icon)
                                            .tag(equipment)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(exercise.equipment.description)
                                        .foregroundStyle(.primary)
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        // MARK: Schwierigkeit
                        HStack {
                            Text("Schwierigkeit")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Menu {
                                Picker("", selection: $exercise.difficulty) {
                                    ForEach(ExerciseDifficulty.allCases) { difficulty in
                                        HStack {
                                            Text(difficulty.description)
                                            Spacer()
                                            HStack(spacing: 2) {
                                                ForEach(0..<difficulty.stars, id: \.self) { _ in
                                                    Image(systemName: "star.fill")
                                                }
                                            }
                                        }
                                        .tag(difficulty)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(exercise.difficulty.description)
                                        .foregroundStyle(.primary)
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        // MARK: Primäre Muskelgruppen
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Primäre Muskelgruppen")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            NavigationLink {
                                MuscleGroupPicker(
                                    selectedMuscles: $exercise.primaryMuscles,
                                    title: "Primäre Muskelgruppen"
                                )
                            } label: {
                                HStack {
                                    if exercise.primaryMuscles.isEmpty {
                                        Text("Keine ausgewählt")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                                                    Text(muscle.description)
                                                        .font(.caption)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(.blue.opacity(0.2))
                                                        .foregroundStyle(.blue)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                            }
                        }
                        
                        // MARK: Sekundäre Muskelgruppen
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sekundäre Muskelgruppen (optional)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            NavigationLink {
                                MuscleGroupPicker(
                                    selectedMuscles: $exercise.secondaryMuscles,
                                    title: "Sekundäre Muskelgruppen"
                                )
                            } label: {
                                HStack {
                                    if exercise.secondaryMuscles.isEmpty {
                                        Text("Keine ausgewählt")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                                                    Text(muscle.description)
                                                        .font(.caption)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background(.purple.opacity(0.2))
                                                        .foregroundStyle(.purple)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                            }
                        }
                        
                        // MARK: GIF Asset Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GIF-Name (optional)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            TextField("z.B. bench_press", text: $exercise.gifAssetName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                                )
                        }
                        
                        // MARK: Favorit
                        Toggle(isOn: $exercise.isFavorite) {
                            HStack(spacing: 8) {
                                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(exercise.isFavorite ? .yellow : .secondary)
                                
                                Text("Als Favorit markieren")
                                    .foregroundStyle(.primary)
                            }
                        }
                        .tint(.yellow)
                    }
                    .glassCard()
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(mode == .add ? "Neue Übung" : "Bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Speichern
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if mode == .add { 
                        exercise.isCustom = true
                        context.insert(exercise) 
                    }
                    try? context.save()
                    dismiss()
                } label: {
                    IconType(icon: .system("checkmark"), color: .blue, size: 16)
                        .glassButton(size: 36, accentColor: .blue)
                }
                .disabled(exercise.name.isEmpty)
            }
            
            // Löschen im Edit-Modus
            if mode == .edit {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        IconType(icon: .system("trash"), color: .red, size: 16)
                            .glassButton(size: 36, accentColor: .red)
                    }
                }
            }
        }
        .alert("Übung löschen?", isPresented: $showDeleteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                deleteExercise()
            }
        } message: {
            Text("Diese Übung wird unwiderruflich gelöscht.")
        }
    }
    
    // MARK: - Hilfsfunktionen
    
    private func deleteExercise() {
        context.delete(exercise)
        try? context.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Exercise Form - Add") {
    NavigationStack {
        ExerciseFormView(mode: .add, exercise: Exercise())
            .environmentObject(AppSettings.shared)
    }
}
