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

struct MainSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    // Daten für Prüfung der Export-Aktivierung abrufen
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    // Import/Export Funktionen
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    @State private var showingShareSheet = false

    // UI-Meldungen für Import/Export
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""

    private let dataManager = IODataManager()

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
            }

            // MARK: - App Information
            Section("App") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    AboutView()
                } label: {
                    Label("Über MotionCore", systemImage: "app.badge")
                }
            }
        }
        .navigationTitle("Einstellungen")
        // Share Sheet für Export
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
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
