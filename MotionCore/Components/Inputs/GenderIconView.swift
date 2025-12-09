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

struct GenderIconView: View {
    let gender: Gender
    var size: CGFloat = 20
    
    var body: some View {
        IconType(icon: gender.icon, color: gender.color, size: size)
    }
}
