//---------------------------------------------------------------------------------/
//  # CrossStats                                                                   /
//---------------------------------------------------------------------------------/
// Filename . . : EditWorkoutView.swift                                            /
// Author . . . : Bartosz Stryjewski                                               /
// Created on . : 22.10.2025                                                       /
// Function . . : Workout Edit View                                                /
//---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                             /
//---------------------------------------------------------------------------------/
//
import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    let maximumRating = 5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maximumRating, id: \.self) { number in
                Image(systemName: number <= rating ? "star.fill" : "star")
                    .foregroundColor(number <= rating ? .yellow : .gray)
                    .font(.system(size: 20))
                    .onTapGesture {
                        rating = number
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    .accessibilityLabel("\(number) Sterne")
            }
        }
        .animation(.easeInOut, value: rating)
        .padding(.vertical, 8)
    }
}
