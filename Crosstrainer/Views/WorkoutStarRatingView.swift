//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : WorkoutStarRatingView.swift                                      /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Edit View                                                /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

struct WorkoutStarRatingView: View {
    @Binding var rating: Intensity
    let maximumRating = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Intensity.allCases, id: \.self) { level in
                Image(systemName: level.rawValue <= rating.rawValue ? "star.fill" : "star")
                    .foregroundColor(level.rawValue <= rating.rawValue ? .yellow : .gray)
                    .font(.system(size: 20))
                    .onTapGesture { rating = level }
                    .accessibilityLabel(level.description)
            }
        }
        .animation(.easeInOut, value: rating)
        .padding(.vertical, 8)
    }
}
