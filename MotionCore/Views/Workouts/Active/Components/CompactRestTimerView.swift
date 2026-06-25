//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : CompactRestTimerView.swift                                       /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 18.04.2026                                                       /
// Beschreibung  : Kompakter RestTimer fuer Einbettung in RIRInputSheet.            /
//                 Ring ~130pt (62% von 210), eigene formatRestTime-Helper.         /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct CompactRestTimerView: View {
    @ObservedObject var restTimerManager: RestTimerManager
    let targetSeconds: Int
    let onAdjust: (Int) -> Void

    // Fortschritt: 0 = voll, 1 = leer (Ring leert sich mit der Zeit)
    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return 1.0 - Double(restTimerManager.remainingSeconds) / Double(targetSeconds)
    }

    // Einfarbiger Ring mit Schwellen (≤10s danger, ≤30s warning, sonst accent)
    private var ringColor: Color {
        let r = restTimerManager.remainingSeconds
        if r <= 10 { return Theme.danger }
        if r <= 30 { return Theme.warning }
        return Theme.accent
    }

    var body: some View {
        VStack(spacing: Space.s2) {
            ZStack {
                // Hintergrund-Ring
                Circle()
                    .stroke(Theme.surfaceSunken, lineWidth: 8)

                // Fortschritts-Ring (einfarbig, kein Gradient)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: restTimerManager.remainingSeconds)

                // Verbleibende Sekunden in der Mitte
                Text(formatRestTime(restTimerManager.remainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
            }
            .frame(width: 130, height: 130)

            // ±15s Anpassungs-Buttons
            HStack(spacing: Space.s4) {
                Button {
                    onAdjust(-15)
                } label: {
                    Label("15s", systemImage: "minus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(AppFont.title)
                        .foregroundStyle(Theme.textSecondary)
                }

                Text("±15s")
                    .font(AppFont.caption)
                    .foregroundStyle(Theme.textSecondary)

                Button {
                    onAdjust(15)
                } label: {
                    Label("15s", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(AppFont.title)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Hilfsfunktion

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
