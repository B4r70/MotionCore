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

    // NEU: Apple Mail Style Filter Section (minimalistisch)
struct FilterSection: View {
    @Binding var selectedDeviceFilter: CardioDevice
    @Binding var selectedTimeFilter: TimeFilter

    var body: some View {
        // Kein HStack, kein Spacer, kein padding - nur das Menu
        Menu {
            // Zeitfilter-Sektion
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

                // Gerätefilter-Sektion
            Section("Gerät") {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDeviceFilter = .none
                    }
                } label: {
                    Label {
                        HStack {
                            Text("Alle Geräte")
                            Spacer()
                            if selectedDeviceFilter == .none {
                                Image(systemName: "checkmark")
                            }
                        }
                    } icon: {
                        Image(systemName: "rectangle.3.group")
                    }
                }

                ForEach([CardioDevice.crosstrainer, .ergometer], id: \.self) { device in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDeviceFilter = device
                        }
                    } label: {
                        Label {
                            HStack {
                                Text(device.description)
                                Spacer()
                                if selectedDeviceFilter == device {
                                    Image(systemName: "checkmark")
                                }
                            }
                        } icon: {
                            Image(systemName: device.symbol)
                        }
                    }
                }
            }
        } label: {
                // NEU: Nur das Icon, wie bei ToolbarButton
            ZStack {
                    // Filter-Icon
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.body)
                    .foregroundStyle(isFiltered ? .blue : .primary)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }

                    // NEU: Blauer Punkt wenn Filter aktiv (rechts oben)
                if isFiltered {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)
                        .offset(x: 10, y: -10)
                }
            }
        }
    }

        // MARK: - Computed Properties

    private var isFiltered: Bool {
        selectedTimeFilter != .all || selectedDeviceFilter != .none
    }
}
