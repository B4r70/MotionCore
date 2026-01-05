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

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: isPaused ? "pause.circle.fill" : "clock.fill")
                        .foregroundStyle(isPaused ? .orange : .blue)

                    Text(formattedElapsedTime)
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.primary)

                    if isPaused {
                        Text("(Pausiert)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Text("\(completedSets)/\(totalSets)")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text("Sätze")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

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
}
