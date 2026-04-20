//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services / Widget                                                /
// Datei . . . . : WidgetSnapshotPublisher.swift                                    /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 2026-04-20                                                       /
// Beschreibung  : Aggregiert Widget-Daten und schreibt Snapshot in AppGroup        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import WidgetKit

// MARK: - Widget Snapshot Publisher

/// Berechnet und schreibt den Widget-Snapshot nach relevanten Events.
/// Analog zu WatchComplicationService — pure static struct, kein State.
struct WidgetSnapshotPublisher {

    // MARK: - Big-3 Schlüsselwörter (case-insensitive Substring-Match)

    /// Bekannte Bench-Press-Namen (lokalisiert)
    private static let benchKeywords   = ["bankdrücken", "bench press", "bench", "brustpresse", "flachbank"]
    /// Bekannte Squat-Namen (lokalisiert)
    private static let squatKeywords   = ["kniebeugen", "squat", "back squat", "front squat", "tiefkniebeuge"]
    /// Bekannte Deadlift-Namen (lokalisiert)
    private static let deadliftKeywords = ["kreuzheben", "deadlift", "konventionelles", "sumo deadlift", "rumänisch"]

    // MARK: - Öffentliches Update

    /// Berechnet alle Widget-Daten und schreibt den Snapshot in den AppGroup-Container.
    /// Anschliessend werden alle Widget-Timelines neu geladen.
    /// - Parameter allSessions: Alle abgeschlossenen StrengthSessions (aus @Query)
    static func publish(allSessions: [StrengthSession]) {
        let completed = allSessions.filter { $0.isCompleted }

        let streakInfo       = buildStreakInfo(sessions: completed)
        let weeklyProgress   = buildWeeklyProgress(sessions: completed)
        let lastWorkout      = buildLastWorkout(sessions: completed)
        let big3PRs          = buildBig3PRs(sessions: completed)
        let volumeTrend      = buildVolumeTrend(sessions: completed)

        let snapshot = WidgetSnapshot(
            streak: streakInfo,
            weeklyProgress: weeklyProgress,
            lastWorkout: lastWorkout,
            big3PRs: big3PRs,
            volumeTrend: volumeTrend,
            updatedAt: Date()
        )

        WidgetDataStore.write(snapshot: snapshot)
        WidgetCenter.shared.reloadAllTimelines()

        print("WidgetSnapshotPublisher: Snapshot aktualisiert — Streak=\(streakInfo.currentStreak), Weekly=\(weeklyProgress.completed)/\(weeklyProgress.goal)")
    }

    // MARK: - Streak

    private static func buildStreakInfo(sessions: [StrengthSession]) -> StreakInfo {
        let trainingDays = sessions.map { $0.date }
        let engine = StreakCalcEngine(allTrainingDays: trainingDays)
        return StreakInfo(
            currentStreak: engine.currentStreak,
            longestStreak: engine.longestStreak
        )
    }

    // MARK: - Wöchentlicher Fortschritt

    private static func buildWeeklyProgress(sessions: [StrengthSession]) -> WeeklyProgress {
        let calendar    = Calendar.current
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        ) ?? .now

        let count = sessions.filter { $0.date >= startOfWeek }.count
        return WeeklyProgress(completed: count, goal: 5)
    }

    // MARK: - Letztes Workout

    private static func buildLastWorkout(sessions: [StrengthSession]) -> LastWorkoutSummary? {
        guard let last = sessions.sorted(by: { $0.date > $1.date }).first else { return nil }

        // Häufigste Übung in der Session als Top-Übung
        let topExercise = last.groupedSets.first?.first.map { set -> String in
            set.exerciseNameSnapshot.isEmpty ? set.exerciseName : set.exerciseNameSnapshot
        } ?? ""

        let duration = last.actualDuration ?? last.duration

        return LastWorkoutSummary(
            date: last.date,
            durationMinutes: duration,
            totalVolumeKg: last.totalVolume,
            topExerciseName: topExercise,
            completedSets: last.completedSets
        )
    }

    // MARK: - Big-3 PRs

    private static func buildBig3PRs(sessions: [StrengthSession]) -> [PRItem] {
        // Alle abgeschlossenen Work-Sets mit Gewicht und Reps
        let allSets = sessions.flatMap { $0.safeExerciseSets }
            .filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }

        let benchPR   = bestPR(from: allSets, keywords: benchKeywords,   displayName: "Bankdrücken")
        let squatPR   = bestPR(from: allSets, keywords: squatKeywords,   displayName: "Kniebeugen")
        let deadliftPR = bestPR(from: allSets, keywords: deadliftKeywords, displayName: "Kreuzheben")

        return [benchPR, squatPR, deadliftPR].compactMap { $0 }
    }

    /// Berechnet das beste geschätzte 1RM (Epley) für eine Gruppe von Keywords
    private static func bestPR(
        from sets: [ExerciseSet],
        keywords: [String],
        displayName: String
    ) -> PRItem? {
        let matching = sets.filter { set in
            let name = (set.exerciseNameSnapshot.isEmpty ? set.exerciseName : set.exerciseNameSnapshot)
                .lowercased()
            return keywords.contains { name.contains($0) }
        }

        guard let best = matching.max(by: {
            $0.weight * (1.0 + Double($0.reps) / 30.0) <
            $1.weight * (1.0 + Double($1.reps) / 30.0)
        }) else { return nil }

        let oneRM = best.weight * (1.0 + Double(best.reps) / 30.0)
        return PRItem(exerciseName: displayName, weight1RMkg: oneRM)
    }

    // MARK: - 4-Wochen-Volumen-Trend

    private static func buildVolumeTrend(sessions: [StrengthSession]) -> [VolumeTrendPoint] {
        let calendar = Calendar.current
        let now = Date()

        // Letzte 4 Wochen (inklusive laufende Woche)
        return (0..<4).reversed().compactMap { weeksAgo -> VolumeTrendPoint? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now),
                  let weekStartNormalized = calendar.date(
                      from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)
                  ),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStartNormalized)
            else { return nil }

            let weekSessions = sessions.filter {
                $0.date >= weekStartNormalized && $0.date < weekEnd
            }

            let volume = weekSessions.reduce(0.0) { $0 + $1.totalVolume }

            // KW-Label (z.B. "KW17")
            let weekNumber = calendar.component(.weekOfYear, from: weekStartNormalized)
            let label = "KW\(weekNumber)"

            return VolumeTrendPoint(weekLabel: label, volumeKg: volume)
        }
    }
}
