//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : StarRatingView.swift                                             /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Intensitätsdarstellung in Sternen                                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct InputStarRating: View {
    @Binding var rating: Intensity
    let maximumRating = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Intensity.allCases.filter { $0 != .none }, id: \.self) { level in
                Image(systemName: level.rawValue <= rating.rawValue ? "star.fill" : "star")
                    .foregroundColor(level.rawValue <= rating.rawValue ? Color.yellow : Color.gray)
                    .font(.system(size: 20))
                    .onTapGesture { rating = level }
                    .accessibilityLabel(level.description)
            }
        }
        .animation(.easeInOut, value: rating)
        .padding(.vertical, 8)
    }
}
