//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout-Karten                                                   /
// Datei . . . . : WorkoutTypeIconTile.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 26.06.2026                                                       /
// Beschreibung  : Einheitliches Icon-Tile mit einem ruhigen Ton je Workout-Typ     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// ponytail: eine geteilte Tile-View statt 3 inline-Kopien — hält die 3 Session-Karten
// pixelgleich (ein Ton je Typ). Token-Ton kommt aus WorkoutType (TypesUI.swift).
struct WorkoutTypeIconTile: View {
    let type: WorkoutType
    let systemImage: String
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(type.calmIconTint)
            .frame(width: size, height: size)
            .background(type.calmTileBackground, in: RoundedRectangle(cornerRadius: Radius.md))
    }
}

#Preview {
    HStack(spacing: Space.s4) {
        WorkoutTypeIconTile(type: .strength, systemImage: "dumbbell.fill")
        WorkoutTypeIconTile(type: .outdoor, systemImage: "figure.outdoor.cycle")
        WorkoutTypeIconTile(type: .cardio, systemImage: "heart.fill")
    }
    .padding()
    .background(Theme.surfaceApp)
}
