//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Aktive Workouts                                                  /
// Datei . . . . : ExerciseCountdownTimerView.swift                                 /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 06.06.2026                                                       /
// Beschreibung  : Anzeige-Komponente für den Übungs-Countdown (Ring + Mono-        /
//                 Ziffern). Enthält keine Buttons — die liegen in ActiveSetCard.   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - ExerciseCountdownTimerView

/// Zeigt Ring-Fortschritt und große Mono-Ziffern für einen zeitbasierten Übungs-Satz.
/// Buttons (Start/Pause/Abschließen) werden in ActiveSetCard eingebettet.
struct ExerciseCountdownTimerView: View {
    let remainingSeconds: Int
    let targetSeconds: Int
    var isRunning: Bool = false
    var isPaused: Bool = false

    var body: some View {
        VStack(spacing: Space.s3) {
            // Kontextabhängiges Label — unterscheidbar von „Pause"-Timer
            Text(statusLabel)
                .font(AppFont.callout)
                .fontWeight(.medium)
                .foregroundStyle(Theme.textSecondary)

            ringTimer
        }
        .padding(.top, Space.s2)
    }

    // MARK: - Ring-Timer

    private var ringTimer: some View {
        ZStack {
            // Hintergrund-Ring
            Circle()
                .stroke(Theme.surfaceSunken, lineWidth: 12)

            // Fortschritts-Ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: remainingSeconds)

            // Mono-Ziffern in der Mitte
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(isRunning || isPaused ? timerColor : Theme.textTertiary)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .frame(width: 170, height: 170)
    }

    // MARK: - Berechnete Properties

    /// Label abhängig vom Countdown-Zustand
    private var statusLabel: String {
        if isPaused { return "Pause" }
        if isRunning { return "Übung läuft" }
        return "Übung starten"
    }

    /// Fortschrittsanteil für den Ring (1.0 = voll, 0.0 = leer)
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, Double(remainingSeconds) / Double(targetSeconds))
    }

    /// Farblogik: neutral vor Start, grün > 60 s, gelb 10–60 s, rot ≤ 10 s
    private var timerColor: Color {
        guard isRunning || isPaused else { return Theme.textTertiary }
        if remainingSeconds > 60 {
            return Theme.success
        } else if remainingSeconds > 10 {
            return Theme.warning
        } else {
            return Theme.danger
        }
    }

    /// mm:ss Format — immer zweistellig
    private var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview("Übungs-Countdown — Zustände") {
    ZStack {
        Theme.surfaceApp.ignoresSafeArea()

        VStack(spacing: 32) {
            // Idle — vor Start
            ExerciseCountdownTimerView(remainingSeconds: 300, targetSeconds: 300, isRunning: false, isPaused: false)

            // > 60 s → grün
            ExerciseCountdownTimerView(remainingSeconds: 180, targetSeconds: 300, isRunning: true)

            // 10–60 s → gelb
            ExerciseCountdownTimerView(remainingSeconds: 35, targetSeconds: 300, isRunning: true)

            // ≤ 10 s → rot
            ExerciseCountdownTimerView(remainingSeconds: 5, targetSeconds: 300, isRunning: true)
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
