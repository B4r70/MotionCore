//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : GenderIconView.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 23.11.2025                                                       /
// Beschreibung  : Ausgabe des Gender-Icons                                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct GenderSymbolView: View {
    let gender: Gender
    var size: CGFloat = 20

    // Eine berechnete Eigenschaft, die Icon-Namen und Farbe liefert
    var iconMetrics: (name: String, color: Color) {
        switch gender {
        case .male:
            return (name: "male.fill", color: .blue)
        case .female:
            return (name: "female.fill", color: .pink)
        case .other:
            // Standard-Symbol für Divers oder Unbekannt (ab SF Symbols 5)
            return (name: "figure.stand.line.vertical.figure.fill", color: .purple)
        }
    }

    var body: some View {
        Image(systemName: iconMetrics.name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(iconMetrics.color)
    }
}
