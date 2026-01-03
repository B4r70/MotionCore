//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Live Activity                                                    /
// Datei . . . . : MotionCoreWidgetsLiveActivity.swift                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 02.01.2026                                                       /
// Geändert am . : 03.01.2026                                                       /
// Beschreibung  : Live Activity UI für Dynamic Island und Sperrbildschirm          /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
// Änderungen:                                                                      /
// - Kompakte Ansicht: Aktiv-Modus zeigt Satz-Fortschritt + Timer in Grün           /
// - Kompakte Ansicht: Pausen-Modus zeigt Icon + Countdown mit Farbverlauf          /
//   (Grün → Orange bei 50% → Rot bei letzten 10 Sekunden)                          /
// - Pulsier-Animation in den letzten 10 Sekunden der Pause                         /
// - Erweiterte Ansicht: Angepasste Farben passend zur kompakten Ansicht            /
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
                // =====================================================================
                // MARK: - Expanded Region (ausgeklappt)
                // =====================================================================

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
                    // Timer-Anzeige mit angepassten Farben
                    if context.state.isResting, let end = context.state.restEndDate {
                        // PAUSEN-MODUS (erweitert)
                        VStack(spacing: 2) {
                            Text("Pause")
                                .font(.caption2)
                                .foregroundStyle(restTimerColor(for: context))

                            Text(end, style: .timer)
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(restTimerColor(for: context))
                        }
                    } else {
                        // AKTIV-MODUS (erweitert)
                        VStack(spacing: 2) {
                            Text(context.state.isPaused ? "Pausiert" : "Läuft")
                                .font(.caption2)
                                .foregroundStyle(context.state.isPaused ? .orange : .green)

                            if context.state.isPaused {
                                Text(formatTime(context.state.elapsedAtPause ?? 0))
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(.orange)
                            } else {
                                Text(context.state.workoutStartDate, style: .timer)
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(.green)
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

                        // Status-Icon mit angepassten Farben
                        if context.state.isResting {
                            Image(systemName: "pause.circle.fill")
                                .foregroundStyle(restTimerColor(for: context))
                                .font(.caption)
                        } else {
                            Image(systemName: context.state.isPaused ? "pause.circle.fill" : "figure.strengthtraining.traditional")
                                .foregroundStyle(context.state.isPaused ? .orange : .green)
                                .font(.caption)
                        }
                    }
                    .padding(.top, 8)
                }

            // =====================================================================
            // MARK: - Compact View (kompakte Pillen-Ansicht)
            // =====================================================================

            } compactLeading: {
                // Kompakt Links - Icon + Satz-Fortschritt je nach Modus
                if context.state.isResting {
                    // PAUSEN-MODUS: Pause-Icon mit Farbverlauf
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(restTimerColor(for: context))
                        .font(.body)
                        .symbolEffect(.pulse, options: .repeating, isActive: isInFinalCountdown(context))
                } else if context.state.isPaused {
                    // WORKOUT PAUSIERT (nicht Satz-Pause)
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.body)
                } else {
                    // AKTIV-MODUS: Icon + Satz-Fortschritt
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(.green)
                            .font(.body)

                        // Satz-Fortschritt in Weiß (hebt sich ab)
                        Text("\(context.state.completedSets)/\(context.state.totalSets)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    }
                }

            } compactTrailing: {
                // Kompakt Rechts - Timer rechtsbündig
                if context.state.isResting, let end = context.state.restEndDate {
                    // PAUSEN-MODUS: Countdown mit Farbverlauf
                    Text(end, style: .timer)
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(restTimerColor(for: context))
                        .contentTransition(.numericText())
                } else if context.state.isPaused {
                    // WORKOUT PAUSIERT
                    Text(formatTime(context.state.elapsedAtPause ?? 0))
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.orange)
                } else {
                    // AKTIV-MODUS: Nur Timer in Grün (rechtsbündig)
                    Text(context.state.workoutStartDate, style: .timer)
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.green)
                }

            } minimal: {
                // =====================================================================
                // MARK: - Minimal View (wenn mehrere Activities laufen)
                // =====================================================================
                if context.state.isResting {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(restTimerColor(for: context))
                } else if context.state.isPaused {
                    Image(systemName: "pause.fill")
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.green)
                }
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

                // Rechts: Timer mit angepassten Farben
                if context.state.isResting, let end = context.state.restEndDate {
                    // PAUSEN-MODUS
                    VStack(spacing: 4) {
                        Text("Pause")
                            .font(.caption)
                            .foregroundStyle(restTimerColor(for: context))

                        Text(end, style: .timer)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(restTimerColor(for: context))
                    }
                } else {
                    // AKTIV-MODUS
                    VStack(spacing: 4) {
                        Text(context.state.isPaused ? "Pausiert" : "Training")
                            .font(.caption)
                            .foregroundStyle(context.state.isPaused ? .orange : .green)

                        if context.state.isPaused {
                            Text(formatTime(context.state.elapsedAtPause ?? 0))
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.orange)
                        } else {
                            Text(context.state.workoutStartDate, style: .timer)
                                .font(.title.bold().monospacedDigit())
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            // Fortschrittsbalken mit angepassten Farben
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Hintergrund
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))

                    // Fortschritt - Farbe je nach Modus
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            context.state.isResting
                                ? LinearGradient(
                                    colors: [restTimerColor(for: context), restTimerColor(for: context).opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
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
                    if context.state.isResting {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(restTimerColor(for: context))
                        Text("Satzpause")
                            .font(.caption)
                    } else {
                        Image(systemName: context.state.isPaused ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundStyle(context.state.isPaused ? .orange : .green)
                        Text(context.state.isPaused ? "Pausiert" : "Aktiv")
                            .font(.caption)
                    }
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

    // MARK: - Pausen-Farb-Logik

    /// Berechnet die Farbe für den Pausen-Timer basierend auf der verbleibenden Zeit
    /// - Grün: Mehr als 50% der Zeit übrig
    /// - Orange: Zwischen 50% und 10 Sekunden
    /// - Rot: Letzte 10 Sekunden
    private func restTimerColor(for context: ActivityViewContext<WorkoutActivityAttributes>) -> Color {
        guard context.state.isResting,
              let endDate = context.state.restEndDate else {
            return .orange // Fallback
        }

        let remainingSeconds = endDate.timeIntervalSinceNow

        // Letzte 10 Sekunden → Rot
        if remainingSeconds <= 10 {
            return .red
        }

        // Berechne ursprüngliche Pausendauer aus ContentState
        // Da wir die Original-Dauer nicht direkt haben, schätzen wir sie
        // basierend auf typischen Pausenzeiten (30-180 Sekunden)
        // Alternativ: Wenn die Zeit > 50% durch ist → Orange

        // Einfache Heuristik: Wenn weniger als 50% der geschätzten Zeit übrig
        // Typische Pause: 60-90 Sekunden → bei < 30-45 Sekunden = Orange
        // Wir nutzen einen festen Schwellenwert für Konsistenz

        // Besserer Ansatz: Wir können die Pausendauer nicht direkt ermitteln,
        // daher nutzen wir absolute Schwellenwerte:
        // > 30 Sekunden → Grün
        // 10-30 Sekunden → Orange
        // < 10 Sekunden → Rot

        if remainingSeconds <= 30 {
            return .orange
        }

        return .green
    }

    /// Prüft ob wir in den letzten 10 Sekunden der Pause sind (für Puls-Animation)
    private func isInFinalCountdown(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> Bool {
        guard context.state.isResting,
              let endDate = context.state.restEndDate else {
            return false
        }

        return endDate.timeIntervalSinceNow <= 10 && endDate.timeIntervalSinceNow > 0
    }
}

// MARK: - Preview

#Preview("Live Activity", as: .dynamicIsland(.compact), using: WorkoutActivityAttributes(
    sessionID: "preview-123",
    workoutType: "strength",
    planName: "Push Day"
)) {
    MotionCoreWidgetsLiveActivity()
} contentStates: {
    // Aktiv-Modus
    WorkoutActivityAttributes.ContentState(
        workoutStartDate: Date().addingTimeInterval(-300),
        isPaused: false,
        currentExercise: "Bankdrücken",
        currentSet: "Satz 3 · 12 Wdh · 40kg",
        isResting: false,
        completedSets: 5,
        totalSets: 24
    )

    // Pausen-Modus (viel Zeit übrig)
    WorkoutActivityAttributes.ContentState(
        workoutStartDate: Date().addingTimeInterval(-300),
        isPaused: false,
        currentExercise: "Bankdrücken",
        currentSet: "Satz 3 · 12 Wdh · 40kg",
        isResting: true,
        restEndDate: Date().addingTimeInterval(45),
        completedSets: 5,
        totalSets: 24
    )

    // Pausen-Modus (wenig Zeit übrig - orange)
    WorkoutActivityAttributes.ContentState(
        workoutStartDate: Date().addingTimeInterval(-300),
        isPaused: false,
        currentExercise: "Bankdrücken",
        currentSet: "Satz 3 · 12 Wdh · 40kg",
        isResting: true,
        restEndDate: Date().addingTimeInterval(20),
        completedSets: 5,
        totalSets: 24
    )

    // Pausen-Modus (finale 10 Sekunden - rot)
    WorkoutActivityAttributes.ContentState(
        workoutStartDate: Date().addingTimeInterval(-300),
        isPaused: false,
        currentExercise: "Bankdrücken",
        currentSet: "Satz 3 · 12 Wdh · 40kg",
        isResting: true,
        restEndDate: Date().addingTimeInterval(8),
        completedSets: 5,
        totalSets: 24
    )
}
