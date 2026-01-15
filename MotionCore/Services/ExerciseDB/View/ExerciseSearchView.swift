//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Exercise                                                   /
// Datei . . . . : ExerciseSearchView.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 10.01.2026                                                       /
// Beschreibung  : Suche und Import von Übungen aus Supabase                        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct ExerciseSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    @State private var searchText = ""
    @State private var searchResults: [SupabaseExercise] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var importedIDs: Set<UUID> = []

        // Filter-Optionen
    @State private var selectedFilter: SearchFilter = .name
    @State private var selectedMuscleGroup: String?
    @State private var selectedEquipment: String?

    enum SearchFilter: String, CaseIterable {
        case name = "Name"
        case muscleGroup = "Muskelgruppe"
        case equipment = "Equipment"
    }

        // Verfügbare Muskelgruppen (aus Supabase)
    let muscleGroups = [
        "abdominals", "abductors", "adductors", "biceps", "calves",
        "chest", "forearms", "glutes", "hamstrings", "lats",
        "lower back", "middle back", "neck", "quadriceps", "shoulders",
        "traps", "triceps"
    ]

        // Verfügbares Equipment (aus Supabase)
    let equipment = [
        "barbell", "dumbbell", "kettlebell", "cable", "machine",
        "bodyweight", "bands", "medicine ball", "other"
    ]

    var body: some View {
        ZStack {
                // Hintergrund
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            VStack(spacing: 0) {
                    // *NEW* Reduced top padding
                Spacer()
                    .frame(height: 8)

                    // Filter-Auswahl
                filterPicker
                    .padding(.horizontal)

                    // Suchfeld oder Dropdown je nach Filter
                searchInputSection
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // *NEW* Better spacing before results
                Spacer()
                    .frame(height: 20)

                    // Ergebnisliste
                resultsList
            }
        }
        .navigationTitle("Übung suchen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Schließen") { dismiss() }
            }
        }
        .onAppear {
            loadExistingImports()
        }
    }

        // MARK: - Filter Picker
    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(SearchFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedFilter) {
            searchResults = []
            searchText = ""
        }
    }

        // MARK: - Search Input
    @ViewBuilder
    private var searchInputSection: some View {
        switch selectedFilter {
            case .name:
                HStack(spacing: 12) {
                    TextField("Übungsname eingeben...", text: $searchText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                        )

                    Button {
                        Task { await searchByName() }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .disabled(searchText.isEmpty || isSearching)
                }

            case .muscleGroup:
                Menu {
                    Button("Auswählen...") {
                        selectedMuscleGroup = nil
                        searchResults = []
                    }

                    ForEach(muscleGroups, id: \.self) { muscle in
                        Button(muscle.capitalized) {
                            selectedMuscleGroup = muscle
                            Task { await searchByMuscleGroup(muscle) }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedMuscleGroup?.capitalized ?? "Muskelgruppe wählen")
                            .foregroundStyle(selectedMuscleGroup == nil ? .secondary : .primary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                    )
                }

            case .equipment:
                Menu {
                    Button("Auswählen...") {
                        selectedEquipment = nil
                        searchResults = []
                    }

                    ForEach(equipment, id: \.self) { eq in
                        Button(eq.capitalized) {
                            selectedEquipment = eq
                            Task { await searchByEquipment(eq) }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedEquipment?.capitalized ?? "Equipment wählen")
                            .foregroundStyle(selectedEquipment == nil ? .secondary : .primary)

                        Spacer()

                        Image(systemName: "chevron.down")
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
    }

        // MARK: - Results List
    private var resultsList: some View {
        Group {
            if isSearching {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Suche läuft...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let error = errorMessage {
                    // *NEW* Better positioned error state
                VStack(spacing: 0) {
                    Spacer()
                    EmptyState(
                        icon: "exclamationmark.triangle",
                        title: "Fehler",
                        message: error
                    )
                    Spacer()
                    Spacer() // Extra spacer to push up slightly
                }

            } else if searchResults.isEmpty {
                    // *NEW* Better positioned empty state
                VStack(spacing: 0) {
                    Spacer()
                    EmptyState(
                        icon: "magnifyingglass",
                        title: "Keine Ergebnisse",
                        message: "Starte eine Suche um Übungen zu finden"
                    )
                    Spacer()
                    Spacer() // Extra spacer to push up slightly
                }

            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.id) { exercise in
                            ExerciseSearchRow(
                                exercise: exercise,
                                isImported: importedIDs.contains(exercise.id),
                                onImport: { importExercise(exercise) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

        // MARK: - Search Methods

    private func searchByName() async {
        guard !searchText.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            searchResults = try await SupabaseExerciseService.shared.searchExercises(byName: searchText)
        } catch let err as SupabaseError {
            errorMessage = "Suche fehlgeschlagen: \(err.errorDescription ?? "Unbekannt")"
        } catch {
            errorMessage = "Suche fehlgeschlagen: \(error.localizedDescription)"
        }
        isSearching = false
    }

    private func searchByMuscleGroup(_ muscleGroup: String) async {
        isSearching = true
        errorMessage = nil
            // *TMP* Debug-Output
        do {
            let url = try SupabaseConfig.url
            let key = try SupabaseConfig.anonKey
            print("🔍 Supabase Config:")
            print("   URL: \(url)")
            print("   Key: \(key.prefix(20))...") // Nur erste 20 Zeichen
        } catch {
            print("❌ Config Error: \(error)")
        }

        do {
            searchResults = try await SupabaseExerciseService.shared.fetchExercises(byMuscleGroup: muscleGroup)
        } catch {
            errorMessage = "Suche fehlgeschlagen: \(error.localizedDescription)"
        }

        isSearching = false
    }

    private func searchByEquipment(_ equipment: String) async {
        isSearching = true
        errorMessage = nil

        // *TMP* Debug-Output
        do {
            let url = try SupabaseConfig.url
            let key = try SupabaseConfig.anonKey
            print("🔍 Supabase Config:")
            print("   URL: \(url)")
            print("   Key: \(key.prefix(20))...") // Nur erste 20 Zeichen
        } catch {
            print("❌ Config Error: \(error)")
        }

        do {
            searchResults = try await SupabaseExerciseService.shared.fetchExercises(byEquipment: equipment)
        } catch {
            errorMessage = "Suche fehlgeschlagen: \(error.localizedDescription)"
        }

        isSearching = false
    }

    // MARK: - Import

    private func importExercise(_ exercise: SupabaseExercise) {
        errorMessage = nil
        
        Task {
            do {
                    // Import + Save (läuft nicht im UI-Flow)
                try ExerciseImportManager.importFromSupabase(exercise, context: modelContext)
                
                    // UI State sicher auf dem MainActor updaten
                await MainActor.run {
                    importedIDs.insert(exercise.id)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
                }
            }
        }
    }

    private func loadExistingImports() {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiID != nil }
        )
        if let existing = try? modelContext.fetch(descriptor) {
            importedIDs = Set(existing.compactMap { $0.apiID })
        }
    }
}

// MARK: - Search Row

struct ExerciseSearchRow: View {
    let exercise: SupabaseExercise
    let isImported: Bool
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    // NEU: Primäre Muskelgruppe (nicht mehr optional)
                    if let primaryMuscle = exercise.primaryMuscles.first {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                            Text(primaryMuscle.capitalized)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    // NEU: Equipment (nicht mehr optional)
                    if let equipment = exercise.equipment.first {
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell")
                                .font(.caption2)
                            Text(equipment.capitalized)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    // NEU: Difficulty (optional mit Fallback)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                        Text((exercise.difficulty ?? "intermediate").capitalized)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isImported {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Button {
                    onImport()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
}
