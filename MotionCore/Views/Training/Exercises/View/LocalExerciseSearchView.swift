//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views/Exercise                                                   /
// Datei . . . . : LocalExerciseSearchView.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.04.2026                                                       /
// Beschreibung  : Lokale SwiftData-Suche für Übungen (ersetzt Supabase RPC-Suche)  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct LocalExerciseSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings

    // Callback: Der Aufrufer entscheidet was nach der Auswahl passiert
    let onSelect: (Exercise) -> Void

    // Suche & Filter
    @State private var searchText = ""
    @State private var selectedEquipment: BundledEquipmentItem?
    @State private var selectedPrimaryMuscle: MuscleGroup?
    @State private var selectedSubMuscle: DetailedMuscle?

    // Bundle-Daten (einmalig geladen)
    @State private var equipmentItems: [BundledEquipmentItem] = []

    // Sheet-State
    @State private var showFilterSheet = false

    // MARK: - Gefilterte Ergebnisse (clientseitig, kein @Query wegen komplexer Filter-Logik)

    var filteredExercises: [Exercise] {
        let searchTerm = searchText.lowercased().trimmingCharacters(in: .whitespaces)

        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []

        return all.filter { exercise in
            // Name-Filter
            let matchesSearch = searchTerm.isEmpty || exercise.name.localizedStandardContains(searchTerm)

            // Equipment-Filter: Vergleich auf equipmentRaw (Supabase snake_case Identifier)
            let matchesEquipment: Bool
            if let eq = selectedEquipment {
                matchesEquipment = exercise.equipmentRaw == eq.identifier
            } else {
                matchesEquipment = true
            }

            // Muskelgruppen-Filter
            let matchesMuscle: Bool
            if let sub = selectedSubMuscle {
                // Level 2: exakter Match auf detailedPrimaryMusclesRaw
                matchesMuscle = exercise.detailedPrimaryMusclesRaw.contains(sub.rawValue)
            } else if let primary = selectedPrimaryMuscle {
                // Level 1: alle DetailedMuscle mit passendem parentGroup → OR-Verknüpfung
                let childRawValues = DetailedMuscle.allCases
                    .filter { $0.parentGroup == primary }
                    .map { $0.rawValue }
                // Primäre DetailedMuscles prüfen — mit Fallback auf primaryMusclesRaw
                if !exercise.detailedPrimaryMusclesRaw.isEmpty {
                    matchesMuscle = exercise.detailedPrimaryMusclesRaw.contains { childRawValues.contains($0) }
                } else {
                    // Fallback: primäre grobe Muskelgruppe direkt prüfen
                    matchesMuscle = exercise.primaryMusclesRaw.contains(primary.rawValue)
                }
            } else {
                matchesMuscle = true
            }

            return matchesSearch && matchesEquipment && matchesMuscle
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

                VStack(spacing: 0) {
                    Spacer().frame(height: 8)

                    // Suchleiste mit Filter-Button
                    searchBar
                        .padding(.horizontal)

                    // Aktive-Filter-Zeile
                    if hasActiveFilters {
                        activeFiltersRow
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 20)

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
        }
        .onAppear {
            equipmentItems = BundledEquipmentService.loadAll()
        }
        .sheet(isPresented: $showFilterSheet) {
            ExerciseFilterSheet(
                selectedEquipment: $selectedEquipment,
                selectedPrimaryMuscle: $selectedPrimaryMuscle,
                selectedSubMuscle: $selectedSubMuscle,
                selectedCategory: .constant(nil),
                equipmentItems: equipmentItems
            )
        }
    }

    // MARK: - Suchleiste

    private var searchBar: some View {
        HStack(spacing: 12) {
            // Eingabefeld
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Übungsname eingeben...", text: $searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)

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

            // Filter-Button
            Button {
                showFilterSheet = true
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

    // MARK: - Aktive Filter

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
                        Text(primary.rawValue)
                            .font(.caption)
                        Button {
                            selectedPrimaryMuscle = nil
                            selectedSubMuscle = nil
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
                        Text(sub.displayName)
                            .font(.caption)
                        Button {
                            selectedSubMuscle = nil
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

    // MARK: - Ergebnisliste

    @ViewBuilder
    private var resultsList: some View {
        let results = filteredExercises

        if results.isEmpty {
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
                    ForEach(results, id: \.persistentModelID) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            LocalExerciseSearchRow(exercise: exercise)
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

    // MARK: - Hilfseigenschaften

    private var hasActiveFilters: Bool {
        selectedEquipment != nil ||
        selectedPrimaryMuscle != nil ||
        selectedSubMuscle != nil
    }
}

// MARK: - Zeilen-Komponente

private struct LocalExerciseSearchRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    // Primären Muskel anzeigen
                    if let firstMuscle = exercise.primaryMuscles.first {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                            Text(firstMuscle.description)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.secondary)
                    }

                    // Equipment anzeigen
                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell")
                            .font(.caption2)
                        Text(exercise.equipment.description)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)

                    // Schwierigkeitsgrad anzeigen
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                        Text(exercise.difficulty.description)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
        )
    }
}

// MARK: - Preview

#Preview("Local Exercise Search") {
    LocalExerciseSearchView { exercise in
        print("Ausgewählt: \(exercise.name)")
    }
    .environmentObject(AppSettings.shared)
    .modelContainer(PreviewData.sharedContainer)
}
