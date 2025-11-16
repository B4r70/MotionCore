// ---------------------------------------------------------------------------------/
//  # MotionCore                                                                   /
// ---------------------------------------------------------------------------------/
// Filename . . : StarRatingView.swift                                             /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Edit View                                                /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Intensity
    let maximumRating = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Intensity.allCases.filter { $0 != .none }, id: \.self) { level in
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
