//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Live Activity                                                    /
// Datei . . . . : MotionCoreWidgetsLiveActivity.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.01.2026                                                       /
// Beschreibung  : Live Activity UI für Dynamic Island und Sperrbildschirm          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import ActivityKit
import WidgetKit
import SwiftUI

struct MotionCoreWidgetsLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Region (ausgeklappt)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.currentExercise ?? "Training")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)

                        if let set = context.state.currentSet {
                            Text(set)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    // Timer (Pause-Timer hat Priorität)
                    if context.state.isResting, let end = context.state.restEndDate {
                        VStack(spacing: 2) {
                            Text("Pause")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            // Counts down system-side (works even when app is closed)
                            Text(end, style: .timer)
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(.orange)
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text(context.state.isPaused ? "Pausiert" : "Läuft")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            if context.state.isPaused {
                                // Frozen display while paused
                                Text(formatTime(context.state.elapsedAtPause ?? 0))
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(.orange)
                            } else {
                                // Counts up system-side (works even when app is closed)
                                Text(context.state.workoutStartDate, style: .timer)
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Fortschritt
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("\(context.state.completedSets)/\(context.state.totalSets) Sätze")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Status-Icon
                        Image(systemName: context.state.isPaused ? "pause.circle.fill" : "figure.strengthtraining.traditional")
                            .foregroundStyle(context.state.isPaused ? .orange : .blue)
                            .font(.caption)
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Kompakt Links - Icon
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                // Kompakt Rechts - Timer
                if context.state.isResting, let end = context.state.restEndDate {
                    Text(end, style: .timer)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.orange)
                } else {
                    if context.state.isPaused {
                        Text(formatTime(context.state.elapsedAtPause ?? 0))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.orange)
                    } else {
                        Text(context.state.workoutStartDate, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.blue)
                    }
                }
            } minimal: {
                // Minimal - nur Icon (wenn mehrere Activities laufen)
                Image(systemName: context.state.isPaused ? "pause.fill" : "dumbbell.fill")
                    .foregroundStyle(context.state.isPaused ? .orange : .blue)
            }
        }
    }

    // MARK: - Lock Screen View

    private func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Links: Übungs-Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.planName ?? "Training")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let exercise = context.state.currentExercise {
                        Text(exercise)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let set = context.state.currentSet {
                        Text(set)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Rechts: Timer
                if context.state.isResting, let end = context.state.restEndDate {
                    VStack(spacing: 4) {
                        Text("Pause")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(end, style: .timer)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                } else {
                    VStack(spacing: 4) {
                        Text(context.state.isPaused ? "Pausiert" : "Training")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if context.state.isPaused {
                            Text(formatTime(context.state.elapsedAtPause ?? 0))
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.orange)
                        } else {
                            Text(context.state.workoutStartDate, style: .timer)
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            // Fortschrittsbalken
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Hintergrund
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Fortschritt
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress(context))
                }
            }
            .frame(height: 8)

            // Untere Info-Zeile
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(context.state.completedSets)/\(context.state.totalSets) Sätze")
                        .font(.caption)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: context.state.isPaused ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundStyle(context.state.isPaused ? .orange : .green)
                    Text(context.state.isPaused ? "Pausiert" : "Aktiv")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    // MARK: - Helper Functions

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func progress(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> Double {
        guard context.state.totalSets > 0 else { return 0 }
        return Double(context.state.completedSets) / Double(context.state.totalSets)
    }
}
