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
                // Calm 2026: ruhiger Icon-Button (surfaceCard + Hairline) statt Glas
                IconType(
                    icon: .system("line.3.horizontal.decrease.circle"),
                    color: isFiltered ? Theme.accent : Theme.textSecondary,
                    size: 16
                )
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.surfaceCard))
                .overlay(Circle().stroke(Theme.line, lineWidth: 1))

                // Akzent-Punkt wenn Filter aktiv (rechts oben)
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
