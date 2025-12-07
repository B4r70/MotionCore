//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : IconTypes.swift                                                  /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 07.12.2025                                                       /
// Beschreibung  : Formatierung des Icon-Typ (SF- oder Asset-Symbole)               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Enumeration für die Wahl zwischen SF- oder Asset-Symbol
enum IconTypes {
    case system(String)  // SF Symbol
    case asset(String)   // eigenes Asset (z. B. SVG)
}

// Hier wird zwischen zwei Icon-Typen unterschieden:
// - System --> SF-Symbole
// - Asset --> Eigene Symbole
struct IconType: View {
    let icon: IconTypes
    let color: Color
    let size: CGFloat

    var body: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: size))
                .foregroundStyle(color)

        case .asset(let name):
            Image(name)
                .resizable()
                .renderingMode(.template)   // important for tinting
                .scaledToFit()
                .frame(height: size)
                .foregroundStyle(color)
        }
    }
}
