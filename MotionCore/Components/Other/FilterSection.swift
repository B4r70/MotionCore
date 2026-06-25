//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : FilterSection.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung von Filter-Chips                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

    // Apple Mail Style Filter Section (minimalistisch)
struct FilterSection: View {
    @Binding var selectedTimeFilter: TimeFilter

    var body: some View {
        // Kein HStack, kein Spacer, kein padding - nur das Menu
        Menu {
            Section("Zeitraum") {
                ForEach(TimeFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTimeFilter = filter
                        }
                    } label: {
                        Label {
                            HStack {
                                Text(filter.description)
                                Spacer()
                                if selectedTimeFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        } icon: {
                            Image(systemName: filter.intervalSymbol)
                        }
                    }
                }
            }
        } label: {
            ZStack {
                // Filter-Icon mit Glass-Effekt
                IconType(
                    icon: .system("line.3.horizontal.decrease.circle"),
                    color: isFiltered ? .blue : .primary,
                    size: 14
                )
                .glassButton(
                    size: 36,
                    accentColor: isFiltered ? .blue : .primary
                )

                // Blauer Punkt wenn Filter aktiv (rechts oben)
                if isFiltered {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 10, height: 10)
                        .offset(x: 10, y: -10)
                }
            }
        }
    }

        // MARK: - Computed Properties

    private var isFiltered: Bool {
        selectedTimeFilter != .all
    }
}
