//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : SupabaseSyncSection.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.03.2026                                                       /
// Beschreibung  : Einstellungs-Sektion für den manuellen Supabase Session Sync     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

/// Einstellungs-Sektion für den manuellen Supabase Session Sync.
/// Zeigt Fortschritt und ermöglicht die einmalige historische Migration.
struct SupabaseSyncSection: View {

    @Environment(\.modelContext) private var context
    @StateObject private var service = SupabaseMigrationService.shared

    var body: some View {
        Section("Supabase Sync") {
            if service.isRunning {
                // Migration läuft
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: service.progress)
                    Text("\(service.uploadedCount) / \(service.totalCount) hochgeladen…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

            } else if service.isDone {
                // Migration abgeschlossen
                Label(
                    "\(service.uploadedCount) Sessions hochgeladen",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)

                if service.failedCount > 0 {
                    Text("\(service.failedCount) fehlgeschlagen – beim nächsten Sync wiederholt")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

            } else {
                // Idle – Button anzeigen
                Button("Historische Sessions synchronisieren") {
                    Task {
                        await service.migrate(context: context)
                    }
                }
            }
        }
    }
}
