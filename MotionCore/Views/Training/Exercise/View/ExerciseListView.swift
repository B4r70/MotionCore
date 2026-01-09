//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ExerciseLibraryView.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.12.2025                                                       /
// Beschreibung  : Hauptdisplay für die Krafttraining-Übungsbibliothek              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]

    @EnvironmentObject private var appSettings: AppSettings

    // Filter States
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var selectedEquipment: ExerciseEquipment? = nil
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var showFavoritesOnly: Bool = false
    @State private var searchText: String = ""

    // NEU: Quellen-Filter
    @State private var showSystemExercises: Bool = true
    @State private var showUserExercises: Bool = true

    // Sheet State
    @State private var showingAddExercise = false
    @State private var draft = Exercise()

    // MARK: - Computed Properties

    var systemExercises: [Exercise] {
        allExercises.filter { $0.isSystemExercise }
    }

    var userExercises: [Exercise] {
        allExercises.filter { !$0.isSystemExercise }
    }

    // MARK: - Filtered Exercises

    var filteredExercises: [Exercise] {
        var exercises = allExercises

        // NEU: Quellen-Filter
        exercises = exercises.filter { exercise in
            if exercise.isSystemExercise && !showSystemExercises {
                return false
            }
            if !exercise.isSystemExercise && !showUserExercises {
                return false
            }
            return true
        }

        // Kategorie-Filter
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }

        // Equipment-Filter
        if let equipment = selectedEquipment {
            exercises = exercises.filter { $0.equipment == equipment }
        }

        // Muskelgruppen-Filter
        if let muscle = selectedMuscleGroup {
            exercises = exercises.filter { exercise in
                exercise.primaryMuscles.contains(muscle) ||
                exercise.secondaryMuscles.contains(muscle)
            }
        }

        // Favoriten-Filter
        if showFavoritesOnly {
            exercises = exercises.filter { $0.isFavorite }
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
        ZStack {
            // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            VStack(spacing: 0) {
                // MARK: Statistik-Badge (NEU)
                statisticBadge
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: Suchleiste
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: Filter-Chips
                filterChips
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: Übungsliste
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredExercises, id: \.persistentModelID) { exercise in
                            NavigationLink {
                                ExerciseFormView(mode: .edit, exercise: exercise)
                            } label: {
                                ExerciseCard(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollViewContentPadding()
                }
                .scrollIndicators(.hidden)
            }

            // Empty State
            if filteredExercises.isEmpty {
                emptyStateView
            }
        }
        .floatingActionButton(
            icon: .system("plus"),
            color: .primary
        ) {
            showingAddExercise = true
        }
        .sheet(isPresented: $showingAddExercise) {
            NavigationStack {
                ExerciseFormView(mode: .add, exercise: draft)
            }
            .environmentObject(appSettings)
            .onDisappear {
                draft = Exercise()
            }
        }
    }

    // MARK: - Subviews

    // NEU: Statistik-Badge
    private var statisticBadge: some View {
        HStack(spacing: 16) {
            // Gesamt
            HStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text("\(allExercises.count)")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("Gesamt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 20)

            // Eigene
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.green)

                Text("\(userExercises.count)")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("Eigene")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 20)

            // Importiert
            HStack(spacing: 6) {
                Image(systemName: "cloud.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text("\(systemExercises.count)")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)

                Text("API")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }

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
                // NEU: Eigene Übungen
                FilterChip(
                    title: "Eigene",
                    icon: .system("person.fill"),
                    count: userExercises.count,
                    isSelected: showUserExercises
                ) {
                    showUserExercises.toggle()
                }

                // NEU: Importierte Übungen
                FilterChip(
                    title: "Aus ExerciseDB",
                    icon: .system("cloud.fill"),
                    count: systemExercises.count,
                    isSelected: showSystemExercises
                ) {
                    showSystemExercises.toggle()
                }

                // Favoriten
                FilterChip(
                    title: "Favoriten",
                    icon: .system("star.fill"),
                    count: allExercises.filter { $0.isFavorite }.count,
                    isSelected: showFavoritesOnly
                ) {
                    showFavoritesOnly.toggle()
                }

                // Kategorien
                Menu {
                    Button("Alle Kategorien") {
                        selectedCategory = nil
                    }

                    ForEach(ExerciseCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack {
                                Text(category.description)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedCategory?.description ?? "Kategorie",
                        icon: .system("tag.fill"),
                        count: selectedCategory != nil ? 1 : 0,
                        isSelected: selectedCategory != nil
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
            }
            .padding(.horizontal, 4)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
            .shadow(color: .black.opacity(0.1), radius: 20)

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "Keine Übungen" : "Keine Treffer")
                    .font(.title2.bold())

                Text(getEmptyStateMessage())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Helper Functions

    private func getEmptyStateMessage() -> String {
        if !searchText.isEmpty {
            return "Versuche es mit anderen Filtern"
        }

        if !showUserExercises && !showSystemExercises {
            return "Aktiviere mindestens einen Quellen-Filter"
        }

        if !showUserExercises {
            return "Keine importierten Übungen vorhanden"
        }

        if !showSystemExercises {
            return "Keine eigenen Übungen vorhanden"
        }

        return "Füge deine erste Übung hinzu"
    }
}

// MARK: - Preview

#Preview("Exercise Library") {
    NavigationStack {
        ExerciseListView()
            .environmentObject(AppSettings.shared)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HeaderView(
                        title: "MotionCore",
                        subtitle: "Übungsbibliothek"
                    )
                }
            }
    }
}
