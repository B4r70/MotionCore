//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : MainSettingsView.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.11.2025                                                       /
// Beschreibung  : Konfigurationshauptdisplay                                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
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

    // Import/Export Funktionen
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false

    // Exercise Import/Export
    @State private var showingExerciseImportPicker = false
    @State private var exerciseExportURL: URL?
    @State private var showingExerciseShareSheet = false

    // StrengthSession Import/Export
    @State private var showingStrengthImportPicker = false
    @State private var strengthExportURL: URL?
    @State private var showingStrengthShareSheet = false

    // TrainingPlan Import/Export
    @State private var showingPlanImportPicker = false
    @State private var planExportURL: URL?
    @State private var showingPlanShareSheet = false

    // ExerciseSet Import/Export
    @State private var showingSetImportPicker = false
    @State private var setExportURL: URL?
    @State private var showingSetShareSheet = false

    // OutdoorSession Import/Export
    @State private var showingOutdoorImportPicker = false
    @State private var outdoorExportURL: URL?
    @State private var showingOutdoorShareSheet = false

    // ExerciseDB API Import
    @State private var isImportingFromAPI = false
    @State private var showingAPIImportConfirmation = false
    @State private var apiImportResult: ExerciseImportResult?
    @State private var showingAPIImportResult = false
    @State private var currentBatchIndex = 0

    // UI-Meldungen für Import/Export
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingDeleteConfirmation = false

    private let dataManager = IODataManager()

    // MARK: - Computed Properties
    var systemExercises: [Exercise] {
        allExercises.filter { $0.isSystemExercise }
    }

    var userExercises: [Exercise] {
        allExercises.filter { !$0.isSystemExercise }
    }

    // MARK: - Helper Functions
    private func handleExport() {
        do {
            exportURL = try dataManager.exportWorkouts(context: modelContext)
            showingShareSheet = true
        } catch let error as DataIOError {
            importErrorMessage = error.errorDescription ?? "Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importErrorMessage = "Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    private func handleDeleteAllData() {
        do {
            let count = try dataManager.deleteAllWorkouts(context: modelContext)

            if count > 0 {
                importErrorMessage = "Alle \(count) Workouts wurden erfolgreich gelöscht."
            } else {
                importErrorMessage = "Es waren keine Workouts vorhanden. Nichts gelöscht."
            }

            showingImportSuccess = true

        } catch {
            let deleteError = error as? DataIOError
            importErrorMessage = deleteError?.errorDescription ?? "Unbekannter Fehler beim Löschen."
            showingImportError = true
        }
    }

    private func handleExerciseExport() {
        do {
            exerciseExportURL = try dataManager.exportExercises(context: modelContext)
            showingExerciseShareSheet = true
        } catch let error as DataIOError {
            importErrorMessage = error.errorDescription ?? "Exercise-Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importErrorMessage = "Exercise-Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    private func handleStrengthExport() {
        do {
            strengthExportURL = try dataManager.exportStrengthSessions(context: modelContext)
            showingStrengthShareSheet = true
        } catch let error as DataIOError {
            importErrorMessage = error.errorDescription ?? "Krafttraining-Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importErrorMessage = "Krafttraining-Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    private func handleOutdoorExport() {
        do {
            outdoorExportURL = try dataManager.exportOutdoorSessions(context: modelContext)
            showingOutdoorShareSheet = true
        } catch let error as DataIOError {
            importErrorMessage = error.errorDescription ?? "Outdoor-Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importErrorMessage = "Outdoor-Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    private func handlePlanExport() {
        do {
            planExportURL = try dataManager.exportTrainingPlans(context: modelContext)
            showingPlanShareSheet = true
        } catch let error as DataIOError {
            importErrorMessage = error.errorDescription ?? "Trainingsplan-Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importErrorMessage = "Trainingsplan-Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    private func handleSetExport() {
        do {
            setExportURL = try dataManager.exportExerciseSets(context: modelContext)
            showingSetShareSheet = true
        } catch let error as DataIOError {
            importErrorMessage = error.errorDescription ?? "ExerciseSet-Export fehlgeschlagen"
            showingImportError = true
        } catch {
            importErrorMessage = "ExerciseSet-Export-Fehler: \(error.localizedDescription)"
            showingImportError = true
        }
    }

    // MARK: - ExerciseDB API Import
    private func startAPIImport() {
        isImportingFromAPI = true

        Task {
            do {
                let result = try await ExerciseImportManager.importBatch(
                    context: modelContext,
                    startIndex: currentBatchIndex,
                    batchSize: 10
                )

                await MainActor.run {
                    isImportingFromAPI = false
                    apiImportResult = result
                    showingAPIImportResult = true
                    currentBatchIndex += 10
                }

            } catch {
                await MainActor.run {
                    isImportingFromAPI = false
                    importErrorMessage = "API-Import Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            }
        }
    }

    // MARK: - Body
    var body: some View {
        List {
            // MARK: - Übungsbibliothek Statistik
            Section {
                HStack {
                    Text("Eigene Übungen")
                    Spacer()
                    Text("\(userExercises.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Importierte Übungen (API)")
                    Spacer()
                    Text("\(systemExercises.count)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Gesamt")
                    Spacer()
                    Text("\(allExercises.count)")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Übungsbibliothek")
            }

            // MARK: - ExerciseDB API Import
            Section {
                Button {
                    showingAPIImportConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Übungen importieren")
                                .foregroundStyle(.primary)
                            Text("exercisedb.p.rapidapi.com")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isImportingFromAPI {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isImportingFromAPI)

                if isImportingFromAPI {
                    HStack(spacing: 12) {
                        ProgressView()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import läuft...")
                                .font(.subheadline)
                            Text("Lade Übungen \(currentBatchIndex) bis \(currentBatchIndex + 10)...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if currentBatchIndex > 0 && !isImportingFromAPI {
                    Button(role: .destructive) {
                        currentBatchIndex = 0
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Batch-Index zurücksetzen")
                        }
                    }
                }

            } header: {
                Text("ExerciseDB API")
            } footer: {
                Text("Importiert 10 Übungen pro Durchgang. Aktueller Index: \(currentBatchIndex). Bereits vorhandene Übungen werden übersprungen.")
                    .font(.caption)
            }

            // MARK: - Workouts
            Section("Workouts") {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        handleExport()
                    } label: {
                        Label("Workouts exportieren", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allWorkouts.isEmpty)

                    Divider()
                        .padding(8)

                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Workouts importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }

            // MARK: Übungsbibliothek Export/Import (JSON)
            Section("Übungsbibliothek (JSON)") {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        handleExerciseExport()
                    } label: {
                        Label("Übungsbibliothek exportieren", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allExercises.isEmpty)

                    Divider()
                        .padding(8)

                    Button {
                        showingExerciseImportPicker = true
                    } label: {
                        Label("Übungsbibliothek importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }

            // MARK: Krafttraining Export/Import
            Section("Krafttrainings") {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        handleStrengthExport()
                    } label: {
                        Label("Krafttrainings exportieren", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allStrengthSessions.isEmpty)

                    Divider()
                        .padding(8)

                    Button {
                        showingStrengthImportPicker = true
                    } label: {
                        Label("Krafttrainings importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }

            // MARK: Trainingspläne Export/Import
            Section("Trainingsplan") {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        handlePlanExport()
                    } label: {
                        Label("Trainingspläne exportieren", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allTrainingPlans.isEmpty)

                    Divider()
                        .padding(8)

                    Button {
                        showingPlanImportPicker = true
                    } label: {
                        Label("Trainingspläne importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }

            // MARK: Übungssätze Export/Import
            Section("Übungssätze") {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        handleSetExport()
                    } label: {
                        Label("Übungssätze exportieren", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allExerciseSets.isEmpty)

                    Divider()
                        .padding(8)

                    Button {
                        showingSetImportPicker = true
                    } label: {
                        Label("Übungssätze importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }

            // MARK: Outdoor Export/Import
            Section("Outdoor-Trainings") {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        handleOutdoorExport()
                    } label: {
                        Label("Outdoor-Trainings exportieren", systemImage: "square.and.arrow.up")
                    }
                    .disabled(allOutdoorSessions.isEmpty)

                    Divider()
                        .padding(8)

                    Button {
                        showingOutdoorImportPicker = true
                    } label: {
                        Label("Outdoor-Trainings importieren", systemImage: "square.and.arrow.down")
                    }
                }
            }

            // MARK: - Gefahrenzone
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

        // MARK: - Share Sheets
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingExerciseShareSheet) {
            if let url = exerciseExportURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingStrengthShareSheet) {
            if let url = strengthExportURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingPlanShareSheet) {
            if let url = planExportURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingSetShareSheet) {
            if let url = setExportURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingOutdoorShareSheet) {
            if let url = outdoorExportURL {
                ShareSheet(items: [url])
            }
        }

        // MARK: - File Importers
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let count = try dataManager.importWorkouts(context: modelContext, url: url)
                    if count > 0 {
                        importErrorMessage = "Import erfolgreich! \(count) Workouts wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importErrorMessage = "Die Datei enthielt keine Workouts zum Importieren."
                        showingImportError = true
                    }
                } catch let error as DataIOError {
                    importErrorMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importErrorMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        .fileImporter(
            isPresented: $showingExerciseImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let count = try dataManager.importExercises(context: modelContext, url: url)
                    if count > 0 {
                        importErrorMessage = "Import erfolgreich! \(count) Übungen wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importErrorMessage = "Die Datei enthielt keine Übungen zum Importieren."
                        showingImportError = true
                    }
                } catch let error as DataIOError {
                    importErrorMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importErrorMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        .fileImporter(
            isPresented: $showingStrengthImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let count = try dataManager.importStrengthSessions(context: modelContext, url: url)
                    if count > 0 {
                        importErrorMessage = "Import erfolgreich! \(count) Krafttrainings wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importErrorMessage = "Die Datei enthielt keine Krafttrainings zum Importieren."
                        showingImportError = true
                    }
                } catch let error as DataIOError {
                    importErrorMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importErrorMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        .fileImporter(
            isPresented: $showingPlanImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let count = try dataManager.importTrainingPlans(context: modelContext, url: url)
                    if count > 0 {
                        importErrorMessage = "Import erfolgreich! \(count) Trainingspläne wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importErrorMessage = "Die Datei enthielt keine Trainingspläne zum Importieren."
                        showingImportError = true
                    }
                } catch let error as DataIOError {
                    importErrorMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importErrorMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        .fileImporter(
            isPresented: $showingSetImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let count = try dataManager.importExerciseSets(context: modelContext, url: url)
                    if count > 0 {
                        importErrorMessage = "Import erfolgreich! \(count) Übungssätze wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importErrorMessage = "Die Datei enthielt keine Übungssätze zum Importieren."
                        showingImportError = true
                    }
                } catch let error as DataIOError {
                    importErrorMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importErrorMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }
        .fileImporter(
            isPresented: $showingOutdoorImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    let count = try dataManager.importOutdoorSessions(context: modelContext, url: url)
                    if count > 0 {
                        importErrorMessage = "Import erfolgreich! \(count) Outdoor-Trainings wurden hinzugefügt."
                        showingImportSuccess = true
                    } else {
                        importErrorMessage = "Die Datei enthielt keine Outdoor-Trainings zum Importieren."
                        showingImportError = true
                    }
                } catch let error as DataIOError {
                    importErrorMessage = error.errorDescription ?? "Unbekannter Fehler beim Import."
                    showingImportError = true
                } catch {
                    importErrorMessage = "Allgemeiner Import-Fehler: \(error.localizedDescription)"
                    showingImportError = true
                }
            case .failure(let error):
                importErrorMessage = "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                showingImportError = true
            }
        }

        // MARK: - Alerts
        .alert("Import erfolgreich", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .alert("Fehler", isPresented: $showingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }

        // ExerciseDB API Import Result
        .alert("ExerciseDB Import abgeschlossen", isPresented: $showingAPIImportResult) {
            Button("OK") {
                apiImportResult = nil
            }
        } message: {
            if let result = apiImportResult {
                Text("""
                Von API geladen: \(result.totalFetched) Übungen
                Neu importiert: \(result.imported)
                Übersprungen (bereits vorhanden): \(result.skipped)
                \(result.errors.isEmpty ? "" : "\nFehler: \(result.errors.count)")
                
                Deine Bibliothek enthält jetzt:
                • \(userExercises.count) eigene Übungen
                • \(systemExercises.count) importierte Übungen
                • \(allExercises.count) Übungen gesamt
                """)
            }
        }

        // ExerciseDB API Import Confirmation
        .confirmationDialog(
            "ExerciseDB Import",
            isPresented: $showingAPIImportConfirmation,
            titleVisibility: .visible
        ) {
            Button("10 Übungen importieren") {
                startAPIImport()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Importiert 10 Übungen von ExerciseDB (Index \(currentBatchIndex) bis \(currentBatchIndex + 10)).\n\nBereits vorhandene Übungen werden automatisch übersprungen.")
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
}

// MARK: - ShareSheet UIKit Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataSettingsView()
            .modelContainer(for: [Exercise.self, CardioSession.self])
    }
}
