//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Readiness                                               /
// Datei . . . . : ReadinessDetailView.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 24.04.2026                                                       /
// Beschreibung  : Detail-Sheet zur SessionReadiness — Score, Faktoren,             /
//                 optionale Energie/Stress-Eingabe (Phase 2)                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct ReadinessDetailView: View {

    // MARK: - Eingaben

    let readiness: SessionReadiness

    // MARK: - Umgebung

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    @Query private var baselines: [HealthBaseline]

    // MARK: - ViewModel

    @State private var viewModel = ReadinessViewModel()

    // MARK: - Lokaler UI-State (User-Input)

    /// Energie-Level: 1 = niedrig, 2 = mittel, 3 = hoch (nil = noch nicht gesetzt)
    @State private var energySelection: Int? = nil
    /// Stress-Level analog
    @State private var stressSelection: ReadinessStressInput? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        scoreHeader
                        if readiness.isCalibrating {
                            calibratingSection
                        } else {
                            if !viewModel.breakdown.isEmpty {
                                factorsSection
                            }
                            userInputSection
                        }
                    }
                    .scrollViewContentPadding()
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Tagesform")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .onAppear {
            // ViewModel mit aktuellem Readiness-Snapshot befüllen
            viewModel.load(
                readiness: readiness,
                baselines: baselines,
                takesCardioMedication: appSettings.takesCardioMedication,
                debugScoreOverride: appSettings.debugReadinessScoreOverride
            )
            // Gespeicherte User-Inputs wiederherstellen
            energySelection = readiness.userEnergyLevel
            if let raw = readiness.userStressLevelRaw {
                stressSelection = ReadinessStressInput(rawValue: raw)
            }
        }
    }

    // MARK: - Score-Header

    private var scoreHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.label.systemIcon)
                .font(.system(size: 44))
                .foregroundStyle(viewModel.label.color)

            Text("\(viewModel.score)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.label.color)

            Text(viewModel.label.localizedTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard()
    }

    // MARK: - Faktoren-Section

    private var factorsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Einflussfaktoren")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(viewModel.breakdown.indices, id: \.self) { idx in
                    ReadinessFactorRow(factor: viewModel.breakdown[idx])
                        .padding(.horizontal, 4)
                    if idx < viewModel.breakdown.count - 1 {
                        Divider()
                            .padding(.horizontal, 4)
                    }
                }
            }
            .glassCard()
        }
    }

    // MARK: - User-Input-Section

    private var userInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wie fühlst du dich?")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                // Energie-Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Energie")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Energie", selection: Binding(
                        get: { energySelection ?? 0 },
                        set: { newValue in
                            energySelection = newValue == 0 ? nil : newValue
                            applyUserInput()
                        }
                    )) {
                        Text("–").tag(0)
                        Text("Niedrig").tag(1)
                        Text("Mittel").tag(2)
                        Text("Hoch").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // Stress-Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stress")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Stress", selection: Binding(
                        get: { stressSelection },
                        set: { newValue in
                            stressSelection = newValue
                            applyUserInput()
                        }
                    )) {
                        Text("–").tag(ReadinessStressInput?.none)
                        Text("Niedrig").tag(ReadinessStressInput?.some(.low))
                        Text("Mittel").tag(ReadinessStressInput?.some(.medium))
                        Text("Hoch").tag(ReadinessStressInput?.some(.high))
                    }
                    .pickerStyle(.segmented)
                }
            }
            .glassCard()
        }
    }

    // MARK: - Kalibrierungs-Section

    private var calibratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Kalibrierung läuft", systemImage: "clock.badge")
                .font(.headline)
                .foregroundStyle(.yellow)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("MotionCore sammelt noch Gesundheitsdaten, um deine persönliche Baseline zu ermitteln. Nach etwa 14 Tagen steht dein personalisierter Readiness-Score bereit.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                // TODO (Schritt 2.9): sampleCount aus SessionReadiness lesen sobald
                // die Felder (hrvSampleCount, sleepSampleCount, restingHRSampleCount,
                // activitySampleCount) im Model ergänzt wurden.
                // Bis dahin werden die HealthBaseline-Einträge als Proxy genutzt.
                let requiredSamples = 14

                CalibrationProgressRow(
                    metricName: "HRV",
                    sampleCount: baselineSampleCount(for: .hrv),
                    requiredSamples: requiredSamples
                )
                Divider()
                CalibrationProgressRow(
                    metricName: "Schlaf",
                    sampleCount: baselineSampleCount(for: .sleep),
                    requiredSamples: requiredSamples
                )
                Divider()
                CalibrationProgressRow(
                    metricName: "Ruhepuls",
                    sampleCount: baselineSampleCount(for: .restingHR),
                    requiredSamples: requiredSamples
                )
                Divider()
                CalibrationProgressRow(
                    metricName: "Aktivität",
                    sampleCount: baselineSampleCount(for: .activity),
                    requiredSamples: requiredSamples
                )
            }
            .glassCard()
        }
    }

    // MARK: - Hilfsmethoden

    /// Liefert den sampleCount der passenden HealthBaseline für den gegebenen Metric-Typ.
    /// Gibt 0 zurück wenn noch keine Baseline vorhanden.
    private func baselineSampleCount(for type: HealthMetricType) -> Int {
        baselines.first { $0.metricType == type }?.sampleCount ?? 0
    }

    // MARK: - User-Input anwenden

    private func applyUserInput() {
        SessionReadinessService.refineWithUserInput(
            readiness: readiness,
            energy: energySelection,
            stress: stressSelection?.rawValue,
            context: context,
            takesCardioMedication: appSettings.takesCardioMedication
        )
        // ViewModel nach Score-Neuberechnung aktualisieren
        viewModel.load(
            readiness: readiness,
            baselines: baselines,
            takesCardioMedication: appSettings.takesCardioMedication,
            debugScoreOverride: appSettings.debugReadinessScoreOverride
        )
    }
}
