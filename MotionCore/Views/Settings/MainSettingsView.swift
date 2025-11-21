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

    // Zugriff auf alle Workouts für den Export
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var allWorkouts: [WorkoutSession]

    // Import/Export Funktionen
    @State private var exportURL: URL?
    @State private var showingImportPicker = false



    var body: some View {
        List {
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

            // MARK: - Daten

            Section("Daten") {
                    // Export Button
                    // Wir nutzen hier eine Group, um dem Compiler bei der Typ-Erkennung zu helfen
                Group {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("Workouts exportieren", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            exportURL = makeExportFile()
                        } label: {
                            Label("Workouts exportieren", systemImage: "square.and.arrow.up")
                        }
                        .disabled(allWorkouts.isEmpty)
                    }
                }

                    // Import Button
                Button {
                    showingImportPicker = true
                } label: {
                    Label("Workouts importieren", systemImage: "square.and.arrow.down")
                }

                    // Alle Daten löschen
                Button(role: .destructive) {
                        // TODO: Confirmation Dialog + Delete all
                } label: {
                    Label("Alle Daten löschen", systemImage: "trash")
                }
            }

            // MARK: - Einstellungen

            Section("Einstellungen") {
                NavigationLink {
                    WorkoutSettingsView()
                } label: {
                    Label("Training", systemImage: "figure.run")
                }

                NavigationLink {
                    DisplaySettingsView()
                } label: {
                    Label("Displayeinstellungen", systemImage: "display")
                }
            }

            // MARK: - Support

            Section("Support") {
                Link(destination: URL(string: "mailto:bartosz@stryjewski.email")!) {
                    Label("Kontakt", systemImage: "envelope")
                }

                NavigationLink {
                    Text("Datenschutz")
                } label: {
                    Label("Datenschutz", systemImage: "hand.raised")
                }
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { _ in
            // TODO: Import-Logik
        }
    }

    // MARK: - Export Function
    private func makeExportFile() -> URL? {
        guard !allWorkouts.isEmpty else { return nil }

        let pkg = ExportPackage(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: .now),
            items: allWorkouts.map { $0.exportItem }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(pkg)
            let filename = "MotionCore-Export-\(Int(Date().timeIntervalSince1970)).json" // Geändert: "MotionCores" → "MotionCore"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print("Export-Fehler:", error)
            return nil
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
