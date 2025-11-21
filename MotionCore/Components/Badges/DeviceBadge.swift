//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : DeviceBadge.swift                                                /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.10.2025                                                       /
// Beschreibung  : Badge für die Darstellung des Gerätetyps im Display              /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct DeviceBadge: View {
    let device: WorkoutDevice
    var compact: Bool = false

    var body: some View {
        Label {
            if !compact {
                Text(device.description)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        } icon: {
            Image(systemName: device.symbol)
                .imageScale(.small)
        }
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(device.tint.opacity(0.35), lineWidth: 1)
        }
        .foregroundStyle(device.tint)
        .accessibilityLabel(Text(device.description))
    }
}
