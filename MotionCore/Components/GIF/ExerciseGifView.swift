//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : ExerciseGifView.swift                                            /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 17.12.2025                                                       /
// Beschreibung  : Darstellung der Krafttrainingübung als GIF                       /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ExerciseGifView: View {
    let assetName: String
    var size: CGFloat = 120
    
    var body: some View {
        if assetName.isEmpty {
            // Fallback: Placeholder
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: size * 0.5))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        } else {
            // GIF aus Assets
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
