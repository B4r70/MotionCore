//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : RestTimerCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 01.01.2026                                                       /
// Beschreibung  : Großer Pause-Timer zwischen Sätzen                               /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

struct RestTimerCard: View {
    let remainingSeconds: Int
    let targetSeconds: Int
    let onSkip: () -> Void
    let onAdjust: (Int) -> Void

    let nextExerciseName: String?
    let nextSetNumber: Int?
    let totalSetsForExercise: Int?

    // Superset: Übungsnamen der nächsten Runde (nil = kein Superset)
    let supersetNextRoundNames: [String]?

    var body: some View {
        VStack(spacing: 24) {
            // "Pause" Label
            Text("Pause")
                .font(.title2.bold())
                .foregroundStyle(.secondary)

            // Kreisförmiger Ring-Timer
            ringTimer

            // Zeitanpassung
            adjustButtons

            // Nächster Satz / Nächste Runde Info
            if let names = supersetNextRoundNames, !names.isEmpty {
                // Superset: Nächste Runde anzeigen
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color.green)
                        Text("Nächste Runde")
                            .font(.caption.bold())
                            .foregroundStyle(Color.green)
                    }
                    HStack(spacing: 4) {
                        ForEach(Array(names.enumerated()), id: \.offset) { idx, name in
                            if idx > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                    }
                }
            } else if let exerciseName = nextExerciseName,
               let setNumber = nextSetNumber,
               let totalSets = totalSetsForExercise {
                VStack(spacing: 4) {
                    Text(exerciseName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("Nächster: Satz \(setNumber) von \(totalSets)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Nächster Satz bereit in \(remainingSeconds) Sekunden")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Skip Button
            Button(action: onSkip) {
                HStack {
                    Image(systemName: "forward.fill")
                    Text("Pause überspringen")
                        .font(.headline)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .glassCard()
    }

    // MARK: - Ring-Timer

    private var ringTimer: some View {
        ZStack {
            // Hintergrund-Ring
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 14)

            // Fortschritts-Ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: progressGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: remainingSeconds)

            // Zahl in der Mitte
            Text(formatRestTime(remainingSeconds))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(remainingSeconds > 10 ? Color.primary : Color.orange)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(width: 210, height: 210)
    }

    // MARK: - Zeitanpassung

    private var adjustButtons: some View {
        HStack {
            Button {
                onAdjust(-15)
            } label: {
                Label("−15s", systemImage: "minus.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            Button {
                onAdjust(15)
            } label: {
                Label("+15s", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Berechnete Properties

    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, Double(remainingSeconds) / Double(targetSeconds))
    }

    private var progressGradientColors: [Color] {
        if remainingSeconds > 30 {
            return [.blue, .green]
        } else if remainingSeconds > 10 {
            return [.green, .orange]
        } else {
            return [.orange, .red]
        }
    }

    // MARK: - Hilfsfunktionen

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview
#Preview("Rest Timer Card") {
    ZStack {
        AnimatedBackground(showAnimatedBlob: true)

        VStack(spacing: 20) {
            RestTimerCard(
                remainingSeconds: 90,
                targetSeconds: 90,
                onSkip: {},
                onAdjust: { _ in },
                nextExerciseName: "Bankdrücken",
                nextSetNumber: 3,
                totalSetsForExercise: 4,
                supersetNextRoundNames: nil
            )

            RestTimerCard(
                remainingSeconds: 45,
                targetSeconds: 60,
                onSkip: {},
                onAdjust: { _ in },
                nextExerciseName: nil,
                nextSetNumber: nil,
                totalSetsForExercise: nil,
                supersetNextRoundNames: ["Crunches", "Beinheben", "Russian Twist"]
            )

            RestTimerCard(
                remainingSeconds: 5,
                targetSeconds: 90,
                onSkip: {},
                onAdjust: { _ in },
                nextExerciseName: nil,
                nextSetNumber: nil,
                totalSetsForExercise: nil,
                supersetNextRoundNames: nil
            )
        }
        .padding()
    }
    .environmentObject(AppSettings.shared)
}
