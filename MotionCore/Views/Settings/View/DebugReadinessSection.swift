//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Einstellungen                                                    /
// Datei . . . . : DebugReadinessSection.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Debug-Sektion für Readiness-Testing: Baseline-Reset,            /
//                 Score-Override, letztes Update-Datum (nur im DEBUG-Build)        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
#if DEBUG
import SwiftUI
import SwiftData

struct DebugReadinessSection: View {

    // MARK: - Parameter

    let baselines: [HealthBaseline]

    // MARK: - Umgebung

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Lokaler State

    @State private var showingResetConfirm = false

    // MARK: - Computed

    private var latestBaselineDate: Date? {
        baselines.first?.lastUpdated
    }

    private var scoreOverrideBinding: Binding<Double> {
        Binding(
            get: { Double(appSettings.debugReadinessScoreOverride < 0 ? 50 : appSettings.debugReadinessScoreOverride) },
            set: { appSettings.debugReadinessScoreOverride = Int($0) }
        )
    }

    private var overrideActive: Bool {
        appSettings.debugReadinessScoreOverride >= 0
    }

    // MARK: - Body

    var body: some View {
        Section {
            // --- Letztes Update ---
            HStack {
                Label("Letztes Update", systemImage: "clock")
                Spacer()
                if let date = latestBaselineDate {
                    Text(date, style: .relative)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    Text("–")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            // --- Anzahl Baselines ---
            HStack {
                Label("Baselines gespeichert", systemImage: "chart.bar")
                Spacer()
                Text("\(baselines.count)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            // --- Baseline zurücksetzen ---
            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Baseline zurücksetzen", systemImage: "trash")
            }
            .confirmationDialog(
                "Alle HealthBaseline-Einträge löschen?",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    deleteAllBaselines()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Damit startet die Kalibrierung neu. Die App muss erneut 14 Tage Daten sammeln.")
            }

            // --- Score-Override ---
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(
                        overrideActive
                            ? "Score-Override: \(appSettings.debugReadinessScoreOverride)"
                            : "Score-Override: aus",
                        systemImage: "slider.horizontal.3"
                    )
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { overrideActive },
                        set: { active in
                            appSettings.debugReadinessScoreOverride = active ? 50 : -1
                        }
                    ))
                    .labelsHidden()
                }

                if overrideActive {
                    Slider(
                        value: scoreOverrideBinding,
                        in: 0...100,
                        step: 1
                    )
                    .tint(.orange)
                }
            }

        } header: {
            Label("Debug — Readiness", systemImage: "ant")
                .foregroundStyle(.orange)
        } footer: {
            Text("Nur im Debug-Build sichtbar. Score-Override ersetzt den echten Readiness-Score in der Card und im ProgressionCalcEngine.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Aktionen

    private func deleteAllBaselines() {
        for baseline in baselines {
            modelContext.delete(baseline)
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            DebugReadinessSection(baselines: [])
        }
        .navigationTitle("Debug")
    }
    .environmentObject(AppSettings.shared)
}
#endif
