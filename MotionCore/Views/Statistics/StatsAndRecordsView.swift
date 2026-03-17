//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik & Rekorde                                              /
// Datei . . . . : StatsAndRecordsView.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Kombinierte View für Statistiken und Rekorde                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Hinweis  . . : Diese View kombiniert StatisticView und RecordView in einem Tab   /
//                mit Segmented Control zur Umschaltung. Spart einen Tab-Platz.     /
// ---------------------------------------------------------------------------------/
//
import SwiftUI
import SwiftData

struct StatsAndRecordsView: View {

    // MARK: - State

    @State private var selectedSegment: StatsSegment = .statistics

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            Picker("Ansicht", selection: $selectedSegment) {
                ForEach(StatsSegment.allCases) { segment in
                    Text(segment.label).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Content basierend auf Auswahl
            switch selectedSegment {
            case .statistics:
                StatisticView()
            case .records:
                RecordView()
            }
        }
    }
}

// MARK: - Segment Enum

enum StatsSegment: String, CaseIterable, Identifiable {
    case statistics = "statistics"
    case records = "records"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .statistics: return "Statistiken"
        case .records: return "Rekorde"
        }
    }
}

// MARK: - Preview

#Preview("Stats & Rekorde") {
    StatsAndRecordsView()
        .modelContainer(PreviewData.sharedContainer)
        .environmentObject(AppSettings.shared)
}
