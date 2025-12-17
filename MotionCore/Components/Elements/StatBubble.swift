//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : StatBubble.swift                                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung von Icons in Form einer Bubble                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatBubble: View {
    let icon: IconTypes
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            IconType(icon: icon, color: color, size: 12)

            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
        }
    }
}
