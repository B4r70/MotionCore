//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Zusammenfassung                                                  /
// Datei . . . . : SummaryWeeklyGoalRing.swift                                      /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-02                                                       /
// Beschreibung  : Animierter Ring für den Wochenziel-Fortschritt                   /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import SwiftUI

// MARK: - Summary Weekly Goal Ring

struct SummaryWeeklyGoalRing: View {

    let goal: WeeklyGoal

    @State private var animatedProgress: Double = 0

    // MARK: - Body

    var body: some View {
        HStack(spacing: 20) {
            // Ring mit Zahl innen
            ZStack {
                // Hintergrunds-Ring
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    .frame(width: 72, height: 72)

                // Fortschritts-Ring
                Circle()
                    .trim(from: 0, to: min(1.0, animatedProgress))
                    .stroke(
                        goal.isReached ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                // Zahl im Ring
                VStack(spacing: 1) {
                    Text("\(goal.current)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(goal.isReached ? .green : .primary)
                    Text("/\(goal.target)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Textbereich rechts
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .foregroundStyle(.blue)
                    Text("Wochenziel")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(contextText)
                    .font(.caption)
                    .foregroundStyle(contextColor)
                    .lineLimit(2)
            }

            Spacer()
        }
        .glassCard()
        .task {
            withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                animatedProgress = goal.progressFraction
            }
        }
    }

    // MARK: - Kontext-Text

    private var contextText: String {
        if goal.isReached {
            return "Ziel erreicht!"
        } else if goal.isAboveAverage {
            return "Über deinem Schnitt"
        } else if goal.averageLast4Weeks > 0 {
            let avg = String(format: "%.1f", goal.averageLast4Weeks)
            return "Ø \(avg)/Woche"
        } else {
            return "\(goal.target - goal.current) übrig"
        }
    }

    private var contextColor: Color {
        if goal.isReached { return .green }
        if goal.isAboveAverage { return .blue }
        return .secondary
    }
}

// MARK: - Preview

#Preview("SummaryWeeklyGoalRing") {
    HStack(spacing: 16) {
        SummaryWeeklyGoalRing(goal: WeeklyGoal(
            target: 4,
            current: 2,
            averageLast4Weeks: 3.0,
            isReached: false,
            isAboveAverage: false,
            progressFraction: 0.5
        ))
        .frame(maxWidth: .infinity)

        SummaryWeeklyGoalRing(goal: WeeklyGoal(
            target: 4,
            current: 5,
            averageLast4Weeks: 3.5,
            isReached: true,
            isAboveAverage: true,
            progressFraction: 1.25
        ))
        .frame(maxWidth: .infinity)
    }
    .padding()
    .environmentObject(AppSettings.shared)
}
