///---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : SettingsView.swift                                               /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 02.11.2025                                                       /
// Function . . : Settings View                                                    /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
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
                    Text("Trainingseinstellungen")
                } label: {
                    Label("Training", systemImage: "figure.run")
                }

                NavigationLink {
                    Text("Anzeigeeinstellungen")
                } label: {
                    Label("Anzeige", systemImage: "eye")
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
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            // TODO: Import-Logik
        }
    }

    // MARK: - Export Function
    private func makeExportFile() -> URL? {
        // TODO: Diese Funktion aus ListView hierher verschieben
        // oder über ein SharedViewModel teilen
        return nil
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
