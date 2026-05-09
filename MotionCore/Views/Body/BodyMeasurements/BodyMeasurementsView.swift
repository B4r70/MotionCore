//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body                                                     /
// Datei . . . . : BodyMeasurementsView.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : Übersicht der erfassten Körpermaße mit Karussell und Empty-State /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

// Wrapper für .sheet(item:) — verhindert leeres Sheet beim ersten Aufruf (CLAUDE.md Sheet-Pattern)
private struct EntrySheetTrigger: Identifiable {
    let id = UUID()
    let measurement: BodyMeasurement?
}

struct BodyMeasurementsView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]

    @State private var entryTrigger: EntrySheetTrigger?

    private var todayMeasurement: BodyMeasurement? {
        measurements.first { Calendar.current.isDateInToday($0.date) }
    }

    // Ratio-Berechnungen als computed properties — verhindert Compiler-Fehler in some View-Kontext
    private var ratios: BodyMeasurementRatios {
        BodyMeasurementRatioCalcEngine().computeRatios(measurements: measurements)
    }

    private var ratioSeries: (waistToHip: [(Date, Double)], chestToWaist: [(Date, Double)], armToChest: [(Date, Double)]) {
        BodyMeasurementRatioCalcEngine().ratioSeries(measurements: measurements)
    }

    var body: some View {
        ZStack {
            AnimatedBackground(showAnimatedBlob: appSettings.showAnimatedBlob)

            if measurements.isEmpty {
                BodyMeasurementsEmptyState {
                    entryTrigger = EntrySheetTrigger(measurement: nil)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        BodyMeasurementsRadarCard(measurements: measurements)
                            .padding(.top, 8)

                        BodyMeasurementsValueCarousel(measurements: measurements)

                        if let trend = ratios.waistToHip {
                            BodyMeasurementsRatioCard(
                                title: "Taille-Hüfte (WHR)",
                                description: "Gesundheits-Marker — niedrig ist günstig",
                                trend: trend,
                                sparklineData: ratioSeries.waistToHip
                            )
                        }
                        if let trend = ratios.chestToWaist {
                            BodyMeasurementsRatioCard(
                                title: "Brust-Taille",
                                description: "V-Taper — höher ist breiter Oberkörper",
                                trend: trend,
                                sparklineData: ratioSeries.chestToWaist
                            )
                        }
                        if let trend = ratios.armToChest {
                            BodyMeasurementsRatioCard(
                                title: "Arm-Brust",
                                description: "Symmetrie zwischen Arm- und Brustumfang",
                                trend: trend,
                                sparklineData: ratioSeries.armToChest
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
                .floatingActionButton(icon: .system("plus"), color: .primary) {
                    entryTrigger = EntrySheetTrigger(measurement: todayMeasurement)
                }
            }
        }
        .navigationTitle("Körpermaße")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $entryTrigger) { trigger in
            BodyMeasurementEntrySheet(editingMeasurement: trigger.measurement)
                .environmentObject(appSettings)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BodyMeasurementsView()
    }
    .modelContainer(PreviewData.sharedContainer)
    .environmentObject(AppSettings.shared)
}
