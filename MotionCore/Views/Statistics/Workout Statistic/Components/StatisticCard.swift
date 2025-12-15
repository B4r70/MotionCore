//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Statistik                                                        /
// Datei . . . . : StatisticsCard.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Darstellung von Cards für den Bereich Statistik                  /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StatisticCard<ValueContent: View>: View {
    let icon: IconTypes
    let title: String
    let valueView: ValueContent
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            // Unterscheidung Icon-Typen
            IconType(icon: icon, color: color, size: 50)

            VStack(spacing: 8) {
                valueView
                    .font(.system(size: 48, weight: .bold))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

// Alternativ im Grid Format 2 Cards pro Zeile
struct StatisticGridCard<ValueContent: View>: View {
    let icon: IconTypes
    let title: String
    let valueView: ValueContent
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            // Unterscheidung Icon-Typen
            IconType(icon: icon, color: color, size: 40)

            // Wert in groß, aber nicht riesig
            valueView
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .font(.system(size: 26, weight: .bold, design: .rounded))

            // Subtitle klein
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120) // EINHEITLICHE HÖHE
        .glassCard()
    }
}
