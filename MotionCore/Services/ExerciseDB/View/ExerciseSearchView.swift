//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Exercise                                                   /
// Datei . . . . : ExerciseSearchView.swift                                         /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 10.01.2026                                                       /
// Beschreibung  : Suche und Import von Übungen aus ExerciseDB API                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct ExerciseSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [UnifiedExercise] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var importedIDs: Set<String> = []
    
    // Filter-Optionen
    @State private var selectedFilter: SearchFilter = .name
    @State private var selectedTarget: String?
    @State private var selectedEquipment: String?
    @State private var selectedBodyPart: String?
    
    enum SearchFilter: String, CaseIterable {
        case name = "Name"
        case target = "Zielmuskel"
        case equipment = "Equipment"
        case bodyPart = "Körperteil"
    }
    
    // Verfügbare Optionen
    let targets = ["abductors", "abs", "adductors", "biceps", "calves", 
                   "cardiovascular system", "delts", "forearms", "glutes", 
                   "hamstrings", "lats", "levator scapulae", "pectorals", 
                   "quads", "serratus anterior", "spine", "traps", "triceps", "upper back"]
    
    let equipment = ["assisted", "band", "barbell", "body weight", "bosu ball", 
                     "cable", "dumbbell", "elliptical machine", "ez barbell", 
                     "hammer", "kettlebell", "leverage machine", "medicine ball",
                     "olympic barbell", "resistance band", "roller", "rope", 
                     "skierg machine", "sled machine", "smith machine", 
                     "stability ball", "stationary bike", "stepmill machine", 
                     "tire", "trap bar", "upper body ergometer", "weighted", "wheel roller"]
    
    let bodyParts = ["back", "cardio", "chest", "lower arms", "lower legs", 
                     "neck", "shoulders", "upper arms", "upper legs", "waist"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter-Auswahl
                filterPicker
                
                // Suchfeld oder Dropdown je nach Filter
                searchInputSection
                
                // Ergebnisliste
                resultsList
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
        .padding()
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
            HStack {
                TextField("Übungsname eingeben...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    Task { await searchByName() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .padding(10)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(searchText.isEmpty || isSearching)
            }
            .padding(.horizontal)
            
        case .target:
            Picker("Zielmuskel wählen", selection: $selectedTarget) {
                Text("Auswählen...").tag(nil as String?)
                ForEach(targets, id: \.self) { target in
                    Text(target.capitalized).tag(target as String?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .onChange(of: selectedTarget) { _, newValue in
                if let target = newValue {
                    Task { await searchByTarget(target) }
                }
            }
            
        case .equipment:
            Picker("Equipment wählen", selection: $selectedEquipment) {
                Text("Auswählen...").tag(nil as String?)
                ForEach(equipment, id: \.self) { eq in
                    Text(eq.capitalized).tag(eq as String?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .onChange(of: selectedEquipment) { _, newValue in
                if let eq = newValue {
                    Task { await searchByEquipment(eq) }
                }
            }
            
        case .bodyPart:
            Picker("Körperteil wählen", selection: $selectedBodyPart) {
                Text("Auswählen...").tag(nil as String?)
                ForEach(bodyParts, id: \.self) { part in
                    Text(part.capitalized).tag(part as String?)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .onChange(of: selectedBodyPart) { _, newValue in
                if let part = newValue {
                    Task { await searchByBodyPart(part) }
                }
            }
        }
    }
    
    // MARK: - Results List
    private var resultsList: some View {
        Group {
            if isSearching {
                ProgressView("Suche läuft...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Fehler", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if searchResults.isEmpty {
                ContentUnavailableView {
                    Label("Keine Ergebnisse", systemImage: "magnifyingglass")
                } description: {
                    Text("Starte eine Suche um Übungen zu finden")
                }
            } else {
                List(searchResults, id: \.id) { exercise in
                    ExerciseSearchRow(
                        exercise: exercise,
                        isImported: importedIDs.contains(exercise.id),
                        onImport: { importExercise(exercise) }
                    )
                }
            }
        }
    }
    
    // MARK: - Search Methods
    private func searchByName() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await ExerciseDBService.shared.searchByName(searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func searchByTarget(_ target: String) async {
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await ExerciseDBService.shared.getByTarget(target)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func searchByEquipment(_ equipment: String) async {
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await ExerciseDBService.shared.getByEquipment(equipment)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func searchByBodyPart(_ bodyPart: String) async {
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await ExerciseDBService.shared.getByBodyPart(bodyPart)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    // MARK: - Import
    private func importExercise(_ exercise: UnifiedExercise) {
        do {
            let success = try ExerciseImportManager.importSingleExercise(exercise, context: modelContext)
            if success {
                importedIDs.insert(exercise.id)
            }
        } catch {
            errorMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
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
    let exercise: UnifiedExercise
    let isImported: Bool
    let onImport: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let target = exercise.targetMuscles.first {
                        Label(target.capitalized, systemImage: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let equipment = exercise.equipment.first {
                        Label(equipment.capitalized, systemImage: "dumbbell")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if isImported {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    onImport()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
