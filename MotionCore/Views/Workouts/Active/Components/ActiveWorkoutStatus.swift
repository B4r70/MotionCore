//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ActiveWorkoutStatus.swift                                        /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 05.01.2026                                                       /
// Beschreibung  : Aktives Workout (Status View)                                    /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct ActiveWorkoutStatus: View {
    let isPaused: Bool
    let formattedElapsedTime: String
    let completedSets: Int
    let totalSets: Int
    let progress: Double
    let sessionVolume: Double
    let planTitle: String?          // Optional: Plan-Name als Badge

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                // Timer (links)
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: isPaused ? "pause.circle.fill" : "clock.fill")
                            .foregroundStyle(isPaused ? .orange : .blue)
                        Text(formattedElapsedTime)
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                    if isPaused {
                        Text("Pausiert")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    // Plan-Badge: nur anzeigen wenn Workout aus einem Plan stammt
                    if let title = planTitle {
                        Text(title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Volumen (Mitte) — nur anzeigen wenn > 0
                if sessionVolume > 0 {
                    VStack(spacing: 2) {
                        Text(formattedVolume)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text("Volumen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .transition(.scale.combined(with: .opacity))
                }

                // Sätze (rechts)
                VStack(spacing: 2) {
                    Text("\(completedSets)/\(totalSets)")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Sätze")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .animation(.easeInOut(duration: 0.3), value: sessionVolume > 0)

            // Fortschrittsbalken
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(0, min(1, progress)), height: 8)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Formatierung

    private var formattedVolume: String {
        if sessionVolume >= 1000 {
            return String(format: "%.1f t", sessionVolume / 1000)
        } else {
            return String(format: "%.0f kg", sessionVolume)
        }
    }
}

// MARK: - Preview

#Preview("Mit Plan") {
    ActiveWorkoutStatus(
        isPaused: false,
        formattedElapsedTime: "12:34",
        completedSets: 3,
        totalSets: 8,
        progress: 0.375,
        sessionVolume: 1450,
        planTitle: "Push Day A"
    )
}

#Preview("Ohne Plan / Pausiert") {
    ActiveWorkoutStatus(
        isPaused: true,
        formattedElapsedTime: "05:00",
        completedSets: 1,
        totalSets: 4,
        progress: 0.25,
        sessionVolume: 0,
        planTitle: nil
    )
}
