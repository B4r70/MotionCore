//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Gesundheitsmetriken                                              /
// Datei . . . . : HealthMetricCard.swift                                           /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 11.11.2025                                                       /
// Beschreibung  : Darstellung von Cards für den Bereich userspez. Gesundheitsdaten /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct HealthMetricCard<ValueContent: View>: View {
    let icon: IconTypes
    let title: String
    let valueView: ValueContent
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
               // Eigene View für Icons
            IconType(icon: icon, color: color, size: 40)
            VStack(spacing: 8) {
                valueView
                    .font(.system(size: 40, weight: .bold))
                    .monospacedDigit()

                Text(title)
                    .font(AppFont.headline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}

// Alternativ im Grid Format 2 Cards pro Zeile
struct HealthMetricGridCard<ValueContent: View>: View {
    let icon: IconTypes
    let title: String
    let valueView: ValueContent
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            // Unterscheidung System-/Asset-Icon
            IconType(icon: icon, color: color, size: 40)

            valueView
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(title)
                .font(AppFont.callout)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
        .card()
    }
}
