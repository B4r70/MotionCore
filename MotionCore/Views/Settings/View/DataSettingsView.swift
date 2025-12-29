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

    // Daten für Prüfung der Export-Aktivierung abrufen
    @Query(sort: \CardioSession.date, order: .reverse)
    private var allWorkouts: [CardioSession]

    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]

    // Queries für weitere Datentypen
    @Query(sort: \StrengthSession.date, order: .reverse)
    private var allStrengthSessions: [StrengthSession]

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

    // UI-Meldungen für Import/Export
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingDeleteConfirmation = false

    private let dataManager = IODataManager()

    // MARK: - Helper Functions
    // Exportfunktion
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
    // Löschfunktion
    private func handleDeleteAllData() {
        do {
            // Ruft die Funktion des Managers auf und übergibt den ModelContext.
            let count = try dataManager.deleteAllWorkouts(context: modelContext)

            // Erfolg: Manager hat die Anzahl der gelöschten Workouts zurückgegeben.
            if count > 0 {
                importErrorMessage = "Alle \(count) Workouts wurden erfolgreich gelöscht."
            } else {
                importErrorMessage = "Es waren keine Workouts vorhanden. Nichts gelöscht."
            }

            // Zeigt den Erfolgs-Alert an
            showingImportSuccess = true

        } catch {
            // Fehler wird hier abgefangen. DataIOError wurde im Manager geworfen.
            let deleteError = error as? DataIOError

            // Zeigt die entsprechende Fehlermeldung an
            importErrorMessage = deleteError?.errorDescription ?? "Unbekannter Fehler beim Löschen."
            showingImportError = true // Zeigt den Fehler-Alert an
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

    //  StrengthSession Export
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

    // TrainingPlan Export
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

    // ExerciseSet Export
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

    var body: some View {
        List {

            // MARK: - Allgemeine Einstellungen
            Section("Allgemeine Einstellungen") {
                // Benutzerspezifische Angaben
                NavigationLink {
                    UserSettingsView()
                } label: {
                    Label("Benutzerspezifische Angaben", systemImage: "person.fill")
                }
                // Workouteinstellungen
                NavigationLink {
                    WorkoutSettingsView()
                } label: {
                    Label("Training", systemImage: "figure.run")
                }
                // Displayeinstellungen
                NavigationLink {
                    DisplaySettingsView()
                } label: {
                    Label("Displayeinstellungen", systemImage: "display")
                }
            }

            // MARK: - Daten-Management
            Section("Daten-Management") {
                // Export-Funktion
                Button {
                    handleExport()
                } label: {
                    Label("Workouts exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allWorkouts.isEmpty)

                // Import-Funktion
                Button {
                    showingImportPicker = true
                } label: {
                    Label("Workouts importieren", systemImage: "square.and.arrow.down")
                }

                // Exercise Export
                Button {
                    handleExerciseExport()
                } label: {
                    Label("Übungen exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allExercises.isEmpty)

                    // Exercise Import
                Button {
                    showingExerciseImportPicker = true
                } label: {
                    Label("Übungen importieren", systemImage: "square.and.arrow.down")
                }

                // StrengthSession Export
                Button {
                    handleStrengthExport()
                } label: {
                    Label("Krafttrainings exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allStrengthSessions.isEmpty)

                // StrengthSession Import
                Button {
                    showingStrengthImportPicker = true
                } label: {
                    Label("Krafttrainings importieren", systemImage: "square.and.arrow.down")
                }

                // TrainingPlan Export
                Button {
                    handlePlanExport()
                } label: {
                    Label("Trainingspläne exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allTrainingPlans.isEmpty)

                // TrainingPlan Import
                Button {
                    showingPlanImportPicker = true
                } label: {
                    Label("Trainingspläne importieren", systemImage: "square.and.arrow.down")
                }

                // ExerciseSet Export
                Button {
                    handleSetExport()
                } label: {
                    Label("Übungssätze exportieren", systemImage: "square.and.arrow.up")
                }
                .disabled(allExerciseSets.isEmpty)

                // ExerciseSet Import
                Button {
                    showingSetImportPicker = true
                } label: {
                    Label("Übungssätze importieren", systemImage: "square.and.arrow.down")
                }

                Button(role: .destructive) { // Rote Farbe für destruktive Aktion
                    showingDeleteConfirmation = true
                } label: {
                    Label("Alle Workouts löschen", systemImage: "trash.fill")
                }
            }

            // MARK: - App Information
            Section("App") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    // Automatische Version aus Xcode Target
                    Text(Bundle.main.fullVersion)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    AboutView()
                } label: {
                    Label("Über MotionCore", systemImage: "app.badge")
                }
            }
        }
        .padding(.top, 20)
        .navigationTitle("Einstellungen")
        // Share Sheet für Export
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        //
        .sheet(isPresented: $showingExerciseShareSheet) {
            if let url = exerciseExportURL {
                ShareSheet(items: [url])
            }
        }
        // Share Sheet für StrengthSessions
        .sheet(isPresented: $showingStrengthShareSheet) {
            if let url = strengthExportURL {
                ShareSheet(items: [url])
            }
        }
        // Share Sheet für TrainingPlans
        .sheet(isPresented: $showingPlanShareSheet) {
            if let url = planExportURL {
                ShareSheet(items: [url])
            }
        }
        // Share Sheet für ExerciseSets
        .sheet(isPresented: $showingSetShareSheet) {
            if let url = setExportURL {
                ShareSheet(items: [url])
            }
        }

        // File Importer Aufruf
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
        // File Importer für Exercises
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
        // File Importer für StrengthSessions
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
        // File Importer für TrainingPlans
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
        // File Importer für ExerciseSets
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
        // UI-Meldungen für Import
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
        .confirmationDialog("Workouts löschen", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("ALLE Workouts unwiderruflich löschen", role: .destructive) {
                // HIER erfolgt der Aufruf der Funktion
                handleDeleteAllData()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden. Sind Sie sicher, dass Sie alle gespeicherten Trainingsdaten unwiderruflich löschen möchten?")
        }
    }
}

// MARK: - ShareSheet UIKit Wrapper
struct SharesSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
