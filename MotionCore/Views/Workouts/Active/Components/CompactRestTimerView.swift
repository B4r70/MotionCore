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

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Hintergrund-Ring
                Circle()
                    .stroke(.primary.opacity(0.1), lineWidth: 8)

                // Fortschritts-Ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: restTimerManager.remainingSeconds)

                // Verbleibende Sekunden in der Mitte
                Text(formatRestTime(restTimerManager.remainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(width: 130, height: 130)

            // ±15s Anpassungs-Buttons
            HStack(spacing: 16) {
                Button {
                    onAdjust(-15)
                } label: {
                    Label("15s", systemImage: "minus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Text("±15s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button {
                    onAdjust(15)
                } label: {
                    Label("15s", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(.secondary)
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
