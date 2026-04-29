//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Trainingsplan                                                    /
// Datei . . . . : ExercisePickerView.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 29.04.2026                                                       /
// Beschreibung  : Wiederverwendbare Übungs-Auswahl (Suche, Filter, Liste).         /
//                 Wird sowohl von ExercisePickerSheet als auch vom                 /
//                 AddExerciseDuringWorkoutSheet (Schritt 1) eingebunden.           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ExercisePickerView: View {
    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]

    let onSelect: (Exercise) -> Void

    // Filter States
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var selectedEquipment: ExerciseEquipment? = nil
    @State private var showOnlyFavorites: Bool = false
    @State private var searchText: String = ""

    // MARK: - Filtered Exercises

    private var filteredExercises: [Exercise] {
        var exercises = allExercises

        if showOnlyFavorites {
            exercises = exercises.filter(\.isFavorite)
        }

        if let muscle = selectedMuscleGroup {
            exercises = exercises.filter { exercise in
                exercise.primaryMuscles.contains(muscle) ||
                exercise.secondaryMuscles.contains(muscle)
            }
        }

        if let equipment = selectedEquipment {
            exercises = exercises.filter { $0.equipment == equipment }
        }

        if !searchText.isEmpty {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return exercises
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 16)

                filterChips
                    .padding(.horizontal)
                    .padding(.top, 12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExercises, id: \.persistentModelID) { exercise in
                            Button {
                                onSelect(exercise)
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

            if filteredExercises.isEmpty {
                emptyStateView
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
                // Favoriten
                FilterChip(
                    title: "Favoriten",
                    icon: .system("star.fill"),
                    count: showOnlyFavorites ? 1 : 0,
                    isSelected: showOnlyFavorites
                ) {
                    showOnlyFavorites.toggle()
                }

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
            Image(systemName: showOnlyFavorites ? "star" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(showOnlyFavorites ? "Keine favorisierten Übungen" : "Keine Übungen gefunden")
                .font(.headline)

            Text(showOnlyFavorites
                 ? "Markiere eine Übung mit dem Stern, um sie hier zu sehen"
                 : "Versuche es mit anderen Filtern")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Exercise Picker Row

struct ExercisePickerRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ExerciseVideoView.forExercise(exercise, size: 56)

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
                            .foregroundStyle(Color.blue)
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
