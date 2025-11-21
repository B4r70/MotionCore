//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : UI-Elemente                                                      /
// Datei . . . . : FilterSection.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 22.10.2025                                                       /
// Beschreibung  : Darstellung von Filter-Chips                                     /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// Neu: Filter Section
struct FilterSection: View {
    @Binding var selectedFilter: WorkoutDevice
    let allWorkouts: [WorkoutSession]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "Alle",
                    count: allWorkouts.count,
                    isSelected: selectedFilter == .none
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = .none
                    }
                }

                FilterChip(
                    title: "Crosstrainer",
                    icon: "figure.elliptical",
                    count: allWorkouts.filter { $0.workoutDevice == .crosstrainer }.count,
                    isSelected: selectedFilter == .crosstrainer
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = .crosstrainer
                    }
                }

                FilterChip(
                    title: "Ergometer",
                    icon: "figure.indoor.cycle",
                    count: allWorkouts.filter { $0.workoutDevice == .ergometer }.count,
                    isSelected: selectedFilter == .ergometer
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = .ergometer
                    }
                }
            }
        }
    }
}

// Neu: Filter Chip (Glassmorphic)
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                }

                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))

                // Count Badge
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(isSelected ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2))
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(isSelected ? .ultraThinMaterial : .thinMaterial)
            }
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}
