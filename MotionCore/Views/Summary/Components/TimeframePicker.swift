//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : TimeframePicker.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.01.2026                                                       /
// Beschreibung  : Segmented Control zur Zeitraum-Auswahl                           /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Timeframe Picker

// Segmented Control zur Auswahl des Zeitraums
struct TimeframePicker: View {
    @Binding var selection: SummaryTimeframe

    var body: some View {
        Picker("Zeitraum", selection: $selection) {
            ForEach(SummaryTimeframe.allCases) { timeframe in
                Text(timeframe.label).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}
