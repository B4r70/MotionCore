//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Watch App                                                        /
// Datei . . . . : WatchActiveWorkoutView.swift                                     /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.03.2026                                                       /
// Beschreibung  : Watch Remote Control für aktive Workouts                         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct WatchActiveWorkoutView: View {
    @EnvironmentObject private var watchSession: WatchSessionManager

    var body: some View {
        VStack(spacing: 8) {
            // Timer und Pause-Button
            HStack {
                Text(formattedTime)
                    .font(.system(.body, design: .monospaced).bold())
                    .foregroundStyle(watchSession.workoutState == .paused ? .orange : .primary)
                Spacer()
                Button {
                    watchSession.sendAction(.pauseResume)
                } label: {
                    Image(systemName: watchSession.workoutState == .paused ? "play.fill" : "pause.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(watchSession.workoutState == .paused ? .orange : .secondary)
            }

            // Übungsname und Position
            Text(watchSession.exerciseName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Übung \(watchSession.exerciseIndex + 1)/\(watchSession.totalExercises)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            // Haupt-Action: Satz abschließen
            Button {
                watchSession.sendAction(.completeSet)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Satz \(watchSession.setIndex + 1)/\(watchSession.totalSets)")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(watchSession.workoutState == .paused)

            // Übungs-Navigation
            HStack(spacing: 0) {
                Button {
                    watchSession.sendAction(.previousExercise)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    watchSession.sendAction(.nextExercise)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Formatierung

    /// Formatiert die verstrichene Zeit als MM:SS oder H:MM:SS
    private var formattedTime: String {
        let seconds = Int(watchSession.elapsedTime)
        let hours   = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs    = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    WatchActiveWorkoutView()
        .environmentObject(WatchSessionManager.shared)
}
