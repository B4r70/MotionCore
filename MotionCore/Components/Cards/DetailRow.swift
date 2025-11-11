//
//  DetailRow.swift
//  MotionCore
//
//  Created by Barto on 11.11.25.
//
import SwiftUI

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
