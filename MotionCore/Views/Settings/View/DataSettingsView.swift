//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
//----------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : DataSettingsView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.11.2025                                                       /
// Beschreibung  : Konfigurationshauptdisplay für Datenimport/-export              /
//----------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
//----------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation

struct DataSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    // MARK: Queries für die Core Entities
    @Query(sort: \CardioSession.date, order: .reverse)
    private var allWorkouts: [CardioSession]

    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allStrengthSessions: [StrengthSession]

    @Query(sort: \OutdoorSession.date, order: .reverse)
    private var allOutdoorSessions: [OutdoorSession]

    // MARK: Queries für die Supporting Entities
    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]

    @Query(sort: \TrainingPlan.title, order: .forward)
    private var allTrainingPlans: [TrainingPlan]

    @Query(sort: \ExerciseSet.exerciseName, order: .forward)
    private var allExerciseSets: [ExerciseSet]

    // UI-Meldungen für Import/Export
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importMessage = ""
    @State private var showingDeleteConfirmation = false

    // Single Share Sheet
    @State private var activeShareURL: URL?
    @State private var showingShareSheet = false

    // Single File Importer
    @State private var showingImporter = false
    @State private var activeImport: ImportKind?

    private let dataManager = IODataManager()

    enum ImportKind: String {
        case workouts
        case exercises
        case strength
        case plans
        case sets
        case outdoor
    }

    // MARK: - Computed Properties
    var systemExercises: [Exercise] { allExercises.filter { $0.isSystemExercise } }
    var userExercises: [Exercise] { allExercises.filter { !$0.isSystemExercise } }
    var supabaseExercises: [Exercise] { allExercises.filter { $0.apiProvider == "supabase" } }

    // MARK: - Security Scoped Access Helper (Sandbox fix)
    private func withSecurityScopedAccess<T>(to url: URL, _ work: () throws -> T) rethrows -> T {
        let didStart = url.startAccessingSecurityScopedResource()
        defer { if didStart { url.stopAccessingSecurityScopedResource() } }
        return try work()
    }

    // MARK: - Export Helpers
    private func export(_ kind: ImportKind) {
        do {
            let url: URL
            switch kind {
            case .workouts:
                url = try dataManager.exportWorkouts(context: modelContext)
            case .exercises:
                url = try dataManager.exportExercises(context: modelContext)
            case .strength:
                url = try dataManager.exportStrengthSessions(context: modelContext)
            case .plans:
                url = try dataManager.exportTrainingPlans(context: modelContext)
            case .sets:
                url = try dataManager.exportExerciseSets(context: modelContext)
            case .outdoor:
                url = try dataManager.exportOutdoorSessions(context: modelContext)
            }

            activeShareURL = url
            showingShareSheet = true
        } catch let error as DataIOError {
            importMessage = error.errorDescription ?? "Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importMessage = "Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    // MARK: - Import Trigger
    private func startImport(_ kind: ImportKind) {
        activeImport = kind
        showingImporter = true
    }

    // MARK: - Delete
    private func handleDeleteAllData() {
        do {
            let count = try dataManager.deleteAllWorkouts(context: modelContext)
            importMessage = count > 0
                ? "Alle \(count) Workouts wurden erfolgreich gelöscht."
                : "Es waren keine Workouts vorhanden. Nichts gelöscht."
            showingImportSuccess = true
        } catch {
            let deleteError = error as? DataIOError
            importMessage = deleteError?.errorDescription ?? "Unbekannter Fehler beim Löschen."
            showingImportError = true
        }
    }

    // MARK: - Body
    var body: some View {
        List {
            // Übungsbibliothek Statistik
            Section {
                statRow("Eigene Übungen", userExercises.count)
                statRow("Supabase Übungen", supabaseExercises.count)
                statRow("Gesamt", allExercises.count, emphasize: true)
            } header: {
                Text("Übungsbibliothek")
            } footer: {
                Text("Übungen aus Supabase können über die Übungsbibliothek importiert werden (Lupen-Symbol).")
                    .font(.caption)
            }

            // Workouts
            Section("Workouts") {
                Button {
                    export(.workouts)
                } label: {
                    Label("Workouts exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allWorkouts.isEmpty)

                Divider().padding(.vertical, 6)

                Button {
                    startImport(.workouts)
                } label: {
                    Label("Workouts importieren", systemImage: "square.and.arrow.down")
                }
            }

            // Übungsbibliothek (JSON)
            Section("Übungsbibliothek (JSON)") {
                Button {
                    export(.exercises)
                } label: {
                    Label("Übungsbibliothek exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allExercises.isEmpty)

                Divider().padding(.vertical, 6)

                Button {
                    startImport(.exercises)
                } label: {
                    Label("Übungsbibliothek importieren", systemImage: "square.and.arrow.down")
                }
            }

            // Krafttrainings
            Section("Krafttrainings") {
                Button {
                    export(.strength)
                } label: {
                    Label("Krafttrainings exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allStrengthSessions.isEmpty)

                Divider().padding(.vertical, 6)

                Button {
                    startImport(.strength)
                } label: {
                    Label("Krafttrainings importieren", systemImage: "square.and.arrow.down")
                }
            }

            // Trainingspläne
            Section("Trainingsplan") {
                Button {
                    export(.plans)
                } label: {
                    Label("Trainingspläne exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allTrainingPlans.isEmpty)

                Divider().padding(.vertical, 6)

                Button {
                    startImport(.plans)
                } label: {
                    Label("Trainingspläne importieren", systemImage: "square.and.arrow.down")
                }
            }

            // Übungssätze
            Section("Übungssätze") {
                Button {
                    export(.sets)
                } label: {
                    Label("Übungssätze exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allExerciseSets.isEmpty)

                Divider().padding(.vertical, 6)

                Button {
                    startImport(.sets)
                } label: {
                    Label("Übungssätze importieren", systemImage: "square.and.arrow.down")
                }
            }

            // Outdoor
            Section("Outdoor-Trainings") {
                Button {
                    export(.outdoor)
                } label: {
                    Label("Outdoor-Trainings exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allOutdoorSessions.isEmpty)

                Divider().padding(.vertical, 6)

                Button {
                    startImport(.outdoor)
                } label: {
                    Label("Outdoor-Trainings importieren", systemImage: "square.and.arrow.down")
                }
            }

            // Gefahrenzone
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Alle Workouts löschen", systemImage: "trash")
                }
                .disabled(allWorkouts.isEmpty)
            } header: {
                Text("Gefahrenzone")
            } footer: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
        .navigationTitle("Daten")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ Single Share Sheet
        .sheet(isPresented: $showingShareSheet) {
            if let url = activeShareURL {
                ShareSheet(items: [url])
            }
        }

        // ✅ Single File Importer (robust!)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            guard let kind = activeImport else { return }

            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }

                do {
                    let count: Int = try withSecurityScopedAccess(to: url) {
                        switch kind {
                        case .workouts:
                            return try dataManager.importWorkouts(context: modelContext, url: url)
                        case .exercises:
                            return try dataManager.importExercises(context: modelContext, url: url)
                        case .strength:
                            return try dataManager.importStrengthSessions(context: modelContext, url: url)
                        case .plans:
                            return try dataManager.importTrainingPlans(context: modelContext, url: url)
                        case .sets:
                            return try dataManager.importExerciseSets(context: modelContext, url: url)
                        case .outdoor:
                            return try dataManager.importOutdoorSessions(context: modelContext, url: url)
                        }
                    }

                    if count > 0 {
                        importMessage = "Import erfolgreich! \(count) Einträge wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importMessage = "Die Datei enthielt keine Einträge zum Importieren."
                        showingImportError = true
                    }

                } catch let error as DataIOError {
                    importMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }

            case .failure(let error):
                importMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }

        // Alerts
        .alert("Import erfolgreich", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage)
        }
        .alert("Fehler", isPresented: $showingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage)
        }

        // Delete Confirmation
        .confirmationDialog("Workouts löschen", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("ALLE Workouts unwiderruflich löschen", role: .destructive) {
                handleDeleteAllData()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden. Sind Sie sicher, dass Sie alle gespeicherten Trainingsdaten unwiderruflich löschen möchten?")
        }
    }

    private func statRow(_ title: String, _ value: Int, emphasize: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
                .fontWeight(emphasize ? .semibold : .regular)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - ShareSheet UIKit Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
