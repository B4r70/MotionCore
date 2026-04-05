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
        VStack(spacing: 6) {
            // Timer + Pause-Button
            HStack {
                Text(formattedTime)
                    .font(.system(.title3, design: .monospaced).bold())
                    .foregroundStyle(watchSession.workoutState == .paused ? Color.orange : .primary)
                Spacer()
                Button {
                    watchSession.sendAction(.pauseResume)
                } label: {
                    Image(systemName: watchSession.workoutState == .paused ? "play.fill" : "pause.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(watchSession.workoutState == .paused ? Color.orange : .secondary)
            }

            if watchSession.isResting, let endDate = watchSession.restEndDate {
                // Rest-Timer-Anzeige: Pause-Countdown statt Satz-Info
                restView(endDate: endDate)
            } else {
                // Normale Trainings-Anzeige
                workoutView
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Sub-Views

    /// Normale Workout-Anzeige (Übungsname, Set-Info, HR/Kalorien, Satz-Button)
    @ViewBuilder
    private var workoutView: some View {
        // Übungsname + Set-Info
        Text(watchSession.exerciseName.isEmpty ? "–" : watchSession.exerciseName)
            .font(.headline)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)

        Text("Satz \(watchSession.setIndex + 1)/\(watchSession.totalSets)  ·  Übung \(watchSession.exerciseIndex + 1)/\(watchSession.totalExercises)")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

        // HR + Kalorien
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.red)
                    .font(.caption2)
                let hr = watchSession.workoutManager?.currentHeartRate ?? 0
                Text(hr > 0 ? "\(Int(hr))" : "–")
                    .font(.system(.caption, design: .monospaced).bold())
                Text("bpm")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
                    .font(.caption2)
                let cal = watchSession.workoutManager?.activeCalories ?? 0
                Text(cal > 0 ? "\(Int(cal))" : "–")
                    .font(.system(.caption, design: .monospaced).bold())
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Spacer(minLength: 2)

        // Satz abschließen (kompakter)
        Button {
            watchSession.sendAction(.completeSet)
        } label: {
            Label("Satz \(watchSession.setIndex + 1)", systemImage: "checkmark.circle.fill")
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(Color.green)
        .disabled(watchSession.workoutState == .paused)
    }

    /// Pause-Anzeige mit Countdown und "Überspringen"-Button
    @ViewBuilder
    private func restView(endDate: Date) -> some View {
        Text("Pause")
            .font(.headline)
            .foregroundStyle(Color.orange)
            .frame(maxWidth: .infinity, alignment: .leading)

        // Countdown via Date-Anchor — kein sekündlicher Sync nötig, kein Aufwärtszählen nach Ablauf
        Text(timerInterval: Date()...endDate, countsDown: true)
            .font(.system(.title2, design: .monospaced).bold())
            .foregroundStyle(Color.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .monospacedDigit()

        Spacer(minLength: 2)

        // Pause überspringen
        Button {
            watchSession.sendAction(.skipRest)
        } label: {
            Label("Überspringen", systemImage: "forward.fill")
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(Color.orange)
    }

    // MARK: - Formatierung

    /// Formatiert die live verstrichene Zeit als MM:SS oder H:MM:SS
    private var formattedTime: String {
        let seconds = Int(watchSession.liveElapsedSeconds)
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
