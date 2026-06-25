//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Workout                                                          /
// Datei . . . . : RestTimerCard.swift                                              /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 01.01.2026                                                       /
// Beschreibung  : Pausen-Timer inline (Ring + Schwellen, einfarbig) — §4.2         /
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
        VStack(spacing: Space.s6) {
            Text("Pause")
                .font(AppFont.headline)
                .foregroundStyle(Theme.textSecondary)

            ringTimer
            adjustButtons
            nextInfo

            Button(action: onSkip) {
                Label("Pause überspringen", systemImage: "forward.fill")
            }
            .buttonStyle(.mcPrimary)
        }
        .card()
    }

    // MARK: - Ring-Timer (einfarbig, Schwellen)

    private var ringTimer: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceSunken, lineWidth: 13)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: remainingSeconds)
            Text(formatRestTime(remainingSeconds))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(width: 210, height: 210)
    }

    // MARK: - Nächster-Satz / Superset-Info

    @ViewBuilder
    private var nextInfo: some View {
        if let names = supersetNextRoundNames, !names.isEmpty {
            VStack(spacing: Space.s2) {
                HStack(spacing: Space.s1) {
                    Image(systemName: "bolt.fill")
                        .font(AppFont.caption)
                        .foregroundStyle(Theme.success)
                    Text("Nächste Runde")
                        .font(AppFont.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.success)
                }
                HStack(spacing: Space.s1) {
                    ForEach(Array(names.enumerated()), id: \.offset) { idx, name in
                        if idx > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Text(name)
                            .font(AppFont.callout)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                }
            }
        } else if let exerciseName = nextExerciseName,
                  let setNumber = nextSetNumber,
                  let totalSets = totalSetsForExercise {
            VStack(spacing: Space.s1) {
                Text(exerciseName)
                    .font(AppFont.body)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.textPrimary)
                Text("Nächster: Satz \(setNumber) von \(totalSets)")
                    .font(AppFont.callout)
                    .foregroundStyle(Theme.textSecondary)
            }
        } else {
            Text("Nächster Satz bereit in \(remainingSeconds) Sekunden")
                .font(AppFont.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Zeitanpassung

    private var adjustButtons: some View {
        HStack {
            adjustPill(amount: -15, label: "−15s", icon: "minus.circle.fill")
            Spacer()
            adjustPill(amount: 15, label: "+15s", icon: "plus.circle.fill")
        }
        .padding(.horizontal, Space.s2)
    }

    private func adjustPill(amount: Int, label: String, icon: String) -> some View {
        Button {
            onAdjust(amount)
        } label: {
            Label(label, systemImage: icon)
                .font(AppFont.callout)
                .fontWeight(.bold)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, Space.s3)
                .padding(.vertical, Space.s2)
                .background(Theme.surfaceSunken, in: Capsule())
        }
    }

    // MARK: - Berechnete Properties

    private var progress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, Double(remainingSeconds) / Double(targetSeconds))
    }

    // ≤10s rot, ≤30s amber, sonst Akzent (kein Gradient)
    private var ringColor: Color {
        if remainingSeconds <= 10 { return Theme.danger }
        if remainingSeconds <= 30 { return Theme.warning }
        return Theme.accent
    }

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview("Rest Timer Card") {
    ZStack {
        Theme.surfaceApp.ignoresSafeArea()
        VStack(spacing: 20) {
            RestTimerCard(
                remainingSeconds: 90, targetSeconds: 90,
                onSkip: {}, onAdjust: { _ in },
                nextExerciseName: "Bankdrücken", nextSetNumber: 3, totalSetsForExercise: 4,
                supersetNextRoundNames: nil
            )
            RestTimerCard(
                remainingSeconds: 25, targetSeconds: 60,
                onSkip: {}, onAdjust: { _ in },
                nextExerciseName: nil, nextSetNumber: nil, totalSetsForExercise: nil,
                supersetNextRoundNames: ["Crunches", "Beinheben", "Russian Twist"]
            )
            RestTimerCard(
                remainingSeconds: 5, targetSeconds: 90,
                onSkip: {}, onAdjust: { _ in },
                nextExerciseName: nil, nextSetNumber: nil, totalSetsForExercise: nil,
                supersetNextRoundNames: nil
            )
        }
        .padding()
    }
}
