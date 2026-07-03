//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Übungsbibliothek                                                 /
// Datei . . . . : ExerciseListView.swift                                           /
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

    // Quellen-Filter
    @State private var showOnlyFavorites: Bool = false

    // Detail-Filter (Sheet)
    @State private var selectedEquipment: BundledEquipmentItem? = nil
    @State private var selectedPrimaryMuscle: MuscleGroup? = nil
    @State private var selectedSubMuscle: DetailedMuscle? = nil
    @State private var selectedCategory: ExerciseCategory? = nil

    // Equipment-Daten aus Bundle
    @State private var equipmentItems: [BundledEquipmentItem] = []

    // Sheet States
    @State private var showFilterSheet: Bool = false
    @State private var showingAddExercise = false
    @State private var draft = Exercise()

    // Suche
    @State private var searchText: String = ""

    // MARK: - Computed Properties

    var systemExercises: [Exercise] {
        allExercises.filter { $0.isSystemExercise }
    }

    var userExercises: [Exercise] {
        allExercises.filter { !$0.isSystemExercise }
    }

    var hasActiveDetailFilters: Bool {
        selectedEquipment != nil || selectedPrimaryMuscle != nil
            || selectedSubMuscle != nil || selectedCategory != nil
    }

    // MARK: - Filtered Exercises

    var filteredExercises: [Exercise] {
        var exercises = allExercises

        // Favoriten-Filter
        if showOnlyFavorites {
            exercises = exercises.filter { $0.isFavorite }
        }

        // Equipment-Filter: Bundle-Identifier → Enum-Mapping, dann Vergleich auf equipmentRaw
        if let equipment = selectedEquipment {
            let targetRaw = ExerciseEquipment.fromSupabase(equipment.identifier).rawValue
            exercises = exercises.filter { $0.equipmentRaw == targetRaw }
        }

        // Muskelgruppen-Filter (zweistufig)
        if let sub = selectedSubMuscle {
            // Level 2: exakter DetailedMuscle-Match
            exercises = exercises.filter { $0.detailedPrimaryMusclesRaw.contains(sub.rawValue) }
        } else if let group = selectedPrimaryMuscle {
            // Level 1: alle DetailedMuscles dieser Gruppe prüfen
            let childRawValues = DetailedMuscle.allCases
                .filter { $0.parentGroup == group }
                .map { $0.rawValue }
            exercises = exercises.filter { exercise in
                if !exercise.detailedPrimaryMusclesRaw.isEmpty {
                    return exercise.detailedPrimaryMusclesRaw.contains { childRawValues.contains($0) }
                } else {
                    return exercise.primaryMusclesRaw.contains(group.rawValue)
                }
            }
        }

        // Kategorie-Filter
        if let cat = selectedCategory {
            exercises = exercises.filter { $0.category == cat }
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
            Theme.surfaceApp.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Statistik-Badge
                statisticBadge
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: Suchleiste
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: FilterBar
                filterBar
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: Aktive Detail-Filter-Tags
                if hasActiveDetailFilters {
                    activeFiltersRow
                        .padding(.top, 8)
                }

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Löschen-Button (nur für System-Übungen)
                                if exercise.isSystemExercise {
                                    Button(role: .destructive) {
                                        deleteExercise(exercise)
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }

                                // Archivieren-Button (für alle Übungen)
                                Button {
                                    toggleArchive(exercise)
                                } label: {
                                    Label(
                                        exercise.isArchived ? "Aktivieren" : "Archivieren",
                                        systemImage: exercise.isArchived ? "tray.and.arrow.up" : "archivebox"
                                    )
                                }
                                .tint(Theme.warning)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                // Favorit-Toggle
                                Button {
                                    toggleFavorite(exercise)
                                } label: {
                                    Label(
                                        exercise.isFavorite ? "Entfernen" : "Favorit",
                                        systemImage: exercise.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(Theme.success)
                            }
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
            color: Theme.textPrimary
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
        .sheet(isPresented: $showFilterSheet) {
            ExerciseFilterSheet(
                selectedEquipment: $selectedEquipment,
                selectedPrimaryMuscle: $selectedPrimaryMuscle,
                selectedSubMuscle: $selectedSubMuscle,
                selectedCategory: $selectedCategory,
                equipmentItems: equipmentItems
            )
        }
        .task {
            equipmentItems = BundledEquipmentService.loadAll()
        }
    }

    // MARK: - Subviews

    // Statistik-Badge
    private var statisticBadge: some View {
        HStack(spacing: 16) {
            // Gesamt
            HStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)

                Text("\(allExercises.count)")
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text("Gesamt")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Divider()
                .frame(height: 20)

            // Eigene
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)

                Text("\(userExercises.count)")
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text("Eigene")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Divider()
                .frame(height: 20)

            // System-Übungen
            HStack(spacing: 6) {
                Image(systemName: "bookmark.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)

                Text("\(systemExercises.count)")
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)

                Text("System")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, Space.s4)
        .padding(.vertical, Space.s3)
        .background(Theme.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textSecondary)

            TextField("Übung suchen...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(Space.s3)
        .background(Theme.surfaceSunken, in: RoundedRectangle(cornerRadius: Radius.md))
    }

    // FilterBar: Toggle-Buttons + Trichter-Button
    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterToggleButton(label: "Favoriten", icon: "heart.fill", isActive: $showOnlyFavorites)

            Spacer()

            Button {
                showFilterSheet = true
            } label: {
                Image(systemName: hasActiveDetailFilters
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
                    .foregroundStyle(hasActiveDetailFilters ? Theme.accent : Theme.textSecondary)
                    .font(.title3)
            }
        }
    }

    // Aktive Detail-Filter als entfernbare Capsule-Tags
    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let eq = selectedEquipment {
                    ActiveFilterTag(label: eq.name) {
                        selectedEquipment = nil
                    }
                }

                if let sub = selectedSubMuscle {
                    ActiveFilterTag(label: sub.displayName) {
                        selectedSubMuscle = nil
                        selectedPrimaryMuscle = nil
                    }
                } else if let group = selectedPrimaryMuscle {
                    ActiveFilterTag(label: group.rawValue) {
                        selectedPrimaryMuscle = nil
                    }
                }

                if let cat = selectedCategory {
                    ActiveFilterTag(label: cat.description) {
                        selectedCategory = nil
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.surfaceSunken)
                    .frame(width: 120, height: 120)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Theme.accent)
            }
            .shadow(color: .black.opacity(0.1), radius: 20)

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "Keine Übungen" : "Keine Treffer")
                    .font(.title2.bold())

                Text(getEmptyStateMessage())
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(Theme.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    // MARK: - Helper Functions

    private func getEmptyStateMessage() -> String {
        if !searchText.isEmpty {
            return "Versuche es mit anderen Filtern"
        }

        if hasActiveDetailFilters {
            return "Keine Übungen für die gewählten Filter"
        }

        return "Füge deine erste Übung hinzu"
    }

    // MARK: - Actions

    private func deleteExercise(_ exercise: Exercise) {
        do {
            try ExerciseImportManager.deleteExercise(exercise, context: modelContext)
        } catch {
            print("❌ Fehler beim Löschen: \(error.localizedDescription)")
        }
    }

    private func toggleFavorite(_ exercise: Exercise) {
        exercise.isFavorite.toggle()
        try? modelContext.save()
    }

    private func toggleArchive(_ exercise: Exercise) {
        exercise.isArchived.toggle()
        try? modelContext.save()
    }
}

// MARK: - FilterToggleButton

private struct FilterToggleButton: View {
    let label: String
    let icon: String
    @Binding var isActive: Bool

    var body: some View {
        Button {
            isActive.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption.bold())
            }
            .foregroundStyle(isActive ? Color.white : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? Theme.accent : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Theme.accent : Theme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ActiveFilterTag

private struct ActiveFilterTag: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.accent)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.accentSoft, in: Capsule())
        .overlay(Capsule().stroke(Theme.accent, lineWidth: 1))
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
    .modelContainer(PreviewData.sharedContainer)
}
