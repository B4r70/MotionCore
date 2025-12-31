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

struct MainSettingsView: View {

    @Environment(\.modelContext) private var modelContext

    // Für Statusanzeige / "destruktive Option nur wenn nötig"
    @Query(sort: \Exercise.name, order: .forward)
    private var allExercises: [Exercise]

    @State private var showingSeederDialog = false
    @State private var showingSeederResult = false
    @State private var seederResultMessage = ""

    var body: some View {
        List {

            // MARK: - Allgemeine Einstellungen
            Section("Allgemeine Einstellungen") {

                NavigationLink {
                    UserSettingsView()
                } label: {
                    Label("Benutzerspezifische Angaben", systemImage: "person.fill")
                }

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

            // MARK: - Daten-Management
            Section("Daten-Management") {

                NavigationLink {
                    DataSettingsView()
                } label: {
                    Label("Import & Export", systemImage: "tray.full")
                }

                    // MARK: - Seeder Button (in MainSettingsView gewünscht)
                Button {
                    showingSeederDialog = true
                } label: {
                    HStack {
                        Label("Standard-Übungen verwalten", systemImage: "square.stack.3d.up.fill")
                        Spacer()
                        Text("\(allExercises.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                .confirmationDialog(
                    "Übungsbibliothek befüllen",
                    isPresented: $showingSeederDialog,
                    titleVisibility: .visible
                ) {

                        // ✅ 1. Fehlende Standard-Übungen ergänzen (sicher)
                    Button("Fehlende Standard-Übungen ergänzen") {
                        let inserted = ExerciseSeeder.seedMissing(context: modelContext)
                        seederResultMessage = inserted > 0
                        ? "✅ \(inserted) neue Übungen hinzugefügt."
                        : "ℹ️ Keine neuen Übungen – alles bereits vorhanden."
                        showingSeederResult = true
                    }

                        // ⚠️ 2. Standard-Übungen aktualisieren (überschreibt Details)
                    if !allExercises.isEmpty {
                        Button("Standard-Übungen aktualisieren (überschreibt Details)") {
                            let result = ExerciseSeeder.upsertAll(context: modelContext)
                            seederResultMessage = "✅ Aktualisiert: \(result.updated) · \(result.inserted)"
                            showingSeederResult = true
                        }
                    }

                        // 💥 3. Komplett zurücksetzen
                    if !allExercises.isEmpty {
                        Button("Übungsbibliothek löschen & neu seeden", role: .destructive) {
                            ExerciseSeeder.reseed(context: modelContext)
                            seederResultMessage = "💥 Übungsbibliothek wurde gelöscht und neu aufgebaut."
                            showingSeederResult = true
                        }
                    }

                    Button("Abbrechen", role: .cancel) {}

                } message: {
                    if allExercises.isEmpty {
                        Text("""
                        Es sind aktuell keine Übungen vorhanden.
                        
                        Soll die Standard-Übungsbibliothek angelegt werden?
                        """)
                    } else {
                        Text("""
                        Aktuell vorhanden: \(allExercises.count) Übungen.
                        
                        • Ergänzen: fügt nur fehlende Standard-Übungen hinzu (empfohlen)
                        • Aktualisieren: überschreibt bestehende Übungsdetails
                        • Löschen & setzt die Bibliothek komplett zurück
                        """)
                    }
                }
            }

            // MARK: - App Information
            Section("App") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
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

        // MARK: - Sicherheitsabfrage
        .confirmationDialog(
            "Übungsbibliothek befüllen",
            isPresented: $showingSeederDialog,
            titleVisibility: .visible
        ) {
            Button("Fehlende Standard-Übungen ergänzen") {
                let inserted = ExerciseSeeder.seedMissing(context: modelContext)
                seederResultMessage = inserted > 0
                ? "✅ \(inserted) neue Übungen hinzugefügt."
                : "ℹ️ Keine neuen Übungen – alles bereits vorhanden."
                showingSeederResult = true
            }

            // Diese Option macht nur Sinn, wenn bereits Einträge existieren
            if !allExercises.isEmpty {
                Button("Übungsbibliothek löschen & neu seeden", role: .destructive) {
                    ExerciseSeeder.reseed(context: modelContext)
                    seederResultMessage = "Übungsbibliothek wurde gelöscht und neu aufgebaut."
                    showingSeederResult = true
                }
            }

            Button("Abbrechen", role: .cancel) {}
        } message: {
            if allExercises.isEmpty {
                Text("Es sind aktuell keine Übungen vorhanden. Soll die Standard-Übungsbibliothek angelegt werden?")
            } else {
                Text("Es sind bereits \(allExercises.count) Übungen vorhanden.\n\n„Hinzufügen“ kann Duplikate erzeugen.\n„Löschen & neu seeden“ setzt die Bibliothek komplett zurück.")
            }
        }

        // MARK: - Ergebnis
        .alert("Übungsbibliothek", isPresented: $showingSeederResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(seederResultMessage)
        }
    }
}

#Preview {
    NavigationStack {
        MainSettingsView()
    }
}
