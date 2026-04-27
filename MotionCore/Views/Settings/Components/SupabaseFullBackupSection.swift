// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                    /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : SupabaseFullBackupSection.swift                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 30.03.2026                                                       /
// Beschreibung  : Einstellungs-Sektion für den manuellen Supabase Full-Backup      /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

/// Einstellungs-Sektion für den manuellen Supabase Full-Backup.
/// Zeigt Fortschritt und ermöglicht das idempotente Hochladen aller lokalen Daten.
struct SupabaseFullBackupSection: View {

    @Environment(\.modelContext) private var context
    @ObservedObject private var service = SupabaseFullBackupService.shared

    var body: some View {
        Section("Supabase Full-Backup") {
            switch service.progress {

            case .idle:
                // Idle – Button anzeigen
                Button {
                    Task {
                        await service.runFullBackup(context: context)
                    }
                } label: {
                    Label("Vollständiges Backup starten", systemImage: "icloud.and.arrow.up")
                }
                .disabled(service.isRunning)

            case .running(let step, let current, let total):
                // Backup läuft – Fortschritt anzeigen
                VStack(alignment: .leading, spacing: 8) {
                    if total > 0 {
                        ProgressView(value: Double(current), total: Double(total))
                    } else {
                        ProgressView()
                    }
                    Text("\(step) (\(current)/\(total))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

            case .completed(let stats):
                // Abgeschlossen – grüne Zusammenfassung
                VStack(alignment: .leading, spacing: 6) {
                    Label("Backup erfolgreich abgeschlossen", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)

                    Group {
                        summaryRow(label: "Übungen", count: stats.exerciseMeta)
                        summaryRow(label: "Krafttrainings", count: stats.strengthSessions)
                        summaryRow(label: "Cardio-Sessions", count: stats.cardioSessions)
                        summaryRow(label: "Outdoor-Sessions", count: stats.outdoorSessions)
                        summaryRow(label: "Trainingspläne", count: stats.trainingPlans)
                        summaryRow(label: "Übungs-Sets", count: stats.exerciseSets)
                        summaryRow(label: "Template-Sets", count: stats.templateSets)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button("Erneut ausführen") {
                        service.progress = .idle
                    }
                    .font(.caption)
                    .padding(.top, 2)
                }
                .padding(.vertical, 4)

            case .failed(let error):
                // Fehler – rote Meldung + Retry-Button
                VStack(alignment: .leading, spacing: 8) {
                    Label("Backup fehlgeschlagen", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.red)

                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Erneut versuchen") {
                        Task {
                            await service.runFullBackup(context: context)
                        }
                    }
                    .disabled(service.isRunning)
                }
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            // Stuck-State-Guard: wenn progress .running zeigt aber kein Task laeuft
            // (z.B. App-Kill mid-backup, Crash, Background-Kill) → zurueck auf idle.
            if case .running = service.progress, !service.isRunning {
                service.progress = .idle
            }
        }
    }

    // MARK: - Hilfsansichten

    @ViewBuilder
    private func summaryRow(label: String, count: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)")
                .monospacedDigit()
        }
    }
}
