//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Views / Body / BodyMeasurements                                  /
// Datei . . . . : BodyMeasurementHistorySheet.swift                               /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 09.05.2026                                                       /
// Beschreibung  : History-Liste für einen Maß-Typ mit Edit- und Delete-Aktionen   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftData
import SwiftUI

// MARK: - BodyMeasurementHistorySheet

struct BodyMeasurementHistorySheet: View {

    // MARK: - Props

    let title: String
    let unit: String
    let keyPath: KeyPath<BodyMeasurement, Double?>
    let measurements: [BodyMeasurement]

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Lokaler State

    @State private var editTrigger: EditTrigger?

    // MARK: - Computed

    private var filteredEntries: [BodyMeasurement] {
        measurements
            .filter { $0[keyPath: keyPath] != nil }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Messungen",
                        systemImage: "ruler",
                        description: Text("Für \(title) wurden noch keine Werte erfasst.")
                    )
                } else {
                    List(filteredEntries) { measurement in
                        row(for: measurement)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(measurement)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                editTrigger = EditTrigger(measurement: measurement)
                            }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $editTrigger) { trigger in
            BodyMeasurementEntrySheet(editingMeasurement: trigger.measurement)
                .environmentObject(AppSettings.shared)
        }
    }

    // MARK: - Hilfsfunktionen

    @ViewBuilder
    private func row(for measurement: BodyMeasurement) -> some View {
        HStack {
            Text(measurement.date.formatted(
                .dateTime
                    .day()
                    .month(.wide)
                    .year()
                    .locale(Locale(identifier: "de_DE"))
            ))
            Spacer()
            if let v = measurement[keyPath: keyPath] {
                Text("\(String(format: "%.1f", v)) \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func delete(_ measurement: BodyMeasurement) {
        modelContext.delete(measurement)
        try? modelContext.save()
    }
}

// MARK: - EditTrigger

private struct EditTrigger: Identifiable {
    let id = UUID()
    let measurement: BodyMeasurement
}

// MARK: - Preview

#Preview {
    BodyMeasurementHistorySheet(
        title: "Körpergewicht",
        unit: "kg",
        keyPath: \.bodyWeight,
        measurements: []
    )
    .modelContainer(PreviewData.sharedContainer)
    .environmentObject(AppSettings.shared)
}
