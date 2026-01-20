//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Exercise                                                   /
// Datei . . . . : ExerciseSearchView.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 10.01.2026                                                       /
// Beschreibung  : Suche und Import von Übungen aus Supabase mit erweiterten Filtern/
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
    @EnvironmentObject private var filterService: SupabaseFilterService

    // Search & Results
    @State private var searchText = ""
    @State private var searchResults: [SupabaseExerciseSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var importedIDs: Set<UUID> = []

    // Advanced Filters
    @State private var showAdvancedFilter = false
    @State private var selectedEquipment: SupabaseEquipment?
    @State private var selectedPrimaryMuscle: SupabaseMuscleGroup?
    @State private var selectedSubMuscle: SupabaseMuscleGroup?

    // State für Success Toast
    @State private var showSuccessToast = false
    @State private var lastImportedName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    // Search Bar mit Filter Button
                    searchBar
                        .padding(.horizontal)

                    // Active Filters Display
                    if hasActiveFilters {
                        activeFiltersRow
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 20)

                    // Results List
                    resultsList
                }

                // Success Toast
                if showSuccessToast {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green)

                            Text("\(lastImportedName) importiert!")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.green, lineWidth: 2))
                        .shadow(color: .green.opacity(0.3), radius: 8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Übung suchen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .onAppear {
            loadExistingImports()
            // Filter laden
            Task {
                await filterService.loadAllFilters(languageCode: "de")
            }
        }
        .sheet(isPresented: $showAdvancedFilter) {
            ExerciseFilterSheet(
                selectedEquipment: $selectedEquipment,
                selectedPrimaryMuscle: $selectedPrimaryMuscle,
                selectedSubMuscle: $selectedSubMuscle
            )
            .environmentObject(filterService)
        }
        .onChange(of: selectedEquipment) { _, _ in performSearch() }
        .onChange(of: selectedPrimaryMuscle) { _, _ in performSearch() }
        .onChange(of: selectedSubMuscle) { _, _ in performSearch() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Übungsname eingeben...", text: $searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
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

            // Filter Button
            Button {
                showAdvancedFilter = true
            } label: {
                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundStyle(hasActiveFilters ? .blue : .secondary)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                    )
            }
        }
    }

    // MARK: - Active Filters Row

    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let equipment = selectedEquipment {
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption2)
                        Text(equipment.name)
                            .font(.caption)
                        Button {
                            selectedEquipment = nil
                            performSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.blue, lineWidth: 1))
                }

                if let primary = selectedPrimaryMuscle {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.arms.open")
                            .font(.caption2)
                        Text(primary.name)
                            .font(.caption)
                        Button {
                            selectedPrimaryMuscle = nil
                            selectedSubMuscle = nil
                            performSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.green, lineWidth: 1))
                }

                if let sub = selectedSubMuscle {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .font(.caption2)
                        Text(sub.name)
                            .font(.caption)
                        Button {
                            selectedSubMuscle = nil
                            performSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.green.opacity(0.6), lineWidth: 1))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Results List

    @ViewBuilder
    private var resultsList: some View {
        if isSearching {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Suche läuft...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else if let error = errorMessage {
            VStack(spacing: 0) {
                Spacer()
                EmptyState(
                    icon: "exclamationmark.triangle",
                    title: "Fehler",
                    message: error
                )
                Spacer()
                Spacer()
            }

        } else if searchResults.isEmpty {
            VStack(spacing: 0) {
                Spacer()
                EmptyState(
                    icon: "magnifyingglass",
                    title: "Keine Ergebnisse",
                    message: hasActiveFilters || !searchText.isEmpty
                        ? "Keine Übungen gefunden. Versuche andere Filter."
                        : "Starte eine Suche oder wähle Filter"
                )
                Spacer()
                Spacer()
            }

        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults, id: \.id) { exercise in
                        NavigationLink {
                            ExerciseSearchDetailView(
                                searchResult: exercise,
                                isImported: importedIDs.contains(exercise.id),
                                onImport: {
                                    importExercise(exercise)
                                }
                            )
                            .environmentObject(appSettings)
                        } label: {
                            ExerciseSearchRow(
                                exercise: exercise,
                                isImported: importedIDs.contains(exercise.id),
                                onImport: { importExercise(exercise) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Search

    private func performSearch() {
        Task {
            await executeSearch()
        }
    }

    private func executeSearch() async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        let languageCode = "de"

        // Search term normalisieren
        let trimmedTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let usableTerm: String? = (trimmedTerm.count >= 2) ? trimmedTerm : nil

        // Filter-IDs bestimmen (Subgroup hat Priorität)
        let selectedEquipmentId: UUID? = selectedEquipment?.id
        let selectedMuscleGroupId: UUID? = selectedSubMuscle?.id ?? selectedPrimaryMuscle?.id

        // Wenn gar kein Kriterium gesetzt ist -> keine Suche
        let hasAnyCriteria = (usableTerm != nil) || (selectedEquipmentId != nil) || (selectedMuscleGroupId != nil)
        guard hasAnyCriteria else {
            searchResults = []
            return
        }

        do {
            searchResults = try await SupabaseExerciseService.shared.searchExercises(
                byName: usableTerm,
                equipmentId: selectedEquipmentId,
                muscleGroupId: selectedMuscleGroupId,
                languageCode: languageCode,
                limit: 50,
                offset: 0
            )
        } catch let err as SupabaseError {
            errorMessage = "Suche fehlgeschlagen: \(err.errorDescription ?? "Unbekannt")"
        } catch {
            errorMessage = "Suche fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    // MARK: - Import

    private func importExercise(_ searchResult: SupabaseExerciseSearchResult) {
        errorMessage = nil

        Task {
            do {
                // Konvertiere SearchResult zu Exercise-Import Format
                try await importFromSearchResult(searchResult)

                await MainActor.run {
                    importedIDs.insert(searchResult.id)

                    // Success Toast anzeigen
                    lastImportedName = searchResult.name
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSuccessToast = true
                    }

                    // Toast nach 2 Sekunden ausblenden
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            withAnimation {
                                showSuccessToast = false
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
                }
            }
        }
    }

    // Helper: Import von SearchResult
    private func importFromSearchResult(_ result: SupabaseExerciseSearchResult) async throws {
        // ✅ ID VORHER extrahieren (außerhalb des Predicates)
        let searchId = result.id

        // Prüfe ob bereits importiert
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.apiID == searchId
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            print("⚠️ Exercise bereits importiert: \(existing.name)")
            return
        }

        // Konvertiere String-Arrays zu MuscleGroup Enums
        let primaryMuscles: [MuscleGroup] = result.muscles.compactMap { muscleName in
            MuscleGroup.allCases.first { $0.rawValue.lowercased().contains(muscleName.lowercased()) }
        }

        // Equipment Mapping (nimm erstes aus Array)
        let equipmentEnum: ExerciseEquipment = {
            guard let firstEquipment = result.equipment.first else { return .bodyweight }
            return ExerciseEquipment.fromSupabase(firstEquipment)  // ✅ String, nicht [String]
        }()

        // Difficulty Mapping
        let difficultyEnum: ExerciseDifficulty = {
            guard let diff = result.difficulty else { return .intermediate }
            return ExerciseDifficulty.fromSupabase(diff)
        }()

        // Category Mapping (aus result)
        let categoryEnum: ExerciseCategory = {
            guard let cat = result.category else { return .compound }
            return ExerciseCategory.fromSupabase(
                mechanic: result.mechanicType,
                force: result.forceType
            )
        }()

        // Erstelle neue Exercise mit ALLEN Feldern
        let newExercise = Exercise(
            name: result.name,
            exerciseDescription: result.description ?? "",
            mediaAssetName: "",
            isCustom: false,
            isFavorite: false,
            createdAt: Date(),
            isUnilateral: false,
            repRangeMin: 8,
            repRangeMax: 12,
            sortIndex: 0,
            cautionNote: "",
            isArchived: false,
            apiID: result.id,
            isSystemExercise: true,
            videoPath: result.videoPath,     // ✅ Aus SQL Result
            posterPath: result.posterPath,   // ✅ Aus SQL Result
            instructions: result.description,
            localVideoFileName: nil,
            apiBodyPart: nil,
            apiTarget: nil,
            apiEquipment: result.equipment.first,
            apiSecondaryMuscles: Array(result.muscles.dropFirst()),
            apiProvider: "supabase",
            apiOverview: nil,
            apiExerciseTips: nil,
            apiVariations: nil,
            apiImageURL: nil,
            categoryRaw: categoryEnum.rawValue,
            equipmentRaw: equipmentEnum.rawValue,
            difficultyRaw: difficultyEnum.rawValue,
            movementPatternRaw: "push",
            bodyPositionRaw: "standing",
            primaryMusclesRaw: primaryMuscles.map { $0.rawValue },
            secondaryMusclesRaw: []
        )

        // Speichern
        modelContext.insert(newExercise)
        try modelContext.save()

        print("✅ Exercise importiert: \(newExercise.name) (Video: \(result.videoPath ?? "N/A"), Poster: \(result.posterPath ?? "N/A"))")
    }

    private func loadExistingImports() {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.apiID != nil }
        )
        if let existing = try? modelContext.fetch(descriptor) {
            importedIDs = Set(existing.compactMap { $0.apiID })
        }
    }

    // MARK: - Helpers

    private var hasActiveFilters: Bool {
        selectedEquipment != nil ||
        selectedPrimaryMuscle != nil ||
        selectedSubMuscle != nil
    }
}

// MARK: - Search Row

struct ExerciseSearchRow: View {
    let exercise: SupabaseExerciseSearchResult
    let isImported: Bool
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let firstMuscle = exercise.muscles.first {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                            Text(firstMuscle)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if let firstEquipment = exercise.equipment.first {
                        HStack(spacing: 4) {
                            Image(systemName: "dumbbell")
                                .font(.caption2)
                            Text(firstEquipment)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if let difficulty = exercise.difficulty {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption2)
                            Text(difficulty.capitalized)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isImported {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Button(action: onImport) {
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
