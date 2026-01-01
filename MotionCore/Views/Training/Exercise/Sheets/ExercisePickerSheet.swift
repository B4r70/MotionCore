//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : ExercisePickerSheet.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 27.12.2025                                                       /
// Beschreibung  : Sheet zum Auswählen einer Übung aus der Bibliothek               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]
    
    @EnvironmentObject private var appSettings: AppSettings
    
    // Callback wenn eine Übung ausgewählt wurde
    let onSelect: (Exercise) -> Void
    
    // Filter States
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var selectedEquipment: ExerciseEquipment? = nil
    @State private var searchText: String = ""
    
    // MARK: - Filtered Exercises
    
    private var filteredExercises: [Exercise] {
        var exercises = allExercises
        
        // Muskelgruppen-Filter
        if let muscle = selectedMuscleGroup {
            exercises = exercises.filter { exercise in
                exercise.primaryMuscles.contains(muscle) ||
                exercise.secondaryMuscles.contains(muscle)
            }
        }
        
        // Equipment-Filter
        if let equipment = selectedEquipment {
            exercises = exercises.filter { $0.equipment == equipment }
        }
        
        // Suchtext-Filter
        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return exercises
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                
                VStack(spacing: 0) {
                    // Suchleiste
                    searchBar
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Filter-Chips
                    filterChips
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    // Übungsliste
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    ExercisePickerRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                }
                
                // Empty State
                if filteredExercises.isEmpty {
                    emptyStateView
                }
            }
            .navigationTitle("Übung wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Übung suchen...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Muskelgruppen
                Menu {
                    Button("Alle Muskelgruppen") {
                        selectedMuscleGroup = nil
                    }
                    
                    ForEach(MuscleGroup.allCases) { muscle in
                        Button {
                            selectedMuscleGroup = muscle
                        } label: {
                            HStack {
                                Text(muscle.description)
                                Spacer()
                                if selectedMuscleGroup == muscle {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedMuscleGroup?.description ?? "Muskel",
                        icon: .system("figure.strengthtraining.traditional"),
                        count: selectedMuscleGroup != nil ? 1 : 0,
                        isSelected: selectedMuscleGroup != nil
                    ) {}
                }
                
                // Equipment
                Menu {
                    Button("Alle Geräte") {
                        selectedEquipment = nil
                    }
                    
                    ForEach(ExerciseEquipment.allCases) { equipment in
                        Button {
                            selectedEquipment = equipment
                        } label: {
                            HStack {
                                Text(equipment.description)
                                Spacer()
                                if selectedEquipment == equipment {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedEquipment?.description ?? "Gerät",
                        icon: .system("dumbbell.fill"),
                        count: selectedEquipment != nil ? 1 : 0,
                        isSelected: selectedEquipment != nil
                    ) {}
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("Keine Übungen gefunden")
                .font(.headline)
            
            Text("Versuche es mit anderen Filtern")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Exercise Picker Row

private struct ExercisePickerRow: View {
    let exercise: Exercise
    
    var body: some View {
        HStack(spacing: 12) {
            // GIF Thumbnail
            ExerciseGifView(assetName: exercise.gifAssetName, size: 56)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Label(exercise.equipment.description, systemImage: exercise.equipment.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let primaryMuscle = exercise.primaryMuscles.first {
                        Text(primaryMuscle.description)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
}

// MARK: - Preview

#Preview("Exercise Picker Sheet") {
    ExercisePickerSheet { exercise in
        print("Selected: \(exercise.name)")
    }
    .environmentObject(AppSettings.shared)
}
